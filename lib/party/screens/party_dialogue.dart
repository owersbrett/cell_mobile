import 'dart:math' as math;

import 'package:cell_mobile/party/party_models.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:flutter/material.dart';

/// Shared character-dialogue kit for the party cinematics (opening ceremony,
/// wheel payoffs, round flair). Portraits are the raster stickers from
/// `assets/characters/` (the one allowed raster exception); expressions are
/// procedural — motion + a painted mood badge — so no expression art is
/// required per character.
///
/// VOICE LAW (Brett, 2026-07-07): "uhhh…" belongs to RUSS ALONE — it is his
/// catchphrase, never a company-wide tic. Butter is smooth, earnest, never
/// hedges and never winks. Every line bank below is written to the character
/// profiles in `~/Potatuhs/info/company/characters/`.

// kCharacters seat map (party_models.dart) — indexes are load-bearing.
const int kCharRuss = 0;
const int kCharButter = 1;
const int kCharCurly = 2;
const int kCharWaffle = 3;
const int kCharFrench = 4;
const int kCharTater = 5;
const int kCharPierogi = 6;
const int kCharBaked = 7;

/// How a portrait carries a line. Drives motion + the painted badge.
enum CharacterMood {
  neutral, // gentle idle sway
  excited, // big bounce + "!" spark
  smug, // slow confident tilt + sparkle
  worried, // quick shiver + sweat drop
  scheming, // lean in + trailing dots
  cozy, // soft sway + steam curl
}

/// One spoken beat: who says it, what they say, how they carry it.
class DialogueBeat {
  final int character; // index into kCharacters
  final String line;
  final CharacterMood mood;
  const DialogueBeat(this.character, this.line,
      [this.mood = CharacterMood.neutral]);
}

// ───────────────────────── portrait with expression ─────────────────────────

/// A character portrait that performs while speaking: mood-shaped motion on
/// the (static, hoisted) sticker plus a procedurally painted badge. One ticker
/// per portrait; the image itself never rebuilds.
class ExpressivePortrait extends StatefulWidget {
  final int character; // index into kCharacters
  final double size;
  final CharacterMood mood;
  final bool speaking;

  const ExpressivePortrait({
    super.key,
    required this.character,
    this.size = 72,
    this.mood = CharacterMood.neutral,
    this.speaking = true,
  });

  @override
  State<ExpressivePortrait> createState() => _ExpressivePortraitState();
}

class _ExpressivePortraitState extends State<ExpressivePortrait>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tick;

  @override
  void initState() {
    super.initState();
    _tick = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    if (widget.speaking) _tick.repeat();
  }

  @override
  void didUpdateWidget(ExpressivePortrait old) {
    super.didUpdateWidget(old);
    if (widget.speaking && !_tick.isAnimating) _tick.repeat();
    if (!widget.speaking && _tick.isAnimating) {
      _tick.stop();
      _tick.value = 0;
    }
  }

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ch = kCharacters[widget.character % kCharacters.length];
    final s = widget.size;
    // Static subtree — built once, transformed per frame via `child:`.
    final portrait = Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Potatuhs.inkPanel,
        border: Border.all(color: ch.color.withValues(alpha: 0.8), width: 2),
        boxShadow: [
          BoxShadow(color: ch.color.withValues(alpha: 0.35), blurRadius: 14),
        ],
      ),
      child: ClipOval(
        child: ch.asset != null
            ? Image.asset(ch.asset!, fit: BoxFit.cover)
            : Center(
                child: Text(ch.name[0],
                    style: Potatuhs.display(size: s * 0.4, color: ch.color)),
              ),
      ),
    );
    return SizedBox(
      // Headroom for the badge above the circle.
      width: s + 20,
      height: s + 20,
      child: AnimatedBuilder(
        animation: _tick,
        child: portrait,
        builder: (context, child) {
          final t = _tick.value;
          final (dy, tilt, squash) = _pose(widget.mood, t);
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..translateByDouble(0.0, dy, 0.0, 1.0)
                  ..rotateZ(tilt)
                  ..scaleByDouble(1.0 + squash, 1.0 - squash, 1.0, 1.0),
                child: child,
              ),
              if (widget.speaking && widget.mood != CharacterMood.neutral)
                Positioned(
                  top: -2,
                  right: -2,
                  child: CustomPaint(
                    size: const Size(26, 26),
                    painter: _MoodBadgePainter(
                        mood: widget.mood, t: t, color: ch.color),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Mood → (bob, tilt, squash) at loop position [t] ∈ [0,1).
  (double, double, double) _pose(CharacterMood mood, double t) {
    final w = t * 2 * math.pi;
    switch (mood) {
      case CharacterMood.neutral:
        return (1.5 * math.sin(w), 0.015 * math.sin(w), 0);
      case CharacterMood.excited:
        // Two eager hops per loop, squashing on the landing.
        final hop = (math.sin(2 * w)).abs();
        return (-7 * hop, 0.03 * math.sin(w), 0.04 * (1 - hop));
      case CharacterMood.smug:
        // Held confident lean + gentle sway. Tilt must be periodic in one
        // loop (whole multiples of w) or the pose snaps when _tick wraps.
        return (1.0 * math.sin(w), 0.05 + 0.035 * math.sin(w), 0);
      case CharacterMood.worried:
        return (1.0 * math.sin(4 * w), 0.02 * math.sin(6 * w), 0);
      case CharacterMood.scheming:
        return (2.0 * math.sin(w), -0.06 - 0.02 * math.sin(w), 0);
      case CharacterMood.cozy:
        return (2.5 * math.sin(w / 1), 0.03 * math.sin(w), 0.01 * math.sin(w));
    }
  }
}

/// The painted expression: a small emblem above the portrait, anime-style.
/// Pure canvas — no raster, per the procedural-assets rule.
class _MoodBadgePainter extends CustomPainter {
  final CharacterMood mood;
  final double t;
  final Color color;
  _MoodBadgePainter({required this.mood, required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final pulse = 0.85 + 0.15 * math.sin(t * 2 * math.pi);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.95);
    final glow = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    switch (mood) {
      case CharacterMood.excited:
        // Bold "!" that pulses.
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.scale(pulse);
        canvas.drawCircle(Offset.zero, 9, glow);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(-2, -9, 4, 11), const Radius.circular(2)),
            paint);
        canvas.drawCircle(const Offset(0, 7), 2.2, paint);
        canvas.restore();
        break;
      case CharacterMood.smug:
        // Four-point sparkle, slowly turning.
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(t * math.pi);
        canvas.drawCircle(Offset.zero, 8, glow);
        final star = Path();
        for (var i = 0; i < 4; i++) {
          final a = i * math.pi / 2;
          star.moveTo(9 * math.cos(a), 9 * math.sin(a));
          star.lineTo(2.5 * math.cos(a + math.pi / 4),
              2.5 * math.sin(a + math.pi / 4));
          star.lineTo(2.5 * math.cos(a - math.pi / 4),
              2.5 * math.sin(a - math.pi / 4));
          star.close();
        }
        canvas.drawPath(star, paint);
        canvas.restore();
        break;
      case CharacterMood.worried:
        // A sweat drop sliding down.
        final dy = 4 * ((t * 2) % 1.0);
        final drop = Path()
          ..moveTo(c.dx, c.dy - 8 + dy)
          ..quadraticBezierTo(
              c.dx + 5, c.dy + dy, c.dx, c.dy + 5 + dy)
          ..quadraticBezierTo(
              c.dx - 5, c.dy + dy, c.dx, c.dy - 8 + dy)
          ..close();
        canvas.drawPath(
            drop, Paint()..color = const Color(0xFF7EC8E3).withValues(alpha: 0.95));
        break;
      case CharacterMood.scheming:
        // Trailing thought-dots, lighting up in sequence.
        for (var i = 0; i < 3; i++) {
          final on = ((t * 3).floor() % 3) == i;
          canvas.drawCircle(
            Offset(c.dx - 7 + i * 7.0, c.dy),
            on ? 3.2 : 2.0,
            Paint()
              ..color = Colors.white.withValues(alpha: on ? 0.95 : 0.4),
          );
        }
        break;
      case CharacterMood.cozy:
        // A curl of steam.
        final wave = math.sin(t * 2 * math.pi);
        final steam = Path()
          ..moveTo(c.dx - 2, c.dy + 8)
          ..cubicTo(c.dx - 6 + 2 * wave, c.dy + 3, c.dx + 4 + 2 * wave,
              c.dy - 1, c.dx - 1 + 2 * wave, c.dy - 8);
        canvas.drawPath(
            steam,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4
              ..strokeCap = StrokeCap.round
              ..color = Colors.white.withValues(alpha: 0.8));
        break;
      case CharacterMood.neutral:
        break;
    }
  }

  @override
  bool shouldRepaint(_MoodBadgePainter old) =>
      old.t != t || old.mood != mood || old.color != color;
}

// ─────────────────────────── the dialogue strip ───────────────────────────

/// A speaking character + their bubble: portrait performing on the left,
/// name + line in a panel tinted by the character's color. The shared shape
/// for ceremony banter, wheel payoffs, and flair beats.
class DialogueStrip extends StatelessWidget {
  final DialogueBeat beat;
  const DialogueStrip({super.key, required this.beat});

  @override
  Widget build(BuildContext context) {
    final ch = kCharacters[beat.character % kCharacters.length];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ExpressivePortrait(
          // Key on speaker so the performance restarts per beat.
          key: ValueKey('portrait_${beat.character}_${beat.mood}'),
          character: beat.character,
          mood: beat.mood,
          size: 72,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: Potatuhs.inkPanel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ch.color.withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ch.name.toUpperCase(),
                  style: Potatuhs.body(size: 10, color: ch.color)
                      .copyWith(letterSpacing: 3, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  beat.line,
                  style: Potatuhs.body(size: 14, color: Potatuhs.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────── the line banks ─────────────────────────────

/// Each playable character's table-talk when the game opens — one in-voice
/// beat apiece, spoken only if that character was actually picked.
DialogueBeat _openingLineFor(int character) {
  switch (character) {
    case kCharRuss:
      return const DialogueBeat(
        kCharRuss,
        'uhhh… so the diamonds are just… lying on the path? Nobody guards '
        'them? Great. I have so many plans.',
        CharacterMood.excited,
      );
    case kCharButter:
      return const DialogueBeat(
        kCharButter,
        "I'd wish you all luck, but I've already seen how this ends. "
        "It's beautiful. For me.",
        CharacterMood.smug,
      );
    case kCharCurly:
      return const DialogueBeat(
        kCharCurly,
        "Already found a shortcut. It twists. You wouldn't get it.",
        CharacterMood.scheming,
      );
    case kCharWaffle:
      return const DialogueBeat(
        kCharWaffle,
        "Rolls, rounds, checkpoints, the Shack. I've gridded the whole "
        'board. Every square has a purpose.',
        CharacterMood.neutral,
      );
    case kCharFrench:
      return const DialogueBeat(
        kCharFrench,
        "Every diamond on that path is revenue. I'll be counting. "
        "I'm always counting.",
        CharacterMood.smug,
      );
    case kCharTater:
      return const DialogueBeat(
        kCharTater,
        'A race with a deadline. Finally. I have never missed one — '
        'ask anybody.',
        CharacterMood.excited,
      );
    case kCharPierogi:
      return const DialogueBeat(
        kCharPierogi,
        'The board remembers who walked it. I write that part down. '
        "Play like it's canon — because it is.",
        CharacterMood.cozy,
      );
    default:
      return const DialogueBeat(
        kCharBaked,
        "Take the long way if you want. It's cozy out there, and the "
        "diamonds don't rush. Neither should you.",
        CharacterMood.cozy,
      );
  }
}

/// The ceremony banter: Butter MCs (she is the show's host whether or not a
/// player picked her), then the characters actually at the table talk back.
/// Pure function of the shared roster — identical on every client.
List<DialogueBeat> openingBanterFor(List<PartyPlayer> players, String mapName) {
  final picked = <int>[];
  for (final p in players) {
    final ch = p.character % kCharacters.length;
    if (!picked.contains(ch)) picked.add(ch);
  }
  final beats = <DialogueBeat>[
    DialogueBeat(
      kCharButter,
      "Welcome to $mapName. Everything you need is on the board behind me. "
      "Let's find out where this goes.",
      CharacterMood.smug,
    ),
  ];
  // The table talks back: up to three picked characters, seat order. Butter
  // only banters as a player if a player actually picked her.
  var spoke = 0;
  for (final ch in picked) {
    if (ch == kCharButter && players.length > 1) continue;
    beats.add(_openingLineFor(ch));
    if (++spoke >= 3) break;
  }
  beats.add(const DialogueBeat(
    kCharButter,
    "That's the spirit. Everyone spins, everyone leaves holding something. "
    "Then we clock in — the Shack won't open itself.",
    CharacterMood.neutral,
  ));
  return beats;
}

/// Butter explains what a landed wheel prize actually does — the host beat
/// between "the wheel settled" and "the player moves the game forward".
DialogueBeat wheelHostBeatFor(WheelSegment seg, PowerUp? granted) {
  if (granted != null) {
    return DialogueBeat(
      kCharButter,
      '${granted.label}. ${granted.description}. Hold it until '
      "the moment is right — you'll know.",
      CharacterMood.smug,
    );
  }
  switch (seg.kind) {
    case WheelPrizeKind.diamonds:
      return DialogueBeat(
        kCharButter,
        '+${seg.amount} diamonds, straight into your pocket. Spend them at '
        'a market, or save for the shack — potatoes live there.',
        CharacterMood.smug,
      );
    case WheelPrizeKind.loseDiamonds:
      return DialogueBeat(
        kCharButter,
        '−${seg.amount} diamonds. The wheel gives and the wheel takes. '
        'It evens out.',
        CharacterMood.neutral,
      );
    case WheelPrizeKind.atp:
      return DialogueBeat(
        kCharButter,
        '+${seg.amount} ATP — roll fuel. Spend it before a roll to reach '
        'farther down the path. The long way pays.',
        CharacterMood.smug,
      );
    case WheelPrizeKind.potatoes:
      return DialogueBeat(
        kCharButter,
        seg.amount > 1
            ? '${seg.amount} whole potatoes. That is the thing you win '
                'with. Guard them.'
            : 'A whole potato. That is the thing you win with. Guard it.',
        CharacterMood.excited,
      );
    case WheelPrizeKind.dropItem:
      return const DialogueBeat(
        kCharButter,
        'An item, gone. The wheel wanted it more.',
        CharacterMood.neutral,
      );
    case WheelPrizeKind.item:
    case WheelPrizeKind.randomItem:
      // Item spins with no granted item = the pack was full (+5 diamonds).
      return const DialogueBeat(
        kCharButter,
        'Your pack was full, so the wheel paid cash instead — +5 diamonds. '
        'The wheel is nothing if not reasonable.',
        CharacterMood.neutral,
      );
    case WheelPrizeKind.bossLastPotato:
      return const DialogueBeat(
        kCharButter,
        'You heard the decree. Finish last and a potato leaves with the big '
        'one. Play like you mean it.',
        CharacterMood.worried,
      );
    case WheelPrizeKind.bossRedistribution:
      return const DialogueBeat(
        kCharButter,
        'Every diamond on this board just became one pot. Top finishers '
        'split it — the rest stays with the big one. Go get yours.',
        CharacterMood.worried,
      );
  }
}
