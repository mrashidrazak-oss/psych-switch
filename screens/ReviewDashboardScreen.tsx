// Review dashboard — clinical author only.
// Shows live audit of rules and drug profiles. Supports in-app sign-off with
// persistence via AsyncStorage and an export function for batch JSON updates.
//
// Sign-off store key: 'psychswitch.signoffs.v1'
// Shape: Record<ruleId | drugId, { by: string; date: string }>
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Modal,
  Pressable,
  ScrollView,
  Share,
  Text,
  TextInput,
  View,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { listAllDrugs, listRules } from '../engine/switchingEngine';

const SIGNOFF_KEY = 'psychswitch.signoffs.v1';

type Tab = 'rules' | 'drugs';
type Signoffs = Record<string, { by: string; date: string }>;

function isPending(reviewedBy: string): boolean {
  return reviewedBy.toUpperCase().includes('PENDING');
}

function todayISO(): string {
  return new Date().toISOString().split('T')[0];
}

// ── Main screen ───────────────────────────────────────────────────────────────

export function ReviewDashboardScreen() {
  const insets = useSafeAreaInsets();
  const [tab, setTab] = useState<Tab>('rules');
  const [showPendingOnly, setShowPendingOnly] = useState(false);
  const [signoffs, setSignoffs] = useState<Signoffs>({});

  // Sign-off modal state
  const [pendingSignoff, setPendingSignoff] = useState<{
    id: string;
    label: string;
  } | null>(null);
  const [reviewerName, setReviewerName] = useState('');

  const rules = useMemo(() => listRules(), []);
  const drugs = useMemo(() => listAllDrugs(), []);

  // Load persisted sign-offs
  useEffect(() => {
    AsyncStorage.getItem(SIGNOFF_KEY).then((raw) => {
      if (raw) {
        try {
          setSignoffs(JSON.parse(raw));
        } catch {
          // ignore corrupt data
        }
      }
    });
  }, []);

  // Persist sign-offs on change
  const saveSignoffs = useCallback(async (updated: Signoffs) => {
    setSignoffs(updated);
    await AsyncStorage.setItem(SIGNOFF_KEY, JSON.stringify(updated));
  }, []);

  // Determine if something is reviewed (either in JSON or in persisted sign-offs)
  const isReviewed = useCallback(
    (id: string, reviewedBy: string) => {
      return !isPending(reviewedBy) || id in signoffs;
    },
    [signoffs],
  );

  const pendingRules = rules.filter((r) => !isReviewed(r.id, r.reviewedBy));
  const pendingDrugs = drugs.filter((d) => !isReviewed(d.id, d.reviewedBy));
  const reviewedRulesCount = rules.length - pendingRules.length;
  const reviewedDrugsCount = drugs.length - pendingDrugs.length;

  const displayRules = showPendingOnly ? pendingRules : rules;
  const displayDrugs = showPendingOnly ? pendingDrugs : drugs;

  // Open sign-off modal
  const openSignoff = (id: string, label: string) => {
    setReviewerName('');
    setPendingSignoff({ id, label });
  };

  // Confirm sign-off
  const confirmSignoff = async () => {
    if (!pendingSignoff || !reviewerName.trim()) return;
    const updated = {
      ...signoffs,
      [pendingSignoff.id]: { by: reviewerName.trim(), date: todayISO() },
    };
    await saveSignoffs(updated);
    setPendingSignoff(null);
  };

  // Undo sign-off
  const undoSignoff = async (id: string) => {
    const updated = { ...signoffs };
    delete updated[id];
    await saveSignoffs(updated);
  };

  // Export sign-offs as formatted text
  const exportSignoffs = async () => {
    const lines: string[] = [
      'PsychSwitch — Sign-off export',
      `Generated: ${new Date().toISOString()}`,
      '═══════════════════════════════════════',
      '',
      '── RULES ─────────────────────────────',
    ];
    for (const rule of rules) {
      const so = signoffs[rule.id];
      const baseReviewed = !isPending(rule.reviewedBy);
      if (so) {
        lines.push(`✓ ${rule.id}`);
        lines.push(`  Signed off by: ${so.by} on ${so.date}`);
      } else if (baseReviewed) {
        lines.push(`✓ ${rule.id}`);
        lines.push(`  JSON: ${rule.reviewedBy} / ${rule.lastReviewedISO}`);
      } else {
        lines.push(`⏳ ${rule.id} — PENDING`);
      }
    }
    lines.push('', '── DRUG PROFILES ─────────────────────');
    for (const drug of drugs) {
      const so = signoffs[drug.id];
      const baseReviewed = !isPending(drug.reviewedBy);
      if (so) {
        lines.push(`✓ ${drug.id} (${drug.genericName})`);
        lines.push(`  Signed off by: ${so.by} on ${so.date}`);
      } else if (baseReviewed) {
        lines.push(`✓ ${drug.id} (${drug.genericName})`);
        lines.push(`  JSON: ${drug.reviewedBy}`);
      } else {
        lines.push(`⏳ ${drug.id} — PENDING`);
      }
    }
    lines.push('', `Summary: ${reviewedRulesCount}/${rules.length} rules · ${reviewedDrugsCount}/${drugs.length} drugs reviewed`);
    await Share.share({ message: lines.join('\n') });
  };

  return (
    <View className="flex-1 bg-bg">
      {/* ── Summary stats ──────────────────────────────────────────── */}
      <View className="px-5 pt-3 pb-3 border-b border-border bg-bg">
        <View className="flex-row gap-3 mb-2">
          <StatPill
            label="Rules signed off"
            value={reviewedRulesCount}
            total={rules.length}
            done={reviewedRulesCount === rules.length}
          />
          <StatPill
            label="Drug profiles signed off"
            value={reviewedDrugsCount}
            total={drugs.length}
            done={reviewedDrugsCount === drugs.length}
          />
        </View>
        <Pressable
          onPress={exportSignoffs}
          className="bg-surface border border-border rounded-xl py-2 active:opacity-70"
        >
          <Text className="text-center text-muted text-xs font-semibold">
            ↑ Export sign-off report
          </Text>
        </Pressable>
      </View>

      {/* ── Tab + filter bar ──────────────────────────────────────── */}
      <View className="flex-row items-center px-5 pt-3 pb-2 gap-3">
        <View className="flex-row flex-1 bg-surface border border-border rounded-2xl p-1">
          <TabBtn
            label={`Rules (${rules.length})`}
            active={tab === 'rules'}
            onPress={() => setTab('rules')}
          />
          <TabBtn
            label={`Drugs (${drugs.length})`}
            active={tab === 'drugs'}
            onPress={() => setTab('drugs')}
          />
        </View>
        <Pressable
          onPress={() => setShowPendingOnly((v) => !v)}
          className={`px-3 py-2 rounded-xl border active:opacity-70 ${
            showPendingOnly ? 'bg-warning/10 border-warning/40' : 'bg-surface border-border'
          }`}
        >
          <Text
            className={`text-xs font-semibold ${showPendingOnly ? 'text-warning' : 'text-muted'}`}
          >
            ⏳ Pending only
          </Text>
        </Pressable>
      </View>

      {/* ── List ──────────────────────────────────────────────────── */}
      <ScrollView
        className="flex-1"
        contentContainerStyle={{
          paddingHorizontal: 20,
          paddingBottom: Math.max(insets.bottom + 16, 32),
        }}
      >
        {tab === 'rules' ? (
          <View className="bg-surface border border-border rounded-2xl overflow-hidden">
            {displayRules.length === 0 ? (
              <View className="px-4 py-6 items-center">
                <Text className="text-to text-sm font-semibold">All rules signed off ✓</Text>
              </View>
            ) : (
              displayRules.map((rule, i) => {
                const reviewed = isReviewed(rule.id, rule.reviewedBy);
                const so = signoffs[rule.id];
                const isLast = i === displayRules.length - 1;
                return (
                  <View
                    key={rule.id}
                    className={`px-4 py-3 ${!isLast ? 'border-b border-border' : ''}`}
                  >
                    <View className="flex-row items-center">
                      <Text className={`text-sm mr-2 ${reviewed ? 'text-to' : 'text-warning'}`}>
                        {reviewed ? '✓' : '⏳'}
                      </Text>
                      <View className="flex-1">
                        <Text className="text-text text-sm font-medium leading-snug">
                          {rule.fromDrugId} → {rule.toDrugId}
                        </Text>
                        <Text className="text-muted text-xs mt-0.5">
                          {rule.strategy} · {rule.durationDays}d
                          {so
                            ? ` · ✓ ${so.by}, ${so.date}`
                            : reviewed
                            ? ` · ${rule.reviewedBy.replace(/PENDING\s*-?\s*/i, '')}`
                            : ' · PENDING'}
                        </Text>
                      </View>
                      {reviewed && so ? (
                        <Pressable
                          onPress={() => undoSignoff(rule.id)}
                          className="ml-2 px-2 py-1 rounded-lg bg-danger/10 border border-danger/30 active:opacity-70"
                        >
                          <Text className="text-danger text-eyebrow font-semibold">Undo</Text>
                        </Pressable>
                      ) : !reviewed ? (
                        <Pressable
                          onPress={() =>
                            openSignoff(rule.id, `${rule.fromDrugId} → ${rule.toDrugId}`)
                          }
                          className="ml-2 px-2 py-1 rounded-lg bg-accent/10 border border-accent/30 active:opacity-70"
                        >
                          <Text className="text-accent text-eyebrow font-semibold">Sign off</Text>
                        </Pressable>
                      ) : (
                        <Text className="text-muted text-xs ml-2">{rule.lastReviewedISO}</Text>
                      )}
                    </View>
                  </View>
                );
              })
            )}
          </View>
        ) : (
          <View className="bg-surface border border-border rounded-2xl overflow-hidden">
            {displayDrugs.length === 0 ? (
              <View className="px-4 py-6 items-center">
                <Text className="text-to text-sm font-semibold">
                  All drug profiles signed off ✓
                </Text>
              </View>
            ) : (
              displayDrugs.map((drug, i) => {
                const reviewed = isReviewed(drug.id, drug.reviewedBy);
                const so = signoffs[drug.id];
                const isLast = i === displayDrugs.length - 1;
                return (
                  <View
                    key={drug.id}
                    className={`px-4 py-3 ${!isLast ? 'border-b border-border' : ''}`}
                  >
                    <View className="flex-row items-center">
                      <Text className={`text-sm mr-2 ${reviewed ? 'text-to' : 'text-warning'}`}>
                        {reviewed ? '✓' : '⏳'}
                      </Text>
                      <View className="flex-1">
                        <View className="flex-row items-center gap-1.5 flex-wrap">
                          <Text className="text-text text-sm font-medium">
                            {drug.genericName}
                          </Text>
                          {drug.hidden ? (
                            <View className="bg-border rounded-full px-1.5 py-0.5">
                              <Text className="text-muted text-[9px] font-semibold">HIDDEN</Text>
                            </View>
                          ) : null}
                        </View>
                        <Text className="text-muted text-xs mt-0.5">
                          {drug.drugClass}
                          {so
                            ? ` · ✓ ${so.by}, ${so.date}`
                            : reviewed
                            ? ` · ${drug.reviewedBy.replace(/PENDING\s*-?\s*/i, '')}`
                            : ' · PENDING'}
                        </Text>
                      </View>
                      {reviewed && so ? (
                        <Pressable
                          onPress={() => undoSignoff(drug.id)}
                          className="ml-2 px-2 py-1 rounded-lg bg-danger/10 border border-danger/30 active:opacity-70"
                        >
                          <Text className="text-danger text-eyebrow font-semibold">Undo</Text>
                        </Pressable>
                      ) : !reviewed ? (
                        <Pressable
                          onPress={() => openSignoff(drug.id, drug.genericName)}
                          className="ml-2 px-2 py-1 rounded-lg bg-accent/10 border border-accent/30 active:opacity-70"
                        >
                          <Text className="text-accent text-eyebrow font-semibold">Sign off</Text>
                        </Pressable>
                      ) : (
                        <Text className="text-muted text-xs ml-2">{drug.lastReviewedISO}</Text>
                      )}
                    </View>
                  </View>
                );
              })
            )}
          </View>
        )}
      </ScrollView>

      {/* ── Sign-off modal ────────────────────────────────────────── */}
      <Modal
        visible={pendingSignoff !== null}
        transparent
        animationType="fade"
        onRequestClose={() => setPendingSignoff(null)}
      >
        {/* Backdrop — pure style, no className on the absolute container */}
        <Pressable
          onPress={() => setPendingSignoff(null)}
          style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.6)', justifyContent: 'center', alignItems: 'center' }}
        >
          {/* Sheet — stop propagation so tapping inside doesn't close modal */}
          <Pressable
            onPress={(e) => e.stopPropagation()}
            style={{ width: '85%', maxWidth: 380 }}
          >
            <View className="bg-surface border border-border rounded-3xl px-6 py-5">
              <Text className="text-text text-base font-bold mb-1">Sign off</Text>
              <Text className="text-muted text-xs mb-4 leading-4" numberOfLines={2}>
                {pendingSignoff?.label}
              </Text>

              <Text className="text-muted text-eyebrow uppercase tracking-widest mb-1.5">
                Your name / initials
              </Text>
              <TextInput
                className="bg-bg border border-border rounded-xl px-3 py-3 text-text text-sm mb-4"
                placeholder="e.g. Rashid R"
                placeholderTextColor="#6b7280"
                value={reviewerName}
                onChangeText={setReviewerName}
                autoFocus
                returnKeyType="done"
                onSubmitEditing={confirmSignoff}
              />

              <View className="flex-row gap-3">
                <Pressable
                  onPress={() => setPendingSignoff(null)}
                  className="flex-1 py-3 rounded-xl bg-surface border border-border active:opacity-70"
                >
                  <Text className="text-center text-muted text-sm font-semibold">Cancel</Text>
                </Pressable>
                <Pressable
                  onPress={confirmSignoff}
                  className={`flex-1 py-3 rounded-xl active:opacity-70 ${
                    reviewerName.trim() ? 'bg-accent' : 'bg-border'
                  }`}
                >
                  <Text
                    className={`text-center text-sm font-bold ${
                      reviewerName.trim() ? 'text-white' : 'text-muted'
                    }`}
                  >
                    Confirm
                  </Text>
                </Pressable>
              </View>

              <Text className="text-muted text-eyebrow text-center mt-3 leading-4">
                Today's date ({todayISO()}) will be recorded automatically.
              </Text>
            </View>
          </Pressable>
        </Pressable>
      </Modal>
    </View>
  );
}

// ── Shared sub-components ─────────────────────────────────────────────────────

function StatPill({
  label,
  value,
  total,
  done,
}: {
  label: string;
  value: number;
  total: number;
  done: boolean;
}) {
  const pct = total > 0 ? Math.round((value / total) * 100) : 0;
  return (
    <View
      className={`flex-1 rounded-2xl border px-3 py-2.5 ${
        done ? 'bg-to/10 border-to/30' : 'bg-surface border-border'
      }`}
    >
      <Text className={`text-xl font-bold ${done ? 'text-to' : 'text-text'}`}>
        {value}/{total}
      </Text>
      <Text className="text-muted text-eyebrow leading-3 mt-0.5">{label}</Text>
      <View className="h-1 bg-border rounded-full mt-2 overflow-hidden">
        <View
          className={`h-full rounded-full ${done ? 'bg-to' : 'bg-warning'}`}
          style={{ width: `${pct}%` }}
        />
      </View>
    </View>
  );
}

function TabBtn({
  label,
  active,
  onPress,
}: {
  label: string;
  active: boolean;
  onPress: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      className={`flex-1 py-2 rounded-xl active:opacity-80 ${active ? 'bg-accent' : ''}`}
    >
      <Text
        className={`text-center text-xs font-semibold ${active ? 'text-white' : 'text-muted'}`}
      >
        {label}
      </Text>
    </Pressable>
  );
}
