// Design tokens — single source of truth for the PsychSwitch palette,
// typography scale, spacing rhythm, radii, and shadow elevations.
//
// Mirrors the React Native tailwind.config.js values so we can do
// pixel-parity audits in Phase 8.
//
// Colour semantics (5-tone palette):
//   accent  — interactive primary, citations, evidence chips
//   warning — clinical caution
//   danger  — safety-critical
//   from    — from-drug identity in schedule visualisation
//   to      — to-drug identity, success states
//
// Typography scale (8 steps, paired with line heights):
//   eyebrow / micro / caption / body / subtitle / title / heading / display
//
// Spacing scale (4-pt grid, 7 steps): xxs/xs/sm/md/lg/xl/xxl
//
// Radii (4 steps): sm / md / lg / pill

import 'package:flutter/material.dart';

abstract final class AppColors {
  // Surfaces
  static const bg = Color(0xFF0B0F14);
  static const surface = Color(0xFF141A22);
  static const surfaceHigh = Color(0xFF1A222D);
  static const border = Color(0xFF1F2933);
  static const borderStrong = Color(0xFF2A3441);

  // Content
  static const text = Color(0xFFE6EDF3);
  static const muted = Color(0xFF8B949E);
  static const mutedStrong = Color(0xFFB1B9C2);

  // Semantic
  static const accent = Color(0xFF3B82F6);
  static const accentDim = Color(0xFF1E3A8A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const success = Color(0xFF34D399);

  // Drug identity
  static const from = Color(0xFF60A5FA);
  static const to = Color(0xFF34D399);
}

/// Spacing scale on a 4-pt grid. Keeps vertical and horizontal rhythm
/// consistent across screens — never write a raw `SizedBox(height: 13)`
/// or magic-number padding outside genuinely one-off layouts.
abstract final class AppSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Radii scale. `pill` = fully rounded for status pills/chips.
abstract final class AppRadii {
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 12;
  static const double xl = 16;
  static const double pill = 999;
}

/// 8-step typography scale. Mirrors tailwind.config.js exactly.
/// Each entry is paired with its line-height to prevent rhythm drift.
abstract final class AppTextSizes {
  static const TextStyle eyebrow = TextStyle(
    fontSize: 10,
    height: 14 / 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: AppColors.muted,
  );
  static const TextStyle micro = TextStyle(
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );
  static const TextStyle title = TextStyle(
    fontSize: 20,
    height: 24 / 20,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static const TextStyle heading = TextStyle(
    fontSize: 24,
    height: 28 / 24,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static const TextStyle display = TextStyle(
    fontSize: 30,
    height: 36 / 30,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
    letterSpacing: -0.6,
  );
}

/// Convenience vertical-gap helper. `Gap.v(AppSpace.lg)` reads better
/// than `SizedBox(height: 16)` and forces every spacing decision to go
/// through the scale.
class Gap extends StatelessWidget {
  const Gap.v(this.size, {super.key}) : _isVertical = true;
  const Gap.h(this.size, {super.key}) : _isVertical = false;

  final double size;
  final bool _isVertical;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _isVertical ? null : size,
      height: _isVertical ? size : null,
    );
  }
}
