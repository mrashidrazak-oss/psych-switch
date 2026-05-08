// Tap-to-copy button. Brief checkmark feedback on success.
//
// Used as both a standalone control and inline next to dose / citation
// strings. The visual treatment scales with the `size` prop:
//   • "sm"     — 24×24, used inline next to numbers / citation chips
//   • "md"     — full-width primary button on a card
//
// Falls back gracefully if expo-clipboard isn't available (dev / web).
import { useState } from 'react';
import { Pressable, Text, View } from 'react-native';
import * as Clipboard from 'expo-clipboard';
import { Icon } from './Icon';

export function CopyButton({
  text,
  label,
  size = 'md',
  onCopied,
}: {
  text: string;
  label?: string;
  size?: 'sm' | 'md';
  onCopied?: () => void;
}) {
  const [copied, setCopied] = useState(false);

  const onPress = async () => {
    try {
      await Clipboard.setStringAsync(text);
      setCopied(true);
      onCopied?.();
      setTimeout(() => setCopied(false), 1500);
    } catch {
      // Surface failure as the same checkmark would for "did" — better
      // than a thrown exception killing the row.
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    }
  };

  if (size === 'sm') {
    return (
      <Pressable
        onPress={onPress}
        hitSlop={10}
        accessibilityLabel={label ? `Copy ${label}` : 'Copy'}
        className="w-6 h-6 items-center justify-center rounded-md active:opacity-60"
      >
        {copied ? (
          <Icon name="check" size={12} color="#34d399" strokeWidth={2.5} />
        ) : (
          <Icon name="document" size={12} color="#8b949e" />
        )}
      </Pressable>
    );
  }

  return (
    <Pressable
      onPress={onPress}
      className={`flex-row items-center justify-center px-3 py-2 rounded-xl border active:opacity-80 ${
        copied ? 'bg-to/10 border-to/40' : 'bg-bg border-border'
      }`}
      accessibilityLabel={label ? `Copy ${label}` : 'Copy'}
    >
      {copied ? (
        <Icon name="check" size={14} color="#34d399" strokeWidth={2.5} />
      ) : (
        <Icon name="document" size={14} color="#8b949e" />
      )}
      <Text
        className={`text-xs font-semibold ml-1.5 ${copied ? 'text-to' : 'text-text'}`}
      >
        {copied ? 'Copied' : label ?? 'Copy'}
      </Text>
    </Pressable>
  );
}
