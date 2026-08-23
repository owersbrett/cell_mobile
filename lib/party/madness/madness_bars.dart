import 'package:flutter/material.dart';

import '../../theme/potatuhs.dart';
import '../net/party_transport.dart' show NetPlayer;
import '../party_models.dart';

/// The madness standings as a podium of bars — 1st at the left, last at the
/// right, horizontally scrollable so a 16-player room fits.
///
/// Reads clearly as a ranking (Brett, 2026-07-17): the PLACE sits on top of
/// each column (big, unambiguous), the score sits under the bar labeled in
/// "pts", and every bar grows from ONE shared baseline. When a round's
/// awards come in, the ceremony plays the moment: bars start at last round's
/// totals, then the +points count up into each score, bars grow, and columns
/// SLIDE into their new order when someone overtakes the lead.
class MadnessBars extends StatefulWidget {
  /// Players in final order, best-first (the caller's leaderboard).
  final List<NetPlayer> ordered;
  final Map<String, int> totals; // final (post-award) totals

  /// Points earned this round. Non-null ⇒ play the addition/reorder reveal.
  final Map<String, int>? awards;

  /// Champions to crown (final ceremony) — their columns go gold.
  final Set<String> highlightUids;

  const MadnessBars({
    super.key,
    required this.ordered,
    required this.totals,
    this.awards,
    this.highlightUids = const {},
  });

  @override
  State<MadnessBars> createState() => _MadnessBarsState();
}

class _MadnessBarsState extends State<MadnessBars> {
  static const double _colWidth = 72;
  static const double _colGap = 6;
  static const Duration _kMove = Duration(milliseconds: 700);

  /// Vertical budget above/below the bar (place + portrait + score + name).
  static const double _chrome = 156;

  /// False while showing the pre-round standings; flips to play the reveal.
  late bool _revealed = widget.awards == null;

  @override
  void initState() {
    super.initState();
    if (!_revealed) {
      // Hold last round's picture for a beat, then add the points in.
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _revealed = true);
      });
    }
  }

  /// Totals as currently shown (pre-award until the reveal fires).
  int _shownTotal(String uid) {
    final total = widget.totals[uid] ?? 0;
    if (_revealed) return total;
    return total - (widget.awards?[uid] ?? 0);
  }

  /// Players sorted by the shown totals — the reveal re-sorts, and the
  /// columns animate to their new slots.
  List<NetPlayer> get _shownOrder {
    final list = [...widget.ordered];
    list.sort((a, b) {
      final d = _shownTotal(b.uid).compareTo(_shownTotal(a.uid));
      return d != 0 ? d : a.slot.compareTo(b.slot);
    });
    return list;
  }

  static String _ordinal(int place) => switch (place) {
        1 => '1ST',
        2 => '2ND',
        3 => '3RD',
        _ => '${place}TH',
      };

  @override
  Widget build(BuildContext context) {
    // The ceremony owns its screen: bars scale with the viewport instead of
    // parking at a fixed 274px and leaving the bottom half dark
    // (composition pass, 2026-07-17).
    final height =
        (MediaQuery.sizeOf(context).height * 0.40).clamp(274.0, 430.0);
    final barMax = height - _chrome;
    final order = _shownOrder;
    var top = 1;
    for (final p in order) {
      final t = _shownTotal(p.uid);
      if (t > top) top = t;
    }
    final rank = {for (var i = 0; i < order.length; i++) order[i].uid: i};
    final width =
        order.length * _colWidth + (order.length - 1) * _colGap;
    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              // Keyed by uid so a column keeps its identity while it SLIDES
              // to a new slot on an overtake.
              for (final p in widget.ordered)
                AnimatedPositioned(
                  key: ValueKey('col_${p.uid}'),
                  duration: _kMove,
                  curve: Curves.easeInOutCubic,
                  left: rank[p.uid]! * (_colWidth + _colGap),
                  bottom: 0,
                  width: _colWidth,
                  height: height,
                  child: _column(p,
                      place: rank[p.uid]! + 1, top: top, barMax: barMax),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _column(NetPlayer p,
      {required int place, required int top, required double barMax}) {
    final total = _shownTotal(p.uid);
    final award = widget.awards?[p.uid];
    final crowned = widget.highlightUids.contains(p.uid);
    final color = crowned ? Potatuhs.gold : Color(p.color);
    // A zero-point bar keeps a stub so the column reads as present; every
    // bar grows UP from the same baseline above the score/name footer.
    final h = 10 + (barMax - 10) * (top <= 0 ? 0 : total / top);
    final ch = kCharacters[p.character % kCharacters.length];
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Place — on top, where a ranking is read first.
        Text(
          _ordinal(place),
          style: Potatuhs.display(
              size: 15, color: place == 1 ? Potatuhs.gold : Potatuhs.textSecondary),
        ),
        const SizedBox(height: 4),
        // Portrait rides the top of its bar.
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Potatuhs.inkPanel,
            border:
                Border.all(color: color.withValues(alpha: 0.9), width: 2),
            boxShadow: crowned
                ? [
                    BoxShadow(
                        color: Potatuhs.gold.withValues(alpha: 0.5),
                        blurRadius: 14)
                  ]
                : null,
          ),
          child: ClipOval(
            child: ch.asset != null
                ? Image.asset(ch.asset!, fit: BoxFit.cover)
                : Center(
                    child: Text(ch.name[0],
                        style: Potatuhs.display(size: 16, color: ch.color)),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: _kMove,
          curve: Curves.easeOutCubic,
          width: 40,
          height: h,
          decoration: BoxDecoration(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.95),
                color.withValues(alpha: 0.45),
              ],
            ),
            border: Border.all(
                color: crowned ? Potatuhs.gold : Colors.black26,
                width: crowned ? 2 : 1),
          ),
        ),
        const SizedBox(height: 6),
        // Score — under the bar, explicitly in points; the round's award
        // counts up into it at the reveal.
        SizedBox(
          height: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: total.toDouble()),
                duration: _kMove,
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Text(
                  '${v.round()} pts',
                  style: Potatuhs.display(
                      size: 14,
                      color: crowned ? Potatuhs.gold : Colors.white),
                ),
              ),
              if (award != null && award > 0) ...[
                const SizedBox(width: 4),
                AnimatedOpacity(
                  duration: _kMove,
                  // The +chip fades once it has been "spent" into the score.
                  opacity: _revealed ? 0.25 : 1,
                  child: Text('+$award',
                      style: Potatuhs.body(size: 11, color: Potatuhs.orange)
                          .copyWith(fontWeight: FontWeight.w900)),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: 28,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              p.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Potatuhs.body(size: 10, color: Potatuhs.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
