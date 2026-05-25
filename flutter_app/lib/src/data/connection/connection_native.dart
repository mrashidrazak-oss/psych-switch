// Native (Android / iOS / macOS / Linux / Windows) drift connection.
// Opens a sqlite file under the app's documents directory.

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

LazyDatabase openPlatformConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'psychswitch.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

QueryExecutor memoryPlatformConnection() => NativeDatabase.memory();
