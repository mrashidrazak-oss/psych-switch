// Fallback when neither dart:io nor dart:js_interop is available
// (e.g. analyzer / unit tests outside a platform context). The stub
// throws — production code never reaches it because every supported
// target has one of the two libraries.

import 'package:drift/drift.dart';

LazyDatabase openPlatformConnection() {
  throw UnsupportedError(
    'No drift connection for the current platform.',
  );
}

QueryExecutor memoryPlatformConnection() {
  throw UnsupportedError(
    'No drift memory connection for the current platform.',
  );
}
