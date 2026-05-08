// Discontinuation-symptom flagger.
//
// Surfaces severity of the expected discontinuation syndrome on STOPPING
// the from-drug, plus mitigating strategies. Used by the Result screen to
// add a banner above the schedule when relevant.
//
// Sources
//   • Maudsley 15th, ch.3 "Discontinuation symptoms".
//   • Horowitz & Taylor 2019 (hyperbolic taper).

export type DiscontinuationSeverity = 'low' | 'moderate' | 'high' | 'very_high';

export interface DiscontinuationFlag {
  drugId: string;
  severity: DiscontinuationSeverity;
  /** Patient-friendly summary. */
  symptoms: string;
  /** What to do — the clinical recommendation. */
  strategy: string;
  /** Half-life in hours, if relevant for the message. */
  halfLifeHours?: number;
  citation?: string;
}

const FLAGS: Record<string, Omit<DiscontinuationFlag, 'drugId'>> = {
  paroxetine: {
    severity: 'very_high',
    symptoms: 'Dizziness, electric-shock sensations, irritability, flu-like symptoms — onset 1–3 d.',
    strategy: 'Hyperbolic taper over 8+ weeks, OR bridge with fluoxetine (Maudsley algorithm).',
    halfLifeHours: 21,
    citation: 'maudsley15_discontinuation_paroxetine',
  },
  venlafaxine: {
    severity: 'very_high',
    symptoms: 'Severe rebound: dizziness, nausea, agitation. Patients often describe missed-dose symptoms.',
    strategy: 'Switch to fluoxetine 20 mg (long t½) for 1–2 weeks before stopping, then taper fluoxetine.',
    halfLifeHours: 5,
    citation: 'maudsley15_discontinuation_venlafaxine',
  },
  desvenlafaxine: {
    severity: 'high',
    symptoms: 'Similar to venlafaxine but slightly less severe.',
    strategy: 'Cross-taper to fluoxetine, or hyperbolic taper.',
    halfLifeHours: 11,
  },
  duloxetine: {
    severity: 'high',
    symptoms: 'Dizziness, headache, paraesthesia.',
    strategy: 'Step down via 30 mg capsule for 2–4 weeks before stopping.',
    halfLifeHours: 12,
  },
  fluvoxamine: {
    severity: 'moderate',
    symptoms: 'Mild flu-like symptoms; less severe than paroxetine.',
    strategy: 'Standard cross-taper sufficient for most patients.',
    halfLifeHours: 15,
  },
  sertraline: {
    severity: 'moderate',
    symptoms: 'Mild dizziness, headache; usually self-limiting.',
    strategy: 'Standard cross-taper. Counsel patient about expected timeline.',
    halfLifeHours: 26,
  },
  escitalopram: {
    severity: 'moderate',
    symptoms: 'Mild — dizziness, sleep disturbance.',
    strategy: 'Standard cross-taper.',
    halfLifeHours: 30,
  },
  fluoxetine: {
    severity: 'low',
    symptoms: 'Long half-life provides intrinsic taper. Symptoms rare.',
    strategy: 'Direct discontinuation usually tolerated. Patient may not even notice.',
    halfLifeHours: 96,
  },
  agomelatine: {
    severity: 'low',
    symptoms: 'No characteristic discontinuation syndrome.',
    strategy: 'Direct discontinuation acceptable.',
  },
  vortioxetine: {
    severity: 'low',
    symptoms: 'Limited data — appears mild.',
    strategy: 'Standard taper.',
  },
  mirtazapine: {
    severity: 'moderate',
    symptoms: 'Insomnia, anxiety, paraesthesia.',
    strategy: 'Reduce by 7.5 mg every 2 weeks.',
  },

  // Antipsychotics — rebound psychosis / dyskinesia
  clozapine: {
    severity: 'very_high',
    symptoms: 'Severe rebound psychosis within 48–72 h; cholinergic rebound (sweating, GI).',
    strategy: 'Cross-taper to another antipsychotic over ≥4 weeks. Never abrupt unless agranulocytosis.',
    citation: 'maudsley15_clozapine_stopping',
  },
  quetiapine: {
    severity: 'moderate',
    symptoms: 'Insomnia, nausea, rebound anxiety.',
    strategy: 'Taper over 1–2 weeks if low-dose, longer if antipsychotic dose.',
  },
  olanzapine: {
    severity: 'moderate',
    symptoms: 'Insomnia, agitation; cholinergic rebound (cramping, sweats).',
    strategy: 'Cross-taper over 2–4 weeks.',
  },

  // Mood stabilizers
  lithium: {
    severity: 'high',
    symptoms: 'Rebound mania within 90 days of abrupt stop.',
    strategy: 'Taper over ≥3 months unless toxicity. Maintain alternative cover.',
    citation: 'maudsley15_lithium_stopping',
  },
  valproate: {
    severity: 'low',
    symptoms: 'Generally well-tolerated stopping.',
    strategy: 'Taper over 1–2 weeks if epilepsy comorbid; otherwise direct.',
  },
  lamotrigine: {
    severity: 'low',
    symptoms: 'Generally well-tolerated stopping.',
    strategy: 'Taper over 2 weeks to avoid seizure risk if epilepsy comorbid.',
  },
};

/**
 * Get the flag for a single drug. Returns null if not registered (in
 * which case the engine should default to "low risk" silently).
 */
export function getDiscontinuationFlag(drugId: string): DiscontinuationFlag | null {
  const f = FLAGS[drugId];
  if (!f) return null;
  return { drugId, ...f };
}

export function severityRank(s: DiscontinuationSeverity): number {
  return { low: 0, moderate: 1, high: 2, very_high: 3 }[s];
}
