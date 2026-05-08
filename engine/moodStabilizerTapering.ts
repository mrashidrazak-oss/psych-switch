// Mood-stabilizer tapering engine module.
//
// Loads structured tapering content (currently lithium-only; other mood
// stabilizers share the same hyperbolic principle but have less specific
// regimen data). All clinical content lives in /content/mood-stabilizers/
// JSON files.
//
// Per Maudsley 15th edition (Bipolar disorder, pp.331–333). Rapid
// discontinuation of lithium increases relapse risk sevenfold over the
// untreated rate — slow hyperbolic tapering is essential.

import lithiumTapering from '../content/mood-stabilizers/lithium-tapering.json';

export interface TaperStep {
  phase: string;
  stepDoseMg: number;
  interval: string;
  untilDoseMg: number;
  notes: string;
}

export interface TaperingRegimen {
  title: string;
  steps: TaperStep[];
  totalDurationMonths: number;
  totalDurationNote: string;
}

export interface WithdrawalEffects {
  rationale: string;
  physical: string[];
  psychological: string[];
}

export interface TaperingProtocol {
  id: string;
  title: string;
  rationale: string;
  whenToConsiderStopping: string[];
  withdrawalEffects: WithdrawalEffects;
  tapering: {
    principle: string;
    rapidVsGradual: string;
    initialReduction: string;
    minimumDoseBeforeStop: string;
    maudsleyRegimen: TaperingRegimen;
  };
  monitoringDuringTaper: string[];
  ifSymptomsEmerge: string[];
  neverDoThis: string[];
  otherMoodStabilizers: string;
  citations: string[];
  lastReviewedISO: string;
  reviewedBy: string;
}

export function getLithiumTapering(): TaperingProtocol {
  return lithiumTapering as unknown as TaperingProtocol;
}
