// Abilify Maintena (aripiprazole monohydrate ER) initiation and dosing guide.
// Source: FDA Prescribing Information, Otsuka America Pharmaceutical, DailyMed 2025.
import { useState } from 'react';
import { Pressable, ScrollView, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Banner } from '../components/Banner';
import { MAINTENA } from '../engine/depotLai';
import type { DrugInteractionAdjustment, MissedDoseScenario } from '../engine/depotLai';

type Tab = 'initiation' | 'maintenance' | 'missed' | 'interactions';

const TABS: { key: Tab; label: string }[] = [
  { key: 'initiation', label: 'Initiation' },
  { key: 'maintenance', label: 'Maintenance' },
  { key: 'missed', label: 'Missed dose' },
  { key: 'interactions', label: 'Drug int.' },
];

export function MaintenaScreen() {
  const [tab, setTab] = useState<Tab>('initiation');
  const insets = useSafeAreaInsets();

  return (
    <View className="flex-1 bg-bg">
      {/* Header */}
      <View className="px-5 pt-3 pb-3 border-b border-border">
        <Text className="text-text text-xl font-bold">{MAINTENA.brandName}</Text>
        <Text className="text-muted text-xs mt-0.5">{MAINTENA.genericName}</Text>
        <Text className="text-muted text-xs">{MAINTENA.indication}</Text>
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
        {tab === 'interactions' && <InteractionsTab />}
      </ScrollView>
    </View>
  );
}

// ── Initiation tab ────────────────────────────────────────────────────────────

function InitiationTab() {
  const [method, setMethod] = useState<'fourteenDay' | 'oneDay'>('fourteenDay');
  const selected = MAINTENA.initiationMethods[method];

  return (
    <>
      {/* Oral pre-treatment */}
      <SectionCard title="Before first injection">
        <Text className="text-text text-sm leading-5">{MAINTENA.oralPreTreatment}</Text>
      </SectionCard>

      {/* Method picker */}
      <Text className="text-muted text-eyebrow uppercase tracking-widest mb-2">
        Choose initiation method
      </Text>
      <View className="flex-row bg-surface border border-border rounded-2xl p-1 mb-4 gap-1">
        <Pressable
          onPress={() => setMethod('fourteenDay')}
          className={`flex-1 py-2.5 rounded-xl active:opacity-70 ${method === 'fourteenDay' ? 'bg-accent' : ''}`}
        >
          <Text className={`text-center text-xs font-semibold ${method === 'fourteenDay' ? 'text-white' : 'text-muted'}`}>
            14-day overlap
          </Text>
          <Text className={`text-center text-eyebrow mt-0.5 ${method === 'fourteenDay' ? 'text-white/70' : 'text-muted/60'}`}>
            Standard
          </Text>
        </Pressable>
        <Pressable
          onPress={() => setMethod('oneDay')}
          className={`flex-1 py-2.5 rounded-xl active:opacity-70 ${method === 'oneDay' ? 'bg-accent' : ''}`}
        >
          <Text className={`text-center text-xs font-semibold ${method === 'oneDay' ? 'text-white' : 'text-muted'}`}>
            1-day dual inj.
          </Text>
          <Text className={`text-center text-eyebrow mt-0.5 ${method === 'oneDay' ? 'text-white/70' : 'text-muted/60'}`}>
            Faster loading
          </Text>
        </Pressable>
      </View>

      {/* Selected method detail */}
      <View className="bg-surface border border-accent/40 rounded-2xl px-4 py-4 mb-4">
        <Text className="text-accent text-xs uppercase tracking-widest font-bold mb-3">
          {selected.label}
        </Text>

        <View className="mb-3 pb-3 border-b border-border">
          <Text className="text-muted text-eyebrow uppercase tracking-widest mb-1">Injection</Text>
          <Text className="text-text text-sm font-semibold">{selected.injection}</Text>
        </View>

        <View className="mb-3 pb-3 border-b border-border">
          <Text className="text-muted text-eyebrow uppercase tracking-widest mb-1">
            Oral aripiprazole
          </Text>
          <Text className="text-text text-sm font-semibold">{selected.oral}</Text>
        </View>

        <View>
          <Text className="text-muted text-eyebrow uppercase tracking-widest mb-1">Notes</Text>
          <Text className="text-muted text-sm leading-5">{selected.notes}</Text>
        </View>
      </View>

      {/* Needle guide */}
      <SectionCard title="Needle selection">
        {MAINTENA.needleGuide.map((ng, i) => (
          <View
            key={i}
            className={`flex-row items-center py-2 ${i < MAINTENA.needleGuide.length - 1 ? 'border-b border-border' : ''}`}
          >
            <View className="flex-1">
              <Text className="text-text text-xs font-semibold">{ng.site}</Text>
              <Text className="text-muted text-xs">{ng.habitus}</Text>
            </View>
            <Text className="text-text text-xs font-mono">{ng.gauge} · {ng.lengthInch}</Text>
          </View>
        ))}
        <Text className="text-muted text-xs leading-4 mt-2">{MAINTENA.injectionSiteNote}</Text>
      </SectionCard>

      {/* Available strengths */}
      <SectionCard title="Available strengths">
        <View className="flex-row gap-3">
          {MAINTENA.availableStrengths.map((s) => (
            <View key={s.mgAripiprazole} className="flex-1 bg-bg border border-border rounded-xl px-3 py-3 items-center">
              <Text className="text-text text-xl font-bold">{s.mgAripiprazole} mg</Text>
              <Text className="text-muted text-eyebrow mt-0.5 text-center leading-3">
                {s.formulation}
              </Text>
            </View>
          ))}
        </View>
      </SectionCard>

      {/* PK notes */}
      <SectionCard title="Pharmacokinetics">
        {MAINTENA.pkNotes.map((note, i) => (
          <Text key={i} className={`text-muted text-xs leading-4 ${i > 0 ? 'mt-1.5' : ''}`}>
            • {note}
          </Text>
        ))}
      </SectionCard>

      <WarningsCard />
    </>
  );
}

// ── Maintenance tab ───────────────────────────────────────────────────────────

function MaintenanceTab() {
  const r = MAINTENA.maintenanceDoseRange;
  return (
    <>
      <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
        <View className="flex-row bg-border/30 px-4 py-2">
          <Text className="text-muted text-eyebrow uppercase tracking-widest">Maintenance dosing</Text>
        </View>
        <View className="px-4 py-3 border-b border-border">
          <View className="flex-row justify-between items-center">
            <Text className="text-muted text-sm">Standard dose</Text>
            <Text className="text-to text-base font-bold">{r.recommended} mg / month</Text>
          </View>
        </View>
        <View className="px-4 py-3 border-b border-border">
          <View className="flex-row justify-between items-center">
            <Text className="text-muted text-sm">Reduced dose</Text>
            <Text className="text-text text-sm font-semibold">{r.min} mg / month</Text>
          </View>
          <Text className="text-muted text-xs mt-0.5">
            If ADRs, CYP2D6 poor metaboliser, or strong inhibitors
          </Text>
        </View>
        <View className="px-4 py-3">
          <View className="flex-row justify-between items-center">
            <Text className="text-muted text-sm">Minimum interval</Text>
            <Text className="text-text text-sm font-semibold">26 days</Text>
          </View>
        </View>
      </View>

      <SectionCard title="Renal / hepatic">
        <Text className="text-text text-sm leading-5">
          {MAINTENA.renalNote}
          {'\n\n'}
          {MAINTENA.hepaticNote}
        </Text>
      </SectionCard>

      <SectionCard title="Needle selection">
        {MAINTENA.needleGuide.map((ng, i) => (
          <View
            key={i}
            className={`flex-row items-center py-2 ${i < MAINTENA.needleGuide.length - 1 ? 'border-b border-border' : ''}`}
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
        eyebrow="Different rules for early vs. established doses"
        body="The restart threshold is stricter for the 2nd and 3rd injections (≥ 5 weeks) than for the 4th dose onward (≥ 6 weeks)."
        className="mb-4"
      />

      <Text className="text-muted text-eyebrow uppercase tracking-widest mb-2">
        2nd or 3rd injection missed
      </Text>
      <MissedDoseList scenarios={[...MAINTENA.missedDoseSecondThird]} />

      <Text className="text-muted text-eyebrow uppercase tracking-widest mb-2 mt-2">
        4th injection onward missed
      </Text>
      <MissedDoseList scenarios={[...MAINTENA.missedDoseFourthOnward]} />

      <View className="bg-surface border border-border rounded-2xl px-4 py-3">
        <Text className="text-muted text-eyebrow uppercase tracking-widest mb-1">
          After restart
        </Text>
        <Text className="text-text text-sm leading-5">
          Use either the 14-day oral overlap method or the 1-day dual-injection
          method. See the Initiation tab for full details of each protocol.
        </Text>
      </View>
    </>
  );
}

// ── Drug interactions tab ─────────────────────────────────────────────────────

function InteractionsTab() {
  return (
    <>
      <Banner
        tone="danger"
        eyebrow="CYP3A4 inducers — avoid > 14 days"
        body="Carbamazepine, rifampicin, and other strong CYP3A4 inducers reduce aripiprazole exposure so substantially that there is no adequate dose alternative. Avoid co-prescription for more than 14 days."
        className="mb-4"
      />

      <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
        {MAINTENA.drugInteractions.map((d: DrugInteractionAdjustment, i) => {
          const isLast = i === MAINTENA.drugInteractions.length - 1;
          const barColor =
            d.severity === 'danger' ? 'bg-danger' : d.severity === 'warning' ? 'bg-warning' : 'bg-accent';
          return (
            <View
              key={i}
              className={`flex-row overflow-hidden ${!isLast ? 'border-b border-border' : ''}`}
            >
              <View className={`w-1.5 ${barColor}`} />
              <View className="flex-1 px-3 py-3">
                <Text className="text-muted text-xs font-semibold mb-1">{d.situation}</Text>
                <Text className={`text-sm leading-5 ${d.severity === 'danger' ? 'text-danger font-semibold' : 'text-text'}`}>
                  {d.action}
                </Text>
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
        const barColor =
          s.severity === 'danger' ? 'bg-danger' : s.severity === 'warning' ? 'bg-warning' : 'bg-accent';
        return (
          <View
            key={i}
            className={`flex-row overflow-hidden ${!isLast ? 'border-b border-border' : ''}`}
          >
            <View className={`w-1.5 ${barColor}`} />
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
        {MAINTENA.keyWarnings.map((w, i) => (
          <View
            key={i}
            className={`flex-row ${i < MAINTENA.keyWarnings.length - 1 ? 'mb-2 pb-2 border-b border-border' : ''}`}
          >
            <Text className="text-warning mr-2 text-xs mt-0.5">⚠</Text>
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
      {MAINTENA.citations.map((c, i) => (
        <Text key={i} className="text-muted text-xs leading-4 mt-0.5">
          [{i + 1}] {c}
        </Text>
      ))}
    </View>
  );
}
