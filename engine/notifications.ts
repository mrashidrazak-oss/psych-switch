// Local-only notification scheduler.
//
// When a clinician saves a case, we derive its monitoring plan and
// schedule one local notification per relevant entry (dayOffset >= 1)
// at the user's preferred reminder time on the absolute calendar day.
// Notifications fire on-device — never via a remote push service —
// so no PHI ever transits a server, and the feature works offline.
//
// Each notification carries:
//   • Title — the case label ("Mr A — 12/07")
//   • Body  — "Day {N}: {label}" e.g. "Day 7: Lithium level"
//   • Data  — { caseId, day, kind } so a tap routes to the right Result
//
// Cancellation: every scheduled notification's identifier is stored
// alongside the case in AsyncStorage so we can wipe them when the
// case is deleted, the user opts out, or a new schedule replaces it.
//
// NOTE on Expo Go:
//   • Local scheduled notifications work in Expo Go on iOS & Android
//     for SDK 54.
//   • Permission prompts behave correctly.
//   • The remote-push token API would NOT work in Expo Go (we don't
//     use it — local only).
import AsyncStorage from '@react-native-async-storage/async-storage';
import Constants, { ExecutionEnvironment } from 'expo-constants';
import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';
import type { MonitoringPlan } from './monitoring';

const SCHEDULE_INDEX_KEY = 'psychswitch.notifications.schedule.v1';

/**
 * True when the JS bundle is running inside the Expo Go shell rather
 * than a custom dev client / standalone build. Expo Go SDK 53+
 * stripped REMOTE push registration; LOCAL scheduled notifications
 * still work, but the package logs an angry warning either way. We
 * use this flag to:
 *   • Skip Android push channel creation that triggers extra warnings
 *   • Surface a friendly "limited support" notice in Settings
 *   • Still allow scheduling — local triggers fire fine in Expo Go.
 */
export const IS_EXPO_GO =
  Constants.executionEnvironment === ExecutionEnvironment.StoreClient;

export interface CaseSchedule {
  /** Stable case id — matches caseManager. */
  caseId: string;
  /** Notification identifiers returned by Notifications.scheduleNotificationAsync. */
  notificationIds: string[];
  /** ISO timestamp the schedule was committed (for audit). */
  scheduledAtISO: string;
  /** Hour-of-day (0-23) at which reminders fire. Persists per-schedule
      so a later global preference change doesn't shift active reminders. */
  hour: number;
  /** Total reminders scheduled (for the cancellation summary). */
  count: number;
}

interface ScheduleIndex {
  [caseId: string]: CaseSchedule | undefined;
}

// ── Permission ────────────────────────────────────────────────────────────────

let _permissionResolved: 'granted' | 'denied' | 'undetermined' | null = null;

/**
 * Request permission to schedule local notifications. iOS shows the
 * system prompt; Android 13+ shows the runtime POST_NOTIFICATIONS
 * prompt. Older Android versions auto-grant.
 *
 * Cached after first resolution to avoid prompting repeatedly.
 */
export async function ensureNotificationPermission(): Promise<'granted' | 'denied' | 'undetermined'> {
  if (_permissionResolved && _permissionResolved !== 'undetermined') {
    return _permissionResolved;
  }
  const existing = await Notifications.getPermissionsAsync();
  if (existing.status === 'granted') {
    _permissionResolved = 'granted';
    return 'granted';
  }
  const requested = await Notifications.requestPermissionsAsync({
    ios: { allowAlert: true, allowBadge: true, allowSound: true },
  });
  _permissionResolved = requested.status as 'granted' | 'denied' | 'undetermined';
  return _permissionResolved;
}

/**
 * Configure default notification handler — show banner + sound when
 * the app is open. Idempotent; safe to call on every mount.
 *
 * In Expo Go we still call setNotificationHandler (it's needed for
 * local scheduled notifications), but skip the Android channel
 * creation which surfaces extra warnings without changing behaviour.
 */
export function configureForeground(): void {
  try {
    Notifications.setNotificationHandler({
      handleNotification: async () => ({
        shouldShowAlert: true,
        shouldPlaySound: false,
        shouldSetBadge: false,
        shouldShowBanner: true,
        shouldShowList: true,
      }),
    });
  } catch {
    // Older SDK runtimes throw on the new shape — ignore and rely on
    // platform defaults. Local scheduled notifications still fire.
  }
  if (Platform.OS === 'android' && !IS_EXPO_GO) {
    Notifications.setNotificationChannelAsync('monitoring', {
      name: 'Monitoring reminders',
      importance: Notifications.AndroidImportance.DEFAULT,
      lightColor: '#3b82f6',
      vibrationPattern: [0, 200, 100, 200],
    }).catch(() => { /* channel creation optional */ });
  }
}

// ── Index persistence ─────────────────────────────────────────────────────────

async function readIndex(): Promise<ScheduleIndex> {
  const raw = await AsyncStorage.getItem(SCHEDULE_INDEX_KEY);
  if (!raw) return {};
  try { return JSON.parse(raw) as ScheduleIndex; } catch { return {}; }
}

async function writeIndex(idx: ScheduleIndex): Promise<void> {
  await AsyncStorage.setItem(SCHEDULE_INDEX_KEY, JSON.stringify(idx));
}

export async function getCaseSchedule(caseId: string): Promise<CaseSchedule | null> {
  const idx = await readIndex();
  return idx[caseId] ?? null;
}

// ── Schedule / cancel ─────────────────────────────────────────────────────────

export interface ScheduleOptions {
  caseId: string;
  caseLabel: string;
  /** Date the case starts. Notifications fire at start + dayOffset days @ hour:00. */
  startDate?: Date;
  /** Hour-of-day to fire reminders. Default 9am. */
  hour?: number;
  /** Monitoring plan to derive entries from. */
  monitoring: MonitoringPlan;
  /** Skip entries with dayOffset === 0 (today / start day). They're not
      "reminders" — the clinician is by definition looking at the schedule. */
  skipDayZero?: boolean;
  /** Cap on number of scheduled reminders per case (iOS allows up to
      64 pending; Android similar). Defaults to 32. */
  max?: number;
}

/**
 * Schedule reminders for a saved case. Cancels any existing schedule
 * for the same caseId first so this is safe to call repeatedly.
 *
 * Returns the count actually scheduled (may be less than the
 * monitoring plan's entries if the cap is hit).
 */
export async function scheduleCaseReminders(opts: ScheduleOptions): Promise<number> {
  const status = await ensureNotificationPermission();
  if (status !== 'granted') return 0;

  await cancelCaseReminders(opts.caseId);

  const startDate = opts.startDate ?? new Date();
  const hour = clampHour(opts.hour ?? 9);
  const skipZero = opts.skipDayZero ?? true;
  const max = opts.max ?? 32;

  const entries = opts.monitoring.entries
    .filter((e) => (skipZero ? e.dayOffset >= 1 : e.dayOffset >= 0))
    .slice(0, max);

  const ids: string[] = [];
  for (const e of entries) {
    const fireAt = new Date(startDate);
    fireAt.setDate(fireAt.getDate() + e.dayOffset);
    fireAt.setHours(hour, 0, 0, 0);
    if (fireAt.getTime() <= Date.now() + 60_000) {
      // Already in the past (or within the next minute) — skip; iOS
      // throws on past triggers and we don't want stale rapid-fire.
      continue;
    }
    try {
      const id = await Notifications.scheduleNotificationAsync({
        content: {
          title: opts.caseLabel || 'PsychSwitch reminder',
          body: `Day ${e.dayOffset}: ${e.label} — ${truncate(e.detail, 90)}`,
          data: { caseId: opts.caseId, day: e.dayOffset, kind: e.label },
          sound: false,
        },
        trigger: {
          type: Notifications.SchedulableTriggerInputTypes.DATE,
          date: fireAt,
          // Custom channel only exists in dev/standalone builds; in
          // Expo Go it's never created so we omit channelId.
          channelId: Platform.OS === 'android' && !IS_EXPO_GO ? 'monitoring' : undefined,
        },
      });
      ids.push(id);
    } catch {
      // Swallow — invalid trigger or quota — keep going.
    }
  }

  const idx = await readIndex();
  idx[opts.caseId] = {
    caseId: opts.caseId,
    notificationIds: ids,
    scheduledAtISO: new Date().toISOString(),
    hour,
    count: ids.length,
  };
  await writeIndex(idx);
  return ids.length;
}

/** Cancel all scheduled reminders for a case. Idempotent. */
export async function cancelCaseReminders(caseId: string): Promise<void> {
  const idx = await readIndex();
  const existing = idx[caseId];
  if (!existing) return;
  for (const id of existing.notificationIds) {
    try {
      await Notifications.cancelScheduledNotificationAsync(id);
    } catch { /* already cancelled / fired — silent */ }
  }
  delete idx[caseId];
  await writeIndex(idx);
}

/** Wipe ALL pending reminders. Used by Settings → Reset. */
export async function cancelAllReminders(): Promise<void> {
  try {
    await Notifications.cancelAllScheduledNotificationsAsync();
  } catch { /* silent */ }
  await AsyncStorage.removeItem(SCHEDULE_INDEX_KEY);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function clampHour(h: number): number {
  if (!Number.isFinite(h)) return 9;
  if (h < 0) return 0;
  if (h > 23) return 23;
  return Math.round(h);
}

function truncate(s: string, n: number): string {
  if (s.length <= n) return s;
  return s.slice(0, n - 1) + '…';
}
