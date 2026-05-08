// Inline glossary tooltip — wraps a clinical term and shows a modal
// definition when tapped. Designed for use inline in body text:
//
//   <Text>Repeat <GlossaryTerm term="ESRS"/> at week 2.</Text>
//
// Renders the term with a subtle dotted underline so the user knows
// it's tappable. Tap → modal with definition + clinical relevance hint.
//
// If the term isn't in the glossary (engine/glossary.ts) we render
// plain text — no underline, no tap handler. This keeps callers
// fearless about wrapping anything.
import { useState } from 'react';
import { Modal, Pressable, Text, View } from 'react-native';
import { lookupTerm } from '../engine/glossary';
import { Icon } from './Icon';
import { tap as hapticTap } from '../utils/haptics';

export function GlossaryTerm({
  term,
  display,
}: {
  /** Lookup key — case-insensitive. Falls back to plain text if missing. */
  term: string;
  /** What to render. Defaults to the term itself uppercased for acronyms. */
  display?: string;
}) {
  const [open, setOpen] = useState(false);
  const entry = lookupTerm(term);
  const visibleText = display ?? (term.length <= 5 ? term.toUpperCase() : term);

  if (!entry) {
    // Term not registered — render as plain inline text.
    return <Text>{visibleText}</Text>;
  }

  return (
    <>
      <Text
        onPress={() => {
          hapticTap();
          setOpen(true);
        }}
        accessibilityRole="button"
        accessibilityLabel={`Glossary: ${term}`}
        className="text-accent"
        style={{ textDecorationLine: 'underline', textDecorationStyle: 'dotted' }}
      >
        {visibleText}
      </Text>

      <Modal
        visible={open}
        transparent
        animationType="fade"
        onRequestClose={() => setOpen(false)}
      >
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
              <View className="w-8 h-8 rounded-xl bg-accent/15 border border-accent/30 items-center justify-center mr-3">
                <Icon name="info" size={14} color="#3b82f6" />
              </View>
              <Text className="text-text text-base font-bold flex-1">
                {visibleText}
              </Text>
              <Pressable onPress={() => setOpen(false)} className="p-1 active:opacity-60">
                <Icon name="check" size={16} color="#8b949e" />
              </Pressable>
            </View>
            <Text className="text-text text-sm leading-5 mb-3">
              {entry.definition}
            </Text>
            {entry.relevance && (
              <View className="bg-bg/60 border-l-2 border-accent rounded-r-md px-3 py-2">
                <Text className="text-muted text-eyebrow uppercase tracking-widest font-bold mb-1">
                  Relevance
                </Text>
                <Text className="text-text text-xs leading-4">
                  {entry.relevance}
                </Text>
              </View>
            )}
          </View>
        </View>
      </Modal>
    </>
  );
}
