// Terms of use.
//
// Decision-support for qualified clinicians, not a substitute for clinical
// judgment, not patient-facing. This page makes that explicit.
import { Text, View } from 'react-native';
import { Icon } from '../components/Icon';
import { ScreenContainer } from '../components/ScreenContainer';

export function TermsScreen() {
  return (
    <ScreenContainer>
      <View className="flex-row items-center mb-3">
        <View className="w-9 h-9 rounded-xl bg-warning/15 border border-warning/30 items-center justify-center mr-3">
          <Icon name="info" size={18} color="#f59e0b" />
        </View>
        <Text className="text-text text-2xl font-bold">Terms of use</Text>
      </View>

      <Section title="Intended audience">
        <P>
          PsychSwitch is for use by qualified mental-health prescribers
          (psychiatrists, mental-health pharmacists, psychiatry trainees and
          GPs with mental-health experience). It is not a patient-facing
          tool and must not be shared with patients as-is.
        </P>
      </Section>

      <Section title="Decision support, not advice">
        <P>
          Cross-titration schedules, monitoring plans, equivalency tables
          and adverse-effect mappings are reference content drawn from
          published guidelines (Maudsley 15th, BAP 2020, NICE, Malaysian
          CPGs). They are decision support, not medical advice. The treating
          clinician's judgment — informed by the individual patient's
          history, comorbidities and local context — always takes
          precedence.
        </P>
      </Section>

      <Section title="No warranty">
        <P>
          The app is provided "as is". The maintainers make no warranty,
          express or implied, regarding the completeness or correctness of
          the clinical content. Always cross-check against the primary
          source before acting.
        </P>
      </Section>

      <Section title="Liability">
        <P>
          The maintainers accept no liability for clinical decisions made
          using PsychSwitch. By tapping "I am a healthcare professional" on
          first launch, you confirm you understand these limitations.
        </P>
      </Section>

      <Section title="Reporting issues">
        <P>
          If you find an error, a stale citation, or a rule that conflicts
          with current guidance, please report it through the GitHub issue
          tracker. Errata are pushed via over-the-air updates within 7 days
          of confirmation.
        </P>
      </Section>

      <Section title="Open content, no commercial use">
        <P>
          Reference content is paraphrased from open guidelines under fair
          use. Quoted material is attributed. The app source is
          MIT-licensed; the clinical content is released under
          CC BY-NC-SA 4.0. Commercial redistribution requires permission.
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
      <Text className="text-warning text-eyebrow uppercase tracking-widest font-bold mb-2">
        {title}
      </Text>
      {children}
    </View>
  );
}

function P({ children }: { children: React.ReactNode }) {
  return <Text className="text-text text-sm leading-5">{children}</Text>;
}
