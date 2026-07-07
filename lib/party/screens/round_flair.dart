import 'package:cell_mobile/party/party_controller.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:flutter/material.dart';

/// The per-round flair beat (PARTY_CINEMATIC_SPEC §5): a short cutscene
/// between the round ceremony/wheel and the next board turn. Round 2 is the
/// ghost debut; later rounds rotate banter about the mini-game just played,
/// ghost sightings, and Shack lore. Content is a pure function of shared
/// controller state, so every client sees the same beat — pacing is local.
class RoundFlairScreen extends StatefulWidget {
  final PartyController controller;
  final VoidCallback onDone;

  const RoundFlairScreen({
    super.key,
    required this.controller,
    required this.onDone,
  });

  @override
  State<RoundFlairScreen> createState() => _RoundFlairScreenState();
}

/// (speaker, line) beats for the current round. Exposed for tests.
List<(String, String)> flairBeatsFor(PartyController c) {
  if (c.round == 2) {
    return const [
      ('RUSS', 'uhhh… did you hear that?'),
      (
        'BUTTER',
        'The ghosts from the Potato Shack are on the loose. They drift '
            'where they please, and they take what glitters. '
            "Don't worry about it."
      ),
    ];
  }
  final game = c.currentSpec?.name ?? 'that last one';
  final winners = [
    for (final s in c.standings)
      if (s.rank == 0) s.player.name
  ];
  final winner = winners.isEmpty ? 'somebody' : winners.join(' & ');
  switch (c.round % 4) {
    case 0:
      return [
        (
          'BUTTER',
          '$winner took $game. We were all watching. '
              "We're always watching."
        ),
      ];
    case 1:
      return [
        (
          'RUSS',
          'uhhh… the ghosts are getting bolder out there. Somebody should '
              'hold their diamonds a little tighter.'
        ),
      ];
    case 2:
      return [
        (
          'BUTTER',
          'The Shack remembers $game. The Shack remembers everything.'
        ),
      ];
    default:
      return [
        ('RUSS', '…did the board just move? uhhh. Roll the dice.'),
      ];
  }
}

class _RoundFlairScreenState extends State<RoundFlairScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beat; // one run per beat, auto-advances
  late final List<(String, String)> _beats;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _beats = flairBeatsFor(widget.controller);
    _beat = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4600))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _advance();
      })
      ..forward();
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  void _advance() {
    if (!mounted) return;
    if (_index >= _beats.length - 1) {
      widget.onDone();
    } else {
      setState(() => _index++);
      _beat.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (speaker, line) = _beats[_index];
    final isGhostDebut = widget.controller.round == 2;
    final accent = isGhostDebut ? const Color(0xFF9FB7CE) : Potatuhs.gold;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _advance,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ROUND ${widget.controller.round}',
                  textAlign: TextAlign.center,
                  style: Potatuhs.body(size: 12, color: Potatuhs.textSecondary)
                      .copyWith(letterSpacing: 4),
                ),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: _beat,
                  builder: (context, child) {
                    final a = Curves.easeOut
                        .transform((_beat.value * 6).clamp(0.0, 1.0));
                    return Opacity(
                      opacity: a,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - a)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Potatuhs.inkPanel,
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: accent.withValues(alpha: 0.45)),
                      boxShadow:
                          Potatuhs.glow(accent, strength: 0.25, blur: 24),
                    ),
                    child: Column(
                      children: [
                        Text(
                          speaker,
                          style: Potatuhs.body(size: 11, color: accent)
                              .copyWith(letterSpacing: 3),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          line,
                          textAlign: TextAlign.center,
                          style: Potatuhs.body(
                              size: 16, color: Potatuhs.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'TAP TO CONTINUE',
                  textAlign: TextAlign.center,
                  style:
                      Potatuhs.body(size: 11, color: Potatuhs.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
