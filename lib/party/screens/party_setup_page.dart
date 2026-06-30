import 'package:flutter/material.dart';

import '../../auth_profile.dart';
import '../party_models.dart';

const _kFont = 'Avenir';
const _kAccent = Color(0xFFAADD44);

/// Match configuration: format, rounds, player names. Pure UI — hands the
/// chosen config to [onStart].
class PartySetupView extends StatefulWidget {
  final void Function(PartyMode mode, int rounds, List<String> names) onStart;
  final VoidCallback onExit;

  const PartySetupView({Key? key, required this.onStart, required this.onExit})
      : super(key: key);

  @override
  State<PartySetupView> createState() => _PartySetupViewState();
}

class _PartySetupViewState extends State<PartySetupView> {
  PartyMode _mode = PartyMode.ffa4;
  int _rounds = 7;
  late final List<String> _names =
      kCharacters.map((c) => c.name).toList();

  // The 7-round match ends on a BOSS round; 5 / 10 flank it for shorter/longer.
  static const _roundCounts = [5, 7, 10];
  static const _roundLabels = ['QUICK', 'STANDARD', 'MARATHON'];

  /// Avatar for player [i]: the signed-in player (slot 0) uses their custom
  /// VIPotato; others use their character sticker; initial as last resort.
  Widget _avatar(int i, PartyCharacter character) {
    if (i == 0 && AuthProfile.hasAvatar) {
      return Image.network(
        AuthProfile.avatarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _sticker(i, character),
      );
    }
    return _sticker(i, character);
  }

  Widget _sticker(int i, PartyCharacter character) {
    if (character.asset != null) {
      return Image.asset(
        character.asset!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initial(i),
      );
    }
    return _initial(i);
  }

  Widget _initial(int i) => Center(
        child: Text(
          _names[i].isEmpty ? '?' : _names[i][0].toUpperCase(),
          style: const TextStyle(
              fontFamily: _kFont,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white),
        ),
      );

  Future<void> _rename(int index) async {
    final controller = TextEditingController(text: _names[index]);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Player name',
            style: TextStyle(fontFamily: _kFont, color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 12,
          style: const TextStyle(fontFamily: _kFont, color: Colors.white),
          decoration: const InputDecoration(counterStyle:
              TextStyle(color: Colors.white38)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _names[index] = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _mode.playerCount;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: widget.onExit,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0x88000000),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white70, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'EXPLORE THE CELL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 3,
                  shadows: [Shadow(color: _kAccent, blurRadius: 16)],
                ),
              ),
              const Text(
                'PARTY MODE — PASS & PLAY',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 12,
                    letterSpacing: 2,
                    color: _kAccent),
              ),
              const SizedBox(height: 20),
              _sectionLabel('FORMAT'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in PartyMode.values)
                    _choiceChip(
                      label: m.label,
                      selected: _mode == m,
                      onTap: () => setState(() => _mode = m),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              _sectionLabel('ROUNDS'),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < _roundCounts.length; i++) ...[
                    Expanded(
                      child: _choiceChip(
                        label: '${_roundLabels[i]} · ${_roundCounts[i]}',
                        selected: _rounds == _roundCounts[i],
                        onTap: () =>
                            setState(() => _rounds = _roundCounts[i]),
                        center: true,
                      ),
                    ),
                    if (i < _roundCounts.length - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              _sectionLabel('PLAYERS — tap to rename'),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: count,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final character = kCharacters[i];
                    final color = character.color;
                    final team = _mode.teamOf(i);
                    return GestureDetector(
                      onTap: () => _rename(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: color.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            // Avatar: the signed-in player (slot 0) shows their
                            // custom VIPotato; everyone else shows their
                            // character sticker; initial as last-resort.
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color.withValues(alpha: 0.25),
                                border: Border.all(
                                    color: color.withValues(alpha: 0.7),
                                    width: 1.5),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _avatar(i, character),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _names[i],
                                style: const TextStyle(
                                    fontFamily: _kFont,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                            if (_mode.isTeams)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: kTeamColors[team]
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: kTeamColors[team]),
                                ),
                                child: Text(
                                  kTeamNames[team],
                                  style: TextStyle(
                                      fontFamily: _kFont,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: kTeamColors[team]),
                                ),
                              ),
                            const SizedBox(width: 6),
                            const Icon(Icons.edit,
                                color: Colors.white24, size: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => widget.onStart(
                    _mode, _rounds, _names.sublist(0, count)),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: _kAccent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: _kAccent.withValues(alpha: 0.45),
                          blurRadius: 18)
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'START GAME',
                      style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontFamily: _kFont,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white54),
      );

  Widget _choiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool center = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? _kAccent.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? _kAccent : Colors.white24,
              width: selected ? 1.5 : 1),
        ),
        child: Text(
          label,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: selected ? _kAccent : Colors.white70,
          ),
        ),
      ),
    );
  }
}
