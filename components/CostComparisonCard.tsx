// Cost comparison card — Malaysian formulary cost (MYR) for the
// from-drug + to-drug, with tier (subsidised → expensive) and a
// delta hint ("RM 80/mo more").
//
// Renders only when at least one drug has cost data. The data is
// curated rough estimates, not real-time pricing — clearly labelled.
import { Text, View } from 'react-native';
import {
  costFor,
  formatMyr,
  tierColor,
  tierLabel,
} from '../engine/costData';
import type { Drug } from '../engine/types';
import { Icon } from './Icon';

export function CostComparisonCard({
  fromDrug,
  toDrug,
}: {
  fromDrug: Drug;
  toDrug: Drug;
}) {
  const fromCost = costFor(fromDrug.id);
  const toCost = costFor(toDrug.id);
  if (!fromCost && !toCost) return null;

  const delta =
    fromCost && toCost ? toCost.monthlyCostMyr - fromCost.monthlyCostMyr : null;
  const deltaLabel =
    delta == null
      ? null
      : delta === 0
        ? 'no change'
        : delta > 0
          ? `RM ${delta.toFixed(0)}/mo more`
          : `RM ${Math.abs(delta).toFixed(0)}/mo less`;
  const deltaTone =
    delta == null ? 'text-muted' : delta > 0 ? 'text-warning' : 'text-to';

  return (
    <View className="bg-surface border border-border rounded-2xl mt-3 px-4 py-3">
      <View className="flex-row items-center mb-2">
        <View className="w-9 h-9 rounded-xl bg-to/15 border border-to/30 items-center justify-center mr-3">
          <Icon name="document" size={16} color="#34d399" />
        </View>
        <View className="flex-1">
          <Text className="text-text text-sm font-bold">Affordability hint</Text>
          <Text className="text-muted text-micro">
            Estimated monthly cost · Malaysian Ringgit
          </Text>
        </View>
        {deltaLabel && (
          <Text className={`${deltaTone} text-micro font-bold`}>{deltaLabel}</Text>
        )}
      </View>

      <View className="flex-row" style={{ gap: 8 }}>
        <CostCell drug={fromDrug} entry={fromCost} side="from" />
        <View className="items-center justify-center">
          <Text className="text-muted text-base">→</Text>
        </View>
        <CostCell drug={toDrug} entry={toCost} side="to" />
      </View>

      <Text className="text-muted text-eyebrow leading-4 mt-3">
        Curated rough estimates from MOH formulary + retail pharmacy
        aggregates. Not real-time pricing — verify with your local
        procurement quote before counselling on cost.
      </Text>
    </View>
  );
}

function CostCell({
  drug,
  entry,
  side,
}: {
  drug: Drug;
  entry: ReturnType<typeof costFor>;
  side: 'from' | 'to';
}) {
  if (!entry) {
    return (
      <View className="flex-1 bg-bg/50 rounded-xl p-3">
        <Text className="text-muted text-eyebrow uppercase tracking-widest font-bold mb-1">
          {side === 'from' ? 'From' : 'To'}
        </Text>
        <Text className="text-text text-xs font-semibold" numberOfLines={1}>
          {drug.genericName}
        </Text>
        <Text className="text-muted text-micro mt-1">No cost data</Text>
      </View>
    );
  }
  const tint = tierColor(entry.tier);
  return (
    <View className="flex-1 bg-bg/50 rounded-xl p-3">
      <Text className="text-muted text-eyebrow uppercase tracking-widest font-bold mb-1">
        {side === 'from' ? 'From' : 'To'}
      </Text>
      <Text className="text-text text-xs font-semibold mb-1" numberOfLines={1}>
        {drug.genericName}
      </Text>
      <View className={`rounded-md ${tint.bg} px-2 py-0.5 self-start`}>
        <Text className={`${tint.text} text-eyebrow font-bold uppercase tracking-wider`}>
          {tierLabel(entry.tier)}
        </Text>
      </View>
      <Text className="text-text text-base font-bold mt-1">
        {formatMyr(entry.monthlyCostMyr)}/mo
      </Text>
      {entry.note && (
        <Text className="text-muted text-eyebrow leading-4 mt-1" numberOfLines={2}>
          {entry.note}
        </Text>
      )}
    </View>
  );
}
