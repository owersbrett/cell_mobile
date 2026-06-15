import 'dart:math';

import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_events.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// PLAY entry: host a room (you're given a code) or join one with a code.
///
/// The networking layer isn't built yet, so the code is generated locally and
/// both paths drop into the existing pass-and-play party. The lobby is the
/// seam online multiplayer will plug into later.
class PlayLobbyPage extends StatefulWidget {
  const PlayLobbyPage({Key? key}) : super(key: key);

  @override
  State<PlayLobbyPage> createState() => _PlayLobbyPageState();
}

class _PlayLobbyPageState extends State<PlayLobbyPage> {
  late final String _hostCode;
  final TextEditingController _joinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _hostCode = _generateCode();
  }

  static String _generateCode() {
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ'; // no I/O to avoid confusion
    final rng = Random();
    return List.generate(4, (_) => letters[rng.nextInt(letters.length)]).join();
  }

  @override
  void dispose() {
    _joinController.dispose();
    super.dispose();
  }

  void _enterGame() =>
      context.read<NavigationBloc>().add(NavigateToScreen(AppScreen.party));

  void _back() =>
      context.read<NavigationBloc>().add(NavigateToScreen(AppScreen.splash));

  @override
  Widget build(BuildContext context) {
    final canJoin = _joinController.text.trim().length >= 4;
    return Scaffold(
      backgroundColor: Potatuhs.inkDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: _back,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: Potatuhs.surface(
                        fill: Potatuhs.inkPanel,
                        radius: 12,
                        borderColor: Colors.white12,
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Potatuhs.textSecondary, size: 20),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const Spacer(flex: 2),
              Center(child: Text('PLAY', style: Potatuhs.display(size: 44))),
              const SizedBox(height: 6),
              Center(
                child: Text('Host a room, or join a friend',
                    style: Potatuhs.body(
                        size: 14, color: Potatuhs.textSecondary)),
              ),
              const Spacer(flex: 2),

              // ── Host ──
              _LobbyCard(
                accent: Potatuhs.gold,
                label: 'HOST A ROOM',
                child: Column(
                  children: [
                    Text('YOUR ROOM CODE',
                        style: Potatuhs.label(color: Potatuhs.textFaint)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _hostCode));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          backgroundColor: Potatuhs.inkPanel,
                          duration: const Duration(seconds: 1),
                          content: Text('Code copied',
                              style: Potatuhs.body(color: Potatuhs.gold)),
                        ));
                      },
                      child: Text(
                        _hostCode,
                        style: Potatuhs.display(size: 46, color: Potatuhs.gold)
                            .copyWith(letterSpacing: 10),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: PotatuhsButton(
                        label: 'START GAME',
                        display: true,
                        icon: Icons.play_arrow,
                        onTap: _enterGame,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Join ──
              _LobbyCard(
                accent: Potatuhs.airForce,
                label: 'JOIN A ROOM',
                child: Column(
                  children: [
                    TextField(
                      controller: _joinController,
                      onChanged: (_) => setState(() {}),
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 4,
                      inputFormatters: [
                        UpperCaseTextFormatter(),
                        FilteringTextInputFormatter.allow(RegExp('[A-Z]')),
                      ],
                      style: Potatuhs.display(size: 30, color: Potatuhs.textPrimary)
                          .copyWith(letterSpacing: 8),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'CODE',
                        hintStyle: Potatuhs.display(
                            size: 30, color: Potatuhs.textFaint),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Colors.white24, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: Potatuhs.airForce, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: PotatuhsButton(
                        label: 'JOIN',
                        display: true,
                        icon: Icons.login,
                        fill: canJoin ? Potatuhs.airForce : Potatuhs.inkPanel,
                        textColor:
                            canJoin ? Potatuhs.ink : Potatuhs.textFaint,
                        glowColor: canJoin
                            ? Potatuhs.airForce
                            : Colors.transparent,
                        borderColor:
                            canJoin ? Potatuhs.ink : Colors.white12,
                        onTap: canJoin ? _enterGame : () {},
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              Text(
                'Online rooms are on the way — for now, games are '
                'pass-and-play on this device.',
                textAlign: TextAlign.center,
                style: Potatuhs.body(size: 12, color: Potatuhs.textFaint),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _LobbyCard extends StatelessWidget {
  final Color accent;
  final String label;
  final Widget child;
  const _LobbyCard(
      {required this.accent, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: Potatuhs.surface(
        fill: Potatuhs.inkPanel,
        borderColor: accent.withValues(alpha: 0.5),
        radius: 20,
        glowColor: accent,
        glowStrength: 0.18,
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(label, style: Potatuhs.label(color: accent)),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Forces typed room codes to uppercase as you go.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
