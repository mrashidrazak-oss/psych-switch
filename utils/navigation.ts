// Shared navigation type so screens can type their props correctly.
// When you add a new screen, add a key here too.
import type { SwitchInput } from '../engine/types';

export type RootStackParamList = {
  Home: undefined;
  Switch: undefined;
  Result: SwitchInput;
  About: undefined;
  // Clozapine module
  ClozapineHome: undefined;
  ClozapineInitiation: undefined;
  ClozapineMonitoring: undefined;
  ClozapineAncChecker: undefined;
  ClozapineRechallenge: undefined;
  ClozapineCommunityCriteria: undefined;
  // Mood stabilizer module
  MoodStabilizerHome: undefined;
  MoodStabilizerDetail: { drugId: string };
  LithiumTapering: undefined;
  // LAI depot module
  DepotHome: undefined;
  Sustenna: undefined;
  Maintena: undefined;
  Trinza: undefined;
  // Admin
  ReviewDashboard: undefined;
  // Tools
  QtcStacker: undefined;
  RamadanMode: undefined;
  Equivalency: undefined;
  AdverseEffects: undefined;
  PatientContext: undefined;
  CaseManager: undefined;
  // Meta
  Settings: undefined;
  Changelog: undefined;
  Privacy: undefined;
  Terms: undefined;
  Glossary: undefined;
  Errata: undefined;
};
