import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Farm Panic — rapid binary decisions under shrinking timers
// ---------------------------------------------------------------------------

const Color _kBg = Color(0xFF0E0A06);
const Color _kSoilC = Color(0xFF5D4037);
const Color _kGreen = Color(0xFF66BB6A);
const Color _kGold = Color(0xFFE8C170);
const Color _kDanger = Color(0xFFE53935);

// ---- crisis data ----------------------------------------------------------

class _CrisisInfo {
  final String title;
  final Color tint;
  final String optA, costA, optB, costB;
  final int minRound;
  const _CrisisInfo({
    required this.title,
    required this.tint,
    required this.optA,
    required this.costA,
    required this.optB,
    required this.costB,
    this.minRound = 0,
  });
}

const List<_CrisisInfo> _kCrises = [
  // --- easy ---
  _CrisisInfo(title: 'DROUGHT!', tint: Color(0xFF795548),
      optA: 'WATER', costA: '-\$5', optB: 'PRAY', costB: 'risky'),
  _CrisisInfo(title: 'WEEDS!', tint: Color(0xFF33691E),
      optA: 'SPRAY', costA: '-\$10', optB: 'PULL', costB: 'free'),
  _CrisisInfo(title: 'CROWS!', tint: Color(0xFF263238),
      optA: 'SCARE', costA: '-\$5', optB: 'IGNORE', costB: 'risky'),
  _CrisisInfo(title: 'FERTILIZE?', tint: Color(0xFF4E342E),
      optA: 'BUY', costA: '-\$15', optB: 'SKIP', costB: 'free'),
  _CrisisInfo(title: 'SEEDS!', tint: Color(0xFF558B2F),
      optA: 'MYSTERY', costA: 'random', optB: 'SELL', costB: '+\$10'),
  // --- medium ---
  _CrisisInfo(title: 'FROST!', tint: Color(0xFF37474F), minRound: 3,
      optA: 'COVER', costA: '-\$15', optB: 'GAMBLE', costB: 'risky'),
  _CrisisInfo(title: 'APHIDS!', tint: Color(0xFFBF360C), minRound: 3,
      optA: 'POISON', costA: '-\$10', optB: 'BUGS', costB: '-\$5'),
  _CrisisInfo(title: 'HARVEST!', tint: Color(0xFFE65100), minRound: 2,
      optA: 'NOW', costA: 'safe', optB: 'WAIT', costB: 'more?'),
  _CrisisInfo(title: 'STORM!', tint: Color(0xFF1A237E), minRound: 4,
      optA: 'SHELTER', costA: '-\$10', optB: 'BRACE', costB: 'risky'),
  _CrisisInfo(title: 'GOPHERS!', tint: Color(0xFF4E342E), minRound: 3,
      optA: 'TRAPS', costA: '-\$10', optB: 'FLOOD', costB: '-soil'),
  _CrisisInfo(title: 'MARKET BOOM!', tint: Color(0xFFFF8F00), minRound: 4,
      optA: 'SELL', costA: '+\$30', optB: 'HOLD', costB: 'risky'),
  _CrisisInfo(title: 'GOAT LOOSE!', tint: Color(0xFF6D4C41), minRound: 2,
      optA: 'CHASE', costA: 'safe', optB: 'LET GRAZE', costB: 'risky'),
  // --- hard ---
  _CrisisInfo(title: 'BLIGHT!', tint: Color(0xFF4A148C), minRound: 7,
      optA: 'TREAT', costA: '-\$25', optB: 'CUT LOSS', costB: '-20 crop'),
  _CrisisInfo(title: 'BROKE!', tint: Color(0xFF455A64), minRound: 6,
      optA: 'FIX', costA: '-\$20', optB: 'DIY', costB: '-crop'),
  _CrisisInfo(title: 'INSPECTOR!', tint: Color(0xFF1B5E20), minRound: 8,
      optA: 'BRIBE', costA: '-\$30', optB: 'SHOW FARM', costB: 'need soil'),
  _CrisisInfo(title: 'HAIL!', tint: Color(0xFF546E7A), minRound: 5,
      optA: 'NET', costA: '-\$15', optB: 'DUCK', costB: 'risky'),
  _CrisisInfo(title: 'RATS!', tint: Color(0xFF3E2723), minRound: 5,
      optA: 'CATS', costA: '-\$10', optB: 'POISON', costB: '-soil'),
];

// ---- phase ----------------------------------------------------------------

enum _Phase { preGame, crisis, consequence, gameOver }

// ---- widget ---------------------------------------------------------------

class FarmPanicGame extends StatefulWidget {
  const FarmPanicGame({Key? key}) : super(key: key);
  @override
  State<FarmPanicGame> createState() => _FarmPanicGameState();
}

class _FarmPanicGameState extends State<FarmPanicGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  // Phase
  _Phase _phase = _Phase.preGame;
  double _phaseTimer = 0;

  // Farm stats
  int _money = 50;
  double _crop = 70; // 0-100
  double _soil = 60; // 0-100
  int _round = 0;
  bool _harvestHalved = false;

  // Current crisis
  int _crisisIdx = 0;
  String _resultText = '';
  bool _resultGood = true;
  int _moneyDelta = 0;
  double _cropDelta = 0;

  // Shake
  double _shakeIntensity = 0;

  // Timing
  Size _size = Size.zero;
  double _lastTime = 0;
  double _elapsed = 0;

  double get _crisisTime => max(2.0, 4.5 - _round * 0.12);

  @override
  void initState() {
    super.initState();
    _ticker =
        AnimationController(vsync: this, duration: const Duration(days: 1))
          ..addListener(_onTick);
    _ticker.forward();
    _lastTime = _now();
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _startGame() {
    _money = 50;
    _crop = 70;
    _soil = 60;
    _round = 0;
    _harvestHalved = false;
    _shakeIntensity = 0;
    _elapsed = 0;
    _nextCrisis();
  }

  void _nextCrisis() {
    // Passive income from farming
    final income = max(1, (_crop / 20).floor());
    _money += income;

    // Soil slowly affects crop
    if (_soil > 50) {
      _crop = min(100, _crop + 1);
    } else if (_soil < 30) {
      _crop = max(0, _crop - 1);
    }

    // Pick a crisis appropriate for this round
    final eligible = <int>[];
    for (int i = 0; i < _kCrises.length; i++) {
      if (_round >= _kCrises[i].minRound) eligible.add(i);
    }
    _crisisIdx = eligible[_rng.nextInt(eligible.length)];
    _phase = _Phase.crisis;
    _phaseTimer = _crisisTime;
    _moneyDelta = 0;
    _cropDelta = 0;
  }

  void _onTick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;
    if (_size == Size.zero) return;

    setState(() {
      _elapsed += dt;

      if (_shakeIntensity > 0) {
        _shakeIntensity *= (1 - dt * 8);
        if (_shakeIntensity < 0.3) _shakeIntensity = 0;
      }

      if (_phase == _Phase.crisis) {
        _phaseTimer -= dt;
        if (_phaseTimer <= 0) {
          // Timeout — auto-pick option B (the risky/lazy one)
          _resolveChoice(false);
        }
      } else if (_phase == _Phase.consequence) {
        _phaseTimer -= dt;
        if (_phaseTimer <= 0) {
          if (_money <= 0 || _crop <= 0) {
            _phase = _Phase.gameOver;
          } else {
            _round++;
            _nextCrisis();
          }
        }
      }
    });
  }

  void _resolveChoice(bool choseA) {
    final oldMoney = _money;
    final oldCrop = _crop;

    _applyCrisis(_crisisIdx, choseA);

    _moneyDelta = _money - oldMoney;
    _cropDelta = _crop - oldCrop;
    _resultGood = _moneyDelta >= 0 && _cropDelta >= -5;

    if (!_resultGood) _shakeIntensity = 6;

    _phase = _Phase.consequence;
    _phaseTimer = 0.8;
  }

  void _applyCrisis(int idx, bool a) {
    switch (idx) {
      case 0: // DROUGHT
        if (a) {
          _money -= 5;
          _resultText = 'Watered!';
        } else {
          if (_rng.nextDouble() < 0.45) {
            _resultText = 'Rain came!';
          } else {
            _crop -= 15;
            _resultText = 'Withered!';
          }
        }
        break;
      case 1: // WEEDS
        if (a) {
          _money -= 10;
          _soil -= 5;
          _resultText = 'Sprayed!';
        } else {
          _crop -= 5;
          _resultText = 'Pulled!';
        }
        break;
      case 2: // CROWS
        if (a) {
          _money -= 5;
          _resultText = 'Scarecrow up!';
        } else {
          if (_rng.nextDouble() < 0.35) {
            _crop -= 12;
            _resultText = 'They feasted!';
          } else {
            _resultText = 'Flew away!';
          }
        }
        break;
      case 3: // FERTILIZE
        if (a) {
          _money -= 15;
          _soil += 15;
          _soil = min(100, _soil);
          _resultText = 'Soil enriched!';
        } else {
          _resultText = 'Skipped.';
        }
        break;
      case 4: // SEEDS
        if (a) {
          final roll = _rng.nextDouble();
          if (roll < 0.3) {
            _crop += 20;
            _crop = min(100, _crop);
            _resultText = 'Magic beans!';
          } else if (roll < 0.6) {
            _resultText = 'Duds.';
          } else {
            _crop -= 10;
            _resultText = 'Invasive weed!';
          }
        } else {
          _money += 10;
          _resultText = 'Sold! +\$10';
        }
        break;
      case 5: // FROST
        if (a) {
          _money -= 15;
          _resultText = 'Covered!';
        } else {
          if (_rng.nextDouble() < 0.4) {
            _crop -= 25;
            _resultText = 'Frozen solid!';
          } else {
            _resultText = 'Survived!';
          }
        }
        break;
      case 6: // APHIDS
        if (a) {
          _money -= 10;
          _soil -= 10;
          _resultText = 'Nuked em!';
        } else {
          _money -= 5;
          _crop -= 5;
          _resultText = 'Ladybugs helped!';
        }
        break;
      case 7: // HARVEST
        if (a) {
          var yield_ = (_crop * 0.3).round();
          if (_harvestHalved) {
            yield_ = (yield_ * 0.5).round();
            _harvestHalved = false;
          }
          _money += yield_;
          _crop -= 10;
          _resultText = 'Harvested +\$$yield_!';
        } else {
          if (_rng.nextDouble() < 0.55) {
            var yield_ = (_crop * 0.5).round();
            if (_harvestHalved) {
              yield_ = (yield_ * 0.5).round();
              _harvestHalved = false;
            }
            _money += yield_;
            _crop -= 10;
            _resultText = 'Big harvest +\$$yield_!';
          } else {
            _crop -= 15;
            _resultText = 'Rotted!';
          }
        }
        break;
      case 8: // STORM
        if (a) {
          _money -= 10;
          _resultText = 'Sheltered!';
        } else {
          final loss = 10 + _rng.nextInt(20);
          _crop -= loss;
          _resultText = 'Battered! -$loss';
        }
        break;
      case 9: // GOPHERS
        if (a) {
          _money -= 10;
          _resultText = 'Trapped!';
        } else {
          _soil -= 8;
          _resultText = 'Flooded tunnels!';
        }
        break;
      case 10: // MARKET BOOM
        if (a) {
          _money += 30;
          _resultText = 'Sold! +\$30!';
        } else {
          if (_rng.nextDouble() < 0.4) {
            _money += 50;
            _resultText = 'Prices soared! +\$50!';
          } else {
            _resultText = 'Market crashed...';
          }
        }
        break;
      case 11: // GOAT
        if (a) {
          _resultText = 'Caught the goat!';
        } else {
          if (_rng.nextDouble() < 0.35) {
            _crop -= 12;
            _resultText = 'Ate the crops!';
          } else {
            _crop += 5;
            _crop = min(100, _crop);
            _resultText = 'Ate the weeds!';
          }
        }
        break;
      case 12: // BLIGHT
        if (a) {
          _money -= 25;
          if (_rng.nextDouble() < 0.65) {
            _resultText = 'Treated!';
          } else {
            _crop -= 15;
            _resultText = 'Still spreading!';
          }
        } else {
          _crop -= 20;
          _resultText = 'Cut losses. -20';
        }
        break;
      case 13: // BROKE (equipment)
        if (a) {
          _money -= 20;
          _resultText = 'Fixed!';
        } else {
          _harvestHalved = true;
          _resultText = 'DIY... half harvest';
        }
        break;
      case 14: // INSPECTOR
        if (a) {
          _money -= 30;
          _resultText = 'Looked the other way!';
        } else {
          if (_soil > 50) {
            _money += 20;
            _resultText = 'Passed! +\$20!';
          } else {
            _money -= 20;
            _resultText = 'Failed! Fined!';
          }
        }
        break;
      case 15: // HAIL
        if (a) {
          _money -= 15;
          _resultText = 'Netted!';
        } else {
          if (_rng.nextDouble() < 0.5) {
            _crop -= 20;
            _resultText = 'Pelted!';
          } else {
            _resultText = 'Missed us!';
          }
        }
        break;
      case 16: // RATS
        if (a) {
          _money -= 10;
          _resultText = 'Cat patrol!';
        } else {
          _money -= 5;
          _soil -= 8;
          _resultText = 'Poisoned rats & soil';
        }
        break;
      default:
        _resultText = '???';
    }

    _crop = _crop.clamp(0, 100);
    _soil = _soil.clamp(0, 100);
  }

  // ---- input --------------------------------------------------------------

  void _onPointerDown(Offset pos) {
    if (_phase == _Phase.preGame || _phase == _Phase.gameOver) {
      _startGame();
      return;
    }
    if (_phase == _Phase.crisis) {
      final leftHalf = pos.dx < _size.width / 2;
      _resolveChoice(leftHalf); // left = A, right = B
    }
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      _size = Size(box.maxWidth, box.maxHeight);
      return Listener(
        onPointerDown: (e) => _onPointerDown(e.localPosition),
        child: ClipRect(
          child: CustomPaint(
            painter: _FarmPanicPainter(
              phase: _phase,
              phaseTimer: _phaseTimer,
              crisisTime: _crisisTime,
              money: _money,
              crop: _crop,
              soil: _soil,
              round: _round,
              crisisIdx: _crisisIdx,
              resultText: _resultText,
              resultGood: _resultGood,
              moneyDelta: _moneyDelta,
              cropDelta: _cropDelta,
              shakeIntensity: _shakeIntensity,
              elapsed: _elapsed,
            ),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// ---- painter --------------------------------------------------------------

class _FarmPanicPainter extends CustomPainter {
  final _Phase phase;
  final double phaseTimer, crisisTime;
  final int money, round, crisisIdx;
  final double crop, soil;
  final String resultText;
  final bool resultGood;
  final int moneyDelta;
  final double cropDelta;
  final double shakeIntensity, elapsed;

  _FarmPanicPainter({
    required this.phase,
    required this.phaseTimer,
    required this.crisisTime,
    required this.money,
    required this.crop,
    required this.soil,
    required this.round,
    required this.crisisIdx,
    required this.resultText,
    required this.resultGood,
    required this.moneyDelta,
    required this.cropDelta,
    required this.shakeIntensity,
    required this.elapsed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);

    if (shakeIntensity > 0) {
      canvas.save();
      canvas.translate(
        sin(elapsed * 45) * shakeIntensity,
        cos(elapsed * 35) * shakeIntensity,
      );
    }

    // Always draw field in background (except pre-game)
    if (phase != _Phase.preGame) {
      _drawField(canvas, size);
      _drawStats(canvas, size);
    }

    switch (phase) {
      case _Phase.preGame:
        _drawPreGame(canvas, size);
        break;
      case _Phase.crisis:
        _drawCrisis(canvas, size);
        break;
      case _Phase.consequence:
        _drawConsequence(canvas, size);
        break;
      case _Phase.gameOver:
        _drawGameOver(canvas, size);
        break;
    }

    if (shakeIntensity > 0) canvas.restore();
  }

  // ---- field visual -------------------------------------------------------

  void _drawField(Canvas canvas, Size size) {
    final fieldTop = 50.0;
    final fieldH = size.height * 0.38;

    // Sky
    canvas.drawRect(
      Rect.fromLTWH(0, fieldTop, size.width, fieldH),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, fieldTop),
          Offset(0, fieldTop + fieldH),
          [const Color(0xFF1A2744), const Color(0xFF2E4A3A)],
        ),
    );

    // Sun
    final sunX = size.width * 0.8;
    final sunY = fieldTop + 25;
    canvas.drawCircle(
      Offset(sunX, sunY),
      12,
      Paint()..color = _kGold.withValues(alpha: 0.4),
    );
    canvas.drawCircle(
      Offset(sunX, sunY),
      8,
      Paint()..color = _kGold.withValues(alpha: 0.7),
    );

    // Ground
    final groundY = fieldTop + fieldH * 0.65;
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.width, fieldTop + fieldH - groundY),
      Paint()
        ..color = Color.lerp(
          const Color(0xFF3E2723),
          _kSoilC,
          (soil / 100).clamp(0.0, 1.0),
        )!,
    );

    // Crop rows
    final cropH = 8 + (crop / 100) * 35;
    final cropCount = 12;
    for (int i = 0; i < cropCount; i++) {
      final cx = size.width * (0.08 + i * 0.84 / (cropCount - 1));
      final sway = sin(elapsed * 1.5 + i * 0.7) * 2;

      // Stalk
      canvas.drawLine(
        Offset(cx + sway * 0.3, groundY),
        Offset(cx + sway, groundY - cropH),
        Paint()
          ..color = Color.lerp(
            const Color(0xFF795548),
            _kGreen,
            (crop / 100).clamp(0.0, 1.0),
          )!
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );

      // Leaves
      if (crop > 25) {
        canvas.drawLine(
          Offset(cx + sway * 0.6, groundY - cropH * 0.6),
          Offset(cx - 7 + sway * 0.8, groundY - cropH * 0.8),
          Paint()
            ..color = _kGreen.withValues(alpha: (crop / 100).clamp(0.3, 0.8))
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );
      }
      if (crop > 50) {
        canvas.drawLine(
          Offset(cx + sway * 0.4, groundY - cropH * 0.4),
          Offset(cx + 7 + sway * 0.5, groundY - cropH * 0.55),
          Paint()
            ..color = _kGreen.withValues(alpha: (crop / 100).clamp(0.3, 0.8))
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );
      }

      // Potato at base
      if (crop > 30) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, groundY + 5),
            width: 8,
            height: 6,
          ),
          Paint()..color = _kGold.withValues(alpha: 0.5),
        );
      }
    }

    // Crisis tint overlay
    if (phase == _Phase.crisis && crisisIdx < _kCrises.length) {
      canvas.drawRect(
        Rect.fromLTWH(0, fieldTop, size.width, fieldH),
        Paint()
          ..color = _kCrises[crisisIdx].tint.withValues(alpha: 0.15),
      );
    }
  }

  // ---- stats bar ----------------------------------------------------------

  void _drawStats(Canvas canvas, Size size) {
    final y = 14.0;

    // Money
    final moneyTp = TextPainter(
      text: TextSpan(
        text: '\$$money',
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _kGold.withValues(alpha: 0.8),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    moneyTp.paint(canvas, Offset(14, y));

    // Round
    final roundTp = TextPainter(
      text: TextSpan(
        text: 'Round $round',
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 13,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    roundTp.paint(
        canvas, Offset((size.width - roundTp.width) / 2, y + 2));

    // Crop bar
    _drawStatBar(
        canvas, size.width - 120, y, 50, 'crop', crop / 100, _kGreen);
    // Soil bar
    _drawStatBar(
        canvas, size.width - 58, y, 44, 'soil', soil / 100, _kSoilC);
  }

  void _drawStatBar(Canvas canvas, double x, double y, double w,
      String label, double fill, Color color) {
    // Label
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 9,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y - 1));

    // Bar
    final barY = y + 12;
    const barH = 4.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x, barY, w, barH), const Radius.circular(2)),
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x, barY, w * fill.clamp(0.0, 1.0), barH),
          const Radius.circular(2)),
      Paint()..color = color.withValues(alpha: 0.6),
    );
  }

  // ---- crisis screen ------------------------------------------------------

  void _drawCrisis(Canvas canvas, Size size) {
    if (crisisIdx >= _kCrises.length) return;
    final crisis = _kCrises[crisisIdx];
    final midY = size.height * 0.52;

    // Crisis title
    _drawCentered(canvas, size, crisis.title, 36,
        Colors.white.withValues(alpha: 0.85), midY - size.height / 2 - 15);

    // Divider line
    canvas.drawLine(
      Offset(size.width / 2, midY + 20),
      Offset(size.width / 2, size.height - 50),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..strokeWidth = 1,
    );

    // Option A (left)
    _drawOption(
        canvas, size, true, crisis.optA, crisis.costA, midY + 30);

    // Option B (right)
    _drawOption(
        canvas, size, false, crisis.optB, crisis.costB, midY + 30);

    // Timer bar
    final timerRatio = (phaseTimer / crisisTime).clamp(0.0, 1.0);
    final barY = size.height - 30;
    final barW = size.width - 48;
    final barX = 24.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW, 6), const Radius.circular(3)),
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );

    final timerColor = timerRatio > 0.4
        ? _kGold
        : timerRatio > 0.2
            ? const Color(0xFFFF9800)
            : _kDanger;

    // Pulse when low
    final pulseAlpha =
        timerRatio < 0.25 ? 0.5 + 0.3 * sin(elapsed * 12) : 0.6;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW * timerRatio, 6),
          const Radius.circular(3)),
      Paint()..color = timerColor.withValues(alpha: pulseAlpha),
    );

    // "TAP LEFT / TAP RIGHT" hint
    if (round < 3) {
      _drawCentered(canvas, size, '\u2190 tap left    tap right \u2192',
          11, Colors.white.withValues(alpha: 0.15), size.height / 2 - 52);
    }
  }

  void _drawOption(Canvas canvas, Size size, bool isLeft, String label,
      String cost, double top) {
    final halfW = size.width / 2;
    final cx = isLeft ? halfW * 0.5 : halfW * 1.5;
    final boxW = halfW - 24;
    final boxH = 65.0;
    final boxX = cx - boxW / 2;

    // Box
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(boxX, top, boxW, boxH), const Radius.circular(10)),
      Paint()..color = Colors.white.withValues(alpha: 0.04),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(boxX, top, boxW, boxH), const Radius.circular(10)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Label
    final labelTp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white.withValues(alpha: 0.75),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelTp.paint(
        canvas, Offset(cx - labelTp.width / 2, top + 12));

    // Cost
    final costColor = cost.startsWith('-')
        ? _kDanger.withValues(alpha: 0.5)
        : cost.startsWith('+')
            ? _kGreen.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.3);
    final costTp = TextPainter(
      text: TextSpan(
        text: cost,
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 13,
          color: costColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    costTp.paint(
        canvas, Offset(cx - costTp.width / 2, top + 40));
  }

  // ---- consequence screen -------------------------------------------------

  void _drawConsequence(Canvas canvas, Size size) {
    // Flash
    final alpha = (phaseTimer / 0.8).clamp(0.0, 1.0);
    final flashColor =
        resultGood ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = flashColor.withValues(alpha: alpha * 0.12),
    );

    // Result text
    _drawCentered(canvas, size, resultText, 28,
        flashColor.withValues(alpha: alpha * 0.8), 0);

    // Delta indicators
    if (moneyDelta != 0) {
      final sign = moneyDelta > 0 ? '+' : '';
      final dColor = moneyDelta > 0 ? _kGreen : _kDanger;
      _drawCentered(canvas, size, '$sign\$$moneyDelta', 16,
          dColor.withValues(alpha: alpha * 0.6), 35);
    }
    if (cropDelta.abs() > 0.5) {
      final sign = cropDelta > 0 ? '+' : '';
      final cColor = cropDelta > 0 ? _kGreen : _kDanger;
      _drawCentered(
          canvas,
          size,
          '${sign}${cropDelta.round()} crop',
          14,
          cColor.withValues(alpha: alpha * 0.5),
          moneyDelta != 0 ? 55 : 35);
    }
  }

  // ---- screens ------------------------------------------------------------

  void _drawPreGame(Canvas canvas, Size size) {
    // Potato
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.33),
        width: 52,
        height: 40,
      ),
      Paint()..color = _kGold.withValues(alpha: 0.6),
    );
    canvas.drawCircle(
      Offset(size.width / 2 - 8, size.height * 0.33 - 4),
      3,
      Paint()..color = const Color(0xFFC08840).withValues(alpha: 0.4),
    );

    _drawCentered(canvas, size, 'Farm Panic', 30,
        Colors.white.withValues(alpha: 0.6), -15);
    _drawCentered(canvas, size, 'Crises hit. Decide fast.', 14,
        Colors.white.withValues(alpha: 0.25), 15);
    _drawCentered(canvas, size, 'Left = safe. Right = risky.', 13,
        Colors.white.withValues(alpha: 0.2), 35);
    _drawCentered(canvas, size, 'Tap to start', 14,
        Colors.white.withValues(alpha: 0.2), 65);
  }

  void _drawGameOver(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: 0.75),
    );

    _drawCentered(canvas, size, 'FARM OVER', 30,
        Colors.white.withValues(alpha: 0.54), -50);
    _drawCentered(canvas, size, '$round', 52,
        _kGold.withValues(alpha: 0.7), -5);
    _drawCentered(canvas, size, 'rounds survived', 14,
        Colors.white.withValues(alpha: 0.3), 30);
    _drawCentered(canvas, size, '\$$money remaining', 14,
        Colors.white.withValues(alpha: 0.25), 52);
    _drawCentered(canvas, size, 'Tap to restart', 14,
        Colors.white.withValues(alpha: 0.2), 80);
  }

  // ---- text helper --------------------------------------------------------

  void _drawCentered(Canvas canvas, Size size, String text, double sz,
      Color color, double yOff) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: sz,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
        canvas,
        Offset((size.width - tp.width) / 2,
            (size.height - tp.height) / 2 + yOff));
  }

  @override
  bool shouldRepaint(covariant _FarmPanicPainter old) => true;
}
