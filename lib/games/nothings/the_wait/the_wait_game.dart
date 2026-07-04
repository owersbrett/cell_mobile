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

/// ATTRACT autopilot cadence — the host calls [_autoStep] on roughly this
/// interval. Used to fire ONE tick ahead so the bot taps as close to the
/// target as it can without overshooting.
const double _kAutoTick = 0.25;

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
    // ATTRACT autopilot: this game knows how to play itself. Registered always
    // (harmless in normal play — the host only calls it in autoplay). See
    // [_autoStep]. Dormant unless the host is driving hands-free.
    _session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (_session.autoPilot == _autoStep) _session.autoPilot = null;
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
    // Host PAUSE (round frozen, will resume): stop the stopwatch and phase
    // timers so paused time isn't counted as "waited" time. Distinct from a
    // real round-end via [isPaused].
    if (_session.isPaused && _started && !_pausedByHost) {
      _pauseForHost();
      setState(() {});
      return;
    }
    // Resume from a host pause: rearm this phase's timing where we left off.
    if (_session.isRunning && _pausedByHost) {
      _resumeFromHost();
      setState(() {});
      return;
    }
    // Genuine run end (not a pause): freeze everything.
    if (!_session.isRunning && !_session.isPaused && _started) {
      _commandTimer?.cancel();
      _windowTimer?.cancel();
      _flashTimer?.cancel();
      _watch.stop();
    }
    setState(() {});
  }

  /// True while the round is frozen by a host pause (see [_pauseForHost]).
  bool _pausedByHost = false;

  /// Freezes the current beat: stops the stopwatch (elapsed preserved) and
  /// cancels the active phase timer, so no wall-clock time accrues while paused.
  void _pauseForHost() {
    _pausedByHost = true;
    _commandTimer?.cancel();
    _windowTimer?.cancel();
    _flashTimer?.cancel();
    if (_watch.isRunning) _watch.stop();
  }

  /// Resumes the current beat exactly where it was: the dark wait rearms its
  /// window timeout for the time that was LEFT and restarts the stopwatch, so
  /// the paused seconds never count. Command/flash beats simply rearm.
  void _resumeFromHost() {
    _pausedByHost = false;
    switch (_phase) {
      case _Phase.command:
        _commandTimer = Timer(
          Duration(milliseconds: (_kCommandSeconds * 1000).round()),
          _enterDark,
        );
        break;
      case _Phase.waiting:
        _watch.start(); // resume elapsed from where it paused
        final leftS = (_kRoundWindow - _watch.elapsedMilliseconds / 1000.0)
            .clamp(0.0, _kRoundWindow);
        _windowTimer = Timer(
          Duration(milliseconds: (leftS * 1000).round()),
          _onWindowExpired,
        );
        break;
      case _Phase.flash:
        _flashTimer = Timer(
          Duration(milliseconds: (_kFlashSeconds * 1000).round()),
          _nextRound,
        );
        break;
      case _Phase.ready:
      case _Phase.done:
        break;
    }
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One hands-free move per host tick (~250ms). This plays The Wait
  /// *perfectly*, not randomly: the only decision the game makes is WHEN to tap
  /// during the black wait, and the bot can read the true target [_target] and
  /// the running [_watch]. Every other phase (command / flash / done)
  /// self-advances on its own timer, so there is nothing to do there.
  ///
  /// It fires ONE tick ahead: if the wait has run long enough that the NEXT
  /// tick would sit at/after the target, this tick is the closest it can land
  /// without overshooting — so it taps now. It never taps far from the target,
  /// because the condition can only be met within a tick of it.
  void _autoStep() {
    if (!_session.isRunning) return;
    if (_phase != _Phase.waiting) return; // only the dark wait needs a decision
    final elapsed = _watch.elapsedMilliseconds / 1000.0;
    if (elapsed + _kAutoTick >= _target) {
      _onTap(); // reached the target (to within one tick) — feel it and tap
    }
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
        const Icon(Icons.hourglass_empty, color: _kAccent, size: 54),
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

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards, drawn in the game's OWN minimal
// language: the void backdrop, the WAIT-N command card, the white result
// flash, and the closeness readout. Static and cheap — rendered once on the
// intro screen, never per-frame.
// ═══════════════════════════════════════════════════════════════════════════

/// Frame 1 — the command: "WAIT 10 SECONDS" floating on the void, exactly as
/// the round shows it before the screen goes dark.
void _legendCommand(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  // The same ambient void the lit states use (frozen at one instant).
  GameFx.atmosphere(canvas, size, _kAccent, 12, motes: 12);

  final cx = size.width / 2;

  // Round tag, as in play.
  final tag = Rect.fromCenter(
      center: Offset(cx, size.height * 0.14),
      width: min(size.width * 0.42, 96),
      height: 18);
  canvas.drawRRect(
    RRect.fromRectAndRadius(tag, const Radius.circular(9)),
    Paint()..color = _kAccent.withValues(alpha: 0.12),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(tag, const Radius.circular(9)),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _kAccent.withValues(alpha: 0.45),
  );
  GameFx.text(canvas, 'ROUND 1 / $_kRounds', tag.center, 8, _kAccent,
      weight: FontWeight.w800);

  GameFx.text(canvas, 'WAIT', Offset(cx, size.height * 0.32), 12, _kAccent,
      weight: FontWeight.w800);
  GameFx.text(canvas, '10', Offset(cx, size.height * 0.52),
      min(size.height * 0.30, size.width * 0.26), Potatuhs.textPrimary,
      display: true);
  GameFx.text(canvas, 'SECONDS', Offset(cx, size.height * 0.72), 12, _kAccent,
      weight: FontWeight.w800);
  GameFx.text(canvas, 'the screen is about to go dark…',
      Offset(cx, size.height * 0.88), 9, Potatuhs.textFaint);
}

/// Frame 2 — the tap moment: the pure-black wait on the left (your tap, the
/// only event in the dark), the white flash with the frozen timestamp on the
/// right — the exact readout the game freezes the instant you tap.
void _legendTap(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final split = size.width * 0.44;

  // Left: THE DARK — pure black, no cue, only your finger.
  canvas.drawRect(
      Rect.fromLTWH(0, 0, split, size.height), Paint()..color = Colors.black);
  final tap = Offset(split * 0.5, size.height * 0.48);
  canvas.drawCircle(tap, 6, Paint()..color = _kAccent);
  for (int i = 1; i <= 3; i++) {
    canvas.drawCircle(
      tap,
      6.0 + i * 9.0,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _kAccent.withValues(alpha: 0.55 - i * 0.15),
    );
  }
  GameFx.text(canvas, 'TAP', Offset(tap.dx, size.height * 0.82), 10, _kAccent,
      weight: FontWeight.w800);

  // Right: the FLASH — white, black timestamp, target + delta (as in play).
  canvas.drawRect(Rect.fromLTWH(split, 0, size.width - split, size.height),
      Paint()..color = Colors.white);
  final fx = split + (size.width - split) / 2;
  GameFx.text(canvas, '9.87s', Offset(fx, size.height * 0.40),
      min(size.height * 0.18, (size.width - split) * 0.20), Colors.black,
      display: true);
  GameFx.text(canvas, 'TARGET 10s', Offset(fx, size.height * 0.60), 9,
      const Color(0xFF555555),
      weight: FontWeight.w800);
  GameFx.text(canvas, '0.13s EARLY', Offset(fx, size.height * 0.72), 9,
      const Color(0xFF555555),
      weight: FontWeight.w800);
}

/// Frame 3 — the scoring curve: a 0→10s timeline with the target tick; a tap
/// near the target earns big points, a far one almost nothing.
void _legendScore(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  canvas.drawRect(Offset.zero & size, Paint()..color = Potatuhs.inkDeep);

  final y = size.height * 0.56;
  final x0 = size.width * 0.08;
  final x1 = size.width * 0.92;

  // The felt-time line (the only axis this game has).
  canvas.drawLine(
    Offset(x0, y),
    Offset(x1, y),
    Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = Potatuhs.textFaint.withValues(alpha: 0.5),
  );

  // Target tick — where 10 real seconds actually land.
  final tx = size.width * 0.78;
  canvas.drawLine(
    Offset(tx, y - 14),
    Offset(tx, y + 14),
    Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = Potatuhs.textPrimary,
  );
  GameFx.text(canvas, 'TARGET 10s', Offset(tx, y + 26), 9,
      Potatuhs.textPrimary,
      weight: FontWeight.w800);

  // Close tap: a breath from the target — big points.
  final nearX = size.width * 0.72;
  canvas.drawCircle(Offset(nearX, y), 6, Paint()..color = _kAccent);
  canvas.drawCircle(
    Offset(nearX, y),
    11,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _kAccent.withValues(alpha: 0.4),
  );
  GameFx.text(canvas, '+92', Offset(nearX, y - size.height * 0.24),
      min(size.height * 0.14, 26), _kAccent,
      display: true);

  // Far tap: seconds off — nearly nothing.
  final farX = size.width * 0.26;
  canvas.drawCircle(
      Offset(farX, y), 5, Paint()..color = Potatuhs.textFaint);
  GameFx.text(canvas, '+18', Offset(farX, y - size.height * 0.20), 12,
      Potatuhs.textFaint,
      weight: FontWeight.w800);
  GameFx.text(canvas, '4.1s', Offset(farX, y + 24), 9, Potatuhs.textFaint);
}

/// The visual manual for The Wait — wired into the registry spec.
final List<LegendFrame> theWaitLegendFrames = [
  const LegendFrame(
      caption: 'Read the target — FEEL that many seconds pass',
      paint: _legendCommand),
  const LegendFrame(
      caption: 'Tap in the dark — a white flash stamps your time',
      paint: _legendTap),
  const LegendFrame(
      caption: 'Closer to the target = more points. Dead on = 100',
      paint: _legendScore),
];

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
