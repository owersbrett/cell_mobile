import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ── Osmosis v2 — UX-refined alternative ──────────────────────────────────────
//
// What changed vs the original `OsmosisGame` (mapped to the teardown):
//
// • AFFORDANCE (teardown #1, the Farm-Panic trap): the invisible whole-screen
//   slider with a tiny 9px handle is gone. There is now an explicit BALANCE DECK
//   along the bottom — a fat drawn track with a big grabbable knob, WATER/SALT
//   end labels and a green ISOTONIC zone. A first-run ghost-hand "DRAG TO
//   BALANCE" hint slides L↔R on the deck and fades on first touch. Input is
//   eased (no absolute edge-slam): the knob glides toward the finger.
//
// • LEGIBILITY (teardown #2, two-stage indirection): the player no longer
//   steers an abstract `inject` that integrates into a separate VOLUME gauge.
//   The knob position IS the net tonicity the cell feels — one value, no hidden
//   offset. The environment DRIFT shoves that same knob, so "hold the knob in
//   the green against the push" is the whole loop. The two HUD bars collapse to
//   ONE thing to track (the knob), with the potato-cell itself as the fused
//   consequence read-out. Flux is fast (kFlux 0.55) so cause→effect is instant.
//
// • FAIR SCORING (teardown #3, runaway): uncapped +6/s + +35 recovery is
//   replaced with a capped multiplier (1×→3×) over a base rate, so a skilled
//   lead is a legible ~3× of a confused one — readable party standings. Host
//   owns clock / opponents / standings.
//
// • CLIMAX (teardown #4): the final 10s is a FINAL SURGE — drift escalates,
//   palette warms to alarm, points ×2, an edge pulse and a banner. Ends on a
//   STABILIZED / RUPTURED flourish instead of a silent clock expiry.
//
// • POTATUHS SKIN (teardown #5): the cell is a POTATO cell — firm golden turgor
//   vs a pale about-to-burst swell vs a brown limp shrivel — brand gold palette,
//   display-face callouts. Reads as an HPG title, not a stock applet.
//
// KEPT (the education + the best juice): osmosis = water crosses toward higher
// solute; hypo→swell/lyse, hyper→shrivel/crenate, isotonic = firm turgor; the
// crenating/swelling membrane tied to volume; the directional "water leaving →"
// sub-caption; the accelerating drift and fail-and-recover (re-forms at 0.50).

// ── Feel constants ───────────────────────────────────────────────────────────

/// Cell volume range. 0 = fully shriveled (crenated), 1 = burst (lysed).
const double _kBandMin = 0.34;
const double _kBandMax = 0.66;
const double _kBandCentre = 0.50;

/// Osmotic flux: volume change per unit net tonicity per second. Higher than the
/// original 0.20 so the cell responds *immediately* — cause→effect is graspable.
const double _kFlux = 0.55;

const double _kLyseAt = 0.97;
const double _kCrenateAt = 0.03;

/// Half-width of the green ISOTONIC zone on the knob track. Generous so holding
/// is achievable; outside it, flux begins.
const double _kIsoTol = 0.14;

/// Score: base points per second while the cell is healthy, times the combo
/// multiplier. Capped multiplier keeps leads legible (no runaway).
const double _kBasePerSec = 10.0;
const double _kMultGain = 0.45; // multiplier growth per healthy second
const double _kMultMax = 3.0;

/// Small fixed bonus for steering the cell back into the band (the dip-and-
/// recover teaching beat) — bounded, not the old uncapped +35.
const int _kRecoveryBonus = 15;

/// Environment drift, modelled as a velocity that shoves the knob. Both the
/// magnitude and the re-roll cadence escalate with progress.
const double _kDriftRangeBase = 0.40; // knob units / sec, early
const double _kDriftRangeGain = 0.70; // +range at full progress
const double _kRetargetBase = 2.2; // seconds between re-rolls, early
const double _kRetargetGain = 1.4; // shrink (faster) at full progress

/// Final-surge window (seconds remaining) and its escalations.
const double _kSurgeAt = 10.0;
const double _kSurgeDriftMul = 1.6;
const double _kSurgeScoreMul = 2.0;

// ── Palette (Potatuhs brand + osmosis cues) ──────────────────────────────────
const _kWater = Color(0xFF42A5F5); // hypotonic / dilute = cool blue
const _kSalt = Color(0xFFFFB74D); // hypertonic / salty = warm amber
const _kSafe = Color(0xFF69F0AE); // isotonic / firm turgor = green
const _kRed = Color(0xFFFF5252); // danger
const _kPotato = Potatuhs.sienna; // potato-cell cytoplasm base
const _kWhite = Colors.white;
const _kShrivel = Color(0xFF6B4423); // browned shrivel tint (matches _paintCell)

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards. Each is drawn statically with the
// SAME literal components the live game uses: the potato cell (firm / swollen /
// shriveled), the flux arrows, and the bottom BALANCE DECK with its knob.
// ═══════════════════════════════════════════════════════════════════════════

/// The potato cell exactly as `_paintCell` renders it, minus the live jitter:
/// firm golden turgor in-band, pale/taut when swelling, browned when shriveling.
void _legendCell(Canvas canvas, Offset center, double r, double volume) {
  if (r <= 1) return;
  final swell = ((volume - _kBandMax) / (1.0 - _kBandMax)).clamp(0.0, 1.0);
  final shrivel = ((_kBandMin - volume) / _kBandMin).clamp(0.0, 1.0);
  final strain = math.max(swell, shrivel);
  final inBand = volume >= _kBandMin && volume <= _kBandMax;

  Color body = _kPotato;
  if (swell > 0) body = Color.lerp(_kPotato, _kWater, swell * 0.5)!;
  if (shrivel > 0) body = Color.lerp(_kPotato, _kShrivel, shrivel)!;

  // Outer glow.
  canvas.drawCircle(
    center,
    r + 10,
    Paint()
      ..color = body.withValues(alpha: 0.18 + 0.22 * (inBand ? 1 : 0.4))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
  );

  // Membrane — crenated (spiky inward) when shriveled, taut when swollen.
  final path = Path();
  const seg = 72;
  final lobes = 7 + (shrivel * 5).round();
  final crenAmp = 0.11 * shrivel;
  final swellJitter = 0.018 * swell;
  for (var i = 0; i <= seg; i++) {
    final a = i / seg * 2 * math.pi;
    var w = math.sin(a * 3) * 0.012;
    w -= crenAmp * (0.5 + 0.5 * math.cos(a * lobes));
    w += swellJitter * math.sin(a * 11);
    final rr = r * (1 + w);
    final pt = center + Offset(math.cos(a), math.sin(a)) * rr;
    if (i == 0) {
      path.moveTo(pt.dx, pt.dy);
    } else {
      path.lineTo(pt.dx, pt.dy);
    }
  }
  path.close();

  // Cytoplasm fill.
  canvas.drawPath(
    path,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [
          Color.lerp(body, _kWhite, 0.45)!.withValues(alpha: 0.92),
          body.withValues(alpha: 0.85),
          Color.lerp(body, Colors.black, 0.5)!.withValues(alpha: 0.92),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r)),
  );

  // Membrane rim — whitens healthy, reddens under strain.
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 + 1.8 * swell
      ..color = Color.lerp(_kWhite, _kRed, strain)!
          .withValues(alpha: 0.7 + 0.3 * strain),
  );

  // Nucleus — the potato "eye".
  GameFx.orb(canvas, center.translate(r * 0.12, r * 0.1), r * 0.24,
      Potatuhs.orange,
      glow: 0.6);
}

/// The osmotic flux arrows as `_paintFluxArrows` draws them: inward blue when
/// water enters (hypotonic), outward amber when water leaves (hypertonic).
void _legendFluxArrows(Canvas canvas, Offset center, double r, bool inward) {
  if (r <= 1) return;
  final color = inward ? _kWater : _kSalt;
  const n = 10;
  for (var i = 0; i < n; i++) {
    final a = i / n * 2 * math.pi;
    final dir = Offset(math.cos(a), math.sin(a));
    final rr = r * 1.28;
    final pos = center + dir * rr;
    final headDir = inward ? -dir : dir;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pos - headDir * 9, pos, paint);
    final perp = Offset(-headDir.dy, headDir.dx);
    canvas.drawLine(pos, pos - headDir * 4 + perp * 3, paint);
    canvas.drawLine(pos, pos - headDir * 4 - perp * 3, paint);
  }
}

/// The bottom BALANCE DECK as `_paintDeck` draws it — WATER→ISOTONIC→SALT track,
/// green safe zone, and the big grabbable knob at [tonicity] (-1 water … +1 salt).
void _legendDeck(Canvas canvas, Size size, double tonicity) {
  final left = size.width * 0.10;
  final w = size.width * 0.80;
  if (w <= 2) return;
  final trackH = math.min(24.0, size.height * 0.11);
  final trackY = size.height - trackH - 30;
  final rect = Rect.fromLTWH(left, trackY, w, trackH);
  final track = RRect.fromRectAndRadius(rect, Radius.circular(trackH / 2));

  canvas.drawRRect(
    track,
    Paint()
      ..shader = const LinearGradient(
        colors: [_kWater, Color(0xFF2A2622), _kSalt],
        stops: [0.0, 0.5, 1.0],
      ).createShader(rect),
  );

  // Green isotonic safe zone in the centre.
  final zoneHalf = w * 0.5 * _kIsoTol;
  final cx = left + w / 2;
  final zone = RRect.fromRectAndRadius(
      Rect.fromLTRB(cx - zoneHalf, trackY - 2, cx + zoneHalf,
          trackY + trackH + 2),
      const Radius.circular(8));
  final knobGreen = tonicity.abs() < _kIsoTol;
  canvas.drawRRect(zone, Paint()..color = _kSafe.withValues(alpha: 0.22));
  canvas.drawRRect(
      zone,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = _kSafe.withValues(alpha: knobGreen ? 0.9 : 0.5));

  // The knob at the current net tonicity.
  final hx = cx + tonicity.clamp(-1.0, 1.0) * (w / 2);
  final hy = trackY + trackH / 2;
  final knobColor =
      knobGreen ? _kSafe : (tonicity < 0 ? _kWater : _kSalt);
  const knobR = 15.0;
  canvas.drawCircle(Offset(hx, hy), knobR + 7,
      Paint()
        ..color = knobColor.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  canvas.drawCircle(Offset(hx, hy), knobR, Paint()..color = knobColor);
  canvas.drawCircle(Offset(hx, hy), knobR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = Potatuhs.ink);
  for (var i = -1; i <= 1; i++) {
    canvas.drawCircle(Offset(hx + i * 5.0, hy), 1.6,
        Paint()..color = Potatuhs.ink.withValues(alpha: 0.7));
  }

  // End labels.
  GameFx.text(canvas, '◀ WATER', Offset(left + 34, trackY - 14), 10, _kWater,
      weight: FontWeight.w800);
  GameFx.text(canvas, 'SALT ▶', Offset(left + w - 30, trackY - 14), 10, _kSalt,
      weight: FontWeight.w800);
  GameFx.text(canvas, 'ISOTONIC', Offset(cx, trackY - 14), 9,
      _kSafe.withValues(alpha: 0.9), weight: FontWeight.w800);
}

// ── Frame 1 · the verb: hold firm turgor, knob in the green ──────────────────
void _legendFrameHold(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final sceneH = size.height * 0.60;
  final center = Offset(size.width * 0.5, sceneH * 0.5);
  final r = math.min(size.width, sceneH) * 0.26;
  // Faint green firm-turgor ring, as in _paintSafeRing.
  canvas.drawCircle(
    center,
    r + 12,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = _kSafe.withValues(alpha: 0.32),
  );
  _legendCell(canvas, center, r, _kBandCentre);
  GameFx.text(canvas, 'FIRM TURGOR', Offset(center.dx, center.dy + r + 20), 12,
      _kSafe, weight: FontWeight.w800, glow: 0.5);
  _legendDeck(canvas, size, 0.0);
}

// ── Frame 2 · how to score: stay in the band, combo climbs to ×3 ─────────────
void _legendFrameScore(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final sceneH = size.height * 0.60;
  final center = Offset(size.width * 0.42, sceneH * 0.5);
  final r = math.min(size.width, sceneH) * 0.24;
  canvas.drawCircle(
    center,
    r + 12,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = _kSafe.withValues(alpha: 0.32),
  );
  _legendCell(canvas, center, r, _kBandCentre);
  // The live multiplier chip, at cap.
  GameFx.text(canvas, '×3.0', Offset(size.width * 0.80, sceneH * 0.34), 22,
      _kSafe, display: true, glow: 0.6);
  GameFx.text(canvas, 'HEALTHY', Offset(size.width * 0.80, sceneH * 0.56), 10,
      _kWhite.withValues(alpha: 0.6), weight: FontWeight.w700);
  _legendDeck(canvas, size, 0.0);
}

// ── Frame 3 · the danger: burst when too dilute, shrivel when too salty ──────
void _legendFrameDanger(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final sceneH = size.height * 0.66;
  final r = math.min(size.width * 0.5, sceneH) * 0.28;
  final cy = sceneH * 0.46;
  // Left: swollen, bursting (lysis) — water flooding IN (hypotonic).
  final lc = Offset(size.width * 0.28, cy);
  _legendFluxArrows(canvas, lc, r * 1.28, true);
  _legendCell(canvas, lc, r * 1.28, 0.92);
  GameFx.text(canvas, 'LYSES', Offset(lc.dx, sceneH * 0.92), 11, _kWater,
      weight: FontWeight.w800);
  // Right: shriveled, crenated — water rushing OUT (hypertonic).
  final rc = Offset(size.width * 0.72, cy);
  _legendFluxArrows(canvas, rc, r * 0.68, false);
  _legendCell(canvas, rc, r * 0.68, 0.10);
  GameFx.text(canvas, 'CRENATES', Offset(rc.dx, sceneH * 0.92), 11, _kSalt,
      weight: FontWeight.w800);
  // The two knob extremes that cause each.
  _legendDeck(canvas, size, 0.0);
}

// ── Frame 4 · the climax: final 10s surge, drift spikes, points ×2 ───────────
void _legendFrameSurge(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  // Alarm vignette, as in _paintSurge.
  final rect = Offset.zero & size;
  canvas.drawRect(
    rect,
    Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, _kRed.withValues(alpha: 0.26)],
        stops: const [0.62, 1.0],
      ).createShader(rect),
  );
  final sceneH = size.height * 0.60;
  final center = Offset(size.width * 0.5, sceneH * 0.54);
  final r = math.min(size.width, sceneH) * 0.24;
  _legendCell(canvas, center, r, 0.62); // straining toward the top of the band
  GameFx.text(canvas, 'FINAL SURGE  ×2', Offset(size.width / 2, sceneH * 0.14),
      18, _kRed, display: true, glow: 0.8);
  // A knob shoved off-centre by the escalated drift.
  _legendDeck(canvas, size, 0.55);
}

/// The visual manual for Osmosis v2 — wired into the registry spec.
final List<LegendFrame> osmosisV2LegendFrames = [
  const LegendFrame(
      caption: 'Drag the knob to green — hold the cell at firm turgor',
      paint: _legendFrameHold),
  const LegendFrame(
      caption: 'Stay in the band: points build a combo up to ×3',
      paint: _legendFrameScore),
  const LegendFrame(
      caption: 'Too dilute bursts it (lysis); too salty shrivels it',
      paint: _legendFrameDanger),
  const LegendFrame(
      caption: 'Last 10s: FINAL SURGE — drift spikes, points ×2',
      paint: _legendFrameSurge),
];

/// Osmosis v2 — keep a POTATO cell at firm turgor by holding the surrounding
/// water at isotonic. Drag the balance knob into the green against an
/// environment that keeps drifting saltier or more dilute.
class OsmosisV2Game extends StatefulWidget {
  final MiniGameSession session;
  const OsmosisV2Game({super.key, required this.session});

  @override
  State<OsmosisV2Game> createState() => _OsmosisV2GameState();
}

class _OsmosisV2GameState extends State<OsmosisV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random();

  // ── Core state ─────────────────────────────────────────────────────────────
  double _volume = _kBandCentre;
  double _knob = 0.0; // -1 full water (hypotonic) … +1 full salt (hypertonic)
  double _driftForce = 0.0; // current environment push on the knob (units/sec)
  double _retargetTimer = 0.0;
  bool _touching = false;
  double _target = 0.0; // finger-driven knob target while touching
  bool _everTouched = false; // dismisses the onboarding ghost hand

  double get _tonicity => _knob.clamp(-1.0, 1.0);
  bool get _inBand => _volume >= _kBandMin && _volume <= _kBandMax;
  bool get _knobGreen => _tonicity.abs() < _kIsoTol;

  // ── Scoring ────────────────────────────────────────────────────────────────
  double _scoreAcc = 0.0;
  double _mult = 1.0;
  bool _wasInBand = true;
  int _recoveries = 0;
  int _healthyStreak = 0;
  double _healthySecAcc = 0.0;

  // ── Juice ──────────────────────────────────────────────────────────────────
  double _idlePhase = 0.0;
  double _membranePhase = 0.0;
  double _fluxPhase = 0.0;
  double _hintPhase = 0.0;
  double _healFlash = 0.0;
  double _burstFlash = 0.0;
  double _shake = 0.0;
  double _surgePulse = 0.0;
  bool _surge = false;
  bool _endShown = false;
  String _eventLabel = '';
  Color _eventColor = _kSafe;
  double _eventLife = 0.0;
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ────────────────────────────────────────────────────────
  // One competent move per call: hold the potato cell at firm turgor by dragging
  // the BALANCE KNOB. Volume drifts by -_kFlux * tonicity, so project it a short
  // horizon ahead under the current (drift-shoved) knob; if that projection is
  // leaving the healthy band, steer the knob target toward the tonicity that
  // pushes volume back to centre (positive tonicity sheds water when swollen,
  // negative draws it in when shriveled). When comfortably centred and already
  // isotonic, hold the knob green. Deterministic — sets the same field a real
  // drag sets (`_touching` + `_target`); no randomness, no synthetic taps.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    _everTouched = true; // dismiss the onboarding ghost hand
    // Project volume a few ticks ahead assuming the knob stays near where it is.
    const horizon = 0.35; // seconds
    final projVol = (_volume - _kFlux * _tonicity * horizon).clamp(0.0, 1.0);
    final err = projVol - _kBandCentre; // >0 too swollen, <0 too shriveled
    double target;
    if (err.abs() < 0.02 && _tonicity.abs() < _kIsoTol) {
      target = 0.0; // centred and green: hold isotonic
    } else {
      // Proportional correction; sign(err) == sign(needed tonicity).
      target = (err * 4.0).clamp(-1.0, 1.0);
    }
    _touching = true; // held drag: knob eases toward _target each tick
    _target = target;
  }

  double _remainingSec() => widget.session.remaining.inMilliseconds / 1000.0;

  double _progress() {
    final total = widget.session.spec.durationSeconds;
    if (total <= 0) return 0.0;
    return (1.0 - _remainingSec() / total).clamp(0.0, 1.0);
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    final running = widget.session.isRunning;
    final progress = running ? _progress() : 0.0;
    _surge = running && _remainingSec() <= _kSurgeAt;

    _idlePhase += dt;
    _hintPhase += dt;
    _membranePhase += dt * (0.9 + 1.4 * _tonicity.abs());
    _fluxPhase += dt * (0.6 + 2.4 * _tonicity.abs());
    if (_surge) _surgePulse += dt * 6.0;

    if (running) {
      // ── Environment drift shoves the knob (re-rolls, accelerating) ──────────
      _retargetTimer -= dt;
      if (_retargetTimer <= 0) {
        var range = _kDriftRangeBase + _kDriftRangeGain * progress;
        var period = (_kRetargetBase - _kRetargetGain * progress)
            .clamp(0.7, _kRetargetBase);
        if (_surge) {
          range *= _kSurgeDriftMul;
          period *= 0.6;
        }
        _driftForce = (_rng.nextDouble() * 2 - 1) * range;
        _retargetTimer = period;
      }
      _knob += _driftForce * dt;

      // ── Player drag eases the knob toward the finger (no edge-slam) ─────────
      if (_touching) {
        _knob += (_target - _knob) * (10.0 * dt).clamp(0.0, 1.0);
      }
      _knob = _knob.clamp(-1.0, 1.0);

      // ── Osmotic flux: net tonicity moves water across the membrane ──────────
      _volume = (_volume - _kFlux * _tonicity * dt).clamp(0.0, 1.0);

      // ── Scoring: capped multiplier over a base rate ────────────────────────
      if (_inBand) {
        _mult = math.min(_kMultMax, _mult + _kMultGain * dt);
        final rate = _kBasePerSec * _mult * (_surge ? _kSurgeScoreMul : 1.0);
        _scoreAcc += rate * dt;
        final whole = _scoreAcc.floor();
        if (whole > 0) {
          widget.session.addScore(whole);
          _scoreAcc -= whole;
        }
        _healthySecAcc += dt;
        while (_healthySecAcc >= 1.0) {
          _healthySecAcc -= 1.0;
          _healthyStreak++;
          widget.session.noteStreak(_healthyStreak);
        }
        if (!_wasInBand) {
          _recoveries++;
          widget.session.addScore(_kRecoveryBonus);
          _flash(_kSafe);
          _event('RECOVERED  +$_kRecoveryBonus', _kSafe);
          _pops.add(FxPop(Offset.zero, '+$_kRecoveryBonus', _kSafe));
          _fx.addAll(FxBurst.spawn(Offset.zero, _kSafe, count: 14, speed: 150));
        }
      } else {
        _mult = 1.0;
        _healthyStreak = 0;
        _healthySecAcc = 0.0;
      }

      // ── Fail-and-recover extremes ──────────────────────────────────────────
      if (_volume >= _kLyseAt) {
        _failEvent('LYSED — too much water!', salty: false);
      } else if (_volume <= _kCrenateAt) {
        _failEvent('CRENATED — too salty!', salty: true);
      }
      _wasInBand = _inBand;
    } else {
      // Calm ready / post-round state: settle to isotonic firm turgor.
      _knob += (0.0 - _knob) * (2.2 * dt).clamp(0.0, 1.0);
      _driftForce = 0.0;
      _retargetTimer = 0.0;
      _volume += (_kBandCentre - _volume) * (1.4 * dt).clamp(0.0, 1.0);
      _wasInBand = _inBand;
      // One-shot end flourish the first frame after the clock stops.
      if (widget.session.phase == MiniGamePhase.finished && !_endShown) {
        _endShown = true;
        final ok = _volume >= _kBandMin && _volume <= _kBandMax;
        _event(ok ? 'STABILIZED!' : 'RUPTURED', ok ? _kSafe : _kRed);
        _flash(ok ? _kSafe : _kRed);
        _fx.addAll(FxBurst.spawn(
            Offset.zero, ok ? _kSafe : _kRed,
            count: 22, speed: 200));
      }
    }

    // ── Decay juice ────────────────────────────────────────────────────────────
    _healFlash = math.max(0.0, _healFlash - dt * 2.6);
    _burstFlash = math.max(0.0, _burstFlash - dt * 2.0);
    _shake = math.max(0.0, _shake - dt * 4.0);
    _eventLife = math.max(0.0, _eventLife - dt);
    _fx.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    setState(() {});
  }

  void _flash(Color c) {
    if (c == _kSafe) {
      _healFlash = 1.0;
    } else {
      _burstFlash = 1.0;
      _shake = 1.0;
    }
  }

  void _event(String text, Color c) {
    _eventLabel = text;
    _eventColor = c;
    _eventLife = 1.6;
  }

  void _failEvent(String label, {required bool salty}) {
    _flash(_kRed);
    _event(label, _kRed);
    _recoveries = 0;
    _healthyStreak = 0;
    _healthySecAcc = 0.0;
    _mult = 1.0;
    _volume = _kBandCentre; // re-forms at firm turgor — setback, not game over
    _wasInBand = true;
    _fx.addAll(FxBurst.spawn(Offset.zero, salty ? _kSalt : _kWater,
        count: 24, speed: 220));
  }

  // ── Input: drag the balance knob (eased toward finger; whole screen drives it
  //    but the deck is drawn big and obvious so the affordance reads) ──────────
  void _grab(double localX, double width) {
    _touching = true;
    _everTouched = true;
    _setTarget(localX, width);
  }

  void _setTarget(double localX, double width) {
    _target = width <= 0 ? 0.0 : ((localX / width) - 0.5) * 2.0;
    _target = _target.clamp(-1.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final dx = _shake > 0 ? (_rng.nextDouble() - 0.5) * 10 * _shake : 0.0;
      final dy = _shake > 0 ? (_rng.nextDouble() - 0.5) * 10 * _shake : 0.0;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _grab(d.localPosition.dx, size.width),
        onTapUp: (_) => _touching = false,
        onTapCancel: () => _touching = false,
        onPanDown: (d) => _grab(d.localPosition.dx, size.width),
        onPanUpdate: (d) => _setTarget(d.localPosition.dx, size.width),
        onPanEnd: (_) => _touching = false,
        onPanCancel: () => _touching = false,
        child: ClipRect(
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: CustomPaint(
              size: Size.infinite,
              painter: _OsmosisV2Painter(
                volume: _volume,
                tonicity: _tonicity,
                knobGreen: _knobGreen,
                inBand: _inBand,
                touching: _touching,
                showHint: !_everTouched,
                surge: _surge,
                mult: _mult,
                healthyStreak: _healthyStreak,
                recoveries: _recoveries,
                idlePhase: _idlePhase,
                membranePhase: _membranePhase,
                fluxPhase: _fluxPhase,
                hintPhase: _hintPhase,
                surgePulse: _surgePulse,
                healFlash: _healFlash,
                burstFlash: _burstFlash,
                eventLabel: _eventLabel,
                eventColor: _eventColor,
                eventAlpha: (_eventLife / 1.6).clamp(0.0, 1.0),
                fx: _fx,
                pops: _pops,
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════════

class _OsmosisV2Painter extends CustomPainter {
  final double volume;
  final double tonicity;
  final bool knobGreen;
  final bool inBand;
  final bool touching;
  final bool showHint;
  final bool surge;
  final double mult;
  final int healthyStreak;
  final int recoveries;
  final double idlePhase;
  final double membranePhase;
  final double fluxPhase;
  final double hintPhase;
  final double surgePulse;
  final double healFlash;
  final double burstFlash;
  final String eventLabel;
  final Color eventColor;
  final double eventAlpha;
  final List<FxParticle> fx;
  final List<FxPop> pops;

  _OsmosisV2Painter({
    required this.volume,
    required this.tonicity,
    required this.knobGreen,
    required this.inBand,
    required this.touching,
    required this.showHint,
    required this.surge,
    required this.mult,
    required this.healthyStreak,
    required this.recoveries,
    required this.idlePhase,
    required this.membranePhase,
    required this.fluxPhase,
    required this.hintPhase,
    required this.surgePulse,
    required this.healFlash,
    required this.burstFlash,
    required this.eventLabel,
    required this.eventColor,
    required this.eventAlpha,
    required this.fx,
    required this.pops,
  });

  // Deck geometry (the explicit balance control along the bottom).
  static const double _deckH = 132.0;
  static const double _deckPad = 26.0;
  static const double _trackH = 26.0;

  @override
  void paint(Canvas canvas, Size size) {
    final accent = surge ? _kSalt : _kPotato;
    GameFx.atmosphere(canvas, size, accent, idlePhase, motes: 18);
    _paintSolution(canvas, size);

    // Cell scene lives above the deck.
    final sceneH = size.height - _deckH;
    final center = Offset(size.width * 0.5, sceneH * 0.46);
    final maxR = math.min(size.width, sceneH) * 0.30;
    _paintSafeRing(canvas, center, maxR);
    _paintFluxArrows(canvas, center, maxR);
    _paintCell(canvas, center, maxR);
    _paintFx(canvas, center);
    _paintStateLabel(canvas, size, center, maxR);

    _paintDeck(canvas, size);
    if (showHint) _paintHint(canvas, size);
    _paintScoreChip(canvas, size);
    if (surge) _paintSurge(canvas, size);
    _paintEvent(canvas, size, sceneH);
    _paintPops(canvas, center);
    _paintFlash(canvas, size);
  }

  // ── Solution field: tinted by tonicity, more solute dots when salty ─────────
  void _paintSolution(Canvas canvas, Size size) {
    final t = tonicity;
    final tint = t > 0
        ? _kSalt.withValues(alpha: 0.05 + 0.16 * t.clamp(0.0, 1.0))
        : _kWater.withValues(alpha: 0.05 + 0.16 * (-t).clamp(0.0, 1.0));
    canvas.drawRect(Offset.zero & size, Paint()..color = tint);

    final dotCount = (24 + 64 * t.clamp(0.0, 1.0)).round();
    final p = Paint()..color = _kSalt.withValues(alpha: 0.32);
    for (var i = 0; i < dotCount; i++) {
      final seed = i * 2.399963;
      final x = (size.width * ((seed * 0.618) % 1.0) +
              fluxPhase * (6 + (i % 4) * 5)) %
          size.width;
      final y = (size.height * ((seed * 0.314) % 1.0) +
              math.sin(fluxPhase * 0.7 + seed) * 6) %
          size.height;
      canvas.drawCircle(Offset(x, y), 1.6, p);
    }
  }

  // ── A faint green "firm turgor" ring fused around the cell (the safe read) ──
  void _paintSafeRing(Canvas canvas, Offset center, double maxR) {
    final healthyR = maxR * (0.42 + 0.58 * _kBandCentre);
    canvas.drawCircle(
      center,
      healthyR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = _kSafe.withValues(alpha: inBand ? 0.32 : 0.16),
    );
  }

  void _paintFluxArrows(Canvas canvas, Offset center, double maxR) {
    final t = tonicity;
    if (t.abs() < _kIsoTol) return;
    final inward = t < 0; // hypotonic ⇒ water enters
    final mag = t.abs().clamp(0.0, 1.0);
    final color = inward ? _kWater : _kSalt;
    final r = _cellRadius(maxR);
    const n = 10;
    for (var i = 0; i < n; i++) {
      final a = i / n * 2 * math.pi + idlePhase * 0.2;
      final dir = Offset(math.cos(a), math.sin(a));
      final phase = (fluxPhase * 0.9 + i * 0.6) % 1.0;
      final travel = inward ? (1.0 - phase) : phase;
      final rr = r * (0.78 + 0.7 * travel);
      final pos = center + dir * rr;
      final headDir = inward ? -dir : dir;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.6 * mag * (1 - (travel - 0.5).abs()))
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(pos - headDir * 7, pos, paint);
      final perp = Offset(-headDir.dy, headDir.dx);
      canvas.drawLine(pos, pos - headDir * 4 + perp * 3, paint);
      canvas.drawLine(pos, pos - headDir * 4 - perp * 3, paint);
    }
  }

  double _cellRadius(double maxR) => maxR * (0.42 + 0.58 * volume);

  // ── The potato cell — firm gold turgor vs pale swell vs brown shrivel ───────
  void _paintCell(Canvas canvas, Offset center, double maxR) {
    final r = _cellRadius(maxR);
    final swell = ((volume - _kBandMax) / (1.0 - _kBandMax)).clamp(0.0, 1.0);
    final shrivel = ((_kBandMin - volume) / _kBandMin).clamp(0.0, 1.0);
    final strain = math.max(swell, shrivel);

    // Potato cytoplasm: firm golden when healthy; pale/taut when swelling toward
    // burst; browned when shriveling.
    Color body = _kPotato;
    if (swell > 0) body = Color.lerp(_kPotato, _kWater, swell * 0.5)!;
    if (shrivel > 0) body = Color.lerp(_kPotato, const Color(0xFF6B4423), shrivel)!;

    // Outer glow.
    canvas.drawCircle(
      center,
      r + 10,
      Paint()
        ..color = body.withValues(alpha: 0.18 + 0.22 * (inBand ? 1 : 0.4))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Membrane path — crenated (spiky inward) when shriveled, taut quiver near burst.
    final path = Path();
    const seg = 72;
    final lobes = 7 + (shrivel * 5).round();
    final crenAmp = 0.11 * shrivel;
    final swellJitter = 0.018 * swell;
    for (var i = 0; i <= seg; i++) {
      final a = i / seg * 2 * math.pi;
      var w = math.sin(a * 3 + membranePhase) * 0.012;
      w -= crenAmp * (0.5 + 0.5 * math.cos(a * lobes - membranePhase * 1.4));
      w += swellJitter * math.sin(a * 11 + membranePhase * 3);
      final rr = r * (1 + w);
      final pt = center + Offset(math.cos(a), math.sin(a)) * rr;
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();

    // Cytoplasm fill.
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [
            Color.lerp(body, _kWhite, 0.45)!.withValues(alpha: 0.92),
            body.withValues(alpha: 0.85),
            Color.lerp(body, Colors.black, 0.5)!.withValues(alpha: 0.92),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Membrane rim — whitens healthy, reddens under strain.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 + 1.8 * swell
        ..color = Color.lerp(_kWhite, _kRed, strain)!
            .withValues(alpha: 0.7 + 0.3 * strain),
    );

    // Nucleus — a potato "eye".
    GameFx.orb(canvas, center.translate(r * 0.12, r * 0.1), r * 0.24,
        Potatuhs.orange,
        glow: 0.6);
  }

  void _paintFx(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    FxBurst.paint(canvas, fx);
    canvas.restore();
  }

  // ── Cell-state caption + the directional "why" (kept from original) ─────────
  void _paintStateLabel(Canvas canvas, Size size, Offset center, double maxR) {
    String s;
    Color c;
    if (volume > _kBandMax + 0.04) {
      s = 'SWELLING — bursting (lysis)';
      c = _kWater;
    } else if (volume < _kBandMin - 0.04) {
      s = 'SHRIVELING — crenation';
      c = _kSalt;
    } else {
      s = 'FIRM TURGOR';
      c = _kSafe;
    }
    GameFx.text(canvas, s, Offset(center.dx, center.dy + maxR + 24), 14, c,
        weight: FontWeight.w800, glow: 0.5);

    String sub;
    if (tonicity.abs() < _kIsoTol) {
      sub = 'isotonic — water balanced';
    } else if (tonicity > 0) {
      sub = 'hypertonic — water leaving cell →';
    } else {
      sub = '← hypotonic — water entering cell';
    }
    GameFx.text(canvas, sub, Offset(center.dx, center.dy + maxR + 42), 10,
        _kWhite.withValues(alpha: 0.6));
  }

  // ── The explicit BALANCE DECK (the affordance fix) ──────────────────────────
  void _paintDeck(Canvas canvas, Size size) {
    final top = size.height - _deckH;
    // Panel.
    final panel = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, top, size.width, _deckH),
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
    );
    canvas.drawRRect(panel, Paint()..color = Potatuhs.inkPanel.withValues(alpha: 0.96));
    canvas.drawRRect(
        panel,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = _kWhite.withValues(alpha: 0.10));

    final left = _deckPad;
    final w = size.width - _deckPad * 2;
    final trackY = top + _deckH - 56.0;
    final track = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, trackY, w, _trackH),
        Radius.circular(_trackH / 2));

    // Track gradient: WATER (blue) … ISOTONIC (green) … SALT (amber).
    canvas.drawRRect(
      track,
      Paint()
        ..shader = const LinearGradient(
          colors: [_kWater, Color(0xFF2A2622), _kSalt],
          stops: [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(left, trackY, w, _trackH)),
    );

    // Green isotonic safe zone in the centre.
    final zoneHalf = w * 0.5 * _kIsoTol / 1.0;
    final cx = left + w / 2;
    final zone = RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - zoneHalf, trackY - 2, cx + zoneHalf,
            trackY + _trackH + 2),
        const Radius.circular(8));
    canvas.drawRRect(zone, Paint()..color = _kSafe.withValues(alpha: 0.22));
    canvas.drawRRect(
        zone,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = _kSafe.withValues(alpha: knobGreen ? 0.9 : 0.5));

    canvas.drawRRect(
        track,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = _kWhite.withValues(alpha: 0.18));

    // Big grabbable knob at the current net tonicity.
    final hx = cx + tonicity.clamp(-1.0, 1.0) * (w / 2);
    final hy = trackY + _trackH / 2;
    final knobColor = knobGreen
        ? _kSafe
        : (tonicity < 0 ? _kWater : _kSalt);
    final knobR = touching ? 19.0 : 16.0;
    canvas.drawCircle(Offset(hx, hy), knobR + 7,
        Paint()
          ..color = knobColor.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(Offset(hx, hy), knobR, Paint()..color = knobColor);
    canvas.drawCircle(Offset(hx, hy), knobR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = Potatuhs.ink);
    // Grip dots on the knob.
    for (var i = -1; i <= 1; i++) {
      canvas.drawCircle(Offset(hx + i * 5.0, hy), 1.6,
          Paint()..color = Potatuhs.ink.withValues(alpha: 0.7));
    }

    // End labels.
    GameFx.text(canvas, '◀ WATER', Offset(left + 40, trackY - 16), 11,
        _kWater, weight: FontWeight.w800);
    GameFx.text(canvas, 'SALT ▶', Offset(left + w - 36, trackY - 16), 11,
        _kSalt, weight: FontWeight.w800);
    GameFx.text(canvas, 'ISOTONIC', Offset(cx, trackY - 16), 10,
        _kSafe.withValues(alpha: 0.9), weight: FontWeight.w800);
    GameFx.text(canvas, 'DRAG TO BALANCE THE CELL',
        Offset(size.width / 2, top + 22), 11,
        _kWhite.withValues(alpha: 0.7), weight: FontWeight.w700);
  }

  // ── First-run onboarding ghost hand sliding L↔R on the deck ──────────────────
  void _paintHint(Canvas canvas, Size size) {
    final top = size.height - _deckH;
    final trackY = top + _deckH - 56.0;
    final left = _deckPad;
    final w = size.width - _deckPad * 2;
    final cx = left + w / 2;
    final sway = math.sin(hintPhase * 1.6) * (w * 0.32);
    final hx = cx + sway;
    final hy = trackY + _trackH / 2;
    final a = 0.45 + 0.35 * (0.5 + 0.5 * math.sin(hintPhase * 3));
    // A simple finger: a rounded rect pointing up to the knob.
    canvas.drawCircle(Offset(hx, hy + 30), 9,
        Paint()..color = _kWhite.withValues(alpha: a));
    final stem = RRect.fromRectAndRadius(
        Rect.fromLTWH(hx - 4, hy + 6, 8, 28), const Radius.circular(4));
    canvas.drawRRect(stem, Paint()..color = _kWhite.withValues(alpha: a));
    // Pulse on the knob target.
    canvas.drawCircle(Offset(hx, hy), 22 + 4 * math.sin(hintPhase * 4),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _kWhite.withValues(alpha: a * 0.8));
  }

  // ── Score multiplier chip (legible, capped) ─────────────────────────────────
  void _paintScoreChip(Canvas canvas, Size size) {
    final mTxt = '×${mult.toStringAsFixed(1)}';
    final col = inBand ? _kSafe : _kWhite.withValues(alpha: 0.5);
    GameFx.text(canvas, mTxt, Offset(size.width - 40, 26), 18, col,
        display: true, glow: inBand ? 0.6 : 0);
    if (healthyStreak > 0) {
      GameFx.text(canvas, 'HEALTHY ${healthyStreak}s',
          Offset(size.width - 52, 46), 9, _kWhite.withValues(alpha: 0.55));
    }
    if (recoveries > 0) {
      GameFx.text(canvas, 'SAVES $recoveries', Offset(48, 26), 10,
          _kSafe.withValues(alpha: 0.7), weight: FontWeight.w700);
    }
  }

  // ── Final-surge climax: alarm vignette + banner ─────────────────────────────
  void _paintSurge(Canvas canvas, Size size) {
    final pulse = 0.18 + 0.12 * (0.5 + 0.5 * math.sin(surgePulse));
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            _kRed.withValues(alpha: pulse),
          ],
          stops: const [0.62, 1.0],
        ).createShader(rect),
    );
    GameFx.text(canvas, 'FINAL SURGE  ×2',
        Offset(size.width / 2, 30), 18,
        _kRed, display: true, glow: 0.7 + 0.3 * (0.5 + 0.5 * math.sin(surgePulse)));
  }

  void _paintEvent(Canvas canvas, Size size, double sceneH) {
    if (eventAlpha <= 0.01 || eventLabel.isEmpty) return;
    GameFx.text(
      canvas,
      eventLabel,
      Offset(size.width / 2, sceneH * 0.18),
      22,
      eventColor.withValues(alpha: eventAlpha),
      display: true,
      glow: 0.8 * eventAlpha,
    );
  }

  void _paintPops(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    for (final p in pops) {
      p.paint(canvas);
    }
    canvas.restore();
  }

  void _paintFlash(Canvas canvas, Size size) {
    if (healFlash > 0.3) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kSafe.withValues(alpha: (healFlash - 0.3) * 0.32));
    }
    if (burstFlash > 0.3) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kRed.withValues(alpha: (burstFlash - 0.3) * 0.40));
    }
  }

  @override
  bool shouldRepaint(covariant _OsmosisV2Painter old) => true;
}
