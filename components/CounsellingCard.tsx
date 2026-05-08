// Counselling card — patient-facing version of the schedule, written
// in plain language. Collapsible so it doesn't dominate the screen
// when the clinician only needs the technical view.
//
// Generated from the engine output via formatCounsellingCard(). No LLM,
// no async. Pure template; future v0.4+ AI rewrites will swap the
// generator without changing this component.
import { useState } from 'react';
import { Pressable, Share, Text, View } from 'react-native';
import { CopyButton } from './CopyButton';
import { Icon } from './Icon';

export function CounsellingCard({ text }: { text: string }) {
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
        <View className="w-9 h-9 rounded-xl bg-to/15 border border-to/30 items-center justify-center mr-3">
          <Icon name="user" size={16} color="#34d399" />
        </View>
        <View className="flex-1">
          <Text className="text-text text-sm font-bold">Patient counselling card</Text>
          <Text className="text-muted text-micro">
            Plain-language handout · review before sharing
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
          <View className="px-4 py-3">
            <Text className="text-text text-[13px] leading-5" selectable>
              {text}
            </Text>
          </View>
          <View className="flex-row gap-2 px-4 py-3 border-t border-border">
            <View className="flex-1">
              <CopyButton text={text} label="Copy text" />
            </View>
            <Pressable
              onPress={onShare}
              className="flex-row items-center justify-center px-3 py-2 rounded-xl bg-bg border border-border active:opacity-80"
              accessibilityLabel="Share with patient via system sheet"
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
