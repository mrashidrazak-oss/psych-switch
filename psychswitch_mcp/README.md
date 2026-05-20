# psychswitch-mcp

PsychSwitch's clinical engine, exposed as Model Context Protocol tools
for AI assistants (Claude Desktop, Cursor) and EMR plugins.

The Dart reimplementation of the original Node MCP server (which lives
at `../mcp-server/` and retires in Phase 7). Same 18 tools, same
shapes, same content tree at `../content/`. Drop-in replacement.

## Tools

| Tool | Purpose |
|---|---|
| `psychswitch_list_drugs` | List every drug (id, name, class) |
| `psychswitch_get_drug` | Full profile for one drug |
| `psychswitch_list_rules` | List the 126 reviewed switching rules |
| `psychswitch_generate_plan` | Generate a cross-taper plan |
| `psychswitch_scale_schedule` | Scale a reviewed rule to actual doses |
| `psychswitch_dose_equivalent` | CPZ-eq / FLX-eq / DZP-eq conversion |
| `psychswitch_predict_ae` | Predicted AE profile for a switch |
| `psychswitch_quantitative_ae` | Curated effect sizes (Leucht / Cipriani NMAs) |
| `psychswitch_check_ddi` | Drug-drug interactions |
| `psychswitch_compute_score` | PsychSwitch Score (0-100) |
| `psychswitch_overlap_intensity` | Day-1 overlap intensity tier + flags |
| `psychswitch_search` | Free-text drug + rule search |
| `psychswitch_lookup_glossary` | Clinical-term lookup (QTc, EPS, ...) |
| `psychswitch_get_citation` | Resolve a citation key |
| `psychswitch_list_errata` | Audit trail of clinical-content corrections |
| `psychswitch_context_warnings` | Patient-context warnings for a drug |
| `psychswitch_assess_specialty` | Pregnancy / paediatric / geriatric depth |
| `psychswitch_cost` | Malaysian monthly cost (MYR) per drug |

## Run

```bash
# From the repo root:
cd psychswitch_mcp
dart pub get
dart run bin/psychswitch_mcp.dart
```

The server reads JSON-RPC requests on stdin and writes responses on
stdout. Boot logs go to stderr.

## Wire to Claude Desktop

Add this to `~/Library/Application Support/Claude/claude_desktop_config.json`
(macOS) or the equivalent on your platform:

```json
{
  "mcpServers": {
    "psychswitch": {
      "command": "dart",
      "args": [
        "run",
        "/absolute/path/to/psych-switch/psychswitch_mcp/bin/psychswitch_mcp.dart"
      ]
    }
  }
}
```

For a faster cold start, compile to a self-contained binary first:

```bash
cd psychswitch_mcp
dart compile exe bin/psychswitch_mcp.dart -o build/psychswitch-mcp
# ~6 MB, no Dart SDK required at runtime.
```

Then point the wiring at the binary:

```json
{
  "mcpServers": {
    "psychswitch": {
      "command": "/absolute/path/to/psych-switch/psychswitch_mcp/build/psychswitch-mcp"
    }
  }
}
```

## Privacy

- No network calls.
- No patient data is logged or persisted.
- Stdin / stdout are session-only — kept by the MCP client (e.g.
  Claude Desktop's chat history), never by this server.

## Content path

The server reads `/content/` from the monorepo by default. To run it
outside the monorepo, set the `PSYCHSWITCH_CONTENT_DIR` env var:

```bash
PSYCHSWITCH_CONTENT_DIR=/path/to/content dart run bin/psychswitch_mcp.dart
```

## Testing

```bash
cd psychswitch_mcp
dart test
```

24 smoke tests — one per handler, plus the registry shape check.
