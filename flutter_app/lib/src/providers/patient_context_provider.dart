// Patient context — transient state for the current Switch flow.
//
// Phase 7B. Lives only in memory. The Switch screen lets the user
// open a sheet to set age/sex/renal/hepatic/pregnancy/comorbidities;
// the Result screen reads the same provider to:
//
//   • compute warnings via warningsForDrug(ctx, toDrugId)
//   • feed contextWarnings into computePsychSwitchScore
//   • pass context into generateMonitoringPlan for renal/hepatic/
//     metabolic add-ons.
//
// We deliberately don't persist this — clinical context is per-patient
// and shouldn't bleed across sessions. A "Clear" action on the sheet
// resets to emptyContext.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:psychswitch_engine/patient_context_pure.dart';

/// Holds the context the clinician is currently building. Defaults to
/// [emptyContext]. UI rebuilds when this changes.
final patientContextProvider = StateProvider<PatientContext>(
  (ref) => emptyContext,
);
