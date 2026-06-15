import 'dart:math';

import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/games/mini_game_registry.dart';
import 'package:flutter/foundation.dart';

import 'party_models.dart';

/// One recorded player decision. Deterministic transitions (walking a step,
/// confirming a panel, advancing through the mini-game intro) are NOT logged —
/// they're replayed automatically — so the log holds only genuine choices.
enum PartyInputKind { roll, choosePath, buyPotato, skipPotato, miniScore, useItem }

class PartyInput {
  final PartyInputKind kind;

  /// Payload: the chosen successor index for [choosePath], the score for
  /// [miniScore]; unused (0) otherwise.
  final int value;

  const PartyInput(this.kind, [this.value = 0]);

  Map<String, dynamic> toJson() => {'k': kind.index, 'v': value};

  factory PartyInput.fromJson(Map<String, dynamic> json) => PartyInput(
      PartyInputKind.values[json['k'] as int], (json['v'] as int?) ?? 0);

  @override
  String toString() {
    final label = kind.toString().split('.').last;
    return value == 0 ? label : '$label:$value';
  }
}

enum PartyPhase {
  turnStart, // current player's banner + ROLL button
  moving, // token steps along the path, one space per UI tick
  chooseBranch, // standing at a fork: the player picks a direction
  shopOffer, // passing the Potato Market with enough paydirt: buy or pass
  spaceResolved, // effect shown, waiting for CONTINUE
  minigameIntro, // round's game revealed
  passPhone, // hand the phone to the next contestant
  minigamePlaying, // MiniGameHost active
  minigameResults, // ranking + paydirt awards
  gameOver,
}

/// The dice half of a roll; movement itself happens step-by-step through
/// [PartyController.advanceStep] so forks and the shop can pause for input.
class TurnResult {
  final int playerIndex;
  final List<int> dice;
  final int rollBonus; // mitochondria
  final int steps;
  final int fromPosition;

  const TurnResult({
    required this.playerIndex,
    required this.dice,
    required this.rollBonus,
    required this.steps,
    required this.fromPosition,
  });
}

class MiniGameStanding {
  final PartyPlayer player;
  final int score;
  int rank = 0;
  int award = 0;
  MiniGameStanding(this.player, this.score);
}

class TeamStanding {
  final int teamIndex;
  final int potatoes;
  final int paydirt;
  const TeamStanding(this.teamIndex, this.potatoes, this.paydirt);
}

/// Pass-and-play board game loop. Each round every player rolls and walks
/// the path (choosing directions at forks, buying potatoes at the market),
/// then everyone plays the same randomly chosen mini-game and paydirt is
/// awarded by rank. Most potatoes after the final round wins (paydirt
/// breaks ties); team modes count the team's combined haul.
class PartyController extends ChangeNotifier {
  PartyController({
    required this.mode,
    required this.totalRounds,
    required List<String> playerNames,
    int? seed,
    Random? random,
  })  : seed = seed ?? _newSeed(),
        _initialNames = List<String>.unmodifiable(playerNames) {
    _rng = random ?? Random(this.seed);
    for (var i = 0; i < mode.playerCount; i++) {
      players.add(PartyPlayer(
        index: i,
        name: playerNames[i],
        color: kCharacters[i].color,
        teamIndex: mode.teamOf(i),
      ));
    }
  }

  /// Rebuilds a game by replaying a recorded input log against fresh code.
  /// This — not a state snapshot — is the canonical save format: it survives
  /// refactors because state is reconstructed by re-running the same decisions
  /// through whatever the controller does today.
  factory PartyController.replay({
    required PartyMode mode,
    required int totalRounds,
    required List<String> playerNames,
    required int seed,
    required List<PartyInput> inputs,
  }) {
    final c = PartyController(
      mode: mode,
      totalRounds: totalRounds,
      playerNames: playerNames,
      seed: seed,
    );
    for (final input in inputs) {
      c._pumpToDecision();
      if (c.phase == PartyPhase.gameOver) break;
      c._apply(input);
    }
    c._pumpToDecision();
    return c;
  }

  static int _newSeed() => Random().nextInt(0x7fffffff);

  final PartyMode mode;
  final int totalRounds;

  /// Seed the whole game derives from. Recorded inputs + this seed fully
  /// determine every roll, event, and mini-game pick.
  final int seed;
  final List<String> _initialNames;
  late final Random _rng;

  /// Ordered log of player decisions — the replayable record of the match.
  final List<PartyInput> inputLog = [];

  final List<PartyPlayer> players = [];
  final List<BoardSpace> board = buildBoard();

  PartyPhase phase = PartyPhase.turnStart;
  int round = 1;
  int currentPlayerIndex = 0;
  TurnResult? lastTurn;

  /// Steps still to walk this turn; the UI calls [advanceStep] per tick.
  int stepsRemaining = 0;

  /// Human-readable effect lines for the current turn (laps, purchases,
  /// space effects).
  final List<String> turnLog = [];

  /// Debug-only: forces every mini-game pick to this spec id.
  String? debugForcedSpecId;

  // Mini-game round state
  MiniGameSpec? currentSpec;
  int miniPlayerIndex = 0;
  final List<MiniGameStanding> standings = [];
  String? _lastSpecId;

  PartyPlayer get currentPlayer => players[currentPlayerIndex];
  PartyPlayer get miniPlayer => players[miniPlayerIndex];
  bool get isLastMiniPlayer => miniPlayerIndex >= players.length - 1;

  // ---------------------------------------------------------------- rolling

  /// Rolls for the current player and enters [PartyPhase.moving]. The UI
  /// then calls [advanceStep] once per animation tick; the controller pauses
  /// in [PartyPhase.chooseBranch] / [PartyPhase.shopOffer] when the player
  /// has a decision to make.
  TurnResult roll() {
    assert(phase == PartyPhase.turnStart);
    inputLog.add(const PartyInput(PartyInputKind.roll));
    final p = currentPlayer;
    turnLog.clear();

    final dice = [_rng.nextInt(6) + 1, if (p.accelerator) _rng.nextInt(6) + 1];
    if (p.accelerator) {
      turnLog.add('${p.name} fired the ACCELERATOR — two dice!');
      p.accelerator = false;
    }
    var bonus = 0;
    if (p.mitochondria) {
      bonus = 3;
      turnLog.add('MITOCHONDRIA kicks in: +3 movement.');
      p.mitochondria = false;
    }

    stepsRemaining = dice.reduce((a, b) => a + b) + bonus;
    lastTurn = TurnResult(
      playerIndex: p.index,
      dice: dice,
      rollBonus: bonus,
      steps: stepsRemaining,
      fromPosition: p.position,
    );
    phase = PartyPhase.moving;
    notifyListeners();
    return lastTurn!;
  }

  /// The choices at the current fork (only valid in [PartyPhase.chooseBranch]).
  List<int> get branchOptions => board[currentPlayer.position].nexts;

  /// Walks one space. Pauses for a branch choice when departing a fork.
  void advanceStep() {
    if (phase != PartyPhase.moving || stepsRemaining <= 0) return;
    final from = board[currentPlayer.position];
    if (from.isFork) {
      phase = PartyPhase.chooseBranch;
      notifyListeners();
      return;
    }
    _stepTo(from.nexts.first);
  }

  /// Resolves a fork: the player picked which successor to walk to.
  void choosePath(int nextIndex) {
    assert(phase == PartyPhase.chooseBranch);
    assert(board[currentPlayer.position].nexts.contains(nextIndex));
    inputLog.add(PartyInput(PartyInputKind.choosePath, nextIndex));
    final p = currentPlayer;
    if (board[nextIndex].isShortcut) {
      final branch = kBoardBranches
          .firstWhere((b) => b.spaceIndices.contains(nextIndex));
      turnLog.add(branch.mergeIndex < branch.forkIndex
          ? '${p.name} ducks into the filibuster loop.'
          : '${p.name} takes the shortcut lane.');
    }
    phase = PartyPhase.moving;
    _stepTo(nextIndex);
  }

  void _stepTo(int next) {
    final p = currentPlayer;
    p.position = next;
    stepsRemaining--;
    if (next == 0) {
      p.paydirt += 5;
      turnLog.add('${p.name} completed a lap of existence: +5 paydirt.');
    }
    // Passing (or landing on) the Potato Market with enough paydirt pauses
    // the walk for a purchase decision.
    if (next == kShopIndex && p.paydirt >= kPotatoPrice) {
      phase = PartyPhase.shopOffer;
      notifyListeners();
      return;
    }
    _finishStep();
  }

  /// Buys one potato at the market, then the walk continues.
  void buyPotato() {
    assert(phase == PartyPhase.shopOffer);
    inputLog.add(const PartyInput(PartyInputKind.buyPotato));
    final p = currentPlayer;
    p.paydirt -= kPotatoPrice;
    p.potatoes++;
    turnLog.add(
        '${p.name} bought a POTATO for $kPotatoPrice paydirt! (${p.potatoes} total)');
    phase = PartyPhase.moving;
    _finishStep();
  }

  /// Declines the market offer; the walk continues.
  void skipPotato() {
    assert(phase == PartyPhase.shopOffer);
    inputLog.add(const PartyInput(PartyInputKind.skipPotato));
    phase = PartyPhase.moving;
    _finishStep();
  }

  void _finishStep() {
    final p = currentPlayer;
    if (stepsRemaining <= 0) {
      _resolveSpace(p, board[p.position], turnLog);
      phase = PartyPhase.spaceResolved;
    }
    notifyListeners();
  }

  /// Advance past the resolution panel: next player, or the mini-game round.
  void confirmSpace() {
    assert(phase == PartyPhase.spaceResolved);
    if (currentPlayerIndex < players.length - 1) {
      currentPlayerIndex++;
      phase = PartyPhase.turnStart;
    } else {
      _startMiniGameRound();
    }
    notifyListeners();
  }

  void _resolveSpace(PartyPlayer p, BoardSpace space, List<String> log) {
    switch (space.type) {
      case SpaceType.gain:
        p.paydirt += 5;
        log.add('${p.name} landed on a paydirt space: +5 paydirt.');
        break;
      case SpaceType.lose:
        if (p.voidShield) {
          p.voidShield = false;
          log.add("${p.name}'s VOID SHIELD absorbed the loss!");
        } else {
          p.paydirt = max(0, p.paydirt - 5);
          log.add('${p.name} hit an entropy space: −5 paydirt.');
        }
        break;
      case SpaceType.powerUp:
        _grantPowerUp(p, space.section, log);
        break;
      case SpaceType.event:
        _runEvent(p, log);
        break;
      case SpaceType.shop:
        // The purchase offer already fired while stepping in; landing here
        // just means the walk ended at the market.
        log.add('${p.name} is at the Potato Market '
            '(potatoes cost $kPotatoPrice paydirt).');
        break;
    }
  }

  /// Power-up spaces now hand you the item to HOLD; you choose when to spend it
  /// on your turn (see [useItem]). The pack is capped at [kMaxItems].
  void _grantPowerUp(PartyPlayer p, BoardSection section, List<String> log) {
    final pu = section.powerUp;
    if (p.items.length >= kMaxItems) {
      log.add('${section.name} power-up: ${pu.label} — but your pack is full!');
      return;
    }
    p.items.add(pu);
    log.add('${section.name} power-up: picked up ${pu.label} '
        '— ${pu.description}.');
  }

  /// Spends a held item on the current player's turn. Pre-roll buffs arm for
  /// the imminent roll; SPARK pays out now; CATALYST and the shields arm for
  /// the next relevant event. A logged decision, so replay stays faithful.
  void useItem(PowerUp item) {
    assert(phase == PartyPhase.turnStart);
    final p = currentPlayer;
    if (!p.items.remove(item)) return; // not in the pack
    inputLog.add(PartyInput(PartyInputKind.useItem, item.index));
    switch (item) {
      case PowerUp.spark:
        p.paydirt += 4;
        break;
      case PowerUp.accelerator:
        p.accelerator = true;
        break;
      case PowerUp.mitochondria:
        p.mitochondria = true;
        break;
      case PowerUp.catalyst:
        p.catalyst = true;
        break;
      case PowerUp.voidShield:
        p.voidShield = true;
        break;
      case PowerUp.strongBond:
        p.strongBond = true;
        break;
    }
    notifyListeners();
  }

  void _runEvent(PartyPlayer p, List<String> log) {
    final others = players.where((o) => o.index != p.index).toList();
    switch (_rng.nextInt(5)) {
      case 0: // Cosmic Swap
        final target = others[_rng.nextInt(others.length)];
        if (target.strongBond) {
          target.strongBond = false;
          log.add(
              'COSMIC SWAP targeted ${target.name}, but their STRONG BOND held!');
        } else {
          final tmp = p.position;
          p.position = target.position;
          target.position = tmp;
          log.add('COSMIC SWAP! ${p.name} traded places with ${target.name}.');
        }
        break;
      case 1: // Entropy
        for (final o in players) {
          final loss = _isLeader(o) ? 6 : 3;
          if (o.voidShield) {
            o.voidShield = false;
          } else {
            o.paydirt = max(0, o.paydirt - loss);
          }
        }
        log.add(
            'ENTROPY SURGE! Everyone loses 3 paydirt, the leader loses 6.');
        break;
      case 2: // Photosynthesis
        for (final o in players) {
          o.paydirt += 3;
        }
        log.add('PHOTOSYNTHESIS! Everyone gains +3 paydirt.');
        break;
      case 3: // Wormhole — 5 hops forward (main option at any fork)
        for (var i = 0; i < 5; i++) {
          p.position = board[p.position].nexts.first;
        }
        log.add('WORMHOLE! ${p.name} jumps forward 5 spaces.');
        break;
      default: // Quantum Tunnel — back 4 along the main loop
        if (!board[p.position].isShortcut) {
          p.position =
              (p.position - 4 + kMainLoopLength) % kMainLoopLength;
          log.add('QUANTUM TUNNEL! ${p.name} slips back 4 spaces.');
        } else {
          log.add(
              'QUANTUM TUNNEL fizzled — ${p.name} is off the main loop.');
        }
        break;
    }
  }

  /// Leader = most potatoes, paydirt breaks ties.
  bool _isLeader(PartyPlayer p) {
    for (final o in players) {
      if (o.potatoes > p.potatoes ||
          (o.potatoes == p.potatoes && o.paydirt > p.paydirt)) {
        return false;
      }
    }
    return true;
  }

  // ------------------------------------------------------------- mini-games

  void _startMiniGameRound() {
    currentSpec = _pickSpec();
    _lastSpecId = currentSpec!.id;
    miniPlayerIndex = 0;
    standings.clear();
    phase = PartyPhase.minigameIntro;
  }

  /// Random pick from the enabled pool, never the same game twice in a row.
  /// A debug override (set from the intro screen in debug builds) wins.
  MiniGameSpec _pickSpec() {
    if (debugForcedSpecId != null) {
      final forced = MiniGameRegistry.byId(debugForcedSpecId!);
      if (forced != null) return forced;
    }
    final list = MiniGameRegistry.enabledSpecs;
    if (list.length == 1) return list.first;
    final pool = list.where((s) => s.id != _lastSpecId).toList();
    return pool[_rng.nextInt(pool.length)];
  }

  /// Debug builds only: swap the revealed game on the intro screen.
  void debugSetSpec(MiniGameSpec spec) {
    assert(phase == PartyPhase.minigameIntro);
    currentSpec = spec;
    _lastSpecId = spec.id;
    debugForcedSpecId = spec.id;
    notifyListeners();
  }

  /// Section badge for the intro screen (the game's home territory).
  BoardSection get currentSection => kBoardSections.firstWhere(
      (s) => s.scale == currentSpec!.scale,
      orElse: () => kBoardSections.last);

  void beginMiniGameRound() {
    assert(phase == PartyPhase.minigameIntro);
    phase = PartyPhase.passPhone;
    notifyListeners();
  }

  void startMiniGameAttempt() {
    assert(phase == PartyPhase.passPhone);
    phase = PartyPhase.minigamePlaying;
    notifyListeners();
  }

  void recordMiniScore(int score) {
    assert(phase == PartyPhase.minigamePlaying);
    inputLog.add(PartyInput(PartyInputKind.miniScore, score));
    standings.add(MiniGameStanding(miniPlayer, score));
    if (isLastMiniPlayer) {
      _scoreMiniGameRound();
      phase = PartyPhase.minigameResults;
    } else {
      miniPlayerIndex++;
      phase = PartyPhase.passPhone;
    }
    notifyListeners();
  }

  static const _ffaAwards = [10, 6, 4, 2, 1, 1, 1, 1];
  static const _teamAwards = [10, 4];

  void _scoreMiniGameRound() {
    if (mode.isTeams) {
      // Rank teams by total score; every member of a team gets that rank's award.
      final totals = <int, int>{};
      for (final s in standings) {
        totals[s.player.teamIndex] =
            (totals[s.player.teamIndex] ?? 0) + s.score;
      }
      final rankedTeams = totals.keys.toList()
        ..sort((a, b) => totals[b]!.compareTo(totals[a]!));
      for (final s in standings) {
        var rank = rankedTeams.indexOf(s.player.teamIndex);
        // Tied team totals share first place.
        if (rank > 0 &&
            totals[s.player.teamIndex] == totals[rankedTeams[0]]) {
          rank = 0;
        }
        s.rank = rank;
        s.award = _teamAwards[min(rank, _teamAwards.length - 1)];
      }
    } else {
      final sorted = [...standings]
        ..sort((a, b) => b.score.compareTo(a.score));
      for (var i = 0; i < sorted.length; i++) {
        // Ties share the better rank.
        if (i > 0 && sorted[i].score == sorted[i - 1].score) {
          sorted[i].rank = sorted[i - 1].rank;
        } else {
          sorted[i].rank = i;
        }
        sorted[i].award = _ffaAwards[min(sorted[i].rank, _ffaAwards.length - 1)];
      }
    }
    for (final s in standings) {
      if (s.player.catalyst) {
        s.player.catalyst = false;
        s.award *= 2;
      }
      s.player.paydirt += s.award;
    }
  }

  /// Past the results screen: next round, or game over.
  void confirmMiniGameResults() {
    assert(phase == PartyPhase.minigameResults);
    if (round >= totalRounds) {
      phase = PartyPhase.gameOver;
    } else {
      round++;
      currentPlayerIndex = 0;
      phase = PartyPhase.turnStart;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------- results

  /// Final placements, best first: potatoes, then paydirt, then position.
  List<PartyPlayer> get finalPlayerRanking {
    final sorted = [...players]..sort((a, b) {
        if (b.potatoes != a.potatoes) return b.potatoes.compareTo(a.potatoes);
        if (b.paydirt != a.paydirt) return b.paydirt.compareTo(a.paydirt);
        return b.position.compareTo(a.position);
      });
    return sorted;
  }

  /// Team totals, best first.
  List<TeamStanding> get finalTeamRanking {
    final potatoes = <int, int>{};
    final paydirt = <int, int>{};
    for (final p in players) {
      potatoes[p.teamIndex] = (potatoes[p.teamIndex] ?? 0) + p.potatoes;
      paydirt[p.teamIndex] = (paydirt[p.teamIndex] ?? 0) + p.paydirt;
    }
    final standings = [
      for (final team in potatoes.keys)
        TeamStanding(team, potatoes[team]!, paydirt[team]!),
    ]..sort((a, b) {
        if (b.potatoes != a.potatoes) return b.potatoes.compareTo(a.potatoes);
        return b.paydirt.compareTo(a.paydirt);
      });
    return standings;
  }

  // ------------------------------------------------------------- replay core

  /// Applies one recorded decision. The controller must already be sitting in
  /// the phase that decision belongs to (see [_pumpToDecision]).
  void _apply(PartyInput input) {
    switch (input.kind) {
      case PartyInputKind.roll:
        roll();
        break;
      case PartyInputKind.choosePath:
        choosePath(input.value);
        break;
      case PartyInputKind.buyPotato:
        buyPotato();
        break;
      case PartyInputKind.skipPotato:
        skipPotato();
        break;
      case PartyInputKind.miniScore:
        recordMiniScore(input.value);
        break;
      case PartyInputKind.useItem:
        useItem(PowerUp.values[input.value]);
        break;
    }
  }

  /// Fast-forwards through every deterministic transition until the game is
  /// waiting on a real decision (or is over). The guard doubles as a soft-lock
  /// detector: if the machine can't reach a decision we surface it loudly
  /// instead of spinning forever.
  void _pumpToDecision() {
    var guard = 0;
    while (guard++ < 100000) {
      switch (phase) {
        case PartyPhase.moving:
          advanceStep();
          break;
        case PartyPhase.spaceResolved:
          confirmSpace();
          break;
        case PartyPhase.minigameIntro:
          beginMiniGameRound();
          break;
        case PartyPhase.passPhone:
          startMiniGameAttempt();
          break;
        case PartyPhase.minigameResults:
          confirmMiniGameResults();
          break;
        case PartyPhase.turnStart:
        case PartyPhase.chooseBranch:
        case PartyPhase.shopOffer:
        case PartyPhase.minigamePlaying:
        case PartyPhase.gameOver:
          return;
      }
    }
    throw StateError('soft-lock: no decision reachable from $phase');
  }

  /// Throws on any broken-game invariant. Cheap enough to call after every
  /// input; this is the contract the Peeler soak will hold the game to.
  void checkInvariants() {
    for (final p in players) {
      if (p.position < 0 || p.position >= board.length) {
        throw StateError('${p.name} position out of range: ${p.position}');
      }
      if (p.paydirt < 0) throw StateError('${p.name} has negative paydirt');
      if (p.potatoes < 0) throw StateError('${p.name} has negative potatoes');
    }
    if (round < 1 || round > totalRounds) {
      throw StateError('round out of range: $round');
    }
  }

  /// The whole match as a tiny, refactor-proof save: seed + setup + decisions.
  Map<String, dynamic> toSaveJson() => {
        'seed': seed,
        'mode': mode.index,
        'rounds': totalRounds,
        'names': _initialNames,
        'inputs': [for (final i in inputLog) i.toJson()],
      };

  /// Reconstructs a controller from [toSaveJson] output by replaying it.
  static PartyController fromSaveJson(Map<String, dynamic> json) =>
      PartyController.replay(
        mode: PartyMode.values[json['mode'] as int],
        totalRounds: json['rounds'] as int,
        playerNames: List<String>.from(json['names'] as List),
        seed: json['seed'] as int,
        inputs: [
          for (final e in (json['inputs'] as List))
            PartyInput.fromJson(Map<String, dynamic>.from(e as Map))
        ],
      );
}
