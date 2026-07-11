import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ============================================================================
// SAY WHAT? — a fast phonetic-phrase decoder (somethings scale).
//
// A common phrase / idiom / name / movie line appears spelled the way it
// SOUNDS (a "fauxnetic" respelling) or as PIG LATIN. Read it OUT LOUD and tap
// the real phrase from four options. Faster correct answers earn more (the
// speed bonus decays from max to a floor over ~4.5 s). A streak multiplier
// rewards consecutive correct answers. Every ~5 correct triggers a special
// "PIG LATIN!" round for variety.
//
// The round ESCALATES: the item pool starts on easy items and mixes in medium
// and hard ones as the round clock burns and the streak climbs, while the
// per-item read time (the speed-bonus decay window) shortens. The host
// (MiniGameHost) owns the round clock, countdown, score HUD and results; this
// widget renders ONLY the play area and never calls endEarly.
// ============================================================================

// -- Palette (from the Potatuhs theme; the accent is the game's gold) --------
const Color _kBg          = Potatuhs.inkDeep;
const Color _kAccent      = Potatuhs.gold;      // brand energy accent
const Color _kGoodGreen   = Color(0xFF69F0AE);  // correct highlight
const Color _kBadRed      = Color(0xFFFF5252);  // wrong shake tint
const Color _kCardBg      = Potatuhs.inkPanel;
const Color _kCardBorder  = Color(0xFF3A352F);
const Color _kTextPrimary = Potatuhs.textPrimary;
const Color _kTextSub     = Potatuhs.textSecondary;
const Color _kTextFaint   = Potatuhs.textFaint;
const Color _kPigLatin    = Potatuhs.airForce; // the pig-latin special-round hue

// -- Timing / scoring --------------------------------------------------------
/// Seconds from answer to next item (reveal-card window).
const double _kRevealDuration = 2.2;
/// Seconds the wrong-answer shake animation lasts.
const double _kShakeDuration  = 0.45;
/// Max points for an instant correct answer.
const int    _kMaxPoints      = 120;
/// Floor points for a very slow correct answer.
const int    _kFloorPoints    = 20;
/// Base window (seconds) over which the speed bonus decays from max to floor.
/// This SHRINKS as the round escalates (see [_decayWindow]).
const double _kBaseDecay      = 4.5;
const double _kMinDecay       = 2.2;
/// Number of particle bursts on correct.
const int    _kBurstCount     = 18;
/// Streak multiplier denominator: every N consecutive correct = +1× bonus.
const int    _kStreakStep     = 3;
/// A PIG LATIN! special item fires every N correct answers.
const int    _kPigLatinEvery  = 5;

// ============================================================================
// Content bank
// ============================================================================

enum SayWhatKind {
  /// A phrase respelled the way it sounds ("AISLE BEE BACK" → I'll be back).
  fauxnetic,
  /// A homophone phrase / word ("SEE FOOD" → seafood).
  homophone,
  /// A famous name or place respelled ("GNU YORK" → New York).
  name,
  /// A movie / TV line respelled.
  line,
  /// A pig-latin round ("ELLO-HAY ORLD-WAY" → hello world).
  pigLatin,
}

enum SayWhatDifficulty { easy, med, hard }

class SayWhatItem {
  /// What's shown BIG — the phrase spelled the way it sounds (or as pig latin).
  final String sounds;

  /// The real phrase (the correct option).
  final String answer;

  /// Exactly three plausible wrong options.
  final List<String> distractors;

  final SayWhatKind kind;
  final SayWhatDifficulty difficulty;

  const SayWhatItem({
    required this.sounds,
    required this.answer,
    required this.distractors,
    required this.kind,
    required this.difficulty,
  });

  List<String> get options => [answer, ...distractors];
}

/// The bank — a varied mix of fauxnetic idioms, homophone phrases, famous
/// names / places, movie lines, and pig-latin rounds. Tagged by difficulty so
/// the round can escalate. ~50 items.
const List<SayWhatItem> kSayWhatBank = [
  // ── EASY ──────────────────────────────────────────────────────────────────
  SayWhatItem(
    sounds: 'SEE FOOD',
    answer: 'Seafood',
    distractors: ['Sea view', 'Free food', 'See you'],
    kind: SayWhatKind.homophone,
    difficulty: SayWhatDifficulty.easy,
  ),
  SayWhatItem(
    sounds: 'ICE CREAM',
    answer: 'I scream',
    distractors: ['Ice cold', 'Nice dream', 'Eye cream'],
    kind: SayWhatKind.homophone,
    difficulty: SayWhatDifficulty.easy,
  ),
  SayWhatItem(
    sounds: 'GNU YORK',
    answer: 'New York',
    distractors: ['New Yolk', 'Knee York', 'Gnaw York'],
    kind: SayWhatKind.name,
    difficulty: SayWhatDifficulty.easy,
  ),
  SayWhatItem(
    sounds: 'EGG SAMPLE',
    answer: 'Example',
    distractors: ['Egg sandwich', 'Exam pull', 'Egg simple'],
    kind: SayWhatKind.fauxnetic,
    difficulty: SayWhatDifficulty.easy,
  ),
  SayWhatItem(
    sounds: 'AISLE BEE BACK',
    answer: "I'll be back",
    distractors: ['Aisle be back', 'I be black', 'I will pack'],
    kind: SayWhatKind.line,
    difficulty: SayWhatDifficulty.easy,
  ),
  SayWhatItem(
    sounds: 'DUE NUT',
    answer: 'Donut',
    distractors: ['Do not', 'Dew nut', 'Two nut'],
    kind: SayWhatKind.homophone,
    difficulty: SayWhatDifficulty.easy,
  ),
  SayWhatItem(
    sounds: 'FOR GET',
    answer: 'Forget',
    distractors: ['Four get', 'Fore jet', 'For jet'],
    kind: SayWhatKind.homophone,
    difficulty: SayWhatDifficulty.easy,
  ),
  SayWhatItem(
    sounds: 'BUTTER FLY',
    answer: 'Butterfly',
    distractors: ['Batter fly', 'Butter fry', 'Better fly'],
    kind: SayWhatKind.homophone,
    difficulty: SayWhatDifficulty.easy,
  ),
  SayWhatItem(
    sounds: 'PEA KNUT BUTTER',
    answer: 'Peanut butter',
    distractors: ['Pee nut butter', 'Pinot butter', 'Peak nut butter'],
    kind: SayWhatKind.fauxnetic,
    difficulty: SayWhatDifficulty.easy,
  ),
  SayWhatItem(
    sounds: 'MAY BEE',
    answer: 'Maybe',
    distractors: ['May bee', 'My bee', 'Mate be'],
    kind: SayWhatKind.homophone,
    difficulty: SayWhatDifficulty.easy,
  ),
  SayWhatItem(
    sounds: 'ANY WON',
    answer: 'Anyone',
    distractors: ['Any won', 'Ani one', 'Any own'],
    kind: SayWhatKind.homophone,
    difficulty: SayWhatDifficulty.easy,
  ),
  SayWhatItem(
    sounds: 'HOLE WHEAT',
    answer: 'Whole wheat',
    distractors: ['Hole wheat', 'Hold wheat', 'Whole week'],
    kind: SayWhatKind.homophone,
    difficulty: SayWhatDifficulty.easy,
  ),
  SayWhatItem(
    sounds: 'BEE WEAR',
    answer: 'Beware',
    distractors: ['Bee wear', 'Be where', 'Bay wear'],
    kind: SayWhatKind.homophone,
    difficulty: SayWhatDifficulty.easy,
  ),
  SayWhatItem(
    sounds: 'SUM WON',
    answer: 'Someone',
    distractors: ['Sum won', 'Some own', 'Sun won'],
    kind: SayWhatKind.homophone,
    difficulty: SayWhatDifficulty.easy,
  ),
  SayWhatItem(
    sounds: 'KNIGHT MAIR',
    answer: 'Nightmare',
    distractors: ['Knight mare', 'Night mayor', 'Night mail'],
    kind: SayWhatKind.homophone,
    difficulty: SayWhatDifficulty.easy,
  ),
  SayWhatItem(
    sounds: 'CELL FISH',
    answer: 'Selfish',
    distractors: ['Sell fish', 'Cell fish', 'Shellfish'],
    kind: SayWhatKind.homophone,
    difficulty: SayWhatDifficulty.easy,
  ),
  SayWhatItem(
    sounds: 'ATE TEEN',
    answer: 'Eighteen',
    distractors: ['Ate teen', 'A teen', 'Eight teen'],
    kind: SayWhatKind.homophone,
    difficulty: SayWhatDifficulty.easy,
  ),

  // ── MEDIUM ────────────────────────────────────────────────────────────────
  SayWhatItem(
    sounds: 'DEW UNTO OTHERS',
    answer: 'Do unto others',
    distractors: ['Dew on the others', 'Due to the others', 'Do under others'],
    kind: SayWhatKind.fauxnetic,
    difficulty: SayWhatDifficulty.med,
  ),
  SayWhatItem(
    sounds: 'AISLE OF VIEW',
    answer: 'I love you',
    distractors: ['Aisle of view', 'A lot of view', 'Isle of view'],
    kind: SayWhatKind.fauxnetic,
    difficulty: SayWhatDifficulty.med,
  ),
  SayWhatItem(
    sounds: 'FOUR SCORN SEVEN',
    answer: 'Four score and seven',
    distractors: ['Four scorn seven', 'For sworn seven', 'Four scores seven'],
    kind: SayWhatKind.line,
    difficulty: SayWhatDifficulty.med,
  ),
  SayWhatItem(
    sounds: 'MAY THE FORCE BEE WITH YOU',
    answer: 'May the force be with you',
    distractors: [
      'May the fourth be with you',
      'Make the force be with you',
      'May the source be with you'
    ],
    kind: SayWhatKind.line,
    difficulty: SayWhatDifficulty.med,
  ),
  SayWhatItem(
    sounds: 'PEACE OF CAKE',
    answer: 'Piece of cake',
    distractors: ['Peace of cake', 'Peas of cake', 'Please the cake'],
    kind: SayWhatKind.fauxnetic,
    difficulty: SayWhatDifficulty.med,
  ),
  SayWhatItem(
    sounds: 'BRAKE A LEG',
    answer: 'Break a leg',
    distractors: ['Brake a leg', 'Bake a leg', 'Break a lack'],
    kind: SayWhatKind.fauxnetic,
    difficulty: SayWhatDifficulty.med,
  ),
  SayWhatItem(
    sounds: 'CEASE THE DAY',
    answer: 'Seize the day',
    distractors: ['Cease the day', 'Sees the day', 'Seas the day'],
    kind: SayWhatKind.fauxnetic,
    difficulty: SayWhatDifficulty.med,
  ),
  SayWhatItem(
    sounds: 'LOWS ANGER LESS',
    answer: 'Los Angeles',
    distractors: ['Lows anger less', 'Loose angels', 'Low sand jealous'],
    kind: SayWhatKind.name,
    difficulty: SayWhatDifficulty.med,
  ),
  SayWhatItem(
    sounds: 'SHEEK AGO',
    answer: 'Chicago',
    distractors: ['She got go', 'Chic ago', 'Sheik ago'],
    kind: SayWhatKind.name,
    difficulty: SayWhatDifficulty.med,
  ),
  SayWhatItem(
    sounds: 'CANT TAKE A HINT',
    answer: "Can't take a hint",
    distractors: ['Can take a hint', 'Can bake a hint', "Can't take a mint"],
    kind: SayWhatKind.fauxnetic,
    difficulty: SayWhatDifficulty.med,
  ),
  SayWhatItem(
    sounds: 'A PEELING',
    answer: 'Appealing',
    distractors: ['A peeling', 'A ceiling', 'Up ceiling'],
    kind: SayWhatKind.homophone,
    difficulty: SayWhatDifficulty.med,
  ),
  SayWhatItem(
    sounds: 'SUPPOSE TOE BEE',
    answer: 'Supposed to be',
    distractors: ['Suppose toe be', 'Super to bee', 'Suppose to bee'],
    kind: SayWhatKind.fauxnetic,
    difficulty: SayWhatDifficulty.med,
  ),
  SayWhatItem(
    sounds: 'HERE STRENGTH ROOM',
    answer: 'Hairs breadth (room to spare)',
    distractors: ["Here's the room", "Here's strength", 'Hair strength room'],
    kind: SayWhatKind.fauxnetic,
    difficulty: SayWhatDifficulty.med,
  ),
  SayWhatItem(
    sounds: 'HERES JOHNNY',
    answer: "Here's Johnny",
    distractors: ['Hairs Johnny', "Hear's Johnny", 'Heres Johnny said'],
    kind: SayWhatKind.line,
    difficulty: SayWhatDifficulty.med,
  ),
  SayWhatItem(
    sounds: 'BAY GULLS',
    answer: 'Bagels',
    distractors: ['Bay gulls', 'Beagles', 'Bay girls'],
    kind: SayWhatKind.homophone,
    difficulty: SayWhatDifficulty.med,
  ),
  SayWhatItem(
    sounds: 'YULE TIED GREET INGS',
    answer: 'Yuletide greetings',
    distractors: ['You tied greetings', 'Yule tide greenings', 'Yellow tied greetings'],
    kind: SayWhatKind.fauxnetic,
    difficulty: SayWhatDifficulty.med,
  ),
  SayWhatItem(
    sounds: 'FRANK LEE MY DEAR',
    answer: "Frankly, my dear",
    distractors: ['Frank Lee, my dear', 'Frankie, my dear', 'Frank, leave my dear'],
    kind: SayWhatKind.line,
    difficulty: SayWhatDifficulty.med,
  ),

  // ── HARD ──────────────────────────────────────────────────────────────────
  SayWhatItem(
    sounds: 'A BOMB IN A BULL TEA SHOP',
    answer: 'A bull in a china shop',
    distractors: [
      'A bomb in a bull tea shop',
      'A bull in a tea shop',
      'A bomb in a bully shop'
    ],
    kind: SayWhatKind.fauxnetic,
    difficulty: SayWhatDifficulty.hard,
  ),
  SayWhatItem(
    sounds: 'ODIN ARY PEE PULL',
    answer: 'Ordinary people',
    distractors: ['Odin, ary people', 'Oh dinner, people', 'Ordinary pupil'],
    kind: SayWhatKind.fauxnetic,
    difficulty: SayWhatDifficulty.hard,
  ),
  SayWhatItem(
    sounds: 'DUES PIRA DA CORPS',
    answer: 'Desperado core',
    distractors: ['Dues pyra da corps', 'Deus per a corps', 'Desperate a corps'],
    kind: SayWhatKind.fauxnetic,
    difficulty: SayWhatDifficulty.hard,
  ),
  SayWhatItem(
    sounds: 'OWL WAYS LICK A BOUT IT',
    answer: 'Always look about it',
    distractors: ['Owl ways lick about it', 'All ways lick a boat', 'Always lack a bout it'],
    kind: SayWhatKind.fauxnetic,
    difficulty: SayWhatDifficulty.hard,
  ),
  SayWhatItem(
    sounds: 'CAWL EE FLOUR',
    answer: 'Cauliflower',
    distractors: ['Call a flower', 'Coffee flower', 'Cow lee flour'],
    kind: SayWhatKind.homophone,
    difficulty: SayWhatDifficulty.hard,
  ),
  SayWhatItem(
    sounds: 'FAH REN HITE',
    answer: 'Fahrenheit',
    distractors: ['Far and height', 'Fair in height', 'Faren height'],
    kind: SayWhatKind.name,
    difficulty: SayWhatDifficulty.hard,
  ),
  SayWhatItem(
    sounds: 'ALB YOU KURK EE',
    answer: 'Albuquerque',
    distractors: ['Al, you quirky', 'Album querky', 'Alba quirky'],
    kind: SayWhatKind.name,
    difficulty: SayWhatDifficulty.hard,
  ),
  SayWhatItem(
    sounds: 'WATCH YOU TALK IN A BOUT',
    answer: "What'chu talkin' about",
    distractors: ['Watch you talk in a boat', 'What you walking about', 'Watch, you talking a bout'],
    kind: SayWhatKind.line,
    difficulty: SayWhatDifficulty.hard,
  ),
  SayWhatItem(
    sounds: 'HERE ZLUKIN AT CHEW',
    answer: "Here's lookin' at you",
    distractors: ["Here's licking at you", 'Hairs looking at chew', "Here's a lookin at zoo"],
    kind: SayWhatKind.line,
    difficulty: SayWhatDifficulty.hard,
  ),
  SayWhatItem(
    sounds: 'A NURSE THEE SEE YA',
    answer: 'Anesthesia',
    distractors: ['A nurse, see ya', 'An earth thesia', 'A nurse the sea'],
    kind: SayWhatKind.homophone,
    difficulty: SayWhatDifficulty.hard,
  ),
  SayWhatItem(
    sounds: 'DIP LOW MAT IK',
    answer: 'Diplomatic',
    distractors: ['Dip low, matic', 'Deep low matic', 'Diploma tick'],
    kind: SayWhatKind.homophone,
    difficulty: SayWhatDifficulty.hard,
  ),
  SayWhatItem(
    sounds: 'PHIL OSS OFF EE',
    answer: 'Philosophy',
    distractors: ['Fill us off, he', 'Phil, off he', 'Fill a soft e'],
    kind: SayWhatKind.homophone,
    difficulty: SayWhatDifficulty.hard,
  ),

  // ── PIG LATIN (kind == pigLatin; injected on the special round) ────────────
  SayWhatItem(
    sounds: 'ELLO-HAY ORLD-WAY',
    answer: 'Hello world',
    distractors: ['Yellow word', 'Hollow world', 'Hello word'],
    kind: SayWhatKind.pigLatin,
    difficulty: SayWhatDifficulty.easy,
  ),
  SayWhatItem(
    sounds: 'IG-PAY ATIN-LAY',
    answer: 'Pig latin',
    distractors: ['Pig eating', 'Big latin', 'Pig ladder'],
    kind: SayWhatKind.pigLatin,
    difficulty: SayWhatDifficulty.easy,
  ),
  SayWhatItem(
    sounds: 'ANK-THAY OU-YAY',
    answer: 'Thank you',
    distractors: ['Tank you', 'Thanks, you', 'Thank ewe'],
    kind: SayWhatKind.pigLatin,
    difficulty: SayWhatDifficulty.easy,
  ),
  SayWhatItem(
    sounds: 'EE-BAY EE-BAY OODBYE-GAY',
    answer: 'Bee-bee goodbye',
    distractors: ['Baby goodbye', 'Maybe goodbye', 'Bee-bee good buy'],
    kind: SayWhatKind.pigLatin,
    difficulty: SayWhatDifficulty.med,
  ),
  SayWhatItem(
    sounds: 'OTATO-PAY',
    answer: 'Potato',
    distractors: ['Tomato', 'Potatoe', 'Potato pay'],
    kind: SayWhatKind.pigLatin,
    difficulty: SayWhatDifficulty.easy,
  ),
  SayWhatItem(
    sounds: 'AME-GAY OVER-WAY',
    answer: 'Game over',
    distractors: ['Same over', 'Game oven', 'Gay maover'],
    kind: SayWhatKind.pigLatin,
    difficulty: SayWhatDifficulty.med,
  ),
  SayWhatItem(
    sounds: 'ILK-MAY AND-WAY OOKIES-CAY',
    answer: 'Milk and cookies',
    distractors: ['Milky and cookies', 'Milk in cookies', 'Silk and cookies'],
    kind: SayWhatKind.pigLatin,
    difficulty: SayWhatDifficulty.hard,
  ),
];

// ============================================================================
// Kind presentation (the little category chip above the phrase)
// ============================================================================

class _KindStyle {
  final String label;
  final IconData icon;
  const _KindStyle(this.label, this.icon);
}

const Map<SayWhatKind, _KindStyle> _kKindStyles = {
  SayWhatKind.fauxnetic: _KindStyle('SOUND IT OUT', Icons.record_voice_over_rounded),
  SayWhatKind.homophone: _KindStyle('SOUNDS LIKE', Icons.hearing_rounded),
  SayWhatKind.name: _KindStyle('NAME / PLACE', Icons.place_rounded),
  SayWhatKind.line: _KindStyle('FAMOUS LINE', Icons.movie_rounded),
  SayWhatKind.pigLatin: _KindStyle('PIG LATIN!', Icons.pets_rounded),
};

_KindStyle _styleFor(SayWhatKind k) => _kKindStyles[k]!;

// ============================================================================
// Internal state
// ============================================================================

enum _AnswerState { waiting, correct, wrong }

class _Particle {
  Offset pos;
  Offset vel;
  double life;
  final double maxLife;
  final double size;
  final Color color;
  _Particle(this.pos, this.vel, this.life, this.size, this.color)
      : maxLife = life;
}

// ============================================================================
// Widget
// ============================================================================

class SayWhatGame extends StatefulWidget {
  final MiniGameSession session;
  const SayWhatGame({super.key, required this.session});

  @override
  State<SayWhatGame> createState() => _SayWhatGameState();
}

class _SayWhatGameState extends State<SayWhatGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  Duration _lastElapsed = Duration.zero;
  double _clock = 0;

  // -- Item pools, bucketed by difficulty for escalation ---------------------
  late List<SayWhatItem> _easy;
  late List<SayWhatItem> _med;
  late List<SayWhatItem> _hard;
  late List<SayWhatItem> _pig;
  int _ei = 0, _mi = 0, _hi = 0, _pi = 0;

  // -- Current item ----------------------------------------------------------
  late SayWhatItem _item;
  late List<String> _options; // shuffled 4-option list
  bool _isPigRound = false;

  _AnswerState _answerState = _AnswerState.waiting;
  String? _tappedOption;
  double _questionTimer = 0;   // seconds since item became visible
  double _postAnswerTimer = 0; // counts down from _kRevealDuration
  double _promptIn = 0;        // 0→1 ease-in of the fauxnetic prompt

  // -- Streak / progression --------------------------------------------------
  int _streak = 0;
  int _lastStreakMultiplier = 1;
  int _correctCount = 0; // total correct — drives the pig-latin cadence

  // -- Shake -----------------------------------------------------------------
  double _shakeT = 0;

  // -- Particles -------------------------------------------------------------
  final List<_Particle> _particles = [];

  // -- Layout ----------------------------------------------------------------
  Size _fieldSize = Size.zero;

  // First-item teaching hint ("Read it OUT LOUD…"), fades after a few seconds.
  bool _showHint = true;
  double _hintFade = 1.0;

  bool _started = false;

  // ==========================================================================
  // Init / dispose
  // ==========================================================================

  @override
  void initState() {
    super.initState();
    _buildPools();
    _loadNextItem();
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot — plays itself correctly, human-paced.
    widget.session.autoPilot = _autoStep;
    widget.session.autoPilotInterval = const Duration(milliseconds: 1150);
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ==========================================================================
  // ATTRACT autopilot
  // ==========================================================================

  /// One hands-free move per host tick. While an item awaits an answer, taps the
  /// correct phrase (promptly, so the speed bonus lands); while the reveal card
  /// is up, advances. The host owns clock + score; the bot banks real points.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_answerState == _AnswerState.waiting) {
      _onOptionTap(_item.answer);
    } else {
      _skipReveal();
    }
  }

  // ==========================================================================
  // Pools + escalation
  // ==========================================================================

  void _buildPools() {
    _easy = kSayWhatBank
        .where((i) => i.kind != SayWhatKind.pigLatin &&
            i.difficulty == SayWhatDifficulty.easy)
        .toList()
      ..shuffle(_rng);
    _med = kSayWhatBank
        .where((i) => i.kind != SayWhatKind.pigLatin &&
            i.difficulty == SayWhatDifficulty.med)
        .toList()
      ..shuffle(_rng);
    _hard = kSayWhatBank
        .where((i) => i.kind != SayWhatKind.pigLatin &&
            i.difficulty == SayWhatDifficulty.hard)
        .toList()
      ..shuffle(_rng);
    _pig = kSayWhatBank
        .where((i) => i.kind == SayWhatKind.pigLatin)
        .toList()
      ..shuffle(_rng);
    _ei = _mi = _hi = _pi = 0;
  }

  SayWhatItem _drawFrom(List<SayWhatItem> pool, int Function() get,
      void Function(int) set) {
    if (pool.isEmpty) return _easy[_ei++ % _easy.length];
    final n = get();
    final item = pool[n % pool.length];
    final next = n + 1;
    if (next % pool.length == 0) pool.shuffle(_rng);
    set(next);
    return item;
  }

  /// Progress fraction of the round (0 at start → 1 as the clock runs out),
  /// used to bias difficulty and shorten the read window.
  double _progress() {
    final total = widget.session.spec.durationSeconds;
    if (total <= 0) return 0;
    final elapsed = total - widget.session.remaining.inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  /// The speed-bonus decay window SHRINKS as the round escalates — later items
  /// give less time to earn the full bonus.
  double _decayWindow() {
    final p = _progress();
    return _kBaseDecay - (_kBaseDecay - _kMinDecay) * p;
  }

  /// Pick the next non-pig item. Difficulty is biased by round progress AND the
  /// current streak: early/low-streak → mostly easy; late/high-streak → hard
  /// creeps in. A perfect run is humanly unreachable because the pool tilts
  /// toward hard while the read window collapses.
  SayWhatItem _drawRegular() {
    final p = _progress();
    // A "heat" value 0→~1.4: how far into the escalation we are.
    final heat = (p + _streak / 12.0).clamp(0.0, 1.4);
    final roll = _rng.nextDouble() * 1.4;
    if (roll < heat - 0.7 && _hard.isNotEmpty) {
      return _drawFrom(_hard, () => _hi, (v) => _hi = v);
    }
    if (roll < heat && _med.isNotEmpty) {
      return _drawFrom(_med, () => _mi, (v) => _mi = v);
    }
    return _drawFrom(_easy, () => _ei, (v) => _ei = v);
  }

  void _loadNextItem() {
    // A PIG LATIN! special round every _kPigLatinEvery correct answers.
    _isPigRound = _correctCount > 0 &&
        _correctCount % _kPigLatinEvery == 0 &&
        _answerState == _AnswerState.correct;
    if (_isPigRound && _pig.isNotEmpty) {
      _item = _drawFrom(_pig, () => _pi, (v) => _pi = v);
    } else {
      _isPigRound = false;
      _item = _drawRegular();
    }
    _options = _item.options.toList()..shuffle(_rng);
    _answerState = _AnswerState.waiting;
    _tappedOption = null;
    _questionTimer = 0;
    _postAnswerTimer = 0;
    _shakeT = 0;
    _promptIn = 0;
  }

  // ==========================================================================
  // Game loop
  // ==========================================================================

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    _clock += dt;
    if (widget.session.isRunning) {
      if (!_started) _started = true;
      _simulate(dt);
    }
    if (mounted) setState(() {});
  }

  void _simulate(double dt) {
    if (_promptIn < 1) _promptIn = (_promptIn + dt * 4.5).clamp(0.0, 1.0);

    if (_answerState == _AnswerState.waiting) {
      _questionTimer += dt;
    } else {
      _postAnswerTimer -= dt;
      if (_shakeT > 0) _shakeT -= dt / _kShakeDuration;
      if (_postAnswerTimer <= 0) _loadNextItem();
    }

    // Fade the teaching hint out after a few seconds of the first item.
    if (_showHint) {
      if (_questionTimer > 2.4 || _correctCount > 0) {
        _hintFade -= dt * 1.4;
        if (_hintFade <= 0) {
          _hintFade = 0;
          _showHint = false;
        }
      }
    }

    _particles.removeWhere((p) {
      p.life -= dt;
      p.pos += p.vel * dt;
      p.vel = p.vel * math.pow(0.12, dt).toDouble();
      return p.life <= 0;
    });
  }

  void _skipReveal() {
    if (_answerState == _AnswerState.waiting) return;
    _postAnswerTimer = 0;
    setState(() {});
  }

  // ==========================================================================
  // Scoring
  // ==========================================================================

  int _speedBonus() {
    final frac = (_questionTimer / _decayWindow()).clamp(0.0, 1.0);
    return (_kMaxPoints - (_kMaxPoints - _kFloorPoints) * frac).round();
  }

  int _streakMultiplier() => 1 + (_streak ~/ _kStreakStep);

  // ==========================================================================
  // Input
  // ==========================================================================

  void _onOptionTap(String option) {
    if (!widget.session.isRunning) return;
    if (_answerState != _AnswerState.waiting) return;

    _tappedOption = option;
    final correct = option == _item.answer;

    if (correct) {
      _answerState = _AnswerState.correct;
      _streak++;
      _correctCount++;
      final mult = _streakMultiplier();
      _lastStreakMultiplier = mult;
      // Pig-latin rounds pay a small variety bonus.
      final base = _speedBonus() + (_item.kind == SayWhatKind.pigLatin ? 30 : 0);
      final pts = base * mult;
      widget.session.addScore(pts);
      widget.session.noteStreak(_streak);
      _burst(_fieldSize.center(Offset.zero), _kGoodGreen);
      if (_streak % _kStreakStep == 0 && _streak > 0) {
        _burst(_fieldSize.center(Offset.zero), _kAccent, count: 12);
      }
    } else {
      _answerState = _AnswerState.wrong;
      _streak = 0;
      _lastStreakMultiplier = 1;
      _shakeT = 1.0;
      // 0-point wrong answer — no deduction; keep it fast and fun.
    }

    _postAnswerTimer = _kRevealDuration;
  }

  // ==========================================================================
  // Particles
  // ==========================================================================

  void _burst(Offset at, Color color, {int count = _kBurstCount}) {
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed = 60.0 + _rng.nextDouble() * 140.0;
      _particles.add(_Particle(
        at,
        Offset(math.cos(angle), math.sin(angle)) * speed,
        0.4 + _rng.nextDouble() * 0.5,
        1.5 + _rng.nextDouble() * 3.0,
        color.withValues(alpha: 0.7 + _rng.nextDouble() * 0.3),
      ));
    }
  }

  // ==========================================================================
  // Build
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
      final accent = _isPigRound ? _kPigLatin : _kAccent;
      return ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BgPainter(
                  clock: _clock,
                  accent: accent,
                  particles: _particles,
                ),
              ),
            ),
            Positioned.fill(
              child: _started ? _buildPlayUI(accent) : _buildReadyState(),
            ),
            if (_started)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _answerState != _AnswerState.waiting
                        ? _buildRevealCard(accent)
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  // -- Ready state -----------------------------------------------------------

  Widget _buildReadyState() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.record_voice_over_rounded,
                  size: 40, color: _kAccent),
              const SizedBox(height: 14),
              Text('SAY WHAT?',
                  style: Potatuhs.display(size: 30, color: _kTextPrimary)),
              const SizedBox(height: 10),
              Text(
                'A phrase spelled the way it SOUNDS. Read it out loud — then tap the real phrase. Faster answers score more.',
                textAlign: TextAlign.center,
                style: Potatuhs.body(size: 14, color: _kTextSub, height: 1.45),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _kAccent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _kAccent.withValues(alpha: 0.35), width: 1),
                ),
                child: Text(
                  '"AISLE BEE BACK"  →  I\'ll be back',
                  textAlign: TextAlign.center,
                  style: Potatuhs.body(
                    size: 13,
                    weight: FontWeight.w700,
                    color: _kAccent.withValues(alpha: 0.95),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -- Play UI ---------------------------------------------------------------

  Widget _buildPlayUI(Color accent) {
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double revealReserve = 140;

          final content = Column(
            children: [
              _buildHUD(accent),
              Flexible(
                flex: 3,
                fit: FlexFit.loose,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildKindChip(accent),
                      const SizedBox(height: 14),
                      _buildPrompt(accent),
                      if (_showHint) ...[
                        const SizedBox(height: 12),
                        Opacity(opacity: _hintFade, child: _buildHint()),
                      ],
                    ],
                  ),
                ),
              ),
              Flexible(
                flex: 5,
                fit: FlexFit.tight,
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  child: _buildOptionGrid(),
                ),
              ),
              SizedBox(
                height: _answerState != _AnswerState.waiting ? revealReserve : 0,
              ),
            ],
          );

          final bool tooShort = constraints.maxHeight < 460;
          if (tooShort) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 460,
                  maxHeight: math.max(460, constraints.maxHeight),
                ),
                child: content,
              ),
            );
          }
          return content;
        },
      ),
    );
  }

  // -- HUD -------------------------------------------------------------------

  Widget _buildHUD(Color accent) {
    final score = widget.session.score;
    final remaining = widget.session.remaining;
    final secs = remaining.inSeconds;
    final tenths = (remaining.inMilliseconds / 100).floor() % 10;
    final mult = _lastStreakMultiplier;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.82),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$score',
            style: Potatuhs.body(
              size: 20,
              weight: FontWeight.w900,
              color: _kTextPrimary,
            ).copyWith(shadows: [Shadow(color: accent, blurRadius: 8)]),
          ),
          const SizedBox(width: 6),
          if (_streak >= _kStreakStep)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _kAccent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: _kAccent.withValues(alpha: 0.7), width: 1),
              ),
              child: Text(
                '×$mult',
                style: Potatuhs.body(
                  size: 13,
                  weight: FontWeight.w800,
                  color: _kAccent,
                ),
              ),
            ),
          const Spacer(),
          Text(
            '$secs.$tenths',
            style: Potatuhs.body(
              size: 18,
              weight: FontWeight.w700,
              color: secs < 5 ? _kBadRed : _kTextPrimary.withValues(alpha: 0.82),
            ).copyWith(
              shadows: secs < 5
                  ? const [Shadow(color: _kBadRed, blurRadius: 10)]
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // -- Kind chip -------------------------------------------------------------

  Widget _buildKindChip(Color accent) {
    final style = _styleFor(_item.kind);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.70), width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 13, color: accent),
          const SizedBox(width: 5),
          Text(
            style.label,
            style: Potatuhs.label(size: 12, color: accent)
                .copyWith(letterSpacing: 1.6),
          ),
        ],
      ),
    );
  }

  // -- Prompt (the big fauxnetic phrase) -------------------------------------

  Widget _buildPrompt(Color accent) {
    // A gentle ease-in scale/opacity as each new phrase lands.
    final ease = Curves.easeOut.transform(_promptIn);
    return Column(
      children: [
        Text(
          'READ IT OUT LOUD',
          style: Potatuhs.label(size: 11, color: _kTextFaint),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: ease,
          child: Transform.scale(
            scale: 0.92 + 0.08 * ease,
            child: Text(
              _item.sounds,
              textAlign: TextAlign.center,
              style: Potatuhs.display(size: 30, color: _kTextPrimary).copyWith(
                shadows: [
                  Shadow(color: accent.withValues(alpha: 0.55), blurRadius: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -- Teaching hint ---------------------------------------------------------

  Widget _buildHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _kCardBg.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kCardBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lightbulb_outline_rounded,
              size: 14, color: _kAccent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Say it out loud — it sounds like a common phrase.',
              style: Potatuhs.body(size: 12, color: _kTextSub, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  // -- Option grid -----------------------------------------------------------

  Widget _buildOptionGrid() {
    const double spacing = 10;
    const int cols = 1; // single column: phrases can be long, keep them legible
    final int rows = _options.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        double aspect = 4.0;
        if (constraints.maxHeight.isFinite && constraints.maxHeight > 0) {
          final double cellH =
              (constraints.maxHeight - spacing * (rows - 1)) / rows;
          if (cellH > 0) {
            aspect = (constraints.maxWidth / cellH).clamp(2.6, 7.0);
          }
        }

        return GridView.count(
          crossAxisCount: cols,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: aspect,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: _options.map(_buildOptionCard).toList(),
        );
      },
    );
  }

  Widget _buildOptionCard(String option) {
    final isCorrect = option == _item.answer;
    final isTapped = option == _tappedOption;
    final answered = _answerState != _AnswerState.waiting;

    Color borderColor = _kCardBorder;
    Color bgColor = _kCardBg;
    Color textColor = _kTextPrimary;

    if (answered) {
      if (isCorrect) {
        borderColor = _kGoodGreen.withValues(alpha: 0.9);
        bgColor = _kGoodGreen.withValues(alpha: 0.12);
        textColor = _kGoodGreen;
      } else if (isTapped && _answerState == _AnswerState.wrong) {
        borderColor = _kBadRed.withValues(alpha: 0.9);
        bgColor = _kBadRed.withValues(alpha: 0.10);
        textColor = _kBadRed;
      } else {
        borderColor = _kCardBorder.withValues(alpha: 0.35);
        textColor = _kTextSub;
      }
    }

    double shakeOffsetX = 0;
    if (isTapped && _answerState == _AnswerState.wrong && _shakeT > 0) {
      final t = (1.0 - _shakeT).clamp(0.0, 1.0);
      shakeOffsetX = math.sin(t * math.pi * 5) * 7.0 * _shakeT;
    }

    return GestureDetector(
      onTap: () => _onOptionTap(option),
      child: Transform.translate(
        offset: Offset(shakeOffsetX, 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.6),
            boxShadow: answered && isCorrect
                ? [
                    BoxShadow(
                      color: _kGoodGreen.withValues(alpha: 0.25),
                      blurRadius: 16,
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                option,
                textAlign: TextAlign.center,
                style: Potatuhs.body(
                  size: 16,
                  weight: FontWeight.w700,
                  color: textColor,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -- Reveal card (post-answer) ---------------------------------------------

  Widget _buildRevealCard(Color accent) {
    final correct = _answerState == _AnswerState.correct;
    final mult = _lastStreakMultiplier;
    final pts = correct
        ? (_speedBonus() + (_item.kind == SayWhatKind.pigLatin ? 30 : 0)) * mult
        : 0;
    final headline = correct
        ? (mult > 1 ? '+$pts   ×$mult streak!' : '+$pts')
        : 'It was…';

    return GestureDetector(
      onTap: _skipReveal,
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: ValueKey(_item.sounds),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: correct
              ? _kGoodGreen.withValues(alpha: 0.10)
              : accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: correct
                ? _kGoodGreen.withValues(alpha: 0.55)
                : _kBadRed.withValues(alpha: 0.55),
            width: 1.4,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              headline,
              style: Potatuhs.body(
                size: 15,
                weight: FontWeight.w900,
                color: correct ? _kGoodGreen : _kBadRed,
              ),
            ),
            const SizedBox(height: 4),
            // The sounds-like → real-phrase pairing (always shows the answer).
            Text(
              '"${_item.sounds}"  →  ${_item.answer}',
              style: Potatuhs.body(
                size: 13,
                weight: FontWeight.w800,
                color: accent,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'TAP TO CONTINUE',
                  style: Potatuhs.label(
                    size: 10,
                    color: accent.withValues(alpha: 0.7),
                  ).copyWith(letterSpacing: 1.0),
                ),
                const SizedBox(width: 3),
                Icon(Icons.arrow_forward,
                    size: 12, color: accent.withValues(alpha: 0.7)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Background + particles painter
// ============================================================================

class _BgPainter extends CustomPainter {
  final double clock;
  final Color accent;
  final List<_Particle> particles;

  const _BgPainter({
    required this.clock,
    required this.accent,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintOrbs(canvas, size);
    _paintParticles(canvas);
  }

  void _paintBackground(Canvas canvas, Size size) {
    // Gradient background (inkDeep → dark tint of the accent), never flat #000.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _kBg,
            Color.lerp(_kBg, accent, 0.10)!,
          ],
        ).createShader(Offset.zero & size),
    );

    // Radial accent glow from center-top.
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.15),
      size.width * 0.65,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: 0.10),
            accent.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.15),
          radius: size.width * 0.65,
        )),
    );

    // Deterministic star field — no shimmer on setState.
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.10);
    for (var i = 0; i < 40; i++) {
      final fx = (i * 73 % 97) / 97.0;
      final fy = (i * 41 % 61) / 61.0 * 0.70;
      canvas.drawCircle(
        Offset(fx * size.width, fy * size.height),
        0.7 + (i % 3) * 0.45,
        starPaint,
      );
    }
  }

  void _paintOrbs(Canvas canvas, Size size) {
    final t = clock * 0.22;

    final orb1x = size.width * (0.15 + 0.08 * math.cos(t));
    final orb1y = size.height * (0.72 + 0.05 * math.sin(t * 0.7));
    canvas.drawCircle(
      Offset(orb1x, orb1y),
      size.width * 0.28,
      Paint()
        ..color = accent.withValues(alpha: 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );

    final orb2x = size.width * (0.82 + 0.06 * math.cos(t * 1.3 + 1.0));
    final orb2y = size.height * (0.38 + 0.07 * math.sin(t * 0.9 + 2.0));
    canvas.drawCircle(
      Offset(orb2x, orb2y),
      size.width * 0.22,
      Paint()
        ..color = Potatuhs.orange.withValues(alpha: 0.03)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35),
    );
  }

  void _paintParticles(Canvas canvas) {
    for (final p in particles) {
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(
        p.pos,
        p.size * alpha,
        Paint()..color = p.color.withValues(alpha: p.color.a * alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_BgPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards, drawn with the game's REAL styling
// (the fauxnetic prompt, the option cards, the streak badge, the reveal card).
// Static + cheap: painted once in the intro carousel, never per-frame.
// ═══════════════════════════════════════════════════════════════════════════

void _legendText(
  Canvas canvas,
  String text,
  Offset at,
  double fontSize,
  Color color, {
  FontWeight weight = FontWeight.w700,
  String family = Potatuhs.bodyFont,
  double maxWidth = double.infinity,
  bool alignLeft = false,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: family,
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        height: 1.2,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: alignLeft ? TextAlign.left : TextAlign.center,
    maxLines: 2,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth.isFinite ? math.max(0, maxWidth) : maxWidth);
  final dx = alignLeft ? at.dx : at.dx - tp.width / 2;
  tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
}

/// One option card — the exact look of [_buildOptionCard].
void _legendOptionCard(
  Canvas canvas,
  Rect r,
  String label, {
  Color border = _kCardBorder,
  Color bg = _kCardBg,
  Color text = _kTextPrimary,
  bool glow = false,
  double fontSize = 11,
}) {
  if (r.width <= 0 || r.height <= 0) return;
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(12));
  if (glow) {
    canvas.drawRRect(
      rr,
      Paint()
        ..color = _kGoodGreen.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }
  canvas.drawRRect(rr, Paint()..color = bg);
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = border,
  );
  _legendText(canvas, label, r.center, fontSize, text, maxWidth: r.width - 16);
}

/// The kind chip pill (mirrors [_buildKindChip]).
void _legendKindChip(Canvas canvas, Offset center, String label, Color accent) {
  final r = Rect.fromCenter(center: center, width: 120, height: 22);
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(11));
  canvas.drawRRect(rr, Paint()..color = accent.withValues(alpha: 0.14));
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = accent.withValues(alpha: 0.70),
  );
  _legendText(canvas, label, center, 9.5, accent, weight: FontWeight.w800);
}

// ── Frame 1: the core loop — a fauxnetic phrase + four options ──────────────

void _legendAsk(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;

  _legendKindChip(canvas, Offset(w * 0.5, h * 0.08), 'SOUND IT OUT', _kAccent);
  _legendText(canvas, 'READ IT OUT LOUD', Offset(w * 0.5, h * 0.19), 9,
      _kTextFaint, weight: FontWeight.w700);
  _legendText(canvas, 'AISLE BEE BACK', Offset(w * 0.5, h * 0.30), 16,
      _kTextPrimary,
      weight: FontWeight.w400, family: Potatuhs.displayFont, maxWidth: w * 0.9);

  const opts = ["I'll be back", 'Aisle be back', 'I will pack', 'I be black'];
  final gapY = h * 0.03;
  final ch = (h * 0.52 - gapY * 3) / 4;
  for (var i = 0; i < 4; i++) {
    final r = Rect.fromLTWH(w * 0.10, h * 0.44 + i * (ch + gapY), w * 0.80, ch);
    _legendOptionCard(canvas, r, opts[i], fontSize: 9.5);
  }
}

// ── Frame 2: scoring — the speed bonus decays 120 → 20 ─────────────────────

void _legendSpeed(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;

  final card = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.20), width: w * 0.62, height: h * 0.15);
  _legendOptionCard(canvas, card, "I'll be back",
      border: _kGoodGreen.withValues(alpha: 0.9),
      bg: _kGoodGreen.withValues(alpha: 0.12),
      text: _kGoodGreen,
      glow: true);
  _legendText(canvas, '+120', Offset(w * 0.5, h * 0.40), 19, _kAccent,
      weight: FontWeight.w900);

  final bar = Rect.fromLTWH(w * 0.12, h * 0.58, w * 0.76, 11);
  final rr = RRect.fromRectAndRadius(bar, const Radius.circular(6));
  canvas.drawRRect(rr, Paint()..color = _kCardBg);
  canvas.drawRRect(
    rr,
    Paint()
      ..shader = LinearGradient(
        colors: [
          _kAccent.withValues(alpha: 0.85),
          _kAccent.withValues(alpha: 0.10),
        ],
      ).createShader(bar),
  );
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _kCardBorder,
  );
  _legendText(canvas, '120', Offset(bar.left, bar.top - 12), 10, _kAccent,
      weight: FontWeight.w800);
  _legendText(canvas, '20', Offset(bar.right, bar.top - 12), 10, _kTextSub,
      weight: FontWeight.w800);
  _legendText(canvas, 'INSTANT', Offset(bar.left + 4, bar.bottom + 12), 8.5,
      _kTextSub);
  _legendText(canvas, 'READ FAST', Offset(bar.right - 4, bar.bottom + 12), 8.5,
      _kTextSub);
}

// ── Frame 3: the pig-latin special round ────────────────────────────────────

void _legendPigLatin(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;

  _legendKindChip(canvas, Offset(w * 0.5, h * 0.12), 'PIG LATIN!', _kPigLatin);
  _legendText(canvas, 'ELLO-HAY ORLD-WAY', Offset(w * 0.5, h * 0.32), 15,
      _kTextPrimary,
      weight: FontWeight.w400, family: Potatuhs.displayFont, maxWidth: w * 0.9);

  final card = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.58), width: w * 0.62, height: h * 0.16);
  _legendOptionCard(canvas, card, 'Hello world',
      border: _kGoodGreen.withValues(alpha: 0.9),
      bg: _kGoodGreen.withValues(alpha: 0.12),
      text: _kGoodGreen,
      glow: true);
  _legendText(canvas, 'every 5 correct — worth bonus points',
      Offset(w * 0.5, h * 0.82), 10, _kTextSub,
      weight: FontWeight.w500, maxWidth: w * 0.9);
}

// ── Frame 4: streak multiplier + the reveal card ────────────────────────────

void _legendStreak(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;

  final check = Paint()
    ..color = _kGoodGreen
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  for (var i = 0; i < 3; i++) {
    final c = Offset(w * (0.16 + i * 0.18), h * 0.15);
    final r = Rect.fromCenter(center: c, width: w * 0.13, height: h * 0.14);
    _legendOptionCard(canvas, r, '',
        border: _kGoodGreen.withValues(alpha: 0.9),
        bg: _kGoodGreen.withValues(alpha: 0.12));
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - 5, c.dy)
        ..lineTo(c.dx - 1.5, c.dy + 4)
        ..lineTo(c.dx + 5.5, c.dy - 4),
      check,
    );
  }

  final arrow = Paint()
    ..color = _kAccent
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final ay = h * 0.15;
  canvas.drawLine(Offset(w * 0.60, ay), Offset(w * 0.70, ay), arrow);
  canvas.drawLine(Offset(w * 0.665, ay - 4), Offset(w * 0.70, ay), arrow);
  canvas.drawLine(Offset(w * 0.665, ay + 4), Offset(w * 0.70, ay), arrow);
  final badge = Rect.fromCenter(
      center: Offset(w * 0.82, ay), width: w * 0.14, height: h * 0.12);
  final brr = RRect.fromRectAndRadius(badge, const Radius.circular(6));
  canvas.drawRRect(brr, Paint()..color = _kAccent.withValues(alpha: 0.18));
  canvas.drawRRect(
    brr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _kAccent.withValues(alpha: 0.7),
  );
  _legendText(canvas, '×2', badge.center, 12, _kAccent, weight: FontWeight.w800);

  final cardR = Rect.fromLTRB(w * 0.08, h * 0.38, w * 0.92, h * 0.90);
  final crr = RRect.fromRectAndRadius(cardR, const Radius.circular(16));
  canvas.drawRRect(crr, Paint()..color = _kGoodGreen.withValues(alpha: 0.10));
  canvas.drawRRect(
    crr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _kGoodGreen.withValues(alpha: 0.55),
  );
  final tx = cardR.left + 14;
  final maxW = cardR.width - 28;
  _legendText(canvas, '+240   ×2 streak!', Offset(tx, cardR.top + h * 0.10),
      12.5, _kGoodGreen,
      weight: FontWeight.w900, alignLeft: true, maxWidth: maxW);
  _legendText(canvas, '"AISLE BEE BACK"  →  I\'ll be back',
      Offset(tx, cardR.top + h * 0.28), 10.5, _kAccent,
      weight: FontWeight.w800, alignLeft: true, maxWidth: maxW);
}

/// The visual manual for Say What? — wired into the registry spec.
final List<LegendFrame> sayWhatLegendFrames = [
  const LegendFrame(
      caption: 'Read the phrase out loud — tap what it really says',
      paint: _legendAsk),
  const LegendFrame(
      caption: 'Answer fast — the bonus falls 120 → 20',
      paint: _legendSpeed),
  const LegendFrame(
      caption: 'Every 5 correct → a PIG LATIN! bonus round',
      paint: _legendPigLatin),
  const LegendFrame(
      caption: '3 in a row = ×2 — the reveal shows the real phrase',
      paint: _legendStreak),
];
