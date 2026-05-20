// Refeeding-syndrome risk (NICE CG32) + MARSIPAN extreme-risk
// modifier.
//
// Relevant to psychiatry managing anorexia nervosa, severe
// depression with starvation, and alcohol-use disorder. Risk
// stratification + the feeding / electrolyte / thiamine plan that
// prevents fatal hypophosphataemia.
//
// NICE: high risk if ANY ONE major criterion, OR TWO OR MORE minor
// criteria. MARSIPAN escalates to "extreme" risk (start ~5 kcal/kg)
// when BMI < 14 or negligible intake > 15 days.

class RefeedCriterion {
  const RefeedCriterion({
    required this.id,
    required this.label,
    required this.tier, // 'major' | 'minor' | 'extreme'
  });

  final String id;
  final String label;
  final String tier;
}

const List<RefeedCriterion> kRefeedMajor = <RefeedCriterion>[
  RefeedCriterion(
    id: 'bmi16',
    label: 'BMI < 16 kg/m²',
    tier: 'major',
  ),
  RefeedCriterion(
    id: 'loss15',
    label: 'Unintentional weight loss > 15% in 3–6 months',
    tier: 'major',
  ),
  RefeedCriterion(
    id: 'intake10',
    label: 'Little or no nutritional intake > 10 days',
    tier: 'major',
  ),
  RefeedCriterion(
    id: 'low_lytes',
    label: 'Low K, PO₄ or Mg before feeding',
    tier: 'major',
  ),
];

const List<RefeedCriterion> kRefeedMinor = <RefeedCriterion>[
  RefeedCriterion(
    id: 'bmi185',
    label: 'BMI < 18.5 kg/m²',
    tier: 'minor',
  ),
  RefeedCriterion(
    id: 'loss10',
    label: 'Unintentional weight loss > 10% in 3–6 months',
    tier: 'minor',
  ),
  RefeedCriterion(
    id: 'intake5',
    label: 'Little or no nutritional intake > 5 days',
    tier: 'minor',
  ),
  RefeedCriterion(
    id: 'history',
    label: 'Alcohol misuse OR drugs incl. insulin, chemotherapy, '
        'antacids, diuretics',
    tier: 'minor',
  ),
];

const List<RefeedCriterion> kRefeedExtreme = <RefeedCriterion>[
  RefeedCriterion(
    id: 'bmi14',
    label: 'BMI < 14 kg/m²',
    tier: 'extreme',
  ),
  RefeedCriterion(
    id: 'intake15',
    label: 'Negligible intake > 15 days',
    tier: 'extreme',
  ),
];

enum RefeedTier { notHighRisk, highRisk, extremeRisk }

class RefeedResult {
  const RefeedResult({
    required this.tier,
    required this.majorCount,
    required this.minorCount,
    required this.headline,
    required this.management,
  });

  final RefeedTier tier;
  final int majorCount;
  final int minorCount;
  final String headline;
  final String management;

  String clipboardSummary() {
    final t = switch (tier) {
      RefeedTier.notHighRisk => 'not high risk',
      RefeedTier.highRisk => 'HIGH RISK',
      RefeedTier.extremeRisk => 'EXTREME RISK',
    };
    return 'Refeeding risk ($majorCount major / $minorCount minor) '
        '— $t. $management';
  }
}

RefeedResult evaluateRefeeding(Set<String> ticked) {
  final major =
      kRefeedMajor.where((c) => ticked.contains(c.id)).length;
  final minor =
      kRefeedMinor.where((c) => ticked.contains(c.id)).length;
  final extreme =
      kRefeedExtreme.any((c) => ticked.contains(c.id));

  const monitoring =
      'Check K, PO₄, Mg, Ca, glucose at baseline and at least daily '
      'for the first 3 days (more often if abnormal). Give thiamine '
      '200–300 mg + balanced multivitamin / B-complex BEFORE and '
      'during the first 10 days of feeding. Replace electrolytes as '
      'feeding proceeds — do not delay feeding to fully correct them. '
      'Fluid balance + cardiac monitoring if severe.';

  if (extreme || (major >= 1 && minor >= 2 && extreme)) {
    return RefeedResult(
      tier: RefeedTier.extremeRisk,
      majorCount: major,
      minorCount: minor,
      headline: 'Extreme risk — MARSIPAN cautious start.',
      management:
          'Start nutrition at ~5 kcal/kg/day with continuous cardiac '
          'monitoring; build up slowly over 7+ days guided by daily '
          'electrolytes. $monitoring Manage in a setting able to '
          'deliver this safely (medical / specialist ED unit).',
    );
  }
  if (major >= 1 || minor >= 2) {
    return RefeedResult(
      tier: RefeedTier.highRisk,
      majorCount: major,
      minorCount: minor,
      headline: 'High risk of refeeding syndrome.',
      management:
          'Start nutrition at ~10 kcal/kg/day and build to full needs '
          'over 4–7 days. $monitoring',
    );
  }
  return RefeedResult(
    tier: RefeedTier.notHighRisk,
    majorCount: major,
    minorCount: minor,
    headline: 'Not high risk on current criteria.',
    management:
        'Standard nutritional management. Re-screen if intake falls '
        'or weight drops; baseline electrolytes are still prudent in '
        'severe mental illness with poor intake.',
  );
}
