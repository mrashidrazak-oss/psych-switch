// Clozapine module — initiation, monitoring and safety logic.
//
// Clozapine is the highest-stakes oral antipsychotic in the registry. It
// gets its own engine module rather than living under switching-rules
// because it is fundamentally not a switch — it is an INITIATION protocol
// with mandatory lifelong haematological monitoring and a discrete set of
// safety considerations (agranulocytosis, myocarditis, ileus, smoking-
// cessation CYP1A2 effect).
//
// Per Maudsley 15th edition (Schizophrenia chapter, p.214–218): titration
// targets and schedules are split by sex × smoking status, not by inpatient
// vs community setting. This is because CYP1A2 activity (the main clozapine-
// metabolising enzyme) varies with both: smoking induces CYP1A2 substantially,
// and males have higher CYP1A2 activity than females. Four variants:
//   - Female non-smoker: target 225 mg/day
//   - Female smoker:     target 300 mg/day
//   - Male non-smoker:   target 250 mg/day
//   - Male smoker:       target 375 mg/day
// All schedules are 20 days, twice-daily dosing, starting at 6.25 mg evening.
//
// All content lives as JSON under /content/clozapine/. This file just
// loads it and provides typed accessors.

import femaleNonSmokerTitration from '../content/clozapine/titration-female-non-smoker.json';
import femaleSmokerTitration from '../content/clozapine/titration-female-smoker.json';
import maleNonSmokerTitration from '../content/clozapine/titration-male-non-smoker.json';
import maleSmokerTitration from '../content/clozapine/titration-male-smoker.json';
import monitoringSchedule from '../content/clozapine/monitoring-schedule.json';
import safetyConsiderations from '../content/clozapine/safety-considerations.json';
import rechallengeRules from '../content/clozapine/rechallenge-rules.json';
import communityInitiation from '../content/clozapine/community-initiation.json';

export type TitrationSex = 'female' | 'male';

export interface TitrationVariant {
  sex: TitrationSex;
  smoker: boolean;
}

export interface TitrationStep {
  day: number;
  morningMg: number;
  eveningMg: number;
  totalMg: number;
  notes?: string;
}

export interface TitrationProtocol {
  id: string;
  variant: TitrationVariant;
  /** Maintenance dose target reached at end of titration (mg/day). */
  targetDoseMg: number;
  rationale: string;
  totalDays: number;
  steps: TitrationStep[];
  postTitrationGuidance: string;
  missedDoseRule: string;
  citations: string[];
  lastReviewedISO: string;
  reviewedBy: string;
}

export interface MonitoringPhase {
  phase: string;
  weekStart: number;
  weekEnd: number | null;
  frequency: string;
  test: string;
  notes: string;
}

export interface MonitoringMilestone {
  id: string;
  timepoint: string;
  weekFromStart: number | null;
  tests: string[];
  criticalNotes: string;
}

export interface FbcThresholds {
  ancGreenAtOrAbove: number;
  ancAmberRange: [number, number];
  ancRedBelow: number;
  wbcGreenAtOrAbove: number;
  wbcAmberRange: [number, number];
  wbcRedBelow: number;
  unit: string;
  actions: { green: string; amber: string; red: string };
  benAdjustment: {
    ancGreenAtOrAbove: number;
    ancAmberRange: [number, number];
    ancRedBelow: number;
    wbcGreenAtOrAbove: number;
    wbcAmberRange: [number, number];
    wbcRedBelow: number;
    notes: string;
  };
}

export interface MonitoringScheduleData {
  id: string;
  rationale: string;
  phases: MonitoringPhase[];
  milestones: MonitoringMilestone[];
  fbcThresholds: FbcThresholds;
  citations: string[];
  lastReviewedISO: string;
  reviewedBy: string;
}

export type SafetySeverityLevel = 'info' | 'warning' | 'danger';

export interface SafetyConsideration {
  id: string;
  severity: SafetySeverityLevel;
  title: string;
  body: string;
  monitoring: string;
}

export interface SafetyConsiderationsData {
  id: string;
  considerations: SafetyConsideration[];
  citations: string[];
  lastReviewedISO: string;
  reviewedBy: string;
}

export function getTitration(variant: TitrationVariant): TitrationProtocol {
  if (variant.sex === 'female' && !variant.smoker)
    return femaleNonSmokerTitration as unknown as TitrationProtocol;
  if (variant.sex === 'female' && variant.smoker)
    return femaleSmokerTitration as unknown as TitrationProtocol;
  if (variant.sex === 'male' && !variant.smoker)
    return maleNonSmokerTitration as unknown as TitrationProtocol;
  return maleSmokerTitration as unknown as TitrationProtocol;
}

/** Return all four titration variants (used by the picker UI). */
export function getAllTitrations(): TitrationProtocol[] {
  return [
    femaleNonSmokerTitration as unknown as TitrationProtocol,
    femaleSmokerTitration as unknown as TitrationProtocol,
    maleNonSmokerTitration as unknown as TitrationProtocol,
    maleSmokerTitration as unknown as TitrationProtocol,
  ];
}

export function getMonitoringSchedule(): MonitoringScheduleData {
  return monitoringSchedule as unknown as MonitoringScheduleData;
}

export function getSafetyConsiderations(): SafetyConsiderationsData {
  return safetyConsiderations as unknown as SafetyConsiderationsData;
}

export type RechallengeSeverity = 'info' | 'warning' | 'danger';

export interface RechallengeTier {
  id: string;
  label: string;
  maxHours: number | null;
  severity: RechallengeSeverity;
  heading: string;
  guidance: string;
  restartInstruction: string;
  retitrationRequired: boolean;
  monitoringNote: string;
  warningSignsToWatch: string[];
}

export interface RechallengeRulesData {
  id: string;
  rationale: string;
  tiers: RechallengeTier[];
  absoluteContraindications: string[];
  citations: string[];
  lastReviewedISO: string;
  reviewedBy: string;
}

export function getRechallengeRules(): RechallengeRulesData {
  return rechallengeRules as unknown as RechallengeRulesData;
}

export interface CommunityInitiationCriterion {
  id: string;
  title: string;
  detail: string;
}

export interface CommunityInitiationData {
  id: string;
  rationale: string;
  relativeContraindications: CommunityInitiationCriterion[];
  essentialCriteria: CommunityInitiationCriterion[];
  initialWorkup: CommunityInitiationCriterion[];
  monitoringIntensity: {
    first_4_weeks: string;
    weeks_5_to_18: string;
    weeks_19_to_52: string;
    year_2_onwards: string;
  };
  citations: string[];
  lastReviewedISO: string;
  reviewedBy: string;
}

export function getCommunityInitiation(): CommunityInitiationData {
  return communityInitiation as unknown as CommunityInitiationData;
}

/**
 * Look up the appropriate restart tier for a given interruption duration.
 *
 * Pass either hours OR days (they are summed: `totalHours = hours + days * 24`).
 * Returns the most conservative tier whose `maxHours` >= the calculated total,
 * or the > 5-day danger tier when the total exceeds all boundaries.
 */
export function classifyInterruption(input: {
  days?: number;
  hours?: number;
}): RechallengeTier {
  const totalHours = (input.days ?? 0) * 24 + (input.hours ?? 0);
  const data = getRechallengeRules();
  // Tiers are ordered ascending by maxHours; find the first one that covers the gap.
  const matched = data.tiers.find(
    (t) => t.maxHours !== null && totalHours <= t.maxHours,
  );
  // If nothing matched, the gap exceeds all finite tiers → last tier (> 5 days).
  return matched ?? data.tiers[data.tiers.length - 1];
}

/**
 * Classify an FBC reading against the CPMS-derived thresholds.
 *
 * Pass `applyBen: true` for patients with documented benign ethnic
 * neutropenia — this swaps in the FULL BEN threshold set (green, amber
 * and red boundaries are all lowered, not just the green line).
 *
 * Either ANC or WBC dropping into a worse zone determines the result;
 * we report whichever is the more concerning (red > amber > green).
 */
export function classifyFbc(input: {
  ancE9PerL: number;
  wbcE9PerL: number;
  applyBen?: boolean;
}): { zone: 'green' | 'amber' | 'red'; reason: string } {
  const t = getMonitoringSchedule().fbcThresholds;
  const ancGreen = input.applyBen
    ? t.benAdjustment.ancGreenAtOrAbove
    : t.ancGreenAtOrAbove;
  const ancRed = input.applyBen ? t.benAdjustment.ancRedBelow : t.ancRedBelow;
  const wbcGreen = input.applyBen
    ? t.benAdjustment.wbcGreenAtOrAbove
    : t.wbcGreenAtOrAbove;
  const wbcRed = input.applyBen ? t.benAdjustment.wbcRedBelow : t.wbcRedBelow;

  // Red trumps amber trumps green. Either marker in red = stop clozapine.
  if (input.ancE9PerL < ancRed || input.wbcE9PerL < wbcRed) {
    return {
      zone: 'red',
      reason:
        input.ancE9PerL < ancRed
          ? `ANC ${input.ancE9PerL} below red threshold ${ancRed}${input.applyBen ? ' (BEN-adjusted)' : ''}`
          : `WBC ${input.wbcE9PerL} below red threshold ${wbcRed}${input.applyBen ? ' (BEN-adjusted)' : ''}`,
    };
  }

  const ancAmber = input.ancE9PerL < ancGreen;
  const wbcAmber = input.wbcE9PerL < wbcGreen;
  if (ancAmber || wbcAmber) {
    return {
      zone: 'amber',
      reason: ancAmber
        ? `ANC ${input.ancE9PerL} below green threshold ${ancGreen}${input.applyBen ? ' (BEN-adjusted)' : ''}`
        : `WBC ${input.wbcE9PerL} below green threshold ${wbcGreen}${input.applyBen ? ' (BEN-adjusted)' : ''}`,
    };
  }

  return { zone: 'green', reason: 'Both ANC and WBC in green range.' };
}
