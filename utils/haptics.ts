// Haptic feedback wrapper.
//
// Three intensity levels mapped to common UI events:
//   • tap()      — light tap. Use for selection (radio, segment switch, toggle).
//   • confirm()  — medium impact. Use for "submit / save / send" actions
//                  that took user input and committed it.
//   • danger()   — heavy + warning notification. Use for destructive or
//                  dangerous actions ("Stop drug", "Avoid pair", etc.).
//
// Why a wrapper instead of using expo-haptics directly:
//   1. Single import surface — easier to swap or extend later.
//   2. Graceful degradation in environments without haptics (web, some
//      Android emulators, future custom dev builds without the module).
//   3. We can quickly mute everything for accessibility ("reduce motion"
//      style) without grepping the codebase. Currently always on; future
//      Settings toggle lands in v0.4+.
import * as Haptics from 'expo-haptics';

let _enabled = true;
export function setHapticsEnabled(on: boolean) {
  _enabled = on;
}

function safe(fn: () => void): void {
  if (!_enabled) return;
  try { fn(); } catch { /* no-op on platforms without haptics */ }
}

export function tap(): void {
  safe(() => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light));
}

export function confirm(): void {
  safe(() => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium));
}

export function danger(): void {
  safe(() => Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning));
}

export function success(): void {
  safe(() => Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success));
}
