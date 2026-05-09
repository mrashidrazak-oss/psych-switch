// PsychSwitch home screen — world-class layout.
//
// Visual hierarchy:
//   1. Hero — brand mark + tagline
//   2. Search bar — finds drugs, "X to Y" rules, tools, modules
//   3. Primary action — "Start a switch" with live rule count
//   4. Recents (saved cases) — only shown if any exist
//   5. Clinical modules — Clozapine (LAI depot + Mood stabilizers
//      hidden in v0.4.15 pending more clinical research; screens stay
//      registered for deep links)
//   6. Tools row (Equivalents · QTc · AE lookup · Ramadan · Patient ctx)
//   7. Footer (About · Review · Settings)
//   8. Status pill
import { useEffect, useMemo, useState } from 'react';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { Pressable, Text, TextInput, View } from 'react-native';
import { Icon, type IconName } from '../components/Icon';
import { ScreenContainer } from '../components/ScreenContainer';
import { TodayPulseCard } from '../components/TodayPulseCard';
import { useCases } from '../engine/caseManager';
import { search, type SearchHit } from '../engine/search';
import { listAllDrugs, listRules, getDrug } from '../engine/switchingEngine';
import { confirm, tap } from '../utils/haptics';
import type { RootStackParamList } from '../utils/navigation';

type Props = NativeStackScreenProps<RootStackParamList, 'Home'>;

export function HomeScreen({ navigation }: Props) {
  // Count only rules whose endpoints are actually pickable in the switch
  // module. Mood-stabilizer + LAI rules are gated out as of v0.4.15
  // pending more clinical research, so showing the unfiltered total
  // would over-promise what the user can actually do from the wizard.
  const ruleCount = useMemo(() => {
    const drugs = new Map(listAllDrugs().map((d) => [d.id, d]));
    return listRules().filter((r) => {
      const from = drugs.get(r.fromDrugId);
      const to = drugs.get(r.toDrugId);
      if (!from || !to) return false;
      if (from.category === 'mood-stabilizer' || to.category === 'mood-stabilizer') return false;
      if (from.formulation === 'lai' || to.formulation === 'lai') return false;
      return true;
    }).length;
  }, []);
  const { cases } = useCases();
  const [q, setQ] = useState('');

  const hits: SearchHit[] = useMemo(() => search(q, 8), [q]);
  const showSearch = q.trim().length >= 2;

  // Star+recent combined, top 3
  const recents = useMemo(() => {
    return [...cases]
      .sort((a, b) => {
        const fa = a.favourite ? 1 : 0;
        const fb = b.favourite ? 1 : 0;
        if (fa !== fb) return fb - fa;
        return b.updatedISO.localeCompare(a.updatedISO);
      })
      .slice(0, 3);
  }, [cases]);

  const goHit = (h: SearchHit) => {
    if (h.target.type === 'switch') {
      const fromD = getDrug(h.target.fromId);
      const toD = getDrug(h.target.toId);
      if (!fromD || !toD) return;
      navigation.navigate('Result', {
        fromDrugId: h.target.fromId,
        fromDoseMg: fromD.dosing.startingDoseMg,
        toDrugId: h.target.toId,
        toDoseMg: toD.dosing.startingDoseMg,
      });
    } else if (h.target.type === 'screen') {
      navigation.navigate(h.target.name as never);
    } else if (h.target.type === 'drug') {
      // Pre-fill the SwitchScreen by navigating with no params for now
      navigation.navigate('Switch');
    }
    setQ('');
  };

  return (
    <ScreenContainer>
      {/* ── Hero ─────────────────────────────────────────────────── */}
      <View className="flex-row items-center justify-between mb-3 mt-1">
        <View className="flex-row items-center flex-1">
          <View className="w-10 h-10 rounded-xl bg-accent/15 border border-accent/30 items-center justify-center mr-3">
            <Icon name="activity" size={20} color="#3b82f6" />
          </View>
          <View>
            <Text className="text-text text-2xl font-bold leading-tight">
              PsychSwitch
            </Text>
            <Text className="text-muted text-xs uppercase tracking-widest">
              Reviewed cross-titration
            </Text>
          </View>
        </View>
        <Pressable
          onPress={() => navigation.navigate('Settings')}
          className="p-2 active:opacity-70"
          accessibilityLabel="Settings"
        >
          <Icon name="settings" size={20} color="#8b949e" />
        </Pressable>
      </View>
      <Text className="text-muted text-sm leading-5 mb-4">
        Reviewed cross-titration schedules, depot protocols, and clozapine
        monitoring — built for the bedside.
      </Text>

      {/* ── Search bar ───────────────────────────────────────────── */}
      <View className="bg-surface border border-border rounded-2xl px-3 py-2.5 mb-3 flex-row items-center">
        <Icon name="search" size={16} color="#8b949e" />
        <TextInput
          value={q}
          onChangeText={setQ}
          placeholder='Search drugs or "olanz to arip"'
          placeholderTextColor="#6b7280"
          className="flex-1 text-text text-sm ml-2"
          returnKeyType="search"
          accessibilityLabel="Search drugs, rules, and tools"
          autoCorrect={false}
          autoCapitalize="none"
        />
        {q.length > 0 && (
          <Pressable onPress={() => setQ('')} className="p-1">
            <Icon name="check" size={14} color="#6b7280" />
          </Pressable>
        )}
      </View>

      {/* ── Search results (overlay-ish) ─────────────────────────── */}
      {showSearch && (
        <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
          {hits.length === 0 ? (
            <View className="px-4 py-4">
              <Text className="text-muted text-sm">No matches.</Text>
            </View>
          ) : (
            hits.map((h, i) => (
              <Pressable
                key={`${h.kind}-${h.title}-${i}`}
                onPress={() => goHit(h)}
                className={`flex-row items-center px-4 py-3 active:opacity-80 ${i < hits.length - 1 ? 'border-b border-border' : ''}`}
              >
                <View className="w-7 items-center mr-2">
                  <Icon name={hitIcon(h.kind)} size={14} color={hitColor(h.kind)} />
                </View>
                <View className="flex-1">
                  <Text className="text-text text-sm font-medium" numberOfLines={1}>
                    {h.title}
                  </Text>
                  {h.subtitle && (
                    <Text className="text-muted text-xs" numberOfLines={1}>
                      {h.subtitle}
                    </Text>
                  )}
                </View>
                <Text className={`text-eyebrow uppercase font-bold ${hitColorClass(h.kind)}`}>
                  {h.kind}
                </Text>
              </Pressable>
            ))
          )}
        </View>
      )}

      {/* When NOT searching, show the rest of the home dashboard */}
      {!showSearch && (
        <>
          {/* ── Today's pulse — proactive monitoring reminders ─── */}
          <TodayPulseCard
            cases={cases}
            onPulsePress={(p) => {
              const fromD = getDrug(p.fromDrugId);
              const toD = getDrug(p.toDrugId);
              if (!fromD || !toD) return;
              const c = cases.find((cc) => cc.id === p.caseId);
              if (!c) return;
              navigation.navigate('Result', {
                fromDrugId: c.fromDrugId,
                fromDoseMg: c.fromDoseMg,
                toDrugId: c.toDrugId,
                toDoseMg: c.toDoseMg,
              });
            }}
          />

          {/* ── Primary CTA ──────────────────────────────────────── */}
          <Pressable
            onPress={() => {
              confirm();
              navigation.navigate('Switch');
            }}
            className="bg-accent rounded-2xl px-5 py-5 mb-3 active:opacity-80"
            style={{
              shadowColor: '#3b82f6',
              shadowOffset: { width: 0, height: 4 },
              shadowOpacity: 0.25,
              shadowRadius: 12,
              elevation: 6,
            }}
            accessibilityRole="button"
            accessibilityLabel="Start a switch"
          >
            <View className="flex-row items-center justify-between">
              <View className="flex-1 pr-3">
                <Text className="text-white text-lg font-bold mb-0.5">
                  Start a switch
                </Text>
                <Text className="text-white/80 text-xs leading-4">
                  {ruleCount} reviewed switching rules · cross-taper, washout, plateau
                </Text>
              </View>
              <View className="w-10 h-10 rounded-xl bg-white/15 items-center justify-center">
                <Icon name="arrow-right" size={20} color="#ffffff" />
              </View>
            </View>
          </Pressable>

          {/* ── Recents ────────────────────────────────────────── */}
          {recents.length > 0 && (
            <View className="mb-3">
              <View className="flex-row items-center justify-between mb-2 mt-3 px-1">
                <Text className="text-muted text-eyebrow uppercase tracking-widest">
                  Recent cases
                </Text>
                <Pressable
                  onPress={() => navigation.navigate('CaseManager')}
                  className="active:opacity-70"
                >
                  <Text className="text-accent text-eyebrow uppercase tracking-widest font-semibold">
                    See all
                  </Text>
                </Pressable>
              </View>
              <View className="bg-surface border border-border rounded-2xl overflow-hidden">
                {recents.map((c, i) => {
                  const fromD = getDrug(c.fromDrugId);
                  const toD = getDrug(c.toDrugId);
                  return (
                    <Pressable
                      key={c.id}
                      onPress={() =>
                        navigation.navigate('Result', {
                          fromDrugId: c.fromDrugId,
                          fromDoseMg: c.fromDoseMg,
                          toDrugId: c.toDrugId,
                          toDoseMg: c.toDoseMg,
                        })
                      }
                      className={`flex-row items-center px-4 py-3 active:opacity-80 ${i < recents.length - 1 ? 'border-b border-border' : ''}`}
                    >
                      <View className="flex-1">
                        <Text className="text-text text-sm font-medium" numberOfLines={1}>
                          {c.label || `${fromD?.genericName ?? c.fromDrugId} → ${toD?.genericName ?? c.toDrugId}`}
                        </Text>
                        <Text className="text-muted text-xs" numberOfLines={1}>
                          {fromD?.genericName ?? c.fromDrugId} {c.fromDoseMg} → {toD?.genericName ?? c.toDrugId} {c.toDoseMg} mg
                        </Text>
                      </View>
                      {c.favourite && (
                        <Text className="text-warning text-base mr-1">★</Text>
                      )}
                      <Icon name="chevron-right" size={16} color="#6b7280" />
                    </Pressable>
                  );
                })}
              </View>
            </View>
          )}

          {/* ── Clinical modules ─────────────────────────────────── */}
          <Text className="text-muted text-eyebrow uppercase tracking-widest mb-2 mt-4 px-1">
            Clinical modules
          </Text>

          {/* LAI depot module hidden in v0.4.15 pending more clinical
              research on initiation overlap, missed-dose algorithms, and
              depot-tail kinetics. Screens (DepotHome / Sustenna / Maintena
              / Trinza) remain registered in the navigator so deep links
              keep working, but the entry tile is gated. */}

          <ModuleCard
            icon="shield"
            iconTint="#f59e0b"
            title="Clozapine module"
            subtitle="Treatment-resistant schizophrenia"
            body="Titration, FBC monitoring, ANC checker, rechallenge."
            onPress={() => navigation.navigate('ClozapineHome')}
          />

          {/* Mood-stabilizer module hidden in v0.4.15 pending more
              clinical research on switching matrix, lithium pacing, SJS
              risk on lamotrigine, valproate teratogenicity in switching
              scenarios. Same hide-not-remove policy as the LAI module. */}

          {/* ── Tools grid — 3-col compact ─────────────────────────
              Switched from a 2-col layout in v0.4.12. With 6 tools the
              3-col grid fits in two rows instead of four, freeing
              vertical space for the Resources row below. */}
          <Text className="text-muted text-eyebrow uppercase tracking-widest mb-2 mt-5 px-1">
            Tools
          </Text>

          <View className="flex-row flex-wrap mb-1" style={{ gap: 8 }}>
            <CompactToolCard
              icon="flask"
              iconTint="#3b82f6"
              label="Dose equivalents"
              onPress={() => navigation.navigate('Equivalency')}
            />
            <CompactToolCard
              icon="heart-pulse"
              iconTint="#ef4444"
              label="QTc stacker"
              onPress={() => navigation.navigate('QtcStacker')}
            />
            <CompactToolCard
              icon="info"
              iconTint="#f59e0b"
              label="Adverse effects"
              onPress={() => navigation.navigate('AdverseEffects')}
            />
            <CompactToolCard
              icon="user"
              iconTint="#34d399"
              label="Patient context"
              onPress={() => navigation.navigate('PatientContext')}
            />
            <CompactToolCard
              icon="sparkles"
              iconTint="#a78bfa"
              label="Ramadan mode"
              onPress={() => navigation.navigate('RamadanMode')}
            />
            <CompactToolCard
              icon="document"
              iconTint="#8b949e"
              label="Saved cases"
              onPress={() => navigation.navigate('CaseManager')}
            />
          </View>

          {/* ── Resources row ────────────────────────────────────
              Reference + meta surfaces. Less prominent than the tools,
              so rendered as small text-only rows in a 2-col grid. */}
          <Text className="text-muted text-eyebrow uppercase tracking-widest mb-2 mt-5 px-1">
            Resources
          </Text>

          <View className="flex-row flex-wrap" style={{ gap: 8 }}>
            <ResourceLink
              icon="info"
              label="Glossary"
              onPress={() => navigation.navigate('Glossary')}
            />
            <ResourceLink
              icon="sparkles"
              label="What's new"
              onPress={() => navigation.navigate('Changelog')}
            />
            <ResourceLink
              icon="clipboard-check"
              label="Review"
              onPress={() => navigation.navigate('ReviewDashboard')}
            />
            <ResourceLink
              icon="info"
              label="About"
              onPress={() => navigation.navigate('About')}
            />
          </View>

          {/* ── Status pill ──────────────────────────────────────── */}
          <View className="mt-6 bg-surface border border-border rounded-2xl px-4 py-3.5">
            <View className="flex-row items-center mb-1.5">
              <View className="w-1.5 h-1.5 rounded-full bg-warning mr-2" />
              <Text className="text-warning text-eyebrow uppercase tracking-widest font-bold">
                Pre-release · pending clinical review
              </Text>
            </View>
            <Text className="text-muted text-xs leading-4">
              Reviewed cross-titration rules across antidepressants and oral
              antipsychotics. Mood stabilizers and LAI depot protocols are
              still under clinical review and currently hidden from the
              switch picker. All content awaits final sign-off before
              public release.
            </Text>
          </View>
        </>
      )}
    </ScreenContainer>
  );
}

function hitIcon(kind: SearchHit['kind']): IconName {
  switch (kind) {
    case 'drug':   return 'pill';
    case 'rule':   return 'arrow-right';
    case 'tool':   return 'flask';
    case 'module': return 'shield';
  }
}

function hitColor(kind: SearchHit['kind']): string {
  switch (kind) {
    case 'drug':   return '#60a5fa';
    case 'rule':   return '#34d399';
    case 'tool':   return '#3b82f6';
    case 'module': return '#f59e0b';
  }
}

function hitColorClass(kind: SearchHit['kind']): string {
  switch (kind) {
    case 'drug':   return 'text-from';
    case 'rule':   return 'text-to';
    case 'tool':   return 'text-accent';
    case 'module': return 'text-warning';
  }
}

// ── Module card — full-width primary clinical surface ────────────────────────
// As of v0.4.12 the multi-line body is dropped and the card is tighter so all
// three modules (Depot, Clozapine, Mood stabilizers) fit comfortably above the
// fold. The body text was repeating what the destination screen says anyway.

function ModuleCard({
  icon,
  iconTint,
  title,
  subtitle,
  body,
  onPress,
}: {
  icon: IconName;
  iconTint: string;
  title: string;
  subtitle: string;
  /** Retained for accessibility label only — no longer rendered visually. */
  body: string;
  onPress: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      className="bg-surface border border-border rounded-2xl px-4 py-3 mb-2 active:opacity-80"
      accessibilityRole="button"
      accessibilityLabel={`${title}. ${subtitle}. ${body}`}
    >
      <View className="flex-row items-center">
        <View
          className="w-10 h-10 rounded-xl items-center justify-center mr-3"
          style={{ backgroundColor: `${iconTint}1a`, borderWidth: 1, borderColor: `${iconTint}33` }}
        >
          <Icon name={icon} size={18} color={iconTint} />
        </View>
        <View className="flex-1 pr-2">
          <Text className="text-text text-base font-bold leading-tight">{title}</Text>
          <Text className="text-muted text-micro mt-0.5" numberOfLines={1}>
            {subtitle}
          </Text>
        </View>
        <Icon name="chevron-right" size={18} color="#6b7280" />
      </View>
    </Pressable>
  );
}

// ── Compact tool card — 3-col grid entry ─────────────────────────────────────
// Replaces UtilityCard (was 2-col, taller card with subtitle text). At 3-col
// width on a phone the subtitle line wraps awkwardly, so we drop it and let
// the icon + label do all the lifting. Width is `~33% - gap` via flexBasis.

function CompactToolCard({
  icon,
  iconTint,
  label,
  onPress,
}: {
  icon: IconName;
  iconTint?: string;
  label: string;
  onPress: () => void;
}) {
  const tint = iconTint ?? '#8b949e';
  return (
    <Pressable
      onPress={onPress}
      style={{ flexBasis: '32%', flexGrow: 1 }}
      className="bg-surface border border-border rounded-2xl px-3 py-3 mb-2 active:opacity-80"
      accessibilityRole="button"
      accessibilityLabel={label}
    >
      <View
        className="w-8 h-8 rounded-xl items-center justify-center mb-2"
        style={{ backgroundColor: `${tint}1a`, borderWidth: 1, borderColor: `${tint}33` }}
      >
        <Icon name={icon} size={16} color={tint} />
      </View>
      <Text className="text-text text-[13px] font-semibold leading-tight" numberOfLines={2}>
        {label}
      </Text>
    </Pressable>
  );
}

// ── Resource link — small reference / meta-surface row ──────────────────────
// Smaller and less prominent than CompactToolCard. Pinned to a 2-col grid.

function ResourceLink({
  icon,
  label,
  onPress,
}: {
  icon: IconName;
  label: string;
  onPress: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      style={{ flexBasis: '48%', flexGrow: 1 }}
      className="bg-surface border border-border rounded-xl px-3 py-2.5 mb-2 flex-row items-center active:opacity-80"
      accessibilityRole="button"
      accessibilityLabel={label}
    >
      <Icon name={icon} size={14} color="#8b949e" />
      <Text className="text-text text-xs font-medium ml-2 flex-1">
        {label}
      </Text>
      <Icon name="chevron-right" size={12} color="#6b7280" />
    </Pressable>
  );
}
