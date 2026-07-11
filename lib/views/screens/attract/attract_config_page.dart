import 'package:flutter/material.dart';

import '../../../games/attract/review_queue.dart';
import '../../../games/mini_game_registry.dart';
import '../../../party/maps/game_map.dart';
import '../../../theme/potatuhs.dart';
import 'attract_games_page.dart';
import 'attract_map_page.dart';

/// The ATTRACT picker (reached from the Home ATTRACT door). Choose what plays
/// itself in the background for build-in-public footage:
///  • All Games — walk every enabled mini-game, one after another.
///  • A party board — auto-play a full 4-player party game on one of the 3 maps.
class AttractConfigPage extends StatelessWidget {
  const AttractConfigPage({super.key});

  static const _mapAccents = [
    Potatuhs.orange,
    Potatuhs.airForce,
    Potatuhs.gold,
  ];

  /// How many queued ids resolve to a real spec (so the picker shows a truthful
  /// count and never launches an empty walk).
  int get _queueCount {
    final ids = MiniGameRegistry.specs.map((s) => s.id).toSet();
    return kReviewQueue.where(ids.contains).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('ATTRACT', style: Potatuhs.display(size: 36)),
              const SizedBox(height: 4),
              Text(
                'Pick what plays itself in the background',
                style: Potatuhs.body(size: 13, color: Potatuhs.textSecondary),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _AttractOption(
                      title: 'ALL GAMES',
                      subtitle: 'Walk every mini-game — pick where to start',
                      icon: Icons.smart_toy,
                      accent: Potatuhs.gold,
                      onTap: () => _pickStartIndex(context),
                    ),
                    const SizedBox(height: 14),
                    // The chat-configured review queue: only the games Claude
                    // and Brett are actively fixing right now. Edited from chat;
                    // see games/attract/review_queue.dart.
                    _AttractOption(
                      title: 'QUEUED GAMES',
                      subtitle: _queueCount == 0
                          ? 'Nothing queued — ask Claude to queue games'
                          : 'Review the $_queueCount game${_queueCount == 1 ? '' : 's'} on the fix list',
                      icon: Icons.playlist_play,
                      accent: Potatuhs.airForce,
                      onTap: _queueCount == 0
                          ? () {}
                          : () => _push(
                                context,
                                const AttractGamesPage(queueIds: kReviewQueue),
                              ),
                    ),
                    const SizedBox(height: 14),
                    for (var i = 0; i < kGameMaps.length; i++) ...[
                      _AttractOption(
                        title: kGameMaps[i].name.toUpperCase(),
                        subtitle: kGameMaps[i].subtitle,
                        icon: Icons.casino,
                        accent: _mapAccents[i % _mapAccents.length],
                        onTap: () => _push(
                          context,
                          AttractMapPage(mapId: kGameMaps[i].id),
                        ),
                      ),
                      if (i < kGameMaps.length - 1) const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget page) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => page),
      );

  /// Choose which game of the walk to start at (QA: hop straight back to a
  /// specific index, e.g. game 20, instead of replaying from the top). Opens a
  /// numbered list of the enabled games, pre-scrolled to where the session
  /// cursor left off; the numbers match the "21/64" attract progress chip.
  void _pickStartIndex(BuildContext context) {
    final games = MiniGameRegistry.specs.where((s) => s.enabled).toList();
    if (games.isEmpty) {
      _push(context, const AttractGamesPage());
      return;
    }
    final resumeAt = AttractState.cursor.clamp(0, games.length - 1);
    const rowExtent = 52.0;
    final controller = ScrollController(
      initialScrollOffset: (resumeAt - 2).clamp(0, games.length - 1) * rowExtent,
    );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Potatuhs.inkPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('START AT', style: Potatuhs.display(size: 24)),
                const SizedBox(height: 4),
                Text(
                  'The walk runs from here through game ${games.length}, then loops',
                  style: Potatuhs.body(size: 12, color: Potatuhs.textSecondary),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    controller: controller,
                    shrinkWrap: true,
                    itemExtent: rowExtent,
                    itemCount: games.length,
                    itemBuilder: (_, i) {
                      final spec = games[i];
                      final isResume = i == resumeAt;
                      return _StartIndexRow(
                        number: i + 1,
                        name: spec.name,
                        accent: spec.accent,
                        highlighted: isResume,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _push(context, AttractGamesPage(startIndex: i));
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(controller.dispose);
  }
}

/// One row of the start-index picker: "NN  GAME NAME", accented like the game,
/// with the session-cursor row highlighted as the natural resume point.
class _StartIndexRow extends StatelessWidget {
  final int number;
  final String name;
  final Color accent;
  final bool highlighted;
  final VoidCallback onTap;

  const _StartIndexRow({
    required this.number,
    required this.name,
    required this.accent,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: highlighted
            ? BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.5)),
              )
            : null,
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Text(
                '$number',
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: Potatuhs.display(size: 16, color: accent),
              ),
            ),
            Expanded(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: Potatuhs.body(
                  size: 14,
                  color: highlighted
                      ? Potatuhs.textPrimary
                      : Potatuhs.textSecondary,
                ),
              ),
            ),
            if (highlighted)
              Text(
                'LEFT OFF',
                style: Potatuhs.body(size: 10, color: accent),
              ),
          ],
        ),
      ),
    );
  }
}

class _AttractOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _AttractOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: Potatuhs.inkPanel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.55), width: 2),
          boxShadow: Potatuhs.glow(accent, strength: 0.30, blur: 22),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.16),
                border: Border.all(
                    color: accent.withValues(alpha: 0.6), width: 1.5),
              ),
              child: Icon(icon, color: accent, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: Potatuhs.display(
                          size: 22, color: Potatuhs.textPrimary)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: Potatuhs.body(
                          size: 13, color: Potatuhs.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: accent),
          ],
        ),
      ),
    );
  }
}
