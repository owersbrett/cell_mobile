import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../theme/potatuhs.dart';
import '../../fx.dart';
import '../../mini_game.dart';
import 'code_trivia_data.dart';

// ============================================================================
// CODE TRIVIA — rapid-fire 4-option programming trivia.
//
// A question card burns a per-card FUSE. Tap the true answer before the fuse
// dies: base points + a speed bonus that follows the fuse + a ×streak
// multiplier. Wrong tap or timeout: streak breaks, the correct answer flashes
// with a one-line WHY (teach in-context). Escalation over the 60 s round:
// tier 1 → 2 → 3 questions by count, the fuse shortening every card, and
// tier-3 distractors authored as near-misses. No repeats within a run.
//
// Architecture (per the repo rendering rules):
//   • ONE Ticker advances the sim and bumps ONE ValueNotifier that repaints
//     ONE CustomPainter behind a RepaintBoundary. The painter owns ALL
//     continuous motion: atmosphere, the burning fuse + spark, streak spark
//     particles, score pops, the red miss-flash, and the painted HUD
//     (score / ×mult / clock) so the widget tree never rebuilds per frame.
//   • The widget layer (question card + 4 answer chips + reveal banner)
//     rebuilds ONLY on discrete events: question load, tap, timeout, reveal
//     end. The miss-shake is an AnimatedBuilder Transform with a hoisted
//     child (cheap: no subtree rebuild).
//   • The host owns clock, score, results and exit. This widget never calls
//     endEarly and gates all play on session.isRunning — always quittable.
// ============================================================================

// ── Palette — theme first; green/red are the repo-wide answer-feedback pair
//    (same values as corners.dart / vocab_game.dart, the reference games). ──
const Color _kAccent = Potatuhs.glaucous; // somethings-adjacent theme purple
const Color _kGold = Potatuhs.gold;
const Color _kGood = Color(0xFF69F0AE); // correct — established feedback green
const Color _kBad = Color(0xFFFF5252); // wrong — established feedback red
const Color _kCardBg = Potatuhs.inkPanel;
const Color _kCardBorder = Color(0x33FDF5EB); // Potatuhs.surface default border

// ── Monospace stack for inline code fragments (the ONLY non-brand font). ──
const String _kMonoFont = 'monospace';
const List<String> _kMonoFallback = ['Menlo', 'Consolas', 'Roboto Mono'];

// ── Feel knobs — first-pass, tune by play. ──
const double _kFuseStart = 8.0; // seconds on the first card's fuse
const double _kFuseFloor = 3.5; // the fuse never shrinks below this
const double _kFuseStep = 0.22; // seconds shaved off the fuse per card asked
const double _kCorrectDwell = 0.75; // green flash before the next card
const double _kRevealDwell = 2.6; // wrong/timeout: answer + why dwell
const int _kBasePoints = 60; // guaranteed points for a correct answer
const int _kSpeedPoints = 60; // extra points at full fuse, decaying to 0
const int _kStreakStep = 3; // every N consecutive corrects = +1× multiplier
const int _kMaxMultiplier = 4; // ×multiplier ceiling
const int _kTier2At = 8; // cards asked before tier 2 begins
const int _kTier3At = 16; // cards asked before tier 3 begins

// ── Painted-HUD geometry (the widget column reserves this space). ──
const double _kHudHeight = 46.0;
const double _kFuseHeight = 8.0;
const double _kFuseInset = 24.0;
const double _kTopReserve = _kHudHeight + _kFuseHeight + 18;

enum _CardState { waiting, correct, wrong, timeout }

// ============================================================================
// Inline-code rich text — backtick-delimited fragments render monospace.
// ============================================================================

TextSpan _codeSpan(String text, TextStyle base) {
  final parts = text.split('`');
  if (parts.length == 1) return TextSpan(text: text, style: base);
  final children = <TextSpan>[];
  for (var i = 0; i < parts.length; i++) {
    if (parts[i].isEmpty) continue;
    if (i.isOdd) {
      children.add(TextSpan(
        text: parts[i],
        style: base.copyWith(
          fontFamily: _kMonoFont,
          fontFamilyFallback: _kMonoFallback,
          color: _kGold,
          fontWeight: FontWeight.w600,
          backgroundColor: Colors.white.withValues(alpha: 0.06),
        ),
      ));
    } else {
      children.add(TextSpan(text: parts[i]));
    }
  }
  return TextSpan(style: base, children: children);
}

// ============================================================================
// Widget
// ============================================================================

class CodeTriviaGame extends StatefulWidget {
  final MiniGameSession session;

  const CodeTriviaGame({super.key, required this.session});

  @override
  State<CodeTriviaGame> createState() => _CodeTriviaGameState();
}

class _CodeTriviaGameState extends State<CodeTriviaGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  /// Bumped once per ticker frame; the painter's repaint listenable. The
  /// widget tree does NOT listen to it (except the cheap shake Transform).
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);

  Duration _lastElapsed = Duration.zero;
  double _clock = 0;

  // -- No-repeat pools, one per tier, shuffled at run start. ------------------
  late List<List<CodeTriviaQuestion>> _pools; // index 0..2 = tier 1..3

  // -- Current card -----------------------------------------------------------
  CodeTriviaQuestion? _q;
  List<String> _options = const [];
  int _correctIndex = 0;
  int _tappedIndex = -1;
  _CardState _state = _CardState.waiting;

  // -- Timers (sim-side; the painter reads fractions, widgets never tick) -----
  double _fuseTime = _kFuseStart; // this card's full fuse length
  double _fuseLeft = _kFuseStart; // seconds left on the fuse
  double _dwell = 0; // reveal countdown after an answer

  // -- Run stats ---------------------------------------------------------------
  int _asked = 0; // cards resolved (drives escalation)
  int _streak = 0;
  int _lastPoints = 0;

  // -- Painter-side juice -------------------------------------------------------
  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];
  double _flash = 0; // red miss vignette, 1 → 0
  double _shake = 0; // miss shake, 1 → 0

  Size _fieldSize = Size.zero;
  bool _started = false;

  // ==========================================================================
  // Lifecycle
  // ==========================================================================

  @override
  void initState() {
    super.initState();
    _buildPools();
    _loadNextCard();
    _ticker = createTicker(_onTick)..start();
    widget.session.addListener(_onSessionPhase);
    // ATTRACT autopilot: answers correctly ~85% of the time at a watchable,
    // human pace (the interval buffers the host's ~250ms cadence).
    widget.session.autoPilot = _autoStep;
    widget.session.autoPilotInterval = const Duration(milliseconds: 1200);
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    widget.session.removeListener(_onSessionPhase);
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  /// Session re-entry (the S in GAMES): if the host resets the session back to
  /// intro after a finished run, rebuild a completely fresh run.
  void _onSessionPhase() {
    if (widget.session.phase == MiniGamePhase.intro && _started) {
      setState(() {
        _started = false;
        _asked = 0;
        _streak = 0;
        _lastPoints = 0;
        _flash = 0;
        _shake = 0;
        _particles.clear();
        _pops.clear();
        _buildPools();
        _loadNextCard();
      });
    }
  }

  // ==========================================================================
  // ATTRACT autopilot
  // ==========================================================================

  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_state == _CardState.waiting) {
      // ~85% correct — it may read the card's answer; misses look human.
      if (_rng.nextDouble() < 0.85) {
        _onOptionTap(_correctIndex);
      } else {
        _onOptionTap((_correctIndex + 1 + _rng.nextInt(3)) % 4);
      }
    } else if (_state != _CardState.correct) {
      _skipReveal(); // don't linger on the why-card forever
    }
  }

  // ==========================================================================
  // Question pools — no repeats within a run
  // ==========================================================================

  void _buildPools() {
    _pools = [
      kCodeTriviaBank.where((q) => q.tier == 1).toList()..shuffle(_rng),
      kCodeTriviaBank.where((q) => q.tier == 2).toList()..shuffle(_rng),
      kCodeTriviaBank.where((q) => q.tier == 3).toList()..shuffle(_rng),
    ];
  }

  int get _tier => _asked < _kTier2At ? 1 : (_asked < _kTier3At ? 2 : 3);

  CodeTriviaQuestion? _draw() {
    // Preferred tier first, then spill to harder, then easier — a card is
    // never repeated within a run (67-question bank vs ~20-card round).
    final order = <int>[_tier - 1, ...[2, 1, 0].where((i) => i != _tier - 1)];
    for (final i in order) {
      if (_pools[i].isNotEmpty) return _pools[i].removeLast();
    }
    return null; // bank exhausted (can't happen in 60 s) — hold the last card
  }

  void _loadNextCard() {
    final q = _draw();
    if (q == null) return;
    _q = q;
    _options = [q.correct, ...q.distractors]..shuffle(_rng);
    _correctIndex = _options.indexOf(q.correct);
    _tappedIndex = -1;
    _state = _CardState.waiting;
    _fuseTime = math.max(_kFuseFloor, _kFuseStart - _kFuseStep * _asked);
    _fuseLeft = _fuseTime;
  }

  // ==========================================================================
  // Sim — ticker-driven; NO setState here except at discrete transitions
  // ==========================================================================

  void _onTick(Duration elapsed) {
    final dt =
        ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    _clock += dt;

    if (widget.session.isRunning) {
      if (!_started) {
        _started = true;
        if (mounted) setState(() {}); // discrete: round begins
      }
      if (_state == _CardState.waiting) {
        _fuseLeft -= dt;
        if (_fuseLeft <= 0) _resolveTimeout(); // discrete: fuse died
      } else {
        _dwell -= dt;
        if (_dwell <= 0) _advance(); // discrete: next card
      }
    }

    if (_flash > 0) _flash = math.max(0, _flash - dt / 0.4);
    if (_shake > 0) _shake = math.max(0, _shake - dt / 0.45);
    _particles.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    _repaint.value++; // repaint the canvas — widgets stay put
  }

  void _advance() {
    if (!mounted) return;
    setState(() {
      _asked++;
      _loadNextCard();
    });
  }

  void _skipReveal() {
    if (_state == _CardState.waiting) return;
    _dwell = 0;
  }

  // ==========================================================================
  // Answering
  // ==========================================================================

  int _multiplier() => math.min(_kMaxMultiplier, 1 + _streak ~/ _kStreakStep);

  void _onOptionTap(int index) {
    if (!widget.session.isRunning) return;
    if (_state != _CardState.waiting) return;
    if (index < 0 || index >= _options.length) return;

    final correct = index == _correctIndex;
    setState(() {
      _tappedIndex = index;
      if (correct) {
        _streak++;
        final mult = _multiplier();
        final speed =
            (_kSpeedPoints * (_fuseLeft / _fuseTime).clamp(0.0, 1.0)).round();
        _lastPoints = (_kBasePoints + speed) * mult;
        widget.session.addScore(_lastPoints);
        widget.session.noteStreak(_streak);
        _state = _CardState.correct;
        _dwell = _kCorrectDwell;
        _celebrate(mult);
      } else {
        _streak = 0;
        _state = _CardState.wrong;
        _dwell = _kRevealDwell;
        _flash = 1;
        _shake = 1;
      }
    });
  }

  void _resolveTimeout() {
    if (!mounted) return;
    setState(() {
      _streak = 0;
      _state = _CardState.timeout;
      _dwell = _kRevealDwell;
      _flash = 1;
      _shake = 1;
    });
  }

  void _celebrate(int mult) {
    final c = _fieldSize.isEmpty
        ? const Offset(180, 320)
        : Offset(_fieldSize.width / 2, _fieldSize.height * 0.42);
    _particles.addAll(FxBurst.spawn(c, _kGood, count: 16, speed: 150));
    if (_streak > 0 && _streak % _kStreakStep == 0) {
      _particles.addAll(FxBurst.spawn(c, _kGold, count: 14, speed: 190));
    }
    _pops.add(FxPop(
        c.translate(0, -30),
        mult > 1 ? '+$_lastPoints ×$mult' : '+$_lastPoints',
        mult > 1 ? _kGold : _kGood));
  }

  // ==========================================================================
  // Build — rebuilt only on discrete events
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
      final content = _started ? _buildPlayColumn() : _buildReadyState();
      return ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _CodeTriviaPainter(this, repaint: _repaint),
                ),
              ),
            ),
            // Miss-shake: the Transform rebuilds per frame while shaking, but
            // its child is hoisted — the subtree itself never rebuilds.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _repaint,
                builder: (context, child) {
                  final dx = _shake <= 0
                      ? 0.0
                      : math.sin((1 - _shake) * math.pi * 6) * 6 * _shake;
                  return Transform.translate(offset: Offset(dx, 0), child: child);
                },
                child: content,
              ),
            ),
          ],
        ),
      );
    });
  }

  // -- Ready state (pre-countdown; the host overlays 3·2·1) -------------------

  Widget _buildReadyState() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.terminal_rounded, size: 42, color: _kAccent),
              const SizedBox(height: 14),
              Text('CODE TRIVIA',
                  textAlign: TextAlign.center,
                  style: Potatuhs.display(size: 26)),
              const SizedBox(height: 10),
              Text(
                'A programming question, four answers, one burning fuse. '
                'Tap the truth before the fuse dies — faster taps and longer '
                'streaks score more.',
                textAlign: TextAlign.center,
                style: Potatuhs.body(
                    size: 14, color: Potatuhs.textSecondary, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -- Play column -------------------------------------------------------------

  Widget _buildPlayColumn() {
    final q = _q;
    if (q == null) return const SizedBox.shrink();
    final answered = _state != _CardState.waiting;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const SizedBox(height: _kTopReserve), // painted HUD + fuse live here
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTierChip(),
                  const SizedBox(height: 12),
                  Text.rich(
                    _codeSpan(
                        q.prompt,
                        Potatuhs.body(
                            size: 19,
                            weight: FontWeight.w800,
                            height: 1.3)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
              child: Column(
                children: [
                  for (var i = 0; i < _options.length; i++) ...[
                    Expanded(child: _buildOptionChip(i)),
                    if (i < _options.length - 1) const SizedBox(height: 9),
                  ],
                ],
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: answered && _state != _CardState.correct
                ? _buildWhyBanner()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildTierChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kAccent.withValues(alpha: 0.7), width: 1.3),
      ),
      child: Text('CODE TRIVIA · TIER $_tier',
          style: Potatuhs.label(size: 11, color: _kAccent)),
    );
  }

  Widget _buildOptionChip(int index) {
    final answered = _state != _CardState.waiting;
    final isCorrect = index == _correctIndex;
    final isTapped = index == _tappedIndex;

    Color border = _kCardBorder;
    Color bg = _kCardBg;
    Color text = Potatuhs.textPrimary;
    if (answered) {
      if (isCorrect) {
        border = _kGood.withValues(alpha: 0.9);
        bg = _kGood.withValues(alpha: 0.12);
        text = _kGood;
      } else if (isTapped) {
        border = _kBad.withValues(alpha: 0.9);
        bg = _kBad.withValues(alpha: 0.10);
        text = _kBad;
      } else {
        border = _kCardBorder.withValues(alpha: 0.35);
        text = Potatuhs.textFaint;
      }
    }

    return GestureDetector(
      onTap: () => _onOptionTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.6),
          boxShadow: answered && isCorrect
              ? Potatuhs.glow(_kGood, strength: 0.3, blur: 14)
              : null,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text.rich(
              _codeSpan(
                  _options[index],
                  Potatuhs.body(
                      size: 15, weight: FontWeight.w700, color: text,
                      height: 1.25)),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
          ),
        ),
      ),
    );
  }

  // -- The why banner (wrong / timeout — the teach-in-context moment) ---------

  Widget _buildWhyBanner() {
    final q = _q;
    if (q == null) return const SizedBox.shrink();
    final timedOut = _state == _CardState.timeout;
    return GestureDetector(
      key: ValueKey(q.prompt),
      onTap: _skipReveal,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: Potatuhs.surface(
          fill: Potatuhs.inkPanel,
          borderColor: _kBad.withValues(alpha: 0.55),
          radius: 14,
          glowColor: _kBad,
          glowStrength: 0.15,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(timedOut ? 'FUSE OUT — THE ANSWER:' : 'THE ANSWER:',
                style: Potatuhs.label(size: 10, color: _kBad)),
            const SizedBox(height: 4),
            Text.rich(
              _codeSpan(
                  q.correct,
                  Potatuhs.body(
                      size: 15, weight: FontWeight.w800, color: _kGood)),
            ),
            const SizedBox(height: 4),
            Text.rich(
              _codeSpan(
                  q.why,
                  Potatuhs.body(
                      size: 12.5,
                      color: Potatuhs.textSecondary,
                      height: 1.35)),
              maxLines: 3,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('TAP TO CONTINUE',
                    style: Potatuhs.label(
                        size: 9,
                        color: _kAccent.withValues(alpha: 0.8))),
                const SizedBox(width: 3),
                Icon(Icons.arrow_forward,
                    size: 11, color: _kAccent.withValues(alpha: 0.8)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Painter — ALL continuous motion + the painted HUD (score / mult / clock /
// fuse / particles / pops / miss-flash). Repainted by the ticker's notifier.
// ============================================================================

class _CodeTriviaPainter extends CustomPainter {
  final _CodeTriviaGameState g;

  _CodeTriviaPainter(this.g, {required Listenable repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 8 || size.height < 8) return; // degenerate-size guard

    GameFx.atmosphere(canvas, size, _kAccent, g._clock, motes: 28);

    if (g._started) {
      _paintHud(canvas, size);
      _paintFuse(canvas, size);
    }

    FxBurst.paint(canvas, g._particles);
    for (final p in g._pops) {
      p.paint(canvas);
    }

    // Miss flash — a red vignette that decays over ~0.4s.
    if (g._flash > 0) {
      final rect = Offset.zero & size;
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            radius: 1.1,
            colors: [
              _kBad.withValues(alpha: 0.0),
              _kBad.withValues(alpha: 0.22 * g._flash),
            ],
          ).createShader(rect),
      );
    }
  }

  void _paintHud(Canvas canvas, Size size) {
    // Faded strip so the HUD reads over any background.
    final strip = Rect.fromLTWH(0, 0, size.width, _kHudHeight + 16);
    canvas.drawRect(
      strip,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Potatuhs.inkDeep.withValues(alpha: 0.85),
            Potatuhs.inkDeep.withValues(alpha: 0.0),
          ],
        ).createShader(strip),
    );

    const midY = _kHudHeight / 2 + 6;

    // Score (left) with a soft accent glow.
    final score = g.widget.session.score;
    GameFx.text(canvas, '$score', const Offset(46, midY), 20,
        Potatuhs.textPrimary,
        weight: FontWeight.w900, glow: 0.5);

    // ×multiplier chip once a streak is rolling.
    if (g._streak >= _kStreakStep) {
      final chip = Rect.fromCenter(
          center: const Offset(100, midY), width: 44, height: 22);
      final rr = RRect.fromRectAndRadius(chip, const Radius.circular(7));
      canvas.drawRRect(rr, Paint()..color = _kGold.withValues(alpha: 0.18));
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..color = _kGold.withValues(alpha: 0.8),
      );
      GameFx.text(canvas, '×${g._multiplier()}', chip.center, 13, _kGold,
          weight: FontWeight.w800);
    }

    // Clock (right) — warning red in the final 5 s.
    final remaining = g.widget.session.remaining;
    final secs = remaining.inSeconds;
    final tenths = (remaining.inMilliseconds / 100).floor() % 10;
    final danger = secs < 5;
    GameFx.text(
      canvas,
      '$secs.$tenths',
      Offset(size.width - 44, midY),
      18,
      danger ? _kBad : Potatuhs.textSecondary,
      weight: FontWeight.w700,
      glow: danger ? 0.8 : 0,
    );
  }

  void _paintFuse(Canvas canvas, Size size) {
    if (g._state != _CardState.waiting) return;
    final track = Rect.fromLTWH(_kFuseInset, _kHudHeight + 8,
        size.width - _kFuseInset * 2, _kFuseHeight);
    if (track.width <= 0) return;

    final frac = (g._fuseLeft / g._fuseTime).clamp(0.0, 1.0);
    final danger = frac < 0.28;

    final rr = RRect.fromRectAndRadius(track, const Radius.circular(4));
    canvas.drawRRect(rr, Paint()..color = Potatuhs.inkPanel);

    final fill = Rect.fromLTWH(
        track.left, track.top, track.width * frac, track.height);
    if (fill.width > 1) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(fill, const Radius.circular(4)),
        Paint()
          ..shader = LinearGradient(
            colors: danger
                ? [_kBad, Potatuhs.orange]
                : [_kAccent, Potatuhs.gold],
          ).createShader(fill),
      );
      // The burning tip — a small living spark, flickering on the clock.
      final tip = Offset(fill.right, fill.center.dy);
      final flicker = 2.4 + 1.1 * math.sin(g._clock * 22);
      GameFx.orb(canvas, tip, flicker, danger ? _kBad : _kGold,
          glow: 1.4, specular: false);
    }

    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = (danger ? _kBad : _kAccent).withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _CodeTriviaPainter oldDelegate) => false;
}

// ============================================================================
// Visual manual — legend frames in the game's OWN render vocabulary: the
// question card + four answer chips, the correct-answer flash + why-line,
// and the burning fuse. Static, cheap, self-contained.
// ============================================================================

void _legendChipCard(
  Canvas canvas,
  Rect r,
  String label,
  int state, // 0 neutral · 1 correct · 2 wrong · 3 dim
) {
  Color border = _kCardBorder;
  Color bg = _kCardBg;
  Color text = Potatuhs.textPrimary;
  switch (state) {
    case 1:
      border = _kGood.withValues(alpha: 0.9);
      bg = _kGood.withValues(alpha: 0.12);
      text = _kGood;
    case 2:
      border = _kBad.withValues(alpha: 0.9);
      bg = _kBad.withValues(alpha: 0.10);
      text = _kBad;
    case 3:
      border = _kCardBorder.withValues(alpha: 0.35);
      text = Potatuhs.textFaint;
  }
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(10));
  if (state == 1) {
    canvas.drawRRect(
      rr.inflate(3),
      Paint()
        ..color = _kGood.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }
  canvas.drawRRect(rr, Paint()..color = bg);
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = border,
  );
  GameFx.text(canvas, label, r.center, r.height < 26 ? 10.5 : 12, text,
      weight: FontWeight.w700);
}

void _legendPrompt(Canvas canvas, Size size, String prompt, double y) {
  final tp = TextPainter(
    text: TextSpan(
      text: prompt,
      style: const TextStyle(
        fontFamily: Potatuhs.bodyFont,
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
        color: Potatuhs.textPrimary,
        height: 1.25,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    maxLines: 2,
    ellipsis: '…',
  )..layout(maxWidth: size.width * 0.86);
  tp.paint(canvas,
      Offset(size.width / 2 - tp.width / 2, y - tp.height / 2));
}

void _legendFuseBar(Canvas canvas, Rect track, double frac, bool danger,
    {double sparkPhase = 0}) {
  final rr = RRect.fromRectAndRadius(track, const Radius.circular(4));
  canvas.drawRRect(rr, Paint()..color = Potatuhs.inkPanel);
  final fill =
      Rect.fromLTWH(track.left, track.top, track.width * frac, track.height);
  if (fill.width > 1) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(fill, const Radius.circular(4)),
      Paint()
        ..shader = LinearGradient(
          colors:
              danger ? [_kBad, Potatuhs.orange] : [_kAccent, Potatuhs.gold],
        ).createShader(fill),
    );
    GameFx.orb(canvas, Offset(fill.right, fill.center.dy),
        2.6 + math.sin(sparkPhase), danger ? _kBad : _kGold,
        glow: 1.4, specular: false);
  }
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = (danger ? _kBad : _kAccent).withValues(alpha: 0.55),
  );
}

// -- Frame 1 · the core loop: a question card and four answer chips. ---------
void _legendFrameCard(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final w = size.width, h = size.height;

  GameFx.text(canvas, 'CODE TRIVIA · TIER 1', Offset(w * 0.5, h * 0.08), 10,
      _kAccent,
      weight: FontWeight.w800);
  _legendPrompt(
      canvas, size, 'Which language declares functions with fun?', h * 0.21);

  const labels = ['Swift', 'Kotlin', 'Go', 'Rust'];
  const states = [0, 1, 0, 0];
  for (var i = 0; i < 4; i++) {
    final r =
        Rect.fromLTWH(w * 0.12, h * (0.34 + i * 0.155), w * 0.76, h * 0.115);
    _legendChipCard(canvas, r, labels[i], states[i]);
  }
}

// -- Frame 2 · the teach: miss and the truth flashes with a one-line why. ----
void _legendFrameWhy(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final w = size.width, h = size.height;

  _legendPrompt(canvas, size, 'Who created Linux?', h * 0.10);

  const labels = ['Steve Wozniak', 'Linus Torvalds'];
  const states = [2, 1];
  for (var i = 0; i < 2; i++) {
    final r =
        Rect.fromLTWH(w * 0.12, h * (0.20 + i * 0.17), w * 0.76, h * 0.125);
    _legendChipCard(canvas, r, labels[i], states[i]);
  }

  // The why banner.
  final banner = Rect.fromLTWH(w * 0.08, h * 0.60, w * 0.84, h * 0.30);
  final rr = RRect.fromRectAndRadius(banner, const Radius.circular(10));
  canvas.drawRRect(rr, Paint()..color = Potatuhs.inkPanel);
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _kBad.withValues(alpha: 0.55),
  );
  GameFx.text(canvas, 'THE ANSWER:', Offset(banner.center.dx, h * 0.66), 9,
      _kBad,
      weight: FontWeight.w800);
  GameFx.text(canvas, 'Linus Torvalds', Offset(banner.center.dx, h * 0.74),
      12.5, _kGood,
      weight: FontWeight.w800);
  GameFx.text(canvas, 'started the kernel in 1991',
      Offset(banner.center.dx, h * 0.83), 10.5, Potatuhs.textSecondary,
      weight: FontWeight.w600);
}

// -- Frame 3 · the pressure: the fuse burns shorter every card. ---------------
void _legendFrameFuse(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final w = size.width, h = size.height;

  GameFx.text(canvas, 'THE FUSE', Offset(w * 0.5, h * 0.10), 13,
      Potatuhs.textPrimary,
      display: true, weight: FontWeight.w700);

  // A fresh fuse, a half fuse, and a dying red one — each shorter.
  _legendFuseBar(canvas,
      Rect.fromLTWH(w * 0.10, h * 0.28, w * 0.80, h * 0.055), 0.95, false);
  GameFx.text(canvas, 'EARLY · SLOW BURN', Offset(w * 0.5, h * 0.40), 9.5,
      Potatuhs.textFaint,
      weight: FontWeight.w700);

  _legendFuseBar(canvas,
      Rect.fromLTWH(w * 0.16, h * 0.52, w * 0.68, h * 0.055), 0.5, false,
      sparkPhase: 2);
  GameFx.text(canvas, 'LATER · SHORTER FUSE', Offset(w * 0.5, h * 0.64), 9.5,
      Potatuhs.textFaint,
      weight: FontWeight.w700);

  _legendFuseBar(canvas,
      Rect.fromLTWH(w * 0.24, h * 0.76, w * 0.52, h * 0.055), 0.18, true,
      sparkPhase: 4);
  GameFx.text(canvas, 'FUSE OUT = A MISS', Offset(w * 0.5, h * 0.88), 10,
      _kBad,
      weight: FontWeight.w800);
}

/// The visual manual for Code Trivia — wired into the registry spec by the
/// orchestrator. Frames use the game's own card/chip/fuse render vocabulary.
final List<LegendFrame> codeTriviaLegendFrames = [
  const LegendFrame(
    caption: 'Read the card — tap the true answer',
    paint: _legendFrameCard,
  ),
  const LegendFrame(
    caption: 'Miss and the truth flashes — read the why',
    paint: _legendFrameWhy,
  ),
  const LegendFrame(
    caption: 'Beat the fuse — it burns shorter every card',
    paint: _legendFrameFuse,
  ),
];
