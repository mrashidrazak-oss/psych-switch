// Invega Trinza (paliperidone palmitate PP3M) — once-every-3-months LAI.
// Source: FDA Prescribing Information, Janssen Pharmaceuticals, DailyMed 2025.
// PP3M is ONLY for patients already stable on PP1M (Invega Sustenna) for ≥ 4 months.
import { useState } from 'react';
import { Pressable, ScrollView, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Banner } from '../components/Banner';
import { TRINZA } from '../engine/depotLai';

type Tab = 'conversion' | 'maintenance' | 'missed' | 'renal';

const TABS: { key: Tab; label: string }[] = [
  { key: 'conversion',   label: 'PP1M → PP3M' },
  { key: 'maintenance',  label: 'Maintenance'  },
  { key: 'missed',       label: 'Missed dose'   },
  { key: 'renal',        label: 'Renal'         },
];

export function TrinzaScreen() {
  const [tab, setTab] = useState<Tab>('conversion');
  const insets = useSafeAreaInsets();

  return (
    <View className="flex-1 bg-bg">
      {/* Header */}
      <View className="px-5 pt-3 pb-3 border-b border-border">
        <Text className="text-text text-xl font-bold">{TRINZA.brandName}</Text>
        <Text className="text-muted text-xs mt-0.5">{TRINZA.genericName}</Text>
        <Text className="text-muted text-xs">{TRINZA.indication}</Text>
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
              className={`text-center text-eyebrow font-semibold ${
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
        {tab === 'conversion'  && <ConversionTab />}
        {tab === 'maintenance' && <MaintenanceTab />}
        {tab === 'missed'      && <MissedDoseTab />}
        {tab === 'renal'       && <RenalTab />}
      </ScrollView>
    </View>
  );
}

// ── Conversion tab (PP1M → PP3M) ──────────────────────────────────────────────

function ConversionTab() {
  return (
    <>
      {/* Eligibility banner */}
      <Banner tone="info" eyebrow="PP3M eligibility requirements" className="mb-4">
        {TRINZA.eligibilityCriteria.map((c, i) => (
          <Text key={i} className={`text-text text-sm leading-5 ${i > 0 ? 'mt-1.5' : ''}`}>
            • {c}
          </Text>
        ))}
      </Banner>

      {/* When to give first dose */}
      <SectionCard title="First PP3M dose timing">
        <Text className="text-text text-sm leading-5">{TRINZA.firstDoseTiming}</Text>
      </SectionCard>

      {/* Conversion table */}
      <Text className="text-muted text-eyebrow uppercase tracking-widest mb-2">
        PP1M → PP3M dose conversion
      </Text>
      <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
        <View className="flex-row bg-border/30 px-4 py-2">
          <Text className="text-muted text-eyebrow uppercase tracking-widest flex-1">
            Last 2 PP1M doses (same strength)
          </Text>
          <Text className="text-muted text-eyebrow uppercase tracking-widest w-28 text-right">
            First PP3M dose
          </Text>
        </View>
        {TRINZA.pp1mToTrinzaConversion.map((row, i) => {
          const isLast = i === TRINZA.pp1mToTrinzaConversion.length - 1;
          return (
            <View
              key={row.pp1mMgEq}
              className={`flex-row items-center px-4 py-3.5 ${!isLast ? 'border-b border-border' : ''}`}
            >
              <View className="flex-1 flex-row items-center">
                <View className="w-2 h-2 rounded-full bg-from mr-2" />
                <Text className="text-text text-sm font-semibold">
                  {row.pp1mMgEq} mg eq / month
                </Text>
              </View>
              <View className="flex-row items-center">
                <View className="w-2 h-2 rounded-full bg-to mr-2" />
                <Text className="text-to text-base font-bold">
                  {row.pp3mMgEq} mg eq
                </Text>
              </View>
            </View>
          );
        })}
      </View>

      {/* Available strengths */}
      <SectionCard title="Available strengths">
        <View className="flex-row flex-wrap gap-2">
          {TRINZA.availableStrengths.map((s) => (
            <View
              key={s.mgEq}
              className="bg-bg border border-border rounded-xl px-3 py-2 items-center"
            >
              <Text className="text-text text-sm font-bold">{s.mgEq} mg eq</Text>
              <Text className="text-muted text-eyebrow">{s.volumeMl} mL</Text>
              <Text className="text-muted/60 text-[9px]">({s.mgPP} mg PP)</Text>
            </View>
          ))}
        </View>
      </SectionCard>

      {/* Needle guide */}
      <SectionCard title="Needle selection (PP3M-specific)">
        {TRINZA.needleGuide.map((ng, i) => (
          <View
            key={i}
            className={`flex-row items-center py-2 ${
              i < TRINZA.needleGuide.length - 1 ? 'border-b border-border' : ''
            }`}
          >
            <View className="flex-1">
              <Text className="text-text text-xs font-semibold">{ng.site}</Text>
              <Text className="text-muted text-xs">{ng.habitus}</Text>
            </View>
            <Text className="text-text text-xs font-mono">
              {ng.gauge} · {ng.lengthInch}
            </Text>
          </View>
        ))}
        <Text className="text-muted text-xs leading-4 mt-2">{TRINZA.injectionSiteNote}</Text>
      </SectionCard>

      <WarningsCard />
    </>
  );
}

// ── Maintenance tab ───────────────────────────────────────────────────────────

function MaintenanceTab() {
  return (
    <>
      <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
        <View className="flex-row bg-border/30 px-4 py-2">
          <Text className="text-muted text-eyebrow uppercase tracking-widest">
            Maintenance dosing
          </Text>
        </View>
        <View className="px-4 py-3 border-b border-border">
          <View className="flex-row justify-between items-center">
            <Text className="text-muted text-sm">Dose range</Text>
            <Text className="text-to text-base font-bold">
              {TRINZA.maintenanceDoseRange.min}–{TRINZA.maintenanceDoseRange.max} mg eq
            </Text>
          </View>
        </View>
        <View className="px-4 py-3 border-b border-border">
          <View className="flex-row justify-between items-center">
            <Text className="text-muted text-sm">Injection interval</Text>
            <Text className="text-text text-sm font-semibold">Every 3 months</Text>
          </View>
        </View>
        <View className="px-4 py-3">
          <View className="flex-row justify-between items-center">
            <Text className="text-muted text-sm">Administration window</Text>
            <Text className="text-text text-sm font-semibold">
              {TRINZA.maintenanceWindow}
            </Text>
          </View>
        </View>
      </View>

      <SectionCard title="Pharmacokinetics">
        {TRINZA.pkNotes.map((note, i) => (
          <Text key={i} className={`text-muted text-xs leading-4 ${i > 0 ? 'mt-1.5' : ''}`}>
            • {note}
          </Text>
        ))}
      </SectionCard>

      <SectionCard title="Needle selection">
        {TRINZA.needleGuide.map((ng, i) => (
          <View
            key={i}
            className={`flex-row items-center py-2 ${
              i < TRINZA.needleGuide.length - 1 ? 'border-b border-border' : ''
            }`}
          >
            <View className="flex-1">
              <Text className="text-text text-xs font-semibold">{ng.site}</Text>
              <Text className="text-muted text-xs">{ng.habitus}</Text>
            </View>
            <Text className="text-text text-xs font-mono">
              {ng.gauge} · {ng.lengthInch}
            </Text>
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
        eyebrow="3-tier algorithm — timing is critical"
        body="The action depends on exactly how long since the last PP3M injection. Injections more than 4 months late require a PP1M bridge — do NOT give PP3M directly."
        className="mb-4"
      />

      {/* 3-tier list */}
      <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
        {TRINZA.missedDoseScenarios.map((s, i) => {
          const isLast = i === TRINZA.missedDoseScenarios.length - 1;
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

      {/* PP1M bridge table */}
      <Text className="text-muted text-eyebrow uppercase tracking-widest mb-2">
        PP1M bridge doses (4–9 month window)
      </Text>
      <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
        <View className="flex-row bg-border/30 px-4 py-2">
          <Text className="text-muted text-eyebrow uppercase tracking-widest flex-1">
            Patient was on PP3M
          </Text>
          <Text className="text-muted text-eyebrow uppercase tracking-widest w-36 text-right">
            PP1M bridge dose × 2
          </Text>
        </View>
        {TRINZA.pp1mBridgeTable.map((row, i) => {
          const isLast = i === TRINZA.pp1mBridgeTable.length - 1;
          const noteHighlighted = row.pp3mStrengthMgEq === 525;
          return (
            <View
              key={row.pp3mStrengthMgEq}
              className={`flex-row items-center px-4 py-3 ${!isLast ? 'border-b border-border' : ''}`}
            >
              <Text className="text-text text-sm font-semibold flex-1">
                {row.pp3mStrengthMgEq} mg eq
              </Text>
              <View className="items-end">
                <Text className="text-accent text-sm font-bold">
                  {row.pp1mBridgeMgEq} mg eq (Day 1 &amp; Day 8)
                </Text>
                {noteHighlighted ? (
                  <Text className="text-muted text-eyebrow mt-0.5">
                    ⚠ 100 mg eq (NOT 150) — per FDA PI
                  </Text>
                ) : null}
              </View>
            </View>
          );
        })}
      </View>

      <View className="bg-surface border border-border rounded-2xl px-4 py-3">
        <Text className="text-muted text-eyebrow uppercase tracking-widest mb-1">
          After PP1M bridge
        </Text>
        <Text className="text-text text-sm leading-5">
          After completing the bridge, re-stabilise on monthly PP1M. Ensure
          the last TWO consecutive PP1M doses are the same strength, and that
          the patient has been on PP1M for ≥ 4 months before transitioning
          back to PP3M.
        </Text>
      </View>
    </>
  );
}

// ── Renal tab ─────────────────────────────────────────────────────────────────

function RenalTab() {
  return (
    <>
      <Banner
        tone="danger"
        eyebrow="Not recommended if CrCl < 50 mL/min"
        body="Paliperidone is primarily renally cleared. PP3M carries the same renal restriction as Invega Sustenna (PP1M). Check CrCl before transitioning from PP1M to PP3M."
        className="mb-4"
      />

      <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
        {TRINZA.renalAdjustments.map((r, i) => {
          const isLast = i === TRINZA.renalAdjustments.length - 1;
          const isContra = r.crcl.includes('< 50');
          return (
            <View
              key={r.category}
              className={`px-4 py-3 ${!isLast ? 'border-b border-border' : ''} ${isContra ? 'bg-danger/5' : ''}`}
            >
              <View className="flex-row items-center mb-1">
                <Text
                  className={`text-xs font-bold flex-1 ${isContra ? 'text-danger' : 'text-text'}`}
                >
                  {r.category}
                </Text>
                <Text className="text-muted text-eyebrow">{r.crcl}</Text>
              </View>
              <Text className="text-muted text-sm leading-5">{r.notes}</Text>
            </View>
          );
        })}
      </View>

      <CitationCard />
    </>
  );
}

// ── Shared helpers ────────────────────────────────────────────────────────────

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

function WarningsCard() {
  return (
    <View className="mb-4">
      <Text className="text-muted text-eyebrow uppercase tracking-widest mb-2">Key warnings</Text>
      <View className="bg-surface border border-border rounded-2xl px-4 py-3">
        {TRINZA.keyWarnings.map((w, i) => (
          <View
            key={i}
            className={`flex-row ${
              i < TRINZA.keyWarnings.length - 1 ? 'mb-2 pb-2 border-b border-border' : ''
            }`}
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
      {TRINZA.citations.map((c, i) => (
        <Text key={i} className="text-muted text-xs leading-4 mt-0.5">
          [{i + 1}] {c}
        </Text>
      ))}
    </View>
  );
}
