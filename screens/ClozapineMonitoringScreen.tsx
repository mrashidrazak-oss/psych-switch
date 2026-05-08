// Clozapine monitoring schedule view: phases (weekly → fortnightly →
// monthly), specific milestones (baseline through year 1), and the
// CPMS-derived ANC/WBC traffic-light thresholds with BEN adjustment.
import { Text, View } from 'react-native';
import { ScreenContainer } from '../components/ScreenContainer';
import { getMonitoringSchedule } from '../engine/clozapine';

export function ClozapineMonitoringScreen() {
  const m = getMonitoringSchedule();
  const t = m.fbcThresholds;

  return (
    <ScreenContainer>
      <Text className="text-text text-2xl font-semibold mb-1">
        Clozapine monitoring
      </Text>
      <Text className="text-muted text-sm mb-4">{m.rationale}</Text>

      {/* Phases */}
      <Text className="text-muted text-xs uppercase tracking-widest mb-2">
        FBC + ANC frequency by phase
      </Text>
      <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
        {m.phases.map((p, i) => {
          const isLast = i === m.phases.length - 1;
          const range =
            p.weekEnd === null
              ? `Week ${p.weekStart}+ (indefinite)`
              : `Weeks ${p.weekStart}–${p.weekEnd}`;
          return (
            <View
              key={p.phase}
              className={`px-4 py-3 ${!isLast ? 'border-b border-border' : ''}`}
            >
              <View className="flex-row justify-between items-baseline mb-1">
                <Text className="text-text text-sm font-semibold capitalize">
                  {p.phase}
                </Text>
                <Text className="text-muted text-xs">{p.frequency}</Text>
              </View>
              <Text className="text-muted text-xs mb-1">{range}</Text>
              <Text className="text-muted text-xs leading-4">{p.notes}</Text>
            </View>
          );
        })}
      </View>

      {/* Traffic-light thresholds */}
      <Text className="text-muted text-xs uppercase tracking-widest mb-2">
        ANC / WBC traffic light ({t.unit})
      </Text>
      <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-2">
        <ZoneRow
          colorClass="bg-to"
          label="Green — continue"
          range={`ANC ≥${t.ancGreenAtOrAbove} & WBC ≥${t.wbcGreenAtOrAbove}`}
          action={t.actions.green}
        />
        <ZoneRow
          colorClass="bg-warning"
          label="Amber — close monitoring"
          range={`ANC ${t.ancAmberRange[0]}–${t.ancAmberRange[1]} or WBC ${t.wbcAmberRange[0]}–${t.wbcAmberRange[1]}`}
          action={t.actions.amber}
        />
        <ZoneRow
          colorClass="bg-danger"
          label="Red — STOP clozapine"
          range={`ANC <${t.ancRedBelow} or WBC <${t.wbcRedBelow}`}
          action={t.actions.red}
          last
        />
      </View>

      <View className="bg-surface border border-border rounded-2xl px-4 py-3 mb-4">
        <Text className="text-muted text-xs uppercase tracking-widest mb-1">
          BEN adjustment
        </Text>
        <Text className="text-text text-xs mb-1">
          Green ANC ≥{t.benAdjustment.ancGreenAtOrAbove}, amber{' '}
          {t.benAdjustment.ancAmberRange[0]}–{t.benAdjustment.ancAmberRange[1]},
          red &lt;{t.benAdjustment.ancRedBelow}
        </Text>
        <Text className="text-muted text-xs leading-4">
          {t.benAdjustment.notes}
        </Text>
      </View>

      {/* Milestones */}
      <Text className="text-muted text-xs uppercase tracking-widest mb-2">
        Milestone investigations
      </Text>
      <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
        {m.milestones.map((ms, i) => {
          const isLast = i === m.milestones.length - 1;
          return (
            <View
              key={ms.id}
              className={`px-4 py-3 ${!isLast ? 'border-b border-border' : ''}`}
            >
              <Text className="text-text text-sm font-semibold mb-1">
                {ms.timepoint}
              </Text>
              <Text className="text-muted text-xs mb-1">
                {ms.tests.join(' · ')}
              </Text>
              <Text className="text-muted text-xs leading-4">
                {ms.criticalNotes}
              </Text>
            </View>
          );
        })}
      </View>

      <View className="bg-surface border border-border rounded-2xl px-4 py-3">
        <Text className="text-muted text-xs uppercase tracking-widest mb-1">
          Citations
        </Text>
        {m.citations.map((c, i) => (
          <Text key={c} className="text-text text-xs">
            [{i + 1}] {c}
          </Text>
        ))}
        <Text className="text-muted text-xs mt-2">Reviewed by: {m.reviewedBy}</Text>
      </View>
    </ScreenContainer>
  );
}

function ZoneRow({
  colorClass,
  label,
  range,
  action,
  last,
}: {
  colorClass: string;
  label: string;
  range: string;
  action: string;
  last?: boolean;
}) {
  return (
    <View className={`flex-row ${!last ? 'border-b border-border' : ''}`}>
      <View className={`w-1.5 ${colorClass}`} />
      <View className="flex-1 px-4 py-3">
        <Text className="text-text text-sm font-semibold mb-1">{label}</Text>
        <Text className="text-muted text-xs mb-1">{range}</Text>
        <Text className="text-muted text-xs leading-4">{action}</Text>
      </View>
    </View>
  );
}
