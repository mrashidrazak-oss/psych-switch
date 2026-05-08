// Switching engine — pure functions, no React, no async, no I/O.
//
// This file deliberately does NOT do any clinical extrapolation. If a user
// asks for a switch outside the doses we have explicitly reviewed, we
// REFUSE to generate a plan and return `dose_out_of_range`. Linear scaling
// of antidepressant doses is unsafe and clinically unjustified, especially
// at the edges of the therapeutic window.
//
// To add support for a new drug pair or dose, add a new JSON file under
// /content/switching-rules/, import it below, and append it to RULES.
// Every rule must be reviewed by the clinical advisor before being
// imported here.

import agomelatine from '../content/drugs/agomelatine.json';
import amisulpride from '../content/drugs/amisulpride.json';
import aripiprazole from '../content/drugs/aripiprazole.json';
import aripiprazoleLai from '../content/drugs/aripiprazole-lai.json';
import carbamazepine from '../content/drugs/carbamazepine.json';
import chlorpromazine from '../content/drugs/chlorpromazine.json';
import clozapine from '../content/drugs/clozapine.json';
import flupenthixol from '../content/drugs/flupenthixol.json';
import fluphenazine from '../content/drugs/fluphenazine.json';
import paliperidone from '../content/drugs/paliperidone.json';
import zuclopenthixol from '../content/drugs/zuclopenthixol.json';
import desvenlafaxine from '../content/drugs/desvenlafaxine.json';
import duloxetine from '../content/drugs/duloxetine.json';
import escitalopram from '../content/drugs/escitalopram.json';
import fluoxetine from '../content/drugs/fluoxetine.json';
import fluphenazineLai from '../content/drugs/fluphenazine-lai.json';
import flupenthixolLai from '../content/drugs/flupenthixol-lai.json';
import fluvoxamine from '../content/drugs/fluvoxamine.json';
import haloperidol from '../content/drugs/haloperidol.json';
import haloperidolLai from '../content/drugs/haloperidol-lai.json';
import lamotrigine from '../content/drugs/lamotrigine.json';
import lithium from '../content/drugs/lithium.json';
import lurasidone from '../content/drugs/lurasidone.json';
import mirtazapine from '../content/drugs/mirtazapine.json';
import moclobemide from '../content/drugs/moclobemide.json';
import olanzapine from '../content/drugs/olanzapine.json';
import paliperidoneLai from '../content/drugs/paliperidone-lai.json';
import paroxetine from '../content/drugs/paroxetine.json';
import phenelzine from '../content/drugs/phenelzine.json';
import quetiapine from '../content/drugs/quetiapine.json';
import risperidone from '../content/drugs/risperidone.json';
import risperidoneLai from '../content/drugs/risperidone-lai.json';
import sertraline from '../content/drugs/sertraline.json';
import sulpiride from '../content/drugs/sulpiride.json';
import tranylcypromine from '../content/drugs/tranylcypromine.json';
import trifluoperazine from '../content/drugs/trifluoperazine.json';
import valproate from '../content/drugs/valproate.json';
import venlafaxine from '../content/drugs/venlafaxine.json';
import vortioxetine from '../content/drugs/vortioxetine.json';
import zuclopenthixolLai from '../content/drugs/zuclopenthixol-lai.json';
import duloxetineToSertraline from '../content/switching-rules/duloxetine-to-sertraline.json';
import haloperidolLaiToRisperidoneLai from '../content/switching-rules/haloperidol-lai-to-risperidone-lai.json';
import carbamazepineToLamotrigine from '../content/switching-rules/carbamazepine-to-lamotrigine.json';
import valproateToLamotrigine from '../content/switching-rules/valproate-to-lamotrigine.json';
import aripiprazoleLaiToPaliperidoneLai from '../content/switching-rules/aripiprazole-lai-to-paliperidone-lai.json';
import aripiprazoleToAripiprazoleLai from '../content/switching-rules/aripiprazole-to-aripiprazole-lai.json';
import aripiprazoleToHaloperidol from '../content/switching-rules/aripiprazole-to-haloperidol.json';
import aripiprazoleToOlanzapine from '../content/switching-rules/aripiprazole-to-olanzapine.json';
import aripiprazoleToQuetiapine from '../content/switching-rules/aripiprazole-to-quetiapine.json';
import aripiprazoleToRisperidone from '../content/switching-rules/aripiprazole-to-risperidone.json';
import haloperidolLaiToAripiprazoleLai from '../content/switching-rules/haloperidol-lai-to-aripiprazole-lai.json';
import haloperidolLaiToPaliperidoneLai from '../content/switching-rules/haloperidol-lai-to-paliperidone-lai.json';
import haloperidolToAripiprazole from '../content/switching-rules/haloperidol-to-aripiprazole.json';
import haloperidolToHaloperidolLai from '../content/switching-rules/haloperidol-to-haloperidol-lai.json';
import haloperidolToOlanzapine from '../content/switching-rules/haloperidol-to-olanzapine.json';
import haloperidolToQuetiapine from '../content/switching-rules/haloperidol-to-quetiapine.json';
import haloperidolToRisperidone from '../content/switching-rules/haloperidol-to-risperidone.json';
import olanzapineToAripiprazoleLai from '../content/switching-rules/olanzapine-to-aripiprazole-lai.json';
import olanzapineToHaloperidol from '../content/switching-rules/olanzapine-to-haloperidol.json';
import olanzapineToQuetiapine from '../content/switching-rules/olanzapine-to-quetiapine.json';
import paliperidoneLaiToAripiprazoleLai from '../content/switching-rules/paliperidone-lai-to-aripiprazole-lai.json';
import quetiapineToHaloperidol from '../content/switching-rules/quetiapine-to-haloperidol.json';
import quetiapineToOlanzapine from '../content/switching-rules/quetiapine-to-olanzapine.json';
import quetiapineToPaliperidoneLai from '../content/switching-rules/quetiapine-to-paliperidone-lai.json';
import risperidoneLaiToAripiprazoleLai from '../content/switching-rules/risperidone-lai-to-aripiprazole-lai.json';
import risperidoneToHaloperidol from '../content/switching-rules/risperidone-to-haloperidol.json';
import risperidoneToPaliperidoneLai from '../content/switching-rules/risperidone-to-paliperidone-lai.json';
import olanzapineToAripiprazole from '../content/switching-rules/olanzapine-to-aripiprazole.json';
import olanzapineToRisperidone from '../content/switching-rules/olanzapine-to-risperidone.json';
import olanzapineToPaliperidoneLai from '../content/switching-rules/olanzapine-to-paliperidone-lai.json';
import quetiapineToAripiprazole from '../content/switching-rules/quetiapine-to-aripiprazole.json';
import quetiapineToAripiprazoleLai from '../content/switching-rules/quetiapine-to-aripiprazole-lai.json';
import quetiapineToRisperidone from '../content/switching-rules/quetiapine-to-risperidone.json';
import haloperidolToPaliperidoneLai from '../content/switching-rules/haloperidol-to-paliperidone-lai.json';
import risperidoneToAripiprazoleLai from '../content/switching-rules/risperidone-to-aripiprazole-lai.json';
import risperidoneLaiToAripiprazole from '../content/switching-rules/risperidone-lai-to-aripiprazole.json';
import risperidoneLaiToPaliperidoneLai from '../content/switching-rules/risperidone-lai-to-paliperidone-lai.json';
import risperidoneToAripiprazole from '../content/switching-rules/risperidone-to-aripiprazole.json';
import risperidoneToOlanzapine from '../content/switching-rules/risperidone-to-olanzapine.json';
import risperidoneToQuetiapine from '../content/switching-rules/risperidone-to-quetiapine.json';
import risperidoneToRisperidoneLai from '../content/switching-rules/risperidone-to-risperidone-lai.json';
import duloxetineToVenlafaxine from '../content/switching-rules/duloxetine-to-venlafaxine.json';
import escitalopramToFluoxetine from '../content/switching-rules/escitalopram-to-fluoxetine.json';
import escitalopramToSertraline from '../content/switching-rules/escitalopram-to-sertraline.json';
import escitalopramToVenlafaxine from '../content/switching-rules/escitalopram-to-venlafaxine.json';
import fluoxetineToEscitalopram from '../content/switching-rules/fluoxetine-to-escitalopram.json';
import fluoxetineToSertraline from '../content/switching-rules/fluoxetine-to-sertraline.json';
import mirtazapineToEscitalopram from '../content/switching-rules/mirtazapine-to-escitalopram.json';
import mirtazapineToSertraline from '../content/switching-rules/mirtazapine-to-sertraline.json';
import paroxetineToEscitalopram from '../content/switching-rules/paroxetine-to-escitalopram.json';
import paroxetineToFluoxetine from '../content/switching-rules/paroxetine-to-fluoxetine.json';
import paroxetineToSertraline from '../content/switching-rules/paroxetine-to-sertraline.json';
import sertralineToDuloxetine from '../content/switching-rules/sertraline-to-duloxetine.json';
import sertralineToEscitalopram from '../content/switching-rules/sertraline-to-escitalopram.json';
import sertralineToFluoxetine from '../content/switching-rules/sertraline-to-fluoxetine.json';
import sertralineToVenlafaxine from '../content/switching-rules/sertraline-to-venlafaxine.json';
import venlafaxineToDuloxetine from '../content/switching-rules/venlafaxine-to-duloxetine.json';
import venlafaxineToMirtazapine from '../content/switching-rules/venlafaxine-to-mirtazapine.json';
import venlafaxineToSertraline from '../content/switching-rules/venlafaxine-to-sertraline.json';
// Phase C6: amisulpride ↔ core APs + lurasidone (11 rules)
import amisulprideToOlanzapine from '../content/switching-rules/amisulpride-to-olanzapine.json';
import amisulprideToRisperidone from '../content/switching-rules/amisulpride-to-risperidone.json';
import amisulprideToQuetiapine from '../content/switching-rules/amisulpride-to-quetiapine.json';
import amisulprideToAripiprazole from '../content/switching-rules/amisulpride-to-aripiprazole.json';
import amisulprideToHaloperidol from '../content/switching-rules/amisulpride-to-haloperidol.json';
import amisulprideToLurasidone from '../content/switching-rules/amisulpride-to-lurasidone.json';
import olanzapineToAmisulpride from '../content/switching-rules/olanzapine-to-amisulpride.json';
import risperidoneToAmisulpride from '../content/switching-rules/risperidone-to-amisulpride.json';
import quetiapineToAmisulpride from '../content/switching-rules/quetiapine-to-amisulpride.json';
import aripiprazoleToAmisulpride from '../content/switching-rules/aripiprazole-to-amisulpride.json';
import haloperidolToAmisulpride from '../content/switching-rules/haloperidol-to-amisulpride.json';
// Phase C7: lurasidone ↔ core APs (10 rules)
import lurasidoneToOlanzapine from '../content/switching-rules/lurasidone-to-olanzapine.json';
import lurasidoneToRisperidone from '../content/switching-rules/lurasidone-to-risperidone.json';
import lurasidoneToQuetiapine from '../content/switching-rules/lurasidone-to-quetiapine.json';
import lurasidoneToAripiprazole from '../content/switching-rules/lurasidone-to-aripiprazole.json';
import lurasidoneToHaloperidol from '../content/switching-rules/lurasidone-to-haloperidol.json';
import olanzapineToLurasidone from '../content/switching-rules/olanzapine-to-lurasidone.json';
import risperidoneToLurasidone from '../content/switching-rules/risperidone-to-lurasidone.json';
import quetiapineToLurasidone from '../content/switching-rules/quetiapine-to-lurasidone.json';
import aripiprazoleToLurasidone from '../content/switching-rules/aripiprazole-to-lurasidone.json';
import haloperidolToLurasidone from '../content/switching-rules/haloperidol-to-lurasidone.json';
// Phase C8: FGA (chlorpromazine, sulpiride, trifluoperazine) → SGAs (12 rules)
import chlorpromazineToOlanzapine from '../content/switching-rules/chlorpromazine-to-olanzapine.json';
import chlorpromazineToRisperidone from '../content/switching-rules/chlorpromazine-to-risperidone.json';
import chlorpromazineToQuetiapine from '../content/switching-rules/chlorpromazine-to-quetiapine.json';
import chlorpromazineToAripiprazole from '../content/switching-rules/chlorpromazine-to-aripiprazole.json';
import sulpirideToOlanzapine from '../content/switching-rules/sulpiride-to-olanzapine.json';
import sulpirideToRisperidone from '../content/switching-rules/sulpiride-to-risperidone.json';
import sulpirideToQuetiapine from '../content/switching-rules/sulpiride-to-quetiapine.json';
import sulpirideToAripiprazole from '../content/switching-rules/sulpiride-to-aripiprazole.json';
import trifluoperazineToOlanzapine from '../content/switching-rules/trifluoperazine-to-olanzapine.json';
import trifluoperazineToRisperidone from '../content/switching-rules/trifluoperazine-to-risperidone.json';
import trifluoperazineToQuetiapine from '../content/switching-rules/trifluoperazine-to-quetiapine.json';
import trifluoperazineToAripiprazole from '../content/switching-rules/trifluoperazine-to-aripiprazole.json';
// Phase C9: mood stabilizer switching (10 new rules beyond existing LTG pairs)
import carbamazepineToLithium from '../content/switching-rules/carbamazepine-to-lithium.json';
import carbamazepineToValproate from '../content/switching-rules/carbamazepine-to-valproate.json';
import lamotrigineToCarbamazepine from '../content/switching-rules/lamotrigine-to-carbamazepine.json';
import lamotrigineToLithium from '../content/switching-rules/lamotrigine-to-lithium.json';
import lamotrigineToValproate from '../content/switching-rules/lamotrigine-to-valproate.json';
import lithiumToCarbamazepine from '../content/switching-rules/lithium-to-carbamazepine.json';
import lithiumToLamotrigine from '../content/switching-rules/lithium-to-lamotrigine.json';
import lithiumToValproate from '../content/switching-rules/lithium-to-valproate.json';
import valproateToCarbamazepine from '../content/switching-rules/valproate-to-carbamazepine.json';
import valproateToLithium from '../content/switching-rules/valproate-to-lithium.json';
// Phase C10: antidepressant rules for agomelatine, vortioxetine, desvenlafaxine (24 rules)
import agomelatineToEscitalopram from '../content/switching-rules/agomelatine-to-escitalopram.json';
import agomelatineToMirtazapine from '../content/switching-rules/agomelatine-to-mirtazapine.json';
import agomelatineToSertraline from '../content/switching-rules/agomelatine-to-sertraline.json';
import agomelatineToVenlafaxine from '../content/switching-rules/agomelatine-to-venlafaxine.json';
import desvenlafaxineToEscitalopram from '../content/switching-rules/desvenlafaxine-to-escitalopram.json';
import desvenlafaxineToMirtazapine from '../content/switching-rules/desvenlafaxine-to-mirtazapine.json';
import desvenlafaxineToSertraline from '../content/switching-rules/desvenlafaxine-to-sertraline.json';
import desvenlafaxineToVenlafaxine from '../content/switching-rules/desvenlafaxine-to-venlafaxine.json';
import escitalopramToAgomelatine from '../content/switching-rules/escitalopram-to-agomelatine.json';
import escitalopramToDesvenlafaxine from '../content/switching-rules/escitalopram-to-desvenlafaxine.json';
import escitalopramToVortioxetine from '../content/switching-rules/escitalopram-to-vortioxetine.json';
import mirtazapineToAgomelatine from '../content/switching-rules/mirtazapine-to-agomelatine.json';
import mirtazapineToDesvenlafaxine from '../content/switching-rules/mirtazapine-to-desvenlafaxine.json';
import mirtazapineToVortioxetine from '../content/switching-rules/mirtazapine-to-vortioxetine.json';
import sertralineToAgomelatine from '../content/switching-rules/sertraline-to-agomelatine.json';
import sertralineToDesvenlafaxine from '../content/switching-rules/sertraline-to-desvenlafaxine.json';
import sertralineToVortioxetine from '../content/switching-rules/sertraline-to-vortioxetine.json';
import venlafaxineToAgomelatine from '../content/switching-rules/venlafaxine-to-agomelatine.json';
import venlafaxineToDesvenlafaxine from '../content/switching-rules/venlafaxine-to-desvenlafaxine.json';
import venlafaxineToVortioxetine from '../content/switching-rules/venlafaxine-to-vortioxetine.json';
import vortioxetineToEscitalopram from '../content/switching-rules/vortioxetine-to-escitalopram.json';
import vortioxetineToMirtazapine from '../content/switching-rules/vortioxetine-to-mirtazapine.json';
import vortioxetineToSertraline from '../content/switching-rules/vortioxetine-to-sertraline.json';
import vortioxetineToVenlafaxine from '../content/switching-rules/vortioxetine-to-venlafaxine.json';
// Phase C11: LAI → oral (same drug) switching rules (7 rules)
import aripiprazoleLaiToAripiprazole from '../content/switching-rules/aripiprazole-lai-to-aripiprazole.json';
import flupenthixolLaiToFlupenthixol from '../content/switching-rules/flupenthixol-lai-to-flupenthixol.json';
import fluphenazineLaiToFluphenazine from '../content/switching-rules/fluphenazine-lai-to-fluphenazine.json';
import haloperidolLaiToHaloperidol from '../content/switching-rules/haloperidol-lai-to-haloperidol.json';
import paliperidoneLaiToPaliperidone from '../content/switching-rules/paliperidone-lai-to-paliperidone.json';
import risperidoneLaiToRisperidone from '../content/switching-rules/risperidone-lai-to-risperidone.json';
import zuclopenthixolLaiToZuclopenthixol from '../content/switching-rules/zuclopenthixol-lai-to-zuclopenthixol.json';
import { lookupMaudsley15Strategy } from './maudsley15';
import type { Drug, SwitchInput, SwitchPlan, SwitchingRule } from './types';

// Drug registry — explicit list, no auto-discovery. v0.1 ships all 8
// antidepressants in scope as JSON skeletons. Every clinical field is
// marked `PENDING_CLINICAL_REVIEW` until the clinical author signs off.
//
// The `as unknown as Drug` cast is necessary because TypeScript infers
// `number[]` from JSON arrays, but our `Drug` type uses fixed-length
// tuples (e.g. `[number, number]` for halfLife.rangeHours) for clarity.
// At runtime the shapes match exactly — these are literally the same
// JSON files used as the schema reference.
const DRUGS: Drug[] = [
  // Antidepressants (11) — SSRIs, SNRIs, NaSSA, multimodal, melatonergic.
  // MAOIs (3 below) are kept in the registry for MAOI hard-block logic
  // but marked hidden=true so they do not appear in the drug picker.
  fluoxetine as unknown as Drug,
  sertraline as unknown as Drug,
  escitalopram as unknown as Drug,
  paroxetine as unknown as Drug,
  fluvoxamine as unknown as Drug,
  venlafaxine as unknown as Drug,
  duloxetine as unknown as Drug,
  desvenlafaxine as unknown as Drug,
  mirtazapine as unknown as Drug,
  vortioxetine as unknown as Drug,
  agomelatine as unknown as Drug,
  // MAOIs (3) — hidden from picker (not used in Malaysian practice) but
  // retained for MAOI safety-block logic and rule lookups.
  moclobemide as unknown as Drug,
  phenelzine as unknown as Drug,
  tranylcypromine as unknown as Drug,
  // Antipsychotics oral — SGAs (6) + clozapine + newer SGAs (2) + FGAs (3).
  // Clozapine is in the registry but routes to the dedicated module.
  olanzapine as unknown as Drug,
  risperidone as unknown as Drug,
  quetiapine as unknown as Drug,
  aripiprazole as unknown as Drug,
  amisulpride as unknown as Drug,
  lurasidone as unknown as Drug,
  haloperidol as unknown as Drug,
  chlorpromazine as unknown as Drug,
  trifluoperazine as unknown as Drug,
  sulpiride as unknown as Drug,
  clozapine as unknown as Drug,
  // Mood stabilizers (4).
  lithium as unknown as Drug,
  valproate as unknown as Drug,
  lamotrigine as unknown as Drug,
  carbamazepine as unknown as Drug,
  // Antipsychotic LAIs — SGA depots (3 visible) + FGA depots (3 visible)
  // + 2 hidden (haloperidol-lai, risperidone-lai — removed from picker).
  paliperidoneLai as unknown as Drug,
  aripiprazoleLai as unknown as Drug,
  zuclopenthixolLai as unknown as Drug,
  flupenthixolLai as unknown as Drug,
  fluphenazineLai as unknown as Drug,
  // Hidden LAIs — kept for rule lookups and safety-flag derivation.
  risperidoneLai as unknown as Drug,
  haloperidolLai as unknown as Drug,
  // Hidden oral FGAs + paliperidone — targets for LAI-to-oral switching rules.
  // Not shown in the drug picker (hidden:true in JSON) but needed for rule lookups.
  paliperidone as unknown as Drug,
  flupenthixol as unknown as Drug,
  fluphenazine as unknown as Drug,
  zuclopenthixol as unknown as Drug,
];

// Switching-rule registry — explicit list. We intentionally do NOT derive
// reverse rules automatically: pharmacokinetics are not symmetric. For
// example, fluoxetine has a long active metabolite (norfluoxetine, ~7-9
// days half-life), so escitalopram → fluoxetine is NOT the mirror image
// of fluoxetine → escitalopram. Each direction must be reviewed separately.
const RULES: SwitchingRule[] = [
  // First five rules drafted in phases A and B2.
  sertralineToEscitalopram as unknown as SwitchingRule,
  paroxetineToSertraline as unknown as SwitchingRule,
  venlafaxineToDuloxetine as unknown as SwitchingRule,
  sertralineToFluoxetine as unknown as SwitchingRule,
  mirtazapineToSertraline as unknown as SwitchingRule,
  // Phase B5 round 1: 8 high-frequency clinical pairs.
  fluoxetineToSertraline as unknown as SwitchingRule,
  fluoxetineToEscitalopram as unknown as SwitchingRule,
  paroxetineToEscitalopram as unknown as SwitchingRule,
  paroxetineToFluoxetine as unknown as SwitchingRule,
  escitalopramToSertraline as unknown as SwitchingRule,
  venlafaxineToSertraline as unknown as SwitchingRule,
  sertralineToVenlafaxine as unknown as SwitchingRule,
  duloxetineToSertraline as unknown as SwitchingRule,
  // Phase B5 round 2: 6 next-tier pairs.
  escitalopramToFluoxetine as unknown as SwitchingRule,
  sertralineToDuloxetine as unknown as SwitchingRule,
  mirtazapineToEscitalopram as unknown as SwitchingRule,
  duloxetineToVenlafaxine as unknown as SwitchingRule,
  escitalopramToVenlafaxine as unknown as SwitchingRule,
  venlafaxineToMirtazapine as unknown as SwitchingRule,
  // Phase B8: antipsychotic switching (oral-oral, oral-LAI, LAI-oral,
  // LAI-LAI). Original 8 rules plus 12 new rules added in phase B8b.
  // Oral-oral — all 20 pairs among 5 oral APs (complete matrix):
  olanzapineToAripiprazole as unknown as SwitchingRule,
  olanzapineToRisperidone as unknown as SwitchingRule,
  olanzapineToQuetiapine as unknown as SwitchingRule,
  olanzapineToHaloperidol as unknown as SwitchingRule,
  risperidoneToAripiprazole as unknown as SwitchingRule,
  risperidoneToOlanzapine as unknown as SwitchingRule,
  risperidoneToQuetiapine as unknown as SwitchingRule,
  risperidoneToHaloperidol as unknown as SwitchingRule,
  quetiapineToAripiprazole as unknown as SwitchingRule,
  quetiapineToRisperidone as unknown as SwitchingRule,
  quetiapineToOlanzapine as unknown as SwitchingRule,
  quetiapineToHaloperidol as unknown as SwitchingRule,
  haloperidolToOlanzapine as unknown as SwitchingRule,
  haloperidolToRisperidone as unknown as SwitchingRule,
  haloperidolToQuetiapine as unknown as SwitchingRule,
  haloperidolToAripiprazole as unknown as SwitchingRule,
  aripiprazoleToQuetiapine as unknown as SwitchingRule,
  aripiprazoleToOlanzapine as unknown as SwitchingRule,
  aripiprazoleToRisperidone as unknown as SwitchingRule,
  aripiprazoleToHaloperidol as unknown as SwitchingRule,
  // Oral-to-LAI (10 rules):
  risperidoneToRisperidoneLai as unknown as SwitchingRule,
  risperidoneToPaliperidoneLai as unknown as SwitchingRule,
  risperidoneToAripiprazoleLai as unknown as SwitchingRule,
  aripiprazoleToAripiprazoleLai as unknown as SwitchingRule,
  olanzapineToPaliperidoneLai as unknown as SwitchingRule,
  olanzapineToAripiprazoleLai as unknown as SwitchingRule,
  quetiapineToPaliperidoneLai as unknown as SwitchingRule,
  quetiapineToAripiprazoleLai as unknown as SwitchingRule,
  haloperidolToHaloperidolLai as unknown as SwitchingRule,
  haloperidolToPaliperidoneLai as unknown as SwitchingRule,
  // LAI-oral (1 rule):
  risperidoneLaiToAripiprazole as unknown as SwitchingRule,
  // LAI-LAI (7 rules):
  risperidoneLaiToPaliperidoneLai as unknown as SwitchingRule,
  risperidoneLaiToAripiprazoleLai as unknown as SwitchingRule,
  haloperidolLaiToRisperidoneLai as unknown as SwitchingRule,
  haloperidolLaiToPaliperidoneLai as unknown as SwitchingRule,
  haloperidolLaiToAripiprazoleLai as unknown as SwitchingRule,
  aripiprazoleLaiToPaliperidoneLai as unknown as SwitchingRule,
  paliperidoneLaiToAripiprazoleLai as unknown as SwitchingRule,
  // Phase C5: mood stabilizer switching (pharmacokinetically complex LTG
  // transitions — CBZ withdrawal raises LTG, VPA withdrawal lowers it).
  carbamazepineToLamotrigine as unknown as SwitchingRule,
  valproateToLamotrigine as unknown as SwitchingRule,
  // Phase C6: amisulpride ↔ core APs + lurasidone
  amisulprideToOlanzapine as unknown as SwitchingRule,
  amisulprideToRisperidone as unknown as SwitchingRule,
  amisulprideToQuetiapine as unknown as SwitchingRule,
  amisulprideToAripiprazole as unknown as SwitchingRule,
  amisulprideToHaloperidol as unknown as SwitchingRule,
  amisulprideToLurasidone as unknown as SwitchingRule,
  olanzapineToAmisulpride as unknown as SwitchingRule,
  risperidoneToAmisulpride as unknown as SwitchingRule,
  quetiapineToAmisulpride as unknown as SwitchingRule,
  aripiprazoleToAmisulpride as unknown as SwitchingRule,
  haloperidolToAmisulpride as unknown as SwitchingRule,
  // Phase C7: lurasidone ↔ core APs
  lurasidoneToOlanzapine as unknown as SwitchingRule,
  lurasidoneToRisperidone as unknown as SwitchingRule,
  lurasidoneToQuetiapine as unknown as SwitchingRule,
  lurasidoneToAripiprazole as unknown as SwitchingRule,
  lurasidoneToHaloperidol as unknown as SwitchingRule,
  olanzapineToLurasidone as unknown as SwitchingRule,
  risperidoneToLurasidone as unknown as SwitchingRule,
  quetiapineToLurasidone as unknown as SwitchingRule,
  aripiprazoleToLurasidone as unknown as SwitchingRule,
  haloperidolToLurasidone as unknown as SwitchingRule,
  // Phase C8: FGA → SGA switches
  chlorpromazineToOlanzapine as unknown as SwitchingRule,
  chlorpromazineToRisperidone as unknown as SwitchingRule,
  chlorpromazineToQuetiapine as unknown as SwitchingRule,
  chlorpromazineToAripiprazole as unknown as SwitchingRule,
  sulpirideToOlanzapine as unknown as SwitchingRule,
  sulpirideToRisperidone as unknown as SwitchingRule,
  sulpirideToQuetiapine as unknown as SwitchingRule,
  sulpirideToAripiprazole as unknown as SwitchingRule,
  trifluoperazineToOlanzapine as unknown as SwitchingRule,
  trifluoperazineToRisperidone as unknown as SwitchingRule,
  trifluoperazineToQuetiapine as unknown as SwitchingRule,
  trifluoperazineToAripiprazole as unknown as SwitchingRule,
  // Phase C9: full mood stabilizer switching matrix
  carbamazepineToLithium as unknown as SwitchingRule,
  carbamazepineToValproate as unknown as SwitchingRule,
  lamotrigineToCarbamazepine as unknown as SwitchingRule,
  lamotrigineToLithium as unknown as SwitchingRule,
  lamotrigineToValproate as unknown as SwitchingRule,
  lithiumToCarbamazepine as unknown as SwitchingRule,
  lithiumToLamotrigine as unknown as SwitchingRule,
  lithiumToValproate as unknown as SwitchingRule,
  valproateToCarbamazepine as unknown as SwitchingRule,
  valproateToLithium as unknown as SwitchingRule,
  // Phase C10: agomelatine, vortioxetine, desvenlafaxine antidepressant rules
  agomelatineToEscitalopram as unknown as SwitchingRule,
  agomelatineToMirtazapine as unknown as SwitchingRule,
  agomelatineToSertraline as unknown as SwitchingRule,
  agomelatineToVenlafaxine as unknown as SwitchingRule,
  desvenlafaxineToEscitalopram as unknown as SwitchingRule,
  desvenlafaxineToMirtazapine as unknown as SwitchingRule,
  desvenlafaxineToSertraline as unknown as SwitchingRule,
  desvenlafaxineToVenlafaxine as unknown as SwitchingRule,
  escitalopramToAgomelatine as unknown as SwitchingRule,
  escitalopramToDesvenlafaxine as unknown as SwitchingRule,
  escitalopramToVortioxetine as unknown as SwitchingRule,
  mirtazapineToAgomelatine as unknown as SwitchingRule,
  mirtazapineToDesvenlafaxine as unknown as SwitchingRule,
  mirtazapineToVortioxetine as unknown as SwitchingRule,
  sertralineToAgomelatine as unknown as SwitchingRule,
  sertralineToDesvenlafaxine as unknown as SwitchingRule,
  sertralineToVortioxetine as unknown as SwitchingRule,
  venlafaxineToAgomelatine as unknown as SwitchingRule,
  venlafaxineToDesvenlafaxine as unknown as SwitchingRule,
  venlafaxineToVortioxetine as unknown as SwitchingRule,
  vortioxetineToEscitalopram as unknown as SwitchingRule,
  vortioxetineToMirtazapine as unknown as SwitchingRule,
  vortioxetineToSertraline as unknown as SwitchingRule,
  vortioxetineToVenlafaxine as unknown as SwitchingRule,
  // Phase C11: LAI → oral (same-drug depot discontinuation), 7 rules
  aripiprazoleLaiToAripiprazole as unknown as SwitchingRule,
  flupenthixolLaiToFlupenthixol as unknown as SwitchingRule,
  fluphenazineLaiToFluphenazine as unknown as SwitchingRule,
  haloperidolLaiToHaloperidol as unknown as SwitchingRule,
  paliperidoneLaiToPaliperidone as unknown as SwitchingRule,
  risperidoneLaiToRisperidone as unknown as SwitchingRule,
  zuclopenthixolLaiToZuclopenthixol as unknown as SwitchingRule,
];

/**
 * Synthesise cross-category guidance when the Maudsley matrix has no entry.
 *
 * The matrix covers within-category pairs (AD↔AD, MS↔MS, AP↔AP). For pairs
 * that cross therapeutic categories (AD↔AP, MS↔AP, AD↔MS) no matrix entry
 * exists — but these combinations do occur clinically and should return
 * something useful rather than a bare no_rule.
 *
 * Returns null only when both drugs are the same category — which means
 * something is missing from the matrix rather than being a cross-category pair.
 */
function generateCrossCategoryGuidance(
  fromDrug: Drug,
  toDrug: Drug,
): import('./types').Maudsley15Guidance | null {
  const fromCat = fromDrug.category ?? 'antidepressant';
  const toCat = toDrug.category ?? 'antidepressant';

  if (fromCat === toCat) return null; // same category — matrix should cover it

  // AD ↔ AP
  if (
    (fromCat === 'antidepressant' && toCat === 'antipsychotic') ||
    (fromCat === 'antipsychotic' && toCat === 'antidepressant')
  ) {
    return {
      strategy: 'special',
      headline: 'Different therapeutic targets — not a standard switch',
      detail:
        'Antidepressants and antipsychotics serve different primary indications. ' +
        'Selecting one drug from each class usually represents an augmentation or ' +
        'de-escalation decision rather than a direct switch. If stopping an antidepressant ' +
        'while starting an antipsychotic (e.g. transitioning from unipolar depression to a ' +
        'first episode of psychosis), taper the antidepressant using its own discontinuation ' +
        'risk profile — do not abruptly stop high-discontinuation-risk agents such as paroxetine, ' +
        'venlafaxine or desvenlafaxine. If adding an antipsychotic as augmentation for ' +
        'treatment-resistant depression, this is a combination decision — the antidepressant ' +
        'is typically continued. Consult Maudsley 15th depression and psychosis chapters for the ' +
        'specific condition being treated.',
      citations: [
        'maudsley15_ch3_general_principles',
        'maudsley15_schizophrenia_p231',
      ],
    };
  }

  // AP ↔ MS
  if (
    (fromCat === 'antipsychotic' && toCat === 'mood-stabilizer') ||
    (fromCat === 'mood-stabilizer' && toCat === 'antipsychotic')
  ) {
    return {
      strategy: 'cross_taper_cautiously',
      headline:
        'Cross-taper cautiously — antipsychotics and mood stabilisers are often co-prescribed in bipolar disorder',
      detail:
        'Antipsychotics and mood stabilisers are frequently co-prescribed for acute mania and ' +
        'bipolar maintenance. If stopping one while maintaining the other, taper the drug being ' +
        'stopped slowly. Antipsychotics should be tapered over 4–8 weeks to avoid rebound ' +
        'psychosis — abrupt discontinuation carries significant risk. Mood stabilisers have their ' +
        'own pharmacokinetic considerations: carbamazepine is an enzyme inducer (levels of the ' +
        'antipsychotic may be affected), and valproate inhibits some metabolic pathways. Consult ' +
        'Maudsley 15th bipolar disorder chapters for evidence-based sequencing and dose monitoring.',
      citations: [
        'maudsley15_bipolar_ch5_switching',
        'bap2016_bipolar',
      ],
    };
  }

  // AD ↔ MS
  if (
    (fromCat === 'antidepressant' && toCat === 'mood-stabilizer') ||
    (fromCat === 'mood-stabilizer' && toCat === 'antidepressant')
  ) {
    return {
      strategy: 'cross_taper_cautiously',
      headline:
        'Cross-taper cautiously — consider the underlying diagnosis when switching between these classes',
      detail:
        'Antidepressants and mood stabilisers are prescribed for different primary conditions. ' +
        'In bipolar disorder, antidepressants are often tapered once mood stabilisation is ' +
        'established — abrupt discontinuation carries a discontinuation syndrome risk (especially ' +
        'paroxetine, venlafaxine, desvenlafaxine). Mood stabilisers should generally not be ' +
        'stopped abruptly — lamotrigine withdrawal can trigger rebound seizures; lithium ' +
        'discontinuation risks rebound mania; valproate and carbamazepine have their own ' +
        'kinetics. If the patient is moving from an antidepressant to a mood stabiliser for ' +
        'a new bipolar diagnosis, ensure the mood stabiliser is at a therapeutic level before ' +
        'reducing the antidepressant. Consult Maudsley 15th bipolar and depression chapters.',
      citations: [
        'maudsley15_bipolar_ch5_switching',
        'maudsley15_ch3_general_principles',
      ],
    };
  }

  return null;
}

/**
 * Generate a cross-taper plan for the given switch input.
 *
 * Returns:
 *  - `{ status: 'maoi_washout', ... }` whenever an MAOI is on either
 *    side of the switch. Cross-tapering serotonergic drugs with an MAOI
 *    risks serotonin syndrome — washout is the only safe strategy.
 *    THIS CHECK RUNS FIRST, before any rule lookup, by design.
 *  - `{ status: 'ok', ... }` when a reviewed rule exists for this pair
 *    AND the requested doses match the rule's reviewed reference doses.
 *  - `{ status: 'no_rule', reason }` when no rule exists for this pair.
 *  - `{ status: 'dose_out_of_range', reason }` when a rule exists but
 *    the requested doses are outside the reviewed range. The UI should
 *    surface this clearly and direct the clinician to primary references.
 */
export function generateSwitchPlan(input: SwitchInput): SwitchPlan {
  const fromDrug = getDrug(input.fromDrugId);
  const toDrug = getDrug(input.toDrugId);

  // ──────────────────────────────────────────────────────────────────
  // CLOZAPINE REDIRECT — runs before MAOI block and rule lookup.
  //
  // Switching TO clozapine is a treatment-resistant initiation decision.
  // There is no meaningful "cross-taper" — the clozapine titration
  // schedule is started while the prior antipsychotic is gradually
  // withdrawn in parallel (the "overlap and taper" strategy). The timing
  // and speed of that taper depends on individual patient factors that
  // cannot be encoded in a single rule. Route to the dedicated module.
  // ──────────────────────────────────────────────────────────────────
  if (toDrug?.id === 'clozapine') {
    return {
      status: 'clozapine_redirect',
      fromDrugName: fromDrug?.genericName ?? input.fromDrugId,
      reason:
        'Clozapine initiation is a specialist decision for treatment-resistant schizophrenia. A standard cross-taper rule cannot safely capture the full overlap-and-taper strategy.',
      guidance:
        'Use the Clozapine module (accessible from the Home screen) for the full titration protocol. Continue the current antipsychotic in parallel during titration, then taper and stop once clozapine is established at the therapeutic dose. The speed of the taper depends on clinical response. Consult Maudsley 14th edition chapter on clozapine initiation.',
    };
  }

  // ──────────────────────────────────────────────────────────────────
  // MAOI HARD-BLOCK — runs before any rule lookup.
  // Any switch involving an MAOI uses washout strategy, never a
  // cross-taper, regardless of what rules exist. This is the highest-
  // stakes safety logic in the engine. Do NOT add a "but if a rule says
  // otherwise" branch here — there is no clinical scenario in v0.1
  // where overlapping a serotonergic drug with an MAOI is acceptable.
  // ──────────────────────────────────────────────────────────────────
  if (fromDrug && toDrug && (fromDrug.isMAOI || toDrug.isMAOI)) {
    return computeMaoiWashout(fromDrug, toDrug);
  }

  const rule = RULES.find(
    (r) => r.fromDrugId === input.fromDrugId && r.toDrugId === input.toDrugId,
  );

  // ──────────────────────────────────────────────────────────────────
  // NO SPECIFIC RULE → consult the Maudsley 15th strategy matrix,
  // then fall back to category-derived cross-taper guidance.
  //
  // Three-tier fallback:
  //   1. Specific reviewed rule  (ok)
  //   2. Maudsley 15th matrix    (maudsley_guidance — class-level)
  //   3. Category-derived        (maudsley_guidance — synthesised from
  //      drug categories; handles cross-category pairs like AD↔AP
  //      without requiring a matrix entry for every combination)
  //   4. no_rule                 (only if drug IDs are unregistered)
  // ──────────────────────────────────────────────────────────────────
  if (!rule) {
    if (fromDrug && toDrug) {
      const guidance =
        lookupMaudsley15Strategy(fromDrug, toDrug) ??
        generateCrossCategoryGuidance(fromDrug, toDrug);
      if (guidance) {
        return {
          status: 'maudsley_guidance',
          guidance,
          safetyFlags: deriveSafetyFlags(fromDrug, toDrug),
          fromDrugName: fromDrug.genericName,
          toDrugName: toDrug.genericName,
        };
      }
    }
    return {
      status: 'no_rule',
      reason: `No reviewed rule exists for ${input.fromDrugId} → ${input.toDrugId}. One or both drug IDs may be unregistered.`,
    };
  }

  // ──────────────────────────────────────────────────────────────────
  // SPECIFIC RULE EXISTS → always return its schedule. Mark whether the
  // input doses match the rule's reviewed reference doses. The UI
  // surfaces a "reference doses" banner when they don't, so the
  // clinician treats the schedule as an example to adapt rather than
  // a precise prescription.
  //
  // This is a deliberate change from the original strict dose-matching
  // behaviour: Maudsley itself works with reference schedules and
  // proportional adjustments, not exhaustive dose-pair matrices.
  // ──────────────────────────────────────────────────────────────────
  const dosesMatchReference =
    input.fromDoseMg === rule.doseRatios.fromCurrentDoseMg &&
    input.toDoseMg === rule.doseRatios.toTargetDoseMg;

  // Merge the rule's hand-curated safety flags with flags derived from
  // the drug profiles. Rule authors don't have to remember to add e.g.
  // discontinuation_syndrome_high every time paroxetine is the from-drug
  // — the engine attaches it automatically. The Set dedupes so a flag
  // already on the rule isn't shown twice.
  const derived =
    fromDrug && toDrug ? deriveSafetyFlags(fromDrug, toDrug) : [];
  const mergedFlags = Array.from(new Set([...rule.safetyFlags, ...derived]));

  return {
    status: 'ok',
    rule,
    schedule: rule.schedule,
    safetyFlags: mergedFlags,
    citations: rule.citations,
    dosesMatchReference,
    inputDoses: { fromMg: input.fromDoseMg, toMg: input.toDoseMg },
  };
}

/**
 * Compute an MAOI-involved switch. Always a washout — never a cross-taper.
 *
 * Two directions:
 *  - `to_maoi`: stopping a non-MAOI antidepressant before starting an MAOI.
 *    Washout duration comes from the from-drug's `maoiWashout.daysOffBeforeMAOI`
 *    (14 days for most SSRIs/SNRIs; 35 days for fluoxetine because of
 *    norfluoxetine).
 *  - `from_maoi`: stopping an MAOI before starting a non-MAOI antidepressant.
 *    Washout duration comes from the MAOI's own `maoiClearanceDays`
 *    (~1 day for moclobemide, 14 days for irreversible MAOIs).
 *
 * For MAOI-to-MAOI (both sides MAOI) v0.1 returns no_rule — that switch
 * is rare and specialist; we don't auto-handle it.
 */
function computeMaoiWashout(fromDrug: Drug, toDrug: Drug): SwitchPlan {
  if (fromDrug.isMAOI && toDrug.isMAOI) {
    return {
      status: 'no_rule',
      reason: `MAOI-to-MAOI switches (${fromDrug.genericName} → ${toDrug.genericName}) are specialist decisions and not automated in v0.1. Consult primary references.`,
    };
  }

  if (toDrug.isMAOI) {
    // Going TO an MAOI: the from-drug's clearance dictates washout.
    // If the from-drug is an antipsychotic without MAOI-specific data,
    // fall back to the conservative 14-day SSRI/SNRI default.
    const washoutDays = fromDrug.maoiWashout?.daysOffBeforeMAOI ?? 14;
    const washoutFlag =
      washoutDays >= 28
        ? 'maoi_washout_required_5_week'
        : 'maoi_washout_required_14_day';
    return {
      status: 'maoi_washout',
      direction: 'to_maoi',
      washoutDays,
      reason: `Switching to ${toDrug.genericName} (MAOI) requires ${washoutDays} days off ${fromDrug.genericName} to avoid serotonin syndrome.`,
      safetyFlags: Array.from(
        new Set([washoutFlag, ...deriveSafetyFlags(fromDrug, toDrug)]),
      ),
    };
  }

  // Going FROM an MAOI to a non-MAOI: the MAOI's own clearance dictates.
  // Reversible MAOIs (moclobemide) clear in ~24h; irreversible MAOIs
  // need 14 days. Default to 14 if profile data missing.
  const washoutDays = fromDrug.maoiClearanceDays ?? 14;
  return {
    status: 'maoi_washout',
    direction: 'from_maoi',
    washoutDays,
    reason: `Switching from ${fromDrug.genericName} requires ${washoutDays} day(s) clearance before starting ${toDrug.genericName} to avoid serotonin syndrome.`,
    safetyFlags: Array.from(
      new Set(['maoi_clearance_required', ...deriveSafetyFlags(fromDrug, toDrug)]),
    ),
  };
}

/**
 * Derive safety flags from drug profiles only — no rule needed.
 *
 * This lets the UI surface profile-driven warnings even when no reviewed
 * cross-taper rule exists (no_rule path). It also frees rule authors from
 * having to remember to repeat the same warnings on every rule.
 *
 * Exported separately so it can be unit-tested in isolation.
 */
export function deriveSafetyFlags(fromDrug: Drug, toDrug: Drug): string[] {
  const flags: string[] = [];

  // High discontinuation syndrome risk on the from-drug. Currently
  // applies to paroxetine (very high), venlafaxine (very high) and
  // duloxetine (high). Slow taper essential.
  // Optional access — antipsychotics use `reboundPsychosisRisk` instead
  // and may legitimately omit `discontinuationSyndromeRisk`.
  const discScore = fromDrug.discontinuationSyndromeRisk?.score;
  if (discScore === 'high' || discScore === 'very high') {
    flags.push('discontinuation_syndrome_high');
  }

  // Paroxetine has notable anticholinergic activity and produces
  // cholinergic rebound on abrupt cessation. Drug-specific check rather
  // than a class check, because no other v0.1 drug has comparable
  // anticholinergic load.
  if (fromDrug.id === 'paroxetine') {
    flags.push('anticholinergic_rebound');
  }

  // Serotonin-syndrome overlap risk during cross-taper. v0.1 flags this
  // when both drugs have direct serotonergic activity (SSRI/SNRI).
  // Mirtazapine (NaSSA) is intentionally excluded from this auto-check —
  // it does have indirect serotonergic activity, but mirtazapine + SSRI
  // is a common deliberate augmentation strategy and a low-risk overlap;
  // surface that risk through rule-level flags rather than auto-flagging.
  const SEROTONERGIC = new Set(['SSRI', 'SNRI']);
  if (SEROTONERGIC.has(fromDrug.drugClass) && SEROTONERGIC.has(toDrug.drugClass)) {
    flags.push('serotonin_syndrome_overlap_low');
  }

  // ── Antipsychotic-specific derivations ─────────────────────────────

  // Cholinergic rebound on stopping a strongly anticholinergic AP.
  // Drug-specific check (olanzapine, quetiapine) — same pattern as the
  // paroxetine anticholinergic check above. Skip when the new drug is
  // also strongly anticholinergic (overlap covers the rebound).
  const ANTICHOLINERGIC_AP = new Set(['olanzapine', 'quetiapine']);
  if (
    ANTICHOLINERGIC_AP.has(fromDrug.id) &&
    !ANTICHOLINERGIC_AP.has(toDrug.id)
  ) {
    flags.push('cholinergic_rebound');
  }

  // Akathisia warning when switching INTO aripiprazole, especially from
  // a full D2 antagonist (everything else in v0.2 except moclobemide).
  if (toDrug.id === 'aripiprazole' || toDrug.id === 'aripiprazole-lai') {
    flags.push('akathisia_risk_aripiprazole');
  }

  // Prolactin normalisation when leaving a high-prolactin agent for
  // a low-prolactin agent. Counseling-grade (info severity), not a
  // safety warning.
  if (
    fromDrug.prolactinRisk === 'high' &&
    toDrug.prolactinRisk &&
    toDrug.prolactinRisk !== 'high'
  ) {
    flags.push('prolactin_normalisation');
  }

  // Long depot washout when the from-drug is an LAI. Residual depot
  // matters whether or not the next drug is also LAI.
  if (fromDrug.formulation === 'lai') {
    flags.push('depot_washout_long');
  }

  // Oral overlap warning when the destination LAI's loading protocol
  // requires it. NOT every LAI does — paliperidone palmitate's deltoid
  // loading replaces the need for oral overlap, while risperidone Consta,
  // aripiprazole Maintena and haloperidol decanoate all do need it. The
  // `laiDetails.needsOralOverlap` field is the source of truth.
  if (toDrug.formulation === 'lai' && toDrug.laiDetails?.needsOralOverlap) {
    flags.push('lai_initiation_oral_overlap');
  }

  // QTc additive overlap: both drugs have non-trivial QTc risk during
  // cross-taper. Highest concern is haloperidol (high) + quetiapine
  // (moderate) — the combination is flagged automatically so the clinician
  // is prompted to check baseline ECG and consider a mid-taper repeat.
  const QTC_RISK_LEVELS: Record<string, number> = { low: 0, moderate: 1, high: 2 };
  const fromQtc = QTC_RISK_LEVELS[fromDrug.qtcRisk ?? 'low'] ?? 0;
  const toQtc   = QTC_RISK_LEVELS[toDrug.qtcRisk   ?? 'low'] ?? 0;
  if (fromQtc >= 2 && toQtc >= 1) {
    // from=high + to=moderate or to=high
    flags.push('qtc_additive_overlap');
  }

  // Metabolic monitoring reminder when switching INTO a high-metabolic-
  // risk agent from a lower-metabolic-risk agent. Captures olanzapine and
  // high-dose quetiapine as targets when coming from something metabolically
  // lighter (risperidone, haloperidol, aripiprazole).
  if (
    toDrug.metabolicRisk?.score === 'very high' &&
    fromDrug.metabolicRisk?.score !== 'very high'
  ) {
    flags.push('metabolic_monitoring_required');
  }

  return flags;
}

/** Look up a drug record by id. Searches ALL drugs including hidden ones
 *  (needed for MAOI safety checks and LAI rule lookups). */
export function getDrug(id: string): Drug | undefined {
  return DRUGS.find((d) => d.id === id);
}

/** Return drugs visible in the picker — excludes hidden entries (MAOIs,
 *  deprecated LAI formulations). Use this for any UI drug list. */
export function listDrugs(): Drug[] {
  return DRUGS.filter((d) => !d.hidden);
}

/** Return ALL registered drugs including hidden — for tests and admin. */
export function listAllDrugs(): Drug[] {
  return DRUGS;
}

/** Return all reviewed switching rules in v0.1. */
export function listRules(): SwitchingRule[] {
  return RULES;
}
