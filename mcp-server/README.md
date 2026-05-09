# PsychSwitch MCP Server (Node — Retiring)

> **Status: Retiring after Phase 8.** The Dart reimplementation lives
> at `../psychswitch_mcp/` and ships the same 18 tools with the same
> shapes against the same `/content/` tree. New work goes there.
>
> This Node server stays online during the Flutter migration so
> existing MCP wirings (Claude Desktop, Cursor, EMR plugins) keep
> working without disruption. After RN/Expo retires in Phase 8, this
> directory deletes — by then any wiring still pointing here should
> have moved to `dart compile exe`'d psychswitch-mcp.

A [Model Context Protocol](https://modelcontextprotocol.io) server
that exposes the PsychSwitch clinical engine as queryable tools for
any MCP-compatible AI assistant — Claude Desktop, Cursor, Goose,
hospital EMR plugins.

## Why this exists

The clinical engine in `/engine/` is pure TypeScript that ships with
zero React-Native-specific code. That makes it usable from anywhere a
Node process can run — including from inside an AI assistant.

Wired up via MCP, you get conversational access:

> *"Run a switch from olanzapine 20 mg to aripiprazole, this patient
> has weight gain on metformin and eGFR 50, show me the schedule and
> explain the trade-offs."*

The AI assistant calls the MCP tools, gets structured engine output,
and writes the explanation. The engine remains the source of clinical
truth — the AI only narrates.

## Tools exposed (18)

| Tool | Purpose |
|------|---------|
| `psychswitch_list_drugs` | List drugs in the registry. Filter by category. |
| `psychswitch_get_drug` | Full drug profile by id. |
| `psychswitch_list_rules` | List reviewed switching rules. Filter by from / to. |
| `psychswitch_generate_plan` | **Main API.** Returns plan + score + adapted schedule + monitoring + AE profile + DDI hits + context warnings, all in one call. |
| `psychswitch_scale_schedule` | Adapt a reviewed schedule to user-entered doses. |
| `psychswitch_dose_equivalent` | CPZ-eq, FLX-eq, DZP-eq dose conversions. |
| `psychswitch_predict_ae` | Predicted side-effect profile, with comparative tier. |
| `psychswitch_check_ddi` | Pairwise DDI check (serotonergic, CYP, QTc, etc). |
| `psychswitch_compute_score` | PsychSwitch Score (0-100) without the full plan envelope. |
| `psychswitch_search` | Cross-content search (drugs, rules, tools). Recognises "X to Y" pair queries. |
| `psychswitch_lookup_glossary` | Define a clinical term (ESRS, QTc, MAOI, NMS, etc.). |
| `psychswitch_get_citation` | Resolve a citation key to reference + paraphrase. |
| `psychswitch_context_warnings` | Patient-context warnings for a single drug. |
| `psychswitch_assess_specialty` | Pregnancy / breastfeeding / pediatric / geriatric tier-ranked recommendations for a switching pair. |
| `psychswitch_list_errata` | Append-only audit trail of clinical-content corrections. Filterable by scope or version. |
| `psychswitch_quantitative_ae` | Effect sizes (OR / SMD / kg) from Leucht 2013 + Cipriani 2018 NMAs, with 95% CI. |
| `psychswitch_cost` | Estimated MYR monthly cost + affordability tier for one or two drugs. |
| `psychswitch_overlap_intensity` | Cross-taper Day-1 overlap assessment — tier (low / moderate / high / severe) + 0-100 score + mechanism stacking flags. |

> **Coverage note:** all rules are returned, including mood-stabilizer + LAI / depot
> rules that are gated from the patient-app picker pending more clinical research.
> Use them via MCP for educational / research queries; keep them out of patient-facing
> workflows until the gate lifts.

## Setup

```bash
cd mcp-server
pnpm install --ignore-workspace
pnpm test          # 24/24 smoke tests should pass
```

That's it. No compile step — `tsx` runs the TypeScript source directly.

## Wiring to Claude Desktop

1. Open the Claude Desktop config:
   ```bash
   # macOS
   open -e ~/Library/Application\ Support/Claude/claude_desktop_config.json
   # Linux
   xdg-open ~/.config/Claude/claude_desktop_config.json
   # Windows: %APPDATA%\Claude\claude_desktop_config.json
   ```

2. Add the PsychSwitch entry:
   ```json
   {
     "mcpServers": {
       "psychswitch": {
         "command": "node",
         "args": [
           "/Users/rashidrazak/Desktop/psych-switch/mcp-server/bin/psychswitch-mcp.mjs"
         ]
       }
     }
   }
   ```
   *(Replace the path with your actual checkout location.)*

3. **Restart Claude Desktop.** The tools should appear under the
   plug-icon menu in the bottom-left of the chat composer.

4. Try it:
   > *"Use psychswitch to plan a switch from olanzapine 20mg to
   > aripiprazole 15mg for a patient with weight gain. Walk me through
   > the schedule and the trade-offs."*

## Wiring to Cursor

Cursor uses the same MCP config format. Add to
`~/.cursor/mcp.json` with the same structure.

## Wiring to other clients

Any MCP-compatible client. The server uses stdio transport — point
your client at the same `bin/psychswitch-mcp.mjs` script.

## Privacy

This server holds **no patient data**. It runs entirely on the host
machine. Tool calls are direct function calls into the engine — no
network, no telemetry.

When wired to an AI assistant, the assistant sees the tool inputs and
outputs as part of the conversation. Whatever privacy contract that
assistant operates under (Claude's no-training-on-API for Anthropic,
etc.) applies. The MCP server itself adds zero retention.

If you pass patient context (age, eGFR, comorbidities) as structured
parameters, those become part of the conversation transcript on the
client side. Treat them with the same discipline as any other PHI you
put in an AI conversation.

## Architecture

```
mcp-server/
  bin/
    psychswitch-mcp.mjs   — Node entry point (delegates to tsx)
  src/
    server.ts             — MCP transport + dispatch
    tools.ts              — JSONSchema tool descriptions for the client
    handlers.ts           — Real implementations (call into ../engine)
    smoke.ts              — Exercises every handler against the real engine
  package.json            — type: module, tsx as runtime
  tsconfig.json           — Spans engine source for type-aware checks
  README.md               — You are here
```

`handlers.ts` imports pure engine modules (no React, no AsyncStorage).
The `engine/patientContext.ts` was split into `patientContextPure.ts`
specifically so this server can import the warning-generation logic
without pulling RN dependencies into Node.

## Example session

After wiring to Claude Desktop:

> **You**: Plan a switch from olanzapine 20mg to aripiprazole 15mg.
> Patient has type 2 diabetes and gained 8kg on the olanzapine.
>
> **Claude**: I'll run the switch through PsychSwitch.
>
> *(Calls `psychswitch_generate_plan` with patientContext.diabetes=true.)*
>
> Here's the engine's plan:
>
> **PsychSwitch Score: 92 (excellent fit · grade A · diabetes flagged)**
>
> The score is high because:
> - Reviewed Maudsley rule for this exact pair (grade A)
> - Aripiprazole is the recommended switch target *away* from
>   olanzapine for weight gain (AE-aligned, +5 bonus)
> - No DDI in the cross-taper window
>
> The diabetes warning shows up but doesn't penalise the score —
> aripiprazole is metabolically neutral.
>
> **Schedule** (28-day plateau cross-taper):
> - Day 1: Olanzapine 20 mg + start Aripiprazole 5 mg
> - Day 7: Olanzapine 15 mg, Aripiprazole 10 mg
> - Day 14: Olanzapine 10 mg, Aripiprazole 15 mg
> - Day 21: Olanzapine 5 mg, Aripiprazole 15 mg
> - Day 28: Stop Olanzapine, Aripiprazole 15 mg ongoing
>
> **Monitoring**: ESRS at week 2 (akathisia is the dose-limiting AE
> on aripiprazole), HbA1c at month 3 (we expect improvement given
> the metabolic switch).
>
> **Citations**: Maudsley 15th ch.4 (aripiprazole profile) and
> BAP 2020 (psychosis switching).

## Roadmap

- v0.4.2 (now) — full server, smoke tests, Claude Desktop wiring
- v0.4.3 — REST shim (HTTP API on the same handlers)
- v0.5 — published as `@psychswitch/mcp` on npm
- v1.0 — auth + audit log layer for hospital deployments

## License

MIT — same as the app source.
