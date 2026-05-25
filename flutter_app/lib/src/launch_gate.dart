// Staged-launch gate.
//
// For the closed-beta launch we surface only the Switch hero plus a
// curated set of five high-use clinical tools. Every other screen
// stays fully built and ROUTED — it is only hidden from Home and
// search. To reveal more in a future release, either flip [staged]
// to false (reveals everything) or add route names to [allowed].
//
// Route names here are the string values of the Routes constants in
// router.dart (kept as literals to avoid an import cycle).
abstract final class LaunchGate {
  /// When true, Home + search show only the curated launch surface.
  /// `final` (not `const`) so the gated `else` branches don't trip
  /// the dead-code analyzer while staged is hard-set.
  // ignore: prefer_const_declarations
  static final bool staged = true;

  /// Tools surfaced alongside the always-on Switch hero in staged
  /// mode. Values must match the Routes constants' string values.
  static const allowed = <String>{
    'equivalency', // dose equivalents
    'adverse_effects', // AE profile
    'polypharmacy', // DDI / interaction + burden checker
    'clozapine', // clozapine module — titration / FBC / ANC / rechallenge
    'scales', // rating scales
    'suicide_risk', // composite suicide risk assessment
  };

  /// True if [route] should be visible on Home / in search results.
  static bool isVisible(String route) =>
      !staged || allowed.contains(route);
}
