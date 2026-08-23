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
  wheelStop, // spinner stops the wheel (value = segment under pointer + 1;
  // 0 = legacy tape draw)
  useItemOn, // targeted item (value = PowerUp.index * 16 + target seat)
  confirmSpace, // walker confirms the landing beat (COMPLETE TURN)
  beginMiniGame, // leave the round's game-reveal screen (host/local)
  voteSkip, // vote to skip the round's mini-game (player = voter seat)
  pickMiniGame, // GAME RIGGER holder picks the round's game (value = choice)
  readyUp, // seat confirms the mini-game ready check (player = seat)
  orderRoll, // seat throws its opening-order double dice (player = seat)
  beginMatch, // leave the resolved order ceremony (host/local tap)
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
  gamePick, // GAME RIGGER was played: its holder picks the round's game
  orderRoll, // the opening order ceremony: double dice decide the ordinals
}

/// The dice half of a roll; movement itself happens step-by-step through
/// [PartyController.advanceStep] so forks and the shop can pause for input.
class TurnResult {
  final int playerIndex;
  final List<int> dice;
  final int rollBonus; // mitochondria
  final int steps;
  final int fromPosition;

  /// Multipliers that hit this roll (Loaded Dice / Sabotage) — remembered so
  /// a MULLIGAN reroll can rebuild the steps under the same conditions.
  final bool doubled;
  final bool halved;

  const TurnResult({
    required this.playerIndex,
    required this.dice,
    required this.rollBonus,
    required this.steps,
    required this.fromPosition,
    this.doubled = false,
    this.halved = false,
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

  /// The item actually granted (null for non-item prizes, and for item spins
  /// that paid cash because the pack was full). Lets the host explain what
  /// the thing does after the wheel settles.
  final PowerUp? item;

  const WheelResult({
    required this.seq,
    required this.tier,
    required this.spinner,
    required this.segmentIndex,
    required this.summary,
    this.item,
  });
}

class TeamStanding {
  final int teamIndex;
  final int potatoes;
  final int diamonds;
  const TeamStanding(this.teamIndex, this.potatoes, this.diamonds);
}

/// A mischief op (the Peeler / the Masher) roaming the board. It relocates
/// each round; on prowl rounds (rules ≥ 4) it may rob a player who brushes
/// its tile, CARRYING the loot — reaching its tile afterwards snatches the
/// stash back. (Rules ≤ 3 replays: it robs the leader every round instead.)
/// Only present on [GameMap] boards.
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

/// The current rules revision — stamped into saves as 'r' (see
/// [PartyController.rules] for what each revision means).
const int kPartyRules = 6;

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
    this.bazaar = true,
    this.rules = kPartyRules,
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
    if (rules >= 6) {
      // THE OPENING ORDER (ORDER_AND_SOLO_SPEC §3): before anything else the
      // cast rolls for the ordinals. [beginMatch] then opens the match.
      phase = PartyPhase.orderRoll;
    } else {
      _openMatch();
    }
  }

  /// Opens the match proper: the opening item wheel (when wheels run), else
  /// straight into the first turn. Rules ≥ 6 reach this via [beginMatch];
  /// older rules straight from the constructor.
  void _openMatch() {
    if (wheels) {
      // The opening spin: every player lands an item before turn one — the
      // immediate-interactivity layer (PARTY_CINEMATIC_SPEC §2).
      _startWheel(WheelTier.opening,
          [for (var i = 0; i < players.length; i++) i]);
    } else {
      phase = PartyPhase.turnStart;
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
    bool bazaar = true,
    int rules = kPartyRules,
  }) {
    final c = PartyController(
      mode: mode,
      totalRounds: totalRounds,
      playerNames: playerNames,
      seed: seed,
      gameMap: gameMap,
      wheels: wheels,
      bazaar: bazaar,
      rules: rules,
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
    bool bazaar = true,
    int rules = kPartyRules,
  }) {
    final c = PartyController(
      mode: mode,
      totalRounds: totalRounds,
      playerNames: playerNames,
      seed: 0, // unused: the client tape never touches Random
      randomMode: PartyRandomMode.client,
      gameMap: gameMap,
      wheels: wheels,
      bazaar: bazaar,
      rules: rules,
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

  /// Rules revision this match plays under ([kPartyRules] for every new game;
  /// older values only when replaying saves recorded before a balance change,
  /// so their input logs stay aligned):
  ///   ≤2 — launch rules: 10/6/4/2… awards; checkpoint spins include the
  ///        round winner (sting exposure right after a win).
  ///    3 — the winner-pays law: awards are 10/5/1/0 (nothing past third),
  ///        and a round's winners are NEVER fed a sting table — when the
  ///        checkpoint lands right after their win they spin the all-positive
  ///        winner table instead and sit out the checkpoint queue.
  ///    4 — clocking out: after clocking in at the Potato Shack (the anchor)
  ///        the player returns to square one (order 0) when their turn is
  ///        confirmed — the Shack is a checkpoint, not a parking spot. Pre-4
  ///        logs replay the old stuck-at-the-anchor behavior.
  ///        ALSO the prowl economy (Brett, 2026-07-12): the mischief crew
  ///        NEVER robs at round boundaries — banked diamonds persist. They
  ///        rob only by board contact during a prowl round (every
  ///        [kOpsProwlEvery]-th), and even then on a coin flip; routing
  ///        around them is the counterplay. And every [kBigBadEvery]-th
  ///        round the map's boss spins the DECREE WHEEL over that round's
  ///        mini-game (last-loses-a-potato / the great redistribution).
  ///    5 — the ready check (READY_UP_SPEC.md, Brett, 2026-07-12): passPhone
  ///        is a genuine decision phase — the pump holds there until every
  ///        seat has logged a [PartyInputKind.readyUp] (a skip vote implies
  ///        ready), so no online mini-game starts before the whole room is
  ///        in. Pre-5 logs replay the old fast-forward.
  ///        ALSO the Vat's heat (Brett, 2026-07-12, fork-strategy session):
  ///        on Down the Hole, ending a walk in the four deepest bands lets
  ///        the Boiling Vat skim 1/2/3/4 💎 ([vatHeatFor]; the Shack is
  ///        safe, Void Shield blocks). The bail-up checkpoint forks are the
  ///        counterplay. Deterministic — pre-5 logs replay heatless.
  ///    6 — THE OPENING ORDER (ORDER_AND_SOLO_SPEC.md, Brett, 2026-07-12):
  ///        the match opens in [PartyPhase.orderRoll] — every seat throws
  ///        double dice, ties re-roll, and the resulting [turnOrder] drives
  ///        turn cycling all game. Adds MULLIGAN (dice reroll) and QUEUE
  ///        JUMPER (ordinal swap, applied at the round boundary) to the
  ///        market. Pre-6 logs replay seat order with no ceremony.
  final int rules;

  /// Whether the market catalog runs (ITEMS_SPEC.md): the always-open rarity
  /// shelf, multi-buy perusing, and the 13 catalog items. True for every new
  /// game; false only when replaying v2-and-earlier saves, which keep the old
  /// affordability-gated single-purchase market so their logs stay aligned.
  final bool bazaar;

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

  /// MAPS_SPEC economy: a diamond sits on every space (except the start);
  /// you EAT the one on each space you walk through — the whole move, not
  /// just the landing — so taking the longer route is how you get paid.
  /// They all respawn when someone completes a traversal (reaches the
  /// anchor; a lap on the legacy loop). Cinematic (wheels) games only, so
  /// v1 replays keep their recorded economy.
  final Set<int> eatenDiamonds = {};

  /// Whether a path diamond is currently sitting on [index].
  bool diamondOn(int index) =>
      wheels && index != 0 && !eatenDiamonds.contains(index);

  /// Map-aware section lookup — the new maps carry their own 8–10 sections, the
  /// legacy board uses the fixed [kBoardSections].
  BoardSection sectionOf(BoardSpace s) => gameMap?.sectionOf(s) ?? s.section;

  PartyPhase phase = PartyPhase.turnStart;
  int round = 1;
  int currentPlayerIndex = 0;
  TurnResult? lastTurn;

  /// Solo mode (ORDER_AND_SOLO_SPEC §2): seats 1–3 are CPU characters,
  /// derived from the mode so saves need no extra field. The party page
  /// auto-drives their decisions; the controller treats them as any seat.
  bool isCpuSeat(int i) => mode == PartyMode.solo && i > 0;

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

  // ------------------------------------------------ market catalog state
  // (ITEMS_SPEC.md — all of it inert when [bazaar] is false.)

  /// What's on the shelf at the market the walker is currently perusing.
  /// Restocked off the tape on every visit: usually 2 commons + 1 rare,
  /// sometimes an exotic. Bought items leave the shelf.
  final List<PowerUp> marketShelf = [];

  /// TOLL CONTRACT: the seat collecting fork tolls, and the last round the
  /// contract covers. Null seat = no contract active.
  int? tollOwnerSeat;
  int tollUntilRound = 0;

  /// GAME RIGGER: the seat that gets to pick the next mini-game, and the
  /// tape-drawn choices offered while [phase] == gamePick.
  int? gamePickerSeat;
  List<MiniGameSpec> gamePickChoices = [];

  /// GOLDEN STAKES: next mini-game's winner takes x3 diamonds and a potato.
  bool stakesArmed = false;

  /// Whether a toll contract is charging right now.
  bool get tollActive => tollOwnerSeat != null && round <= tollUntilRound;

  /// Where the WARP POTATO can take you: every market and gateway (power-up
  /// space) on the board, in path order. Capped at 16 because a targeted-item
  /// input encodes its target in 4 bits (value = item.index * 16 + slot).
  List<int> get warpNodes {
    final nodes = <int>[
      for (final s in board)
        if (s.type == SpaceType.shop || s.type == SpaceType.powerUp) s.index
    ];
    return nodes.length > 16 ? nodes.sublist(0, 16) : nodes;
  }

  /// Steps still to walk this turn; the UI calls [advanceStep] per tick.
  int stepsRemaining = 0;

  /// Set when the walker clocked in at the Shack this landing (rules ≥ 4):
  /// their COMPLETE TURN tap ([confirmSpace]) walks them home to square one.
  /// Set and consumed within the same turn, so replay needs no extra state.
  bool _clockOutPending = false;

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

  /// The map's headline boss — the Big Bad who spins the decree wheel on
  /// [_bigBadDue] rounds (null on bossless boards / the legacy loop).
  Op? get bigBad =>
      (gameMap?.bosses.isNotEmpty ?? false) ? gameMap!.bosses.first : null;

  /// The Big Bad's decree armed by this round's wheel (rules ≥ 4) — announced
  /// before the mini-game, applied to its results, then cleared.
  BossRule? armedBossRule;

  /// Player-facing outcome lines of the decree just applied (who lost the
  /// potato, how the pot paid out) — the round ceremony displays these.
  final List<String> bossRuleOutcome = [];

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

    // Dice count: TRIPLE DICE trumps the accelerator (which stays armed for
    // a later roll rather than being wasted under the bigger effect).
    final int diceCount;
    if (p.tripleDice) {
      diceCount = 3;
      turnLog.add('${p.name} throws Triple Dice — three added together!');
      p.tripleDice = false;
    } else if (p.accelerator) {
      diceCount = 2;
      turnLog.add('${p.name} fired the Accelerator — two dice!');
      p.accelerator = false;
    } else {
      diceCount = 1;
    }
    final dice = [for (var i = 0; i < diceCount; i++) _tape.next(6) + 1];
    var bonus = 0;
    if (p.mitochondria) {
      bonus += 3;
      turnLog.add('Mitochondria kicks in: +3 movement.');
      p.mitochondria = false;
    }
    if (p.tailwind) {
      bonus += 2;
      turnLog.add('Tailwind at ${p.name}\'s back: +2 movement.');
      p.tailwind = false;
    }
    if (p.boostFive) {
      bonus += 5;
      turnLog.add('Booster ignites: +5 movement.');
      p.boostFive = false;
    }
    if (p.boostTen) {
      bonus += 10;
      turnLog.add('Mega Booster roars: +10 movement!');
      p.boostTen = false;
    }
    if (p.secondWindTurns > 0) {
      bonus += 1;
      p.secondWindTurns--;
      turnLog.add('Second Wind: +1 movement '
          '(${p.secondWindTurns} turn${p.secondWindTurns == 1 ? '' : 's'} left).');
    }
    if (atpRollBonus > 0) {
      bonus += atpRollBonus;
      turnLog.add('${p.name} hydrolyzed $atpRollBonus ATP into the roll.');
    }

    stepsRemaining = dice.reduce((a, b) => a + b) + bonus;
    var doubled = false, halved = false;
    if (p.loadedDice) {
      stepsRemaining *= 2;
      doubled = true;
      turnLog.add('Loaded Dice — the roll counts double!');
      p.loadedDice = false;
    }
    // SABOTAGE lands last: whatever the roll became, it's halved (round up).
    if (p.halvedRoll) {
      stepsRemaining = (stepsRemaining / 2).ceil();
      halved = true;
      turnLog.add('${p.name} was sabotaged — the roll is halved '
          'to $stepsRemaining!');
      p.halvedRoll = false;
    }
    lastTurn = TurnResult(
      playerIndex: p.index,
      dice: dice,
      rollBonus: bonus,
      steps: stepsRemaining,
      fromPosition: p.position,
      doubled: doubled,
      halved: halved,
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
      turnLog.add('${p.name} is frozen solid — turn skipped!');
      _endTurn();
      return;
    }
    p.atp += kAtpPerTurn;
  }

  /// Hands play to the next ordinal, or fires the round's mini-game after
  /// the last one. Shared by [confirmSpace] and the frozen-turn skip.
  void _endTurn() {
    if (_turnPos < players.length - 1) {
      _turnPos++;
      currentPlayerIndex = turnOrder[_turnPos];
      phase = PartyPhase.turnStart;
      _beginTurn();
    } else {
      _startMiniGameRound();
    }
  }

  // ── THE OPENING ORDER (ORDER_AND_SOLO_SPEC §3, rules ≥ 6) ────────────────

  /// Seat order of play: turnOrder[0] rolls first each round. Identity for
  /// rules ≤ 5; earned by the opening double-dice ceremony from rules 6.
  late List<int> turnOrder = _allSeats;

  /// Cursor into [turnOrder] for the round's turn cycling.
  int _turnPos = 0;

  /// Latest ceremony dice per seat (UI display). A tie-group's dice are
  /// cleared when it re-rolls; resolved seats keep theirs on screen.
  final Map<int, List<int>> orderDice = {};

  /// Tie-group resolution: ordered groups of seats still unordered BETWEEN
  /// themselves. All singletons ⇒ the ceremony is resolved.
  late final List<List<int>> _orderGroups = [_allSeats];

  bool get orderResolved => _orderGroups.every((g) => g.length == 1);

  List<int>? get _activeOrderGroup {
    for (final g in _orderGroups) {
      if (g.length > 1) return g;
    }
    return null;
  }

  /// The seat whose ceremony roll is up (null once the order is resolved).
  int? get orderPendingSeat {
    final g = _activeOrderGroup;
    if (g == null) return null;
    for (final s in g) {
      if (!orderDice.containsKey(s)) return s;
    }
    return null;
  }

  /// One opening-order throw: two dice off the tape for [player] (defaults
  /// to the pending seat). A logged decision — lockstep/replay safe.
  void rollForOrder({int? player}) {
    assert(phase == PartyPhase.orderRoll);
    final seat = player ?? orderPendingSeat;
    if (seat == null || seat != orderPendingSeat) return;
    inputLog.add(PartyInput(PartyInputKind.orderRoll, 0, seat));
    final dice = [_tape.next(6) + 1, _tape.next(6) + 1];
    orderDice[seat] = dice;
    turnLog.add('${players[seat].name} throws ${dice[0]} + ${dice[1]} '
        '= ${dice[0] + dice[1]} for the order!');
    _maybeSplitOrderGroup();
    notifyListeners();
  }

  /// Once every seat of the active tie group has dice, split it by total
  /// (descending). Subgroups still tied stay grouped, lose their dice, and
  /// re-roll when their turn comes. All singletons ⇒ [turnOrder] locks.
  void _maybeSplitOrderGroup() {
    final g = _activeOrderGroup;
    if (g == null || g.any((s) => !orderDice.containsKey(s))) return;
    final byTotal = <int, List<int>>{};
    for (final s in g) {
      final t = orderDice[s]![0] + orderDice[s]![1];
      byTotal.putIfAbsent(t, () => []).add(s);
    }
    final totals = byTotal.keys.toList()..sort((a, b) => b.compareTo(a));
    final split = [for (final t in totals) byTotal[t]!];
    final at = _orderGroups.indexOf(g);
    _orderGroups
      ..removeAt(at)
      ..insertAll(at, split);
    for (final sub in split) {
      if (sub.length > 1) {
        turnLog.add('TIE! ${sub.map((s) => players[s].name).join(' and ')} '
            'throw again!');
        for (final s in sub) {
          orderDice.remove(s); // fresh dice for the tie-break
        }
      }
    }
    if (orderResolved) {
      turnOrder = [for (final gg in _orderGroups) gg.single];
      turnLog.add('The order is set: '
          '${turnOrder.map((s) => players[s].name).join(' → ')}!');
    }
  }

  /// Leaves the resolved ceremony (a logged decision — the host/local tap,
  /// tap-to-drive law) and opens the match proper.
  void beginMatch() {
    assert(phase == PartyPhase.orderRoll && orderResolved);
    inputLog.add(const PartyInput(PartyInputKind.beginMatch));
    _turnPos = 0;
    currentPlayerIndex = turnOrder[0];
    _openMatch();
    notifyListeners();
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

  /// What one branch of the current fork offers, so the chooser can NAME the
  /// trade (PARTY UX LAW — a strategy the player can't see isn't a strategy).
  /// Valid in [PartyPhase.chooseBranch]. Purely derived — no state change,
  /// no tape draw.
  BranchPreview previewBranch(int nextIndex) {
    final at = currentPlayer.position;
    // The far arm a cut-through jumps to (or -1 when this fork has none).
    final cutTarget = board[at]
        .nexts
        .fold<int>(-1, (m, n) => n > at + 1 ? max(m, n) : m);
    // The stretch this choice commits you to that the other choice avoids:
    // · the cut itself — one hop straight to the far arm;
    // · bail-up — the already-walked ground back down to this fork;
    // · onward — everything up to where the cut (if any) would merge back in.
    List<int> segment;
    if (nextIndex > at + 1) {
      segment = [nextIndex];
    } else if (nextIndex < at) {
      segment = [for (var o = nextIndex; o < at; o++) o];
    } else {
      final merge = cutTarget > at ? cutTarget : at + 2;
      segment = [for (var o = at + 1; o < merge; o++) o];
    }
    var gems = 0;
    var market = false, powerUp = false, risky = false;
    for (final o in segment) {
      if (diamondOn(o)) gems++;
      switch (board[o].type) {
        case SpaceType.shop:
          market = true;
          break;
        case SpaceType.powerUp:
          powerUp = true;
          break;
        case SpaceType.lose:
        case SpaceType.cardWild:
          risky = true;
          break;
        default:
          break;
      }
    }
    final heatOn = rules >= 5;
    return BranchPreview(
      isCut: nextIndex > at + 1,
      isBail: nextIndex < at,
      spots: segment.length,
      diamonds: gems,
      market: market,
      powerUp: powerUp,
      risky: risky,
      heatHere: heatOn ? vatHeatFor(gameMap, board[at]) : 0,
      heatThere: heatOn ? vatHeatFor(gameMap, board[nextIndex]) : 0,
    );
  }

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
    // TOLL CONTRACT: while it runs, an op charges rivals at every fork —
    // going further costs more. Paid to the contract holder. Deterministic.
    if (tollActive && tollOwnerSeat != currentPlayerIndex) {
      final owner = players[tollOwnerSeat!];
      final toll = min(p.diamonds, kForkToll);
      if (toll > 0) {
        p.diamonds -= toll;
        owner.diamonds += toll;
        turnLog.add('The op at the fork tolls ${p.name} $toll diamonds '
            '— straight into ${owner.name}\'s pocket!');
      } else {
        turnLog.add(
            'The op at the fork pats down ${p.name} — nothing to toll.');
      }
    }
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
    // Pac-Man economy: eat the path diamond on every space walked through.
    // A DIAMOND MAGNET makes every diamond on this walk count double.
    if (diamondOn(next)) {
      eatenDiamonds.add(next);
      p.diamonds += p.magnet ? 2 : 1;
    }
    // Completing a traversal respawns the whole trail for everyone.
    if (wheels &&
        ((gameMap != null && next == board.length - 1) ||
            (gameMap == null && next == 0))) {
      eatenDiamonds.clear();
      turnLog.add('${p.name} completed the traversal — the diamonds respawn!');
    }
    _opBrush(p, next);
    // Lap bonus only on the legacy loop (the maps are linear, not a ring).
    if (gameMap == null && next == 0) {
      p.diamonds += 5;
      turnLog.add('${p.name} completed a lap of existence: +5 diamonds.');
    }
    // Passing (or landing on) a market pauses the walk. Legacy uses the fixed
    // shop index; maps use the type.
    final atShop = gameMap == null
        ? next == kShopIndex
        : board[next].type == SpaceType.shop;
    // Catalog games ALWAYS open the market — passing a market means you get
    // to peruse the wares, broke or not (Brett, 2026-07-12). Legacy games
    // keep their affordability gate so old logs stay aligned.
    if (atShop && (bazaar || p.diamonds >= kMinShopPrice)) {
      if (bazaar) _stockShelf();
      phase = PartyPhase.shopOffer;
      notifyListeners();
      return;
    }
    _finishStep();
  }

  /// Restocks [marketShelf] off the tape for a fresh market visit: 2 distinct
  /// commons + 1 rare, and roughly one visit in [kExoticShelfChance] an exotic
  /// joins the shelf. Host-recorded draws keep every replica's shelf identical.
  void _stockShelf() {
    marketShelf.clear();
    // Rules ≥ 6 shelves stock the order items too; pre-6 replays must draw
    // from the original pool SIZES or their recorded shelves shift.
    final rares = rules >= 6 ? kRareItemsV6 : kRareItems;
    final exotics = rules >= 6 ? kExoticItemsV6 : kExoticItems;
    final commons = [...kCommonItems];
    for (var i = 0; i < kShelfCommonSlots && commons.isNotEmpty; i++) {
      marketShelf.add(commons.removeAt(_tape.next(commons.length)));
    }
    for (var i = 0; i < kShelfRareSlots; i++) {
      marketShelf.add(rares[_tape.next(rares.length)]);
    }
    if (_tape.next(kExoticShelfChance) == 0) {
      marketShelf.add(exotics[_tape.next(exotics.length)]);
    }
  }

  /// What [item] costs the perusing player right now: catalog price on
  /// catalog games (legacy price otherwise), halved (rounded up) by a COUPON.
  int shelfPriceOf(PowerUp item, PartyPlayer p) {
    final base =
        (bazaar ? kCatalogPrices[item] : kItemPrices[item]) ?? 999;
    return bazaar && p.coupon ? (base / 2).ceil() : base;
  }

  /// What a potato costs the perusing player right now (COUPON applies).
  int potatoPriceFor(PartyPlayer p) =>
      bazaar && p.coupon ? (kPotatoPrice / 2).ceil() : kPotatoPrice;

  /// Buys one potato at the market. Catalog games stay at the stall so the
  /// player can keep perusing (LEAVE MARKET exits); legacy games walk on.
  void buyPotato() {
    assert(phase == PartyPhase.shopOffer);
    final p = currentPlayer;
    final price = potatoPriceFor(p);
    if (p.diamonds < price) return;
    inputLog.add(const PartyInput(PartyInputKind.buyPotato));
    p.diamonds -= price;
    if (bazaar && p.coupon) {
      p.coupon = false;
      turnLog.add('${p.name}\'s Coupon knocked the potato to $price diamonds.');
    }
    p.potatoes++;
    turnLog.add(
        '${p.name} bought a potato for $price diamonds! (${p.potatoes} total)');
    if (bazaar) {
      notifyListeners();
      return; // keep perusing — LEAVE MARKET continues the walk
    }
    phase = PartyPhase.moving;
    _finishStep();
  }

  /// Leaves the market; the walk continues. (On catalog games this is the
  /// only way out of the stall — buying never auto-ejects the player.)
  void skipPotato() {
    assert(phase == PartyPhase.shopOffer);
    inputLog.add(const PartyInput(PartyInputKind.skipPotato));
    phase = PartyPhase.moving;
    _finishStep();
  }

  void _finishStep() {
    final p = currentPlayer;
    if (stepsRemaining <= 0) {
      // The DIAMOND MAGNET covers one whole walk; it lets go on landing.
      if (p.magnet) {
        p.magnet = false;
        turnLog.add('${p.name}\'s Diamond Magnet powers down.');
      }
      // Ladders / snakes / rainbow slides relocate you on landing, then the
      // destination space resolves.
      final landed = board[p.position];
      if (landed.jumpTo != null) {
        final to = landed.jumpTo!;
        turnLog.add(to > p.position
            ? '${p.name} rode a lift up to $to!'
            : '${p.name} slipped back to $to.');
        p.position = to;
      }
      final beforeDiamonds = p.diamonds, beforePotatoes = p.potatoes;
      // CLOCKING IN (Brett, 2026-07-11): reaching the Potato Shack — the
      // anchor, where everyone works — always pays one potato. You get a
      // potato for showing up; buying more with diamonds is separate.
      if (gameMap != null && p.position == board.length - 1) {
        p.potatoes += 1;
        turnLog.add('${p.name} clocked in at the Potato Shack: +1 potato!');
        // CLOCKING OUT (rules ≥ 4, Brett 2026-07-12): the Shack is a
        // checkpoint, not a parking spot — the walker heads home to square
        // one. Announced here so the landing panel explains it; the move
        // itself waits for the COMPLETE TURN tap (PARTY UX LAW).
        _clockOutPending = rules >= 4;
      }
      // Landing on a ghost's space costs diamonds before the space resolves
      // (folded into the same landing pop via the delta below).
      _hauntCheck(p, p.position, turnLog);
      _resolveSpace(p, board[p.position], turnLog);
      // THE VAT'S HEAT (rules ≥ 5): ending the walk in one of Down the
      // Hole's deep bands lets the Boiling Vat skim diamonds — the pressure
      // the bail-up checkpoint forks trade against. Folded into the same
      // landing pop; Void Shield blocks it (it is a diamonds loss).
      final heat = rules >= 5 ? vatHeatFor(gameMap, board[p.position]) : 0;
      if (heat > 0 && p.diamonds > 0) {
        if (p.voidShield) {
          p.voidShield = false;
          turnLog.add("${p.name}'s VOID SHIELD hisses in the hot water — "
              'the Vat takes nothing!');
        } else {
          final take = min(heat, p.diamonds);
          p.diamonds -= take;
          turnLog.add('The BOILING VAT skims $take 💎 off ${p.name} — '
              'the water is hotter down here.');
        }
      }
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
      // The clock-out announcement reads LAST in the landing panel, after the
      // space's own resolution lines.
      if (_clockOutPending) {
        turnLog.add("Shift's over — ${p.name} heads back to square one.");
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
    inputLog.add(const PartyInput(PartyInputKind.confirmSpace));
    // Clocking out (rules ≥ 4): the Shack landing was seen and confirmed —
    // now the walker returns to square one to start the climb again. The UI
    // renders any multi-node move as the long token glide.
    if (_clockOutPending) {
      _clockOutPending = false;
      currentPlayer.position = 0;
    }
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
          log.add("${p.name}'s Void Shield absorbed the loss!");
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
    // MULLIGAN is the one item played AFTER the dice land (rollResult);
    // everything else arms before the roll (turnStart).
    assert(item == PowerUp.reroll
        ? phase == PartyPhase.rollResult
        : phase == PartyPhase.turnStart);
    if (item == PowerUp.reroll && phase != PartyPhase.rollResult) return;
    // Targeted items need a target — they go through [useItemOn].
    if (item.isTargeted) return;
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
      case PowerUp.tailwind:
        p.tailwind = true;
        break;
      case PowerUp.boostFive:
        p.boostFive = true;
        break;
      case PowerUp.boostTen:
        p.boostTen = true;
        break;
      case PowerUp.tripleDice:
        p.tripleDice = true;
        break;
      case PowerUp.magnet:
        p.magnet = true;
        break;
      case PowerUp.coupon:
        p.coupon = true;
        break;
      case PowerUp.secondWind:
        p.secondWindTurns = 3;
        break;
      case PowerUp.sabotage:
        for (final o in players) {
          if (o.index != p.index) o.halvedRoll = true;
        }
        turnLog.add('${p.name} sabotaged the field — '
            "every rival's next roll is halved!");
        break;
      case PowerUp.pickpocket:
        _pickpocket(p);
        break;
      case PowerUp.tollOp:
        tollOwnerSeat = p.index;
        tollUntilRound = round + 1;
        turnLog.add('${p.name} signed a Toll Contract — an op now charges '
            'rivals $kForkToll diamonds at every fork through '
            'round $tollUntilRound!');
        break;
      case PowerUp.gameRigger:
        gamePickerSeat = p.index;
        turnLog.add('${p.name} rigged the round — '
            'they pick the next mini-game!');
        break;
      case PowerUp.goldenStakes:
        stakesArmed = true;
        turnLog.add('${p.name} raised Golden Stakes — the next mini-game\'s '
            'winner takes triple diamonds and a potato!');
        break;
      case PowerUp.reroll:
        _rerollDice(p);
        break;
      case PowerUp.freezeRay:
      case PowerUp.swapper:
      case PowerUp.warpPotato:
      case PowerUp.orderSwap:
        break; // unreachable: guarded above, targeted use only
    }
    p.itemsUsed++;
    notifyListeners();
  }

  /// MULLIGAN: throw the same dice again (fresh tape draws) under the same
  /// conditions — bonuses and multipliers carry over; the new result stands.
  void _rerollDice(PartyPlayer p) {
    final turn = lastTurn;
    if (turn == null) return;
    final dice = [
      for (var i = 0; i < turn.dice.length; i++) _tape.next(6) + 1
    ];
    var steps = dice.reduce((a, b) => a + b) + turn.rollBonus;
    if (turn.doubled) steps *= 2;
    if (turn.halved) steps = (steps / 2).ceil();
    stepsRemaining = steps;
    lastTurn = TurnResult(
      playerIndex: turn.playerIndex,
      dice: dice,
      rollBonus: turn.rollBonus,
      steps: steps,
      fromPosition: turn.fromPosition,
      doubled: turn.doubled,
      halved: turn.halved,
    );
    turnLog.add('${p.name} plays the MULLIGAN — the dice fly again: '
        '${dice.join(' + ')} for $steps steps!');
  }

  /// PICKPOCKET: lift 3 diamonds off the leading rival. STRONG BOND on the
  /// mark blocks it (and is consumed), same as every other steal.
  void _pickpocket(PartyPlayer p) {
    final others = players.where((o) => o.index != p.index).toList();
    if (others.isEmpty) return;
    final mark = others.reduce((a, b) => (b.potatoes > a.potatoes ||
            (b.potatoes == a.potatoes && b.diamonds > a.diamonds))
        ? b
        : a);
    if (mark.strongBond) {
      mark.strongBond = false;
      turnLog.add("${mark.name}'s Strong Bond caught ${p.name}'s "
          'pickpocketing hand!');
      return;
    }
    final take = min(3, mark.diamonds);
    mark.diamonds -= take;
    p.diamonds += take;
    if (take > 0) mark.stolenFromCount++;
    turnLog.add(take > 0
        ? '${p.name} pickpocketed $take diamonds off ${mark.name}!'
        : '${mark.name}\'s pockets were empty — the pickpocket got nothing.');
  }

  /// Spends a TARGETED item on the current player's turn. For freeze ray /
  /// swapper [target] is a rival's seat (STRONG BOND blocks, and is
  /// consumed); for the warp potato it's a slot into [warpNodes]. A logged
  /// decision: value = item.index * 16 + target (hence targets < 16).
  void useItemOn(PowerUp item, int target) {
    assert(phase == PartyPhase.turnStart);
    if (!item.isTargeted) return;
    if (item == PowerUp.warpPotato) {
      final nodes = warpNodes;
      if (target < 0 || target >= nodes.length) return;
      final p = currentPlayer;
      if (!p.items.remove(item)) return; // not in the pack
      inputLog
          .add(PartyInput(PartyInputKind.useItemOn, item.index * 16 + target));
      p.itemsUsed++;
      p.position = nodes[target];
      turnLog.add('${p.name} bit the Warp Potato — '
          'zapped across the board!');
      notifyListeners();
      return;
    }
    if (target < 0 || target >= players.length) return;
    if (target == currentPlayerIndex) return;
    final p = currentPlayer;
    if (!p.items.remove(item)) return; // not in the pack
    inputLog.add(PartyInput(PartyInputKind.useItemOn, item.index * 16 + target));
    p.itemsUsed++;
    final t = players[target];
    if (t.strongBond) {
      t.strongBond = false;
      turnLog.add("${t.name}'s Strong Bond shrugged off ${p.name}'s "
          '${item.label}!');
      notifyListeners();
      return;
    }
    t.stolenFromCount++; // aggression economy: feeds Most Stolen-From
    switch (item) {
      case PowerUp.freezeRay:
        t.frozenTurns++;
        turnLog.add('${p.name} froze ${t.name} — they lose a turn!');
        break;
      case PowerUp.swapper:
        final a = p.position;
        p.position = t.position;
        t.position = a;
        turnLog.add('${p.name} swapped places with ${t.name}!');
        break;
      case PowerUp.orderSwap:
        _pendingOrderSwaps.add((p.index, target));
        turnLog.add('${p.name} plays the QUEUE JUMPER — from next round '
            "they take ${t.name}'s place in the order!");
        break;
      default:
        break;
    }
    notifyListeners();
  }

  /// QUEUE JUMPER swaps queued this round — applied at the round boundary so
  /// nobody gains or loses a turn mid-round (ORDER_AND_SOLO_SPEC §4).
  final List<(int, int)> _pendingOrderSwaps = [];

  void _applyPendingOrderSwap() {
    for (final (a, b) in _pendingOrderSwaps) {
      final ia = turnOrder.indexOf(a), ib = turnOrder.indexOf(b);
      if (ia < 0 || ib < 0) continue;
      turnOrder[ia] = b;
      turnOrder[ib] = a;
      turnLog.add('${players[a].name} and ${players[b].name} '
          'trade places in the order!');
    }
    _pendingOrderSwaps.clear();
  }

  void _runEvent(PartyPlayer p, List<String> log) {
    final others = players.where((o) => o.index != p.index).toList();
    switch (_tape.next(5)) {
      case 0: // Cosmic Swap
        final target = others[_tape.next(others.length)];
        if (target.strongBond) {
          target.strongBond = false;
          log.add(
              'Cosmic Swap targeted ${target.name}, but their Strong Bond held!');
        } else {
          final tmp = p.position;
          p.position = target.position;
          target.position = tmp;
          log.add('Cosmic Swap! ${p.name} traded places with ${target.name}.');
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
            'Entropy Surge! Everyone loses 3 diamonds, the leader loses 6.');
        break;
      case 2: // Photosynthesis
        for (final o in players) {
          o.diamonds += 3;
        }
        log.add('Photosynthesis! Everyone gains +3 diamonds.');
        break;
      case 3: // Wormhole — 5 hops forward (main option at any fork)
        for (var i = 0; i < 5; i++) {
          p.position = board[p.position].nexts.first;
        }
        log.add('Wormhole! ${p.name} jumps forward 5 spaces.');
        break;
      default: // Quantum Tunnel — back 4 along the main loop
        if (!board[p.position].isShortcut) {
          p.position =
              (p.position - 4 + kMainLoopLength) % kMainLoopLength;
          log.add('Quantum Tunnel! ${p.name} slips back 4 spaces.');
        } else {
          log.add(
              'Quantum Tunnel fizzled — ${p.name} is off the main loop.');
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

  /// Diamonds one prowl-round skim can take (rules ≥ 4).
  static const int _kOpSkim = 8;

  /// Rules ≥ 4: whether the crew is on the hunt THIS round. Derived purely
  /// from [round], so every replica agrees with no extra state. On prowl
  /// rounds — and only then — brushing an op's tile risks a robbery.
  bool get opsProwling =>
      rules >= 4 && ops.isNotEmpty && round % kOpsProwlEvery == 0;

  /// Whoever the ops prey on — the current leader (rubber-band: the crew robs
  /// from the front). Deterministic, so replay reproduces the victim.
  /// Rules ≤ 3 replays only.
  PartyPlayer? _opVictim() {
    if (players.isEmpty) return null;
    return players.reduce((a, b) => (b.potatoes > a.potatoes ||
            (b.potatoes == a.potatoes && b.diamonds > a.diamonds))
        ? b
        : a);
  }

  /// Round boundary: the crew relocates (tiles off the tape so online stays
  /// in sync) — the "will they move?" gamble that makes routing around them
  /// a real choice. Rules ≥ 4 they NEVER rob from here (banked diamonds
  /// persist round to round); robbery happens only on board contact during a
  /// prowl round — see [_opBrush]. Rules ≤ 3 replays keep the old
  /// rob-the-leader-every-round behavior so their logs stay aligned.
  void _runOps(List<String> log) {
    if (rules >= 4) {
      for (final t in ops) {
        t.position = _tape.next(board.length);
      }
      if (opsProwling) {
        log.add('The crew is PROWLING this round — brush their tile and '
            'they may rob you. Route around them!');
      }
      return;
    }
    for (final t in ops) {
      final victim = _opVictim();
      if (victim != null) {
        if (t.op.id == kMasher.id &&
            victim.potatoes > 0 &&
            !victim.strongBond) {
          victim.potatoes--;
          t.potatoes++;
          victim.stolenFromCount++;
          log.add('${t.op.name} mashed a potato out of ${victim.name}!');
        } else if (victim.strongBond) {
          victim.strongBond = false;
          log.add('${victim.name}\'s Strong Bond fended off ${t.op.name}.');
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

  /// A player brushing an op's tile (landing on it or walking through). On a
  /// prowl round the op pounces first — a tape coin flip per brush; heads it
  /// robs and slinks off with the loot ([_robAttempt]). A missed pounce, a
  /// non-prowl round, or a Strong Bond parry all resolve the other way:
  /// the player CATCHES the op and snatches back its whole stash. Pure
  /// transfer — no tape draw on the catch itself.
  void _opBrush(PartyPlayer p, int tile) {
    for (final t in ops) {
      if (t.position != tile) continue;
      if (opsProwling && _robAttempt(p, t)) continue;
      if (!t.hasLoot) continue;
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

  /// One prowl-round pounce (rules ≥ 4). True only when the op actually got
  /// away with a take — the Masher mashes a potato when there is one, the
  /// skim caps at [_kOpSkim] diamonds, and the crook immediately relocates
  /// (tape draw), loot in hand, for the table to chase. A Strong Bond parries
  /// (consumed) and empty pockets are skipped — both WITHOUT drawing the
  /// coin flip, so every replica stays aligned.
  bool _robAttempt(PartyPlayer p, OpToken t) {
    if (p.strongBond) {
      p.strongBond = false;
      turnLog.add("${p.name}'s Strong Bond fended off ${t.op.name}!");
      return false; // parried — now grab the crook's stash
    }
    final canMash = t.op.id == kMasher.id && p.potatoes > 0;
    if (!canMash && p.diamonds == 0) return false; // nothing worth taking
    if (_tape.next(2) != 0) return false; // the pounce misses — catch them!
    if (canMash) {
      p.potatoes--;
      t.potatoes++;
      p.stolenFromCount++;
      turnLog.add('${t.op.name} MASHED a potato out of ${p.name} and '
          'slinked off with it — catch them to take it back!');
    } else {
      final take = min(p.diamonds, _kOpSkim);
      p.diamonds -= take;
      t.diamonds += take;
      p.stolenFromCount++;
      turnLog.add('${t.op.name} skimmed $take diamonds off ${p.name} and '
          'slinked off — catch them to take it back!');
    }
    t.position = _tape.next(board.length);
    return true;
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
        log.add('uhhh… did you hear that? The ghosts from the Potato '
            'Shack are on the loose!');
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
        log.add("${p.name}'s Void Shield glowed — the ghost fled!");
      } else {
        final take = min(p.diamonds, _kGhostBite);
        if (take > 0) {
          p.diamonds -= take;
          p.stolenFromCount++;
          log.add('A ghost got ${p.name} — $take diamonds haunted back '
              'to the Shack!');
        } else {
          log.add('A ghost passed straight through ${p.name}. Chilling.');
        }
      }
      g.position = _tape.next(board.length);
    }
  }

  // ----------------------------------------------------------------- cards

  /// Draws from the common (Tater) or wild (Void) deck and HOLDS it. Every
  /// card — decision or not — pauses in [PartyPhase.cardDecision] so the
  /// player sees what they drew before anything executes (PARTY UX LAW: the
  /// card is revealed, then the player plays it). The draw index comes off
  /// the tape so host and clients land on the same card.
  void _drawCard(PartyPlayer p, CardDeck deck, List<String> log) {
    final cards = deck == CardDeck.wild ? kWildDeck : kCommonDeck;
    final card = cards[_tape.next(cards.length)];
    currentCard = card;
    final deckName = deck == CardDeck.wild ? 'VOID CARD' : 'TATER CARD';
    log.add('$deckName — ${card.title}: ${card.text}');
    phase = PartyPhase.cardDecision; // _finishStep leaves this in place
  }

  /// Resolves the held card: the player picked option [i] (decision cards),
  /// or played the card as drawn (common cards — [i] is ignored).
  void chooseCardOption(int i) {
    assert(phase == PartyPhase.cardDecision);
    final card = currentCard;
    if (card == null) return;
    if (card.isDecision) {
      if (i < 0 || i >= card.options.length) return;
      inputLog.add(PartyInput(PartyInputKind.chooseCardOption, i));
      turnLog.add('${currentPlayer.name} chose: ${card.options[i].label}.');
      _applyCardEffects(currentPlayer, card.options[i].effects, turnLog);
    } else {
      inputLog.add(const PartyInput(PartyInputKind.chooseCardOption));
      _applyCardEffects(currentPlayer, card.effects, turnLog);
    }
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
      case EffectKind.gainDiamonds:
        p.diamonds += e.amount;
        log.add('${p.name} +${e.amount} diamonds.');
        break;
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
            log.add("${victim.name}'s Strong Bond blocks the heist!");
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
      case EffectKind.swapDiamonds:
        if (others.isNotEmpty) {
          final t = others[_tape.next(others.length)];
          if (t.strongBond) {
            t.strongBond = false;
            log.add("${t.name}'s Strong Bond holds — no swap.");
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
          log.add('Coin-flip — win!');
          _applyCardEffects(p, e.win, log);
        } else {
          log.add('Coin-flip — lose.');
          _applyCardEffects(p, e.lose, log);
        }
        break;
      case EffectKind.gainPotato:
        p.potatoes++;
        log.add('${p.name} gains a potato!');
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
    // Card grants draw common + rare — exotics are market-only game-benders.
    // Legacy games keep the fixed 9-item pool their logs were recorded on.
    final pool =
        bazaar ? const [...kCommonItems, ...kRareItems] : kItemShop;
    final it = pool[_tape.next(pool.length)];
    p.items.add(it);
    log.add('${p.name} gains a ${it.label}.');
  }

  void _cardMove(PartyPlayer p, int delta, List<String> log) {
    if (delta >= 0) {
      var eaten = 0;
      for (var i = 0; i < delta; i++) {
        final n = board[p.position].nexts;
        if (n.isEmpty) break;
        p.position = n.first;
        // Card moves are still traversal — the Pac-Man economy applies to
        // every space moved through, exactly like a walked step.
        if (diamondOn(p.position)) {
          eatenDiamonds.add(p.position);
          p.diamonds += 1;
          eaten++;
        }
        if (wheels &&
            ((gameMap != null && p.position == board.length - 1) ||
                (gameMap == null && p.position == 0))) {
          eatenDiamonds.clear();
          log.add('${p.name} completed the traversal — the diamonds respawn!');
        }
      }
      log.add(eaten > 0
          ? '${p.name} moves forward ${delta.abs()} (+$eaten diamonds).'
          : '${p.name} moves forward ${delta.abs()}.');
    } else {
      p.position = gameMap == null
          ? (p.position + delta + kMainLoopLength) % kMainLoopLength
          : max(0, p.position + delta);
      log.add('${p.name} moves back ${delta.abs()}.');
    }
  }

  /// Buys one held item at the market. Catalog games sell off [marketShelf]
  /// (the bought item leaves the shelf, the player keeps perusing); legacy
  /// games sell the fixed list and walk on. A logged decision.
  void buyItem(PowerUp item) {
    assert(phase == PartyPhase.shopOffer);
    final p = currentPlayer;
    if (bazaar && !marketShelf.contains(item)) return; // not on this shelf
    final price = shelfPriceOf(item, p);
    if (p.diamonds < price || p.items.length >= kMaxItems) return;
    inputLog.add(PartyInput(PartyInputKind.buyItem, item.index));
    p.diamonds -= price;
    if (bazaar && p.coupon) {
      p.coupon = false;
      turnLog.add(
          '${p.name}\'s COUPON knocked ${item.label} to $price diamonds.');
    }
    p.items.add(item);
    turnLog.add('${p.name} bought ${item.label} for $price diamonds.');
    if (bazaar) {
      marketShelf.remove(item);
      notifyListeners();
      return; // keep perusing — LEAVE MARKET continues the walk
    }
    phase = PartyPhase.moving;
    _finishStep();
  }

  // ------------------------------------------------------------- mini-games

  /// Big Bad rounds land every [kBigBadEvery]-th round on boss maps
  /// (rules ≥ 4, cinematic games only): the map's boss spins the decree
  /// wheel over that round's mini-game.
  bool get _bigBadDue =>
      rules >= 4 &&
      wheels &&
      (gameMap?.bosses.isNotEmpty ?? false) &&
      round % kBigBadEvery == 0;

  void _startMiniGameRound() {
    standings.clear();
    skipVotes.clear();
    readySeats.clear();
    bossRuleOutcome.clear();
    // The closing round is the boss showdown when the map fields a boss.
    isBossRound = round >= totalRounds && (gameMap?.bosses.isNotEmpty ?? false);
    // THE BIG BAD'S ROUND: the boss takes the table before the game is even
    // revealed — the decree wheel spins, arming the harsh rule this round's
    // mini-game is played under (announced up front: everyone plays knowing
    // the stakes). The trailing player presses the stop — the comeback seat
    // drives the comeback tool. Every segment arms a rule, so a non-null
    // [armedBossRule] marks the spin as done when the wheel exits back here.
    if (_bigBadDue && armedBossRule == null) {
      _startWheel(WheelTier.bigBad, [finalPlayerRanking.last.index]);
      return;
    }
    // GAME RIGGER: its holder picks the round's game from a tape-drawn hand
    // instead of the table getting a random one. Holds for a real input so
    // every replica sees the same choice (and the picker drives the moment).
    if (bazaar && gamePickerSeat != null) {
      _dealGamePicks();
      phase = PartyPhase.gamePick;
      return;
    }
    currentSpec = _pickSpec();
    _lastSpecId = currentSpec!.id;
    phase = PartyPhase.minigameIntro;
  }

  /// Deals the GAME RIGGER's hand: up to 4 distinct specs off the tape,
  /// never the game just played.
  void _dealGamePicks() {
    final pool = MiniGameRegistry.enabledSpecs
        .where((s) => s.id != _lastSpecId)
        .toList();
    gamePickChoices = [];
    final hand = min(4, pool.length);
    for (var i = 0; i < hand; i++) {
      gamePickChoices.add(pool.removeAt(_tape.next(pool.length)));
    }
  }

  /// The GAME RIGGER holder picked choice [i] from [gamePickChoices]. A
  /// logged decision; resolves into the normal game-reveal intro.
  void pickMiniGame(int i) {
    assert(phase == PartyPhase.gamePick);
    if (i < 0 || i >= gamePickChoices.length) return;
    inputLog.add(PartyInput(PartyInputKind.pickMiniGame, i));
    currentSpec = gamePickChoices[i];
    _lastSpecId = currentSpec!.id;
    final picker = players[gamePickerSeat ?? currentPlayerIndex];
    turnLog.add('${picker.name} rigged the round: ${currentSpec!.name}!');
    gamePickerSeat = null;
    gamePickChoices = [];
    phase = PartyPhase.minigameIntro;
    notifyListeners();
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
    inputLog.add(const PartyInput(PartyInputKind.beginMiniGame));
    phase = PartyPhase.passPhone;
    notifyListeners();
  }

  void startMiniGameAttempt() {
    assert(phase == PartyPhase.passPhone);
    phase = PartyPhase.minigamePlaying;
    notifyListeners();
  }

  /// Seats that have confirmed the round's ready check (READY_UP_SPEC.md).
  /// Rules ≥ 5: the pump holds the match at [PartyPhase.passPhone] until
  /// every seat is in, and the LAST [readyUp] fires the transition itself —
  /// so lockstep replicas start the game on the same canonical input.
  /// Cleared each round; a full set keeps mid-round passPhone re-entries
  /// (between score submissions) pumping through.
  final Set<int> readySeats = {};

  bool get allSeatsReady => readySeats.length >= players.length;

  /// One ready confirmation per seat, cast on the ready-check screen. A
  /// logged decision (player = seat) so every replica agrees; a repeat is a
  /// no-op, not a re-log.
  void readyUp({int? player}) {
    assert(phase == PartyPhase.passPhone);
    final idx = player ?? miniPlayerIndex;
    if (idx < 0 || idx >= players.length) return;
    if (!readySeats.add(idx)) return; // one ready per seat
    inputLog.add(PartyInput(PartyInputKind.readyUp, 0, idx));
    turnLog.add('${players[idx].name} is ready '
        '(${readySeats.length}/${players.length})');
    if (allSeatsReady) {
      startMiniGameAttempt(); // notifies
      return;
    }
    notifyListeners();
  }

  /// Seats that have voted to skip this round's mini-game. A strict majority
  /// (votes * 2 > players) skips the round outright — no scores, no awards,
  /// straight on. This is also the escape hatch for a stalled table now that
  /// the auto-bank watchdog is gone: the players decide, not a timer.
  final Set<int> skipVotes = {};

  int get skipVotesNeeded => players.length ~/ 2 + 1;

  /// One vote per seat, cast during the round's mini-game (intro included).
  /// A logged decision (player = voter seat) so every replica agrees.
  void voteSkip({int? player}) {
    assert(phase == PartyPhase.minigamePlaying ||
        phase == PartyPhase.passPhone ||
        phase == PartyPhase.minigameIntro);
    final idx = player ?? miniPlayerIndex;
    if (idx < 0 || idx >= players.length) return;
    if (!skipVotes.add(idx)) return; // one vote per seat
    inputLog.add(PartyInput(PartyInputKind.voteSkip, 0, idx));
    // A skip vote implies ready (READY_UP_SPEC §2.2): a failed protest must
    // never deadlock the ready check. Derived, not logged — replay recomputes
    // it from the voteSkip input the same way.
    readySeats.add(idx);
    turnLog.add('${players[idx].name} voted to skip '
        '(${skipVotes.length}/$skipVotesNeeded needed)');
    if (skipVotes.length * 2 > players.length) {
      _skipMiniGameRound();
    } else if (rules >= 5 &&
        phase == PartyPhase.passPhone &&
        allSeatsReady) {
      startMiniGameAttempt(); // notifies
      return;
    }
    notifyListeners();
  }

  /// Majority reached: the table wasn't feeling this one. No scores, no
  /// awards, no ceremony — the board moves on. An armed decree fizzles with
  /// the skip (no results to apply it to).
  void _skipMiniGameRound() {
    turnLog.add('The table has spoken — '
        '${currentSpec?.name ?? 'the game'} is skipped!');
    if (armedBossRule != null) {
      armedBossRule = null;
      turnLog.add("The skip washes out ${bigBad?.name ?? 'the Big Bad'}'s "
          'decree — no dues today.');
    }
    standings.clear();
    skipVotes.clear();
    readySeats.clear();
    _advancePastRound(skipped: true);
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

  static const _ffaAwards = [10, 6, 4, 2, 1, 1, 1, 1]; // rules ≤ 2 replays
  // Winner-heavy podium (Brett, 2026-07-12): 10 / 5 / 1, nothing past third —
  // winning the round is what pays, showing up is not.
  static const _ffaAwardsV3 = [10, 5, 1, 0];
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
        final awards = rules >= 3 ? _ffaAwardsV3 : _ffaAwards;
        sorted[i].award = awards[min(sorted[i].rank, awards.length - 1)];
      }
    }
    // GOLDEN STAKES: the winner's diamond take is tripled (folded into the
    // award so the ceremony shows the true number), plus a potato below.
    final stakesLive = stakesArmed;
    if (stakesLive) {
      stakesArmed = false;
      for (final s in standings) {
        if (s.rank == 0) s.award *= 3;
      }
    }
    for (final s in standings) {
      if (s.player.catalyst) {
        s.player.catalyst = false;
        s.award *= 2;
      }
      s.player.diamonds += s.award;
    }
    if (stakesLive) {
      for (final s in standings) {
        if (s.rank == 0) {
          s.player.potatoes++;
          turnLog.add('GOLDEN STAKES pay out — ${s.player.name} takes '
              '${s.award} diamonds and a WHOLE POTATO!');
        }
      }
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
    _applyBossRule();
  }

  /// Applies the Big Bad's armed decree to the round's results (rules ≥ 4).
  /// Deterministic from the standings — no tape draws. Outcome lines land in
  /// [bossRuleOutcome] for the ceremony to show (PARTY UX LAW: the decree's
  /// consequence is displayed with the results, never applied invisibly).
  void _applyBossRule() {
    final rule = armedBossRule;
    if (rule == null || standings.isEmpty) return;
    armedBossRule = null;
    final name = bigBad?.name ?? 'The Big Bad';
    var worstRank = 0;
    for (final s in standings) {
      if (s.rank > worstRank) worstRank = s.rank;
    }
    switch (rule) {
      case BossRule.lastLosesPotato:
        if (worstRank == 0) {
          bossRuleOutcome.add("A dead heat — $name's decree finds no last "
              'place. Everyone keeps their potatoes.');
          return;
        }
        for (final s in standings) {
          if (s.rank != worstRank) continue;
          if (s.player.potatoes > 0) {
            s.player.potatoes--;
            bossRuleOutcome
                .add('${s.player.name} came last — $name takes a POTATO!');
          } else {
            bossRuleOutcome.add('${s.player.name} came last, but had no '
                'potato for $name to take.');
          }
        }
        return;
      case BossRule.greatRedistribution:
        var pot = 0;
        for (final p in players) {
          pot += p.diamonds;
          p.diamonds = 0;
        }
        if (pot == 0) {
          bossRuleOutcome.add('$name upended every purse — and found '
              'nothing. The pot was empty.');
          return;
        }
        bossRuleOutcome.add('$name pools every diamond: $pot 💎 in the pot.');
        var paid = 0;
        // One tranche per rank: winners split 50%, second place splits 25%,
        // dead last (when distinct from those) splits 12.5% — the comeback
        // rung. The Big Bad pockets whatever the floor divisions leave.
        void pay(int rank, int perMille, String label) {
          final group = [
            for (final s in standings)
              if (s.rank == rank) s
          ];
          if (group.isEmpty) return;
          final each = pot * perMille ~/ 1000 ~/ group.length;
          for (final s in group) {
            s.player.diamonds += each;
            paid += each;
            bossRuleOutcome
                .add('${s.player.name} ($label) claims $each 💎 of the pot.');
          }
        }

        pay(0, 500, 'winner');
        pay(1, 250, '2nd');
        if (worstRank >= 2) pay(worstRank, 125, 'last');
        bossRuleOutcome.add('$name pockets the remaining ${pot - paid} 💎.');
        return;
    }
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
    _advancePastRound(skipped: false);
    notifyListeners();
  }

  /// Shared exit from a mini-game round — the ceremony's confirm and the
  /// vote-skip both land here. Skipped rounds have no winners, so no winner
  /// spin; the checkpoint cadence still applies.
  void _advancePastRound({required bool skipped}) {
    // The round's winners, captured before standings clear next round —
    // they earn the winner spin on the maps that run one.
    final winners = skipped
        ? const <int>[]
        : [
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
      if (!skipped) turnLog.clear();
      _runOps(turnLog); // the crew relocates (and, rules ≤ 3, robs the leader)
      _runGhosts(turnLog);
      _applyPendingOrderSwap(); // QUEUE JUMPER lands at the boundary
      _turnPos = 0;
      currentPlayerIndex = turnOrder[0];
      // The winner-pays law (rules ≥ 3): a round's winners are never fed a
      // sting table. On checkpoint rounds they spin the all-positive winner
      // table (even on INTO THE VOID, whose per-round winner spins are off)
      // and sit out the checkpoint queue — see _exitWheel.
      final winnerSpin = wheels &&
          winners.isNotEmpty &&
          (_mapHasWinnerSpins || (rules >= 3 && _checkpointDue));
      if (winnerSpin) {
        _lastRoundWinners = winners;
        _startWheel(WheelTier.winner, winners);
      } else if (wheels && _checkpointDue) {
        _startWheel(WheelTier.checkpoint, _allSeats);
      } else {
        phase = PartyPhase.turnStart;
        _beginTurn();
      }
    }
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

  /// Seats that won the round whose winner spin is running — excluded from a
  /// checkpoint session chained right behind it (rules ≥ 3: winning a round
  /// must never expose you to the checkpoint's sting segments).
  List<int> _lastRoundWinners = const [];

  void _startWheel(WheelTier tier, List<int> spinners) {
    if (spinners.isEmpty) {
      _exitWheel(tier);
      return;
    }
    wheel = WheelSession(tier, List.of(spinners));
    phase = PartyPhase.wheelSpin;
  }

  /// The current spinner stops the wheel. The stop is a SKILL input: the
  /// spinner's client passes the [segment] under the pointer at the moment of
  /// the press, and that segment IS the outcome — logged as value = segment+1
  /// so every client replays the same landing. value 0 (legacy logs, and any
  /// caller that omits the segment) falls back to the old tape draw.
  void wheelStop([int segment = -1]) {
    assert(phase == PartyPhase.wheelSpin);
    final w = wheel!;
    final table = wheelTableFor(w.tier);
    final skill = segment >= 0 && segment < table.length;
    inputLog.add(PartyInput(PartyInputKind.wheelStop, skill ? segment + 1 : 0));
    final idx = skill ? segment : _drawSegment(table);
    final p = players[w.currentSpinner];
    final (summary, granted) = _applyWheelPrize(p, table[idx]);
    lastWheelResult = WheelResult(
      seq: ++_wheelSeq,
      tier: w.tier,
      spinner: w.currentSpinner,
      segmentIndex: idx,
      summary: summary,
      item: granted,
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
          // Rules ≥ 3: the winners already had their (all-positive) spin —
          // they sit out the checkpoint and its stings.
          final spinners = rules >= 3
              ? [
                  for (final s in _allSeats)
                    if (!_lastRoundWinners.contains(s)) s
                ]
              : _allSeats;
          _startWheel(WheelTier.checkpoint, spinners);
        } else {
          phase = PartyPhase.turnStart;
          _beginTurn();
        }
        break;
      case WheelTier.finale:
        phase = PartyPhase.gameOver;
        break;
      case WheelTier.bigBad:
        // Decree armed — back to the round setup, which now proceeds to
        // the game reveal (the intro screen announces the decree).
        _startMiniGameRound();
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

  (String, PowerUp?) _applyWheelPrize(PartyPlayer p, WheelSegment seg) {
    switch (seg.kind) {
      case WheelPrizeKind.item:
        return _wheelGrantItem(p, seg.item!);
      case WheelPrizeKind.randomItem:
        final item = kWheelItemPool[_tape.next(kWheelItemPool.length)];
        return _wheelGrantItem(p, item);
      case WheelPrizeKind.diamonds:
        p.diamonds += seg.amount;
        return ('${p.name} spun +${seg.amount} diamonds!', null);
      case WheelPrizeKind.loseDiamonds:
        p.diamonds = max(0, p.diamonds - seg.amount);
        return ('${p.name} spun −${seg.amount} diamonds. Brutal.', null);
      case WheelPrizeKind.atp:
        p.atp += seg.amount;
        return ('${p.name} spun +${seg.amount} ATP!', null);
      case WheelPrizeKind.potatoes:
        p.potatoes += seg.amount;
        return (
          seg.amount > 1
              ? '${p.name} spun ${seg.amount} WHOLE POTATOES!!'
              : '${p.name} spun a WHOLE POTATO!',
          null
        );
      case WheelPrizeKind.dropItem:
        if (p.items.isEmpty) {
          p.diamonds = max(0, p.diamonds - 3);
          return ('${p.name} had no item to drop — −3 diamonds instead.', null);
        }
        final dropped = p.items.removeAt(0);
        return ('${p.name} dropped ${dropped.label}!', null);
      case WheelPrizeKind.bossLastPotato:
        armedBossRule = BossRule.lastLosesPotato;
        return (
          '${bigBad?.name ?? 'The Big Bad'} decrees: whoever comes LAST in '
              'this mini-game LOSES A POTATO!',
          null
        );
      case WheelPrizeKind.bossRedistribution:
        armedBossRule = BossRule.greatRedistribution;
        return (
          '${bigBad?.name ?? 'The Big Bad'} decrees: THE GREAT '
              'REDISTRIBUTION — every diamond goes into one pot. Finish top '
              'to win it back!',
          null
        );
    }
  }

  (String, PowerUp?) _wheelGrantItem(PartyPlayer p, PowerUp item) {
    if (p.items.length >= kMaxItems) {
      p.diamonds += 5;
      return ("${p.name}'s pack is full — ${item.label} became +5 diamonds.",
          null);
    }
    p.items.add(item);
    return ('${p.name} won ${item.label} — ${item.description}.', item);
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
    // A recorded walk replays instantly — pacing is a live-table affair.
    while (phase == PartyPhase.moving) {
      advanceStep();
    }
    // Compat shims: logs recorded before these phases became held decisions
    // relied on the pump auto-advancing them. When an older log presents a
    // later input while we're holding, auto-run the hold first (re-logging
    // the synthetic input identically on every replayer). Order matters —
    // each shim can land on the next held phase.
    // Common (non-decision) cards used to auto-apply; they now hold for the
    // player's play-it tap. Old logs present their next input while we hold —
    // play the card through first (this can land on spaceResolved, so it runs
    // before that shim).
    if (phase == PartyPhase.cardDecision &&
        !(currentCard?.isDecision ?? true) &&
        input.kind != PartyInputKind.chooseCardOption) {
      chooseCardOption(0);
    }
    if (phase == PartyPhase.spaceResolved &&
        input.kind != PartyInputKind.confirmSpace) {
      confirmSpace();
    }
    if (phase == PartyPhase.minigameIntro &&
        input.kind != PartyInputKind.beginMiniGame &&
        input.kind != PartyInputKind.voteSkip) {
      beginMiniGameRound();
    }
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
        wheelStop(input.value - 1);
        break;
      case PartyInputKind.useItemOn:
        useItemOn(PowerUp.values[input.value ~/ 16], input.value % 16);
        break;
      case PartyInputKind.confirmSpace:
        confirmSpace();
        break;
      case PartyInputKind.beginMiniGame:
        beginMiniGameRound();
        break;
      case PartyInputKind.voteSkip:
        voteSkip(player: input.player);
        break;
      case PartyInputKind.pickMiniGame:
        pickMiniGame(input.value);
        break;
      case PartyInputKind.readyUp:
        readyUp(player: input.player);
        break;
      case PartyInputKind.orderRoll:
        rollForOrder(player: input.player);
        break;
      case PartyInputKind.beginMatch:
        beginMatch();
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
        case PartyPhase.passPhone:
          // Rules ≥ 5: the ready check (READY_UP_SPEC.md) — passPhone is a
          // genuine decision phase until every seat has readied. Mid-round
          // re-entries between score submissions pump through: the set is
          // still full from the round start.
          if (rules >= 5 && !allSeatsReady) return;
          startMiniGameAttempt();
          break;
        // Paced beats, held for their moment on every device (the pump used
        // to fast-forward these online, which teleported the walk and
        // skipped the landing + game-reveal dialogs entirely):
        // moving advances on each device's step ticker; spaceResolved waits
        // for the walker's COMPLETE TURN; minigameIntro for the host/local
        // reveal tap. Replays fast-forward via _apply.
        case PartyPhase.moving:
        case PartyPhase.spaceResolved:
        case PartyPhase.minigameIntro:
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
        // The GAME RIGGER's pick is a genuine input.
        case PartyPhase.gamePick:
        // Every opening-order throw (and the beginMatch tap) is an input.
        case PartyPhase.orderRoll:
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
        // Rules revision (see [rules]); absent = 2 (pre-revision saves).
        'r': rules,
        // Market catalog (see [bazaar]); absent = false (pre-catalog saves
        // keep the gated single-purchase market their logs were recorded on).
        'bazaar': bazaar,
        // The board the log was recorded on — replaying a GameMap match on
        // the legacy loop walks a different board and desyncs immediately.
        // Absent = legacy loop (pre-map saves).
        if (gameMap != null) 'map': gameMap!.id,
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
        gameMap:
            json['map'] != null ? gameMapById(json['map'] as String) : null,
        wheels: ((json['v'] as int?) ?? 1) >= 2,
        rules: (json['r'] as int?) ?? 2,
        bazaar: (json['bazaar'] as bool?) ?? false,
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

/// A [PartyController.previewBranch] result — what one fork branch offers,
/// computed fresh for the chooser UI. Derived, never stored or serialized.
class BranchPreview {
  final bool isCut;
  final bool isBail;
  final int spots; // spaces this branch commits you to before the merge
  final int diamonds; // path diamonds still sitting on that stretch
  final bool market; // a market is on the stretch
  final bool powerUp; // a power-up tile is on the stretch
  final bool risky; // a lose or wild-card space is on the stretch
  final int heatHere; // the Vat's heat where you stand (0 = cool / off)
  final int heatThere; // the heat at the branch's first spot

  const BranchPreview({
    required this.isCut,
    required this.isBail,
    required this.spots,
    required this.diamonds,
    required this.market,
    required this.powerUp,
    required this.risky,
    required this.heatHere,
    required this.heatThere,
  });
}
