// MarketSim — the MARKET half of Market Trader, extracted from the widget so
// it can be (a) seeded and (b) run by exactly ONE authority per room. In a
// shared game the host runs the only sim and publishes its tape; joiners never
// step price locally (see market_feed.dart / ONLINE.md). Flutter-free on
// purpose: dart:math only, so it can be unit-tested and host-run headlessly.
//
// Behavior is a verbatim extraction of the widget's former trend/news/price
// logic — same constants, same step order, same clamps.
import 'dart:math';

// --- Market tuning (moved verbatim from market_trader.dart) -----------------
const double kMtStartingPrice  = 100.0;
const double kMtGameDuration   = 60.0; // seconds (mirrors host clock)
const double kMtBaseTickHz     = 12.0;
const double kMtMaxTickHz      = 30.0;
const double kMtBaseVolatility = 1.8;
const double kMtMaxVolatility  = 9.0;
const double kMtTrendDuration  = 4.0;
const double kMtNewsDuration   = 1.5;
const double kMtNewsChance     = 0.08;
const double kMtNewsAmplitude  = 14.0;

// --- Player market-event tuning ---
const double kMtEventImpulse   = 22.0;
const double kMtEventDuration  = 2.5;
const double kMtEventCooldown  = 14.0;

/// An active market impulse: organic headline or a purchased player event.
/// [by] is the uid of the player who bought it (null = organic news) — the
/// shared-market banner attributes rival events with it. [eventIdx] is the
/// kMtEvents index for player events (null = organic) — clients sync their
/// local cooldown rings off it so a shared event cools the button room-wide.
class MtNews {
  final String headline;
  final double impulse;
  final String? by;
  final int? eventIdx;
  double ttl;
  MtNews(this.headline, this.impulse, this.ttl, {this.by, this.eventIdx});
}

class MtEventDef {
  final String label;
  final String emoji;
  final double sign;
  const MtEventDef(this.label, this.emoji, this.sign);
}

const List<MtEventDef> kMtEvents = [
  MtEventDef('Drought',   '☀️',  1.0),
  MtEventDef('Flooding',  '🌊',  1.0),
  MtEventDef('Tornado',   '🌪️',  1.0),
  MtEventDef('Quake',     '⚡',  1.0),
  MtEventDef('Recession', '📉', -1.0),
  MtEventDef('Abundance', '🌾', -1.0),
];

/// The price walk: random trend regimes + noise + news/event impulses, with
/// volatility and tick rate ramping over the round. Deterministic for a given
/// (seed, dt stream, event stream).
class MarketSim {
  MarketSim({required int seed, this.duration = kMtGameDuration})
      : _rng = Random(seed);

  final Random _rng;
  final double duration;

  double elapsed = 0.0; // sim-time seconds stepped so far (drives the ramp)
  double price = kMtStartingPrice;
  /// Lowest price touched during the most recent [step] call — order fills
  /// check this so an intra-frame dip through a limit still fills.
  double low = kMtStartingPrice;

  MtNews? news;
  double _trend      = 0.0;
  double _trendTimer = 0.0;
  double _priceClock = 0.0;
  double _newsTimer  = 0.0;

  double get _ramp => (elapsed / duration).clamp(0.0, 1.0);
  double get volatility =>
      kMtBaseVolatility + (kMtMaxVolatility - kMtBaseVolatility) * _ramp;
  double get tickHz => kMtBaseTickHz + (kMtMaxTickHz - kMtBaseTickHz) * _ramp;

  /// Advance the market by [dt] seconds. Returns true when something DISCRETE
  /// changed (news started or ended) that the desk should rebuild for.
  bool step(double dt) {
    if (dt <= 0) return false;
    elapsed += dt;
    bool dirty = false;

    _trendTimer -= dt;
    if (_trendTimer <= 0) {
      _trend      = (_rng.nextDouble() * 2 - 1);
      _trendTimer = kMtTrendDuration * (0.6 + _rng.nextDouble() * 0.8);
      if (news == null && _rng.nextDouble() < kMtNewsChance) {
        _spawnNews();
        dirty = true;
      }
    }

    if (news != null) {
      _newsTimer -= dt;
      if (_newsTimer <= 0) {
        news = null;
        dirty = true;
      }
    }

    _priceClock += dt * tickHz;
    final steps = _priceClock.floor();
    _priceClock -= steps;
    low = price;
    for (int s = 0; s < steps; s++) {
      _stepPrice();
      if (price < low) low = price;
    }
    return dirty;
  }

  void _stepPrice() {
    final vol   = volatility;
    final drift = _trend * vol * 0.35;
    final noise = (_rng.nextDouble() * 2 - 1) * vol;
    double impulse = 0;
    final n = news;
    if (n != null) impulse = n.impulse * 0.5;
    price = (price + drift + noise + impulse).clamp(10.0, 9999.0);
  }

  void _spawnNews() {
    final positive = _rng.nextBool();
    final headlines = positive
        ? ['STRONG EARNINGS', 'UPGRADE: BUY', 'SHORT SQUEEZE!', 'BULLISH DATA']
        : ['EARNINGS MISS', 'FED HIKE FEAR', 'SELL-OFF WAVE', 'MARGIN CALLS'];
    final impulse = (positive ? 1 : -1) *
        (kMtNewsAmplitude * (0.7 + _rng.nextDouble() * 0.6));
    news = MtNews(
      headlines[_rng.nextInt(headlines.length)],
      impulse,
      kMtNewsDuration,
    );
    _newsTimer  = kMtNewsDuration;
    _trend      = positive ? 0.9 : -0.9;
    _trendTimer = kMtNewsDuration;
  }

  /// A purchased player event (Drought/…): strong sustained impulse + trend
  /// shove. The DESK owns cost/cooldown gating; the sim just moves the market.
  void applyPlayerEvent(int idx, {String? by}) {
    final ev = kMtEvents[idx];
    news = MtNews(
      ev.label.toUpperCase(),
      ev.sign * kMtEventImpulse,
      kMtEventDuration,
      by: by,
      eventIdx: idx,
    );
    _newsTimer  = kMtEventDuration;
    _trend      = ev.sign * 0.95;
    _trendTimer = kMtEventDuration;
  }
}
