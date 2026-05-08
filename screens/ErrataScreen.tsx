// Errata screen — public audit trail of every clinical-content change.
//
// Search by rule id, drug name, or free text. Filter by severity.
// Each row expands to show before/after, rationale, reviewer, and
// supporting citations.
//
// Visible to anyone — this is a *trust signal*. The whole point of an
// errata feed is that it's open and scrolls forever.
import { useMemo, useState } from 'react';
import { Pressable, Text, TextInput, View } from 'react-native';
import { Icon } from '../components/Icon';
import { ScreenContainer } from '../components/ScreenContainer';
import {
  changeKindLabel,
  errataCount,
  listErrata,
  severityColor,
  severityLabel,
  type ErrataEntry,
  type ErrataSeverity,
} from '../engine/errata';

const SEVERITIES: (ErrataSeverity | 'all')[] = ['all', 'critical', 'significant', 'moderate', 'minor'];

export function ErrataScreen() {
  const [q, setQ] = useState('');
  const [severity, setSeverity] = useState<ErrataSeverity | 'all'>('all');

  const all = useMemo(() => listErrata(), []);

  const filtered = useMemo(() => {
    let out = all;
    if (severity !== 'all') out = out.filter((e) => e.severity === severity);
    if (q.trim().length >= 2) {
      const needle = q.trim().toLowerCase();
      out = out.filter(
        (e) =>
          e.scope.toLowerCase().includes(needle) ||
          e.scopeLabel.toLowerCase().includes(needle) ||
          e.summary.toLowerCase().includes(needle) ||
          e.detail.toLowerCase().includes(needle) ||
          e.rationale.toLowerCase().includes(needle),
      );
    }
    return out;
  }, [all, q, severity]);

  return (
    <ScreenContainer>
      <Text className="text-text text-2xl font-bold mb-1">Errata</Text>
      <Text className="text-muted text-sm leading-5 mb-4">
        {errataCount()} corrections recorded since v0.1. Every accepted
        change is logged with a reviewer signature and citation. No
        edits, no quiet rewrites — append-only audit trail.
      </Text>

      {/* Search */}
      <View className="bg-surface border border-border rounded-2xl px-3 py-2.5 mb-3 flex-row items-center">
        <Icon name="search" size={16} color="#8b949e" />
        <TextInput
          value={q}
          onChangeText={setQ}
          placeholder="Search rule, drug, summary"
          placeholderTextColor="#6b7280"
          className="flex-1 text-text text-sm ml-2"
          returnKeyType="search"
          autoCorrect={false}
          autoCapitalize="none"
        />
      </View>

      {/* Severity filter */}
      <View className="flex-row bg-surface border border-border rounded-2xl p-1 mb-4">
        {SEVERITIES.map((s) => {
          const active = s === severity;
          return (
            <Pressable
              key={s}
              onPress={() => setSeverity(s)}
              className={`flex-1 py-2 rounded-xl ${active ? 'bg-accent' : ''}`}
            >
              <Text className={`text-center text-xs font-semibold ${active ? 'text-white' : 'text-text'}`}>
                {s === 'all' ? 'All' : severityLabel(s as ErrataSeverity)}
              </Text>
            </Pressable>
          );
        })}
      </View>

      {filtered.length === 0 && (
        <View className="bg-surface border border-border rounded-2xl px-4 py-6">
          <Text className="text-muted text-sm text-center">
            No matching errata.
          </Text>
        </View>
      )}

      {filtered.map((e) => (
        <ErrataRow key={e.id} entry={e} />
      ))}

      <View className="bg-surface border border-border rounded-2xl px-4 py-3 mt-4">
        <Text className="text-muted text-eyebrow uppercase tracking-widest font-bold mb-1">
          Report a new issue
        </Text>
        <Text className="text-text text-xs leading-4">
          Found something wrong with a rule? Open the rule's Result
          screen → tap "Report an issue with this rule". Your email
          is templated with the rule id + app version. No patient data.
        </Text>
      </View>
    </ScreenContainer>
  );
}

function ErrataRow({ entry }: { entry: ErrataEntry }) {
  const [expanded, setExpanded] = useState(false);
  const tint = severityColor(entry.severity);

  return (
    <View className="bg-surface border border-border rounded-2xl mt-2 overflow-hidden">
      <Pressable
        onPress={() => setExpanded((e) => !e)}
        className="px-4 py-3 active:opacity-80"
      >
        <View className="flex-row items-start justify-between mb-1">
          <Text className="text-muted text-eyebrow uppercase tracking-widest font-bold">
            {entry.dateISO} · v{entry.appVersion}
          </Text>
          <View className={`rounded-full ${tint.bg} ${tint.border} border px-2 py-0.5`}>
            <Text className={`${tint.text} text-[9px] font-bold uppercase tracking-wider`}>
              {severityLabel(entry.severity)}
            </Text>
          </View>
        </View>
        <Text className="text-text text-sm font-semibold leading-5 mb-1">
          {entry.summary}
        </Text>
        <Text className="text-muted text-micro">
          {entry.scopeLabel} · {changeKindLabel(entry.changeKind)}
        </Text>
      </Pressable>

      {expanded && (
        <View className="border-t border-border px-4 py-3">
          <Text className="text-muted text-eyebrow uppercase tracking-widest font-bold mb-1">
            Detail
          </Text>
          <Text className="text-text text-xs leading-4 mb-3">{entry.detail}</Text>

          {(entry.before || entry.after) && (
            <>
              <Text className="text-muted text-eyebrow uppercase tracking-widest font-bold mb-1">
                Diff
              </Text>
              {entry.before && (
                <View className="bg-danger/10 border-l-2 border-danger rounded-r-md px-3 py-1.5 mb-1">
                  <Text className="text-text text-micro font-mono leading-4">- {entry.before}</Text>
                </View>
              )}
              {entry.after && (
                <View className="bg-to/10 border-l-2 border-to rounded-r-md px-3 py-1.5 mb-3">
                  <Text className="text-text text-micro font-mono leading-4">+ {entry.after}</Text>
                </View>
              )}
            </>
          )}

          <Text className="text-muted text-eyebrow uppercase tracking-widest font-bold mb-1">
            Rationale
          </Text>
          <Text className="text-text text-xs leading-4 mb-3">{entry.rationale}</Text>

          {entry.citations.length > 0 && (
            <>
              <Text className="text-muted text-eyebrow uppercase tracking-widest font-bold mb-1">
                Citations
              </Text>
              {entry.citations.map((c) => (
                <Text key={c} className="text-muted text-eyebrow font-mono mb-0.5">
                  · {c}
                </Text>
              ))}
              <View className="h-3" />
            </>
          )}

          <Text className="text-muted text-eyebrow">
            Reviewer: {entry.reviewer} · scope: {entry.scope}
          </Text>
        </View>
      )}
    </View>
  );
}
