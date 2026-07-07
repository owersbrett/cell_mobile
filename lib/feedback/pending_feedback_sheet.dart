import 'package:flutter/material.dart';

import '../games/game_catalog.dart';
import '../theme/potatuhs.dart';
import 'game_feedback.dart';

/// Bottom sheet listing every game awaiting feedback (skipped prompts), with
/// inline 👍/👎 resolution. Opened from the pending badge on the home
/// account button. Read-only use of [GameCatalog] for display names.
Future<void> showPendingFeedbackSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PendingFeedbackSheet(),
  );
}

class _PendingFeedbackSheet extends StatelessWidget {
  const _PendingFeedbackSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: const BoxDecoration(
        color: Potatuhs.inkPanel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
          child: ValueListenableBuilder<int>(
            valueListenable: GameFeedback.pendingCount,
            builder: (context, count, _) {
              final ids = GameFeedback.pendingGameIds;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'RATE YOUR GAMES',
                    textAlign: TextAlign.center,
                    style: Potatuhs.display(size: 20, spacing: 2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ids.isEmpty
                        ? 'All caught up — nothing waiting.'
                        : 'Games you played but haven\'t rated yet. '
                            'One tap each.',
                    textAlign: TextAlign.center,
                    style:
                        Potatuhs.body(size: 13, color: Potatuhs.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: ids.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) =>
                          _PendingRow(gameId: ids[i]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  final String gameId;
  const _PendingRow({required this.gameId});

  @override
  Widget build(BuildContext context) {
    final game = GameCatalog.byId(gameId);
    final name = game?.name ?? gameId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: Potatuhs.surface(
        fill: Colors.white.withValues(alpha: 0.04),
        radius: 14,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Potatuhs.body(size: 15, weight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Liked it',
            onPressed: () => GameFeedback.resolvePending(gameId,
                liked: true, source: 'solo'),
            icon: const Icon(Icons.thumb_up_alt_rounded,
                color: Potatuhs.gold, size: 22),
          ),
          IconButton(
            tooltip: 'Not for me',
            onPressed: () => GameFeedback.resolvePending(gameId,
                liked: false, source: 'solo'),
            icon: const Icon(Icons.thumb_down_alt_rounded,
                color: Potatuhs.copper, size: 22),
          ),
        ],
      ),
    );
  }
}
