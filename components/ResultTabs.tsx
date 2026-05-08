// Result-screen tab bar — segmented control with 4 tabs.
//
// The Result screen had grown to 24+ stacked cards by v0.4.6, with the
// schedule itself buried at item 16 in a long scroll. Splitting into
// purpose-grouped tabs reduces cognitive load and gets the schedule
// to the top.
//
// Tabs:
//   • Schedule    — the actual schedule + safety flags + toggles
//   • Insights    — predicted AE, alternatives, cost, specialty depth
//   • Provenance  — citations, reviewer, errata, report-issue
//   • Workflow    — discharge summary, counselling card
//
// Inline-style segmented control (not a top-of-screen tab nav) so the
// drug-pair header remains visible above. Tappable, haptic feedback
// on switch, accent fill on the active tab.
import { Pressable, Text, View } from 'react-native';
import { tap as hapticTap } from '../utils/haptics';
import { Icon, type IconName } from './Icon';

export type ResultTab = 'schedule' | 'insights' | 'provenance' | 'workflow';

const TABS: Array<{ id: ResultTab; label: string; icon: IconName }> = [
  { id: 'schedule',   label: 'Schedule',   icon: 'activity' },
  { id: 'insights',   label: 'Insights',   icon: 'sparkles' },
  { id: 'provenance', label: 'Provenance', icon: 'shield' },
  { id: 'workflow',   label: 'Workflow',   icon: 'document' },
];

export function ResultTabs({
  active,
  onChange,
}: {
  active: ResultTab;
  onChange: (tab: ResultTab) => void;
}) {
  return (
    <View
      className="flex-row bg-surface border border-border rounded-2xl p-1 mt-4 mb-3"
      accessibilityRole="tablist"
    >
      {TABS.map((t) => {
        const isActive = t.id === active;
        return (
          <Pressable
            key={t.id}
            onPress={() => {
              if (!isActive) hapticTap();
              onChange(t.id);
            }}
            accessibilityRole="tab"
            accessibilityState={{ selected: isActive }}
            accessibilityLabel={t.label}
            className={`flex-1 flex-row items-center justify-center py-2 px-2 rounded-xl ${
              isActive ? 'bg-accent' : ''
            }`}
          >
            <Icon
              name={t.icon}
              size={13}
              color={isActive ? '#ffffff' : '#8b949e'}
            />
            <Text
              className={`text-xs font-semibold ml-1.5 ${
                isActive ? 'text-white' : 'text-muted'
              }`}
              numberOfLines={1}
            >
              {t.label}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}
