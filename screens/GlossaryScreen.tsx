// Glossary screen — alphabetical clinical-terms reference. Used as a
// standalone tool from Home, and indirectly by the GlossaryTerm
// component (inline tooltips) that reads from the same registry.
//
// Search box at the top filters as you type.
import { useMemo, useState } from 'react';
import { Text, TextInput, View } from 'react-native';
import { Icon } from '../components/Icon';
import { ScreenContainer } from '../components/ScreenContainer';
import { listGlossary } from '../engine/glossary';

export function GlossaryScreen() {
  const [q, setQ] = useState('');
  const all = useMemo(() => listGlossary(), []);
  const filtered = useMemo(() => {
    const needle = q.trim().toLowerCase();
    if (needle.length < 2) return all;
    return all.filter(
      (e) =>
        e.term.includes(needle) ||
        e.definition.toLowerCase().includes(needle) ||
        (e.relevance ?? '').toLowerCase().includes(needle),
    );
  }, [q, all]);

  return (
    <ScreenContainer>
      <Text className="text-text text-2xl font-bold mb-1">Glossary</Text>
      <Text className="text-muted text-sm leading-5 mb-4">
        Quick reference for clinical abbreviations and terms used
        throughout the app.
      </Text>

      {/* Search */}
      <View className="bg-surface border border-border rounded-2xl px-3 py-2.5 mb-4 flex-row items-center">
        <Icon name="search" size={16} color="#8b949e" />
        <TextInput
          value={q}
          onChangeText={setQ}
          placeholder="Search terms or definitions"
          placeholderTextColor="#6b7280"
          className="flex-1 text-text text-sm ml-2"
          returnKeyType="search"
          autoCorrect={false}
          autoCapitalize="none"
        />
      </View>

      {filtered.length === 0 && (
        <View className="bg-surface border border-border rounded-2xl px-4 py-6">
          <Text className="text-muted text-sm text-center">No matches.</Text>
        </View>
      )}

      <View className="bg-surface border border-border rounded-2xl overflow-hidden">
        {filtered.map((e, i) => (
          <View
            key={e.term}
            className={`px-4 py-3 ${i < filtered.length - 1 ? 'border-b border-border' : ''}`}
          >
            <Text className="text-text text-sm font-bold uppercase tracking-wider mb-1">
              {e.term}
            </Text>
            <Text className="text-text text-sm leading-5">{e.definition}</Text>
            {e.relevance && (
              <View className="bg-bg/60 border-l-2 border-accent rounded-r-md px-3 py-1.5 mt-2">
                <Text className="text-muted text-micro leading-4">
                  {e.relevance}
                </Text>
              </View>
            )}
          </View>
        ))}
      </View>
    </ScreenContainer>
  );
}
