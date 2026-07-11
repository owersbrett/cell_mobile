import 'dart:math' as math;

import 'package:cell_mobile/party/party_actions.dart';
import 'package:cell_mobile/party/party_controller.dart';
import 'package:cell_mobile/party/party_models.dart';
import 'package:cell_mobile/party/screens/party_dialogue.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:flutter/material.dart';

/// The wheel (PARTY_CINEMATIC_SPEC §2). Spinners take the wheel in queue
/// order. STOP is a SKILL input: the segment under the pointer at the press
/// is the outcome (carried through the lockstep log), and the wheel visibly
/// decelerates forward onto it — read the wheel, time the press, get the
/// prize. After it settles, Butter explains what the prize does and the
/// player drives the game forward with CONTINUE; nothing auto-advances.
/// On the opening spin of round 1 the ceremony plays over the top first:
/// a rules board that holds ALL the information, while the characters the
/// players actually picked banter across it.
///
/// All animation here is presentation: rotation is a pure function of local
/// tickers; the landed segment comes from the shared controller state.
class WheelScreen extends StatefulWidget {
  final PartyController controller;
  final PartyActions actions;

  /// Seat this device owns online (-1 = local pass-and-play: every seat).
  final int mySlot;
  final bool isOnline;

  /// OUTRO mode: the session already ended (last stop landed, phase moved on)
  /// but the final payoff still deserves its moment. Renders the landed
  /// result for [lastWheelResult.seq] == [outroSeq], then calls [onOutroDone].
  final int? outroSeq;
  final VoidCallback? onOutroDone;

  const WheelScreen({
    super.key,
    required this.controller,
    required this.actions,
    this.mySlot = -1,
    this.isOnline = false,
    this.outroSeq,
    this.onOutroDone,
  });

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen>
    with TickerProviderStateMixin {
  /// Free-spin rotation while waiting for the STOP.
  late final AnimationController _spin;

  /// Deceleration + result-card hold after a landed stop.
  late final AnimationController _landing;

  int _seenSeq = 0;
  WheelResult? _landingResult; // the spin being paid off right now
  WheelResult? _pendingResult; // landed while the previous payoff was held
  double _spinAngleAtStop = 0;
  double _landingTargetAngle = 0;
  bool _ceremonyDismissed = false;
  int _ceremonyPage = 0;

  PartyController get c => widget.controller;

  bool get _isOutro => widget.outroSeq != null;

  static const double _kTwoPi = 2 * math.pi;

  @override
  void initState() {
    super.initState();
    _seenSeq = c.lastWheelResult?.seq ?? 0;
    // One revolution per cycle — slow enough that the labels are readable
    // in flight. Reading the wheel is the whole skill.
    _spin = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400));
    // Pure deceleration; the result then HOLDS until the player continues.
    _landing = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1700))
      ..addStatusListener((s) {
        if (s != AnimationStatus.completed || !mounted) return;
        // Park the free-spin phase where the landing ended so any resume
        // continues seamlessly, then reveal the host explanation.
        _spin.value = (_landingTargetAngle % _kTwoPi) / _kTwoPi;
        setState(() {});
      });
    if (_isOutro) {
      // Pay off the already-landed final stop, then hand back to the board.
      final r = c.lastWheelResult;
      _landingResult = r;
      _spinAngleAtStop = 0;
      if (r != null) {
        _landingTargetAngle =
            _landingTarget(wheelTableFor(r.tier), r.segmentIndex);
      }
      _landing.forward(from: 0);
    } else {
      _spin.repeat();
      c.addListener(_onController);
    }
  }

  @override
  void dispose() {
    if (!_isOutro) c.removeListener(_onController);
    _spin.dispose();
    _landing.dispose();
    super.dispose();
  }

  void _onController() {
    final r = c.lastWheelResult;
    if (r != null && r.seq != _seenSeq && mounted) {
      _seenSeq = r.seq;
      if (_landingResult != null) {
        // Still holding the previous payoff — queue this one behind it.
        _pendingResult = r;
        return;
      }
      _beginLanding(r);
    }
  }

  void _beginLanding(WheelResult r) {
    setState(() {
      _landingResult = r;
      _spinAngleAtStop = _spin.value * _kTwoPi;
      _landingTargetAngle =
          _landingTarget(wheelTableFor(r.tier), r.segmentIndex);
    });
    _spin.stop();
    _landing.forward(from: 0);
  }

  /// The player closes the payoff — the ONLY way past a landed result.
  void _continueAfterResult() {
    if (_landingResult == null || _landing.isAnimating) return;
    if (_isOutro) {
      widget.onOutroDone?.call();
      return;
    }
    final pending = _pendingResult;
    setState(() {
      _landingResult = null;
      _pendingResult = null;
    });
    if (pending != null) {
      _beginLanding(pending);
    } else if (c.wheel != null) {
      _spin.repeat();
    }
  }

  bool get _canStop {
    final w = c.wheel;
    if (w == null) return false;
    if (_landingResult != null) return false;
    if (!widget.isOnline) return true; // pass-and-play: the phone is the seat
    return widget.mySlot == w.currentSpinner;
  }

  /// The segment under the pointer (3 o'clock) at wheel rotation [angle] —
  /// what the spinner is looking at the instant they press STOP.
  int _segmentUnderPointer(List<WheelSegment> table, double angle) {
    var total = 0;
    for (final s in table) {
      total += s.weight;
    }
    var f = (-angle / _kTwoPi) % 1.0;
    if (f < 0) f += 1.0;
    var w = f * total;
    for (var i = 0; i < table.length; i++) {
      w -= table[i].weight;
      if (w < 0) return i;
    }
    return table.length - 1;
  }

  void _onStopPressed() {
    if (!_canStop) return;
    final w = c.wheel;
    if (w == null) return;
    final table = wheelTableFor(w.tier);
    widget.actions
        .wheelStop(_segmentUnderPointer(table, _spin.value * _kTwoPi));
  }

  /// First forward angle ≥ ~0.9 revolutions past the press that centers
  /// [idx] under the pointer — the wheel never reverses, it just runs out
  /// of steam and comes back around onto what the spinner called.
  double _landingTarget(List<WheelSegment> table, int idx) {
    var target = _targetAngle(table, idx) % _kTwoPi;
    if (target < 0) target += _kTwoPi;
    while (target < _spinAngleAtStop + _kTwoPi * 0.9) {
      target += _kTwoPi;
    }
    return target;
  }

  /// Angle that centers [segmentIndex] under the pointer, given weights.
  double _targetAngle(List<WheelSegment> table, int segmentIndex) {
    var total = 0;
    for (final s in table) {
      total += s.weight;
    }
    var before = 0;
    for (var i = 0; i < segmentIndex; i++) {
      before += table[i].weight;
    }
    final center =
        (before + table[segmentIndex].weight / 2) / total * 2 * math.pi;
    // Painter draws segment 0 starting at the pointer (3 o'clock), clockwise;
    // rotating the wheel by −center puts the segment's middle under it.
    return -center;
  }

  @override
  Widget build(BuildContext context) {
    final w = c.wheel;
    final showCeremony = !_ceremonyDismissed &&
        (w?.tier == WheelTier.opening) &&
        c.round == 1;

    // During the landing payoff the session may already have advanced (or
    // ended); render the landed spin's own tier/spinner.
    final r = _landingResult;
    final tier = r?.tier ?? w?.tier;
    final spinnerSeat = r?.spinner ?? w?.currentSpinner;
    if (tier == null || spinnerSeat == null) {
      return const Scaffold(backgroundColor: Colors.black, body: SizedBox());
    }
    final spinner = c.players[spinnerSeat];
    final table = wheelTableFor(tier);

    // A settled result waits for the PLAYER — tapping anywhere continues.
    final settled = r != null && !_landing.isAnimating;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: settled ? _continueAfterResult : null,
        child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 14),
                Text(
                  tier.title,
                  textAlign: TextAlign.center,
                  style: Potatuhs.body(size: 13, color: Potatuhs.textSecondary)
                      .copyWith(letterSpacing: 3),
                ),
                const SizedBox(height: 6),
                Text(
                  r != null
                      ? '${spinner.name.toUpperCase()} LANDED…'
                      : "${spinner.name.toUpperCase()}'S SPIN",
                  textAlign: TextAlign.center,
                  style: Potatuhs.display(size: 24, color: spinner.color),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_spin, _landing]),
                    builder: (context, _) {
                      double angle;
                      if (r != null) {
                        // Friction, not physics-reversal: the wheel keeps
                        // its direction and eases forward onto the segment
                        // the spinner called at the press.
                        final t =
                            Curves.easeOutCubic.transform(_landing.value);
                        angle = _spinAngleAtStop +
                            (_landingTargetAngle - _spinAngleAtStop) * t;
                      } else {
                        angle = _spin.value * _kTwoPi;
                      }
                      return CustomPaint(
                        painter: _WheelPainter(
                          table: table,
                          angle: angle,
                          accent: spinner.color,
                          highlight: r != null && _landing.value > 0.8
                              ? r.segmentIndex
                              : null,
                        ),
                        child: const SizedBox.expand(),
                      );
                    },
                  ),
                ),
                if (settled)
                  // The wheel has settled: the host explains what the prize
                  // actually does, and the PLAYER moves the game forward.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          r.summary,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: Potatuhs.body(size: 15, color: Potatuhs.gold)
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        DialogueStrip(
                          beat: wheelHostBeatFor(
                              table[r.segmentIndex], r.item),
                        ),
                        const SizedBox(height: 14),
                        _bigButton('CONTINUE', enabled: true,
                            onTap: _continueAfterResult),
                      ],
                    ),
                  )
                else ...[
                  SizedBox(
                    height: 64,
                    child: Center(
                      child: r != null
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                r.summary,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: Potatuhs.body(
                                        size: 15, color: Potatuhs.gold)
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                            )
                          : Text(
                              _canStop
                                  ? 'Read the wheel — STOP it on the prize '
                                      'you want'
                                  : 'Waiting for ${spinner.name}…',
                              textAlign: TextAlign.center,
                              style: Potatuhs.body(
                                  size: 14, color: Potatuhs.textSecondary),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: _bigButton('SPIN',
                        enabled: _canStop, onTap: _onStopPressed),
                  ),
                ],
              ],
            ),
            if (showCeremony) _openingCeremony(context),
          ],
        ),
        ),
      ),
    );
  }

  /// The gold action button (STOP / CONTINUE) — one shape, one weight.
  Widget _bigButton(String label,
      {required bool enabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : 0.25,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: enabled ? Potatuhs.gold : Potatuhs.gold.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(18),
            boxShadow: enabled
                ? [
                    BoxShadow(
                        color: Potatuhs.gold.withValues(alpha: 0.45),
                        blurRadius: 20)
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: Potatuhs.body(size: 20, color: Colors.black)
                  .copyWith(fontWeight: FontWeight.w900, letterSpacing: 6),
            ),
          ),
        ),
      ),
    );
  }

  // ── The opening ceremony (SPEC §1): the BOARD holds the rules, the ──────
  // characters the players picked banter across it. Butter MCs — smooth,
  // never hedging; "uhhh…" belongs to Russ alone.

  static const _kRuleRows = <(IconData, String, String)>[
    (
      Icons.emoji_events,
      'WIN',
      'Most POTATOES wins. Buy them with diamonds at the DESTINATION — '
          'and you eat every diamond you walk over.',
    ),
    (
      Icons.casino,
      'ROUNDS',
      'Everyone rolls & moves, then a MINI-GAME fires. The region you '
          'land in picks its flavor — steer toward games you like.',
    ),
    (
      Icons.track_changes,
      'THE WHEEL',
      'Hands out ITEMS now, returns every 4 rounds, pays potatoes at the '
          'end. STOP it on the prize you want — timing is real.',
    ),
  ];

  Widget _rulesBoard(String mapSub) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Potatuhs.inkPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Potatuhs.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mapSub.toUpperCase(),
            style: Potatuhs.body(size: 10, color: Potatuhs.textSecondary)
                .copyWith(letterSpacing: 3),
          ),
          for (final (icon, label, text) in _kRuleRows) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: Potatuhs.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: Potatuhs.body(
                          size: 13, color: Potatuhs.textPrimary),
                      children: [
                        TextSpan(
                          text: '$label — ',
                          style: Potatuhs.body(size: 13, color: Potatuhs.gold)
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: text),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _openingCeremony(BuildContext context) {
    final map = c.gameMap;
    final mapName = map?.name.toUpperCase() ?? 'THE BOARD';
    final mapSub = map?.subtitle ?? 'a journey through the scales';
    final beats = openingBanterFor(c.players, mapName);
    final page = _ceremonyPage.clamp(0, beats.length - 1);
    final last = page == beats.length - 1;
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          if (last) {
            _ceremonyDismissed = true;
          } else {
            _ceremonyPage++;
          }
        }),
        child: Container(
          color: Colors.black.withValues(alpha: 0.92),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'WELCOME TO $mapName',
                textAlign: TextAlign.center,
                style: Potatuhs.display(size: 24, color: Potatuhs.gold),
              ),
              const SizedBox(height: 14),
              // The board: every rule, visible the whole time. Characters
              // talk OVER it — they never have to carry the information.
              _rulesBoard(mapSub),
              const SizedBox(height: 16),
              DialogueStrip(beat: beats[page]),
              const SizedBox(height: 18),
              Text(
                last
                    ? 'TAP TO SPIN  ·  ${page + 1}/${beats.length}'
                    : 'TAP TO CONTINUE  ·  ${page + 1}/${beats.length}',
                textAlign: TextAlign.center,
                style:
                    Potatuhs.body(size: 12, color: Potatuhs.textSecondary),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _ceremonyDismissed = true),
                child: Text(
                  'SKIP',
                  textAlign: TextAlign.center,
                  style: Potatuhs.body(size: 12, color: Potatuhs.textSecondary)
                      .copyWith(decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints the wheel face: weighted segments starting at the pointer,
/// clockwise, labels laid radially. Pure function of (table, angle).
///
/// The pointer sits at 3 O'CLOCK (not the top) ON PURPOSE: labels run
/// radially outward, so a segment under a side pointer reads HORIZONTALLY —
/// the landed prize is legible at the payoff on every spin. A top pointer
/// left the winning label vertical (Brett, 2026-07-08).
class _WheelPainter extends CustomPainter {
  final List<WheelSegment> table;
  final double angle;
  final Color accent;
  final int? highlight;
  _WheelPainter({
    required this.table,
    required this.angle,
    required this.accent,
    this.highlight,
  });

  static const _fills = [
    Color(0xFF2A2438),
    Color(0xFF1D2B3A),
    Color(0xFF33241E),
    Color(0xFF1F3227),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(10.0, math.min(size.width, size.height) / 2 - 18);
    var totalWeight = 0;
    for (final s in table) {
      totalWeight += s.weight;
    }

    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.black;

    var startWeight = 0;
    for (var i = 0; i < table.length; i++) {
      final seg = table[i];
      // Segment 0 starts at 0 rad = 3 o'clock, where the pointer sits.
      final a0 = angle + startWeight / totalWeight * 2 * math.pi;
      final sweep = seg.weight / totalWeight * 2 * math.pi;
      paint.color = i == highlight
          ? accent.withValues(alpha: 0.85)
          : _fills[i % _fills.length];
      canvas.drawArc(rect, a0, sweep, true, paint);
      canvas.drawArc(rect, a0, sweep, true, stroke);

      // Radial label along the segment's centerline.
      final mid = a0 + sweep / 2;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(mid);
      final tp = TextPainter(
        text: TextSpan(
          text: seg.label,
          style: TextStyle(
            fontFamily: Potatuhs.bodyFont,
            fontSize: radius * 0.072,
            fontWeight: FontWeight.bold,
            color: i == highlight ? Colors.black : Colors.white70,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: radius * 0.62);
      tp.paint(canvas, Offset(radius * 0.30, -tp.height / 2));
      canvas.restore();
      startWeight += seg.weight;
    }

    // Hub.
    paint.color = Potatuhs.ink;
    canvas.drawCircle(center, radius * 0.14, paint);
    stroke.color = accent;
    canvas.drawCircle(center, radius * 0.14, stroke);

    // Rim glow.
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = accent.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, radius, rim);

    // Side pointer (3 o'clock), aiming inward — the segment it marks reads
    // horizontally.
    final pointer = Path()
      ..moveTo(center.dx + radius + 10, center.dy - 12)
      ..lineTo(center.dx + radius + 10, center.dy + 12)
      ..lineTo(center.dx + radius - 14, center.dy)
      ..close();
    paint.color = Potatuhs.gold;
    canvas.drawPath(pointer, paint);
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.angle != angle ||
      old.table != table ||
      old.highlight != highlight ||
      old.accent != accent;
}
