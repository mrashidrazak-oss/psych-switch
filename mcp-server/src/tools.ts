// Tool definitions for the PsychSwitch MCP server.
//
// Each entry describes a tool the server exposes to MCP clients
// (Claude Desktop, Cursor, hospital EMR plugins, etc.). The shape
// matches the @modelcontextprotocol/sdk Tool interface.
//
// Tool names are prefixed `psychswitch_` so they don't collide with
// other servers in a stacked MCP configuration. Descriptions are
// written in the imperative because they get embedded into prompts;
// short and direct beats verbose.

export interface ToolDefinition {
  name: string;
  description: string;
  inputSchema: {
    type: 'object';
    properties?: Record<string, unknown>;
    required?: string[];
  };
}

const PATIENT_CONTEXT_SCHEMA = {
  type: 'object',
  description:
    'Optional patient context. All fields optional; pass only what the clinician has captured. Used for context-aware warnings (CKD, pregnancy, smoking, comorbidities).',
  properties: {
    ageYears: { type: 'number' },
    sex: { type: 'string', enum: ['male', 'female', 'other'] },
    weightKg: { type: 'number' },
    heightCm: { type: 'number' },
    renal: { type: 'string', enum: ['normal', 'mild', 'moderate', 'severe'] },
    egfr: { type: 'number', description: 'mL/min/1.73m². Used to derive renal band when not given.' },
    hepatic: { type: 'string', enum: ['normal', 'mild', 'moderate', 'severe'] },
    pregnant: { type: 'boolean' },
    trimester: { type: 'number', enum: [1, 2, 3] },
    breastfeeding: { type: 'boolean' },
    smoker: { type: 'boolean' },
    comorbidities: {
      type: 'object',
      properties: {
        cardiac: { type: 'boolean' },
        seizure: { type: 'boolean' },
        diabetes: { type: 'boolean' },
        obesity: { type: 'boolean' },
        dyslipidemia: { type: 'boolean' },
      },
    },
  },
};

export const TOOLS: ToolDefinition[] = [
  {
    name: 'psychswitch_list_drugs',
    description:
      'List every drug in the PsychSwitch registry. Returns drug ids, generic names, drug class, category and formulation. Use this to enumerate options before calling other tools. Note: mood stabilizers and LAI / depot antipsychotics are registered in the engine but currently gated from the patient-facing switch picker pending more clinical research. They are still returned by this tool for research / educational queries.',
    inputSchema: {
      type: 'object',
      properties: {
        includeHidden: {
          type: 'boolean',
          description: 'Include hidden drugs (e.g. MAOIs not in the picker). Defaults to false.',
        },
        category: {
          type: 'string',
          enum: ['antidepressant', 'antipsychotic', 'mood-stabilizer'],
          description: 'Optional filter by drug category.',
        },
      },
    },
  },
  {
    name: 'psychswitch_get_drug',
    description:
      'Return the full drug profile for a given id, including dosing, half-life, CYP interactions, per-AE risk fields and citations.',
    inputSchema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Drug id (kebab-case, e.g. "aripiprazole").' },
      },
      required: ['id'],
    },
  },
  {
    name: 'psychswitch_list_rules',
    description:
      'List all reviewed switching rules — id, fromDrugId, toDrugId, strategy (direct / cross-taper / plateau-cross-taper / washout), durationDays, evidence grade (A/B/C/D), reviewer and last-reviewed date. Includes mood-stabilizer + LAI rules even though they are gated from the patient app picker.',
    inputSchema: {
      type: 'object',
      properties: {
        fromDrugId: { type: 'string', description: 'Optional. Filter to rules originating from this drug.' },
        toDrugId: { type: 'string', description: 'Optional. Filter to rules targeting this drug.' },
      },
    },
  },
  {
    name: 'psychswitch_generate_plan',
    description:
      'Generate the COMPLETE switching plan envelope for a drug pair + doses. Returns the schedule, adapted-to-doses schedule, DDI hits, context warnings, evidence grade, PsychSwitch Score, monitoring plan, and predicted AE profile in a single call. This is the main API — prefer it over composing scale_schedule + check_ddi + predict_ae individually.',
    inputSchema: {
      type: 'object',
      properties: {
        fromDrugId: { type: 'string', description: 'Drug id (kebab-case, e.g. "olanzapine").' },
        fromDoseMg: { type: 'number', description: 'Current daily dose in mg (per-injection mg for LAIs).' },
        toDrugId: { type: 'string', description: 'Target drug id.' },
        toDoseMg: { type: 'number', description: 'Target daily dose in mg.' },
        patientContext: PATIENT_CONTEXT_SCHEMA,
      },
      required: ['fromDrugId', 'fromDoseMg', 'toDrugId', 'toDoseMg'],
    },
  },
  {
    name: 'psychswitch_scale_schedule',
    description:
      "Apply adaptive scaling to a reviewed rule's schedule. Useful when the user wants to explore what the schedule looks like at non-reference doses without re-fetching the whole plan envelope.",
    inputSchema: {
      type: 'object',
      properties: {
        fromDrugId: { type: 'string' },
        fromDoseMg: { type: 'number' },
        toDrugId: { type: 'string' },
        toDoseMg: { type: 'number' },
      },
      required: ['fromDrugId', 'fromDoseMg', 'toDrugId', 'toDoseMg'],
    },
  },
  {
    name: 'psychswitch_dose_equivalent',
    description:
      'Convert a dose between drugs in the same equivalency family. Families: cpz (antipsychotics → chlorpromazine 100 mg), fluoxetine (antidepressants → fluoxetine 40 mg), diazepam (benzodiazepines → diazepam 10 mg). When toDrugId is omitted, returns just the reference units (e.g. "0.5 CPZ-eq").',
    inputSchema: {
      type: 'object',
      properties: {
        family: { type: 'string', enum: ['cpz', 'fluoxetine', 'diazepam'] },
        fromDrugId: { type: 'string' },
        fromDoseMg: { type: 'number' },
        toDrugId: { type: 'string', description: 'Optional. Omit for reference-units output only.' },
      },
      required: ['family', 'fromDrugId', 'fromDoseMg'],
    },
  },
  {
    name: 'psychswitch_predict_ae',
    description:
      'Predicted side-effect profile for a target drug, with likelihood tiers (high / moderate / low / lower-than-current). Pass fromDrugId to enable comparative "lower than current drug" hints.',
    inputSchema: {
      type: 'object',
      properties: {
        toDrugId: { type: 'string' },
        fromDrugId: { type: 'string', description: 'Optional. Enables comparative tier.' },
      },
      required: ['toDrugId'],
    },
  },
  {
    name: 'psychswitch_check_ddi',
    description:
      'Check overlap-window interactions for a drug pair (or larger set). Returns serotonergic, CYP, QTc, anticholinergic, sedation, and pharmacodynamic hits with severity (info / caution / warning / avoid) and mitigation guidance.',
    inputSchema: {
      type: 'object',
      properties: {
        drugIds: {
          type: 'array',
          items: { type: 'string' },
          minItems: 2,
          description: 'Two or more drug ids to check pairwise.',
        },
      },
      required: ['drugIds'],
    },
  },
  {
    name: 'psychswitch_compute_score',
    description:
      'Compute the PsychSwitch Score (0-100) for a drug pair without re-fetching the full plan. Use for what-if exploration.',
    inputSchema: {
      type: 'object',
      properties: {
        fromDrugId: { type: 'string' },
        fromDoseMg: { type: 'number' },
        toDrugId: { type: 'string' },
        toDoseMg: { type: 'number' },
        patientContext: PATIENT_CONTEXT_SCHEMA,
      },
      required: ['fromDrugId', 'fromDoseMg', 'toDrugId', 'toDoseMg'],
    },
  },
  {
    name: 'psychswitch_search',
    description:
      'Search across drugs, reviewed rules, tools and modules. Recognises "X to Y", "X -> Y", and "X → Y" pair-form queries (e.g. "olanz to arip" matches the olanzapine → aripiprazole rule). Returns the top results across all kinds, scored by relevance.',
    inputSchema: {
      type: 'object',
      properties: {
        query: { type: 'string', description: 'Free-text search. Drug names, brand names, "X to Y" forms, tool names.' },
        limit: { type: 'number', description: 'Max results. Defaults to 12.' },
      },
      required: ['query'],
    },
  },
  {
    name: 'psychswitch_lookup_glossary',
    description:
      'Define a clinical term from the PsychSwitch glossary (ESRS, QTc, MAOI, CYP2D6, eGFR, NMS, SSRI discontinuation syndrome, etc.). Case-insensitive substring match.',
    inputSchema: {
      type: 'object',
      properties: {
        term: { type: 'string', description: 'Term to look up. Acronyms preferred (e.g. "QTc", "ESRS", "NMS").' },
      },
      required: ['term'],
    },
  },
  {
    name: 'psychswitch_get_citation',
    description:
      'Resolve a citation key (e.g. "maudsley15_ch3_p369_table_3_7") to the full bibliographic reference, locator, and paraphrased quote.',
    inputSchema: {
      type: 'object',
      properties: {
        key: { type: 'string' },
      },
      required: ['key'],
    },
  },
  {
    name: 'psychswitch_context_warnings',
    description:
      'Compute patient-context warnings for a single drug. Returns severity-graded hints (CKD, hepatic, pregnancy, breastfeeding, smoking, comorbidities) for the prescriber.',
    inputSchema: {
      type: 'object',
      properties: {
        drugId: { type: 'string' },
        patientContext: PATIENT_CONTEXT_SCHEMA,
      },
      required: ['drugId'],
    },
  },
  {
    name: 'psychswitch_assess_specialty',
    description:
      'Run the specialty-depth assessment (pregnancy / breastfeeding / pediatric / geriatric) for a switching pair. Returns tier-ranked recommendations (preferred / acceptable / caution / avoid) with dose modifiers, additional monitoring, and known risks. Active only when patient context flags one of these subgroups.',
    inputSchema: {
      type: 'object',
      properties: {
        fromDrugId: { type: 'string' },
        toDrugId: { type: 'string' },
        patientContext: PATIENT_CONTEXT_SCHEMA,
      },
      required: ['fromDrugId', 'toDrugId'],
    },
  },
  {
    name: 'psychswitch_list_errata',
    description:
      'Append-only audit trail of every accepted clinical-content correction. Filterable by rule id (scope) or app version. Use this to verify trust signals, show change history, or generate a "what has changed since version X" summary.',
    inputSchema: {
      type: 'object',
      properties: {
        scope: { type: 'string', description: 'Optional rule id, drug id, or scope label to filter to.' },
        sinceVersion: { type: 'string', description: 'Return only entries first shipped after this version (e.g. "0.3.0").' },
      },
    },
  },
  {
    name: 'psychswitch_quantitative_ae',
    description:
      'Quantitative effect sizes for a drug across adverse effects, drawn from the major network meta-analyses (Leucht 2013 for antipsychotics, Cipriani 2018 for antidepressants). Returns OR / SMD / kg values with 95% CI and citation. Surface this when the assistant needs numbers, not tiers.',
    inputSchema: {
      type: 'object',
      properties: {
        drugId: { type: 'string' },
      },
      required: ['drugId'],
    },
  },
  {
    name: 'psychswitch_cost',
    description:
      'Estimated monthly cost (Malaysian Ringgit) for one or two drugs at typical adult target dose, with affordability tier (subsidised / affordable / moderate / expensive). When two drugs are given, returns a delta. Curated rough estimates — not real-time pricing.',
    inputSchema: {
      type: 'object',
      properties: {
        drugIds: {
          type: 'array',
          items: { type: 'string' },
          minItems: 1,
          maxItems: 2,
        },
      },
      required: ['drugIds'],
    },
  },
  {
    name: 'psychswitch_overlap_intensity',
    description:
      'Assess the cross-taper overlap intensity (low / moderate / high / severe) for a switching pair. Composite of Day-1 dose intensity, overlap window length, and receptor-mechanism stacking (serotonergic / QT-additive / sedation-additive / EPS-additive / anticholinergic). Use this when the user asks "is this overlap risky" — surfaces a tier + 0-100 score with rationale.',
    inputSchema: {
      type: 'object',
      properties: {
        fromDrugId: { type: 'string' },
        fromDoseMg: { type: 'number' },
        toDrugId: { type: 'string' },
        toDoseMg: { type: 'number' },
      },
      required: ['fromDrugId', 'fromDoseMg', 'toDrugId', 'toDoseMg'],
    },
  },
];
