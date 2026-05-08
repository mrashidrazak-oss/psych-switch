// Skeleton-loader primitive — gentle pulsing surface used while a list
// or chart is computing. Single component used in multiple shapes via
// width/height/borderRadius props.
//
// Animation: opacity oscillates 0.35 → 0.7 over 1100ms with a setInterval
// + Animated.timing. No reliance on requestAnimationFrame quirks; no
// reliance on first-render useEffect race (failsafe is a single
// setValue call inside the interval). Robust against the kind of
// Expo Go bridge-hiccup that took down AnimatedReveal earlier.
import { useEffect, useRef } from 'react';
import { Animated } from 'react-native';

export function Skeleton({
  width = '100%',
  height = 14,
  borderRadius = 8,
  style,
}: {
  width?: number | string;
  height?: number;
  borderRadius?: number;
  style?: object;
}) {
  const opacity = useRef(new Animated.Value(0.4)).current;

  useEffect(() => {
    let alive = true;
    let toggle = false;
    const id = setInterval(() => {
      if (!alive) return;
      toggle = !toggle;
      Animated.timing(opacity, {
        toValue: toggle ? 0.7 : 0.35,
        duration: 550,
        useNativeDriver: true,
      }).start();
    }, 600);
    return () => {
      alive = false;
      clearInterval(id);
    };
  }, [opacity]);

  return (
    <Animated.View
      style={[
        {
          width: width as never,
          height,
          borderRadius,
          backgroundColor: '#1f2933',
          opacity,
        },
        style,
      ]}
    />
  );
}

/** Convenience: 3 stacked skeleton rows mimicking a list. */
export function SkeletonList({ rows = 3 }: { rows?: number }) {
  return (
    <>
      {Array.from({ length: rows }).map((_, i) => (
        <Skeleton key={i} height={56} style={{ marginBottom: 8 }} />
      ))}
    </>
  );
}
