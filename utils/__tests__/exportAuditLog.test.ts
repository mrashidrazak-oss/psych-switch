import { exportAuditLogCsv, exportAuditLogJson } from '../exportAuditLog';
import type { SavedCase } from '../../engine/caseManager';

const SAMPLE: SavedCase[] = [
  {
    id: 'c_demo_001',
    label: 'Mr A — 12/07',
    fromDrugId: 'olanzapine',
    fromDoseMg: 20,
    toDrugId: 'aripiprazole',
    toDoseMg: 15,
    startedISO: '2026-04-15T09:30:00Z',
    updatedISO: '2026-04-15T09:30:00Z',
    favourite: true,
    notes: 'Switching for weight gain',
  },
  {
    id: 'c_demo_002',
    label: 'Ms B — patient with "quotes"',
    fromDrugId: 'sertraline',
    fromDoseMg: 100,
    toDrugId: 'mirtazapine',
    toDoseMg: 30,
    startedISO: '2026-04-20T10:00:00Z',
    updatedISO: '2026-04-22T10:00:00Z',
  },
];

describe('exportAuditLogCsv', () => {
  test('produces a header line + one row per case', () => {
    const csv = exportAuditLogCsv({ cases: SAMPLE, appVersion: '0.4.5' });
    const lines = csv.split('\n');
    // 3 comment lines + header + 2 case rows = 6 lines
    expect(lines.length).toBe(6);
    expect(lines[3]).toContain('case_id,label');
  });

  test('escapes commas and quotes per RFC 4180', () => {
    const csv = exportAuditLogCsv({ cases: SAMPLE, appVersion: '0.4.5' });
    // The label "Ms B — patient with \"quotes\"" should be wrapped + escaped
    expect(csv).toContain('"Ms B — patient with ""quotes"""');
  });

  test('newlines in notes are stripped', () => {
    const withNewline: SavedCase[] = [
      { ...SAMPLE[0], notes: 'line1\nline2' },
    ];
    const csv = exportAuditLogCsv({ cases: withNewline, appVersion: '0.4.5' });
    expect(csv).not.toContain('line1\nline2');
    expect(csv).toContain('line1 line2');
  });

  test('handles empty cases list', () => {
    const csv = exportAuditLogCsv({ cases: [], appVersion: '0.4.5' });
    // Just headers + comment lines
    expect(csv.split('\n').length).toBe(4);
  });
});

describe('exportAuditLogJson', () => {
  test('returns valid JSON with schema envelope', () => {
    const json = exportAuditLogJson({ cases: SAMPLE, appVersion: '0.4.5' });
    const parsed = JSON.parse(json);
    expect(parsed.schema).toBe('psychswitch.audit.v1');
    expect(parsed.appVersion).toBe('0.4.5');
    expect(parsed.caseCount).toBe(2);
    expect(parsed.cases.length).toBe(2);
  });

  test('case fields normalised', () => {
    const json = exportAuditLogJson({ cases: SAMPLE, appVersion: '0.4.5' });
    const parsed = JSON.parse(json);
    expect(parsed.cases[0].favourite).toBe(true);
    expect(parsed.cases[1].favourite).toBe(false);
    expect(parsed.cases[1].notes).toBeNull();
  });

  test('handles empty cases list', () => {
    const json = exportAuditLogJson({ cases: [], appVersion: '0.4.5' });
    const parsed = JSON.parse(json);
    expect(parsed.caseCount).toBe(0);
    expect(parsed.cases).toEqual([]);
  });
});
