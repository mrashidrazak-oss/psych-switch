// Global search — one-box jumping point across the whole app.
//
// A single query searches three indexes at once:
//
//   • Drugs — generic name, Malaysian brand names, drug class
//   • Glossary terms
//   • App tools (calculators, regimen check, comparator, depot…)
//
// Results render in three named groups so the user always knows what
// kind of thing they're tapping. Tapping a drug routes to its profile;
// glossary scrolls to that term; tool routes to the screen.
//
// Designed for the "I know there's something for this — where is it?"
// moment that an unfamiliar UI always has. Pure presentation, all
// indexes are computed in-memory from already-loaded providers.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/providers/engine_provider.dart';
import 'package:psychswitch/src/router.dart';
import 'package:psychswitch/src/ui/haptics.dart';
import 'package:psychswitch/src/ui/theme/clinical_theme.dart';
import 'package:psychswitch/src/ui/theme/tokens.dart';
import 'package:psychswitch/src/ui/widgets/engine_loading_view.dart';
import 'package:psychswitch_engine/glossary.dart';
import 'package:psychswitch_engine/switching_engine.dart';
import 'package:psychswitch_engine/types/drug.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engineAsync = ref.watch(engineProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: engineAsync.when(
          loading: () => const EngineLoadingView(),
          error: (e, _) => EngineErrorView(error: e),
          data: (engine) => Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.md,
                  ClinicalSpace.lg + 4,
                  ClinicalSpace.sm,
                ),
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  style: ClinicalText.body,
                  onChanged: (v) => setState(() => _q = v),
                  decoration: InputDecoration(
                    hintText: 'Search drugs, brands, terms, tools',
                    hintStyle: ClinicalText.body
                        .copyWith(color: ClinicalPalette.muted),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _q.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _ctrl.clear();
                              setState(() => _q = '');
                              unawaited(hapticsTap());
                            },
                          ),
                    filled: true,
                    fillColor: ClinicalPalette.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ClinicalRadii.tile),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(child: _Results(engine: engine, q: _q)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.engine, required this.q});

  final SwitchingEngine engine;
  final String q;

  @override
  Widget build(BuildContext context) {
    final query = q.trim().toLowerCase();

    if (query.isEmpty) return const _EmptyHint();

    final drugs = _searchDrugs(engine, query);
    final terms = _searchGlossary(query);
    final tools = _searchTools(query);

    if (drugs.isEmpty && terms.isEmpty && tools.isEmpty) {
      return const _NoResults();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg + 4,
        ClinicalSpace.sm,
        ClinicalSpace.lg + 4,
        ClinicalSpace.xl,
      ),
      children: <Widget>[
        if (tools.isNotEmpty) ...<Widget>[
          _GroupHeader(label: 'Tools', count: tools.length),
          _Card(child: Column(children: <Widget>[
            for (var i = 0; i < tools.length; i++) ...<Widget>[
              if (i > 0) _hairline(),
              _ToolRow(item: tools[i]),
            ],
          ])),
          const Gap.v(ClinicalSpace.lg),
        ],
        if (drugs.isNotEmpty) ...<Widget>[
          _GroupHeader(label: 'Drugs', count: drugs.length),
          _Card(child: Column(children: <Widget>[
            for (var i = 0; i < drugs.length; i++) ...<Widget>[
              if (i > 0) _hairline(),
              _DrugRow(drug: drugs[i], query: query),
            ],
          ])),
          const Gap.v(ClinicalSpace.lg),
        ],
        if (terms.isNotEmpty) ...<Widget>[
          _GroupHeader(label: 'Glossary', count: terms.length),
          _Card(child: Column(children: <Widget>[
            for (var i = 0; i < terms.length; i++) ...<Widget>[
              if (i > 0) _hairline(),
              _TermRow(entry: terms[i]),
            ],
          ])),
        ],
      ],
    );
  }

  static Widget _hairline() => Divider(
        height: 0.5,
        thickness: 0.5,
        color: ClinicalPalette.border.withValues(alpha: 0.7),
      );
}

// ── Indexes ─────────────────────────────────────────────────────────

List<Drug> _searchDrugs(SwitchingEngine engine, String q) {
  final hits = <Drug>[];
  for (final d in engine.listDrugs()) {
    if (d.genericName.toLowerCase().contains(q)) {
      hits.add(d);
      continue;
    }
    if (d.drugClass.toLowerCase().contains(q)) {
      hits.add(d);
      continue;
    }
    for (final b in d.malaysianBrandNames) {
      if (b.toLowerCase().contains(q)) {
        hits.add(d);
        break;
      }
    }
  }
  hits.sort((a, b) => a.genericName.compareTo(b.genericName));
  return hits.take(20).toList();
}

List<GlossaryEntry> _searchGlossary(String q) {
  final all = listGlossary();
  final hits = <GlossaryEntry>[];
  for (final e in all) {
    if (e.term.toLowerCase().contains(q) ||
        e.definition.toLowerCase().contains(q)) {
      hits.add(e);
    }
  }
  return hits.take(15).toList();
}

class _ToolItem {
  const _ToolItem({
    required this.label,
    required this.tagline,
    required this.icon,
    required this.route,
    this.keywords = const <String>[],
  });

  final String label;
  final String tagline;
  final IconData icon;
  final String route;
  final List<String> keywords;
}

const List<_ToolItem> _allTools = <_ToolItem>[
  _ToolItem(
    label: 'Switch wizard',
    tagline: 'Generate a cross-titration plan',
    icon: Icons.swap_horiz_rounded,
    route: Routes.switch_,
    keywords: <String>['switch', 'taper', 'cross-titration'],
  ),
  _ToolItem(
    label: 'Compare drugs',
    tagline: 'Side-by-side attribute matrix',
    icon: Icons.compare_arrows,
    route: Routes.compare,
    keywords: <String>['compare', 'side by side'],
  ),
  _ToolItem(
    label: 'Regimen check',
    tagline: 'QTc · ACB · sedation · DDI',
    icon: Icons.medication_outlined,
    route: Routes.polypharmacy,
    keywords: <String>[
      'polypharmacy',
      'regimen',
      'ddi',
      'interaction',
      'anticholinergic',
      'acb',
    ],
  ),
  _ToolItem(
    label: 'Rating scales',
    tagline: 'PHQ-9 · GAD-7 · MADRS · EPDS · AUDIT · DAST-10 · HAM-D · AIMS',
    icon: Icons.assignment_turned_in_outlined,
    route: Routes.scales,
    keywords: <String>[
      'phq', 'gad', 'madrs', 'hamilton', 'hamd', 'aims', 'epds',
      'audit', 'dast', 'scale', 'rating',
      'depression', 'anxiety', 'dyskinesia', 'alcohol', 'drug',
      'postnatal', 'perinatal',
    ],
  ),
  _ToolItem(
    label: 'C-SSRS suicide screen',
    tagline: 'Columbia severity + risk tier',
    icon: Icons.emergency_outlined,
    route: Routes.cssrs,
    keywords: <String>[
      'cssrs', 'columbia', 'suicide', 'suicidal', 'ideation',
      'self-harm', 'risk',
    ],
  ),
  _ToolItem(
    label: 'NMS screener',
    tagline: 'Neuroleptic malignant syndrome',
    icon: Icons.local_fire_department_outlined,
    route: Routes.nms,
    keywords: <String>[
      'nms', 'neuroleptic', 'malignant', 'rigidity', 'fever', 'ck',
      'levenson', 'rhabdomyolysis',
    ],
  ),
  _ToolItem(
    label: 'Serotonin syndrome',
    tagline: 'Hunter toxicity criteria',
    icon: Icons.bolt_outlined,
    route: Routes.serotonin,
    keywords: <String>[
      'serotonin', 'hunter', 'clonus', 'cyproheptadine', 'tramadol',
      'maoi', 'syndrome',
    ],
  ),
  _ToolItem(
    label: 'TDM interpreter',
    tagline: 'Lithium · clozapine · valproate · lamotrigine',
    icon: Icons.science_outlined,
    route: Routes.tdm,
    keywords: <String>[
      'tdm', 'level', 'lithium', 'clozapine', 'valproate', 'lamotrigine',
      'therapeutic', 'serum', 'monitoring', 'trough',
    ],
  ),
  _ToolItem(
    label: 'Lab interpreter',
    tagline: 'TSH · prolactin · ANC · sodium · HbA1c · more',
    icon: Icons.biotech_outlined,
    route: Routes.lab,
    keywords: <String>[
      'lab', 'tsh', 'prolactin', 'anc', 'sodium', 'na', 'ck', 'creatinine',
      'hba1c', 'glucose', 'ldl', 'lipid', 'alt', 'thyroid', 'neutrophil',
    ],
  ),
  _ToolItem(
    label: 'Movement disorder',
    tagline: 'EPS differentiator',
    icon: Icons.accessibility_new,
    route: Routes.movement,
    keywords: <String>[
      'eps', 'parkinsonism', 'akathisia', 'dystonia', 'tardive',
      'tremor', 'movement', 'aimsdifferential',
    ],
  ),
  _ToolItem(
    label: 'Agitation management',
    tagline: 'De-escalation + rapid tranquillisation',
    icon: Icons.flash_on_outlined,
    route: Routes.agitation,
    keywords: <String>[
      'agitation', 'rapid', 'tranquillisation', 'tranquilization',
      'haloperidol', 'lorazepam', 'olanzapine', 'promethazine', 'rt',
      'restraint',
    ],
  ),
  _ToolItem(
    label: 'Clinician self-care',
    tagline: 'Weekly burnout check',
    icon: Icons.favorite_border,
    route: Routes.selfCare,
    keywords: <String>[
      'burnout', 'self-care', 'wellness', 'maslach', 'fatigue',
      'recovery',
    ],
  ),
  _ToolItem(
    label: 'AD deprescribing',
    tagline: 'Hyperbolic taper planner',
    icon: Icons.trending_down,
    route: Routes.deprescribing,
    keywords: <String>[
      'deprescribe', 'deprescribing', 'taper', 'hyperbolic', 'stop',
      'discontinue', 'withdrawal', 'horowitz', 'maudsley', 'wean',
    ],
  ),
  _ToolItem(
    label: 'Benzo taper',
    tagline: 'Diazepam-equivalent + Ashton schedule',
    icon: Icons.trending_down,
    route: Routes.benzoTaper,
    keywords: <String>[
      'benzo', 'benzodiazepine', 'diazepam', 'ashton', 'taper',
      'equivalent', 'lorazepam', 'alprazolam', 'clonazepam',
      'zopiclone', 'zolpidem', 'wean', 'withdrawal',
    ],
  ),
  _ToolItem(
    label: '4AT delirium',
    tagline: 'Rapid delirium assessment',
    icon: Icons.psychology_alt_outlined,
    route: Routes.delirium4at,
    keywords: <String>[
      '4at', 'delirium', 'confusion', 'amt4', 'attention',
      'cognitive', 'acute', 'fluctuating',
    ],
  ),
  _ToolItem(
    label: 'Catatonia screen',
    tagline: 'Bush-Francis + lorazepam challenge',
    icon: Icons.accessibility_new,
    route: Routes.catatonia,
    keywords: <String>[
      'catatonia', 'bush', 'francis', 'bfcsi', 'stupor', 'mutism',
      'posturing', 'waxy', 'negativism', 'lorazepam',
    ],
  ),
  _ToolItem(
    label: 'Hyperthermic Dx',
    tagline: 'NMS vs serotonin vs catatonia vs anticholinergic',
    icon: Icons.local_fire_department_outlined,
    route: Routes.hyperthermicDx,
    keywords: <String>[
      'hyperthermia', 'hyperthermic', 'nms', 'serotonin', 'malignant',
      'catatonia', 'anticholinergic', 'toxidrome', 'rigidity',
      'clonus', 'differential',
    ],
  ),
  _ToolItem(
    label: 'Lithium toxicity',
    tagline: 'Graded management + dialysis criteria',
    icon: Icons.science_outlined,
    route: Routes.lithiumToxicity,
    keywords: <String>[
      'lithium', 'toxicity', 'toxic', 'dialysis', 'haemodialysis',
      'extrip', 'level', 'tremor', 'ataxia', 'overdose',
    ],
  ),
  _ToolItem(
    label: 'Alcohol withdrawal',
    tagline: 'CIWA-driven regimen + thiamine',
    icon: Icons.local_bar_outlined,
    route: Routes.alcoholWithdrawal,
    keywords: <String>[
      'alcohol', 'withdrawal', 'ciwa', 'chlordiazepoxide',
      'librium', 'detox', 'dts', 'delirium tremens', 'thiamine',
    ],
  ),
  _ToolItem(
    label: 'OST induction',
    tagline: 'Buprenorphine / methadone day-1',
    icon: Icons.medication_liquid_outlined,
    route: Routes.ostInduction,
    keywords: <String>[
      'ost', 'opioid', 'substitution', 'buprenorphine', 'subutex',
      'methadone', 'induction', 'cows', 'precipitated', 'opiate',
    ],
  ),
  _ToolItem(
    label: 'Wernicke / thiamine',
    tagline: 'Prophylaxis vs treatment dosing',
    icon: Icons.vaccines_outlined,
    route: Routes.thiamine,
    keywords: <String>[
      'wernicke', 'thiamine', 'pabrinex', 'b1', 'korsakoff',
      'encephalopathy', 'prophylaxis', 'vitamin',
    ],
  ),
  _ToolItem(
    label: 'Hyponatraemia / SIADH',
    tagline: 'Sodium + symptom-graded plan',
    icon: Icons.water_drop_outlined,
    route: Routes.hyponatraemia,
    keywords: <String>[
      'hyponatraemia', 'hyponatremia', 'sodium', 'na', 'siadh',
      'ssri', 'snri', 'carbamazepine', 'demyelination',
    ],
  ),
  _ToolItem(
    label: 'Hyperprolactinaemia',
    tagline: 'Prolactin band + prolactinoma threshold',
    icon: Icons.science_outlined,
    route: Routes.hyperprolactinaemia,
    keywords: <String>[
      'prolactin', 'hyperprolactinaemia', 'hyperprolactinemia',
      'galactorrhoea', 'risperidone', 'amisulpride', 'aripiprazole',
      'prolactinoma',
    ],
  ),
  _ToolItem(
    label: 'Clozapine myocarditis',
    tagline: 'First-weeks troponin/CRP surveillance',
    icon: Icons.monitor_heart_outlined,
    route: Routes.clozapineMyocarditis,
    keywords: <String>[
      'clozapine', 'myocarditis', 'troponin', 'crp', 'cardiac',
      'titration', 'cardiomyopathy', 'pericarditis',
    ],
  ),
  _ToolItem(
    label: 'Valproate PPP',
    tagline: 'Pregnancy Prevention Programme gate',
    icon: Icons.pregnant_woman_outlined,
    route: Routes.valproatePpp,
    keywords: <String>[
      'valproate', 'valproic', 'sodium valproate', 'ppp',
      'pregnancy prevention', 'teratogen', 'childbearing',
      'epilim', 'depakote', 'contraception',
    ],
  ),
  _ToolItem(
    label: 'Olanzapine LAI — PDSS',
    tagline: 'Post-injection observation + triage',
    icon: Icons.timer_outlined,
    route: Routes.postInjectionSyndrome,
    keywords: <String>[
      'olanzapine', 'pamoate', 'lai', 'depot', 'pdss', 'pios',
      'post-injection', 'post injection', 'sedation', 'delirium',
      'zypadhera',
    ],
  ),
  _ToolItem(
    label: 'Opioid overdose',
    tagline: 'Naloxone + airway + observation',
    icon: Icons.emergency_outlined,
    route: Routes.opioidOverdose,
    keywords: <String>[
      'opioid', 'overdose', 'naloxone', 'narcan', 'heroin',
      'methadone', 'fentanyl', 'take-home', 'reversal',
      'respiratory',
    ],
  ),
  _ToolItem(
    label: 'Pre-stimulant cardiac',
    tagline: 'ADHD cardiovascular screening gate',
    icon: Icons.favorite_border,
    route: Routes.stimulantCardiac,
    keywords: <String>[
      'stimulant', 'adhd', 'methylphenidate', 'lisdexamfetamine',
      'cardiac', 'cardiovascular', 'ecg', 'screening', 'atomoxetine',
    ],
  ),
  _ToolItem(
    label: 'High-dose antipsychotic',
    tagline: 'Cumulative %-of-max + HDAT safeguards',
    icon: Icons.stacked_line_chart_outlined,
    route: Routes.antipsychoticHighDose,
    keywords: <String>[
      'high dose', 'hdat', 'antipsychotic', 'maximum', 'bnf max',
      'polypharmacy', 'cumulative', 'percent', 'monitoring',
    ],
  ),
  _ToolItem(
    label: 'Bupe micro-dosing',
    tagline: 'Bernese overlapping induction',
    icon: Icons.timeline_outlined,
    route: Routes.bupeMicrodosing,
    keywords: <String>[
      'buprenorphine', 'microdosing', 'micro-dosing', 'bernese',
      'induction', 'fentanyl', 'methadone', 'subutex', 'suboxone',
      'overlap',
    ],
  ),
  _ToolItem(
    label: 'Acute pain on OST',
    tagline: 'Continue maintenance + additive analgesia',
    icon: Icons.healing_outlined,
    route: Routes.ostAcutePain,
    keywords: <String>[
      'pain', 'analgesia', 'ost', 'methadone', 'buprenorphine',
      'naltrexone', 'perioperative', 'surgery', 'opioid',
    ],
  ),
  _ToolItem(
    label: 'Antipsychotic + Parkinsonism',
    tagline: 'Lewy-body sensitivity, safe choices, BPSD',
    icon: Icons.psychology_outlined,
    route: Routes.antipsychoticParkinsonism,
    keywords: <String>[
      'parkinson', 'lewy', 'dlb', 'pdd', 'dementia', 'bpsd',
      'neuroleptic sensitivity', 'quetiapine', 'clozapine',
      'pimavanserin', 'risperidone',
    ],
  ),
  _ToolItem(
    label: 'ECT work-up',
    tagline: 'Pre-ECT checklist + drug review',
    icon: Icons.electric_bolt_outlined,
    route: Routes.ectWorkup,
    keywords: <String>[
      'ect', 'electroconvulsive', 'work-up', 'workup', 'anaesthetic',
      'consent', 'fasting', 'lithium', 'seizure', 'checklist',
    ],
  ),
  _ToolItem(
    label: 'MAOI diet',
    tagline: 'Tyramine food tiers + crisis script',
    icon: Icons.restaurant_outlined,
    route: Routes.maoiDiet,
    keywords: <String>[
      'maoi', 'tyramine', 'diet', 'cheese', 'phenelzine',
      'tranylcypromine', 'hypertensive', 'crisis', 'food',
    ],
  ),
  _ToolItem(
    label: 'Refeeding risk',
    tagline: 'NICE criteria + feeding plan',
    icon: Icons.monitor_weight_outlined,
    route: Routes.refeeding,
    keywords: <String>[
      'refeeding', 'nice', 'marsipan', 'anorexia', 'malnutrition',
      'phosphate', 'thiamine', 'eating', 'starvation',
    ],
  ),
  _ToolItem(
    label: 'Renal & hepatic dosing',
    tagline: 'eGFR / Child-Pugh adjustment',
    icon: Icons.water_drop_outlined,
    route: Routes.renalHepatic,
    keywords: <String>[
      'renal', 'hepatic', 'egfr', 'ckd', 'child-pugh', 'liver',
      'kidney', 'dialysis', 'dose', 'adjustment', 'impairment',
    ],
  ),
  _ToolItem(
    label: 'Pharmacogenomics',
    tagline: 'CYP2D6 / CYP2C19 dosing',
    icon: Icons.biotech_outlined,
    route: Routes.pharmacogenomics,
    keywords: <String>[
      'pgx', 'pharmacogenomics', 'genotype', 'cyp2d6', 'cyp2c19',
      'metaboliser', 'metabolizer', 'poor', 'ultrarapid', 'cpic',
    ],
  ),
  _ToolItem(
    label: 'Metabolic monitoring',
    tagline: 'Antipsychotic monitoring calendar',
    icon: Icons.event_available_outlined,
    route: Routes.metabolicMonitoring,
    keywords: <String>[
      'metabolic', 'monitoring', 'schedule', 'baseline', 'lipid',
      'hba1c', 'antipsychotic', 'lester', 'weight', 'waist',
    ],
  ),
  _ToolItem(
    label: 'Smoking & CYP1A2',
    tagline: 'Clozapine / olanzapine dose adjustment',
    icon: Icons.smoke_free,
    route: Routes.smokingAdjustment,
    keywords: <String>[
      'smoking', 'cyp1a2', 'cessation', 'clozapine', 'olanzapine',
      'induction', 'tobacco', 'cigarette', 'quit',
    ],
  ),
  _ToolItem(
    label: 'Capacity assessment',
    tagline: 'Four-limb ACE evaluation',
    icon: Icons.balance,
    route: Routes.capacity,
    keywords: <String>[
      'capacity', 'ace', 'consent', 'mca', 'understand', 'retain',
      'weigh', 'communicate',
    ],
  ),
  _ToolItem(
    label: 'MSE generator',
    tagline: 'Mental State Exam narrative',
    icon: Icons.edit_note_rounded,
    route: Routes.mse,
    keywords: <String>[
      'mse', 'mental state', 'narrative', 'note', 'documentation',
      'examination',
    ],
  ),
  _ToolItem(
    label: 'Crisis + safety plan',
    tagline: 'Lifelines · Stanley-Brown plan',
    icon: Icons.phone_in_talk,
    route: Routes.crisis,
    keywords: <String>[
      'crisis', 'safety', 'plan', 'talian', 'kasih', 'befrienders',
      'mentari', 'helpline', 'hotline', 'suicide',
    ],
  ),
  _ToolItem(
    label: 'MHA 2001 (Malaysia)',
    tagline: 'Sections · durations · forms',
    icon: Icons.gavel_outlined,
    route: Routes.mha,
    keywords: <String>[
      'mha', 'mental health act', 'section', 'admission', 'detention',
      'involuntary', 'voluntary', 'act 615', 'gazette', 'malaysia',
    ],
  ),
  _ToolItem(
    label: 'DSM-5-TR criteria',
    tagline: 'Tick-box criterion sets',
    icon: Icons.checklist_rounded,
    route: Routes.dsm,
    keywords: <String>[
      'dsm', 'criteria', 'diagnosis', 'mdd', 'gad', 'ptsd',
      'schizophrenia', 'ocd', 'mania', 'bipolar', 'panic', 'aud', 'adhd',
    ],
  ),
  _ToolItem(
    label: 'Pregnancy & lactation',
    tagline: 'Per-drug perinatal safety atlas',
    icon: Icons.pregnant_woman,
    route: Routes.perinatal,
    keywords: <String>[
      'pregnancy', 'lactation', 'breastfeeding', 'perinatal',
      'pregnant', 'teratogen', 'breast', 'milk', 'fetal',
    ],
  ),
  _ToolItem(
    label: 'STOPP / START',
    tagline: 'Geriatric deprescribing prompts',
    icon: Icons.elderly,
    route: Routes.stoppStart,
    keywords: <String>[
      'stopp', 'start', 'elderly', 'geriatric', 'deprescribe',
      'deprescribing', 'older', 'fall', 'anticholinergic',
    ],
  ),
  _ToolItem(
    label: 'QTc stacker',
    tagline: 'Aggregate QTc risk',
    icon: Icons.monitor_heart_outlined,
    route: Routes.qtcStacker,
    keywords: <String>['qtc', 'qt', 'torsade'],
  ),
  _ToolItem(
    label: 'Calculators',
    tagline: 'CrCl · QTc · BMI',
    icon: Icons.calculate_outlined,
    route: Routes.calculators,
    keywords: <String>[
      'calculator',
      'crcl',
      'cockcroft',
      'creatinine',
      'bmi',
      'qtc'
    ],
  ),
  _ToolItem(
    label: 'Dose equivalency',
    tagline: 'Antipsychotic / antidepressant equivalents',
    icon: Icons.swap_horiz_rounded,
    route: Routes.equivalency,
    keywords: <String>['equivalent', 'equivalence', 'chlorpromazine'],
  ),
  _ToolItem(
    label: 'Adverse-effect lookup',
    tagline: 'EPS · metabolic · prolactin · sexual',
    icon: Icons.health_and_safety_outlined,
    route: Routes.adverseEffects,
    keywords: <String>['adverse', 'side effect', 'ae'],
  ),
  _ToolItem(
    label: 'Halal & Ramadan',
    tagline: 'Fasting-window dosing guidance',
    icon: Icons.dark_mode_outlined,
    route: Routes.ramadan,
    keywords: <String>['ramadan', 'fasting', 'halal', 'suhoor', 'iftar'],
  ),
  _ToolItem(
    label: 'Clozapine',
    tagline: 'Titration · FBC · myocarditis · constipation',
    icon: Icons.local_hospital_outlined,
    route: Routes.clozapine,
    keywords: <String>['clozapine', 'fbc', 'anc', 'myocarditis'],
  ),
  _ToolItem(
    label: 'Depot LAI',
    tagline: 'Long-acting injectable protocols',
    icon: Icons.vaccines_outlined,
    route: Routes.depotIndex,
    keywords: <String>['depot', 'lai', 'paliperidone', 'aripiprazole'],
  ),
  _ToolItem(
    label: 'Mood stabilisers',
    tagline: 'Lithium · valproate · lamotrigine · carbamazepine',
    icon: Icons.balance_outlined,
    route: Routes.moodStabilizers,
    keywords: <String>['lithium', 'valproate', 'lamotrigine', 'mood'],
  ),
  _ToolItem(
    label: 'Lithium tapering',
    tagline: 'Slow stop protocol',
    icon: Icons.timelapse_outlined,
    route: Routes.lithiumTapering,
    keywords: <String>['lithium', 'taper', 'stop'],
  ),
  _ToolItem(
    label: 'Glossary',
    tagline: 'Clinical-term lookup',
    icon: Icons.menu_book_outlined,
    route: Routes.glossary,
    keywords: <String>['glossary', 'definition'],
  ),
  _ToolItem(
    label: 'Errata',
    tagline: 'Content corrections log',
    icon: Icons.fact_check_outlined,
    route: Routes.errata,
    keywords: <String>['errata', 'correction'],
  ),
  _ToolItem(
    label: 'History',
    tagline: 'Saved cases',
    icon: Icons.history,
    route: Routes.history,
    keywords: <String>['history', 'saved'],
  ),
];

List<_ToolItem> _searchTools(String q) {
  final hits = <_ToolItem>[];
  for (final t in _allTools) {
    if (t.label.toLowerCase().contains(q) ||
        t.tagline.toLowerCase().contains(q)) {
      hits.add(t);
      continue;
    }
    for (final k in t.keywords) {
      if (k.toLowerCase().contains(q)) {
        hits.add(t);
        break;
      }
    }
  }
  return hits;
}

// ── UI pieces ───────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: ClinicalSpace.xs,
        bottom: ClinicalSpace.sm,
      ),
      child: Row(
        children: <Widget>[
          Text(label.toUpperCase(), style: ClinicalText.eyebrow),
          const Gap.h(ClinicalSpace.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ClinicalSpace.sm,
              vertical: 1,
            ),
            decoration: BoxDecoration(
              color: ClinicalPalette.surfaceMuted,
              borderRadius: BorderRadius.circular(ClinicalRadii.pill),
            ),
            child: Text(
              '$count',
              style: ClinicalText.eyebrow.copyWith(color: ClinicalPalette.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClinicalPalette.surface,
        border: Border.all(
          color: ClinicalPalette.border.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(ClinicalRadii.tile),
      ),
      child: child,
    );
  }
}

class _DrugRow extends StatelessWidget {
  const _DrugRow({required this.drug, required this.query});
  final Drug drug;
  final String query;

  @override
  Widget build(BuildContext context) {
    final brandHit = drug.malaysianBrandNames.firstWhere(
      (b) => b.toLowerCase().contains(query),
      orElse: () => '',
    );
    return InkWell(
      onTap: () {
        unawaited(hapticsTap());
        context.pushNamed(
          Routes.drugProfile,
          pathParameters: <String, String>{'id': drug.id},
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ClinicalSpace.md + 2,
          vertical: ClinicalSpace.md,
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.medication_outlined,
                size: 18, color: ClinicalPalette.muted),
            const Gap.h(ClinicalSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    drug.genericName,
                    style: ClinicalText.body.copyWith(
                      color: ClinicalPalette.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    brandHit.isNotEmpty
                        ? '${drug.drugClass} · $brandHit'
                        : drug.drugClass,
                    style: ClinicalText.caption,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: ClinicalPalette.muted),
          ],
        ),
      ),
    );
  }
}

class _TermRow extends StatelessWidget {
  const _TermRow({required this.entry});
  final GlossaryEntry entry;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        unawaited(hapticsTap());
        context.pushNamed(Routes.glossary);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ClinicalSpace.md + 2,
          vertical: ClinicalSpace.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.menu_book_outlined,
                size: 18, color: ClinicalPalette.muted),
            const Gap.h(ClinicalSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    entry.term.toUpperCase(),
                    style: ClinicalText.body.copyWith(
                      color: ClinicalPalette.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap.v(ClinicalSpace.xs - 1),
                  Text(
                    entry.definition,
                    style: ClinicalText.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({required this.item});
  final _ToolItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        unawaited(hapticsTap());
        context.pushNamed(item.route);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ClinicalSpace.md + 2,
          vertical: ClinicalSpace.md,
        ),
        child: Row(
          children: <Widget>[
            Icon(item.icon, size: 18, color: ClinicalPalette.accent),
            const Gap.h(ClinicalSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.label,
                    style: ClinicalText.body.copyWith(
                      color: ClinicalPalette.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(item.tagline, style: ClinicalText.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: ClinicalPalette.muted),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    final hints = <String>[
      'Try a drug name: sertraline, clozapine, lithium',
      'Or a Malaysian brand: Zoloft, Clopine, Lithicarb',
      'Or a tool: regimen, QTc, calculator, fasting',
      'Or a clinical term: akathisia, NMS, hyponatraemia',
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpace.lg + 4,
        ClinicalSpace.md,
        ClinicalSpace.lg + 4,
        ClinicalSpace.xl,
      ),
      children: <Widget>[
        const Text('Search anything', style: ClinicalText.title),
        const Gap.v(ClinicalSpace.sm),
        const Text(
          'One box for drugs, glossary terms, and every tool.',
          style: ClinicalText.caption,
        ),
        const Gap.v(ClinicalSpace.lg),
        for (final h in hints) ...<Widget>[
          Container(
            margin: const EdgeInsets.only(bottom: ClinicalSpace.sm),
            padding: const EdgeInsets.all(ClinicalSpace.md),
            decoration: BoxDecoration(
              color: ClinicalPalette.surface,
              border: Border.all(
                color: ClinicalPalette.border.withValues(alpha: 0.7),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(ClinicalRadii.chip),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.lightbulb_outline,
                    size: 16, color: ClinicalPalette.muted),
                const Gap.h(ClinicalSpace.sm),
                Expanded(child: Text(h, style: ClinicalText.caption)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ClinicalSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.search_off,
                size: 36, color: ClinicalPalette.muted),
            const Gap.v(ClinicalSpace.md),
            Text(
              'No matches',
              style: ClinicalText.subtitle.copyWith(color: ClinicalPalette.text),
            ),
            const Gap.v(ClinicalSpace.xs),
            const Text(
              'Try a different spelling or shorter prefix.',
              style: ClinicalText.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
