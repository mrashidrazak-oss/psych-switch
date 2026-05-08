// Shared types for the specialty-depth modules.

export type SpecialtyTier = 'preferred' | 'acceptable' | 'caution' | 'avoid';

export type Specialty = 'pregnancy' | 'breastfeeding' | 'pediatric' | 'geriatric';

export interface PregnancyEntry {
  drugId: string;
  tier: SpecialtyTier;
  /** When set, overrides the base tier for the given trimester. */
  trimesterOverrides?: { 1?: SpecialtyTier; 2?: SpecialtyTier; 3?: SpecialtyTier };
  rationale: string;
  /** Specific known fetal / maternal risks. */
  knownRisks?: string;
  /** Required additional monitoring. Free-form, one entry per item. */
  additionalMonitoring?: string[];
  /** Tier for breastfeeding (often differs from pregnancy). */
  breastfeedingTier?: SpecialtyTier;
  citations: string[];
}

export interface PediatricEntry {
  drugId: string;
  tier: SpecialtyTier;
  /** Age in years from which the drug is licensed (any indication). null = off-label all ages. */
  licensedFrom: number | null;
  /** Indication(s) for which licensing applies. */
  licensedFor: string | null;
  /** Multiplier for adult target dose. Defaults to 0.5 if absent. */
  doseFactor?: number;
  rationale: string;
  citations: string[];
}

export interface GeriatricEntry {
  drugId: string;
  tier: SpecialtyTier;
  /** Multiplier for adult target dose. */
  doseFactor: number;
  /** Composite of sedation + orthostasis + EPS. */
  fallsRisk: 'low' | 'moderate' | 'high' | 'very high';
  /** Anticholinergic + cognitive blunting contribution. */
  cognitiveRisk: 'low' | 'moderate' | 'high' | 'very high';
  rationale: string;
  citations: string[];
}
