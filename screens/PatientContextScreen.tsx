// Patient context screen — capture the modifiers that change every
// clinical decision (age band, renal/hepatic, pregnancy, smoking,
// comorbidities). Stored locally only; no identifying data.
//
// Used by:
//   • Switching engine warnings
//   • Monitoring schedule generator
//   • Equivalency dose-adjustment hints
//   • DDI flag stacking (smoker → CYP1A2)
import { Pressable, Text, TextInput, View } from 'react-native';
import { Icon } from '../components/Icon';
import { ScreenContainer } from '../components/ScreenContainer';
import {
  bmi,
  isComplete,
  renalBandFromEgfr,
  usePatientContext,
  type PatientContext,
  type RenalFn,
  type HepaticFn,
  type Sex,
} from '../engine/patientContext';

export function PatientContextScreen() {
  const { ctx, update, clear, loaded } = usePatientContext();

  if (!loaded) return <ScreenContainer><Text className="text-muted">Loading…</Text></ScreenContainer>;

  const computedBmi = bmi(ctx);

  return (
    <ScreenContainer>
      {/* Privacy banner */}
      <View className="bg-accent/10 border border-accent/30 rounded-2xl px-4 py-3 mb-4 flex-row items-start">
        <Icon name="shield" size={16} color="#3b82f6" />
        <View className="flex-1 ml-2">
          <Text className="text-accent text-eyebrow uppercase tracking-widest font-bold mb-1">
            Privacy
          </Text>
          <Text className="text-text text-xs leading-4">
            Stored on this device only. No name, MRN, NRIC or DOB.
            Treat as a parameter register — not a patient record.
          </Text>
        </View>
      </View>

      <Text className="text-text text-2xl font-bold mb-1">Patient context</Text>
      <Text className="text-muted text-sm leading-5 mb-4">
        Sets the warnings the engine surfaces during a switch.
        Leave blank if not assessing.
      </Text>

      {/* Age + sex */}
      <SectionHeader title="Demographics" />
      <View className="flex-row gap-3 mb-3">
        <View className="flex-1">
          <Field label="Age (yrs)">
            <NumberInput
              value={ctx.ageYears}
              onChange={(v) => update({ ageYears: v })}
              placeholder="e.g. 42"
            />
          </Field>
        </View>
        <View className="flex-1">
          <Field label="Sex">
            <Segmented<Sex>
              options={[
                { key: 'male', label: 'M' },
                { key: 'female', label: 'F' },
                { key: 'other', label: '–' },
              ]}
              value={ctx.sex ?? null}
              onChange={(v) => update({ sex: v ?? undefined })}
            />
          </Field>
        </View>
      </View>

      <View className="flex-row gap-3 mb-1">
        <View className="flex-1">
          <Field label="Weight (kg)">
            <NumberInput value={ctx.weightKg} onChange={(v) => update({ weightKg: v })} />
          </Field>
        </View>
        <View className="flex-1">
          <Field label="Height (cm)">
            <NumberInput value={ctx.heightCm} onChange={(v) => update({ heightCm: v })} />
          </Field>
        </View>
        <View className="flex-1">
          <Field label="BMI">
            <View className="bg-surface border border-border rounded-2xl px-3 py-3 h-12 justify-center">
              <Text className="text-text text-sm">
                {computedBmi ? computedBmi.toFixed(1) : '—'}
              </Text>
            </View>
          </Field>
        </View>
      </View>

      {/* Renal */}
      <SectionHeader title="Renal function" />
      <Field label="eGFR (mL/min/1.73m²)">
        <NumberInput
          value={ctx.egfr}
          onChange={(v) => update({
            egfr: v,
            renal: v != null ? renalBandFromEgfr(v) : undefined,
          })}
          placeholder="e.g. 75"
        />
      </Field>
      <Segmented<RenalFn>
        options={[
          { key: 'normal',   label: 'Normal' },
          { key: 'mild',     label: 'Mild' },
          { key: 'moderate', label: 'Moderate' },
          { key: 'severe',   label: 'Severe' },
        ]}
        value={ctx.renal ?? null}
        onChange={(v) => update({ renal: v ?? undefined })}
      />
      <Helper>≥90 normal · 60–89 mild · 30–59 moderate · &lt;30 severe</Helper>

      {/* Hepatic */}
      <SectionHeader title="Hepatic function" />
      <Segmented<HepaticFn>
        options={[
          { key: 'normal',   label: 'Normal' },
          { key: 'mild',     label: 'Mild' },
          { key: 'moderate', label: 'Mod' },
          { key: 'severe',   label: 'Severe' },
        ]}
        value={ctx.hepatic ?? null}
        onChange={(v) => update({ hepatic: v ?? undefined })}
      />
      <Helper>Child-Pugh A / B / C bands</Helper>

      {/* Pregnancy / breastfeeding */}
      <SectionHeader title="Reproductive status" />
      <ToggleRow
        label="Pregnant"
        value={!!ctx.pregnant}
        onChange={(v) => update({ pregnant: v, trimester: v ? ctx.trimester ?? 2 : undefined })}
      />
      {ctx.pregnant && (
        <View className="mt-2 mb-2">
          <Segmented<1 | 2 | 3>
            options={[
              { key: 1, label: '1st' },
              { key: 2, label: '2nd' },
              { key: 3, label: '3rd' },
            ]}
            value={ctx.trimester ?? null}
            onChange={(v) => update({ trimester: v ?? undefined })}
          />
        </View>
      )}
      <ToggleRow
        label="Breastfeeding"
        value={!!ctx.breastfeeding}
        onChange={(v) => update({ breastfeeding: v })}
      />

      {/* Lifestyle */}
      <SectionHeader title="Lifestyle" />
      <ToggleRow
        label="Smoker (CYP1A2 induction)"
        value={!!ctx.smoker}
        onChange={(v) => update({ smoker: v })}
      />

      {/* Comorbidities */}
      <SectionHeader title="Relevant comorbidities" />
      <ToggleRow
        label="Cardiac history / structural disease"
        value={!!ctx.comorbidities?.cardiac}
        onChange={(v) => update({ comorbidities: { ...ctx.comorbidities, cardiac: v } })}
      />
      <ToggleRow
        label="Seizure history"
        value={!!ctx.comorbidities?.seizure}
        onChange={(v) => update({ comorbidities: { ...ctx.comorbidities, seizure: v } })}
      />
      <ToggleRow
        label="Diabetes"
        value={!!ctx.comorbidities?.diabetes}
        onChange={(v) => update({ comorbidities: { ...ctx.comorbidities, diabetes: v } })}
      />
      <ToggleRow
        label="Obesity"
        value={!!ctx.comorbidities?.obesity}
        onChange={(v) => update({ comorbidities: { ...ctx.comorbidities, obesity: v } })}
      />
      <ToggleRow
        label="Dyslipidemia"
        value={!!ctx.comorbidities?.dyslipidemia}
        onChange={(v) => update({ comorbidities: { ...ctx.comorbidities, dyslipidemia: v } })}
      />

      {/* Status + clear */}
      <View className="bg-surface border border-border rounded-2xl px-4 py-3 mt-5 mb-3 flex-row items-center">
        <View
          className={`w-2 h-2 rounded-full mr-2 ${isComplete(ctx) ? 'bg-to' : 'bg-warning'}`}
        />
        <Text className="text-muted text-xs">
          {isComplete(ctx) ? 'Context applied to engine warnings.' : 'Add age + sex to activate warnings.'}
        </Text>
      </View>
      <Pressable
        onPress={clear}
        className="bg-surface border border-danger/30 rounded-2xl py-3 active:opacity-80"
      >
        <Text className="text-danger text-center text-sm font-semibold">
          Clear all context
        </Text>
      </Pressable>
    </ScreenContainer>
  );
}

// ── helpers ──────────────────────────────────────────────────────────────

function SectionHeader({ title }: { title: string }) {
  return (
    <Text className="text-muted text-eyebrow uppercase tracking-widest mt-4 mb-2 px-1">
      {title}
    </Text>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <View className="mb-2">
      <Text className="text-muted text-eyebrow uppercase tracking-wider mb-1 px-1">
        {label}
      </Text>
      {children}
    </View>
  );
}

function Helper({ children }: { children: React.ReactNode }) {
  return (
    <Text className="text-muted text-eyebrow mt-1 mb-1 px-1">{children}</Text>
  );
}

function NumberInput({
  value,
  onChange,
  placeholder,
}: {
  value: number | undefined;
  onChange: (v: number | undefined) => void;
  placeholder?: string;
}) {
  return (
    <TextInput
      value={value != null ? String(value) : ''}
      onChangeText={(t) => {
        const n = parseFloat(t);
        onChange(isNaN(n) ? undefined : n);
      }}
      keyboardType="decimal-pad"
      placeholder={placeholder}
      placeholderTextColor="#6b7280"
      className="bg-surface border border-border rounded-2xl px-3 py-3 text-text text-sm h-12"
    />
  );
}

function Segmented<T extends string | number>({
  options,
  value,
  onChange,
}: {
  options: Array<{ key: T; label: string }>;
  value: T | null;
  onChange: (v: T | null) => void;
}) {
  return (
    <View className="flex-row bg-surface border border-border rounded-2xl p-1">
      {options.map((o) => {
        const active = value === o.key;
        return (
          <Pressable
            key={String(o.key)}
            onPress={() => onChange(active ? null : o.key)}
            className={`flex-1 py-2 rounded-xl ${active ? 'bg-accent' : ''}`}
          >
            <Text
              className={`text-center text-xs font-semibold ${active ? 'text-white' : 'text-text'}`}
            >
              {o.label}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

function ToggleRow({
  label,
  value,
  onChange,
}: {
  label: string;
  value: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <Pressable
      onPress={() => onChange(!value)}
      className="bg-surface border border-border rounded-2xl px-4 py-3 mb-2 flex-row items-center active:opacity-80"
    >
      <View
        className={`w-5 h-5 rounded mr-3 items-center justify-center border ${value ? 'bg-accent border-accent' : 'border-border'}`}
      >
        {value && <Text className="text-white text-xs font-bold">✓</Text>}
      </View>
      <Text className="text-text text-sm flex-1">{label}</Text>
    </Pressable>
  );
}
