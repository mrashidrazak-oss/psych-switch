// Rationale panel — explains WHY this particular strategy was chosen for
// this drug pair. Collapses long clinical explanations behind a "Read more"
// toggle so the schedule itself stays the focal point of the screen.
//
// The rationale string is sourced from the rule JSON's `rationale` field
// and is written for clinicians (mentions receptor profiles, half-lives,
// EPS risk, etc.). It is the single most important explanatory text on
// the screen — without it, the schedule is opaque.
import { useState } from 'react';
import { Pressable, Text, View } from 'react-native';

const PREVIEW_CHAR_LIMIT = 180;

export function RationalePanel({ rationale }: { rationale: string }) {
  const [expanded, setExpanded] = useState(false);

  // Strip the audit suffix so it doesn't confuse clinicians reading the
  // explanation. The "PENDING_CLINICAL_REVIEW" marker is engine-internal.
  const cleaned = rationale.replace(/\s*PENDING_CLINICAL_REVIEW\.?\s*$/i, '').trim();
  const isLong = cleaned.length > PREVIEW_CHAR_LIMIT;
  const preview = isLong ? cleaned.slice(0, PREVIEW_CHAR_LIMIT).trimEnd() + '…' : cleaned;

  return (
    <View className="bg-surface border border-border rounded-2xl px-4 py-3 mb-3">
      <Text className="text-muted text-xs uppercase tracking-wider mb-1.5">
        Why this strategy
      </Text>
      <Text className="text-text text-sm leading-5">
        {expanded || !isLong ? cleaned : preview}
      </Text>
      {isLong ? (
        <Pressable
          onPress={() => setExpanded((v) => !v)}
          hitSlop={8}
          className="mt-2 active:opacity-60"
        >
          <Text className="text-accent text-xs font-semibold">
            {expanded ? 'Show less' : 'Read more'}
          </Text>
        </Pressable>
      ) : null}
    </View>
  );
}
