import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:cell_mobile/games/mini_game_host.dart';
import 'package:cell_mobile/games/mini_game_registry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/potatuhs.dart';
import '../party_actions.dart';
import '../party_controller.dart';
import '../party_models.dart';
import '../party_session_store.dart';
import '../net/party_net.dart';
import '../net/party_session.dart';
import 'party_setup_page.dart';

const _kFont = Potatuhs.bodyFont; // Outfit — body/UI
const _kDisplay = Potatuhs.displayFont; // Bowlby One SC — hero titles
const _kAccent = Potatuhs.gold; // brand gold accent (was off-brand green)

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

  /// Backs the temporary "SKIP" button used to race through the games while
  /// testing the board flow.
  final Random _debugRng = Random();

  /// Non-null when this session is an ONLINE match (set once at initState).
  PartyNet? _net;

  @override
  void initState() {
    super.initState();
    final net = PartySession.active;
    if (net != null) {
      // ONLINE mode: no local save/resume logic.
      _net = net;
      return;
    }
    // LOCAL mode: existing save/resume behaviour unchanged.
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
    // _net is owned by PartySession; we don't dispose it here (the user might
    // navigate back and reconnect). Only PartySession.clear() disposes it.
    super.dispose();
  }

  Future<void> _confirmQuit() async {
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Potatuhs.inkPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: Potatuhs.gold.withValues(alpha: 0.5), width: 1.5),
        ),
        title: Text('QUIT GAME?',
            style: Potatuhs.display(size: 22)),
        content: Text('Progress will be lost.',
            style: Potatuhs.body(size: 15, color: Potatuhs.textSecondary)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('KEEP PLAYING',
                style: Potatuhs.body(
                    size: 14, weight: FontWeight.w700, color: Potatuhs.gold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('QUIT',
                style: Potatuhs.body(
                    size: 14,
                    weight: FontWeight.w700,
                    color: Potatuhs.textFaint)),
          ),
        ],
      ),
    );
    if (quit == true && mounted) {
      if (_net != null) {
        // Online: tear down the match; no local save to worry about.
        PartySession.clear();
        _net = null;
      } else {
        // Local: the dialog warns progress is lost, so drop the save too.
        _controller?.removeListener(_persist);
        PartySessionStore.clear();
      }
      widget.onExit();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── ONLINE mode ───────────────────────────────────────────────────────────
    final net = _net;
    if (net != null) {
      return AnimatedBuilder(
        animation: net,
        builder: (context, _) {
          final c = net.controller;
          if (c == null) {
            // Waiting for the host to start the game.
            return Scaffold(
              backgroundColor: Potatuhs.inkDeep,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Potatuhs.gold),
                    const SizedBox(height: 16),
                    Text(
                      'Connecting…',
                      style: Potatuhs.body(size: 16, color: Potatuhs.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }
          final actions = OnlineActions(net);
          final mySlot = net.mySlot ?? -1;
          return _buildPhaseScreen(c, actions, net: net, mySlot: mySlot);
        },
      );
    }

    // ── LOCAL mode ────────────────────────────────────────────────────────────
    final controller = _controller;
    if (controller == null) {
      final setup = PartySetupView(onStart: _start, onExit: widget.onExit);
      return _resumable == null ? setup : _withResumeBanner(setup);
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final actions = LocalActions(controller);
        return _buildPhaseScreen(controller, actions);
      },
    );
  }

  /// Builds the per-phase screen for both LOCAL and ONLINE paths.
  /// [net] and [mySlot] are only non-null in ONLINE mode.
  Widget _buildPhaseScreen(
    PartyController c,
    PartyActions actions, {
    PartyNet? net,
    int mySlot = -1,
  }) {
    final isOnline = net != null;

    // Turn-gating: who can tap buttons right now.
    bool boardInteractive() {
      if (!isOnline) return true;
      return mySlot == c.currentPlayerIndex;
    }

    bool miniPlayInteractive() {
      if (!isOnline) return true;
      return !c.hasSubmittedMiniScore(mySlot);
    }

    switch (c.phase) {
      case PartyPhase.turnStart:
      case PartyPhase.rollResult:
      case PartyPhase.moving:
      case PartyPhase.chooseBranch:
      case PartyPhase.shopOffer:
      case PartyPhase.spaceResolved:
        return _BoardScreen(
          controller: c,
          actions: actions,
          interactive: boardInteractive(),
          onQuit: _confirmQuit,
        );
      case PartyPhase.minigameIntro:
        return _MiniGameIntroScreen(
          controller: c,
          actions: actions,
          interactive: !isOnline, // host auto-advances online
        );
      case PartyPhase.passPhone:
        return _PassPhoneScreen(
          controller: c,
          actions: actions,
          interactive: !isOnline, // host auto-advances online
        );
      case PartyPhase.minigamePlaying:
        final spec = c.currentSpec!;
        final player = c.miniPlayer;
        final teamTag = c.mode.isTeams
            ? ' — ${kTeamNames[player.teamIndex]}'
            : '';
        final interactive = miniPlayInteractive();
        if (!interactive) {
          // Non-interactive: read-only "Waiting for others…" overlay.
          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Stack(
                children: [
                  // Render the board scoreboard for context.
                  _MiniGameWaitingOverlay(controller: c),
                ],
              ),
            ),
          );
        }
        final host = MiniGameHost(
          // New host per attempt so state never leaks between players.
          key: ValueKey('mg_${c.round}_${player.index}_${spec.id}'),
          spec: spec,
          playerLabel: '${player.name}$teamTag',
          onComplete: actions.recordMiniScore,
          onExit: () => actions.recordMiniScore(0),
        );
        return Stack(
          children: [
            host,
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 12),
                  child: _buildSkipButton(c, actions),
                ),
              ),
            ),
          ],
        );
      case PartyPhase.minigameResults:
        return _MiniRoundResultsScreen(
          controller: c,
          actions: actions,
          interactive: !isOnline, // host auto-advances online
        );
      case PartyPhase.gameOver:
        if (isOnline) PartySession.clear();
        return _PodiumScreen(
          controller: c,
          onPlayAgain: isOnline ? widget.onExit : _backToSetup,
          onExit: widget.onExit,
        );
    }
  }

  /// Score that lands the current player strictly below everyone who has
  /// already played this round (a random value in `[0, lowest)`), so skipping
  /// every game still yields a clean reverse-order ranking while testing the
  /// board flow. The first player gets a mid score to leave room beneath.
  int _skipScore(PartyController controller) {
    final scores = controller.standings.map((s) => s.score).toList();
    if (scores.isEmpty) return 60 + _debugRng.nextInt(60);
    final lowest = scores.reduce(min);
    return lowest <= 0 ? 0 : _debugRng.nextInt(lowest);
  }

  /// Temporary "skip this game" affordance — forfeits the round to last place.
  Widget _buildSkipButton(PartyController controller, PartyActions actions) {
    return GestureDetector(
      onTap: () => actions.recordMiniScore(_skipScore(controller)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SKIP',
              style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white70),
            ),
            SizedBox(width: 6),
            Icon(Icons.skip_next, color: Colors.white70, size: 18),
          ],
        ),
      ),
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
// Online-only waiting overlay shown during minigamePlaying for non-active players
// ---------------------------------------------------------------------------

class _MiniGameWaitingOverlay extends StatelessWidget {
  final PartyController controller;
  const _MiniGameWaitingOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    final spec = controller.currentSpec!;
    final player = controller.miniPlayer;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(spec.icon, color: spec.accent, size: 54),
            const SizedBox(height: 16),
            Text(
              spec.name.toUpperCase(),
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(color: spec.accent, blurRadius: 14)],
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Potatuhs.gold),
            const SizedBox(height: 16),
            Text(
              'Waiting for ${player.name}…',
              style: Potatuhs.body(size: 15, color: Potatuhs.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Board screen: HUD + board + turn panel
// ---------------------------------------------------------------------------

class _BoardScreen extends StatefulWidget {
  final PartyController controller;
  final PartyActions actions;
  final bool interactive;
  final VoidCallback onQuit;
  const _BoardScreen({
    required this.controller,
    required this.actions,
    required this.interactive,
    required this.onQuit,
  });

  @override
  State<_BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<_BoardScreen> {
  // The controller now moves tokens one space at a time; this timer just
  // paces the walk and pauses automatically at forks / the market.
  Timer? _stepTimer;
  bool _diceSettled = false;

  PartyController get controller => widget.controller;
  PartyActions get actions => widget.actions;

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
      if (controller.phase == PartyPhase.rollResult) {
        // Dice are revealed (and held) on the roll-result panel.
        _diceSettled = true;
      } else if (controller.phase != PartyPhase.chooseBranch &&
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
    // In online mode advanceStep() is a no-op; the host drives movement via the
    // canonical stream and the phase will leave 'moving' when the replica
    // catches up, which causes _syncMovement to cancel this timer naturally.
    actions.advanceStep();
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
        child: Stack(
          children: [
            Column(
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
            // Online non-interactive overlay: the board renders read-only;
            // action buttons in the turn panel are hidden (see _turnPanel), and
            // a hint is shown at the bottom.
            if (!widget.interactive)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: const BoxDecoration(
                    color: Color(0xCC101018),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Center(
                    child: Text(
                      'Waiting for ${controller.currentPlayer.name}…',
                      style:
                          Potatuhs.body(size: 14, color: Potatuhs.textSecondary),
                    ),
                  ),
                ),
              ),
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
    final ranked = controller.finalPlayerRanking;
    final teamRank = controller.finalTeamRanking;
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          if (teams)
            for (var i = 0; i < teamRank.length; i++)
              _chip(
                rank: i,
                color: kTeamColors[teamRank[i].teamIndex],
                name: kTeamNames[teamRank[i].teamIndex],
                potatoes: teamRank[i].potatoes,
                paydirt: teamRank[i].paydirt,
                bold: true,
              ),
          for (var i = 0; i < ranked.length; i++)
            _chip(
              rank: i,
              color: ranked[i].color,
              name: ranked[i].name,
              potatoes: ranked[i].potatoes,
              paydirt: ranked[i].paydirt,
              atp: ranked[i].atp,
              highlight: ranked[i].index == controller.currentPlayer.index &&
                  controller.phase != PartyPhase.spaceResolved,
              icons: ranked[i].armedPowerUps.map((pu) => pu.icon).toList(),
            ),
        ],
      ),
    );
  }

  /// One ranked entry on the leaderboard strip. Rank 0 is crowned in gold.
  Widget _chip({
    required int rank,
    required Color color,
    required String name,
    required int potatoes,
    required int paydirt,
    int? atp,
    bool highlight = false,
    bool bold = false,
    List<IconData> icons = const [],
  }) {
    final isLeader = rank == 0;
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.fromLTRB(6, 0, 10, 0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: highlight ? 0.30 : 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isLeader
                ? Potatuhs.gold
                : (highlight ? color : color.withValues(alpha: 0.4)),
            width: isLeader || highlight ? 1.5 : 1),
        boxShadow:
            isLeader ? Potatuhs.glow(Potatuhs.gold, strength: 0.25, blur: 8) : null,
      ),
      child: Row(
        children: [
          // Rank badge — crown for the leader, number otherwise.
          Container(
            width: 19,
            height: 19,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLeader ? Potatuhs.gold : Colors.white12,
            ),
            child: isLeader
                ? const Icon(Icons.emoji_events, size: 11, color: Colors.black)
                : Text('${rank + 1}',
                    style: const TextStyle(
                        fontFamily: _kFont,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70)),
          ),
          const SizedBox(width: 7),
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
                fontWeight: bold || highlight || isLeader
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
          if (atp != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.bolt, size: 11, color: Potatuhs.gold),
            Text('$atp',
                style: const TextStyle(
                    fontFamily: _kFont, fontSize: 11, color: Potatuhs.gold)),
          ],
          for (final icon in icons) ...[
            const SizedBox(width: 4),
            Icon(icon, size: 12, color: color),
          ],
        ],
      ),
    );
  }

  Widget _turnPanel() {
    // When not interactive (online, not our turn), the overlay in build() shows
    // the waiting hint instead; the turn panel is hidden beneath it. We still
    // build it with empty content so the panel height stays consistent.
    if (!widget.interactive) {
      return const SizedBox(height: 70); // reserved space for the overlay
    }

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
                fontFamily: _kDisplay,
                fontSize: 18,
                letterSpacing: 1,
                color: p.color),
          ),
          if (p.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('TAP AN ITEM TO USE',
                      style: Potatuhs.label(
                          size: 9.5, color: Potatuhs.textFaint)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final item in p.items)
                        _itemChip(item, () => actions.useItem(item)),
                    ],
                  ),
                ],
              ),
            ),
          if (p.armedPowerUps.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'ARMED · ${p.armedPowerUps.map((pu) => pu.label).join(' · ')}',
                style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 10.5,
                    letterSpacing: 1,
                    color: Colors.white38),
              ),
            ),
          if (p.atp >= kAtpPlus2Cost || controller.atpRollBonus > 0)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.atpRollBonus > 0
                        ? 'PRIMED +${controller.atpRollBonus}  ·  ${p.atp} ATP LEFT'
                        : 'SPEND ATP BEFORE ROLLING  ·  ${p.atp} ATP',
                    style: Potatuhs.label(size: 9.5, color: Potatuhs.gold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (p.atp >= kAtpPlus2Cost)
                        _atpButton('+2', kAtpPlus2Cost,
                            () => actions.useAtp(2)),
                      if (p.atp >= kAtpPlus3Cost) ...[
                        const SizedBox(width: 8),
                        _atpButton('+3', kAtpPlus3Cost,
                            () => actions.useAtp(3)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: PotatuhsButton(
              label: 'ROLL',
              display: true,
              icon: Icons.casino,
              fill: p.color,
              glowColor: p.color,
              textColor: Colors.black,
              onTap: () => actions.roll(),
            ),
          ),
        ],
      );
    } else if (phase == PartyPhase.rollResult) {
      final turn = controller.lastTurn!;
      child = Column(
        key: const ValueKey('rollResult'),
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
          const SizedBox(height: 6),
          Text(
            'Move ${controller.stepsRemaining}',
            style: const TextStyle(
                fontFamily: _kFont, fontSize: 13, color: Colors.white54),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (p.atp >= kAtpPlus1Cost) ...[
                _atpButton('+1', kAtpPlus1Cost, () => actions.useAtp(1)),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: PotatuhsButton(
                  label: 'MOVE',
                  display: true,
                  icon: Icons.directions_walk,
                  fill: p.color,
                  glowColor: p.color,
                  textColor: Colors.black,
                  onTap: actions.beginWalk,
                ),
              ),
            ],
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
            onTap: actions.confirmSpace,
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

  /// A held power-up shown on your turn; tap to spend it.
  Widget _itemChip(PowerUp item, VoidCallback onUse) {
    return GestureDetector(
      onTap: onUse,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: Potatuhs.inkPanel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Potatuhs.gold.withValues(alpha: 0.65), width: 1.5),
          boxShadow: Potatuhs.glow(Potatuhs.gold, strength: 0.16, blur: 9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 15, color: Potatuhs.gold),
            const SizedBox(width: 5),
            Text(item.label,
                style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  /// A gold ATP-spend pill: a boost label (+1/+2/+3) and its energy cost.
  Widget _atpButton(String label, int cost, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Potatuhs.inkPanel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Potatuhs.gold, width: 1.5),
          boxShadow: Potatuhs.glow(Potatuhs.gold, strength: 0.2, blur: 8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(width: 6),
            const Icon(Icons.bolt, size: 13, color: Potatuhs.gold),
            Text('$cost',
                style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Potatuhs.gold)),
          ],
        ),
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
        onTap: () => actions.choosePath(next),
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
                onTap: actions.buyPotato,
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
                onTap: actions.skipPotato,
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
// Board view: a rounded-rectangle racetrack loop. The main spaces sit evenly
// around the ring (coloured by section); shortcut/filibuster lanes are chords
// cutting across the open middle. Tokens slide node-to-node around the loop.
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
            // Territory watermarks at each section's arc, nudged inward.
            for (var s = 0; s < _BoardGeometry.sections; s++)
              _sectionLabel(geo, s),
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

  Widget _sectionLabel(_BoardGeometry geo, int s) {
    final anchor = Offset.lerp(geo.sectionAnchor(s), geo.center, 0.4)!;
    return Positioned(
      left: anchor.dx - 60,
      top: anchor.dy - 9,
      width: 120,
      child: IgnorePointer(
        child: Text(
          kBoardSections[s].name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            color: kBoardSections[s].color.withValues(alpha: 0.18),
          ),
        ),
      ),
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
      child: Tooltip(
        message: _spaceDescription(space),
        triggerMode: TooltipTriggerMode.tap,
        preferBelow: false,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Potatuhs.inkPanel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Potatuhs.gold.withValues(alpha: 0.6)),
          boxShadow: Potatuhs.glow(Potatuhs.gold, strength: 0.2, blur: 10),
        ),
        textStyle: const TextStyle(
            fontFamily: _kFont, fontSize: 12, color: Colors.white, height: 1.35),
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
      ),
    );
  }

  /// What landing on [space] does — shown as a tap tooltip on the tile.
  String _spaceDescription(BoardSpace space) {
    final lane = space.isShortcut ? ' · risky shortcut lane' : '';
    switch (space.type) {
      case SpaceType.gain:
        return 'Paydirt space$lane\nLand here: +5 paydirt.';
      case SpaceType.lose:
        return 'Entropy space$lane\nLand here: −5 paydirt (a Void Shield blocks it).';
      case SpaceType.powerUp:
        final pu = space.section.powerUp;
        return '${pu.label}$lane\nPick it up to use on your turn: ${pu.description}.';
      case SpaceType.event:
        return 'Event space$lane\nTriggers a random cosmic event.';
      case SpaceType.shop:
        return 'Potato Market\nSpend $kPotatoPrice paydirt for a potato.';
    }
  }

  List<Widget> _tokens(
      _BoardGeometry geo, int nodeIndex, List<PartyPlayer> players) {
    final center = geo.nodeCenter(nodeIndex);
    final widgets = <Widget>[];
    for (var j = 0; j < players.length; j++) {
      final p = players[j];
      final isCurrent = p.index == highlightPlayer;
      final tr = geo.nodeRadius * (isCurrent ? 0.52 : 0.44);
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

/// Places [kMainLoopLength] spaces evenly around a rounded-rectangle loop using
/// arc-length sampling, so the board is a genuine closed circuit. Sections take
/// successive arcs (lengths from [kSectionSizes]); branches are chords across
/// the open interior.
class _BoardGeometry {
  static const int sections = 6;

  final Size size;
  final Rect rect;
  final double corner;
  late final Path loop;
  late final ui.PathMetric _metric;
  late final double _len;
  late final double nodeRadius;

  _BoardGeometry(this.size)
      : rect = _boardRect(size),
        corner = _boardCorner(size) {
    loop = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(corner)));
    _metric = loop.computeMetrics().first;
    _len = _metric.length;
    nodeRadius = min(22.0, _len / kMainLoopLength * 0.42);
  }

  static Rect _boardRect(Size size) {
    const m = 30.0;
    return Rect.fromLTRB(m, m, size.width - m, size.height - m);
  }

  static double _boardCorner(Size size) => min(size.width, size.height) * 0.15;

  Offset get center => rect.center;

  Offset _pointAt(double frac) {
    var f = frac % 1.0;
    if (f < 0) f += 1.0;
    return _metric.getTangentForOffset(f * _len)?.position ?? center;
  }

  /// Position + travel direction at a loop fraction — for direction arrows.
  ui.Tangent? tangentAt(double frac) {
    var f = frac % 1.0;
    if (f < 0) f += 1.0;
    return _metric.getTangentForOffset(f * _len);
  }

  /// Sub-path of the loop between two fractions — used for per-section colour.
  Path subPath(double f0, double f1) =>
      _metric.extractPath(f0 * _len, f1 * _len);

  Offset nodeCenter(int index) {
    if (index >= kMainLoopLength) return branchNodeCenter(index);
    return _pointAt(index / kMainLoopLength);
  }

  /// First main-loop index of section [s].
  static int sectionStart(int s) {
    var start = 0;
    for (var k = 0; k < s; k++) {
      start += kSectionSizes[k];
    }
    return start;
  }

  /// Centroid of a section's nodes — anchor for its watermark.
  Offset sectionAnchor(int s) {
    final start = sectionStart(s);
    final size = kSectionSizes[s];
    var sx = 0.0, sy = 0.0;
    for (var i = 0; i < size; i++) {
      final p = nodeCenter(start + i);
      sx += p.dx;
      sy += p.dy;
    }
    return Offset(sx / size, sy / size);
  }

  /// Branch control point: bows the lane GENTLY inward (toward centre) by a
  /// modest amount proportional to its span, so each shortcut is a small local
  /// bulge hugging just inside the ring — not a long chord across the middle
  /// that tangles with the others.
  Offset branchControl(BoardBranch branch) {
    final f = nodeCenter(branch.forkIndex);
    final m = nodeCenter(branch.mergeIndex);
    final mid = Offset((f.dx + m.dx) / 2, (f.dy + m.dy) / 2);
    final toCenter = center - mid;
    final len = toCenter.distance;
    if (len == 0) return mid;
    final bow = ((f - m).distance * 0.5).clamp(40.0, 72.0);
    return mid + (toCenter / len) * bow;
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
}

class _BoardPathPainter extends CustomPainter {
  final _BoardGeometry geo;
  _BoardPathPainter(this.geo);

  @override
  void paint(Canvas canvas, Size size) {
    // Soft under-glow + base ring on the whole closed loop.
    canvas.drawPath(
      geo.loop,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..color = Colors.white.withValues(alpha: 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawPath(
      geo.loop,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white.withValues(alpha: 0.08),
    );

    // Each section colours its arc of the ring.
    for (var s = 0; s < _BoardGeometry.sections; s++) {
      final start = _BoardGeometry.sectionStart(s);
      final f0 = start / kMainLoopLength;
      final f1 = (start + kSectionSizes[s]) / kMainLoopLength;
      canvas.drawPath(
        geo.subPath(f0, f1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = kBoardSections[s].color.withValues(alpha: 0.55),
      );
    }

    // Direction-of-travel arrows around the loop.
    const arrowN = 14;
    for (var i = 0; i < arrowN; i++) {
      final tan = geo.tangentAt((i + 0.5) / arrowN);
      if (tan != null) {
        _arrow(canvas, tan.position, tan.vector,
            Colors.white.withValues(alpha: 0.28), 5);
      }
    }

    // Branch lanes: dashed chords across the interior. Amber = shortcut,
    // potato-brown = filibuster loop (merges backward past the market).
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
          ..color = col.withValues(alpha: 0.6),
      );
      // Arrowhead near the merge, pointing the way the lane flows.
      _arrow(canvas, _quad(f, c, m, 0.80), m - c, col, 6);
    }
  }

  /// A small chevron at [pos] pointing along [dir].
  void _arrow(Canvas canvas, Offset pos, Offset dir, Color color, double size) {
    final len = dir.distance;
    final d = len == 0 ? const Offset(1, 0) : dir / len;
    final perp = Offset(-d.dy, d.dx);
    final tip = pos + d * size;
    final back = pos - d * size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    canvas.drawLine(back + perp * size, tip, paint);
    canvas.drawLine(back - perp * size, tip, paint);
  }

  Offset _quad(Offset a, Offset c, Offset b, double t) {
    final u = 1 - t;
    return Offset(
      u * u * a.dx + 2 * u * t * c.dx + t * t * b.dx,
      u * u * a.dy + 2 * u * t * c.dy + t * t * b.dy,
    );
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
  final PartyActions actions;
  final bool interactive;
  const _MiniGameIntroScreen({
    required this.controller,
    required this.actions,
    required this.interactive,
  });

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
                _DebugGamePicker(controller: controller, actions: actions),
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
              if (interactive)
              GestureDetector(
                onTap: actions.beginMiniGameRound,
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
  final PartyActions actions;
  const _DebugGamePicker({
    required this.controller,
    required this.actions,
  });

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
                  onTap: () => actions.debugSetSpec(s),
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
  final PartyActions actions;
  final bool interactive;
  const _PassPhoneScreen({
    required this.controller,
    required this.actions,
    required this.interactive,
  });

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
              if (interactive)
                GestureDetector(
                  onTap: actions.startMiniGameAttempt,
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
                )
              else
                Center(
                  child: Text(
                    'Waiting for ${p.name}…',
                    style:
                        Potatuhs.body(size: 14, color: Potatuhs.textSecondary),
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
  final PartyActions actions;
  final bool interactive;
  const _MiniRoundResultsScreen({
    required this.controller,
    required this.actions,
    required this.interactive,
  });

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
              if (interactive)
                GestureDetector(
                  onTap: actions.confirmMiniGameResults,
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
                )
              else
                Center(
                  child: Text(
                    'Waiting for host…',
                    style:
                        Potatuhs.body(size: 14, color: Potatuhs.textSecondary),
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
                    fontFamily: _kDisplay,
                    fontSize: 34,
                    color: Colors.white,
                    letterSpacing: 1,
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
