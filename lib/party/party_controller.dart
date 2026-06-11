import 'dart:math';

import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/games/mini_game_registry.dart';
import 'package:flutter/foundation.dart';

import 'party_models.dart';

enum PartyPhase {
  turnStart, // current player's banner + ROLL button
  moving, // page animates the token using the latest TurnResult
  spaceResolved, // effect shown, waiting for CONTINUE
  minigameIntro, // round's game revealed
  passPhone, // hand the phone to the next contestant
  minigamePlaying, // MiniGameHost active
  minigameResults, // ranking + ATP awards
  gameOver,
}

/// Everything that happened in one roll, so the UI can animate it.
class TurnResult {
  final int playerIndex;
  final List<int> dice;
  final int rollBonus; // mitochondria
  final int steps;
  final int fromPosition;
  final int toPosition;
  final bool lapCompleted;
  final List<String> log; // human-readable effect lines

  const TurnResult({
    required this.playerIndex,
    required this.dice,
    required this.rollBonus,
    required this.steps,
    required this.fromPosition,
    required this.toPosition,
    required this.lapCompleted,
    required this.log,
  });
}

class MiniGameStanding {
  final PartyPlayer player;
  final int score;
  int rank = 0;
  int award = 0;
  MiniGameStanding(this.player, this.score);
}

/// Pass-and-play board game loop: each round every player rolls and resolves
/// a space, then everyone plays the same mini-game and ATP is awarded by
/// rank. Most ATP after the final round wins (team total in team modes).
class PartyController extends ChangeNotifier {
  PartyController({
    required this.mode,
    required this.totalRounds,
    required List<String> playerNames,
    Random? random,
  }) : _rng = random ?? Random() {
    for (var i = 0; i < mode.playerCount; i++) {
      players.add(PartyPlayer(
        index: i,
        name: playerNames[i],
        color: kCharacters[i].color,
        teamIndex: mode.teamOf(i),
      ));
    }
  }

  final PartyMode mode;
  final int totalRounds;
  final Random _rng;
  final List<PartyPlayer> players = [];
  final List<BoardSpace> board = buildBoard();

  PartyPhase phase = PartyPhase.turnStart;
  int round = 1;
  int currentPlayerIndex = 0;
  TurnResult? lastTurn;

  // Mini-game round state
  MiniGameSpec? currentSpec;
  int miniPlayerIndex = 0;
  final List<MiniGameStanding> standings = [];
  String? _lastSpecId;

  PartyPlayer get currentPlayer => players[currentPlayerIndex];
  PartyPlayer get miniPlayer => players[miniPlayerIndex];
  bool get isLastMiniPlayer => miniPlayerIndex >= players.length - 1;

  // ---------------------------------------------------------------- rolling

  /// Rolls for the current player, resolves the landing space, and moves to
  /// [PartyPhase.moving]. The UI animates from the returned TurnResult, then
  /// calls [confirmSpace].
  TurnResult roll() {
    assert(phase == PartyPhase.turnStart);
    final p = currentPlayer;
    final log = <String>[];

    final dice = [_rng.nextInt(6) + 1, if (p.accelerator) _rng.nextInt(6) + 1];
    if (p.accelerator) {
      log.add('${p.name} fired the ACCELERATOR — two dice!');
      p.accelerator = false;
    }
    var bonus = 0;
    if (p.mitochondria) {
      bonus = 3;
      log.add('MITOCHONDRIA kicks in: +3 movement.');
      p.mitochondria = false;
    }

    final int steps = dice.reduce((a, b) => a + b) + bonus;
    final from = p.position;
    final int to = (from + steps) % board.length;
    final lap = from + steps >= board.length;
    p.position = to;

    if (lap) {
      p.atp += 5;
      log.add('${p.name} completed a lap of existence: +5 ATP.');
    }
    _resolveSpace(p, board[to], log);

    lastTurn = TurnResult(
      playerIndex: p.index,
      dice: dice,
      rollBonus: bonus,
      steps: steps,
      fromPosition: from,
      toPosition: to,
      lapCompleted: lap,
      log: log,
    );
    phase = PartyPhase.moving;
    notifyListeners();
    return lastTurn!;
  }

  /// UI finished the token animation; show the resolution panel.
  void markMoved() {
    if (phase != PartyPhase.moving) return;
    phase = PartyPhase.spaceResolved;
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
        p.atp += 5;
        log.add('${p.name} landed on an energy space: +5 ATP.');
        break;
      case SpaceType.lose:
        if (p.voidShield) {
          p.voidShield = false;
          log.add("${p.name}'s VOID SHIELD absorbed the loss!");
        } else {
          p.atp = max(0, p.atp - 5);
          log.add('${p.name} hit an entropy space: −5 ATP.');
        }
        break;
      case SpaceType.powerUp:
        _grantPowerUp(p, space.section, log);
        break;
      case SpaceType.event:
        _runEvent(p, log);
        break;
    }
  }

  void _grantPowerUp(PartyPlayer p, BoardSection section, List<String> log) {
    final pu = section.powerUp;
    log.add('${section.name} power-up: ${pu.label} — ${pu.description}.');
    switch (pu) {
      case PowerUp.voidShield:
        p.voidShield = true;
        break;
      case PowerUp.spark:
        p.atp += 4;
        break;
      case PowerUp.accelerator:
        p.accelerator = true;
        break;
      case PowerUp.strongBond:
        p.strongBond = true;
        break;
      case PowerUp.catalyst:
        p.catalyst = true;
        break;
      case PowerUp.mitochondria:
        p.mitochondria = true;
        break;
    }
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
            o.atp = max(0, o.atp - loss);
          }
        }
        log.add('ENTROPY SURGE! Everyone loses 3 ATP, the leader loses 6.');
        break;
      case 2: // Photosynthesis
        for (final o in players) {
          o.atp += 3;
        }
        log.add('PHOTOSYNTHESIS! Everyone gains +3 ATP.');
        break;
      case 3: // Wormhole
        p.position = (p.position + 5) % board.length;
        log.add('WORMHOLE! ${p.name} jumps forward 5 spaces.');
        break;
      default: // Quantum Tunnel
        p.position = (p.position - 4 + board.length) % board.length;
        log.add('QUANTUM TUNNEL! ${p.name} slips back 4 spaces.');
        break;
    }
  }

  bool _isLeader(PartyPlayer p) {
    final maxAtp = players.map((o) => o.atp).reduce(max);
    return p.atp == maxAtp;
  }

  // ------------------------------------------------------------- mini-games

  void _startMiniGameRound() {
    currentSpec = _pickSpec();
    _lastSpecId = currentSpec!.id;
    miniPlayerIndex = 0;
    standings.clear();
    phase = PartyPhase.minigameIntro;
  }

  /// The round plays the game of the territory the board leader stands in.
  MiniGameSpec _pickSpec() {
    var leader = players.first;
    for (final p in players) {
      if (p.atp > leader.atp ||
          (p.atp == leader.atp && p.position > leader.position)) {
        leader = p;
      }
    }
    final section = board[leader.position].section;
    var spec = MiniGameRegistry.forScale(section.scale) ??
        MiniGameRegistry.enabledSpecs.first;
    if (spec.id == _lastSpecId && MiniGameRegistry.enabledSpecs.length > 1) {
      final list = MiniGameRegistry.enabledSpecs;
      spec = list[(list.indexOf(spec) + 1) % list.length];
    }
    return spec;
  }

  /// Section whose game is being played this round (for the intro screen).
  BoardSection get currentSection => kBoardSections
      .firstWhere((s) => s.scale == currentSpec!.scale, orElse: () => kBoardSections.last);

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
      s.player.atp += s.award;
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

  /// Final placements, best first. FFA: players ranked by ATP then position.
  List<PartyPlayer> get finalPlayerRanking {
    final sorted = [...players]..sort((a, b) {
        if (b.atp != a.atp) return b.atp.compareTo(a.atp);
        return b.position.compareTo(a.position);
      });
    return sorted;
  }

  /// Team totals, best first, as (teamIndex, totalAtp).
  List<MapEntry<int, int>> get finalTeamRanking {
    final totals = <int, int>{};
    for (final p in players) {
      totals[p.teamIndex] = (totals[p.teamIndex] ?? 0) + p.atp;
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }
}
