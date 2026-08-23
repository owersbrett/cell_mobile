import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/potatuhs.dart';
import '../party_models.dart';
import 'madness_net.dart';

/// THE HOT POTATO TIEBREAKER (Brett 2026-07-17) — the dead-heat final,
/// settled in real time. The tied players sit in a ring; one potato with a
/// burning fuse hops between them. Three abilities: pass LEFT, pass RIGHT
/// (1s cooldown each), and an armed SKIP that lets the potato pass THROUGH
/// you (cooldown: alive players × 5s; the arm tell is hidden when the potato
/// is within 3 passes). Out three ways: the fuse blows in your hands, you
/// hold it past the 3s shot clock, or you press pass without the potato —
/// the itchy-trigger rule (a ~150ms grace after it leaves absolves lag).
/// Fuses shorten per potato: 60 → 45 → 30 → 15 and stay at 15.
///
/// All refereeing is host-side (madness_net); this view renders the shared
/// state and reports my inputs. My own actions render optimistically only in
/// button state — the potato itself always follows meta, so every screen
/// agrees on where it is.
class MadnessTiebreakView extends StatefulWidget {
  final MadnessNet net;
  const MadnessTiebreakView({super.key, required this.net});

  @override
  State<MadnessTiebreakView> createState() => _MadnessTiebreakViewState();
}

class _MadnessTiebreakViewState extends State<MadnessTiebreakView> {
  static const int _kPassCdMs = 1000;
  static const int _kGraceMs = 150;

  MadnessNet get net => widget.net;

  Timer? _clock;
  final Map<String, int> _passCdUntil = {'left': 0, 'right': 0};

  /// When the potato last left my hands — the itchy-trigger grace window.
  int _lostAt = 0;
  bool _wasHolder = false;

  /// Set the instant I self-report a false tap, so the OUT reads immediately
  /// even before the host confirms.
  bool _selfOut = false;

  int get _now => DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    net.addListener(_onNet);
    _wasHolder = net.amTbHolder;
    // The fuse, shot clock and cooldowns are all wall-clock renders.
    _clock = Timer.periodic(
        const Duration(milliseconds: 100), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _clock?.cancel();
    net.removeListener(_onNet);
    super.dispose();
  }

  void _onNet() {
    if (!mounted) return;
    final holding = net.amTbHolder;
    if (_wasHolder && !holding) _lostAt = _now;
    _wasHolder = holding;
    setState(() {});
  }

  // ── input ──────────────────────────────────────────────────────────────────

  void _pressPass(String dir) {
    if (_selfOut || !net.amTbAlive || net.tbWinner.isNotEmpty) return;
    final now = _now;
    if (net.amTbHolder) {
      if (now < (_passCdUntil[dir] ?? 0)) return; // direction on cooldown
      _passCdUntil[dir] = now + _kPassCdMs;
      net.sendTbPass(dir);
      return;
    }
    // No potato: inside the grace window right after it left, forgive lag.
    if (now - _lostAt <= _kGraceMs) return;
    setState(() => _selfOut = true);
    net.sendTbOut();
  }

  void _pressSkip() {
    if (_selfOut || !net.amTbAlive || net.amTbHolder) return;
    if (net.tbSkipArmed.containsKey(net.myUid)) return;
    if (_now < (net.tbSkipCooldownUntil[net.myUid] ?? 0)) return;
    net.sendTbSkip();
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ring = net.tbPlayers;
    if (ring.isEmpty) return const SizedBox.shrink();
    final fuseLeft =
        ((net.tbFuseEndAt - _now) / 1000).clamp(0.0, double.infinity);
    final urgent = fuseLeft <= 5;

    return Column(
      children: [
        const SizedBox(height: 10),
        Text('HOT POTATO — TIEBREAKER',
            textAlign: TextAlign.center,
            style: Potatuhs.display(size: 22, color: Potatuhs.orange)),
        const SizedBox(height: 2),
        Text(
          'POTATO #${net.tbRound} · last one standing takes the crown',
          textAlign: TextAlign.center,
          style: Potatuhs.body(size: 12, color: Potatuhs.textSecondary),
        ),
        const SizedBox(height: 6),
        // The fuse — the one number everyone watches.
        Text(
          fuseLeft >= 10
              ? fuseLeft.floor().toString()
              : fuseLeft.toStringAsFixed(1),
          textAlign: TextAlign.center,
          style: Potatuhs.display(
              size: 40,
              color: urgent ? const Color(0xFFE5484D) : Potatuhs.gold),
        ),
        Expanded(child: LayoutBuilder(builder: _buildRing)),
        _buildStatusLine(),
        const SizedBox(height: 8),
        _buildControls(),
        const SizedBox(height: 14),
      ],
    );
  }

  Alignment _seatAlign(int seat, int n) {
    final a = -math.pi / 2 + 2 * math.pi * seat / n;
    return Alignment(math.cos(a) * 0.82, math.sin(a) * 0.82);
  }

  Widget _buildRing(BuildContext context, BoxConstraints box) {
    final ring = net.tbPlayers;
    final n = ring.length;
    final holder = net.tbHolder;
    final holdFrac =
        ((_now - net.tbHoldStartAt) / 3000).clamp(0.0, 1.0).toDouble();

    return Stack(
      children: [
        for (var i = 0; i < n; i++)
          Align(
            alignment: _seatAlign(i, n),
            child: _seat(ring[i], isHolder: ring[i] == holder,
                holdFrac: holdFrac),
          ),
        // The potato rides meta — every screen agrees where it is.
        AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: holder.isEmpty
              ? Alignment.center
              : _seatAlign(ring.indexOf(holder).clamp(0, n - 1), n),
          child: IgnorePointer(
            child: Transform.translate(
              offset: const Offset(0, -44),
              child: Text('🥔',
                  style: TextStyle(fontSize: 30, shadows: [
                    Shadow(
                        color: Potatuhs.orange.withValues(alpha: 0.9),
                        blurRadius: 16),
                  ])),
            ),
          ),
        ),
      ],
    );
  }

  Widget _seat(String uid, {required bool isHolder, required double holdFrac}) {
    final p = net.playerByUid(uid);
    final alive = net.tbAlive.contains(uid);
    final ch = kCharacters[(p?.character ?? 0) % kCharacters.length];
    // The arm tell — my own always shows to me; others only when the arm was
    // made with the potato more than 3 passes away (the stealth rule).
    final armedEntry = net.tbSkipArmed[uid];
    final showTell =
        armedEntry != null && (uid == net.myUid || armedEntry == true);

    return Opacity(
      opacity: alive ? 1 : 0.35,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (isHolder && alive)
                SizedBox(
                  width: 58,
                  height: 58,
                  child: CustomPaint(
                      painter: _ShotClockPainter(frac: holdFrac)),
                ),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Potatuhs.inkPanel,
                  border: Border.all(
                      color: isHolder && alive
                          ? Potatuhs.orange
                          : Color(p?.color ?? 0xFF888888)
                              .withValues(alpha: 0.9),
                      width: isHolder && alive ? 2.5 : 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: ch.asset != null
                    ? Image.asset(ch.asset!, fit: BoxFit.cover)
                    : Center(
                        child: Text(ch.name[0],
                            style: Potatuhs.display(
                                size: 18, color: ch.color))),
              ),
              if (!alive)
                const Text('💥', style: TextStyle(fontSize: 22)),
              if (showTell)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Icon(Icons.shield_rounded,
                      size: 16,
                      color: Potatuhs.airForce.withValues(alpha: 0.95)),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            p?.name ?? '—',
            style: Potatuhs.body(
                    size: 10,
                    color: uid == net.myUid
                        ? Potatuhs.gold
                        : Potatuhs.textSecondary)
                .copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLine() {
    final String line;
    final Color color;
    if (_selfOut || !net.amTbAlive && net.tbPlayers.contains(net.myUid)) {
      line = "YOU'RE OUT — watch it burn";
      color = const Color(0xFFE5484D);
    } else if (!net.tbPlayers.contains(net.myUid)) {
      line = 'Not your tie — enjoy the show';
      color = Potatuhs.textFaint;
    } else if (net.amTbHolder) {
      line = 'YOU HAVE IT — pass within 3 seconds';
      color = Potatuhs.orange;
    } else if (net.tbSkipArmed.containsKey(net.myUid)) {
      line = 'Skip ARMED — the next potato passes through you';
      color = Potatuhs.airForce;
    } else {
      line = 'Careful: pressing pass without the potato puts you out';
      color = Potatuhs.textSecondary;
    }
    return Text(line,
        textAlign: TextAlign.center,
        style:
            Potatuhs.body(size: 12, color: color).copyWith(letterSpacing: 0.4));
  }

  Widget _buildControls() {
    final inRing = net.tbPlayers.contains(net.myUid);
    if (!inRing || !net.amTbAlive || _selfOut) {
      return const SizedBox(height: 56);
    }
    final now = _now;
    final skipArmed = net.tbSkipArmed.containsKey(net.myUid);
    final skipCdLeft =
        (((net.tbSkipCooldownUntil[net.myUid] ?? 0) - now) / 1000)
            .clamp(0.0, double.infinity);
    final skipReady = !skipArmed && skipCdLeft <= 0 && !net.amTbHolder;

    Widget btn(String label, VoidCallback onTap,
        {bool lit = true, Color fill = Potatuhs.gold}) {
      return Expanded(
        child: GestureDetector(
          // Tap-down, not tap-up: a hot potato answers the finger instantly.
          onTapDown: (_) => onTap(),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 120),
            opacity: lit ? 1 : 0.35,
            child: Container(
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Potatuhs.ink, width: 2),
                boxShadow: const [
                  BoxShadow(color: Potatuhs.ink, offset: Offset(3, 3))
                ],
              ),
              child: Center(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: Potatuhs.body(size: 14, color: Potatuhs.ink)
                        .copyWith(
                            fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          btn('← PASS', () => _pressPass('left'),
              lit: !net.amTbHolder || now >= (_passCdUntil['left'] ?? 0)),
          btn(
            skipArmed
                ? 'ARMED'
                : skipCdLeft > 0
                    ? 'SKIP ${skipCdLeft.ceil()}s'
                    : 'SKIP',
            _pressSkip,
            lit: skipReady || skipArmed,
            fill: skipArmed ? Potatuhs.airForce : Potatuhs.sienna,
          ),
          btn('PASS →', () => _pressPass('right'),
              lit: !net.amTbHolder || now >= (_passCdUntil['right'] ?? 0)),
        ],
      ),
    );
  }
}

/// The 3-second shot clock — a depleting arc around the holder's portrait.
class _ShotClockPainter extends CustomPainter {
  final double frac; // 0 fresh → 1 out
  _ShotClockPainter({required this.frac});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final color = frac > 0.66 ? const Color(0xFFE5484D) : Potatuhs.orange;
    canvas.drawArc(
      rect.deflate(2),
      -math.pi / 2,
      2 * math.pi * (1 - frac),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ShotClockPainter old) => old.frac != frac;
}
