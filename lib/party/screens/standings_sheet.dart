import 'package:cell_mobile/party/party_controller.dart';
import 'package:cell_mobile/party/party_models.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:flutter/material.dart';

/// The standings viewer (PARTY_CINEMATIC_SPEC §6): every player's full state
/// at a glance — potatoes, diamonds, ATP, held items, board region, round
/// wins, frozen status — openable at any time from the board HUD.
Future<void> showStandingsSheet(
    BuildContext context, PartyController controller) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xF5121219),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'STANDINGS',
              textAlign: TextAlign.center,
              style: Potatuhs.display(size: 18, color: Potatuhs.gold),
            ),
            const SizedBox(height: 4),
            Text(
              'Most 🥔 at the end wins · 💎 breaks ties',
              textAlign: TextAlign.center,
              style: Potatuhs.body(size: 11, color: Potatuhs.textSecondary),
            ),
            const SizedBox(height: 12),
            for (final p in controller.finalPlayerRanking)
              _PlayerRow(controller: controller, player: p),
          ],
        ),
      ),
    ),
  );
}

class _PlayerRow extends StatelessWidget {
  final PartyController controller;
  final PartyPlayer player;
  const _PlayerRow({required this.controller, required this.player});

  @override
  Widget build(BuildContext context) {
    final p = player;
    final space = controller.board[p.position];
    final region = controller.gameMap != null
        ? controller.sectionOf(space).name
        : 'spot ${p.position}';
    final character = kCharacters[p.character % kCharacters.length];
    final isUp = controller.currentPlayer.index == p.index;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.color.withValues(alpha: isUp ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: p.color.withValues(alpha: isUp ? 0.8 : 0.4),
            width: isUp ? 1.6 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.color.withValues(alpha: 0.25),
              border: Border.all(color: p.color, width: 1.6),
            ),
            clipBehavior: Clip.antiAlias,
            child: character.asset != null
                ? Image.asset(character.asset!, fit: BoxFit.cover)
                : Center(
                    child: Text(
                      p.name.isEmpty ? '?' : p.name[0].toUpperCase(),
                      style: Potatuhs.display(size: 18, color: Colors.white),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Potatuhs.body(
                                size: 14, color: Potatuhs.textPrimary)
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (p.frozenTurns > 0) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.ac_unit,
                          size: 13, color: Color(0xFF80DEEA)),
                    ],
                  ],
                ),
                Text(
                  '$region · ${p.roundWins} round win'
                  '${p.roundWins == 1 ? '' : 's'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      Potatuhs.body(size: 11, color: Potatuhs.textSecondary),
                ),
                if (p.items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      children: [
                        for (final item in p.items) ...[
                          Icon(item.icon,
                              size: 13,
                              color: Potatuhs.gold.withValues(alpha: 0.85)),
                          const SizedBox(width: 4),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🥔 ${p.potatoes}',
                style: Potatuhs.body(size: 14, color: Potatuhs.textPrimary)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '💎 ${p.diamonds} · ⚡ ${p.atp}',
                style: Potatuhs.body(size: 11, color: Potatuhs.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
