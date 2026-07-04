import 'dart:math';

import 'package:flutter/material.dart';

import '../../../theme/potatuhs.dart';
import '../../mini_game.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Everything — "Everything Everywhere"  (BioScale.universeAll)
//
// SELF-CONTAINED MODULE. Extracted from the mini_games_batch3 megafile so this
// game can be reviewed/improved without touching other games. Depends only on
// the framework session (MiniGameSession) + Flutter.
// ═══════════════════════════════════════════════════════════════════════════

// Local copy of the shared juice particle — kept private so the module owns
// all its dependencies (no reliance on a shared megafile helper).
class _JuiceParticle {
  double x, y, vx, vy, life, maxLife, radius;
  Color color;
  _JuiceParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
    this.radius = 3,
  }) : maxLife = life;
}

// ═══════════════════════════════════════════════════════════════════════════════
// EverythingGame — "Everything Everywhere"
// Multilingual word-finder: type the English meaning of a word shown in many
// rotating foreign-language forms.  Three concentric wheels of related forms
// orbit the center at different speeds for cosmic visual flavor.
// ═══════════════════════════════════════════════════════════════════════════════

// ---------------------------------------------------------------------------
// Feel constants — tweak here without hunting through the logic below
// ---------------------------------------------------------------------------

/// Total game duration in seconds.
const double _ewTotalSeconds = 60.0;

/// Starting time budget per word (seconds).  Shrinks each round by [_ewTimeDecay].
const double _ewWordTimeStart = 12.0;

/// How many seconds are subtracted from the per-word budget each round.
const double _ewTimeDecay = 0.6;

/// Minimum per-word budget (seconds) regardless of decay.
const double _ewWordTimeMin = 4.0;

/// Points awarded for a correct answer.
const int _ewPointsCorrect = 10;

/// Points per second remaining when the answer is given (bonus).
const int _ewPointsTimeBonus = 2;

/// First hint reveals after this many seconds into the word (the category).
const double _ewHint1Delay = 3.0;

/// Second hint: on round >= this round number hints come 1 s faster per round.
const int _ewHintEscalationRound = 4;

/// Second hint reveals a letter after this many seconds into the word.
const double _ewHint2Delay = 6.0;

/// Seconds between language cycling on the center display.
const double _ewLangCycleBase = 1.4;

/// Minimum language cycle speed (at high escalation).
const double _ewLangCycleMin = 0.55;

/// Outer wheel rotation speed (radians/s).
const double _ewWheelSpeedOuter = 0.22;

/// Middle wheel rotation speed (radians/s).
const double _ewWheelSpeedMiddle = -0.15; // opposite direction

/// Inner (decorative) ring rotation speed (radians/s).
const double _ewWheelSpeedInner = 0.35;

// ---------------------------------------------------------------------------
// Word dataset — English answer + forms in other languages/scripts
// ---------------------------------------------------------------------------

class _EWWord {
  final String answer;       // English word the player must type
  final String category;     // shown as Hint 1 (e.g. "Nature", "Body")
  final List<String> forms;  // foreign-language renderings shown in center
  const _EWWord({required this.answer, required this.category, required this.forms});
}

const List<_EWWord> _ewWords = [
  _EWWord(answer: 'water', category: 'Nature',
    forms: ['agua', 'eau', 'wasser', 'mizu (水)', 'acqua', 'voda', 'pani', 'uisce', 'vatten', 'mae nam']),
  _EWWord(answer: 'fire', category: 'Nature',
    forms: ['fuego', 'feu', 'feuer', 'hi (火)', 'fuoco', 'ogon', 'agni', 'tine', 'eld', 'nar']),
  _EWWord(answer: 'star', category: 'Cosmos',
    forms: ['estrella', 'étoile', 'stern', 'hoshi (星)', 'stella', 'zvezda', 'tara', 'réalta', 'stjärna', 'dara']),
  _EWWord(answer: 'moon', category: 'Cosmos',
    forms: ['luna', 'lune', 'mond', 'tsuki (月)', 'luna', 'luna', 'chand', 'gealach', 'måne', 'ay']),
  _EWWord(answer: 'sun', category: 'Cosmos',
    forms: ['sol', 'soleil', 'sonne', 'taiyō (太陽)', 'sole', 'solntse', 'suraj', 'grian', 'sol', 'güneş']),
  _EWWord(answer: 'earth', category: 'Cosmos',
    forms: ['tierra', 'terre', 'erde', 'chi (地)', 'terra', 'zemlya', 'dharti', 'an domhan', 'jord', 'dünya']),
  _EWWord(answer: 'life', category: 'Existence',
    forms: ['vida', 'vie', 'leben', 'inochi (命)', 'vita', 'zhizn', 'jeevan', 'saol', 'liv', 'hayat']),
  _EWWord(answer: 'time', category: 'Existence',
    forms: ['tiempo', 'temps', 'zeit', 'jikan (時間)', 'tempo', 'vremya', 'samay', 'am', 'tid', 'zaman']),
  _EWWord(answer: 'love', category: 'Feeling',
    forms: ['amor', 'amour', 'liebe', 'ai (愛)', 'amore', 'lyubov', 'pyar', 'grá', 'kärlek', 'aşk']),
  _EWWord(answer: 'light', category: 'Cosmos',
    forms: ['luz', 'lumière', 'licht', 'hikari (光)', 'luce', 'svet', 'prakash', 'solas', 'ljus', 'ışık']),
  _EWWord(answer: 'wind', category: 'Nature',
    forms: ['viento', 'vent', 'wind', 'kaze (風)', 'vento', 'veter', 'hawa', 'gaoth', 'vind', 'rüzgar']),
  _EWWord(answer: 'tree', category: 'Nature',
    forms: ['árbol', 'arbre', 'baum', 'ki (木)', 'albero', 'derevo', 'ped', 'crann', 'träd', 'ağaç']),
  _EWWord(answer: 'dream', category: 'Mind',
    forms: ['sueño', 'rêve', 'traum', 'yume (夢)', 'sogno', 'son', 'sapna', 'brionglóid', 'dröm', 'rüya']),
  _EWWord(answer: 'heart', category: 'Body',
    forms: ['corazón', 'coeur', 'herz', 'kokoro (心)', 'cuore', 'serdtse', 'dil', 'croí', 'hjärta', 'kalp']),
  _EWWord(answer: 'sky', category: 'Nature',
    forms: ['cielo', 'ciel', 'himmel', 'sora (空)', 'cielo', 'nebo', 'aakash', 'spéir', 'himmel', 'gökyüzü']),
  _EWWord(answer: 'ocean', category: 'Nature',
    forms: ['océano', 'océan', 'ozean', 'umi (海)', 'oceano', 'okean', 'sagar', 'aigéan', 'hav', 'okyanus']),
  _EWWord(answer: 'peace', category: 'Feeling',
    forms: ['paz', 'paix', 'frieden', 'heiwa (平和)', 'pace', 'mir', 'shanti', 'síocháin', 'fred', 'barış']),
  _EWWord(answer: 'voice', category: 'Mind',
    forms: ['voz', 'voix', 'stimme', 'koe (声)', 'voce', 'golos', 'awaaz', 'guth', 'röst', 'ses']),
];

// ---------------------------------------------------------------------------
// Wheel-ring word entries (decorative; unrelated to the answer)
// ---------------------------------------------------------------------------

const List<String> _ewWheelTokens = [
  'cosmos', 'alma', 'âme', 'seele', 'tamashii', 'anima', 'ruh',
  'infinito', 'unendlich', 'mugen', 'infini', 'sonsuz',
  'origen', 'origin', 'ursprung', 'kigen', 'menşe',
  'todo', 'tout', 'alles', 'subete', 'tutto',
  'nada', 'rien', 'nichts', 'mu', 'niente',
  'luz', 'licht', 'hikari', 'lumière', 'ışık',
  'tiempo', 'temps', 'zeit', 'jikan', 'zaman',
];

// ---------------------------------------------------------------------------
// EverythingGame widget
// ---------------------------------------------------------------------------

class EverythingGame extends StatefulWidget {
  final MiniGameSession session;
  const EverythingGame({Key? key, required this.session}) : super(key: key);
  @override
  State<EverythingGame> createState() => _EverythingGameState();
}

class _EverythingGameState extends State<EverythingGame>
    with SingleTickerProviderStateMixin {

  // --- animation / timing ---
  late AnimationController _ctrl;
  double _lastWallTime = 0;

  // --- game state ---
  double _gameTimeLeft = _ewTotalSeconds;
  bool _gameOver = false;
  int _score = 0;
  int _round = 0;             // increments each new word
  List<_EWWord> _deck = [];   // shuffled copy, cycled through

  // --- current word ---
  late _EWWord _current;
  double _wordTimeLeft = _ewWordTimeStart;
  double _wordTimeBudget = _ewWordTimeStart;
  int _langIndex = 0;
  // Shuffled order of form indices so each word starts on a RANDOM language
  // (not always Spanish) and cycles through all of them in random order.
  List<int> _formOrder = [];
  int _formPos = 0;
  double _langTimer = 0;
  bool _hint1Shown = false;   // category
  bool _hint2Shown = false;   // first letter
  bool _correct = false;
  double _correctFlash = 0;   // >0 = still flashing

  // --- typing ---
  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // --- wheels ---
  double _wheelAngle0 = 0; // inner
  double _wheelAngle1 = 0; // middle
  double _wheelAngle2 = 0; // outer
  // Slight "slow-down" pulse on outer wheel
  double _outerPulse = 0;

  // --- particles ---
  final List<_JuiceParticle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _buildDeck();
    _loadWord();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(hours: 1),
    )
      ..addListener(_tick)
      ..forward();
    _lastWallTime = _now();
    // ATTRACT autopilot: this game knows the answer to every word — it stores
    // it in [_EWWord.answer] to score against. Registered always (harmless in
    // normal play; the host only calls it hands-free). See [_autoStep].
    widget.session.autoPilot = _autoStep;
    // Buffer answers to a human pace — else it types a correct word every tick.
    widget.session.autoPilotInterval = const Duration(milliseconds: 1100);
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ctrl.dispose();
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ─────────────────────────────────────────────────────
  /// One competent, deterministic move per host tick (~250ms). This plays
  /// Everything Everywhere *correctly*, never by simulating keystrokes: it
  /// already knows the English answer for the current word ([_current.answer]),
  /// so it drops that exact word straight into the input buffer ([_textCtrl])
  /// and fires the game's own answer-check handler ([_onTextChanged]). A correct
  /// match scores + burst-particles + auto-advances to the next word (600ms
  /// later), and the next tick simply submits that word too. Mid-transition —
  /// game over, already-correct flash — there is nothing to answer, so return.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_gameOver || _correct || _correctFlash > 0) return; // nothing to answer
    _textCtrl.text = _current.answer;             // set the input buffer
    _onTextChanged(_current.answer);              // submit via the game's check
  }

  // Build a shuffled deck; refill when exhausted.
  void _buildDeck() {
    _deck = List<_EWWord>.from(_ewWords)..shuffle(_rng);
  }

  void _loadWord() {
    if (_deck.isEmpty) _buildDeck();
    _current = _deck.removeLast();
    final timeThisRound = (_ewWordTimeStart - _round * _ewTimeDecay)
        .clamp(_ewWordTimeMin, _ewWordTimeStart);
    _wordTimeBudget = timeThisRound;
    _wordTimeLeft = timeThisRound;
    // Random language order per word — starts on a random language, not Spanish.
    _formOrder = List<int>.generate(_current.forms.length, (i) => i)
      ..shuffle(_rng);
    _formPos = 0;
    _langIndex = _formOrder.isEmpty ? 0 : _formOrder[0];
    _langTimer = 0;
    _hint1Shown = false;
    _hint2Shown = false;
    _correct = false;
    _correctFlash = 0;
    _textCtrl.clear();
    // Auto-focus keyboard on each word
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_gameOver) _focusNode.requestFocus();
    });
  }

  // Compute effective hint timings for current round (escalation: hints come
  // progressively later as rounds advance to keep pressure up).
  double get _effectiveHint1Delay {
    final extra = (_round - _ewHintEscalationRound).clamp(0, 999) * 0.4;
    return (_ewHint1Delay + extra).clamp(0, _wordTimeBudget - 0.5);
  }

  double get _effectiveHint2Delay {
    final extra = (_round - _ewHintEscalationRound).clamp(0, 999) * 0.4;
    return (_ewHint2Delay + extra).clamp(0, _wordTimeBudget - 0.2);
  }

  double get _effectiveLangCycle {
    final speedup = _round * 0.08;
    return (_ewLangCycleBase - speedup).clamp(_ewLangCycleMin, _ewLangCycleBase);
  }

  void _tick() {
    // Host owns the clock — only advance during the playing phase.
    if (!widget.session.isRunning) return;
    final now = _now();
    final dt = (now - _lastWallTime).clamp(0.001, 0.05);
    _lastWallTime = now;

    setState(() {
      // --- wheels ---
      _outerPulse += dt * 1.1;
      final outerMod = 0.6 + 0.4 * (0.5 + 0.5 * sin(_outerPulse)); // [0.6..1.0]
      _wheelAngle0 += _ewWheelSpeedInner * dt;
      _wheelAngle1 += _ewWheelSpeedMiddle * dt;
      _wheelAngle2 += _ewWheelSpeedOuter * outerMod * dt;

      // --- particles ---
      for (final p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt;
      }
      _particles.removeWhere((p) => p.life <= 0);

      // --- flash timer ---
      if (_correctFlash > 0) {
        _correctFlash -= dt;
        return; // brief freeze while flashing
      }

      // --- word clock ---
      _wordTimeLeft -= dt;

      // Hints
      final elapsed = _wordTimeBudget - _wordTimeLeft;
      if (!_hint1Shown && elapsed >= _effectiveHint1Delay) _hint1Shown = true;
      if (!_hint2Shown && elapsed >= _effectiveHint2Delay) _hint2Shown = true;

      // Language cycling — walk the shuffled order, reshuffle each full pass
      // so it keeps surfacing every language in a fresh random sequence.
      _langTimer += dt;
      if (_langTimer >= _effectiveLangCycle && _formOrder.isNotEmpty) {
        _langTimer = 0;
        _formPos++;
        if (_formPos >= _formOrder.length) {
          _formOrder.shuffle(_rng);
          _formPos = 0;
        }
        _langIndex = _formOrder[_formPos];
      }

      // Timeout → advance, no points
      if (_wordTimeLeft <= 0) {
        _round++;
        _loadWord();
      }
    });
  }

  void _onTextChanged(String val) {
    if (_gameOver || _correct) return;
    if (val.trim().toLowerCase() == _current.answer.toLowerCase()) {
      // Correct!
      final timeBonus = (_wordTimeLeft * _ewPointsTimeBonus).round();
      final earned = _ewPointsCorrect + timeBonus;
      setState(() {
        _score += earned;
        widget.session.addScore(earned); // report to host scoreboard
        _correct = true;
        _correctFlash = 0.55;
        // Burst particles from center-ish
        for (int i = 0; i < 20; i++) {
          final a = _rng.nextDouble() * 2 * pi;
          final spd = 0.15 + _rng.nextDouble() * 0.25;
          _particles.add(_JuiceParticle(
            x: 0.5, y: 0.45,
            vx: cos(a) * spd, vy: sin(a) * spd,
            life: 0.6 + _rng.nextDouble() * 0.4,
            color: const Color(0xFFFFD54F),
            radius: 3 + _rng.nextDouble() * 3,
          ));
        }
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _round++;
            _loadWord();
          });
        }
      });
    }
  }

  String get _hint1Text => _hint1Shown ? _current.category : '';
  String get _hint2Text {
    if (!_hint2Shown) return '';
    final a = _current.answer;
    if (a.isEmpty) return '';
    return '${a[0].toUpperCase()}_ _ _';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tapping anywhere outside the TextField re-focuses it.
      onTap: () => _focusNode.requestFocus(),
      child: Container(
        color: const Color(0xFF050510),
        child: LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            children: [
              // --- Background wheel painter ---
              CustomPaint(
                size: Size(w, h),
                painter: _EverythingWheelPainter(
                  angle0: _wheelAngle0,
                  angle1: _wheelAngle1,
                  angle2: _wheelAngle2,
                  tokens: _ewWheelTokens,
                  particles: _particles,
                  correctFlash: _correctFlash,
                ),
              ),

              if (!_gameOver) ...[
                // (Host draws score + timer.)

                // --- Central language display ---
                Positioned(
                  top: h * 0.24, left: 24, right: 24,
                  child: Column(
                    children: [
                      // Word-timer progress bar
                      _WordTimerBar(
                        fraction: (_wordTimeLeft / _wordTimeBudget).clamp(0.0, 1.0),
                      ),
                      const SizedBox(height: 14),
                      // Current foreign-language form. A fade+scale transition
                      // makes each language change clearly visible so the player
                      // can adjust mid-type as it keeps cycling.
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.85, end: 1.0)
                                .animate(anim),
                            child: child,
                          ),
                        ),
                        child: Text(
                          _current.forms[_langIndex],
                          key: ValueKey(_langIndex),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: _correctFlash > 0
                                ? const Color(0xFFFFD54F)
                                : Colors.white,
                            shadows: [
                              Shadow(
                                color: const Color(0xFF7E57C2).withValues(alpha: 0.8),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Language flag (form index / total)
                      Text(
                        '${_langIndex + 1} / ${_current.forms.length}',
                        style: const TextStyle(
                          fontFamily: 'Avenir', fontSize: 11, color: Colors.white24,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Hints row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_hint1Text.isNotEmpty)
                            _HintChip(label: _hint1Text),
                          if (_hint1Text.isNotEmpty && _hint2Text.isNotEmpty)
                            const SizedBox(width: 8),
                          if (_hint2Text.isNotEmpty)
                            _HintChip(label: _hint2Text, bright: true),
                        ],
                      ),
                    ],
                  ),
                ),

                // --- Typing field ---
                Positioned(
                  bottom: h * 0.22, left: 32, right: 32,
                  child: Column(
                    children: [
                      const Text(
                        'Type the English word',
                        style: TextStyle(
                          fontFamily: 'Avenir', fontSize: 12, color: Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _EWTextField(
                        controller: _textCtrl,
                        focusNode: _focusNode,
                        onChanged: _onTextChanged,
                        correct: _correctFlash > 0,
                        // Keep the field ENABLED for the whole game so the OS
                        // keyboard/input connection is never torn down. During
                        // the brief correct-answer flash we go read-only instead
                        // of disabled — disabling a focused field drops the input
                        // connection and intermittently can't be re-attached,
                        // which permanently locks the player out of typing.
                        enabled: !_gameOver,
                        readOnly: _correctFlash > 0,
                      ),
                    ],
                  ),
                ),

                // --- Round indicator ---
                Positioned(
                  bottom: h * 0.15, left: 0, right: 0,
                  child: Center(
                    child: Text(
                      'Word ${_round + 1}',
                      style: const TextStyle(
                        fontFamily: 'Avenir', fontSize: 11, color: Colors.white24,
                      ),
                    ),
                  ),
                ),
              ],
              // (Game-over/results overlay handled by the host.)
            ],
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TextField wrapper
// ---------------------------------------------------------------------------

class _EWTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool correct;
  final bool enabled;
  final bool readOnly;

  const _EWTextField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.correct,
    required this.enabled,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      enabled: enabled,
      readOnly: readOnly,
      textAlign: TextAlign.center,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
      style: TextStyle(
        fontFamily: 'Avenir',
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: correct ? const Color(0xFFFFD54F) : Colors.white,
        letterSpacing: 2,
      ),
      cursorColor: const Color(0xFF7E57C2),
      decoration: InputDecoration(
        hintText: '???',
        hintStyle: const TextStyle(
          fontFamily: 'Avenir', fontSize: 22, color: Colors.white24,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: correct ? 0.08 : 0.04),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: correct
                ? const Color(0xFFFFD54F)
                : const Color(0xFF7E57C2).withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: correct
                ? const Color(0xFFFFD54F)
                : const Color(0xFF7E57C2),
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hint chip widget
// ---------------------------------------------------------------------------

class _HintChip extends StatelessWidget {
  final String label;
  final bool bright;
  const _HintChip({required this.label, this.bright = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: bright
                ? const Color(0xFFFFD54F).withValues(alpha: 0.7)
                : const Color(0xFF7E57C2).withValues(alpha: 0.5),
          ),
          color: (bright ? const Color(0xFFFFD54F) : const Color(0xFF7E57C2))
              .withValues(alpha: 0.07),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 13,
            color: bright
                ? const Color(0xFFFFD54F).withValues(alpha: 0.9)
                : Colors.white54,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Word timer bar
// ---------------------------------------------------------------------------

class _WordTimerBar extends StatelessWidget {
  final double fraction; // 1.0 = full, 0.0 = empty
  const _WordTimerBar({required this.fraction});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final Color barColor = fraction > 0.5
          ? const Color(0xFF7E57C2)
          : fraction > 0.25
              ? const Color(0xFFFFB300)
              : const Color(0xFFEF5350);
      return Stack(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: 4,
            width: w * fraction,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: barColor,
            ),
          ),
        ],
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Game-clock arc (top-right)
// ---------------------------------------------------------------------------

class _TimerArc extends StatelessWidget {
  final double fraction;
  final int seconds;
  const _TimerArc({required this.fraction, required this.seconds});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: CustomPaint(
        painter: _TimerArcPainter(fraction: fraction),
        child: Center(
          child: Text(
            '$seconds',
            style: const TextStyle(
              fontFamily: 'Avenir', fontSize: 12,
              fontWeight: FontWeight.bold, color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerArcPainter extends CustomPainter {
  final double fraction;
  const _TimerArcPainter({required this.fraction});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = cx - 3;
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);
    final Color arcColor = fraction > 0.4
        ? const Color(0xFF7E57C2)
        : fraction > 0.2
            ? const Color(0xFFFFB300)
            : const Color(0xFFEF5350);
    final fgPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -pi / 2,
      2 * pi * fraction,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerArcPainter old) =>
      old.fraction != fraction;
}

// ---------------------------------------------------------------------------
// Game-over panel
// ---------------------------------------------------------------------------

class _EWGameOverPanel extends StatelessWidget {
  final int score;
  final int rounds;
  final VoidCallback onRestart;
  const _EWGameOverPanel({required this.score, required this.rounds, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF7E57C2).withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Everything ends.',
              style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white38),
            ),
            const SizedBox(height: 12),
            Text(
              '$score',
              style: const TextStyle(
                fontFamily: 'Avenir', fontSize: 52,
                fontWeight: FontWeight.bold, color: Colors.white,
              ),
            ),
            const Text(
              'points',
              style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white38),
            ),
            const SizedBox(height: 6),
            Text(
              '$rounds words decoded',
              style: const TextStyle(fontFamily: 'Avenir', fontSize: 13, color: Colors.white30),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRestart,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF7E57C2).withValues(alpha: 0.6)),
                  color: const Color(0xFF7E57C2).withValues(alpha: 0.1),
                ),
                child: const Text(
                  'Again',
                  style: TextStyle(
                    fontFamily: 'Avenir', fontSize: 16,
                    fontWeight: FontWeight.bold, color: Colors.white70,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Three-wheel background painter
// ---------------------------------------------------------------------------

class _EverythingWheelPainter extends CustomPainter {
  final double angle0, angle1, angle2;
  final List<String> tokens;
  final List<_JuiceParticle> particles;
  final double correctFlash;

  const _EverythingWheelPainter({
    required this.angle0,
    required this.angle1,
    required this.angle2,
    required this.tokens,
    required this.particles,
    required this.correctFlash,
  });

  void _drawRing(Canvas canvas, Size size, double angle, double radius,
      List<String> words, Color color, double fontSize, double alpha) {
    final cx = size.width / 2;
    final cy = size.height * 0.42;
    final n = words.length;
    for (int i = 0; i < n; i++) {
      final a = angle + i / n * 2 * pi;
      final x = cx + cos(a) * radius;
      final y = cy + sin(a) * radius;
      final tp = TextPainter(
        text: TextSpan(
          text: words[i],
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: fontSize,
            color: color.withValues(alpha: alpha),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF050510),
    );

    final cx = size.width / 2;
    final cy = size.height * 0.42;

    // Subtle glow at center
    final flashAlpha = (correctFlash / 0.55).clamp(0.0, 1.0);
    final glowColor = Color.lerp(
      const Color(0xFF7E57C2).withValues(alpha: 0.07),
      const Color(0xFFFFD54F).withValues(alpha: 0.18),
      flashAlpha,
    )!;
    canvas.drawCircle(Offset(cx, cy), size.width * 0.55,
        Paint()..color = glowColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60));

    // Three orbital rings (decorative arcs)
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const ringRadii = [85.0, 145.0, 210.0];
    const ringAlphas = [0.08, 0.06, 0.04];
    for (int i = 0; i < 3; i++) {
      ringPaint.color = Colors.white.withValues(alpha: ringAlphas[i]);
      canvas.drawCircle(Offset(cx, cy), ringRadii[i], ringPaint);
    }

    // Determine ring word subsets
    final n = tokens.length;
    final inner = tokens.sublist(0, (n * 0.3).round().clamp(1, n));
    final middle = tokens.sublist(inner.length, (n * 0.65).round().clamp(inner.length, n));
    final outer = tokens.sublist(middle.length.clamp(0, n));

    _drawRing(canvas, size, angle0, ringRadii[0], inner,
        const Color(0xFFCE93D8), 8.5, 0.22);
    _drawRing(canvas, size, angle1, ringRadii[1], middle,
        const Color(0xFF9575CD), 9.0, 0.18);
    _drawRing(canvas, size, angle2, ringRadii[2], outer,
        const Color(0xFF7E57C2), 9.5, 0.14);

    // Particles
    for (final p in particles) {
      if (p.life > 0) {
        canvas.drawCircle(
          Offset(p.x * size.width, p.y * size.height),
          p.radius,
          Paint()
            ..color = p.color
                .withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EverythingWheelPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards for the intro screen. Each frame is a
// static snapshot of the LITERAL in-game components (the cosmic wheel field,
// the cycling foreign word, the answer field, the hint chips, the word-timer
// bar), drawn in the game's own palette. Cheap + self-contained: painted once
// in the intro carousel, never per-frame.
// ═══════════════════════════════════════════════════════════════════════════

// The game's own palette, named for the legend painters (same hex values used
// throughout the live game above — no new colors).
const Color _ewLegendBg = Color(0xFF050510);
const Color _ewLegendPurple = Color(0xFF7E57C2);
const Color _ewLegendPurpleMid = Color(0xFF9575CD);
const Color _ewLegendPurpleLight = Color(0xFFCE93D8);
const Color _ewLegendGold = Color(0xFFFFD54F);
const Color _ewLegendAmber = Color(0xFFFFB300);
const Color _ewLegendRed = Color(0xFFEF5350);

/// Centred text helper for the legend cards (theme body face, not 'Avenir').
void _ewLegendText(
  Canvas canvas,
  String text,
  Offset center,
  double fontSize,
  Color color, {
  FontWeight weight = FontWeight.w600,
  List<Shadow>? shadows,
  double letterSpacing = 0,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: Potatuhs.bodyFont,
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        shadows: shadows,
        letterSpacing: letterSpacing,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}

/// Deep-space backdrop + centre glow (gold-tinted when [flash] > 0), exactly
/// like the live `_EverythingWheelPainter` background.
void _ewLegendBackdrop(Canvas canvas, Size size, {double flash = 0}) {
  canvas.drawRect(Offset.zero & size, Paint()..color = _ewLegendBg);
  final c = Offset(size.width / 2, size.height * 0.45);
  final glow = Color.lerp(
    _ewLegendPurple.withValues(alpha: 0.10),
    _ewLegendGold.withValues(alpha: 0.20),
    flash.clamp(0.0, 1.0),
  )!;
  canvas.drawCircle(
    c,
    size.shortestSide * 0.55,
    Paint()
      ..color = glow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
  );
}

/// The three orbital word-wheels with a sprinkle of the real ring tokens.
void _ewLegendWheels(Canvas canvas, Size size, Offset c) {
  final base = size.shortestSide;
  final radii = [base * 0.26, base * 0.38, base * 0.50];
  const ringAlphas = [0.10, 0.07, 0.05];
  final ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  for (int i = 0; i < 3; i++) {
    ringPaint.color = Colors.white.withValues(alpha: ringAlphas[i]);
    canvas.drawCircle(c, radii[i], ringPaint);
  }
  const ringColors = [
    _ewLegendPurpleLight,
    _ewLegendPurpleMid,
    _ewLegendPurple
  ];
  const tokenAlphas = [0.30, 0.24, 0.18];
  for (int ring = 0; ring < 3; ring++) {
    final n = 4 + ring;
    for (int i = 0; i < n; i++) {
      final a = ring * 0.7 + i / n * 2 * pi;
      final pos = c + Offset(cos(a), sin(a)) * radii[ring];
      final token = _ewWheelTokens[(ring * 7 + i * 3) % _ewWheelTokens.length];
      _ewLegendText(canvas, token, pos, 7.5 + ring,
          ringColors[ring].withValues(alpha: tokenAlphas[ring]),
          weight: FontWeight.w500);
    }
  }
}

/// The per-word countdown bar (same track/fill as the live `_WordTimerBar`).
void _ewLegendTimerBar(
    Canvas canvas, Size size, double y, double fraction, Color color) {
  final left = size.width * 0.14;
  final width = size.width * 0.72;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(left, y, width, 5), const Radius.circular(2.5)),
    Paint()..color = Colors.white.withValues(alpha: 0.08),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(left, y, width * fraction.clamp(0.0, 1.0), 5),
        const Radius.circular(2.5)),
    Paint()..color = color,
  );
}

/// One hint chip, matching the live `_HintChip` (purple = category hint,
/// bright gold = first-letter hint).
void _ewLegendChip(Canvas canvas, Offset center, String label,
    {bool bright = false}) {
  final tp = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(
        fontFamily: Potatuhs.bodyFont,
        fontSize: 11,
        color: bright
            ? _ewLegendGold.withValues(alpha: 0.9)
            : Colors.white54,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final base = bright ? _ewLegendGold : _ewLegendPurple;
  final r = RRect.fromRectAndRadius(
    Rect.fromCenter(
        center: center, width: tp.width + 24, height: tp.height + 10),
    const Radius.circular(14),
  );
  canvas.drawRRect(r, Paint()..color = base.withValues(alpha: 0.07));
  canvas.drawRRect(
    r,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = base.withValues(alpha: bright ? 0.7 : 0.5),
  );
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}

/// The typing field, matching the live `_EWTextField` (gold when correct).
void _ewLegendField(Canvas canvas, Size size, Offset center, String text,
    {bool correct = false}) {
  final r = RRect.fromRectAndRadius(
    Rect.fromCenter(center: center, width: size.width * 0.58, height: 36),
    const Radius.circular(12),
  );
  canvas.drawRRect(
      r, Paint()..color = Colors.white.withValues(alpha: correct ? 0.08 : 0.04));
  canvas.drawRRect(
    r,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color =
          correct ? _ewLegendGold : _ewLegendPurple.withValues(alpha: 0.6),
  );
  _ewLegendText(canvas, text, center, 15,
      correct ? _ewLegendGold : Colors.white,
      weight: FontWeight.bold, letterSpacing: 2);
}

/// Small downward chevron cue.
void _ewLegendChevron(Canvas canvas, Offset c, Color color) {
  final p = Paint()
    ..color = color
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  canvas.drawLine(Offset(c.dx - 8, c.dy - 5), Offset(c.dx, c.dy + 4), p);
  canvas.drawLine(Offset(c.dx + 8, c.dy - 5), Offset(c.dx, c.dy + 4), p);
}

bool _ewLegendDegenerate(Size size) =>
    size.width <= 0 ||
    size.height <= 0 ||
    !size.width.isFinite ||
    !size.height.isFinite;

// ── Frame 1: the core object — one word cycling through languages ──────────
void _legendCycle(Canvas canvas, Size size) {
  if (_ewLegendDegenerate(size)) return;
  _ewLegendBackdrop(canvas, size);
  final c = Offset(size.width / 2, size.height * 0.45);
  _ewLegendWheels(canvas, size, c);
  // The same word ("water") in three of its forms, mid-cycle: faded previous,
  // bright current, faded next — with chevrons showing the flow.
  _ewLegendText(canvas, 'agua', Offset(c.dx, c.dy - size.height * 0.24), 12,
      Colors.white.withValues(alpha: 0.30));
  _ewLegendChevron(canvas, Offset(c.dx, c.dy - size.height * 0.14),
      _ewLegendPurpleLight.withValues(alpha: 0.5));
  _ewLegendText(
    canvas,
    'mizu (水)',
    c,
    21,
    Colors.white,
    weight: FontWeight.bold,
    shadows: [
      Shadow(
          color: _ewLegendPurple.withValues(alpha: 0.8), blurRadius: 14),
    ],
  );
  _ewLegendChevron(canvas, Offset(c.dx, c.dy + size.height * 0.13),
      _ewLegendPurpleLight.withValues(alpha: 0.5));
  _ewLegendText(canvas, 'wasser', Offset(c.dx, c.dy + size.height * 0.23), 12,
      Colors.white.withValues(alpha: 0.30));
  _ewLegendText(canvas, '4 / 10', Offset(c.dx, c.dy + size.height * 0.33), 9,
      Colors.white24);
}

// ── Frame 2: the verb + how to score — type the English meaning ────────────
void _legendType(Canvas canvas, Size size) {
  if (_ewLegendDegenerate(size)) return;
  _ewLegendBackdrop(canvas, size, flash: 1);
  _ewLegendText(
    canvas,
    'agua',
    Offset(size.width / 2, size.height * 0.24),
    19,
    Colors.white,
    weight: FontWeight.bold,
    shadows: [
      Shadow(
          color: _ewLegendPurple.withValues(alpha: 0.8), blurRadius: 14),
    ],
  );
  _ewLegendChevron(
      canvas, Offset(size.width / 2, size.height * 0.40), _ewLegendGold);
  final fieldC = Offset(size.width / 2, size.height * 0.57);
  _ewLegendField(canvas, size, fieldC, 'water', correct: true);
  // Gold burst particles, like the live correct-answer juice.
  final rng = Random(7);
  for (int i = 0; i < 12; i++) {
    final a = i / 12 * 2 * pi;
    final d = size.shortestSide * (0.20 + rng.nextDouble() * 0.14);
    canvas.drawCircle(
      fieldC + Offset(cos(a), sin(a)) * d,
      1.5 + rng.nextDouble() * 2.5,
      Paint()
        ..color =
            _ewLegendGold.withValues(alpha: 0.4 + rng.nextDouble() * 0.5),
    );
  }
  _ewLegendText(canvas, '+10  + time bonus',
      Offset(size.width / 2, size.height * 0.80), 11, _ewLegendGold,
      weight: FontWeight.bold);
}

// ── Frame 3: the help — hints arrive while the word timer drains ───────────
void _legendHints(Canvas canvas, Size size) {
  if (_ewLegendDegenerate(size)) return;
  _ewLegendBackdrop(canvas, size);
  _ewLegendTimerBar(canvas, size, size.height * 0.22, 0.42, _ewLegendAmber);
  _ewLegendText(
    canvas,
    'kokoro (心)',
    Offset(size.width / 2, size.height * 0.42),
    19,
    Colors.white,
    weight: FontWeight.bold,
    shadows: [
      Shadow(
          color: _ewLegendPurple.withValues(alpha: 0.8), blurRadius: 14),
    ],
  );
  _ewLegendChip(canvas, Offset(size.width * 0.35, size.height * 0.64), 'Body');
  _ewLegendChip(canvas, Offset(size.width * 0.64, size.height * 0.64), 'H _ _ _',
      bright: true);
  _ewLegendText(canvas, 'hints cost your time bonus',
      Offset(size.width / 2, size.height * 0.80), 9, Colors.white38);
}

// ── Frame 4: the danger + escalation — timeout scores zero, pace rises ─────
void _legendTimeout(Canvas canvas, Size size) {
  if (_ewLegendDegenerate(size)) return;
  _ewLegendBackdrop(canvas, size);
  _ewLegendTimerBar(canvas, size, size.height * 0.22, 0.10, _ewLegendRed);
  _ewLegendText(canvas, 'zvezda', Offset(size.width / 2, size.height * 0.42),
      19, Colors.white70,
      weight: FontWeight.bold);
  _ewLegendText(canvas, 'TOO SLOW · 0 points',
      Offset(size.width / 2, size.height * 0.60), 12, _ewLegendRed,
      weight: FontWeight.bold, letterSpacing: 1);
  // Speed chevrons: every round the languages cycle faster.
  final cy = size.height * 0.78;
  for (int i = 0; i < 3; i++) {
    final cx = size.width * 0.44 + i * 13;
    final p = Paint()
      ..color = _ewLegendPurpleLight.withValues(alpha: 0.35 + i * 0.25)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx - 4, cy - 6), Offset(cx + 4, cy), p);
    canvas.drawLine(Offset(cx + 4, cy), Offset(cx - 4, cy + 6), p);
  }
  _ewLegendText(canvas, 'faster every round',
      Offset(size.width / 2, size.height * 0.88), 9, Colors.white38);
}

/// The visual manual for Everything Everywhere — wired into the registry spec.
final List<LegendFrame> everythingLegendFrames = [
  const LegendFrame(
      caption: 'Watch one word cycle through many languages',
      paint: _legendCycle),
  const LegendFrame(
      caption: 'Type its English meaning — answer fast for bonus',
      paint: _legendType),
  const LegendFrame(
      caption: 'Stuck? Hints arrive: category, then first letter',
      paint: _legendHints),
  const LegendFrame(
      caption: 'Beat the bar — timeout scores zero and pace quickens',
      paint: _legendTimeout),
];
