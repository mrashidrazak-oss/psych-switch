// Drift web worker — handles sqlite3 WASM database operations in a
// background thread so the main UI thread stays responsive. Compiled
// to JS via:
//
//   dart compile js -O4 web/drift_worker.dart -o web/drift_worker.dart.js
//
// The compiled artifact is referenced by `connection_web.dart` via
// `Uri.parse('drift_worker.dart.js')`. Both files are served at the
// site root by the Flutter web build.

import 'package:drift/wasm.dart';

void main() {
  WasmDatabase.workerMainForOpen();
}
