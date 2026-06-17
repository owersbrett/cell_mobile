import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/potatuhs.dart';
import 'mini_game.dart';

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

  const MiniGameHost({
    Key? key,
    required this.spec,
    required this.onExit,
    this.playerLabel,
    this.onComplete,
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
  int? _bestScore;
  bool _newBest = false;

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
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _bestScore = prefs.getInt(_bestKey));
  }

  String get _bestKey => 'minigame_best_${widget.spec.id}';

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
    _endsAt = DateTime.now()
        .add(Duration(seconds: widget.spec.durationSeconds));
    _session.hostSetPhase(MiniGamePhase.playing);
    _clock = Timer.periodic(const Duration(milliseconds: 100), (_) {
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
    if (!widget.isParty) _saveBest();
    setState(() {});
  }

  Future<void> _saveBest() async {
    final score = _session.score;
    if (_bestScore == null || score > _bestScore!) {
      _newBest = score > 0;
      _bestScore = score;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_bestKey, score);
      if (mounted) setState(() {});
    }
  }

  void _playAgain() {
    _clock?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _newBest = false;
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
          builder: (context, _) {
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
                        Expanded(
                            child: spec.builder(context, _session)),
                      ],
                    ),
                    if (_session.phase == MiniGamePhase.countdown)
                      _CountdownOverlay(
                          value: _countdown, accent: spec.accent),
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
                return _ResultsView(
                  spec: spec,
                  score: _session.score,
                  playerLabel: widget.playerLabel,
                  bestScore: widget.isParty ? null : _bestScore,
                  newBest: _newBest,
                  isParty: widget.isParty,
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

class _ResultsView extends StatelessWidget {
  final MiniGameSpec spec;
  final int score;
  final String? playerLabel;
  final int? bestScore;
  final bool newBest;
  final bool isParty;
  final VoidCallback? onContinue;
  final VoidCallback? onPlayAgain;
  final VoidCallback onExit;

  const _ResultsView({
    required this.spec,
    required this.score,
    required this.newBest,
    required this.isParty,
    required this.onExit,
    this.playerLabel,
    this.bestScore,
    this.onContinue,
    this.onPlayAgain,
  });

  @override
  Widget build(BuildContext context) {
    final accent = spec.accent;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Center(
            child: Text(
              "TIME'S UP",
              style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.white54),
            ),
          ),
          const SizedBox(height: 8),
          if (playerLabel != null)
            Center(
              child: Text(
                playerLabel!,
                style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              '$score',
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 84,
                fontWeight: FontWeight.bold,
                color: accent,
                shadows: [Shadow(color: accent, blurRadius: 26)],
              ),
            ),
          ),
          Center(
            child: Text(
              spec.scoreUnit,
              style: const TextStyle(
                  fontFamily: _kFont, fontSize: 16, color: Colors.white70),
            ),
          ),
          if (newBest) ...[
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD54F)),
                ),
                child: const Text(
                  'NEW BEST!',
                  style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD54F),
                      letterSpacing: 1.5),
                ),
              ),
            ),
          ] else if (bestScore != null) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Best: $bestScore',
                style: const TextStyle(
                    fontFamily: _kFont, fontSize: 14, color: Colors.white54),
              ),
            ),
          ],
          const Spacer(),
          if (isParty)
            _BigButton(label: 'CONTINUE', color: accent, onTap: onContinue!)
          else ...[
            _BigButton(label: 'PLAY AGAIN', color: accent, onTap: onPlayAgain!),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onExit,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Center(
                  child: Text(
                    'EXIT',
                    style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                        letterSpacing: 2),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BigButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 18)
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: 3),
          ),
        ),
      ),
    );
  }
}
