// PsychSwitch MCP Server.
//
// Exposes the PsychSwitch clinical engine as Model Context Protocol
// tools. Wire to Claude Desktop / Cursor / any MCP-compatible
// assistant via the snippet in README.md.
//
// Privacy: this server does no I/O other than the MCP transport. It
// holds no patient data, makes no network calls. Tool inputs and
// outputs are session-only — kept by whatever MCP client invokes the
// server, never persisted here.
//
// Architecture:
//   server.ts   — transport boot + request dispatch (this file)
//   tools.ts    — JSONSchema descriptions for the MCP client
//   handlers.ts — actual implementations (call into ../engine)
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';

import { handlers, type HandlerName } from './handlers';
import { TOOLS } from './tools';

// ── Server setup ──────────────────────────────────────────────────────────

const SERVER_NAME = 'psychswitch';
const SERVER_VERSION = '0.4.2';

const server = new Server(
  { name: SERVER_NAME, version: SERVER_VERSION },
  { capabilities: { tools: {} } },
);

// ── Tool listing ──────────────────────────────────────────────────────────

server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools: TOOLS }));

// ── Tool dispatch ─────────────────────────────────────────────────────────

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const name = request.params.name as HandlerName;
  const handler = handlers[name];
  if (!handler) {
    return {
      isError: true,
      content: [
        {
          type: 'text' as const,
          text: `Unknown tool: ${name}. Call list_tools to see what's available.`,
        },
      ],
    };
  }
  try {
    const result = await handler(request.params.arguments ?? {});
    return {
      content: [
        {
          type: 'text' as const,
          text: JSON.stringify(result, null, 2),
        },
      ],
    };
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    return {
      isError: true,
      content: [
        {
          type: 'text' as const,
          text: `Tool '${name}' failed: ${msg}`,
        },
      ],
    };
  }
});

// ── Boot ──────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  // stderr only — stdout is reserved for the MCP protocol stream.
  console.error(`PsychSwitch MCP server v${SERVER_VERSION} ready · ${TOOLS.length} tools.`);
}

main().catch((err) => {
  console.error('PsychSwitch MCP server failed to start:', err);
  process.exit(1);
});
