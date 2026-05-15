// Clinical light theme — a soft, modern Apple-Health-meets-Roam visual
// language built for daytime clinical use:
//
//   • Squircle cards (24–28 pt radius) with a hairline tint border
//     and 0-elevation surface (no soft shadows — keeps it crisp)
//   • Pastel tone fills (lavender / peach / mint / sand) on hero +
//     category cards
//   • Black-pill primary CTAs (sharp contrast against the soft fills)
//   • Bold + medium type pairing, generous line-height
//   • Progress rings for state (% complete, days into a switch, etc.)
//   • Big-radius avatar bubble for the clinician greeting
//
// This file is the *palette + primitives* for the new language. The
// existing dark theme stays the default for the whole app; new screens
// opt in by wrapping themselves in [Theme(data: buildClinicalTheme(), …)].
// Over time we migrate every screen and flip the default.
//
// Reference: the Roam / Learning-App moodboard the founder attached on
// 2026-05-15 — soft pastel surfaces, big avatar, "JOIN NOW" black-pill
// CTA, day-of-week pill row, color-coded category tiles with progress
// rings.

import 'package:flutter/material.dart';

/// Hand-picked clinical-light palette. Saturated enough to feel
/// premium, restrained enough to read as medical (not edu-tainment).
abstract final class ClinicalPalette {
  // ── Surfaces ────────────────────────────────────────────────────
  /// App background — the "paper" behind every card.
  static const bg = Color(0xFFF4F5F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF8F9FB);
  static const border = Color(0xFFE7EAF0);
  static const borderStrong = Color(0xFFD6DBE3);

  // ── Content ─────────────────────────────────────────────────────
  static const text = Color(0xFF0E1116);
  static const muted = Color(0xFF6B7280);
  static const mutedStrong = Color(0xFF4B5360);

  // ── CTAs ────────────────────────────────────────────────────────
  /// Primary CTA — true black pill (high contrast against pastel fills).
  static const cta = Color(0xFF111418);
  static const ctaText = Color(0xFFFFFFFF);
  static const ctaDisabled = Color(0xFFCBD2DC);

  // ── Tone fills (large card backgrounds) ────────────────────────
  /// Lavender — antidepressants, switch hero.
  static const toneLavender = Color(0xFFDDE3FF);
  static const toneLavenderInk = Color(0xFF3B4280);

  /// Peach — antipsychotics, alerts.
  static const tonePeach = Color(0xFFFFE0CC);
  static const tonePeachInk = Color(0xFF8C3E0F);

  /// Mint — mood stabilisers, success.
  static const toneMint = Color(0xFFCBEED9);
  static const toneMintInk = Color(0xFF1F5A38);

  /// Rose — anti-anxiety, clozapine.
  static const toneRose = Color(0xFFFFD5E1);
  static const toneRoseInk = Color(0xFF8A1F44);

  /// Sand — calculators, references.
  static const toneSand = Color(0xFFFFEFC2);
  static const toneSandInk = Color(0xFF7A5300);

  /// Sky — search, info.
  static const toneSky = Color(0xFFCCE7FF);
  static const toneSkyInk = Color(0xFF1F4F7E);

  // ── Semantic ────────────────────────────────────────────────────
  static const accent = Color(0xFF3B82F6);
  static const warning = Color(0xFFEF8A1F);
  static const danger = Color(0xFFDC2A2A);
  static const success = Color(0xFF1F9D55);
}

/// Spacing / radius scale for the clinical theme. Slightly more
/// generous than the dark theme — squircles need air.
abstract final class ClinicalSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

abstract final class ClinicalRadii {
  /// Card corner — feels like a squircle at these dimensions.
  static const double card = 28;

  /// Tile corner — slightly tighter, used inside cards.
  static const double tile = 20;
  static const double chip = 14;
  static const double pill = 999;
}

/// Typography scale. Bold display + medium body, generous height.
abstract final class ClinicalText {
  static const TextStyle display = TextStyle(
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w800,
    color: ClinicalPalette.text,
    letterSpacing: -0.6,
  );
  static const TextStyle heading = TextStyle(
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w800,
    color: ClinicalPalette.text,
    letterSpacing: -0.3,
  );
  static const TextStyle title = TextStyle(
    fontSize: 18,
    height: 23 / 18,
    fontWeight: FontWeight.w700,
    color: ClinicalPalette.text,
    letterSpacing: -0.1,
  );
  static const TextStyle subtitle = TextStyle(
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w600,
    color: ClinicalPalette.text,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    color: ClinicalPalette.text,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    color: ClinicalPalette.muted,
  );
  static const TextStyle eyebrow = TextStyle(
    fontSize: 10,
    height: 14 / 10,
    fontWeight: FontWeight.w700,
    color: ClinicalPalette.muted,
    letterSpacing: 1.5,
  );
}

/// Build the Material 3 ThemeData for the clinical light theme.
///
/// This is the app's ROOT theme (set on MaterialApp.theme in main.dart).
/// Every Material widget — AppBars, TextFields, Cards, Dialogs, Sheets,
/// Buttons, Switches, Tabs, Scrollbars — inherits the clinical-light
/// language from these sub-themes. Individual screens don't need to
/// re-wrap in `Theme(buildClinicalTheme(), …)` any more.
ThemeData buildClinicalTheme() {
  const colorScheme = ColorScheme.light(
    // Explicit even though it matches the Material default — locks the
    // surface color so a future Material upgrade can't drift it.
    // ignore: avoid_redundant_argument_values
    surface: ClinicalPalette.surface,
    onSurface: ClinicalPalette.text,
    primary: ClinicalPalette.cta,
    secondary: ClinicalPalette.accent,
    onSecondary: Colors.white,
    error: ClinicalPalette.danger,
    outline: ClinicalPalette.border,
    outlineVariant: ClinicalPalette.borderStrong,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: ClinicalPalette.bg,
    canvasColor: ClinicalPalette.bg,
    colorScheme: colorScheme,

    // ── App bars ────────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: ClinicalPalette.bg,
      foregroundColor: ClinicalPalette.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: ClinicalSpace.sm,
      iconTheme: IconThemeData(color: ClinicalPalette.text, size: 22),
      titleTextStyle: TextStyle(
        color: ClinicalPalette.text,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),

    // ── Tab bars ────────────────────────────────────────────────────
    tabBarTheme: const TabBarThemeData(
      indicatorColor: ClinicalPalette.cta,
      labelColor: ClinicalPalette.cta,
      unselectedLabelColor: ClinicalPalette.muted,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: ClinicalPalette.border,
    ),

    // ── Cards ───────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: ClinicalPalette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
        side: const BorderSide(color: ClinicalPalette.border, width: 0.5),
      ),
    ),

    // ── Dialogs ─────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: ClinicalPalette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ClinicalRadii.card),
      ),
      titleTextStyle: const TextStyle(
        color: ClinicalPalette.text,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: const TextStyle(
        color: ClinicalPalette.mutedStrong,
        fontSize: 14,
        height: 1.5,
      ),
    ),

    // ── Snack bars ──────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ClinicalPalette.cta,
      contentTextStyle: const TextStyle(
        color: ClinicalPalette.ctaText,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ClinicalRadii.chip),
      ),
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: ClinicalSpace.lg,
        vertical: ClinicalSpace.md,
      ),
    ),

    // ── Bottom sheets ───────────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: ClinicalPalette.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: ClinicalPalette.surface,
      modalBarrierColor: Color(0x66000000),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ClinicalRadii.card),
        ),
      ),
    ),

    // ── Dividers ────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: ClinicalPalette.border,
      thickness: 0.5,
      space: 0.5,
    ),

    // ── Icons ───────────────────────────────────────────────────────
    iconTheme: const IconThemeData(color: ClinicalPalette.text, size: 20),

    // ── Buttons ─────────────────────────────────────────────────────
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ClinicalPalette.cta,
        foregroundColor: ClinicalPalette.ctaText,
        disabledBackgroundColor: ClinicalPalette.ctaDisabled,
        disabledForegroundColor: ClinicalPalette.mutedStrong,
        padding: const EdgeInsets.symmetric(
          horizontal: ClinicalSpace.xl,
          vertical: 14,
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        shape: const StadiumBorder(),
        minimumSize: const Size(0, 44),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ClinicalPalette.text,
        side: const BorderSide(color: ClinicalPalette.borderStrong),
        padding: const EdgeInsets.symmetric(
          horizontal: ClinicalSpace.xl,
          vertical: 12,
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        shape: const StadiumBorder(),
        minimumSize: const Size(0, 44),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ClinicalPalette.text,
        padding: const EdgeInsets.symmetric(
          horizontal: ClinicalSpace.md,
          vertical: ClinicalSpace.sm,
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        minimumSize: const Size(0, 40),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: ClinicalPalette.text,
        minimumSize: const Size(44, 44),
      ),
    ),

    // ── Switches ────────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return ClinicalPalette.muted;
        }
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return ClinicalPalette.cta;
        }
        return ClinicalPalette.borderStrong;
      }),
      trackOutlineColor:
          const WidgetStatePropertyAll(Colors.transparent),
    ),

    // ── Inputs ──────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ClinicalPalette.surfaceMuted,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: ClinicalSpace.md,
        vertical: 14,
      ),
      labelStyle:
          const TextStyle(color: ClinicalPalette.muted, fontSize: 13),
      hintStyle:
          const TextStyle(color: ClinicalPalette.muted, fontSize: 14),
      floatingLabelStyle: const TextStyle(
        color: ClinicalPalette.cta,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ClinicalRadii.chip + 2),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ClinicalRadii.chip + 2),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ClinicalRadii.chip + 2),
        borderSide:
            const BorderSide(color: ClinicalPalette.cta, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ClinicalRadii.chip + 2),
        borderSide: const BorderSide(color: ClinicalPalette.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ClinicalRadii.chip + 2),
        borderSide:
            const BorderSide(color: ClinicalPalette.danger, width: 1.5),
      ),
    ),

    // ── List tiles ──────────────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      iconColor: ClinicalPalette.mutedStrong,
      textColor: ClinicalPalette.text,
      tileColor: ClinicalPalette.surface,
      contentPadding: EdgeInsets.symmetric(
        horizontal: ClinicalSpace.lg,
        vertical: ClinicalSpace.xs,
      ),
    ),

    // ── Progress indicators ─────────────────────────────────────────
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: ClinicalPalette.cta,
      circularTrackColor: ClinicalPalette.border,
      strokeWidth: 2.5,
    ),

    // ── Scrollbar ───────────────────────────────────────────────────
    scrollbarTheme: ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll(4),
      thumbColor: WidgetStatePropertyAll(
        ClinicalPalette.muted.withValues(alpha: 0.4),
      ),
      radius: const Radius.circular(ClinicalRadii.pill),
    ),

    // ── Splash / hover ─────────────────────────────────────────────
    splashFactory: InkSparkle.splashFactory,
    splashColor: ClinicalPalette.text.withValues(alpha: 0.04),
    highlightColor: ClinicalPalette.text.withValues(alpha: 0.02),
    hoverColor: ClinicalPalette.text.withValues(alpha: 0.02),

    // ── Dividers ────────────────────────────────────────────────────
    dividerColor: ClinicalPalette.border,
  );
}
