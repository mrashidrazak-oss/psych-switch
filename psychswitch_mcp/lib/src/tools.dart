// MCP tool descriptors — JSON Schema definitions returned by tools/list.
//
// Each descriptor mirrors the existing Node tools.ts shape so MCP
// clients (Claude Desktop, Cursor, etc.) keep working unchanged when
// the server is swapped from Node → Dart.
//
// 18 tools, all prefixed `psychswitch_`. The handler implementations
// live in handlers.dart.

const List<Map<String, dynamic>> toolDescriptors = <Map<String, dynamic>>[
  // ── Drug registry ──────────────────────────────────────────────
  <String, dynamic>{
    'name': 'psychswitch_list_drugs',
    'description': 'List every visible drug in the registry. Returns id, '
        'genericName, drugClass, formulation, and category for each. '
        'Use psychswitch_get_drug for the full profile of a single drug.',
    'inputSchema': <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'includeHidden': <String, dynamic>{
          'type': 'boolean',
          'description':
              'When true, includes hidden registry entries (MAOIs, deprecated '
                  'LAIs). Default false.',
          'default': false,
        },
      },
    },
  },
  <String, dynamic>{
    'name': 'psychswitch_get_drug',
    'description':
        'Full drug profile (e.g. olanzapine): half-life, active metabolite, CYP interactions, MAOI washout, EPS/metabolic/QTc/sedation/prolactin/discontinuation risk, dosing, citations.',
    'inputSchema': <String, dynamic>{
      'type': 'object',
      'required': <String>['drugId'],
      'properties': <String, dynamic>{
        'drugId': <String, dynamic>{
          'type': 'string',
          'description': "Drug id, e.g. 'olanzapine', 'sertraline'.",
        },
      },
    },
  },

  // ── Switching rules ────────────────────────────────────────────
  <String, dynamic>{
    'name': 'psychswitch_list_rules',
    'description': 'List every reviewed cross-titration rule (id, fromDrugId, '
        'toDrugId, strategy, durationDays, citations).',
    'inputSchema': <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{},
    },
  },
  <String, dynamic>{
    'name': 'psychswitch_generate_plan',
    'description': 'Generate a cross-taper plan. Returns one of: ok '
        '(reviewed schedule), maudsley_guidance (class-level fallback), '
        'maoi_washout, clozapine_redirect, no_rule.',
    'inputSchema': <String, dynamic>{
      'type': 'object',
      'required': <String>['fromDrugId', 'fromDoseMg', 'toDrugId', 'toDoseMg'],
      'properties': <String, dynamic>{
        'fromDrugId': <String, dynamic>{'type': 'string'},
        'fromDoseMg': <String, dynamic>{'type': 'number'},
        'toDrugId': <String, dynamic>{'type': 'string'},
        'toDoseMg': <String, dynamic>{'type': 'number'},
      },
    },
  },
  <String, dynamic>{
    'name': 'psychswitch_scale_schedule',
    'description': "Adapt a reviewed rule to the user's actual doses. "
        'Returns the scaled schedule + warnings (capped_at_max, '
        'rounded_to_zero, merged_duplicate, extreme_factor).',
    'inputSchema': <String, dynamic>{
      'type': 'object',
      'required': <String>[
        'fromDrugId',
        'fromDoseMg',
        'toDrugId',
        'toDoseMg',
      ],
      'properties': <String, dynamic>{
        'fromDrugId': <String, dynamic>{'type': 'string'},
        'fromDoseMg': <String, dynamic>{'type': 'number'},
        'toDrugId': <String, dynamic>{'type': 'string'},
        'toDoseMg': <String, dynamic>{'type': 'number'},
      },
    },
  },

  // ── Dose equivalence ──────────────────────────────────────────
  <String, dynamic>{
    'name': 'psychswitch_dose_equivalent',
    'description': 'Convert a dose between drugs in the same family '
        '(cpz / fluoxetine / diazepam equivalents).',
    'inputSchema': <String, dynamic>{
      'type': 'object',
      'required': <String>['family', 'fromDrugId', 'fromDoseMg', 'toDrugId'],
      'properties': <String, dynamic>{
        'family': <String, dynamic>{
          'type': 'string',
          'enum': <String>['cpz', 'fluoxetine', 'diazepam'],
        },
        'fromDrugId': <String, dynamic>{'type': 'string'},
        'fromDoseMg': <String, dynamic>{'type': 'number'},
        'toDrugId': <String, dynamic>{'type': 'string'},
      },
    },
  },

  // ── AE prediction + lookup ────────────────────────────────────
  <String, dynamic>{
    'name': 'psychswitch_predict_ae',
    'description': 'Predicted side-effect profile for a to-drug, with '
        'comparative tier when fromDrugId is supplied (e.g. "lower than '
        'current drug" for weight gain when switching olanzapine → '
        'aripiprazole).',
    'inputSchema': <String, dynamic>{
      'type': 'object',
      'required': <String>['toDrugId'],
      'properties': <String, dynamic>{
        'toDrugId': <String, dynamic>{'type': 'string'},
        'fromDrugId': <String, dynamic>{'type': 'string'},
      },
    },
  },
  <String, dynamic>{
    'name': 'psychswitch_quantitative_ae',
    'description': 'Curated effect sizes from Leucht 2013 + Cipriani 2018 '
        '(SMD vs placebo, kg of weight gain, OR for EPS / akathisia / '
        'prolactin / dropout) for a single drug.',
    'inputSchema': <String, dynamic>{
      'type': 'object',
      'required': <String>['drugId'],
      'properties': <String, dynamic>{
        'drugId': <String, dynamic>{'type': 'string'},
      },
    },
  },

  // ── DDI ────────────────────────────────────────────────────────
  <String, dynamic>{
    'name': 'psychswitch_check_ddi',
    'description': 'Drug-drug interactions for the overlap window of a '
        'cross-taper. Five mechanisms: serotonergic stacking, '
        'CYP-mediated, QT additive, sedation additive, anticholinergic '
        'burden, pharmacodynamic conflict.',
    'inputSchema': <String, dynamic>{
      'type': 'object',
      'required': <String>['drugIds'],
      'properties': <String, dynamic>{
        'drugIds': <String, dynamic>{
          'type': 'array',
          'items': <String, dynamic>{'type': 'string'},
        },
      },
    },
  },

  // ── Score + overlap ───────────────────────────────────────────
  <String, dynamic>{
    'name': 'psychswitch_compute_score',
    'description': 'PsychSwitch Score (0–100) for a switch — composite over '
        'evidence grade, AE alignment, context safety, DDI safety, dose '
        'fidelity. Returns total + band + per-component breakdown.',
    'inputSchema': <String, dynamic>{
      'type': 'object',
      'required': <String>['fromDrugId', 'fromDoseMg', 'toDrugId', 'toDoseMg'],
      'properties': <String, dynamic>{
        'fromDrugId': <String, dynamic>{'type': 'string'},
        'fromDoseMg': <String, dynamic>{'type': 'number'},
        'toDrugId': <String, dynamic>{'type': 'string'},
        'toDoseMg': <String, dynamic>{'type': 'number'},
      },
    },
  },
  <String, dynamic>{
    'name': 'psychswitch_overlap_intensity',
    'description': 'Day-1 overlap intensity for a generated cross-taper. '
        'Returns tier (low/moderate/high/severe) + 0-100 score + flagged '
        'mechanisms (serotonergic_stacking, qt_additive, etc.).',
    'inputSchema': <String, dynamic>{
      'type': 'object',
      'required': <String>['fromDrugId', 'fromDoseMg', 'toDrugId', 'toDoseMg'],
      'properties': <String, dynamic>{
        'fromDrugId': <String, dynamic>{'type': 'string'},
        'fromDoseMg': <String, dynamic>{'type': 'number'},
        'toDrugId': <String, dynamic>{'type': 'string'},
        'toDoseMg': <String, dynamic>{'type': 'number'},
      },
    },
  },

  // ── Search + glossary ─────────────────────────────────────────
  <String, dynamic>{
    'name': 'psychswitch_search',
    'description': 'Free-text search across drugs and rules. e.g. '
        '"olanz to arip", "ssri washout", "lithium taper".',
    'inputSchema': <String, dynamic>{
      'type': 'object',
      'required': <String>['query'],
      'properties': <String, dynamic>{
        'query': <String, dynamic>{'type': 'string'},
      },
    },
  },
  <String, dynamic>{
    'name': 'psychswitch_lookup_glossary',
    'description':
        "Look up a clinical term (e.g. 'QTc', 'EPS', 'NMS', 'CYP2D6', "
            "'LAI', 'FBC', 'eGFR'). Case-insensitive.",
    'inputSchema': <String, dynamic>{
      'type': 'object',
      'required': <String>['term'],
      'properties': <String, dynamic>{
        'term': <String, dynamic>{'type': 'string'},
      },
    },
  },

  // ── Citations + errata ────────────────────────────────────────
  <String, dynamic>{
    'name': 'psychswitch_get_citation',
    'description': 'Resolve a citation key to the full entry (source, '
        'reference text, optional paraphrase, ISBN, page locator).',
    'inputSchema': <String, dynamic>{
      'type': 'object',
      'required': <String>['key'],
      'properties': <String, dynamic>{
        'key': <String, dynamic>{
          'type': 'string',
          'description': "e.g. 'maudsley15_ch3_p369_table_3_7'.",
        },
      },
    },
  },
  <String, dynamic>{
    'name': 'psychswitch_list_errata',
    'description': 'List every accepted clinical-content correction. '
        'Filterable by scope (rule/drug id) or sinceVersion.',
    'inputSchema': <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'scope': <String, dynamic>{'type': 'string'},
        'sinceVersion': <String, dynamic>{'type': 'string'},
      },
    },
  },

  // ── Patient context + specialty ──────────────────────────────
  <String, dynamic>{
    'name': 'psychswitch_context_warnings',
    'description': 'Generate patient-context warnings for a drug given an '
        'age/renal/hepatic/pregnancy/comorbidity context. Returns '
        'severity-tagged messages (info / warning / danger).',
    'inputSchema': <String, dynamic>{
      'type': 'object',
      'required': <String>['drugId'],
      'properties': <String, dynamic>{
        'drugId': <String, dynamic>{'type': 'string'},
        'context': <String, dynamic>{
          'type': 'object',
          'description':
              'Subset of PatientContext fields. e.g. { ageYears, sex, '
                  'renal, hepatic, pregnant, trimester, breastfeeding, '
                  'smoker, comorbidities: { cardiac, diabetes, ... } }',
        },
      },
    },
  },
  <String, dynamic>{
    'name': 'psychswitch_assess_specialty',
    'description': 'Specialty depth assessment (pregnancy / breastfeeding / '
        'pediatric / geriatric) for a drug pair given the patient context.',
    'inputSchema': <String, dynamic>{
      'type': 'object',
      'required': <String>['fromDrugId', 'toDrugId'],
      'properties': <String, dynamic>{
        'fromDrugId': <String, dynamic>{'type': 'string'},
        'toDrugId': <String, dynamic>{'type': 'string'},
        'context': <String, dynamic>{'type': 'object'},
      },
    },
  },

  // ── Cost ───────────────────────────────────────────────────────
  <String, dynamic>{
    'name': 'psychswitch_cost',
    'description': 'Malaysian monthly cost (MYR) for a drug + tier '
        '(subsidised / affordable / moderate / expensive).',
    'inputSchema': <String, dynamic>{
      'type': 'object',
      'required': <String>['drugId'],
      'properties': <String, dynamic>{
        'drugId': <String, dynamic>{'type': 'string'},
      },
    },
  },
];
