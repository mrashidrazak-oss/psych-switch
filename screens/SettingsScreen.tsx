// Settings — the only place to change app-wide preferences. Kept narrow:
// text size, locale, crash reports opt-in, citation chips, reminders, reset.
import { Alert, Pressable, Text, View } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { Banner } from '../components/Banner';
import { Icon } from '../components/Icon';
import { ScreenContainer } from '../components/ScreenContainer';
import { SegmentedControl } from '../components/SegmentedControl';
import { SwitchRow } from '../components/SwitchRow';
import { cancelAllReminders, IS_EXPO_GO } from '../engine/notifications';
import { useSettings, type Locale, type TextSize } from '../engine/settings';
import type { RootStackParamList } from '../utils/navigation';

type Nav = NativeStackNavigationProp<RootStackParamList>;

export function SettingsScreen() {
  const nav = useNavigation<Nav>();
  const { settings, update, resetAll, loaded } = useSettings();

  if (!loaded) {
    return <ScreenContainer><Text className="text-muted">Loading…</Text></ScreenContainer>;
  }

  const onReset = () => {
    Alert.alert(
      'Clear all local data?',
      'This wipes patient context, saved cases, sign-offs and preferences. Cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Clear all',
          style: 'destructive',
          onPress: () =>
            resetAll().then(() => Alert.alert('Cleared', 'All local data has been reset.')),
        },
      ],
    );
  };

  return (
    <ScreenContainer>
      <Text className="text-text text-2xl font-bold mb-1">Settings</Text>
      <Text className="text-muted text-sm leading-5 mb-4">
        App-wide preferences. All stored locally.
      </Text>

      {/* Display */}
      <SectionLabel>Display</SectionLabel>
      <Field label="Text size">
        <SegmentedControl<TextSize>
          options={[
            { value: 'compact', label: 'Compact' },
            { value: 'normal',  label: 'Normal'  },
            { value: 'large',   label: 'Large'   },
          ]}
          value={settings.textSize}
          onChange={(v) => update({ textSize: v })}
        />
      </Field>

      <Field label="Language">
        <SegmentedControl<Locale>
          options={[
            { value: 'en', label: 'EN' },
            { value: 'ms', label: 'BM' },
            { value: 'id', label: 'ID' },
          ]}
          value={settings.locale}
          onChange={(v) => update({ locale: v })}
        />
        <Helper>BM / ID translations land in v0.3 — UI scaffolded.</Helper>
      </Field>

      {/* Behaviour */}
      <SectionLabel>Behaviour</SectionLabel>
      <SwitchRow
        label="Show citation chips on schedule"
        description="Per-step source pointer (Maudsley page, BAP §)."
        value={settings.showCitationChips}
        onChange={(v) => update({ showCitationChips: v })}
        className="mb-2"
      />
      <SwitchRow
        label="Patient-context prompt"
        description="Nudge to add age, renal/hepatic status before running a switch."
        value={settings.surfaceContextPrompt}
        onChange={(v) => update({ surfaceContextPrompt: v })}
        className="mb-2"
      />

      {/* Reminders */}
      <SectionLabel>Reminders</SectionLabel>
      {IS_EXPO_GO && (
        <Banner
          tone="warning"
          eyebrow="Running in Expo Go"
          className="mb-2"
        >
          <Text className="text-text text-xs leading-4">
            Local scheduled reminders work, but Expo Go logs a warning
            about remote push that we don't use. For full
            notification support (channels, custom sounds, lock-screen
            priority) build a custom dev client.
          </Text>
        </Banner>
      )}
      <SwitchRow
        label="Monitoring reminders"
        description="Local notifications on the days each saved case has labs / reviews / ECGs due."
        value={settings.remindersEnabled}
        onChange={(v) => {
          update({ remindersEnabled: v });
          if (!v) cancelAllReminders();
        }}
        className="mb-2"
      />
      {settings.remindersEnabled && (
        <>
          <SwitchRow
            label="Auto-schedule on save"
            description="When you save a case, reminders are scheduled silently. Turn off to ask each time."
            value={settings.autoScheduleReminders}
            onChange={(v) => update({ autoScheduleReminders: v })}
            className="mb-2"
          />
          <Field label="Reminder time of day">
            <SegmentedControl<number>
              options={[
                { value: 7,  label: '7am'  },
                { value: 9,  label: '9am'  },
                { value: 12, label: '12pm' },
                { value: 17, label: '5pm'  },
              ]}
              value={settings.reminderHour}
              onChange={(v) => update({ reminderHour: v })}
            />
            <Helper>
              Existing scheduled reminders keep their original time; only newly-saved cases pick this up.
            </Helper>
          </Field>
        </>
      )}

      {/* Privacy */}
      <SectionLabel>Privacy</SectionLabel>
      <SwitchRow
        label="Send anonymous crash reports"
        description="Helps fix engine bugs. Stack traces only — no clinical inputs."
        value={settings.crashReports}
        onChange={(v) => update({ crashReports: v })}
        className="mb-2"
      />
      <Pressable
        onPress={() => nav.navigate('Privacy')}
        className="bg-surface border border-border rounded-2xl px-4 py-3 mb-2 flex-row items-center active:opacity-80"
      >
        <Icon name="shield" size={16} color="#3b82f6" />
        <Text className="text-text text-sm font-medium ml-2 flex-1">
          Privacy policy
        </Text>
        <Icon name="chevron-right" size={16} color="#6b7280" />
      </Pressable>
      <Pressable
        onPress={() => nav.navigate('Terms')}
        className="bg-surface border border-border rounded-2xl px-4 py-3 mb-2 flex-row items-center active:opacity-80"
      >
        <Icon name="info" size={16} color="#f59e0b" />
        <Text className="text-text text-sm font-medium ml-2 flex-1">
          Terms of use
        </Text>
        <Icon name="chevron-right" size={16} color="#6b7280" />
      </Pressable>
      <Pressable
        onPress={() => nav.navigate('Changelog')}
        className="bg-surface border border-border rounded-2xl px-4 py-3 mb-2 flex-row items-center active:opacity-80"
      >
        <Icon name="sparkles" size={16} color="#3b82f6" />
        <Text className="text-text text-sm font-medium ml-2 flex-1">
          What's new
        </Text>
        <Icon name="chevron-right" size={16} color="#6b7280" />
      </Pressable>
      <Pressable
        onPress={() => nav.navigate('Errata')}
        className="bg-surface border border-border rounded-2xl px-4 py-3 mb-2 flex-row items-center active:opacity-80"
      >
        <Icon name="clipboard-check" size={16} color="#f59e0b" />
        <Text className="text-text text-sm font-medium ml-2 flex-1">
          Errata
        </Text>
        <Icon name="chevron-right" size={16} color="#6b7280" />
      </Pressable>

      {/* Danger zone */}
      <SectionLabel>Reset</SectionLabel>
      <Pressable
        onPress={onReset}
        className="bg-surface border border-danger/30 rounded-2xl py-3 active:opacity-80"
      >
        <Text className="text-danger text-center text-sm font-semibold">
          Clear all local data
        </Text>
      </Pressable>
    </ScreenContainer>
  );
}

// ── helpers ──────────────────────────────────────────────────────────

function SectionLabel({ children }: { children: React.ReactNode }) {
  return (
    <Text className="text-muted text-eyebrow uppercase tracking-widest mt-4 mb-2 px-1">
      {children}
    </Text>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <View className="mb-3">
      <Text className="text-muted text-eyebrow uppercase tracking-wider mb-1 px-1">
        {label}
      </Text>
      {children}
    </View>
  );
}

function Helper({ children }: { children: React.ReactNode }) {
  return <Text className="text-muted text-eyebrow mt-1 px-1">{children}</Text>;
}

// Bespoke Segmented + ToggleRow helpers removed in v0.4.11 —
// replaced by the shared SegmentedControl + SwitchRow primitives.
