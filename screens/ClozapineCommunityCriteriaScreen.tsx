// Clozapine community-initiation criteria.
//
// Per Maudsley 15th edition (p.236): when initiating clozapine outside
// an inpatient setting, certain relative contraindications, essential
// suitability criteria, and a baseline workup must be addressed before
// the first dose. This screen presents that checklist.
import { Text, View } from 'react-native';
import { ScreenContainer } from '../components/ScreenContainer';
import { getCommunityInitiation } from '../engine/clozapine';

export function ClozapineCommunityCriteriaScreen() {
  const data = getCommunityInitiation();

  return (
    <ScreenContainer>
      <Text className="text-text text-2xl font-semibold mb-1">
        Community initiation
      </Text>
      <Text className="text-muted text-sm mb-4">
        Suitability criteria, relative contraindications, and the initial
        work-up before any clozapine dose in the community setting.
      </Text>

      <View className="bg-surface border border-border rounded-2xl px-4 py-3 mb-4">
        <Text className="text-muted text-xs uppercase tracking-widest mb-1">
          Why this matters
        </Text>
        <Text className="text-text text-sm leading-5">{data.rationale}</Text>
      </View>

      {/* Relative contraindications */}
      <Text className="text-muted text-xs uppercase tracking-widest mb-2">
        Relative contraindications — DO NOT initiate in the community
      </Text>
      <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
        {data.relativeContraindications.map((c, i) => {
          const isLast = i === data.relativeContraindications.length - 1;
          return (
            <View
              key={c.id}
              className={`flex-row ${!isLast ? 'border-b border-border' : ''}`}
            >
              <View className="w-1.5 bg-danger" />
              <View className="flex-1 px-4 py-3">
                <Text className="text-text text-sm font-semibold mb-1">
                  {c.title}
                </Text>
                <Text className="text-muted text-xs leading-4">{c.detail}</Text>
              </View>
            </View>
          );
        })}
      </View>

      {/* Essential criteria */}
      <Text className="text-muted text-xs uppercase tracking-widest mb-2">
        Essential criteria — ALL must be met before initiation
      </Text>
      <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
        {data.essentialCriteria.map((c, i) => {
          const isLast = i === data.essentialCriteria.length - 1;
          return (
            <View
              key={c.id}
              className={`flex-row ${!isLast ? 'border-b border-border' : ''}`}
            >
              <View className="w-1.5 bg-warning" />
              <View className="flex-1 px-4 py-3">
                <Text className="text-text text-sm font-semibold mb-1">
                  ✓ {c.title}
                </Text>
                <Text className="text-muted text-xs leading-4">{c.detail}</Text>
              </View>
            </View>
          );
        })}
      </View>

      {/* Baseline workup */}
      <Text className="text-muted text-xs uppercase tracking-widest mb-2">
        Initial work-up — order at baseline
      </Text>
      <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
        {data.initialWorkup.map((c, i) => {
          const isLast = i === data.initialWorkup.length - 1;
          return (
            <View
              key={c.id}
              className={`flex-row ${!isLast ? 'border-b border-border' : ''}`}
            >
              <View className="w-1.5 bg-accent" />
              <View className="flex-1 px-4 py-3">
                <Text className="text-text text-sm font-semibold mb-1">
                  {c.title}
                </Text>
                <Text className="text-muted text-xs leading-4">{c.detail}</Text>
              </View>
            </View>
          );
        })}
      </View>

      {/* Monitoring intensity */}
      <Text className="text-muted text-xs uppercase tracking-widest mb-2">
        Monitoring intensity by phase
      </Text>
      <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
        <PhaseRow
          label="Weeks 1–4"
          detail={data.monitoringIntensity.first_4_weeks}
          highlighted
        />
        <PhaseRow
          label="Weeks 5–18"
          detail={data.monitoringIntensity.weeks_5_to_18}
        />
        <PhaseRow
          label="Weeks 19–52"
          detail={data.monitoringIntensity.weeks_19_to_52}
        />
        <PhaseRow
          label="Year 2 onwards"
          detail={data.monitoringIntensity.year_2_onwards}
          last
        />
      </View>

      {/* Citations */}
      <View className="bg-surface border border-border rounded-2xl px-4 py-3">
        <Text className="text-muted text-xs uppercase tracking-widest mb-1">
          Citations
        </Text>
        {data.citations.map((c, i) => (
          <Text key={c} className="text-text text-xs">
            [{i + 1}] {c}
          </Text>
        ))}
        <Text className="text-muted text-xs mt-2">
          Reviewed by: {data.reviewedBy}
        </Text>
      </View>
    </ScreenContainer>
  );
}

function PhaseRow({
  label,
  detail,
  highlighted,
  last,
}: {
  label: string;
  detail: string;
  highlighted?: boolean;
  last?: boolean;
}) {
  return (
    <View
      className={`px-4 py-3 ${!last ? 'border-b border-border' : ''} ${highlighted ? 'bg-accent/10' : ''}`}
    >
      <Text
        className={`text-sm font-semibold mb-1 ${highlighted ? 'text-accent' : 'text-text'}`}
      >
        {label}
      </Text>
      <Text className="text-muted text-xs leading-4">{detail}</Text>
    </View>
  );
}
