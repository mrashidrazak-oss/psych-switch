// First-launch onboarding tour. 4 cards, swipe-to-advance, skippable.
//
// Persisted via AsyncStorage so it appears exactly once per device.
// Scrubbed by the same Reset → "Clear all local data" path in Settings.
//
// Designed to NOT block the disclaimer flow — onboarding shows AFTER
// the disclaimer has been acknowledged and AFTER the first time the
// user actually opens the home screen, so they see one modal at a
// time rather than two stacked.
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useEffect, useRef, useState } from 'react';
import {
  Animated,
  Dimensions,
  Modal,
  Pressable,
  Text,
  View,
  type NativeScrollEvent,
  type NativeSyntheticEvent,
} from 'react-native';
import { Icon, type IconName } from './Icon';
import { tap } from '../utils/haptics';

const STORAGE_KEY = 'psychswitch.onboarding.seen.v1';

interface Card {
  icon: IconName;
  iconTint: string;
  title: string;
  body: string;
  highlight: string;
}

const CARDS: Card[] = [
  {
    icon: 'activity',
    iconTint: '#3b82f6',
    title: 'Reviewed switching schedules',
    body: 'PsychSwitch produces cross-titration plans drawn from Maudsley 15th, BAP, NICE and the Malaysian CPGs. Every step is graded and citable.',
    highlight: 'Direct-guideline · paraphrase quotes one tap away',
  },
  {
    icon: 'sparkles',
    iconTint: '#34d399',
    title: 'Smart, patient-aware',
    body: 'Set patient context once (age, eGFR, pregnancy, comorbidities). The picker re-orders by clinical relevance, the schedule adapts to your entered doses, and the engine flags interactions in the overlap window.',
    highlight: 'PsychSwitch Score · 0–100 · single confidence number',
  },
  {
    icon: 'user',
    iconTint: '#60a5fa',
    title: 'Closes the workflow loop',
    body: 'Generates a discharge summary you can paste into the EMR, a plain-language counselling card for the patient, and a printable PDF — all from the same engine output.',
    highlight: 'Discharge · Patient handout · PDF',
  },
  {
    icon: 'shield',
    iconTint: '#f59e0b',
    title: 'Privacy-first',
    body: 'Patient context, saved cases, and sign-offs stay on this device. Nothing leaves unless you explicitly tap Share. No tracking, no analytics on your prescribing.',
    highlight: 'Local-only · no PHI · open errata channel',
  },
];

export function OnboardingTour() {
  const [visible, setVisible] = useState(false);
  const [index, setIndex] = useState(0);
  const scrollRef = useRef<{ scrollTo: (opts: { x: number; animated?: boolean }) => void } | null>(null);
  const fade = useRef(new Animated.Value(0)).current;
  const { width } = Dimensions.get('window');

  // Defer the visibility check by one tick so the disclaimer modal
  // (which has its own `acknowledged === null` guard) wins the
  // first-frame race. Smoother UX than two modals fighting.
  useEffect(() => {
    AsyncStorage.getItem(STORAGE_KEY).then((seen) => {
      if (!seen) {
        setVisible(true);
        Animated.timing(fade, {
          toValue: 1,
          duration: 220,
          useNativeDriver: true,
        }).start();
      }
    });
  }, [fade]);

  const dismiss = async () => {
    tap();
    Animated.timing(fade, {
      toValue: 0,
      duration: 160,
      useNativeDriver: true,
    }).start(({ finished }) => {
      if (finished) setVisible(false);
    });
    await AsyncStorage.setItem(STORAGE_KEY, '1');
  };

  const onScrollEnd = (e: NativeSyntheticEvent<NativeScrollEvent>) => {
    const offset = e.nativeEvent.contentOffset.x;
    const newIndex = Math.round(offset / width);
    if (newIndex !== index) {
      setIndex(newIndex);
      tap();
    }
  };

  const next = () => {
    if (index < CARDS.length - 1) {
      tap();
      const newIndex = index + 1;
      setIndex(newIndex);
      scrollRef.current?.scrollTo({ x: newIndex * width, animated: true });
    } else {
      dismiss();
    }
  };

  if (!visible) return null;

  return (
    <Modal visible={visible} transparent animationType="none" onRequestClose={dismiss}>
      <Animated.View
        style={{
          flex: 1,
          backgroundColor: 'rgba(11,15,20,0.96)',
          opacity: fade,
        }}
      >
        <View style={{ flex: 1 }}>
          {/* Skip */}
          <View style={{ flexDirection: 'row', justifyContent: 'flex-end', paddingTop: 56, paddingHorizontal: 20 }}>
            <Pressable
              onPress={dismiss}
              hitSlop={12}
              accessibilityLabel="Skip onboarding"
              className="active:opacity-60"
            >
              <Text className="text-muted text-sm">Skip</Text>
            </Pressable>
          </View>

          {/* Cards (horizontal swipe) */}
          <Animated.ScrollView
            ref={(r) => { scrollRef.current = r as never; }}
            horizontal
            pagingEnabled
            showsHorizontalScrollIndicator={false}
            onMomentumScrollEnd={onScrollEnd}
            style={{ flex: 1 }}
          >
            {CARDS.map((card, i) => (
              <View key={i} style={{ width, paddingHorizontal: 28, justifyContent: 'center' }}>
                <View
                  className="bg-surface border border-border rounded-3xl p-6"
                  style={{
                    shadowColor: card.iconTint,
                    shadowOffset: { width: 0, height: 6 },
                    shadowOpacity: 0.18,
                    shadowRadius: 16,
                    elevation: 4,
                  }}
                >
                  <View
                    className="w-14 h-14 rounded-2xl items-center justify-center mb-4"
                    style={{
                      backgroundColor: `${card.iconTint}1a`,
                      borderWidth: 1,
                      borderColor: `${card.iconTint}33`,
                    }}
                  >
                    <Icon name={card.icon} size={26} color={card.iconTint} />
                  </View>
                  <Text className="text-text text-2xl font-bold leading-tight mb-2">
                    {card.title}
                  </Text>
                  <Text className="text-muted text-sm leading-5 mb-4">
                    {card.body}
                  </Text>
                  <View className="bg-bg/60 rounded-xl px-3 py-2 border border-border">
                    <Text className="text-text text-micro font-medium" style={{ color: card.iconTint }}>
                      {card.highlight}
                    </Text>
                  </View>
                </View>
              </View>
            ))}
          </Animated.ScrollView>

          {/* Pagination dots */}
          <View
            style={{
              flexDirection: 'row',
              justifyContent: 'center',
              alignItems: 'center',
              paddingVertical: 12,
              gap: 8,
            }}
          >
            {CARDS.map((_, i) => (
              <View
                key={i}
                style={{
                  width: i === index ? 24 : 8,
                  height: 8,
                  borderRadius: 4,
                  backgroundColor: i === index ? '#3b82f6' : '#1f2933',
                }}
              />
            ))}
          </View>

          {/* CTA */}
          <View style={{ paddingHorizontal: 28, paddingBottom: 40 }}>
            <Pressable
              onPress={next}
              className="bg-accent rounded-2xl py-4 active:opacity-80"
              style={{
                shadowColor: '#3b82f6',
                shadowOffset: { width: 0, height: 4 },
                shadowOpacity: 0.25,
                shadowRadius: 12,
                elevation: 6,
              }}
            >
              <Text className="text-white text-base font-bold text-center">
                {index < CARDS.length - 1 ? 'Next' : "Let's go"}
              </Text>
            </Pressable>
          </View>
        </View>
      </Animated.View>
    </Modal>
  );
}
