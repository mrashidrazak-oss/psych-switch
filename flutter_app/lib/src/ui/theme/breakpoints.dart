// Responsive breakpoints — single source of truth for "is this a
// foldable / tablet / wide window?".
//
// Material 3 window-size classes give us three useful tiers:
//   • compact   < 600          — typical phone (Pixel, iPhone)
//   • medium    600–839        — large phone, foldable cover screen,
//                                small tablet portrait
//   • expanded  ≥ 840          — foldable inner screen, tablet
//                                landscape, desktop
//
// We anchor the wide-layout switch at `expanded` (≥ 840) deliberately:
//   1. The Galaxy Z Fold 6 unfolded inner screen lands here (~1100
//      logical px wide), the cover screen does not.
//   2. The flutter_test default viewport (800×600) stays in `medium`,
//      so existing widget tests don't suddenly start exercising the
//      two-column code paths.
//   3. We never want to two-column on a phone in landscape — the
//      content density drops below comfortable.
//
// `BuildContext.isWide` is the one-line shorthand every screen uses:
//
//     Widget build(BuildContext context) {
//       if (context.isWide) return const _WideLayout();
//       return const _NarrowLayout();
//     }

import 'package:flutter/widgets.dart';

/// Material 3 window-size class constants (logical pixels).
abstract final class Breakpoints {
  /// Phones in portrait — single column.
  static const double compact = 600;

  /// Large phones / foldable cover / small tablet portrait.
  static const double medium = 840;

  /// Foldable inner / tablet landscape / desktop.
  static const double expanded = 1200;
}

extension WindowSizeContext on BuildContext {
  /// Width-only window-size class. Sufficient for our layouts —
  /// height-aware adaptation only matters for landscape phones,
  /// which we don't promote to the wide path anyway.
  WindowSize get windowSize {
    final w = MediaQuery.sizeOf(this).width;
    if (w >= Breakpoints.medium) return WindowSize.expanded;
    if (w >= Breakpoints.compact) return WindowSize.medium;
    return WindowSize.compact;
  }

  /// True when the layout should render its two-column variant —
  /// foldable inner, tablet, desktop.
  bool get isWide => windowSize == WindowSize.expanded;
}

enum WindowSize { compact, medium, expanded }
