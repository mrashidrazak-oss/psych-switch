// ANC / WBC traffic-light checker for clozapine patients.
//
// Accepts live lab values, applies the CPMS-derived thresholds from
// monitoring-schedule.json, and returns the green / amber / red zone with
// the specific reason. BEN-adjusted thresholds are toggled by a switch.
//
// The classifyFbc engine function is unit-tested in isolation — this
// screen is pure presentation/interaction.
import { useState } from 'react';
import { Text, TextInput, TouchableOpacity, View } from 'react-native';
import { ScreenContainer } from '../components/ScreenContainer';
import { SwitchRow } from '../components/SwitchRow';
import { classifyFbc } from '../engine/clozapine';

type Zone = 'green' | 'amber' | 'red' | null;

export function ClozapineAncCheckerScreen() {
  const [ancText, setAncText] = useState('');
  const [wbcText, setWbcText] = useState('');
  const [isBen, setIsBen] = useState(false);
  const [zone, setZone] = useState<Zone>(null);
  const [reason, setReason] = useState('');

  const handleCheck = () => {
    const anc = parseFloat(ancText);
    const wbc = parseFloat(wbcText);
    if (isNaN(anc) || isNaN(wbc) || anc <= 0 || wbc <= 0) {
      setZone(null);
      setReason('Enter valid positive numbers for both ANC and WBC.');
      return;
    }
    const result = classifyFbc({ ancE9PerL: anc, wbcE9PerL: wbc, applyBen: isBen });
    setZone(result.zone);
    setReason(result.reason);
  };

  const zoneColor = {
    green: 'bg-to',
    amber: 'bg-warning',
    red: 'bg-danger',
  } as const;

  const zoneLabel = {
    green: 'GREEN — continue clozapine',
    amber: 'AMBER — close monitoring',
    red: 'RED — STOP clozapine immediately',
  } as const;

  const zoneActionText = {
    green: 'FBC within acceptable range. Continue clozapine as prescribed. Maintain monitoring schedule.',
    amber: 'Increase FBC frequency to twice weekly. Do NOT stop clozapine unless result worsens. Consult CPMS / haematology if persistent. Repeat in 3 days.',
    red: 'STOP clozapine immediately. Do NOT rechallenge without haematology consultation and CPMS authorisation. Report to CPMS within 24 h.',
  } as const;

  return (
    <ScreenContainer>
      <Text className="text-text text-2xl font-semibold mb-1">ANC / WBC Checker</Text>
      <Text className="text-muted text-sm mb-6">
        Enter today's results to get the CPMS traffic-light classification.
        Values in ×10⁹/L (e.g. ANC 2.0, WBC 4.5).
      </Text>

      {/* Inputs */}
      <View className="bg-surface border border-border rounded-2xl px-4 py-4 mb-4">
        <InputRow
          label="ANC (×10⁹/L)"
          value={ancText}
          onChange={setAncText}
          placeholder="e.g. 2.0"
        />
        <View className="h-px bg-border my-3" />
        <InputRow
          label="WBC (×10⁹/L)"
          value={wbcText}
          onChange={setWbcText}
          placeholder="e.g. 4.5"
        />
      </View>

      {/* BEN toggle */}
      <SwitchRow
        label="Apply BEN adjustment"
        description="Benign ethnic neutropenia — uses lower ANC/WBC thresholds for eligible patients."
        value={isBen}
        onChange={(v) => {
          setIsBen(v);
          setZone(null);
        }}
        className="mb-4"
      />

      {/* Check button */}
      <TouchableOpacity
        onPress={handleCheck}
        className="bg-accent rounded-2xl py-4 mb-6 active:opacity-80"
        activeOpacity={0.8}
      >
        <Text className="text-white text-center text-base font-semibold">
          Classify result
        </Text>
      </TouchableOpacity>

      {/* Result */}
      {zone !== null && (
        <View className="bg-surface border border-border rounded-2xl overflow-hidden mb-4">
          <View className="flex-row">
            <View className={`w-2 ${zoneColor[zone]}`} />
            <View className="flex-1 px-4 py-4">
              <Text
                className={`text-base font-bold mb-2 ${
                  zone === 'red'
                    ? 'text-danger'
                    : zone === 'amber'
                      ? 'text-warning'
                      : 'text-to'
                }`}
              >
                {zoneLabel[zone]}
              </Text>
              <Text className="text-muted text-xs mb-3">{reason}</Text>
              <Text className="text-text text-sm leading-5">
                {zoneActionText[zone]}
              </Text>
              {isBen && (
                <Text className="text-muted text-xs mt-2 italic">
                  BEN-adjusted thresholds applied.
                </Text>
              )}
            </View>
          </View>
        </View>
      )}

      {zone === null && reason.length > 0 && (
        <Text className="text-warning text-sm mt-2">{reason}</Text>
      )}

      {/* Reference thresholds */}
      <View className="bg-surface border border-border rounded-2xl px-4 py-3 mt-2">
        <Text className="text-muted text-xs uppercase tracking-widest mb-2">
          Reference thresholds {isBen ? '(BEN-adjusted)' : '(standard)'}
        </Text>
        {isBen ? (
          <ThresholdTable
            rows={[
              { label: 'Green (continue)', anc: '≥ 1.5', wbc: '≥ 3.0' },
              { label: 'Amber (monitor)', anc: '1.0–1.5', wbc: '2.5–3.0' },
              { label: 'Red (STOP)', anc: '< 1.0', wbc: '< 2.5' },
            ]}
          />
        ) : (
          <ThresholdTable
            rows={[
              { label: 'Green (continue)', anc: '≥ 2.0', wbc: '≥ 3.5' },
              { label: 'Amber (monitor)', anc: '1.5–2.0', wbc: '3.0–3.5' },
              { label: 'Red (STOP)', anc: '< 1.5', wbc: '< 3.0' },
            ]}
          />
        )}
        <Text className="text-muted text-xs mt-2">
          Source: CPMS (Clozaril Patient Monitoring Service). PENDING_CLINICAL_REVIEW — Rashid Razak.
        </Text>
      </View>
    </ScreenContainer>
  );
}

function InputRow({
  label,
  value,
  onChange,
  placeholder,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  placeholder: string;
}) {
  return (
    <View className="flex-row items-center">
      <Text className="text-text text-sm font-semibold flex-1">{label}</Text>
      <TextInput
        className="bg-bg border border-border rounded-xl px-3 py-2 text-text text-base w-28 text-right"
        value={value}
        onChangeText={onChange}
        keyboardType="decimal-pad"
        placeholder={placeholder}
        placeholderTextColor="#6b7280"
        returnKeyType="done"
      />
    </View>
  );
}

function ThresholdTable({
  rows,
}: {
  rows: { label: string; anc: string; wbc: string }[];
}) {
  return (
    <>
      <View className="flex-row mb-1">
        <Text className="text-muted text-xs w-32 font-semibold">Zone</Text>
        <Text className="text-muted text-xs flex-1 text-center font-semibold">ANC</Text>
        <Text className="text-muted text-xs flex-1 text-center font-semibold">WBC</Text>
      </View>
      {rows.map((r) => (
        <View key={r.label} className="flex-row py-1">
          <Text className="text-text text-xs w-32">{r.label}</Text>
          <Text className="text-text text-xs flex-1 text-center">{r.anc}</Text>
          <Text className="text-text text-xs flex-1 text-center">{r.wbc}</Text>
        </View>
      ))}
    </>
  );
}
