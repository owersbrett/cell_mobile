import 'package:flutter/material.dart';

import 'potatuhs.dart';

/// Hot Potato Games component kit — the design system's reserved `GameCard` /
/// `GameList` components, built for this app's dark theme.
///
/// Source of truth: `~/Potatuhs/potatuhs-design/DESIGN.md` §11 (layout levels)
/// and `library/src/verticals/hotpotatogames/tokens.css`. A game list is a
/// Level-4 "Card" surface: 16px radius, thick border, HARD-OFFSET shadow (no
/// blur) — the comic sticker edge. On dark, the ink offset is invisible, so
/// the offset is tinted with the card's accent instead (the HPG tokens already
/// tint their shadows gold: `8px 8px 0 rgba(212,160,23,.35)`).
///
/// Components take plain values (labels, colors, callbacks) — never catalog or
/// registry types — so any screen can compose them.
class HpgKit {
  HpgKit._();

  /// Division accent — HPG gold (`--v-accent`), warmer than the brand-gradient
  /// gold and reserved for division chrome: chips, badges, emphasis.
  static const Color gold = Color(0xFFD4A017);

  /// `--v-accent-soft`: gold at 10% for quiet fills.
  static const Color goldSoft = Color(0x1AD4A017);

  /// Humanizes a camelCase identifier: `supplyChain` → `Supply Chain`.
  static String humanize(String camel) {
    final spaced = camel.replaceAllMapped(
      RegExp(r'(?<=[a-z])(?=[A-Z])'),
      (_) => ' ',
    );
    return spaced
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

/// Level-4 card surface: panel fill, 16px radius, accent-tinted border and a
/// hard-offset accent shadow. Pressing sinks the card into its shadow
/// (translate toward the offset, offset shrinks) per the DESIGN.md motion spec.
class HpgCard extends StatefulWidget {
  final Widget child;
  final Color accent;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  /// Rest shadow offset; press drops it to 1px. Design spec is 8px for hero
  /// cards — list rows default tighter so a dense list stays readable.
  final double shadowOffset;

  const HpgCard({
    super.key,
    required this.child,
    required this.accent,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.margin = const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
    this.shadowOffset = 4,
  });

  @override
  State<HpgCard> createState() => _HpgCardState();
}

class _HpgCardState extends State<HpgCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final offset = _down ? 1.0 : widget.shadowOffset;
    final sink = widget.shadowOffset - offset;
    return Padding(
      // Reserve the shadow's footprint so rows don't overlap it.
      padding: widget.margin.add(EdgeInsets.only(
          right: widget.shadowOffset, bottom: widget.shadowOffset)),
      child: GestureDetector(
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: widget.onTap == null
            ? null
            : (_) {
                setState(() => _down = false);
                widget.onTap!();
              },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(sink, sink, 0),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: Potatuhs.inkPanel,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: widget.accent.withValues(alpha: 0.45), width: 2),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withValues(alpha: 0.30),
                offset: Offset(offset, offset),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Circular rank pill: accent-soft fill, accent ring, Outfit-extrabold letter.
/// Dynamic content never wears the display face (DESIGN.md type law).
class HpgRankBadge extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback? onTap;
  final double size;

  const HpgRankBadge({
    super.key,
    required this.label,
    required this.accent,
    this.onTap,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(color: accent.withValues(alpha: 0.7), width: 2),
        ),
        child: Text(
          label,
          style: Potatuhs.body(
            size: size * 0.42,
            weight: FontWeight.w800,
            color: accent,
          ),
        ),
      ),
    );
  }
}

/// Selectable pill chip (sort/filter rails). Selected = gold-soft fill + gold
/// ring; unselected = quiet outline. Pill shape per the badge system.
class HpgChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const HpgChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? HpgKit.goldSoft : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected
                ? HpgKit.gold.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.14),
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: Potatuhs.body(
            size: 11,
            weight: FontWeight.w700,
            color: selected ? HpgKit.gold : Potatuhs.textSecondary,
            spacing: 0.8,
          ),
        ),
      ),
    );
  }
}

/// Rounded search field in the panel surface, Outfit body text.
class HpgSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const HpgSearchField({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: Potatuhs.body(size: 14),
      decoration: InputDecoration(
        isDense: true,
        prefixIcon:
            const Icon(Icons.search, size: 18, color: Potatuhs.textFaint),
        hintText: hint,
        hintStyle: Potatuhs.body(size: 13, color: Potatuhs.textFaint),
        filled: true,
        fillColor: Potatuhs.inkPanel,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.10), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide:
              BorderSide(color: HpgKit.gold.withValues(alpha: 0.7), width: 2),
        ),
      ),
    );
  }
}

/// Primary per-row action: a bright accent disc with an ink glyph and ink
/// border — the PotatuhsButton sticker language at icon size.
class HpgPlayButton extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;
  final IconData icon;
  final String? tooltip;
  final double size;

  const HpgPlayButton({
    super.key,
    required this.accent,
    required this.onTap,
    this.icon = Icons.play_arrow_rounded,
    this.tooltip,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: accent,
          shape: BoxShape.circle,
          border: Border.all(color: Potatuhs.ink, width: 2),
        ),
        child: Icon(icon, color: Potatuhs.ink, size: size * 0.6),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Quiet stroked icon action (secondary row/header actions).
class HpgIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;

  const HpgIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = Potatuhs.textSecondary,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: color, size: 22),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// The GameCard row: rank badge · title (display face) + scale label ·
/// rate / quick-match / play actions. Pure values in, callbacks out.
class HpgGameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String rankLabel;
  final Color accent;
  final bool hasNote;
  final VoidCallback onPlay;
  final VoidCallback onRate;

  /// Non-null shows the "play with friends" action.
  final VoidCallback? onQuickMatch;

  const HpgGameCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.rankLabel,
    required this.accent,
    required this.hasNote,
    required this.onPlay,
    required this.onRate,
    this.onQuickMatch,
  });

  @override
  Widget build(BuildContext context) {
    return HpgCard(
      accent: accent,
      onTap: onPlay,
      child: Row(
        children: [
          HpgRankBadge(label: rankLabel, accent: accent, onTap: onRate),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Potatuhs.display(size: 13, spacing: 0.3),
                      ),
                    ),
                    if (hasNote) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.mode_comment_outlined,
                          size: 12, color: accent.withValues(alpha: 0.85)),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle.toUpperCase(),
                  style: Potatuhs.body(
                    size: 10,
                    weight: FontWeight.w700,
                    color: Potatuhs.textFaint,
                    spacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRate,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Text(
                'RATE',
                style: Potatuhs.body(
                  size: 11,
                  weight: FontWeight.w800,
                  color: Potatuhs.textSecondary,
                  spacing: 1.2,
                ),
              ),
            ),
          ),
          if (onQuickMatch != null)
            HpgIconButton(
              icon: Icons.groups_2_outlined,
              color: accent.withValues(alpha: 0.9),
              onTap: onQuickMatch!,
              tooltip: 'Play with friends',
            ),
          const SizedBox(width: 2),
          HpgPlayButton(accent: accent, onTap: onPlay, tooltip: 'Play'),
        ],
      ),
    );
  }
}
