// Polished toast — brand-aligned floating SnackBars to replace the
// generic Material defaults across the app.
//
// Two helpers covering the two micro-moments that mattered most in
// audit: copy-to-clipboard confirmation and save-case affirmation.
//
//   • [showCopiedToast]  — accent-tinted, copy glyph, label of what
//                          was copied. Calm informative.
//   • [showSavedToast]   — mint-tinted, checkmark, brief affirmation
//                          of what was just saved. Celebratory but
//                          restrained.
//
// Both use SnackBarBehavior.floating with a rounded surface, brief
// duration, and a leading icon — so the toast reads as a *moment*,
// not a system notification. Honours system reduced-motion via the
// SnackBar's own animation timing.

import 'package:flutter/material.dart';

import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';

/// Show an accent-tinted "Copied · <label>" toast. Dismisses any
/// current toast first so rapid double-taps don't queue.
void showCopiedToast(
  BuildContext context, {
  required String label,
}) {
  _show(
    context,
    icon: Icons.check_rounded,
    eyebrow: 'Copied',
    label: label,
    tone: ClinicalPalette.accent,
  );
}

/// Show a mint-tinted "Saved · <label>" toast for case saves +
/// kindred affirmations. Slightly different ink so the user knows
/// "this is now mine" vs "I just copied something".
void showSavedToast(
  BuildContext context, {
  required String label,
}) {
  _show(
    context,
    icon: Icons.bookmark_added_rounded,
    eyebrow: 'Saved',
    label: label,
    tone: ClinicalPalette.toneMintInk,
  );
}

void _show(
  BuildContext context, {
  required IconData icon,
  required String eyebrow,
  required String label,
  required Color tone,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ClinicalPalette.surface,
        elevation: 6,
        margin: const EdgeInsets.symmetric(
          horizontal: ClinicalSpace.lg,
          vertical: ClinicalSpace.md,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: ClinicalSpace.md + 2,
          vertical: ClinicalSpace.sm + 4,
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: ClinicalPalette.border.withValues(alpha: 0.6),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(ClinicalRadii.card),
        ),
        duration: const Duration(seconds: 2),
        content: Row(
          children: <Widget>[
            // Leading tinted-tone glyph.
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: tone),
            ),
            const Gap.h(ClinicalSpace.sm + 2),
            // Two-line content — eyebrow above, detail below.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    eyebrow.toUpperCase(),
                    style: TextStyle(
                      color: tone,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      color: ClinicalPalette.text,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
}
