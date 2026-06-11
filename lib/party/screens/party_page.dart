import 'dart:async';

import 'package:cell_mobile/games/mini_game_host.dart';
import 'package:flutter/material.dart';

import '../party_controller.dart';
import '../party_models.dart';
import 'party_setup_page.dart';

const _kFont = 'Avenir';
const _kAccent = Color(0xFFAADD44);

/// Full party flow: setup → board rounds → mini-game rounds → podium.
/// Owns the controller; [onExit] returns to the home screen.
class PartyFlowPage extends StatefulWidget {
  final VoidCallback onExit;
  const PartyFlowPage({Key? key, required this.onExit}) : super(key: key);

  @override
  State<PartyFlowPage> createState() => _PartyFlowPageState();
}

class _PartyFlowPageState extends State<PartyFlowPage> {
  PartyController? _controller;

  void _start(PartyMode mode, int rounds, List<String> names) {
    setState(() {
      _controller = PartyController(
          mode: mode, totalRounds: rounds, playerNames: names);
    });
  }

  void _backToSetup() {
    setState(() => _controller = null);
  }

  Future<void> _confirmQuit() async {
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Quit game?',
            style: TextStyle(fontFamily: _kFont, color: Colors.white)),
        content: const Text('Progress will be lost.',
            style: TextStyle(fontFamily: _kFont, color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep playing')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Quit')),
        ],
      ),
    );
    if (quit == true && mounted) widget.onExit();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return PartySetupView(onStart: _start, onExit: widget.onExit);
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        switch (controller.phase) {
          case PartyPhase.turnStart:
          case PartyPhase.moving:
          case PartyPhase.spaceResolved:
            return _BoardScreen(
                controller: controller, onQuit: _confirmQuit);
          case PartyPhase.minigameIntro:
            return _MiniGameIntroScreen(controller: controller);
          case PartyPhase.passPhone:
            return _PassPhoneScreen(controller: controller);
          case PartyPhase.minigamePlaying:
            final spec = controller.currentSpec!;
            final player = controller.miniPlayer;
            final teamTag = controller.mode.isTeams
                ? ' — ${kTeamNames[player.teamIndex]}'
                : '';
            return MiniGameHost(
              // New host per attempt so state never leaks between players.
              key: ValueKey(
                  'mg_${controller.round}_${player.index}_${spec.id}'),
              spec: spec,
              playerLabel: '${player.name}$teamTag',
              onComplete: controller.recordMiniScore,
              onExit: () => controller.recordMiniScore(0),
            );
          case PartyPhase.minigameResults:
            return _MiniRoundResultsScreen(controller: controller);
          case PartyPhase.gameOver:
            return _PodiumScreen(
              controller: controller,
              onPlayAgain: _backToSetup,
              onExit: widget.onExit,
            );
        }
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Board screen: HUD + board + turn panel
// ---------------------------------------------------------------------------

class _BoardScreen extends StatefulWidget {
  final PartyController controller;
  final VoidCallback onQuit;
  const _BoardScreen({required this.controller, required this.onQuit});

  @override
  State<_BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<_BoardScreen> {
  // While animating a move, the moving player's token renders here instead
  // of at its controller position.
  int? _animPlayerIndex;
  int? _animDisplayPos;
  bool _diceSettled = false;
  Timer? _timer;

  PartyController get controller => widget.controller;

  @override
  void didUpdateWidget(covariant _BoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeAnimate();
  }

  @override
  void initState() {
    super.initState();
    _maybeAnimate();
  }

  void _maybeAnimate() {
    if (controller.phase != PartyPhase.moving || _timer != null) return;
    final turn = controller.lastTurn!;
    _animPlayerIndex = turn.playerIndex;
    _animDisplayPos = turn.fromPosition;
    _diceSettled = false;

    // Dice settle beat, then step the token, then hand back to controller.
    var step = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      if (!mounted) return;
      if (!_diceSettled) {
        if (t.tick >= 4) setState(() => _diceSettled = true);
        return;
      }
      step++;
      if (step <= turn.steps) {
        setState(() => _animDisplayPos =
            (turn.fromPosition + step) % controller.board.length);
      } else {
        t.cancel();
        _timer = null;
        _animPlayerIndex = null;
        _animDisplayPos = null;
        controller.markMoved();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _displayPosition(PartyPlayer p) {
    if (_animPlayerIndex == p.index && _animDisplayPos != null) {
      return _animDisplayPos!;
    }
    // While the mover is mid-animation, freeze it at the animated spot;
    // everyone else renders live (handles swaps fine).
    return p.position;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            _scoreboard(),
            const SizedBox(height: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _BoardView(
                  controller: controller,
                  positionOf: _displayPosition,
                  highlightPlayer: controller.currentPlayer.index,
                ),
              ),
            ),
            _turnPanel(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onQuit,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0x88000000),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child:
                  const Icon(Icons.close, color: Colors.white54, size: 18),
            ),
          ),
          const Spacer(),
          Text(
            'ROUND ${controller.round} / ${controller.totalRounds}',
            style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.white),
          ),
          const Spacer(),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _scoreboard() {
    final teams = controller.mode.isTeams;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          if (teams)
            for (final entry in controller.finalTeamRanking)
              _chip(
                color: kTeamColors[entry.key],
                label: '${kTeamNames[entry.key]}  ${entry.value}',
                bold: true,
              ),
          for (final p in controller.players)
            _chip(
              color: p.color,
              label: '${p.name}  ${p.atp}',
              highlight: p.index == controller.currentPlayer.index &&
                  controller.phase != PartyPhase.spaceResolved,
              icons: p.armedPowerUps.map((pu) => pu.icon).toList(),
            ),
        ],
      ),
    );
  }

  Widget _chip({
    required Color color,
    required String label,
    bool highlight = false,
    bool bold = false,
    List<IconData> icons = const [],
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: highlight ? 0.30 : 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: highlight ? color : color.withValues(alpha: 0.4),
            width: highlight ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                fontFamily: _kFont,
                fontSize: 12,
                fontWeight: bold || highlight
                    ? FontWeight.bold
                    : FontWeight.w600,
                color: Colors.white),
          ),
          for (final icon in icons) ...[
            const SizedBox(width: 4),
            Icon(icon, size: 12, color: color),
          ],
        ],
      ),
    );
  }

  Widget _turnPanel() {
    final phase = controller.phase;
    final p = controller.currentPlayer;
    Widget child;

    if (phase == PartyPhase.turnStart) {
      child = Column(
        key: const ValueKey('roll'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${p.name.toUpperCase()}'S TURN",
            style: TextStyle(
                fontFamily: _kFont,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: p.color),
          ),
          if (p.armedPowerUps.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                p.armedPowerUps.map((pu) => pu.label).join(' · '),
                style: const TextStyle(
                    fontFamily: _kFont, fontSize: 11, color: Colors.white54),
              ),
            ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => controller.roll(),
            child: Container(
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(
                color: p.color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: p.color.withValues(alpha: 0.45), blurRadius: 16)
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.casino, color: Colors.black, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'ROLL',
                    style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 3),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (phase == PartyPhase.moving) {
      final turn = controller.lastTurn!;
      child = Column(
        key: const ValueKey('dice'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final d in turn.dice) _die(d, p.color),
              if (turn.rollBonus > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '+${turn.rollBonus}',
                    style: const TextStyle(
                        fontFamily: _kFont,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _kAccent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _diceSettled ? '${p.name} moves ${turn.steps}…' : 'Rolling…',
            style: const TextStyle(
                fontFamily: _kFont, fontSize: 13, color: Colors.white54),
          ),
          const SizedBox(height: 12),
        ],
      );
    } else {
      final turn = controller.lastTurn!;
      child = Column(
        key: const ValueKey('resolved'),
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final line in turn.log)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                line,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 13,
                    color: Colors.white,
                    height: 1.25),
              ),
            ),
          if (turn.log.isEmpty)
            const Text(
              'Nothing happened.',
              style: TextStyle(
                  fontFamily: _kFont, fontSize: 13, color: Colors.white54),
            ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: controller.confirmSpace,
            child: Container(
              height: 46,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white30),
              ),
              child: Center(
                child: Text(
                  controller.currentPlayerIndex <
                          controller.players.length - 1
                      ? 'NEXT PLAYER'
                      : 'MINI-GAME TIME!',
                  style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF101018),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: child,
      ),
    );
  }

  Widget _die(int value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 12)
        ],
      ),
      child: Center(
        child: Text(
          _diceSettled ? '$value' : '?',
          style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Board view: 6 section rows × 6 spaces, snaking path, VOID at the bottom
// ---------------------------------------------------------------------------

class _BoardView extends StatelessWidget {
  final PartyController controller;
  final int Function(PartyPlayer) positionOf;
  final int highlightPlayer;

  const _BoardView({
    required this.controller,
    required this.positionOf,
    required this.highlightPlayer,
  });

  @override
  Widget build(BuildContext context) {
    // Rows top→bottom: section 5 (ORGANELLES) down to section 0 (THE VOID).
    return Column(
      children: [
        for (var section = 5; section >= 0; section--)
          Expanded(child: _row(section)),
      ],
    );
  }

  Widget _row(int section) {
    final info = kBoardSections[section];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Section marker strip
          SizedBox(
            width: 22,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(info.icon, size: 13, color: info.color),
                const SizedBox(height: 2),
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: info.color.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          for (var c = 0; c < 6; c++)
            Expanded(child: _cell(_indexFor(section, c))),
        ],
      ),
    );
  }

  /// Snake path: even sections run left→right, odd sections right→left.
  int _indexFor(int section, int column) =>
      section * 6 + (section.isEven ? column : 5 - column);

  Widget _cell(int index) {
    final space = controller.board[index];
    final color = space.section.color;
    final tokens = controller.players
        .where((p) => positionOf(p) == index)
        .toList();
    final isStart = index == 0;

    IconData icon;
    Color iconColor;
    switch (space.type) {
      case SpaceType.gain:
        icon = Icons.add;
        iconColor = const Color(0xFF81C784);
        break;
      case SpaceType.lose:
        icon = Icons.remove;
        iconColor = const Color(0xFFE57373);
        break;
      case SpaceType.powerUp:
        icon = Icons.bolt;
        iconColor = const Color(0xFFFFD54F);
        break;
      case SpaceType.event:
        icon = Icons.help_outline;
        iconColor = const Color(0xFF80DEEA);
        break;
    }

    return Container(
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: isStart ? Colors.white : color.withValues(alpha: 0.45),
          width: isStart ? 1.6 : 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon,
              size: 14, color: iconColor.withValues(alpha: 0.8)),
          if (isStart)
            const Positioned(
              top: 1,
              child: Text(
                'START',
                style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 6,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Colors.white70),
              ),
            ),
          if (tokens.isNotEmpty)
            Positioned(
              bottom: 1,
              child: Wrap(
                spacing: 1,
                runSpacing: 1,
                alignment: WrapAlignment.center,
                children: [
                  for (final p in tokens)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: p.index == highlightPlayer ? 12 : 9,
                      height: p.index == highlightPlayer ? 12 : 9,
                      decoration: BoxDecoration(
                        color: p.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.black, width: 0.8),
                        boxShadow: [
                          BoxShadow(
                              color: p.color.withValues(alpha: 0.8),
                              blurRadius: 4)
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mini-game round screens
// ---------------------------------------------------------------------------

class _MiniGameIntroScreen extends StatelessWidget {
  final PartyController controller;
  const _MiniGameIntroScreen({required this.controller});

  @override
  Widget build(BuildContext context) {
    final spec = controller.currentSpec!;
    final section = controller.currentSection;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Text(
                  'MINI-GAME ROUND ${controller.round}',
                  style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: Colors.white54),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: section.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: section.color),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(section.icon, size: 14, color: section.color),
                      const SizedBox(width: 6),
                      Text(
                        "LEADER'S TERRITORY: ${section.name}",
                        style: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: section.color),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Center(child: Icon(spec.icon, color: spec.accent, size: 54)),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  spec.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: [Shadow(color: spec.accent, blurRadius: 18)],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  spec.howToWin,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: _kFont, fontSize: 14, color: spec.accent),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Everyone plays once. ATP goes to the best scores.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 13,
                      color: Colors.white70),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Wrap(
                  spacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final p in controller.players)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: p.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: p.color.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          p.name,
                          style: TextStyle(
                              fontFamily: _kFont,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: p.color),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: controller.beginMiniGameRound,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: spec.accent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: spec.accent.withValues(alpha: 0.45),
                          blurRadius: 18)
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "LET'S PLAY",
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
}

class _PassPhoneScreen extends StatelessWidget {
  final PartyController controller;
  const _PassPhoneScreen({required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = controller.miniPlayer;
    final teams = controller.mode.isTeams;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Center(
                child: Text(
                  'PASS THE PHONE TO',
                  style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: Colors.white54),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: p.color,
                  child: Text(
                    p.name.isEmpty ? '?' : p.name[0].toUpperCase(),
                    style: const TextStyle(
                        fontFamily: _kFont,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  p.name.toUpperCase(),
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: [Shadow(color: p.color, blurRadius: 20)],
                  ),
                ),
              ),
              if (teams)
                Center(
                  child: Text(
                    kTeamNames[p.teamIndex],
                    style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: kTeamColors[p.teamIndex]),
                  ),
                ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Player ${controller.miniPlayerIndex + 1} of '
                  '${controller.players.length} — '
                  '${controller.currentSpec!.name}',
                  style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 13,
                      color: Colors.white54),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: controller.startMiniGameAttempt,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: p.color,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: p.color.withValues(alpha: 0.45),
                          blurRadius: 18)
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "I'M ${p.name.toUpperCase()} — READY",
                      style: const TextStyle(
                          fontFamily: _kFont,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 2),
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
}

class _MiniRoundResultsScreen extends StatelessWidget {
  final PartyController controller;
  const _MiniRoundResultsScreen({required this.controller});

  @override
  Widget build(BuildContext context) {
    final spec = controller.currentSpec!;
    final sorted = [...controller.standings]
      ..sort((a, b) => a.rank.compareTo(b.rank));
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Text(
                  '${spec.name.toUpperCase()} — RESULTS',
                  style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.separated(
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final s = sorted[i];
                    final isFirst = s.rank == 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: s.player.color
                            .withValues(alpha: isFirst ? 0.22 : 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFirst
                              ? const Color(0xFFFFD54F)
                              : s.player.color.withValues(alpha: 0.4),
                          width: isFirst ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              '${s.rank + 1}.',
                              style: TextStyle(
                                  fontFamily: _kFont,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isFirst
                                      ? const Color(0xFFFFD54F)
                                      : Colors.white54),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              controller.mode.isTeams
                                  ? '${s.player.name} · ${kTeamNames[s.player.teamIndex]}'
                                  : s.player.name,
                              style: const TextStyle(
                                  fontFamily: _kFont,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                          Text(
                            '${s.score} ${spec.scoreUnit}',
                            style: const TextStyle(
                                fontFamily: _kFont,
                                fontSize: 13,
                                color: Colors.white70),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '+${s.award} ATP',
                            style: const TextStyle(
                                fontFamily: _kFont,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _kAccent),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: controller.confirmMiniGameResults,
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
                  child: Center(
                    child: Text(
                      controller.round >= controller.totalRounds
                          ? 'FINAL RESULTS'
                          : 'BACK TO THE BOARD',
                      style: const TextStyle(
                          fontFamily: _kFont,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 2),
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
}

class _PodiumScreen extends StatelessWidget {
  final PartyController controller;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const _PodiumScreen({
    required this.controller,
    required this.onPlayAgain,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final teams = controller.mode.isTeams;
    final ranking = controller.finalPlayerRanking;
    final teamRanking = controller.finalTeamRanking;
    final winnerColor =
        teams ? kTeamColors[teamRanking.first.key] : ranking.first.color;
    final winnerName = teams
        ? kTeamNames[teamRanking.first.key]
        : ranking.first.name.toUpperCase();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Center(
                child: Icon(Icons.emoji_events,
                    color: Color(0xFFFFD54F), size: 64),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  winnerName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: [Shadow(color: winnerColor, blurRadius: 22)],
                  ),
                ),
              ),
              const Center(
                child: Text(
                  'WINS THE JOURNEY',
                  style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 13,
                      letterSpacing: 3,
                      color: Colors.white54),
                ),
              ),
              const SizedBox(height: 20),
              if (teams)
                Row(
                  children: [
                    for (final entry in teamRanking)
                      Expanded(
                        child: Container(
                          margin:
                              const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kTeamColors[entry.key]
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: kTeamColors[entry.key]),
                          ),
                          child: Column(
                            children: [
                              Text(
                                kTeamNames[entry.key],
                                style: TextStyle(
                                    fontFamily: _kFont,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: kTeamColors[entry.key]),
                              ),
                              Text(
                                '${entry.value} ATP',
                                style: const TextStyle(
                                    fontFamily: _kFont,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              if (teams) const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: ranking.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final p = ranking[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: p.color.withValues(alpha: i == 0 ? 0.2 : 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: p.color.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 26,
                            child: Text(
                              '${i + 1}.',
                              style: const TextStyle(
                                  fontFamily: _kFont,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white54),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              teams
                                  ? '${p.name} · ${kTeamNames[p.teamIndex]}'
                                  : p.name,
                              style: const TextStyle(
                                  fontFamily: _kFont,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                          Text(
                            '${p.atp} ATP',
                            style: const TextStyle(
                                fontFamily: _kFont,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _kAccent),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onPlayAgain,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: _kAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'PLAY AGAIN',
                      style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onExit,
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Center(
                    child: Text(
                      'EXIT',
                      style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          letterSpacing: 2),
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
}
