import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../games/mini_game.dart';
import '../../games/mini_game_registry.dart';
import '../../models/bio_entity.dart';
import '../../theme/hpg_kit.dart';
import '../../theme/potatuhs.dart';
import 'madness_net.dart';

/// The MADNESS tab's host configuration — deliberately just three things:
/// which scales feed the scale wheel, a search to remove specific games from
/// the pool, and how many spins each player gets (rounds = spins × players).
/// The spins field is a free number input (any positive value below the pool
/// size), not preset chips.
class MadnessHostCard extends StatefulWidget {
  final bool enabled; // online + not busy
  final String hostLabel; // 'HOST' / 'STARTING…'
  final void Function(MadnessConfig config) onHost;

  const MadnessHostCard({
    super.key,
    required this.enabled,
    required this.hostLabel,
    required this.onHost,
  });

  @override
  State<MadnessHostCard> createState() => _MadnessHostCardState();
}

class _MadnessHostCardState extends State<MadnessHostCard> {
  late final Set<BioScale> _scales =
      MadnessConfig.scalesWithGames().toSet(); // default: everything on
  final Set<String> _excluded = {};
  final TextEditingController _search = TextEditingController();
  final TextEditingController _spins = TextEditingController(text: '1');

  @override
  void dispose() {
    _search.dispose();
    _spins.dispose();
    super.dispose();
  }

  MadnessConfig get _config => MadnessConfig(
        scales: Set.of(_scales),
        excludedSpecIds: Set.of(_excluded),
        spinsPerPlayer: int.tryParse(_spins.text) ?? 0,
      );

  List<MiniGameSpec> get _pool => _config.pool();

  int get _spinCount => int.tryParse(_spins.text) ?? 0;

  /// Positive, and below the total number of games in the pool — the room's
  /// no-repeat guarantee needs spins × players ≤ pool, re-checked at START.
  bool get _spinsValid => _spinCount >= 1 && _spinCount < _pool.length;

  bool get _valid => _scales.isNotEmpty && _pool.isNotEmpty && _spinsValid;

  void _bumpSpins(int delta) {
    final next = (_spinCount + delta).clamp(1, 999);
    setState(() => _spins.text = '$next');
  }

  @override
  Widget build(BuildContext context) {
    final pool = _pool;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Scales ──
        Text('SCALES', style: Potatuhs.label(color: Potatuhs.textFaint)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in MadnessConfig.scalesWithGames())
              _scaleChip(s, selected: _scales.contains(s)),
          ],
        ),
        const SizedBox(height: 14),

        // ── Remove games ──
        Text('REMOVE GAMES', style: Potatuhs.label(color: Potatuhs.textFaint)),
        const SizedBox(height: 6),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          style: Potatuhs.body(size: 14),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search the pool…',
            hintStyle: Potatuhs.body(size: 14, color: Potatuhs.textFaint),
            prefixIcon: const Icon(Icons.search,
                size: 18, color: Potatuhs.textFaint),
            filled: true,
            fillColor: Potatuhs.inkDeep,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        ..._searchResults(),
        if (_excluded.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final id in _excluded) _excludedChip(id),
            ],
          ),
        ],
        const SizedBox(height: 14),

        // ── Spins per player ──
        Text('SPINS PER PLAYER',
            style: Potatuhs.label(color: Potatuhs.textFaint)),
        const SizedBox(height: 6),
        Row(
          children: [
            _stepButton(Icons.remove, () => _bumpSpins(-1)),
            const SizedBox(width: 10),
            SizedBox(
              width: 74,
              child: TextField(
                controller: _spins,
                onChanged: (_) => setState(() {}),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 3,
                style: Potatuhs.display(size: 24),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Potatuhs.inkDeep,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _stepButton(Icons.add, () => _bumpSpins(1)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'rounds = spins × players',
                style: Potatuhs.body(size: 11, color: Potatuhs.textFaint),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _scales.isEmpty
              ? 'Turn on at least one scale.'
              : !_spinsValid && pool.isNotEmpty
                  ? 'Spins must be between 1 and ${pool.length - 1} '
                      '(${pool.length} games in the pool).'
                  : '${pool.length} games in the pool.',
          style: Potatuhs.body(
              size: 12,
              color: _valid ? Potatuhs.textSecondary : Potatuhs.orange),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: PotatuhsButton(
            label: widget.hostLabel,
            display: true,
            icon: Icons.add_circle_outline,
            onTap: (widget.enabled && _valid)
                ? () => widget.onHost(_config)
                : () {},
            fill: (widget.enabled && _valid)
                ? Potatuhs.orange
                : Potatuhs.inkPanel,
            textColor: (widget.enabled && _valid)
                ? Potatuhs.ink
                : Potatuhs.textFaint,
          ),
        ),
      ],
    );
  }

  Widget _scaleChip(BioScale s, {required bool selected}) {
    return GestureDetector(
      onTap: () => setState(() {
        selected ? _scales.remove(s) : _scales.add(s);
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Potatuhs.orange.withValues(alpha: 0.16) : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? Potatuhs.orange : Colors.white24),
        ),
        child: Text(
          HpgKit.humanize(s.name),
          style: Potatuhs.body(
              size: 11,
              weight: FontWeight.w700,
              color: selected ? Potatuhs.orange : Potatuhs.textFaint),
        ),
      ),
    );
  }

  List<Widget> _searchResults() {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final hits = [
      for (final s in _pool)
        if (s.name.toLowerCase().contains(q)) s
    ].take(6);
    return [
      const SizedBox(height: 6),
      for (final s in hits)
        GestureDetector(
          onTap: () => setState(() => _excluded.add(s.id)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.remove_circle_outline,
                    size: 16, color: Potatuhs.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${s.name} · ${HpgKit.humanize(s.scale.name)}',
                    style: Potatuhs.body(size: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _excludedChip(String id) {
    final name = MiniGameRegistry.byId(id)?.name ?? id;
    return GestureDetector(
      onTap: () => setState(() => _excluded.remove(id)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Potatuhs.inkDeep,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name,
                style: Potatuhs.body(size: 11, color: Potatuhs.textSecondary)),
            const SizedBox(width: 4),
            const Icon(Icons.close, size: 12, color: Potatuhs.textFaint),
          ],
        ),
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Potatuhs.inkDeep,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, size: 18, color: Potatuhs.textSecondary),
      ),
    );
  }
}
