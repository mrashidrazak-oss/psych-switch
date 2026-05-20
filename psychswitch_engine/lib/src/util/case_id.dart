// Case-id minter — short, sortable, collision-free enough for a
// single-device on-device store. Format:
//
//   <epoch-ms-radix36>-<4-hex-random>
//
// e.g. `lvz86q1z-a3f4`. Sorts the same as creation time, fits in
// a list view header, and collisions across a single user's cases
// over decades are essentially impossible.

import 'dart:math';

String mintCaseId({DateTime? now, Random? random}) {
  final ts = (now ?? DateTime.now()).millisecondsSinceEpoch.toRadixString(36);
  final rnd = random ?? Random();
  final suffix = rnd.nextInt(0xFFFF).toRadixString(16).padLeft(4, '0');
  return '$ts-$suffix';
}
