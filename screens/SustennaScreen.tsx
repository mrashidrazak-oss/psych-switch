// Invega Sustenna (paliperidone palmitate PP1M) initiation and dosing guide.
// Source: FDA Prescribing Information, Janssen Pharmaceuticals, DailyMed Feb 2025.
// Doses in mg equivalents (mg eq) of paliperidone — standard ASEAN/Malaysian convention.
import { useState } from 'react';
import { Pressable, ScrollView, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Banner } from '../components/Banner';
import { Chip } from '../components/Chip';
import { SUSTENNA } from '../engine/depotLai';
import type { MissedDoseScenario } from '../engine/depotLai';

type Tab = 'initiation' | 'maintenance' | 'missed' | 'renal';

const TABS: { key: Tab; label: string }[] = [
  { key: 'initiation', label: 'Initiation' },
  { key: 'maintenance', label: 'Maintenance' },
  { key: 'missed', label: 'Missed dose' },
  { key: 'renal', label: 'Renal' },
];

export function SustennaScreen() {
  const [tab, setTab] = useState<Tab>('initiation');
  const insets = useSafeAreaInsets();

  return (
    <View className="flex-1 bg-bg">
      {/* Header */}
      <View className="px-5 pt-3 pb-3 border-b border-border">
        <Text className="text-text text-xl font-bold">{SUSTENNA.brandName}</Text>
        <Text className="text-muted text-xs mt-0.5">{SUSTENNA.genericName}</Text>
        <Text className="text-muted text-xs">{SUSTENNA.indication}</Text>
      </View>

      {/* Tabs */}
      <View className="flex-row px-4 pt-3 pb-0 gap-1.5">
        {TABS.map((t) => (
          <Pressable
            key={t.key}
            onPress={() => setTab(t.key)}
            className={`flex-1 py-2 rounded-xl active:opacity-70 ${
              tab === t.key ? 'bg-accent' : 'bg-surface border border-border'
            }`}
          >
            <Text
              className={`text-center text-micro font-semibold ${
                tab === t.key ? 'text-white' : 'text-muted'
              }`}
            >
              {t.label}
            </Text>
          </Pressable>
        ))}
      </View>

      {/* Content */}
      <ScrollView
        className="flex-1"
        contentContainerStyle={{
          padding: 20,
          paddingBottom: Math.max(insets.bottom + 16, 32),
        }}
      >
        {tab === 'initiation' && <InitiationTab />}
        {tab === 'maintenance' && <MaintenanceTab />}
        {tab === 'missed' && <MissedDoseTab />}
        {tab === 'renal' && <RenalTab />}
      </ScrollView>
    </View>
  );
}

// ── Initiation tab ────────────────────────────────────────────────────────────

function InitiationTab() {
  return (
    <>
      {/* Oral pre-treatment */}
      <SectionCard title="Before first injection">
        <Text className="text-text text-sm leading-5">{SUSTENNA.oralPreTreatment}</Text>
      </SectionCard>

      {/* Loading steps */}
      <Text className="text-muted text-eyebrow uppercase tracking-widest mb-2">
        Loading &amp; initiation schedule
      </Text>
      <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
        {SUSTENNA.initiationSteps.map((step, i) => {
          const isLast = i === SUSTENNA.initiationSteps.length - 1;
          const isLoading = i < 2;
          return (
            <View
              key={step.label}
              className={`px-4 py-3.5 ${!isLast ? 'border-b border-border' : ''}`}
            >
              <View className="flex-row items-start justify-between mb-1">
                <Text className="text-text text-sm font-bold">{step.label}</Text>
                <Chip
                  tone={isLoading ? 'info' : 'success'}
                  size="md"
                  label={`${step.doseMgEq} mg eq`}
                />
              </View>
              <Text className="text-warning text-xs font-semibold mb-1">
                📍 {step.site}
              </Text>
              {step.notes ? (
                <Text className="text-muted text-xs leading-4">{step.notes}</Text>
              ) : null}
            </View>
          );
        })}
      </View>

      {/* Needle guide */}
      <SectionCard title="Needle selection">
        <View className="mb-2">
          {SUSTENNA.needleGuide.map((ng, i) => (
            <View
              key={i}
              className={`flex-row items-start py-2 ${i < SUSTENNA.needleGuide.length - 1 ? 'border-b border-border' : ''}`}
            >
              <View className="flex-1">
                <Text className="text-text text-xs font-semibold">{ng.site}</Text>
                <Text className="text-muted text-xs">{ng.habitus}</Text>
              </View>
              <Text className="text-text text-xs font-mono text-right">
                {ng.gauge} · {ng.lengthInch}
              </Text>
            </View>
          ))}
        </View>
        <Text className="text-muted text-xs leading-4 mt-1">{SUSTENNA.injectionSiteNote}</Text>
      </SectionCard>

      {/* Available strengths */}
      <SectionCard title="Available strengths">
        <View className="flex-row flex-wrap gap-2">
          {SUSTENNA.availableStrengths.map((s) => (
            <View key={s.mgEq} className="bg-bg border border-border rounded-xl px-3 py-2 items-center">
              <Text className="text-text text-sm font-bold">{s.mgEq} mg eq</Text>
              <Text className="text-muted text-eyebrow">{s.volumeMl} mL</Text>
              <Text className="text-muted/60 text-[9px]">({s.mgPP} mg PP)</Text>
            </View>
          ))}
        </View>
      </SectionCard>

      <WarningsCard />
    </>
  );
}

// ── Maintenance tab ───────────────────────────────────────────────────────────

function MaintenanceTab() {
  const r = SUSTENNA.maintenanceDoseRange;
  return (
    <>
      {/* Dose summary */}
      <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
        <View className="flex-row bg-border/30 px-4 py-2">
          <Text className="text-muted text-eyebrow uppercase tracking-widest">Maintenance dosing</Text>
        </View>
        <View className="px-4 py-3 border-b border-border">
          <View className="flex-row justify-between items-center">
            <Text className="text-muted text-sm">Recommended dose</Text>
            <Text className="text-to text-base font-bold">{r.recommended} mg eq / month</Text>
          </View>
        </View>
        <View className="px-4 py-3 border-b border-border">
          <View className="flex-row justify-between items-center">
            <Text className="text-muted text-sm">Dose range</Text>
            <Text className="text-text text-sm font-semibold">{r.min}–{r.max} mg eq / month</Text>
          </View>
        </View>
        <View className="px-4 py-3">
          <View className="flex-row justify-between items-center">
            <Text className="text-muted text-sm">Administration window</Text>
            <Text className="text-text text-sm font-semibold">{SUSTENNA.maintenanceWindow}</Text>
          </View>
        </View>
      </View>

      {/* Injection interval */}
      <SectionCard title="Injection schedule">
        <Text className="text-text text-sm leading-5">
          Administer once monthly (every 28 days) with a ±7 day window. Either the deltoid or gluteal muscle may be used from the first maintenance dose onward.
          {'\n\n'}
          Schizophrenia — recommended 75 mg eq monthly (range 25–150 mg eq).{'\n'}
          Schizoaffective disorder — range 75–150 mg eq monthly.
        </Text>
      </SectionCard>

      {/* Needle guide */}
      <SectionCard title="Needle selection">
        {SUSTENNA.needleGuide.map((ng, i) => (
          <View
            key={i}
            className={`flex-row items-center py-2 ${i < SUSTENNA.needleGuide.length - 1 ? 'border-b border-border' : ''}`}
          >
            <View className="flex-1">
              <Text className="text-text text-xs font-semibold">{ng.site}</Text>
              <Text className="text-muted text-xs">{ng.habitus}</Text>
            </View>
            <Text className="text-text text-xs font-mono">{ng.gauge} · {ng.lengthInch}</Text>
          </View>
        ))}
      </SectionCard>

      <CitationCard />
    </>
  );
}

// ── Missed dose tab ───────────────────────────────────────────────────────────

function MissedDoseTab() {
  return (
    <>
      <Banner
        tone="warning"
        eyebrow="Timing matters"
        body="The re-initiation protocol depends on exactly how long since the last injection. Different windows apply to initiation doses vs. maintenance doses."
        className="mb-4"
      />

      <Text className="text-muted text-eyebrow uppercase tracking-widest mb-2">
        If the Day 8 (2nd) initiation dose is missed
      </Text>
      <MissedDoseList scenarios={[...SUSTENNA.missedDoseInitiation]} />

      <Text className="text-muted text-eyebrow uppercase tracking-widest mb-2 mt-4">
        If a maintenance dose is missed
      </Text>
      <MissedDoseList scenarios={[...SUSTENNA.missedDoseMaintenance]} />

      <CitationCard />
    </>
  );
}

// ── Renal tab ─────────────────────────────────────────────────────────────────

function RenalTab() {
  return (
    <>
      <Banner
        tone="danger"
        eyebrow="Contraindicated in moderate/severe renal impairment"
        body="Invega Sustenna is NOT recommended when CrCl < 50 mL/min. Paliperidone is renally excreted; impaired clearance causes accumulation. Check CrCl before every initiation."
        className="mb-4"
      />

      {/* Renal table */}
      <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
        <View className="flex-row bg-border/30 px-3 py-2">
          <Text className="text-muted text-eyebrow uppercase tracking-widest flex-1">Category</Text>
          <Text className="text-muted text-eyebrow uppercase tracking-widest w-16 text-center">Day 1</Text>
          <Text className="text-muted text-eyebrow uppercase tracking-widest w-16 text-center">Day 8</Text>
          <Text className="text-muted text-eyebrow uppercase tracking-widest w-20 text-center">Maint.</Text>
        </View>
        {SUSTENNA.renalAdjustments.map((r, i) => {
          const isContra = r.maintenance === 'CONTRAINDICATED';
          const isLast = i === SUSTENNA.renalAdjustments.length - 1;
          return (
            <View
              key={r.category}
              className={`px-3 py-3 ${!isLast ? 'border-b border-border' : ''} ${isContra ? 'bg-danger/5' : ''}`}
            >
              <View className="flex-row items-start">
                <View className="flex-1 pr-2">
                  <Text className={`text-xs font-semibold ${isContra ? 'text-danger' : 'text-text'}`}>
                    {r.category}
                  </Text>
                  <Text className="text-muted text-eyebrow mt-0.5">{r.crcl}</Text>
                </View>
                {isContra ? (
                  <View className="flex-row items-center">
                    <Text className="text-danger text-xs font-bold">CONTRA-INDICATED</Text>
                  </View>
                ) : (
                  <>
                    <Text className="text-text text-xs w-16 text-center font-semibold">{r.day1}</Text>
                    <Text className="text-text text-xs w-16 text-center font-semibold">{r.day8}</Text>
                    <Text className="text-text text-xs w-20 text-center font-semibold">{r.maintenance}</Text>
                  </>
                )}
              </View>
            </View>
          );
        })}
      </View>

      <CitationCard />
    </>
  );
}

// ── Shared helper components ──────────────────────────────────────────────────

function SectionCard({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <View className="mb-4">
      <Text className="text-muted text-eyebrow uppercase tracking-widest mb-2">{title}</Text>
      <View className="bg-surface border border-border rounded-2xl px-4 py-3">
        {children}
      </View>
    </View>
  );
}

function MissedDoseList({ scenarios }: { scenarios: MissedDoseScenario[] }) {
  return (
    <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
      {scenarios.map((s, i) => {
        const isLast = i === scenarios.length - 1;
        const borderColor =
          s.severity === 'danger' ? 'bg-danger' : s.severity === 'warning' ? 'bg-warning' : 'bg-accent';
        return (
          <View
            key={i}
            className={`flex-row overflow-hidden ${!isLast ? 'border-b border-border' : ''}`}
          >
            <View className={`w-1.5 ${borderColor}`} />
            <View className="flex-1 px-3 py-3">
              <Text className="text-muted text-xs font-semibold mb-1">{s.condition}</Text>
              <Text className="text-text text-sm leading-5">{s.action}</Text>
            </View>
          </View>
        );
      })}
    </View>
  );
}

function WarningsCard() {
  return (
    <View className="mb-4">
      <Text className="text-muted text-eyebrow uppercase tracking-widest mb-2">Key warnings</Text>
      <View className="bg-surface border border-border rounded-2xl px-4 py-3">
        {SUSTENNA.keyWarnings.map((w, i) => (
          <View key={i} className={`flex-row ${i < SUSTENNA.keyWarnings.length - 1 ? 'mb-2 pb-2 border-b border-border' : ''}`}>
            <Text className="text-warning mr-2 text-xs">⚠</Text>
            <Text className="text-muted text-xs leading-4 flex-1">{w}</Text>
          </View>
        ))}
      </View>
    </View>
  );
}

function CitationCard() {
  return (
    <View className="bg-surface border border-border rounded-2xl px-4 py-3">
      <Text className="text-muted text-eyebrow uppercase tracking-widest mb-1">Source</Text>
      {SUSTENNA.citations.map((c, i) => (
        <Text key={i} className="text-muted text-xs leading-4 mt-0.5">
          [{i + 1}] {c}
        </Text>
      ))}
    </View>
  );
}
