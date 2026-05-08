#!/usr/bin/env node
// PsychSwitch MCP — entry point.
//
// Spawned by an MCP client (Claude Desktop, Cursor, etc.) over stdio.
// We delegate to tsx so the TypeScript source runs without a build
// step. tsx is bundled as a devDependency; if invoked from a global
// install the user is expected to have tsx available.
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const serverEntry = resolve(here, '..', 'src', 'server.ts');

// Locate tsx — prefer the package's own copy. Falls back to npx as
// a last resort.
const tsxPath = resolve(here, '..', 'node_modules', '.bin', 'tsx');

const child = spawn(tsxPath, [serverEntry], {
  stdio: 'inherit',
  env: process.env,
});

child.on('exit', (code) => process.exit(code ?? 0));
child.on('error', (err) => {
  console.error('Failed to launch tsx:', err.message);
  console.error('Try: npm i -g tsx');
  process.exit(127);
});
