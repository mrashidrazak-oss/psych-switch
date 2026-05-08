// What-if alternatives card.
//
// Reuses the smartPicker engine to surface the top 3 *other* drugs the
// clinician could reasonably switch the patient to from the same
// from-drug, given the current patient context. The current to-drug is
// excluded — this is for the "if this doesn't work out" explorer
// scenario.
//
// Tap an alternative → start a new switch with that drug as the target.
// The patient context register persists, so the new Result will use
// the same patient-aware engine outputs.
import { useMemo } from 'react';
import { Pressable, Text, View } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { rankDrugs, type RelevanceTier } from '../engine/smartPicker';
import { listDrugs } from '../engine/switchingEngine';
import type { Drug } from '../engine/types';
import type { PatientContext } from '../engine/patientContext';
import type { RootStackParamList } from '../utils/navigation';
import { Chip, type ChipTone } from './Chip';
import { Icon } from './Icon';

const TIER_LABEL: Record<RelevanceTier, string> = {
  top:      '★ Best fit',
  reviewed: 'Reviewed',
  fallback: 'Fallback',
  caution:  'Caution',
  avoid:    'Avoid',
};

const TIER_TONE: Record<RelevanceTier, ChipTone> = {
  top:      'warning',  // ★ — stand-out amber, matches the star
  reviewed: 'success',
  fallback: 'neutral',
  caution:  'warning',
  avoid:    'danger',
};

export function AlternativesCard({
  fromDrug,
  currentToDrug,
  context,
}: {
  fromDrug: Drug;
  currentToDrug: Drug;
  context: PatientContext;
}) {
  const nav = useNavigation<NativeStackNavigationProp<RootStackParamList>>();

  const alternatives = useMemo(() => {
    const all = listDrugs().filter((d) => d.id !== fromDrug.id && d.id !== currentToDrug.id);
    const ranked = rankDrugs(all, { fromDrugId: fromDrug.id, context });
    // Surface the top 3 reviewed / top picks; never list "avoid" alternatives
    // — they're the wrong shape of suggestion.
    return ranked
      .filter((r) => r.tier === 'top' || r.tier === 'reviewed')
      .slice(0, 3);
  }, [fromDrug.id, currentToDrug.id, context]);

  if (alternatives.length === 0) return null;

  const goAlternative = (toDrug: Drug) => {
    nav.popToTop();
    nav.navigate('Result', {
      fromDrugId: fromDrug.id,
      fromDoseMg: fromDrug.dosing.startingDoseMg,
      toDrugId: toDrug.id,
      toDoseMg: toDrug.dosing.startingDoseMg,
    });
  };

  return (
    <View className="bg-surface border border-border rounded-2xl mt-3 overflow-hidden">
      <View className="flex-row items-center px-4 py-3">
        <View className="w-9 h-9 rounded-xl bg-from/15 border border-from/30 items-center justify-center mr-3">
          <Icon name="sparkles" size={16} color="#60a5fa" />
        </View>
        <View className="flex-1">
          <Text className="text-text text-sm font-bold">
            What if this doesn't work out?
          </Text>
          <Text className="text-muted text-micro">
            {alternatives.length} alternative {alternatives.length === 1 ? 'target' : 'targets'} from {fromDrug.genericName}
          </Text>
        </View>
      </View>

      <View className="border-t border-border">
        {alternatives.map((alt, i) => {
          const isLast = i === alternatives.length - 1;
          return (
            <Pressable
              key={alt.drug.id}
              onPress={() => goAlternative(alt.drug)}
              className={`flex-row items-center px-4 py-3 active:opacity-80 ${!isLast ? 'border-b border-border' : ''}`}
              accessibilityLabel={`Switch to ${alt.drug.genericName}, ${TIER_LABEL[alt.tier]}`}
            >
              <View className="flex-1">
                <Text className="text-text text-sm font-semibold">{alt.drug.genericName}</Text>
                <Text className="text-muted text-micro mt-0.5">
                  {alt.drug.drugClass}
                </Text>
              </View>
              <View className="mr-2">
                <Chip
                  tone={TIER_TONE[alt.tier]}
                  size="sm"
                  label={TIER_LABEL[alt.tier]}
                />
              </View>
              <Icon name="chevron-right" size={14} color="#6b7280" />
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}
