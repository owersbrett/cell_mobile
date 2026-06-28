import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../party/party_models.dart';
import '../telemetry/cell_telemetry.dart';
import '../theme/potatuhs.dart';
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

  const MiniGameHost({
    Key? key,
    required this.spec,
    required this.onExit,
    this.playerLabel,
    this.onComplete,
    this.opponentCount = 0,
    this.disruption = false,
  }) : super(key: key);

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
    CellTelemetry.recordMiniGamePlay(widget.spec.id);
    _endsAt = DateTime.now()
        .add(Duration(seconds: widget.spec.durationSeconds));
    _appliedBonus = Duration.zero;
    _session.hostSetPhase(MiniGamePhase.playing);
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

  void _finish({bool fromSession = false}) {
    _clock?.cancel();
    _clock = null;
    _session.hostTick(Duration.zero);
    if (!fromSession) _session.hostSetPhase(MiniGamePhase.finished);
    if (!widget.isParty) _recordRun();
    _generateOpponents();
    _startWrapUp();
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
    _session.removeListener(_onSessionChanged);
    _session.dispose();
    super.dispose();
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
                return _IntroView(
                  spec: spec,
                  playerLabel: widget.playerLabel,
                  bestScore: widget.isParty ? null : _bestScore,
                  onStart: _startCountdown,
                  onExit: widget.onExit,
                );
              case MiniGamePhase.countdown:
              case MiniGamePhase.playing:
                return Stack(
                  children: [
                    Column(
                      children: [
                        _GameHud(session: _session),
                        Expanded(child: gameChild!),
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
                    // Always-available quit. In a party round the board overlays
                    // its own SKIP/forfeit, so the in-game quit is for solo
                    // Explore play (leave back to the scale).
                    if (!widget.isParty)
                      Positioned(
                        top: 6,
                        left: 10,
                        child: SafeArea(
                          child: GestureDetector(
                            onTap: widget.onExit,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: Colors.white24),
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white70, size: 20),
                            ),
                          ),
                        ),
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
                return _ResultsView(
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
                );
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

  const _IntroView({
    required this.spec,
    required this.onStart,
    required this.onExit,
    this.playerLabel,
    this.bestScore,
  });

  @override
  Widget build(BuildContext context) {
    final accent = spec.accent;
    return Padding(
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
          GestureDetector(
            onTap: onStart,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: accent.withValues(alpha: 0.45), blurRadius: 18)
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
        ],
      ),
    );
  }
}

class _GameHud extends StatelessWidget {
  final MiniGameSession session;
  const _GameHud({required this.session});

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
              Text(
                spec.name,
                style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white54),
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
