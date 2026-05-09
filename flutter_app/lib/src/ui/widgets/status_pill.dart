// Shared status pill — used everywhere a labelled status indicator
// appears (Result status, ready badge, tier tags, FBC zone, etc).
//
// Standardises the pill geometry (4-pt vertical padding, pill radius,
// 12% tinted bg, 40% tinted border, eyebrow-weight label) so the look
// stays consistent across screens.

import 'package:flutter/material.dart';

import 'package:psychswitch/src/ui/theme/tokens.dart';

/// Compact, fully-rounded status pill. Pass [tone] for the colour
/// family, [label] for the text, optional [dot] to show the leading
/// status dot, and optional [icon] for an inline glyph.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.tone,
    this.dot = false,
    this.icon,
    this.compact = false,
  });

  final String label;
  final Color tone;
  final bool dot;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hPad = compact ? AppSpace.sm : AppSpace.md;
    final vPad = compact ? 3.0 : 5.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        border: Border.all(color: tone.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (dot) ...<Widget>[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: tone,
                shape: BoxShape.circle,
              ),
            ),
            const Gap.h(AppSpace.sm),
          ],
          if (icon != null) ...<Widget>[
            Icon(icon, color: tone, size: compact ? 11 : 13),
            const Gap.h(AppSpace.xs),
          ],
          Text(
            label,
            style: TextStyle(
              color: tone,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
