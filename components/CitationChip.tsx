// Citation chip — tappable pill that opens a modal showing the full
// reference + paraphrased quote. The "show your work" feature.
//
// Use as a single chip:
//   <CitationChip citationKey="maudsley15_ch3_p369_table_3_7" />
//
// Or as a row of chips for a rule:
//   <CitationChips citationKeys={plan.citations} />
//
// As of v0.4.8 the chip is built on the unified Chip primitive. The
// previous bespoke per-source colour table (12 sources × 3 colour
// classes each) collapsed into a 4-tone mapping: guideline-grade
// (info/blue) vs regulatory (warning/amber) vs class-leading
// reference (success/teal) vs informal (neutral/gray). Cleaner, and
// matches the tone scale used everywhere else in the app.
import { useState } from 'react';
import { Modal, Pressable, ScrollView, Text, View } from 'react-native';
import { getCitation, type CitationSource } from '../engine/citations';
import { Chip, type ChipTone, TONE_HEX } from './Chip';
import { Icon } from './Icon';

const SOURCE_LABEL: Record<CitationSource, string> = {
  Maudsley15:     'Maudsley',
  BAP:            'BAP',
  NICE:           'NICE',
  FDA:            'FDA',
  EMA:            'EMA',
  'CPG-MY':       'CPG-MY',
  'meta-analysis': 'Meta-analysis',
  Ashton:         'Ashton',
  Horowitz:       'Horowitz',
  manufacturer:   'Manufacturer PI',
  expert:         'Expert',
  other:          'Source',
};

/**
 * Source → tone mapping. The semantic split:
 *   info     — major clinical guidelines (Maudsley, BAP, Ashton, Horowitz)
 *   success  — independent evidence-synthesis (NICE, meta-analysis)
 *   warning  — regulatory/manufacturer (FDA, EMA, CPG-MY, manufacturer PI)
 *   neutral  — informal sources (expert opinion, other)
 */
const SOURCE_TONE: Record<CitationSource, ChipTone> = {
  Maudsley15:     'info',
  BAP:            'info',
  Ashton:         'info',
  Horowitz:       'info',
  NICE:           'success',
  'meta-analysis': 'success',
  FDA:            'warning',
  EMA:            'warning',
  'CPG-MY':       'warning',
  manufacturer:   'warning',
  expert:         'neutral',
  other:          'neutral',
};

export function CitationChip({
  citationKey,
  compact = false,
}: {
  citationKey: string;
  compact?: boolean;
}) {
  const [open, setOpen] = useState(false);
  const cit = getCitation(citationKey);
  const tone = SOURCE_TONE[cit.source];
  const label = SOURCE_LABEL[cit.source];
  const fullLabel = cit.locator ? `${label} · ${cit.locator}` : label;

  return (
    <>
      <Chip
        tone={tone}
        size={compact ? 'sm' : 'md'}
        label={fullLabel}
        trailingIcon="info"
        onPress={() => setOpen(true)}
        accessibilityLabel={`Show ${label} citation`}
      />

      <Modal visible={open} transparent animationType="fade" onRequestClose={() => setOpen(false)}>
        <View
          style={{
            flex: 1,
            backgroundColor: 'rgba(0,0,0,0.6)',
            justifyContent: 'center',
            paddingHorizontal: 24,
          }}
        >
          <View
            style={{
              backgroundColor: '#141a22',
              borderRadius: 20,
              borderWidth: 1,
              borderColor: '#1f2933',
              maxHeight: '80%',
            }}
          >
            <ScrollView contentContainerStyle={{ padding: 20 }}>
              <View className="flex-row items-center mb-3">
                <Chip tone={tone} label={label} />
                <View className="flex-1" />
                <Pressable
                  onPress={() => setOpen(false)}
                  className="p-1 active:opacity-70"
                  accessibilityLabel="Close citation"
                >
                  <Icon name="check" size={18} color={TONE_HEX.neutral} />
                </Pressable>
              </View>

              {cit.locator && (
                <Text className="text-muted text-eyebrow uppercase tracking-widest font-bold mb-1">
                  Locator
                </Text>
              )}
              {cit.locator && (
                <Text className="text-text text-sm font-mono mb-3">{cit.locator}</Text>
              )}

              {cit.paraphrase && (
                <>
                  <Text className="text-muted text-eyebrow uppercase tracking-widest font-bold mb-1">
                    Paraphrase
                  </Text>
                  <View className="bg-bg border-l-2 border-accent rounded-r-md px-3 py-2 mb-4">
                    <Text className="text-text text-sm leading-5 italic">
                      {cit.paraphrase}
                    </Text>
                  </View>
                </>
              )}

              <Text className="text-muted text-eyebrow uppercase tracking-widest font-bold mb-1">
                Reference
              </Text>
              <Text className="text-text text-sm leading-5 mb-3">{cit.reference}</Text>

              <Text className="text-muted text-eyebrow mt-2">
                Paraphrased excerpts shown for clinical decision support; verify against the
                original source before acting. Quote &lt;15 words to respect copyright.
              </Text>
            </ScrollView>
          </View>
        </View>
      </Modal>
    </>
  );
}

export function CitationChips({
  citationKeys,
  max,
  compact,
}: {
  citationKeys: string[];
  max?: number;
  compact?: boolean;
}) {
  const visible = max ? citationKeys.slice(0, max) : citationKeys;
  const remainder = citationKeys.length - visible.length;

  return (
    <View className="flex-row flex-wrap" style={{ gap: 6 }}>
      {visible.map((k) => (
        <CitationChip key={k} citationKey={k} compact={compact} />
      ))}
      {remainder > 0 && (
        <Chip
          tone="neutral"
          size={compact ? 'sm' : 'md'}
          label={`+${remainder} more`}
        />
      )}
    </View>
  );
}
