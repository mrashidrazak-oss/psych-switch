// Lightweight toast — appears at the bottom of the screen, fades
// out after a fixed duration. Used for ephemeral confirmations
// like "Case saved" that don't need a full alert.
//
// Built with the same failsafe pattern as AnimatedReveal: starts
// visible, animation is additive only. The toast is gone once the
// duration elapses; the parent unmounts it.
import { useEffect, useRef } from 'react';
import { Animated, View, Text } from 'react-native';
import { Icon, type IconName } from './Icon';

export type ToastTone = 'success' | 'info' | 'warning' | 'danger';

const TONE_TINT: Record<ToastTone, { bg: string; border: string; iconHex: string }> = {
  success: { bg: 'bg-to/15',      border: 'border-to/40',      iconHex: '#34d399' },
  info:    { bg: 'bg-accent/15',  border: 'border-accent/40',  iconHex: '#3b82f6' },
  warning: { bg: 'bg-warning/15', border: 'border-warning/40', iconHex: '#f59e0b' },
  danger:  { bg: 'bg-danger/15',  border: 'border-danger/40',  iconHex: '#ef4444' },
};

const TONE_ICON: Record<ToastTone, IconName> = {
  success: 'check',
  info:    'info',
  warning: 'info',
  danger:  'shield',
};

export function Toast({
  visible,
  message,
  tone = 'success',
  onHide,
  durationMs = 1800,
}: {
  visible: boolean;
  message: string;
  tone?: ToastTone;
  onHide: () => void;
  durationMs?: number;
}) {
  const opacity = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (!visible) return;
    Animated.timing(opacity, {
      toValue: 1,
      duration: 180,
      useNativeDriver: true,
    }).start();
    const id = setTimeout(() => {
      Animated.timing(opacity, {
        toValue: 0,
        duration: 180,
        useNativeDriver: true,
      }).start(({ finished }) => {
        if (finished) onHide();
      });
    }, durationMs);
    return () => clearTimeout(id);
  }, [visible, opacity, onHide, durationMs]);

  if (!visible) return null;
  const tint = TONE_TINT[tone];

  return (
    <Animated.View
      pointerEvents="none"
      style={{
        position: 'absolute',
        left: 24,
        right: 24,
        bottom: 60,
        opacity,
        transform: [
          {
            translateY: opacity.interpolate({
              inputRange: [0, 1],
              outputRange: [10, 0],
            }),
          },
        ],
      }}
    >
      <View
        className={`bg-surface ${tint.border} border rounded-2xl px-4 py-3 flex-row items-center`}
        style={{
          shadowColor: '#000',
          shadowOffset: { width: 0, height: 4 },
          shadowOpacity: 0.3,
          shadowRadius: 12,
          elevation: 6,
        }}
      >
        <View className={`w-8 h-8 rounded-xl ${tint.bg} items-center justify-center mr-3`}>
          <Icon name={TONE_ICON[tone]} size={14} color={tint.iconHex} strokeWidth={2.5} />
        </View>
        <Text className="text-text text-sm flex-1" numberOfLines={2}>
          {message}
        </Text>
      </View>
    </Animated.View>
  );
}
