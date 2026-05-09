# Phase 0 — your turn

Two items I couldn't run from this session — they need physical access
to a phone and Claude Desktop respectively. Do these, paste the
results back, and Phase 0 closes. Then we kick off Phase 1.

Time: ~2-3 hours total split across both spikes.

---

## Phase 0.2 — MCP architecture spike

**Goal**: decide whether the Dart MCP ecosystem is mature enough to
fully replace the Node MCP server.

**Outcome locks**: Architecture C (full Dart) vs Architecture D (Node
MCP, codegen-shared content).

### The 1-tool prototype

Make a temporary directory anywhere outside this repo:

```bash
mkdir ~/Desktop/dart-mcp-spike && cd ~/Desktop/dart-mcp-spike
dart create -t console mcp_spike
cd mcp_spike

# Add the community Dart MCP server package:
dart pub add mcp_server
# (Verify the package exists at https://pub.dev/packages/mcp_server
# before this. If it has been renamed/removed, that's a strong
# signal toward Architecture D.)
```

Replace `bin/mcp_spike.dart` with a 1-tool server that exposes
`psychswitch_list_drugs`. Hardcode 3 dummy drugs as the response — we
don't need the real engine for this spike, just MCP plumbing:

```dart
import 'package:mcp_server/mcp_server.dart';

void main() async {
  final server = McpServer(
    name: 'psychswitch_spike',
    version: '0.0.1',
  );

  server.addTool(
    name: 'psychswitch_list_drugs',
    description: 'Spike: list 3 dummy drugs',
    inputSchema: {'type': 'object', 'properties': {}},
    handler: (input) async {
      return {
        'drugs': [
          {'id': 'olanzapine', 'name': 'Olanzapine'},
          {'id': 'aripiprazole', 'name': 'Aripiprazole'},
          {'id': 'sertraline', 'name': 'Sertraline'},
        ],
      };
    },
  );

  await server.run();
}
```

Compile to a single binary:

```bash
dart compile exe bin/mcp_spike.dart -o ./psychswitch-spike
```

Wire it into Claude Desktop:

```bash
# macOS path:
open -e ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

Add to the `mcpServers` block:

```json
{
  "mcpServers": {
    "psychswitch_spike": {
      "command": "/Users/rashidrazak/Desktop/dart-mcp-spike/mcp_spike/psychswitch-spike"
    }
  }
}
```

Restart Claude Desktop. In a new chat, ask:

> "List the drugs from psychswitch_spike"

### Acceptance criteria — all 4 must pass

- [ ] Claude Desktop discovers the server (it appears in the MCP icon dropdown)
- [ ] Claude can list the available tools (`psychswitch_list_drugs` shows up)
- [ ] Claude successfully invokes the tool and renders the 3 drugs
- [ ] No errors, hangs, or warnings in the Claude Desktop dev console

### Decision rules

| Outcome | Architecture |
|---|---|
| All 4 pass cleanly, the package looks well-maintained, recent commits | **C — full Dart** |
| All 4 pass but the package looks abandoned / has open critical issues | **D — Node MCP, codegen-shared** (safer) |
| 1+ failure or rough edges | **D — Node MCP, codegen-shared** |

Document the result in `docs/FLUTTER_STACK.md` § Architecture decision.

---

## Phase 0.3 — Performance reality check on target device

**Goal**: prove Flutter on a Galaxy A14 (or similar 4GB MediaTek
Helio device) can hit the performance budgets we committed to in
the migration plan.

**Outcome locks**: GO / NO-GO for the migration.

### The "Hello Stress" spike app

Make a temporary directory anywhere outside this repo:

```bash
cd ~/Desktop
flutter create flutter_perf_spike --platforms=android
cd flutter_perf_spike
```

Replace `lib/main.dart` with this minimal stress test:

```dart
import 'dart:convert';
import 'package:flutter/material.dart';

void main() => runApp(const SpikeApp());

class SpikeApp extends StatelessWidget {
  const SpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF0B0F14),
          primary: Color(0xFF3B82F6),
        ),
      ),
      home: const HomeStress(),
    );
  }
}

/// Proxies for our actual app:
/// - 100-row scrollable list (drug picker) with rich rows
/// - One CustomPaint widget (Gantt chart proxy)
/// - Navigate to detail with hero animation
class HomeStress extends StatelessWidget {
  const HomeStress({super.key});

  @override
  Widget build(BuildContext context) {
    final drugs = List.generate(100, (i) => {
      'id': 'drug_$i',
      'name': 'Drug Name $i',
      'class': i % 4 == 0 ? 'SSRI' : i % 4 == 1 ? 'SNRI' : i % 4 == 2 ? 'AP' : 'Other',
      'halfLife': '${20 + i % 80}h',
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(title: const Text('Spike')),
      body: ListView.builder(
        itemCount: drugs.length,
        itemBuilder: (ctx, i) => Card(
          color: const Color(0xFF141A22),
          child: ListTile(
            title: Text(drugs[i]['name']!,
                style: const TextStyle(color: Colors.white)),
            subtitle: Text('${drugs[i]['class']} · t½ ${drugs[i]['halfLife']}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => DetailWithGantt(drug: drugs[i]),
            )),
          ),
        ),
      ),
    );
  }
}

class DetailWithGantt extends StatefulWidget {
  const DetailWithGantt({super.key, required this.drug});
  final Map<String, String> drug;

  @override
  State<DetailWithGantt> createState() => _DetailWithGanttState();
}

class _DetailWithGanttState extends State<DetailWithGantt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() { _ctl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(title: Text(widget.drug['name']!)),
      body: Column(
        children: [
          AnimatedBuilder(
            animation: _ctl,
            builder: (_, __) => CustomPaint(
              size: const Size(double.infinity, 200),
              painter: GanttPainter(progress: _ctl.value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 50,
              itemBuilder: (_, i) => ListTile(
                title: Text('Day ${i + 1}: ${widget.drug['name']}'),
                subtitle: const Text('Dose change row stress'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GanttPainter extends CustomPainter {
  GanttPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 60; i++) {
      final x = (i * size.width / 60);
      final h = (40 + 60 * ((i + progress * 60) % 10) / 10);
      p.color = i % 2 == 0
          ? const Color(0xFF60A5FA)
          : const Color(0xFF34D399);
      canvas.drawRRect(
        RRect.fromLTRBR(x, size.height - h, x + size.width / 60 - 2,
            size.height, const Radius.circular(2)),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(GanttPainter oldDelegate) => oldDelegate.progress != progress;
}
```

Build a release AAB and install on the target Galaxy A14:

```bash
flutter build apk --release
# or flutter build appbundle --release if you want to test the AAB path

# Plug A14 in via USB, USB debugging on:
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Test session — measure all 5

Open Flutter DevTools (`flutter pub global activate devtools && devtools`)
and connect to the running app on the device.

| Metric | Target | How to measure |
|---|---|---|
| Cold start (first launch) | < 2.0s | Stopwatch from tap to first frame |
| Scroll fps on the 100-row list | 60fps sustained, 0 jank | DevTools Performance overlay |
| Detail-screen open transition | 60fps | Same |
| CustomPaint Gantt at 60fps | 60fps with the animated bars | Same |
| Memory steady-state (detail screen open) | < 180 MB | DevTools Memory tab |

### Acceptance criteria

**All 5 pass** → GO. Migration is performance-sound. Update
`docs/FLUTTER_STACK.md` § Performance with measured numbers.

**Any 1 misses** → NO-GO until investigated. Possible causes:
- Galaxy A14 unit you tested is slower than spec
- Impeller renderer not enabled (verify with `--enable-impeller`)
- Device thermals throttled (give it a 5-min rest, retry)
- Real underlying limitation (rare but possible)

If a real limitation is found, halt the migration and reconsider
whether the targets are realistic. We do NOT proceed past Phase 0
on a maybe.

---

## Reporting back

When both spikes are done, paste the results into a comment on the
v0.4.23 GitHub issue (or just here in chat) with this template:

```
PHASE 0.2 (MCP)
- Claude Desktop discovery: [pass / fail]
- Tool list: [pass / fail]
- Tool invocation: [pass / fail]
- Console errors: [yes/no — describe]
- Decision: Architecture [C / D]
- Notes: [anything weird]

PHASE 0.3 (PERF)
- Device: Galaxy A14 (or specific model)
- Cold start: [Xs]
- Scroll fps: [X / 60]
- Detail open: [pass / fail]
- Gantt animation: [X / 60]
- Memory steady-state: [X MB]
- Verdict: GO / NO-GO
- Notes: [anything weird]
```

Once those are filled in, Phase 0 closes. I update the docs with
the locked decisions, and we kick off Phase 1.
