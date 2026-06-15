import 'dart:async';
import 'dart:math';

import 'package:cell_mobile/games/mini_game_host.dart';
import 'package:cell_mobile/games/mini_game_registry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../party_controller.dart';
import '../party_models.dart';
import '../party_session_store.dart';
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

  /// A saved-but-not-yet-resumed game found on launch (debug desktop only).
  PartyController? _resumable;

  /// Number of recorded inputs already persisted; lets [_persist] skip the
  /// many non-input notifications fired while a token walks.
  int _savedInputCount = -1;

  @override
  void initState() {
    super.initState();
    final saved = PartySessionStore.load();
    if (saved != null && saved.phase != PartyPhase.gameOver) {
      if (PartySessionStore.autoResume) {
        _bind(saved);
        _controller = saved;
      } else {
        _resumable = saved;
      }
    }
  }

  void _start(PartyMode mode, int rounds, List<String> names) {
    final c =
        PartyController(mode: mode, totalRounds: rounds, playerNames: names);
    _bind(c);
    PartySessionStore.save(c); // persist the fresh game right away
    setState(() {
      _resumable = null;
      _controller = c;
    });
  }

  void _resume() {
    final c = _resumable;
    if (c == null) return;
    _bind(c);
    setState(() {
      _resumable = null;
      _controller = c;
    });
  }

  /// Start persisting [c]: save whenever a new decision is recorded, and clear
  /// the save once the game ends.
  void _bind(PartyController c) {
    _savedInputCount = c.inputLog.length;
    c.addListener(_persist);
  }

  void _persist() {
    final c = _controller;
    if (c == null) return;
    if (c.phase == PartyPhase.gameOver) {
      PartySessionStore.clear();
      return;
    }
    if (c.inputLog.length == _savedInputCount) return;
    _savedInputCount = c.inputLog.length;
    PartySessionStore.save(c);
  }

  void _backToSetup() {
    _controller?.removeListener(_persist);
    PartySessionStore.clear();
    setState(() => _controller = null);
  }

  @override
  void dispose() {
    _controller?.removeListener(_persist);
    super.dispose();
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
    if (quit == true && mounted) {
      // The dialog warns progress is lost, so drop the save too.
      _controller?.removeListener(_persist);
      PartySessionStore.clear();
      widget.onExit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      final setup = PartySetupView(onStart: _start, onExit: widget.onExit);
      return _resumable == null ? setup : _withResumeBanner(setup);
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        switch (controller.phase) {
          case PartyPhase.turnStart:
          case PartyPhase.moving:
          case PartyPhase.chooseBranch:
          case PartyPhase.shopOffer:
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

  /// Debug-desktop resume prompt floated over the setup screen when a saved
  /// game is found on launch. Tap to pick up where you left off; ✕ to discard.
  Widget _withResumeBanner(Widget setup) {
    final r = _resumable!;
    return Stack(
      children: [
        setup,
        Positioned(
          left: 12,
          right: 12,
          top: 0,
          child: SafeArea(
            child: GestureDetector(
              onTap: _resume,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF101018),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kAccent),
                  boxShadow: [
                    BoxShadow(
                        color: _kAccent.withValues(alpha: 0.30),
                        blurRadius: 14),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: _kAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'RESUME LAST GAME',
                            style: TextStyle(
                                fontFamily: _kFont,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: _kAccent),
                          ),
                          Text(
                            '${r.mode.label} · Round ${r.round}/${r.totalRounds}',
                            style: const TextStyle(
                                fontFamily: _kFont,
                                fontSize: 11,
                                color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        PartySessionStore.clear();
                        setState(() => _resumable = null);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child:
                            Icon(Icons.close, color: Colors.white38, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
  // The controller now moves tokens one space at a time; this timer just
  // paces the walk and pauses automatically at forks / the market.
  Timer? _stepTimer;
  bool _diceSettled = false;

  PartyController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _syncMovement();
  }

  @override
  void didUpdateWidget(covariant _BoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMovement();
  }

  /// Keep the stepping timer in sync with the controller phase. Stepping
  /// runs only while moving; it stops (and the dice reset) once the walk
  /// resolves, and pauses — without resetting the dice — at a fork or shop.
  void _syncMovement() {
    if (controller.phase == PartyPhase.moving) {
      _stepTimer ??= Timer.periodic(
          const Duration(milliseconds: 240), _onStepTick);
    } else {
      _stepTimer?.cancel();
      _stepTimer = null;
      if (controller.phase != PartyPhase.chooseBranch &&
          controller.phase != PartyPhase.shopOffer) {
        _diceSettled = false;
      }
    }
  }

  void _onStepTick(Timer t) {
    if (!mounted) return;
    if (controller.phase != PartyPhase.moving) {
      t.cancel();
      _stepTimer = null;
      return;
    }
    if (!_diceSettled) {
      // One beat to reveal the dice before the token starts walking.
      setState(() => _diceSettled = true);
      return;
    }
    controller.advanceStep();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
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
                  positionOf: (p) => p.position,
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
            for (final t in controller.finalTeamRanking)
              _chip(
                color: kTeamColors[t.teamIndex],
                name: kTeamNames[t.teamIndex],
                potatoes: t.potatoes,
                paydirt: t.paydirt,
                bold: true,
              ),
          for (final p in controller.players)
            _chip(
              color: p.color,
              name: p.name,
              potatoes: p.potatoes,
              paydirt: p.paydirt,
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
    required String name,
    required int potatoes,
    required int paydirt,
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
            name,
            style: TextStyle(
                fontFamily: _kFont,
                fontSize: 12,
                fontWeight: bold || highlight
                    ? FontWeight.bold
                    : FontWeight.w600,
                color: Colors.white),
          ),
          const SizedBox(width: 6),
          Text('🥔$potatoes',
              style: const TextStyle(fontFamily: _kFont, fontSize: 12)),
          const SizedBox(width: 4),
          Icon(Icons.savings, size: 11, color: _kAccent),
          const SizedBox(width: 2),
          Text('$paydirt',
              style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 11,
                  color: Colors.white70)),
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
            !_diceSettled
                ? 'Rolling…'
                : '${p.name} moves — ${controller.stepsRemaining} to go',
            style: const TextStyle(
                fontFamily: _kFont, fontSize: 13, color: Colors.white54),
          ),
          const SizedBox(height: 12),
        ],
      );
    } else if (phase == PartyPhase.chooseBranch) {
      child = _branchChoice(p);
    } else if (phase == PartyPhase.shopOffer) {
      child = _shopOffer(p);
    } else {
      child = Column(
        key: const ValueKey('resolved'),
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final line in controller.turnLog)
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
          if (controller.turnLog.isEmpty)
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

  Widget _branchChoice(PartyPlayer p) {
    final options = controller.branchOptions;
    return Column(
      key: const ValueKey('branch'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'WHICH WAY, ${p.name.toUpperCase()}?',
          style: TextStyle(
              fontFamily: _kFont,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: p.color),
        ),
        const SizedBox(height: 4),
        Text(
          '${controller.stepsRemaining} step'
          '${controller.stepsRemaining == 1 ? '' : 's'} left',
          style: const TextStyle(
              fontFamily: _kFont, fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(height: 10),
        for (final next in options) _pathOption(p, next),
      ],
    );
  }

  Widget _pathOption(PartyPlayer p, int next) {
    final space = controller.board[next];
    String label;
    String sub;
    IconData icon;
    if (!space.isShortcut) {
      label = 'STAY THE COURSE';
      sub = 'The main path onward';
      icon = Icons.arrow_forward;
    } else {
      final branch = kBoardBranches
          .firstWhere((b) => b.spaceIndices.contains(next));
      if (branch.mergeIndex < branch.forkIndex) {
        label = 'FILIBUSTER LOOP';
        sub = 'Orbit the Potato Market — stall for paydirt';
        icon = Icons.loop;
      } else {
        label = 'SHORTCUT LANE';
        sub = 'Skip ahead — risky spaces';
        icon = Icons.fast_forward;
      }
    }
    final color = space.section.color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => controller.choosePath(next),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                          fontFamily: _kFont,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.white),
                    ),
                    Text(
                      sub,
                      style: const TextStyle(
                          fontFamily: _kFont,
                          fontSize: 11,
                          color: Colors.white60),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shopOffer(PartyPlayer p) {
    return Column(
      key: const ValueKey('shop'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '🥔  POTATO MARKET  🥔',
          style: TextStyle(
              fontFamily: _kFont,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Color(0xFFD7A86E)),
        ),
        const SizedBox(height: 6),
        Text(
          'Buy a potato for $kPotatoPrice paydirt?',
          style: const TextStyle(
              fontFamily: _kFont, fontSize: 14, color: Colors.white),
        ),
        const SizedBox(height: 2),
        Text(
          'You have ${p.paydirt} paydirt · ${p.potatoes} potato'
          '${p.potatoes == 1 ? '' : 'es'}',
          style: const TextStyle(
              fontFamily: _kFont, fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: controller.buyPotato,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7A86E),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'BUY POTATO',
                      style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 1),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: controller.skipPotato,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: const Center(
                    child: Text(
                      'SKIP',
                      style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          letterSpacing: 1),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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
// Board view: a serpentine path winding from THE VOID (bottom) up to
// ORGANELLES (top). Spaces are nodes on the curve; tokens slide along it.
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final geo = _BoardGeometry(
            Size(constraints.maxWidth, constraints.maxHeight));

        // Group tokens by node so co-located tokens fan out around it.
        final tokensAt = <int, List<PartyPlayer>>{};
        for (final p in controller.players) {
          tokensAt.putIfAbsent(positionOf(p), () => []).add(p);
        }

        final startCenter = geo.nodeCenter(0);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Territory watermarks, behind everything.
            for (var s = 0; s < _BoardGeometry.bands; s++)
              Positioned(
                left: 0,
                right: 0,
                top: geo.bandCenterY(s) - 13,
                child: IgnorePointer(
                  child: Text(
                    kBoardSections[s].name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 7,
                      color: kBoardSections[s]
                          .color
                          .withValues(alpha: 0.13),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: CustomPaint(painter: _BoardPathPainter(geo)),
            ),
            for (var i = 0; i < controller.board.length; i++)
              _node(geo, i),
            Positioned(
              left: startCenter.dx - 24,
              top: startCenter.dy + geo.nodeRadius + 2,
              child: const SizedBox(
                width: 48,
                child: Text(
                  'START',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.white70),
                ),
              ),
            ),
            for (final entry in tokensAt.entries)
              ..._tokens(geo, entry.key, entry.value),
          ],
        );
      },
    );
  }

  Widget _node(_BoardGeometry geo, int index) {
    final space = controller.board[index];
    final center = geo.nodeCenter(index);
    final isStart = index == 0;
    final isShop = space.type == SpaceType.shop;
    // Shop is a landmark — draw it larger; shortcut nodes slightly smaller.
    final r = geo.nodeRadius * (isShop ? 1.35 : space.isShortcut ? 0.85 : 1.0);
    var color = space.section.color;

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
      case SpaceType.shop:
        icon = Icons.storefront;
        iconColor = const Color(0xFFD7A86E);
        color = const Color(0xFFD7A86E);
        break;
    }

    return Positioned(
      left: center.dx - r,
      top: center.dy - r,
      child: Container(
        width: r * 2,
        height: r * 2,
        decoration: BoxDecoration(
          // Solid-ish fill so the path line doesn't show through the node.
          color: Color.alphaBlend(
              color.withValues(alpha: isShop ? 0.35 : 0.22),
              const Color(0xFF0B0B12)),
          shape: BoxShape.circle,
          border: Border.all(
            color: isStart || isShop
                ? color
                : color.withValues(alpha: space.isShortcut ? 0.7 : 0.55),
            width: isStart || isShop ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: isShop ? 0.5 : 0.30),
                blurRadius: isShop ? 14 : 9),
          ],
        ),
        child: Icon(icon,
            size: r * (isShop ? 1.1 : 0.95),
            color: iconColor.withValues(alpha: 0.9)),
      ),
    );
  }

  List<Widget> _tokens(
      _BoardGeometry geo, int nodeIndex, List<PartyPlayer> players) {
    final center = geo.nodeCenter(nodeIndex);
    final widgets = <Widget>[];
    for (var j = 0; j < players.length; j++) {
      final p = players[j];
      final isCurrent = p.index == highlightPlayer;
      final tr = isCurrent ? 8.0 : 6.5;
      // Lone token sits on the node; groups fan out around its rim.
      final fan = players.length > 1 ? geo.nodeRadius * 0.75 : 0.0;
      final angle = 2 * pi * j / players.length - pi / 2;
      final off = Offset(cos(angle) * fan, sin(angle) * fan);
      widgets.add(AnimatedPositioned(
        key: ValueKey('token_${p.index}'),
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        left: center.dx + off.dx - tr,
        top: center.dy + off.dy - tr,
        child: Container(
          width: tr * 2,
          height: tr * 2,
          decoration: BoxDecoration(
            color: p.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 1),
            boxShadow: [
              BoxShadow(
                  color: p.color.withValues(alpha: 0.85),
                  blurRadius: isCurrent ? 8 : 4),
            ],
          ),
        ),
      ));
    }
    return widgets;
  }
}

/// Lays the 36 spaces along a serpentine curve: six horizontal bands with a
/// gentle sine wave, joined by elliptical U-turns at alternating edges.
/// Band 0 (THE VOID) is at the bottom; the path climbs to ORGANELLES.
class _BoardGeometry {
  static const int bands = 6;
  static const int perBand = 6;

  final Size size;
  final double bandH;
  final double nodeRadius;
  final double xLeft;
  final double xRight;
  final double waveAmp;
  final double turnRx;

  _BoardGeometry(this.size)
      : bandH = size.height / bands,
        nodeRadius = min(18.0, size.height / bands * 0.26),
        xLeft = 36,
        xRight = size.width - 36,
        waveAmp = min(14.0, size.height / bands * 0.17),
        turnRx = 24;

  double bandCenterY(int s) => size.height - bandH * (s + 0.5);

  bool _leftToRight(int s) => s.isEven;

  Offset pointOnBand(int s, double t) {
    final ltr = _leftToRight(s);
    final x = ltr ? xLeft + (xRight - xLeft) * t : xRight - (xRight - xLeft) * t;
    final y =
        bandCenterY(s) + waveAmp * sin(t * pi * 2) * (ltr ? 1 : -1);
    return Offset(x, y);
  }

  Offset nodeCenter(int index) {
    if (index >= bands * perBand) return branchNodeCenter(index);
    final s = index ~/ perBand;
    final i = index % perBand;
    return pointOnBand(s, (i + 0.5) / perBand);
  }

  /// Control point for a branch's curve: bowed toward the open vertical
  /// corridor down the middle of the board so lanes read as alternate routes.
  Offset branchControl(BoardBranch branch) {
    final f = nodeCenter(branch.forkIndex);
    final m = nodeCenter(branch.mergeIndex);
    final mid = Offset((f.dx + m.dx) / 2, (f.dy + m.dy) / 2);
    final targetX = size.width / 2;
    var bow = targetX - mid.dx;
    if (bow.abs() < 50) bow = mid.dx <= targetX ? 70 : -70;
    return Offset(mid.dx + bow, mid.dy);
  }

  Offset _bezier(Offset a, Offset c, Offset b, double t) {
    final u = 1 - t;
    return Offset(
      u * u * a.dx + 2 * u * t * c.dx + t * t * b.dx,
      u * u * a.dy + 2 * u * t * c.dy + t * t * b.dy,
    );
  }

  Offset branchNodeCenter(int spaceIndex) {
    final branch = kBoardBranches
        .firstWhere((b) => b.spaceIndices.contains(spaceIndex));
    final i = branch.spaceIndices.indexOf(spaceIndex);
    final n = branch.spaceIndices.length;
    return _bezier(
      nodeCenter(branch.forkIndex),
      branchControl(branch),
      nodeCenter(branch.mergeIndex),
      (i + 1) / (n + 1),
    );
  }

  List<Offset> bandPoints(int s) =>
      [for (var k = 0; k <= 24; k++) pointOnBand(s, k / 24)];

  /// U-turn connecting the end of band [s] to the start of band s+1.
  List<Offset> turnPoints(int s) {
    final ltr = _leftToRight(s);
    final xEdge = ltr ? xRight : xLeft;
    final ry = bandH / 2;
    final cy = bandCenterY(s) - ry;
    return [
      for (var k = 0; k <= 16; k++)
        Offset(
          xEdge + (ltr ? 1 : -1) * turnRx * cos(pi / 2 - k * pi / 16),
          cy + ry * sin(pi / 2 - k * pi / 16),
        ),
    ];
  }
}

class _BoardPathPainter extends CustomPainter {
  final _BoardGeometry geo;
  _BoardPathPainter(this.geo);

  Path _polyline(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Full route, as one path for the soft under-glow.
    final allPoints = <Offset>[];
    for (var s = 0; s < _BoardGeometry.bands; s++) {
      allPoints.addAll(geo.bandPoints(s));
      if (s < _BoardGeometry.bands - 1) allPoints.addAll(geo.turnPoints(s));
    }
    final full = _polyline(allPoints);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(full, glow);

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawPath(full, base);

    // Each band glows in its territory color; turns fade toward the next.
    for (var s = 0; s < _BoardGeometry.bands; s++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = kBoardSections[s].color.withValues(alpha: 0.50);
      canvas.drawPath(_polyline(geo.bandPoints(s)), paint);
      if (s < _BoardGeometry.bands - 1) {
        final turnPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = kBoardSections[s + 1].color.withValues(alpha: 0.28);
        canvas.drawPath(_polyline(geo.turnPoints(s)), turnPaint);
      }
    }

    // Branch lanes: dashed alternate routes. Amber = shortcut, potato-brown
    // = filibuster loop (merges backward past the market).
    for (final branch in kBoardBranches) {
      final f = geo.nodeCenter(branch.forkIndex);
      final m = geo.nodeCenter(branch.mergeIndex);
      final c = geo.branchControl(branch);
      final isLoop = branch.mergeIndex < branch.forkIndex;
      final col = isLoop ? const Color(0xFFD7A86E) : const Color(0xFFFFB74D);
      final path = Path()
        ..moveTo(f.dx, f.dy)
        ..quadraticBezierTo(c.dx, c.dy, m.dx, m.dy);
      _dashed(
        canvas,
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..color = col.withValues(alpha: 0.55),
      );
    }
  }

  void _dashed(Canvas canvas, Path path, Paint paint,
      {double dash = 7, double gap = 5}) {
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
            metric.extractPath(d, min(d + dash, metric.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPathPainter oldDelegate) =>
      oldDelegate.geo.size != geo.size;
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
                  'Everyone plays once. Paydirt goes to the best scores — '
                  'spend it on potatoes at the market.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 13,
                      color: Colors.white70),
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 12),
                _DebugGamePicker(controller: controller),
              ],
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

/// Debug-only: override the randomly chosen game on the intro screen.
class _DebugGamePicker extends StatelessWidget {
  final PartyController controller;
  const _DebugGamePicker({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF8A65), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DEBUG · FORCE GAME',
            style: TextStyle(
                fontFamily: _kFont,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Color(0xFFFF8A65)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in MiniGameRegistry.enabledSpecs)
                GestureDetector(
                  onTap: () => controller.debugSetSpec(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: controller.currentSpec!.id == s.id
                          ? s.accent.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: controller.currentSpec!.id == s.id
                            ? s.accent
                            : Colors.white24,
                      ),
                    ),
                    child: Text(
                      s.name,
                      style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: controller.currentSpec!.id == s.id
                              ? s.accent
                              : Colors.white70),
                    ),
                  ),
                ),
            ],
          ),
        ],
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.savings,
                                  size: 13, color: _kAccent),
                              const SizedBox(width: 3),
                              Text(
                                '+${s.award}',
                                style: const TextStyle(
                                    fontFamily: _kFont,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _kAccent),
                              ),
                            ],
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
    final winnerColor = teams
        ? kTeamColors[teamRanking.first.teamIndex]
        : ranking.first.color;
    final winnerName = teams
        ? kTeamNames[teamRanking.first.teamIndex]
        : ranking.first.name.toUpperCase();
    final winnerPotatoes =
        teams ? teamRanking.first.potatoes : ranking.first.potatoes;

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
              Center(
                child: Text(
                  'WINS WITH $winnerPotatoes 🥔',
                  style: const TextStyle(
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
                    for (final t in teamRanking)
                      Expanded(
                        child: Container(
                          margin:
                              const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kTeamColors[t.teamIndex]
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: kTeamColors[t.teamIndex]),
                          ),
                          child: Column(
                            children: [
                              Text(
                                kTeamNames[t.teamIndex],
                                style: TextStyle(
                                    fontFamily: _kFont,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: kTeamColors[t.teamIndex]),
                              ),
                              Text(
                                '${t.potatoes} 🥔',
                                style: const TextStyle(
                                    fontFamily: _kFont,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              Text(
                                '${t.paydirt} paydirt',
                                style: const TextStyle(
                                    fontFamily: _kFont,
                                    fontSize: 11,
                                    color: Colors.white54),
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
                            '${p.potatoes} 🥔',
                            style: const TextStyle(
                                fontFamily: _kFont,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${p.paydirt}',
                            style: const TextStyle(
                                fontFamily: _kFont,
                                fontSize: 13,
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
