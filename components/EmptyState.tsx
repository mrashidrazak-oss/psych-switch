// Reusable empty-state block with icon, title, body, and an optional
// primary CTA. Used on Saved cases (when nothing saved yet), Search
// (no matches), and any other "nothing here yet" surface.
//
// Visual: large iconified circle, two-tier typography, subtle CTA button.
// Designed to feel like a deliberate "yes you're in the right place,
// here's what to do next" moment rather than a missing-feature stub.
import { Pressable, Text, View } from 'react-native';
import { Icon, type IconName } from './Icon';

export function EmptyState({
  icon,
  iconTint = '#3b82f6',
  title,
  body,
  ctaLabel,
  onCta,
}: {
  icon: IconName;
  iconTint?: string;
  title: string;
  body: string;
  ctaLabel?: string;
  onCta?: () => void;
}) {
  return (
    <View className="bg-surface border border-border rounded-2xl px-6 py-8 items-center">
      <View
        className="w-16 h-16 rounded-2xl items-center justify-center mb-4"
        style={{
          backgroundColor: `${iconTint}1a`,
          borderWidth: 1,
          borderColor: `${iconTint}33`,
        }}
      >
        <Icon name={icon} size={28} color={iconTint} />
      </View>
      <Text className="text-text text-base font-bold mb-1 text-center">
        {title}
      </Text>
      <Text
        className="text-muted text-xs leading-4 text-center max-w-[260px]"
      >
        {body}
      </Text>
      {ctaLabel && onCta && (
        <Pressable
          onPress={onCta}
          className="bg-accent rounded-xl px-5 py-2.5 mt-4 active:opacity-80"
        >
          <Text className="text-white text-sm font-semibold">{ctaLabel}</Text>
        </Pressable>
      )}
    </View>
  );
}
