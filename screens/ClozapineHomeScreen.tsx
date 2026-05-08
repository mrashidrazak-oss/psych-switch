// Clozapine module home — entry point for the dedicated clozapine
// initiation, monitoring and safety workflows. Clozapine is too high-
// stakes to fold into the standard switch flow.
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { Pressable, Text, View } from 'react-native';
import { ScreenContainer } from '../components/ScreenContainer';
import { getSafetyConsiderations } from '../engine/clozapine';
import { getFlagDisplay } from '../utils/safetyFlags';
import type { RootStackParamList } from '../utils/navigation';

type Props = NativeStackScreenProps<RootStackParamList, 'ClozapineHome'>;

export function ClozapineHomeScreen({ navigation }: Props) {
  const safety = getSafetyConsiderations();
  const dangerCount = safety.considerations.filter(
    (c) => c.severity === 'danger',
  ).length;

  return (
    <ScreenContainer>
      <Text className="text-text text-3xl font-semibold mb-1">Clozapine</Text>
      <Text className="text-muted text-sm mb-6">
        Treatment-resistant schizophrenia. Highest-stakes oral antipsychotic in
        the registry — dedicated workflow.
      </Text>

      <NavTile
        title="Initiation: titration schedule"
        subtitle="Inpatient and community protocols, day-by-day with AM/PM splits."
        onPress={() => navigation.navigate('ClozapineInitiation')}
      />
      <NavTile
        title="Mandatory monitoring"
        subtitle="FBC + ANC schedule, cardiac and metabolic milestones, ANC traffic-light thresholds (incl. BEN)."
        onPress={() => navigation.navigate('ClozapineMonitoring')}
      />
      <NavTile
        title="ANC / WBC checker"
        subtitle="Enter today's lab values — get the CPMS green / amber / red classification instantly. BEN toggle included."
        onPress={() => navigation.navigate('ClozapineAncChecker')}
      />
      <NavTile
        title="Interruption restart wizard"
        subtitle="Patient missed doses? Enter the gap duration to get the correct restart strategy and retitration guidance."
        onPress={() => navigation.navigate('ClozapineRechallenge')}
      />
      <NavTile
        title="Community initiation criteria"
        subtitle="Suitability checklist, relative contraindications and baseline work-up before initiating clozapine outside an inpatient setting (Maudsley 15th)."
        onPress={() => navigation.navigate('ClozapineCommunityCriteria')}
      />

      <Text className="text-muted text-xs uppercase tracking-widest mt-8 mb-3">
        Safety at a glance
      </Text>
      <Text className="text-muted text-xs leading-4 mb-3">
        {dangerCount} danger-grade considerations. Tap monitoring above for
        full action thresholds.
      </Text>

      {safety.considerations.map((c) => {
        const flag = getFlagDisplay(`clozapine-${c.id}`);
        // Use the per-consideration severity directly (engine doesn't
        // need to round-trip through utils/safetyFlags for clozapine).
        return (
          <View
            key={c.id}
            className="flex-row bg-surface border border-border rounded-2xl mb-3 overflow-hidden"
          >
            <View
              className={`w-1.5 ${
                c.severity === 'danger'
                  ? 'bg-danger'
                  : c.severity === 'warning'
                    ? 'bg-warning'
                    : 'bg-accent'
              }`}
            />
            <View className="flex-1 px-4 py-3">
              <Text className="text-muted text-eyebrow uppercase tracking-widest mb-1">
                {c.severity}
              </Text>
              <Text className="text-text text-base font-semibold mb-1">
                {c.title}
              </Text>
              <Text className="text-muted text-sm leading-5">{c.body}</Text>
              <Text className="text-muted text-xs mt-2 italic">
                Monitoring: {c.monitoring}
              </Text>
            </View>
            {/* `flag` ref kept so getFlagDisplay isn't tree-shaken if
                we later route clozapine flags through the central map. */}
            {flag ? null : null}
          </View>
        );
      })}

      <View className="bg-surface border border-border rounded-2xl px-4 py-3 mt-2">
        <Text className="text-muted text-xs uppercase tracking-widest mb-1">
          Citations
        </Text>
        {safety.citations.map((c, i) => (
          <Text key={c} className="text-text text-xs">
            [{i + 1}] {c}
          </Text>
        ))}
        <Text className="text-muted text-xs mt-2">
          Reviewed by: {safety.reviewedBy}
        </Text>
      </View>
    </ScreenContainer>
  );
}

function NavTile({
  title,
  subtitle,
  onPress,
}: {
  title: string;
  subtitle: string;
  onPress: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      className="bg-surface border border-border rounded-2xl px-4 py-4 mb-3 active:opacity-80"
    >
      <Text className="text-text text-base font-semibold mb-1">{title}</Text>
      <Text className="text-muted text-sm leading-5">{subtitle}</Text>
    </Pressable>
  );
}
