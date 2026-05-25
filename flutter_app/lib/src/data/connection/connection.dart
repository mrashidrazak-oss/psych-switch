// Database connection — conditional-import shim.
//
// Drift uses dart:ffi on native platforms (Android, iOS, macOS,
// Linux, Windows) and a sqlite3 WebAssembly module on the web. This
// file is the single import point; the platform-specific
// implementations live in `connection_native.dart` and
// `connection_web.dart`.

import 'package:drift/drift.dart';

import 'package:psychswitch/src/data/connection/connection_stub.dart'
    if (dart.library.io) 'connection_native.dart'
    if (dart.library.js_interop) 'connection_web.dart';

/// Open the per-platform database backend. Native = sqlite file under
/// the app's documents directory. Web = sqlite3 WASM module with an
/// IndexedDB-backed persistence layer.
LazyDatabase openConnection() => openPlatformConnection();

/// In-memory executor used by unit tests (the `AppDatabase.memory()`
/// constructor). On native that's `NativeDatabase.memory()`; on web
/// it's the WASM equivalent — `WasmDatabase.inMemory()`.
QueryExecutor memoryConnection() => memoryPlatformConnection();
