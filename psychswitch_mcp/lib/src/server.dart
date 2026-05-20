// MCP server — JSON-RPC 2.0 over stdio.
//
// Implements the subset of the Model Context Protocol that
// PsychSwitch needs:
//   • initialize           → handshake (capabilities + server info)
//   • tools/list           → returns the 18 tool descriptors
//   • tools/call           → dispatches to a handler in handlers.dart
//
// Wire format: each request is one JSON object on a single stdin line
// (LSP-style Content-Length framing is NOT used by current MCP
// clients over stdio). Responses are written one JSON object per line
// to stdout. Stderr is reserved for human-readable boot logging so
// the client never sees it as protocol noise.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:psychswitch_mcp/src/handlers.dart';
import 'package:psychswitch_mcp/src/tools.dart';

/// Server name + version surfaced to MCP clients.
const String serverName = 'psychswitch';
const String serverVersion = '0.5.0-alpha.0';

/// Boot the server. Reads JSON-RPC requests from [stdin] and writes
/// responses to [stdout] until the client closes the pipe.
Future<void> runServer({
  required HandlerRegistry handlers,
  Stream<String>? input,
  IOSink? output,
}) async {
  final out = output ?? stdout;
  final lines = input ??
      stdin.transform(utf8.decoder).transform(const LineSplitter());

  await for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final response = await _handleLine(trimmed, handlers);
    if (response != null) {
      out.writeln(jsonEncode(response));
      await out.flush();
    }
  }
}

Future<Map<String, dynamic>?> _handleLine(
  String line,
  HandlerRegistry handlers,
) async {
  Map<String, dynamic> request;
  try {
    request = jsonDecode(line) as Map<String, dynamic>;
  } on FormatException catch (e) {
    return _error(null, -32700, 'Parse error: ${e.message}');
  }

  // Notifications (no `id`) — process and return nothing.
  final id = request['id'];
  final method = request['method'] as String?;
  if (method == null) {
    return _error(id, -32600, 'Invalid Request: method missing');
  }
  final params = request['params'] as Map<String, dynamic>? ?? const {};

  try {
    final result = await _dispatch(method, params, handlers);
    if (id == null) return null; // notification
    return <String, dynamic>{
      'jsonrpc': '2.0',
      'id': id,
      'result': result,
    };
  } on _RpcException catch (e) {
    return _error(id, e.code, e.message);
  } on Object catch (e, st) {
    stderr.writeln('Internal error in $method: $e\n$st');
    return _error(id, -32603, 'Internal error: $e');
  }
}

Future<Object?> _dispatch(
  String method,
  Map<String, dynamic> params,
  HandlerRegistry handlers,
) async {
  switch (method) {
    case 'initialize':
      // Echo the client's protocol version (defaults to a recent
      // supported one if absent).
      final protocolVersion =
          (params['protocolVersion'] as String?) ?? '2024-11-05';
      return <String, dynamic>{
        'protocolVersion': protocolVersion,
        'capabilities': <String, dynamic>{
          'tools': <String, dynamic>{},
        },
        'serverInfo': <String, dynamic>{
          'name': serverName,
          'version': serverVersion,
        },
      };

    case 'notifications/initialized':
      // No-op acknowledgement; clients send this after the
      // initialize round-trip completes.
      return null;

    case 'tools/list':
      return <String, dynamic>{'tools': toolDescriptors};

    case 'tools/call':
      final name = params['name'] as String?;
      if (name == null) {
        throw _RpcException(-32602, 'tools/call: name missing');
      }
      final handler = handlers[name];
      if (handler == null) {
        throw _RpcException(
          -32601,
          'Unknown tool: "$name". Call tools/list to see available tools.',
        );
      }
      final args = params['arguments'] as Map<String, dynamic>? ?? const {};
      try {
        final result = await handler(args);
        return <String, dynamic>{
          'content': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'text',
              'text': const JsonEncoder.withIndent('  ').convert(result),
            },
          ],
        };
      } on Object catch (e) {
        return <String, dynamic>{
          'isError': true,
          'content': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'text',
              'text': "Tool '$name' failed: $e",
            },
          ],
        };
      }

    default:
      throw _RpcException(-32601, 'Method not found: $method');
  }
}

Map<String, dynamic> _error(Object? id, int code, String message) {
  return <String, dynamic>{
    'jsonrpc': '2.0',
    if (id != null) 'id': id,
    'error': <String, dynamic>{
      'code': code,
      'message': message,
    },
  };
}

class _RpcException implements Exception {
  _RpcException(this.code, this.message);

  final int code;
  final String message;

  @override
  String toString() => 'RpcException($code, $message)';
}
