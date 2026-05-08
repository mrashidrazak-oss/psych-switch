// Local audit log export — turns the saved cases into a CSV or JSON
// dump suitable for hospital QI / personal audit / research use.
//
// Privacy:
//   • Exports only what's already on the device (case labels, drug
//     ids, doses, dates, favourite flag).
//   • The clinician chose those labels — typically initials / codes,
//     not patient-identifying data.
//   • The export is generated on-device and handed off via the share
//     sheet. Nothing is uploaded.
//
// Two formats:
//   • CSV — paste into Excel / SPSS / spreadsheet QI tools.
//   • JSON — machine-readable for research pipelines.
import type { SavedCase } from '../engine/caseManager';

interface ExportOptions {
  cases: SavedCase[];
  appVersion: string;
}

const CSV_HEADERS = [
  'case_id',
  'label',
  'started_iso',
  'updated_iso',
  'from_drug_id',
  'from_dose_mg',
  'to_drug_id',
  'to_dose_mg',
  'favourite',
  'notes',
] as const;

/**
 * Render the saved cases as a CSV string. Newlines inside notes /
 * labels are stripped (they break CSV); commas + quotes are escaped
 * per RFC 4180.
 */
export function exportAuditLogCsv({ cases, appVersion }: ExportOptions): string {
  const lines: string[] = [];
  lines.push(`# PsychSwitch audit log · v${appVersion}`);
  lines.push(`# Generated ${new Date().toISOString()}`);
  lines.push(`# ${cases.length} saved cases`);
  lines.push(CSV_HEADERS.join(','));
  for (const c of cases) {
    lines.push([
      escape(c.id),
      escape(c.label),
      escape(c.startedISO),
      escape(c.updatedISO),
      escape(c.fromDrugId),
      String(c.fromDoseMg),
      escape(c.toDrugId),
      String(c.toDoseMg),
      c.favourite ? '1' : '0',
      escape((c.notes ?? '').replace(/[\r\n]+/g, ' ')),
    ].join(','));
  }
  return lines.join('\n');
}

/**
 * Render the saved cases as a JSON string. Includes a meta envelope
 * with the schema version + generation timestamp so external
 * pipelines can detect format changes.
 */
export function exportAuditLogJson({ cases, appVersion }: ExportOptions): string {
  const payload = {
    schema: 'psychswitch.audit.v1',
    appVersion,
    generatedISO: new Date().toISOString(),
    caseCount: cases.length,
    cases: cases.map((c) => ({
      id: c.id,
      label: c.label,
      startedISO: c.startedISO,
      updatedISO: c.updatedISO,
      fromDrugId: c.fromDrugId,
      fromDoseMg: c.fromDoseMg,
      toDrugId: c.toDrugId,
      toDoseMg: c.toDoseMg,
      favourite: !!c.favourite,
      notes: c.notes ?? null,
    })),
  };
  return JSON.stringify(payload, null, 2);
}

// CSV cell escaping per RFC 4180: wrap in quotes if the cell contains
// a comma, double-quote, or newline; double any internal quotes.
function escape(s: string): string {
  if (s == null) return '';
  if (/[,"\r\n]/.test(s)) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}
