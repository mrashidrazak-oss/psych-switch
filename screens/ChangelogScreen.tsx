// Changelog — versioned list of clinical-content + feature updates. Used
// to show clinicians exactly what changed since they last opened the app.
import { Text, View } from 'react-native';
import { Icon, type IconName } from '../components/Icon';
import { ScreenContainer } from '../components/ScreenContainer';
import { CHANGELOG, type ChangeKind } from '../engine/changelog';

const KIND_COLOR: Record<ChangeKind, string> = {
  feature:  'text-accent',
  rule:     'text-to',
  fix:      'text-warning',
  breaking: 'text-danger',
};
const KIND_BG: Record<ChangeKind, string> = {
  feature:  'bg-accent/15 border-accent/30',
  rule:     'bg-to/15 border-to/30',
  fix:      'bg-warning/15 border-warning/30',
  breaking: 'bg-danger/15 border-danger/30',
};
const KIND_ICON: Record<ChangeKind, IconName> = {
  feature:  'sparkles',
  rule:     'check',
  fix:      'refresh',
  breaking: 'shield',
};

export function ChangelogScreen() {
  return (
    <ScreenContainer>
      <Text className="text-text text-2xl font-bold mb-1">What's new</Text>
      <Text className="text-muted text-sm leading-5 mb-4">
        Versioned record of clinical content and app changes. Pulled
        automatically via OTA — restart the app to receive the latest.
      </Text>

      {CHANGELOG.map((entry) => (
        <View
          key={entry.version}
          className="bg-surface border border-border rounded-2xl px-4 py-4 mb-3"
        >
          <View className="flex-row items-center mb-2">
            <View className={`w-9 h-9 rounded-xl ${KIND_BG[entry.kind]} border items-center justify-center mr-3`}>
              <Icon
                name={KIND_ICON[entry.kind]}
                size={16}
                color={
                  entry.kind === 'feature' ? '#3b82f6' :
                  entry.kind === 'rule' ? '#34d399' :
                  entry.kind === 'fix' ? '#f59e0b' : '#ef4444'
                }
              />
            </View>
            <View className="flex-1">
              <View className="flex-row items-baseline">
                <Text className="text-text text-base font-bold">v{entry.version}</Text>
                <Text className={`text-eyebrow uppercase tracking-widest font-bold ml-2 ${KIND_COLOR[entry.kind]}`}>
                  {entry.kind}
                </Text>
              </View>
              <Text className="text-muted text-xs mt-0.5">{entry.title} · {entry.dateISO}</Text>
            </View>
          </View>
          {entry.items.map((it, i) => (
            <View key={i} className="flex-row mb-1">
              <Text className="text-muted text-sm leading-5 mr-2">•</Text>
              <Text className="text-text text-sm leading-5 flex-1">{it}</Text>
            </View>
          ))}
        </View>
      ))}
    </ScreenContainer>
  );
}
