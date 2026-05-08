// App-wide settings — persisted locally. The shape here is the source of
// truth; screens read via the useSettings() hook.
//
// Kept narrow on purpose: each setting must change something the user can
// see. No engagement-driving toggles, no analytics opt-ins disguised as
// preferences.
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useEffect, useState } from 'react';

const STORAGE_KEY = 'psychswitch.settings.v1';

export type TextSize = 'compact' | 'normal' | 'large';
export type Locale = 'en' | 'ms' | 'id';

export interface AppSettings {
  textSize: TextSize;
  locale: Locale;
  /** Opt-in anonymous crash reporting. Off by default. */
  crashReports: boolean;
  /** Show the per-step citation chips on the detailed schedule. */
  showCitationChips: boolean;
  /** Surface the patient-context warning prompt at the top of Result. */
  surfaceContextPrompt: boolean;
  /** Master toggle: when off, no reminders are ever scheduled. */
  remindersEnabled: boolean;
  /** Hour-of-day (0-23) that monitoring reminders fire on. Default 9am. */
  reminderHour: number;
  /** Whether new saved cases auto-schedule reminders by default. */
  autoScheduleReminders: boolean;
}

export const DEFAULT_SETTINGS: AppSettings = {
  textSize: 'normal',
  locale: 'en',
  crashReports: false,
  showCitationChips: true,
  surfaceContextPrompt: true,
  remindersEnabled: true,
  reminderHour: 9,
  autoScheduleReminders: true,
};

let _cached: AppSettings = DEFAULT_SETTINGS;
export function getSettingsSync(): AppSettings {
  return _cached;
}

export function useSettings() {
  const [settings, setSettings] = useState<AppSettings>(DEFAULT_SETTINGS);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    AsyncStorage.getItem(STORAGE_KEY)
      .then((v) => {
        if (v) {
          try {
            const merged = { ...DEFAULT_SETTINGS, ...JSON.parse(v) };
            setSettings(merged);
            _cached = merged;
          } catch {}
        }
      })
      .finally(() => setLoaded(true));
  }, []);

  const update = async (patch: Partial<AppSettings>) => {
    const next = { ...settings, ...patch };
    setSettings(next);
    _cached = next;
    await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(next));
  };

  const resetAll = async () => {
    // Wipe ALL local state (settings, cases, patient context, sign-offs,
    // notification schedule index). Don't clear the disclaimer ack —
    // re-prompting the disclaimer on every reset would be confusing.
    await AsyncStorage.multiRemove([
      STORAGE_KEY,
      'psychswitch.cases.v1',
      'psychswitch.patient_context.v1',
      'psychswitch.signoffs.v1',
      'psychswitch.notifications.schedule.v1',
    ]);
    setSettings(DEFAULT_SETTINGS);
    _cached = DEFAULT_SETTINGS;
  };

  return { settings, update, resetAll, loaded };
}

// ── Text-size scaling ────────────────────────────────────────────────────────
// Provides a multiplier to apply to text-size classes. NativeWind doesn't
// support runtime-dynamic class composition, so we keep this simple: the
// scale is exposed and the only places that *visibly* need it (long-form
// reading screens) opt in by reading from settings.

export function textScale(size: TextSize): number {
  return size === 'compact' ? 0.92 : size === 'large' ? 1.15 : 1.0;
}
