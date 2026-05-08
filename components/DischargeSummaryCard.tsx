// Discharge summary card — collapsible block with EMR-paste-ready text
// and a one-tap copy button. Shows the formatted summary inline in a
// monospace font so the clinician can scan for typos before pasting.
import { useState } from 'react';
import { Pressable, Share, Text, View } from 'react-native';
import { CopyButton } from './CopyButton';
import { Icon } from './Icon';

export function DischargeSummaryCard({ text }: { text: string }) {
  const [expanded, setExpanded] = useState(false);

  const onShare = async () => {
    try {
      await Share.share({ message: text });
    } catch {
      // user cancelled — silent
    }
  };

  return (
    <View className="bg-surface border border-border rounded-2xl mt-4 overflow-hidden">
      <Pressable
        onPress={() => setExpanded((e) => !e)}
        className="flex-row items-center px-4 py-3 active:opacity-80"
      >
        <View className="w-9 h-9 rounded-xl bg-accent/15 border border-accent/30 items-center justify-center mr-3">
          <Icon name="clipboard-check" size={16} color="#3b82f6" />
        </View>
        <View className="flex-1">
          <Text className="text-text text-sm font-bold">Discharge summary</Text>
          <Text className="text-muted text-micro">
            EMR-paste-ready · {text.split('\n').length} lines
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
          <View className="bg-bg/50 px-4 py-3">
            <Text
              className="text-text text-xs leading-5"
              style={{ fontFamily: 'Menlo' }}
              selectable
            >
              {text}
            </Text>
          </View>
          <View className="flex-row gap-2 px-4 py-3">
            <View className="flex-1">
              <CopyButton text={text} label="Copy to clipboard" />
            </View>
            <Pressable
              onPress={onShare}
              className="flex-row items-center justify-center px-3 py-2 rounded-xl bg-bg border border-border active:opacity-80"
              accessibilityLabel="Share via system sheet"
            >
              <Icon name="share" size={14} color="#8b949e" />
              <Text className="text-text text-xs font-semibold ml-1.5">Share</Text>
            </Pressable>
          </View>
        </View>
      )}
    </View>
  );
}
