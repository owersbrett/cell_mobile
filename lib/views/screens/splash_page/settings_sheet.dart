import 'package:flutter/material.dart';

import '../../../games/mini_game_registry.dart';
import '../../../games/opponent_config.dart';
import '../../../games/play_config.dart';
import '../../../party/party_models.dart';
import '../../../theme/potatuhs.dart';

/// Opens the play settings sheet: game mode + disruption, who you play as, and
/// the per-character CPU roster (difficulty + favourite game).
Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();
  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future.wait([PlayConfig.load(), OpponentRoster.load()]).then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.88;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Potatuhs.inkPanel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: !_ready
            ? const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            : ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  child: Column(
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
                      const SizedBox(height: 16),
                      Text('SETTINGS',
                          textAlign: TextAlign.center,
                          style: Potatuhs.display(size: 22, spacing: 2)),
                      const SizedBox(height: 22),
                      _ModeSection(onChanged: () => setState(() {})),
                      const SizedBox(height: 24),
                      const _SectionLabel('YOU PLAY AS'),
                      const SizedBox(height: 10),
                      _PlayAsRow(onChanged: () => setState(() {})),
                      const SizedBox(height: 24),
                      const _SectionLabel('CPU ROSTER'),
                      const SizedBox(height: 4),
                      Text(
                        'Difficulty + favourite game per character. Applied when '
                        'they play as a CPU — never when you play as them.',
                        style: Potatuhs.body(
                            size: 12.5, color: Potatuhs.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      for (final c in kCharacters)
                        _CharacterCard(
                          character: c,
                          isYou: OpponentRoster.playAs == c.name,
                          onChanged: () => setState(() {}),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: Potatuhs.label(size: 12));
}

/// Game mode (Solo / 1v1 / 1v1v1 / 1v1v1v1) + the disruption toggle. Moved here
/// from the home screen.
class _ModeSection extends StatelessWidget {
  final VoidCallback onChanged;
  const _ModeSection({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final disruptEnabled = PlayConfig.opponentCount > 0;
    final disruptOn = PlayConfig.disruption && disruptEnabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('MODE'),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final m in GameMode.values) ...[
              Expanded(
                child: _Chip(
                  label: m.label,
                  selected: PlayConfig.mode == m,
                  accent: Potatuhs.gold,
                  onTap: () async {
                    await PlayConfig.setMode(m);
                    onChanged();
                  },
                ),
              ),
              if (m != GameMode.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Opacity(
          opacity: disruptEnabled ? 1 : 0.4,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: disruptEnabled
                ? () async {
                    await PlayConfig.setDisruption(!PlayConfig.disruption);
                    onChanged();
                  }
                : null,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: disruptOn
                    ? Potatuhs.orange.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: disruptOn
                      ? Potatuhs.orange
                      : Colors.white.withValues(alpha: 0.12),
                  width: disruptOn ? 1.6 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt,
                      size: 16,
                      color: disruptOn ? Potatuhs.orange : Colors.white54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'DISRUPTION — opponents can mess with you',
                      style: TextStyle(
                        fontFamily: Potatuhs.bodyFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: disruptOn ? Potatuhs.orange : Colors.white60,
                      ),
                    ),
                  ),
                  Icon(disruptOn ? Icons.toggle_on : Icons.toggle_off,
                      size: 26,
                      color: disruptOn ? Potatuhs.orange : Colors.white38),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Horizontal avatar strip — pick the character the human plays as. Tapping the
/// active one again clears the choice.
class _PlayAsRow extends StatelessWidget {
  final VoidCallback onChanged;
  const _PlayAsRow({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kCharacters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = kCharacters[i];
          final selected = OpponentRoster.playAs == c.name;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              await OpponentRoster.setPlayAs(selected ? null : c.name);
              onChanged();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CharacterAvatar(character: c, size: 56, selected: selected),
                const SizedBox(height: 6),
                Text(
                  c.name,
                  style: Potatuhs.body(
                    size: 11.5,
                    color: selected ? Potatuhs.gold : Potatuhs.textSecondary,
                    weight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final PartyCharacter character;
  final bool isYou;
  final VoidCallback onChanged;
  const _CharacterCard({
    required this.character,
    required this.isYou,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = OpponentRoster.configFor(character.name);
    return Opacity(
      opacity: isYou ? 0.5 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CharacterAvatar(character: character, size: 40),
                const SizedBox(width: 12),
                Text(character.name, style: Potatuhs.display(size: 18)),
                const Spacer(),
                if (isYou)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Potatuhs.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Potatuhs.gold, width: 1.2),
                    ),
                    child: Text('YOU',
                        style: Potatuhs.label(size: 10, color: Potatuhs.gold)),
                  ),
              ],
            ),
            if (!isYou) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final d in CpuDifficulty.values) ...[
                    Expanded(
                      child: _Chip(
                        label: d.label,
                        selected: cfg.difficulty == d,
                        accent: Potatuhs.airForce,
                        compact: true,
                        onTap: () async {
                          await OpponentRoster.setDifficulty(
                              character.name, d);
                          onChanged();
                        },
                      ),
                    ),
                    if (d != CpuDifficulty.values.last)
                      const SizedBox(width: 6),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              _FavoriteGameDropdown(
                value: cfg.favoriteGameId,
                onChanged: (id) async {
                  await OpponentRoster.setFavoriteGame(character.name, id);
                  onChanged();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FavoriteGameDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  const _FavoriteGameDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Guard against a stale id (game removed from the registry).
    final valid =
        value != null && MiniGameRegistry.byId(value!) != null ? value : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(Icons.star, size: 16, color: Potatuhs.gold.withValues(alpha: 0.8)),
          const SizedBox(width: 8),
          Text('Favourite',
              style: Potatuhs.body(size: 12.5, color: Potatuhs.textSecondary)),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: valid,
              isDense: true,
              dropdownColor: Potatuhs.inkPanel,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
              hint: Text('Any',
                  style: Potatuhs.body(size: 13, color: Potatuhs.textPrimary)),
              style: Potatuhs.body(size: 13),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Any', style: Potatuhs.body(size: 13)),
                ),
                for (final s in MiniGameRegistry.enabledSpecs)
                  DropdownMenuItem<String?>(
                    value: s.id,
                    child: Text(s.name, style: Potatuhs.body(size: 13)),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterAvatar extends StatelessWidget {
  final PartyCharacter character;
  final double size;
  final bool selected;
  const _CharacterAvatar({
    required this.character,
    required this.size,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: character.color.withValues(alpha: 0.25),
        border: Border.all(
          color: selected ? Potatuhs.gold : character.color,
          width: selected ? 2.4 : 1.6,
        ),
        image: character.asset != null
            ? DecorationImage(
                image: AssetImage(character.asset!), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: character.asset == null
          ? Text(character.name[0],
              style: Potatuhs.display(size: size * 0.4))
          : null,
    );
  }
}

/// A selectable pill used for mode + difficulty.
class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final bool compact;
  const _Chip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: compact ? 8 : 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(compact ? 9 : 12),
          border: Border.all(
            color: selected ? accent : Colors.white.withValues(alpha: 0.12),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: Potatuhs.bodyFont,
            fontSize: compact ? 10.5 : 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: selected ? accent : Colors.white70,
          ),
        ),
      ),
    );
  }
}
