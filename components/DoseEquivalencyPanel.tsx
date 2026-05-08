// Dose equivalency panel — surfaces the rule's reviewed dose mapping so
// clinicians can sanity-check whether the target dose roughly matches the
// current dose. Sourced from the rule JSON's `doseRatios` block.
//
// Visual: From-dose tile · arrow · To-dose tile, with the equivalency note
// underneath as small grey text. The colour-coded dots match the schedule
// table's `bg-from` / `bg-to` palette so the eye carries the association
// across the screen.
import { Text, View } from 'react-native';
import type { Drug, SwitchingRule } from '../engine/types';

export function DoseEquivalencyPanel({
  fromDrug,
  toDrug,
  rule,
}: {
  fromDrug: Drug;
  toDrug: Drug;
  rule: SwitchingRule;
}) {
  const fromUnit = fromDrug.formulation === 'lai' ? 'mg/inj' : 'mg';
  const toUnit = toDrug.formulation === 'lai' ? 'mg/inj' : 'mg';

  // Strip the engine-internal audit marker before display.
  const cleanedNote = rule.doseRatios.equivalencyNote.replace(
    /\s*PENDING_CLINICAL_REVIEW\.?\s*$/i,
    '',
  ).trim();

  return (
    <View className="bg-surface border border-border rounded-2xl px-4 py-3 mb-3">
      <Text className="text-muted text-xs uppercase tracking-wider mb-2">
        Reviewed dose equivalency
      </Text>
      <View className="flex-row items-center mb-2">
        {/* From */}
        <View className="flex-1">
          <View className="flex-row items-center mb-0.5">
            <View className="w-2 h-2 rounded-full bg-from mr-1.5" />
            <Text className="text-muted text-eyebrow uppercase tracking-wider" numberOfLines={1}>
              {fromDrug.genericName}
            </Text>
          </View>
          <Text className="text-text text-base font-bold">
            {rule.doseRatios.fromCurrentDoseMg} {fromUnit}
          </Text>
        </View>
        {/* Arrow */}
        <Text className="text-muted text-base mx-2">≈</Text>
        {/* To */}
        <View className="flex-1">
          <View className="flex-row items-center mb-0.5">
            <View className="w-2 h-2 rounded-full bg-to mr-1.5" />
            <Text className="text-muted text-eyebrow uppercase tracking-wider" numberOfLines={1}>
              {toDrug.genericName}
            </Text>
          </View>
          <Text className="text-text text-base font-bold">
            {rule.doseRatios.toTargetDoseMg} {toUnit}
          </Text>
        </View>
      </View>
      {cleanedNote ? (
        <Text className="text-muted text-xs leading-4">{cleanedNote}</Text>
      ) : null}
    </View>
  );
}
