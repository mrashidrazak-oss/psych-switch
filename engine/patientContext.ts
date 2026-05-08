// Patient context — React-side hook + AsyncStorage persistence.
//
// This file re-exports the pure types and helpers from
// `patientContextPure.ts`, then layers on the React hook used by
// PatientContextScreen / SwitchScreen / ResultScreen.
//
// All UI code that imports from `engine/patientContext` continues to
// work; the split exists so a Node-only consumer (the MCP server) can
// import from `patientContextPure.ts` without pulling in React or
// AsyncStorage.
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useEffect, useState } from 'react';
import {
  EMPTY_CONTEXT,
  type PatientContext,
} from './patientContextPure';

const STORAGE_KEY = 'psychswitch.patient_context.v1';

// ── Re-exports — the React app's import surface stays unchanged. ───────────
export {
  EMPTY_CONTEXT,
  ageBand,
  bmi,
  estimateEgfr,
  isComplete,
  renalBandFromEgfr,
  warningsForDrug,
  type AgeBand,
  type ContextWarning,
  type HepaticFn,
  type PatientContext,
  type RenalFn,
  type Sex,
} from './patientContextPure';

// ── Persistence hook ────────────────────────────────────────────────────────

export function usePatientContext() {
  const [ctx, setCtx] = useState<PatientContext>(EMPTY_CONTEXT);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    AsyncStorage.getItem(STORAGE_KEY)
      .then((v) => {
        if (v) {
          try { setCtx(JSON.parse(v)); } catch {}
        }
      })
      .finally(() => setLoaded(true));
  }, []);

  const update = async (patch: Partial<PatientContext>) => {
    const next = { ...ctx, ...patch };
    setCtx(next);
    await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(next));
  };

  const clear = async () => {
    setCtx(EMPTY_CONTEXT);
    await AsyncStorage.removeItem(STORAGE_KEY);
  };

  return { ctx, update, clear, loaded };
}

// ── Sync cache (for non-React engine functions that need read-only access) ─
let _cachedContext: PatientContext = EMPTY_CONTEXT;
export function getPatientContextSync(): PatientContext {
  return _cachedContext;
}
export function _setPatientContextCache(ctx: PatientContext) {
  _cachedContext = ctx;
}
