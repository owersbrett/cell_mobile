import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ============================================================================
// HILBERT'S HOTEL — APPLY-THE-RULE: a logic puzzle about countable infinity.
//
// The hotel has a room for every counting number 1, 2, 3, … and it is ALREADY
// FULL — every room has a guest. Yet new guests keep arriving. Each round an
// arrival is announced (one guest · one infinite bus · infinitely many buses)
// and the player taps the REASSIGNMENT rule that makes room:
//   • one guest          → shift every guest n → n+1   (room 1 opens)
//   • one infinite bus    → n → 2n  (all odd rooms open for the bus)
//   • infinitely many buses → prime-powers: guest n → 2ⁿ, bus b seat s → (odd
//     prime)ˢ — unique factorization, no clashes.
// Distractor rules genuinely FAIL (dump everyone in room 1 = double-booking,
// shift down = evict guest 1, append a room = there is no last room). The
// rooms visibly shift so the paradox — a FULL infinite hotel always fits more —
// is felt, not just stated. Teaches countable infinity, bijections and ℵ₀.
//
// Self-contained module. Imports only the framework session + theme tokens.
// One Ticker drives one CustomPainter; the host owns the clock, the 3·2·1
// countdown, the score HUD and the results screen. This widget renders only
// the play area and never calls endEarly (no fail state). See GAME.md.
// ============================================================================

const String _kFont = Potatuhs.bodyFont;

// -- Palette (on Potatuhs ink) -----------------------------------------------
const Color _kBg = Potatuhs.inkDeep;
const Color _kFacade = Potatuhs.inkPanel; // the hotel building
const Color _kDoor = Color(0xFF1E1B18); // room interior
const Color _kDoorEdge = Color(0xFF3A352F);
const Color _kGold = Potatuhs.gold; // marquee / open-room glow
const Color _kResident = Potatuhs.sienna; // a guest already in residence
const Color _kArrival = Color(0xFF6FB7D6); // a newly-arrived guest (cool blue)
const Color _kGood = Color(0xFF69F0AE);
const Color _kBad = Color(0xFFFF5252);
const Color _kCardBg = Potatuhs.inkPanel;
const Color _kCardBorder = Color(0xFF3A352F);
const Color _kTextPrimary = Potatuhs.textPrimary;
const Color _kTextSub = Potatuhs.textSecondary;

// -- Layout ------------------------------------------------------------------
// The host stacks its own score/timer HUD ABOVE this widget (see
// mini_game_host.dart: Column[_GameHud, Expanded(game)]), so our play area is
// already below the score. We reserve a compact banner on top and a fixed panel
// on the bottom; both are sized so 4 rule cards + header + footer fit a phone
// without overflow, and the corridor keeps real height in the middle.
const int _kRooms = 7; // visible rooms (the corridor continues to ∞)
// Canvas reserve for the rule options / card. The panel itself sizes to its
// content (it may run a few px past this); the reserve only keeps the room
// row clear of it, so it errs roomy.
const double _kBottomPanel = 236;
const double _kBannerTop = 52; // top reserve for the arrival banner overlay

// -- Timing & scoring --------------------------------------------------------
const double _kFeedbackDur = 2.2; // seconds the resolution + card stay up
const double _kDropDur = 0.5; // new-guest drop-in animation length
const double _kShiftRate = 5.5; // how fast guests slide to their new rooms
const double _kDecayWindow = 4.5; // seconds the speed bonus decays over
const double _kFloorFrac = 0.35; // slowest-answer fraction of base points
const int _kStreakStep = 3; // correct answers per +1× multiplier

// ============================================================================
// Arrivals & rules (the educational core, as data)
// ============================================================================

enum _Arrival { oneGuest, oneBus, manyBuses }

extension _ArrivalInfo on _Arrival {
  /// Base points — harder cardinalities are worth more.
  int get base {
    switch (this) {
      case _Arrival.oneGuest:
        return 80;
      case _Arrival.oneBus:
        return 120;
      case _Arrival.manyBuses:
        return 170;
    }
  }

  IconData get icon {
    switch (this) {
      case _Arrival.oneGuest:
        return Icons.person_rounded;
      case _Arrival.oneBus:
        return Icons.directions_bus_rounded;
      case _Arrival.manyBuses:
        return Icons.commute_rounded;
    }
  }

  /// The announcement headline shown on the arrival banner.
  String get headline {
    switch (this) {
      case _Arrival.oneGuest:
        return '1 NEW GUEST';
      case _Arrival.oneBus:
        return 'A BUS — ℵ₀ GUESTS';
      case _Arrival.manyBuses:
        return 'ℵ₀ BUSES — EACH ℵ₀';
    }
  }

  String get blurb {
    switch (this) {
      case _Arrival.oneGuest:
        return 'One traveller at the desk. The hotel is full.';
      case _Arrival.oneBus:
        return 'A bus with one seat per counting number pulls in.';
      case _Arrival.manyBuses:
        return 'Infinitely many buses, each infinitely full, queue up.';
    }
  }
}

/// What a rule physically does to the corridor (drives the animation).
enum _Shift { plusOne, timesTwo, powTwo, dumpOne, shiftDown, addEnd }

class _Rule {
  final String id;
  final String label; // short rule, e.g. "n → n+1"
  final String sub; // one-line description
  final _Shift shift;
  final Set<_Arrival> solves; // arrivals this rule correctly accommodates
  final String win; // shown when it was the right call
  final String fail; // shown when it was the wrong call
  const _Rule({
    required this.id,
    required this.label,
    required this.sub,
    required this.shift,
    required this.solves,
    required this.win,
    required this.fail,
  });
}

const _Rule _rShiftOne = _Rule(
  id: 'shiftOne',
  label: 'n → n+1',
  sub: 'Every guest moves up one room',
  shift: _Shift.plusOne,
  solves: {_Arrival.oneGuest},
  win: 'Room 1 opens and the guest checks in. A full hotel still had room.',
  fail: 'This frees only ONE room. A bus is ℵ₀ guests — they will not fit.',
);
const _Rule _rDouble = _Rule(
  id: 'double',
  label: 'n → 2n',
  sub: 'Each guest moves to double their room',
  shift: _Shift.timesTwo,
  solves: {_Arrival.oneBus},
  win: 'Every odd room opens — ℵ₀ of them — and the bus fills the odds.',
  fail: 'Opens ℵ₀ rooms, but ℵ₀ BUSES need a 2-D pairing — this leaves them '
      'unassigned.',
);
const _Rule _rPrimes = _Rule(
  id: 'primes',
  label: 'Prime powers',
  sub: 'Guest n → 2ⁿ · bus b, seat s → (odd prime b)ˢ',
  shift: _Shift.powTwo,
  solves: {_Arrival.manyBuses},
  win: 'Unique prime factorization gives every guest a private room. No clash.',
  fail: 'It works, but it is overkill here. Save it for infinitely many buses.',
);
const _Rule _rDumpOne = _Rule(
  id: 'dumpOne',
  label: 'All → room 1',
  sub: 'Send everyone to room 1',
  shift: _Shift.dumpOne,
  solves: {},
  win: '',
  fail: 'Room 1 holds ONE guest. This double-books it infinitely — illegal.',
);
const _Rule _rShiftDown = _Rule(
  id: 'shiftDown',
  label: 'n → n−1',
  sub: 'Every guest moves down one room',
  shift: _Shift.shiftDown,
  solves: {},
  win: '',
  fail: 'Guest 1 has nowhere to go — room 0 does not exist. You evicted them.',
);
const _Rule _rAddEnd = _Rule(
  id: 'addEnd',
  label: 'Add a room at the end',
  sub: 'Build one more room past the last',
  shift: _Shift.addEnd,
  solves: {},
  win: '',
  fail: 'There is no last room — the hallway never ends. You cannot append to ∞.',
);

/// The correct rule for each arrival, and a curated distractor pool whose
/// members all GENUINELY fail for that arrival (so grading is never unfair).
const Map<_Arrival, _Rule> _kCorrect = {
  _Arrival.oneGuest: _rShiftOne,
  _Arrival.oneBus: _rDouble,
  _Arrival.manyBuses: _rPrimes,
};
const Map<_Arrival, List<_Rule>> _kDistractors = {
  _Arrival.oneGuest: [_rDumpOne, _rShiftDown, _rAddEnd],
  _Arrival.oneBus: [_rShiftOne, _rDumpOne, _rAddEnd, _rShiftDown],
  _Arrival.manyBuses: [_rDouble, _rShiftOne, _rDumpOne, _rAddEnd],
};

// ============================================================================
// Guest token + spark (inlined, tiny, self-contained)
// ============================================================================

class _Guest {
  final int origin; // starting room (1-based)
  double pos; // current room (fractional during a slide)
  double target;
  double appear; // 0..1 drop-in progress (1 = settled)
  final bool isNew; // a fresh arrival vs a resident
  _Guest({
    required this.origin,
    required this.pos,
    required this.target,
    this.appear = 1,
    this.isNew = false,
  });
}

class _Spark {
  Offset pos;
  Offset vel;
  double life;
  final double maxLife;
  final double size;
  final Color color;
  _Spark(this.pos, this.vel, this.life, this.size, this.color)
      : maxLife = life;
}

// ============================================================================
// Widget
// ============================================================================

class HilbertsHotelGame extends StatefulWidget {
  final MiniGameSession session;
  const HilbertsHotelGame({super.key, required this.session});

  @override
  State<HilbertsHotelGame> createState() => _HilbertsHotelGameState();
}

enum _Phase { choosing, feedback }

class _HilbertsHotelGameState extends State<HilbertsHotelGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  Duration _lastElapsed = Duration.zero;
  double _clock = 0;
  bool _started = false;

  _Phase _phase = _Phase.choosing;

  _Arrival _arrival = _Arrival.oneGuest;
  List<_Rule> _options = const [];
  _Arrival? _lastArrival;

  double _optionsAt = 0; // clock when options appeared (speed bonus)
  double _feedbackTimer = 0;

  // Resolution feedback.
  bool _wasCorrect = false;
  int _lastPts = 0;
  int _lastMult = 1;
  _Rule? _picked;

  int _streak = 0;

  // Corridor state.
  final List<_Guest> _guests = [];
  Set<int> _openRooms = const {}; // freed rooms (gold glow)
  int? _flashRoom; // room flashing red on a failed rule
  double _flashT = 0;

  final List<_Spark> _sparks = [];
  Size _fieldSize = Size.zero;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fillHotel();
    // ATTRACT autopilot: the game knows the correct reassignment rule for every
    // arrival, so it plays itself correctly (see [_autoStep]). Each move banks a
    // real scored answer, so pace it just slower than the feedback reveal.
    widget.session.autoPilot = _autoStep;
    widget.session.autoPilotInterval = const Duration(milliseconds: 1100);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ────────────────────────────────────────────────────
  /// One hands-free move per host tick. During [_Phase.choosing] it taps the
  /// ONE rule that actually accommodates the current arrival — the correct
  /// reassignment ([_kCorrect] / `rule.solves.contains(_arrival)`), never a
  /// distractor — so it banks genuine points. During [_Phase.feedback] it lets
  /// the resolution card breathe, then skips ahead to the next arrival (the
  /// round self-advances on its own timer anyway). Deterministic, no randomness.
  void _autoStep() {
    if (!widget.session.isRunning || !_started) return;
    switch (_phase) {
      case _Phase.choosing:
        _Rule? correct;
        for (final r in _options) {
          if (r.solves.contains(_arrival)) {
            correct = r;
            break;
          }
        }
        if (correct != null) _onRule(correct);
        break;
      case _Phase.feedback:
        // Nudge past the reveal so attract keeps moving; harmless if the
        // feedback timer has already elapsed.
        _onTapField();
        break;
    }
  }

  // ── Corridor helpers ─────────────────────────────────────────────────────────

  /// Reset the corridor to "full": one resident in every visible room. The
  /// paradox resets each arrival ("the hotel is full, yet…").
  void _fillHotel() {
    _guests.clear();
    for (int r = 1; r <= _kRooms; r++) {
      _guests.add(_Guest(origin: r, pos: r.toDouble(), target: r.toDouble()));
    }
    _openRooms = const {};
    _flashRoom = null;
    _flashT = 0;
  }

  // ── Round flow ───────────────────────────────────────────────────────────────

  double _progress() {
    final dur = widget.session.spec.durationSeconds;
    if (dur <= 0) return 0;
    final rem = widget.session.remaining.inMilliseconds / 1000.0;
    return (1 - rem / dur).clamp(0.0, 1.0);
  }

  _Arrival _pickArrival() {
    final p = _progress();
    final pool = <_Arrival>[_Arrival.oneGuest];
    if (p >= 0.28) pool.add(_Arrival.oneBus);
    if (p >= 0.58) {
      pool.add(_Arrival.manyBuses);
      // Bias toward the harder arrivals late so the difficulty is felt.
      if (p >= 0.75) pool.add(_Arrival.manyBuses);
    }
    _Arrival a;
    var guard = 0;
    do {
      a = pool[_rng.nextInt(pool.length)];
      guard++;
    } while (a == _lastArrival && pool.length > 1 && guard < 6);
    _lastArrival = a;
    return a;
  }

  void _startGame() {
    _started = true;
    _streak = 0;
    _nextRound();
  }

  void _nextRound() {
    _fillHotel();
    _arrival = _pickArrival();

    final correct = _kCorrect[_arrival]!;
    final pool = [..._kDistractors[_arrival]!]..shuffle(_rng);
    // 3 options early, 4 once the round warms up.
    final wantDistractors = _progress() < 0.4 ? 2 : 3;
    final picks = <_Rule>[correct];
    for (final d in pool) {
      if (picks.length >= 1 + wantDistractors) break;
      picks.add(d);
    }
    picks.shuffle(_rng);
    _options = picks;

    _picked = null;
    _optionsAt = _clock;
    _phase = _Phase.choosing;
  }

  // ── Input ────────────────────────────────────────────────────────────────────

  void _onRule(_Rule rule) {
    if (!widget.session.isRunning || _phase != _Phase.choosing) return;
    final correct = rule.solves.contains(_arrival);
    _picked = rule;
    _wasCorrect = correct;

    if (correct) {
      _streak++;
      final mult = 1 + _streak ~/ _kStreakStep;
      final answerTime = _clock - _optionsAt;
      final frac = 1 - (1 - _kFloorFrac) * (answerTime / _kDecayWindow).clamp(0.0, 1.0);
      final pts = (_arrival.base * frac).round() * mult;
      _lastPts = pts;
      _lastMult = mult;
      widget.session.addScore(pts);
      widget.session.noteStreak(_streak);
    } else {
      _streak = 0;
      _lastPts = 0;
      _lastMult = 1;
    }

    _applyShift(rule);
    _phase = _Phase.feedback;
    _feedbackTimer = _kFeedbackDur;
  }

  /// Animate what the chosen rule does to the corridor — whether it works or
  /// not — so the consequence is visible.
  void _applyShift(_Rule rule) {
    switch (rule.shift) {
      case _Shift.plusOne:
      case _Shift.timesTwo:
      case _Shift.powTwo:
        final occupied = <int>{};
        for (final g in _guests) {
          final nr = _shiftRoom(rule.shift, g.origin);
          g.target = nr.toDouble();
          if (nr >= 1 && nr <= _kRooms) occupied.add(nr);
        }
        final freed = <int>[];
        for (int r = 1; r <= _kRooms; r++) {
          if (!occupied.contains(r)) freed.add(r);
        }
        _openRooms = freed.toSet();
        // The arrivals drop into the freed rooms.
        for (final r in freed) {
          _guests.add(_Guest(
            origin: r,
            pos: r.toDouble(),
            target: r.toDouble(),
            appear: 0,
            isNew: true,
          ));
        }
        break;
      case _Shift.dumpOne:
        for (final g in _guests) {
          g.target = 1;
        }
        _flashRoom = 1;
        _flashT = 1;
        break;
      case _Shift.shiftDown:
        for (final g in _guests) {
          g.target = (g.origin - 1).toDouble(); // origin 1 → room 0 (evicted)
        }
        _flashRoom = 1;
        _flashT = 1;
        break;
      case _Shift.addEnd:
        _flashRoom = _kRooms; // flash the far end — there is no "next" room
        _flashT = 1;
        break;
    }
  }

  int _shiftRoom(_Shift shift, int r) {
    switch (shift) {
      case _Shift.plusOne:
        return r + 1;
      case _Shift.timesTwo:
        return 2 * r;
      case _Shift.powTwo:
        return _ipow(2, r);
      default:
        return r;
    }
  }

  static int _ipow(int base, int exp) {
    var r = 1;
    for (var i = 0; i < exp; i++) {
      r *= base;
      if (r > 9999) return r; // it only needs to leave the screen
    }
    return r;
  }

  void _onTapField() {
    // During feedback a tap skips ahead to the next arrival.
    if (_phase == _Phase.feedback) _feedbackTimer = 0;
  }

  // ── Game loop ────────────────────────────────────────────────────────────────

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    _clock += dt;

    final running = widget.session.isRunning;
    if (running && !_started) _startGame();

    // Slide guests toward their targets; fade flash; advance drop-ins.
    final k = (dt * _kShiftRate).clamp(0.0, 1.0);
    for (final g in _guests) {
      g.pos += (g.target - g.pos) * k;
      if (g.appear < 1) {
        g.appear = (g.appear + dt / _kDropDur).clamp(0.0, 1.0);
        if (g.appear > 0.45) _maybeSpark(g);
      }
    }
    if (_flashT > 0) _flashT = (_flashT - dt / 0.9).clamp(0.0, 1.0);

    if (running && _phase == _Phase.feedback) {
      _feedbackTimer -= dt;
      if (_feedbackTimer <= 0) _nextRound();
    }

    // Particles.
    _sparks.removeWhere((s) {
      s.life -= dt;
      s.pos += s.vel * dt;
      s.vel = s.vel * math.pow(0.12, dt).toDouble();
      return s.life <= 0;
    });

    if (mounted) setState(() {});
  }

  final Set<int> _sparked = {};
  void _maybeSpark(_Guest g) {
    if (!g.isNew || _sparked.contains(g.origin)) return;
    if (_fieldSize.isEmpty) return;
    _sparked.add(g.origin);
    final at = _roomScreenCenter(g.origin.toDouble());
    final color = _wasCorrect ? _kGood : _kArrival;
    for (var i = 0; i < 10; i++) {
      final a = _rng.nextDouble() * math.pi * 2;
      final sp = 50 + _rng.nextDouble() * 120;
      _sparks.add(_Spark(
        at,
        Offset(math.cos(a), math.sin(a)) * sp,
        0.35 + _rng.nextDouble() * 0.4,
        1.4 + _rng.nextDouble() * 2.6,
        color.withValues(alpha: 0.7 + _rng.nextDouble() * 0.3),
      ));
    }
  }

  // Mirror of the painter's room geometry, so sparks land on the right room.
  Offset _roomScreenCenter(double room) {
    const pad = 16.0;
    final plotL = pad;
    final plotR = _fieldSize.width - pad;
    final roomW = (plotR - plotL) / _kRooms;
    final top = _kBannerTop + 6;
    final bottom = _fieldSize.height - _kBottomPanel - 14;
    final cy = (top + bottom) / 2;
    return Offset(plotL + (room - 0.5) * roomW, cy);
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTapField,
        child: ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _HotelPainter(
                    clock: _clock,
                    guests: _guests,
                    openRooms: _openRooms,
                    flashRoom: _flashRoom,
                    flashT: _flashT,
                    sparks: _sparks,
                    running: widget.session.isRunning,
                  ),
                ),
              ),
              // Arrival banner (top).
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(bottom: false, child: _buildBanner()),
              ),
              // Options / feedback (bottom). Sizes to its content — a fixed
              // box clipped the last rule card on phones. The lift keeps it
              // clear of the iOS home indicator / Safari toolbar (viewPadding
              // is live now that index.html declares viewport-fit=cover).
              Positioned(
                left: 0,
                right: 0,
                bottom: math.max(
                    8, MediaQuery.of(context).viewPadding.bottom),
                child: _phase == _Phase.choosing
                    ? _buildOptions()
                    : _buildFeedback(),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBanner() {
    final running = widget.session.isRunning && _started;
    if (!running) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "HILBERT'S HOTEL",
              style: TextStyle(
                fontFamily: Potatuhs.displayFont,
                fontSize: 18,
                color: _kGold,
                letterSpacing: 1,
                shadows: [Shadow(color: _kGold.withValues(alpha: 0.6), blurRadius: 12)],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'A full ∞ hotel — yet always room for more',
              style: TextStyle(
                  fontFamily: _kFont, fontSize: 12, color: _kTextSub),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kArrival.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kArrival.withValues(alpha: 0.6)),
            ),
            child: Icon(_arrival.icon, color: _kArrival, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_arrival.headline}  ·  HOTEL FULL',
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _kTextPrimary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _arrival.blurb,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: _kFont, fontSize: 11.5, color: _kTextSub),
                ),
              ],
            ),
          ),
          if (_streak >= _kStreakStep) ...[
            const SizedBox(width: 8),
            _streakChip(),
          ],
        ],
      ),
    );
  }

  Widget _streakChip() {
    final mult = 1 + _streak ~/ _kStreakStep;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _kGold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kGold.withValues(alpha: 0.7)),
      ),
      child: Text(
        '×$mult · $_streak',
        style: const TextStyle(
          fontFamily: _kFont,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: _kGold,
        ),
      ),
    );
  }

  Widget _buildOptions() {
    // The panel is a fixed [_kBottomPanel] high (the canvas reserves it).
    // Three cards fit at full size; when the round warms up to four, compact
    // metrics shrink each card's padding/type so the header + 4 cards stay
    // inside the 214px panel on a phone instead of overflowing it.
    final compact = _options.length >= 4;
    // Objective line makes scoring legible: the number the host HUD shows is
    // POINTS, and this says what a correct pick is worth right now.
    final points = _arrival.base;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Flexible(
                child: Text(
                  'TAP THE RULE THAT MAKES ROOM',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: _kTextSub,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _kGood.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: _kGood.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '+$points pts',
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: _kGood,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 5 : 7),
          for (final r in _options)
            Padding(
              padding: EdgeInsets.only(bottom: compact ? 5 : 7),
              child: _optionCard(r, compact: compact),
            ),
        ],
      ),
    );
  }

  Widget _optionCard(_Rule r, {required bool compact}) {
    return GestureDetector(
      onTap: () => _onRule(r),
      child: Container(
        width: double.infinity,
        padding:
            EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 6 : 9),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kCardBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Scale down rather than wrap/ellipsize — a wrapped label
                  // adds a line and blows the fixed panel; the player must
                  // still read the whole rule.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      r.label,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: compact ? 14 : 15.5,
                        fontWeight: FontWeight.w900,
                        color: _kTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    r.sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: compact ? 10.5 : 11.5,
                        color: _kTextSub),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: _kTextSub.withValues(alpha: 0.6), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    final accent = _wasCorrect ? _kGood : _kBad;
    final rule = _picked;
    final header = _wasCorrect
        ? (_lastMult > 1 ? '+$_lastPts   ×$_lastMult streak!' : '+$_lastPts')
        : 'Not quite';
    final body = rule == null
        ? ''
        : (_wasCorrect ? rule.win : rule.fail);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: accent.withValues(alpha: 0.55), width: 1.4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      _wasCorrect
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: accent,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      header,
                      style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                    const Spacer(),
                    if (rule != null)
                      Text(
                        rule.label,
                        style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kTextSub,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  body,
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 13,
                    height: 1.38,
                    color: _kTextSub,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'TAP TO CONTINUE',
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: _kTextSub.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Painter — the corridor of rooms, the residents/arrivals, the ∞ fade, sparks.
// All continuous motion is here (one Ticker → setState → repaint).
// ============================================================================

class _HotelPainter extends CustomPainter {
  final double clock;
  final List<_Guest> guests;
  final Set<int> openRooms;
  final int? flashRoom;
  final double flashT;
  final List<_Spark> sparks;
  final bool running;

  _HotelPainter({
    required this.clock,
    required this.guests,
    required this.openRooms,
    required this.flashRoom,
    required this.flashT,
    required this.sparks,
    required this.running,
  });

  late double _plotL;
  late double _plotR;
  late double _roomW;
  late double _top;
  late double _bottom;

  double _roomX(double room) => _plotL + (room - 0.5) * _roomW;
  double get _cy => (_top + _bottom) / 2;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);

    const pad = 16.0;
    _plotL = pad;
    _plotR = size.width - pad;
    _roomW = (_plotR - _plotL) / _kRooms;
    _top = _kBannerTop + 6;
    _bottom = size.height - _kBottomPanel - 14;
    if (_bottom - _top <= 10 || _roomW <= 4) return;

    _paintAmbient(canvas, size);
    _paintCorridor(canvas);
    _paintGuests(canvas);
    _paintSparks(canvas);
  }

  void _paintAmbient(Canvas canvas, Size size) {
    // A warm marquee glow from the top-centre.
    canvas.drawCircle(
      Offset(size.width * 0.5, _top - 4),
      size.width * 0.6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _kGold.withValues(alpha: 0.07),
            _kGold.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.5, _top - 4),
          radius: size.width * 0.6,
        )),
    );
  }

  void _paintCorridor(Canvas canvas) {
    final bandTop = _cy - _roomW * 0.62;
    final bandBot = _cy + _roomW * 0.62;
    final h = bandBot - bandTop;

    // Facade slab spanning the rooms, fading into ∞ on the right.
    final slab = Rect.fromLTRB(_plotL - 4, bandTop - 14, _plotR + 4, bandBot + 14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(slab, const Radius.circular(14)),
      Paint()..color = _kFacade.withValues(alpha: 0.55),
    );

    for (int r = 1; r <= _kRooms; r++) {
      final cx = _roomX(r.toDouble());
      final doorRect = Rect.fromCenter(
        center: Offset(cx, _cy),
        width: _roomW * 0.78,
        height: h,
      );
      final rr = RRect.fromRectAndRadius(doorRect, const Radius.circular(9));
      final open = openRooms.contains(r);
      final flashing = flashRoom == r && flashT > 0;

      // Door interior.
      canvas.drawRRect(rr, Paint()..color = _kDoor);
      // Open-room gold wash + glow.
      if (open) {
        canvas.drawRRect(
          rr,
          Paint()..color = _kGold.withValues(alpha: 0.16),
        );
        canvas.drawRRect(
          rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = _kGold.withValues(alpha: 0.85)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }
      if (flashing) {
        canvas.drawRRect(
          rr,
          Paint()..color = _kBad.withValues(alpha: 0.25 * flashT),
        );
      }
      // Door edge.
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = open
              ? _kGold.withValues(alpha: 0.9)
              : (flashing
                  ? _kBad.withValues(alpha: 0.9)
                  : _kDoorEdge),
      );

      // Room number above the door.
      _label(
        canvas,
        '$r',
        Offset(cx, bandTop - 22),
        open ? _kGold : _kTextSub,
        size: 12,
        weight: FontWeight.w800,
      );

      // "OPEN" tag for a freed room.
      if (open) {
        _label(canvas, 'OPEN', Offset(cx, bandBot + 9), _kGold,
            size: 9, weight: FontWeight.w900, spacing: 1.0);
      }
    }

    // The ∞ continuation: a fade arrow + label past the last visible room.
    final fadeX = _plotR + 2;
    _label(canvas, '→ ∞', Offset(fadeX - 16, bandTop - 22), _kGold,
        size: 13, weight: FontWeight.w800);
  }

  void _paintGuests(Canvas canvas) {
    final r = _roomW * 0.27;
    for (final g in guests) {
      // Edge fade as a guest slides past the visible corridor (either end).
      double alpha = 1;
      if (g.pos > _kRooms + 0.2) {
        alpha = (_kRooms + 1.3 - g.pos).clamp(0.0, 1.0);
      } else if (g.pos < 0.8) {
        alpha = (g.pos - 0.0).clamp(0.0, 1.0);
      }
      if (alpha <= 0.02) continue;

      final cx = _roomX(g.pos);
      // Drop-in: new guests fall from above; residents idle-bob gently.
      final drop = g.appear < 1
          ? -(1 - g.appear) * (1 - g.appear) * _roomW * 0.9
          : (running ? math.sin(clock * 2 + g.origin) * 1.6 : 0);
      final cy = _cy + drop;
      alpha *= g.appear.clamp(0.0, 1.0);

      _paintPotato(canvas, Offset(cx, cy), r, g.isNew ? _kArrival : _kResident,
          alpha);
    }
  }

  void _paintPotato(Canvas canvas, Offset c, double r, Color tint, double a) {
    // Soft glow.
    canvas.drawCircle(
      c,
      r * 1.5,
      Paint()
        ..color = tint.withValues(alpha: 0.22 * a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Body (slightly ovoid — a potato).
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(1.0, 0.86);
    canvas.drawCircle(Offset.zero, r, Paint()..color = tint.withValues(alpha: a));
    canvas.drawCircle(
      Offset(0, -r * 0.18),
      r,
      Paint()..color = Colors.white.withValues(alpha: 0.10 * a),
    );
    canvas.restore();
    // Eyes.
    final eye = Paint()..color = Potatuhs.ink.withValues(alpha: 0.85 * a);
    canvas.drawCircle(Offset(c.dx - r * 0.32, c.dy - r * 0.1), r * 0.13, eye);
    canvas.drawCircle(Offset(c.dx + r * 0.32, c.dy - r * 0.1), r * 0.13, eye);
  }

  void _paintSparks(Canvas canvas) {
    for (final s in sparks) {
      final a = (s.life / s.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(
        s.pos,
        s.size * a,
        Paint()..color = s.color.withValues(alpha: s.color.a * a),
      );
    }
  }

  void _label(Canvas canvas, String text, Offset center, Color color,
      {double size = 11,
      FontWeight weight = FontWeight.w700,
      double spacing = 0}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: spacing,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _HotelPainter old) => true;
}

// ============================================================================
// Visual manual — legend carousel cards. _LegendArt mirrors the LIVE painter's
// component draws (doors, potato guests, rule cards) with the same palette
// constants, so the manual shows the EXACT corridor the player will meet.
// Static rendering only: painted once on the intro screen, never per-frame.
// ============================================================================

class _LegendArt {
  _LegendArt._();

  static void text(
    Canvas canvas,
    String s,
    Offset center,
    double size,
    Color color, {
    FontWeight weight = FontWeight.w700,
    double spacing = 0,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: spacing,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  /// A guest token — same ovoid body + sheen + eyes as the live painter.
  static void potato(Canvas canvas, Offset c, double r, Color tint,
      {double a = 1}) {
    canvas.drawCircle(
      c,
      r * 1.5,
      Paint()
        ..color = tint.withValues(alpha: 0.22 * a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(1.0, 0.86);
    canvas.drawCircle(
        Offset.zero, r, Paint()..color = tint.withValues(alpha: a));
    canvas.drawCircle(
      Offset(0, -r * 0.18),
      r,
      Paint()..color = Colors.white.withValues(alpha: 0.10 * a),
    );
    canvas.restore();
    final eye = Paint()..color = Potatuhs.ink.withValues(alpha: 0.85 * a);
    canvas.drawCircle(Offset(c.dx - r * 0.32, c.dy - r * 0.1), r * 0.13, eye);
    canvas.drawCircle(Offset(c.dx + r * 0.32, c.dy - r * 0.1), r * 0.13, eye);
  }

  /// The corridor band: facade slab, numbered doors, gold OPEN rooms, red
  /// flash room and the `→ ∞` continuation. Returns each door's rect so
  /// callers can place guests inside.
  static List<Rect> corridor(
    Canvas canvas,
    Size size,
    double cy, {
    int rooms = 5,
    Set<int> open = const {},
    int? flash,
  }) {
    final pad = size.width * 0.07;
    final plotL = pad;
    final plotR = size.width - pad;
    final roomW = (plotR - plotL) / rooms;
    final doorH = (roomW * 1.15).clamp(28.0, size.height * 0.40);
    final rects = <Rect>[];

    // Facade slab spanning the rooms.
    final slab = Rect.fromLTRB(
        plotL - 4, cy - doorH / 2 - 10, plotR + 4, cy + doorH / 2 + 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(slab, const Radius.circular(14)),
      Paint()..color = _kFacade.withValues(alpha: 0.55),
    );

    for (int r = 1; r <= rooms; r++) {
      final cx = plotL + (r - 0.5) * roomW;
      final doorRect = Rect.fromCenter(
          center: Offset(cx, cy), width: roomW * 0.78, height: doorH);
      rects.add(doorRect);
      final rr = RRect.fromRectAndRadius(doorRect, const Radius.circular(9));
      final isOpen = open.contains(r);
      final isFlash = flash == r;

      canvas.drawRRect(rr, Paint()..color = _kDoor);
      if (isOpen) {
        canvas.drawRRect(rr, Paint()..color = _kGold.withValues(alpha: 0.16));
        canvas.drawRRect(
          rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = _kGold.withValues(alpha: 0.85)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }
      if (isFlash) {
        canvas.drawRRect(rr, Paint()..color = _kBad.withValues(alpha: 0.25));
      }
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = isOpen
              ? _kGold.withValues(alpha: 0.9)
              : (isFlash ? _kBad.withValues(alpha: 0.9) : _kDoorEdge),
      );

      text(canvas, '$r', Offset(cx, doorRect.top - 12), 10,
          isOpen ? _kGold : _kTextSub,
          weight: FontWeight.w800);
      if (isOpen) {
        text(canvas, 'OPEN', Offset(cx, doorRect.bottom + 9), 8, _kGold,
            weight: FontWeight.w900, spacing: 1.0);
      }
      if (isFlash) {
        text(canvas, 'FULL!', Offset(cx, doorRect.bottom + 9), 8, _kBad,
            weight: FontWeight.w900, spacing: 1.0);
      }
    }

    text(canvas, '→ ∞', Offset(plotR - 10, slab.top - 12), 11, _kGold,
        weight: FontWeight.w800);
    return rects;
  }

  /// One rule option card — same shape/palette as the live [_optionCard].
  static void ruleCard(
    Canvas canvas,
    Rect r,
    String label,
    String sub, {
    Color? accent,
  }) {
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(12));
    canvas.drawRRect(rr, Paint()..color = _kCardBg);
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = accent ?? _kCardBorder,
    );
    if (accent != null) {
      canvas.drawRRect(rr, Paint()..color = accent.withValues(alpha: 0.10));
    }
    final hasSub = sub.isNotEmpty && r.height >= 34;
    final labelY = hasSub ? r.top + r.height * 0.36 : r.center.dy;
    text(canvas, label, Offset(r.center.dx, labelY), 12.5,
        accent ?? _kTextPrimary,
        weight: FontWeight.w900);
    if (hasSub) {
      text(canvas, sub, Offset(r.center.dx, r.top + r.height * 0.72), 9,
          _kTextSub);
    }
  }

  /// The tap cue: a gold fingertip ring, as in other games' manuals.
  static void tapCue(Canvas canvas, Offset c) {
    canvas.drawCircle(
      c,
      13,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _kGold,
    );
    canvas.drawCircle(c, 5, Paint()..color = _kGold.withValues(alpha: 0.85));
  }

  static bool degenerate(Size size) =>
      size.width <= 0 ||
      size.height <= 0 ||
      !size.width.isFinite ||
      !size.height.isFinite;
}

// ── Frame 1: the setup — an infinite FULL hotel, and an arrival ─────────────

void _legendHotel(Canvas canvas, Size size) {
  if (_LegendArt.degenerate(size)) return;
  final doors = _LegendArt.corridor(canvas, size, size.height * 0.36);
  final r = doors.first.width * 0.34;
  // Every room occupied by a resident — the hotel is full.
  for (final d in doors) {
    _LegendArt.potato(canvas, d.center, r, _kResident);
  }
  // A newly-arrived guest waits below, with the announcement chip.
  final ac = Offset(size.width * 0.5, size.height * 0.78);
  _LegendArt.potato(canvas, ac, r * 1.1, _kArrival);
  _LegendArt.text(canvas, '1 NEW GUEST · HOTEL FULL',
      Offset(size.width * 0.5, size.height * 0.94), 10, _kArrival,
      weight: FontWeight.w900, spacing: 0.6);
  // An up-arrow from the arrival toward the corridor.
  final p = Paint()
    ..color = _kArrival
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final ax = size.width * 0.5;
  final ay0 = size.height * 0.68, ay1 = size.height * 0.56;
  canvas.drawLine(Offset(ax, ay0), Offset(ax, ay1), p);
  canvas.drawLine(Offset(ax - 6, ay1 + 7), Offset(ax, ay1), p);
  canvas.drawLine(Offset(ax + 6, ay1 + 7), Offset(ax, ay1), p);
}

// ── Frame 2: the action — tap the rule; n → n+1 opens room 1 ────────────────

void _legendRule(Canvas canvas, Size size) {
  if (_LegendArt.degenerate(size)) return;
  final doors = _LegendArt.corridor(canvas, size, size.height * 0.30,
      open: const {1});
  final r = doors.first.width * 0.34;
  // Residents shifted up one room; the arrival drops into the freed room 1.
  for (int i = 1; i < doors.length; i++) {
    _LegendArt.potato(canvas, doors[i].center, r, _kResident);
  }
  _LegendArt.potato(canvas, doors.first.center, r, _kArrival);
  // The correct rule card, with the tap cue on it.
  final card = Rect.fromCenter(
    center: Offset(size.width * 0.5, size.height * 0.78),
    width: size.width * 0.72,
    height: size.height * 0.20,
  );
  _LegendArt.ruleCard(canvas, card, 'n → n+1', 'Every guest moves up one room',
      accent: _kGood);
  _LegendArt.tapCue(
      canvas, Offset(card.right - card.width * 0.14, card.center.dy));
}

// ── Frame 3: the danger — a wrong rule genuinely fails ──────────────────────

void _legendWrong(Canvas canvas, Size size) {
  if (_LegendArt.degenerate(size)) return;
  final doors = _LegendArt.corridor(canvas, size, size.height * 0.30,
      flash: 1);
  final r = doors.first.width * 0.30;
  // "All → room 1" piles everyone into one room — an illegal double-booking.
  final c1 = doors.first.center;
  _LegendArt.potato(canvas, c1.translate(-r * 0.7, r * 0.4), r, _kResident);
  _LegendArt.potato(canvas, c1.translate(r * 0.7, r * 0.3), r, _kResident);
  _LegendArt.potato(canvas, c1.translate(0, -r * 0.6), r, _kResident);
  // The failing rule card, struck through in red.
  final card = Rect.fromCenter(
    center: Offset(size.width * 0.5, size.height * 0.78),
    width: size.width * 0.72,
    height: size.height * 0.20,
  );
  _LegendArt.ruleCard(canvas, card, 'All → room 1', 'Send everyone to room 1',
      accent: _kBad);
  final x = Paint()
    ..color = _kBad
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  final xc = Offset(card.left + card.width * 0.12, card.center.dy);
  canvas.drawLine(xc.translate(-6, -6), xc.translate(6, 6), x);
  canvas.drawLine(xc.translate(6, -6), xc.translate(-6, 6), x);
  _LegendArt.text(canvas, '0 PTS · STREAK RESETS',
      Offset(size.width * 0.5, size.height * 0.94), 9.5, _kBad,
      weight: FontWeight.w900, spacing: 0.8);
}

// ── Frame 4: the escalation — ℵ₀ buses and four rules to choose from ────────

void _legendBuses(Canvas canvas, Size size) {
  if (_LegendArt.degenerate(size)) return;
  // The late-game arrival banner chip.
  final chip = Rect.fromCenter(
    center: Offset(size.width * 0.5, size.height * 0.12),
    width: size.width * 0.72,
    height: size.height * 0.14,
  );
  final chipRR = RRect.fromRectAndRadius(chip, const Radius.circular(12));
  canvas.drawRRect(
      chipRR, Paint()..color = _kArrival.withValues(alpha: 0.16));
  canvas.drawRRect(
    chipRR,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _kArrival.withValues(alpha: 0.6),
  );
  _LegendArt.text(canvas, 'ℵ₀ BUSES — EACH ℵ₀', chip.center, 12, _kArrival,
      weight: FontWeight.w900, spacing: 0.4);
  // Four compact rule cards — only ONE fits this arrival.
  const labels = ['Prime powers', 'n → 2n', 'n → n+1', 'All → room 1'];
  for (int i = 0; i < 4; i++) {
    final card = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * (0.32 + i * 0.185)),
      width: size.width * 0.72,
      height: size.height * 0.135,
    );
    _LegendArt.ruleCard(canvas, card, labels[i], '',
        accent: i == 0 ? _kGold : null);
    if (i == 0) {
      _LegendArt.tapCue(
          canvas, Offset(card.right - card.width * 0.12, card.center.dy));
    }
  }
}

/// The visual manual for Hilbert's Hotel — wired into the registry spec.
final List<LegendFrame> hilbertsHotelLegendFrames = [
  const LegendFrame(
      caption: 'The ∞ hotel is FULL — yet a new guest arrives',
      paint: _legendHotel),
  const LegendFrame(
      caption: 'Tap the rule that makes room — n → n+1 opens room 1',
      paint: _legendRule),
  const LegendFrame(
      caption: 'Wrong rules truly fail: 0 points, streak resets',
      paint: _legendWrong),
  const LegendFrame(
      caption: 'Later: ℵ₀ buses arrive and 4 rules to pick from',
      paint: _legendBuses),
];
