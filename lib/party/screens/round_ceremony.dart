import 'dart:async';
import 'dart:math' as math;

import 'package:cell_mobile/feedback/feedback_prompt.dart';
import 'package:cell_mobile/party/party_actions.dart';
import 'package:cell_mobile/party/party_controller.dart';
import 'package:cell_mobile/party/party_models.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:flutter/material.dart';

/// The post-mini-game ceremony (PARTY_CINEMATIC_SPEC §4) — every round ends
/// with a shared moment: staged podium reveal (last podium step first), a
/// declared WINNER with confetti, and the diamond awards, before the board
/// resumes. All clients see the same ceremony; only [interactive] devices can
/// advance it (locally: always; online: the host, who also auto-advances after
/// a dwell so a distracted host can't stall the room).
///
/// Presentation is a pure function of controller state + local reveal time —
/// zero random-tape draws, lockstep-safe.
class RoundCeremonyScreen extends StatefulWidget {
  final PartyController controller;
  final PartyActions actions;

  /// Whether this device may advance past the ceremony.
  final bool interactive;

  /// Online host: auto-confirm a few seconds after the reveal completes.
  final bool autoAdvance;

  /// Show the one-tap "did you like that game?" prompt once the reveal has
  /// played (PARTY_CINEMATIC_SPEC §7). Off in attract mode.
  final bool showFeedback;

  const RoundCeremonyScreen({
    super.key,
    required this.controller,
    required this.actions,
    required this.interactive,
    this.autoAdvance = false,
    this.showFeedback = true,
  });

  @override
  State<RoundCeremonyScreen> createState() => _RoundCeremonyScreenState();
}

class _RoundCeremonyScreenState extends State<RoundCeremonyScreen>
    with TickerProviderStateMixin {
  // Checkpoint 2026-07-10: the reveal starts sooner and runs tighter — the
  // first bars rise almost immediately instead of ~600ms of dead air.
  static const _revealDuration = Duration(milliseconds: 3000);
  static const _autoAdvanceDwell = Duration(seconds: 6);

  late final AnimationController _reveal;

  /// Drives confetti + winner-glow pulse; time source for the fx painter.
  late final AnimationController _fx;

  Timer? _autoTimer;
  bool _confirmed = false;

  /// Fx-clock ms at the moment the winner banner first appeared — confetti
  /// time zero, so the burst fires with the banner, not at screen open.
  int? _confettiT0;

  bool _feedbackDone = false;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(vsync: this, duration: _revealDuration)
      ..addStatusListener(_onRevealStatus)
      ..forward();
    _fx = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
  }

  void _onRevealStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (widget.autoAdvance && _autoTimer == null) {
      _autoTimer = Timer(_autoAdvanceDwell, () {
        if (mounted) _confirm();
      });
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _reveal.dispose();
    _fx.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_confirmed) return;
    _confirmed = true;
    widget.actions.confirmMiniGameResults();
  }

  /// Tap anywhere mid-reveal fast-forwards to the fully-revealed state.
  void _skipReveal() {
    if (_reveal.isAnimating) _reveal.value = 1.0;
  }

  // ── standings shape ────────────────────────────────────────────────────────

  List<MiniGameStanding> get _sorted {
    final s = [...widget.controller.standings];
    s.sort((a, b) {
      if (a.rank != b.rank) return a.rank.compareTo(b.rank);
      return b.score.compareTo(a.score);
    });
    return s;
  }

  List<MiniGameStanding> get _winners =>
      [for (final s in widget.controller.standings) if (s.rank == 0) s];

  String get _winnerLine {
    final c = widget.controller;
    final winners = _winners;
    if (c.mode.isTeams && winners.isNotEmpty) {
      return '${kTeamNames[winners.first.player.teamIndex].toUpperCase()} '
          'TAKE THE ROUND!';
    }
    if (winners.length > 1) {
      final names =
          winners.map((s) => s.player.name.toUpperCase()).join(' & ');
      return 'DEAD HEAT — $names!';
    }
    if (winners.isEmpty) return 'ROUND COMPLETE';
    return '${winners.first.player.name.toUpperCase()} TAKES THE ROUND!';
  }

  Color get _winnerColor {
    final winners = _winners;
    if (winners.isEmpty) return Potatuhs.gold;
    final c = widget.controller;
    return c.mode.isTeams
        ? kTeamColors[winners.first.player.teamIndex]
        : winners.first.player.color;
  }

  // ── intervals: when each element pops during the reveal ──────────────────

  static const _bannerInterval =
      Interval(0.62, 0.80, curve: Curves.easeOutBack);
  static const _footerInterval = Interval(0.80, 0.92, curve: Curves.easeOut);

  /// Boss-round stakes for a row: +1 potato to the top score, −1 to the
  /// bottom (mirrors _applyBossPotatoes so the swing is VISIBLE).
  int _bossDelta(MiniGameStanding s) {
    final c = widget.controller;
    if (!c.isBossRound || c.standings.isEmpty) return 0;
    var top = c.standings.first.score, bottom = c.standings.first.score;
    for (final x in c.standings) {
      if (x.score > top) top = x.score;
      if (x.score < bottom) bottom = x.score;
    }
    if (s.score == top) return 1;
    if (top != bottom && s.score == bottom) return -1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final spec = c.currentSpec!;
    final sorted = _sorted;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skipReveal,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _reveal,
            builder: (context, footer) {
              final t = _reveal.value;
              final fxMs = _fx.lastElapsedDuration?.inMilliseconds ?? 0;
              if (t >= _bannerInterval.begin) _confettiT0 ??= fxMs;
              return Stack(
                children: [
                  // Confetti fires with the winner banner.
                  if (_confettiT0 != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _fx,
                          builder: (_, __) => CustomPaint(
                            painter: _ConfettiPainter(
                              time: (_fx.lastElapsedDuration?.inMilliseconds ??
                                      0) -
                                  _confettiT0!,
                              colors: [
                                Potatuhs.gold,
                                _winnerColor,
                                for (final s in sorted.take(3))
                                  s.player.color,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 18),
                      _header(spec.name, c.round, c.totalRounds, t),
                      const SizedBox(height: 8),
                      _winnerBanner(t),
                      Expanded(child: _barChart(sorted, spec.scoreUnit, t)),
                      if (widget.showFeedback &&
                          !_feedbackDone &&
                          t >= _footerInterval.begin)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                          child: FeedbackPrompt(
                            gameId: spec.id,
                            gameName: spec.name,
                            source: 'party',
                            onDone: () =>
                                setState(() => _feedbackDone = true),
                          ),
                        ),
                      const SizedBox(height: 12),
                      footer!,
                      const SizedBox(height: 8),
                    ],
                  ),
                ],
              );
            },
            // Static subtree: the footer rebuilds only via its own Opacity.
            child: _footer(c),
          ),
        ),
      ),
    );
  }

  Widget _header(String gameName, int round, int totalRounds, double t) {
    final a = const Interval(0.0, 0.12, curve: Curves.easeOut).transform(t);
    final boss = widget.controller.isBossRound;
    return Opacity(
      opacity: a,
      child: Column(
        children: [
          if (boss)
            Text(
              '⚔ BOSS ROUND ⚔',
              textAlign: TextAlign.center,
              style: Potatuhs.body(size: 12, color: const Color(0xFFE5484D))
                  .copyWith(letterSpacing: 4, fontWeight: FontWeight.bold),
            ),
          Text(
            gameName.toUpperCase(),
            textAlign: TextAlign.center,
            style: Potatuhs.body(size: 13, color: Potatuhs.textSecondary)
                .copyWith(letterSpacing: 3),
          ),
          const SizedBox(height: 4),
          Text(
            'ROUND $round / $totalRounds',
            textAlign: TextAlign.center,
            style: Potatuhs.body(size: 12, color: Potatuhs.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _winnerBanner(double t) {
    final a = _bannerInterval.transform(t);
    if (a == 0) return const SizedBox(height: 52);
    final pulse = 1.0 + 0.03 * math.sin(_fx.value * 2 * math.pi * 3);
    return SizedBox(
      height: 52,
      child: Center(
        child: Transform.scale(
          scale: (0.6 + 0.4 * a) * pulse,
          child: Opacity(
            opacity: a.clamp(0.0, 1.0),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _winnerColor.withValues(alpha: 0.8), width: 2),
                boxShadow: Potatuhs.glow(_winnerColor, strength: 0.5, blur: 26),
                color: _winnerColor.withValues(alpha: 0.12),
              ),
              child: Text(
                _winnerLine,
                textAlign: TextAlign.center,
                style: Potatuhs.display(size: 20, color: Potatuhs.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The results as an animated BAR CHART (checkpoint 2026-07-10): EVERY
  /// player gets a bar, rank-ordered left → right, bars growing to their
  /// score (height ∝ score / best score) with a small stagger. The score
  /// counts up as the bar rises; the winner is crowned when the banner hits.
  Widget _barChart(List<MiniGameStanding> all, String scoreUnit, double t) {
    if (all.isEmpty) return const SizedBox.shrink();
    var maxScore = 0;
    for (final s in all) {
      if (s.score > maxScore) maxScore = s.score;
    }
    final top = maxScore <= 0 ? 1 : maxScore;
    return LayoutBuilder(
      builder: (context, box) {
        // Room above the bars for crown + portrait + name + score.
        final barMax = math.max(60.0, box.maxHeight - 132);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < all.length; i++)
                Expanded(
                    child: _bar(
                        all[i], i, all.length, barMax, top, scoreUnit, t)),
            ],
          ),
        );
      },
    );
  }

  Widget _bar(MiniGameStanding s, int i, int n, double barMax, int top,
      String scoreUnit, double t) {
    // Stagger by rank; compress the step when the field is large so the last
    // bar still lands before the winner banner.
    final step = n <= 5 ? 0.08 : 0.40 / n;
    final a = Interval(0.04 + step * i,
            (0.34 + step * i).clamp(0.0, 1.0), curve: Curves.easeOutCubic)
        .transform(t);
    if (a == 0) return const SizedBox.shrink();
    final isWinner = s.rank == 0;
    final color = s.player.color;
    final ringColor = isWinner ? Potatuhs.gold : color;
    final crowned = isWinner && t >= _bannerInterval.begin;
    final h = math.max(14.0, barMax * (s.score / top) * a);
    final shown = (s.score * a).round();
    return Opacity(
      opacity: a.clamp(0.0, 1.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (crowned)
            const Icon(Icons.emoji_events, color: Potatuhs.gold, size: 26),
          const SizedBox(height: 2),
          _portrait(s.player, size: isWinner ? 50 : 40, ring: ringColor),
          const SizedBox(height: 4),
          Text(
            s.player.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Potatuhs.body(size: 11.5, color: Potatuhs.textPrimary)
                .copyWith(fontWeight: FontWeight.bold),
          ),
          if (widget.controller.mode.isTeams)
            Text(
              kTeamNames[s.player.teamIndex],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Potatuhs.body(size: 9, color: Potatuhs.textSecondary),
            ),
          Text(
            '$shown',
            style: Potatuhs.body(size: 13, color: Potatuhs.textSecondary)
                .copyWith(fontWeight: FontWeight.bold),
          ),
          _awardChip(s.award),
          if (_bossDelta(s) != 0) _potatoChip(_bossDelta(s)),
          const SizedBox(height: 4),
          Container(
            height: h,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: isWinner ? 0.55 : 0.35),
                  color.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(
                  color: ringColor.withValues(alpha: 0.6), width: 1.5),
              boxShadow: crowned
                  ? Potatuhs.glow(Potatuhs.gold, strength: 0.35, blur: 20)
                  : null,
            ),
            child: h >= 34
                ? Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${s.rank + 1}',
                        style: Potatuhs.display(
                            size: isWinner ? 26 : 20,
                            color: Potatuhs.textPrimary),
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  /// The boss-round potato swing — the headline stake, shown in-row.
  Widget _potatoChip(int delta) {
    final up = delta > 0;
    return Text(
      up ? '+$delta 🥔' : '$delta 🥔',
      style: Potatuhs.body(
              size: 14, color: up ? Potatuhs.gold : const Color(0xFFE5484D))
          .copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _awardChip(int award) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.savings, size: 13, color: Potatuhs.gold),
        const SizedBox(width: 3),
        Text(
          '+$award',
          style: Potatuhs.body(size: 14, color: Potatuhs.gold)
              .copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _portrait(PartyPlayer player, {required double size, Color? ring}) {
    final character = kCharacters[player.character % kCharacters.length];
    final asset = character.asset;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: player.color.withValues(alpha: 0.25),
        border: Border.all(
            color: (ring ?? player.color).withValues(alpha: 0.9),
            width: size >= 56 ? 2.5 : 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: asset != null
          ? Image.asset(asset, fit: BoxFit.cover)
          : Center(
              child: Text(
                player.name.isEmpty ? '?' : player.name[0].toUpperCase(),
                style: Potatuhs.display(
                    size: size * 0.45, color: Colors.white),
              ),
            ),
    );
  }

  Widget _footer(PartyController c) {
    return AnimatedBuilder(
      animation: _reveal,
      builder: (context, _) {
        final a = _footerInterval.transform(_reveal.value);
        if (a == 0) return const SizedBox(height: 56);
        if (!widget.interactive) {
          return SizedBox(
            height: 56,
            child: Center(
              child: Opacity(
                opacity: a,
                child: Text(
                  'Waiting for host…',
                  style:
                      Potatuhs.body(size: 14, color: Potatuhs.textSecondary),
                ),
              ),
            ),
          );
        }
        return Opacity(
          opacity: a,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: _confirm,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Potatuhs.gold,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Potatuhs.gold.withValues(alpha: 0.45),
                        blurRadius: 18),
                  ],
                ),
                child: Center(
                  child: Text(
                    c.round >= c.totalRounds
                        ? 'FINAL RESULTS'
                        : 'BACK TO THE BOARD',
                    style: Potatuhs.body(size: 17, color: Colors.black)
                        .copyWith(
                            fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One-shot confetti burst — every particle's position is a pure function of
/// elapsed time + its seed params, so the painter holds no mutable state and
/// allocates nothing per frame beyond the paint objects.
class _ConfettiPainter extends CustomPainter {
  final int time; // ms since the fx ticker started
  final List<Color> colors;
  _ConfettiPainter({required this.time, required this.colors});

  static const _count = 90;
  static const _lifeMs = 2600.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = time.toDouble();
    final paint = Paint();
    for (var i = 0; i < _count; i++) {
      // Deterministic per-particle params from the index.
      final h = _hash(i);
      final delay = (h % 700).toDouble();
      final life = t - delay;
      if (life < 0 || life > _lifeMs) continue;
      final u = life / _lifeMs;
      final startX = size.width * (((h >> 3) % 1000) / 1000.0);
      final drift = math.sin(u * math.pi * 2 * (1 + (h % 3))) *
          (20 + (h >> 5) % 40);
      final fallSpeed = 0.35 + ((h >> 7) % 100) / 220.0;
      final y = -20 + size.height * u * fallSpeed * 2.2;
      if (y > size.height + 20) continue;
      final x = startX + drift;
      final color = colors[i % colors.length]
          .withValues(alpha: (1.0 - u).clamp(0.0, 1.0));
      paint.color = color;
      final spin = u * math.pi * 4 * (1 + (h % 2));
      final s = 3.0 + (h >> 9) % 5;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(spin);
      if (h.isEven) {
        canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: s * 2, height: s),
            paint);
      } else {
        canvas.drawCircle(Offset.zero, s * 0.7, paint);
      }
      canvas.restore();
    }
  }

  static int _hash(int i) {
    var x = i * 2654435761;
    x ^= x >> 13;
    x = (x * 0x5bd1e995) & 0x7fffffff;
    return x ^ (x >> 15);
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.time != time || old.colors != colors;
}
