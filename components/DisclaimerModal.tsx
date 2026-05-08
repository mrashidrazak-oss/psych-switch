// First-launch disclaimer gate. The user must explicitly tap "I understand"
// before the rest of the app becomes accessible. We persist the
// acknowledgement locally with AsyncStorage so the modal only appears once
// per install.
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useEffect, useState } from 'react';
import { Modal, Pressable, ScrollView, Text, View } from 'react-native';
import { Icon } from './Icon';

const ACK_KEY = 'psychswitch.disclaimer.ack.v1';

export function useDisclaimerGate() {
  const [acknowledged, setAcknowledged] = useState<boolean | null>(null);

  useEffect(() => {
    AsyncStorage.getItem(ACK_KEY)
      .then((v) => setAcknowledged(v === 'true'))
      .catch(() => setAcknowledged(false));
  }, []);

  const acknowledge = async () => {
    await AsyncStorage.setItem(ACK_KEY, 'true');
    setAcknowledged(true);
  };

  return { acknowledged, acknowledge };
}

export function DisclaimerModal({
  visible,
  onAcknowledge,
}: {
  visible: boolean;
  onAcknowledge: () => void;
}) {
  return (
    <Modal visible={visible} animationType="fade" transparent={false}>
      <View className="flex-1 bg-bg">
        <ScrollView
          contentContainerStyle={{
            flexGrow: 1,
            justifyContent: 'center',
            paddingHorizontal: 24,
            paddingVertical: 48,
          }}
        >
          {/* Brand mark */}
          <View className="flex-row items-center mb-6">
            <View className="w-10 h-10 rounded-xl bg-accent/15 border border-accent/30 items-center justify-center mr-3">
              <Icon name="activity" size={20} color="#3b82f6" />
            </View>
            <View>
              <Text className="text-text text-xl font-bold leading-tight">
                PsychSwitch
              </Text>
              <Text className="text-muted text-eyebrow uppercase tracking-widest">
                ASEAN edition
              </Text>
            </View>
          </View>

          {/* Headline */}
          <Text className="text-text text-2xl font-bold leading-snug mb-1">
            Decision support,
          </Text>
          <Text className="text-muted text-2xl font-bold leading-snug mb-5">
            not medical advice.
          </Text>

          {/* Bullets */}
          <View className="bg-surface border border-border rounded-2xl px-4 py-4 mb-5">
            <DisclaimerBullet
              title="For qualified clinicians"
              body="Reference cross-titration schedules drawn from Maudsley 15th, BAP 2020, NICE, and the Malaysian CPGs."
            />
            <DisclaimerBullet
              title="Not a substitute for clinical judgment"
              body="Final prescribing decisions always rest with the treating clinician — patient factors, comorbidities, and local guidance take precedence."
            />
            <DisclaimerBullet
              title="Cross-check primary sources"
              body="Verify dosing against the original references and your patient's individual context before acting on any plan."
              isLast
            />
          </View>

          <Pressable
            onPress={onAcknowledge}
            className="bg-accent rounded-2xl py-4 flex-row items-center justify-center active:opacity-80"
            style={{
              shadowColor: '#3b82f6',
              shadowOffset: { width: 0, height: 4 },
              shadowOpacity: 0.25,
              shadowRadius: 12,
              elevation: 6,
            }}
          >
            <Icon name="check" size={18} color="#ffffff" strokeWidth={2.5} />
            <Text className="text-white text-base font-semibold ml-2">
              I am a healthcare professional
            </Text>
          </Pressable>
          <Text className="text-muted text-xs text-center mt-3">
            By tapping above you confirm you understand the limitations.
          </Text>
        </ScrollView>
      </View>
    </Modal>
  );
}

function DisclaimerBullet({
  title,
  body,
  isLast,
}: {
  title: string;
  body: string;
  isLast?: boolean;
}) {
  return (
    <View className={`flex-row ${isLast ? '' : 'mb-3 pb-3 border-b border-border'}`}>
      <View className="w-1.5 h-1.5 rounded-full bg-accent mt-2 mr-3" />
      <View className="flex-1">
        <Text className="text-text text-sm font-semibold mb-0.5">{title}</Text>
        <Text className="text-muted text-xs leading-4">{body}</Text>
      </View>
    </View>
  );
}
