import 'dart:math';

import 'package:flutter/material.dart';

import '../../mini_game.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Count Forever  (BioScale.infinities)
//
// SELF-CONTAINED MODULE. This game depends only on the framework session
// ([MiniGameSession]) — no shared per-game helpers, no megafile. An agent can
// rebuild this game by editing only this folder.
//
// CORE LOOP — orchestrated, deterministic escalation (no random penalties):
//   • Tap to count up. Every tap always *progresses* you toward the next tier,
//     even if the shared world toggle is currently pushing your number down.
//   • TIER 1 @ 10 climbs : auto-granted AUTO-CLICKER — a helper taps 1/sec.
//   • TIER 2 @ 30 climbs : CHOOSE faster helper (×2/sec) OR +1 per tap.
//   • TIER 3 @ 50 climbs : CHOOSE faster helper, OR more per tap, OR
//                          FLIP THE WORLD (toggle the shared up/down direction
//                          for everyone) + an instant bonus to you.
//   • Later tiers escalate (doubling helper / tap value, bigger bonuses).
//
// THE DISRUPTION FACET — the shared up/down direction ([CountDirection]).
//   Flipping it makes *everyone's* taps subtract until it's flipped back;
//   concurrent flips resolve by parity. In Phase 1 this is a LOCAL direction;
//   the [CountDirection] seam lets the host swap in an AI-driven (solo) or
//   networked (party) implementation later WITHOUT touching game logic.
// ═══════════════════════════════════════════════════════════════════════════

// ── Feel constants — tune here without touching logic ──────────────────────
/// Base auto-clicker rate granted at tier 1 (clicks/sec).
const int _kBaseAutoRate = 1;

/// Seconds a player has to pick at a tier before the first (safe) option is
/// auto-chosen. The host clock keeps running during selection — decide fast.
const double _kPickTimeout = 5.0;

/// Seconds the upgrade menu stays NON-selectable after it appears. Players tap
/// rapidly to count up; without this guard, an in-flight tap lands on whatever
/// card spawns under the finger and instantly picks an upgrade they never read.
/// During this window cards are dimmed and ignore taps.
const double _kPickArmDelay = 0.5;

/// Particles spawned per manual tap / per tier-up burst.
const int _kTapParticles = 5;
const int _kTierParticles = 64;

/// Accent — matches the Count Forever catalog entry.
const Color _kAccent = Color(0xFF5C6BC0);

// ═══════════════════════════════════════════════════════════════════════════
// Shared direction seam — the disruption facet, swappable per transport.
// ═══════════════════════════════════════════════════════════════════════════

/// A shared up/down direction that the disruption mechanic flips. When
/// [reversed] is true, taps subtract instead of add. [flip] toggles it.
///
/// Phase 1 uses [LocalCountDirection]. A later AI-driven (solo) or networked
/// (party) implementation can back this so a flip crosses players; concurrent
/// flips naturally resolve by parity (two toggles cancel out).
abstract class CountDirection extends ChangeNotifier {
  bool get reversed;
  void flip();
}

/// Local, single-player direction. Flipping affects only this client.
class LocalCountDirection extends CountDirection {
  bool _reversed = false;
  @override
  bool get reversed => _reversed;
  @override
  void flip() {
    _reversed = !_reversed;
    notifyListeners();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Upgrade offers
// ═══════════════════════════════════════════════════════════════════════════

enum _OfferKind {
  fasterHelper, // grant / double the auto-clicker rate
  plusPerTap,   // +1 to tap value
  doublePerTap, // ×2 tap value (late game)
  flipWorld,    // toggle the shared direction + bonus to you (the disrupt option)
  burst,        // instant bonus to your count
}

/// One selectable upgrade at a tier. Built dynamically so labels reflect the
/// player's CURRENT stats ("2/s → 4/s").
class _Offer {
  final _OfferKind kind;
  final String emoji;
  final String label;
  final String desc;
  final int payload; // bonus amount for flipWorld / burst; 0 otherwise
  const _Offer(this.kind, this.emoji, this.label, this.desc, [this.payload = 0]);
}

/// Active, permanent player modifiers.
class _Mods {
  int autoRate = 0; // helper clicks/sec (0 = no helper yet)
  int tapValue = 1; // count produced per click (manual or helper)

  List<String> labels() {
    final out = <String>[];
    if (autoRate > 0) out.add('HELPER $autoRate/s');
    if (tapValue > 1) out.add('×$tapValue / TAP');
    return out;
  }
}

// ── Lightweight, self-contained juice types ────────────────────────────────
class _Particle {
  double x, y, vx, vy, life, maxLife, radius;
  Color color;
  _Particle(this.x, this.y, this.vx, this.vy, this.life, this.color, this.radius)
      : maxLife = life;
}

class _Pop {
  double x, y, life, maxLife;
  final String text;
  final Color color;
  _Pop(this.x, this.y, this.text, this.color, double life)
      : life = life,
        maxLife = life;
}

// ═══════════════════════════════════════════════════════════════════════════
// Widget
// ═══════════════════════════════════════════════════════════════════════════

class CountForeverGame extends StatefulWidget {
  final MiniGameSession session;

  /// Shared direction source. Defaults to a local one; the host can inject an
  /// AI-driven or networked implementation to make the toggle cross players.
  final CountDirection? direction;

  const CountForeverGame({Key? key, required this.session, this.direction})
      : super(key: key);

  @override
  State<CountForeverGame> createState() => _CountForeverGameState();
}

class _CountForeverGameState extends State<CountForeverGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final CountDirection _dir;
  final Random _rng = Random();
  final _Mods _mods = _Mods();

  MiniGameSession get _session => widget.session;

  // ── Tier progression ──
  // Monotonic "effort" — every click (manual OR helper) adds tapValue here.
  // Tiers fire off this, so tapping ALWAYS advances you even when the world is
  // flipped and your visible score is dropping. This is the core fix: progress
  // can never be taken away by a disruption.
  double _climb = 0;
  int _tier = 0;
  late final List<int> _thresholds = _buildThresholds();

  // ── Tier choice overlay ──
  bool _choosing = false;
  List<_Offer> _choices = const [];
  double _pickTimer = 0;
  // Counts down while the freshly-opened menu is still locked (see
  // [_kPickArmDelay]). Cards only become tappable once this reaches 0.
  double _pickArm = 0;

  // ── Juice ──
  double _bgHue = 230;
  double _digitBounce = 0;
  double _shockRadius = 0;
  double _shockAlpha = 0;
  double _autoAccum = 0;
  final List<_Particle> _particles = [];
  final List<_Pop> _pops = [];

  @override
  void initState() {
    super.initState();
    _dir = widget.direction ?? LocalCountDirection();
    _dir.addListener(_onDirChanged);
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _dir.removeListener(_onDirChanged);
    if (widget.direction == null) _dir.dispose(); // only dispose ones we made
    super.dispose();
  }

  void _onDirChanged() {
    if (!mounted) return;
    setState(() {
      _spawnPop(_dir.reversed ? 'WORLD FLIPPED ↓' : 'WORLD RESTORED ↑',
          _dir.reversed ? Colors.redAccent : Colors.greenAccent,
          big: true);
    });
  }

  // ── Tier thresholds: 10, 30, 50, then growing gaps (×1.4) ────────────────
  static List<int> _buildThresholds() {
    final list = <int>[10, 30, 50];
    int last = 50;
    double gap = 30;
    while (list.length < 30) {
      last += gap.round();
      list.add(last);
      gap *= 1.4;
    }
    return list;
  }

  int _thresholdForTier(int tier) =>
      tier <= _thresholds.length ? _thresholds[tier - 1] : _thresholds.last;

  // ── Per-frame tick (juice + auto-clicker) ────────────────────────────────
  void _tick() {
    const double dt = 1 / 60.0;
    setState(() {
      // Auto-clicker — only while the round is live.
      if (_session.isRunning && _mods.autoRate > 0) {
        _autoAccum += _mods.autoRate * dt;
        while (_autoAccum >= 1.0) {
          _autoAccum -= 1.0;
          _applyClick(isAuto: true);
        }
      }

      // Pick countdown (host clock keeps running — there's real time pressure).
      if (_choosing) {
        // Hold the menu locked for a beat so an in-flight rapid tap can't
        // auto-select a card the instant it appears.
        if (_pickArm > 0) _pickArm = max(0, _pickArm - dt);
        _pickTimer -= dt;
        if (_pickTimer <= 0) {
          _applyOffer(_choices.first); // auto-pick the safe (first) option
          _choosing = false;
        }
      }

      // Shockwave.
      if (_shockAlpha > 0) {
        _shockRadius += 200 * dt;
        _shockAlpha = max(0, _shockAlpha - dt * 2.5);
      }
      _digitBounce *= 0.88;

      // Background drift — accelerates as you climb tiers.
      _bgHue = (_bgHue + dt * (3 + _tier * 0.6)) % 360;

      for (final p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.vy += 60 * dt;
        p.life -= dt;
      }
      _particles.removeWhere((p) => p.life <= 0);

      for (final p in _pops) {
        p.y -= 28 * dt;
        p.life -= dt;
      }
      _pops.removeWhere((p) => p.life <= 0);
    });
  }

  // ── Apply one click (manual or helper) ───────────────────────────────────
  void _applyClick({bool isAuto = false}) {
    if (!_session.isRunning) return;
    final v = _mods.tapValue;

    // Effort always counts toward the next tier — direction can't undo it.
    _climb += v;

    // Score moves with the shared world direction. addScore clamps at 0, so a
    // flipped world floors you at zero rather than going negative.
    _session.addScore(_dir.reversed ? -v : v);

    if (!isAuto) {
      _shockRadius = 0;
      _shockAlpha = 0.45;
      _digitBounce = 1.0;
      _spawnTapParticles();
    } else {
      // The helper used to tick the number up invisibly. Give it a soft visible
      // heartbeat so a game literally called "Count Forever" feels alive while
      // the auto-clicker works — a faint bounce + a single drifting mote.
      _digitBounce = max(_digitBounce, 0.3);
      _spawnAutoParticle();
    }
    _maybeTier();
  }

  void _maybeTier() {
    if (_choosing) return;
    if (_climb >= _thresholdForTier(_tier + 1)) _fireTier();
  }

  void _fireTier() {
    _tier++;
    _spawnTierBurst();
    if (_tier == 1) {
      // Pure gift — the auto-clicker. No choice, no downside.
      _mods.autoRate = _kBaseAutoRate;
      _spawnPop('🤖 AUTO-CLICKER!', Colors.amberAccent, big: true);
      return;
    }
    _choices = _offersForTier(_tier);
    _pickTimer = _kPickTimeout;
    _pickArm = _kPickArmDelay;
    _choosing = true;
  }

  // ── Build the menu for a tier. Every option is a real upgrade; the only
  //    "risk" is the deliberate FLIP THE WORLD gamble (and it pays you a bonus).
  List<_Offer> _offersForTier(int tier) {
    final nextAuto = _mods.autoRate <= 0 ? _kBaseAutoRate : _mods.autoRate * 2;
    final faster = _Offer(
      _OfferKind.fasterHelper,
      '⚡',
      _mods.autoRate <= 0 ? 'GET A HELPER' : 'FASTER HELPER',
      _mods.autoRate <= 0
          ? 'A helper clicks $nextAuto/sec'
          : 'Helper ${_mods.autoRate}/s → $nextAuto/s',
    );
    final plus = _Offer(
      _OfferKind.plusPerTap,
      '👆',
      '+1 PER TAP',
      'Each click ${_mods.tapValue} → ${_mods.tapValue + 1}',
    );
    final dbl = _Offer(
      _OfferKind.doublePerTap,
      '✊',
      'DOUBLE TAP',
      'Each click ${_mods.tapValue} → ${_mods.tapValue * 2}',
    );
    // Flip bonus: 100 at tier 3, doubling each later tier.
    final flipBonus = 100 * (1 << max(0, tier - 3));
    final flip = _Offer(
      _OfferKind.flipWorld,
      '🔃',
      'FLIP THE WORLD',
      'Flip everyone\'s direction  •  +$flipBonus to you',
      flipBonus,
    );
    final burstAmt = 50 * (tier - 2);
    final burst = _Offer(
      _OfferKind.burst,
      '🎁',
      'INSTANT BONUS',
      '+$burstAmt to your count now',
      burstAmt,
    );

    switch (tier) {
      case 2:
        return [faster, plus];
      case 3:
        return [faster, plus, flip];
      default:
        // Tier 4+ : escalate — doubling tap value, bigger flip bonus, a burst.
        return [faster, dbl, flip, burst];
    }
  }

  void _applyOffer(_Offer o) {
    switch (o.kind) {
      case _OfferKind.fasterHelper:
        _mods.autoRate = _mods.autoRate <= 0 ? _kBaseAutoRate : _mods.autoRate * 2;
        break;
      case _OfferKind.plusPerTap:
        _mods.tapValue += 1;
        break;
      case _OfferKind.doublePerTap:
        _mods.tapValue *= 2;
        break;
      case _OfferKind.burst:
        _session.addScore(o.payload); // a reward — always adds, ignores flip
        _spawnPop('+${o.payload}!', Colors.greenAccent, big: true);
        break;
      case _OfferKind.flipWorld:
        _dir.flip(); // the disruption — direction change pops via _onDirChanged
        _session.addScore(o.payload); // your bribe for flipping on everyone
        _spawnPop('+${o.payload}!', Colors.cyanAccent, big: true);
        break;
    }
  }

  // ── Input ─────────────────────────────────────────────────────────────────
  void _onTap() {
    if (_choosing || !_session.isRunning) return;
    setState(() => _applyClick());
  }

  void _onPick(_Offer o) {
    // Ignore taps while the menu is still locked — prevents accidental picks
    // from a tap that was already on its way down when the menu opened.
    if (_pickArm > 0) return;
    setState(() {
      _applyOffer(o);
      _choosing = false;
    });
  }

  // ── Juice spawners ─────────────────────────────────────────────────────────
  void _spawnTapParticles() {
    for (int i = 0; i < _kTapParticles; i++) {
      _particles.add(_Particle(
        (_rng.nextDouble() - 0.5) * 80,
        (_rng.nextDouble() - 0.5) * 50,
        (_rng.nextDouble() - 0.5) * 80,
        -40 - _rng.nextDouble() * 60,
        0.55,
        HSVColor.fromAHSV(1, (_bgHue + _rng.nextDouble() * 40 - 20) % 360, 0.7, 1).toColor(),
        2.5 + _rng.nextDouble() * 2,
      ));
    }
  }

  /// One small, short-lived mote per auto-click — the helper's visible pulse.
  /// Kept to a single particle so even an 8/sec helper never spams the field.
  void _spawnAutoParticle() {
    _particles.add(_Particle(
      (_rng.nextDouble() - 0.5) * 50,
      (_rng.nextDouble() - 0.5) * 30,
      (_rng.nextDouble() - 0.5) * 40,
      -30 - _rng.nextDouble() * 30,
      0.4,
      HSVColor.fromAHSV(0.8, (_bgHue + _rng.nextDouble() * 30 - 15) % 360, 0.5, 1)
          .toColor(),
      1.6 + _rng.nextDouble() * 1.2,
    ));
  }

  void _spawnTierBurst() {
    for (int i = 0; i < _kTierParticles; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      final s = 100 + _rng.nextDouble() * 200;
      _particles.add(_Particle(
        0, 0, cos(a) * s, sin(a) * s - 60, 1.4,
        HSVColor.fromAHSV(1, _rng.nextDouble() * 360, 0.9, 1).toColor(),
        3.5 + _rng.nextDouble() * 4,
      ));
    }
  }

  void _spawnPop(String text, Color color, {bool big = false}) {
    _pops.add(_Pop(
      (_rng.nextDouble() - 0.5) * 80,
      -20 - _rng.nextDouble() * 30,
      text,
      color,
      big ? 1.4 : 0.9,
    ));
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bg = HSVColor.fromAHSV(1, _bgHue, 0.18, 0.05).toColor();
    final reversed = _dir.reversed;
    final score = _session.score;

    return LayoutBuilder(builder: (context, c) {
      final cx = c.maxWidth / 2;
      final cy = c.maxHeight * 0.40;
      final toNext = max(0, _thresholdForTier(_tier + 1) - _climb.floor());

      return GestureDetector(
        onTapDown: (_choosing || !_session.isRunning) ? null : (_) => _onTap(),
        child: Container(
          color: bg,
          child: Stack(
            children: [
              // Tier readout.
              Positioned(
                top: 8,
                left: 14,
                child: Text(
                  _tier == 0
                      ? 'TIER 0  •  helper in $toNext'
                      : 'TIER $_tier  •  next in $toNext',
                  style: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 11,
                    color: _kAccent.withValues(alpha: 0.8),
                  ),
                ),
              ),

              // Shockwave.
              if (_shockAlpha > 0)
                Positioned(
                  left: cx - _shockRadius,
                  top: cy - _shockRadius,
                  child: IgnorePointer(
                    child: Container(
                      width: _shockRadius * 2,
                      height: _shockRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: HSVColor.fromAHSV(
                                  _shockAlpha.clamp(0.0, 1.0), _bgHue, 0.6, 1)
                              .toColor(),
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                ),

              // Particles.
              ..._particles.map((p) => Positioned(
                    left: cx + p.x - p.radius,
                    top: cy + p.y - p.radius,
                    child: IgnorePointer(
                      child: Container(
                        width: p.radius * 2,
                        height: p.radius * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.color.withValues(
                              alpha: (p.life / p.maxLife).clamp(0.0, 1.0)),
                        ),
                      ),
                    ),
                  )),

              // The big number — FittedBox so it NEVER overflows, any length.
              Positioned(
                left: 24,
                right: 24,
                top: cy - 90,
                height: 180,
                child: IgnorePointer(
                  child: Transform.scale(
                    scaleY: (1.0 + _digitBounce * 0.25).clamp(0.7, 1.5),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$score',
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 140,
                          fontWeight: FontWeight.w900,
                          color: reversed
                              ? Colors.redAccent.withValues(alpha: 0.92)
                              : HSVColor.fromAHSV(0.92, _bgHue, 0.25, 1).toColor(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Floating pops.
              ..._pops.map((p) => Positioned(
                    left: cx + p.x - 90,
                    top: cy + p.y,
                    width: 180,
                    child: IgnorePointer(
                      child: Text(
                        p.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: p.color.withValues(
                              alpha: (p.life / p.maxLife).clamp(0.0, 1.0)),
                        ),
                      ),
                    ),
                  )),

              // Active modifiers strip.
              Positioned(
                bottom: 96,
                left: 8,
                right: 8,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final l in _mods.labels())
                      _chip(l, Colors.white70),
                    if (reversed) _chip('↓ FLIPPED', Colors.redAccent),
                  ],
                ),
              ),

              // Tap prompt.
              Positioned(
                bottom: 44,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    reversed ? 'WORLD FLIPPED — taps count DOWN' : 'TAP to count up',
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 13,
                      color: (reversed ? Colors.redAccent : Colors.white)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),

              if (_choosing) _buildChoiceOverlay(),
            ],
          ),
        ),
      );
    });
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: TextStyle(fontFamily: 'Avenir', fontSize: 10, color: color)),
      );

  // ── Tier choice overlay ───────────────────────────────────────────────────
  Widget _buildChoiceOverlay() {
    final frac = (_pickTimer / _kPickTimeout).clamp(0.0, 1.0);
    final armed = _pickArm <= 0;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.82),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                armed ? 'TIER $_tier  —  PICK AN UPGRADE' : 'GET READY…',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: armed ? _kAccent : Colors.white38,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: LinearProgressIndicator(
                  value: frac,
                  minHeight: 3,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(
                    Color.lerp(Colors.redAccent, Colors.greenAccent, frac)!,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final o in _choices) ...[
                        _OfferCard(
                            offer: o,
                            enabled: armed,
                            onTap: () => _onPick(o)),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final _Offer offer;
  final VoidCallback onTap;
  final bool enabled;
  const _OfferCard(
      {required this.offer, required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final isFlip = offer.kind == _OfferKind.flipWorld;
    final accent = isFlip ? Colors.orangeAccent : _kAccent;
    // While locked, the card dims and swallows taps via onTap (a press still
    // can't fire a selection — the parent also guards on _pickArm).
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: GestureDetector(
        // Use onTap (fires on release) rather than onTapDown while locked, and
        // ignore the press entirely until armed.
        onTap: enabled ? onTap : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: accent.withValues(alpha: 0.10),
            border:
                Border.all(color: accent.withValues(alpha: 0.55), width: 1.4),
          ),
        child: Row(
          children: [
            Text(offer.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.label,
                    style: const TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    offer.desc,
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 12,
                      height: 1.25,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
