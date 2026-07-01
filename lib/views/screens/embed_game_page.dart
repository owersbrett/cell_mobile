import 'package:flutter/material.dart';

import 'package:cell_mobile/games/mini_game_host.dart';
import 'package:cell_mobile/games/mini_game_registry.dart';

/// Chromeless single-game host for iframe embedding at `/{slug}`.
///
/// Renders exactly ONE game (solo, no opponents) with no splash, overview, or
/// app navigation. Exiting the game replays it — the embed is self-contained.
///
/// This screen is reached ONLY when the app is opened at a game deep-link URL
/// (see [GameSlug.embedSpecIdFromUrl]); the normal in-app flow never routes
/// here, so existing navigation is untouched.
class EmbedGamePage extends StatefulWidget {
  final String specId;
  const EmbedGamePage({Key? key, required this.specId}) : super(key: key);

  @override
  State<EmbedGamePage> createState() => _EmbedGamePageState();
}

class _EmbedGamePageState extends State<EmbedGamePage> {
  int _replay = 0;

  @override
  Widget build(BuildContext context) {
    final spec = MiniGameRegistry.byId(widget.specId);
    if (spec == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Game "${widget.specId}" not found',
            style: const TextStyle(fontFamily: 'Avenir', color: Colors.white54),
          ),
        ),
      );
    }
    return MiniGameHost(
      // Remount on replay so exiting restarts a fresh round.
      key: ValueKey('embed-${widget.specId}-$_replay'),
      spec: spec,
      // No app to exit to in a kiosk embed — restart the game instead.
      onExit: () => setState(() => _replay++),
      opponentCount: 0,
      disruption: false,
    );
  }
}
