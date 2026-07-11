import 'dart:math';

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PortfolioGame — "Portfolio"  (BioScale.financial)
// ═══════════════════════════════════════════════════════════════════════════════
//
// Teaches DIVERSIFICATION. The player splits a $1,000 portfolio across four
// volatile sector STOCKS and one steady INDEX BASKET (ETF). The portfolio is
// continuously rebalanced to the weights the player sets, so the weights ARE the
// allocation. Each second the market moves: individual stocks swing wildly (big
// upside, big crashes), the ETF glides. Rounds throw SHOCKS — a sector crashes
// (and, late, two correlated sectors crash together). A concentrated bet can get
// wiped; a diversified book only takes a glancing hit.
//
// The chart draws THREE lines so the lesson is visible:
//   • YOU       — your live portfolio value (bright).
//   • 1 STOCK   — what going all-in on a single stock would have done (wild/red).
//   • BASKET    — what holding only the ETF would have done (smooth/teal).
//
// Score = portfolio value (in dollars → points), synced to the host session via
// session.addScore on every change. The host owns the clock/countdown/results;
// this widget only runs the sim while session.isRunning, and renders the play
// area. Steady growth is rewarded; blow-ups are punished (value can fall).

// --- Sim tuning -------------------------------------------------------------
const double _kStartValue   = 1000.0; // opening capital (also the baseline)
const double _kDt           = 1 / 60.0;
const int    _kHistMax      = 240;    // ~60s at 4 samples/s
const double _kSampleEvery  = 0.25;   // seconds between chart samples

const double _kStockVol     = 0.95;   // per-second stock volatility (noise amp)
const double _kEtfVol       = 0.30;   // per-second ETF volatility (much calmer)
const double _kDriftMin     = -0.014; // per-second drift floor (some stocks bleed)
const double _kDriftMax      = 0.024; // per-second drift ceiling
const double _kReshuffle     = 7.0;   // seconds between drift reshuffles

const double _kShockFirst    = 6.0;   // seconds to the first shock
const double _kShockIntEarly = 7.5;   // shock interval early (calm)
const double _kShockIntLate  = 3.2;   // shock interval late (relentless)
const double _kShockDur      = 1.4;   // seconds a shock takes to play out
const double _kCrashMin      = 0.50;  // base sector crash depth (fraction)
const double _kCrashMax      = 0.82;  // late sector crash depth (fraction)
const double _kRallyChance    = 0.22; // a shock is a moonshot rally (else crash)
const double _kCorrelateRamp  = 0.55; // ramp past which crashes can pair up
const double _kSurviveDraw    = 0.10; // <10% portfolio drop = shock "weathered"
const double _kChunk          = 0.12; // weight shifted by one + / − tap
const double _kAutoDiversifyFloor = 0.995; // attract bot rebalances below this

// One tradeable position. ETF flag marks the diversified index basket.
class _Asset {
  final String ticker;
  final String sector;
  final Color  color;
  final bool   isEtf;
  double price;       // index, starts at 100
  double drift;       // per-second drift (reshuffled for stocks)
  double weight;      // 0..1, player-controlled
  double lastReturn;  // per-tick return, for display
  _Asset(this.ticker, this.sector, this.color, this.isEtf, this.drift)
      : price = 100.0,
        weight = 0.0,
        lastReturn = 0.0;
  double get pct => price / 100.0 - 1.0; // total change since open
}

// A live market shock pinned to one stock (negative = crash, positive = rally).
class _Shock {
  final int    assetIndex;
  final double perTick; // signed per-tick return contribution
  double ttl;
  final bool   positive;
  final double vStart;  // portfolio value when it began (for the streak check)
  bool resolved = false;
  _Shock(this.assetIndex, this.perTick, this.ttl, this.positive, this.vStart);
}

// One chart sample: the three lines share the $1,000 baseline.
class _Sample {
  final double you;
  final double solo;
  final double basket;
  _Sample(this.you, this.solo, this.basket);
}

// A rising "+N / −N%" callout.
class _Pop {
  Offset pos;
  final String label;
  final Color color;
  double life = 1.1;
  _Pop(this.pos, this.label, this.color);
  bool step(double dt) {
    pos = pos.translate(0, -46 * dt);
    life -= dt / 1.1;
    return life > 0;
  }
  void paint(Canvas canvas) {
    final a = life.clamp(0.0, 1.0);
    GameFx.text(canvas, label, pos, 20, color.withValues(alpha: a),
        weight: FontWeight.w800, glow: 0.8 * a);
  }
}

class PortfolioGame extends StatefulWidget {
  final MiniGameSession session;
  const PortfolioGame({super.key, required this.session});
  @override
  State<PortfolioGame> createState() => _PortfolioGameState();
}

class _PortfolioGameState extends State<PortfolioGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rng = Random();

  // 0..3 = volatile sector stocks, 4 = the diversified ETF/index basket.
  final List<_Asset> _assets = [];
  static const int _kEtf = 4;

  double _value  = _kStartValue;
  double _solo   = _kStartValue; // all-in on stock[0] reference
  double _basket = _kStartValue; // all-in on the ETF reference

  double _wall      = 0.0; // never-pausing clock for background motion
  double _timeLeft  = 60.0;
  double _shockTimer = _kShockFirst;
  double _reshuffleTimer = _kReshuffle;
  double _sampleClock = 0.0;

  final List<_Shock>    _shocks = [];
  final List<_Sample>   _hist   = [];
  final List<FxParticle> _fx    = [];
  final List<_Pop>      _pops    = [];

  Color  _flashColor = Colors.transparent;
  double _flashAlpha = 0.0;

  String _bannerText = '';
  double _bannerTtl  = 0.0;
  bool   _bannerBad  = true;

  int _survived = 0; // consecutive shocks weathered (streak award)

  // How-to-play coach: a bright, unmissable hint that FADES once the player
  // makes their first allocation move (taps a row's +/− or a preset). Until
  // then it pulses so a new player always knows the control. `_acted` latches
  // on first touch; `_hintAlpha` eases to 0 over ~0.9s after that.
  bool   _acted = false;
  double _hintAlpha = 1.0;

  // +N score-driver pops: portfolio value grows in tiny per-tick steps, so we
  // accumulate the rise and float a single "+N" every ~0.5s of net gain. Makes
  // the winning behaviour (steady growth) legible without spamming a pop/tick.
  double _gainAccum = 0.0;
  double _gainClock = 0.0;
  double _lastValue = _kStartValue;

  Size _hudSize = Size.zero;

  // --- Derived -------------------------------------------------------------
  double get _ramp => (1.0 - _timeLeft / 60.0).clamp(0.0, 1.0);

  /// Herfindahl-based diversification, 0 (all in one) → 1 (perfectly even).
  double get _diversification {
    double h = 0;
    for (final a in _assets) {
      h += a.weight * a.weight;
    }
    const n = 5;
    const denom = 1.0 - 1.0 / n;
    return ((1.0 - h) / denom).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _seedAssets();
    _hist.add(_Sample(_kStartValue, _kStartValue, _kStartValue));
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)
      ..forward();
    // ATTRACT autopilot: this game knows the winning line — DIVERSIFY. Registered
    // always (harmless in normal play; the host only calls it in autoplay). See
    // [_autoStep]. Dormant unless the host is driving hands-free.
    widget.session.autoPilot = _autoStep;
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  double _autoPhase = 0.0; // seconds elapsed in the current demo phase
  int    _autoStage = 0;   // 0 spread → 1 dangerous concentrate → 2 recover

  /// One hands-free move per host tick (~250ms). A static hold would show
  /// nothing moving, so the demo VISIBLY teaches the lesson by cycling the
  /// game's own controls: SPREAD EVENLY (calm), then ALL-IN on one stock (watch
  /// a concentrated book take a crash on the chin), then SPREAD EVENLY again to
  /// recover. Deterministic sequencing, no synthetic taps — it calls the same
  /// methods the player's buttons do.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    _autoPhase += 0.25; // host cadence ≈ 250ms
    switch (_autoStage) {
      case 0: // establish a diversified book, hold ~5s
        if (_diversification < _kAutoDiversifyFloor) _spreadEven();
        if (_autoPhase > 5.0) { _autoStage = 1; _autoPhase = 0; }
        break;
      case 1: // concentrate into one stock to show the danger, hold ~4s
        if (_assets[0].weight < 0.98) _allInStock(0);
        if (_autoPhase > 4.0) { _autoStage = 2; _autoPhase = 0; }
        break;
      case 2: // re-diversify to recover, hold ~5s, then loop
        if (_diversification < _kAutoDiversifyFloor) _spreadEven();
        if (_autoPhase > 5.0) { _autoStage = 0; _autoPhase = 0; }
        break;
    }
  }

  void _seedAssets() {
    _assets
      ..clear()
      ..addAll([
        _Asset('FRYZ', 'Fast Food',  Potatuhs.orange,   false, _newDrift()),
        _Asset('CHIPZ', 'Snacks',    Potatuhs.sienna,   false, _newDrift()),
        _Asset('SPUD', 'Farming',    Potatuhs.copper,   false, _newDrift()),
        _Asset('MASH', 'Industrial', Potatuhs.glaucous, false, _newDrift()),
        _Asset('TUBR', 'Index ETF',  Potatuhs.airForce, true,  0.012),
      ]);
    // Calm ready state: a sensibly diversified default book.
    for (final a in _assets) {
      a.weight = 1.0 / _assets.length;
    }
  }

  double _newDrift() =>
      _kDriftMin + _rng.nextDouble() * (_kDriftMax - _kDriftMin);

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ctrl.dispose();
    super.dispose();
  }

  // ─── Main loop (host owns the clock) ──────────────────────────────────────
  void _tick() {
    _wall += _kDt;

    // Decay transient visuals even while idle so the scene feels alive.
    if (_flashAlpha > 0) _flashAlpha = (_flashAlpha - _kDt * 2.5).clamp(0, 1);
    if (_bannerTtl > 0) _bannerTtl -= _kDt;
    // Coach hint fades out once the player has acted; while idle it pulses.
    // Safety: if a passive player never touches a control, auto-dismiss after
    // ~7s of live play so the hint can never permanently cover the chart.
    if (!_acted && widget.session.isRunning && (60.0 - _timeLeft) > 7.0) {
      _acted = true;
    }
    if (_acted && _hintAlpha > 0) {
      _hintAlpha = (_hintAlpha - _kDt / 0.9).clamp(0.0, 1.0);
    }
    _fx.removeWhere((p) => !p.step(_kDt));
    _pops.removeWhere((p) => !p.step(_kDt));

    if (!widget.session.isRunning) return;

    _timeLeft = widget.session.remaining.inMilliseconds / 1000.0;

    // Reshuffle stock drifts so no single stock is permanently "the winner".
    _reshuffleTimer -= _kDt;
    if (_reshuffleTimer <= 0) {
      for (int i = 0; i < _kEtf; i++) {
        _assets[i].drift = _newDrift();
      }
      _reshuffleTimer = _kReshuffle * (0.7 + _rng.nextDouble() * 0.6);
    }

    // Spawn shocks, accelerating as time runs out.
    _shockTimer -= _kDt;
    if (_shockTimer <= 0) {
      _spawnShock();
      final interval =
          _kShockIntEarly + (_kShockIntLate - _kShockIntEarly) * _ramp;
      _shockTimer = interval * (0.75 + _rng.nextDouble() * 0.5);
    }

    // Per-stock returns (drift + noise + any active shock on that stock).
    double driftSum = 0;
    double shockSum = 0;
    for (int i = 0; i < _kEtf; i++) {
      final a = _assets[i];
      final noise = (_rng.nextDouble() * 2 - 1) * _kStockVol * _kDt;
      final sh = _shockReturnFor(i);
      final r = a.drift * _kDt + noise + sh;
      a.lastReturn = r;
      a.price = (a.price * (1 + r)).clamp(2.0, 100000.0);
      driftSum += a.drift;
      shockSum += sh;
    }

    // The ETF: gentle drift, low noise, and only ~1/4 of the shock pain.
    final etf = _assets[_kEtf];
    final etfNoise = (_rng.nextDouble() * 2 - 1) * _kEtfVol * _kDt;
    etf.lastReturn = (driftSum / _kEtf) * _kDt + etfNoise + shockSum / _kEtf;
    etf.price = (etf.price * (1 + etf.lastReturn)).clamp(2.0, 100000.0);

    // Continuously rebalanced portfolio: value compounds the weighted return.
    double pr = 0;
    for (final a in _assets) {
      pr += a.weight * a.lastReturn;
    }
    _value = (_value * (1 + pr)).clamp(0.0, 1e9);

    // Score-driver feedback: bank the net rise and float one "+N" every ~0.5s
    // it stays positive, so a player sees exactly which behaviour is paying.
    _gainAccum += _value - _lastValue;
    _lastValue = _value;
    _gainClock += _kDt;
    if (_gainClock >= 0.5) {
      _gainClock = 0;
      if (_gainAccum >= 8 && _hudSize != Size.zero) {
        _pops.add(_Pop(
          Offset(_hudSize.width * (0.30 + _rng.nextDouble() * 0.16),
              _hudSize.height * 0.30),
          '+${_gainAccum.round()}',
          const Color(0xFF66BB6A),
        ));
      }
      _gainAccum = 0;
    }

    // Reference lines (normalized to the same $1,000 baseline).
    _solo   = _kStartValue * _assets[0].price / 100.0;
    _basket = _kStartValue * etf.price / 100.0;

    // Resolve expiring shocks (streak = weathering a crash without a big drop).
    for (int i = _shocks.length - 1; i >= 0; i--) {
      final s = _shocks[i];
      s.ttl -= _kDt;
      if (s.ttl <= 0 && !s.resolved) {
        s.resolved = true;
        if (!s.positive) {
          final drawdown =
              s.vStart > 0 ? (s.vStart - _value) / s.vStart : 0.0;
          if (drawdown < _kSurviveDraw) {
            _survived++;
            widget.session.noteStreak(_survived);
            // Celebrate the lesson landing: a diversified book shrugged off a
            // crash. Green pop + burst so weathering it reads as a WIN.
            if (_hudSize != Size.zero) {
              _pops.add(_Pop(
                Offset(_hudSize.width * 0.5, _hudSize.height * 0.24),
                _survived > 1 ? 'DIVERSIFIED ×$_survived' : 'DIVERSIFIED!',
                const Color(0xFF66BB6A),
              ));
            }
            _spawnFx(const Color(0xFF66BB6A), count: 10, speed: 120);
          } else {
            _survived = 0;
          }
        }
        _shocks.removeAt(i);
      }
    }

    // Chart sampling (throttled) and score sync.
    _sampleClock += _kDt;
    if (_sampleClock >= _kSampleEvery) {
      _sampleClock = 0;
      _hist.add(_Sample(_value, _solo, _basket));
      if (_hist.length > _kHistMax) _hist.removeAt(0);
    }
    _syncScore();
  }

  double _shockReturnFor(int assetIndex) {
    double r = 0;
    for (final s in _shocks) {
      if (s.assetIndex == assetIndex) r += s.perTick;
    }
    return r;
  }

  void _spawnShock() {
    final positive = _rng.nextDouble() < _kRallyChance;
    final f = positive
        ? 0.40 + _rng.nextDouble() * 0.45
        : (_kCrashMin + (_kCrashMax - _kCrashMin) * _ramp) *
            (0.7 + _rng.nextDouble() * 0.5);
    final dur = _kShockDur * (0.8 + _rng.nextDouble() * 0.6);
    // Convert a target fraction over the window into a per-tick multiplier.
    final mag = 1.0 - pow(1.0 - f.clamp(0.0, 0.95), _kDt / dur).toDouble();
    final perTick = positive ? mag : -mag;

    final i = _rng.nextInt(_kEtf);
    _shocks.add(_Shock(i, perTick, dur, positive, _value));

    // Late game: crashes can hit two correlated sectors at once.
    final correlated =
        !positive && _ramp > _kCorrelateRamp && _rng.nextDouble() < 0.5;
    int? j;
    if (correlated) {
      j = (i + 1 + _rng.nextInt(_kEtf - 1)) % _kEtf;
      _shocks.add(_Shock(j, perTick, dur, false, _value));
    }

    final a = _assets[i];
    _bannerBad = !positive;
    _bannerTtl = dur + 0.6;
    if (positive) {
      _bannerText = 'RALLY · ${a.ticker} ${a.sector}';
      _flashColor = const Color(0xFF66BB6A);
      _flashAlpha = 0.16;
    } else {
      _bannerText = j != null
          ? 'CORRELATED CRASH · ${a.ticker} + ${_assets[j].ticker}'
          : 'SECTOR CRASH · ${a.ticker} ${a.sector}';
      _flashColor = const Color(0xFFEF5350);
      _flashAlpha = 0.22;
    }
  }

  /// session.score == round(portfolio value). addScore is monotonic-via-delta
  /// and clamps at ≥ 0, so pushing (target − current) tracks the live value.
  void _syncScore() {
    final target = _value.round();
    widget.session.addScore(target - widget.session.score);
  }

  // ─── Allocation controls ──────────────────────────────────────────────────
  /// First real allocation move dismisses the coach hint (it fades over ~0.9s).
  void _markActed() {
    if (!_acted) _acted = true;
  }

  void _shiftInto(int i, double chunk) {
    _markActed();
    final others = 1.0 - _assets[i].weight;
    if (others <= 1e-6) return; // already fully concentrated here
    final add = min(chunk, others);
    final scale = (others - add) / others;
    setState(() {
      for (int j = 0; j < _assets.length; j++) {
        if (j != i) _assets[j].weight *= scale;
      }
      _assets[i].weight += add;
      _normalize();
    });
    _spawnFx(_assets[i].color, count: 6);
  }

  void _shiftOut(int i, double chunk) {
    _markActed();
    final w = _assets[i].weight;
    if (w <= 1e-6) return;
    final take = min(chunk, w);
    final rest = 1.0 - w;
    setState(() {
      _assets[i].weight -= take;
      if (rest <= 1e-6) {
        // Nothing else to receive it — spread the freed weight evenly.
        final each = take / (_assets.length - 1);
        for (int j = 0; j < _assets.length; j++) {
          if (j != i) _assets[j].weight += each;
        }
      } else {
        final scale = (rest + take) / rest;
        for (int j = 0; j < _assets.length; j++) {
          if (j != i) _assets[j].weight *= scale;
        }
      }
      _normalize();
    });
  }

  void _spreadEven() {
    _markActed();
    setState(() {
      for (final a in _assets) {
        a.weight = 1.0 / _assets.length;
      }
    });
    _spawnFx(Potatuhs.airForce, count: 12, speed: 110);
  }

  void _allInEtf() {
    _markActed();
    setState(() {
      for (int j = 0; j < _assets.length; j++) {
        _assets[j].weight = j == _kEtf ? 1.0 : 0.0;
      }
    });
    _spawnFx(_assets[_kEtf].color, count: 12, speed: 110);
  }

  /// Concentrate the whole book into one holding. Not a player control — used by
  /// the ATTRACT demo to show a concentrated (risky) book on the chart.
  void _allInStock(int i) {
    setState(() {
      for (int j = 0; j < _assets.length; j++) {
        _assets[j].weight = j == i ? 1.0 : 0.0;
      }
    });
    _spawnFx(_assets[i].color, count: 10, speed: 100);
  }

  void _normalize() {
    double sum = 0;
    for (final a in _assets) {
      a.weight = a.weight.clamp(0.0, 1.0);
      sum += a.weight;
    }
    if (sum <= 1e-9) {
      for (final a in _assets) {
        a.weight = 1.0 / _assets.length;
      }
      return;
    }
    for (final a in _assets) {
      a.weight /= sum;
    }
  }

  void _spawnFx(Color color, {int count = 8, double speed = 80}) {
    if (_hudSize == Size.zero) return;
    final center = Offset(_hudSize.width / 2, _hudSize.height * 0.5);
    _fx.addAll(FxBurst.spawn(center, color, count: count, speed: speed));
  }

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(
        child: RepaintBoundary(
          child: CustomPaint(painter: _BackgroundPainter(this)),
        ),
      ),
      if (_flashAlpha > 0)
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              color: _flashColor.withValues(alpha: _flashAlpha),
            ),
          ),
        ),
      SafeArea(
        child: Column(children: [
          // Live HUD (value, gauge, 3-line chart, market strip) — one painter,
          // repainting off the ticker, never rebuilding the widget tree.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: LayoutBuilder(builder: (ctx, c) {
                _hudSize = Size(c.maxWidth, c.maxHeight);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _HudPainter(this),
                  ),
                );
              }),
            ),
          ),
          _buildControls(),
        ]),
      ),
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(painter: _FxPainter(this)),
        ),
      ),
    ]);
  }

  // ─── Allocation panel (rebuilds only on tap) ──────────────────────────────
  Widget _buildControls() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: Potatuhs.surface(
        fill: Potatuhs.inkPanel.withValues(alpha: 0.92),
        borderColor: Potatuhs.airForce.withValues(alpha: 0.3),
        radius: 14,
      ),
      child: Column(children: [
        for (int i = 0; i < _assets.length; i++) _assetRow(i),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: _actionBtn(
              'SPREAD EVENLY',
              'diversify all',
              Potatuhs.airForce,
              _spreadEven,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionBtn(
              'ALL-IN ETF',
              'one-tap basket',
              _assets[_kEtf].color,
              _allInEtf,
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _assetRow(int i) {
    final a = _assets[i];
    final pctW = (a.weight * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.only(right: 7),
          decoration: BoxDecoration(
            color: a.color,
            shape: BoxShape.circle,
            boxShadow: Potatuhs.glow(a.color, strength: 0.6, blur: 6),
          ),
        ),
        SizedBox(
          width: 52,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(a.ticker,
                    style: Potatuhs.body(
                        size: 12,
                        weight: FontWeight.w800,
                        color: Potatuhs.textPrimary)),
                if (a.isEtf)
                  Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: Icon(Icons.shield_outlined,
                        size: 11, color: a.color.withValues(alpha: 0.9)),
                  ),
              ]),
              Text(a.sector,
                  style: Potatuhs.label(size: 7, color: Potatuhs.textFaint),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 6),
        // Weight bar (target allocation — static between taps).
        Expanded(
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: a.weight.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    a.color.withValues(alpha: 0.55),
                    a.color,
                  ]),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text('$pctW%',
              textAlign: TextAlign.right,
              style: Potatuhs.body(
                  size: 12,
                  weight: FontWeight.w800,
                  color: a.weight > 0.001 ? a.color : Potatuhs.textFaint)),
        ),
        const SizedBox(width: 4),
        _miniBtn('−', () => _shiftOut(i, _kChunk)),
        const SizedBox(width: 4),
        _miniBtn('+', () => _shiftInto(i, _kChunk)),
      ]),
    );
  }

  Widget _miniBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Text(label,
            style: Potatuhs.body(
                size: 18,
                weight: FontWeight.w800,
                color: Potatuhs.textPrimary)),
      ),
    );
  }

  Widget _actionBtn(String top, String sub, Color accent, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.6), width: 1.4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(top, style: Potatuhs.label(size: 11, color: accent)),
            Text(sub,
                style: Potatuhs.label(size: 7, color: Potatuhs.textFaint)),
          ],
        ),
      ),
    );
  }
}

// ─── Background painter ─────────────────────────────────────────────────────
class _BackgroundPainter extends CustomPainter {
  final _PortfolioGameState s;
  _BackgroundPainter(this.s) : super(repaint: s._ctrl);
  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, const Color(0xFF4DB6AC), s._wall, motes: 24);
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) => false;
}

// ─── HUD painter: value, allocation donut, 3-line chart, market strip ───────
class _HudPainter extends CustomPainter {
  final _PortfolioGameState s;
  _HudPainter(this.s) : super(repaint: s._ctrl);

  // Static labels are laid out ONCE (design rule: don't re-layout static text
  // via GameFx.text every frame). These are the always-on objective line and
  // the coach how-to strip — the two comprehension anchors this pass adds.
  static final TextPainter _objectiveTp = TextPainter(
    text: TextSpan(
      text: 'SPREAD RISK — SET THE MIX ACROSS 5 HOLDINGS',
      style: Potatuhs.label(size: 9, color: Potatuhs.airForce),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  static final TextPainter _hintTp = TextPainter(
    text: TextSpan(
      text: 'Tap  −  +  to set each weight  ·  SPREAD EVENLY to diversify',
      style: Potatuhs.body(
          size: 12, weight: FontWeight.w700, color: Potatuhs.textPrimary),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Potatuhs.inkPanel.withValues(alpha: 0.95),
            Potatuhs.inkDeep.withValues(alpha: 0.98),
          ],
        ).createShader(rect),
    );

    const pad = 12.0;
    const topH = 78.0; // taller: value + objective line on the left, donut right
    const stripH = 40.0;
    const chartTop = topH + 6;
    final chartBottom = size.height - stripH - 6;
    final chartRect = Rect.fromLTRB(
        pad, chartTop, size.width - pad, chartBottom);

    _paintHeader(canvas, Size(size.width, topH), pad);
    _paintChart(canvas, chartRect);
    _paintMarketStrip(
        canvas,
        Rect.fromLTRB(pad, size.height - stripH, size.width - pad, size.height));

    // Coach hint — bright, centered over the chart, fades out after first move.
    if (s._hintAlpha > 0.01) {
      // Idle pulse before the first action so the control is unmissable.
      final pulse = s._acted ? 1.0 : (0.72 + 0.28 * (0.5 + 0.5 * sin(s._wall * 3.4)));
      final a = (s._hintAlpha * pulse).clamp(0.0, 1.0);
      final cx = size.width / 2;
      final cy = chartRect.top + chartRect.height * 0.5;
      final bw = _hintTp.width + 26;
      final box = Rect.fromCenter(
          center: Offset(cx, cy), width: bw, height: 34);
      final rr = RRect.fromRectAndRadius(box, const Radius.circular(10));
      canvas.drawRRect(
          rr, Paint()..color = Potatuhs.inkDeep.withValues(alpha: 0.82 * a));
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = Potatuhs.airForce.withValues(alpha: 0.7 * a),
      );
      canvas.saveLayer(
          box.inflate(4), Paint()..color = Colors.white.withValues(alpha: a));
      _hintTp.paint(
          canvas, Offset(cx - _hintTp.width / 2, cy - _hintTp.height / 2));
      canvas.restore();
    }
  }

  void _paintHeader(Canvas canvas, Size size, double pad) {
    final up = s._value >= _kStartValue;
    final col =
        up ? const Color(0xFF66BB6A) : const Color(0xFFEF5350);

    // Portfolio value.
    final vp = TextPainter(
      text: TextSpan(
        text: '\$${s._value.toStringAsFixed(0)}',
        style: Potatuhs.display(size: 30, color: col).copyWith(shadows: [
          Shadow(color: col.withValues(alpha: 0.5), blurRadius: 12),
        ]),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    vp.paint(canvas, Offset(pad, 4));

    final deltaPct = (s._value / _kStartValue - 1) * 100;
    GameFx.text(
      canvas,
      '${deltaPct >= 0 ? '▲' : '▼'} ${deltaPct.abs().toStringAsFixed(1)}%',
      Offset(pad + vp.width + 34, 4 + vp.height / 2),
      13,
      col,
      weight: FontWeight.w800,
    );
    GameFx.text(canvas, 'PORTFOLIO VALUE', Offset(pad + 44, 4 + vp.height + 6), 8,
        Potatuhs.textFaint);

    // Always-visible OBJECTIVE — the one line that makes Portfolio's distinct
    // point (ALLOCATION across many holdings, not single-asset timing) obvious.
    final oy = 4 + vp.height + 18.0;
    canvas.drawCircle(Offset(pad + 4, oy + _objectiveTp.height / 2), 3.2,
        Paint()..color = Potatuhs.airForce);
    _objectiveTp.paint(canvas, Offset(pad + 12, oy));

    // Allocation DONUT — the signature differentiator. A live pie of the five
    // weights (this is ALLOCATION, which a single-asset trading desk can't show)
    // with the diversification word + RISK SPREAD label in the hole.
    final d = s._diversification;
    final ringR = (size.height * 0.42).clamp(26.0, 40.0);
    final cx = size.width - pad - ringR - 30;
    final cy = size.height / 2;
    _paintAllocationDonut(canvas, Offset(cx, cy), ringR, d);

    // Shock banner.
    if (s._bannerTtl > 0) {
      final a = (s._bannerTtl).clamp(0.0, 1.0);
      final bc =
          s._bannerBad ? const Color(0xFFEF5350) : const Color(0xFF66BB6A);
      GameFx.text(
        canvas,
        '${s._bannerBad ? '⚠ ' : '★ '}${s._bannerText}',
        Offset(size.width / 2, size.height + 2),
        12,
        bc.withValues(alpha: a),
        weight: FontWeight.w800,
        glow: 0.7 * a,
      );
    }
  }

  // The allocation donut: each holding's weight as a colored arc, the shield-
  // ringed ETF included. The hole shows the RISK SPREAD read-out. This is the
  // "pie of weights" that visually separates Portfolio (allocation) from the
  // single-price trading desk of Market Trader.
  void _paintAllocationDonut(Canvas canvas, Offset c, double r, double d) {
    final thick = r * 0.42;
    final rr = r - thick / 2;
    final ring = Rect.fromCircle(center: c, radius: rr);

    // Faint full track behind the arcs.
    canvas.drawCircle(
      c,
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thick
        ..color = Colors.white.withValues(alpha: 0.06),
    );

    double start = -pi / 2;
    const gap = 0.045; // small seam between slices
    for (final a in s._assets) {
      final w = a.weight.clamp(0.0, 1.0);
      if (w <= 0.001) continue;
      final sweep = w * 2 * pi;
      final drawSweep = (sweep - gap).clamp(0.0, 2 * pi);
      canvas.drawArc(
        ring,
        start + gap / 2,
        drawSweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = thick
          ..strokeCap = StrokeCap.butt
          ..color = a.color,
      );
      // ETF slice gets a bright inner rim (its shield motif) so the "safe
      // basket" is recognizable at a glance.
      if (a.isEtf) {
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: rr - thick / 2 + 1),
          start + gap / 2,
          drawSweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = Colors.white.withValues(alpha: 0.85),
        );
      }
      start += sweep;
    }

    // Hole read-out: diversification word (red→green) + RISK SPREAD label.
    final fillCol =
        Color.lerp(const Color(0xFFEF5350), const Color(0xFF66BB6A), d)!;
    final word = d < 0.34
        ? 'CONCENTR.'
        : (d < 0.67 ? 'BALANCED' : 'SPREAD');
    GameFx.text(canvas, word, c.translate(0, -3), 9, fillCol,
        weight: FontWeight.w800);
    GameFx.text(canvas, 'RISK SPREAD', c.translate(0, 8), 6.5,
        Potatuhs.textFaint, weight: FontWeight.w700);
  }

  void _paintChart(Canvas canvas, Rect r) {
    final hist = s._hist;
    if (hist.length < 2) return;

    double minV = double.infinity, maxV = -double.infinity;
    for (final h in hist) {
      minV = min(minV, min(h.you, min(h.solo, h.basket)));
      maxV = max(maxV, max(h.you, max(h.solo, h.basket)));
    }
    minV = min(minV, _kStartValue);
    maxV = max(maxV, _kStartValue);
    final padV = (maxV - minV) * 0.12 + 20;
    minV -= padV;
    maxV += padV;
    final range = maxV - minV;
    if (range <= 0) return;

    double px(int i) => r.left + (i / (hist.length - 1)) * r.width;
    double py(double v) => r.bottom - ((v - minV) / range) * r.height;

    // Grid.
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;
    for (int i = 1; i <= 3; i++) {
      final y = r.top + r.height * i / 4;
      canvas.drawLine(Offset(r.left, y), Offset(r.right, y), grid);
    }

    // $1,000 baseline.
    final baseY = py(_kStartValue);
    final dash = Paint()
      ..color = Potatuhs.textFaint.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;
    for (double x = r.left; x < r.right; x += 10) {
      canvas.drawLine(Offset(x, baseY), Offset(x + 5, baseY), dash);
    }

    Path linePath(double Function(_Sample) sel) {
      final p = Path();
      for (int i = 0; i < hist.length; i++) {
        final x = px(i);
        final y = py(sel(hist[i]));
        i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
      }
      return p;
    }

    // Reference: single-stock (wild, red) and basket/ETF (smooth, teal).
    canvas.drawPath(
      linePath((h) => h.solo),
      Paint()
        ..color = const Color(0xFFEF5350).withValues(alpha: 0.45)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      linePath((h) => h.basket),
      Paint()
        ..color = Potatuhs.airForce.withValues(alpha: 0.55)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );

    // Your portfolio (bright, glow + core).
    final youPath = linePath((h) => h.you);
    final youCol = s._value >= _kStartValue
        ? const Color(0xFF4DB6AC)
        : const Color(0xFFEF5350);
    canvas.drawPath(
      youPath,
      Paint()
        ..color = youCol.withValues(alpha: 0.3)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      youPath,
      Paint()
        ..color = youCol
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final tipX = px(hist.length - 1);
    final tipY = py(hist.last.you);
    canvas.drawCircle(Offset(tipX, tipY), 3.5, Paint()..color = youCol);

    // Legend.
    _legend(canvas, Offset(r.left + 4, r.top + 2), 'YOU', youCol);
    _legend(canvas, Offset(r.left + 4, r.top + 16), '1 STOCK',
        const Color(0xFFEF5350));
    _legend(
        canvas, Offset(r.left + 4, r.top + 30), 'BASKET', Potatuhs.airForce);
  }

  void _legend(Canvas canvas, Offset at, String label, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(at.dx, at.dy + 2, 12, 3), const Radius.circular(2)),
      Paint()..color = color,
    );
    final tp = TextPainter(
      text: TextSpan(
          text: label,
          style: Potatuhs.label(
              size: 8, color: color.withValues(alpha: 0.9))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(at.dx + 17, at.dy - 2));
  }

  // Live per-asset % change since open — the market at a glance.
  void _paintMarketStrip(Canvas canvas, Rect r) {
    final n = s._assets.length;
    final cellW = r.width / n;
    for (int i = 0; i < n; i++) {
      final a = s._assets[i];
      final cx = r.left + cellW * i + cellW / 2;
      final pct = a.pct * 100;
      final col = pct >= 0
          ? const Color(0xFF66BB6A)
          : const Color(0xFFEF5350);
      GameFx.text(canvas, a.ticker, Offset(cx, r.top + 9), 9, a.color,
          weight: FontWeight.w800);
      GameFx.text(
        canvas,
        '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(0)}%',
        Offset(cx, r.top + 26),
        12,
        col,
        weight: FontWeight.w800,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HudPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, drawn with the REAL components
// (the same asset chips, weight bars, RISK SPREAD gauge and 3-line chart the
// live game uses). Cheap, static, size-guarded — rendered once in the intro.
// ═══════════════════════════════════════════════════════════════════════════

// Up/down market colours (identical to the values the live HUD paints with —
// not a new palette, just named for the manual).
const Color _kLegUp   = Color(0xFF66BB6A);
const Color _kLegDown = Color(0xFFEF5350);

// The book as the player first meets it: four sector stocks + one steady ETF.
// (ticker, colour, isEtf) — mirrors _seedAssets().
const List<(String, Color, bool)> _kLegAssets = [
  ('FRYZ',  Potatuhs.orange,   false),
  ('CHIPZ', Potatuhs.sienna,   false),
  ('SPUD',  Potatuhs.copper,   false),
  ('MASH',  Potatuhs.glaucous, false),
  ('TUBR',  Potatuhs.airForce, true),
];

// Width-constrained centered text for the legend cards. The shared [GameFx.text]
// lays out at natural width with no cap, so the long crash headers ("⚠ CORRELATED
// CRASH · FRYZ + MASH") and the packed ticker/% lingo spilled past their box on
// the narrow embeds the cell runs in. This shrinks the font toward [minSize]
// until the line fits [maxWidth] (mirrors the tissue/skin_layers fix; local
// because the shared kit intentionally has no max-width and must not change).
void _legFit(Canvas canvas, String s, Offset center, double size, Color color,
    double maxWidth,
    {bool display = false,
    FontWeight weight = FontWeight.w800,
    double glow = 0,
    double minSize = 6}) {
  if (maxWidth <= 0 || s.isEmpty) return;
  var fontSize = size;
  TextPainter tp() => TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontFamily: display ? Potatuhs.displayFont : Potatuhs.bodyFont,
            fontSize: fontSize,
            fontWeight: weight,
            color: color,
            shadows: glow > 0
                ? [Shadow(color: color.withValues(alpha: glow), blurRadius: 12)]
                : null,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      );
  var painter = tp()..layout();
  while (painter.width > maxWidth && fontSize > minSize) {
    fontSize = (fontSize - 0.5).clamp(minSize, size);
    painter = tp()..layout();
  }
  painter = tp()..layout(maxWidth: maxWidth);
  painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
}

// One allocation row (glowing colour dot + ticker + weight bar + %) — the exact
// row the player taps − / + on.
void _legAssetRow(
    Canvas canvas, Rect r, String ticker, Color color, double weight, bool etf) {
  final cy = r.center.dy;
  final dot = Offset(r.left + r.height * 0.5, cy);
  final dr = (r.height * 0.28).clamp(3.0, 7.0);
  canvas.drawCircle(dot, dr * 1.7,
      Paint()..color = color.withValues(alpha: 0.28));
  canvas.drawCircle(dot, dr, Paint()..color = color);
  if (etf) {
    canvas.drawCircle(
      dot,
      dr * 2.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = color.withValues(alpha: 0.75),
    );
  }
  final barL = r.left + r.height * 2.7;
  final barR = r.right - r.height * 1.4;
  // Ticker sits in the gap between the colour dot and the bar; fit it there so
  // it never runs under the weight bar on a short row.
  final tickLeft = r.left + r.height * 1.05;
  _legFit(canvas, ticker, Offset((tickLeft + barL) / 2, cy), 12,
      Potatuhs.textPrimary, barL - tickLeft - 2);

  if (barR > barL) {
    final track = Rect.fromLTWH(barL, cy - 5, barR - barL, 10);
    _legBar(canvas, track, weight, color);
  }
  _legFit(canvas, '${(weight * 100).round()}%',
      Offset(r.right - r.height * 0.7, cy), 11, color, r.height * 1.4);
}

// The weight bar (rounded track + colour fill) as drawn in _assetRow.
void _legBar(Canvas canvas, Rect track, double frac, Color color) {
  final rad = Radius.circular(track.height / 2);
  canvas.drawRRect(RRect.fromRectAndRadius(track, rad),
      Paint()..color = Colors.white.withValues(alpha: 0.06));
  final w = track.width * frac.clamp(0.0, 1.0);
  if (w > 0.5) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(track.left, track.top, w, track.height), rad),
      Paint()
        ..shader = LinearGradient(colors: [
          color.withValues(alpha: 0.55),
          color,
        ]).createShader(track),
    );
  }
}

// The RISK SPREAD gauge (Herfindahl bar, red→green) — the live diversification
// read-out. [d]=0 concentrated, 1 diversified.
void _legGauge(Canvas canvas, Rect track, double d) {
  final rad = Radius.circular(track.height / 2);
  canvas.drawRRect(RRect.fromRectAndRadius(track, rad),
      Paint()..color = Colors.white.withValues(alpha: 0.08));
  final fillCol = Color.lerp(_kLegDown, _kLegUp, d)!;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(track.left, track.top,
            track.width * d.clamp(0.05, 1.0), track.height),
        rad),
    Paint()..color = fillCol,
  );
  final word =
      d < 0.34 ? 'CONCENTRATED' : (d < 0.67 ? 'BALANCED' : 'DIVERSIFIED');
  _legFit(canvas, word, Offset(track.center.dx, track.top - 11), 9, fillCol,
      track.width);
  _legFit(canvas, 'RISK SPREAD', Offset(track.center.dx, track.bottom + 9), 7,
      Potatuhs.textFaint, track.width,
      weight: FontWeight.w700);
}

// A short signed arrow (a shock's direction on a ticker).
void _legArrow(Canvas canvas, Offset tip, double len, Color color,
    {bool down = true}) {
  final p = Paint()
    ..color = color
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final dir = down ? 1.0 : -1.0;
  canvas.drawLine(tip.translate(0, -len * dir), tip, p);
  canvas.drawLine(tip, tip.translate(-5, -6 * dir), p);
  canvas.drawLine(tip, tip.translate(5, -6 * dir), p);
}

// An in-game action button (SPREAD EVENLY / ALL-IN ETF), as _actionBtn draws.
void _legActionBtn(Canvas canvas, Rect r, String label, Color accent) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(12));
  canvas.drawRRect(rr, Paint()..color = accent.withValues(alpha: 0.16));
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = accent.withValues(alpha: 0.6),
  );
  _legFit(canvas, label, r.center, 11, accent, r.width - 10);
}

// ── Frame 1: the book — split a fixed budget across the five positions ────────
void _legendBook(Canvas canvas, Size size) {
  if (size.width < 24 || size.height < 24) return;
  _legFit(canvas, 'YOUR \$1,000 BOOK',
      Offset(size.width * 0.5, size.height * 0.08), 10, Potatuhs.textFaint,
      size.width * 0.9);
  final rowH = (size.height * 0.15).clamp(14.0, 40.0);
  final gap = size.height * 0.028;
  final top = size.height * 0.15;
  for (int i = 0; i < _kLegAssets.length; i++) {
    final a = _kLegAssets[i];
    final y = top + i * (rowH + gap);
    final r = Rect.fromLTWH(size.width * 0.06, y, size.width * 0.88, rowH);
    _legAssetRow(canvas, r, a.$1, a.$2, 0.20, a.$3);
  }
}

// ── Frame 2: how to score — grow the value; steady beats the wild single stock
void _legendGrow(Canvas canvas, Size size) {
  if (size.width < 24 || size.height < 24) return;
  final r = Rect.fromLTWH(size.width * 0.08, size.height * 0.16,
      size.width * 0.84, size.height * 0.62);
  if (r.width < 8 || r.height < 8) return;

  // Normalised traces (0 bottom → 1 top): your book climbs steadily, a single
  // stock whipsaws and ends low, the basket glides up gently.
  const you = [0.30, 0.33, 0.31, 0.40, 0.45, 0.43, 0.53, 0.60, 0.67, 0.76];
  const stock = [0.30, 0.48, 0.19, 0.58, 0.26, 0.64, 0.17, 0.44, 0.23, 0.15];
  const basket = [0.30, 0.32, 0.34, 0.37, 0.39, 0.42, 0.45, 0.48, 0.52, 0.56];

  Path trace(List<double> f) {
    final p = Path();
    for (int i = 0; i < f.length; i++) {
      final x = r.left + i / (f.length - 1) * r.width;
      final y = r.bottom - f[i] * r.height;
      i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
    }
    return p;
  }

  // $1,000 baseline (dashed), pinned to the traces' opening level.
  final baseY = r.bottom - 0.30 * r.height;
  final dash = Paint()
    ..color = Potatuhs.textFaint.withValues(alpha: 0.4)
    ..strokeWidth = 1.0;
  for (double x = r.left; x < r.right; x += 10) {
    canvas.drawLine(Offset(x, baseY), Offset(x + 5, baseY), dash);
  }

  canvas.drawPath(
    trace(stock),
    Paint()
      ..color = _kLegDown.withValues(alpha: 0.5)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round,
  );
  canvas.drawPath(
    trace(basket),
    Paint()
      ..color = Potatuhs.airForce.withValues(alpha: 0.6)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round,
  );
  final youPath = trace(you);
  const youCol = Color(0xFF4DB6AC);
  canvas.drawPath(
    youPath,
    Paint()
      ..color = youCol.withValues(alpha: 0.3)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
  );
  canvas.drawPath(
    youPath,
    Paint()
      ..color = youCol
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
  canvas.drawCircle(
      Offset(r.right, r.bottom - you.last * r.height), 3.5,
      Paint()..color = youCol);

  _legTag(canvas, Offset(r.left + 4, r.top + 2), 'YOU', youCol);
  _legTag(canvas, Offset(r.left + 4, r.top + 16), '1 STOCK', _kLegDown);
  _legTag(canvas, Offset(r.left + 4, r.top + 30), 'BASKET', Potatuhs.airForce);
}

// The chart's tiny colour-swatch + label, as _HudPainter._legend draws.
void _legTag(Canvas canvas, Offset at, String label, Color color) {
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(at.dx, at.dy + 2, 12, 3), const Radius.circular(2)),
    Paint()..color = color,
  );
  final tp = TextPainter(
    text: TextSpan(
        text: label,
        style: Potatuhs.label(size: 8, color: color.withValues(alpha: 0.9))),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(at.dx + 17, at.dy - 2));
}

// ── Frame 3: the danger — a sector crash craters a concentrated bet ───────────
void _legendCrash(Canvas canvas, Size size) {
  if (size.width < 24 || size.height < 24) return;
  _legFit(canvas, '⚠ SECTOR CRASH · SPUD',
      Offset(size.width * 0.5, size.height * 0.14), 12, _kLegDown,
      size.width * 0.9,
      glow: 0.7);

  // The crashing ticker, market-strip style: ticker over a big red −%.
  final cx = size.width * 0.5;
  _legFit(canvas, 'SPUD', Offset(cx, size.height * 0.36), 13, Potatuhs.copper,
      size.width * 0.4);
  _legArrow(canvas, Offset(cx - size.width * 0.24, size.height * 0.52),
      size.height * 0.16, _kLegDown);
  _legFit(canvas, '−72%', Offset(cx, size.height * 0.50), 22, _kLegDown,
      size.width * 0.4,
      glow: 0.6);

  // A book that's all-in on one stock reads CONCENTRATED — the losing setup.
  final gauge = Rect.fromLTWH(
      size.width * 0.18, size.height * 0.76, size.width * 0.64, 10);
  _legGauge(canvas, gauge, 0.10);
}

// ── Frame 4: the escalation — two sectors crash together; spread or hold ETF ──
void _legendCorrelated(Canvas canvas, Size size) {
  if (size.width < 24 || size.height < 24) return;
  _legFit(canvas, '⚠ CORRELATED CRASH · FRYZ + MASH',
      Offset(size.width * 0.5, size.height * 0.13), 11, _kLegDown,
      size.width * 0.94,
      glow: 0.7);

  final leftX = size.width * 0.30;
  final rightX = size.width * 0.70;
  final tickerY = size.height * 0.30;
  _legFit(canvas, 'FRYZ', Offset(leftX, tickerY), 12, Potatuhs.orange,
      size.width * 0.36);
  _legFit(canvas, 'MASH', Offset(rightX, tickerY), 12, Potatuhs.glaucous,
      size.width * 0.36);
  _legArrow(canvas, Offset(leftX, size.height * 0.50), size.height * 0.14,
      _kLegDown);
  _legArrow(canvas, Offset(rightX, size.height * 0.50), size.height * 0.14,
      _kLegDown);

  // The two escape hatches — the real in-game buttons.
  final btnY = size.height * 0.66;
  final btnH = (size.height * 0.16).clamp(20.0, 46.0);
  final w = size.width * 0.40;
  _legActionBtn(canvas, Rect.fromLTWH(size.width * 0.06, btnY, w, btnH),
      'SPREAD EVENLY', Potatuhs.airForce);
  _legActionBtn(canvas, Rect.fromLTWH(size.width * 0.54, btnY, w, btnH),
      'ALL-IN ETF', Potatuhs.airForce);
}

/// The visual manual for Portfolio — wired into the registry spec.
final List<LegendFrame> portfolioLegendFrames = [
  const LegendFrame(
      caption: 'Split \$1,000 across 4 stocks + 1 steady ETF',
      paint: _legendBook),
  const LegendFrame(
      caption: 'Grow the value: steady beats an all-in gamble',
      paint: _legendGrow),
  const LegendFrame(
      caption: 'A sector crash craters a concentrated bet',
      paint: _legendCrash),
  const LegendFrame(
      caption: 'Late: two sectors crash at once — spread or hold ETF',
      paint: _legendCorrelated),
];

// ─── FX overlay painter ─────────────────────────────────────────────────────
class _FxPainter extends CustomPainter {
  final _PortfolioGameState s;
  _FxPainter(this.s) : super(repaint: s._ctrl);
  @override
  void paint(Canvas canvas, Size size) {
    FxBurst.paint(canvas, s._fx);
    for (final p in s._pops) {
      p.paint(canvas);
    }
  }

  @override
  bool shouldRepaint(covariant _FxPainter oldDelegate) => false;
}
