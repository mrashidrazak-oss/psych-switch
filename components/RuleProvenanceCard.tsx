// Rule-provenance card — surfaces the trust signals that make a rule
// defensible at a CME: who reviewed it, when, when the next review is
// due, the rule ID, and the evidence grade.
//
// Designed to be visible in BOTH summary and detailed views (was
// previously buried in detailed-only). Trust signals shouldn't be a
// power-user feature — the clinician should see them every time they
// open a schedule.
//
// Review cadence: 90 days. Computed from `lastReviewedISO` on the rule.
// "Overdue" badge appears when next review is in the past.
import { Pressable, Text, View } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { EvidenceBadge } from './EvidenceBadge';
import { Icon } from './Icon';
import type { EvidenceGrade } from '../engine/citations';
import { errataForRule } from '../engine/errata';
import type { SwitchingRule } from '../engine/types';
import type { RootStackParamList } from '../utils/navigation';
import { computeReviewStatus, formatHumanDate } from '../utils/reviewCadence';

export function RuleProvenanceCard({
  rule,
  evidenceGrade,
  adapted = false,
}: {
  rule: SwitchingRule;
  evidenceGrade: EvidenceGrade;
  /** When true, an "(adapted)" subscript is added to the badge label. */
  adapted?: boolean;
}) {
  const nav = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const review = computeReviewStatus(rule.lastReviewedISO);
  const { nextReview, overdue } = review;
  const ruleErrata = errataForRule(rule.id);

  return (
    <View className="bg-surface border border-border rounded-2xl px-4 py-3 mt-3">
      <View className="flex-row items-start">
        <View className="w-9 h-9 rounded-xl bg-accent/15 border border-accent/30 items-center justify-center mr-3">
          <Icon name="clipboard-check" size={16} color="#3b82f6" />
        </View>
        <View className="flex-1">
          <Text className="text-muted text-eyebrow uppercase tracking-widest font-bold mb-0.5">
            Provenance
          </Text>
          <Text className="text-text text-sm font-semibold" numberOfLines={2}>
            {rule.reviewedBy}
          </Text>
          <View className="flex-row items-center mt-1 flex-wrap" style={{ gap: 8 }}>
            <View className="flex-row items-center">
              <View className="w-1.5 h-1.5 rounded-full bg-muted mr-1" />
              <Text className="text-muted text-micro">
                Reviewed {formatHumanDate(rule.lastReviewedISO)}
              </Text>
            </View>
            {nextReview && (
              <View className="flex-row items-center">
                <View
                  className={`w-1.5 h-1.5 rounded-full mr-1 ${overdue ? 'bg-warning' : 'bg-to'}`}
                />
                <Text className={`text-micro ${overdue ? 'text-warning font-semibold' : 'text-muted'}`}>
                  Next review {overdue ? 'overdue' : `due ${formatHumanDate(nextReview.toISOString())}`}
                </Text>
              </View>
            )}
          </View>
          <Text className="text-muted text-eyebrow mt-1.5 font-mono">
            {rule.id}
          </Text>
          {ruleErrata.length > 0 && (
            <Pressable
              onPress={() => nav.navigate('Errata')}
              className="flex-row items-center mt-2 active:opacity-70"
              accessibilityLabel={`${ruleErrata.length} corrections recorded for this rule. Tap to view errata.`}
            >
              <View className="w-1.5 h-1.5 rounded-full bg-warning mr-1.5" />
              <Text className="text-warning text-micro font-semibold">
                {ruleErrata.length} correction{ruleErrata.length === 1 ? '' : 's'} recorded
              </Text>
              <Icon name="chevron-right" size={12} color="#f59e0b" />
            </Pressable>
          )}
        </View>
        <View>
          <EvidenceBadge grade={evidenceGrade} compact />
          {adapted && (
            <Text className="text-muted text-eyebrow mt-1 text-right">
              (adapted)
            </Text>
          )}
        </View>
      </View>
    </View>
  );
}

