import 'package:cell_mobile/party/maps/mini_map.dart';
import 'package:cell_mobile/party/party_controller.dart';
import 'package:cell_mobile/party/screens/party_dialogue.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:flutter/material.dart';

/// The per-round flair beat (PARTY_CINEMATIC_SPEC §5): a short cutscene
/// between the round ceremony/wheel and the next board turn. Round 2 is the
/// ghost debut; later rounds rotate banter about the mini-game just played,
/// ghost sightings, and Shack lore. Content is a pure function of shared
/// controller state, so every client sees the same beat — pacing is local.
///
/// The live [MiniMap] anchors every beat: whatever the line is about (the
/// ghosts, the Shack, a winner's token) is PINGED on the board via the beat's
/// [MiniMapEmphasis], so the narration always points at a visible place.
class RoundFlairScreen extends StatefulWidget {
  final PartyController controller;
  final VoidCallback onDone;

  /// ATTRACT only: beats advance themselves when their animation completes.
  /// Everywhere else the beat HOLDS for the tap — TAP-TO-DRIVE LAW
  /// (ORDER_AND_SOLO_SPEC §1, Brett 2026-07-12): no timer advances a dialog.
  final bool auto;

  const RoundFlairScreen({
    super.key,
    required this.controller,
    required this.onDone,
    this.auto = false,
  });

  @override
  State<RoundFlairScreen> createState() => _RoundFlairScreenState();
}

/// (speaker, line, what-to-ping) beats for the current round. Exposed for
/// tests (which read `.$1`/`.$2`; the third field drives the mini-map).
List<(String, String, MiniMapEmphasis)> flairBeatsFor(PartyController c) {
  // The boss debut owns the final round on maps that field one.
  final bosses = c.gameMap?.bosses ?? const [];
  if (c.round == c.totalRounds && bosses.isNotEmpty) {
    final boss = bosses.first;
    return [
      ('RUSS', "uhhh… why'd it get so quiet?", MiniMapEmphasis.none),
      (
        'BUTTER',
        'FINAL ROUND. ${boss.name} runs this one — win it and take a whole '
            'POTATO. Lose it, and it takes one of yours. '
            "We'll be watching. We're always watching.",
        // The showdown converges on the Shack — the anchor everyone races to.
        const MiniMapEmphasis(shack: true),
      ),
    ];
  }
  if (c.round == 2) {
    return const [
      ('RUSS', 'uhhh… did you hear that?', MiniMapEmphasis(ghosts: true)),
      (
        'BUTTER',
        'The ghosts from the Potato Shack are on the loose. They drift '
            'where they please, and they take what glitters. '
            "Don't worry about it.",
        MiniMapEmphasis(ghosts: true, shack: true),
      ),
    ];
  }
  final game = c.currentSpec?.name ?? 'that last one';
  final winners = [
    for (final s in c.standings)
      if (s.rank == 0) s.player.name
  ];
  final winner = winners.isEmpty ? 'somebody' : winners.join(' & ');
  final winnerSeats = {
    for (final s in c.standings)
      if (s.rank == 0) s.player.index
  };
  switch (c.round % 4) {
    case 0:
      return [
        (
          'BUTTER',
          '$winner took $game. We were all watching. '
              "We're always watching.",
          MiniMapEmphasis(players: winnerSeats),
        ),
      ];
    case 1:
      return [
        (
          'RUSS',
          'uhhh… the ghosts are getting bolder out there. Somebody should '
              'hold their diamonds a little tighter.',
          const MiniMapEmphasis(ghosts: true),
        ),
      ];
    case 2:
      return [
        (
          'BUTTER',
          'The Shack remembers $game. The Shack remembers everything.',
          const MiniMapEmphasis(shack: true),
        ),
      ];
    default:
      return [
        (
          'RUSS',
          '…did the board just move? uhhh. Roll the dice.',
          const MiniMapEmphasis(ops: true),
        ),
      ];
  }
}

class _RoundFlairScreenState extends State<RoundFlairScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beat; // one run per beat, then HOLDS
  late final List<(String, String, MiniMapEmphasis)> _beats;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _beats = flairBeatsFor(widget.controller);
    _beat = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4600))
      ..addStatusListener((s) {
        // Tap-to-drive: only ATTRACT's bot audience auto-advances.
        if (s == AnimationStatus.completed && widget.auto) _advance();
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
    final (speaker, line, emphasis) = _beats[_index];
    final c = widget.controller;
    final isBossDebut = c.round == c.totalRounds &&
        (c.gameMap?.bosses.isNotEmpty ?? false);
    final isGhostDebut = !isBossDebut && c.round == 2;
    final accent = isBossDebut
        ? const Color(0xFFE5484D)
        : isGhostDebut
            ? const Color(0xFF9FB7CE)
            : Potatuhs.gold;
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
                  style: Potatuhs.body(size: 12, color: accent)
                      .copyWith(letterSpacing: 4),
                ),
                // The board itself, live, with the beat's subject pinged —
                // the cutscene narrates a visible place, not a black void.
                if (c.gameMap != null) ...[
                  const SizedBox(height: 12),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight:
                            MediaQuery.sizeOf(context).height * 0.38,
                      ),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: MiniMap(controller: c, emphasis: emphasis),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const MiniMapLegend(),
                ],
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
                  child: DialogueStrip(
                    beat: DialogueBeat(
                      speaker == 'RUSS' ? kCharRuss : kCharButter,
                      line,
                      speaker == 'RUSS'
                          ? (isBossDebut || isGhostDebut
                              ? CharacterMood.worried
                              : CharacterMood.excited)
                          : CharacterMood.smug,
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
