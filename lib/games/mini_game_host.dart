import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../party/party_models.dart';
import '../telemetry/cell_telemetry.dart';
import '../theme/potatuhs.dart';
import 'attract/auto_tapper.dart';
import 'leaderboard/leaderboard_models.dart';
import 'leaderboard/leaderboard_panel.dart';
import 'leaderboard/score_history_store.dart';
import 'mini_game.dart';
import 'opponent_config.dart';

/// Runs one mini-game from intro to results.
///
/// Solo (Explore) mode: omit [onComplete] — the results screen offers
/// Play Again / Exit and tracks a local best score.
/// Party mode: pass [onComplete] — the results screen shows a single
/// Continue button that reports the final score to the board game loop.
class MiniGameHost extends StatefulWidget {
  final MiniGameSpec spec;
  final String? playerLabel;
  final ValueChanged<int>? onComplete;
  final VoidCallback onExit;

  /// Number of AI opponents to score against in solo (Explore) play. 0 = solo
  /// score-attack (no comparison). 1/2/3 → 1v1 / 1v1v1 / 1v1v1v1. Ignored in
  /// party mode (real players already provide the comparison).
  final int opponentCount;

  /// When true, opponents may interfere with the player's run. Games that
  /// support score-disruption read this; the host surfaces a "disruption on"
  /// badge during play so the feature is testable even before a game wires it.
  final bool disruption;

  /// Attract mode: the host runs the game hands-free — auto-starts past the
  /// intro after a settle beat, drives a synthetic-tap bot at 250ms during
  /// play, and (when [onAutoAdvance] is set) calls it a few seconds after the
  /// results land so the caller can move to the next game. Flipping this back
  /// to false mid-round stops the bot in place so a human can take over the
  /// live round. See `AttractScreen`.
  final bool autoPlay;

  /// Called by attract mode once a round's results have settled, so the caller
  /// (the attract loop) can advance to the next game. Ignored when [autoPlay]
  /// is false.
  final VoidCallback? onAutoAdvance;

  /// Quick-hop between catalog games (the triage flow): when set, the intro
  /// and results screens show a `◀ hopLabel ▶` strip; the arrows call this
  /// with -1 / +1 and the CALLER swaps the spec (rebuild the host with a new
  /// key). Never shown during countdown/play.
  final void Function(int delta)? onHopGame;

  /// The strip's label, e.g. `12/126` (current game / total games).
  final String? hopLabel;

  /// Optional compact action rendered on the intro screen's START row, to the
  /// left of the START button — host-level chrome injected by a wrapper (e.g.
  /// the party page's vote-to-skip button). Leaves with the intro, so it can
  /// never sit over live gameplay.
  final Widget? introAction;

  /// Skip the local intro: a short settle beat on mount, then straight into
  /// the 3-2-1 countdown. Used by the online party flow, where the READY
  /// CHECK screen (READY_UP_SPEC.md) has already served as reading time and
  /// every seat starts together — a second START tap would desynchronize the
  /// round. Solo, quick match, and offline party never pass this.
  final bool autoStart;

  const MiniGameHost({
    super.key,
    required this.spec,
    required this.onExit,
    this.playerLabel,
    this.onComplete,
    this.opponentCount = 0,
    this.disruption = false,
    this.autoPlay = false,
    this.onAutoAdvance,
    this.onHopGame,
    this.hopLabel,
    this.introAction,
    this.autoStart = false,
  });

  bool get isParty => onComplete != null;

  @override
  State<MiniGameHost> createState() => _MiniGameHostState();
}

class _MiniGameHostState extends State<MiniGameHost> {
  late MiniGameSession _session;
  Timer? _clock;
  Timer? _countdownTimer;
  int _countdown = 3;
  DateTime? _endsAt;
  Duration _appliedBonus = Duration.zero;
  int? _bestScore;
  bool _newBest = false;
  List<_Opponent> _opponents = const [];
  // Device score history (solo only) — powers the History / Bests leaderboard
  // views. Filled on finish from the isolated ScoreHistoryStore.
  LeaderboardStats _stats = const LeaderboardStats.empty();

  // End-of-game wind-down: a "3·2·1·STOP!" beat (taps blocked) before the
  // results become interactive — so reflexive tapping can't skip the score /
  // standings / highscore.
  Timer? _wrapTimer;
  int _wrapCount = 3; // 3 → 2 → 1 → 0(=STOP) → results
  bool _resultsReady = false;

  // ── Attract mode (autoplay) ──────────────────────────────────────────────
  // Marks the game surface so the bot can target taps inside it (below the HUD,
  // never on the exit button / overlays which live above it).
  final GlobalKey _gameAreaKey = GlobalKey();
  final AutoTapper _tapper = AutoTapper();
  final Random _botRng = Random();
  Timer? _botTimer; // fires a synthetic action every 250ms during play
  Timer? _autoIntroTimer; // settle beat, then auto-start past the intro
  Timer? _autoAdvanceTimer; // dwell on results, then advance to the next game
  bool _botBusy = false; // guards the async (pixel-capture) tick from re-entry

  // Anti-stuck watchdog: if a round makes zero forward progress (score AND
  // clock both frozen — e.g. a blocking teaching card the bot can't dismiss),
  // force the round to end so the attract loop never hangs on camera.
  int _wdScore = 0;
  Duration _wdRemaining = Duration.zero;
  int _wdStallTicks = 0;
  static const _wdStallLimit = 40; // 40 × 250ms ≈ 10s of no progress

  /// Generate opponent scores from the configured character roster, scaled to
  /// the game's realistic human ceiling so the comparison feels fair, and tuned
  /// per character by their CPU difficulty. Solo (Explore) only.
  void _generateOpponents() {
    if (widget.isParty || widget.opponentCount <= 0) {
      _opponents = const [];
      return;
    }
    final rng = Random();
    // Realistic ceiling: the tuned humanMax, or a score-relative estimate.
    final ceiling = widget.spec.humanMax > 0
        ? widget.spec.humanMax
        : max(120, (_session.score * 1.7).round());
    // Draw opponents from the canonical cast, excluding whoever the human plays
    // as (their tuning never controls a CPU). Falls back to the full cast if
    // the exclusion would leave too few to fill the seats.
    var pool = kCharacters
        .where((c) => c.name != OpponentRoster.playAs)
        .toList();
    if (pool.length < widget.opponentCount) pool = [...kCharacters];
    pool.shuffle(rng);
    _opponents = List.generate(widget.opponentCount, (i) {
      final character = pool[i % pool.length];
      final (lo, hi) = OpponentRoster.configFor(character.name).difficulty.band;
      final skill = lo + rng.nextDouble() * (hi - lo);
      final noise = (rng.nextDouble() - 0.5) * 0.08;
      final s = (ceiling * (skill + noise)).round().clamp(0, ceiling);
      return _Opponent(character.name, s);
    });
  }

  @override
  void initState() {
    super.initState();
    _session = MiniGameSession(
        spec: widget.spec, playerLabel: widget.playerLabel);
    _session.hostReset();
    _session.addListener(_onSessionChanged);
    if (!widget.isParty) _loadBest();
    if (widget.autoPlay) {
      _armAutoIntro();
    } else if (widget.autoStart) {
      // Ready-checked start (READY_UP_SPEC.md): settle beat, then countdown.
      _autoIntroTimer = Timer(const Duration(milliseconds: 400), () {
        if (mounted && _session.phase == MiniGamePhase.intro) {
          _startCountdown();
        }
      });
    }
  }

  /// Attract mode: let the intro card breathe (rest/settle during the screen
  /// transition), then auto-start the round.
  void _armAutoIntro() {
    _autoIntroTimer?.cancel();
    _autoIntroTimer = Timer(const Duration(milliseconds: 1300), () {
      if (mounted && _session.phase == MiniGamePhase.intro) _startCountdown();
    });
  }

  @override
  void didUpdateWidget(covariant MiniGameHost old) {
    super.didUpdateWidget(old);
    // Ejected mid-round (autoPlay armed → disarmed on the SAME game): stop the
    // bot and any pending auto-advance so the live round is handed to the human
    // to play out. Re-arming is done by remounting a fresh host, not here.
    if (old.autoPlay && !widget.autoPlay) {
      _botTimer?.cancel();
      _botTimer = null;
      _autoIntroTimer?.cancel();
      _autoAdvanceTimer?.cancel();
      _autoAdvanceTimer = null;
    }
  }

  static const _botTickMs = 250;
  int _sinceActMs = 0; // time accumulated toward the next paced autopilot move

  void _startBot() {
    _botTimer?.cancel();
    _wdScore = _session.score;
    _wdRemaining = _session.remaining;
    _wdStallTicks = 0;
    _sinceActMs = 0;
    _botTimer = Timer.periodic(const Duration(milliseconds: _botTickMs), (_) {
      if (!mounted || !_session.isRunning) return;
      if (_checkStall()) return; // watchdog force-ended the round (runs every tick)
      // Per-game pacing: quizzes buffer to ~1s so answering isn't superhuman;
      // action games leave the interval at zero and act every tick.
      _sinceActMs += _botTickMs;
      if (_sinceActMs < _session.autoPilotInterval.inMilliseconds) return;
      _sinceActMs = 0;
      _botTick();
    });
  }

  /// Returns true if the round was force-ended for lack of progress. A stall =
  /// score AND remaining-time both unchanged (a game that isn't advancing and
  /// whose clock is frozen — a blocking modal the bot can't clear).
  bool _checkStall() {
    if (_session.score != _wdScore || _session.remaining != _wdRemaining) {
      _wdScore = _session.score;
      _wdRemaining = _session.remaining;
      _wdStallTicks = 0;
      return false;
    }
    if (++_wdStallTicks < _wdStallLimit) return false;
    _session.endEarly(); // → _onSessionChanged → _finish → auto-advance
    return true;
  }

  /// One hands-free action. FIRST choice: the game's OWN autopilot — it knows
  /// its state and drives itself competently (the per-game reference). Only when
  /// a game hasn't shipped one yet do we fall back to the generic driver: prefer
  /// the brightest on-screen target, else a random tap/drag. Async because the
  /// pixel capture is; guarded against re-entry.
  Future<void> _botTick() async {
    // Per-game autopilot wins — no guessing, no synthetic taps needed.
    final hook = _session.autoPilot;
    if (hook != null) {
      hook();
      return;
    }
    if (_botBusy) return;
    _botBusy = true;
    try {
      final rect = _gameAreaRect();
      if (rect == null) return;
      Offset? target;
      if (_botRng.nextDouble() < 0.8) target = await _brightestPoint();
      if (!mounted || !_session.isRunning) return;
      if (target != null && rect.contains(target)) {
        _tapper.tap(target);
      } else {
        _tapper.act(rect); // random tap / occasional drag for motion
      }
    } finally {
      _botBusy = false;
    }
  }

  /// Global (logical-pixel) rect of the live game surface, slightly inset so the
  /// bot's taps land cleanly inside it. Null until the game area is laid out.
  Rect? _gameAreaRect() {
    final box = _gameAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return (box.localToGlobal(Offset.zero) & box.size).deflate(12);
  }

  /// Captures the game surface at low resolution and returns the global position
  /// of its brightest cluster (with a little jitter), or null if the screen is
  /// essentially dark or the capture isn't available. Cheap: an ~1–2k pixel scan
  /// a few times a second. Only used by the generic fallback tapper (a game with
  /// no per-game autopilot).
  Future<Offset?> _brightestPoint() async {
    try {
      final boundary =
          _gameAreaKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary || boundary.debugNeedsPaint) {
        return null;
      }
      const ratio = 0.08;
      final image = await boundary.toImage(pixelRatio: ratio);
      final w = image.width, h = image.height;
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      if (data == null || w == 0 || h == 0) return null;
      final bytes = data.buffer.asUint8List();
      // Pass 1: peak luminance. Pass 2: centroid of the brightest band — this
      // lands on a large filled button (many bright pixels) rather than on thin
      // bright text (a title), which a single-brightest-pixel pick would miss.
      var peak = 0.0;
      for (var i = 0; i < w * h; i++) {
        final o = i * 4;
        final lum =
            0.2126 * bytes[o] + 0.7152 * bytes[o + 1] + 0.0722 * bytes[o + 2];
        if (lum > peak) peak = lum;
      }
      if (peak < 40) return null; // essentially dark → no clear target
      final threshold = peak * 0.85;
      var sumX = 0.0, sumY = 0.0, count = 0;
      for (var i = 0; i < w * h; i++) {
        final o = i * 4;
        final lum =
            0.2126 * bytes[o] + 0.7152 * bytes[o + 1] + 0.0722 * bytes[o + 2];
        if (lum >= threshold) {
          sumX += i % w;
          sumY += i ~/ w;
          count++;
        }
      }
      if (count == 0) return null;
      final localX = (sumX / count + 0.5) / ratio;
      final localY = (sumY / count + 0.5) / ratio;
      final global = boundary.localToGlobal(Offset(localX, localY));
      return global +
          Offset((_botRng.nextDouble() - 0.5) * 18,
              (_botRng.nextDouble() - 0.5) * 18);
    } catch (_) {
      return null; // capture unsupported / transient failure → random fallback
    }
  }

  Future<void> _loadBest() async {
    final best = await ScoreHistoryStore.bestFor(widget.spec.id);
    if (!mounted) return;
    setState(() => _bestScore = best);
  }

  void _onSessionChanged() {
    // A game can call endEarly(); make sure the clock stops and results save.
    if (_session.phase == MiniGamePhase.finished && _clock != null) {
      _finish(fromSession: true);
    }
  }

  void _startCountdown() {
    setState(() => _countdown = 3);
    _session.hostSetPhase(MiniGamePhase.countdown);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 800), (t) {
      if (!mounted) return;
      if (_countdown <= 1) {
        t.cancel();
        _begin();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _begin() {
    // Count this play into the shared hot-potato-games counter (Sessions KPI).
    // Fire-and-forget; never blocks or throws. See docs/SESSIONS_COUNTER.md.
    // Attract-mode (autoPlay) is a bot loop — it must NOT inflate the Sessions
    // KPI (the Honest-Sessions gate: a session is a real, non-Brett human).
    if (!widget.autoPlay) CellTelemetry.recordMiniGamePlay(widget.spec.id);
    _endsAt = DateTime.now()
        .add(Duration(seconds: widget.spec.durationSeconds));
    _appliedBonus = Duration.zero;
    _session.hostSetPhase(MiniGamePhase.playing);
    if (widget.autoPlay) _startBot();
    _runClock();
  }

  /// Starts the 100ms round clock against [_endsAt]. Used by [_begin] and by
  /// [_resume] (which first rebases [_endsAt] off the remaining time).
  void _runClock() {
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final extra = _session.bonusTime - _appliedBonus;
      if (extra > Duration.zero) {
        _endsAt = _endsAt!.add(extra);
        _appliedBonus = _session.bonusTime;
      }
      final left = _endsAt!.difference(DateTime.now());
      if (left <= Duration.zero) {
        _finish();
      } else {
        _session.hostTick(left);
      }
    });
  }

  // ── Pause (solo human play) ───────────────────────────────────────────────
  bool _paused = false;
  Duration _pausedRemaining = Duration.zero;

  /// Freezes the round: stops the clock, remembers the time left, and flips the
  /// session out of `isRunning` so the game halts its own logic. A modal shows
  /// over the top with Resume / Quit. Only meaningful during live play.
  void _pause() {
    if (_paused || !_session.isRunning) return;
    _pausedRemaining = _session.remaining;
    _clock?.cancel();
    _clock = null;
    setState(() => _paused = true);
    _session.hostSetPaused(true); // isRunning → false; games stop advancing
  }

  /// Resumes: rebases the clock off the remembered remaining time and lets the
  /// game run again.
  void _resume() {
    if (!_paused) return;
    _session.hostSetPaused(false);
    _endsAt = DateTime.now().add(_pausedRemaining);
    _runClock();
    setState(() => _paused = false);
  }

  void _finish({bool fromSession = false}) {
    _clock?.cancel();
    _clock = null;
    _botTimer?.cancel();
    _botTimer = null;
    _session.hostTick(Duration.zero);
    if (!fromSession) _session.hostSetPhase(MiniGamePhase.finished);
    if (!widget.isParty) _recordRun();
    _generateOpponents();
    _startWrapUp();
    // Attract mode: dwell on the score payoff (the wind-down + a beat of the
    // results screen — good b-roll), then continue hands-free. Solo attract uses
    // onAutoAdvance (next game); a party round has no auto-advance hook, so we
    // auto-submit the score via onComplete to keep the board loop moving.
    if (widget.autoPlay) {
      _autoAdvanceTimer?.cancel();
      _autoAdvanceTimer = Timer(const Duration(milliseconds: 4200), () {
        if (!mounted) return;
        if (widget.onAutoAdvance != null) {
          widget.onAutoAdvance!();
        } else if (widget.isParty) {
          widget.onComplete!(_session.score);
        }
      });
    }
    setState(() {});
  }

  /// "3 · 2 · 1 · STOP!" wind-down, then reveal the (interactive) results. Until
  /// it completes, results are non-interactive and taps do nothing — so you
  /// actually get to read your score/standings instead of tapping past them.
  void _startWrapUp() {
    _wrapTimer?.cancel();
    _resultsReady = false;
    _wrapCount = 3;
    _wrapTimer = Timer.periodic(const Duration(milliseconds: 750), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_wrapCount > 0) {
          _wrapCount--; // 3 → 2 → 1 → 0 (STOP!)
        } else {
          t.cancel();
          _resultsReady = true; // results become interactive now
        }
      });
    });
  }

  /// Persist this run to the isolated history store and refresh the stats that
  /// feed the History / Bests leaderboard views. Solo (Explore) only.
  Future<void> _recordRun() async {
    final score = _session.score;
    final prevBest = _bestScore;
    _newBest = score > 0 && (prevBest == null || score > prevBest);
    final stats = await ScoreHistoryStore.record(widget.spec.id, score);
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _bestScore = stats.best;
    });
  }

  /// Effective star cutoffs for this game: explicit spec values, else derived
  /// from the human ceiling, else relative to the player's best/this score.
  List<int> get _starThresholds => resolveStarThresholds(
        explicit: widget.spec.starThresholds,
        humanMax: widget.spec.humanMax,
        reference: max(_bestScore ?? 0, _session.score),
      );

  void _playAgain() {
    _clock?.cancel();
    _countdownTimer?.cancel();
    _wrapTimer?.cancel();
    setState(() {
      _newBest = false;
      _resultsReady = false;
      _session.removeListener(_onSessionChanged);
      _session.dispose();
      _session = MiniGameSession(
          spec: widget.spec, playerLabel: widget.playerLabel);
      _session.hostReset();
      _session.addListener(_onSessionChanged);
    });
    _startCountdown();
  }

  @override
  void dispose() {
    _clock?.cancel();
    _countdownTimer?.cancel();
    _wrapTimer?.cancel();
    _botTimer?.cancel();
    _autoIntroTimer?.cancel();
    _autoAdvanceTimer?.cancel();
    _session.removeListener(_onSessionChanged);
    _session.dispose();
    super.dispose();
  }

  /// Overlays the quick-hop strip (`◀ 12/126 ▶`) on a rest screen (intro /
  /// results). No-op when the caller didn't wire [MiniGameHost.onHopGame].
  Widget _withHopStrip(Widget screen) {
    final hop = widget.onHopGame;
    if (hop == null) return screen;
    Widget arrow(IconData icon, int delta) => GestureDetector(
          onTap: () => hop(delta),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Icon(icon, size: 20, color: Colors.white70),
          ),
        );
    return Stack(
      children: [
        screen,
        Positioned(
          top: 8,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0x66000000),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                arrow(Icons.chevron_left_rounded, -1),
                if (widget.hopLabel != null)
                  Text(
                    widget.hopLabel!,
                    style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Colors.white70,
                    ),
                  ),
                arrow(Icons.chevron_right_rounded, 1),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _session,
          // The game widget is built ONCE and handed to AnimatedBuilder as its
          // stable `child`, so a game scoring a point (addScore → noteStreak →
          // notifyListeners) only re-runs the HUD/overlay `builder` below — it does
          // NOT rebuild the game subtree. Before this, every point scored rebuilt
          // the ENTIRE game tree (e.g. all 16 Harvest cells + every floating card)
          // → build-phase overload → dropped/black frames, worst exactly when the
          // player was scoring fastest. Each game owns its own 60fps ticker and
          // repaints its canvas itself; it never needs the host to rebuild it.
          // The instance is stable for the whole round: during `playing` the host
          // never calls setState (the 100ms clock and scores flow through _session
          // → this AnimatedBuilder), so `child` is reconstructed only on
          // countdown/finish/replay, where a fresh game is exactly what we want.
          child: spec.builder(context, _session),
          builder: (context, gameChild) {
            switch (_session.phase) {
              case MiniGamePhase.intro:
                return _withHopStrip(_IntroView(
                  spec: spec,
                  playerLabel: widget.playerLabel,
                  bestScore: widget.isParty ? null : _bestScore,
                  onStart: _startCountdown,
                  onExit: widget.onExit,
                  action: widget.introAction,
                ));
              case MiniGamePhase.countdown:
              case MiniGamePhase.playing:
                return Stack(
                  children: [
                    Column(
                      children: [
                        _GameHud(
                          session: _session,
                          // Solo human play only — hidden in party rounds and in
                          // attract mode (the autopilot owns the round).
                          onPause: (!widget.isParty &&
                                  !widget.autoPlay &&
                                  _session.isRunning)
                              ? _pause
                              : null,
                        ),
                        // RepaintBoundary so attract mode's generic fallback
                        // tapper can capture the game surface's pixels to aim at
                        // the brightest target. Wraps ONLY the game area.
                        Expanded(
                          child: RepaintBoundary(
                              key: _gameAreaKey, child: gameChild!),
                        ),
                      ],
                    ),
                    if (_session.phase == MiniGamePhase.countdown)
                      _CountdownOverlay(
                          value: _countdown, accent: spec.accent),
                    // Disruption-active badge — feature is on for this round.
                    if (widget.disruption &&
                        _session.phase == MiniGamePhase.playing)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: SafeArea(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF7043)
                                  .withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFFF7043)
                                      .withValues(alpha: 0.7)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt,
                                    size: 13, color: Color(0xFFFF7043)),
                                SizedBox(width: 3),
                                Text(
                                  'DISRUPTION',
                                  style: TextStyle(
                                    fontFamily: _kFont,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: Color(0xFFFF7043),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Pause modal (solo human play). Freezes the round + game;
                    // Resume continues, Quit exits. See _pause/_resume.
                    if (_paused)
                      _PauseOverlay(
                        accent: spec.accent,
                        onResume: _resume,
                        onQuit: widget.onExit,
                      ),
                  ],
                );
              case MiniGamePhase.finished:
                // Locked transition beat first — non-interactive, so stray taps
                // can't skip the results. Score counts up here.
                if (!_resultsReady) {
                  return _TransitionOverlay(
                    count: _wrapCount,
                    score: _session.score,
                    scoreUnit: spec.scoreUnit,
                    accent: spec.accent,
                  );
                }
                return _withHopStrip(_ResultsView(
                  spec: spec,
                  score: _session.score,
                  playerLabel: widget.playerLabel,
                  bestScore: widget.isParty ? null : _bestScore,
                  newBest: _newBest,
                  isParty: widget.isParty,
                  opponents: _opponents,
                  stats: _stats,
                  stars: starsForScore(_session.score, _starThresholds),
                  bestStreak: _session.bestStreak,
                  onContinue: widget.isParty
                      ? () => widget.onComplete!(_session.score)
                      : null,
                  onPlayAgain: widget.isParty ? null : _playAgain,
                  onExit: widget.onExit,
                ));
            }
          },
        ),
      ),
    );
  }
}

const _kFont = Potatuhs.bodyFont; // Outfit

class _IntroView extends StatelessWidget {
  final MiniGameSpec spec;
  final String? playerLabel;
  final int? bestScore;
  final VoidCallback onStart;
  final VoidCallback onExit;

  /// Compact wrapper-injected action sharing the START row (left of START).
  final Widget? action;

  const _IntroView({
    required this.spec,
    required this.onStart,
    required this.onExit,
    this.playerLabel,
    this.bestScore,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final accent = spec.accent;
    // Scroll-safe: the Spacer-driven Column distributes slack on a tall
    // screen, but on a short viewport (long rules lists, small embeds) the
    // fixed content would overflow the bottom — so size to at least the
    // viewport and scroll when there isn't room. Same pattern as the lobby.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onExit,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0x88000000),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white70, size: 20),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${spec.durationSeconds}s',
                  style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: accent),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (playerLabel != null) ...[
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  playerLabel!,
                  style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Center(child: Icon(spec.icon, color: accent, size: 56)),
          const SizedBox(height: 12),
          Center(
            child: Text(
              spec.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: Potatuhs.displayFont,
                fontSize: 30,
                color: Colors.white,
                letterSpacing: 1,
                shadows: [Shadow(color: accent, blurRadius: 18)],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              spec.tagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 14,
                  color: accent,
                  fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 24),
          // Visual manual: games that ship `legendFrames` (or a demo) get a
          // carousel of their REAL components instead of a flat text list. Games
          // that don't fall back to the bullet rules below — no regressions.
          if (spec.legendFrames.isNotEmpty || spec.demoBuilder != null)
            _LegendCarousel(spec: spec, accent: accent)
          else
            Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOW TO PLAY',
                  style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: accent),
                ),
                const SizedBox(height: 8),
                for (final rule in spec.rules)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('•  ',
                            style: TextStyle(
                                fontFamily: _kFont,
                                fontSize: 14,
                                color: accent)),
                        Expanded(
                          child: Text(
                            rule,
                            style: const TextStyle(
                                fontFamily: _kFont,
                                fontSize: 14,
                                color: Colors.white,
                                height: 1.25),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.emoji_events, color: accent, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        spec.howToWin,
                        style: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: accent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (bestScore != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Best: $bestScore ${spec.scoreUnit}',
                style: const TextStyle(
                    fontFamily: _kFont, fontSize: 13, color: Colors.white54),
              ),
            ),
          ],
          const Spacer(),
          Row(
            children: [
              if (action != null) ...[
                action!,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: GestureDetector(
                  onTap: onStart,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: accent.withValues(alpha: 0.45),
                            blurRadius: 18)
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'START',
                        style: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameHud extends StatelessWidget {
  final MiniGameSession session;

  /// Pause control, shown to the LEFT of the game name. Null hides it (attract
  /// mode, where the autopilot owns the round).
  final VoidCallback? onPause;

  const _GameHud({required this.session, this.onPause});

  @override
  Widget build(BuildContext context) {
    final spec = session.spec;
    final total = spec.durationSeconds * 1000;
    final left = session.remaining.inMilliseconds;
    final frac = total == 0 ? 0.0 : (left / total).clamp(0.0, 1.0);
    final secondsLeft = (left / 1000).ceil();
    final urgent = secondsLeft <= 5 && session.isRunning;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Flexible + ellipsis: long game names must yield to the score
              // instead of overflowing the HUD on phone widths.
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onPause != null) ...[
                      GestureDetector(
                        onTap: onPause,
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding:
                              EdgeInsets.only(right: 8, top: 2, bottom: 2),
                          child: Icon(Icons.pause_rounded,
                              color: Colors.white54, size: 20),
                        ),
                      ),
                    ],
                    Flexible(
                      child: Text(
                        spec.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: _kFont,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white54),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${session.score} ${spec.scoreUnit}',
                style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: spec.accent),
              ),
              Text(
                '${secondsLeft}s',
                style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: urgent ? const Color(0xFFFF5252) : Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 5,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(
                  urgent ? const Color(0xFFFF5252) : spec.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownOverlay extends StatelessWidget {
  final int value;
  final Color accent;
  const _CountdownOverlay({required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Text(
              '$value',
              key: ValueKey(value),
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 110,
                fontWeight: FontWeight.bold,
                color: accent,
                shadows: [Shadow(color: accent, blurRadius: 30)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// End-of-game locked transition: a cosmic burst with the score counting up
/// from zero, then a "STOP!" settle. Intentionally has NO tap handlers, so
/// reflexive end-of-game tapping can't skip the results — this is the input
/// lock that guarantees players see the payoff.
class _TransitionOverlay extends StatefulWidget {
  final int count; // 3,2,1 then 0 = STOP!
  final int score;
  final String scoreUnit;
  final Color accent;
  const _TransitionOverlay({
    required this.count,
    required this.score,
    required this.scoreUnit,
    required this.accent,
  });

  @override
  State<_TransitionOverlay> createState() => _TransitionOverlayState();
}

class _TransitionOverlayState extends State<_TransitionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    final settled = widget.count <= 0;
    // width/height infinity forces this overlay to FILL the available space even
    // when handed loose constraints (e.g. the party page embeds the host in a
    // Stack, which passes loose constraints to non-positioned children). Without
    // it, the Stack below could shrink-wrap to the Column and render top-left.
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Expanding cosmic rings radiating from the core.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => CustomPaint(
                painter: _CosmicBurstPainter(_pulse.value, accent),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "TIME'S UP",
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 18),
              // Score counts up from 0 — the emotional payoff of the round.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: widget.score.toDouble()),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Text(
                  '${value.round()}',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 96,
                    fontWeight: FontWeight.bold,
                    color: accent,
                    shadows: [Shadow(color: accent, blurRadius: 34)],
                  ),
                ),
              ),
              Text(
                widget.scoreUnit,
                style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 15,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: settled
                    ? Text(
                        'STOP!',
                        key: const ValueKey('stop'),
                        style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          color: accent,
                        ),
                      )
                    : Text(
                        'tallying the round…',
                        key: ValueKey(widget.count),
                        style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.4),
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

/// Concentric rings expanding outward from screen center — the "cosmic zoom
/// out / collapse" flavor called for by the transition spec.
class _CosmicBurstPainter extends CustomPainter {
  final double t; // 0..1, repeating
  final Color accent;
  const _CosmicBurstPainter(this.t, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.longestSide * 0.7;
    for (int i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1.0;
      final radius = maxR * phase;
      final alpha = (1.0 - phase) * 0.22;
      if (alpha <= 0) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = accent.withValues(alpha: alpha);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_CosmicBurstPainter old) =>
      old.t != t || old.accent != accent;
}

/// Full-screen PAUSED modal (solo human play). The host has already frozen the
/// clock and the game; this just offers Resume / Quit.
class _PauseOverlay extends StatelessWidget {
  final Color accent;
  final VoidCallback onResume;
  final VoidCallback onQuit;
  const _PauseOverlay({
    required this.accent,
    required this.onResume,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.82),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pause_circle_filled, color: accent, size: 56),
              const SizedBox(height: 12),
              Text(
                'PAUSED',
                style: TextStyle(
                  fontFamily: Potatuhs.displayFont,
                  fontSize: 30,
                  color: Colors.white,
                  letterSpacing: 3,
                  shadows: [Shadow(color: accent, blurRadius: 18)],
                ),
              ),
              const SizedBox(height: 28),
              _BigButton(label: 'RESUME', color: accent, onTap: onResume),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onQuit,
                child: Container(
                  height: 52,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Center(
                    child: Text('QUIT',
                        style: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                            letterSpacing: 2)),
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

/// A generated AI opponent and the score it posted this round.
class _Opponent {
  final String name;
  final int score;
  const _Opponent(this.name, this.score);
}

class _ResultsView extends StatefulWidget {
  final MiniGameSpec spec;
  final int score;
  final String? playerLabel;
  final int? bestScore;
  final bool newBest;
  final bool isParty;
  final List<_Opponent> opponents;
  final LeaderboardStats stats;
  final int stars; // 0–3
  final int bestStreak;
  final VoidCallback? onContinue;
  final VoidCallback? onPlayAgain;
  final VoidCallback onExit;

  const _ResultsView({
    required this.spec,
    required this.score,
    required this.newBest,
    required this.isParty,
    required this.stats,
    required this.stars,
    required this.bestStreak,
    required this.onExit,
    this.opponents = const [],
    this.playerLabel,
    this.bestScore,
    this.onContinue,
    this.onPlayAgain,
  });

  @override
  State<_ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends State<_ResultsView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Eased 0→1 progress for the window [start, end] of the master timeline —
  /// the choreography that staggers each element's entrance.
  double _stage(double start, double end, {Curve curve = Curves.easeOutCubic}) {
    final raw = ((_c.value - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(raw);
  }

  /// Fade + rise (or, with negative [dy], settle-down) reveal.
  Widget _reveal(double v, Widget child, {double dy = 14}) {
    return Opacity(
      opacity: v,
      child: Transform.translate(offset: Offset(0, (1 - v) * dy), child: child),
    );
  }

  /// This round's standings (you + opponents) as shared leaderboard entries.
  List<LeaderboardEntry> get _entries => [
        LeaderboardEntry('YOU', widget.score, isPlayer: true),
        for (final o in widget.opponents) LeaderboardEntry(o.name, o.score),
      ];

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final accent = spec.accent;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final titleT = _stage(0.00, 0.18);
          final scoreT = _stage(0.08, 0.52);
          final scoreScale =
              0.62 + 0.38 * _stage(0.08, 0.52, curve: Curves.easeOutBack);
          final unitT = _stage(0.34, 0.54);
          final badgeT = _stage(0.60, 0.78);
          final streakT = _stage(0.66, 0.84);
          final boardT = _stage(0.55, 0.88);
          final buttonsT = _stage(0.80, 1.0);
          // Count the score up as it scales in — the payoff beat.
          final shownScore =
              (widget.score * _stage(0.08, 0.52, curve: Curves.easeOut))
                  .round();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              _reveal(
                titleT,
                const Center(
                  child: Text("TIME'S UP",
                      style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: Colors.white54)),
                ),
                dy: -8,
              ),
              const SizedBox(height: 6),
              if (widget.playerLabel != null)
                _reveal(
                  titleT,
                  Center(
                    child: Text(widget.playerLabel!,
                        style: const TextStyle(
                            fontFamily: _kFont,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
              const SizedBox(height: 12),
              Opacity(
                opacity: scoreT == 0.0 ? 0.0 : 1.0,
                child: Transform.scale(
                  scale: scoreScale,
                  child: Center(
                    child: Text(
                      '$shownScore',
                      style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 68,
                        fontWeight: FontWeight.bold,
                        color: accent,
                        shadows: [Shadow(color: accent, blurRadius: 26 * scoreT)],
                      ),
                    ),
                  ),
                ),
              ),
              _reveal(
                unitT,
                Center(
                  child: Text(spec.scoreUnit,
                      style: const TextStyle(
                          fontFamily: _kFont,
                          fontSize: 16,
                          color: Colors.white70)),
                ),
              ),
              const SizedBox(height: 10),
              _starsRow(),
              if (widget.newBest) ...[
                const SizedBox(height: 8),
                _reveal(badgeT, _badge('NEW BEST!', const Color(0xFFFFD54F))),
              ] else if (widget.bestScore != null) ...[
                const SizedBox(height: 8),
                _reveal(
                  badgeT,
                  Center(
                    child: Text('Best: ${widget.bestScore}',
                        style: const TextStyle(
                            fontFamily: _kFont,
                            fontSize: 14,
                            color: Colors.white54)),
                  ),
                ),
              ],
              if (_streakLabel != null) ...[
                const SizedBox(height: 8),
                _reveal(streakT, _badge(_streakLabel!, const Color(0xFFFF7043))),
              ],
              // Solo: the full three-view leaderboard. Party: the board owns the
              // cross-player standings, so we keep this screen lean.
              if (!widget.isParty) ...[
                const SizedBox(height: 16),
                Expanded(
                  child: _reveal(
                    boardT,
                    LeaderboardPanel(
                      entries: _entries,
                      stats: widget.stats,
                      scoreUnit: spec.scoreUnit,
                      accent: accent,
                      showMatch: widget.opponents.isNotEmpty,
                    ),
                    dy: 20,
                  ),
                ),
                const SizedBox(height: 14),
              ] else
                const Spacer(),
              _reveal(
                buttonsT,
                widget.isParty
                    ? _BigButton(
                        label: 'CONTINUE',
                        color: accent,
                        onTap: widget.onContinue!)
                    : Column(
                        children: [
                          _BigButton(
                              label: 'PLAY AGAIN',
                              color: accent,
                              onTap: widget.onPlayAgain!),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: widget.onExit,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: Colors.white24),
                              ),
                              child: const Center(
                                child: Text('EXIT',
                                    style: TextStyle(
                                        fontFamily: _kFont,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white70,
                                        letterSpacing: 2)),
                              ),
                            ),
                          ),
                        ],
                      ),
                dy: 22,
              ),
            ],
          );
        },
      ),
    );
  }

  /// Three stars, each popping in (elastic) once the score has landed. The
  /// Mario-Party payoff. Earned stars bounce in; unearned outlines sit waiting.
  Widget _starsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < 3; i++)
          Builder(builder: (_) {
            final start = 0.48 + i * 0.10;
            final pop = Curves.elasticOut
                .transform(((_c.value - start) / 0.34).clamp(0.0, 1.0));
            final earned = i < widget.stars;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: earned ? (0.2 + 0.8 * pop) : 1.0,
                child: Opacity(
                  opacity: earned ? pop.clamp(0.0, 1.0) : 1.0,
                  child: Icon(
                    earned ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 36,
                    color: earned
                        ? const Color(0xFFFFD54F)
                        : Colors.white.withValues(alpha: 0.22),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  /// Streak award: 30+ = mastery, 20+ = recognition. Null below 20.
  String? get _streakLabel {
    if (widget.bestStreak >= 30) {
      return '🔥 ${widget.bestStreak} STREAK — MASTER';
    }
    if (widget.bestStreak >= 20) return '🔥 ${widget.bestStreak} STREAK';
    return null;
  }

  Widget _badge(String text, Color color) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Text(
          text,
          style: TextStyle(
              fontFamily: _kFont,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.2),
        ),
      ),
    );
  }
}

class _BigButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BigButton(
      {required this.label, required this.color, required this.onTap});

  @override
  State<_BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<_BigButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(color, Colors.white, 0.16)!,
                color,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: _down ? 0.30 : 0.50),
                blurRadius: _down ? 12 : 22,
                offset: Offset(0, _down ? 2 : 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 3),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual carousel — shown on the intro when a game ships `legendFrames`
// (and/or a `demoBuilder`). Each card is drawn by the game's OWN render code, so
// the manual shows the literal components a player will meet, not a text list.
// Auto-advances and is swipeable; the `howToWin` line stays pinned beneath it.
// ═══════════════════════════════════════════════════════════════════════════

class _LegendCarousel extends StatefulWidget {
  final MiniGameSpec spec;
  final Color accent;
  const _LegendCarousel({required this.spec, required this.accent});

  @override
  State<_LegendCarousel> createState() => _LegendCarouselState();
}

class _LegendCarouselState extends State<_LegendCarousel> {
  final PageController _controller = PageController();
  Timer? _auto;
  int _page = 0;

  // Reserved demo slot: a game may ship a live attract-mode demo as the last
  // card. It runs on its own throwaway session so it never touches real score.
  MiniGameSession? _demoSession;

  List<LegendFrame> get _frames => widget.spec.legendFrames;
  bool get _hasDemo => widget.spec.demoBuilder != null;
  int get _pageCount => _frames.length + (_hasDemo ? 1 : 0);

  /// Dwell per card. Reading pace, not slideshow pace (checkpoint
  /// 2026-07-11: 3.2s flipped rules ~4× faster than they could be read).
  static const _kDwell = Duration(milliseconds: 12800);

  @override
  void initState() {
    super.initState();
    if (_hasDemo) _demoSession = MiniGameSession(spec: widget.spec);
    _armAuto();
  }

  /// One-shot advance armed after every page change (auto OR manual swipe),
  /// so a manual swipe resets the reading clock instead of the carousel
  /// flipping a card out from under the player.
  void _armAuto() {
    _auto?.cancel();
    if (_pageCount <= 1) return;
    _auto = Timer(_kDwell, () {
      if (!mounted || !_controller.hasClients) return;
      _controller.animateToPage(
        (_page + 1) % _pageCount,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _controller.dispose();
    _demoSession?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    // Illustration canvas sized to the screen: a fixed 168px strip cramped
    // legend labels and clipped bottom edges on tall phones while the intro
    // screen sat mostly empty (playtest 2026-07-12). Floor keeps short
    // windows at the old footprint.
    final legendHeight =
        (MediaQuery.sizeOf(context).height * 0.26).clamp(168.0, 300.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW TO PLAY',
            style: TextStyle(
                fontFamily: _kFont,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: accent),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: legendHeight,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) {
                setState(() => _page = i);
                _armAuto();
              },
              itemCount: _pageCount,
              itemBuilder: (context, i) {
                if (_hasDemo && i == _pageCount - 1) return _demoCard();
                return _frameCard(_frames[i]);
              },
            ),
          ),
          const SizedBox(height: 10),
          if (_pageCount > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < _pageCount; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? accent
                          : Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.emoji_events, color: accent, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.spec.howToWin,
                  style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: accent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _frameCard(LegendFrame f) {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              color: Colors.black.withValues(alpha: 0.35),
              child: CustomPaint(
                painter: _LegendFramePainter(f.paint),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          f.caption,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontFamily: _kFont, fontSize: 13, color: Colors.white, height: 1.2),
        ),
      ],
    );
  }

  Widget _demoCard() {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              color: Colors.black.withValues(alpha: 0.35),
              child: widget.spec.demoBuilder!(context, _demoSession!),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Live demo',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontFamily: _kFont,
              fontSize: 13,
              color: widget.accent,
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _LegendFramePainter extends CustomPainter {
  final LegendPainter fn;
  _LegendFramePainter(this.fn);

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.shortestSide <= 0) {
      return;
    }
    fn(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _LegendFramePainter oldDelegate) =>
      oldDelegate.fn != fn;
}
