// QTc stacker engine — pure functions, no React.
//
// Loads the drug QTc risk registry and provides functions to:
//   - list all registered drugs
//   - compute an aggregate risk category from a selection of drug IDs
//
// Risk categories (CredibleMeds / AzCERT-derived):
//   'known'      → Known Risk of TdP
//   'conditional'→ Conditional Risk (risk elevated under certain conditions)
//   'possible'   → Possible Risk
//   'low'        → Low / negligible risk

import qtcData from '../content/qtc/drug-qtc-risks.json';

export type QtcCategory = 'known' | 'conditional' | 'possible' | 'low';

export interface QtcDrugEntry {
  id: string;
  name: string;
  category: string;
  qtcCategory: QtcCategory;
  notes: string;
}

export interface QtcRiskData {
  id: string;
  rationale: string;
  riskCategories: Record<QtcCategory, string>;
  drugs: QtcDrugEntry[];
  riskThresholds: {
    overallAssessmentNote: string;
  };
  citations: string[];
  lastReviewedISO: string;
  reviewedBy: string;
}

export type OverallRisk = 'none' | 'low' | 'moderate' | 'high' | 'very_high';

export interface QtcAssessment {
  overallRisk: OverallRisk;
  knownCount: number;
  conditionalCount: number;
  possibleCount: number;
  selectedDrugs: QtcDrugEntry[];
  summary: string;
  recommendations: string[];
}

export function getQtcData(): QtcRiskData {
  return qtcData as unknown as QtcRiskData;
}

export function listQtcDrugs(): QtcDrugEntry[] {
  return getQtcData().drugs;
}

/**
 * Calculate aggregate QTc risk from a list of selected drug IDs.
 *
 * Risk scoring:
 *  known × 1      = +3 points each
 *  conditional × 1 = +2 points each
 *  possible × 1   = +1 point each
 *
 *  0 points   → none
 *  1–2 points → low
 *  3–5 points → moderate
 *  6–8 points → high
 *  ≥ 9 points → very_high
 */
export function assessQtcRisk(selectedIds: string[]): QtcAssessment {
  const data = getQtcData();
  const selectedDrugs = data.drugs.filter((d) => selectedIds.includes(d.id));

  const knownCount = selectedDrugs.filter((d) => d.qtcCategory === 'known').length;
  const conditionalCount = selectedDrugs.filter(
    (d) => d.qtcCategory === 'conditional',
  ).length;
  const possibleCount = selectedDrugs.filter(
    (d) => d.qtcCategory === 'possible',
  ).length;

  const score = knownCount * 3 + conditionalCount * 2 + possibleCount * 1;

  let overallRisk: OverallRisk;
  if (score === 0) overallRisk = 'none';
  else if (score <= 2) overallRisk = 'low';
  else if (score <= 5) overallRisk = 'moderate';
  else if (score <= 8) overallRisk = 'high';
  else overallRisk = 'very_high';

  const recommendations: string[] = [];

  if (overallRisk === 'none') {
    recommendations.push(
      'No selected drug has significant QTc-prolonging potential. Standard clinical monitoring sufficient.',
    );
  } else if (overallRisk === 'low') {
    recommendations.push(
      'Low aggregate QTc risk. Consider baseline ECG if cardiac risk factors present.',
    );
  } else if (overallRisk === 'moderate') {
    recommendations.push(
      'Moderate QTc risk — baseline ECG recommended before combining these drugs.',
      'Check serum potassium and magnesium at initiation and periodically.',
      'Review all QTc-prolonging agents — consider substituting a lower-risk alternative if possible.',
    );
  } else {
    recommendations.push(
      'HIGH QTc risk combination — baseline ECG REQUIRED before prescribing.',
      'Repeat ECG at steady state (7–14 days) and after any dose increase.',
      'Stop or substitute if QTc > 480 ms (men) or > 500 ms (women), or if QTc increases > 60 ms from baseline.',
      'Correct electrolyte abnormalities (hypokalaemia, hypomagnesaemia) before or alongside treatment.',
      'Consider cardiology consultation if QTc prolongation persists or clinical concern.',
    );
  }

  if (knownCount >= 2) {
    recommendations.push(
      'Two or more KNOWN-risk drugs are selected — this is a high-stakes combination. Cardiology input strongly recommended.',
    );
  }

  const summary =
    selectedDrugs.length === 0
      ? 'No drugs selected.'
      : `${selectedDrugs.length} drug${selectedDrugs.length === 1 ? '' : 's'} selected: ${knownCount} Known, ${conditionalCount} Conditional, ${possibleCount} Possible QTc risk.`;

  return {
    overallRisk,
    knownCount,
    conditionalCount,
    possibleCount,
    selectedDrugs,
    summary,
    recommendations,
  };
}
