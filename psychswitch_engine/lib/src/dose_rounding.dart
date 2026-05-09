// Dose-rounding helper, shared between overlap_intensity and
// scale_schedule (Phase 2D). Lifted into its own file so the two
// modules don't depend on each other.
//
// Mirrors the `roundToIncrement` function in engine/scaleSchedule.ts
// line-for-line.

/// Round [value] to the nearest entry in a sorted [increments] array.
/// Returns 0 unchanged (it's a clinically meaningful "stop" signal).
/// Returns [value] unchanged when [increments] is empty.
num roundToIncrement(num value, List<num> increments) {
  if (value <= 0) return 0;
  if (increments.isEmpty) return value;
  var best = increments[0];
  var bestDelta = (value - best).abs();
  for (final inc in increments) {
    final delta = (value - inc).abs();
    if (delta < bestDelta) {
      best = inc;
      bestDelta = delta;
    }
  }
  return best;
}
