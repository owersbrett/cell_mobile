// MarketFeed — the seam between the trading DESK (the widget: wallet, orders,
// P&L, FX) and the MARKET (price + news). The game reads a feed and never
// knows whether the market is local or shared (ONLINE.md):
//
//   • LocalMarketFeed — solo / no room: wraps a private MarketSim. Today's
//     behavior, verbatim.
//   • HostMarketFeed / NetMarketFeed (market_net.dart) — shared room: the
//     host's sim is the one market; joiners render its published tape.
//
// Wallets, orders and P&L stay in the desk in every mode — only the price
// path and events flow through here.
import 'market_sim.dart';

abstract class MarketFeed {
  /// Live price the desk trades at.
  double get price;

  /// Lowest price touched since the previous [step] — limit fills check this
  /// so an intra-frame dip through a limit still fills.
  double get low;

  /// Active impulse (organic headline or player event), null when calm.
  MtNews? get news;

  /// True when the market authority is gone (shared rooms only): the desk
  /// locks trading and shows the halt banner. Always false locally.
  bool get halted;

  /// Advance/interpolate by [dt] seconds. Returns true when something
  /// discrete changed (news started/ended, halt flipped) that needs an
  /// immediate widget rebuild.
  bool step(double dt);

  /// Fire the player market event [idx]. The DESK gates cost + local
  /// cooldown before calling; the feed moves the market (locally, or by
  /// routing the intent to the host).
  void fireEvent(int idx);

  void dispose();
}

/// The solo market: a private, seeded sim. Identical to the pre-extraction
/// in-widget market.
class LocalMarketFeed implements MarketFeed {
  LocalMarketFeed(this.sim);

  final MarketSim sim;

  @override
  double get price => sim.price;

  @override
  double get low => sim.low;

  @override
  MtNews? get news => sim.news;

  @override
  bool get halted => false;

  @override
  bool step(double dt) => sim.step(dt);

  @override
  void fireEvent(int idx) => sim.applyPlayerEvent(idx);

  @override
  void dispose() {}
}
