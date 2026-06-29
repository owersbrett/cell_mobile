import 'dart:math' as math;

/// One curve in the "Area Under" bank: a function `f` over the closed interval
/// `[a, b]`, with its **exact signed area** (the definite integral) and the
/// y-range needed to plot it. The true area is computed once, at construction,
/// with a very fine midpoint sum (20k subdivisions) — accurate to display
/// precision, so the game can score against it without an analytic antiderivative.
///
/// `signed == true` means the curve dips below the x-axis somewhere on `[a, b]`,
/// so part of the region counts as **negative** area — the signed-area twist.
class AreaCurve {
  /// Pretty label, e.g. `f(x) = x²`.
  final String label;

  /// Interval endpoints (a < b).
  final double a;
  final double b;

  /// The function itself.
  final double Function(double x) f;

  /// Difficulty tier: 0 gentle/positive · 1 curvier/positive · 2 signed (dips below).
  final int tier;

  /// True if the curve goes below the x-axis on [a, b] (signed area in play).
  final bool signed;

  /// Exact signed area on [a, b] = ∫ₐᵇ f(x) dx (precomputed, very fine).
  final double trueArea;

  /// Min / max of f over [a, b], each pulled toward 0 so the axis is always
  /// visible. Used only for plot scaling.
  final double yLo;
  final double yHi;

  const AreaCurve({
    required this.label,
    required this.a,
    required this.b,
    required this.f,
    required this.tier,
    required this.signed,
    required this.trueArea,
    required this.yLo,
    required this.yHi,
  });
}

/// Build one curve, computing its exact area and plot bounds from `f`.
AreaCurve _mk(
  String label,
  double a,
  double b,
  double Function(double) f,
  int tier,
) {
  // Exact signed area via a very fine midpoint sum.
  const n = 20000;
  final w = (b - a) / n;
  var area = 0.0;
  for (var i = 0; i < n; i++) {
    area += f(a + (i + 0.5) * w) * w;
  }

  // Plot bounds — sample densely, then clamp the window to include y = 0.
  var lo = 0.0;
  var hi = 0.0;
  const samples = 400;
  for (var i = 0; i <= samples; i++) {
    final y = f(a + (b - a) * i / samples);
    if (y < lo) lo = y;
    if (y > hi) hi = y;
  }

  return AreaCurve(
    label: label,
    a: a,
    b: b,
    f: f,
    tier: tier,
    signed: lo < -1e-6,
    trueArea: area,
    yLo: lo,
    yHi: hi,
  );
}

/// The midpoint Riemann sum of `c` with `n` rectangles — the player's running
/// estimate. The *exact* area is the limit of this sum as `n → ∞`.
double riemannMidpoint(AreaCurve c, int n) {
  if (n < 1) n = 1;
  final w = (c.b - c.a) / n;
  var s = 0.0;
  for (var i = 0; i < n; i++) {
    s += c.f(c.a + (i + 0.5) * w) * w;
  }
  return s;
}

/// The full curve bank, grouped (loosely) by tier. Built once and cached.
List<AreaCurve>? _bank;

List<AreaCurve> buildAreaCurveBank() {
  return _bank ??= [
    // ── Tier 0 — gentle, strictly positive ──────────────────────────────────
    _mk('f(x) = x²', 0, 3, (x) => x * x, 0),
    _mk('f(x) = 4 − x²', -2, 2, (x) => 4 - x * x, 0),
    _mk('f(x) = sin x', 0, math.pi, (x) => math.sin(x), 0),
    _mk('f(x) = ½x + 1', 0, 4, (x) => 0.5 * x + 1, 0),

    // ── Tier 1 — curvier, still positive ────────────────────────────────────
    _mk('f(x) = x³', 0, 2, (x) => x * x * x, 1),
    _mk('f(x) = 3 + 2 sin x', 0, 2 * math.pi, (x) => 3 + 2 * math.sin(x), 1),
    _mk('f(x) = ½x² + 1', 0, 4, (x) => 0.5 * x * x + 1, 1),
    _mk('f(x) = 6 − (x − 2)²', 0, 4, (x) => 6 - (x - 2) * (x - 2), 1),

    // ── Tier 2 — dips below the axis (signed area) ──────────────────────────
    _mk('f(x) = x² − 2', 0, 3, (x) => x * x - 2, 2),
    _mk('f(x) = sin x', 0, 3 * math.pi / 2, (x) => math.sin(x), 2),
    _mk('f(x) = (x−1)(x−2)', 0, 3, (x) => (x - 1) * (x - 2), 2),
    _mk('f(x) = x³ − 4x', -1, 2, (x) => x * x * x - 4 * x, 2),
  ];
}
