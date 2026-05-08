// Subtle fade + slide-up reveal for content blocks.
//
// FAILSAFE BEHAVIOUR:
//   • When `delay === 0` (the first card / critical content) we start
//     visible. The animation runs as a no-op. This guarantees the most
//     important content is *never* hidden by an animation that fails
//     to fire (which can happen on the first navigation in Expo Go
//     before the JS bridge stabilises).
//
//   • When `delay > 0` (decorative staggering for downstream cards) we
//     start invisible and run the fade-in. If the animation fails to
//     fire for any reason, a setTimeout failsafe forces the values to
//     visible after delay + duration + 600ms — so even broken animation
//     doesn't permanently hide a card.
//
// Uses RN's built-in Animated API (no Reanimated worklet rules to fight)
// with `useNativeDriver: true` for performance on opacity + transform.
import { useEffect, useRef, type ReactNode } from 'react';
import { Animated } from 'react-native';

export function AnimatedReveal({
  children,
  delay = 0,
  durationMs = 220,
  offset = 8,
}: {
  children: ReactNode;
  delay?: number;
  durationMs?: number;
  offset?: number;
}) {
  const startInvisible = delay > 0;
  const opacity = useRef(new Animated.Value(startInvisible ? 0 : 1)).current;
  const ty = useRef(new Animated.Value(startInvisible ? offset : 0)).current;

  useEffect(() => {
    if (!startInvisible) {
      // First-card path: already visible, no animation needed.
      return;
    }

    const anim = Animated.parallel([
      Animated.timing(opacity, {
        toValue: 1,
        duration: durationMs,
        delay,
        useNativeDriver: true,
      }),
      Animated.timing(ty, {
        toValue: 0,
        duration: durationMs,
        delay,
        useNativeDriver: true,
      }),
    ]);
    anim.start();

    // Failsafe — if for any reason the Animated timing doesn't run to
    // completion (Expo Go bridge hiccup, paused screen, etc.) force
    // the values to their final state so the card is never permanently
    // invisible. Generous margin (+600ms) so legitimate animations
    // complete first.
    const failsafe = setTimeout(() => {
      opacity.setValue(1);
      ty.setValue(0);
    }, delay + durationMs + 600);

    return () => {
      anim.stop();
      clearTimeout(failsafe);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <Animated.View
      style={{
        opacity,
        transform: [{ translateY: ty }],
      }}
    >
      {children}
    </Animated.View>
  );
}
