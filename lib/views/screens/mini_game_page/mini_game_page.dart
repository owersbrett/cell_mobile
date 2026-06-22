import 'dart:math';
import 'dart:ui' as ui;
import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_events.dart';
import 'package:cell_mobile/games/game_catalog.dart';
import 'package:cell_mobile/games/play_config.dart';
import 'package:cell_mobile/games/rank_store.dart';
import 'package:cell_mobile/games/mini_game_host.dart';
import 'package:cell_mobile/games/mini_game_registry.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'games/big_bang_game.dart';
import 'games/thought_catcher_game.dart';
import 'games/starch_factory_game.dart';
import 'games/molecule_builder_game.dart';
import 'games/mitosis_rush_game.dart';
import 'games/potato_rush_game.dart';
import 'games/farm_panic_game.dart';
import 'games/tissue_layer_game.dart';
import 'games/organ_system_game.dart';
import 'mini_games_batch2.dart';
import 'mini_games_batch3.dart';
// Enhanced financial game (market events + debt/credit; fixes sold-early lockout).
// Aliased to avoid the name clash with the legacy FinancialTradingGame in batch3.
import 'package:cell_mobile/games/financial/market_trader/market_trader.dart'
    as mt;

/// Generic mini-game page — routes to a scale's game(s) via the ranked catalog.
///
/// EVERY scale shows the chooser (the particles Collider/Accelerator pattern,
/// generalised to all 22 scales) listing that scale's [GameCatalog] games
/// ordered by rank — even at one game today, ready to grow toward ~8. Picking a
/// game launches it: registry games via the shared [MiniGameHost], legacy games
/// via their per-scale widget (`_buildGame`).
class MiniGamePage extends StatefulWidget {
  final BioScale scale;
  const MiniGamePage({Key? key, required this.scale}) : super(key: key);

  @override
  State<MiniGamePage> createState() => _MiniGamePageState();
}

class _MiniGamePageState extends State<MiniGamePage> {
  /// The game chosen from the per-scale picker; null shows the picker.
  CatalogGame? _chosen;

  BioScale get scale => widget.scale;

  void _toOverview() => context
      .read<NavigationBloc>()
      .add(NavigateToScreen(AppScreen.scaleOverview));

  @override
  Widget build(BuildContext context) {
    final games = GameCatalog.forScale(scale);

    // Every scale shows the chooser (generalised particles pattern), even at
    // one game — ready to grow toward ~8 per scale.
    if (_chosen == null) {
      return _GamePicker(
        scale: scale,
        games: games,
        onBack: _toOverview,
        onPick: (g) => setState(() => _chosen = g),
      );
    }

    final chosen = _chosen!;
    void backToPicker() => setState(() => _chosen = null);

    // Registry game → shared host, vs the mode picked on the home page.
    if (chosen.specId != null) {
      final spec = MiniGameRegistry.byId(chosen.specId!);
      if (spec != null) {
        return MiniGameHost(
          spec: spec,
          onExit: backToPicker,
          opponentCount: PlayConfig.opponentCount,
          disruption: PlayConfig.disruptionActive,
        );
      }
    }

    // Legacy game → its per-scale widget, wrapped with a HUD + back-to-picker.
    return _legacyScaffold(chosen, backToPicker);
  }

  Widget _legacyScaffold(CatalogGame game, VoidCallback onBack) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0x88000000),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white70, size: 22),
                    ),
                  ),
                  Text(
                    game.name,
                    style: const TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(child: _buildGame(scale)),
          ],
        ),
      ),
    );
  }

  Widget _buildGame(BioScale scale) {
    switch (scale) {
      case BioScale.nothings: return BigBangGame();
      case BioScale.somethings: return const ThoughtCatcherGame();
      case BioScale.particles: return const _ParticleAcceleratorGame();
      case BioScale.atoms: return const StarchFactoryGame();
      case BioScale.molecular: return MoleculeBuilderGame();
      case BioScale.cell: return const MitosisRushGame();
      case BioScale.tissue: return const TissueLayerGame();
      case BioScale.organ: return const OrganGrowGame();
      case BioScale.organSystem: return const OrganSystemGame();
      case BioScale.organism: return const OrganismHarvestGame();
      case BioScale.ecosystem: return const PotatoRushGame();
      case BioScale.farmSystem: return const FarmPanicGame();
      case BioScale.supplyChain: return const SupplyChainGame();
      case BioScale.financial: return const mt.FinancialTradingGame();
      case BioScale.planets: return const PlanetCatchGame();
      case BioScale.solarSystems: return const SolarSortGame();
      case BioScale.galactic: return const GalaxyCollectorGame();
      case BioScale.cosmicStructures: return const NeuronConnectGame();
      case BioScale.multiverseAll: return const RealityMergeGame();
      case BioScale.universeAll: return const EverythingGame();
      case BioScale.infinities: return const InfinityCounterGame();
      default: return BigBangGame();
    }
  }
}


// ---------------------------------------------------------------------------
// Game picker — shown when a scale has more than one game (e.g. particles →
// Collider + Accelerator). Lets the player choose which to play.
// ---------------------------------------------------------------------------

class _GamePicker extends StatefulWidget {
  final BioScale scale;
  final List<CatalogGame> games;
  final VoidCallback onBack;
  final ValueChanged<CatalogGame> onPick;

  const _GamePicker({
    required this.scale,
    required this.games,
    required this.onBack,
    required this.onPick,
  });

  @override
  State<_GamePicker> createState() => _GamePickerState();
}

class _GamePickerState extends State<_GamePicker> {
  BioScale get scale => widget.scale;

  @override
  void initState() {
    super.initState();
    // Load any saved rank overrides, then re-sort with them applied.
    RankStore.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  /// Scale's games ordered by their EFFECTIVE rank (override or default).
  List<CatalogGame> get _sorted {
    final list = [...widget.games];
    list.sort((a, b) {
      final r = RankStore.rankFor(a).order.compareTo(RankStore.rankFor(b).order);
      return r != 0 ? r : a.name.compareTo(b.name);
    });
    return list;
  }

  Future<void> _editGame(CatalogGame game) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, // keyboard pushes the sheet up
      backgroundColor: const Color(0xFF15131C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => GameFeedbackSheet(game: game),
    );
    if (mounted) setState(() {}); // refresh rank badge + comment indicator
  }

  @override
  Widget build(BuildContext context) {
    final games = _sorted;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0x88000000),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white70, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'CHOOSE A GAME',
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(54, 0, 16, 6),
              child: Text(
                '${scale.name.toUpperCase()} · ${games.length} ${games.length == 1 ? 'game' : 'games'}',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ),
            // Game cards
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
                itemCount: games.length,
                itemBuilder: (context, i) => _GameCard(
                  game: games[i],
                  rank: RankStore.rankFor(games[i]),
                  hasNote: RankStore.hasNote(games[i].id),
                  onTap: () => widget.onPick(games[i]),
                  onEdit: () => _editGame(games[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final CatalogGame game;
  final GameRank rank;
  final bool hasNote;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  const _GameCard({
    required this.game,
    required this.rank,
    required this.hasNote,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final accent = game.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.20),
              accent.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.22),
              blurRadius: 16,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          children: [
            // Rank badge — the assigned tier, leading the card.
            _rankBadge(accent),
            const SizedBox(width: 12),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.6)),
              ),
              child: Icon(game.icon, color: accent, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.name,
                    style: const TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    game.tagline,
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 12,
                      height: 1.2,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  if (hasNote) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.mode_comment,
                            size: 13, color: accent.withValues(alpha: 0.85)),
                        const SizedBox(width: 3),
                        Text(
                          'FEEDBACK',
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: accent.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.play_circle_fill, color: accent, size: 32),
          ],
        ),
      ),
    );
  }

  Widget _rankBadge(Color accent) {
    // Tappable — rate (S A B C D F) + comment on this game from the chooser.
    return GestureDetector(
      onTap: onEdit,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: 0.6)),
            ),
            child: Text(
              rank.label,
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Icon(Icons.edit, size: 10, color: accent.withValues(alpha: 0.6)),
        ],
      ),
    );
  }

}

// ---------------------------------------------------------------------------
// Game feedback sheet — rate (S A B C D F) + jot comments + copy them out.
// Shared by the chooser and the debug Games console.
// ---------------------------------------------------------------------------

class GameFeedbackSheet extends StatefulWidget {
  final CatalogGame game;
  const GameFeedbackSheet({super.key, required this.game});

  @override
  State<GameFeedbackSheet> createState() => _GameFeedbackSheetState();
}

class _GameFeedbackSheetState extends State<GameFeedbackSheet> {
  late final TextEditingController _noteCtrl;
  late GameRank _rank;

  CatalogGame get game => widget.game;

  @override
  void initState() {
    super.initState();
    _rank = RankStore.rankFor(game);
    _noteCtrl = TextEditingController(text: RankStore.noteFor(game.id));
  }

  @override
  void dispose() {
    // Persist whatever's typed when the sheet closes.
    RankStore.setNote(game.id, _noteCtrl.text);
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    await RankStore.setNote(game.id, _noteCtrl.text);
    await Clipboard.setData(ClipboardData(text: RankStore.feedbackFor(game)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${game.name} feedback'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = game.accent;
    return Padding(
      // Lift above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RATE ${game.name.toUpperCase()}',
                style: const TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap a tier — best (S) to worst (F).',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final r in GameRankLabel.assignable)
                    GestureDetector(
                      onTap: () async {
                        setState(() => _rank = r);
                        await RankStore.setRank(game.id, r);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: r == _rank
                              ? accent.withValues(alpha: 0.30)
                              : accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: r == _rank
                                ? accent
                                : accent.withValues(alpha: 0.4),
                            width: r == _rank ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          r.label,
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: r == _rank
                                ? accent
                                : Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'COMMENTS',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _noteCtrl,
                maxLines: 4,
                minLines: 3,
                style: const TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 14,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'What needs work? Jot it now — copy it to the agent later.',
                  hintStyle: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accent.withValues(alpha: 0.4)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accent.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copy,
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('COPY'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: BorderSide(color: accent.withValues(alpha: 0.6)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('DONE'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GAME 2: Particle Accelerator — tap to speed orbiting particles, collide them
// ---------------------------------------------------------------------------

class _ParticleAcceleratorGame extends StatefulWidget {
  const _ParticleAcceleratorGame();
  @override
  State<_ParticleAcceleratorGame> createState() =>
      _ParticleAcceleratorGameState();
}

class _ParticleAcceleratorGameState extends State<_ParticleAcceleratorGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  // Particle orbit angles (radians)
  double _angle1 = 0;
  double _angle2 = pi;

  // Speed mechanics
  double _speed = 0.0;
  static const double _maxSpeed = 10.0;
  static const double _drag = 0.55;
  static const double _tapBoost = 0.7;

  // Target zone (fraction of _maxSpeed)
  double _zoneMin = 0.35;
  double _zoneMax = 0.65;

  // Collision progress (0..1)
  double _progress = 0.0;
  static const double _fillRate = 1.0 / 3.0; // fills in ~3 seconds
  static const double _drainRate = 0.15;

  // Scoring
  int _totalFunding = 0;
  int _collisions = 0;
  int _level = 1;
  int _nextReward = 50;

  // Timer
  double _elapsed = 0.0;
  static const double _gameDuration = 60.0;
  bool _gameOver = false;

  // Visual effects
  double _ringFlash = 0.0;
  double _screenShake = 0.0;
  final List<_AccelDebris> _debris = [];
  final List<_FundingPopup> _popups = [];
  String? _levelText;
  double _levelTextAge = 0.0;

  double _lastTime = 0;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_onTick);
    _ticker.forward();
    _lastTime = _now();
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1000000.0;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _resetGame() {
    _speed = 0.0;
    _progress = 0.0;
    _totalFunding = 0;
    _collisions = 0;
    _level = 1;
    _nextReward = 50;
    _elapsed = 0.0;
    _gameOver = false;
    _ringFlash = 0.0;
    _screenShake = 0.0;
    _debris.clear();
    _popups.clear();
    _levelText = null;
    _zoneMin = 0.35;
    _zoneMax = 0.65;
    _angle1 = 0;
    _angle2 = pi;
    _lastTime = _now();
  }

  void _onTick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;

    if (_gameOver) return;

    setState(() {
      _elapsed += dt;

      // Check game over conditions
      if (_elapsed >= _gameDuration || _speed > _maxSpeed) {
        _gameOver = true;
        return;
      }

      // Natural deceleration (drag)
      _speed *= (1 - _drag * dt);
      if (_speed < 0.01) _speed = 0.0;

      // Move particles — speed maps to angular velocity
      final angularVel = _speed * 2.0;
      _angle1 += angularVel * dt;
      _angle2 += (angularVel * 0.8 + 0.3) * dt;

      // Check if speed is in the target zone
      final normalizedSpeed = _speed / _maxSpeed;
      final inZone = normalizedSpeed >= _zoneMin && normalizedSpeed <= _zoneMax;

      if (inZone) {
        _progress += _fillRate * dt;
        if (_progress >= 1.0) {
          _triggerCollision();
        }
      } else {
        _progress -= _drainRate * dt;
        if (_progress < 0) _progress = 0;
      }

      // Update debris
      for (final d in _debris) {
        d.x += d.vx * dt;
        d.y += d.vy * dt;
        d.vx *= (1 - 1.5 * dt);
        d.vy *= (1 - 1.5 * dt);
        d.life -= dt * 0.5;
      }
      _debris.removeWhere((d) => d.life <= 0);

      // Update popups
      for (final p in _popups) {
        p.y -= 40 * dt;
        p.age += dt;
      }
      _popups.removeWhere((p) => p.age > 2.0);

      // Decay effects
      if (_ringFlash > 0) _ringFlash = (_ringFlash - dt * 3).clamp(0.0, 1.0);
      if (_screenShake > 0) {
        _screenShake = (_screenShake - dt * 4).clamp(0.0, 1.0);
      }

      // Level text decay
      if (_levelText != null) {
        _levelTextAge += dt;
        if (_levelTextAge > 2.0) _levelText = null;
      }
    });
  }

  void _triggerCollision() {
    _collisions++;
    _totalFunding += _nextReward;
    _progress = 0.0;
    _ringFlash = 1.0;
    _screenShake = 1.0;

    // Spawn popup
    _popups.add(_FundingPopup(
      text: '\$$_nextReward for potato research!',
      y: 0,
      age: 0,
    ));

    // Increase reward for next collision
    _nextReward = (50 + _collisions * 25).clamp(50, 500);

    // Reset speed
    _speed = 0.0;
    _angle1 = 0;
    _angle2 = pi;

    // Narrow the target zone for next level
    _level++;
    final zoneShrink = 0.03 * _collisions;
    final zoneCenter = (_zoneMin + _zoneMax) / 2;
    final halfWidth =
        ((_zoneMax - _zoneMin) / 2 - zoneShrink).clamp(0.04, 0.15);
    _zoneMin = (zoneCenter - halfWidth).clamp(0.1, 0.8);
    _zoneMax = (zoneCenter + halfWidth).clamp(0.2, 0.9);

    _levelText = 'Level $_level';
    _levelTextAge = 0;

    // Spawn debris burst (positions set to zero, repositioned in build)
    for (int i = 0; i < 30; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      final spd = 60 + _rng.nextDouble() * 250;
      _debris.add(_AccelDebris(
        x: 0,
        y: 0,
        vx: cos(a) * spd,
        vy: sin(a) * spd,
        life: 1.0,
        color: HSVColor.fromAHSV(
          1,
          _rng.nextDouble() * 60 + 20,
          0.8,
          1,
        ).toColor(),
        radius: 2 + _rng.nextDouble() * 4,
      ));
    }
  }

  void _onTap() {
    if (_gameOver) {
      setState(_resetGame);
      return;
    }
    setState(() {
      _speed += _tapBoost;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _onTap(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final ctr = Offset(w / 2, h / 2);
          final ringR = min(w, h) * 0.32;

          // Position debris at ring top on first frame
          for (final d in _debris) {
            if (d.x == 0 && d.y == 0) {
              d.x = ctr.dx;
              d.y = ctr.dy - ringR;
            }
          }

          return ClipRect(
            child: CustomPaint(
              painter: _AcceleratorPainter(
                center: ctr,
                ringRadius: ringR,
                angle1: _angle1,
                angle2: _angle2,
                speed: _speed,
                maxSpeed: _maxSpeed,
                zoneMin: _zoneMin,
                zoneMax: _zoneMax,
                progress: _progress,
                totalFunding: _totalFunding,
                collisions: _collisions,
                level: _level,
                elapsed: _elapsed,
                gameDuration: _gameDuration,
                gameOver: _gameOver,
                ringFlash: _ringFlash,
                screenShake: _screenShake,
                debris: _debris,
                popups: _popups,
                levelText: _levelText,
                levelTextAge: _levelTextAge,
                rng: _rng,
              ),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }
}

class _FundingPopup {
  String text;
  double y;
  double age;
  _FundingPopup({required this.text, required this.y, required this.age});
}

class _AccelDebris {
  double x, y, vx, vy, life, radius;
  Color color;
  _AccelDebris({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
    required this.radius,
  });
}

class _AcceleratorPainter extends CustomPainter {
  final Offset center;
  final double ringRadius;
  final double angle1, angle2;
  final double speed, maxSpeed;
  final double zoneMin, zoneMax;
  final double progress;
  final int totalFunding, collisions, level;
  final double elapsed, gameDuration;
  final bool gameOver;
  final double ringFlash, screenShake;
  final List<_AccelDebris> debris;
  final List<_FundingPopup> popups;
  final String? levelText;
  final double levelTextAge;
  final Random rng;

  _AcceleratorPainter({
    required this.center,
    required this.ringRadius,
    required this.angle1,
    required this.angle2,
    required this.speed,
    required this.maxSpeed,
    required this.zoneMin,
    required this.zoneMax,
    required this.progress,
    required this.totalFunding,
    required this.collisions,
    required this.level,
    required this.elapsed,
    required this.gameDuration,
    required this.gameOver,
    required this.ringFlash,
    required this.screenShake,
    required this.debris,
    required this.popups,
    required this.levelText,
    required this.levelTextAge,
    required this.rng,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Screen shake offset
    if (screenShake > 0) {
      final shakeX = (rng.nextDouble() - 0.5) * 8 * screenShake;
      final shakeY = (rng.nextDouble() - 0.5) * 8 * screenShake;
      canvas.save();
      canvas.translate(shakeX, shakeY);
    }

    // Background
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF0A0A14));

    // Subtle radial grid
    _drawRadialGrid(canvas);

    final normalizedSpeed = (speed / maxSpeed).clamp(0.0, 1.0);
    final inZone = normalizedSpeed >= zoneMin && normalizedSpeed <= zoneMax;
    final tooFast = normalizedSpeed > zoneMax;

    if (!gameOver) {
      _drawRing(canvas, normalizedSpeed, inZone, tooFast);
      _drawParticles(canvas, normalizedSpeed, inZone, tooFast);
      _drawSpeedGauge(canvas, size, normalizedSpeed);
      _drawProgressBar(canvas, size);
      _drawFundingCounter(canvas, size);
      _drawTimer(canvas, size);
      _drawDebris(canvas);
      _drawPopups(canvas, size);
      if (levelText != null) _drawLevelText(canvas, size);
      _drawInstructions(canvas, size);
    } else {
      _drawGameOver(canvas, size);
    }

    // Screen flash on collision
    if (ringFlash > 0.5) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = Colors.white.withValues(alpha: (ringFlash - 0.5) * 0.6),
      );
    }

    if (screenShake > 0) {
      canvas.restore();
    }
  }

  void _drawRadialGrid(Canvas canvas) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (int i = 1; i <= 6; i++) {
      canvas.drawCircle(center, ringRadius * i * 0.3, gridPaint);
    }
    for (int i = 0; i < 12; i++) {
      final a = i * pi / 6;
      canvas.drawLine(
        center,
        Offset(center.dx + cos(a) * ringRadius * 1.8,
            center.dy + sin(a) * ringRadius * 1.8),
        gridPaint,
      );
    }
  }

  void _drawRing(
      Canvas canvas, double normalizedSpeed, bool inZone, bool tooFast) {
    Color ringColor;
    double glowWidth;
    double glowAlpha;

    if (inZone) {
      ringColor = const Color(0xFF4CAF50);
      glowWidth = 8;
      glowAlpha = 0.7;
    } else if (tooFast) {
      ringColor = const Color(0xFFFF1744);
      glowWidth = 6 + sin(elapsed * 20) * 3;
      glowAlpha = 0.8;
    } else {
      ringColor = const Color(0xFF444466);
      glowWidth = 4;
      glowAlpha = 0.3 + normalizedSpeed * 0.3;
    }

    if (ringFlash > 0) {
      ringColor = Color.lerp(ringColor, Colors.white, ringFlash)!;
      glowAlpha = glowAlpha + ringFlash * 0.3;
    }

    // Outer glow
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..color =
            ringColor.withValues(alpha: (glowAlpha * 0.3).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = glowWidth + 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Main ring track
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..color = ringColor.withValues(alpha: glowAlpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = glowWidth,
    );

    // Inner edges
    final edgePaint = Paint()
      ..color = ringColor.withValues(alpha: (glowAlpha * 0.5).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, ringRadius - glowWidth / 2, edgePaint);
    canvas.drawCircle(center, ringRadius + glowWidth / 2, edgePaint);
  }

  void _drawParticles(
      Canvas canvas, double normalizedSpeed, bool inZone, bool tooFast) {
    const color1 = Color(0xFF4FC3F7);
    const color2 = Color(0xFFFF7043);

    final p1 = Offset(
      center.dx + cos(angle1) * ringRadius,
      center.dy + sin(angle1) * ringRadius,
    );
    final p2 = Offset(
      center.dx + cos(angle2) * ringRadius,
      center.dy + sin(angle2) * ringRadius,
    );

    // Trail length depends on speed state
    final trailSteps = inZone ? 12 : (tooFast ? 8 : 4);
    final trailSpacing = normalizedSpeed * 0.15 + 0.02;

    for (int i = trailSteps; i > 0; i--) {
      final t = i * trailSpacing;
      final alpha = (1.0 - i / trailSteps) * 0.4;

      final t1 = Offset(
        center.dx + cos(angle1 - t) * ringRadius,
        center.dy + sin(angle1 - t) * ringRadius,
      );
      canvas.drawCircle(t1, 3,
          Paint()..color = color1.withValues(alpha: alpha.clamp(0.0, 1.0)));

      final t2 = Offset(
        center.dx +
            cos(angle2 - t * 0.8 - 0.3 * t / trailSteps) * ringRadius,
        center.dy +
            sin(angle2 - t * 0.8 - 0.3 * t / trailSteps) * ringRadius,
      );
      canvas.drawCircle(t2, 3,
          Paint()..color = color2.withValues(alpha: alpha.clamp(0.0, 1.0)));
    }

    // Erratic jitter when too fast
    if (tooFast) {
      for (int i = 0; i < 4; i++) {
        final jitter = (rng.nextDouble() - 0.5) * 12;
        canvas.drawCircle(Offset(p1.dx + jitter, p1.dy + jitter), 2,
            Paint()..color = color1.withValues(alpha: 0.3));
        canvas.drawCircle(Offset(p2.dx + jitter, p2.dy + jitter), 2,
            Paint()..color = color2.withValues(alpha: 0.3));
      }
    }

    _drawGlowDot(canvas, p1, color1, 7);
    _drawGlowDot(canvas, p2, color2, 7);
  }

  void _drawGlowDot(Canvas canvas, Offset pos, Color color, double r) {
    final gradient = ui.Gradient.radial(
      pos,
      r * 3,
      [color.withValues(alpha: 0.5), color.withValues(alpha: 0)],
    );
    canvas.drawCircle(pos, r * 3, Paint()..shader = gradient);
    canvas.drawCircle(pos, r, Paint()..color = color);
    canvas.drawCircle(
        pos, r * 0.4, Paint()..color = Colors.white.withValues(alpha: 0.8));
  }

  void _drawSpeedGauge(Canvas canvas, Size size, double normalizedSpeed) {
    const gaugeLeft = 20.0;
    final gaugeTop = size.height * 0.2;
    final gaugeHeight = size.height * 0.55;
    const gaugeWidth = 24.0;

    // Background
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(gaugeLeft, gaugeTop, gaugeWidth, gaugeHeight),
      const Radius.circular(12),
    );
    canvas.drawRRect(bgRect, Paint()..color = const Color(0xFF1A1A2E));
    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = const Color(0xFF333355)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Target zone (green band)
    final zoneTop = gaugeTop + gaugeHeight * (1.0 - zoneMax);
    final zoneBottom = gaugeTop + gaugeHeight * (1.0 - zoneMin);
    final zoneRect = Rect.fromLTRB(
        gaugeLeft + 2, zoneTop, gaugeLeft + gaugeWidth - 2, zoneBottom);
    canvas.drawRect(
        zoneRect,
        Paint()
          ..color = const Color(0xFF4CAF50).withValues(alpha: 0.35));
    canvas.drawRect(
      zoneRect,
      Paint()
        ..color = const Color(0xFF4CAF50).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Speed fill bar
    final fillHeight = gaugeHeight * normalizedSpeed;
    final fillTop = gaugeTop + gaugeHeight - fillHeight;
    Color fillColor;
    if (normalizedSpeed > zoneMax) {
      fillColor = const Color(0xFFFF1744);
    } else if (normalizedSpeed >= zoneMin) {
      fillColor = const Color(0xFF4CAF50);
    } else {
      fillColor = const Color(0xFF4FC3F7);
    }

    final fillRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(gaugeLeft + 4, fillTop, gaugeWidth - 8, fillHeight),
      bottomLeft: const Radius.circular(8),
      bottomRight: const Radius.circular(8),
    );
    canvas.drawRRect(
        fillRect, Paint()..color = fillColor.withValues(alpha: 0.8));

    // Speed indicator line
    final indicatorY = gaugeTop + gaugeHeight * (1.0 - normalizedSpeed);
    canvas.drawLine(
      Offset(gaugeLeft - 4, indicatorY),
      Offset(gaugeLeft + gaugeWidth + 4, indicatorY),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );

    // Labels
    final slowLabel = TextPainter(
      text: const TextSpan(
        text: 'SLOW',
        style: TextStyle(
            fontFamily: 'Avenir', fontSize: 9, color: Colors.white30),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    slowLabel.paint(
      canvas,
      Offset(gaugeLeft + (gaugeWidth - slowLabel.width) / 2,
          gaugeTop + gaugeHeight + 4),
    );

    final fastLabel = TextPainter(
      text: const TextSpan(
        text: 'FAST',
        style: TextStyle(
            fontFamily: 'Avenir', fontSize: 9, color: Colors.white30),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    fastLabel.paint(
      canvas,
      Offset(gaugeLeft + (gaugeWidth - fastLabel.width) / 2, gaugeTop - 16),
    );
  }

  void _drawProgressBar(Canvas canvas, Size size) {
    const barLeft = 60.0;
    final barRight = size.width - 20;
    const barTop = 50.0;
    const barHeight = 14.0;
    final barWidth = barRight - barLeft;

    // Label
    final label = TextPainter(
      text: const TextSpan(
        text: 'COLLISION',
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white54,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(barLeft, barTop - 16));

    // Background
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
      const Radius.circular(7),
    );
    canvas.drawRRect(bgRect, Paint()..color = const Color(0xFF1A1A2E));
    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = const Color(0xFF333355)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Fill
    if (progress > 0) {
      final fillWidth = barWidth * progress.clamp(0.0, 1.0);
      final fillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, barTop, fillWidth, barHeight),
        const Radius.circular(7),
      );
      final fillPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(barLeft, barTop),
          Offset(barLeft + fillWidth, barTop),
          [const Color(0xFF4FC3F7), const Color(0xFFFFFFFF)],
        );
      canvas.drawRRect(fillRect, fillPaint);

      // Glow on leading edge
      if (progress > 0.05) {
        canvas.drawCircle(
          Offset(barLeft + fillWidth, barTop + barHeight / 2),
          6,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    }
  }

  void _drawFundingCounter(Canvas canvas, Size size) {
    final text = '\$$totalFunding for potato research';
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: 'Avenir',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE19816),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width - tp.width - 16, 14));
  }

  void _drawTimer(Canvas canvas, Size size) {
    final remaining = (gameDuration - elapsed).clamp(0.0, gameDuration);
    final secs = remaining.ceil();
    final timerColor = secs <= 10 ? const Color(0xFFFF1744) : Colors.white54;
    final tp = TextPainter(
      text: TextSpan(
        text: '${secs}s',
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: timerColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, const Offset(16, 14));
  }

  void _drawDebris(Canvas canvas) {
    for (final d in debris) {
      final a = d.life.clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(d.x, d.y),
        d.radius * a,
        Paint()..color = d.color.withValues(alpha: a * 0.8),
      );
    }
  }

  void _drawPopups(Canvas canvas, Size size) {
    for (final p in popups) {
      final alpha = (1.0 - p.age / 2.0).clamp(0.0, 1.0);
      final yPos = size.height * 0.35 + p.y;
      final tp = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFE19816).withValues(alpha: alpha),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((size.width - tp.width) / 2, yPos));
    }
  }

  void _drawLevelText(Canvas canvas, Size size) {
    final alpha = (1.0 - levelTextAge / 2.0).clamp(0.0, 1.0);
    final scale = 1.0 + levelTextAge * 0.3;
    final tp = TextPainter(
      text: TextSpan(
        text: levelText,
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 28 * scale,
          fontWeight: FontWeight.w900,
          color: Colors.white.withValues(alpha: alpha),
          letterSpacing: 4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, center.dy - tp.height / 2),
    );
  }

  void _drawInstructions(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: 'TAP to accelerate \u2022 Keep speed in the GREEN zone',
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 13,
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height - 36));
  }

  void _drawGameOver(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF0A0A14));

    // Title
    final title = TextPainter(
      text: const TextSpan(
        text: 'RESEARCH COMPLETE',
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: Color(0xFFE19816),
          letterSpacing: 3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    title.paint(
        canvas, Offset((size.width - title.width) / 2, size.height * 0.2));

    // Stats
    final stats = [
      'Total Funding Raised: \$$totalFunding',
      'Collisions Achieved: $collisions',
      'Highest Level: $level',
    ];
    for (int i = 0; i < stats.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: stats[i],
          style: const TextStyle(
            fontFamily: 'Avenir',
            fontSize: 18,
            color: Colors.white70,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset((size.width - tp.width) / 2, size.height * 0.35 + i * 36));
    }

    // Restart button
    const btnWidth = 260.0;
    const btnHeight = 50.0;
    final btnRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.65),
        width: btnWidth,
        height: btnHeight,
      ),
      const Radius.circular(25),
    );
    canvas.drawRRect(btnRect, Paint()..color = const Color(0xFFE19816));

    final btnText = TextPainter(
      text: const TextSpan(
        text: 'Fund More Research',
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    btnText.paint(
      canvas,
      Offset((size.width - btnText.width) / 2,
          size.height * 0.65 - btnText.height / 2),
    );

    // Potato accent
    final potatoLabel = TextPainter(
      text: const TextSpan(
        text: 'Potato Particle Collider',
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 14,
          color: Colors.white24,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    potatoLabel.paint(canvas,
        Offset((size.width - potatoLabel.width) / 2, size.height * 0.8));
  }

  @override
  bool shouldRepaint(covariant _AcceleratorPainter old) => true;
}

// ---------------------------------------------------------------------------
// Existing games below (kept for other scales)
// ---------------------------------------------------------------------------

/// Tap the void to create particles of light
class _TapToCreateGame extends StatefulWidget {
  const _TapToCreateGame();
  @override
  State<_TapToCreateGame> createState() => _TapToCreateGameState();
}

class _TapToCreateGameState extends State<_TapToCreateGame> {
  final List<_Particle> _particles = [];
  int _score = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        setState(() {
          _score++;
          final rng = Random();
          for (int i = 0; i < 5; i++) {
            _particles.add(_Particle(
              x: details.localPosition.dx + (rng.nextDouble() - 0.5) * 30,
              y: details.localPosition.dy + (rng.nextDouble() - 0.5) * 30,
              vx: (rng.nextDouble() - 0.5) * 80,
              vy: (rng.nextDouble() - 0.5) * 80 - 30,
              life: 1.0,
              color: HSVColor.fromAHSV(1, rng.nextDouble() * 360, 0.7, 0.9).toColor(),
            ));
          }
        });
        _tickParticles();
      },
      child: Stack(
        children: [
          // Dark void
          Container(color: Colors.black),
          // Particles
          ...(_particles.where((p) => p.life > 0)).map((p) => Positioned(
            left: p.x - 3,
            top: p.y - 3,
            child: Container(
              width: 6 * p.life,
              height: 6 * p.life,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.color.withValues(alpha: p.life * 0.7),
              ),
            ),
          )),
          // Score
          Positioned(
            bottom: 40,
            left: 0, right: 0,
            child: Center(
              child: Text(
                '$_score created',
                style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white38),
              ),
            ),
          ),
          if (_score == 0)
            const Center(
              child: Text('Tap the void', style: TextStyle(fontFamily: 'Avenir', fontSize: 20, color: Colors.white24)),
            ),
        ],
      ),
    );
  }

  void _tickParticles() async {
    for (int frame = 0; frame < 30; frame++) {
      await Future.delayed(const Duration(milliseconds: 33));
      if (!mounted) return;
      setState(() {
        for (final p in _particles) {
          p.x += p.vx * 0.033;
          p.y += p.vy * 0.033;
          p.vy += 20 * 0.033; // gravity
          p.life -= 0.033;
        }
        _particles.removeWhere((p) => p.life <= 0);
      });
    }
  }
}

/// Catch flashing targets before they disappear
class _CatchTheFlashGame extends StatefulWidget {
  const _CatchTheFlashGame();
  @override
  State<_CatchTheFlashGame> createState() => _CatchTheFlashGameState();
}

class _CatchTheFlashGameState extends State<_CatchTheFlashGame> {
  final Random _rng = Random();
  int _score = 0;
  int _missed = 0;
  double _targetX = 0.5, _targetY = 0.5;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _spawnTarget();
  }

  void _spawnTarget() {
    setState(() {
      _targetX = 0.1 + _rng.nextDouble() * 0.8;
      _targetY = 0.1 + _rng.nextDouble() * 0.8;
      _visible = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_visible) {
        setState(() { _missed++; _visible = false; });
        Future.delayed(const Duration(milliseconds: 300), () { if (mounted) _spawnTarget(); });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return GestureDetector(
        onTapDown: (details) {
          if (!_visible) return;
          final tx = _targetX * constraints.maxWidth;
          final ty = _targetY * constraints.maxHeight;
          final dist = (details.localPosition - Offset(tx, ty)).distance;
          if (dist < 35) {
            setState(() { _score++; _visible = false; });
            Future.delayed(const Duration(milliseconds: 200), () { if (mounted) _spawnTarget(); });
          }
        },
        child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              if (_visible)
                Positioned(
                  left: _targetX * constraints.maxWidth - 20,
                  top: _targetY * constraints.maxHeight - 20,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.touch_app, color: Colors.white38, size: 20),
                  ),
                ),
              Positioned(
                bottom: 40, left: 0, right: 0,
                child: Center(
                  child: Text(
                    'Caught: $_score  Missed: $_missed',
                    style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white38),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Keep ecosystem bars balanced by tapping the low ones
class _BalanceGame extends StatefulWidget {
  const _BalanceGame();
  @override
  State<_BalanceGame> createState() => _BalanceGameState();
}

class _BalanceGameState extends State<_BalanceGame> {
  final _labels = ['Water', 'Sun', 'Soil', 'Air'];
  late List<double> _levels;
  int _score = 0;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _levels = [0.7, 0.6, 0.8, 0.5];
    _tick();
  }

  void _tick() async {
    while (mounted && !_gameOver) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() {
        final rng = Random();
        for (int i = 0; i < _levels.length; i++) {
          _levels[i] -= 0.01 + rng.nextDouble() * 0.02;
          if (_levels[i] <= 0) { _gameOver = true; return; }
          if (_levels[i] > 1) _levels[i] = 1;
        }
        _score++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _gameOver ? 'Game Over! Score: $_score' : 'Keep everything balanced',
            style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white54),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_levels.length, (i) {
                return GestureDetector(
                  onTap: () {
                    if (_gameOver) return;
                    setState(() { _levels[i] = (_levels[i] + 0.2).clamp(0.0, 1.0); });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(_labels[i], style: const TextStyle(fontFamily: 'Avenir', fontSize: 11, color: Colors.white38)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          width: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: _levels[i],
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(7),
                                  color: Color.lerp(Colors.red, Colors.green, _levels[i])!.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          if (_gameOver)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: GestureDetector(
                onTap: () => setState(() { _levels = [0.7, 0.6, 0.8, 0.5]; _score = 0; _gameOver = false; _tick(); }),
                child: const Text('Tap to retry', style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white54)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Buy low, sell high — simple market game
class _MarketTraderGame extends StatefulWidget {
  const _MarketTraderGame();
  @override
  State<_MarketTraderGame> createState() => _MarketTraderGameState();
}

class _MarketTraderGameState extends State<_MarketTraderGame> {
  double _price = 50;
  double _cash = 100;
  int _potatoes = 0;
  final List<double> _history = [50];

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() async {
    final rng = Random();
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _price += (rng.nextDouble() - 0.48) * 8; // slight upward bias
        _price = _price.clamp(5, 200);
        _history.add(_price);
        if (_history.length > 40) _history.removeAt(0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Price chart
          Expanded(
            child: CustomPaint(
              painter: _ChartPainter(_history),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 16),
          Text('\$${_price.toStringAsFixed(1)}/potato', style: const TextStyle(fontFamily: 'Avenir', fontSize: 20, color: Colors.white70)),
          const SizedBox(height: 8),
          Text('Cash: \$${_cash.toStringAsFixed(0)}  Potatoes: $_potatoes', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white38)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _cash >= _price ? () => setState(() { _cash -= _price; _potatoes++; }) : null,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                child: const Text('Buy', style: TextStyle(fontFamily: 'Avenir')),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _potatoes > 0 ? () => setState(() { _cash += _price; _potatoes--; }) : null,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
                child: const Text('Sell', style: TextStyle(fontFamily: 'Avenir')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Net worth: \$${(_cash + _potatoes * _price).toStringAsFixed(0)}', style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Color(0xFFE19816))),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> data;
  _ChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final minV = data.reduce(min) - 5;
    final maxV = data.reduce(max) + 5;
    final range = maxV - minV;
    if (range <= 0) return;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - ((data[i] - minV) / range) * size.height;
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    canvas.drawPath(path, Paint()..color = const Color(0xFFE19816)..strokeWidth = 2..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => true;
}

/// Binary choice branching
class _ChoosePathGame extends StatefulWidget {
  const _ChoosePathGame();
  @override
  State<_ChoosePathGame> createState() => _ChoosePathGameState();
}

class _ChoosePathGameState extends State<_ChoosePathGame> {
  final List<String> _choices = ['You exist.'];
  int _depth = 0;

  final _options = [
    ['Look left', 'Look right'],
    ['Step forward', 'Stay still'],
    ['Reach out', 'Pull back'],
    ['Speak', 'Listen'],
    ['Create', 'Observe'],
    ['Remember', 'Forget'],
    ['Accept', 'Question'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // History
          Expanded(
            child: ListView(
              children: _choices.map((c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(c, style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white.withValues(alpha: 0.5))),
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),
          if (_depth < _options.length) ...[
            const Text('Choose:', style: TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _choiceButton(_options[_depth][0]),
                const SizedBox(width: 16),
                _choiceButton(_options[_depth][1]),
              ],
            ),
          ] else
            const Text('Every choice created a universe.\nYou are in this one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _choiceButton(String label) {
    return GestureDetector(
      onTap: () => setState(() { _choices.add('You chose: $label'); _depth++; }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
          color: Colors.white.withValues(alpha: 0.05),
        ),
        child: Text(label, style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white70)),
      ),
    );
  }
}

/// Counter that never ends
class _CountForeverGame extends StatefulWidget {
  const _CountForeverGame();
  @override
  State<_CountForeverGame> createState() => _CountForeverGameState();
}

class _CountForeverGameState extends State<_CountForeverGame> {
  BigInt _count = BigInt.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _count += BigInt.one),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$_count',
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: _count < BigInt.from(1000) ? 48 : 28,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Tap to count.\nYou will never finish.', textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white24)),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  double x, y, vx, vy, life;
  Color color;
  _Particle({required this.x, required this.y, required this.vx, required this.vy, required this.life, required this.color});
}


// ---------------------------------------------------------------------------
// LightSpeedGame — "Light Speed"
// Side-scrolling photon dodging gravity wells. Distance = score in light-years.
// ---------------------------------------------------------------------------

class _GravityObstacle {
  double x, y, radius, mass;
  Color color;
  _GravityObstacle({required this.x, required this.y, required this.radius, required this.mass, required this.color});
}

class LightSpeedGame extends StatefulWidget {
  const LightSpeedGame({Key? key}) : super(key: key);
  @override
  State<LightSpeedGame> createState() => _LightSpeedGameState();
}

class _LightSpeedGameState extends State<LightSpeedGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rng = Random();

  double _photonY = 0.5; // normalized Y position
  double _photonVy = 0;
  double _distance = 0; // light-years
  double _speed = 180; // pixels/sec scrolling
  bool _gameOver = false;
  double _lastTime = 0;
  Size _size = Size.zero;

  final List<_GravityObstacle> _obstacles = [];
  double _spawnTimer = 0;
  final List<Offset> _trail = [];
  final List<_Particle> _particles = [];

  // Star field
  final List<Offset> _stars = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)
      ..forward();
    _lastTime = _now();
    // Pre-generate stars
    for (int i = 0; i < 60; i++) {
      _stars.add(Offset(_rng.nextDouble(), _rng.nextDouble()));
    }
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _tick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;
    if (_gameOver || _size == Size.zero) return;

    setState(() {
      _distance += dt * _speed * 0.01; // Convert to light-years-ish
      _speed += dt * 3; // Gradually speed up

      // Photon physics — damping
      _photonVy *= (1 - 2 * dt);
      _photonY += _photonVy * dt;

      // Apply gravity from obstacles
      final photonX = 0.15; // fixed X position on screen (normalized)
      for (final obs in _obstacles) {
        final dx = obs.x - photonX;
        final dy = obs.y - _photonY;
        final dist = sqrt(dx * dx + dy * dy).clamp(0.02, 2.0);
        final force = obs.mass * 0.003 / (dist * dist);
        _photonVy += dy / dist * force;
      }

      // Bounds
      if (_photonY < 0.02 || _photonY > 0.98) {
        _photonY = _photonY.clamp(0.02, 0.98);
        _photonVy = 0;
      }

      // Trail
      _trail.add(Offset(photonX, _photonY));
      if (_trail.length > 30) _trail.removeAt(0);

      // Move obstacles
      for (final obs in _obstacles) {
        obs.x -= _speed / _size.width * dt;
      }
      _obstacles.removeWhere((o) => o.x < -0.15);

      // Collision check
      for (final obs in _obstacles) {
        final dx = obs.x - photonX;
        final dy = obs.y - _photonY;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < obs.radius + 0.02) {
          _gameOver = true;
          for (int i = 0; i < 15; i++) {
            final a = _rng.nextDouble() * 2 * pi;
            _particles.add(_Particle(
              x: photonX, y: _photonY,
              vx: cos(a) * 0.3, vy: sin(a) * 0.3,
              life: 0.6, color: Colors.yellowAccent,
            ));
          }
          break;
        }
      }

      // Spawn obstacles
      _spawnTimer -= dt;
      if (_spawnTimer <= 0) {
        _spawnTimer = 0.8 + _rng.nextDouble() * 1.2;
        final isBH = _rng.nextDouble() < 0.3; // black hole vs star
        _obstacles.add(_GravityObstacle(
          x: 1.2,
          y: 0.1 + _rng.nextDouble() * 0.8,
          radius: isBH ? 0.03 + _rng.nextDouble() * 0.02 : 0.04 + _rng.nextDouble() * 0.04,
          mass: isBH ? 1.5 + _rng.nextDouble() : 0.5 + _rng.nextDouble() * 0.5,
          color: isBH ? const Color(0xFF1A1A2E) : Colors.amber,
        ));
      }

      // Move stars
      for (int i = 0; i < _stars.length; i++) {
        var sx = _stars[i].dx - _speed * 0.0002 * dt;
        if (sx < 0) sx += 1;
        _stars[i] = Offset(sx, _stars[i].dy);
      }

      // Particles
      for (final p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt;
      }
      _particles.removeWhere((p) => p.life <= 0);
    });
  }

  void _restart() {
    setState(() {
      _photonY = 0.5;
      _photonVy = 0;
      _distance = 0;
      _speed = 180;
      _gameOver = false;
      _obstacles.clear();
      _trail.clear();
      _particles.clear();
      _spawnTimer = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _size = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        onPanUpdate: (d) {
          if (_gameOver) return;
          _photonVy += d.delta.dy / _size.height * -3;
        },
        onTapDown: (_) {
          if (_gameOver) _restart();
        },
        child: Container(
          color: Colors.black,
          child: CustomPaint(
            painter: _LightSpeedPainter(
              photonY: _photonY, trail: _trail,
              obstacles: _obstacles, stars: _stars,
              particles: _particles, distance: _distance,
              gameOver: _gameOver,
            ),
            child: Stack(
              children: [
                // Distance HUD
                Positioned(
                  top: 8, left: 0, right: 0,
                  child: Center(
                    child: Text(
                      '${_distance.toStringAsFixed(1)} light-years',
                      style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.yellowAccent),
                    ),
                  ),
                ),
                if (_gameOver)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Absorbed!', style: TextStyle(fontFamily: 'Avenir', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                        const SizedBox(height: 8),
                        Text('Distance: ${_distance.toStringAsFixed(1)} ly', style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white54)),
                        const SizedBox(height: 12),
                        const Text('Tap to restart', style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white30)),
                      ],
                    ),
                  ),
                if (!_gameOver && _distance < 1)
                  Positioned(
                    bottom: 20, left: 0, right: 0,
                    child: const Center(child: Text('Swipe up/down to dodge gravity wells', style: TextStyle(fontFamily: 'Avenir', fontSize: 12, color: Color(0x33FFFFFF)))),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _LightSpeedPainter extends CustomPainter {
  final double photonY;
  final List<Offset> trail;
  final List<_GravityObstacle> obstacles;
  final List<Offset> stars;
  final List<_Particle> particles;
  final double distance;
  final bool gameOver;

  _LightSpeedPainter({
    required this.photonY, required this.trail,
    required this.obstacles, required this.stars,
    required this.particles, required this.distance,
    required this.gameOver,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);

    // Stars
    for (final s in stars) {
      canvas.drawCircle(
        Offset(s.dx * size.width, s.dy * size.height),
        0.5 + (s.dx * 3 % 1) * 0.8,
        Paint()..color = Colors.white.withValues(alpha: 0.1 + (s.dy * 5 % 1) * 0.15),
      );
    }

    // Obstacles
    for (final obs in obstacles) {
      final ox = obs.x * size.width;
      final oy = obs.y * size.height;
      final or2 = obs.radius * size.width;
      final isBH = obs.color == const Color(0xFF1A1A2E);
      if (isBH) {
        // Black hole
        canvas.drawCircle(Offset(ox, oy), or2 + 12, Paint()..color = Colors.deepPurple.withValues(alpha: 0.08));
        canvas.drawCircle(Offset(ox, oy), or2 + 6, Paint()..color = Colors.deepPurple.withValues(alpha: 0.12));
        canvas.drawCircle(Offset(ox, oy), or2, Paint()..color = const Color(0xFF0D0D1A));
        canvas.drawCircle(Offset(ox, oy), or2, Paint()
          ..color = Colors.deepPurple.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke..strokeWidth = 1.5);
      } else {
        // Star
        final glow = Paint()..shader = ui.Gradient.radial(
          Offset(ox, oy), or2 * 2.5,
          [obs.color.withValues(alpha: 0.2), Colors.transparent],
        );
        canvas.drawCircle(Offset(ox, oy), or2 * 2.5, glow);
        canvas.drawCircle(Offset(ox, oy), or2, Paint()..color = obs.color.withValues(alpha: 0.8));
        canvas.drawCircle(Offset(ox, oy), or2 * 0.4, Paint()..color = Colors.white.withValues(alpha: 0.5));
      }
    }

    // Trail
    final photonX = 0.15 * size.width;
    if (trail.length > 1) {
      for (int i = 1; i < trail.length; i++) {
        final alpha = i / trail.length * 0.5;
        canvas.drawLine(
          Offset(photonX - (trail.length - i) * 2, trail[i - 1].dy * size.height),
          Offset(photonX - (trail.length - i - 1) * 2, trail[i].dy * size.height),
          Paint()..color = Colors.yellowAccent.withValues(alpha: alpha)..strokeWidth = 2,
        );
      }
    }

    // Photon
    if (!gameOver) {
      final py = photonY * size.height;
      canvas.drawCircle(Offset(photonX, py), 10, Paint()..color = Colors.yellowAccent.withValues(alpha: 0.15));
      canvas.drawCircle(Offset(photonX, py), 5, Paint()..color = Colors.yellowAccent.withValues(alpha: 0.6));
      canvas.drawCircle(Offset(photonX, py), 2.5, Paint()..color = Colors.white.withValues(alpha: 0.9));
    }

    // Particles
    for (final p in particles) {
      if (p.life > 0) {
        canvas.drawCircle(
          Offset(p.x * size.width, p.y * size.height), 2.5,
          Paint()..color = p.color.withValues(alpha: (p.life / 0.6).clamp(0.0, 1.0)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LightSpeedPainter old) => true;
}
