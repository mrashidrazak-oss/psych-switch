// Empty state — a shared "nothing here yet, here's how to start"
// primitive. Extracted from History's polished empty state so every
// tool screen can share the same arrival language for the "before
// the user has done anything" moment.
//
// Composition:
//   • Tone-tinted glyph in a brand-gradient circle (dual-tone glow)
//   • Headline (20pt, w800, -0.4 letter-spacing)
//   • Body (caption, 1.55 line-height, centered)
//   • Optional CTA (FilledButton.icon with brand accent)
//
// Honours system reduced-motion — entrance animation skipped.

import 'package:flutter/material.dart';

import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/entrance_fade.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.headline,
    required this.body,
    super.key,
    this.ctaLabel,
    this.onCta,
    this.ctaIcon,
    this.iconTone,
    this.iconInk,
  });

  final IconData icon;
  final String headline;
  final String body;

  /// Optional CTA. When [ctaLabel] is provided, [onCta] must also be.
  final String? ctaLabel;
  final VoidCallback? onCta;
  final IconData? ctaIcon;

  /// Override the gradient ink colors. Defaults to the brand
  /// lavender→mint pair used on History.
  final Color? iconTone;
  final Color? iconInk;

  @override
  Widget build(BuildContext context) {
    final tone = iconTone ?? ClinicalPalette.toneLavenderInk;
    final ink = iconInk ?? ClinicalPalette.toneMintInk;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.xxl,
        ClinicalSpace.xl,
        ClinicalSpace.xxl,
        ClinicalSpace.xxl,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            EntranceFade(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: tone.withValues(alpha: 0.22),
                      blurRadius: 36,
                      spreadRadius: -10,
                      offset: const Offset(-6, 8),
                    ),
                    BoxShadow(
                      color: ink.withValues(alpha: 0.22),
                      blurRadius: 36,
                      spreadRadius: -10,
                      offset: const Offset(6, 8),
                    ),
                  ],
                ),
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[tone, ink],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(icon, color: Colors.white, size: 34),
                  ),
                ),
              ),
            ),
            const Gap.v(ClinicalSpace.xl),
            EntranceFade(
              index: 1,
              child: Text(
                headline,
                style: const TextStyle(
                  color: ClinicalPalette.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Gap.v(ClinicalSpace.sm + 2),
            EntranceFade(
              index: 2,
              child: Text(
                body,
                style: ClinicalText.caption.copyWith(height: 1.55),
                textAlign: TextAlign.center,
              ),
            ),
            if (ctaLabel != null && onCta != null) ...<Widget>[
              const Gap.v(ClinicalSpace.xl),
              EntranceFade(
                index: 3,
                child: FilledButton.icon(
                  onPressed: onCta,
                  icon: Icon(
                    ctaIcon ?? Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                  label: Text(ctaLabel!),
                  style: FilledButton.styleFrom(
                    backgroundColor: ClinicalPalette.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: ClinicalSpace.xl,
                      vertical: ClinicalSpace.md + 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(ClinicalRadii.card),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
