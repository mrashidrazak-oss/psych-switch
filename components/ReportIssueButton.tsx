// "Report an issue with this rule" — opens the platform's mail client
// with a templated bug report pre-filled. Turns the user base into a
// lightweight QA / errata team without us having to build a backend.
//
// What's included in the body:
//   • Rule ID (so we can find the JSON quickly)
//   • App version (from app.json)
//   • Reviewer attribution (so we know who originally signed it off)
//   • Last-reviewed date (so we know when it was last looked at)
//   • A blank "What's wrong" prompt for the clinician to fill in
//
// What's deliberately NOT included: any patient context, dose
// inputs, or saved-case data. The report is about the *rule*, not the
// patient. Privacy stays clean.
//
// We use Linking with mailto: rather than expo-mail-composer because
// (a) no extra native dep, (b) it works in Expo Go, and (c) users
// pick whatever mail app they prefer (Gmail, Outlook, Apple Mail).
import { Alert, Linking, Pressable, Text, View } from 'react-native';
import { Icon } from './Icon';
import type { SwitchingRule } from '../engine/types';

const ERRATA_EMAIL = 'errata@psychswitch.health';
const APP_VERSION = '0.3.2';

export function ReportIssueButton({ rule }: { rule: SwitchingRule }) {
  const onPress = async () => {
    const subject = `[Errata] ${rule.id}`;
    const body = [
      'Hello,',
      '',
      "I'd like to report an issue with the following PsychSwitch rule:",
      '',
      `  Rule ID:        ${rule.id}`,
      `  From → To:      ${rule.fromDrugId} → ${rule.toDrugId}`,
      `  Strategy:       ${rule.strategy}`,
      `  Last reviewed:  ${rule.lastReviewedISO}`,
      `  Reviewer:       ${rule.reviewedBy}`,
      `  App version:    ${APP_VERSION}`,
      '',
      'What I think is wrong:',
      '',
      '  [ Please describe the issue here — wrong dose, stale citation,',
      '    missed contraindication, mismatch with the source guideline,',
      '    etc. Include a page reference if you have one. ]',
      '',
      'Suggested correction (optional):',
      '',
      '  [ ... ]',
      '',
      'Thanks,',
    ].join('\n');

    const url = `mailto:${ERRATA_EMAIL}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;

    try {
      const supported = await Linking.canOpenURL(url);
      if (!supported) {
        Alert.alert(
          'No mail client',
          `Could not open a mail app. Please email your report to ${ERRATA_EMAIL} and include rule ID "${rule.id}" + app version ${APP_VERSION}.`,
        );
        return;
      }
      await Linking.openURL(url);
    } catch {
      Alert.alert(
        'Could not open mail',
        `Please email ${ERRATA_EMAIL} with rule ID "${rule.id}".`,
      );
    }
  };

  return (
    <Pressable
      onPress={onPress}
      className="bg-surface border border-border rounded-2xl px-4 py-3 mt-3 flex-row items-center active:opacity-80"
      accessibilityLabel={`Report an issue with rule ${rule.id}`}
    >
      <View className="w-9 h-9 rounded-xl bg-warning/15 border border-warning/30 items-center justify-center mr-3">
        <Icon name="info" size={16} color="#f59e0b" />
      </View>
      <View className="flex-1">
        <Text className="text-text text-sm font-semibold">
          Report an issue with this rule
        </Text>
        <Text className="text-muted text-micro leading-4 mt-0.5">
          Opens your mail client with a templated report (no patient data)
        </Text>
      </View>
      <Icon name="chevron-right" size={16} color="#6b7280" />
    </Pressable>
  );
}
