// Privacy policy.
//
// PsychSwitch is privacy-first: nothing leaves the device unless the
// clinician explicitly hits Share. This screen states that plainly so the
// user (and any review board) can see exactly what is and isn't collected.
import { Text, View } from 'react-native';
import { Icon } from '../components/Icon';
import { ScreenContainer } from '../components/ScreenContainer';

export function PrivacyScreen() {
  return (
    <ScreenContainer>
      <View className="flex-row items-center mb-3">
        <View className="w-9 h-9 rounded-xl bg-accent/15 border border-accent/30 items-center justify-center mr-3">
          <Icon name="shield" size={18} color="#3b82f6" />
        </View>
        <Text className="text-text text-2xl font-bold">Privacy</Text>
      </View>

      <Section title="What we collect">
        <P>
          Nothing personally identifying. PsychSwitch does not require an
          account, does not track location, and does not transmit clinical
          inputs to any server.
        </P>
      </Section>

      <Section title="What stays on your device">
        <Bullet>
          Your patient context (age band, renal/hepatic, comorbidities) —
          stored as parameters, never as a patient record.
        </Bullet>
        <Bullet>
          Saved cases (your own free-form labels and switch parameters).
        </Bullet>
        <Bullet>
          Reviewer sign-offs and starred cases.
        </Bullet>
        <Bullet>
          App-level preferences (theme, text size).
        </Bullet>
      </Section>

      <Section title="What is sent off your device">
        <Bullet>
          Crash reports — anonymous, aggregated, opt-in via Settings. They
          contain stack traces but no clinical inputs.
        </Bullet>
        <Bullet>
          Over-the-air rule corrections — pulled from Expo on app start.
          One-way: server to device. No data is uploaded in the request.
        </Bullet>
        <Bullet>
          Only when you tap "Share schedule": the formatted plan goes to
          whichever app you choose (WhatsApp, email, etc.). PsychSwitch
          itself sees no copy.
        </Bullet>
      </Section>

      <Section title="What we never collect">
        <Bullet>Patient name, NRIC, MRN or DOB.</Bullet>
        <Bullet>Location, contacts, photos, calendar.</Bullet>
        <Bullet>Browser history or cross-app fingerprinting.</Bullet>
        <Bullet>Analytics on which rules you view or which patients.</Bullet>
      </Section>

      <Section title="Removing your data">
        <P>
          Uninstalling the app deletes all locally-stored data. From within
          the app: Settings → Reset → "Clear all local data" wipes patient
          context, saved cases and preferences in one tap.
        </P>
      </Section>

      <Section title="Contact">
        <P>
          Questions about privacy? Open a GitHub issue on the project page,
          or email the maintainer (listed on the About screen).
        </P>
      </Section>

      <Text className="text-muted text-eyebrow text-center mt-6">
        Last updated 2026-05-06
      </Text>
    </ScreenContainer>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <View className="bg-surface border border-border rounded-2xl px-4 py-4 mb-3">
      <Text className="text-accent text-eyebrow uppercase tracking-widest font-bold mb-2">
        {title}
      </Text>
      {children}
    </View>
  );
}

function P({ children }: { children: React.ReactNode }) {
  return <Text className="text-text text-sm leading-5 mb-1">{children}</Text>;
}

function Bullet({ children }: { children: React.ReactNode }) {
  return (
    <View className="flex-row mb-1.5">
      <Text className="text-muted text-sm leading-5">• </Text>
      <Text className="text-text text-sm leading-5 flex-1">{children}</Text>
    </View>
  );
}
