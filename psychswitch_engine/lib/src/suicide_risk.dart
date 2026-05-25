// Suicide risk assessment — composite engine.
//
// The C-SSRS engine (cssrs.dart) handles ideation + behaviour scoring
// per the validated Columbia ladder. Real clinical risk assessment is
// broader: ideation + behaviour PLUS static risk factors PLUS dynamic
// risk factors PLUS protective factors → composite tier → disposition.
//
// This engine composes C-SSRS with factor inventories and produces:
//   • A composite tier (acute / high / moderate / low / minimal)
//   • A one-line headline
//   • A disposition recommendation (the actual next clinical action)
//   • A rationale explaining WHY the tier landed where it did
//   • A multi-line clinical note formatted for paste into the chart
//
// DECISION SUPPORT, NOT A DECISION. The composite tier is a starting
// point for a clinical interview; it never replaces it. Acute-tier
// output mandates direct transfer to ED — the engine intentionally
// does not provide outpatient-management language at acute tier.
//
// Tier promotion logic (in order):
//   1. High C-SSRS + any acute amplifier (lethal means / substances /
//      psychosis) → ACUTE — ED transfer.
//   2. High C-SSRS without amplifier → HIGH — urgent same-day eval.
//   3. Moderate C-SSRS + risk-minus-protective >= 3 → HIGH (composite
//      promotion).
//   4. Moderate C-SSRS → MODERATE — safety plan + 1wk f/u.
//   5. Low C-SSRS + risk-minus-protective > 2 → MODERATE (composite
//      promotion).
//   6. Low C-SSRS → LOW — routine f/u + crisis numbers.
//   7. No ideation/behaviour + >= 4 risk factors → LOW — monitor for
//      deterioration.
//   8. Otherwise → MINIMAL — document negative screen, reassess.

import 'package:psychswitch_engine/cssrs.dart';

/// Risk factors split into static (largely non-modifiable history) and
/// dynamic (current modifiable state). The engine doesn't distinguish
/// them in scoring — both count toward risk weight — but the UI groups
/// them so the clinician can see which lever to pull.
enum SuicideRiskFactor {
  // ── Static ────────────────────────────────────────────────────
  priorAttempt('prior_attempt'),
  familyHistorySuicide('family_history_suicide'),
  chronicMentalIllness('chronic_mental_illness'),
  childhoodTrauma('childhood_trauma'),
  chronicPainOrIllness('chronic_pain_or_illness'),
  recentPsychDischarge('recent_psych_discharge'),

  // ── Dynamic (current, modifiable) ─────────────────────────────
  hopelessness('hopelessness'),
  recentMajorLoss('recent_major_loss'),
  socialIsolation('social_isolation'),
  acutePsychosocialStressor('acute_psychosocial_stressor'),
  substanceUseOrIntoxication('substance_use_or_intoxication'),
  activePsychosis('active_psychosis'),
  severeInsomnia('severe_insomnia'),
  lethalMeansAccess('lethal_means_access');

  const SuicideRiskFactor(this.jsonValue);
  final String jsonValue;

  /// True when the factor is part of the engine's acute-amplifier set —
  /// these elevate a high-C-SSRS picture into the acute tier (direct
  /// ED transfer).
  bool get isAcuteAmplifier =>
      this == SuicideRiskFactor.lethalMeansAccess ||
      this == SuicideRiskFactor.substanceUseOrIntoxication ||
      this == SuicideRiskFactor.activePsychosis;
}

enum SuicideProtectiveFactor {
  childrenAtHome('children_at_home'),
  pregnancy('pregnancy'),
  religiousSpiritualObjection('religious_spiritual_objection'),
  therapeuticAlliance('therapeutic_alliance'),
  reasonsForLiving('reasons_for_living'),
  fearOfDeathOrPain('fear_of_death_or_pain'),
  activeTreatmentEngagement('active_treatment_engagement'),
  socialOrFamilySupport('social_or_family_support');

  const SuicideProtectiveFactor(this.jsonValue);
  final String jsonValue;
}

enum SuicideRiskTier {
  acute('acute'), // ED / admission
  high('high'), // urgent same-day psych
  moderate('moderate'), // close f/u + safety plan
  low('low'), // safety plan + routine f/u
  minimal('minimal'); // reassurance, document negative screen

  const SuicideRiskTier(this.jsonValue);
  final String jsonValue;
}

class SuicideRiskInput {
  const SuicideRiskInput({
    required this.cssrs,
    required this.riskFactors,
    required this.protectiveFactors,
  });

  final CssrsInput cssrs;
  final Set<SuicideRiskFactor> riskFactors;
  final Set<SuicideProtectiveFactor> protectiveFactors;
}

class SuicideRiskAssessment {
  const SuicideRiskAssessment({
    required this.tier,
    required this.tierLabel,
    required this.cssrsResult,
    required this.headline,
    required this.disposition,
    required this.rationale,
    required this.input,
  });

  final SuicideRiskTier tier;
  final String tierLabel;
  final CssrsResult cssrsResult;
  final String headline;
  final String disposition;
  final String rationale;
  final SuicideRiskInput input;

  /// Multi-line clinical-note summary, suitable for paste into the
  /// patient chart. Names the C-SSRS finding, factor counts, the tier,
  /// and the disposition. The note is intentionally compact — chart
  /// notes earn space by being scanned at handover, not by being read.
  String clinicalNote() {
    final cssrsLine = cssrsResult.clipboardSummary();
    final risksList = input.riskFactors.isEmpty
        ? 'no factors endorsed'
        : input.riskFactors.map(suicideRiskFactorLabel).join(', ');
    final protectiveList = input.protectiveFactors.isEmpty
        ? 'no factors endorsed'
        : input.protectiveFactors
            .map(suicideProtectiveFactorLabel)
            .join(', ');
    return <String>[
      'SUICIDE RISK ASSESSMENT — $tierLabel',
      '',
      cssrsLine,
      '',
      'Risk factors: $risksList',
      'Protective factors: $protectiveList',
      '',
      'Disposition: $disposition',
    ].join('\n');
  }
}

/// Run the composite assessment. Pure — no provider reads, no I/O.
SuicideRiskAssessment assessSuicideRisk(SuicideRiskInput input) {
  final cssrs = evaluateCssrs(input.cssrs);
  final riskCount = input.riskFactors.length;
  final protectiveCount = input.protectiveFactors.length;
  final hasAcuteAmplifier =
      input.riskFactors.any((f) => f.isAcuteAmplifier);

  // ── 1 / 2: high C-SSRS — acute vs high ────────────────────────
  if (cssrs.tier == CssrsTier.high) {
    if (hasAcuteAmplifier) {
      final amplifiers = input.riskFactors
          .where((f) => f.isAcuteAmplifier)
          .map(suicideRiskFactorLabel)
          .join(' + ');
      return SuicideRiskAssessment(
        tier: SuicideRiskTier.acute,
        tierLabel: 'Acute high risk',
        cssrsResult: cssrs,
        headline: 'Immediate transfer to ED indicated.',
        disposition:
            'Do not leave alone. Arrange immediate ED transfer with a '
            'safe escort. Means restriction (firearms, medications, '
            'sharps) — engage family. Collateral history. Document '
            'precipitants. Hand-off to receiving team in person.',
        rationale: 'High C-SSRS PLUS acute amplifier ($amplifiers) — '
            'risk exceeds outpatient management.',
        input: input,
      );
    }
    return SuicideRiskAssessment(
      tier: SuicideRiskTier.high,
      tierLabel: 'High risk',
      cssrsResult: cssrs,
      headline: 'Urgent same-day psychiatric review.',
      disposition:
          'Urgent psychiatric eval today. Means restriction. Stanley-'
          'Brown safety plan with patient. Follow-up within 24-72 h. '
          'Consider admission. Document collateral.',
      rationale: 'High C-SSRS ideation (level 4-5) or behaviour in '
          'the last 3 months mandates urgent review even without '
          'acute amplifiers.',
      input: input,
    );
  }

  // ── 3 / 4: moderate C-SSRS — composite-promote or hold ────────
  if (cssrs.tier == CssrsTier.moderate) {
    if (riskCount - protectiveCount >= 3) {
      return SuicideRiskAssessment(
        tier: SuicideRiskTier.high,
        tierLabel: 'High risk',
        cssrsResult: cssrs,
        headline:
            'Moderate ideation with dense risk profile — same-day eval.',
        disposition:
            'Same-day psychiatric eval. Stanley-Brown safety plan. '
            'Means restriction. Follow-up 48-72 h. Treat modifiable '
            'factors (substance use, insomnia, hopelessness) at this '
            'visit.',
        rationale: '$riskCount risk factor${riskCount == 1 ? '' : 's'} '
            'vs $protectiveCount protective — the profile elevates '
            'moderate C-SSRS to high composite tier.',
        input: input,
      );
    }
    return SuicideRiskAssessment(
      tier: SuicideRiskTier.moderate,
      tierLabel: 'Moderate risk',
      cssrsResult: cssrs,
      headline: 'Close follow-up + safety plan indicated.',
      disposition:
          'Complete Stanley-Brown safety plan. Means restriction. '
          'Outpatient follow-up within 1 week. Document precipitants, '
          'protective factors, and patient-named supports.',
      rationale: 'Moderate C-SSRS, $riskCount risk vs $protectiveCount '
          'protective — standard outpatient management with safety '
          'plan.',
      input: input,
    );
  }

  // ── 5 / 6: low C-SSRS — composite-promote or hold ─────────────
  if (cssrs.tier == CssrsTier.low) {
    if (riskCount > protectiveCount + 2) {
      return SuicideRiskAssessment(
        tier: SuicideRiskTier.moderate,
        tierLabel: 'Moderate risk',
        cssrsResult: cssrs,
        headline: 'Low ideation but elevated risk profile.',
        disposition:
            'Stanley-Brown safety plan. Follow-up within 1-2 weeks. '
            'Treat modifiable factors. Crisis numbers documented + '
            'shared.',
        rationale: '$riskCount risk vs $protectiveCount protective — '
            'even with low C-SSRS the profile warrants moderate-tier '
            'care.',
        input: input,
      );
    }
    return SuicideRiskAssessment(
      tier: SuicideRiskTier.low,
      tierLabel: 'Low risk',
      cssrsResult: cssrs,
      headline: 'Routine follow-up + crisis information.',
      disposition:
          'Routine follow-up. Provide crisis hotline numbers (Talian '
          'Kasih 15999, Befrienders, MENTARI). Optional Stanley-Brown '
          'safety plan as a preventive measure. Reassess at next '
          'visit.',
      rationale: 'Low C-SSRS, manageable risk profile. Continue to '
          'monitor.',
      input: input,
    );
  }

  // ── 7 / 8: no C-SSRS findings ─────────────────────────────────
  if (riskCount >= 4) {
    return SuicideRiskAssessment(
      tier: SuicideRiskTier.low,
      tierLabel: 'Low risk',
      cssrsResult: cssrs,
      headline: 'No current ideation but multiple risk factors.',
      disposition:
          'Routine follow-up. Treat modifiable risk factors (substance '
          'use, insomnia, hopelessness). Reassess at each visit. '
          'Document patient denies current ideation.',
      rationale: '$riskCount risk factors present without current '
          'ideation — monitor for deterioration; treat what is '
          'modifiable.',
      input: input,
    );
  }
  return SuicideRiskAssessment(
    tier: SuicideRiskTier.minimal,
    tierLabel: 'Minimal risk',
    cssrsResult: cssrs,
    headline: 'No current concern — document and reassess.',
    disposition:
        'Document negative screen. Reassess at next visit and on any '
        'clinical deterioration.',
    rationale:
        'No current ideation or behaviour, $riskCount risk vs '
        '$protectiveCount protective factors.',
    input: input,
  );
}

/// Display label for a risk factor — used in checkboxes, the rationale
/// string, and the clinical note.
String suicideRiskFactorLabel(SuicideRiskFactor f) {
  switch (f) {
    case SuicideRiskFactor.priorAttempt:
      return 'Prior suicide attempt';
    case SuicideRiskFactor.familyHistorySuicide:
      return 'Family history of suicide';
    case SuicideRiskFactor.chronicMentalIllness:
      return 'Chronic mental illness';
    case SuicideRiskFactor.childhoodTrauma:
      return 'Childhood trauma / abuse';
    case SuicideRiskFactor.chronicPainOrIllness:
      return 'Chronic pain or illness';
    case SuicideRiskFactor.recentPsychDischarge:
      return 'Recent psychiatric discharge';
    case SuicideRiskFactor.hopelessness:
      return 'Current hopelessness';
    case SuicideRiskFactor.recentMajorLoss:
      return 'Recent major loss';
    case SuicideRiskFactor.socialIsolation:
      return 'Social isolation';
    case SuicideRiskFactor.acutePsychosocialStressor:
      return 'Acute psychosocial stressor';
    case SuicideRiskFactor.substanceUseOrIntoxication:
      return 'Substance use / intoxication';
    case SuicideRiskFactor.activePsychosis:
      return 'Active psychosis';
    case SuicideRiskFactor.severeInsomnia:
      return 'Severe insomnia';
    case SuicideRiskFactor.lethalMeansAccess:
      return 'Access to lethal means';
  }
}

/// Single-sentence clinical note explaining what the factor signals.
/// Surfaced as the help-text under each checkbox so the clinician can
/// see why the factor matters without leaving the screen.
String suicideRiskFactorNote(SuicideRiskFactor f) {
  switch (f) {
    case SuicideRiskFactor.priorAttempt:
      return "The single strongest predictor — risk multiplies after "
          "the first attempt.";
    case SuicideRiskFactor.familyHistorySuicide:
      return 'Heritable component; familial precedent normalises means.';
    case SuicideRiskFactor.chronicMentalIllness:
      return 'Depression, bipolar, schizophrenia, BPD — all raise '
          'baseline risk.';
    case SuicideRiskFactor.childhoodTrauma:
      return 'Adverse childhood experiences double lifetime risk.';
    case SuicideRiskFactor.chronicPainOrIllness:
      return 'Chronic somatic burden — terminal illness, pain '
          'syndromes.';
    case SuicideRiskFactor.recentPsychDischarge:
      return 'Highest-risk window is the first 30 days post-discharge.';
    case SuicideRiskFactor.hopelessness:
      return 'Hopelessness predicts suicide more strongly than '
          'depression severity.';
    case SuicideRiskFactor.recentMajorLoss:
      return 'Death, divorce, job loss, status loss within 6 months.';
    case SuicideRiskFactor.socialIsolation:
      return 'Living alone, no confidant, recent withdrawal from '
          'support network.';
    case SuicideRiskFactor.acutePsychosocialStressor:
      return 'Legal, financial, relationship crisis within last 30 days.';
    case SuicideRiskFactor.substanceUseOrIntoxication:
      return 'Acute intoxication or current heavy use — disinhibits + '
          'compounds impulsivity.';
    case SuicideRiskFactor.activePsychosis:
      return 'Command hallucinations or persecutory delusions raise '
          'acute risk.';
    case SuicideRiskFactor.severeInsomnia:
      return 'Severe insomnia is an independent acute risk marker.';
    case SuicideRiskFactor.lethalMeansAccess:
      return 'Firearms, large medication supply, jumping access — '
          'restriction reduces completed-suicide risk by up to 80%.';
  }
}

String suicideProtectiveFactorLabel(SuicideProtectiveFactor f) {
  switch (f) {
    case SuicideProtectiveFactor.childrenAtHome:
      return 'Children at home';
    case SuicideProtectiveFactor.pregnancy:
      return 'Pregnancy';
    case SuicideProtectiveFactor.religiousSpiritualObjection:
      return 'Religious / spiritual objection';
    case SuicideProtectiveFactor.therapeuticAlliance:
      return 'Strong therapeutic alliance';
    case SuicideProtectiveFactor.reasonsForLiving:
      return 'Reasons for living / future plans';
    case SuicideProtectiveFactor.fearOfDeathOrPain:
      return 'Fear of death or pain';
    case SuicideProtectiveFactor.activeTreatmentEngagement:
      return 'Active treatment engagement';
    case SuicideProtectiveFactor.socialOrFamilySupport:
      return 'Social / family support';
  }
}

String suicideProtectiveFactorNote(SuicideProtectiveFactor f) {
  switch (f) {
    case SuicideProtectiveFactor.childrenAtHome:
      return 'Dependent children at home — a primary deterrent for '
          'most patients.';
    case SuicideProtectiveFactor.pregnancy:
      return 'Current pregnancy or postpartum (first trimester).';
    case SuicideProtectiveFactor.religiousSpiritualObjection:
      return 'Faith-based objection to suicide as a moral wrong.';
    case SuicideProtectiveFactor.therapeuticAlliance:
      return 'Trusts and engages with their clinician.';
    case SuicideProtectiveFactor.reasonsForLiving:
      return 'Articulates specific reasons or near-term plans.';
    case SuicideProtectiveFactor.fearOfDeathOrPain:
      return 'Stated fear of dying or pain limits acting on ideation.';
    case SuicideProtectiveFactor.activeTreatmentEngagement:
      return 'In active treatment (therapy, meds) and adherent.';
    case SuicideProtectiveFactor.socialOrFamilySupport:
      return 'Available family, friends, partner — known to the '
          'patient.';
  }
}

/// True when the factor is grouped as "static" in the UI — the rest
/// are dynamic / current-state factors.
bool isStaticRiskFactor(SuicideRiskFactor f) {
  switch (f) {
    case SuicideRiskFactor.priorAttempt:
    case SuicideRiskFactor.familyHistorySuicide:
    case SuicideRiskFactor.chronicMentalIllness:
    case SuicideRiskFactor.childhoodTrauma:
    case SuicideRiskFactor.chronicPainOrIllness:
    case SuicideRiskFactor.recentPsychDischarge:
      return true;
    case SuicideRiskFactor.hopelessness:
    case SuicideRiskFactor.recentMajorLoss:
    case SuicideRiskFactor.socialIsolation:
    case SuicideRiskFactor.acutePsychosocialStressor:
    case SuicideRiskFactor.substanceUseOrIntoxication:
    case SuicideRiskFactor.activePsychosis:
    case SuicideRiskFactor.severeInsomnia:
    case SuicideRiskFactor.lethalMeansAccess:
      return false;
  }
}
