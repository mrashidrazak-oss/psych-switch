// Reusable primitives for the clinical light theme. Each is a thin
// stateless widget that locks in the design language so screens stay
// uniform without re-implementing chrome:
//
//   • [SquircleCard] — borderless 28pt-radius surface, optional tone
//     fill (lavender / peach / mint / sand / rose / sky).
//   • [PillButton] — black-pill primary CTA with optional leading icon.
//   • [GhostPillButton] — outlined transparent variant for secondary
//     actions.
//   • [ProgressRing] — circular ring with a center label (Apple Health
//     activity rings, in monochrome).
//   • [AvatarCircle] — initials in a tinted bubble.
//   • [ToneTile] — square-ish tinted tile with icon + label, used in
//     quick-action grids.
//
// Every primitive accepts a [tone] argument from [ClinicalPalette] —
// pick the colour family from the screen-level intent and the
// primitive handles the shade + ink + border calculation.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';

/// A 28-pt squircle card. `tone` paints the entire surface (used on
/// hero / category cards); when `tone` is null the card defaults to
/// the neutral white surface with a hairline border.
class SquircleCard extends StatelessWidget {
  const SquircleCard({
    super.key,
    required this.child,
    this.tone,
    this.onTap,
    this.padding = const EdgeInsets.all(ClinicalSpace.lg + 4),
    this.bordered = true,
    this.radius = ClinicalRadii.card,
  });

  final Widget child;
  final Color? tone;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool bordered;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bg = tone ?? ClinicalPalette.surface;
    final card = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: bordered && tone == null
            ? Border.all(color: ClinicalPalette.border, width: 0.5)
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: ClinicalPalette.text.withValues(alpha: 0.04),
        highlightColor: ClinicalPalette.text.withValues(alpha: 0.02),
        child: card,
      ),
    );
  }
}

/// Primary black-pill CTA. Min 44pt height for clinical tap hygiene.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = false,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final btn = Material(
      color: disabled ? ClinicalPalette.ctaDisabled : ClinicalPalette.cta,
      borderRadius: BorderRadius.circular(ClinicalRadii.pill),
      child: InkWell(
        onTap: disabled
            ? null
            : () {
                unawaited(hapticsTap());
                onPressed!();
              },
        borderRadius: BorderRadius.circular(ClinicalRadii.pill),
        splashColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.04),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? ClinicalSpace.lg : ClinicalSpace.xl,
            vertical: dense ? 10 : 14,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: dense ? 14 : 16, color: ClinicalPalette.ctaText),
                const SizedBox(width: ClinicalSpace.sm),
              ],
              Text(
                label,
                style: TextStyle(
                  color: ClinicalPalette.ctaText,
                  fontSize: dense ? 13 : 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

/// Outlined transparent variant of [PillButton] — secondary actions.
class GhostPillButton extends StatelessWidget {
  const GhostPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = false,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final color =
        disabled ? ClinicalPalette.mutedStrong : ClinicalPalette.text;
    final btn = Material(
      color: Colors.transparent,
      shape: const StadiumBorder(
        side: BorderSide(
          color: ClinicalPalette.borderStrong,
        ),
      ),
      child: InkWell(
        onTap: disabled
            ? null
            : () {
                unawaited(hapticsTap());
                onPressed!();
              },
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? ClinicalSpace.lg : ClinicalSpace.xl,
            vertical: dense ? 10 : 14,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: dense ? 14 : 16, color: color),
                const SizedBox(width: ClinicalSpace.sm),
              ],
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: dense ? 13 : 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

/// Circular progress ring with a label in the center (e.g. "2/3" or
/// "47%"). Monochrome by default — pass a [tone] to tint.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.label,
    this.size = 44,
    this.thickness = 4,
    this.tone,
    this.labelStyle,
  });

  /// 0.0 to 1.0.
  final double value;
  final String label;
  final double size;
  final double thickness;
  final Color? tone;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final ring = tone ?? ClinicalPalette.text;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _RingPainter(
                value: value.clamp(0, 1).toDouble(),
                color: ring,
                trackColor: ring.withValues(alpha: 0.15),
                thickness: thickness,
              ),
            ),
          ),
          Text(
            label,
            style: labelStyle ??
                TextStyle(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w800,
                  color: ring,
                  letterSpacing: -0.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.thickness,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide / 2) - thickness / 2;

    final track = Paint()
      ..color = trackColor
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (value <= 0) return;
    final arc = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.thickness != thickness;
}

/// Circular avatar bubble. Renders initials on a tinted surface.
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.initials,
    this.size = 48,
    this.tone = ClinicalPalette.toneLavender,
    this.ink = ClinicalPalette.toneLavenderInk,
  });

  final String initials;
  final double size;
  final Color tone;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: ink,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.34,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Tone-tinted square tile with a leading icon and a label below.
/// Used in the home quick-actions grid.
class ToneTile extends StatelessWidget {
  const ToneTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.tone = ClinicalPalette.toneLavender,
    this.ink = ClinicalPalette.toneLavenderInk,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color tone;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tone,
      borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
        splashColor: ink.withValues(alpha: 0.08),
        highlightColor: ink.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ClinicalSpace.md,
            vertical: ClinicalSpace.md + 2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(ClinicalRadii.chip),
                ),
                child: Icon(icon, size: 18, color: ink),
              ),
              const SizedBox(height: ClinicalSpace.md),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ink,
                  height: 16 / 13,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped chip used in day-of-week selectors / category filters.
class DayPill extends StatelessWidget {
  const DayPill({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.tone = ClinicalPalette.tonePeach,
    this.ink = ClinicalPalette.tonePeachInk,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color tone;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ClinicalRadii.pill),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? tone : Colors.transparent,
          shape: BoxShape.circle,
          border: selected
              ? null
              : Border.all(
                  color: ClinicalPalette.border,
                  width: 0.5,
                ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? ink : ClinicalPalette.mutedStrong,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// Small inline "tag" inside cards — uppercased eyebrow on a tinted
/// pill. Useful for category labels ("ANTIPSYCHOTIC", "MOOD").
class TonePill extends StatelessWidget {
  const TonePill({
    super.key,
    required this.label,
    this.tone = ClinicalPalette.toneSky,
    this.ink = ClinicalPalette.toneSkyInk,
  });

  final String label;
  final Color tone;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ClinicalSpace.sm + 2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(ClinicalRadii.pill),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
      ),
    );
  }
}
