// Design tokens — single source of truth for the PsychSwitch palette
// + typography scale. Mirrors the React Native tailwind.config.js
// values exactly so we can do pixel-parity audits in Phase 8.
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

import 'package:flutter/material.dart';

abstract final class AppColors {
  static const bg = Color(0xFF0B0F14);
  static const surface = Color(0xFF141A22);
  static const border = Color(0xFF1F2933);
  static const text = Color(0xFFE6EDF3);
  static const muted = Color(0xFF8B949E);
  static const accent = Color(0xFF3B82F6);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const from = Color(0xFF60A5FA);
  static const to = Color(0xFF34D399);
}

/// 8-step typography scale. Mirrors tailwind.config.js exactly.
/// Each entry is paired with its line-height to prevent rhythm drift.
abstract final class AppTextSizes {
  static const TextStyle eyebrow = TextStyle(
    fontSize: 10,
    height: 14 / 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
  );
  static const TextStyle micro = TextStyle(
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle title = TextStyle(
    fontSize: 20,
    height: 24 / 20,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle heading = TextStyle(
    fontSize: 24,
    height: 28 / 24,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle display = TextStyle(
    fontSize: 30,
    height: 36 / 30,
    fontWeight: FontWeight.w800,
  );
}
