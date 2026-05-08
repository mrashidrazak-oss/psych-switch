// Case manager — view, resume and delete saved switches.
//
// Privacy note: cases are clinician-supplied labels only (e.g. "Mr A —
// 12/07"). No identifying data is encouraged in the UI.
import { useCallback } from 'react';
import { Alert, Pressable, Share, Text, View } from 'react-native';
import { useFocusEffect, useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { EmptyState } from '../components/EmptyState';
import { Icon } from '../components/Icon';
import { ScreenContainer } from '../components/ScreenContainer';
import { deleteCase, toggleFavourite, useCases } from '../engine/caseManager';
import { cancelCaseReminders } from '../engine/notifications';
import { getDrug } from '../engine/switchingEngine';
import { exportAuditLogCsv, exportAuditLogJson } from '../utils/exportAuditLog';
import type { RootStackParamList } from '../utils/navigation';

const APP_VERSION = '0.4.5';

type Nav = NativeStackNavigationProp<RootStackParamList>;

export function CaseManagerScreen() {
  const nav = useNavigation<Nav>();
  const { cases, loaded, reload } = useCases();

  // Refresh when we come back from Result (the case may have been updated)
  useFocusEffect(useCallback(() => { reload(); }, []));

  const open = (id: string) => {
    const c = cases.find((x) => x.id === id);
    if (!c) return;
    nav.navigate('Result', {
      fromDrugId: c.fromDrugId,
      fromDoseMg: c.fromDoseMg,
      toDrugId: c.toDrugId,
      toDoseMg: c.toDoseMg,
    });
  };

  const remove = (id: string, label: string) => {
    Alert.alert(
      'Delete case?',
      `This will remove "${label}" from your device. The audit trail is local only.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: () => Promise.all([deleteCase(id), cancelCaseReminders(id)]).then(reload),
        },
      ],
    );
  };

  if (!loaded) {
    return <ScreenContainer><Text className="text-muted">Loading…</Text></ScreenContainer>;
  }

  const favourites = cases.filter((c) => c.favourite);
  const recents    = cases.filter((c) => !c.favourite);

  const onExport = (format: 'csv' | 'json') => {
    const text =
      format === 'csv'
        ? exportAuditLogCsv({ cases, appVersion: APP_VERSION })
        : exportAuditLogJson({ cases, appVersion: APP_VERSION });
    Share.share({ message: text }).catch(() => {});
  };

  return (
    <ScreenContainer>
      <Text className="text-text text-2xl font-bold mb-1">Saved cases</Text>
      <Text className="text-muted text-sm leading-5 mb-4">
        Local-only register of switches in progress. Use initials or codes —
        never identifying data.
      </Text>

      {cases.length === 0 && (
        <EmptyState
          icon="document"
          title="No saved cases yet"
          body="Run a switch and tap 'Save' on the schedule to keep it here. Use initials or codes — never patient-identifying data."
          ctaLabel="Start a switch"
          onCta={() => nav.navigate('Switch')}
        />
      )}

      {/* Audit-log export — appears only when there are cases to export. */}
      {cases.length > 0 && (
        <View className="bg-surface border border-border rounded-2xl px-3 py-3 mb-4 flex-row items-center">
          <View className="w-9 h-9 rounded-xl bg-to/15 border border-to/30 items-center justify-center mr-3">
            <Icon name="document" size={16} color="#34d399" />
          </View>
          <View className="flex-1">
            <Text className="text-text text-sm font-bold">Export audit log</Text>
            <Text className="text-muted text-micro">
              {cases.length} cases · share via system sheet
            </Text>
          </View>
          <Pressable
            onPress={() => onExport('csv')}
            className="bg-bg border border-border rounded-xl px-3 py-2 mr-2 active:opacity-70"
            accessibilityLabel="Export audit log as CSV"
          >
            <Text className="text-text text-xs font-bold">CSV</Text>
          </Pressable>
          <Pressable
            onPress={() => onExport('json')}
            className="bg-bg border border-border rounded-xl px-3 py-2 active:opacity-70"
            accessibilityLabel="Export audit log as JSON"
          >
            <Text className="text-text text-xs font-bold">JSON</Text>
          </Pressable>
        </View>
      )}

      {favourites.length > 0 && (
        <>
          <Text className="text-muted text-eyebrow uppercase tracking-widest mb-2 px-1">
            ★ Starred
          </Text>
          <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
            {favourites.map((c, i) => (
              <CaseRow
                key={c.id}
                caseObj={c}
                isLast={i === favourites.length - 1}
                onOpen={() => open(c.id)}
                onStar={() => toggleFavourite(c.id).then(reload)}
                onDelete={() => remove(c.id, c.label)}
              />
            ))}
          </View>
        </>
      )}

      {recents.length > 0 && (
        <>
          <Text className="text-muted text-eyebrow uppercase tracking-widest mb-2 px-1">
            Recent
          </Text>
          <View className="bg-surface border border-border rounded-2xl overflow-hidden">
            {recents.map((c, i) => (
              <CaseRow
                key={c.id}
                caseObj={c}
                isLast={i === recents.length - 1}
                onOpen={() => open(c.id)}
                onStar={() => toggleFavourite(c.id).then(reload)}
                onDelete={() => remove(c.id, c.label)}
              />
            ))}
          </View>
        </>
      )}
    </ScreenContainer>
  );
}

function CaseRow({
  caseObj,
  isLast,
  onOpen,
  onStar,
  onDelete,
}: {
  caseObj: import('../engine/caseManager').SavedCase;
  isLast: boolean;
  onOpen: () => void;
  onStar: () => void;
  onDelete: () => void;
}) {
  const fromDrug = safeName(caseObj.fromDrugId);
  const toDrug = safeName(caseObj.toDrugId);
  const date = new Date(caseObj.updatedISO);
  const dateStr = `${date.getDate()}/${date.getMonth() + 1}`;

  return (
    <Pressable
      onPress={onOpen}
      onLongPress={onDelete}
      className={`flex-row items-center px-4 py-3 active:opacity-80 ${!isLast ? 'border-b border-border' : ''}`}
    >
      <View className="flex-1">
        <Text className="text-text text-sm font-semibold mb-0.5" numberOfLines={1}>
          {caseObj.label || `${fromDrug} → ${toDrug}`}
        </Text>
        <Text className="text-muted text-xs" numberOfLines={1}>
          {fromDrug} {caseObj.fromDoseMg} → {toDrug} {caseObj.toDoseMg} mg · {dateStr}
        </Text>
      </View>
      <Pressable
        onPress={onStar}
        className="p-2 mr-1"
        accessibilityLabel={caseObj.favourite ? 'Unstar case' : 'Star case'}
      >
        <Text className={`text-base ${caseObj.favourite ? 'text-warning' : 'text-muted'}`}>
          {caseObj.favourite ? '★' : '☆'}
        </Text>
      </Pressable>
      <Icon name="chevron-right" size={16} color="#6b7280" />
    </Pressable>
  );
}

function safeName(id: string): string {
  try {
    const d = getDrug(id);
    return d?.genericName ?? id;
  } catch { return id; }
}
