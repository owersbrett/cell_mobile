import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ============================================================================
// HILBERT'S HOTEL v2 — MAKE ROOM (a swipe game about countable infinity).
//
// UX-pass rebuild of `hilberts_hotel`. The original was a 3-fixed-answer
// reading quiz: you parsed a banner ("ℵ₀ BUSES — EACH ℵ₀") plus three symbolic
// rule cards and TAPPED the right label, then sat through a 2.2s feedback hold.
//
// v2 makes the corridor the verb. You ENACT the bijection by SWIPING the
// guests — and you watch them slide, rooms open, and newcomers pour in:
//   • SWIPE →  (right)  shift  n → n+1   — opens rooms on the left   (one guest)
//   • SWIPE ↑  (up)     double n → 2n     — every ODD room opens      (a bus)
//   • SWIPE ↓  (down)   prime powers       — residents pack the powers
//                                            of two; the rest flood open (∞ buses)
//   • SWIPE ←  (left)   shift down n → n−1 — ILLEGAL: evicts guest 1  (taught, penalised)
// A pulsing chevron on the corridor shows the legal direction for the current
// arrival, so the read is glanceable (no set-theory literacy required). There
// is NO blocking feedback gate — the slide animates, the score ticks live, and
// the next arrival fires immediately, so the round can accelerate into a
// flood-of-buses climax in the final seconds.
//
// The paradox is preserved: the corridor visibly RESETS TO FULL before every
// arrival, yet your swipe always makes room — a full ℵ₀ hotel still fits more.
// The three real bijections and the honest, physically-failing distractor
// (shift-down evicts guest 1) are all kept; here you DO them instead of reading
// a label.
//
// Self-contained module. Imports only the framework session + theme tokens.
// One Ticker drives one CustomPainter; the host owns the clock, the countdown,
// the score HUD and the results screen. This widget renders only the play area
// and never calls endEarly (no fail state). See GAME.md.
// ============================================================================

const String _kFont = Potatuhs.bodyFont;

// -- Palette (on Potatuhs ink) -----------------------------------------------
const Color _kBg = Potatuhs.inkDeep;
const Color _kFacade = Potatuhs.inkPanel;
const Color _kDoor = Color(0xFF1E1B18);
const Color _kDoorEdge = Color(0xFF3A352F);
const Color _kGold = Potatuhs.gold; // marquee / open-room glow
const Color _kResident = Potatuhs.sienna; // a guest already in residence
const Color _kArrival = Color(0xFF6FB7D6); // a newly-arrived guest (cool blue)
const Color _kGood = Color(0xFF69F0AE);
const Color _kBad = Color(0xFFFF5252);
const Color _kTextPrimary = Potatuhs.textPrimary;
const Color _kTextSub = Potatuhs.textSecondary;

// -- Layout ------------------------------------------------------------------
// The host stacks its own score/timer HUD ABOVE this widget, so the play area
// is already below the score. 8 rooms keep the potato guests readable at phone
// widths (12 made them tiny dots and crowded the `→ ∞` label); the corridor
// still fades into ∞, so the paradox reads. Painter uses the same constants.
const int _kRooms = 8; // visible rooms (the corridor continues to ∞)
const double _kBottomPanel = 78; // reserved for the coach / legend strip
// Top reserve: the arrival banner PLUS the persistent result ledger — the
// "what just happened" line lives above the hotel and stays until the next
// move replaces it (Brett 2026-07-17).
const double _kBannerTop = 96;

// -- Timing & scoring --------------------------------------------------------
const double _kShiftRate = 7.5; // how fast guests slide to their new rooms
const double _kDropDur = 0.42; // arrival drop-in animation length
const double _kSwipeMin = 26.0; // px a swipe must travel to register
const int _kStreakStep = 4; // legal moves per +1× multiplier
const int _kMaxMult = 4; // multiplier cap (no runaway leader)
const double _kClimaxFrom = 0.80; // progress at which the flood begins

// ============================================================================
// Arrivals, directions, moves (the educational core, as data)
// ============================================================================

enum _Demand { guest, bus, buses }

enum _Dir { right, up, down, left }

extension _DemandInfo on _Demand {
  /// The legal, canonical swipe for this arrival.
  _Dir get canonical {
    switch (this) {
      case _Demand.guest:
        return _Dir.right;
      case _Demand.bus:
        return _Dir.up;
      case _Demand.buses:
        return _Dir.down;
    }
  }

  /// Points per guest actually checked in. Bigger batches are worth less per
  /// seat so a perfect bus and a perfect guest stay score-comparable.
  int get perSeat {
    switch (this) {
      case _Demand.guest:
        return 44;
      case _Demand.bus:
        return 22;
      case _Demand.buses:
        return 18;
    }
  }

  IconData get icon {
    switch (this) {
      case _Demand.guest:
        return Icons.person_rounded;
      case _Demand.bus:
        return Icons.directions_bus_rounded;
      case _Demand.buses:
        return Icons.commute_rounded;
    }
  }

  String get headline {
    switch (this) {
      case _Demand.guest:
        return '1 GUEST';
      case _Demand.bus:
        return 'A BUS · ℵ₀';
      case _Demand.buses:
        return 'ℵ₀ BUSES';
    }
  }

  /// The verb hint shown beside the chevron (a nudge, not a rule to parse).
  String get verb {
    switch (this) {
      case _Demand.guest:
        return 'SWIPE → SHIFT UP';
      case _Demand.bus:
        return 'SWIPE ↑ DOUBLE';
      case _Demand.buses:
        return 'SWIPE ↓ PRIMES';
    }
  }
}

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
  _Spark(this.pos, this.vel, this.life, this.size, this.color) : maxLife = life;
}

// ============================================================================
// Widget
// ============================================================================

class HilbertsHotelV2Game extends StatefulWidget {
  final MiniGameSession session;
  const HilbertsHotelV2Game({super.key, required this.session});

  @override
  State<HilbertsHotelV2Game> createState() => _HilbertsHotelV2GameState();
}

class _HilbertsHotelV2GameState extends State<HilbertsHotelV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  Duration _lastElapsed = Duration.zero;
  double _clock = 0;
  bool _started = false;

  // Current arrival.
  _Demand _demand = _Demand.guest;
  _Demand? _lastDemand;
  bool _locked = false; // a move is resolving; settle timer running
  double _settleT = 0;

  // Corridor state.
  final List<_Guest> _guests = [];
  Set<int> _openRooms = const {};
  int? _flashRoom;
  double _flashT = 0;

  // Live drag preview (tactile tug toward the finger; commits on release).
  bool _panActive = false;
  double _panDx = 0;
  double _panDy = 0;

  // The persistent result ledger (above the hotel): what the last swipe DID,
  // descriptively. Never fades — it holds until the next move replaces it,
  // so a player can always read back what just happened. Never gates input.
  String _result = '';
  Color _resultColor = _kTextSub;

  // Scoring.
  int _streak = 0;

  final List<_Spark> _sparks = [];
  Size _fieldSize = Size.zero;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fillHotel();
    // ATTRACT autopilot: the host may drive us hands-free (~every tick). One
    // move banks a scored check-in, so pace it out so the slide can breathe.
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

  // ── ATTRACT autopilot ──────────────────────────────────────────────────────
  /// One hands-free move per host call. Plays the hotel *correctly*: it enacts
  /// the exact bijection the current arrival demands by swiping in the arrival's
  /// canonical direction (guest → right/shift, bus → up/double, buses →
  /// down/primes) through the game's own move handler. Never the illegal
  /// left-eviction. It waits out the brief settle between arrivals and lets the
  /// host own the clock, banking real check-ins until the round ends.
  void _autoStep() {
    if (!widget.session.isRunning || !_started) return;
    if (_locked) return; // a move is resolving; the next arrival is imminent
    // The canonical swipe for this arrival; shiftBy 1 (only the guest/right
    // case reads it, where a single shift opens exactly the one room needed).
    _resolveMove(_demand.canonical, 1);
  }

  // ── Corridor helpers ───────────────────────────────────────────────────────

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
    _sparked.clear();
  }

  double _progress() {
    final dur = widget.session.spec.durationSeconds;
    if (dur <= 0) return 0;
    final rem = widget.session.remaining.inMilliseconds / 1000.0;
    return (1 - rem / dur).clamp(0.0, 1.0);
  }

  bool get _climax => _progress() >= _kClimaxFrom;

  // ── Round flow ─────────────────────────────────────────────────────────────

  void _startGame() {
    _started = true;
    _streak = 0;
    _newDemand();
  }

  _Demand _pickDemand() {
    final p = _progress();
    if (_climax) return _Demand.buses; // the flood
    final pool = <_Demand>[_Demand.guest];
    if (p >= 0.22) pool.add(_Demand.bus);
    if (p >= 0.50) pool.add(_Demand.buses);
    if (p >= 0.65) pool.add(_Demand.bus); // bias toward the harder mids
    _Demand d;
    var guard = 0;
    do {
      d = pool[_rng.nextInt(pool.length)];
      guard++;
    } while (d == _lastDemand && pool.length > 1 && guard < 6);
    _lastDemand = d;
    return d;
  }

  void _newDemand() {
    _fillHotel();
    _demand = _pickDemand();
    _locked = false;
    _settleT = 0;
    _panDx = 0;
    _panDy = 0;
  }

  /// How many seats a given move makes available, and where the rooms open.
  /// Returns the set of opened visible rooms; sets each resident's target.
  Set<int> _applyMove(_Dir dir, {int shiftBy = 1}) {
    final opened = <int>{};
    switch (dir) {
      case _Dir.right: // n → n+k : rooms 1..k open
        final k = shiftBy.clamp(1, _kRooms - 1);
        for (final g in _guests) {
          g.target = (g.origin + k).toDouble();
        }
        for (int r = 1; r <= k; r++) {
          opened.add(r);
        }
        break;
      case _Dir.up: // n → 2n : every odd room opens
        for (final g in _guests) {
          g.target = (2 * g.origin).toDouble();
        }
        for (int r = 1; r <= _kRooms; r += 2) {
          opened.add(r);
        }
        break;
      case _Dir.down: // prime powers : residents pack {1,2,4,8…}, the rest flood
        final pow2 = <int>{};
        var v = 1;
        while (v <= _kRooms) {
          pow2.add(v);
          v *= 2;
        }
        final sorted = [..._guests]..sort((a, b) => a.origin.compareTo(b.origin));
        final slots = pow2.toList()..sort();
        for (int i = 0; i < sorted.length; i++) {
          // First few residents land on the power-of-two rooms; the rest slide
          // off to their unique high prime-power rooms (off-screen → ∞).
          sorted[i].target =
              (i < slots.length ? slots[i] : _kRooms + 3 + i).toDouble();
        }
        for (int r = 1; r <= _kRooms; r++) {
          if (!pow2.contains(r)) opened.add(r);
        }
        break;
      case _Dir.left: // n → n-1 : ILLEGAL — guest 1 evicted to room 0
        for (final g in _guests) {
          g.target = (g.origin - 1).toDouble();
        }
        break;
    }
    return opened;
  }

  // ── Input ──────────────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    if (!widget.session.isRunning || _locked) return;
    _panActive = true;
    _panDx = 0;
    _panDy = 0;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_panActive) return;
    _panDx += d.delta.dx;
    _panDy += d.delta.dy;
  }

  void _onPanEnd(DragEndDetails d) {
    if (!_panActive) return;
    _panActive = false;
    final dx = _panDx, dy = _panDy;
    _panDx = 0;
    _panDy = 0;
    if (!widget.session.isRunning || _locked) return;
    if (dx.abs() < _kSwipeMin && dy.abs() < _kSwipeMin) return; // a tap, ignore

    final _Dir dir;
    if (dx.abs() >= dy.abs()) {
      dir = dx >= 0 ? _Dir.right : _Dir.left;
    } else {
      dir = dy <= 0 ? _Dir.up : _Dir.down;
    }
    final roomW = _fieldSize.width <= 0 ? 1.0 : _fieldSize.width / _kRooms;
    final shiftBy = (dx / roomW).abs().round().clamp(1, 6);
    _resolveMove(dir, shiftBy);
  }

  void _resolveMove(_Dir dir, int shiftBy) {
    // The illegal eviction — kept as the honest, physically-failing distractor.
    if (dir == _Dir.left) {
      _applyMove(_Dir.left);
      _flashRoom = 1;
      _flashT = 1;
      _streak = 0;
      _setResult(
          '← SHIFTED DOWN n → n−1 — GUEST 1 EVICTED: room 0 does not exist',
          _kBad);
      _beginSettle();
      return;
    }

    final opened = _applyMove(dir, shiftBy: shiftBy);
    final need = _demandNeed(_demand);
    final seats = math.min(opened.length, need);

    // Drop the arrivals into the freed rooms (cool-blue newcomers).
    final openList = opened.toList()..sort();
    for (int i = 0; i < seats; i++) {
      final r = openList[i];
      _guests.add(_Guest(
        origin: r,
        pos: r.toDouble(),
        target: r.toDouble(),
        appear: 0,
        isNew: true,
      ));
    }
    _openRooms = openList.take(seats).toSet();

    // Score: per-seat × matched-read bonus × streak multiplier (capped).
    final matched = dir == _demand.canonical;
    _streak++;
    final mult = (1 + _streak ~/ _kStreakStep).clamp(1, _kMaxMult);
    final bonus = matched ? 1.25 : 1.0;
    final gain = (seats * _demand.perSeat * bonus).round() * mult;
    if (gain > 0) {
      widget.session.addScore(gain);
      widget.session.noteStreak(_streak);
    }

    // The persistent ledger line — descriptive, never a read-gate: what the
    // swipe DID (the bijection), what opened, who got in.
    final rule = _ruleText(dir, shiftBy);
    if (matched) {
      _setResult('$rule — ${_winLine(_demand, seats)}', _kGood);
    } else if (seats < need) {
      _setResult('$rule — only $seats of $need seated · ${_underLine(_demand)}',
          _kArrival);
    } else {
      _setResult('$rule — $seats seated · more rooms freed than needed',
          _kArrival);
    }

    _beginSettle();
  }

  /// What the swipe physically did, as the bijection it enacted.
  String _ruleText(_Dir dir, int shiftBy) {
    switch (dir) {
      case _Dir.right:
        final k = shiftBy.clamp(1, _kRooms - 1);
        return k == 1
            ? '→ SHIFTED n → n+1'
            : '→ SHIFTED n → n+$k';
      case _Dir.up:
        return '↑ DOUBLED n → 2n';
      case _Dir.down:
        return '↓ PRIME POWERS n → 2ⁿ';
      case _Dir.left:
        return '← SHIFTED DOWN n → n−1';
    }
  }

  int _demandNeed(_Demand d) {
    switch (d) {
      case _Demand.guest:
        return 1;
      case _Demand.bus:
        return (_kRooms / 2).floor(); // a screenful of the bus (the odds)
      case _Demand.buses:
        return _kRooms - 4; // a screenful of the many-bus flood
    }
  }

  String _winLine(_Demand d, int seats) {
    switch (d) {
      case _Demand.guest:
        return 'room 1 opened, the guest is in. A full hotel still had room';
      case _Demand.bus:
        return 'every ODD room opened, the whole bus is in';
      case _Demand.buses:
        return 'residents packed the powers of 2 — every bus got unique rooms';
    }
  }

  String _underLine(_Demand d) {
    switch (d) {
      case _Demand.guest:
        return 'one shift is enough for one guest';
      case _Demand.bus:
        return 'a bus needs DOUBLE (↑)';
      case _Demand.buses:
        return 'ℵ₀ buses need PRIMES (↓)';
    }
  }

  void _setResult(String t, Color c) {
    _result = t;
    _resultColor = c;
  }

  void _beginSettle() {
    _locked = true;
    // Short anim settle (NOT a read-gate): scales down into the climax.
    _settleT = _climax ? 0.24 : (0.40 - 0.12 * _progress());
  }

  // ── Game loop ────────────────────────────────────────────────────────────────

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    _clock += dt;

    final running = widget.session.isRunning;
    if (running && !_started) _startGame();

    // Slide guests toward their targets; advance drop-ins; fade flash + toast.
    final k = (dt * _kShiftRate).clamp(0.0, 1.0);
    for (final g in _guests) {
      g.pos += (g.target - g.pos) * k;
      if (g.appear < 1) {
        g.appear = (g.appear + dt / _kDropDur).clamp(0.0, 1.0);
        if (g.appear > 0.45) _maybeSpark(g);
      }
    }
    if (_flashT > 0) _flashT = (_flashT - dt / 0.9).clamp(0.0, 1.0);

    if (running && _locked) {
      _settleT -= dt;
      if (_settleT <= 0) _newDemand();
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
    for (var i = 0; i < 9; i++) {
      final a = _rng.nextDouble() * math.pi * 2;
      final sp = 50 + _rng.nextDouble() * 120;
      _sparks.add(_Spark(
        at,
        Offset(math.cos(a), math.sin(a)) * sp,
        0.32 + _rng.nextDouble() * 0.4,
        1.4 + _rng.nextDouble() * 2.4,
        _kGood.withValues(alpha: 0.7 + _rng.nextDouble() * 0.3),
      ));
    }
  }

  // Mirror of the painter's room geometry, so sparks land on the right room.
  Offset _roomScreenCenter(double room) {
    const pad = 14.0;
    const plotL = pad;
    final plotR = _fieldSize.width - pad;
    final roomW = (plotR - plotL) / _kRooms;
    const top = _kBannerTop + 6;
    final bottom = _fieldSize.height - _kBottomPanel - 12;
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
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
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
                    running: widget.session.isRunning && _started,
                    hintDir: (_started && !_locked && !_panActive)
                        ? _demand.canonical
                        : null,
                    tugDx: _panActive ? _panDx : 0,
                    tugDy: _panActive ? _panDy : 0,
                    result: _result,
                    resultColor: _resultColor,
                    climax: _climax,
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
              // Coach / streak strip (bottom).
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: SizedBox(height: _kBottomPanel, child: _buildCoach()),
                ),
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
                shadows: [
                  Shadow(color: _kGold.withValues(alpha: 0.6), blurRadius: 12)
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Swipe the guests — a full ∞ hotel always fits more',
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
            child: Icon(_demand.icon, color: _kArrival, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_demand.headline}  ·  HOTEL FULL',
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
                  _demand.verb,
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: _kGold.withValues(alpha: 0.95),
                  ),
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
    final mult = (1 + _streak ~/ _kStreakStep).clamp(1, _kMaxMult);
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

  Widget _buildCoach() {
    final running = widget.session.isRunning && _started;
    // The host HUD already shows the live SCORE up top — this strip stays a
    // control legend + one-line objective, never a second (contradicting)
    // number. Scoring is legible: each guest you legally check in adds points,
    // and matching the arrival's canonical swipe pays a bonus.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot('→', 'shift'),
              _legendDot('↑', 'double'),
              _legendDot('↓', 'primes'),
              _legendDot('←', 'evict', danger: true),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            running
                ? 'SWIPE THE GOLD ARROW — SCORE PER GUEST CHECKED IN'
                : 'SWIPE TO ENACT THE BIJECTION',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: _kTextSub.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(String glyph, String label, {bool danger = false}) {
    final c = danger ? _kBad : _kGold;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            glyph,
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: c.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: _kTextSub,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Painter — the corridor of rooms, residents/arrivals, the swipe chevron, the
// ∞ fade, sparks, and the inline toast. All continuous motion is here
// (one Ticker → setState → repaint).
// ============================================================================

class _HotelPainter extends CustomPainter {
  final double clock;
  final List<_Guest> guests;
  final Set<int> openRooms;
  final int? flashRoom;
  final double flashT;
  final List<_Spark> sparks;
  final bool running;
  final _Dir? hintDir;
  final double tugDx;
  final double tugDy;
  final String result;
  final Color resultColor;
  final bool climax;

  _HotelPainter({
    required this.clock,
    required this.guests,
    required this.openRooms,
    required this.flashRoom,
    required this.flashT,
    required this.sparks,
    required this.running,
    required this.hintDir,
    required this.tugDx,
    required this.tugDy,
    required this.result,
    required this.resultColor,
    required this.climax,
  });

  late double _plotL;
  late double _plotR;
  late double _roomW;
  late double _top;
  late double _bottom;
  double _tx = 0;
  double _ty = 0;

  double _roomX(double room) => _plotL + (room - 0.5) * _roomW + _tx;
  double get _cy => (_top + _bottom) / 2;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);

    const pad = 14.0;
    _plotL = pad;
    _plotR = size.width - pad;
    _roomW = (_plotR - _plotL) / _kRooms;
    _top = _kBannerTop + 6;
    _bottom = size.height - _kBottomPanel - 12;
    if (_bottom - _top <= 10 || _roomW <= 3) return;

    // Tactile tug toward the finger (clamped), so the corridor follows a drag.
    _tx = tugDx.clamp(-_roomW * 0.7, _roomW * 0.7);
    _ty = tugDy.clamp(-_roomW * 0.5, _roomW * 0.5);

    _paintAmbient(canvas, size);
    _paintCorridor(canvas);
    _paintGuests(canvas);
    if (running && hintDir != null) _paintHint(canvas, size);
    _paintSparks(canvas);
    if (result.isNotEmpty) _paintResult(canvas, size);
  }

  void _paintAmbient(Canvas canvas, Size size) {
    final glow = climax ? 0.12 : 0.07;
    canvas.drawCircle(
      Offset(size.width * 0.5, _top - 4),
      size.width * 0.6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _kGold.withValues(alpha: glow),
            _kGold.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.5, _top - 4),
          radius: size.width * 0.6,
        )),
    );
  }

  void _paintCorridor(Canvas canvas) {
    final bandTop = _cy - _roomW * 0.62 + _ty;
    final bandBot = _cy + _roomW * 0.62 + _ty;
    final h = bandBot - bandTop;

    final slab =
        Rect.fromLTRB(_plotL - 4, bandTop - 14, _plotR + 4, bandBot + 14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(slab, const Radius.circular(14)),
      Paint()..color = _kFacade.withValues(alpha: 0.55),
    );

    for (int r = 1; r <= _kRooms; r++) {
      final cx = _roomX(r.toDouble());
      final doorRect = Rect.fromCenter(
        center: Offset(cx, _cy + _ty),
        width: _roomW * 0.78,
        height: h,
      );
      final rr = RRect.fromRectAndRadius(doorRect, const Radius.circular(8));
      final open = openRooms.contains(r);
      final flashing = flashRoom == r && flashT > 0;

      canvas.drawRRect(rr, Paint()..color = _kDoor);
      if (open) {
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
      if (flashing) {
        canvas.drawRRect(
          rr,
          Paint()..color = _kBad.withValues(alpha: 0.28 * flashT),
        );
      }
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = open
              ? _kGold.withValues(alpha: 0.9)
              : (flashing ? _kBad.withValues(alpha: 0.9) : _kDoorEdge),
      );

      _label(
        canvas,
        '$r',
        Offset(cx, bandTop - 16),
        open ? _kGold : _kTextSub,
        size: 11,
        weight: FontWeight.w800,
      );
    }

    // The ∞ continuation past the last visible room.
    _label(canvas, '→ ∞', Offset(_plotR - 8, bandTop - 16), _kGold,
        size: 13, weight: FontWeight.w800);
  }

  void _paintGuests(Canvas canvas) {
    final rad = _roomW * 0.27;
    for (final g in guests) {
      double alpha = 1;
      if (g.pos > _kRooms + 0.2) {
        alpha = (_kRooms + 1.6 - g.pos).clamp(0.0, 1.0);
      } else if (g.pos < 0.8) {
        alpha = (g.pos - 0.0).clamp(0.0, 1.0);
      }
      if (alpha <= 0.02) continue;

      final cx = _roomX(g.pos);
      final drop = g.appear < 1
          ? -(1 - g.appear) * (1 - g.appear) * _roomW * 0.9
          : (running ? math.sin(clock * 2 + g.origin) * 1.6 : 0);
      final cy = _cy + _ty + drop;
      alpha *= g.appear.clamp(0.0, 1.0);

      _paintPotato(
          canvas, Offset(cx, cy), rad, g.isNew ? _kArrival : _kResident, alpha);
    }
  }

  void _paintPotato(Canvas canvas, Offset c, double r, Color tint, double a) {
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

  /// The pulsing directional chevron — the glanceable "swipe this way" cue.
  /// Sits BELOW the room band (Brett 2026-07-17): over the corridor it hid
  /// behind the guests while playing; down here it owns clear ground between
  /// the rooms and the coach strip.
  void _paintHint(Canvas canvas, Size size) {
    final pulse = 0.5 + 0.5 * math.sin(clock * 4);
    final a = 0.45 + 0.45 * pulse;
    final bandBot = _cy + _roomW * 0.62 + _ty + 14;
    final lane = (_bottom - bandBot).clamp(0.0, double.infinity);
    if (lane < 18) return; // no clear ground on a tiny viewport
    final reach = math.min(_roomW * (0.55 + 0.25 * pulse), lane * 0.42);
    final center = Offset(size.width * 0.5, (bandBot + _bottom) / 2);

    Offset dir;
    switch (hintDir!) {
      case _Dir.right:
        dir = const Offset(1, 0);
        break;
      case _Dir.up:
        dir = const Offset(0, -1);
        break;
      case _Dir.down:
        dir = const Offset(0, 1);
        break;
      case _Dir.left:
        dir = const Offset(-1, 0);
        break;
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _kGold.withValues(alpha: a);

    // Three stacked chevrons marching in the swipe direction.
    final perp = Offset(-dir.dy, dir.dx);
    for (int i = 0; i < 3; i++) {
      final base = center + dir * (reach * 0.4 + i * reach * 0.5);
      final wing = reach * 0.34;
      final tip = base + dir * (wing * 0.7);
      final p1 = base - perp * wing - dir * (wing * 0.2);
      final p2 = base + perp * wing - dir * (wing * 0.2);
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(p2.dx, p2.dy);
      canvas.drawPath(
          path,
          paint
            ..color = _kGold.withValues(alpha: a * (1 - i * 0.22)));
    }
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

  /// The persistent result ledger — ABOVE the hotel, in the reserve between
  /// the arrival banner and the corridor. What the last swipe did, in full;
  /// it holds until the next move replaces it (Brett 2026-07-17).
  void _paintResult(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: result,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: resultColor,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: size.width - 44);
    // Centered in the strip between the banner (~52px) and the corridor top.
    const y = (_kBannerTop + 52) / 2 + 8;
    final plate = Rect.fromCenter(
      center: Offset(size.width / 2, y),
      width: tp.width + 24,
      height: tp.height + 12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(plate, const Radius.circular(10)),
      Paint()..color = _kBg.withValues(alpha: 0.78),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(plate, const Radius.circular(10)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = resultColor.withValues(alpha: 0.55),
    );
    tp.paint(canvas, plate.center - Offset(tp.width / 2, tp.height / 2));
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
    )..layout(maxWidth: 320);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _HotelPainter old) => true;
}

// ============================================================================
// Visual manual — the legend carousel cards, each drawn with the REAL
// components the player meets (numbered doors, sienna residents / cool-blue
// arrivals, the pulsing swipe chevron) in the game's own palette. Cheap and
// self-contained: they render once, statically, on the intro screen.
// ============================================================================

/// One numbered door, exactly as the corridor draws it: gold glow when [open],
/// red flash when [danger], otherwise the dim closed door + edge.
void _legendDoor(Canvas canvas, Rect r, {bool open = false, bool danger = false}) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(6));
  canvas.drawRRect(rr, Paint()..color = _kDoor);
  if (open) {
    canvas.drawRRect(rr, Paint()..color = _kGold.withValues(alpha: 0.16));
  }
  if (danger) {
    canvas.drawRRect(rr, Paint()..color = _kBad.withValues(alpha: 0.26));
  }
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = open
          ? _kGold.withValues(alpha: 0.9)
          : (danger ? _kBad.withValues(alpha: 0.9) : _kDoorEdge),
  );
}

/// A guest token — the same lumpy potato + eyes the painter draws in-game.
void _legendPotato(Canvas canvas, Offset c, double r, Color tint) {
  canvas.drawCircle(
    c,
    r * 1.5,
    Paint()
      ..color = tint.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
  );
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.scale(1.0, 0.86);
  canvas.drawCircle(Offset.zero, r, Paint()..color = tint);
  canvas.drawCircle(Offset(0, -r * 0.18), r,
      Paint()..color = Colors.white.withValues(alpha: 0.10));
  canvas.restore();
  final eye = Paint()..color = Potatuhs.ink.withValues(alpha: 0.85);
  canvas.drawCircle(Offset(c.dx - r * 0.32, c.dy - r * 0.1), r * 0.13, eye);
  canvas.drawCircle(Offset(c.dx + r * 0.32, c.dy - r * 0.1), r * 0.13, eye);
}

void _legendText(Canvas canvas, String t, Offset c, Color color,
    {double size = 11, FontWeight weight = FontWeight.w800}) {
  final tp = TextPainter(
    text: TextSpan(
      text: t,
      style: TextStyle(
          fontFamily: _kFont, fontSize: size, fontWeight: weight, color: color),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: 400);
  tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
}

/// Three stacked chevrons marching along [dir] — the exact "swipe this way" cue.
void _legendChevron(
    Canvas canvas, Offset center, Offset dir, double reach, Color color) {
  final perp = Offset(-dir.dy, dir.dx);
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  for (int i = 0; i < 3; i++) {
    final base = center + dir * (reach * 0.35 + i * reach * 0.32);
    final wing = reach * 0.32;
    final tip = base + dir * (wing * 0.7);
    final p1 = base - perp * wing - dir * (wing * 0.2);
    final p2 = base + perp * wing - dir * (wing * 0.2);
    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(p2.dx, p2.dy);
    canvas.drawPath(
        path, paint..color = color.withValues(alpha: 0.9 - i * 0.22));
  }
}

/// A short numbered corridor for the legend cards, built from the real door +
/// potato primitives. [open] rooms glow gold, [danger] rooms flash red,
/// [arrivals] hold cool-blue newcomers; every other room keeps a sienna
/// resident. Rooms are numbered 1..count with the "→ ∞" continuation.
void _legendCorridor(
  Canvas canvas,
  Size size, {
  required int count,
  Set<int> open = const {},
  Set<int> arrivals = const {},
  Set<int> danger = const {},
  double cyFrac = 0.5,
}) {
  final pad = size.width * 0.06;
  final plotL = pad, plotR = size.width - pad;
  final roomW = (plotR - plotL) / count;
  if (roomW < 6) return;
  final cy = size.height * cyFrac;
  final h = roomW * 1.15;

  final slab =
      Rect.fromLTRB(plotL - 4, cy - h / 2 - 12, plotR + 4, cy + h / 2 + 12);
  canvas.drawRRect(RRect.fromRectAndRadius(slab, const Radius.circular(12)),
      Paint()..color = _kFacade.withValues(alpha: 0.55));

  for (int r = 1; r <= count; r++) {
    final cx = plotL + (r - 0.5) * roomW;
    final rect =
        Rect.fromCenter(center: Offset(cx, cy), width: roomW * 0.78, height: h);
    final isOpen = open.contains(r), isDanger = danger.contains(r);
    _legendDoor(canvas, rect, open: isOpen, danger: isDanger);
    _legendText(canvas, '$r', Offset(cx, cy - h / 2 - 12),
        isOpen ? _kGold : _kTextSub,
        size: 10);
    Color? tint;
    if (arrivals.contains(r)) {
      tint = _kArrival;
    } else if (!isOpen && !isDanger) {
      tint = _kResident;
    }
    if (tint != null) {
      _legendPotato(canvas, Offset(cx, cy), roomW * 0.26, tint);
    }
  }

  _legendText(canvas, '→ ∞', Offset(plotR - 2, cy + h / 2 + 12), _kGold,
      size: 12);
}

// Frame 1 — the setup: a corridor with a resident in every room. Full, yet…
void _legendFull(Canvas canvas, Size size) {
  if (size.width < 40 || size.height < 40) return;
  canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);
  _legendCorridor(canvas, size, count: 6, cyFrac: 0.46);
  _legendText(canvas, 'HOTEL FULL — every counting number 1,2,3…',
      Offset(size.width / 2, size.height * 0.82), _kTextSub,
      size: 12);
}

// Frame 2 — score: 1 GUEST → swipe right, room 1 opens, the guest checks in.
void _legendGuest(Canvas canvas, Size size) {
  if (size.width < 40 || size.height < 40) return;
  canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);
  _legendCorridor(canvas, size,
      count: 6, open: {1}, arrivals: {1}, cyFrac: 0.44);
  _legendChevron(canvas, Offset(size.width * 0.5, size.height * 0.44),
      const Offset(1, 0), size.width * 0.13, _kGold);
  _legendText(canvas, '1 GUEST  ·  +points',
      Offset(size.width / 2, size.height * 0.80), _kArrival,
      size: 13);
}

// Frame 3 — escalation: a bus of ∞ → swipe up, every ODD room opens at once.
void _legendBus(Canvas canvas, Size size) {
  if (size.width < 40 || size.height < 40) return;
  canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);
  _legendCorridor(canvas, size,
      count: 6, open: {1, 3, 5}, arrivals: {1, 3, 5}, cyFrac: 0.44);
  _legendChevron(canvas, Offset(size.width * 0.5, size.height * 0.66),
      const Offset(0, -1), size.height * 0.15, _kGold);
  _legendText(canvas, 'A BUS · ℵ₀  ·  the odd rooms fill',
      Offset(size.width / 2, size.height * 0.84), _kArrival,
      size: 12);
}

// Frame 4 — danger: swipe LEFT evicts guest 1 to room 0, which cannot exist.
void _legendEvict(Canvas canvas, Size size) {
  if (size.width < 40 || size.height < 40) return;
  canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);
  _legendCorridor(canvas, size, count: 6, danger: {1}, cyFrac: 0.44);
  _legendChevron(canvas, Offset(size.width * 0.5, size.height * 0.44),
      const Offset(-1, 0), size.width * 0.13, _kBad);
  _legendText(canvas, 'ROOM 0 DOES NOT EXIST',
      Offset(size.width / 2, size.height * 0.80), _kBad,
      size: 12);
}

/// The visual manual for Hilbert's Hotel v2 — wired into the registry spec.
final List<LegendFrame> hilbertsHotelV2LegendFrames = [
  const LegendFrame(
      caption: 'Every room is full — yet guests keep arriving',
      paint: _legendFull),
  const LegendFrame(
      caption: '1 guest? Swipe → to shift up: room 1 opens',
      paint: _legendGuest),
  const LegendFrame(
      caption: 'A bus? Swipe ↑ to double: every odd room opens',
      paint: _legendBus),
  const LegendFrame(
      caption: 'Never swipe ← — it evicts guest 1, streak lost',
      paint: _legendEvict),
];
