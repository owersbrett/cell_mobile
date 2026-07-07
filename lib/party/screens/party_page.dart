import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:cell_mobile/games/mini_game_host.dart';
import 'package:cell_mobile/games/mini_game_registry.dart';
import 'package:cell_mobile/telemetry/cell_telemetry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/potatuhs.dart';
import '../party_actions.dart';
import '../../games/play_config.dart';
import '../maps/game_map.dart';
import '../maps/ops.dart';
import '../party_controller.dart';
import '../party_models.dart';
import '../party_session_store.dart';
import '../net/party_net.dart';
import '../net/party_session.dart';
import 'party_setup_page.dart';
import 'round_ceremony.dart';

const _kFont = Potatuhs.bodyFont; // Outfit — body/UI
const _kDisplay = Potatuhs.displayFont; // Bowlby One SC — hero titles
const _kAccent = Potatuhs.gold; // brand gold accent (was off-brand green)

/// Full party flow: setup → board rounds → mini-game rounds → podium.
/// Owns the controller; [onExit] returns to the home screen.
class PartyFlowPage extends StatefulWidget {
  final VoidCallback onExit;

  /// Attract mode: skip setup, auto-start a 4-player game on the configured
  /// board, and drive every decision hands-free (the board self-walks; the
  /// embedded [MiniGameHost] auto-plays each minigame). Flipping this false
  /// mid-game pauses the driver in place so a human can take over; flipping it
  /// back on resumes. Never persists or counts telemetry. See `AttractMapPage`.
  final bool autoPilot;

  const PartyFlowPage({Key? key, required this.onExit, this.autoPilot = false})
      : super(key: key);

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

  // ── Attract autopilot ─────────────────────────────────────────────────────
  static const _kAutoRounds = 5;
  static const _kAutoNames = ['Russ', 'Butter', 'Chips', 'Tater'];
  final Random _autoRng = Random();
  Timer? _autoPending; // the next scheduled hands-free action

  @override
  void initState() {
    super.initState();
    if (widget.autoPilot) {
      // Attract: no online / save / resume logic — just start a fresh board.
      _startAutoGame();
      return;
    }
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
    final c = PartyController(
      mode: mode,
      totalRounds: rounds,
      playerNames: names,
      gameMap: gameMapById(PlayConfig.mapId),
    );
    // Count this fresh board game into the shared counter (Sessions KPI).
    // Only on a NEW board (not _resume), so resuming a dropped game doesn't
    // double-count. Fire-and-forget. See docs/SESSIONS_COUNTER.md.
    CellTelemetry.recordBoardPlay();
    _bind(c);
    PartySessionStore.save(c); // persist the fresh game right away
    setState(() {
      _resumable = null;
      _controller = c;
    });
  }

  // ── Attract autopilot driver ──────────────────────────────────────────────
  // The board self-walks (its own step timer) and the embedded MiniGameHost
  // auto-plays each minigame; the driver only needs to "press the buttons" at
  // each genuine decision phase, on a watchable dwell.

  void _startAutoGame() {
    _controller?.removeListener(_autoOnChange);
    final c = PartyController(
      mode: PartyMode.ffa4,
      totalRounds: _kAutoRounds,
      playerNames: _kAutoNames,
      gameMap: gameMapById(PlayConfig.mapId),
    );
    // No PartySessionStore.save / CellTelemetry here — attract is a bot loop and
    // must not persist or count toward the Sessions KPI.
    c.addListener(_autoOnChange);
    _controller = c;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _autoOnChange();
    });
  }

  /// Dwell before acting on each decision phase (null = don't act; the phase
  /// resolves itself — `moving` walks, `minigamePlaying` is the host's bot).
  Duration? _autoDelayFor(PartyPhase p) {
    switch (p) {
      case PartyPhase.turnStart:
        return const Duration(milliseconds: 900);
      case PartyPhase.rollResult:
        return const Duration(milliseconds: 700);
      case PartyPhase.chooseBranch:
        return const Duration(milliseconds: 700);
      case PartyPhase.shopOffer:
        return const Duration(milliseconds: 800);
      case PartyPhase.cardDecision:
        return const Duration(milliseconds: 1100);
      case PartyPhase.spaceResolved:
        return const Duration(milliseconds: 1100);
      case PartyPhase.minigameIntro:
        return const Duration(milliseconds: 1600);
      case PartyPhase.passPhone:
        return const Duration(milliseconds: 900);
      case PartyPhase.minigameResults:
        // Long enough for the full ceremony reveal to play in attract b-roll.
        return const Duration(milliseconds: 7000);
      case PartyPhase.gameOver:
        return const Duration(milliseconds: 4000);
      case PartyPhase.moving:
      case PartyPhase.minigamePlaying:
        return null;
    }
  }

  /// Called on every controller notification. Schedules the next hands-free
  /// action if the current phase needs one and nothing is already pending.
  void _autoOnChange() {
    if (!widget.autoPilot || !mounted || _autoPending != null) return;
    final c = _controller;
    if (c == null) return;
    final delay = _autoDelayFor(c.phase);
    if (delay == null) return;
    final scheduledPhase = c.phase;
    _autoPending = Timer(delay, () {
      _autoPending = null;
      if (!widget.autoPilot || !mounted) return;
      final cur = _controller;
      if (cur == null) return;
      // Phase moved underneath us (e.g. the board finished walking): re-evaluate
      // rather than act on a stale phase.
      if (cur.phase != scheduledPhase) {
        _autoOnChange();
        return;
      }
      _autoAct(cur, scheduledPhase);
    });
  }

  void _autoAct(PartyController c, PartyPhase phase) {
    final a = LocalActions(c);
    switch (phase) {
      case PartyPhase.turnStart:
        a.roll();
        break;
      case PartyPhase.rollResult:
        a.beginWalk();
        break;
      case PartyPhase.chooseBranch:
        final opts = c.branchOptions;
        a.choosePath(opts[_autoRng.nextInt(opts.length)]);
        break;
      case PartyPhase.shopOffer:
        // Simple policy: grab a potato when affordable (it's the win condition),
        // otherwise pass.
        if (c.currentPlayer.diamonds >= kPotatoPrice) {
          a.buyPotato();
        } else {
          a.skipPotato();
        }
        break;
      case PartyPhase.cardDecision:
        a.chooseCardOption(0);
        break;
      case PartyPhase.spaceResolved:
        a.confirmSpace();
        break;
      case PartyPhase.minigameIntro:
        a.beginMiniGameRound();
        break;
      case PartyPhase.passPhone:
        a.startMiniGameAttempt();
        break;
      case PartyPhase.minigameResults:
        a.confirmMiniGameResults();
        break;
      case PartyPhase.gameOver:
        setState(_startAutoGame); // endless: restart the board
        break;
      case PartyPhase.moving:
      case PartyPhase.minigamePlaying:
        break;
    }
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
  void didUpdateWidget(covariant PartyFlowPage old) {
    super.didUpdateWidget(old);
    if (old.autoPilot && !widget.autoPilot) {
      // Ejected: stop driving; the live game stays interactive for the human.
      _autoPending?.cancel();
      _autoPending = null;
    } else if (!old.autoPilot && widget.autoPilot) {
      // Resumed: pick the game back up from whatever phase it's sitting in.
      _autoOnChange();
    }
  }

  @override
  void dispose() {
    _autoPending?.cancel();
    _controller?.removeListener(_autoOnChange);
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
      case PartyPhase.cardDecision:
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
          // Attract: the bot plays each player's attempt and auto-submits.
          autoPlay: widget.autoPilot,
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
        // The round ceremony: everyone watches the same podium reveal; the
        // host (or the local player) advances it, with an auto-dwell online.
        return RoundCeremonyScreen(
          controller: c,
          actions: actions,
          interactive: !isOnline || net.isHost,
          autoAdvance: isOnline && net.isHost,
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

class _BoardScreenState extends State<_BoardScreen>
    with SingleTickerProviderStateMixin {
  // The controller now moves tokens one space at a time; this timer just
  // paces the walk and pauses automatically at forks / the market.
  Timer? _stepTimer;
  bool _diceSettled = false;

  /// Drives the dice TUMBLE — a presentation-only roll animation. The rolled
  /// value is fixed by the controller's host-authoritative tape; this just
  /// makes the reveal feel like a thrown die (cycling pip faces → settle bounce)
  /// instead of a number popping into a box. Faces lock at 75% of the run; the
  /// final quarter is the elastic settle.
  late final AnimationController _diceCtrl;

  /// Last phase [_syncMovement] saw, so we trigger the tumble exactly once on
  /// the transition INTO rollResult rather than on every controller rebuild.
  PartyPhase? _lastSyncPhase;

  /// Persistent across the frequent controller rebuilds so a pinch-zoom on the
  /// board doesn't snap back to 1× every time a token takes a step.
  final TransformationController _boardTransform = TransformationController();

  /// One-time flag so we frame the board (center + initial zoom) on first
  /// layout, then leave the camera under the player's control.
  bool _framed = false;
  _BoardGeometry? _geo;
  Size? _viewport;

  /// The board space currently open in the tap-to-inspect sheet, if any.
  int? _inspecting;

  /// How zoomed-in the board opens / re-frames to. Above 1.0 so the tiles land
  /// comfortably spaced instead of crammed; the player can pinch out to 0.5×.
  static const double _frameZoom = 1.45;

  PartyController get controller => widget.controller;
  PartyActions get actions => widget.actions;

  /// Stash the resolved geometry each layout and frame the board the first time.
  void _onBoardLayout(_BoardGeometry geo, Size viewport) {
    _geo = geo;
    _viewport = viewport;
    if (!_framed) {
      _framed = true;
      _centerOn(controller.currentPlayer.position);
    }
  }

  /// Re-center the camera on the active player at the framing zoom.
  void _reframeOnActive() => _centerOn(controller.currentPlayer.position);

  /// Point the camera at board space [index] at [_frameZoom]. No-op until the
  /// board has laid out at least once (geometry/viewport known).
  void _centerOn(int index) {
    final geo = _geo;
    final viewport = _viewport;
    if (geo == null || viewport == null) return;
    final target = geo.nodeCenter(index);
    const z = _frameZoom;
    const margin = _kBoardBoundaryMargin;

    // Translation that would center [target] at zoom [z].
    double tx = viewport.width / 2 - target.dx * z;
    double ty = viewport.height / 2 - target.dy * z;

    // Clamp to the SAME pan boundary the InteractiveViewer enforces (canvas
    // size + boundaryMargin). Otherwise centering an edge tile writes a
    // transform outside the legal region and the player's first drag snaps the
    // camera back — the "fighting the camera" feel. min(lo, hi) guards the
    // clamp bounds in case the canvas is ever smaller than the viewport.
    const maxTx = margin * z;
    const maxTy = margin * z;
    final minTx = viewport.width - (geo.size.width + margin) * z;
    final minTy = viewport.height - (geo.size.height + margin) * z;
    tx = tx.clamp(min(minTx, maxTx), maxTx);
    ty = ty.clamp(min(minTy, maxTy), maxTy);

    _boardTransform.value = Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(z, z, z, 1);
  }

  @override
  void initState() {
    super.initState();
    _diceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _diceSettled = true);
        }
      });
    _boardTransform.addListener(_onZoom);
    _syncMovement();
  }

  // Rebuild on zoom so the board furniture (nodes, links, tokens) can
  // counter-scale to a constant on-screen size — zooming spreads the layout
  // apart while the dots stay the same size, instead of ballooning.
  void _onZoom() {
    if (mounted) setState(() {});
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
    final phase = controller.phase;
    final entering = phase != _lastSyncPhase;
    _lastSyncPhase = phase;
    if (phase == PartyPhase.moving) {
      // By the time we're walking the dice have settled (locked face shown).
      if (!_diceCtrl.isCompleted) _diceCtrl.value = 1.0;
      _diceSettled = true;
      _stepTimer ??= Timer.periodic(
          const Duration(milliseconds: 240), _onStepTick);
    } else {
      _stepTimer?.cancel();
      _stepTimer = null;
      if (phase == PartyPhase.rollResult) {
        // Throw the dice: cycle pip faces, then settle on the rolled value.
        if (entering) {
          _diceSettled = false;
          _diceCtrl.forward(from: 0);
        }
      } else if (phase != PartyPhase.chooseBranch &&
          phase != PartyPhase.shopOffer) {
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
    _diceCtrl.dispose();
    _boardTransform.dispose();
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
                _narratorBar(),
                const SizedBox(height: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: GestureDetector(
                      onDoubleTap: _reframeOnActive,
                      child: _BoardView(
                        controller: controller,
                        positionOf: (p) => p.position,
                        highlightPlayer: controller.currentPlayer.index,
                        transformController: _boardTransform,
                        viewScale: _boardTransform.value.getMaxScaleOnAxis(),
                        onLayout: _onBoardLayout,
                        onTapSpace: (space, i) =>
                            setState(() => _inspecting = i),
                        inspectedIndex: _inspecting,
                      ),
                    ),
                  ),
                ),
                _turnPanel(),
              ],
            ),
            if (_inspecting != null)
              _SpaceInspector(
                space: controller.board[_inspecting!],
                index: _inspecting!,
                controller: controller,
                onClose: () => setState(() => _inspecting = null),
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

  // ----------------------------------------------------------- narrator

  /// Hash calls the play-by-play. A persistent strip under the scoreboard that
  /// narrates each beat of the game in Hash's voice (leaf-green, the company's
  /// steady grinder).
  Widget _narratorBar() {
    const hashGreen = Color(0xFF7CB342);
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF13200D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hashGreen.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: hashGreen,
              shape: BoxShape.circle,
              border: Border.all(color: hashGreen, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/characters/hash.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Text('H',
                    style: TextStyle(
                        fontFamily: _kFont,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HASH · NARRATOR',
                    style: Potatuhs.label(color: const Color(0xFF9CCC65))),
                const SizedBox(height: 1),
                Text(
                  _hashNarration(),
                  style:
                      Potatuhs.body(size: 13, color: Potatuhs.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One line of Hash commentary for the current game beat. Prefers the live
  /// turn log (the real effect that just happened); otherwise a phase prompt.
  String _hashNarration() {
    final c = controller;
    final last = c.turnLog.isNotEmpty ? c.turnLog.last : null;
    final who = c.currentPlayer.name;
    switch (c.phase) {
      case PartyPhase.turnStart:
        return "Uhhh… $who, you're up. Give the dice a rip.";
      case PartyPhase.rollResult:
        return last ?? "$who lets it fly!";
      case PartyPhase.moving:
        return last ?? "$who is on the move…";
      case PartyPhase.chooseBranch:
        return "Fork in the road — $who, climb out or push deeper?";
      case PartyPhase.shopOffer:
        return last ?? "The market's open! Spend up, $who?";
      case PartyPhase.cardDecision:
        return last ?? "A card! $who, what'll it be?";
      case PartyPhase.spaceResolved:
        return last ?? "And $who sticks the landing.";
      case PartyPhase.minigameIntro:
        return "Mini-game time — everybody plays for the diamonds!";
      case PartyPhase.passPhone:
        return "Pass the phone — $who, you're on deck.";
      case PartyPhase.minigamePlaying:
        return "Go go go!";
      case PartyPhase.minigameResults:
        return "Let's tally it up…";
      case PartyPhase.gameOver:
        return "Uhhh… and that's a wrap. What a game, folks.";
    }
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
                diamonds: teamRank[i].diamonds,
                bold: true,
              ),
          for (var i = 0; i < ranked.length; i++)
            _chip(
              rank: i,
              color: ranked[i].color,
              name: ranked[i].name,
              potatoes: ranked[i].potatoes,
              diamonds: ranked[i].diamonds,
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
    required int diamonds,
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
          Text('$diamonds',
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
              for (var i = 0; i < turn.dice.length; i++)
                _die(turn.dice[i], p.color, i),
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
              for (var i = 0; i < turn.dice.length; i++)
                _die(turn.dice[i], p.color, i),
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
    } else if (phase == PartyPhase.cardDecision) {
      child = _cardDecision(p);
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
          Text(
            controller.currentPlayerIndex < controller.players.length - 1
                ? 'NEXT UP · ${controller.players[controller.currentPlayerIndex + 1].name.toUpperCase()}'
                : 'MINI-GAME ROUND NEXT',
            style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 10,
                letterSpacing: 1.5,
                color: Colors.white38),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: actions.confirmSpace,
            child: Container(
              height: 46,
              width: double.infinity,
              decoration: BoxDecoration(
                color: p.color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.color.withValues(alpha: 0.7)),
              ),
              child: const Center(
                child: Text(
                  'COMPLETE TURN',
                  style: TextStyle(
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
    if (controller.gameMap != null) {
      // xy maps carry their own forks and never set [isShortcut] (so the legacy
      // [kBoardBranches] lookup below would throw). Label by order delta from
      // the fork instead: the main path advances one step; a cut-through jumps
      // ahead; a bail-up doubles back toward safety.
      final delta = next - p.position;
      if (delta <= 1) {
        label = 'PRESS ON';
        sub = 'The main path onward';
        icon = Icons.arrow_forward;
      } else if (next > p.position) {
        label = 'CUT-THROUGH';
        sub = 'Skip ahead — riskier ground';
        icon = Icons.fast_forward;
      } else {
        label = 'BAIL OUT';
        sub = 'Double back toward safety';
        icon = Icons.u_turn_left;
      }
    } else if (!space.isShortcut) {
      label = 'STAY THE COURSE';
      sub = 'The main path onward';
      icon = Icons.arrow_forward;
    } else {
      final branch = kBoardBranches
          .firstWhere((b) => b.spaceIndices.contains(next));
      if (branch.mergeIndex < branch.forkIndex) {
        label = 'FILIBUSTER LOOP';
        sub = 'Orbit the Potato Market — stall for diamonds';
        icon = Icons.loop;
      } else {
        label = 'SHORTCUT LANE';
        sub = 'Skip ahead — risky spaces';
        icon = Icons.fast_forward;
      }
    }
    // Resolve the section via the controller so GameMap boards (8–10 sections)
    // don't index the fixed 6-entry legacy [kBoardSections] list and RangeError.
    final color = controller.sectionOf(space).color;
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
    final potatoAfford = p.diamonds >= kPotatoPrice;
    final packFull = p.items.length >= kMaxItems;
    return Column(
      key: const ValueKey('shop'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '🥔  THE MARKET  🥔',
          style: TextStyle(
              fontFamily: _kFont,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Color(0xFFD7A86E)),
        ),
        const SizedBox(height: 4),
        Text(
          '${p.diamonds} 💎  ·  ${p.potatoes} 🥔  ·  pack ${p.items.length}/$kMaxItems',
          style: const TextStyle(
              fontFamily: _kFont, fontSize: 12, color: Colors.white60),
        ),
        const SizedBox(height: 10),
        // The win-condition buy: a potato.
        GestureDetector(
          onTap: potatoAfford ? actions.buyPotato : null,
          child: Opacity(
            opacity: potatoAfford ? 1 : 0.4,
            child: Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFD7A86E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  'BUY POTATO  ·  $kPotatoPrice 💎',
                  style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 1),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            packFull ? 'ITEMS · pack full' : 'ITEMS',
            style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 11,
                letterSpacing: 1.5,
                color: Colors.white38),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          alignment: WrapAlignment.center,
          children: [
            for (final item in kItemShop) _shopItemButton(p, item, packFull),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: actions.skipPotato,
          child: Container(
            width: double.infinity,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white30),
            ),
            child: const Center(
              child: Text(
                'LEAVE MARKET',
                style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                    letterSpacing: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// A buyable item pill: icon, label, diamond price. Dimmed and inert when the
  /// player can't afford it or their pack is full.
  Widget _shopItemButton(PartyPlayer p, PowerUp item, bool packFull) {
    final price = kItemPrices[item] ?? 999;
    final enabled = !packFull && p.diamonds >= price;
    return GestureDetector(
      onTap: enabled ? () => actions.buyItem(item) : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Potatuhs.inkPanel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Potatuhs.gold.withValues(alpha: 0.6), width: 1.3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 18, color: Potatuhs.gold),
              const SizedBox(height: 3),
              Text(item.label,
                  style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              Text('$price 💎',
                  style: const TextStyle(
                      fontFamily: _kFont, fontSize: 9, color: Colors.white60)),
            ],
          ),
        ),
      ),
    );
  }

  /// A drawn DECISION card waiting on the player's A/B pick.
  Widget _cardDecision(PartyPlayer p) {
    final card = controller.currentCard;
    if (card == null) {
      // Defensive: shouldn't happen, but never strand the player.
      return Column(
        key: const ValueKey('cardless'),
        mainAxisSize: MainAxisSize.min,
        children: [
          PotatuhsButton(
            label: 'CONTINUE',
            display: true,
            fill: p.color,
            textColor: Colors.black,
            onTap: () => actions.chooseCardOption(0),
          ),
        ],
      );
    }
    final wild = card.deck == CardDeck.wild;
    final accent = wild ? const Color(0xFF9B6DFF) : const Color(0xFF6FCF6B);
    return Column(
      key: const ValueKey('card'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          wild ? 'VOID CARD' : 'TATER CARD',
          style: TextStyle(
              fontFamily: _kFont,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: accent),
        ),
        const SizedBox(height: 2),
        Text(
          card.title,
          style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          card.text,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontFamily: _kFont, fontSize: 12, color: Colors.white60),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < card.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => actions.chooseCardOption(i),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    Text(
                      String.fromCharCode(65 + i), // A, B, …
                      style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        card.options[i].label,
                        style: const TextStyle(
                            fontFamily: _kFont,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white38),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// A single pip-face die. [index] varies the tumble phase so two dice don't
  /// flip in lockstep. The animation is purely cosmetic — [value] is the rolled
  /// number from the controller and is what shows once the throw settles.
  Widget _die(int value, Color color, int index) {
    return AnimatedBuilder(
      animation: _diceCtrl,
      builder: (context, _) {
        final t = _diceCtrl.value;
        // Faces lock at 75%; the last quarter is the elastic settle bounce.
        final locked = _diceSettled || t >= 0.75;
        final int face;
        double scale;
        double rot;
        if (!locked) {
          final u = t / 0.75; // 0..1 across the tumble
          // Cycle pip faces fast, offset per die so they differ frame-to-frame.
          face = 1 + (((t * 26).floor()) + index * 2) % 6;
          scale = 0.86 + 0.14 * u;
          rot = (1 - u) * 0.55 * sin(t * 46 + index); // diminishing wobble
        } else {
          face = value;
          if (_diceSettled) {
            scale = 1;
          } else {
            // Settle quarter (t 0.75..1): slam down with an elastic overshoot.
            final u = ((t - 0.75) / 0.25).clamp(0.0, 1.0);
            scale = 1 + 0.26 * (1 - Curves.elasticOut.transform(u));
          }
          rot = 0;
        }
        return Transform.rotate(
          angle: rot,
          child: Transform.scale(
            scale: scale,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFE8E8EC)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: locked ? 0.55 : 0.35),
                      blurRadius: locked ? 12 : 7),
                ],
              ),
              child: CustomPaint(
                painter: _DiePainter(face, color),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Paints the pip layout for a d6 face (1–6) — the dots that make a die read
/// as a die. Pip color is tinted toward the player's accent.
class _DiePainter extends CustomPainter {
  final int face;
  final Color accent;
  const _DiePainter(this.face, this.accent);

  // 3×3 grid slots a face lights up, in (col,row) with col/row ∈ {0,1,2}.
  static const Map<int, List<List<int>>> _pips = {
    1: [
      [1, 1]
    ],
    2: [
      [0, 0],
      [2, 2]
    ],
    3: [
      [0, 0],
      [1, 1],
      [2, 2]
    ],
    4: [
      [0, 0],
      [2, 0],
      [0, 2],
      [2, 2]
    ],
    5: [
      [0, 0],
      [2, 0],
      [1, 1],
      [0, 2],
      [2, 2]
    ],
    6: [
      [0, 0],
      [2, 0],
      [0, 1],
      [2, 1],
      [0, 2],
      [2, 2]
    ],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final pips = _pips[face.clamp(1, 6)]!;
    final r = size.width * 0.085;
    final cols = [size.width * 0.28, size.width * 0.5, size.width * 0.72];
    final rows = [size.height * 0.28, size.height * 0.5, size.height * 0.72];
    final fill = Paint()
      ..color = Color.lerp(Colors.black, accent, 0.35)!
      ..style = PaintingStyle.fill;
    for (final p in pips) {
      canvas.drawCircle(Offset(cols[p[0]], rows[p[1]]), r, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _DiePainter old) =>
      old.face != face || old.accent != accent;
}

// ---------------------------------------------------------------------------
// Board view: a rounded-rectangle racetrack loop. The main spaces sit evenly
// around the ring (coloured by section); shortcut/filibuster lanes are chords
// cutting across the open middle. Tokens slide node-to-node around the loop.
// ---------------------------------------------------------------------------

/// Structured "what is this tile" data for the tap-to-inspect sheet.
typedef _SpaceInfo = ({String region, String title, String effect, IconData icon, Color color});

_SpaceInfo _inspectSpace(PartyController c, BoardSpace space, int index) {
  final sec = c.sectionOf(space);
  final region = c.gameMap != null ? sec.name : '';
  final lane = space.isShortcut ? ' · risky shortcut lane' : '';
  final isAnchor =
      c.gameMap != null && space.order == c.board.length - 1;
  if (isAnchor) {
    return (
      region: region,
      title: 'The Anchor',
      effect: 'The finish line + potato market — buy a potato for '
          '$kPotatoPrice diamonds.',
      icon: Icons.flag,
      color: const Color(0xFFD7A86E),
    );
  }
  switch (space.type) {
    case SpaceType.gain:
      return (region: region, title: 'Diamond Space$lane',
          effect: 'Land here: +5 diamonds.',
          icon: Icons.add, color: const Color(0xFF81C784));
    case SpaceType.lose:
      return (region: region, title: 'Entropy Space$lane',
          effect: 'Land here: −5 diamonds (a Void Shield blocks it).',
          icon: Icons.remove, color: const Color(0xFFE57373));
    case SpaceType.powerUp:
      final pu = sec.powerUp;
      final theme = sec.powerUpTheme;
      final name = theme != null ? '${pu.label} · $theme' : pu.label;
      return (region: region, title: '$name$lane',
          effect: 'Pick it up to use on your turn: ${pu.description}.',
          icon: Icons.bolt, color: const Color(0xFFFFD54F));
    case SpaceType.event:
      return (region: region, title: 'Event Space$lane',
          effect: 'Triggers a random cosmic event.',
          icon: Icons.help_outline, color: const Color(0xFF80DEEA));
    case SpaceType.shop:
      return (region: region, title: 'Potato Market',
          effect: 'Spend $kPotatoPrice diamonds for a potato.',
          icon: Icons.storefront, color: const Color(0xFFD7A86E));
    case SpaceType.cardCommon:
      return (region: region, title: 'Tater Card$lane',
          effect: 'Draw a common card — usually upside.',
          icon: Icons.style, color: const Color(0xFF80DEEA));
    case SpaceType.cardWild:
      return (region: region, title: 'Void Card$lane',
          effect: 'Draw a wild card — big swings, can hurt.',
          icon: Icons.auto_awesome, color: const Color(0xFFCE93D8));
  }
}

/// Bottom card that explains the tapped tile — "what happens if you land here".
class _SpaceInspector extends StatelessWidget {
  final BoardSpace space;
  final int index;
  final PartyController controller;
  final VoidCallback onClose;

  const _SpaceInspector({
    required this.space,
    required this.index,
    required this.controller,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final info = _inspectSpace(controller, space, index);
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
          decoration: BoxDecoration(
            color: const Color(0xF21A1A24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: info.color.withValues(alpha: 0.6)),
            boxShadow: Potatuhs.glow(info.color, strength: 0.22, blur: 14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: info.color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: info.color.withValues(alpha: 0.7)),
                ),
                child: Icon(info.icon, color: info.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (info.region.isNotEmpty)
                      Text(info.region.toUpperCase(),
                          style: Potatuhs.label(
                              size: 9.5, color: info.color)),
                    Text(info.title,
                        style: const TextStyle(
                            fontFamily: _kFont,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 3),
                    Text(info.effect,
                        style: const TextStyle(
                            fontFamily: _kFont,
                            fontSize: 12.5,
                            height: 1.3,
                            color: Colors.white70)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, color: Colors.white38, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pan slack (px) allowed outside the board canvas, in canvas space. Shared by
/// the [InteractiveViewer] boundary and [_BoardScreenState._centerOn]'s clamp so
/// a programmatic frame can never land outside the legal pan region.
const double _kBoardBoundaryMargin = 240.0;

class _BoardView extends StatelessWidget {
  final PartyController controller;
  final int Function(PartyPlayer) positionOf;
  final int highlightPlayer;
  final TransformationController transformController;

  /// Current pinch-zoom scale; node/link/token sizes divide by this so they
  /// keep a constant on-screen size as the board zooms.
  final double viewScale;

  /// Fires once per layout with the resolved board geometry and the viewport
  /// size, so the owning state can frame the board (center + initial zoom) the
  /// first time and re-center on a double-tap instead of snapping to a blank
  /// fit. Stateless here keeps the heavy geometry where it's computed.
  final void Function(_BoardGeometry geo, Size viewport)? onLayout;

  /// Called when a tile is tapped — opens the tap-to-inspect sheet.
  final void Function(BoardSpace space, int index)? onTapSpace;

  /// The space currently being inspected (highlighted on the board), if any.
  final int? inspectedIndex;

  const _BoardView({
    required this.controller,
    required this.positionOf,
    required this.highlightPlayer,
    required this.transformController,
    required this.viewScale,
    this.onLayout,
    this.onTapSpace,
    this.inspectedIndex,
  });

  /// How much larger than the viewport the board canvas is. A roomier canvas
  /// spreads the tiles apart in absolute terms; you pan/zoom across it rather
  /// than cramming all 88 spaces into one screen.
  static const double kCanvasSpread = 1.8;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        // The board lives on a canvas larger than the viewport so the tiles get
        // real breathing room; you pan/zoom across it.
        final canvas = Size(
            viewport.width * kCanvasSpread, viewport.height * kCanvasSpread);
        final geo = _BoardGeometry(
          canvas,
          spaces: controller.board,
          useXY: controller.gameMap != null,
          scale: viewScale,
        );

        // Hand the geometry back so the owner can frame the board once.
        if (onLayout != null) {
          final cb = onLayout!;
          WidgetsBinding.instance
              .addPostFrameCallback((_) => cb(geo, viewport));
        }

        // Group tokens by node so co-located tokens fan out around it.
        final tokensAt = <int, List<PartyPlayer>>{};
        for (final p in controller.players) {
          tokensAt.putIfAbsent(positionOf(p), () => []).add(p);
        }

        final startCenter = geo.nodeCenter(0);

        // Pinch to zoom + drag to pan the board; nodes, links and tokens scale
        // with the zoom. Double-tap re-frames on the active player. The
        // transform is held by the parent state so it survives the frequent
        // step-by-step rebuilds. Tapping a space opens the inspector sheet.
        return InteractiveViewer(
            transformationController: transformController,
            // The board canvas is [kCanvasSpread]× the viewport, i.e. LARGER
            // than the viewer. Without this the child is clamped to viewport
            // size and the far bottom/right of the board (incl. the boss/anchor)
            // is unreachable by any pan — the "can't scroll to see where I'm
            // going" bug. `constrained: false` lets the child take its natural
            // 1.8× size so the whole board is pannable.
            constrained: false,
            minScale: 0.5,
            maxScale: 5.0,
            boundaryMargin: const EdgeInsets.all(_kBoardBoundaryMargin),
            child: SizedBox(
              width: canvas.width,
              height: canvas.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
            // Territory watermarks — legacy ring only (the new maps carry
            // their own 8–10 sections and skip the centroid watermark).
            if (controller.gameMap == null)
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
            // The mischief crew rides above the player tokens so a loot-carrying
            // op is easy to spot and chase.
            for (final op in controller.ops) _opToken(geo, op),
            // The landing beat's number pop — floats the resource delta over
            // the tile the moment its effect resolves.
            if (controller.lastLanding != null)
              _landingPop(geo, controller.lastLanding!),
              ],
              ),
            ),
        );
      },
    );
  }

  /// Floating "+5 💎" / "−5 💎" over the landed tile — the number pop that
  /// makes a landing's consequence readable at the moment it resolves. A
  /// one-shot rise-and-fade, restarted by the seq key on each fresh landing;
  /// the text subtree is hoisted into `child:` so only the transform/opacity
  /// rebuild per frame.
  Widget _landingPop(_BoardGeometry geo, LandingEffect fx) {
    final center = geo.nodeCenter(fx.position);
    final parts = <String>[
      if (fx.diamonds != 0) '${fx.diamonds > 0 ? '+' : ''}${fx.diamonds} 💎',
      if (fx.potatoes != 0) '${fx.potatoes > 0 ? '+' : ''}${fx.potatoes} 🥔',
    ];
    final gain = fx.diamonds > 0 || fx.potatoes > 0;
    return Positioned(
      key: ValueKey('landing_${fx.seq}'),
      left: center.dx - 60,
      top: center.dy - geo.nodeRadius * 2.2,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOut,
          builder: (context, t, child) => Opacity(
            opacity: t < 0.65 ? 1.0 : ((1 - t) / 0.35).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -geo.nodeRadius * 1.6 * t),
              child: child,
            ),
          ),
          child: SizedBox(
            width: 120,
            child: Text(
              parts.join('  '),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: geo.nodeRadius * 1.15,
                fontWeight: FontWeight.w900,
                color: gain ? _kAccent : const Color(0xFFE5484D),
                shadows: const [
                  Shadow(color: Colors.black, blurRadius: 6),
                  Shadow(color: Colors.black, blurRadius: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A roaming op token (the Peeler / the Masher). Sits just above its tile;
  /// when carrying stolen loot it pulses red with a 💎/🥔 badge so players know
  /// who to chase.
  Widget _opToken(_BoardGeometry geo, OpToken op) {
    final center = geo.nodeCenter(op.position);
    final r = geo.nodeRadius * 0.5;
    const danger = Color(0xFFE5484D);
    final loot = op.hasLoot;
    return AnimatedPositioned(
      key: ValueKey('op_${op.op.id}'),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      // Perch on the upper rim of the tile so it doesn't hide the players.
      left: center.dx - r,
      top: center.dy - geo.nodeRadius - r,
      child: SizedBox(
        width: r * 2,
        height: r * 2,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: r * 2,
              height: r * 2,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(
                    color: loot ? danger : Colors.white54,
                    width: loot ? 2.5 : 1.5),
                boxShadow: [
                  BoxShadow(
                      color: (loot ? danger : Colors.black)
                          .withValues(alpha: loot ? 0.8 : 0.5),
                      blurRadius: loot ? 10 : 4),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  op.op.asset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.theater_comedy,
                      color: danger, size: 18),
                ),
              ),
            ),
            if (loot)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: danger,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    op.potatoes > 0 ? '🥔${op.potatoes}' : '💎${op.diamonds}',
                    style: const TextStyle(
                        fontFamily: _kFont,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
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
    var color = controller.sectionOf(space).color;

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
      case SpaceType.cardCommon:
        icon = Icons.style;
        iconColor = const Color(0xFF80DEEA);
        break;
      case SpaceType.cardWild:
        icon = Icons.auto_awesome;
        iconColor = const Color(0xFFCE93D8);
        break;
    }

    final isInspected = inspectedIndex == index;
    // A bigger invisible hit-target than the dot so crowded tiles stay tappable.
    final hit = max(r * 2, 30.0);
    return Positioned(
      left: center.dx - hit / 2,
      top: center.dy - hit / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTapSpace?.call(space, index),
        child: SizedBox(
          width: hit,
          height: hit,
          child: Center(
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
              color: isInspected
                  ? Colors.white
                  : isStart || isShop
                      ? color
                      : color.withValues(alpha: space.isShortcut ? 0.7 : 0.55),
              width: isInspected ? 2.6 : (isStart || isShop ? 1.8 : 1.2),
            ),
            boxShadow: [
              BoxShadow(
                  color: (isInspected ? Colors.white : color)
                      .withValues(alpha: isInspected ? 0.6 : (isShop ? 0.5 : 0.30)),
                  blurRadius: isShop ? 14 : 9),
            ],
          ),
          child: Icon(icon,
              size: r * (isShop ? 1.1 : 0.95),
              color: iconColor.withValues(alpha: 0.9)),
        ),
          ),
        ),
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
      final tr = geo.nodeRadius * (isCurrent ? 0.52 : 0.44);
      // Lone token sits on the node; groups fan out around its rim.
      final fan = players.length > 1 ? geo.nodeRadius * 0.75 : 0.0;
      final angle = 2 * pi * j / players.length - pi / 2;
      final off = Offset(cos(angle) * fan, sin(angle) * fan);
      final asset = kCharacters[p.character % kCharacters.length].asset;
      widgets.add(AnimatedPositioned(
        key: ValueKey('token_${p.index}'),
        // Matches the per-step walk cadence so the character visibly slides
        // node-to-node toward its next location.
        duration: const Duration(milliseconds: 230),
        curve: Curves.easeInOut,
        left: center.dx + off.dx - tr,
        top: center.dy + off.dy - tr,
        child: Container(
          width: tr * 2,
          height: tr * 2,
          decoration: BoxDecoration(
            color: p.color,
            shape: BoxShape.circle,
            border: Border.all(
                color: isCurrent ? Colors.white : Colors.black,
                width: isCurrent ? 2.5 : 1.5),
            boxShadow: [
              BoxShadow(
                  color: p.color.withValues(alpha: 0.85),
                  blurRadius: isCurrent ? 8 : 4),
            ],
          ),
          // The character sprite rides the token; falls back to the solid color
          // chip if the asset is missing.
          child: asset == null
              ? null
              : ClipOval(
                  child: Image.asset(
                    asset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
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

  /// The spaces being rendered, and whether to lay them out by their own
  /// normalized (x,y) — true for the three [GameMap]s, false for the legacy ring.
  final List<BoardSpace> spaces;
  final bool useXY;

  /// Live pinch-zoom scale. Node/link/token sizes divide by this so they hold
  /// a constant on-screen size while the layout zooms.
  final double viewScale;

  _BoardGeometry(this.size,
      {this.spaces = const [], this.useXY = false, double scale = 1.0})
      : viewScale = scale <= 0 ? 1.0 : scale,
        rect = _boardRect(size),
        corner = _boardCorner(size) {
    loop = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(corner)));
    _metric = loop.computeMetrics().first;
    _len = _metric.length;
    final base = useXY
        ? min(15.0, min(rect.width, rect.height) / 18)
        : min(22.0, _len / kMainLoopLength * 0.42);
    nodeRadius = base / viewScale;
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
    if (useXY) {
      final s = spaces[index];
      return Offset(rect.left + s.x * rect.width, rect.top + s.y * rect.height);
    }
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
    // New maps lay out by (x,y): draw path links + ladders/snakes/slides and
    // skip the legacy ring entirely.
    if (geo.useXY) {
      _paintTopology(canvas);
      return;
    }
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

  /// Renders a [GameMap] topology: thin links along the path, plus accented
  /// strokes for ladders (green, forward) and snakes/back-slides (red).
  void _paintTopology(Canvas canvas) {
    final spaces = geo.spaces;
    final z = geo.viewScale; // counter-scale strokes to constant on-screen width
    final link = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 / z
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.20);
    for (final s in spaces) {
      final from = geo.nodeCenter(s.order);
      for (final n in s.nexts) {
        canvas.drawLine(from, geo.nodeCenter(n), link);
      }
    }
    for (final s in spaces) {
      final j = s.jumpTo;
      if (j == null) continue;
      final col = j > s.order
          ? const Color(0xFF81C784) // ladder / slide up
          : const Color(0xFFE57373); // snake back
      final a = geo.nodeCenter(s.order);
      final b = geo.nodeCenter(j);
      canvas.drawLine(
        a,
        b,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 / z
          ..strokeCap = StrokeCap.round
          ..color = col.withValues(alpha: 0.75),
      );
      _arrow(canvas, Offset.lerp(a, b, 0.85)!, b - a, col, 6 / z);
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
                  controller.isBossRound
                      ? 'FINAL ROUND ${controller.round}'
                      : 'MINI-GAME ROUND ${controller.round}',
                  style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: Colors.white54),
                ),
              ),
              if (controller.isBossRound && controller.currentBoss != null) ...[
                const SizedBox(height: 14),
                _bossBanner(controller.currentBoss!),
              ],
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
                  controller.isBossRound
                      ? 'BOSS STAKES: the top scorer EARNS a potato — the '
                          'lowest scorer LOSES one. Diamonds still pay out.'
                      : 'Everyone plays once. Diamonds go to the best scores — '
                          'spend them on potatoes at the market.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 13,
                      color: controller.isBossRound
                          ? const Color(0xFFFFB4A2)
                          : Colors.white70),
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

  /// The boss showdown header — the op's portrait, name, and a "BOSS ROUND"
  /// flag. Shown only on the final round when the map fields a boss.
  Widget _bossBanner(Op boss) {
    const danger = Color(0xFFE5484D);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: danger.withValues(alpha: 0.7), width: 1.5),
          boxShadow: [
            BoxShadow(color: danger.withValues(alpha: 0.35), blurRadius: 16),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                boss.asset,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.whatshot, color: danger, size: 40),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BOSS ROUND',
                  style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: danger),
                ),
                Text(
                  boss.name,
                  style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
          ],
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
                                '${t.diamonds} diamonds',
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
                            '${p.diamonds}',
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
