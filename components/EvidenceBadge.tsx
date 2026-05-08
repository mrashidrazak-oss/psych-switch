// Evidence-grade badge — A / B / C / D pill with tap-to-explain modal.
// Communicates *how strong the evidence is* for this rule, not how
// safe the rule is. See engine/citations.ts for the grading logic.
//
// Built on the unified Chip primitive (v0.4.8) so the trigger pill
// shares its tone scale, padding, and corner radius with every other
// chip in the app.
import { useState } from 'react';
import { Modal, Pressable, Text, View } from 'react-native';
import {
  type EvidenceGrade,
  gradeDescription,
  gradeLabel,
} from '../engine/citations';
import { Chip, ChipDot, type ChipTone } from './Chip';
import { Icon } from './Icon';

/** Map evidence grade A–D to a Chip tone. */
function gradeTone(g: EvidenceGrade): ChipTone {
  switch (g) {
    case 'A': return 'success';
    case 'B': return 'info';
    case 'C': return 'warning';
    case 'D': return 'danger';
  }
}

export function EvidenceBadge({
  grade,
  compact = false,
}: {
  grade: EvidenceGrade;
  compact?: boolean;
}) {
  const [open, setOpen] = useState(false);
  const tone = gradeTone(grade);

  return (
    <>
      <Chip
        tone={tone}
        size={compact ? 'sm' : 'md'}
        label={compact ? 'Evidence' : gradeLabel(grade)}
        leading={<ChipDot text={grade} tone={tone} size={compact ? 'sm' : 'md'} />}
        onPress={() => setOpen(true)}
        accessibilityLabel={`Evidence grade ${grade} — ${gradeLabel(grade)}. Tap for explanation.`}
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
              padding: 20,
            }}
          >
            <View className="flex-row items-center mb-3">
              <ChipDot text={grade} tone={tone} size="md" />
              <View className="flex-1 ml-1">
                <Text className="text-muted text-eyebrow uppercase tracking-widest font-bold">
                  Evidence
                </Text>
                <Text className="text-text text-base font-bold">{gradeLabel(grade)}</Text>
              </View>
              <Pressable onPress={() => setOpen(false)} className="p-1 active:opacity-70">
                <Icon name="check" size={18} color="#8b949e" />
              </Pressable>
            </View>

            <Text className="text-text text-sm leading-5 mb-4">
              {gradeDescription(grade)}
            </Text>

            <Text className="text-muted text-eyebrow uppercase tracking-widest font-bold mb-2">
              Grading scale
            </Text>
            <GradeRow grade="A" />
            <GradeRow grade="B" />
            <GradeRow grade="C" />
            <GradeRow grade="D" />

            <Text className="text-muted text-xs leading-4 mt-3">
              Grade describes the strength of evidence, not the safety of
              the rule. A and B rules are equally usable; C and D require
              more individual judgement.
            </Text>
          </View>
        </View>
      </Modal>
    </>
  );
}

function GradeRow({ grade }: { grade: EvidenceGrade }) {
  const tone = gradeTone(grade);
  return (
    <View className="flex-row items-start mb-2">
      <ChipDot text={grade} tone={tone} size="md" />
      <View className="flex-1 ml-1">
        <Text className="text-text text-xs font-bold">{gradeLabel(grade)}</Text>
        <Text className="text-muted text-micro leading-4">{gradeDescription(grade)}</Text>
      </View>
    </View>
  );
}
