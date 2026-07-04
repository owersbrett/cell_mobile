import 'package:flutter/material.dart';

import '../../../games/attract/auto_tapper.dart';
import '../../../games/play_config.dart';
import '../../../party/maps/game_map.dart';
import '../../../party/screens/party_page.dart';
import '../../../theme/potatuhs.dart';

/// Attract mode — a full 4-player party game playing itself on one board, for
/// build-in-public b-roll. Wraps [PartyFlowPage] in autopilot: it auto-starts
/// the chosen map, drives every decision hands-free, and restarts on game-over.
///
/// A REAL screen tap (told apart from the bot's synthetic minigame taps by
/// [kAutoTapKind]) pauses the autopilot in place — the live game is handed to
/// you — and a RESUME bar appears. RESUME picks the board back up where it was.
class AttractMapPage extends StatefulWidget {
  final String mapId;
  const AttractMapPage({super.key, required this.mapId});

  @override
  State<AttractMapPage> createState() => _AttractMapPageState();
}

class _AttractMapPageState extends State<AttractMapPage> {
  bool _running = true;

  @override
  void initState() {
    super.initState();
    // PartyFlowPage reads this when it auto-starts (in its own initState).
    PlayConfig.mapId = widget.mapId;
  }

  void _eject() => setState(() => _running = false);
  void _resume() => setState(() => _running = true);

  @override
  Widget build(BuildContext context) {
    final map = gameMapById(widget.mapId);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        onPointerDown: (e) {
          if (_running && e.kind != kAutoTapKind) _eject();
        },
        child: Stack(
          children: [
            PartyFlowPage(
              autoPilot: _running,
              onExit: () => Navigator.of(context).maybePop(),
            ),
            // Bottom-right, clear of the HUD. Hidden while paused (paused bar).
            if (_running)
              Positioned(
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10, bottom: 10),
                    child: _chip(map),
                  ),
                ),
              ),
            if (!_running) _pausedBar(),
          ],
        ),
      ),
    );
  }

  Widget _chip(GameMap map) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Potatuhs.gold.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_running ? Icons.smart_toy : Icons.pause,
              size: 13, color: Potatuhs.gold),
          const SizedBox(width: 5),
          Text(
            map.name.toUpperCase(),
            style: Potatuhs.body(
                size: 11, weight: FontWeight.w700, color: Potatuhs.gold),
          ),
        ],
      ),
    );
  }

  Widget _pausedBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                const Icon(Icons.pause_circle_filled,
                    size: 18, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AUTOPILOT PAUSED — the game is yours',
                    style: Potatuhs.body(
                        size: 12,
                        weight: FontWeight.w700,
                        color: Colors.white70),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('EXIT'),
                ),
                const SizedBox(width: 4),
                FilledButton.icon(
                  onPressed: _resume,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('RESUME'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
