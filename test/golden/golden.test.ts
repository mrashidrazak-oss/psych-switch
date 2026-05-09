// Golden-file engine harness — TypeScript side.
//
// Loads every fixture in /test/golden/fixtures/, runs the named engine
// function, and compares against the captured snapshot in
// /test/golden/snapshots/.
//
// Modes:
//   • Default:        compare current output against snapshot. Fail on diff.
//   • CAPTURE=1 env:  write output as the new snapshot (use to bootstrap
//                     a new fixture or after an intentional engine change).
//
// The Dart-side harness (Phase 2) replays the same fixtures through the
// Dart engine and compares against the SAME snapshots. Identical
// snapshots = identical engine behavior = no drift.

/// <reference types="node" />
import * as fs from 'fs';
import * as path from 'path';
import { generateSwitchPlan } from '../../engine/switchingEngine';

const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const SNAPSHOTS_DIR = path.join(__dirname, 'snapshots');
const CAPTURE = process.env.CAPTURE === '1';

interface Fixture {
  name: string;
  engine: string;
  input: Record<string, unknown>;
}

/**
 * Stable-key JSON serializer. Sorts object keys recursively so the
 * snapshot diffs stay legible regardless of how the engine emits keys.
 */
function stableStringify(value: unknown): string {
  return JSON.stringify(value, (_key, v) => {
    if (v && typeof v === 'object' && !Array.isArray(v)) {
      const sorted: Record<string, unknown> = {};
      for (const k of Object.keys(v).sort()) {
        sorted[k] = (v as Record<string, unknown>)[k];
      }
      return sorted;
    }
    return v;
  }, 2);
}

/**
 * Dispatch table: fixture.engine → invoking function.
 * Each entry takes the fixture's `input` and returns the output to snapshot.
 */
const ENGINES: Record<string, (input: Record<string, unknown>) => unknown> = {
  generateSwitchPlan: (input) => {
    const i = input as {
      fromDrugId: string;
      fromDoseMg: number;
      toDrugId: string;
      toDoseMg: number;
    };
    return generateSwitchPlan({
      fromDrugId: i.fromDrugId,
      fromDoseMg: i.fromDoseMg,
      toDrugId: i.toDrugId,
      toDoseMg: i.toDoseMg,
    });
  },
};

function loadFixtures(): Array<{ file: string; fixture: Fixture }> {
  if (!fs.existsSync(FIXTURES_DIR)) return [];
  return fs
    .readdirSync(FIXTURES_DIR)
    .filter((f: string) => f.endsWith('.json'))
    .map((file: string) => {
      const fixture = JSON.parse(
        fs.readFileSync(path.join(FIXTURES_DIR, file), 'utf-8'),
      ) as Fixture;
      return { file, fixture };
    });
}

describe('Golden-file engine harness — TS side', () => {
  if (!fs.existsSync(SNAPSHOTS_DIR)) {
    fs.mkdirSync(SNAPSHOTS_DIR, { recursive: true });
  }

  const fixtures = loadFixtures();

  test(`at least 5 fixtures present (Phase 1C minimum)`, () => {
    expect(fixtures.length).toBeGreaterThanOrEqual(5);
  });

  for (const { file, fixture } of fixtures) {
    const fixtureName = file.replace(/\.json$/, '');
    const snapshotPath = path.join(SNAPSHOTS_DIR, `${fixtureName}.json`);

    test(`fixture: ${fixture.name}`, () => {
      const engineFn = ENGINES[fixture.engine];
      expect(engineFn).toBeDefined();
      const output = engineFn(fixture.input);
      const serialized = stableStringify(output);

      if (CAPTURE) {
        fs.writeFileSync(snapshotPath, serialized + '\n', 'utf-8');
        // eslint-disable-next-line no-console
        console.log(`  📸 captured ${fixtureName}.json`);
        return;
      }

      // Verify mode
      expect(fs.existsSync(snapshotPath)).toBe(true);
      const expected = fs.readFileSync(snapshotPath, 'utf-8').trim();
      expect(serialized).toBe(expected);
    });
  }
});
