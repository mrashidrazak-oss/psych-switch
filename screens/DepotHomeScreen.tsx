import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { Pressable, Text, View } from 'react-native';
import { ScreenContainer } from '../components/ScreenContainer';
import type { RootStackParamList } from '../utils/navigation';

type Props = NativeStackScreenProps<RootStackParamList, 'DepotHome'>;

export function DepotHomeScreen({ navigation }: Props) {
  return (
    <ScreenContainer>
      <Text className="text-text text-2xl font-semibold mb-1">
        LAI Depot Initiation
      </Text>
      <Text className="text-muted text-sm mb-6 leading-5">
        Step-by-step initiation protocols, maintenance dosing, missed-dose
        algorithms, and needle guides — sourced from FDA prescribing
        information (DailyMed, 2025).
      </Text>

      <Pressable
        onPress={() => navigation.navigate('Sustenna')}
        className="bg-surface border border-border rounded-2xl px-4 py-4 mb-3 active:opacity-80"
      >
        <View className="flex-row items-center mb-1">
          <View className="w-2.5 h-2.5 rounded-full bg-accent mr-2" />
          <Text className="text-text text-base font-bold">Invega Sustenna</Text>
        </View>
        <Text className="text-muted text-sm">Paliperidone palmitate · Once-monthly PP1M</Text>
        <Text className="text-muted text-xs mt-1.5 leading-4">
          Day 1 / Day 8 loading · 150 mg eq → 100 mg eq → 75 mg eq monthly.
          Renal dose adjustments required.
        </Text>
      </Pressable>

      <Pressable
        onPress={() => navigation.navigate('Maintena')}
        className="bg-surface border border-border rounded-2xl px-4 py-4 mb-3 active:opacity-80"
      >
        <View className="flex-row items-center mb-1">
          <View className="w-2.5 h-2.5 rounded-full bg-to mr-2" />
          <Text className="text-text text-base font-bold">Abilify Maintena</Text>
        </View>
        <Text className="text-muted text-sm">Aripiprazole monohydrate ER · Once-monthly</Text>
        <Text className="text-muted text-xs mt-1.5 leading-4">
          14-day oral overlap or 1-day dual-injection method · 400 mg monthly.
          CYP2D6 / CYP3A4 dose adjustments required.
        </Text>
      </Pressable>

      <Pressable
        onPress={() => navigation.navigate('Trinza')}
        className="bg-surface border border-border rounded-2xl px-4 py-4 mb-4 active:opacity-80"
      >
        <View className="flex-row items-center mb-1">
          <View className="w-2.5 h-2.5 rounded-full bg-warning mr-2" />
          <Text className="text-text text-base font-bold">Invega Trinza</Text>
        </View>
        <Text className="text-muted text-sm">Paliperidone palmitate PP3M · Once every 3 months</Text>
        <Text className="text-muted text-xs mt-1.5 leading-4">
          For patients stable on PP1M ≥ 4 months. PP1M → PP3M conversion table,
          missed-dose 3-tier algorithm, renal restrictions.
        </Text>
      </Pressable>

      <View className="bg-surface border border-border rounded-2xl px-4 py-3">
        <Text className="text-muted text-xs uppercase tracking-wider mb-1">
          Source
        </Text>
        <Text className="text-muted text-xs leading-4">
          Prescribing information sourced from FDA DailyMed (Janssen
          Pharmaceuticals and Otsuka America Pharmaceutical, February 2025).
          Always verify against the local Malaysian product insert before use.
        </Text>
      </View>
    </ScreenContainer>
  );
}
