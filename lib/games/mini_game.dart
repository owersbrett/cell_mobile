import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter/material.dart';

/// Lifecycle of one mini-game run, driven by [MiniGameHost].
enum MiniGamePhase { intro, countdown, playing, finished }

/// Shared state for a single run of a mini-game.
///
/// The host owns the clock: it starts the run, ticks the remaining time and
/// ends the run. Game widgets read [isRunning] / [remaining], and report
/// points through [addScore]. A game may end itself early with [endEarly]
/// (e.g. a sudden-death fail state) — the score it has at that moment stands.
class MiniGameSession extends ChangeNotifier {
  MiniGameSession({required this.spec, this.playerLabel});

  final MiniGameSpec spec;

  /// Shown during intro/results in party mode ("Tater — Team Red"). Null in solo.
  final String? playerLabel;

  /// Per-game autopilot hook for ATTRACT mode. A game that knows how to play
  /// itself sets this in its `initState` to a callback that reads its OWN state
  /// and makes one smart move (dismiss a card, replay the sequence, tap the
  /// correct answer…). The host calls it on the autopilot cadence (~250ms)
  /// while [isRunning]; games that don't set it fall back to the generic driver.
  /// Not a notifier field — it's an imperative hook, cleared on the game's
  /// dispose. See `MiniGameHost._botTick` and `docs`/the reference autopilot.
  void Function()? autoPilot;

  /// Minimum time between [autoPilot] calls in ATTRACT mode. Default zero = the
  /// host drives it every ~250ms tick (right for action games — catching,
  /// steering, timing). Games where acting every tick looks SUPERHUMAN — the
  /// multiple-choice / typing quizzes that would else bank a correct answer 4×/s
  /// — set this to ~1s so the bot answers at a human, watchable pace. The host
  /// paces the calls; the game logic doesn't change.
  Duration autoPilotInterval = Duration.zero;

  MiniGamePhase _phase = MiniGamePhase.intro;
  int _score = 0;
  Duration _remaining = Duration.zero;
  Duration _bonusTime = Duration.zero;
  int _bestStreak = 0;
  bool _paused = false;

  MiniGamePhase get phase => _phase;
  int get score => _score;
  Duration get remaining => _remaining;
  Duration get bonusTime => _bonusTime;

  /// True while a round is live AND not paused. Games gate their own ticking on
  /// this, so pausing (host [hostSetPaused]) halts them without extra wiring.
  bool get isRunning => _phase == MiniGamePhase.playing && !_paused;

  /// True while the host has frozen a live round (pause modal up). Lets a game
  /// distinguish a PAUSE (freeze + later resume) from the round actually ending
  /// — needed by games with their own wall-clock stopwatch (e.g. The Wait).
  bool get isPaused => _paused && _phase == MiniGamePhase.playing;

  /// Host-only: freeze/unfreeze the run. Flips [isRunning] so games stop/resume.
  void hostSetPaused(bool paused) {
    if (_paused == paused) return;
    _paused = paused;
    notifyListeners();
  }

  /// Longest run of consecutive successes a game reported via [noteStreak].
  /// Surfaced on the results screen as a streak award (20/30 = mastery).
  int get bestStreak => _bestStreak;

  /// Games that track a combo/streak report their *current* streak here on
  /// every success; the session keeps the high-water mark. No-op outside play.
  void noteStreak(int currentStreak) {
    if (!isRunning) return;
    if (currentStreak > _bestStreak) {
      _bestStreak = currentStreak;
      notifyListeners();
    }
  }

  void addScore(int delta) {
    if (!isRunning) return;
    _score = (_score + delta).clamp(0, 1 << 31);
    notifyListeners();
  }

  /// DISABLED (no-op). Every round is a fixed, host-owned length. A game that
  /// added clock time on scoring let ATTRACT mode's always-scoring autopilot
  /// extend the round forever (the loop hung on Molecule Mixer). No game may
  /// lengthen its own round; kept as a method so existing call sites compile.
  void addTime(Duration d) {}

  /// Game-initiated early finish (fail states, perfect clears).
  void endEarly() {
    if (!isRunning) return;
    _setPhase(MiniGamePhase.finished);
  }

  // Host-side controls.
  void hostSetPhase(MiniGamePhase phase) => _setPhase(phase);

  void hostTick(Duration remaining) {
    _remaining = remaining;
    notifyListeners();
  }

  void hostReset() {
    _score = 0;
    _remaining = Duration(seconds: spec.durationSeconds);
    _bonusTime = Duration.zero;
    _bestStreak = 0;
    _paused = false;
    _setPhase(MiniGamePhase.intro);
  }

  void _setPhase(MiniGamePhase phase) {
    if (_phase == phase) return;
    _phase = phase;
    notifyListeners();
  }
}

typedef MiniGameBuilder = Widget Function(
    BuildContext context, MiniGameSession session);

/// Paints ONE manual/legend card into [size] using a game's OWN rendering
/// primitives. The point of the visual manual is that it shows the LITERAL
/// components a player meets in play (a graded spud, a defect tell, a bin) —
/// drawn by the same code the game uses — rather than an abstract diagram or a
/// line of text. Keep these cheap and self-contained: they render statically in
/// the intro carousel, not every frame.
typedef LegendPainter = void Function(Canvas canvas, Size size);

/// One card in a game's visual manual carousel, shown by [MiniGameHost] on the
/// intro screen. [paint] draws a real in-game component; [caption] names it.
class LegendFrame {
  final String caption;
  final LegendPainter paint;
  const LegendFrame({required this.caption, required this.paint});
}

/// Declarative description of a mini-game: identity, rules, scoring and the
/// widget that plays it. One spec serves both Explore (solo score attack)
/// and Party mode (pass-and-play, highest score wins the round).
class MiniGameSpec {
  final String id;
  final String name;
  final BioScale scale;

  /// One-line hook shown under the name ("Ignite matter from the void").
  final String tagline;

  /// Short imperative rules, one action each ("Tap blue sparks: +10").
  final List<String> rules;

  /// One line that makes winning unambiguous ("Most matter when time runs out wins").
  final String howToWin;

  final int durationSeconds;

  /// What the score counts ("matter", "collisions", "molecules").
  final String scoreUnit;

  /// Only enabled games appear in party mode rotation and the new explore flow.
  final bool enabled;

  final Color accent;
  final IconData icon;
  final MiniGameBuilder builder;

  /// The realistic per-round ceiling — what a SKILLED HUMAN could actually
  /// reach in a round, not the theoretical point total (difficulty ramps past
  /// human reach). Used to calibrate AI-opponent scores. 0 = untuned; the host
  /// falls back to a score-relative estimate. Tune per game by playtest.
  final int humanMax;

  /// Up to three ascending score cutoffs `[oneStar, twoStar, threeStar]` that
  /// map a final score to a 0–3 star rating on the results screen. Empty =
  /// untuned; the host derives bands from [humanMax] or the player's own best.
  /// Tune per game by playtest.
  final List<int> starThresholds;

  /// Optional visual manual: captioned cards, each drawn by the game's OWN
  /// render code, shown as a swipeable/auto-advancing carousel on the intro.
  /// Empty = the host falls back to the text [rules] bullets.
  final List<LegendFrame> legendFrames;

  /// Optional live attract-mode demo, shown as the final manual card on its own
  /// throwaway session. Null = the slot is reserved but unused for this game.
  final MiniGameBuilder? demoBuilder;

  const MiniGameSpec({
    required this.id,
    required this.name,
    required this.scale,
    required this.tagline,
    required this.rules,
    required this.howToWin,
    required this.durationSeconds,
    required this.scoreUnit,
    required this.enabled,
    required this.accent,
    required this.icon,
    required this.builder,
    this.humanMax = 0,
    this.starThresholds = const [],
    this.legendFrames = const [],
    this.demoBuilder,
  });
}
