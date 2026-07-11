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
import 'board_ambient.dart';
import 'board_life_tuning.dart';
import 'party_setup_page.dart';
import 'round_ceremony.dart';
import 'round_flair.dart';
import 'standings_sheet.dart';
import 'wheel_screen.dart';

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

  /// Non-null when this session is an ONLINE match (set once at initState).
  PartyNet? _net;

  // ── Wheel payoff hold + round flair (presentation-only) ──────────────────
  PartyController? _payoffController;
  int _wheelPayoffDone = 0;
  int _flairDoneRound = 1; // rounds 2+ get a flair beat before the board

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
      case PartyPhase.wheelSpin:
        return const Duration(milliseconds: 1600);
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
      case PartyPhase.wheelSpin:
        a.wheelStop(-1); // autoplay has no eyes on the wheel: tape draw
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
    // Modal language per potatuhs-design: dark panel, gold accent, display
    // title, one FILLED primary action (the safe one) and one quiet escape —
    // not two grey text links fighting for attention.
    final quit = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          decoration: BoxDecoration(
            color: Potatuhs.inkPanel,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: Potatuhs.gold.withValues(alpha: 0.5), width: 1.5),
            boxShadow: Potatuhs.glow(Potatuhs.gold, strength: 0.18, blur: 30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('QUIT GAME?',
                  textAlign: TextAlign.center,
                  style: Potatuhs.display(size: 24, color: Potatuhs.gold)),
              const SizedBox(height: 10),
              Text('This run ends here — progress will be lost.',
                  textAlign: TextAlign.center,
                  style:
                      Potatuhs.body(size: 15, color: Potatuhs.textSecondary)),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: () => Navigator.pop(context, false),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: Potatuhs.gold,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: Potatuhs.glow(Potatuhs.gold,
                        strength: 0.35, blur: 16),
                  ),
                  child: Center(
                    child: Text('KEEP PLAYING',
                        style: Potatuhs.body(
                                size: 16,
                                weight: FontWeight.w900,
                                color: Colors.black)
                            .copyWith(letterSpacing: 2)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.pop(context, true),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Center(
                    child: Text('QUIT',
                        style: Potatuhs.body(
                                size: 14,
                                weight: FontWeight.w700,
                                color: Potatuhs.textFaint)
                            .copyWith(letterSpacing: 2)),
                  ),
                ),
              ),
            ],
          ),
        ),
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

    // Wheel payoff hold: the LAST stop of a session (and every single-spinner
    // winner spin) exits wheelSpin the instant it lands, which would cut the
    // payoff. Keep the wheel up in outro mode until its deceleration + result
    // moment has played (or been tapped through). Presentation-only.
    if (_payoffController != c) {
      _payoffController = c;
      _wheelPayoffDone = 0;
      _flairDoneRound = 1;
    }
    final wheelResult = c.lastWheelResult;
    if (c.phase != PartyPhase.wheelSpin &&
        wheelResult != null &&
        wheelResult.seq > _wheelPayoffDone) {
      return WheelScreen(
        key: ValueKey('wheel_outro_${wheelResult.seq}'),
        controller: c,
        actions: actions,
        mySlot: mySlot,
        isOnline: isOnline,
        outroSeq: wheelResult.seq,
        onOutroDone: () => setState(() => _wheelPayoffDone = wheelResult.seq),
      );
    }

    // Round flair (SPEC §5): after the ceremony + wheel resolve into a new
    // round, one short cutscene beat plays before the board comes back —
    // round 2 is the ghost debut. Deterministic content, local pacing.
    final onBoard = switch (c.phase) {
      PartyPhase.turnStart ||
      PartyPhase.rollResult ||
      PartyPhase.moving ||
      PartyPhase.chooseBranch ||
      PartyPhase.shopOffer ||
      PartyPhase.cardDecision ||
      PartyPhase.spaceResolved =>
        true,
      _ => false,
    };
    if (onBoard && c.wheels && c.round > 1 && _flairDoneRound < c.round) {
      return RoundFlairScreen(
        key: ValueKey('flair_${c.round}'),
        controller: c,
        onDone: () => setState(() => _flairDoneRound = c.round),
      );
    }

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
        // Held for its moment (SPEC: a dialog beat before the game): local
        // taps through; online the room host taps or auto-advances.
        final intro = _MiniGameIntroScreen(
          controller: c,
          actions: actions,
          interactive: !isOnline || net.isHost,
        );
        return isOnline && net.isHost
            ? _AutoAdvanceAfter(
                key: ValueKey('mg_intro_${c.round}'),
                delay: const Duration(seconds: 6),
                onFire: actions.beginMiniGameRound,
                child: intro,
              )
            : intro;
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
        final attemptKey = 'mg_${c.round}_${player.index}_${spec.id}';
        return MiniGameHost(
          // New host per attempt so state never leaks between players.
          key: ValueKey(attemptKey),
          spec: spec,
          playerLabel: '${player.name}$teamTag',
          onComplete: actions.recordMiniScore,
          onExit: () => actions.recordMiniScore(0),
          // Attract: the bot plays each player's attempt and auto-submits.
          autoPlay: widget.autoPilot,
          // VOTE TO SKIP — the table's escape hatch (majority skips the
          // round; replaces both the debug skip and the old auto-bank
          // watchdog). Rides the intro's START row and leaves with it —
          // never over live gameplay.
          introAction: _VoteSkipButton(
            controller: c,
            actions: actions,
            mySeat: isOnline ? mySlot : c.miniPlayerIndex,
          ),
        );
      case PartyPhase.minigameResults:
        // The round ceremony: everyone watches the same podium reveal; the
        // host (or the local player) advances it, with an auto-dwell online.
        return RoundCeremonyScreen(
          controller: c,
          actions: actions,
          interactive: !isOnline || net.isHost,
          autoAdvance: isOnline && net.isHost,
          // The feedback prompt is for humans — attract's bots don't rate.
          showFeedback: !widget.autoPilot,
        );
      case PartyPhase.gameOver:
        if (isOnline) PartySession.clear();
        return _PodiumScreen(
          controller: c,
          onPlayAgain: isOnline ? widget.onExit : _backToSetup,
          onExit: widget.onExit,
        );
      case PartyPhase.wheelSpin:
        return WheelScreen(
          controller: c,
          actions: actions,
          mySlot: mySlot,
          isOnline: isOnline,
        );
    }
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
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

  /// Tweens the camera between nodes during the walk (and on re-frames) with
  /// the SAME duration/curve as the token's AnimatedPositioned slide, so the
  /// camera and character travel together. Writing the target transform
  /// directly made the whole board JUMP a node each step while the token then
  /// glided to catch up — the "visceral jerk".
  late final AnimationController _camCtrl;
  late final Animation<double> _camEase;
  Matrix4Tween? _camTween;

  /// Last zoom scale [_onZoom] rebuilt for. Board furniture (nodes, links,
  /// tokens) only counter-scales on SCALE changes — pan/translation is applied
  /// by the InteractiveViewer itself — so camera tweens and drags must not
  /// trigger a whole-board rebuild every frame.
  double _lastZoomScale = 1.0;

  /// One-time flag so we frame the board (center + initial zoom) on first
  /// layout, then leave the camera under the player's control.
  bool _framed = false;
  _BoardGeometry? _geo;
  Size? _viewport;

  /// The board space currently open in the tap-to-inspect sheet, if any.
  int? _inspecting;

  /// The board-life ambient clock (Stage 0 spine) — null on maps without a
  /// life layer, so the legacy ring and unstyled maps pay zero cost. Ticks
  /// only while the board is on screen: this State unmounts during
  /// mini-games/cutscenes (the phase switch swaps screens), and
  /// [didChangeAppLifecycleState] pauses it while the app is backgrounded.
  BoardAmbientClock? _ambient;

  /// How zoomed-in the board opens / re-frames to. Above 1.0 so the tiles land
  /// comfortably spaced instead of crammed; the player can pinch out as far as
  /// a whole-board overview (minScale = 1 / kCanvasSpread).
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
  void _reframeOnActive() =>
      _centerOn(controller.currentPlayer.position, animate: true);

  /// Point the camera at board space [index] — at [_frameZoom] by default, or
  /// a caller-chosen [zoom] (the walk uses the wider [kWalkCameraZoom]). No-op
  /// until the board has laid out at least once (geometry/viewport known).
  /// With [animate], the camera glides there (step cadence) instead of
  /// snapping — the walk's per-step camera move MUST use this or the board
  /// jumps.
  void _centerOn(int index, {bool animate = false, double zoom = _frameZoom}) {
    final geo = _geo;
    if (geo == null || _viewport == null) return;
    _driveCamera(geo.nodeCenter(index), zoom, animate: animate);
  }

  /// Step the zoom by [factor] (the +/− buttons), keeping whatever world point
  /// is at the viewport center fixed so the board scales in place instead of
  /// drifting. Clamped to the same limits the pinch gesture obeys.
  void _zoomBy(double factor) {
    final viewport = _viewport;
    if (_geo == null || viewport == null) return;
    final m = _boardTransform.value;
    final z0 = m.getMaxScaleOnAxis();
    final z = (z0 * factor)
        .clamp(_BoardView.kMinZoom, _BoardView.kMaxZoom)
        .toDouble();
    if ((z - z0).abs() < 0.001) return;
    final t = m.getTranslation();
    final focus = Offset(
        (viewport.width / 2 - t.x) / z0, (viewport.height / 2 - t.y) / z0);
    _driveCamera(focus, z, animate: true);
  }

  /// Write the camera transform that puts world point [focus] at the viewport
  /// center at zoom [z] — the single path every programmatic camera move
  /// (re-frames, walk steps, zoom buttons) goes through.
  void _driveCamera(Offset focus, double z, {required bool animate}) {
    final geo = _geo!;
    final viewport = _viewport!;
    const margin = _kBoardBoundaryMargin;

    // Translation that would center [focus] at zoom [z].
    double tx = viewport.width / 2 - focus.dx * z;
    double ty = viewport.height / 2 - focus.dy * z;

    // Clamp to the SAME pan boundary the InteractiveViewer enforces (canvas
    // size + boundaryMargin). Otherwise centering an edge tile writes a
    // transform outside the legal region and the player's first drag snaps the
    // camera back — the "fighting the camera" feel. min(lo, hi) guards the
    // clamp bounds in case the canvas is ever smaller than the viewport.
    final maxTx = margin * z;
    final maxTy = margin * z;
    final minTx = viewport.width - (geo.size.width + margin) * z;
    final minTy = viewport.height - (geo.size.height + margin) * z;
    tx = tx.clamp(min(minTx, maxTx), maxTx);
    ty = ty.clamp(min(minTy, maxTy), maxTy);

    final targetMatrix = Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(z, z, z, 1);
    if (!animate) {
      _camCtrl.stop();
      _camTween = null;
      _boardTransform.value = targetMatrix;
      return;
    }
    _camTween =
        Matrix4Tween(begin: _boardTransform.value.clone(), end: targetMatrix);
    _camCtrl.forward(from: 0);
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
    // Matches the token's AnimatedPositioned hop ([kWalkHopMs], easeInOut) so
    // the camera arrives at the node exactly when the character does, then
    // RESTS with it for the remainder of the step period (board-game feel).
    _camCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: kWalkHopMs),
    );
    _camEase = CurvedAnimation(parent: _camCtrl, curve: Curves.easeInOut);
    _camCtrl.addListener(() {
      final tween = _camTween;
      if (tween != null) _boardTransform.value = tween.evaluate(_camEase);
    });
    _boardTransform.addListener(_onZoom);
    final mapId = controller.gameMap?.id;
    if (mapId != null && kBoardLifeMaps.contains(mapId)) {
      _ambient = BoardAmbientClock(this)..start();
      WidgetsBinding.instance.addObserver(this);
    }
    _syncMovement();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Battery: the ambient clock must not tick while the app is backgrounded.
    if (state == AppLifecycleState.resumed) {
      _ambient?.start();
    } else {
      _ambient?.stop();
    }
  }

  // Rebuild on zoom so the board furniture (nodes, links, tokens) can
  // counter-scale to a constant on-screen size — zooming spreads the layout
  // apart while the dots stay the same size, instead of ballooning. Gated to
  // actual SCALE changes: pans (drags, per-step camera tweens) re-transform
  // the existing raster via the InteractiveViewer and must not rebuild the
  // whole board every frame.
  void _onZoom() {
    final s = _boardTransform.value.getMaxScaleOnAxis();
    if ((s - _lastZoomScale).abs() < 0.001) return;
    _lastZoomScale = s;
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
      // Bring the camera to the walker BEFORE the first hop — pulled out to
      // the walk zoom so several spaces ahead are visible for the whole move
      // (PARTY UX LAW: the player watches a journey, not a chase). The first
      // timer tick lands a full step period later — the glide has finished.
      if (entering) {
        _centerOn(controller.currentPlayer.position,
            animate: true, zoom: kWalkCameraZoom);
      }
      _stepTimer ??= Timer.periodic(
          const Duration(milliseconds: kWalkStepPeriodMs), _onStepTick);
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
    //
    // setState: the token's hop and the camera's glide are driven by this SAME
    // tick. The board rebuild must not depend on the controller-notify chain —
    // when it stalls, the camera (which needs no rebuild) marches to the
    // destination while the character stands still until some foreign rebuild
    // teleports it (checkpoint 2026-07-10).
    setState(() {
      actions.advanceStep();
    });
    // The camera walks WITH the token, node to node — movement is a tracked
    // journey across the board, not a teleport at the edge of the frame.
    // Animated: the camera glides in step with the token's slide, at the
    // wider walk zoom so upcoming spaces are visible.
    _centerOn(controller.currentPlayer.position,
        animate: true, zoom: kWalkCameraZoom);
  }

  /// Where the current player can land with the rolled steps — shown after
  /// the roll so branch picks and the +1 ATP boost are informed decisions.
  /// BFS over `nexts` covers both fork arms; updates live as stepsRemaining
  /// changes. Presentation-only.
  Set<int> _landingPreview() {
    if (controller.phase != PartyPhase.rollResult) return const {};
    final steps = controller.stepsRemaining;
    if (steps <= 0) return const {};
    final board = controller.board;
    final onMap = controller.gameMap != null;
    var frontier = <int>{controller.currentPlayer.position};
    for (var d = 0; d < steps; d++) {
      final next = <int>{};
      for (final i in frontier) {
        final nexts = board[i].nexts;
        if (nexts.isEmpty) {
          // The map anchor is terminal — you stop there. The legacy ring
          // just wraps.
          if (onMap) {
            next.add(i);
          } else {
            next.add((i + 1) % board.length);
          }
        } else {
          next.addAll(nexts);
        }
      }
      frontier = next;
    }
    // Ladders/snakes relocate on landing — show the true destination too.
    final out = <int>{...frontier};
    for (final i in frontier) {
      final j = board[i].jumpTo;
      if (j != null) out.add(j);
    }
    return out;
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _diceCtrl.dispose();
    _camCtrl.dispose();
    if (_ambient != null) {
      WidgetsBinding.instance.removeObserver(this);
      _ambient!.dispose();
    }
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
                // The narrator does NOT persist during normal turns — hosts
                // engage the player inside cutscenes (ceremony/flair/wheel);
                // the board belongs to the board (PARTY UX LAW).
                const SizedBox(height: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Stack(
                      children: [
                        GestureDetector(
                          onDoubleTap: _reframeOnActive,
                          child: _BoardView(
                            controller: controller,
                            positionOf: (p) => p.position,
                            highlightPlayer: controller.currentPlayer.index,
                            ambientClock: _ambient,
                            transformController: _boardTransform,
                            viewScale:
                                _boardTransform.value.getMaxScaleOnAxis(),
                            onLayout: _onBoardLayout,
                            onTapSpace: (space, i) =>
                                setState(() => _inspecting = i),
                            inspectedIndex: _inspecting,
                            landingPreview: _landingPreview(),
                          ),
                        ),
                        // Zoom stepper — sits under the top bar's center-me /
                        // standings buttons so the camera controls read as one
                        // cluster. Pinch still works; these are the
                        // discoverable version.
                        Positioned(top: 6, right: 2, child: _zoomButtons()),
                      ],
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
                // Chevron navigation: focus glides node-to-node along the
                // path, camera following (SPEC §6).
                onInspect: (i) {
                  setState(() => _inspecting = i);
                  _centerOn(i);
                },
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

  // Narrator bar REMOVED (Brett, 2026-07-07): the narrator never persists as
  // a modal over the board — hosts engage the player inside cutscenes
  // (ceremony, wheel payoffs, round flair) via party_dialogue.dart. It also
  // violated the voice law (Hash borrowed Russ's "uhhh…").

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
          // Snap the camera back to the active player (double-tap also works,
          // but a visible button is discoverable).
          GestureDetector(
            onTap: _reframeOnActive,
            child: Container(
              padding: const EdgeInsets.all(7),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0x88000000),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.my_location,
                  color: Colors.white54, size: 18),
            ),
          ),
          // The standings viewer — every player's full state, any time.
          GestureDetector(
            onTap: () => showStandingsSheet(context, controller),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0x88000000),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.groups,
                  color: Potatuhs.gold, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  /// The +/− zoom stepper, styled to match the top bar's camera buttons.
  Widget _zoomButtons() {
    Widget btn(IconData icon, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0x88000000),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Icon(icon, color: Colors.white54, size: 18),
          ),
        );
    return Column(
      children: [
        btn(Icons.zoom_in, () => _zoomBy(1.5)),
        const SizedBox(height: 8),
        btn(Icons.zoom_out, () => _zoomBy(1 / 1.5)),
      ],
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
              asset: kCharacters[ranked[i].character % kCharacters.length]
                  .asset,
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

  /// One ranked entry on the leaderboard strip. Identity is the character
  /// portrait + name; the three stats read left-to-right in fixed order with
  /// unambiguous icons: 🥔 potatoes (the win), ◆ diamonds (the spend),
  /// ⚡ ATP (the fuel). No decoration that isn't information.
  Widget _chip({
    required int rank,
    required Color color,
    required String name,
    String? asset,
    required int potatoes,
    required int diamonds,
    int? atp,
    bool highlight = false,
    bool bold = false,
    List<IconData> icons = const [],
  }) {
    final isLeader = rank == 0;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: highlight ? 0.30 : 0.12),
        borderRadius: BorderRadius.circular(14),
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
          // The character IS the identity: portrait in a color ring, with the
          // leader's crown riding the corner instead of replacing the face.
          SizedBox(
            width: 30,
            height: 30,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(
                        color: isLeader ? Potatuhs.gold : Colors.black26,
                        width: 1.5),
                  ),
                  child: asset != null
                      ? ClipOval(
                          child: Image.asset(asset,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink()),
                        )
                      : null,
                ),
                Positioned(
                  right: -4,
                  bottom: -3,
                  child: Container(
                    width: 15,
                    height: 15,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLeader ? Potatuhs.gold : Colors.black87,
                      border: Border.all(
                          color: isLeader ? Colors.black26 : Colors.white24),
                    ),
                    child: isLeader
                        ? const Icon(Icons.emoji_events,
                            size: 9, color: Colors.black)
                        : Text('${rank + 1}',
                            style: const TextStyle(
                                fontFamily: _kFont,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: TextStyle(
                fontFamily: _kFont,
                fontSize: 13,
                fontWeight: bold || highlight || isLeader
                    ? FontWeight.bold
                    : FontWeight.w600,
                color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text('🥔$potatoes',
              style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 7),
          const Icon(Icons.diamond, size: 13, color: Color(0xFF7EE8FA)),
          const SizedBox(width: 2),
          Text('$diamonds',
              style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7EE8FA))),
          if (atp != null) ...[
            const SizedBox(width: 7),
            const Icon(Icons.bolt, size: 13, color: Potatuhs.gold),
            Text('$atp',
                style: const TextStyle(
                    fontFamily: _kFont, fontSize: 13, color: Potatuhs.gold)),
          ],
          for (final icon in icons) ...[
            const SizedBox(width: 5),
            Icon(icon, size: 13, color: color),
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
              child: const Center(
                child: Text(
                  'BUY POTATO  ·  $kPotatoPrice 💎',
                  style: TextStyle(
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
        // A drawn common card is revealed and WAITS — the player plays it.
        if (card.options.isEmpty)
          PotatuhsButton(
            label: 'PLAY IT',
            display: true,
            fill: accent,
            textColor: Colors.black,
            onTap: () => actions.chooseCardOption(0),
          ),
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

/// The node viewer (SPEC §6) — explains the focused tile, lists everything
/// standing on it (players, ops, ghosts), and steps focus node-to-node with
/// chevrons; forks and jumps expose their targets as tappable chips.
class _SpaceInspector extends StatelessWidget {
  final BoardSpace space;
  final int index;
  final PartyController controller;
  final VoidCallback onClose;

  /// Move focus to another board index (camera follows).
  final void Function(int index)? onInspect;

  const _SpaceInspector({
    required this.space,
    required this.index,
    required this.controller,
    required this.onClose,
    this.onInspect,
  });

  @override
  Widget build(BuildContext context) {
    final info = _inspectSpace(controller, space, index);
    final n = controller.board.length;
    final occupants = [
      for (final p in controller.players)
        if (p.position == index) p
    ];
    final opsHere = [
      for (final t in controller.ops)
        if (t.position == index) t
    ];
    final ghostsHere =
        controller.ghosts.where((g) => g.position == index).length;
    final prev = (index - 1 + n) % n;
    final nexts = space.nexts.isEmpty ? <int>[(index + 1) % n] : space.nexts;
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
          decoration: BoxDecoration(
            color: const Color(0xF21A1A24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: info.color.withValues(alpha: 0.6)),
            boxShadow: Potatuhs.glow(info.color, strength: 0.22, blur: 14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: info.color.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: info.color.withValues(alpha: 0.7)),
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
              // Who/what is standing here — the persistent-element readout.
              if (occupants.isNotEmpty || opsHere.isNotEmpty || ghostsHere > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (final p in occupants)
                              _chip(p.name, p.color, Icons.person),
                            for (final t in opsHere)
                              _chip(
                                  t.op.name,
                                  const Color(0xFFE5484D),
                                  Icons.theater_comedy),
                            if (ghostsHere > 0)
                              _chip(
                                  ghostsHere > 1
                                      ? 'HAUNTED ×$ghostsHere'
                                      : 'HAUNTED',
                                  const Color(0xFF9FB7CE),
                                  Icons.dark_mode),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              // Chevron navigation + fork/jump targets.
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    _navButton(Icons.chevron_left, () => onInspect?.call(prev)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        children: [
                          Text('SPOT ${space.order + 1} / $n',
                              style: Potatuhs.label(
                                  size: 10, color: Colors.white54)),
                          if (space.isFork)
                            for (final f in nexts)
                              GestureDetector(
                                onTap: () => onInspect?.call(f),
                                child: _chip('FORK → ${f + 1}',
                                    const Color(0xFFFFB74D), Icons.call_split),
                              ),
                          if (space.jumpTo != null)
                            GestureDetector(
                              onTap: () => onInspect?.call(space.jumpTo!),
                              child: _chip(
                                  space.jumpTo! > index
                                      ? 'LIFT → ${space.jumpTo! + 1}'
                                      : 'SLIDE → ${space.jumpTo! + 1}',
                                  space.jumpTo! > index
                                      ? const Color(0xFF81C784)
                                      : const Color(0xFFE57373),
                                  Icons.moving),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _navButton(Icons.chevron_right,
                        () => onInspect?.call(nexts.first)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
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

  /// Exact spaces the rolled move can land on (empty outside rollResult) —
  /// ringed so branch picks and the +1 boost are informed.
  final Set<int> landingPreview;

  /// Board-life clock; non-null only on maps with a life layer
  /// ([kBoardLifeMaps]). Drives the ambient canvas below the path painter.
  final BoardAmbientClock? ambientClock;

  const _BoardView({
    required this.controller,
    required this.positionOf,
    required this.highlightPlayer,
    required this.transformController,
    required this.viewScale,
    this.ambientClock,
    this.onLayout,
    this.onTapSpace,
    this.inspectedIndex,
    this.landingPreview = const {},
  });

  /// How much larger than the viewport the board canvas is. A roomier canvas
  /// spreads the tiles apart in absolute terms; you pan/zoom across it rather
  /// than cramming all 88 spaces into one screen. Node size is capped
  /// (see [_BoardGeometry]) so growing this multiplies the DISTANCE between
  /// spots, not the spots themselves (Brett, 2026-07-10: the 1.8× board read
  /// far too congested — spots need ~4× the breathing room).
  static const double kCanvasSpread = 7.2;

  /// Zoom limits shared by the pinch gesture and the +/− buttons. Min is low
  /// enough that a full zoom-out fits the whole kCanvasSpread-sized board in
  /// the viewport for an overview.
  static const double kMinZoom = 1 / kCanvasSpread;
  static const double kMaxZoom = 5.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        // The board lives on a canvas larger than the viewport so the tiles get
        // real breathing room; you pan/zoom across it.
        //
        // The canvas derives from the SCREEN, not from [viewport]: the turn
        // panel below the board changes height on every phase (ROLL → dice →
        // walking), and a world scaled to the leftover area re-positions every
        // node and token on each panel change — tokens visibly bounced on ROLL
        // and the first hop rode still-moving geometry (checkpoint
        // 2026-07-10). Screen size is stable for the whole match.
        final screen = MediaQuery.sizeOf(context);
        final canvas =
            Size(screen.width * kCanvasSpread, screen.height * kCanvasSpread);
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
            // [kCanvasSpread]× size so the whole board is pannable.
            constrained: false,
            minScale: kMinZoom,
            maxScale: kMaxZoom,
            boundaryMargin: const EdgeInsets.all(_kBoardBoundaryMargin),
            child: SizedBox(
              width: canvas.width,
              height: canvas.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
            // Board-life ambient layer (Stage 0) — BELOW the path painter so
            // glows come from under the world. RepaintBoundary isolates its
            // per-frame ticks from the 88 node widgets; the painter culls to
            // the live viewport and never hit-tests.
            if (ambientClock != null && controller.gameMap != null)
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: BoardAmbientPainter(
                      clock: ambientClock!,
                      spaces: controller.board,
                      sections: controller.gameMap!.sections,
                      centers: [
                        for (var i = 0; i < controller.board.length; i++)
                          geo.nodeCenter(i)
                      ],
                      nodeRadius: geo.nodeRadius,
                      transform: transformController,
                      viewport: viewport,
                    ),
                  ),
                ),
              ),
            // Territory watermarks — legacy ring only (the new maps carry
            // their own 8–10 sections and skip the centroid watermark).
            if (controller.gameMap == null)
              for (var s = 0; s < _BoardGeometry.sections; s++)
                _sectionLabel(geo, s),
            Positioned.fill(
              child: CustomPaint(
                  painter: _BoardPathPainter(geo,
                      sections: controller.gameMap?.sections,
                      diamondIndices: [
                        for (var i = 0; i < controller.board.length; i++)
                          if (controller.diamondOn(i)) i
                      ])),
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
            for (final g in controller.ghosts) _ghostToken(geo, g),
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
  /// A Potato Shack ghost drifting on the board — procedural (no sprite), a
  /// translucent spirit perched on its haunted tile. Landing there costs
  /// diamonds, so visibility IS the gameplay.
  Widget _ghostToken(_BoardGeometry geo, GhostToken g) {
    final center = geo.nodeCenter(g.position);
    final r = geo.nodeRadius * 0.62;
    return AnimatedPositioned(
      key: ValueKey('ghost_${controller.ghosts.indexOf(g)}'),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      left: center.dx - r,
      // Hover just above the tile, opposite side from the ops' perch.
      top: center.dy - geo.nodeRadius * 1.7 - r,
      child: IgnorePointer(
        child: CustomPaint(
          size: Size(r * 2, r * 2.3),
          painter: _GhostPainter(),
        ),
      ),
    );
  }

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
    // The destination anchor is THE landmark: the race target and the one
    // potato buy point — it must be unmissable (SPEC §6).
    final isAnchor = geo.useXY && space.order == controller.board.length - 1;
    // Shop is a landmark — draw it larger; shortcut nodes slightly smaller.
    final r = geo.nodeRadius *
        (isAnchor ? 2.1 : isShop ? 1.6 : space.isShortcut ? 0.85 : 1.0);
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
    if (isAnchor) {
      icon = Icons.flag;
      iconColor = const Color(0xFFFFD54F);
      color = const Color(0xFFFFD54F);
    }

    final isInspected = inspectedIndex == index;
    final isLanding = landingPreview.contains(index);
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
          child: CustomPaint(
            foregroundPainter: _NodeDecorPainter(
                type: space.type, radius: r, accent: iconColor),
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
              color: isInspected || isLanding
                  ? Colors.white
                  : isStart || isShop || isAnchor
                      ? color
                      : color.withValues(alpha: space.isShortcut ? 0.7 : 0.55),
              width: isInspected || isLanding
                  ? 2.6
                  : isAnchor
                      ? 3.0
                      : (isStart || isShop ? 1.8 : 1.2),
            ),
            boxShadow: [
              BoxShadow(
                  color: (isInspected || isLanding ? Colors.white : color)
                      .withValues(
                          alpha: isInspected || isLanding
                              ? 0.6
                              : isAnchor
                                  ? 0.7
                                  : (isShop ? 0.5 : 0.30)),
                  blurRadius: isLanding
                      ? 16
                      : isAnchor
                          ? 22
                          : (isShop ? 14 : 9)),
            ],
          ),
          child: Icon(icon,
              size: r * (isShop ? 1.1 : 0.95),
              color: iconColor.withValues(alpha: 0.9)),
        ),
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
      // A lone player OWNS the node — the avatar fills it so you can see who
      // is where from across the table. Groups shrink and fan out to share.
      final solo = players.length == 1;
      final tr = geo.nodeRadius * (solo ? (isCurrent ? 1.0 : 0.9) : 0.62);
      final fan = solo ? 0.0 : geo.nodeRadius * 0.85;
      final angle = 2 * pi * j / players.length - pi / 2;
      final off = Offset(cos(angle) * fan, sin(angle) * fan);
      final asset = kCharacters[p.character % kCharacters.length].asset;
      final frozen = p.frozenTurns > 0;
      widgets.add(AnimatedPositioned(
        key: ValueKey('token_${p.index}'),
        // One node-to-node HOP per step tick; the step period exceeds this so
        // the character visibly settles on each node before the next hop
        // (kWalkHopMs / kWalkStepPeriodMs — the board-game walk).
        duration: const Duration(milliseconds: kWalkHopMs),
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
                // FREEZE RAY victims read as iced until their skipped turn.
                color: frozen
                    ? const Color(0xFF9BE7FF)
                    : isCurrent
                        ? Colors.white
                        : Colors.black,
                width: frozen ? 2.5 : (isCurrent ? 2.5 : 1.5)),
            boxShadow: [
              BoxShadow(
                  color: (frozen ? const Color(0xFF9BE7FF) : p.color)
                      .withValues(alpha: 0.85),
                  blurRadius: frozen ? 10 : (isCurrent ? 8 : 4)),
            ],
          ),
          // The character sprite rides the token; falls back to the solid color
          // chip if the asset is missing.
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (asset != null)
                ClipOval(
                  child: Image.asset(
                    asset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              if (frozen)
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x669BE7FF),
                  ),
                  child: Icon(Icons.ac_unit,
                      size: tr * 1.1, color: Colors.white),
                ),
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
    // Sized for legibility at the default frame (Brett, 2026-07-07: the old
    // board read ~4× too small — spaces and avatars must be identifiable at
    // a glance, not decoded).
    final base = useXY
        ? min(24.0, min(rect.width, rect.height) / 11)
        : min(26.0, _len / kMainLoopLength * 0.46);
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
  final List<BoardSection>? sections;

  /// Board indices still carrying a path diamond (MAPS_SPEC economy) —
  /// eaten ones vanish as tokens walk over them.
  final List<int> diamondIndices;
  _BoardPathPainter(this.geo,
      {this.sections, this.diamondIndices = const []});

  @override
  void paint(Canvas canvas, Size size) {
    // New maps lay out by (x,y): draw path links + ladders/snakes/slides and
    // skip the legacy ring entirely.
    if (geo.useXY) {
      _paintTopology(canvas);
      _paintDiamonds(canvas);
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

    _paintDiamonds(canvas);

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
    final secs = sections;
    final link = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 / z
      ..strokeCap = StrokeCap.round;
    for (final s in spaces) {
      final from = geo.nodeCenter(s.order);
      // Region-tinted links so the territories read as territories.
      final tint = secs != null && s.sectionIndex < secs.length
          ? secs[s.sectionIndex].color
          : Colors.white;
      link.color = Color.alphaBlend(
          tint.withValues(alpha: 0.30), Colors.white.withValues(alpha: 0.10));
      for (final n in s.nexts) {
        canvas.drawLine(from, geo.nodeCenter(n), link);
      }
    }
    // Direction-of-travel chevrons: every third link points the way forward,
    // so "which way do I go" is answered by the path itself.
    for (final s in spaces) {
      if (s.order % 3 != 1 || s.nexts.isEmpty) continue;
      final from = geo.nodeCenter(s.order);
      final to = geo.nodeCenter(s.nexts.first);
      _arrow(canvas, Offset.lerp(from, to, 0.5)!, to - from,
          Colors.white.withValues(alpha: 0.5), 5 / z);
    }
    // Region labels at each territory's centroid.
    if (secs != null) {
      final sums = <int, Offset>{};
      final counts = <int, int>{};
      for (final s in spaces) {
        final c = geo.nodeCenter(s.order);
        sums[s.sectionIndex] = (sums[s.sectionIndex] ?? Offset.zero) + c;
        counts[s.sectionIndex] = (counts[s.sectionIndex] ?? 0) + 1;
      }
      sums.forEach((i, sum) {
        if (i >= secs.length) return;
        final c = sum / counts[i]!.toDouble();
        _label(canvas, secs[i].name.toUpperCase(),
            secs[i].color.withValues(alpha: 0.55), c, 11 / z);
      });
    }
    // The destination anchor gets a name.
    if (spaces.isNotEmpty) {
      final anchor = geo.nodeCenter(spaces.length - 1);
      _label(canvas, 'DESTINATION', const Color(0xFFFFD54F),
          anchor + Offset(0, 26 / z), 10 / z);
    }
    // Every market is named too — the potato buy points must be identifiable
    // at a glance, not decoded from an icon.
    for (final s in spaces) {
      if (s.type != SpaceType.shop) continue;
      _label(canvas, 'MARKET', const Color(0xFFD7A86E),
          geo.nodeCenter(s.order) + Offset(0, geo.nodeRadius * 2.2), 10 / z);
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

  /// The uneaten path diamonds: a tiny gem on each space's shoulder. Eaten
  /// ones simply aren't in the list, so they wink out as tokens pass.
  void _paintDiamonds(Canvas canvas) {
    if (diamondIndices.isEmpty) return;
    final s = geo.nodeRadius * 0.34;
    final fill = Paint()..color = const Color(0xFF9BEBFF);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF2E7A8F);
    for (final i in diamondIndices) {
      final c = geo.nodeCenter(i) +
          Offset(geo.nodeRadius * 0.95, -geo.nodeRadius * 0.95);
      final gem = Path()
        ..moveTo(c.dx, c.dy - s)
        ..lineTo(c.dx + s * 0.7, c.dy)
        ..lineTo(c.dx, c.dy + s)
        ..lineTo(c.dx - s * 0.7, c.dy)
        ..close();
      canvas.drawPath(gem, fill);
      canvas.drawPath(gem, edge);
    }
  }

  /// Painter-level text, centered on [pos].
  void _label(
      Canvas canvas, String text, Color color, Offset pos, double size) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: size,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          color: color,
          shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
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
      oldDelegate.geo.size != geo.size ||
      oldDelegate.diamondIndices.length != diamondIndices.length;
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
                      // Long section names (ENGINE ROOM, BOBO THE WATCHER)
                      // overflow phone widths — ellipsize, never overflow.
                      Flexible(
                        child: Text(
                          "LEADER'S TERRITORY: ${section.name}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: _kFont,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: section.color),
                        ),
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

/// Debug-only: override the randomly chosen game on the intro screen. The
/// full registry is ~126 chips, so the chip cloud lives inside a fixed-height
/// scroll box — it must never grow the (non-scrolling) intro column.
class _DebugGamePicker extends StatelessWidget {
  final PartyController controller;
  final PartyActions actions;
  const _DebugGamePicker({
    required this.controller,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final specs = [...MiniGameRegistry.enabledSpecs]
      ..sort((a, b) => a.name.compareTo(b.name));
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF8A65), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 128),
            child: SingleChildScrollView(
              child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in specs)
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
            ),
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


/// The Potato Shack ghost: pale translucent body, wavy hem, hollow eyes.
/// Deliberately simple — it reads at tile scale and repaints only on move.
class _GhostPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width, h = size.height;
    final body = Paint()..color = const Color(0xCCDCE8F2);
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..quadraticBezierTo(w, 0, w, h * 0.45)
      ..lineTo(w, h * 0.82)
      // Wavy hem: three scallops.
      ..quadraticBezierTo(w * 0.83, h * 0.68, w * 0.66, h * 0.86)
      ..quadraticBezierTo(w * 0.5, h * 1.0, w * 0.34, h * 0.86)
      ..quadraticBezierTo(w * 0.17, h * 0.68, 0, h * 0.82)
      ..lineTo(0, h * 0.45)
      ..quadraticBezierTo(0, 0, w * 0.5, 0)
      ..close();
    canvas.drawShadow(path, const Color(0xFF9FB7CE), 4, true);
    canvas.drawPath(path, body);
    // Hollow eyes + a small "oh" mouth.
    final ink = Paint()..color = const Color(0xE6222633);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.36, h * 0.34),
            width: w * 0.14,
            height: w * 0.2),
        ink);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.64, h * 0.34),
            width: w * 0.14,
            height: w * 0.2),
        ink);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.52),
            width: w * 0.12,
            height: w * 0.14),
        ink);
  }

  @override
  bool shouldRepaint(_GhostPainter old) => false;
}


/// Type decor drawn over special nodes so they read as PLACES, not dots:
/// markets wear a striped awning, event spaces get a live-looking swirl,
/// wild-card spaces a spark halo. Static per node — repaints never.
class _NodeDecorPainter extends CustomPainter {
  final SpaceType type;
  final double radius;
  final Color accent;
  _NodeDecorPainter(
      {required this.type, required this.radius, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final c = Offset(size.width / 2, size.height / 2);
    switch (type) {
      case SpaceType.shop:
        _awning(canvas, c);
        break;
      case SpaceType.event:
        _swirl(canvas, c);
        break;
      case SpaceType.cardWild:
        _sparks(canvas, c);
        break;
      default:
        break;
    }
  }

  /// A striped market awning over the top half of the stall. Each stripe is a
  /// true annular sector (outer arc -> inner arc), NOT a filled wedge with the
  /// interior overpainted — this is a foregroundPainter, so any "cut it back
  /// out" disc would erase the node (icon, fill, ring) underneath and leave
  /// markets reading as featureless black holes.
  void _awning(Canvas canvas, Offset c) {
    const stripes = 5;
    final outer = Rect.fromCircle(center: c, radius: radius * 1.34);
    final inner = Rect.fromCircle(center: c, radius: radius * 1.04);
    final a = Paint()..color = accent;
    final b = Paint()..color = const Color(0xFFF4EDE3);
    const start = pi; // left
    const sweep = pi / stripes; // across the top half
    for (var i = 0; i < stripes; i++) {
      final band = Path()
        ..arcTo(outer, start + i * sweep, sweep, true)
        ..arcTo(inner, start + (i + 1) * sweep, -sweep, false)
        ..close();
      canvas.drawPath(band, i.isEven ? a : b);
    }
    // Scalloped hem.
    final hem = Paint()..color = accent;
    for (var i = 0; i < stripes; i++) {
      final ang = pi + (i + 0.5) * sweep;
      final p = c + Offset(cos(ang), sin(ang)) * radius * 1.18;
      canvas.drawCircle(p, radius * 0.12, hem);
    }
  }

  /// A cosmic swirl orbiting the event orb.
  void _swirl(Canvas canvas, Offset c) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.14
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.75);
    final rect = Rect.fromCircle(center: c, radius: radius * 1.22);
    canvas.drawArc(rect, -0.4, 1.9, false, paint);
    canvas.drawArc(rect, pi - 0.4, 1.9, false, paint);
  }

  /// Spark halo for the wild (Void) card spaces.
  void _sparks(Canvas canvas, Offset c) {
    final paint = Paint()..color = accent.withValues(alpha: 0.85);
    for (var i = 0; i < 4; i++) {
      final ang = pi / 4 + i * pi / 2;
      final p = c + Offset(cos(ang), sin(ang)) * radius * 1.28;
      canvas.drawCircle(p, radius * 0.11, paint);
    }
  }

  @override
  bool shouldRepaint(_NodeDecorPainter old) =>
      old.type != type || old.radius != radius || old.accent != accent;
}


/// The table's escape hatch: one vote per seat; a strict majority skips the
/// round's mini-game outright (no scores, no awards). Replaces the debug SKIP
/// and the old duration+grace auto-bank watchdog. Rendered by MiniGameHost on
/// the intro's START row (via `introAction`) in the host's secondary-button
/// style — same height as START, compact width.
class _VoteSkipButton extends StatelessWidget {
  final PartyController controller;
  final PartyActions actions;
  final int mySeat; // -1 = unknown (spectating replica edge)
  const _VoteSkipButton({
    required this.controller,
    required this.actions,
    required this.mySeat,
  });

  @override
  Widget build(BuildContext context) {
    // Listen directly so live vote counts repaint even though the host owns
    // this subtree's rebuilds.
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final votes = controller.skipVotes.length;
        final needed = controller.skipVotesNeeded;
        final voted = mySeat >= 0 && controller.skipVotes.contains(mySeat);
        final canVote = mySeat >= 0 && !voted;
        final color = voted ? Potatuhs.gold : Colors.white70;
        return GestureDetector(
          onTap: canVote ? actions.voteSkip : null,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: voted
                      ? Potatuhs.gold.withValues(alpha: 0.8)
                      : Colors.white24),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.skip_next, size: 18, color: color),
                const SizedBox(height: 2),
                Text(
                  votes > 0 ? 'SKIP $votes/$needed' : 'SKIP',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Fires [onFire] once after [delay] — used by the online host to auto-pace
/// held dialog beats (game reveal) so a distracted host can't stall the room.
class _AutoAdvanceAfter extends StatefulWidget {
  final Duration delay;
  final VoidCallback onFire;
  final Widget child;
  const _AutoAdvanceAfter({
    super.key,
    required this.delay,
    required this.onFire,
    required this.child,
  });

  @override
  State<_AutoAdvanceAfter> createState() => _AutoAdvanceAfterState();
}

class _AutoAdvanceAfterState extends State<_AutoAdvanceAfter> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, widget.onFire);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
