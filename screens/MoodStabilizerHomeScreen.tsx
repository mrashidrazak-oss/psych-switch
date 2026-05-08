// Mood stabilizer module — overview of lithium, valproate, lamotrigine
// and carbamazepine with key safety flags and navigation to detail views.
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { Pressable, Text, View } from 'react-native';
import { Banner } from '../components/Banner';
import { ScreenContainer } from '../components/ScreenContainer';
import { getDrug } from '../engine/switchingEngine';
import type { RootStackParamList } from '../utils/navigation';

type Props = NativeStackScreenProps<RootStackParamList, 'MoodStabilizerHome'>;

const DRUGS = ['lithium', 'valproate', 'lamotrigine', 'carbamazepine'] as const;

// Key safety badge for each drug — one-liner, colour-coded.
const KEY_FLAG: Record<
  string,
  { label: string; severity: 'danger' | 'warning' | 'info' }
> = {
  lithium: {
    label: 'Narrow therapeutic index — level monitoring mandatory',
    severity: 'warning',
  },
  valproate: {
    label: 'High teratogenicity — contraindicated in women of CP without EURAP',
    severity: 'danger',
  },
  lamotrigine: {
    label: 'SJS risk — SLOW titration mandatory, stop on rash',
    severity: 'danger',
  },
  carbamazepine: {
    label: 'HLA-B*1502 screen MANDATORY in Asians before prescribing',
    severity: 'danger',
  },
};

const SEVERITY_COLOR = {
  danger: 'bg-danger',
  warning: 'bg-warning',
  info: 'bg-accent',
} as const;

export function MoodStabilizerHomeScreen({ navigation }: Props) {
  return (
    <ScreenContainer>
      <Text className="text-text text-3xl font-semibold mb-1">
        Mood stabilizers
      </Text>
      <Text className="text-muted text-sm mb-6">
        Lithium, valproate, lamotrigine, carbamazepine. Includes switching
        guidance for the critical LTG pharmacokinetic interactions.
      </Text>

      {DRUGS.map((id) => {
        const drug = getDrug(id);
        if (!drug) return null;
        const flag = KEY_FLAG[id];
        return (
          <Pressable
            key={id}
            onPress={() => navigation.navigate('MoodStabilizerDetail', { drugId: id })}
            className="bg-surface border border-border rounded-2xl overflow-hidden mb-3 active:opacity-80"
          >
            <View className="flex-row">
              <View className={`w-1.5 ${flag ? SEVERITY_COLOR[flag.severity] : 'bg-border'}`} />
              <View className="flex-1 px-4 py-4">
                <View className="flex-row items-baseline justify-between mb-1">
                  <Text className="text-text text-base font-semibold">
                    {drug.genericName}
                  </Text>
                  <Text className="text-muted text-xs">
                    {drug.drugClass}
                  </Text>
                </View>
                <Text className="text-muted text-xs mb-2">
                  {drug.malaysianBrandNames.join(' · ')}
                </Text>
                {flag && (
                  <View className={`rounded-lg px-2 py-1.5 ${
                    flag.severity === 'danger'
                      ? 'bg-danger/10'
                      : flag.severity === 'warning'
                        ? 'bg-warning/10'
                        : 'bg-accent/10'
                  }`}>
                    <Text
                      className={`text-xs leading-4 ${
                        flag.severity === 'danger'
                          ? 'text-danger'
                          : flag.severity === 'warning'
                            ? 'text-warning'
                            : 'text-accent'
                      }`}
                    >
                      {flag.label}
                    </Text>
                  </View>
                )}
              </View>
            </View>
          </Pressable>
        );
      })}

      {/* Lithium tapering tile (Maudsley 15 dedicated guidance) */}
      <Pressable
        onPress={() => navigation.navigate('LithiumTapering')}
        className="active:opacity-80 mb-3"
      >
        <Banner
          tone="warning"
          eyebrow="Stopping lithium — slow taper"
          body="Maudsley 15 Box 2.3 reduction regimen, withdrawal effects, and hyperbolic tapering principles. Manic rebound risk is 7× untreated rate after rapid cessation."
        />
      </Pressable>

      {/* Switching guidance callout */}
      <View className="bg-surface border border-border rounded-2xl px-4 py-4 mt-2">
        <Text className="text-muted text-xs uppercase tracking-widest mb-2">
          Switching rules — key interactions
        </Text>
        <InteractionRow
          label="CBZ → LTG"
          detail="As CBZ is withdrawn, LTG levels RISE (CYP induction lost). Reduce LTG dose in step."
          severity="danger"
        />
        <InteractionRow
          label="VPA → LTG"
          detail="As VPA is withdrawn, LTG levels FALL (UGT inhibition relieved). Increase LTG dose in step."
          severity="danger"
        />
        <Text className="text-muted text-xs mt-3 leading-4">
          Use the 'Start a switch' flow on the Home screen and select these
          drug pairs to see the full step-by-step schedule.
        </Text>
      </View>
    </ScreenContainer>
  );
}

function InteractionRow({
  label,
  detail,
  severity,
}: {
  label: string;
  detail: string;
  severity: 'danger' | 'warning';
}) {
  return (
    <View className="flex-row mb-2">
      <View className={`w-1 ${severity === 'danger' ? 'bg-danger' : 'bg-warning'} rounded-full mr-3 my-1`} />
      <View className="flex-1">
        <Text className="text-text text-sm font-semibold">{label}</Text>
        <Text className="text-muted text-xs leading-4 mt-0.5">{detail}</Text>
      </View>
    </View>
  );
}
