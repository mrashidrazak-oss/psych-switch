// Citations panel — full reference list with tappable chips for the
// "show your work" UX. Resolves each citation key against the registry
// in engine/citations.ts to render human-readable text.
//
// Key design decisions:
//   • Chips at the top for quick scanning + tap-to-expand
//   • Expanded list below for completeness in the detailed view
//   • <15 word paraphrased quotes only (copyright-safe)
import { Text, View } from 'react-native';
import { CitationChip } from './CitationChip';
import { getCitation } from '../engine/citations';

export function CitationsPanel({ citations }: { citations: string[] }) {
  if (!citations.length) return null;
  return (
    <View className="bg-surface border border-border rounded-2xl px-4 py-3 mt-4">
      <Text className="text-muted text-eyebrow uppercase tracking-widest font-bold mb-2">
        Citations
      </Text>

      {/* Chips — tap any for the paraphrased quote */}
      <View className="flex-row flex-wrap mb-3" style={{ gap: 6 }}>
        {citations.map((k) => (
          <CitationChip key={k} citationKey={k} />
        ))}
      </View>

      {/* Full bibliographic list */}
      {citations.map((k, i) => {
        const cit = getCitation(k);
        return (
          <View key={k} className="mb-1.5">
            <Text className="text-text text-xs leading-4">
              <Text className="text-muted">[{i + 1}] </Text>
              {cit.reference}
              {cit.locator ? (
                <Text className="text-muted"> — {cit.locator}</Text>
              ) : null}
            </Text>
          </View>
        );
      })}
    </View>
  );
}
