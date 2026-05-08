// Case manager — local-only "saved switches" register.
//
// Each case is a SwitchInput + a free-form label (e.g. "Mr A — olanz→arip")
// plus the timestamp it was started. Stored in AsyncStorage; max 50 cases.
// No identifying data — clinicians use initials/codes only.
//
// Used to:
//   • Resume a switch in progress (re-open the Result screen)
//   • Show recents on Home
//   • Audit own practice ("how often do I run this rule?")
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useEffect, useState } from 'react';
import type { SwitchInput } from './types';

const STORAGE_KEY = 'psychswitch.cases.v1';
const MAX_CASES = 50;

export interface SavedCase extends SwitchInput {
  /** Stable ID — uuid-ish, generated client-side. */
  id: string;
  /** Free-form clinician-supplied label. */
  label: string;
  /** ISO timestamp the case was started. */
  startedISO: string;
  /** ISO timestamp of the last update. */
  updatedISO: string;
  /** Optional clinician notes (also stored locally only). */
  notes?: string;
  /** Whether the user starred this case. */
  favourite?: boolean;
}

export function newCaseId(): string {
  return `c_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 8)}`;
}

async function readAll(): Promise<SavedCase[]> {
  const v = await AsyncStorage.getItem(STORAGE_KEY);
  if (!v) return [];
  try { return JSON.parse(v) as SavedCase[]; } catch { return []; }
}

async function writeAll(cases: SavedCase[]): Promise<void> {
  // Keep at most MAX_CASES, newest first.
  const trimmed = [...cases]
    .sort((a, b) => b.updatedISO.localeCompare(a.updatedISO))
    .slice(0, MAX_CASES);
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(trimmed));
}

export async function saveCase(c: Omit<SavedCase, 'id' | 'startedISO' | 'updatedISO'> & { id?: string }): Promise<SavedCase> {
  const all = await readAll();
  const now = new Date().toISOString();
  if (c.id) {
    const idx = all.findIndex((x) => x.id === c.id);
    if (idx >= 0) {
      const merged: SavedCase = { ...all[idx], ...c, id: c.id, updatedISO: now };
      all[idx] = merged;
      await writeAll(all);
      return merged;
    }
  }
  const created: SavedCase = {
    ...c,
    id: c.id ?? newCaseId(),
    startedISO: now,
    updatedISO: now,
  };
  all.unshift(created);
  await writeAll(all);
  return created;
}

export async function deleteCase(id: string): Promise<void> {
  const all = await readAll();
  await writeAll(all.filter((c) => c.id !== id));
}

export async function toggleFavourite(id: string): Promise<void> {
  const all = await readAll();
  const idx = all.findIndex((c) => c.id === id);
  if (idx < 0) return;
  all[idx] = { ...all[idx], favourite: !all[idx].favourite, updatedISO: new Date().toISOString() };
  await writeAll(all);
}

export function useCases() {
  const [cases, setCases] = useState<SavedCase[]>([]);
  const [loaded, setLoaded] = useState(false);

  const reload = async () => {
    const all = await readAll();
    setCases(all);
  };

  useEffect(() => {
    readAll()
      .then(setCases)
      .finally(() => setLoaded(true));
  }, []);

  return { cases, loaded, reload };
}
