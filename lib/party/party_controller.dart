import 'dart:math';

import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/games/mini_game_registry.dart';
import 'package:flutter/foundation.dart';

import 'maps/game_map.dart';
import 'maps/ops.dart';
import 'party_models.dart';

/// One recorded player decision. Deterministic transitions (walking a step,
/// confirming a panel, advancing through the mini-game intro) are NOT logged —
/// they're replayed automatically — so the log holds only genuine choices.
enum PartyInputKind {
  roll,
  choosePath,
  buyPotato,
  skipPotato,
  miniScore,
  useItem,
  useAtp, // spend ATP to boost the roll (value = +1/+2/+3)
  beginWalk, // leave the roll-result panel and start walking
  // APPENDED (index-stable; toJson serializes by .index): keep at the END.
  chooseCardOption, // pick option A/B on a decision card (value = option index)
  buyItem, // buy an item at the market (value = PowerUp.index)
  confirmResults, // advance past the round ceremony (local tap / online host)
  wheelStop, // the current spinner stops the wheel (outcome = tape draw)
  useItemOn, // targeted item (value = PowerUp.index * 16 + target seat)
}

/// Where the match's randomness comes from.
///
/// [local] and [host] draw straight from a seeded [Random]; the difference is
/// that [host] also *records* every draw so it can be published. [client]
/// never touches [Random] — it replays the host's recorded draws verbatim.
/// This makes online rolls/events/game-picks host-authoritative, so clients
/// stay in sync without depending on cross-platform `Random(seed)` parity.
enum PartyRandomMode { local, host, client }

class PartyInput {
  final PartyInputKind kind;

  /// Payload: the chosen successor index for [choosePath], the score for
  /// [miniScore]; unused (0) otherwise.
  final int value;

  /// Which player this input belongs to. Only meaningful for [miniScore],
  /// where simultaneous online play means scores arrive in any order and each
  /// must be attributed to its author. Defaults to 0 for every other input
  /// (whose owner is implied by the turn order).
  final int player;

  const PartyInput(this.kind, [this.value = 0, this.player = 0]);

  Map<String, dynamic> toJson() =>
      {'k': kind.index, 'v': value, if (player != 0) 'p': player};

  factory PartyInput.fromJson(Map<String, dynamic> json) => PartyInput(
        PartyInputKind.values[json['k'] as int],
        (json['v'] as int?) ?? 0,
        (json['p'] as int?) ?? 0,
      );

  @override
  String toString() {
    final label = kind.toString().split('.').last;
    final suffix = player == 0 ? '' : '@p$player';
    return value == 0 ? '$label$suffix' : '$label:$value$suffix';
  }
}

enum PartyPhase {
  turnStart, // current player's banner + ROLL button (+ pre-roll ATP boost)
  rollResult, // dice shown; optional +1 ATP boost, then MOVE
  moving, // token steps along the path, one space per UI tick
  chooseBranch, // standing at a fork: the player picks a direction
  shopOffer, // passing the market: buy a potato or an item, or pass
  cardDecision, // a decision card was drawn: pick option A or B
  spaceResolved, // effect shown, waiting for CONTINUE
  minigameIntro, // round's game revealed
  passPhone, // hand the phone to the next contestant
  minigamePlaying, // MiniGameHost active
  minigameResults, // ranking + diamonds awards
  gameOver,
  // APPENDED (switch coverage everywhere; phase itself is never serialized).
  wheelSpin, // the wheel is up: spinners hit STOP in queue order
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

/// A landing's numeric consequence (signed resource deltas), stamped with a
/// sequence number so the board UI can float a "+5 💎"-style pop exactly once
/// per fresh landing.
class LandingEffect {
  final int seq;
  final int playerIndex;
  final int position; // board index the pop renders over
  final int diamonds; // signed delta
  final int potatoes; // signed delta

  const LandingEffect({
    required this.seq,
    required this.playerIndex,
    required this.position,
    required this.diamonds,
    required this.potatoes,
  });
}

class MiniGameStanding {
  final PartyPlayer player;
  final int score;
  int rank = 0;
  int award = 0;
  MiniGameStanding(this.player, this.score);
}

/// A live wheel session: who still has to spin and which table is up.
class WheelSession {
  final WheelTier tier;
  final List<int> queue; // seat indices still to spin (head = current)
  WheelSession(this.tier, this.queue);
  int get currentSpinner => queue.first;
}

/// One landed wheel outcome, stamped so the UI can animate it exactly once.
class WheelResult {
  final int seq;
  final WheelTier tier;
  final int spinner; // seat index
  final int segmentIndex; // into wheelTableFor(tier)
  final String summary; // narrator-ready outcome line
  const WheelResult({
    required this.seq,
    required this.tier,
    required this.spinner,
    required this.segmentIndex,
    required this.summary,
  });
}

class TeamStanding {
  final int teamIndex;
  final int potatoes;
  final int diamonds;
  const TeamStanding(this.teamIndex, this.potatoes, this.diamonds);
}

/// A mischief op (the Peeler / the Masher) roaming the board. Each round it
/// robs the leader and relocates, CARRYING the loot; a player who reaches its
/// tile snatches the stash back. Only present on [GameMap] boards.
class OpToken {
  final Op op;
  int position;
  int diamonds = 0; // loot carried, reclaimable by catching it
  int potatoes = 0;
  OpToken(this.op, this.position);

  bool get hasLoot => diamonds > 0 || potatoes > 0;
}

/// A Potato Shack ghost — released after round 1, haunting the board for the
/// rest of the game (PARTY_CINEMATIC_SPEC §5). Ghosts drift strangely between
/// rounds and shake diamonds out of players who land on them; what they take
/// goes back to the Shack (gone for good), unlike the ops' reclaimable loot.
class GhostToken {
  int position;
  GhostToken(this.position);
}

/// Pass-and-play board game loop. Each round every player rolls and walks
/// the path (choosing directions at forks, buying potatoes at the market),
/// then everyone plays the same randomly chosen mini-game and diamonds is
/// awarded by rank. Most potatoes after the final round wins (diamonds
/// breaks ties); team modes count the team's combined haul.
class PartyController extends ChangeNotifier {
  PartyController({
    required this.mode,
    required this.totalRounds,
    required List<String> playerNames,
    int? seed,
    Random? random,
    this.randomMode = PartyRandomMode.local,
    this.gameMap,
    List<int>? characters,
    this.wheels = true,
  })  : seed = seed ?? _newSeed(),
        _initialNames = List<String>.unmodifiable(playerNames) {
    _rng = random ?? Random(this.seed);
    _tape = randomMode == PartyRandomMode.client
        ? _ReplayTape()
        : _SeededTape(_rng, record: randomMode == PartyRandomMode.host);
    for (var i = 0; i < mode.playerCount; i++) {
      // Character chosen in the lobby (online) or defaulted to the seat index.
      final charIdx = (characters != null && i < characters.length)
          ? characters[i] % kCharacters.length
          : i % kCharacters.length;
      players.add(PartyPlayer(
        index: i,
        name: playerNames[i],
        color: kCharacters[charIdx].color,
        teamIndex: mode.teamOf(i),
        character: charIdx,
      ));
    }
    // The mischief crew works the GameMap boards; legacy loop has none. Seed
    // them at distinct tiles so they read as separate threats from the start.
    if (gameMap != null) {
      final n = board.length;
      ops.add(OpToken(kPeeler, (n * 0.34).floor()));
      ops.add(OpToken(kMasher, (n * 0.67).floor()));
    }
    if (wheels) {
      // The opening spin: every player lands an item before turn one — the
      // immediate-interactivity layer (PARTY_CINEMATIC_SPEC §2).
      _startWheel(WheelTier.opening,
          [for (var i = 0; i < players.length; i++) i]);
    } else {
      _beginTurn(); // first player's energy trickle
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
    GameMap? gameMap,
    bool wheels = true,
  }) {
    final c = PartyController(
      mode: mode,
      totalRounds: totalRounds,
      playerNames: playerNames,
      seed: seed,
      gameMap: gameMap,
      wheels: wheels,
    );
    for (final input in inputs) {
      c._pumpToDecision();
      if (c.phase == PartyPhase.gameOver) break;
      c._apply(input);
    }
    c._pumpToDecision();
    return c;
  }

  /// Rebuilds a match from a recorded input log plus the host's recorded
  /// random draws, WITHOUT recomputing any randomness locally. This is how an
  /// online client (or a late joiner) reconstructs the authoritative game: it
  /// replays the host's exact rolls/events/picks. Because draw *order* is fully
  /// determined by the inputs, feeding the whole [randoms] list up front is
  /// enough — the client consumes it in lockstep.
  factory PartyController.replayWithRandoms({
    required PartyMode mode,
    required int totalRounds,
    required List<String> playerNames,
    required List<PartyInput> inputs,
    required List<int> randoms,
    GameMap? gameMap,
    bool wheels = true,
  }) {
    final c = PartyController(
      mode: mode,
      totalRounds: totalRounds,
      playerNames: playerNames,
      seed: 0, // unused: the client tape never touches Random
      randomMode: PartyRandomMode.client,
      gameMap: gameMap,
      wheels: wheels,
    );
    c.feedRandoms(randoms);
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

  /// How randomness is sourced for this match (see [PartyRandomMode]).
  final PartyRandomMode randomMode;

  /// Every random int the match consumes flows through here. For [host] it
  /// records the sequence ([recordedRandoms]); for [client] it replays a fed
  /// sequence ([feedRandoms]).
  late final RandomTape _tape;

  /// Ordered log of player decisions — the replayable record of the match.
  final List<PartyInput> inputLog = [];

  /// The board this match plays on. One of the three [GameMap]s when set;
  /// otherwise the legacy 52-space loop.
  final GameMap? gameMap;

  /// Whether the wheel system (opening/checkpoint/winner/final spins) runs.
  /// True for every new game; false only when replaying v1 saves recorded
  /// before the wheel existed, so their input logs stay aligned.
  final bool wheels;

  final List<PartyPlayer> players = [];
  late final List<BoardSpace> board = gameMap?.spaces ?? buildBoard();

  /// The mischief crew roaming this board (Peeler + Masher). Empty on the
  /// legacy loop; present on every [GameMap]. They rob the leader each round
  /// and players chase them down to recover the loot.
  final List<OpToken> ops = [];

  /// The Potato Shack ghosts. Empty until they're released after round 1;
  /// only on cinematic (wheels) games so v1 replays stay aligned.
  final List<GhostToken> ghosts = [];

  bool get ghostsLoose => ghosts.isNotEmpty;

  /// Map-aware section lookup — the new maps carry their own 8–10 sections, the
  /// legacy board uses the fixed [kBoardSections].
  BoardSection sectionOf(BoardSpace s) => gameMap?.sectionOf(s) ?? s.section;

  PartyPhase phase = PartyPhase.turnStart;
  int round = 1;
  int currentPlayerIndex = 0;
  TurnResult? lastTurn;

  /// The most recent landing's numeric consequence — the board's floating
  /// delta pop reads this. [LandingEffect.seq] increments on every landing
  /// that moves a total, so the UI detects a fresh effect even across
  /// lockstep replays. Derived purely from applied inputs: deterministic.
  LandingEffect? lastLanding;
  int _landingSeq = 0;

  /// Live wheel session (non-null exactly while [phase] == wheelSpin).
  WheelSession? wheel;

  /// Latest landed spin, for the wheel screen's deceleration + result toast.
  WheelResult? lastWheelResult;
  int _wheelSeq = 0;

  /// The card currently drawn on a cardCommon/cardWild tile — held while a
  /// decision card waits for the player's A/B choice, and shown on the reveal.
  Card? currentCard;

  /// Steps still to walk this turn; the UI calls [advanceStep] per tick.
  int stepsRemaining = 0;

  /// Pre-roll movement bought with ATP this turn (+2/+3); folded into the roll.
  int atpRollBonus = 0;

  /// Human-readable effect lines for the current turn (laps, purchases,
  /// space effects).
  final List<String> turnLog = [];

  /// Debug-only: forces every mini-game pick to this spec id.
  String? debugForcedSpecId;

  // Mini-game round state
  MiniGameSpec? currentSpec;
  final List<MiniGameStanding> standings = [];
  String? _lastSpecId;

  /// True on the final round when the map has a boss: the closing mini-game is
  /// the BOSS round — top scorer earns a potato, lowest scorer loses one.
  bool isBossRound = false;

  /// The boss op presiding over the current boss round (null otherwise).
  Op? get currentBoss => isBossRound && (gameMap?.bosses.isNotEmpty ?? false)
      ? gameMap!.bosses.first
      : null;

  PartyPlayer get currentPlayer => players[currentPlayerIndex];

  /// True once player [i] has banked a score in the current mini-game round.
  bool hasSubmittedMiniScore(int i) =>
      standings.any((s) => s.player.index == i);

  /// In local pass-and-play, the next player to hand the phone to — the lowest
  /// index that hasn't scored yet. Online every player plays at once on their
  /// own device, but this still resolves to the local player's pending attempt
  /// and drives the same intro/play screens.
  int get miniPlayerIndex {
    for (var i = 0; i < players.length; i++) {
      if (!hasSubmittedMiniScore(i)) return i;
    }
    return players.length - 1;
  }

  PartyPlayer get miniPlayer => players[miniPlayerIndex];

  /// True when exactly one player is still to score — used by the pass-phone
  /// screen to say "last up".
  bool get isLastMiniPlayer => standings.length == players.length - 1;

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

    final dice = [_tape.next(6) + 1, if (p.accelerator) _tape.next(6) + 1];
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
    if (atpRollBonus > 0) {
      bonus += atpRollBonus;
      turnLog.add('${p.name} channelled $atpRollBonus ATP into the roll.');
    }

    stepsRemaining = dice.reduce((a, b) => a + b) + bonus;
    if (p.loadedDice) {
      stepsRemaining *= 2;
      turnLog.add('LOADED DICE — the roll counts DOUBLE!');
      p.loadedDice = false;
    }
    lastTurn = TurnResult(
      playerIndex: p.index,
      dice: dice,
      rollBonus: bonus,
      steps: stepsRemaining,
      fromPosition: p.position,
    );
    // Dice are revealed on the roll-result panel; the player may spend 10 ATP
    // for +1 (reactive) before tapping MOVE.
    phase = PartyPhase.rollResult;
    notifyListeners();
    return lastTurn!;
  }

  /// Start of a player's turn: reset the pre-roll boost and trickle in energy.
  void _beginTurn() {
    atpRollBonus = 0;
    final p = currentPlayer;
    if (p.frozenTurns > 0) {
      // FREEZE RAY: sit this one out. Deterministic (no input), so replay and
      // lockstep sail through it; the narrator line is the player-facing beat.
      p.frozenTurns--;
      turnLog.add('${p.name} is FROZEN SOLID — turn skipped!');
      _endTurn();
      return;
    }
    p.atp += kAtpPerTurn;
  }

  /// Hands play to the next seat, or fires the round's mini-game after the
  /// last one. Shared by [confirmSpace] and the frozen-turn skip.
  void _endTurn() {
    if (currentPlayerIndex < players.length - 1) {
      currentPlayerIndex++;
      phase = PartyPhase.turnStart;
      _beginTurn();
    } else {
      _startMiniGameRound();
    }
  }

  /// Spend ATP to boost the roll. Before the roll (turnStart): +2 (15) or +3
  /// (20), folded into the upcoming roll. After it (rollResult): +1 (10),
  /// added to the steps you're about to walk. A logged decision.
  void useAtp(int plus) {
    final p = currentPlayer;
    if (phase == PartyPhase.turnStart) {
      if (plus != 2 && plus != 3) return;
      final cost = plus == 3 ? kAtpPlus3Cost : kAtpPlus2Cost;
      if (p.atp < cost) return;
      p.atp -= cost;
      atpRollBonus += plus;
    } else if (phase == PartyPhase.rollResult) {
      if (plus != 1 || p.atp < kAtpPlus1Cost) return;
      p.atp -= kAtpPlus1Cost;
      stepsRemaining += 1;
      final t = lastTurn;
      if (t != null) {
        lastTurn = TurnResult(
          playerIndex: t.playerIndex,
          dice: t.dice,
          rollBonus: t.rollBonus + 1,
          steps: stepsRemaining,
          fromPosition: t.fromPosition,
        );
      }
    } else {
      return;
    }
    inputLog.add(PartyInput(PartyInputKind.useAtp, plus));
    notifyListeners();
  }

  /// Leave the roll-result panel and start walking.
  void beginWalk() {
    assert(phase == PartyPhase.rollResult);
    inputLog.add(const PartyInput(PartyInputKind.beginWalk));
    phase = PartyPhase.moving;
    notifyListeners();
  }

  /// The choices at the current fork (only valid in [PartyPhase.chooseBranch]).
  List<int> get branchOptions => board[currentPlayer.position].nexts;

  /// Walks one space. Pauses for a branch choice when departing a fork.
  void advanceStep() {
    if (phase != PartyPhase.moving || stepsRemaining <= 0) return;
    final from = board[currentPlayer.position];
    // Linear maps end at the anchor (order 87, no successor): stop walking.
    if (from.nexts.isEmpty) {
      stepsRemaining = 0;
      _finishStep();
      return;
    }
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
    p.stepsTaken++;
    stepsRemaining--;
    _catchOps(p, next);
    // Lap bonus only on the legacy loop (the maps are linear, not a ring).
    if (gameMap == null && next == 0) {
      p.diamonds += 5;
      turnLog.add('${p.name} completed a lap of existence: +5 diamonds.');
    }
    // Passing (or landing on) a market with enough diamonds pauses the walk for
    // a purchase decision. Legacy uses the fixed shop index; maps use the type.
    final atShop = gameMap == null
        ? next == kShopIndex
        : board[next].type == SpaceType.shop;
    // Open the market if the player can afford anything on the shelf — a potato
    // or the cheapest item.
    if (atShop && p.diamonds >= kMinShopPrice) {
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
    p.diamonds -= kPotatoPrice;
    p.potatoes++;
    turnLog.add(
        '${p.name} bought a POTATO for $kPotatoPrice diamonds! (${p.potatoes} total)');
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
      // Ladders / snakes / rainbow slides relocate you on landing, then the
      // destination space resolves.
      final landed = board[p.position];
      if (landed.jumpTo != null) {
        final to = landed.jumpTo!;
        turnLog.add(to > p.position
            ? '${p.name} rode a lift up to ${to}!'
            : '${p.name} slipped back to ${to}.');
        p.position = to;
      }
      final beforeDiamonds = p.diamonds, beforePotatoes = p.potatoes;
      // Landing on a ghost's space costs diamonds before the space resolves
      // (folded into the same landing pop via the delta below).
      _hauntCheck(p, p.position, turnLog);
      _resolveSpace(p, board[p.position], turnLog);
      final dDiamonds = p.diamonds - beforeDiamonds;
      final dPotatoes = p.potatoes - beforePotatoes;
      if (dDiamonds != 0 || dPotatoes != 0) {
        lastLanding = LandingEffect(
          seq: ++_landingSeq,
          playerIndex: currentPlayerIndex,
          position: p.position,
          diamonds: dDiamonds,
          potatoes: dPotatoes,
        );
      }
      // A decision card pauses for the player's choice; otherwise the space is
      // resolved. _resolveSpace leaves the phase at [moving] unless it set a
      // pause (cardDecision), so only advance when it didn't.
      if (phase == PartyPhase.moving) {
        phase = PartyPhase.spaceResolved;
      }
    }
    notifyListeners();
  }

  /// Advance past the resolution panel: next player, or the mini-game round.
  void confirmSpace() {
    assert(phase == PartyPhase.spaceResolved);
    _endTurn();
    notifyListeners();
  }

  void _resolveSpace(PartyPlayer p, BoardSpace space, List<String> log) {
    switch (space.type) {
      case SpaceType.gain:
        p.diamonds += 5;
        log.add('${p.name} landed on a diamonds space: +5 diamonds.');
        break;
      case SpaceType.lose:
        if (p.voidShield) {
          p.voidShield = false;
          log.add("${p.name}'s VOID SHIELD absorbed the loss!");
        } else {
          p.diamonds = max(0, p.diamonds - 5);
          log.add('${p.name} hit an entropy space: −5 diamonds.');
        }
        break;
      case SpaceType.powerUp:
        _grantPowerUp(p, sectionOf(space), log);
        break;
      case SpaceType.event:
        _runEvent(p, log);
        break;
      case SpaceType.shop:
        // The purchase offer already fired while stepping in; landing here
        // just means the walk ended at the market.
        log.add('${p.name} is at the Potato Market '
            '(potatoes cost $kPotatoPrice diamonds).');
        break;
      case SpaceType.cardCommon:
        _drawCard(p, CardDeck.common, log);
        break;
      case SpaceType.cardWild:
        _drawCard(p, CardDeck.wild, log);
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
    // Targeted items need a victim — they go through [useItemOn].
    if (item == PowerUp.freezeRay || item == PowerUp.swapper) return;
    final p = currentPlayer;
    if (!p.items.remove(item)) return; // not in the pack
    inputLog.add(PartyInput(PartyInputKind.useItem, item.index));
    switch (item) {
      case PowerUp.spark:
        p.diamonds += 4;
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
      case PowerUp.loadedDice:
        p.loadedDice = true;
        break;
      case PowerUp.freezeRay:
      case PowerUp.swapper:
        break; // unreachable: guarded above, targeted use only
    }
    p.itemsUsed++;
    notifyListeners();
  }

  /// Spends a TARGETED item (freeze ray / swapper) on [target]'s seat, on the
  /// current player's turn. STRONG BOND on the target blocks it (and is
  /// consumed). A logged decision: value = item.index * 16 + target.
  void useItemOn(PowerUp item, int target) {
    assert(phase == PartyPhase.turnStart);
    if (item != PowerUp.freezeRay && item != PowerUp.swapper) return;
    if (target < 0 || target >= players.length) return;
    if (target == currentPlayerIndex) return;
    final p = currentPlayer;
    if (!p.items.remove(item)) return; // not in the pack
    inputLog.add(PartyInput(PartyInputKind.useItemOn, item.index * 16 + target));
    p.itemsUsed++;
    final t = players[target];
    if (t.strongBond) {
      t.strongBond = false;
      turnLog.add("${t.name}'s STRONG BOND shrugged off ${p.name}'s "
          '${item.label}!');
      notifyListeners();
      return;
    }
    t.stolenFromCount++; // aggression economy: feeds Most Stolen-From
    switch (item) {
      case PowerUp.freezeRay:
        t.frozenTurns++;
        turnLog.add('${p.name} FROZE ${t.name} — they lose a turn!');
        break;
      case PowerUp.swapper:
        final a = p.position;
        p.position = t.position;
        t.position = a;
        turnLog.add('${p.name} SWAPPED places with ${t.name}!');
        break;
      default:
        break;
    }
    notifyListeners();
  }

  void _runEvent(PartyPlayer p, List<String> log) {
    final others = players.where((o) => o.index != p.index).toList();
    switch (_tape.next(5)) {
      case 0: // Cosmic Swap
        final target = others[_tape.next(others.length)];
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
            o.diamonds = max(0, o.diamonds - loss);
          }
        }
        log.add(
            'ENTROPY SURGE! Everyone loses 3 diamonds, the leader loses 6.');
        break;
      case 2: // Photosynthesis
        for (final o in players) {
          o.diamonds += 3;
        }
        log.add('PHOTOSYNTHESIS! Everyone gains +3 diamonds.');
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

  /// Leader = most potatoes, diamonds breaks ties.
  bool _isLeader(PartyPlayer p) {
    for (final o in players) {
      if (o.potatoes > p.potatoes ||
          (o.potatoes == p.potatoes && o.diamonds > p.diamonds)) {
        return false;
      }
    }
    return true;
  }

  // ------------------------------------------------------------------- ops

  /// Whoever the ops prey on — the current leader (rubber-band: the crew robs
  /// from the front). Deterministic, so replay reproduces the victim.
  PartyPlayer? _opVictim() {
    if (players.isEmpty) return null;
    return players.reduce((a, b) => (b.potatoes > a.potatoes ||
            (b.potatoes == a.potatoes && b.diamonds > a.diamonds))
        ? b
        : a);
  }

  /// Run the mischief crew's turn: each op robs the leader and relocates,
  /// carrying the loot for players to chase. Called once at the top of each new
  /// round. The relocation tile comes off the tape so online stays in sync.
  void _runOps(List<String> log) {
    for (final t in ops) {
      final victim = _opVictim();
      if (victim != null) {
        if (t.op.id == kMasher.id &&
            victim.potatoes > 0 &&
            !victim.strongBond) {
          victim.potatoes--;
          t.potatoes++;
          victim.stolenFromCount++;
          log.add('${t.op.name} mashed a POTATO out of ${victim.name}!');
        } else if (victim.strongBond) {
          victim.strongBond = false;
          log.add('${victim.name}\'s STRONG BOND fended off ${t.op.name}.');
        } else {
          final take = min(victim.diamonds, 10);
          if (take > 0) {
            victim.diamonds -= take;
            t.diamonds += take;
            victim.stolenFromCount++;
            log.add('${t.op.name} skimmed $take diamonds from ${victim.name}!');
          }
        }
      }
      // Slink off to a new tile, loot in hand — go catch them.
      t.position = _tape.next(board.length);
    }
  }

  /// A player landing on (or passing through) an op's tile snatches back its
  /// whole stash. Pure transfer — deterministic, no tape draw.
  void _catchOps(PartyPlayer p, int tile) {
    for (final t in ops) {
      if (t.position != tile || !t.hasLoot) continue;
      if (t.diamonds > 0) {
        p.diamonds += t.diamonds;
        turnLog.add(
            '${p.name} caught ${t.op.name} — recovered ${t.diamonds} diamonds!');
        t.diamonds = 0;
      }
      if (t.potatoes > 0) {
        p.potatoes += t.potatoes;
        turnLog.add(
            '${p.name} wrenched ${t.potatoes} potato back from ${t.op.name}!');
        t.potatoes = 0;
      }
    }
  }

  // ---------------------------------------------------------------- ghosts

  static const int _kGhostCount = 2;
  static const int _kGhostBite = 6; // diamonds a haunting costs (max)

  /// Round boundary: release the ghosts after round 1 (cinematic games only),
  /// then let them drift strangely — a few spaces of drift, with the odd
  /// clean teleport. Every position comes off the tape for lockstep.
  void _runGhosts(List<String> log) {
    if (!wheels) return;
    if (ghosts.isEmpty) {
      if (round == 2) {
        for (var i = 0; i < _kGhostCount; i++) {
          ghosts.add(GhostToken(_tape.next(board.length)));
        }
        log.add('uhhh… did you hear that? THE GHOSTS FROM THE POTATO '
            'SHACK ARE ON THE LOOSE!');
      }
      return;
    }
    for (final g in ghosts) {
      if (_tape.next(5) == 0) {
        g.position = _tape.next(board.length); // phase through the void
      } else {
        g.position = (g.position + _tape.next(7) + 2) % board.length;
      }
    }
    log.add('The ghosts drift across the board…');
  }

  /// Landing on a ghost's space costs diamonds (VOID SHIELD blocks it); the
  /// spooked ghost immediately phases elsewhere.
  void _hauntCheck(PartyPlayer p, int tile, List<String> log) {
    for (final g in ghosts) {
      if (g.position != tile) continue;
      if (p.voidShield) {
        p.voidShield = false;
        log.add("${p.name}'s VOID SHIELD glowed — the ghost fled!");
      } else {
        final take = min(p.diamonds, _kGhostBite);
        if (take > 0) {
          p.diamonds -= take;
          p.stolenFromCount++;
          log.add('A GHOST got ${p.name} — $take diamonds haunted back '
              'to the Shack!');
        } else {
          log.add('A ghost passed straight through ${p.name}. Chilling.');
        }
      }
      g.position = _tape.next(board.length);
    }
  }

  // ----------------------------------------------------------------- cards

  /// Draws from the common (Tater) or wild (Void) deck and applies it. A
  /// decision card pauses in [PartyPhase.cardDecision] for the player's A/B
  /// pick; every other card resolves immediately. The draw index comes off the
  /// tape so host and clients land on the same card.
  void _drawCard(PartyPlayer p, CardDeck deck, List<String> log) {
    final cards = deck == CardDeck.wild ? kWildDeck : kCommonDeck;
    final card = cards[_tape.next(cards.length)];
    currentCard = card;
    final deckName = deck == CardDeck.wild ? 'VOID CARD' : 'TATER CARD';
    log.add('$deckName — ${card.title}: ${card.text}');
    if (card.isDecision) {
      phase = PartyPhase.cardDecision; // _finishStep leaves this in place
      return;
    }
    _applyCardEffects(p, card.effects, log);
  }

  /// Resolves a decision card: the player chose option [i].
  void chooseCardOption(int i) {
    assert(phase == PartyPhase.cardDecision);
    final card = currentCard;
    if (card == null || i < 0 || i >= card.options.length) return;
    inputLog.add(PartyInput(PartyInputKind.chooseCardOption, i));
    turnLog.add('${currentPlayer.name} chose: ${card.options[i].label}.');
    _applyCardEffects(currentPlayer, card.options[i].effects, turnLog);
    phase = PartyPhase.spaceResolved;
    notifyListeners();
  }

  void _applyCardEffects(
      PartyPlayer p, List<CardEffect> effects, List<String> log) {
    for (final e in effects) {
      _applyOneEffect(p, e, log);
    }
  }

  void _applyOneEffect(PartyPlayer p, CardEffect e, List<String> log) {
    final others = players.where((o) => o.index != p.index).toList();
    switch (e.kind) {
      case EffectKind.gainPaydirt:
      case EffectKind.gainDiamonds:
        p.diamonds += e.amount;
        log.add('${p.name} +${e.amount} diamonds.');
        break;
      case EffectKind.losePaydirt:
      case EffectKind.loseDiamonds:
        final loss = min(p.diamonds, e.amount);
        p.diamonds -= loss;
        log.add('${p.name} −$loss diamonds.');
        break;
      case EffectKind.tithe:
        var total = 0;
        for (final o in others) {
          final t = (o.diamonds * e.amount / 100).floor();
          o.diamonds -= t;
          total += t;
        }
        p.diamonds += total;
        log.add('${p.name} collects $total diamonds in tithe.');
        break;
      case EffectKind.allLoseDiamonds:
        for (final o in players) {
          o.diamonds -= (o.diamonds * e.amount / 100).floor();
        }
        log.add('A void opens — everyone loses ${e.amount}% of their diamonds.');
        break;
      case EffectKind.gainItem:
        final n = e.amount <= 0 ? 1 : e.amount;
        for (var i = 0; i < n; i++) {
          _grantRandomItem(p, log);
        }
        break;
      case EffectKind.loseItem:
        if (p.items.isNotEmpty) {
          final it = p.items.removeAt(_tape.next(p.items.length));
          log.add('${p.name} loses their ${it.label}.');
        }
        break;
      case EffectKind.stealItem:
        final haves = others.where((o) => o.items.isNotEmpty).toList();
        if (p.items.length >= kMaxItems || haves.isEmpty) {
          log.add('The Peeler finds nothing to lift.');
        } else {
          final victim = haves[_tape.next(haves.length)];
          if (victim.strongBond) {
            victim.strongBond = false;
            log.add("${victim.name}'s STRONG BOND blocks the heist!");
          } else {
            final it = victim.items.removeAt(_tape.next(victim.items.length));
            p.items.add(it);
            victim.stolenFromCount++;
            log.add('${p.name} lifts a ${it.label} from ${victim.name}!');
          }
        }
        break;
      case EffectKind.gainAtp:
        p.atp += e.amount;
        log.add('${p.name} +${e.amount} ATP.');
        break;
      case EffectKind.move:
        _cardMove(p, e.amount, log);
        break;
      case EffectKind.teleport:
        p.position = e.amount == 1 ? board.length - 1 : 0;
        log.add('${p.name} teleports to '
            '${e.amount == 1 ? 'the anchor' : 'the start'}.');
        break;
      case EffectKind.swapPaydirt:
        if (others.isNotEmpty) {
          final t = others[_tape.next(others.length)];
          if (t.strongBond) {
            t.strongBond = false;
            log.add("${t.name}'s STRONG BOND holds — no swap.");
          } else {
            final tmp = p.diamonds;
            p.diamonds = t.diamonds;
            t.diamonds = tmp;
            log.add('${p.name} swaps diamonds with ${t.name}.');
          }
        }
        break;
      case EffectKind.setEqualToLeader:
        final lead = players.reduce((a, b) => (b.potatoes > a.potatoes ||
                (b.potatoes == a.potatoes && b.diamonds > a.diamonds))
            ? b
            : a);
        p.diamonds = lead.diamonds;
        log.add('${p.name} mirrors the leader: ${lead.diamonds} diamonds.');
        break;
      case EffectKind.coinFlip:
        if (_tape.next(2) == 0) {
          log.add('Coin-flip — WIN!');
          _applyCardEffects(p, e.win, log);
        } else {
          log.add('Coin-flip — lose.');
          _applyCardEffects(p, e.lose, log);
        }
        break;
      case EffectKind.gainPotato:
        p.potatoes++;
        log.add('${p.name} gains a POTATO!');
        break;
      case EffectKind.losePotato:
        if (p.potatoes > 0) {
          p.potatoes--;
          log.add('${p.name} loses a potato.');
        }
        break;
    }
  }

  void _grantRandomItem(PartyPlayer p, List<String> log) {
    if (p.items.length >= kMaxItems) {
      log.add("${p.name}'s pack is full — no room for the item.");
      return;
    }
    final it = kItemShop[_tape.next(kItemShop.length)];
    p.items.add(it);
    log.add('${p.name} gains a ${it.label}.');
  }

  void _cardMove(PartyPlayer p, int delta, List<String> log) {
    if (delta >= 0) {
      for (var i = 0; i < delta; i++) {
        final n = board[p.position].nexts;
        if (n.isEmpty) break;
        p.position = n.first;
      }
    } else {
      p.position = gameMap == null
          ? (p.position + delta + kMainLoopLength) % kMainLoopLength
          : max(0, p.position + delta);
    }
    log.add('${p.name} moves ${delta >= 0 ? 'forward' : 'back'} ${delta.abs()}.');
  }

  /// Buys one held item at the market (alongside the potato purchase), then the
  /// walk continues. A logged decision so replay stays faithful.
  void buyItem(PowerUp item) {
    assert(phase == PartyPhase.shopOffer);
    final p = currentPlayer;
    final price = kItemPrices[item] ?? 999;
    if (p.diamonds < price || p.items.length >= kMaxItems) return;
    inputLog.add(PartyInput(PartyInputKind.buyItem, item.index));
    p.diamonds -= price;
    p.items.add(item);
    turnLog.add('${p.name} bought ${item.label} for $price diamonds.');
    phase = PartyPhase.moving;
    _finishStep();
  }

  // ------------------------------------------------------------- mini-games

  void _startMiniGameRound() {
    currentSpec = _pickSpec();
    _lastSpecId = currentSpec!.id;
    standings.clear();
    // The closing round is the boss showdown when the map fields a boss.
    isBossRound = round >= totalRounds && (gameMap?.bosses.isNotEmpty ?? false);
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
    return pool[_tape.next(pool.length)];
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

  /// Banks one player's mini-game score. [player] defaults to the local
  /// pending attempt ([miniPlayerIndex]) for pass-and-play; online it's set
  /// explicitly so simultaneous submissions land on the right author in any
  /// arrival order. Each player scores at most once per round; the round
  /// resolves once everyone has a score.
  void recordMiniScore(int score, {int? player}) {
    assert(phase == PartyPhase.minigamePlaying ||
        phase == PartyPhase.passPhone);
    final idx = player ?? miniPlayerIndex;
    if (hasSubmittedMiniScore(idx)) return; // one score per player per round
    inputLog.add(PartyInput(PartyInputKind.miniScore, score, idx));
    standings.add(MiniGameStanding(players[idx], score));
    if (standings.length >= players.length) {
      _scoreMiniGameRound();
      phase = PartyPhase.minigameResults;
    } else {
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
      s.player.diamonds += s.award;
    }
    // Round win/loss tallies (feed the end-game "Most Round Wins"/"Most L's"
    // awards and the ceremony's winner declaration). On an all-tie everyone
    // shares the win and nobody takes an L.
    var worstRank = 0;
    for (final s in standings) {
      if (s.rank > worstRank) worstRank = s.rank;
    }
    for (final s in standings) {
      if (s.rank == 0) s.player.roundWins++;
      if (worstRank > 0 && s.rank == worstRank) s.player.roundLosses++;
    }
    if (isBossRound) _applyBossPotatoes();
  }

  /// Boss-round stakes: the top scorer(s) earn a potato; the lowest scorer(s)
  /// lose one (never below zero). On an all-tie, everyone shares the top and no
  /// one loses. Deterministic from the standings, so replay needs no extra draw.
  void _applyBossPotatoes() {
    if (standings.isEmpty) return;
    final top =
        standings.map((s) => s.score).reduce((a, b) => a > b ? a : b);
    final bottom =
        standings.map((s) => s.score).reduce((a, b) => a < b ? a : b);
    for (final s in standings) {
      if (s.score == top) {
        s.player.potatoes++;
      } else if (top != bottom && s.score == bottom) {
        s.player.potatoes = max(0, s.player.potatoes - 1);
      }
    }
  }

  /// Past the round ceremony: next round, or game over. A real logged input
  /// since the ceremony became a genuine decision phase (the pump used to
  /// auto-confirm it, which skipped the results entirely online).
  void confirmMiniGameResults() {
    assert(phase == PartyPhase.minigameResults);
    inputLog.add(const PartyInput(PartyInputKind.confirmResults));
    // The round's winners, captured before standings clear next round —
    // they earn the winner spin on the maps that run one.
    final winners = [
      for (final s in standings)
        if (s.rank == 0) s.player.index
    ];
    if (round >= totalRounds) {
      if (wheels) {
        _startWheel(WheelTier.finale, _allSeats);
      } else {
        phase = PartyPhase.gameOver;
      }
    } else {
      round++;
      turnLog.clear();
      _runOps(turnLog); // the crew robs the leader and scatters the loot
      _runGhosts(turnLog);
      currentPlayerIndex = 0;
      if (wheels && _mapHasWinnerSpins && winners.isNotEmpty) {
        _startWheel(WheelTier.winner, winners);
      } else if (wheels && _checkpointDue) {
        _startWheel(WheelTier.checkpoint, _allSeats);
      } else {
        phase = PartyPhase.turnStart;
        _beginTurn();
      }
    }
    notifyListeners();
  }

  // ------------------------------------------------------------------ wheel

  List<int> get _allSeats => [for (var i = 0; i < players.length; i++) i];

  /// Checkpoint spins land every [kWheelCheckpointEvery] rounds: 5, 9, 13…
  bool get _checkpointDue =>
      round > 1 && (round - 1) % kWheelCheckpointEvery == 0;

  /// Winner spins run on every board except INTO THE VOID (that map wants
  /// less wheel — PARTY_CINEMATIC_SPEC §2).
  bool get _mapHasWinnerSpins =>
      gameMap == null || gameMap!.id != 'into_the_void';

  void _startWheel(WheelTier tier, List<int> spinners) {
    if (spinners.isEmpty) {
      _exitWheel(tier);
      return;
    }
    wheel = WheelSession(tier, List.of(spinners));
    phase = PartyPhase.wheelSpin;
  }

  /// The current spinner stops the wheel. The stop is the logged input; the
  /// landed segment comes off the random tape, so every client agrees while
  /// the tap still feels like the player's own.
  void wheelStop() {
    assert(phase == PartyPhase.wheelSpin);
    final w = wheel!;
    inputLog.add(const PartyInput(PartyInputKind.wheelStop));
    final table = wheelTableFor(w.tier);
    final idx = _drawSegment(table);
    final p = players[w.currentSpinner];
    final summary = _applyWheelPrize(p, table[idx]);
    lastWheelResult = WheelResult(
      seq: ++_wheelSeq,
      tier: w.tier,
      spinner: w.currentSpinner,
      segmentIndex: idx,
      summary: summary,
    );
    turnLog.add(summary);
    w.queue.removeAt(0);
    if (w.queue.isEmpty) {
      wheel = null;
      _exitWheel(w.tier);
    }
    notifyListeners();
  }

  void _exitWheel(WheelTier tier) {
    switch (tier) {
      case WheelTier.opening:
      case WheelTier.checkpoint:
        phase = PartyPhase.turnStart;
        _beginTurn();
        break;
      case WheelTier.winner:
        if (_checkpointDue) {
          _startWheel(WheelTier.checkpoint, _allSeats);
        } else {
          phase = PartyPhase.turnStart;
          _beginTurn();
        }
        break;
      case WheelTier.finale:
        phase = PartyPhase.gameOver;
        break;
    }
  }

  int _drawSegment(List<WheelSegment> table) {
    var total = 0;
    for (final s in table) {
      total += s.weight;
    }
    var r = _tape.next(total);
    for (var i = 0; i < table.length; i++) {
      r -= table[i].weight;
      if (r < 0) return i;
    }
    return table.length - 1;
  }

  String _applyWheelPrize(PartyPlayer p, WheelSegment seg) {
    switch (seg.kind) {
      case WheelPrizeKind.item:
        return _wheelGrantItem(p, seg.item!);
      case WheelPrizeKind.randomItem:
        final item = kWheelItemPool[_tape.next(kWheelItemPool.length)];
        return _wheelGrantItem(p, item);
      case WheelPrizeKind.diamonds:
        p.diamonds += seg.amount;
        return '${p.name} spun +${seg.amount} diamonds!';
      case WheelPrizeKind.loseDiamonds:
        p.diamonds = max(0, p.diamonds - seg.amount);
        return '${p.name} spun −${seg.amount} diamonds. Brutal.';
      case WheelPrizeKind.atp:
        p.atp += seg.amount;
        return '${p.name} spun +${seg.amount} ATP!';
      case WheelPrizeKind.potatoes:
        p.potatoes += seg.amount;
        return seg.amount > 1
            ? '${p.name} spun ${seg.amount} WHOLE POTATOES!!'
            : '${p.name} spun a WHOLE POTATO!';
      case WheelPrizeKind.dropItem:
        if (p.items.isEmpty) {
          p.diamonds = max(0, p.diamonds - 3);
          return '${p.name} had no item to drop — −3 diamonds instead.';
        }
        final dropped = p.items.removeAt(0);
        return '${p.name} dropped ${dropped.label}!';
    }
  }

  String _wheelGrantItem(PartyPlayer p, PowerUp item) {
    if (p.items.length >= kMaxItems) {
      p.diamonds += 5;
      return "${p.name}'s pack is full — ${item.label} became +5 diamonds.";
    }
    p.items.add(item);
    return '${p.name} won ${item.label} — ${item.description}.';
  }

  // ---------------------------------------------------------------- results

  /// Final placements, best first: potatoes, then diamonds, then position.
  List<PartyPlayer> get finalPlayerRanking {
    final sorted = [...players]..sort((a, b) {
        if (b.potatoes != a.potatoes) return b.potatoes.compareTo(a.potatoes);
        if (b.diamonds != a.diamonds) return b.diamonds.compareTo(a.diamonds);
        return b.position.compareTo(a.position);
      });
    return sorted;
  }

  /// Team totals, best first.
  List<TeamStanding> get finalTeamRanking {
    final potatoes = <int, int>{};
    final diamonds = <int, int>{};
    for (final p in players) {
      potatoes[p.teamIndex] = (potatoes[p.teamIndex] ?? 0) + p.potatoes;
      diamonds[p.teamIndex] = (diamonds[p.teamIndex] ?? 0) + p.diamonds;
    }
    final standings = [
      for (final team in potatoes.keys)
        TeamStanding(team, potatoes[team]!, diamonds[team]!),
    ]..sort((a, b) {
        if (b.potatoes != a.potatoes) return b.potatoes.compareTo(a.potatoes);
        return b.diamonds.compareTo(a.diamonds);
      });
    return standings;
  }

  // ------------------------------------------------------------- replay core

  /// Applies one recorded decision. The controller must already be sitting in
  /// the phase that decision belongs to (see [_pumpToDecision]).
  void _apply(PartyInput input) {
    // Compat: logs recorded before confirmResults existed relied on the pump
    // auto-confirming the results phase. When such a log presents any other
    // input while we're holding on the ceremony, confirm first (this also
    // re-logs the synthetic confirm identically on every replayer).
    if (phase == PartyPhase.minigameResults &&
        input.kind != PartyInputKind.confirmResults) {
      confirmMiniGameResults();
    }
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
        recordMiniScore(input.value, player: input.player);
        break;
      case PartyInputKind.useItem:
        useItem(PowerUp.values[input.value]);
        break;
      case PartyInputKind.useAtp:
        useAtp(input.value);
        break;
      case PartyInputKind.beginWalk:
        beginWalk();
        break;
      case PartyInputKind.chooseCardOption:
        chooseCardOption(input.value);
        break;
      case PartyInputKind.buyItem:
        buyItem(PowerUp.values[input.value]);
        break;
      case PartyInputKind.confirmResults:
        confirmMiniGameResults();
        break;
      case PartyInputKind.wheelStop:
        wheelStop();
        break;
      case PartyInputKind.useItemOn:
        useItemOn(PowerUp.values[input.value ~/ 16], input.value % 16);
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
        case PartyPhase.turnStart:
        case PartyPhase.rollResult:
        case PartyPhase.chooseBranch:
        case PartyPhase.shopOffer:
        case PartyPhase.cardDecision:
        case PartyPhase.minigamePlaying:
        // The round ceremony is a genuine decision phase: it holds until a
        // confirmResults input (local tap, or the online host's tap /
        // auto-dwell) so every client actually sees the results.
        case PartyPhase.minigameResults:
        // Each spinner's STOP is a genuine input too.
        case PartyPhase.wheelSpin:
        case PartyPhase.gameOver:
          return;
      }
    }
    throw StateError('soft-lock: no decision reachable from $phase');
  }

  // ------------------------------------------------------- host/client tape

  /// The host's recorded random draws so far, in consumption order. Published
  /// to clients alongside the input log. Empty unless [randomMode] is
  /// [PartyRandomMode.host].
  List<int> get recordedRandoms => List.unmodifiable(_tape.recorded);

  /// Feeds host-authored random draws into a [PartyRandomMode.client] tape so
  /// subsequent inputs replay the host's exact outcomes. Append-only; safe to
  /// call repeatedly as more draws arrive over the wire.
  void feedRandoms(Iterable<int> values) {
    final tape = _tape;
    if (tape is! _ReplayTape) {
      throw StateError('feedRandoms is only valid for a client-mode match');
    }
    tape.feed(values);
  }

  /// Fast-forwards deterministic transitions (walking, result panels, the
  /// mini-game intro/results) until the match is waiting on a genuine decision.
  /// The host calls this to settle its authoritative controller between
  /// processed requests, drawing and recording any randomness along the way.
  void advanceToDecision() {
    _pumpToDecision();
    notifyListeners();
  }

  /// Applies one host-authored decision to a client-mode match, fast-forwarding
  /// the deterministic transitions around it (mirrors the replay loop body).
  /// Any random draws this input triggers must already be fed via
  /// [feedRandoms]. This is how an online client advances in lockstep with the
  /// host's canonical input log.
  void applyNetworkInput(PartyInput input) {
    _pumpToDecision();
    if (phase == PartyPhase.gameOver) {
      notifyListeners();
      return;
    }
    _apply(input);
    _pumpToDecision();
    notifyListeners();
  }

  /// Throws on any broken-game invariant. Cheap enough to call after every
  /// input; this is the contract the Peeler soak will hold the game to.
  void checkInvariants() {
    for (final p in players) {
      if (p.position < 0 || p.position >= board.length) {
        throw StateError('${p.name} position out of range: ${p.position}');
      }
      if (p.diamonds < 0) throw StateError('${p.name} has negative diamonds');
      if (p.atp < 0) throw StateError('${p.name} has negative ATP');
      if (p.potatoes < 0) throw StateError('${p.name} has negative potatoes');
    }
    if (round < 1 || round > totalRounds) {
      throw StateError('round out of range: $round');
    }
  }

  /// The whole match as a tiny, refactor-proof save: seed + setup + decisions.
  Map<String, dynamic> toSaveJson() => {
        // v2 = played with the wheel system; v1 (or absent, pre-wheel builds)
        // replays with wheels off so old input logs stay aligned.
        'v': wheels ? 2 : 1,
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
        wheels: ((json['v'] as int?) ?? 1) >= 2,
        inputs: [
          for (final e in (json['inputs'] as List))
            PartyInput.fromJson(Map<String, dynamic>.from(e as Map))
        ],
      );
}

/// Source of every random int a match consumes (dice, board events, mini-game
/// picks). Abstracting it is what lets online play be host-authoritative: the
/// host records its draws and clients replay them, so no one relies on
/// `Random(seed)` producing identical sequences across web and mobile.
abstract class RandomTape {
  /// Next random int in `[0, max)`.
  int next(int max);

  /// Whether [count] more values can be served without blocking. Always true
  /// for local/host tapes; a client tape returns false when it has run out of
  /// fed values (it is waiting on the host).
  bool hasAtLeast(int count);

  /// Draws recorded so far, in order (host tape only; empty otherwise).
  List<int> get recorded;
}

/// Local and host tape: draws from a seeded [Random]. When [record] is set
/// (host), each draw is also kept so the sequence can be published.
class _SeededTape implements RandomTape {
  _SeededTape(this._rng, {this.record = false});

  final Random _rng;
  final bool record;
  final List<int> _recorded = [];

  @override
  int next(int max) {
    final v = _rng.nextInt(max);
    if (record) _recorded.add(v);
    return v;
  }

  @override
  bool hasAtLeast(int count) => true;

  @override
  List<int> get recorded => _recorded;
}

/// Client tape: replays the host's recorded draws verbatim and never touches
/// [Random]. The stored values were already reduced by the host's `max`, and
/// because the client runs the same code over the same inputs it consumes them
/// in the same order, so [max] here is only a sanity bound.
class _ReplayTape implements RandomTape {
  final List<int> _values = [];
  int _cursor = 0;

  void feed(Iterable<int> values) => _values.addAll(values);

  @override
  int next(int max) {
    if (_cursor >= _values.length) {
      throw StateError(
          'random tape starved: client outran the host (need draw '
          '${_cursor + 1}, have ${_values.length})');
    }
    return _values[_cursor++];
  }

  @override
  bool hasAtLeast(int count) => _values.length - _cursor >= count;

  @override
  List<int> get recorded => List.unmodifiable(_values);
}
