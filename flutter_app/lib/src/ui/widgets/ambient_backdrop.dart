// Ambient backdrop — the soft radial gradient wash that anchors
// first-impression surfaces (Disclaimer + Onboarding + future
// landing-style screens). Extracted from per-screen duplicates so
// the wash reads identically across every gate the clinician passes
// through before reaching Home.
//
// Composition:
//   • Radial gradient anchored top-left (Alignment(-0.4, -0.7))
//   • Lavender → mint → transparent
//   • Wrapped in IgnorePointer so the wash never absorbs taps
//
// Use as a Positioned.fill child of a Stack:
//
//   Stack(
//     children: [
//       const Positioned.fill(child: AmbientBackdrop()),
//       SafeArea(child: ...),
//     ],
//   )

import 'package:flutter/material.dart';

import 'package:psychswitch/src/ui/theme/clinical_theme.dart';

class AmbientBackdrop extends StatelessWidget {
  const AmbientBackdrop({
    super.key,
    this.center = const Alignment(-0.4, -0.7),
  });

  /// Source of the radial. Defaults to the top-left family used by
  /// Disclaimer. Override per-screen for variation (e.g. Onboarding
  /// uses (-0.3, -0.7)).
  final Alignment center;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: center,
            radius: 1.2,
            colors: <Color>[
              ClinicalPalette.toneLavenderInk.withValues(alpha: 0.1),
              ClinicalPalette.toneMintInk.withValues(alpha: 0.05),
              Colors.transparent,
            ],
            stops: const <double>[0, 0.45, 1],
          ),
        ),
      ),
    );
  }
}
