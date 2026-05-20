// Haptic-feedback helpers.
//
// Centralised so every clinically-meaningful interaction uses the
// same intensity scale. The HapticFeedback platform calls are no-ops
// in widget tests and on platforms without a vibration motor — safe
// to call unconditionally.
//
// Tiers:
//   • [tap]      — light, used for selections + segmented toggles.
//   • [confirm]  — medium, used for "you committed" actions
//                  (Generate plan, Save case, Apply context).
//   • [warning]  — heavy + selection bookend, used for safety-critical
//                  results (RED ANC zone, hard rule blocks).

import 'package:flutter/services.dart';

/// Light tick — selection / segmented option.
Future<void> hapticsTap() => HapticFeedback.selectionClick();

/// Medium tick — committed clinical action.
Future<void> hapticsConfirm() => HapticFeedback.mediumImpact();

/// Heavy tick — clinically-critical alert (RED zone, hard block).
Future<void> hapticsWarning() => HapticFeedback.heavyImpact();
