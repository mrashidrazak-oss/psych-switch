// Patient context — pure types and helpers.
//
// Split from `patientContext.ts` so the MCP server (and any future
// non-React consumer of the engine) can import the warning-generation
// logic without pulling in AsyncStorage / React.
//
// `patientContext.ts` re-exports everything here, so existing UI code
// keeps working unchanged. Only the React hook + AsyncStorage caching
// live in the parent file.
//
// IMPORTANT — keep this file pure:
//   • No imports from `react`, `react-native`, `expo-*`, `@react-native-*`.
//   • No top-level side effects.
//   • If you need a stateful behaviour, add it to patientContext.ts.

export type AgeBand = 'pediatric' | 'adult' | 'older_adult';
export type RenalFn = 'normal' | 'mild' | 'moderate' | 'severe';
export type HepaticFn = 'normal' | 'mild' | 'moderate' | 'severe';
export type Sex = 'male' | 'female' | 'other';

export interface PatientContext {
  /** Age in years. Used to derive the band; the band drives the warnings. */
  ageYears?: number;
  sex?: Sex;
  weightKg?: number;
  heightCm?: number;
  /** Renal function band (eGFR). */
  renal?: RenalFn;
  egfr?: number; // mL/min/1.73m²
  /** Hepatic function (Child-Pugh band, simplified). */
  hepatic?: HepaticFn;
  /** Pregnancy status. */
  pregnant?: boolean;
  trimester?: 1 | 2 | 3;
  /** Breastfeeding status. */
  breastfeeding?: boolean;
  /** Smoking — major CYP1A2 inducer (clozapine, olanzapine clearance ↑). */
  smoker?: boolean;
  /** Comorbidities relevant to switching. */
  comorbidities?: {
    cardiac?: boolean; // baseline QTc concern, structural heart disease
    seizure?: boolean; // seizure history (clozapine, bupropion implications)
    diabetes?: boolean; // metabolic risk
    obesity?: boolean;
    dyslipidemia?: boolean;
  };
}

export const EMPTY_CONTEXT: PatientContext = {};

export function ageBand(ctx: PatientContext): AgeBand | null {
  if (ctx.ageYears == null) return null;
  if (ctx.ageYears < 18) return 'pediatric';
  if (ctx.ageYears >= 65) return 'older_adult';
  return 'adult';
}

export function bmi(ctx: PatientContext): number | null {
  if (!ctx.weightKg || !ctx.heightCm) return null;
  const m = ctx.heightCm / 100;
  return ctx.weightKg / (m * m);
}

/**
 * Estimate eGFR using the simplified Cockcroft-Gault when explicit eGFR
 * is not provided. Returns null if inputs are insufficient.
 *
 * Note: CKD-EPI is preferred clinically; this is a fallback for the
 * dose-adjustment hint, not a CKD diagnosis.
 */
export function estimateEgfr(ctx: PatientContext): number | null {
  if (ctx.egfr != null) return ctx.egfr;
  if (!ctx.ageYears || !ctx.weightKg || !ctx.sex) return null;
  // Cockcroft-Gault (no serum creatinine input — return null since it's
  // mandatory for the formula).
  return null;
}

export function renalBandFromEgfr(egfr: number): RenalFn {
  if (egfr >= 90) return 'normal';
  if (egfr >= 60) return 'mild';
  if (egfr >= 30) return 'moderate';
  return 'severe';
}

export function isComplete(ctx: PatientContext): boolean {
  return ctx.ageYears != null && ctx.sex != null;
}

// ── Warning generation ──────────────────────────────────────────────────────

export interface ContextWarning {
  severity: 'info' | 'warning' | 'danger';
  drugId?: string;
  message: string;
}

/**
 * Given a patient context and a drug, produce a list of dose-adjustment
 * or contraindication warnings. Used by the switching engine, the
 * equivalency screen, and the MCP server.
 */
export function warningsForDrug(
  ctx: PatientContext,
  drugId: string,
): ContextWarning[] {
  const out: ContextWarning[] = [];
  const band = ageBand(ctx);
  const renal = ctx.renal ?? (ctx.egfr != null ? renalBandFromEgfr(ctx.egfr) : null);

  // Older-adult sedation / falls
  if (band === 'older_adult') {
    if (['olanzapine', 'quetiapine', 'mirtazapine', 'clozapine'].includes(drugId)) {
      out.push({
        severity: 'warning',
        drugId,
        message: 'Older adult: start at 25–50% of adult dose; review fall risk.',
      });
    }
  }

  // Pediatric
  if (band === 'pediatric') {
    out.push({
      severity: 'warning',
      drugId,
      message: 'Pediatric prescribing: most psychotropics are off-label <18. Specialist input recommended.',
    });
  }

  // Renal
  if (renal === 'moderate' || renal === 'severe') {
    if (drugId === 'amisulpride' || drugId === 'sulpiride' || drugId === 'paliperidone') {
      out.push({
        severity: renal === 'severe' ? 'danger' : 'warning',
        drugId,
        message: `Renal clearance — reduce dose ${renal === 'severe' ? '≥50%' : '~25%'} or choose alternative.`,
      });
    }
    if (drugId === 'lithium') {
      out.push({
        severity: 'danger',
        drugId,
        message: 'Lithium: contraindicated in moderate-severe CKD. Choose alternative mood stabilizer.',
      });
    }
  }

  // Hepatic
  if (ctx.hepatic === 'moderate' || ctx.hepatic === 'severe') {
    if (['valproate', 'carbamazepine', 'duloxetine', 'agomelatine'].includes(drugId)) {
      out.push({
        severity: 'danger',
        drugId,
        message: 'Hepatic impairment: hepatotoxicity risk — avoid or use with frequent LFTs.',
      });
    }
  }

  // Pregnancy
  if (ctx.pregnant) {
    if (drugId === 'valproate') {
      out.push({
        severity: 'danger',
        drugId,
        message: 'Valproate in pregnancy: 30–40% major malformation rate. Contraindicated; switch urgently.',
      });
    }
    if (drugId === 'carbamazepine') {
      out.push({
        severity: 'warning',
        drugId,
        message: 'Carbamazepine: neural tube defects 1%. Folate 5 mg/day. Consider alternative.',
      });
    }
    if (drugId === 'paroxetine') {
      out.push({
        severity: 'warning',
        drugId,
        message: 'Paroxetine in 1st trimester: cardiac defect signal. Avoid if possible.',
      });
    }
    if (drugId === 'lithium' && ctx.trimester === 1) {
      out.push({
        severity: 'warning',
        drugId,
        message: 'Lithium 1st trimester: small Ebstein anomaly risk. Fetal echo at 18–20w.',
      });
    }
  }

  // Breastfeeding
  if (ctx.breastfeeding) {
    if (['lithium', 'clozapine', 'lamotrigine'].includes(drugId)) {
      out.push({
        severity: 'warning',
        drugId,
        message: 'Breastfeeding: high transfer / case reports. Monitor infant; consider alternative.',
      });
    }
  }

  // Smoking — clearance modifier (CYP1A2 induction)
  if (ctx.smoker) {
    if (['clozapine', 'olanzapine'].includes(drugId)) {
      out.push({
        severity: 'info',
        drugId,
        message: 'Smoking induces CYP1A2 → up to 50% lower plasma level. Doses ↓ if smoking stops.',
      });
    }
  }

  // Cardiac comorbidity + QTc-prolongers
  if (ctx.comorbidities?.cardiac) {
    if (['haloperidol', 'chlorpromazine', 'sulpiride', 'amisulpride', 'citalopram', 'escitalopram'].includes(drugId)) {
      out.push({
        severity: 'warning',
        drugId,
        message: 'Cardiac history + QTc-prolonging agent. Baseline + on-treatment ECG.',
      });
    }
  }

  // Diabetes / metabolic + olanzapine, clozapine, quetiapine
  if (ctx.comorbidities?.diabetes || ctx.comorbidities?.dyslipidemia) {
    if (['olanzapine', 'clozapine', 'quetiapine'].includes(drugId)) {
      out.push({
        severity: 'warning',
        drugId,
        message: 'Metabolic risk + high-metabolic agent. Prefer aripiprazole/lurasidone if possible.',
      });
    }
  }

  // Seizure + clozapine, bupropion
  if (ctx.comorbidities?.seizure) {
    if (drugId === 'clozapine') {
      out.push({
        severity: 'warning',
        drugId,
        message: 'Seizure history: clozapine lowers threshold. EEG, slow titration.',
      });
    }
  }

  return out;
}
