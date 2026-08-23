import 'package:flutter/material.dart';

import '../../theme/potatuhs.dart';
import '../party_models.dart';

/// The lobby character select, shared by the party room and the madness
/// lobby: one card per [kCharacters] entry — portrait, name, and the
/// character's one-line bio — so picking is a read, not a guess. Your pick
/// glows gold; characters other players hold are dimmed and locked.
class CharacterPicker extends StatelessWidget {
  /// My current pick (index into [kCharacters]), null when unseated.
  final int? selected;

  /// Characters other players hold.
  final Set<int> taken;

  final void Function(int index) onPick;

  const CharacterPicker({
    super.key,
    required this.selected,
    required this.taken,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PICK YOUR CHARACTER',
            style: Potatuhs.label(color: Potatuhs.textFaint)),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, box) {
            // 3-up on phones; on wider viewports the count grows so cards
            // hold a readable ~110–130px — never a few giant columns.
            final columns =
                (box.maxWidth / 118).floor().clamp(2, kCharacters.length);
            final width =
                ((box.maxWidth - (columns - 1) * 8) / columns).clamp(96.0, 132.0);
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < kCharacters.length; i++)
                  _card(i, width),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _card(int i, double width) {
    final c = kCharacters[i];
    final isMine = i == selected;
    final dim = taken.contains(i) && !isMine;
    return GestureDetector(
      onTap: dim ? null : () => onPick(i),
      child: Opacity(
        opacity: dim ? 0.3 : 1,
        child: Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          decoration: BoxDecoration(
            color: isMine
                ? Potatuhs.gold.withValues(alpha: 0.14)
                : Potatuhs.inkPanel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isMine ? Potatuhs.gold : Colors.white12,
                width: 1.5),
            boxShadow: isMine
                ? [
                    BoxShadow(
                        color: Potatuhs.gold.withValues(alpha: 0.35),
                        blurRadius: 14)
                  ]
                : null,
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Potatuhs.inkDeep,
                  border: Border.all(
                      color: c.color.withValues(alpha: 0.85), width: 2),
                ),
                child: ClipOval(
                  child: c.asset != null
                      ? Image.asset(
                          c.asset!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(c.name[0],
                                style: Potatuhs.display(
                                    size: 22, color: c.color)),
                          ),
                        )
                      : Center(
                          child: Text(c.name[0],
                              style: Potatuhs.display(
                                  size: 22, color: c.color)),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                c.name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Potatuhs.body(
                        size: 11,
                        weight: FontWeight.w800,
                        color: isMine ? Potatuhs.gold : Potatuhs.textPrimary)
                    .copyWith(letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 42,
                child: Text(
                  c.bio,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Potatuhs.body(
                      size: 9.5, color: Potatuhs.textSecondary),
                ),
              ),
              if (dim)
                Text('TAKEN',
                    style: Potatuhs.body(
                            size: 9,
                            weight: FontWeight.w800,
                            color: Potatuhs.orange)
                        .copyWith(letterSpacing: 2)),
            ],
          ),
        ),
      ),
    );
  }
}
