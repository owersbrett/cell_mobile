import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Bit Memory  (BioScale.nothings)  —  the binary memory ladder
//
// SELF-CONTAINED MODULE. Depends only on the framework session
// ([MiniGameSession]) and the brand theme. No per-game shared helpers, no
// other game's code. An agent can rebuild this game by editing only this
// folder. See GAME.md / AGENT.md / EDUCATION.md alongside this file.
//
// CORE LOOP (host owns the 60s clock, countdown, score HUD and results):
//   1. MEMORIZE — a string of bits is shown. Length DOUBLES each level:
//      level 1..8 → [1, 2, 4, 8, 16, 32, 64, 128]. A "GO" button ends the
//      memorize window early; otherwise it auto-advances after a short window
//      that scales with length.
//   2. ANSWER — the string hides. Two big buttons, 0 and 1. Reproduce the
//      string in order, one bit per press. Filled pips show HOW MANY bits you
//      have entered, never the values.
//   3. EVALUATE fail-fast — the first wrong bit ends the attempt as WRONG;
//      a full correct string is RIGHT.
//        RIGHT → award length×10, advance one level (cap 8), streak++.
//        WRONG → knock back one level (min 1), reset streak.
//   4. The first time a level is reached, a dismissible EDUCATION card explains
//      that bit-width (bit / nibble / byte / 16 / 32 / 64 / 128).
// ═══════════════════════════════════════════════════════════════════════════

// ── Feel constants — tune here without touching logic ──────────────────────
/// Bit-lengths per level (index 0 = level 1). Length doubles each level.
const List<int> _kLevelLengths = [1, 2, 4, 8, 16, 32, 64, 128];

/// Memorize window = base + perBit × length, capped. The GO button lets a
/// confident player skip straight to answering.
const double _kWindowBase = 0.5;
const double _kWindowPerBit = 0.18;
const double _kWindowCap = 7.0;

/// How long the RIGHT/WRONG result flash holds before the next prompt.
const double _kResultHold = 1.0;

/// Points for clearing a level = length × this. Deeper = exponentially more
/// (10 / 20 / 40 / 80 / 160 / 320 / 640 / 1280).
const int _kPointsPerBit = 10;

/// Accent — matches the Bit Memory catalog entry.
const Color _kAccent = Color(0xFF35D0BA);
const Color _kZero = Color(0xFF6690A3); // airforce-ish
const Color _kOne = Color(0xFFE19816); // sienna

// ── Internal phases (distinct from host MiniGamePhase) ─────────────────────
enum _Phase { ready, milestone, memorize, answer, result }

class BitMemoryGame extends StatefulWidget {
  final MiniGameSession session;
  const BitMemoryGame({super.key, required this.session});

  @override
  State<BitMemoryGame> createState() => _BitMemoryGameState();
}

class _BitMemoryGameState extends State<BitMemoryGame> {
  final Random _rng = Random();

  MiniGameSession get _session => widget.session;

  _Phase _phase = _Phase.ready;
  bool _started = false;

  int _level = 1; // 1..8
  int _streak = 0;
  List<int> _bits = const [];
  int _answerIndex = 0;

  // Drives a fresh time-bar animation each memorize window.
  int _windowEpoch = 0;
  double _windowSeconds = 0;
  Timer? _windowTimer;
  Timer? _resultTimer;

  // Education milestones already shown (by level). Each fires once per run.
  final Set<int> _milestoneShown = {};
  int _pendingMilestone = 1;

  // Last result flash.
  bool _lastCorrect = false;
  int _lastAward = 0;

  int _lenForLevel(int level) => _kLevelLengths[(level - 1).clamp(0, 7)];

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSession);
  }

  @override
  void dispose() {
    _session.removeListener(_onSession);
    _windowTimer?.cancel();
    _resultTimer?.cancel();
    super.dispose();
  }

  void _onSession() {
    if (!mounted) return;
    // Auto-start the first prompt when the host flips us into play.
    if (_session.isRunning && !_started) {
      _started = true;
      _startRun();
      return; // _startRun already calls setState
    }
    // When the run ends, freeze any in-flight timers and reflect the phase.
    if (!_session.isRunning && _started) {
      _windowTimer?.cancel();
      _resultTimer?.cancel();
    }
    setState(() {});
  }

  // ── Run / level lifecycle ──────────────────────────────────────────────
  void _startRun() {
    _level = 1;
    _streak = 0;
    _milestoneShown.clear();
    _enterLevel();
  }

  void _enterLevel() {
    _generateBits();
    _answerIndex = 0;
    if (!_milestoneShown.contains(_level)) {
      _pendingMilestone = _level;
      setState(() => _phase = _Phase.milestone);
    } else {
      _enterMemorize();
    }
  }

  void _generateBits() {
    final n = _lenForLevel(_level);
    _bits = List<int>.generate(n, (_) => _rng.nextInt(2));
  }

  void _dismissMilestone() {
    _milestoneShown.add(_pendingMilestone);
    _enterMemorize();
  }

  void _enterMemorize() {
    final len = _bits.length;
    _windowSeconds =
        (_kWindowBase + _kWindowPerBit * len).clamp(_kWindowBase, _kWindowCap);
    _windowTimer?.cancel();
    _windowEpoch++;
    _windowTimer = Timer(
      Duration(milliseconds: (_windowSeconds * 1000).round()),
      _toAnswer,
    );
    setState(() => _phase = _Phase.memorize);
  }

  void _toAnswer() {
    if (!mounted || !_session.isRunning) return;
    _windowTimer?.cancel();
    setState(() {
      _answerIndex = 0;
      _phase = _Phase.answer;
    });
  }

  // ── Input ──────────────────────────────────────────────────────────────
  void _onGo() {
    if (_phase != _Phase.memorize || !_session.isRunning) return;
    _toAnswer();
  }

  void _onBit(int value) {
    if (_phase != _Phase.answer || !_session.isRunning) return;
    final expected = _bits[_answerIndex];
    if (value != expected) {
      _resolve(false);
      return;
    }
    _answerIndex++;
    if (_answerIndex >= _bits.length) {
      _resolve(true);
    } else {
      setState(() {});
    }
  }

  void _resolve(bool correct) {
    final clearedLen = _bits.length;
    if (correct) {
      _lastAward = clearedLen * _kPointsPerBit;
      _session.addScore(_lastAward);
      _streak++;
      _session.noteStreak(_streak);
      _level = min(8, _level + 1);
    } else {
      _lastAward = 0;
      _streak = 0;
      _level = max(1, _level - 1);
    }
    _lastCorrect = correct;
    setState(() => _phase = _Phase.result);
    _resultTimer?.cancel();
    _resultTimer = Timer(
      Duration(milliseconds: (_kResultHold * 1000).round()),
      () {
        if (!mounted || !_session.isRunning) return;
        _enterLevel();
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Potatuhs.inkDeep,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 10),
              Expanded(child: _stage()),
              const SizedBox(height: 12),
              _bitPad(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final len = _lenForLevel(_level);
    return Row(
      children: [
        _tag('LEVEL $_level', _kAccent),
        const SizedBox(width: 8),
        _tag('$len BIT${len == 1 ? '' : 'S'}', Potatuhs.textSecondary),
        const Spacer(),
        if (_streak > 0) _tag('STREAK $_streak', Potatuhs.gold),
      ],
    );
  }

  Widget _tag(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.10),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Text(label, style: Potatuhs.label(size: 11, color: color)),
      );

  Widget _stage() {
    switch (_phase) {
      case _Phase.ready:
        return _readyStage();
      case _Phase.milestone:
        return _milestoneStage();
      case _Phase.memorize:
        return _memorizeStage();
      case _Phase.answer:
        return _answerStage();
      case _Phase.result:
        return _resultStage();
    }
  }

  // Calm pre-play state. The host overlays its own countdown on top of this.
  Widget _readyStage() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('1 0 1 1 0',
              style: Potatuhs.display(size: 40, color: _kAccent)),
          const SizedBox(height: 16),
          Text('BIT MEMORY',
              style: Potatuhs.display(size: 26, color: Potatuhs.textPrimary)),
          const SizedBox(height: 8),
          Text('Memorize the bits, then play them back.',
              textAlign: TextAlign.center,
              style: Potatuhs.body(size: 14, color: Potatuhs.textSecondary)),
        ],
      ),
    );
  }

  Widget _memorizeStage() {
    return Column(
      children: [
        Text('MEMORIZE',
            style: Potatuhs.label(size: 12, color: _kAccent)),
        const SizedBox(height: 8),
        _TimeBar(
          key: ValueKey(_windowEpoch),
          seconds: _windowSeconds,
          color: _kAccent,
        ),
        const SizedBox(height: 14),
        Expanded(child: _bitDisplay(_bits)),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: PotatuhsButton(
            label: 'GO',
            display: true,
            onTap: _onGo,
          ),
        ),
      ],
    );
  }

  Widget _answerStage() {
    final len = _bits.length;
    return Column(
      children: [
        Text('PLAY IT BACK',
            style: Potatuhs.label(size: 12, color: _kOne)),
        const SizedBox(height: 6),
        Text('bit ${_answerIndex + 1} of $len',
            style: Potatuhs.body(size: 14, color: Potatuhs.textSecondary)),
        const SizedBox(height: 16),
        Expanded(child: Center(child: _progress(len, _answerIndex))),
      ],
    );
  }

  Widget _resultStage() {
    final color = _lastCorrect ? _kAccent : Colors.redAccent;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_lastCorrect ? 'CORRECT' : 'WRONG',
              style: Potatuhs.display(size: 40, color: color)),
          const SizedBox(height: 10),
          if (_lastCorrect)
            Text('+$_lastAward',
                style: Potatuhs.display(size: 26, color: Potatuhs.gold))
          else ...[
            Text('the string was',
                style:
                    Potatuhs.body(size: 13, color: Potatuhs.textSecondary)),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: _bitDisplay(_bits, dim: true),
            ),
          ],
        ],
      ),
    );
  }

  // The two big input buttons (disabled outside the answer phase / pre-play).
  Widget _bitPad() {
    final active = _phase == _Phase.answer && _session.isRunning;
    return SizedBox(
      height: 120,
      child: Row(
        children: [
          Expanded(child: _bitButton(0, _kZero, active)),
          const SizedBox(width: 14),
          Expanded(child: _bitButton(1, _kOne, active)),
        ],
      ),
    );
  }

  Widget _bitButton(int value, Color color, bool active) {
    return Opacity(
      opacity: active ? 1.0 : 0.30,
      child: GestureDetector(
        onTap: active ? () => _onBit(value) : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: color.withValues(alpha: 0.14),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
            boxShadow: active
                ? Potatuhs.glow(color, strength: 0.28, blur: 18)
                : null,
          ),
          child: Center(
            child: Text('$value',
                style: Potatuhs.display(size: 56, color: color)),
          ),
        ),
      ),
    );
  }

  // ── Bit string display (memorize / reveal) ─────────────────────────────
  Widget _bitDisplay(List<int> bits, {bool dim = false}) {
    return SingleChildScrollView(
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final b in bits) _bitCell(b, dim: dim),
          ],
        ),
      ),
    );
  }

  Widget _bitCell(int b, {bool dim = false}) {
    final color = b == 1 ? _kOne : _kZero;
    // Smaller cells when the string is long so 128 bits still fit.
    final big = _bits.length <= 16;
    final size = big ? 40.0 : (_bits.length <= 64 ? 26.0 : 18.0);
    final font = big ? 22.0 : (_bits.length <= 64 ? 15.0 : 11.0);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(big ? 10 : 6),
        color: color.withValues(alpha: dim ? 0.10 : 0.18),
        border: Border.all(
            color: color.withValues(alpha: dim ? 0.30 : 0.55),
            width: big ? 1.5 : 1.0),
      ),
      child: Text('$b',
          style: TextStyle(
            fontFamily: Potatuhs.bodyFont,
            fontSize: font,
            fontWeight: FontWeight.w800,
            color: color.withValues(alpha: dim ? 0.6 : 1.0),
          )),
    );
  }

  // ── Answer progress (filled pips — count only, never the values) ────────
  Widget _progress(int len, int filled) {
    // Pips for short strings; a compact bar + count for long ones.
    if (len <= 16) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (int i = 0; i < len; i++)
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled
                    ? _kAccent
                    : Colors.white.withValues(alpha: 0.08),
                border: Border.all(
                    color: _kAccent.withValues(alpha: i < filled ? 0.9 : 0.3)),
              ),
            ),
        ],
      );
    }
    final frac = len == 0 ? 0.0 : filled / len;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$filled / $len',
            style: Potatuhs.display(size: 34, color: _kAccent)),
        const SizedBox(height: 16),
        SizedBox(
          width: 220,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(_kAccent),
            ),
          ),
        ),
      ],
    );
  }

  // ── Education milestone card (event-driven, dismissible) ────────────────
  Widget _milestoneStage() {
    final m = _milestoneFor(_pendingMilestone);
    return Center(
      child: Container(
        decoration: Potatuhs.surface(
          fill: Potatuhs.inkPanel,
          borderColor: _kAccent.withValues(alpha: 0.5),
          glowColor: _kAccent,
          glowStrength: 0.3,
          radius: 18,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(m.headline,
                textAlign: TextAlign.center,
                style: Potatuhs.display(size: 24, color: _kAccent)),
            const SizedBox(height: 6),
            Text(m.subhead,
                textAlign: TextAlign.center,
                style: Potatuhs.label(size: 11, color: Potatuhs.textSecondary)),
            const SizedBox(height: 14),
            Text(m.body,
                textAlign: TextAlign.center,
                style: Potatuhs.body(size: 14, color: Potatuhs.textPrimary)),
            if (m.table.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [for (final t in m.table) _tableChip(t)],
              ),
            ],
            const SizedBox(height: 20),
            PotatuhsButton(
              label: 'GOT IT',
              icon: Icons.bolt,
              onTap: _dismissMilestone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableChip(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: _kAccent.withValues(alpha: 0.3)),
        ),
        child: Text(t,
            style: TextStyle(
              fontFamily: Potatuhs.bodyFont,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Potatuhs.textPrimary,
            )),
      );

  _Milestone _milestoneFor(int level) {
    switch (level) {
      case 1:
        return const _Milestone(
          headline: "That's a bit!",
          subhead: '1 BIT · 2 VALUES',
          body: 'The smallest unit of information — a single 0 or 1. '
              'On or off. With one bit there are exactly 2 possible values.',
        );
      case 2:
        return const _Milestone(
          headline: '2 bits → 4 values',
          subhead: '2 BITS · 4 VALUES',
          body: 'Add a second bit and you can count to 3. Each extra bit '
              'doubles the number of patterns.',
          table: ['00 = 0', '01 = 1', '10 = 2', '11 = 3'],
        );
      case 3:
        return const _Milestone(
          headline: "That's a nibble!",
          subhead: '4 BITS · 16 VALUES',
          body: 'Four bits hold 16 values (0–15). One hexadecimal digit is '
              'exactly 4 bits (0–F); two hex digits make one byte.',
        );
      case 4:
        return const _Milestone(
          headline: "That's a byte!",
          subhead: '8 BITS · 256 VALUES',
          body: '8 bits → 256 values (0–255). The 8-bit era (NES). 255 is the '
              'classic cap — max gold, items, stats. A byte = 2 hex digits.',
        );
      case 5:
        return const _Milestone(
          headline: '16 bits → 65,536 values',
          subhead: '16 BITS · 2 BYTES',
          body: '0–65,535. The 16-bit era (SNES / Genesis). 65,535 gold caps; '
              '32,767 is the signed cap.',
        );
      case 6:
        return const _Milestone(
          headline: '32 bits → ~4.29 billion',
          subhead: '32 BITS · 4 BYTES',
          body: '4,294,967,295 values. 32-bit systems, the ~4 GB RAM limit, '
              'IPv4 addresses. Signed overflow at 2,147,483,647 broke the '
              'Gangnam Style view counter.',
        );
      case 7:
        return const _Milestone(
          headline: '64 bits → ~18.4 quintillion',
          subhead: '64 BITS · 8 BYTES',
          body: 'Modern 64-bit CPUs. Counters this wide are effectively '
              'limitless — you will not overflow them by counting.',
        );
      default:
        return const _Milestone(
          headline: '128 bits → 3.4×10³⁸',
          subhead: '128 BITS · 16 BYTES',
          body: 'Unimaginably large. UUIDs, cryptographic keys and IPv6 '
              'addresses all live at 128 bits — enough to name everything.',
        );
    }
  }
}

class _Milestone {
  final String headline;
  final String subhead;
  final String body;
  final List<String> table;
  const _Milestone({
    required this.headline,
    required this.subhead,
    required this.body,
    this.table = const [],
  });
}

/// A small, isolated shrinking time bar. Animates 1→0 over [seconds] using a
/// single [TweenAnimationBuilder] so the memorize countdown never rebuilds the
/// whole game tree at 60fps. A fresh [key] per window restarts it.
class _TimeBar extends StatelessWidget {
  final double seconds;
  final Color color;
  const _TimeBar({super.key, required this.seconds, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 0.0),
      duration: Duration(milliseconds: (seconds * 1000).round()),
      builder: (context, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: v,
          minHeight: 8,
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    );
  }
}
