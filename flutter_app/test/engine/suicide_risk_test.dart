// Tests for the composite suicide risk assessment engine.
//
// The engine layers risk + protective factors on top of C-SSRS and
// produces a composite tier. These tests verify the tier-promotion
// boundaries — they are the highest-stakes branches in the app.

import 'package:flutter_test/flutter_test.dart';
import 'package:psychswitch_engine/cssrs.dart';
import 'package:psychswitch_engine/suicide_risk.dart';

const _cssrsNone = CssrsInput(
  highestIdeationLevel: 0,
  ideationLastMonth: false,
  behaviourLifetime: false,
  behaviourLast3Months: false,
);
const _cssrsLow = CssrsInput(
  highestIdeationLevel: 1,
  ideationLastMonth: true,
  behaviourLifetime: false,
  behaviourLast3Months: false,
);
const _cssrsMod = CssrsInput(
  highestIdeationLevel: 3,
  ideationLastMonth: true,
  behaviourLifetime: false,
  behaviourLast3Months: false,
);
const _cssrsHigh = CssrsInput(
  highestIdeationLevel: 4,
  ideationLastMonth: true,
  behaviourLifetime: false,
  behaviourLast3Months: false,
);

void main() {
  group('Composite suicide risk tier', () {
    test('No ideation, no factors → MINIMAL', () {
      final a = assessSuicideRisk(const SuicideRiskInput(
        cssrs: _cssrsNone,
        riskFactors: <SuicideRiskFactor>{},
        protectiveFactors: <SuicideProtectiveFactor>{},
      ));
      expect(a.tier, SuicideRiskTier.minimal);
    });

    test('No ideation, 4+ risk factors → LOW (monitor)', () {
      final a = assessSuicideRisk(const SuicideRiskInput(
        cssrs: _cssrsNone,
        riskFactors: <SuicideRiskFactor>{
          SuicideRiskFactor.priorAttempt,
          SuicideRiskFactor.chronicMentalIllness,
          SuicideRiskFactor.socialIsolation,
          SuicideRiskFactor.hopelessness,
        },
        protectiveFactors: <SuicideProtectiveFactor>{},
      ));
      expect(a.tier, SuicideRiskTier.low);
    });

    test('Low C-SSRS, balanced factors → LOW', () {
      final a = assessSuicideRisk(const SuicideRiskInput(
        cssrs: _cssrsLow,
        riskFactors: <SuicideRiskFactor>{
          SuicideRiskFactor.hopelessness,
        },
        protectiveFactors: <SuicideProtectiveFactor>{
          SuicideProtectiveFactor.childrenAtHome,
        },
      ));
      expect(a.tier, SuicideRiskTier.low);
    });

    test('Low C-SSRS, risk >> protective → MODERATE (promoted)', () {
      final a = assessSuicideRisk(const SuicideRiskInput(
        cssrs: _cssrsLow,
        riskFactors: <SuicideRiskFactor>{
          SuicideRiskFactor.hopelessness,
          SuicideRiskFactor.socialIsolation,
          SuicideRiskFactor.recentMajorLoss,
        },
        protectiveFactors: <SuicideProtectiveFactor>{},
      ));
      expect(a.tier, SuicideRiskTier.moderate);
    });

    test('Moderate C-SSRS, balanced → MODERATE', () {
      final a = assessSuicideRisk(const SuicideRiskInput(
        cssrs: _cssrsMod,
        riskFactors: <SuicideRiskFactor>{
          SuicideRiskFactor.hopelessness,
        },
        protectiveFactors: <SuicideProtectiveFactor>{
          SuicideProtectiveFactor.childrenAtHome,
        },
      ));
      expect(a.tier, SuicideRiskTier.moderate);
    });

    test('Moderate C-SSRS, dense risk (risk - protective ≥ 3) → HIGH', () {
      final a = assessSuicideRisk(const SuicideRiskInput(
        cssrs: _cssrsMod,
        riskFactors: <SuicideRiskFactor>{
          SuicideRiskFactor.priorAttempt,
          SuicideRiskFactor.hopelessness,
          SuicideRiskFactor.socialIsolation,
          SuicideRiskFactor.severeInsomnia,
        },
        protectiveFactors: <SuicideProtectiveFactor>{
          SuicideProtectiveFactor.childrenAtHome,
        },
      ));
      // 4 risk - 1 protective = 3 → promote to high
      expect(a.tier, SuicideRiskTier.high);
    });

    test('High C-SSRS, no amplifier → HIGH', () {
      final a = assessSuicideRisk(const SuicideRiskInput(
        cssrs: _cssrsHigh,
        riskFactors: <SuicideRiskFactor>{
          SuicideRiskFactor.priorAttempt,
        },
        protectiveFactors: <SuicideProtectiveFactor>{},
      ));
      expect(a.tier, SuicideRiskTier.high);
    });

    test('High C-SSRS + lethal means access → ACUTE', () {
      final a = assessSuicideRisk(const SuicideRiskInput(
        cssrs: _cssrsHigh,
        riskFactors: <SuicideRiskFactor>{
          SuicideRiskFactor.lethalMeansAccess,
        },
        protectiveFactors: <SuicideProtectiveFactor>{},
      ));
      expect(a.tier, SuicideRiskTier.acute);
    });

    test('High C-SSRS + active psychosis → ACUTE', () {
      final a = assessSuicideRisk(const SuicideRiskInput(
        cssrs: _cssrsHigh,
        riskFactors: <SuicideRiskFactor>{
          SuicideRiskFactor.activePsychosis,
        },
        protectiveFactors: <SuicideProtectiveFactor>{},
      ));
      expect(a.tier, SuicideRiskTier.acute);
    });

    test('High C-SSRS + substance use → ACUTE', () {
      final a = assessSuicideRisk(const SuicideRiskInput(
        cssrs: _cssrsHigh,
        riskFactors: <SuicideRiskFactor>{
          SuicideRiskFactor.substanceUseOrIntoxication,
        },
        protectiveFactors: <SuicideProtectiveFactor>{},
      ));
      expect(a.tier, SuicideRiskTier.acute);
    });
  });

  group('Acute amplifier classification', () {
    test('lethal means / substances / psychosis are amplifiers', () {
      expect(SuicideRiskFactor.lethalMeansAccess.isAcuteAmplifier, isTrue);
      expect(
        SuicideRiskFactor.substanceUseOrIntoxication.isAcuteAmplifier,
        isTrue,
      );
      expect(SuicideRiskFactor.activePsychosis.isAcuteAmplifier, isTrue);
    });

    test('other dynamic factors are NOT amplifiers', () {
      expect(SuicideRiskFactor.hopelessness.isAcuteAmplifier, isFalse);
      expect(SuicideRiskFactor.recentMajorLoss.isAcuteAmplifier, isFalse);
      expect(SuicideRiskFactor.severeInsomnia.isAcuteAmplifier, isFalse);
    });

    test('static factors are not amplifiers', () {
      expect(SuicideRiskFactor.priorAttempt.isAcuteAmplifier, isFalse);
      expect(
        SuicideRiskFactor.familyHistorySuicide.isAcuteAmplifier,
        isFalse,
      );
    });
  });

  group('Static vs dynamic classification', () {
    test('the 6 static factors are flagged static', () {
      expect(isStaticRiskFactor(SuicideRiskFactor.priorAttempt), isTrue);
      expect(
        isStaticRiskFactor(SuicideRiskFactor.familyHistorySuicide),
        isTrue,
      );
      expect(
        isStaticRiskFactor(SuicideRiskFactor.chronicMentalIllness),
        isTrue,
      );
      expect(
        isStaticRiskFactor(SuicideRiskFactor.childhoodTrauma),
        isTrue,
      );
      expect(
        isStaticRiskFactor(SuicideRiskFactor.chronicPainOrIllness),
        isTrue,
      );
      expect(
        isStaticRiskFactor(SuicideRiskFactor.recentPsychDischarge),
        isTrue,
      );
    });

    test('the 8 dynamic factors are flagged dynamic', () {
      expect(isStaticRiskFactor(SuicideRiskFactor.hopelessness), isFalse);
      expect(
        isStaticRiskFactor(SuicideRiskFactor.recentMajorLoss),
        isFalse,
      );
      expect(
        isStaticRiskFactor(SuicideRiskFactor.socialIsolation),
        isFalse,
      );
      expect(
        isStaticRiskFactor(SuicideRiskFactor.acutePsychosocialStressor),
        isFalse,
      );
      expect(
        isStaticRiskFactor(SuicideRiskFactor.substanceUseOrIntoxication),
        isFalse,
      );
      expect(
        isStaticRiskFactor(SuicideRiskFactor.activePsychosis),
        isFalse,
      );
      expect(
        isStaticRiskFactor(SuicideRiskFactor.severeInsomnia),
        isFalse,
      );
      expect(
        isStaticRiskFactor(SuicideRiskFactor.lethalMeansAccess),
        isFalse,
      );
    });
  });

  group('Clinical note formatting', () {
    test('includes tier, C-SSRS line, factor lists, disposition', () {
      final a = assessSuicideRisk(const SuicideRiskInput(
        cssrs: _cssrsMod,
        riskFactors: <SuicideRiskFactor>{
          SuicideRiskFactor.hopelessness,
          SuicideRiskFactor.recentMajorLoss,
        },
        protectiveFactors: <SuicideProtectiveFactor>{
          SuicideProtectiveFactor.childrenAtHome,
        },
      ));
      final note = a.clinicalNote();
      expect(note, contains('SUICIDE RISK ASSESSMENT'));
      expect(note, contains('Moderate'));
      expect(note, contains('C-SSRS'));
      expect(note, contains('Current hopelessness'));
      expect(note, contains('Children at home'));
      expect(note, contains('Disposition:'));
    });

    test('handles empty factor sets gracefully', () {
      final a = assessSuicideRisk(const SuicideRiskInput(
        cssrs: _cssrsNone,
        riskFactors: <SuicideRiskFactor>{},
        protectiveFactors: <SuicideProtectiveFactor>{},
      ));
      final note = a.clinicalNote();
      expect(note, contains('no factors endorsed'));
    });
  });
}
