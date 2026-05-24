// App router — go_router config.
//
// Top-level routes:
//   /         → Home
//   /switch   → Switch wizard (drug pickers + dose inputs)
//   /result   → Result screen (schedule, safety flags, citations)
//   /history  → Saved cases list
//   /glossary → Clinical-term lookup
//   /settings → Toggles + destructive actions
//   /about    → Version, stats, licenses
//   /clozapine→ Clozapine module (5 tabs)
//   /depot    → Depot LAI index, with /:id detail children
//
// Routes are typed via `name` constants so screens never hard-code
// path strings.
//
// Every route uses [_fadeThroughPage] so navigation feels smooth and
// brand-cohesive instead of the platform-default slide. The transition
// auto-disables when MediaQuery.disableAnimations is true (system
// reduced-motion preference) — accessibility-correct without ceremony.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:psychswitch/src/ui/screens/about_screen.dart';
import 'package:psychswitch/src/ui/screens/adverse_effects_screen.dart';
import 'package:psychswitch/src/ui/screens/agitation_screen.dart';
import 'package:psychswitch/src/ui/screens/alcohol_withdrawal_screen.dart';
import 'package:psychswitch/src/ui/screens/antipsychotic_high_dose_screen.dart';
import 'package:psychswitch/src/ui/screens/antipsychotic_in_parkinsonism_screen.dart';
import 'package:psychswitch/src/ui/screens/benzo_taper_screen.dart';
import 'package:psychswitch/src/ui/screens/bupe_microdosing_screen.dart';
import 'package:psychswitch/src/ui/screens/calculators_screen.dart';
import 'package:psychswitch/src/ui/screens/capacity_screen.dart';
import 'package:psychswitch/src/ui/screens/catatonia_screen.dart';
import 'package:psychswitch/src/ui/screens/clozapine_fever_screen.dart';
import 'package:psychswitch/src/ui/screens/clozapine_gi_screen.dart';
import 'package:psychswitch/src/ui/screens/clozapine_myocarditis_screen.dart';
import 'package:psychswitch/src/ui/screens/clozapine_screen.dart';
import 'package:psychswitch/src/ui/screens/compare_screen.dart';
import 'package:psychswitch/src/ui/screens/crisis_screen.dart';
import 'package:psychswitch/src/ui/screens/cssrs_screen.dart';
import 'package:psychswitch/src/ui/screens/delirium_4at_screen.dart';
import 'package:psychswitch/src/ui/screens/depot_screen.dart';
import 'package:psychswitch/src/ui/screens/deprescribing_screen.dart';
import 'package:psychswitch/src/ui/screens/drug_profile_screen.dart';
import 'package:psychswitch/src/ui/screens/dsm_runner_screen.dart';
import 'package:psychswitch/src/ui/screens/dsm_screen.dart';
import 'package:psychswitch/src/ui/screens/ect_workup_screen.dart';
import 'package:psychswitch/src/ui/screens/equivalency_screen.dart';
import 'package:psychswitch/src/ui/screens/errata_screen.dart';
import 'package:psychswitch/src/ui/screens/glossary_screen.dart';
import 'package:psychswitch/src/ui/screens/history_screen.dart';
import 'package:psychswitch/src/ui/screens/home_screen.dart';
import 'package:psychswitch/src/ui/screens/hyperprolactinaemia_screen.dart';
import 'package:psychswitch/src/ui/screens/hyperthermic_dx_screen.dart';
import 'package:psychswitch/src/ui/screens/hyponatraemia_screen.dart';
import 'package:psychswitch/src/ui/screens/lab_screen.dart';
import 'package:psychswitch/src/ui/screens/lamotrigine_titration_screen.dart';
import 'package:psychswitch/src/ui/screens/lithium_tapering_screen.dart';
import 'package:psychswitch/src/ui/screens/lithium_toxicity_screen.dart';
import 'package:psychswitch/src/ui/screens/maoi_diet_screen.dart';
import 'package:psychswitch/src/ui/screens/metabolic_monitoring_screen.dart';
import 'package:psychswitch/src/ui/screens/metabolic_weight_screen.dart';
import 'package:psychswitch/src/ui/screens/mha_screen.dart';
import 'package:psychswitch/src/ui/screens/mood_stabilizer_detail_screen.dart';
import 'package:psychswitch/src/ui/screens/mood_stabilizer_home_screen.dart';
import 'package:psychswitch/src/ui/screens/movement_disorder_screen.dart';
import 'package:psychswitch/src/ui/screens/mse_screen.dart';
import 'package:psychswitch/src/ui/screens/nms_rechallenge_screen.dart';
import 'package:psychswitch/src/ui/screens/nms_screen.dart';
import 'package:psychswitch/src/ui/screens/opioid_overdose_screen.dart';
import 'package:psychswitch/src/ui/screens/ost_acute_pain_screen.dart';
import 'package:psychswitch/src/ui/screens/ost_induction_screen.dart';
import 'package:psychswitch/src/ui/screens/perinatal_screen.dart';
import 'package:psychswitch/src/ui/screens/perioperative_psychotropics_screen.dart';
import 'package:psychswitch/src/ui/screens/pharmacogenomics_screen.dart';
import 'package:psychswitch/src/ui/screens/polypharmacy_screen.dart';
import 'package:psychswitch/src/ui/screens/post_injection_syndrome_screen.dart';
import 'package:psychswitch/src/ui/screens/qtc_stacker_screen.dart';
import 'package:psychswitch/src/ui/screens/ramadan_screen.dart';
import 'package:psychswitch/src/ui/screens/refeeding_screen.dart';
import 'package:psychswitch/src/ui/screens/renal_hepatic_screen.dart';
import 'package:psychswitch/src/ui/screens/result_screen.dart';
import 'package:psychswitch/src/ui/screens/scale_runner_screen.dart';
import 'package:psychswitch/src/ui/screens/scales_screen.dart';
import 'package:psychswitch/src/ui/screens/search_screen.dart';
import 'package:psychswitch/src/ui/screens/self_care_screen.dart';
import 'package:psychswitch/src/ui/screens/serotonergic_opioid_screen.dart';
import 'package:psychswitch/src/ui/screens/serotonin_screen.dart';
import 'package:psychswitch/src/ui/screens/settings_screen.dart';
import 'package:psychswitch/src/ui/screens/smoking_adjustment_screen.dart';
import 'package:psychswitch/src/ui/screens/ssri_sexual_dysfunction_screen.dart';
import 'package:psychswitch/src/ui/screens/steroid_psychiatric_screen.dart';
import 'package:psychswitch/src/ui/screens/stimulant_cardiac_screen_screen.dart';
import 'package:psychswitch/src/ui/screens/stopp_start_screen.dart';
import 'package:psychswitch/src/ui/screens/switch_screen.dart';
import 'package:psychswitch/src/ui/screens/tardive_dyskinesia_screen.dart';
import 'package:psychswitch/src/ui/screens/tdm_screen.dart';
import 'package:psychswitch/src/ui/screens/thiamine_screen.dart';
import 'package:psychswitch/src/ui/screens/valproate_ppp_screen.dart';

/// Named route ids — kept in one place so screen code never hard-codes
/// path strings.
abstract final class Routes {
  static const home = 'home';
  static const switch_ = 'switch';
  static const result = 'result';
  static const history = 'history';
  static const glossary = 'glossary';
  static const settings = 'settings';
  static const about = 'about';
  static const clozapine = 'clozapine';
  static const depotIndex = 'depot_index';
  static const depot = 'depot';
  static const moodStabilizers = 'mood_stabilizers';
  static const moodStabilizerDetail = 'mood_stabilizer_detail';
  static const lithiumTapering = 'lithium_tapering';
  static const qtcStacker = 'qtc_stacker';
  static const errata = 'errata';
  static const adverseEffects = 'adverse_effects';
  static const equivalency = 'equivalency';
  static const drugProfile = 'drug_profile';
  static const ramadan = 'ramadan';
  static const calculators = 'calculators';
  static const polypharmacy = 'polypharmacy';
  static const compare = 'compare';
  static const search = 'search';
  static const scales = 'scales';
  static const scaleRunner = 'scale_runner';
  static const dsm = 'dsm';
  static const dsmRunner = 'dsm_runner';
  static const perinatal = 'perinatal';
  static const stoppStart = 'stopp_start';
  static const cssrs = 'cssrs';
  static const mse = 'mse';
  static const mha = 'mha';
  static const crisis = 'crisis';
  static const nms = 'nms';
  static const serotonin = 'serotonin';
  static const tdm = 'tdm';
  static const capacity = 'capacity';
  static const lab = 'lab';
  static const movement = 'movement';
  static const agitation = 'agitation';
  static const selfCare = 'self_care';
  static const deprescribing = 'deprescribing';
  static const pharmacogenomics = 'pharmacogenomics';
  static const metabolicMonitoring = 'metabolic_monitoring';
  static const smokingAdjustment = 'smoking_adjustment';
  static const delirium4at = 'delirium_4at';
  static const catatonia = 'catatonia';
  static const benzoTaper = 'benzo_taper';
  static const renalHepatic = 'renal_hepatic';
  static const ectWorkup = 'ect_workup';
  static const maoiDiet = 'maoi_diet';
  static const refeeding = 'refeeding';
  static const hyperthermicDx = 'hyperthermic_dx';
  static const lithiumToxicity = 'lithium_toxicity';
  static const alcoholWithdrawal = 'alcohol_withdrawal';
  static const ostInduction = 'ost_induction';
  static const thiamine = 'thiamine';
  static const hyponatraemia = 'hyponatraemia';
  static const hyperprolactinaemia = 'hyperprolactinaemia';
  static const clozapineMyocarditis = 'clozapine_myocarditis';
  static const valproatePpp = 'valproate_ppp';
  static const postInjectionSyndrome = 'post_injection_syndrome';
  static const opioidOverdose = 'opioid_overdose';
  static const stimulantCardiac = 'stimulant_cardiac';
  static const antipsychoticHighDose = 'antipsychotic_high_dose';
  static const bupeMicrodosing = 'bupe_microdosing';
  static const ostAcutePain = 'ost_acute_pain';
  static const antipsychoticParkinsonism =
      'antipsychotic_parkinsonism';
  static const serotonergicOpioid = 'serotonergic_opioid';
  static const steroidPsychiatric = 'steroid_psychiatric';
  static const metabolicWeight = 'metabolic_weight';
  static const clozapineGi = 'clozapine_gi';
  static const ssriSexualDysfunction = 'ssri_sexual_dysfunction';
  static const lamotrigineTitration = 'lamotrigine_titration';
  static const tardiveDyskinesia = 'tardive_dyskinesia';
  static const nmsRechallenge = 'nms_rechallenge';
  static const perioperative = 'perioperative_psychotropics';
  static const clozapineFever = 'clozapine_fever';
}

/// Custom shared-axis (horizontal) page builder. Material 3 spatial
/// motion: forward navigation pushes the new page in from the right
/// while the old page slides out to the left; pop reverses both. The
/// app reads as *spatial* — drug profile is "to the right" of home,
/// home is "to the left of" everywhere — rather than a deck of cards
/// fading through each other.
///
/// Subtle slide (4% of screen width), short duration (220ms forward /
/// 180ms reverse), no scale — pure fade + lateral motion. The slide
/// is gentle enough that pop gestures still feel like fade-throughs
/// to the eye, but the directional intent registers subconsciously.
///
/// Auto-disables under MediaQuery.disableAnimations (system reduced-
/// motion) — accessibility-correct without ceremony.
CustomTransitionPage<T> _fadeThroughPage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Honour system reduced-motion preference.
      if (MediaQuery.disableAnimationsOf(context)) return child;

      // Responsive slide amplitude — 4% reads on phones, ~30px on a
      // 7.6" Fold inner which is below perceptual threshold. Bump to
      // 6.5% on wide breakpoints (≥600px) so the spatial intent
      // actually registers on the larger surface.
      final isWide = MediaQuery.sizeOf(context).width >= 600;
      final amplitude = isWide ? 0.065 : 0.04;

      // ── Incoming page ─────────────────────────────────────────
      final fadeIn = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.3, 1, curve: Curves.easeOutCubic),
      );
      final slideIn = Tween<Offset>(
        begin: Offset(amplitude, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      );

      // ── Outgoing page (the one being covered) ─────────────────
      final fadeOut = CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0, 0.6, curve: Curves.easeIn),
      );
      final slideOut = Tween<Offset>(
        begin: Offset.zero,
        end: Offset(-amplitude, 0),
      ).animate(
        CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeIn),
      );

      return SlideTransition(
        position: slideOut,
        child: FadeTransition(
          opacity: ReverseAnimation(fadeOut),
          child: SlideTransition(
            position: slideIn,
            child: FadeTransition(opacity: fadeIn, child: child),
          ),
        ),
      );
    },
  );
}

GoRouter buildRouter() => GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          name: Routes.home,
          path: '/',
          pageBuilder: (context, state) =>
              _fadeThroughPage(state: state, child: const HomeScreen()),
        ),
        GoRoute(
          name: Routes.switch_,
          path: '/switch',
          pageBuilder: (context, state) =>
              _fadeThroughPage(state: state, child: const SwitchScreen()),
        ),
        GoRoute(
          name: Routes.result,
          path: '/result',
          pageBuilder: (context, state) {
            final args = state.extra as ResultScreenArgs?;
            return _fadeThroughPage(
              state: state,
              child: ResultScreen(args: args),
            );
          },
        ),
        GoRoute(
          name: Routes.history,
          path: '/history',
          pageBuilder: (context, state) =>
              _fadeThroughPage(state: state, child: const HistoryScreen()),
        ),
        GoRoute(
          name: Routes.glossary,
          path: '/glossary',
          pageBuilder: (context, state) =>
              _fadeThroughPage(state: state, child: const GlossaryScreen()),
        ),
        GoRoute(
          name: Routes.settings,
          path: '/settings',
          pageBuilder: (context, state) =>
              _fadeThroughPage(state: state, child: const SettingsScreen()),
        ),
        GoRoute(
          name: Routes.about,
          path: '/about',
          pageBuilder: (context, state) =>
              _fadeThroughPage(state: state, child: const AboutScreen()),
        ),
        GoRoute(
          name: Routes.clozapine,
          path: '/clozapine',
          pageBuilder: (context, state) =>
              _fadeThroughPage(state: state, child: const ClozapineScreen()),
        ),
        GoRoute(
          name: Routes.moodStabilizers,
          path: '/mood-stabilizers',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const MoodStabilizerHomeScreen(),
          ),
          routes: <RouteBase>[
            GoRoute(
              name: Routes.moodStabilizerDetail,
              path: ':id',
              pageBuilder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return _fadeThroughPage(
                  state: state,
                  child: MoodStabilizerDetailScreen(drugId: id),
                );
              },
            ),
          ],
        ),
        GoRoute(
          name: Routes.lithiumTapering,
          path: '/lithium-tapering',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const LithiumTaperingScreen(),
          ),
        ),
        GoRoute(
          name: Routes.qtcStacker,
          path: '/qtc-stacker',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const QtcStackerScreen(),
          ),
        ),
        GoRoute(
          name: Routes.errata,
          path: '/errata',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const ErrataScreen(),
          ),
        ),
        GoRoute(
          name: Routes.adverseEffects,
          path: '/adverse-effects',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const AdverseEffectsScreen(),
          ),
        ),
        GoRoute(
          name: Routes.equivalency,
          path: '/equivalency',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const EquivalencyScreen(),
          ),
        ),
        GoRoute(
          name: Routes.drugProfile,
          path: '/drug/:id',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return _fadeThroughPage(
              state: state,
              child: DrugProfileScreen(drugId: id),
            );
          },
        ),
        GoRoute(
          name: Routes.ramadan,
          path: '/ramadan',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const RamadanScreen(),
          ),
        ),
        GoRoute(
          name: Routes.calculators,
          path: '/calculators',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const CalculatorsScreen(),
          ),
        ),
        GoRoute(
          name: Routes.search,
          path: '/search',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const SearchScreen(),
          ),
        ),
        GoRoute(
          name: Routes.scales,
          path: '/scales',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const ScalesScreen(),
          ),
        ),
        GoRoute(
          name: Routes.scaleRunner,
          path: '/scales/:id',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return _fadeThroughPage(
              state: state,
              child: ScaleRunnerScreen(scaleId: id),
            );
          },
        ),
        GoRoute(
          name: Routes.dsm,
          path: '/dsm',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const DsmScreen(),
          ),
        ),
        GoRoute(
          name: Routes.dsmRunner,
          path: '/dsm/:id',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return _fadeThroughPage(
              state: state,
              child: DsmRunnerScreen(disorderId: id),
            );
          },
        ),
        GoRoute(
          name: Routes.perinatal,
          path: '/perinatal',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const PerinatalScreen(),
          ),
        ),
        GoRoute(
          name: Routes.stoppStart,
          path: '/stopp-start',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const StoppStartScreen(),
          ),
        ),
        GoRoute(
          name: Routes.cssrs,
          path: '/cssrs',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const CssrsScreen(),
          ),
        ),
        GoRoute(
          name: Routes.mse,
          path: '/mse',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const MseScreen(),
          ),
        ),
        GoRoute(
          name: Routes.mha,
          path: '/mha',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const MhaScreen(),
          ),
        ),
        GoRoute(
          name: Routes.crisis,
          path: '/crisis',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const CrisisScreen(),
          ),
        ),
        GoRoute(
          name: Routes.nms,
          path: '/nms',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const NmsScreen(),
          ),
        ),
        GoRoute(
          name: Routes.serotonin,
          path: '/serotonin',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const SerotoninScreen(),
          ),
        ),
        GoRoute(
          name: Routes.tdm,
          path: '/tdm',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const TdmScreen(),
          ),
        ),
        GoRoute(
          name: Routes.capacity,
          path: '/capacity',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const CapacityScreen(),
          ),
        ),
        GoRoute(
          name: Routes.lab,
          path: '/lab',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const LabScreen(),
          ),
        ),
        GoRoute(
          name: Routes.movement,
          path: '/movement',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const MovementDisorderScreen(),
          ),
        ),
        GoRoute(
          name: Routes.agitation,
          path: '/agitation',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const AgitationScreen(),
          ),
        ),
        GoRoute(
          name: Routes.selfCare,
          path: '/self-care',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const SelfCareScreen(),
          ),
        ),
        GoRoute(
          name: Routes.deprescribing,
          path: '/deprescribing',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const DeprescribingScreen(),
          ),
        ),
        GoRoute(
          name: Routes.pharmacogenomics,
          path: '/pharmacogenomics',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const PharmacogenomicsScreen(),
          ),
        ),
        GoRoute(
          name: Routes.metabolicMonitoring,
          path: '/metabolic-monitoring',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const MetabolicMonitoringScreen(),
          ),
        ),
        GoRoute(
          name: Routes.smokingAdjustment,
          path: '/smoking-adjustment',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const SmokingAdjustmentScreen(),
          ),
        ),
        GoRoute(
          name: Routes.delirium4at,
          path: '/delirium-4at',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const Delirium4atScreen(),
          ),
        ),
        GoRoute(
          name: Routes.catatonia,
          path: '/catatonia',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const CatatoniaScreen(),
          ),
        ),
        GoRoute(
          name: Routes.benzoTaper,
          path: '/benzo-taper',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const BenzoTaperScreen(),
          ),
        ),
        GoRoute(
          name: Routes.renalHepatic,
          path: '/renal-hepatic',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const RenalHepaticScreen(),
          ),
        ),
        GoRoute(
          name: Routes.ectWorkup,
          path: '/ect-workup',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const EctWorkupScreen(),
          ),
        ),
        GoRoute(
          name: Routes.maoiDiet,
          path: '/maoi-diet',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const MaoiDietScreen(),
          ),
        ),
        GoRoute(
          name: Routes.refeeding,
          path: '/refeeding',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const RefeedingScreen(),
          ),
        ),
        GoRoute(
          name: Routes.hyperthermicDx,
          path: '/hyperthermic-dx',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const HyperthermicDxScreen(),
          ),
        ),
        GoRoute(
          name: Routes.lithiumToxicity,
          path: '/lithium-toxicity',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const LithiumToxicityScreen(),
          ),
        ),
        GoRoute(
          name: Routes.alcoholWithdrawal,
          path: '/alcohol-withdrawal',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const AlcoholWithdrawalScreen(),
          ),
        ),
        GoRoute(
          name: Routes.ostInduction,
          path: '/ost-induction',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const OstInductionScreen(),
          ),
        ),
        GoRoute(
          name: Routes.thiamine,
          path: '/thiamine',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const ThiamineScreen(),
          ),
        ),
        GoRoute(
          name: Routes.hyponatraemia,
          path: '/hyponatraemia',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const HyponatraemiaScreen(),
          ),
        ),
        GoRoute(
          name: Routes.hyperprolactinaemia,
          path: '/hyperprolactinaemia',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const HyperprolactinaemiaScreen(),
          ),
        ),
        GoRoute(
          name: Routes.clozapineMyocarditis,
          path: '/clozapine-myocarditis',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const ClozapineMyocarditisScreen(),
          ),
        ),
        GoRoute(
          name: Routes.valproatePpp,
          path: '/valproate-ppp',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const ValproatePppScreen(),
          ),
        ),
        GoRoute(
          name: Routes.postInjectionSyndrome,
          path: '/post-injection-syndrome',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const PostInjectionSyndromeScreen(),
          ),
        ),
        GoRoute(
          name: Routes.opioidOverdose,
          path: '/opioid-overdose',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const OpioidOverdoseScreen(),
          ),
        ),
        GoRoute(
          name: Routes.stimulantCardiac,
          path: '/stimulant-cardiac',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const StimulantCardiacScreen(),
          ),
        ),
        GoRoute(
          name: Routes.antipsychoticHighDose,
          path: '/antipsychotic-high-dose',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const AntipsychoticHighDoseScreen(),
          ),
        ),
        GoRoute(
          name: Routes.bupeMicrodosing,
          path: '/bupe-microdosing',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const BupeMicrodosingScreen(),
          ),
        ),
        GoRoute(
          name: Routes.ostAcutePain,
          path: '/ost-acute-pain',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const OstAcutePainScreen(),
          ),
        ),
        GoRoute(
          name: Routes.antipsychoticParkinsonism,
          path: '/antipsychotic-parkinsonism',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const AntipsychoticInParkinsonismScreen(),
          ),
        ),
        GoRoute(
          name: Routes.serotonergicOpioid,
          path: '/serotonergic-opioid',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const SerotonergicOpioidScreen(),
          ),
        ),
        GoRoute(
          name: Routes.steroidPsychiatric,
          path: '/steroid-psychiatric',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const SteroidPsychiatricScreen(),
          ),
        ),
        GoRoute(
          name: Routes.metabolicWeight,
          path: '/metabolic-weight',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const MetabolicWeightScreen(),
          ),
        ),
        GoRoute(
          name: Routes.clozapineGi,
          path: '/clozapine-gi',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const ClozapineGiScreen(),
          ),
        ),
        GoRoute(
          name: Routes.ssriSexualDysfunction,
          path: '/ssri-sexual-dysfunction',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const SsriSexualDysfunctionScreen(),
          ),
        ),
        GoRoute(
          name: Routes.lamotrigineTitration,
          path: '/lamotrigine-titration',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const LamotrigineTitrationScreen(),
          ),
        ),
        GoRoute(
          name: Routes.tardiveDyskinesia,
          path: '/tardive-dyskinesia',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const TardiveDyskinesiaScreen(),
          ),
        ),
        GoRoute(
          name: Routes.nmsRechallenge,
          path: '/nms-rechallenge',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const NmsRechallengeScreen(),
          ),
        ),
        GoRoute(
          name: Routes.perioperative,
          path: '/perioperative-psychotropics',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const PerioperativePsychotropicsScreen(),
          ),
        ),
        GoRoute(
          name: Routes.clozapineFever,
          path: '/clozapine-fever',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const ClozapineFeverScreen(),
          ),
        ),
        GoRoute(
          name: Routes.compare,
          path: '/compare',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const CompareScreen(),
          ),
        ),
        GoRoute(
          name: Routes.polypharmacy,
          path: '/polypharmacy',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const PolypharmacyScreen(),
          ),
        ),
        GoRoute(
          name: Routes.depotIndex,
          path: '/depot',
          pageBuilder: (context, state) => _fadeThroughPage(
            state: state,
            child: const DepotIndexScreen(),
          ),
          routes: <RouteBase>[
            GoRoute(
              name: Routes.depot,
              path: ':id',
              pageBuilder: (context, state) {
                final kind = DepotKind.parse(state.pathParameters['id']);
                final child = kind == null
                    // Unknown id → fall back to the index.
                    ? const DepotIndexScreen()
                    : DepotProtocolScreen(kind: kind);
                return _fadeThroughPage(state: state, child: child);
              },
            ),
          ],
        ),
      ],
    );
