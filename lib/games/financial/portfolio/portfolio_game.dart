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
    final denom = 1.0 - 1.0 / n;
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
    _ctrl.dispose();
    super.dispose();
  }

  // ─── Main loop (host owns the clock) ──────────────────────────────────────
  void _tick() {
    _wall += _kDt;

    // Decay transient visuals even while idle so the scene feels alive.
    if (_flashAlpha > 0) _flashAlpha = (_flashAlpha - _kDt * 2.5).clamp(0, 1);
    if (_bannerTtl > 0) _bannerTtl -= _kDt;
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
  void _shiftInto(int i, double chunk) {
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
    setState(() {
      for (final a in _assets) {
        a.weight = 1.0 / _assets.length;
      }
    });
    _spawnFx(Potatuhs.airForce, count: 12, speed: 110);
  }

  void _allInEtf() {
    setState(() {
      for (int j = 0; j < _assets.length; j++) {
        _assets[j].weight = j == _kEtf ? 1.0 : 0.0;
      }
    });
    _spawnFx(_assets[_kEtf].color, count: 12, speed: 110);
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

// ─── HUD painter: value, diversification gauge, 3-line chart, market strip ──
class _HudPainter extends CustomPainter {
  final _PortfolioGameState s;
  _HudPainter(this.s) : super(repaint: s._ctrl);

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
    final topH = 56.0;
    final stripH = 40.0;
    final chartTop = topH + 6;
    final chartBottom = size.height - stripH - 6;
    final chartRect = Rect.fromLTRB(
        pad, chartTop, size.width - pad, chartBottom);

    _paintHeader(canvas, Size(size.width, topH), pad);
    _paintChart(canvas, chartRect);
    _paintMarketStrip(
        canvas,
        Rect.fromLTRB(pad, size.height - stripH, size.width - pad, size.height));
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
    vp.paint(canvas, Offset(pad, 6));

    final deltaPct = (s._value / _kStartValue - 1) * 100;
    GameFx.text(
      canvas,
      '${deltaPct >= 0 ? '▲' : '▼'} ${deltaPct.abs().toStringAsFixed(1)}%',
      Offset(pad + vp.width + 36, 6 + vp.height / 2),
      13,
      col,
      weight: FontWeight.w800,
    );
    GameFx.text(canvas, 'PORTFOLIO', Offset(pad + 30, 6 + vp.height + 8), 8,
        Potatuhs.textFaint);

    // Diversification gauge (right-aligned).
    final d = s._diversification;
    final gw = (size.width * 0.42).clamp(120.0, 240.0);
    final gx = size.width - pad - gw;
    final gy = 18.0;
    final track = Rect.fromLTWH(gx, gy, gw, 9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(track, const Radius.circular(5)),
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
    final fillCol =
        Color.lerp(const Color(0xFFEF5350), const Color(0xFF66BB6A), d)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(gx, gy, gw * d.clamp(0.04, 1.0), 9),
          const Radius.circular(5)),
      Paint()..color = fillCol,
    );
    final word = d < 0.34
        ? 'CONCENTRATED'
        : (d < 0.67 ? 'BALANCED' : 'DIVERSIFIED');
    final wp = TextPainter(
      text: TextSpan(text: word, style: Potatuhs.label(size: 9, color: fillCol)),
      textDirection: TextDirection.ltr,
    )..layout();
    wp.paint(canvas, Offset(size.width - pad - wp.width, gy - 13));
    GameFx.text(canvas, 'RISK SPREAD', Offset(gx + 38, gy + 18), 7,
        Potatuhs.textFaint);

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
