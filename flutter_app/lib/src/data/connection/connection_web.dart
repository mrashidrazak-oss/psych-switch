// Web drift connection — sqlite3 compiled to WebAssembly +
// IndexedDB-backed persistence.
//
// Requires two files under `web/`:
//   • sqlite3.wasm        — the WebAssembly sqlite3 binary
//   • drift_worker.dart.js — drift's web worker bundle
//
// Both are served as static assets at the site root by Flutter's web
// dev server / production build. The clinician's saved cases persist
// across page reloads via IndexedDB.

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

LazyDatabase openPlatformConnection() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'psychswitch',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
    );
    return result.resolvedExecutor;
  });
}

QueryExecutor memoryPlatformConnection() {
  throw UnsupportedError(
    'Memory connection not supported on web — tests run on the host.',
  );
}
