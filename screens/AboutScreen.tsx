import Constants from 'expo-constants';
import { Linking, Pressable, Text, View } from 'react-native';
import { ScreenContainer } from '../components/ScreenContainer';
import { listErrata } from '../engine/errata';
import { listDrugs, listRules } from '../engine/switchingEngine';

/**
 * Hand-tracked build facts. Bump alongside changelog entries when the
 * underlying numbers change. The version + errata count are pulled
 * dynamically (expo-constants + errata registry) so they don't live here.
 */
const BUILD_FACTS = {
  tests: '302 / 302',
  mcpTools: 18,
} as const;

const REFERENCES = [
  {
    key: 'maudsley15',
    label: 'The Maudsley Prescribing Guidelines in Psychiatry, 15th Edition',
    detail: 'Taylor D, Barnes TRE, Young AH. Wiley-Blackwell, 2021.',
  },
  {
    key: 'leucht2016',
    label: 'Leucht et al. — Antipsychotic drug treatment: a systematic multi-level meta-analysis',
    detail: 'Schizophrenia Bulletin, 2016. Defined-daily-dose equivalence basis.',
  },
  {
    key: 'bap2020',
    label: 'BAP 2020 — Evidence-based guidelines for the pharmacological treatment of psychosis',
    detail:
      'Barnes TRE & the BAPGuidelines Working Group. Journal of Psychopharmacology, 2020.',
  },
  {
    key: 'nice2022',
    label: 'NICE CG185 — Bipolar disorder: assessment and management',
    detail: 'National Institute for Health and Care Excellence, 2014 (updated 2020).',
  },
  {
    key: 'cpg_moh2009',
    label: 'Malaysian CPG — Management of Schizophrenia',
    detail: 'Ministry of Health Malaysia, 2009. 2nd edition.',
  },
  {
    key: 'invega_sustenna_pi',
    label: 'Invega Sustenna (paliperidone palmitate) — FDA Prescribing Information',
    detail: 'Janssen Pharmaceuticals, Inc. DailyMed, updated February 2025.',
  },
  {
    key: 'abilify_maintena_pi',
    label: 'Abilify Maintena (aripiprazole) — FDA Prescribing Information',
    detail: 'Otsuka America Pharmaceutical, Inc. DailyMed, 2025.',
  },
  {
    key: 'clozapine_maudsley',
    label: 'Maudsley 15th — Clozapine initiation & monitoring protocols',
    detail: 'Chapter 1. Tables by sex × smoking status (CYP1A2 stratification).',
  },
];

export function AboutScreen() {
  const rules = listRules();
  const drugs = listDrugs();

  const adRules = rules.filter(
    (r) =>
      r.fromDrugId.match(/escitalopram|sertraline|venlafaxine|mirtazapine|agomelatine|vortioxetine|desvenlafaxine/) ||
      r.toDrugId.match(/escitalopram|sertraline|venlafaxine|mirtazapine|agomelatine|vortioxetine|desvenlafaxine/),
  ).length;

  const msRules = rules.filter(
    (r) =>
      r.fromDrugId.match(/lithium|valproate|lamotrigine|carbamazepine/) ||
      r.toDrugId.match(/lithium|valproate|lamotrigine|carbamazepine/),
  ).length;

  const apRules = rules.length - adRules - msRules;

  return (
    <ScreenContainer>
      <Text className="text-text text-2xl font-semibold mb-2">
        About PsychSwitch
      </Text>
      <Text className="text-muted text-base mb-6 leading-6">
        Clinical decision-support for cross-titration of psychotropic
        medications. Built for medical officers and psychiatrists in Malaysia
        and the ASEAN region.
      </Text>

      {/* ── Clinical author ─────────────────────────────────────────── */}
      <View className="bg-surface border border-border rounded-2xl px-4 py-4 mb-4">
        <Text className="text-muted text-xs uppercase tracking-wider mb-2">
          Clinical author
        </Text>
        <Text className="text-text text-base font-semibold">
          Dr. Rashid Razak
        </Text>
        <Text className="text-muted text-sm mt-0.5">Consultant Psychiatrist · Malaysia</Text>
        <Text className="text-muted text-xs mt-2 leading-4">
          All clinical content (switching rules, drug profiles, depot
          protocols, clozapine titration schedules) is authored, reviewed,
          and signed off by the clinical author. PENDING_CLINICAL_REVIEW
          markers indicate content awaiting final sign-off.
        </Text>
      </View>

      {/* ── Content statistics ──────────────────────────────────────── */}
      <View className="bg-surface border border-border rounded-2xl px-4 py-4 mb-4">
        <Text className="text-muted text-xs uppercase tracking-wider mb-3">
          Content coverage
        </Text>
        <View className="flex-row justify-between mb-2">
          <Text className="text-muted text-sm">Total switching rules</Text>
          <Text className="text-text text-sm font-semibold">{rules.length}</Text>
        </View>
        <View className="flex-row justify-between mb-2">
          <Text className="text-muted text-sm">Antipsychotic rules</Text>
          <Text className="text-text text-sm font-semibold">{apRules}</Text>
        </View>
        <View className="flex-row justify-between mb-2">
          <Text className="text-muted text-sm">Antidepressant rules</Text>
          <Text className="text-text text-sm font-semibold">{adRules}</Text>
        </View>
        <View className="flex-row justify-between mb-2">
          <Text className="text-muted text-sm">Mood stabilizer rules</Text>
          <Text className="text-text text-sm font-semibold">{msRules}</Text>
        </View>
        <View className="border-t border-border mt-1 pt-2 flex-row justify-between">
          <Text className="text-muted text-sm">Drug profiles</Text>
          <Text className="text-text text-sm font-semibold">{drugs.length}</Text>
        </View>
        <Text className="text-muted text-micro leading-4 mt-2">
          Mood-stabilizer and LAI depot rules are registered in the engine but
          gated from the cross-titration picker pending more clinical research.
        </Text>
      </View>

      {/* ── Primary references ──────────────────────────────────────── */}
      <View className="bg-surface border border-border rounded-2xl px-4 py-4 mb-4">
        <Text className="text-muted text-xs uppercase tracking-wider mb-3">
          Primary references
        </Text>
        {REFERENCES.map((ref, i) => (
          <View
            key={ref.key}
            className={i < REFERENCES.length - 1 ? 'mb-3 pb-3 border-b border-border' : ''}
          >
            <Text className="text-text text-sm font-semibold leading-5 mb-0.5">
              {ref.label}
            </Text>
            <Text className="text-muted text-xs leading-4">{ref.detail}</Text>
          </View>
        ))}
      </View>

      {/* ── Disclaimer ──────────────────────────────────────────────── */}
      <View className="bg-surface border border-border rounded-2xl px-4 py-4 mb-4">
        <Text className="text-muted text-xs uppercase tracking-wider mb-2">
          Disclaimer
        </Text>
        <Text className="text-text text-sm leading-5">
          This tool is decision support and does not replace clinical
          judgment. Final prescribing decisions rest with the treating
          clinician. Always cross-check against primary references (Maudsley,
          BAP, NICE, local CPG) and the patient's individual circumstances.
          The authors accept no liability for clinical decisions made using
          this tool.
        </Text>
      </View>

      {/* ── Contact ─────────────────────────────────────────────────── */}
      <View className="bg-surface border border-border rounded-2xl px-4 py-4 mb-4">
        <Text className="text-muted text-xs uppercase tracking-wider mb-2">
          Contact
        </Text>
        <Pressable
          onPress={() => Linking.openURL('mailto:errata@psychswitch.health')}
          className="active:opacity-70 mb-2"
        >
          <Text className="text-text text-sm font-medium">Report an errata</Text>
          <Text className="text-accent text-xs">errata@psychswitch.health</Text>
        </Pressable>
        <Pressable
          onPress={() => Linking.openURL('mailto:privacy@psychswitch.health')}
          className="active:opacity-70 mb-2"
        >
          <Text className="text-text text-sm font-medium">Privacy questions</Text>
          <Text className="text-accent text-xs">privacy@psychswitch.health</Text>
        </Pressable>
        <Pressable
          onPress={() => Linking.openURL('https://github.com/mrashidrazak-oss/psych-switch')}
          className="active:opacity-70"
        >
          <Text className="text-text text-sm font-medium">Source + issues</Text>
          <Text className="text-accent text-xs">github.com/mrashidrazak-oss/psych-switch</Text>
        </Pressable>
      </View>

      {/* ── Licensing ───────────────────────────────────────────────── */}
      <View className="bg-surface border border-border rounded-2xl px-4 py-4 mb-4">
        <Text className="text-muted text-xs uppercase tracking-wider mb-2">
          Licensing
        </Text>
        <View className="flex-row justify-between mb-1">
          <Text className="text-muted text-sm">App source</Text>
          <Text className="text-text text-sm font-mono">MIT</Text>
        </View>
        <View className="flex-row justify-between">
          <Text className="text-muted text-sm">Clinical content</Text>
          <Text className="text-text text-sm font-mono">CC BY-NC-SA 4.0</Text>
        </View>
        <Text className="text-muted text-micro leading-4 mt-2">
          Anyone can fork, deploy, or contribute. Commercial redistribution of clinical content requires permission.
        </Text>
      </View>

      {/* ── Build info ────────────────────────────────────────────────
          Pulled live so this never goes stale again. The version reads
          from expo-constants (which reads app.json at build time). The
          errata count is the registry length. The test + MCP-tool
          counts are static-but-tracked here as `BUILD_FACTS` — single
          source of truth, easy to bump alongside changelog entries. */}
      <View className="bg-surface border border-border rounded-2xl px-4 py-3">
        <Text className="text-muted text-xs uppercase tracking-wider mb-1">
          Build
        </Text>
        <View className="flex-row justify-between mb-1">
          <Text className="text-muted text-xs">Version</Text>
          <Text className="text-text text-xs font-mono">
            {Constants.expoConfig?.version ?? 'dev'}
          </Text>
        </View>
        <View className="flex-row justify-between mb-1">
          <Text className="text-muted text-xs">Engine tests</Text>
          <Text className="text-text text-xs font-mono">{BUILD_FACTS.tests}</Text>
        </View>
        <View className="flex-row justify-between mb-1">
          <Text className="text-muted text-xs">MCP tools</Text>
          <Text className="text-text text-xs font-mono">{BUILD_FACTS.mcpTools}</Text>
        </View>
        <View className="flex-row justify-between">
          <Text className="text-muted text-xs">Errata recorded</Text>
          <Text className="text-text text-xs font-mono">{listErrata().length}</Text>
        </View>
      </View>
    </ScreenContainer>
  );
}
