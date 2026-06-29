import 'dart:async';

import 'package:flutter/material.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════
// The Wait v2  (BioScale.nothings)  —  internal time perception, TIGHTENING
//
// SELF-CONTAINED MODULE. Depends only on the framework session
// ([MiniGameSession]), the shared FX kit and the brand theme. No per-game
// shared helpers, no other game's code. An agent can rebuild this game by
// editing only this folder. See GAME.md / AGENT.md / EDUCATION.md / POTATUHS.md.
//
// THE VERB — unchanged soul: TIME-ESTIMATION in the dark. There is nothing to
// watch, catch, tap-fast or remember. Only your internal clock, alone in pure
// black. The screen goes BLACK with zero cue; you FEEL the seconds and TAP;
// the instant you tap it FLASHES WHITE and freezes your timestamp. That
// black→white timestamp identity is preserved exactly.
//
// WHAT v2 FIXES (per teardown):
//   • TIGHTENING ARC, not 6 flat random 1–10s waits. The targets DESCEND
//     (5 → 4 → 3 → 2.5 → 2 → 1.5s) so reveals come faster and faster — the run
//     ACCELERATES into a tense, snappy climax instead of risking a 9s dead
//     wait at the end. The tolerance band TIGHTENS every round and the points
//     WEIGHT rises, so the final wait is the highest-stakes moment.
//   • SKILL via CONSISTENCY. A "tight" tap (inside the round's shrinking band)
//     builds a PRECISION STREAK that compounds a multiplier (x1 → x3). One
//     loose tap resets it. A calibrated player who stays tight massively
//     out-scores a lucky single guess — variance is punished, calibration is
//     rewarded. That is the deeper ceiling the verb was missing.
//   • A CLEAR COMPARABLE STANDING for pass-and-play: a row of round PIPS
//     (dead-on / tight / loose / miss) builds across the run, plus the live
//     multiplier and running total — two players compare profiles at a glance,
//     no clock needed, purity intact.
//   • LESS DEAD AIR. The longest wait is 5s (was up to 10s). The "no tap"
//     safety window is target-relative, not a flat 10s.
//
// HOST CONTRACT: the host (MiniGameHost) owns the run clock, countdown, score
//   HUD, opponents and results. This widget renders ONLY the play area,
//   auto-starts when the session enters play, reports points via
//   session.addScore / session.noteStreak, and calls session.endEarly() when
//   the six waits are spent (a clean "perfect clear" finish). It draws no
//   timer and no results screen of its own.
// ═══════════════════════════════════════════════════════════════════════════

// ── Feel constants — tune here without touching logic ──────────────────────

/// The TIGHTENING ARC. Targets DESCEND so the run accelerates; the band
/// SHRINKS and the weight RISES so the final wait is the climax. All three
/// lists are the same length and that length IS the round count.
const List<double> _kTargets = [5.0, 4.0, 3.0, 2.5, 2.0, 1.5];

/// Absolute "tight" band (± seconds) per round — narrows toward the climax.
const List<double> _kBands = [0.80, 0.62, 0.46, 0.36, 0.28, 0.22];

/// Points weight per round — rises so later, tighter waits matter most.
const List<double> _kWeights = [1.0, 1.15, 1.3, 1.5, 1.7, 2.0];

/// Base points for a perfect tap (error 0). Scaled by weight × multiplier.
const double _kBasePerfect = 100.0;

/// Streak multiplier: 1 + step·min(streak,cap). A run of tight taps compounds.
const double _kMultStep = 0.5;
const int _kMultCap = 4; // → max multiplier x3.0

/// How long the "WAIT N" command holds before the screen goes black.
const double _kCommandSeconds = 0.9;

/// How long the white timestamp flash holds before the next command.
const double _kFlashSeconds = 1.5;

/// Extra grace beyond the target before a round auto-fails as NO TAP. Keeps
/// dead air short: window = target + this (vs the old flat 10s).
const double _kWindowGrace = 2.5;

/// Accent — a calm, clockless violet (distinct from The Wait v1's entry).
const Color _kAccent = Color(0xFF9B8BF5);
const Color _kGood = Color(0xFF3DDC97);
const Color _kWarn = Color(0xFFFF6E5A);

int get _kRounds => _kTargets.length;

// ── Verdict bands for a resolved tap ───────────────────────────────────────
enum _Verdict { deadOn, tight, loose, off, miss }

extension on _Verdict {
  bool get isTight => this == _Verdict.deadOn || this == _Verdict.tight;
}

// ── Internal phases (distinct from host MiniGamePhase) ─────────────────────
enum _Phase { ready, command, waiting, flash, done }

/// One completed round's record (for pips + the done summary).
class _RoundResult {
  final double target;
  final double band;
  final double? elapsed; // actual tap time, or null = no tap
  final int score;
  final _Verdict verdict;
  const _RoundResult(
      this.target, this.band, this.elapsed, this.score, this.verdict);
}

class TheWaitV2Game extends StatefulWidget {
  final MiniGameSession session;
  const TheWaitV2Game({super.key, required this.session});

  @override
  State<TheWaitV2Game> createState() => _TheWaitV2GameState();
}

class _TheWaitV2GameState extends State<TheWaitV2Game>
    with SingleTickerProviderStateMixin {
  MiniGameSession get _session => widget.session;

  _Phase _phase = _Phase.ready;
  bool _started = false;

  int _roundIndex = 0; // 0.._kRounds
  double _target = 0; // current N
  double _band = 0; // current tight band
  int _total = 0; // running sum (mirrors session.score)
  int _streak = 0; // consecutive tight taps
  int _bestStreak = 0;
  final List<_RoundResult> _results = [];

  // Last flash payload.
  double? _lastElapsed;
  int _lastScore = 0;
  double _lastMult = 1.0;
  _Verdict _lastVerdict = _Verdict.miss;

  // The single discrete instrument: started when the screen goes black, read on
  // tap. No frame loop is involved in timing — accurate and cue-free.
  final Stopwatch _watch = Stopwatch();

  Timer? _commandTimer;
  Timer? _windowTimer; // target-relative "no tap" auto-fail
  Timer? _flashTimer;

  // One Ticker → one ambient CustomPainter for the LIT states only. The black
  // wait deliberately runs NO painter and NO ticker so the dark has zero cue.
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
    if (_session.isRunning && !_started) {
      _started = true;
      _startRun();
      return; // _startRun calls setState
    }
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
    _bestStreak = 0;
    _results.clear();
    _nextRound();
  }

  void _nextRound() {
    if (!mounted || !_session.isRunning) return;
    if (_roundIndex >= _kRounds) {
      setState(() => _phase = _Phase.done);
      _session.endEarly(); // clean perfect-clear finish; host shows results
      return;
    }
    _target = _kTargets[_roundIndex];
    _band = _kBands[_roundIndex];
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
    final windowMs = ((_target + _kWindowGrace) * 1000).round();
    _windowTimer?.cancel();
    _windowTimer = Timer(Duration(milliseconds: windowMs), _onWindowExpired);
    setState(() => _phase = _Phase.waiting);
  }

  void _onTap() {
    if (_phase != _Phase.waiting || !_session.isRunning) return;
    _watch.stop();
    final cap = _target + _kWindowGrace;
    final elapsed = (_watch.elapsedMilliseconds / 1000.0).clamp(0.0, cap);
    _resolve(elapsed);
  }

  void _onWindowExpired() {
    if (_phase != _Phase.waiting || !mounted || !_session.isRunning) return;
    _watch.stop();
    _resolve(null);
  }

  void _resolve(double? elapsed) {
    _windowTimer?.cancel();

    final verdict = _verdictFor(elapsed, _target, _band);
    final base = elapsed == null ? 0.0 : _baseScore(elapsed, _target);

    // Multiplier from the streak STANDING BEFORE this tap, then update it.
    final mult = 1.0 + _kMultStep * (_streak.clamp(0, _kMultCap));
    final weight = _kWeights[_roundIndex];
    final score = (base * weight * mult).round();

    if (verdict.isTight) {
      _streak++;
      if (_streak > _bestStreak) _bestStreak = _streak;
      _session.noteStreak(_streak);
    } else {
      _streak = 0;
    }

    _lastElapsed = elapsed;
    _lastScore = score;
    _lastMult = mult;
    _lastVerdict = verdict;
    _total += score;
    _session.addScore(score);

    _results.add(_RoundResult(_target, _band, elapsed, score, verdict));
    _roundIndex++;

    setState(() => _phase = _Phase.flash);
    _flashTimer?.cancel();
    _flashTimer = Timer(
      Duration(milliseconds: (_kFlashSeconds * 1000).round()),
      _nextRound,
    );
  }

  /// Closeness curve: 100 at a perfect match, fading linearly to 0 at a full
  /// target's worth of error. Education lives here — early or late by the same
  /// fraction costs the same.
  double _baseScore(double elapsed, double target) {
    final err = (elapsed - target).abs() / target;
    final s = _kBasePerfect * (1.0 - err);
    return s <= 0 ? 0 : s;
  }

  _Verdict _verdictFor(double? elapsed, double target, double band) {
    if (elapsed == null) return _Verdict.miss;
    final err = (elapsed - target).abs();
    if (err <= band * 0.4) return _Verdict.deadOn;
    if (err <= band) return _Verdict.tight;
    if (err <= band * 2.0) return _Verdict.loose;
    return _Verdict.off;
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

  // ── Pips: the comparable standing, built round over round ─────────────────
  Widget _pips({Color onColor = _kAccent, Color offColor = Colors.white24}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _kRounds; i++) _pip(i, onColor, offColor),
      ],
    );
  }

  Widget _pip(int i, Color onColor, Color offColor) {
    Color color;
    bool filled;
    if (i < _results.length) {
      switch (_results[i].verdict) {
        case _Verdict.deadOn:
          color = _kGood;
          filled = true;
          break;
        case _Verdict.tight:
          color = onColor;
          filled = true;
          break;
        case _Verdict.loose:
          color = onColor;
          filled = false;
          break;
        case _Verdict.off:
        case _Verdict.miss:
          color = _kWarn;
          filled = false;
          break;
      }
    } else {
      color = offColor;
      filled = false;
    }
    final current = i == _roundIndex && _phase != _Phase.done;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : Colors.transparent,
        border: Border.all(
          color: current ? Potatuhs.gold : color,
          width: current ? 2.2 : 1.6,
        ),
      ),
    );
  }

  Widget _bandChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: _kAccent.withValues(alpha: 0.12),
          border: Border.all(color: _kAccent.withValues(alpha: 0.45)),
        ),
        child: Text(
          'BAND ±${_band.toStringAsFixed(2)}s',
          style: Potatuhs.label(size: 11, color: _kAccent),
        ),
      );

  // Calm pre-play state. The host overlays its own countdown on top of this.
  Widget _readyContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.hourglass_top, color: _kAccent, size: 54),
        const SizedBox(height: 18),
        Text('THE WAIT',
            style: Potatuhs.display(size: 34, color: Potatuhs.textPrimary)),
        Text('v2 · the tightening',
            style: Potatuhs.label(size: 11, color: _kAccent)),
        const SizedBox(height: 14),
        Text('No clock. No ticking. No bar.',
            textAlign: TextAlign.center,
            style: Potatuhs.body(size: 15, color: Potatuhs.textSecondary)),
        const SizedBox(height: 4),
        Text('Feel the seconds — tap when the time is up.',
            textAlign: TextAlign.center,
            style: Potatuhs.body(size: 15, color: Potatuhs.textSecondary)),
        const SizedBox(height: 4),
        Text('Each wait is shorter and the band is tighter.',
            textAlign: TextAlign.center,
            style: Potatuhs.body(size: 14, color: Potatuhs.textFaint)),
      ],
    );
  }

  Widget _commandContent() {
    final n = _target;
    final label = n == n.roundToDouble()
        ? n.toStringAsFixed(0)
        : n.toStringAsFixed(1);
    final isFinal = _roundIndex == _kRounds - 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _pips(),
        const SizedBox(height: 22),
        Text(isFinal ? 'FINAL WAIT' : 'WAIT',
            style: Potatuhs.label(size: 14, color: isFinal ? Potatuhs.gold : _kAccent)),
        const SizedBox(height: 6),
        Text(label,
            style: Potatuhs.display(
                size: 104,
                color: isFinal ? Potatuhs.gold : Potatuhs.textPrimary)),
        const SizedBox(height: 2),
        Text(n == 1 ? 'SECOND' : 'SECONDS',
            style: Potatuhs.label(size: 14, color: _kAccent)),
        const SizedBox(height: 18),
        _bandChip(),
        const SizedBox(height: 14),
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

  // The white flash with frozen black text: timestamp, verdict, score×mult,
  // the running total, the pip standing, and the education insight.
  Widget _flashStage() {
    final elapsed = _lastElapsed;
    final last = _results.isNotEmpty ? _results.last : null;
    final target = last?.target ?? _target;
    final missed = elapsed == null;
    final delta = missed ? 0.0 : elapsed - target;
    final verdictText = _verdictText(_lastVerdict, delta);
    final verdictColor = _verdictColor(_lastVerdict);

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
              duration: const Duration(milliseconds: 220),
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
                            fontSize: 70,
                            color: Colors.black,
                          )),
                      const SizedBox(height: 4),
                      Text(
                          'TARGET ${_fmt(target)}s · $verdictText',
                          style: TextStyle(
                            fontFamily: Potatuhs.bodyFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 1.0,
                            color: verdictColor,
                          )),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(_lastScore > 0 ? '+$_lastScore' : '0',
                              style: const TextStyle(
                                fontFamily: Potatuhs.displayFont,
                                fontSize: 40,
                                color: Color(0xFF6A4FD0),
                              )),
                          if (_lastMult > 1.0) ...[
                            const SizedBox(width: 8),
                            Text('×${_fmtMult(_lastMult)}',
                                style: const TextStyle(
                                  fontFamily: Potatuhs.bodyFont,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: Color(0xFF1B9E63),
                                )),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text('TOTAL $_total',
                          style: const TextStyle(
                            fontFamily: Potatuhs.bodyFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: 1.5,
                            color: Colors.black,
                          )),
                      const SizedBox(height: 16),
                      // The comparable standing, in black-on-white.
                      _pips(onColor: const Color(0xFF6A4FD0), offColor: const Color(0x22000000)),
                      const SizedBox(height: 20),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Text(
                          _insight(_lastVerdict, delta),
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

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  String _fmtMult(double m) =>
      m == m.roundToDouble() ? m.toStringAsFixed(0) : m.toStringAsFixed(1);

  String _verdictText(_Verdict v, double delta) {
    switch (v) {
      case _Verdict.deadOn:
        return 'DEAD ON';
      case _Verdict.tight:
        return '${delta.abs().toStringAsFixed(2)}s ${delta > 0 ? 'LATE' : 'EARLY'} · TIGHT';
      case _Verdict.loose:
        return '${delta.abs().toStringAsFixed(2)}s ${delta > 0 ? 'LATE' : 'EARLY'} · LOOSE';
      case _Verdict.off:
        return '${delta.abs().toStringAsFixed(2)}s ${delta > 0 ? 'LATE' : 'EARLY'}';
      case _Verdict.miss:
        return 'NO TAP';
    }
  }

  Color _verdictColor(_Verdict v) {
    switch (v) {
      case _Verdict.deadOn:
        return const Color(0xFF1B9E63);
      case _Verdict.tight:
        return const Color(0xFF6A4FD0);
      case _Verdict.loose:
        return const Color(0xFF555555);
      case _Verdict.off:
      case _Verdict.miss:
        return const Color(0xFFC0392B);
    }
  }

  // Education IN the mechanic: every flash names what your internal clock did.
  String _insight(_Verdict v, double delta) {
    if (v == _Verdict.miss) {
      return 'The window closed with no tap. With no external cue, an interval '
          'you stop holding in mind slips away entirely.';
    }
    if (v == _Verdict.deadOn) {
      return 'Calibrated. Your internal pacemaker matched real time almost '
          'exactly — and the band keeps tightening from here.';
    }
    if (delta > 0) {
      return 'You over-waited. Counting attentively makes time feel SLOWER, so '
          'people drift LATE — and the cost grows as the band shrinks.';
    }
    return 'You jumped early. When you stop attending to time it speeds up, so '
        'unmonitored intervals tend to run EARLY.';
  }

  Widget _doneContent() {
    final tightCount = _results.where((r) => r.verdict.isTight).length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('WAITS COMPLETE',
            style: Potatuhs.display(size: 24, color: _kAccent)),
        const SizedBox(height: 8),
        Text('$_total',
            style: Potatuhs.display(size: 54, color: Potatuhs.textPrimary)),
        Text('TOTAL POINTS',
            style: Potatuhs.label(size: 11, color: Potatuhs.textSecondary)),
        const SizedBox(height: 14),
        _pips(),
        const SizedBox(height: 10),
        Text('$tightCount / $_kRounds tight · best streak $_bestStreak',
            style: Potatuhs.body(size: 13, color: Potatuhs.textSecondary)),
        const SizedBox(height: 18),
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
          Text('±${r.band.toStringAsFixed(2)}  @ ${_fmt(r.target)}s',
              style: Potatuhs.body(size: 13, color: Potatuhs.textSecondary)),
          Text(missed ? 'no tap' : '${r.elapsed!.toStringAsFixed(2)}s',
              style: Potatuhs.body(size: 14, color: Potatuhs.textPrimary)),
          SizedBox(
            width: 56,
            child: Text('+${r.score}',
                textAlign: TextAlign.right,
                style: Potatuhs.body(
                    size: 14,
                    weight: FontWeight.w800,
                    color: r.verdict.isTight ? _kAccent : Potatuhs.textFaint)),
          ),
        ],
      ),
    );
  }
}

/// One ambient backdrop for the LIT (non-dark) states — soft gradient + drift,
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
