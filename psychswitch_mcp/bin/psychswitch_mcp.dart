// PsychSwitch MCP server — entry point.
//
// Reads JSON-RPC requests from stdin, writes responses to stdout.
// Wire to Claude Desktop / Cursor via the snippet in README.md.
//
// Privacy: the server makes no network calls. The only I/O is
// reading the /content/ directory at startup + the MCP transport.
// Patient data is never written or persisted.
//
// Boot logs go to stderr so they don't interfere with the JSON-RPC
// stream on stdout.

import 'dart:io';

import 'package:psychswitch_mcp/psychswitch_mcp.dart';

Future<void> main(List<String> argv) async {
  stderr.writeln('psychswitch-mcp v$serverVersion booting...');
  final ServerContent content;
  try {
    content = await loadServerContent();
    stderr.writeln(
      '✓ engine loaded — '
      '${content.engine.listAllDrugs().length} drugs, '
      '${content.engine.listRules().length} reviewed rules',
    );
  } on Object catch (e) {
    stderr.writeln('✗ failed to load engine: $e');
    exit(1);
  }
  final handlers = buildHandlers(content);
  stderr
    ..writeln('✓ ${handlers.length} tools registered')
    ..writeln('listening on stdio...');
  await runServer(handlers: handlers);
}
