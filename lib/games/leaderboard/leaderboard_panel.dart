import 'package:flutter/material.dart';

import '../../theme/potatuhs.dart';
import 'leaderboard_models.dart';

/// The shared three-view leaderboard, consumed by any mini-game's results
/// screen. Switch views by tapping the segmented control OR swiping the pages
/// (both stay in sync):
///
///   • Match    — this round's standings (you vs the CPU opponents)
///   • History  — this device's best / average / recent runs
///   • Bests    — the highest runs ever recorded on this device
///
/// Stateless about the *data*: the host computes [entries] and [stats] and
/// hands them in, so this widget never touches storage or game logic.
class LeaderboardPanel extends StatefulWidget {
  /// This round's standings (must include the player entry), unsorted.
  final List<LeaderboardEntry> entries;

  /// Device history powering the History / Bests views.
  final LeaderboardStats stats;

  /// What the score counts ("matter", "points").
  final String scoreUnit;

  final Color accent;

  /// Hide the Match tab when there were no opponents (solo score-attack) — the
  /// standings would just be a single "YOU" row.
  final bool showMatch;

  const LeaderboardPanel({
    super.key,
    required this.entries,
    required this.stats,
    required this.scoreUnit,
    required this.accent,
    this.showMatch = true,
  });

  @override
  State<LeaderboardPanel> createState() => _LeaderboardPanelState();
}

class _LeaderboardPanelState extends State<LeaderboardPanel> {
  static const _font = Potatuhs.bodyFont;
  late final PageController _pager;
  late final List<_Tab> _tabs;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _tabs = [
      if (widget.showMatch) const _Tab('MATCH', _View.match),
      const _Tab('HISTORY', _View.history),
      const _Tab('BESTS', _View.bests),
    ];
    _pager = PageController();
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _select(int i) {
    setState(() => _index = i);
    _pager.animateToPage(
      i,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _segmentedControl(),
        const SizedBox(height: 12),
        Expanded(
          child: PageView(
            controller: _pager,
            onPageChanged: (i) => setState(() => _index = i),
            children: [
              for (final tab in _tabs) _pageFor(tab.view),
            ],
          ),
        ),
        if (_tabs.length > 1) ...[
          const SizedBox(height: 10),
          _dots(),
        ],
      ],
    );
  }

  Widget _segmentedControl() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < _tabs.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => _select(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: i == _index
                        ? widget.accent.withValues(alpha: 0.22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: i == _index
                          ? widget.accent.withValues(alpha: 0.7)
                          : Colors.transparent,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _tabs[i].label,
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: i == _index
                            ? widget.accent
                            : Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < _tabs.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _index ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == _index
                  ? widget.accent
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }

  Widget _pageFor(_View view) => switch (view) {
        _View.match => _matchView(),
        _View.history => _historyView(),
        _View.bests => _bestsView(),
      };

  // ── View 1: this round's standings ───────────────────────────────────────
  Widget _matchView() {
    final ranked = [...widget.entries]
      ..sort((a, b) => b.score.compareTo(a.score));
    final place = ranked.indexWhere((e) => e.isPlayer) + 1;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Center(
          child: Text(
            '${_ordinal(place)} of ${ranked.length}',
            style: TextStyle(
              fontFamily: _font,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: place == 1 ? const Color(0xFFFFD54F) : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (int i = 0; i < ranked.length; i++)
          _rankRow(
            rank: i + 1,
            name: ranked[i].name,
            score: ranked[i].score,
            highlight: ranked[i].isPlayer,
          ),
      ],
    );
  }

  // ── View 2: device history (best / average / recent) ─────────────────────
  Widget _historyView() {
    final stats = widget.stats;
    if (stats.isEmpty) return _emptyState('No runs recorded yet.');
    final recent = stats.recent(6);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Row(
          children: [
            _statCard('BEST', stats.best),
            const SizedBox(width: 8),
            _statCard('AVERAGE', stats.average),
            const SizedBox(width: 8),
            _statCard('PLAYS', stats.plays),
          ],
        ),
        const SizedBox(height: 14),
        _sectionLabel('RECENT'),
        const SizedBox(height: 6),
        for (final r in recent)
          _scoreRow(r.score, subtitle: _ago(r.at)),
      ],
    );
  }

  // ── View 3: personal bests ───────────────────────────────────────────────
  Widget _bestsView() {
    final stats = widget.stats;
    if (stats.isEmpty) return _emptyState('Set a score to start your bests.');
    final top = stats.top(8);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        for (int i = 0; i < top.length; i++)
          _rankRow(
            rank: i + 1,
            name: '${_ordinal(i + 1)} best',
            score: top[i].score,
            highlight: i == 0,
          ),
      ],
    );
  }

  // ── shared row builders ──────────────────────────────────────────────────
  Widget _rankRow({
    required int rank,
    required String name,
    required int score,
    required bool highlight,
  }) {
    final accent = widget.accent;
    final medal = _medalColor(rank);
    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        gradient: highlight
            ? LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.30),
                  accent.withValues(alpha: 0.12),
                ],
              )
            : null,
        color: highlight ? null : Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? accent.withValues(alpha: 0.75)
              : Colors.white.withValues(alpha: 0.06),
          width: highlight ? 1.5 : 1,
        ),
        boxShadow: highlight
            ? [BoxShadow(color: accent.withValues(alpha: 0.28), blurRadius: 14)]
            : null,
      ),
      child: Row(
        children: [
          // Rank chip — medal-tinted for the podium (gold / silver / bronze).
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: medal != null
                  ? medal.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: medal != null
                    ? medal.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: rank == 1
                ? Icon(Icons.emoji_events, size: 14, color: medal)
                : Text(
                    '$rank',
                    style: TextStyle(
                      fontFamily: _font,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: medal ?? Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: _font,
                fontSize: 15,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                color: highlight ? Colors.white : Colors.white70,
                letterSpacing: highlight ? 0.5 : 0,
              ),
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              fontFamily: _font,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: highlight ? accent : Colors.white,
            ),
          ),
        ],
      ),
    );
    // Cascade the rows in — later ranks slide from the right a beat later.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TweenAnimationBuilder<double>(
        key: ValueKey('rankrow_${rank}_${name}_$score'),
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 260 + rank * 80),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset((1 - t) * 26, 0),
            child: child,
          ),
        ),
        child: row,
      ),
    );
  }

  static Color? _medalColor(int rank) => switch (rank) {
        1 => const Color(0xFFFFD54F),
        2 => const Color(0xFFCFD8DC),
        3 => const Color(0xFFD7A98C),
        _ => null,
      };

  Widget _scoreRow(int score, {required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                subtitle,
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
            Text(
              '$score',
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, int value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontFamily: _font,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: widget.accent,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: _font,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
          fontFamily: _font,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: Colors.white.withValues(alpha: 0.4),
        ),
      );

  Widget _emptyState(String text) => Center(
        child: Text(
          text,
          style: TextStyle(
            fontFamily: _font,
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
      );

  static String _ordinal(int p) => switch (p) {
        1 => '1st',
        2 => '2nd',
        3 => '3rd',
        _ => '${p}th',
      };

  /// "just now" / "3m ago" / "2h ago" / "5d ago". `at == 0` = migrated legacy
  /// best with no real timestamp.
  static String _ago(int at) {
    if (at == 0) return 'earlier';
    final now = DateTime.now().millisecondsSinceEpoch;
    final secs = ((now - at) / 1000).round();
    if (secs < 60) return 'just now';
    final mins = secs ~/ 60;
    if (mins < 60) return '${mins}m ago';
    final hours = mins ~/ 60;
    if (hours < 24) return '${hours}h ago';
    return '${hours ~/ 24}d ago';
  }
}

enum _View { match, history, bests }

class _Tab {
  final String label;
  final _View view;
  const _Tab(this.label, this.view);
}
