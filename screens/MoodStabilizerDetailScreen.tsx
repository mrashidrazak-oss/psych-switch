// Mood stabilizer detail screen — shows a single drug's profile, dosing,
// CYP interactions, and special considerations.
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { Text, View } from 'react-native';
import { ScreenContainer } from '../components/ScreenContainer';
import { getDrug } from '../engine/switchingEngine';
import type { RootStackParamList } from '../utils/navigation';

type Props = NativeStackScreenProps<RootStackParamList, 'MoodStabilizerDetail'>;

// Consideration severity is inferred from a DANGER prefix in the text.
function considerationSeverity(
  text: string,
): 'danger' | 'warning' | 'info' {
  if (text.startsWith('DANGER') || text.includes('(DANGER)')) return 'danger';
  if (text.startsWith('TERATOGEN') || text.startsWith('HLA') || text.startsWith('SLOW')) return 'danger';
  if (text.startsWith('EURAP') || text.startsWith('Monitoring') || text.startsWith('Drug interactions')) return 'warning';
  return 'info';
}

const STRIPE = {
  danger: 'bg-danger',
  warning: 'bg-warning',
  info: 'bg-accent',
} as const;

export function MoodStabilizerDetailScreen({ route }: Props) {
  const { drugId } = route.params;
  const drug = getDrug(drugId);

  if (!drug) {
    return (
      <ScreenContainer>
        <Text className="text-danger text-base">
          Drug not found: {drugId}
        </Text>
      </ScreenContainer>
    );
  }

  // specialConsiderations is a custom field on mood-stabilizer JSONs — not
  // part of the core Drug interface. Access via type assertion.
  const specialConsiderations: string[] =
    (drug as unknown as { specialConsiderations?: string[] })
      .specialConsiderations ?? [];

  return (
    <ScreenContainer>
      <Text className="text-text text-2xl font-semibold mb-1">
        {drug.genericName}
      </Text>
      <Text className="text-muted text-sm mb-1">{drug.drugClass}</Text>
      <Text className="text-muted text-xs mb-6">
        {drug.malaysianBrandNames.join(' · ')}
      </Text>

      {/* Dosing */}
      <SectionHeader title="Dosing" />
      <View className="bg-surface border border-border rounded-2xl px-4 py-4 mb-4">
        <InfoRow label="Starting dose" value={`${drug.dosing.startingDoseMg} mg`} />
        <InfoRow
          label="Typical range"
          value={`${drug.dosing.typicalTargetRangeMg[0]}–${drug.dosing.typicalTargetRangeMg[1]} mg/day`}
        />
        <InfoRow label="Maximum dose" value={`${drug.dosing.maxDoseMg} mg/day`} />
        <View className="mt-2">
          <Text className="text-muted text-xs uppercase tracking-wider mb-1">
            Available in Malaysia
          </Text>
          {drug.dosing.formulationsAvailableMy.map((f) => (
            <Text key={f} className="text-text text-xs">
              • {f}
            </Text>
          ))}
        </View>
        {drug.formulationNotes && (
          <Text className="text-muted text-xs mt-2 leading-4 italic">
            {drug.formulationNotes}
          </Text>
        )}
      </View>

      {/* Half-life */}
      <SectionHeader title="Pharmacokinetics" />
      <View className="bg-surface border border-border rounded-2xl px-4 py-4 mb-4">
        <InfoRow
          label="Half-life"
          value={`${drug.halfLife.meanHours}h mean (${drug.halfLife.rangeHours[0]}–${drug.halfLife.rangeHours[1]}h)`}
        />
        {drug.halfLife.notes && (
          <Text className="text-muted text-xs mt-2 leading-4">
            {drug.halfLife.notes}
          </Text>
        )}
        {drug.activeMetabolite.clinicallySignificant && (
          <>
            <View className="h-px bg-border my-3" />
            <InfoRow
              label="Active metabolite"
              value={drug.activeMetabolite.name ?? '—'}
            />
            <Text className="text-muted text-xs mt-1 leading-4">
              {drug.activeMetabolite.notes}
            </Text>
          </>
        )}
      </View>

      {/* Drug interactions */}
      <SectionHeader title="Drug interactions (switching relevance)" />
      <View className="bg-surface border border-border rounded-2xl px-4 py-4 mb-4">
        {drug.cypInteractions.substrateOf.length > 0 && (
          <InfoRow
            label="Substrate of"
            value={drug.cypInteractions.substrateOf.join(', ')}
          />
        )}
        {drug.cypInteractions.inhibitorOf.length > 0 && (
          <InfoRow
            label="Inhibitor of"
            value={drug.cypInteractions.inhibitorOf.join(', ')}
          />
        )}
        <Text className="text-muted text-xs mt-2 leading-4">
          {drug.cypInteractions.switchingRelevance}
        </Text>
      </View>

      {/* Special considerations */}
      {specialConsiderations.length > 0 && (
        <>
          <SectionHeader title="Special considerations" />
          {specialConsiderations.map((c, i) => {
            const sev = considerationSeverity(c);
            return (
              <View
                key={i}
                className="flex-row bg-surface border border-border rounded-2xl overflow-hidden mb-3"
              >
                <View className={`w-1.5 ${STRIPE[sev]}`} />
                <View className="flex-1 px-4 py-3">
                  <Text className="text-text text-sm leading-5">{c}</Text>
                </View>
              </View>
            );
          })}
        </>
      )}

      {/* Citations */}
      <View className="bg-surface border border-border rounded-2xl px-4 py-3 mt-2">
        <Text className="text-muted text-xs uppercase tracking-widest mb-1">
          Citations
        </Text>
        {drug.citations.map((c, i) => (
          <Text key={c} className="text-text text-xs">
            [{i + 1}] {c}
          </Text>
        ))}
        <Text className="text-muted text-xs mt-2">
          Reviewed by: {drug.reviewedBy}
        </Text>
      </View>
    </ScreenContainer>
  );
}

function SectionHeader({ title }: { title: string }) {
  return (
    <Text className="text-muted text-xs uppercase tracking-widest mb-2 mt-2">
      {title}
    </Text>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <View className="flex-row justify-between items-baseline mb-1">
      <Text className="text-muted text-xs flex-1">{label}</Text>
      <Text className="text-text text-sm font-medium flex-shrink-0 ml-2 text-right">
        {value}
      </Text>
    </View>
  );
}
