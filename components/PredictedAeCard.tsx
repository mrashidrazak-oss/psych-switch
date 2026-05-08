// Predicted adverse-effect profile for the to-drug.
//
// Rendered as a stack of rows, each carrying a likelihood pill (high /
// moderate / low / lower-than-current). Tap a row to expand and see
// the management note. The whole card is collapsed by default to
// avoid screen real-estate pressure on the Result screen.
import { useState } from 'react';
import { Pressable, Text, View } from 'react-native';
import {
  likelihoodLabel,
  type AeLikelihood,
  type PredictedAeProfile,
  type PredictedAe,
} from '../engine/predictedAeProfile';
import {
  formatEffect,
  quantitativeForAe,
} from '../engine/quantitativeAe';
import { Chip, type ChipTone } from './Chip';
import { Icon } from './Icon';

/** Map AE likelihood → Chip tone. */
function likelihoodTone(l: AeLikelihood): ChipTone {
  switch (l) {
    case 'high':                 return 'danger';
    case 'moderate':             return 'warning';
    case 'low':                  return 'info';
    case 'lower-than-current':   return 'success';
    case 'unknown':              return 'neutral';
  }
}

export function PredictedAeCard({ profile }: { profile: PredictedAeProfile }) {
  const [expanded, setExpanded] = useState(false);

  if (profile.predictions.length === 0) return null;

  const high = profile.predictions.filter((p) => p.likelihood === 'high').length;
  const moderate = profile.predictions.filter((p) => p.likelihood === 'moderate').length;
  const headline =
    high > 0
      ? `${high} likely · ${moderate} possible`
      : moderate > 0
        ? `${moderate} possible side effects`
        : 'Mostly favourable profile';

  return (
    <View className="bg-surface border border-border rounded-2xl mt-3 overflow-hidden">
      <Pressable
        onPress={() => setExpanded((e) => !e)}
        className="flex-row items-center px-4 py-3 active:opacity-80"
      >
        <View className="w-9 h-9 rounded-xl bg-warning/15 border border-warning/30 items-center justify-center mr-3">
          <Icon name="info" size={16} color="#f59e0b" />
        </View>
        <View className="flex-1">
          <Text className="text-text text-sm font-bold">
            Predicted side-effect profile
          </Text>
          <Text className="text-muted text-micro">
            {profile.toDrug.genericName} · {headline}
          </Text>
        </View>
        <Icon
          name={expanded ? 'chevron-left' : 'chevron-right'}
          size={16}
          color="#6b7280"
        />
      </Pressable>

      {expanded && (
        <View className="border-t border-border">
          {profile.predictions.map((p, i) => (
            <PredictionRow
              key={p.ae.id}
              prediction={p}
              isLast={i === profile.predictions.length - 1}
              toDrugId={profile.toDrug.id}
            />
          ))}
          <View className="px-4 py-2 bg-bg/50 border-t border-border">
            <Text className="text-muted text-micro leading-4">
              Likelihoods are tier-based (high / moderate / low) — not numeric
              probabilities. Drawn from per-drug profile fields and the
              adverse-effect reverse-lookup table. Verify with the
              Maudsley reference if a tier surprises you.
            </Text>
          </View>
        </View>
      )}
    </View>
  );
}

function PredictionRow({
  prediction,
  isLast,
  toDrugId,
}: {
  prediction: PredictedAe;
  isLast: boolean;
  toDrugId: string;
}) {
  const [open, setOpen] = useState(false);
  const quant = quantitativeForAe(toDrugId, prediction.ae.id);

  return (
    <Pressable
      onPress={() => setOpen((o) => !o)}
      className={`px-4 py-3 active:opacity-80 ${!isLast ? 'border-b border-border' : ''}`}
    >
      <View className="flex-row items-start">
        <View className="flex-1 pr-3">
          <Text className="text-text text-sm font-medium">{prediction.ae.label}</Text>
          {quant && (
            <Text className="text-muted text-micro mt-0.5 font-mono">
              {formatEffect(quant)}
            </Text>
          )}
          {open && (
            <>
              <Text className="text-muted text-micro leading-4 mt-1">
                {prediction.reason} {prediction.ae.management}
              </Text>
              {quant && (
                <Text className="text-muted text-eyebrow leading-4 mt-1">
                  Source: {quant.citation}
                  {quant.note ? ` · ${quant.note}` : ''}
                </Text>
              )}
            </>
          )}
        </View>
        <Chip
          tone={likelihoodTone(prediction.likelihood)}
          size="sm"
          label={likelihoodLabel(prediction.likelihood)}
        />
      </View>
    </Pressable>
  );
}
