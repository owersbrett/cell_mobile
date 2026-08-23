import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../games/mini_game.dart';
import '../../games/mini_game_registry.dart';
import '../../models/bio_entity.dart';
import '../../theme/hpg_kit.dart';
import '../../theme/potatuhs.dart';
import '../net/party_transport.dart' show NetPlayer;
import '../screens/party_dialogue.dart';
import 'madness_categories.dart';
import 'madness_dialogue.dart';
import 'madness_net.dart';

/// The MADNESS spin phase: the round's spinner drives three wheels in a row —
/// CATEGORY (7 fat groups), then SCALE within it, then GAME within that —
/// and confirms. Every landing BROADCASTS (meta spin fields), so all devices
/// ride along: spectators' wheels whoosh onto the same segment the spinner
/// called, the breadcrumb fills in progressively, and the next wheel drifts
/// for everyone when the spinner advances.
///
/// SPIN-DRIVES LAW (Brett 2026-07-17): the wheel DRIFTS slowly until the
/// spinner fires SPIN — the button always says SPIN, never STOP. The segment
/// under the 3-o'clock pointer at the press is the outcome (skill: fire when
/// your pick is at the pointer), played back as a full spin-up that runs
/// extra revolutions and lands on the call. Nothing auto-advances for the
/// spinner (PARTY UX LAW).
///
/// Wedges carry NUMBERS (money-wheel legible at speed); the legend under the
/// wheel maps each number to its name and highlights the landed one.
///
/// On round 1 the opening ceremony plays over the top first — a rules board
/// that holds all the information while the hosts banter across it.
class MadnessSpinView extends StatefulWidget {
  final MadnessNet net;
  const MadnessSpinView({super.key, required this.net});

  @override
  State<MadnessSpinView> createState() => _MadnessSpinViewState();
}

enum _SpinStage {
  category,
  categoryLanded,
  scale,
  scaleLanded,
  game,
  gameLanded,
  sent,
}

class _MadnessSpinViewState extends State<MadnessSpinView>
    with TickerProviderStateMixin {
  late final AnimationController _spin; // slow drift while waiting for SPIN
  late final AnimationController _landing; // the fired spin-up + landing
  late final AnimationController _fx; // light chase / pulse clock

  _SpinStage _stage = _SpinStage.category;
  int _landedIndex = 0;
  double _angleAtStop = 0;
  double _landingTarget = 0;
  MadnessCategory? _category; // wheel #1's outcome
  BioScale? _scale; // wheel #2's outcome
  MiniGameSpec? _game; // wheel #3's outcome
  bool _ceremonyDismissed = false;
  int _ceremonyPage = 0;

  static const double _kTwoPi = 2 * math.pi;

  MadnessNet get net => widget.net;

  @override
  void initState() {
    super.initState();
    // DRIFT, not a live spin: slow enough to aim at — the spinner fires
    // SPIN when their pick nears the pointer (SPIN-DRIVES LAW).
    _spin = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 9000))
      ..repeat();
    // The fired spin: accelerate through extra revolutions, land on the call.
    _landing = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) setState(() {});
      });
    // Bulb chase while drifting/spinning, pulse on the landed wedge.
    _fx = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    // Spectators mirror the spinner's broadcast progress.
    net.addListener(_onNet);
    // Late joiner / rebuild mid-spin: catch up immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onNet());
  }

  @override
  void dispose() {
    net.removeListener(_onNet);
    _spin.dispose();
    _landing.dispose();
    _fx.dispose();
    super.dispose();
  }

  // ------------------------------------------------------- spectator sync

  /// Which wheel a local stage belongs to.
  String _wheelOf(_SpinStage s) => switch (s) {
        _SpinStage.category || _SpinStage.categoryLanded => 'category',
        _SpinStage.scale || _SpinStage.scaleLanded => 'scale',
        _ => 'game',
      };

  void _onNet() {
    if (!mounted) return;
    final m = net.meta;
    if (m == null || m.status != 'spin' || net.isMySpin) return;

    // 1) The spinner advanced to a new wheel → jump there and spin.
    if (m.spinStage != _wheelOf(_stage) || _stage == _SpinStage.sent) {
      setState(() {
        _category = _categoryByName(m.spinCategory);
        _scale = _scaleByName(m.spinScale);
        _stage = switch (m.spinStage) {
          'scale' => _SpinStage.scale,
          'game' => _SpinStage.game,
          _ => _SpinStage.category,
        };
        _spin.value = 0;
      });
      _landing.stop();
      _spin.repeat();
      return;
    }

    // 2) The current wheel landed → decelerate onto the broadcast segment.
    if (_stage == _SpinStage.category ||
        _stage == _SpinStage.scale ||
        _stage == _SpinStage.game) {
      final value = switch (m.spinStage) {
        'category' => m.spinCategory,
        'scale' => m.spinScale,
        _ => m.spinGame,
      };
      if (value.isEmpty) return;
      final idx = _indexForValue(m.spinStage, value);
      if (idx != null) _beginLanding(idx);
    }
  }

  MadnessCategory? _categoryByName(String name) {
    for (final c in kMadnessCategories) {
      if (c.name == name) return c;
    }
    return null;
  }

  BioScale? _scaleByName(String name) {
    for (final s in BioScale.values) {
      if (s.name == name) return s;
    }
    return null;
  }

  int? _indexForValue(String wheel, String value) {
    switch (wheel) {
      case 'category':
        final i = _categories.indexWhere((c) => c.name == value);
        return i < 0 ? null : i;
      case 'scale':
        final i = _scalesInCategory.indexWhere((s) => s.name == value);
        return i < 0 ? null : i;
      default:
        final scale = _scale;
        if (scale == null) return null;
        final i = net.availableGamesFor(scale).indexWhere((g) => g.id == value);
        return i < 0 ? null : i;
    }
  }

  // ----------------------------------------------------------------- wheels

  /// Categories that still hold at least one available game — wheel #1.
  List<MadnessCategory> get _categories {
    final live = net.availableScales.toSet();
    return [
      for (final c in kMadnessCategories)
        if (c.scales.any(live.contains)) c
    ];
  }

  /// The chosen category's still-available scales — wheel #2.
  List<BioScale> get _scalesInCategory {
    final c = _category;
    if (c == null) return const [];
    return [
      for (final s in net.availableScales)
        if (c.scales.contains(s)) s
    ];
  }

  List<_Segment> get _table {
    switch (_stage) {
      case _SpinStage.category:
      case _SpinStage.categoryLanded:
        return [for (final c in _categories) _Segment(c.name)];
      case _SpinStage.scale:
      case _SpinStage.scaleLanded:
        return [
          for (final s in _scalesInCategory)
            _Segment(HpgKit.humanize(s.name).toUpperCase())
        ];
      default:
        final scale = _scale;
        if (scale == null) return const [];
        return [
          for (final g in net.availableGamesFor(scale)) _Segment(g.name)
        ];
    }
  }

  /// The segment under the pointer (3 o'clock) at rotation [angle].
  int _segmentUnderPointer(int count, double angle) {
    if (count == 0) return 0;
    var f = (-angle / _kTwoPi) % 1.0;
    if (f < 0) f += 1.0;
    return (f * count).floor().clamp(0, count - 1);
  }

  /// Angle centering segment [idx] under the pointer.
  double _targetAngle(int count, int idx) =>
      -((idx + 0.5) / count) * _kTwoPi;

  /// The fired spin: whoosh forward through extra revolutions onto [idx] —
  /// shared by the spinner's SPIN press and the spectators' broadcast
  /// landings, so every device sees the same ride.
  void _beginLanding(int idx) {
    final table = _table;
    if (table.isEmpty || _landing.isAnimating) return;
    final angle = _spin.value * _kTwoPi;
    var target = _targetAngle(table.length, idx) % _kTwoPi;
    if (target < 0) target += _kTwoPi;
    // Never reverse — spin UP from the drift, run at least ~3 full turns,
    // and ease onto the call.
    while (target < angle + _kTwoPi * 3.2) {
      target += _kTwoPi;
    }
    setState(() {
      _landedIndex = idx;
      _angleAtStop = angle;
      _landingTarget = target;
      _stage = switch (_stage) {
        _SpinStage.category => _SpinStage.categoryLanded,
        _SpinStage.scale => _SpinStage.scaleLanded,
        _ => _SpinStage.gameLanded,
      };
    });
    _spin.stop();
    _landing.forward(from: 0);
  }

  void _onSpin() {
    if (!net.isMySpin || _landing.isAnimating) return;
    final table = _table;
    if (table.isEmpty) return;
    final idx =
        _segmentUnderPointer(table.length, _spin.value * _kTwoPi);
    // Broadcast the call as it lands so every wheel whooshes together.
    switch (_stage) {
      case _SpinStage.category:
        net.publishSpinEvent('category', _categories[idx].name);
      case _SpinStage.scale:
        net.publishSpinEvent('scale', _scalesInCategory[idx].name);
      default:
        final scale = _scale;
        if (scale != null) {
          net.publishSpinEvent(
              'game', net.availableGamesFor(scale)[idx].id);
        }
    }
    _beginLanding(idx);
  }

  bool get _settled =>
      (_stage == _SpinStage.categoryLanded ||
          _stage == _SpinStage.scaleLanded ||
          _stage == _SpinStage.gameLanded) &&
      !_landing.isAnimating;

  /// The spinner closes a landed wheel — the only way past a result.
  void _continue() {
    if (!_settled || !net.isMySpin) return;
    if (_stage == _SpinStage.categoryLanded) {
      final cats = _categories;
      setState(() {
        _category = cats[_landedIndex.clamp(0, cats.length - 1)];
        _stage = _SpinStage.scale;
        _spin.value = 0;
      });
      net.publishSpinEvent('stage', 'scale');
      _spin.repeat();
    } else if (_stage == _SpinStage.scaleLanded) {
      final scales = _scalesInCategory;
      setState(() {
        _scale = scales[_landedIndex.clamp(0, scales.length - 1)];
        _stage = _SpinStage.game;
        _spin.value = 0;
      });
      net.publishSpinEvent('stage', 'game');
      _spin.repeat();
    } else {
      final scale = _scale;
      if (scale == null) return;
      final games = net.availableGamesFor(scale);
      final game = games[_landedIndex.clamp(0, games.length - 1)];
      setState(() {
        _game = game;
        _stage = _SpinStage.sent;
      });
      net.submitSpin(game.id); // meta flips to 'playing' for everyone
    }
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final spinner = net.currentSpinner;
    final me = net.isMySpin;
    final accent =
        spinner == null ? Potatuhs.gold : Color(spinner.color);
    final showCeremony = !_ceremonyDismissed && net.round == 1;

    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 8),
            Row(children: [
              const SizedBox(width: 16),
              // Never trap a spectator — leaving the room is always possible.
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: Potatuhs.surface(
                    fill: Potatuhs.inkPanel,
                    radius: 12,
                    borderColor: Colors.white12,
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: Potatuhs.textSecondary, size: 20),
                ),
              ),
              const Spacer(),
            ]),
            const SizedBox(height: 6),
            Text(
              'ROUND ${net.round} / ${net.totalRounds}  ·  '
              '${switch (_stage) {
                _SpinStage.category ||
                _SpinStage.categoryLanded =>
                  'CATEGORY WHEEL',
                _SpinStage.scale || _SpinStage.scaleLanded => 'SCALE WHEEL',
                _ => 'GAME WHEEL',
              }}',
              textAlign: TextAlign.center,
              style: Potatuhs.body(size: 13, color: Potatuhs.textSecondary)
                  .copyWith(letterSpacing: 3),
            ),
            const SizedBox(height: 6),
            Text(
              _settled
                  ? '${(spinner?.name ?? '').toUpperCase()} LANDED…'
                  : "${(spinner?.name ?? '').toUpperCase()}'S SPIN",
              textAlign: TextAlign.center,
              style: Potatuhs.display(size: 24, color: accent),
            ),
            const SizedBox(height: 8),
            _breadcrumb(),
            const SizedBox(height: 6),
            Expanded(
              child: AnimatedBuilder(
                animation: Listenable.merge([_spin, _landing, _fx]),
                builder: (context, _) {
                  double angle;
                  if (_stage == _SpinStage.categoryLanded ||
                      _stage == _SpinStage.gameLanded ||
                      _stage == _SpinStage.scaleLanded ||
                      _stage == _SpinStage.sent) {
                    // Whoosh: slow off the drift, accelerate through the
                    // extra revolutions, ease onto the call.
                    final t = Curves.easeInOutCubic.transform(_landing.value);
                    angle =
                        _angleAtStop + (_landingTarget - _angleAtStop) * t;
                  } else {
                    angle = _spin.value * _kTwoPi;
                  }
                  return CustomPaint(
                    painter: _MadnessWheelPainter(
                      table: _table,
                      angle: angle,
                      accent: accent,
                      fx: _fx.value,
                      highlight: _settled || _stage == _SpinStage.sent
                          ? _landedIndex
                          : null,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
            _legend(),
            _footer(me, spinner),
          ],
        ),
        if (showCeremony) _openingCeremony(context),
      ],
    );
  }

  /// The chain of choices so far — identical on every device, fed by the
  /// broadcast meta so spectators read the spin as it happens.
  Widget _breadcrumb() {
    final m = net.meta;
    final catName = m?.spinCategory ?? '';
    final scale = _scaleByName(m?.spinScale ?? '');
    final game =
        (m?.spinGame ?? '').isEmpty ? null : MiniGameRegistry.byId(m!.spinGame);
    final wheel = m?.spinStage ?? 'category';

    Widget chip(String label, {required bool landed, required bool live}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: landed
              ? Potatuhs.gold
              : live
                  ? Potatuhs.gold.withValues(alpha: 0.14)
                  : Potatuhs.inkPanel,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
              color: landed
                  ? Potatuhs.ink
                  : live
                      ? Potatuhs.gold
                      : Colors.white12),
        ),
        child: Text(
          label,
          style: Potatuhs.body(
              size: 10,
              weight: FontWeight.w800,
              color: landed
                  ? Potatuhs.ink
                  : live
                      ? Potatuhs.gold
                      : Potatuhs.textFaint),
        ),
      );
    }

    final arrow = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text('→',
          style: Potatuhs.body(size: 11, color: Potatuhs.textFaint)),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        chip(catName.isEmpty ? 'CATEGORY' : catName,
            landed: catName.isNotEmpty, live: wheel == 'category'),
        arrow,
        chip(
            scale == null
                ? 'SCALE'
                : HpgKit.humanize(scale.name).toUpperCase(),
            landed: scale != null,
            live: wheel == 'scale'),
        arrow,
        Flexible(
          child: chip(game == null ? 'GAME' : game.name.toUpperCase(),
              landed: game != null, live: wheel == 'game'),
        ),
      ],
    );
  }

  /// The number → name legend (Brett 2026-07-17): wedges carry numbers so
  /// they read at speed; the mapping lives here, landed entry highlighted.
  Widget _legend() {
    final table = _table;
    if (table.isEmpty) return const SizedBox.shrink();
    final landed =
        (_settled || _stage == _SpinStage.sent) ? _landedIndex : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 5,
        children: [
          for (var i = 0; i < table.length; i++)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: i == landed ? Potatuhs.gold : Potatuhs.inkPanel,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: i == landed
                        ? Potatuhs.ink
                        : _MadnessWheelPainter.fillFor(i)
                            .withValues(alpha: 0.65)),
              ),
              child: Text(
                '${i + 1} · ${table[i].label.toUpperCase()}',
                style: Potatuhs.body(
                        size: 10,
                        color: i == landed
                            ? Potatuhs.ink
                            : Potatuhs.textPrimary)
                    .copyWith(fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }

  Widget _footer(bool me, NetPlayer? spinner) {
    if (_stage == _SpinStage.sent) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Text(
          '${_game?.name.toUpperCase() ?? ''} — starting…',
          textAlign: TextAlign.center,
          style: Potatuhs.body(size: 15, color: Potatuhs.gold)
              .copyWith(fontWeight: FontWeight.bold),
        ),
      );
    }
    if (_settled) {
      final label = _table.isEmpty
          ? ''
          : _table[_landedIndex.clamp(0, _table.length - 1)]
              .label
              .toUpperCase();
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                textAlign: TextAlign.center,
                style: Potatuhs.display(size: 22, color: Potatuhs.gold)),
            const SizedBox(height: 12),
            if (me)
              // Clarity law: only the SPIN button spins — advancing to the
              // next wheel is NEXT, and it starts that wheel drifting.
              _bigButton(
                  switch (_stage) {
                    _SpinStage.categoryLanded => 'NEXT: SCALE WHEEL',
                    _SpinStage.scaleLanded => 'NEXT: GAME WHEEL',
                    _ => 'PLAY IT',
                  },
                  enabled: true,
                  onTap: _continue)
            else
              Text('Waiting for ${spinner?.name ?? 'the spinner'}…',
                  style:
                      Potatuhs.body(size: 14, color: Potatuhs.textSecondary)),
          ],
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 48,
          child: Center(
            child: Text(
              me
                  ? 'Fire SPIN when your pick drifts to the pointer'
                  : '${spinner?.name ?? 'The spinner'} is at the wheel…',
              textAlign: TextAlign.center,
              style: Potatuhs.body(size: 14, color: Potatuhs.textSecondary),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: _bigButton('SPIN', enabled: me, onTap: _onSpin),
        ),
      ],
    );
  }

  Widget _bigButton(String label,
      {required bool enabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : 0.25,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: enabled
                ? Potatuhs.gold
                : Potatuhs.gold.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Potatuhs.ink, width: 2),
            boxShadow: enabled
                ? const [
                    BoxShadow(color: Potatuhs.ink, offset: Offset(4, 4))
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: Potatuhs.body(size: 20, color: Potatuhs.ink)
                  .copyWith(fontWeight: FontWeight.w900, letterSpacing: 6),
            ),
          ),
        ),
      ),
    );
  }

  // ── The opening ceremony: the board holds the rules, the hosts banter. ──

  Widget _rulesBoard() {
    final rows = <(IconData, String, String)>[
      (
        Icons.emoji_events,
        'WIN',
        'Placement points every round — 1st place pays the most. Highest '
            'total after the last spin takes it.',
      ),
      (
        Icons.track_changes,
        'WHEELS',
        'The spinner stops three wheels — CATEGORY, then SCALE, then GAME. '
            'Timing is real. No game repeats.',
      ),
      (
        Icons.bolt,
        'ROUNDS',
        '${net.meta?.spinsPerPlayer ?? 1} spin(s) each, '
            '${net.totalRounds} rounds total. Everyone plays every game.',
      ),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Potatuhs.inkPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Potatuhs.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MINIGAME MADNESS',
            style: Potatuhs.body(size: 10, color: Potatuhs.textSecondary)
                .copyWith(letterSpacing: 3),
          ),
          for (final (icon, label, text) in rows) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: Potatuhs.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style:
                          Potatuhs.body(size: 13, color: Potatuhs.textPrimary),
                      children: [
                        TextSpan(
                          text: '$label — ',
                          style: Potatuhs.body(size: 13, color: Potatuhs.gold)
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: text),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _openingCeremony(BuildContext context) {
    final beats = madnessOpeningBeats(
        net.meta?.spinsPerPlayer ?? 1, net.totalRounds);
    final page = _ceremonyPage.clamp(0, beats.length - 1);
    final last = page == beats.length - 1;
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          if (last) {
            _ceremonyDismissed = true;
          } else {
            _ceremonyPage++;
          }
        }),
        child: Container(
          color: Colors.black.withValues(alpha: 0.92),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'WELCOME TO THE MADNESS',
                      textAlign: TextAlign.center,
                      style: Potatuhs.display(size: 24, color: Potatuhs.gold),
                    ),
                    const SizedBox(height: 14),
                    _rulesBoard(),
                    const SizedBox(height: 16),
                    DialogueStrip(beat: beats[page]),
                    const SizedBox(height: 18),
                    Text(
                      last
                          ? 'TAP TO SPIN  ·  ${page + 1}/${beats.length}'
                          : 'TAP TO CONTINUE  ·  ${page + 1}/${beats.length}',
                      textAlign: TextAlign.center,
                      style: Potatuhs.body(
                          size: 12, color: Potatuhs.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _ceremonyDismissed = true),
                      child: Text(
                        'SKIP',
                        textAlign: TextAlign.center,
                        style: Potatuhs.body(
                                size: 12, color: Potatuhs.textSecondary)
                            .copyWith(decoration: TextDecoration.underline),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Segment {
  final String label;
  const _Segment(this.label);
}

/// Paints the madness wheel in the potatuhs-design language: segments cycle
/// a warm/cool CONTRAST rotation from DESIGN.md (Fiery Orange · Air Force
/// Blue · Golden Shade · Glaucous · Morning Sienna · Deep Mocha) so adjacent
/// wedges always pop, with 2px Ink Black separators, an ink hub, a
/// hard-offset ink shadow, and a gold ink-bordered pointer at 3 o'clock.
///
/// Wedges carry big NUMBERS (money-wheel legible at full spin speed) — the
/// legend below the wheel maps them to names (Brett 2026-07-17). Light lives
/// on the wheel: rim bulbs at every wedge seam CHASE with the [fx] clock and
/// pulse gold once landed; LED dots run each separator hub→rim.
class _MadnessWheelPainter extends CustomPainter {
  final List<_Segment> table;
  final double angle;
  final Color accent;
  final double fx; // 0..1 repeating light clock
  final int? highlight;
  _MadnessWheelPainter({
    required this.table,
    required this.angle,
    required this.accent,
    required this.fx,
    this.highlight,
  });

  // DESIGN.md palette, ordered warm/cool so neighbours (and the wrap seam)
  // always contrast.
  static const _fills = [
    Potatuhs.orange, // #E16416 Fiery Orange
    Potatuhs.airForce, // #6690A3 Air Force Blue
    Potatuhs.gold, // #E1C916 Golden Shade
    Potatuhs.glaucous, // #7272AB Glaucous
    Potatuhs.sienna, // #E19816 Morning Sienna
    Potatuhs.mocha, // #533A35 Deep Mocha
  ];

  static Color fillFor(int i) => _fills[i % _fills.length];

  /// Ink on the warm fills, warm white on the cool/dark ones.
  static Color _numberColor(int i) => switch (i % _fills.length) {
        0 || 2 || 4 => Potatuhs.ink,
        _ => Potatuhs.textPrimary,
      };

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || table.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(10.0, math.min(size.width, size.height) / 2 - 22);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..style = PaintingStyle.fill;

    // Hard-offset opaque shadow (the design system's card shadow, not blur).
    paint.color = Potatuhs.ink;
    canvas.drawCircle(center.translate(5, 6), radius, paint);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Potatuhs.ink;

    final sweep = 2 * math.pi / table.length;
    for (var i = 0; i < table.length; i++) {
      final a0 = angle + i * sweep;
      paint.color = fillFor(i);
      canvas.drawArc(rect, a0, sweep, true, paint);
      canvas.drawArc(rect, a0, sweep, true, stroke);

      // The wedge NUMBER — big, radial, readable at full spin speed.
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(a0 + sweep / 2);
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            fontFamily: Potatuhs.displayFont,
            fontSize:
                radius * (table.length > 12 ? 0.13 : 0.17).clamp(0.0, 1.0),
            color: _numberColor(i),
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      tp.paint(
          canvas, Offset(radius * 0.60 - tp.width / 2, -tp.height / 2));
      canvas.restore();

      // LED strip along the leading separator, hub → rim (wheel3 energy).
      const dots = 5;
      for (var d = 0; d < dots; d++) {
        final rr = radius * (0.30 + 0.15 * d);
        final tw =
            0.45 + 0.55 * math.sin((fx + i / table.length + d * 0.11) * 2 * math.pi);
        paint.color = Potatuhs.gold.withValues(alpha: 0.25 + 0.6 * tw * tw);
        canvas.drawCircle(
            center + Offset(math.cos(a0), math.sin(a0)) * rr, 2.2, paint);
      }
    }

    // Rim bulbs at every seam: CHASE while turning, all-pulse gold when
    // landed — the light the reference wheels have.
    final landed = highlight != null;
    final bulbs = table.length;
    final lit = (fx * bulbs * 2).floor();
    for (var i = 0; i < bulbs; i++) {
      final a = angle + i * sweep;
      final p = center + Offset(math.cos(a), math.sin(a)) * (radius + 9);
      final on = landed
          ? 0.55 + 0.45 * math.sin(fx * 2 * math.pi * 2)
          : (i == lit % bulbs || i == (lit + bulbs ~/ 2) % bulbs)
              ? 1.0
              : 0.30;
      paint.color = Potatuhs.gold.withValues(alpha: on.clamp(0.0, 1.0));
      canvas.drawCircle(p, landed ? 4.0 : 3.2, paint);
      stroke
        ..strokeWidth = 1
        ..color = Potatuhs.ink;
      canvas.drawCircle(p, landed ? 4.0 : 3.2, stroke);
    }
    stroke.strokeWidth = 2;

    // The landed segment gets a warm-white ring pop; fills stay full-sat.
    final hl = highlight;
    if (hl != null && hl < table.length) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Potatuhs.textPrimary;
      canvas.drawArc(rect.deflate(2), angle + hl * sweep, sweep, true, ring);
    }

    // Rim: clean ink line (borders are structural, per the design system).
    stroke.strokeWidth = 3;
    canvas.drawCircle(center, radius, stroke);

    // Hub: ink disc, spinner-colored ring.
    paint.color = Potatuhs.ink;
    canvas.drawCircle(center, radius * 0.14, paint);
    stroke
      ..strokeWidth = 2.5
      ..color = accent;
    canvas.drawCircle(center, radius * 0.14, stroke);

    // Gold pointer with ink border + its own hard shadow (3 o'clock, aiming
    // inward — the segment it marks reads horizontally).
    Path pointerAt(Offset c) => Path()
      ..moveTo(c.dx + radius + 12, c.dy - 13)
      ..lineTo(c.dx + radius + 12, c.dy + 13)
      ..lineTo(c.dx + radius - 15, c.dy)
      ..close();
    paint.color = Potatuhs.ink;
    canvas.drawPath(pointerAt(center.translate(3, 4)), paint);
    paint.color = Potatuhs.gold;
    canvas.drawPath(pointerAt(center), paint);
    stroke
      ..strokeWidth = 2
      ..color = Potatuhs.ink;
    canvas.drawPath(pointerAt(center), stroke);
  }

  @override
  bool shouldRepaint(_MadnessWheelPainter old) =>
      old.angle != angle ||
      old.table != table ||
      old.highlight != highlight ||
      old.accent != accent ||
      old.fx != fx;
}
