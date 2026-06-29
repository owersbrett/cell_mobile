import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════
// The Wait  (BioScale.nothings)  —  pure internal time perception
//
// SELF-CONTAINED MODULE. Depends only on the framework session
// ([MiniGameSession]), the shared FX kit and the brand theme. No per-game
// shared helpers, no other game's code. An agent can rebuild this game by
// editing only this folder. See GAME.md / AGENT.md / EDUCATION.md alongside.
//
// THE VERB: TIME-ESTIMATION. There is nothing to watch, catch, tap-fast or
// remember. There is only your internal clock, alone in the dark.
//
// CORE LOOP (host owns the 60s clock, countdown, score HUD and results):
//   1. COMMAND — a target appears: "WAIT N SECONDS" (N = random int 1..10).
//   2. THE DARK — the screen goes FULLY BLACK. No timer, no bar, no ticking,
//      no cue of any kind. You must FEEL the seconds pass and TAP at N seconds.
//   3. FLASH — the instant you tap, the background flashes WHITE and freezes
//      BLACK text: your actual tap time vs the target, the round score, and
//      the running total. If you never tap inside the 10s window, the round
//      scores 0 (NO TAP).
//   Score per round = round(100 · max(0, 1 − |elapsed − N| / N)).
//   EXACTLY 6 ROUNDS, each a 10-second window → ~60s, inside the host's 60s.
// ═══════════════════════════════════════════════════════════════════════════

// ── Feel constants — tune here without touching logic ──────────────────────
/// How many timing rounds make a full run.
const int _kRounds = 6;

/// Hard cap on the black wait window per round. No tap inside this = NO TAP (0).
const double _kRoundWindow = 10.0;

/// How long the "WAIT N SECONDS" command is shown before the screen goes black.
const double _kCommandSeconds = 1.2;

/// How long the white result flash holds before the next command.
const double _kFlashSeconds = 1.7;

/// A round counts toward the streak when its score reaches this (a "good feel").
const int _kStreakThreshold = 65;

/// Accent — matches The Wait catalog entry (a calm, clockless violet).
const Color _kAccent = Color(0xFF8C7AE6);

// ── Internal phases (distinct from host MiniGamePhase) ─────────────────────
enum _Phase { ready, command, waiting, flash, done }

/// One completed round's record (for the done summary).
class _RoundResult {
  final int target; // N seconds requested
  final double? elapsed; // actual tap time, or null = no tap
  final int score;
  const _RoundResult(this.target, this.elapsed, this.score);
}

class TheWaitGame extends StatefulWidget {
  final MiniGameSession session;
  const TheWaitGame({super.key, required this.session});

  @override
  State<TheWaitGame> createState() => _TheWaitGameState();
}

class _TheWaitGameState extends State<TheWaitGame>
    with SingleTickerProviderStateMixin {
  final Random _rng = Random();

  MiniGameSession get _session => widget.session;

  _Phase _phase = _Phase.ready;
  bool _started = false;

  int _roundIndex = 0; // 0.._kRounds
  int _target = 0; // current N
  int _total = 0; // running sum of round scores (mirrors session.score)
  int _streak = 0;
  final List<_RoundResult> _results = [];

  // Last flash payload.
  double? _lastElapsed;
  int _lastScore = 0;

  // The single discrete measurement instrument: started at the moment the
  // screen goes black, read on tap. No frame loop is involved in timing.
  final Stopwatch _watch = Stopwatch();

  Timer? _commandTimer;
  Timer? _windowTimer; // 10s "no tap" auto-fail
  Timer? _flashTimer;

  // One Ticker → one ambient CustomPainter for the lit (non-dark) states. The
  // black wait deliberately runs NO painter and NO ticker so there is zero cue.
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSession);
  }

  @override
  void dispose() {
    _session.removeListener(_onSession);
    _commandTimer?.cancel();
    _windowTimer?.cancel();
    _flashTimer?.cancel();
    _ambient.dispose();
    super.dispose();
  }

  void _onSession() {
    if (!mounted) return;
    // Auto-start when the host flips us into play.
    if (_session.isRunning && !_started) {
      _started = true;
      _startRun();
      return; // _startRun calls setState
    }
    // When the run ends, freeze any in-flight timers and the stopwatch.
    if (!_session.isRunning && _started) {
      _commandTimer?.cancel();
      _windowTimer?.cancel();
      _flashTimer?.cancel();
      _watch.stop();
    }
    setState(() {});
  }

  // ── Run / round lifecycle ───────────────────────────────────────────────
  void _startRun() {
    _roundIndex = 0;
    _total = 0;
    _streak = 0;
    _results.clear();
    _nextRound();
  }

  void _nextRound() {
    if (!mounted || !_session.isRunning) return;
    if (_roundIndex >= _kRounds) {
      setState(() => _phase = _Phase.done);
      return;
    }
    _target = 1 + _rng.nextInt(10); // N ∈ [1, 10]
    _commandTimer?.cancel();
    _commandTimer = Timer(
      Duration(milliseconds: (_kCommandSeconds * 1000).round()),
      _enterDark,
    );
    setState(() => _phase = _Phase.command);
  }

  void _enterDark() {
    if (!mounted || !_session.isRunning) return;
    _watch
      ..reset()
      ..start();
    _windowTimer?.cancel();
    _windowTimer = Timer(
      Duration(milliseconds: (_kRoundWindow * 1000).round()),
      _onWindowExpired,
    );
    setState(() => _phase = _Phase.waiting);
  }

  // The player felt the seconds and tapped.
  void _onTap() {
    if (_phase != _Phase.waiting || !_session.isRunning) return;
    _watch.stop();
    final elapsed = (_watch.elapsedMilliseconds / 1000.0).clamp(0.0, _kRoundWindow);
    _resolve(elapsed);
  }

  // 10s passed with no tap — the window closed.
  void _onWindowExpired() {
    if (_phase != _Phase.waiting || !mounted || !_session.isRunning) return;
    _watch.stop();
    _resolve(null);
  }

  void _resolve(double? elapsed) {
    _windowTimer?.cancel();
    final score = elapsed == null ? 0 : _scoreFor(elapsed, _target);
    _lastElapsed = elapsed;
    _lastScore = score;
    _total += score;
    _session.addScore(score);
    if (score >= _kStreakThreshold) {
      _streak++;
      _session.noteStreak(_streak);
    } else {
      _streak = 0;
    }
    _results.add(_RoundResult(_target, elapsed, score));
    _roundIndex++;

    setState(() => _phase = _Phase.flash);
    _flashTimer?.cancel();
    _flashTimer = Timer(
      Duration(milliseconds: (_kFlashSeconds * 1000).round()),
      _nextRound,
    );
  }

  /// Closeness scoring: 100 at a perfect match, fading linearly to 0 at a full
  /// target's worth of error. Education lives in this curve — being early or
  /// late by the same fraction costs the same.
  int _scoreFor(double elapsed, int target) {
    final err = (elapsed - target).abs() / target;
    final s = 100.0 * (1.0 - err);
    return s <= 0 ? 0 : s.round();
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _Phase.waiting:
        return _darkStage();
      case _Phase.flash:
        return _flashStage();
      case _Phase.ready:
        return _ambientScaffold(_readyContent());
      case _Phase.command:
        return _ambientScaffold(_commandContent());
      case _Phase.done:
        return _ambientScaffold(_doneContent());
    }
  }

  // A lit backdrop (single ticker → single painter) with centered content.
  Widget _ambientScaffold(Widget child) {
    return Container(
      color: Potatuhs.inkDeep,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _AmbientPainter(_ambient, _kAccent),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Center(child: child),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundTag() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: _kAccent.withValues(alpha: 0.12),
          border: Border.all(color: _kAccent.withValues(alpha: 0.45)),
        ),
        child: Text(
          'ROUND ${min(_roundIndex + 1, _kRounds)} / $_kRounds',
          style: Potatuhs.label(size: 11, color: _kAccent),
        ),
      );

  // Calm pre-play state. The host overlays its own countdown on top of this.
  Widget _readyContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.hourglass_empty, color: _kAccent, size: 54),
        const SizedBox(height: 18),
        Text('THE WAIT',
            style: Potatuhs.display(size: 34, color: Potatuhs.textPrimary)),
        const SizedBox(height: 12),
        Text('No clock. No ticking. No bar.',
            textAlign: TextAlign.center,
            style: Potatuhs.body(size: 15, color: Potatuhs.textSecondary)),
        const SizedBox(height: 6),
        Text('Feel the seconds — tap when the time is up.',
            textAlign: TextAlign.center,
            style: Potatuhs.body(size: 15, color: Potatuhs.textSecondary)),
      ],
    );
  }

  Widget _commandContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _roundTag(),
        const SizedBox(height: 26),
        Text('WAIT', style: Potatuhs.label(size: 14, color: _kAccent)),
        const SizedBox(height: 6),
        Text('$_target',
            style: Potatuhs.display(size: 110, color: Potatuhs.textPrimary)),
        const SizedBox(height: 2),
        Text(_target == 1 ? 'SECOND' : 'SECONDS',
            style: Potatuhs.label(size: 14, color: _kAccent)),
        const SizedBox(height: 22),
        Text('the screen is about to go dark…',
            textAlign: TextAlign.center,
            style: Potatuhs.body(size: 13, color: Potatuhs.textFaint)),
      ],
    );
  }

  // PURE BLACK. No painter, no ticker, no cue. Just a full-screen tap target.
  Widget _darkStage() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      child: const ColoredBox(
        color: Colors.black,
        child: SizedBox.expand(),
      ),
    );
  }

  // The white flash with frozen black text: actual vs target, score, total.
  Widget _flashStage() {
    final elapsed = _lastElapsed;
    final target = _results.isEmpty ? _target : _results.last.target;
    final missed = elapsed == null;
    final delta = missed ? 0.0 : elapsed - target;
    final lateEarly = missed
        ? 'NO TAP'
        : delta.abs() < 0.15
            ? 'DEAD ON'
            : '${delta.abs().toStringAsFixed(2)}s ${delta > 0 ? 'LATE' : 'EARLY'}';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // taps during the flash are inert
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: TweenAnimationBuilder<double>(
              key: ValueKey(_results.length),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              builder: (context, fade, _) => Opacity(
                opacity: fade,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(missed ? 'NO TAP' : '${elapsed.toStringAsFixed(2)}s',
                          style: const TextStyle(
                            fontFamily: Potatuhs.displayFont,
                            fontSize: 72,
                            color: Colors.black,
                          )),
                      const SizedBox(height: 4),
                      Text('TARGET ${target}s · $lateEarly',
                          style: const TextStyle(
                            fontFamily: Potatuhs.bodyFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 1.0,
                            color: Color(0xFF555555),
                          )),
                      const SizedBox(height: 22),
                      Text(_lastScore > 0 ? '+$_lastScore' : '0',
                          style: const TextStyle(
                            fontFamily: Potatuhs.displayFont,
                            fontSize: 40,
                            color: Color(0xFF7C5CD6),
                          )),
                      const SizedBox(height: 18),
                      Text('TOTAL $_total',
                          style: const TextStyle(
                            fontFamily: Potatuhs.bodyFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: 1.5,
                            color: Colors.black,
                          )),
                      const SizedBox(height: 22),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Text(
                          _insight(missed, delta),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: Potatuhs.bodyFont,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            height: 1.35,
                            color: Color(0xFF777777),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Education IN the mechanic: every flash names what your internal clock did.
  String _insight(bool missed, double delta) {
    if (missed) {
      return 'The 10-second window closed with no tap. With no external cue, '
          'long intervals are hard to hold in mind.';
    }
    if (delta.abs() < 0.15) {
      return 'Calibrated. Your internal pacemaker matched real time almost '
          'exactly — that is rare without a clock.';
    }
    if (delta > 0) {
      return 'You over-waited. Counting attentively makes time feel SLOWER, '
          'so people drift LATE on bare intervals.';
    }
    return 'You jumped early. When you stop attending to time it speeds up — '
        'so unmonitored intervals tend to run EARLY.';
  }

  Widget _doneContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('WAITS COMPLETE',
            style: Potatuhs.display(size: 26, color: _kAccent)),
        const SizedBox(height: 8),
        Text('$_total',
            style: Potatuhs.display(size: 56, color: Potatuhs.textPrimary)),
        Text('TOTAL POINTS',
            style: Potatuhs.label(size: 11, color: Potatuhs.textSecondary)),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            children: [
              for (final r in _results) _summaryRow(r),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(_RoundResult r) {
    final missed = r.elapsed == null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Target ${r.target}s',
              style: Potatuhs.body(size: 14, color: Potatuhs.textSecondary)),
          Text(missed ? 'no tap' : '${r.elapsed!.toStringAsFixed(2)}s',
              style: Potatuhs.body(size: 14, color: Potatuhs.textPrimary)),
          SizedBox(
            width: 56,
            child: Text('+${r.score}',
                textAlign: TextAlign.right,
                style: Potatuhs.body(
                    size: 14,
                    weight: FontWeight.w800,
                    color: r.score >= _kStreakThreshold
                        ? _kAccent
                        : Potatuhs.textFaint)),
          ),
        ],
      ),
    );
  }
}

/// One ambient backdrop for the lit (non-dark) states — soft gradient + drift,
/// from the shared FX kit. Driven by the single game ticker. The black wait
/// stage never mounts this, so the dark truly has no motion.
class _AmbientPainter extends CustomPainter {
  final Animation<double> t;
  final Color accent;
  _AmbientPainter(this.t, this.accent) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, accent, t.value * 60, motes: 28);
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) => false;
}
