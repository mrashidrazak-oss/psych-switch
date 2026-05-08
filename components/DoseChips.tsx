// Row of tappable dose chips. The available doses come from the drug's
// `dosing.increments` array — clinicians see only doses that are actually
// available at typical formulations, not arbitrary numbers.
import { Pressable, Text, View } from 'react-native';
import type { Drug } from '../engine/types';

export function DoseChips({
  drug,
  selectedDose,
  onSelect,
}: {
  drug: Drug;
  selectedDose: number | null;
  onSelect: (dose: number) => void;
}) {
  return (
    <View className="flex-row flex-wrap -mr-2 -mb-2">
      {drug.dosing.increments.map((dose) => {
        const isSelected = dose === selectedDose;
        return (
          <Pressable
            key={dose}
            onPress={() => onSelect(dose)}
            className={`mr-2 mb-2 px-4 py-2 rounded-full border active:opacity-80 ${
              isSelected
                ? 'bg-accent border-accent'
                : 'bg-surface border-border'
            }`}
          >
            <Text
              className={`text-sm font-semibold ${
                isSelected ? 'text-white' : 'text-text'
              }`}
            >
              {dose} mg
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}
