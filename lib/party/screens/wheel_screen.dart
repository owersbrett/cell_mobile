import 'dart:math' as math;

import 'package:cell_mobile/party/party_actions.dart';
import 'package:cell_mobile/party/party_controller.dart';
import 'package:cell_mobile/party/party_models.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:flutter/material.dart';

/// The wheel (PARTY_CINEMATIC_SPEC §2). Spinners take the wheel in queue
/// order; the wheel spins live until the spinner hits STOP (a real lockstep
/// input), then decelerates onto the tape-drawn segment before the next
/// spinner takes over. On the opening spin of round 1 the Butter-MC'd opening
/// ceremony plays over the top first.
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
  double _spinAngleAtStop = 0;
  bool _ceremonyDismissed = false;
  int _ceremonyPage = 0;

  PartyController get c => widget.controller;

  bool get _isOutro => widget.outroSeq != null;

  @override
  void initState() {
    super.initState();
    _seenSeq = c.lastWheelResult?.seq ?? 0;
    _spin = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _landing = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2100))
      ..addStatusListener((s) {
        if (s != AnimationStatus.completed || !mounted) return;
        if (_isOutro) {
          widget.onOutroDone?.call();
        } else {
          setState(() => _landingResult = null);
          _spin.repeat();
        }
      });
    if (_isOutro) {
      // Pay off the already-landed final stop, then hand back to the board.
      _landingResult = c.lastWheelResult;
      _spinAngleAtStop = 0;
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
      // A stop landed: pay it off with a deceleration before moving on.
      _seenSeq = r.seq;
      setState(() {
        _landingResult = r;
        _spinAngleAtStop = _spin.value * 2 * math.pi;
      });
      _spin.stop();
      _landing.forward(from: 0);
    }
  }

  bool get _canStop {
    final w = c.wheel;
    if (w == null) return false;
    if (_landingResult != null) return false;
    if (!widget.isOnline) return true; // pass-and-play: the phone is the seat
    return widget.mySlot == w.currentSpinner;
  }

  /// Angle that centers [segmentIndex] under the top pointer, given weights.
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
    // Painter draws segment 0 starting at the top, clockwise; rotating the
    // wheel by −center puts the segment's middle under the pointer.
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _isOutro ? widget.onOutroDone : null,
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
                        final t =
                            Curves.easeOutCubic.transform(_landing.value);
                        // Two extra revolutions, easing onto the target.
                        final target = _targetAngle(table, r.segmentIndex) -
                            4 * math.pi;
                        angle = _spinAngleAtStop +
                            (target - _spinAngleAtStop) * t;
                      } else {
                        angle = _spin.value * 2 * math.pi;
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
                                ? 'Hit STOP to claim your fate'
                                : 'Waiting for ${spinner.name}…',
                            style: Potatuhs.body(
                                size: 14, color: Potatuhs.textSecondary),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: GestureDetector(
                    onTap: _canStop ? widget.actions.wheelStop : null,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _canStop ? 1 : 0.25,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: _canStop
                              ? Potatuhs.gold
                              : Potatuhs.gold.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: _canStop
                              ? [
                                  BoxShadow(
                                      color: Potatuhs.gold
                                          .withValues(alpha: 0.45),
                                      blurRadius: 20)
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'STOP',
                            style: Potatuhs.body(size: 20, color: Colors.black)
                                .copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (showCeremony) _openingCeremony(context),
          ],
        ),
        ),
      ),
    );
  }

  // ── The opening ceremony: Butter MCs the rules (SPEC §1) ────────────────

  static const _kButter = 'Butter';

  List<(String, String)> get _ceremonyBeats {
    final map = c.gameMap;
    final mapName = map?.name.toUpperCase() ?? 'THE BOARD';
    final mapSub = map?.subtitle ?? 'a journey through the scales';
    return [
      (
        'WELCOME TO $mapName',
        "I'm Butter. You're here, we're here — $mapSub. "
            "We've always been here. Let's play.",
      ),
      (
        'HOW YOU WIN',
        'Most POTATOES at the end wins. Buy them with diamonds at the '
            'DESTINATION — the glowing anchor at the end of the path. '
            'Diamonds? You eat every one you walk over. Take the long way.',
      ),
      (
        'HOW A ROUND WORKS',
        'Everyone rolls and moves. When the whole table has moved, a '
            'MINI-GAME fires — and the region you land in picks its flavor. '
            'Steer toward the scales whose games you like. Tip the odds.',
      ),
      (
        'THE WHEEL',
        "uhhh… one more thing. The wheel. Everyone spins it now — it hands "
            'out ITEMS. It comes back every four rounds, and one final time '
            'at the end, when it pays out potatoes. Hit STOP when it feels '
            'right. It always feels right.',
      ),
    ];
  }

  Widget _openingCeremony(BuildContext context) {
    final beats = _ceremonyBeats;
    final page = _ceremonyPage.clamp(0, beats.length - 1);
    final (title, line) = beats[page];
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
          color: Colors.black.withValues(alpha: 0.88),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: Potatuhs.display(size: 26, color: Potatuhs.gold),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Potatuhs.inkPanel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Potatuhs.gold.withValues(alpha: 0.35)),
                ),
                child: Column(
                  children: [
                    Text(
                      _kButter.toUpperCase(),
                      style: Potatuhs.body(size: 11, color: Potatuhs.gold)
                          .copyWith(letterSpacing: 3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      line,
                      textAlign: TextAlign.center,
                      style: Potatuhs.body(
                          size: 15, color: Potatuhs.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
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

/// Paints the wheel face: weighted segments starting at the top pointer,
/// clockwise, labels laid radially. Pure function of (table, angle).
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
      final a0 = angle - math.pi / 2 + startWeight / totalWeight * 2 * math.pi;
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

    // Top pointer.
    final pointer = Path()
      ..moveTo(center.dx - 12, center.dy - radius - 10)
      ..lineTo(center.dx + 12, center.dy - radius - 10)
      ..lineTo(center.dx, center.dy - radius + 14)
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
