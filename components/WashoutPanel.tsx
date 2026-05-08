// Visual representation of an MAOI washout. Four blocks now (was three):
//
//   0. ⚠ Serotonin syndrome danger banner (always visible, red).
//   1. Day 0 — stop original drug at full dose.
//   2. Days 1–N — NO antidepressant; visual timeline with day count.
//   3. Day N+1 — start new drug at standard starting dose.
//
// We deliberately do NOT use the Gantt component here. A washout is not
// a graded titration — visualising it as bars would mislead. A clear
// step list with explicit day markers is safer.
//
// The danger banner exists because the consequence of getting MAOI
// timing wrong is fatal serotonin syndrome — every clinician needs that
// reminder at the top of the screen, not buried in a footer.
import { Text, View } from 'react-native';
import type { Drug } from '../engine/types';
import { Banner } from './Banner';

export function WashoutPanel({
  fromDrug,
  toDrug,
  fromDoseMg,
  washoutDays,
  direction,
}: {
  fromDrug: Drug;
  toDrug: Drug;
  fromDoseMg: number;
  washoutDays: number;
  direction: 'to_maoi' | 'from_maoi';
}) {
  const startDay = washoutDays + 1;

  return (
    <View>
      {/* ── Stark serotonin-syndrome banner ─────────────────────────── */}
      <Banner
        tone="danger"
        eyebrow="Fatal interaction risk"
        title="No overlap permitted"
        body={`Combining ${direction === 'to_maoi' ? `${fromDrug.genericName} (or its active metabolites) with an MAOI` : `an MAOI with ${toDrug.genericName}`} can cause fatal serotonin syndrome (hyperthermia, autonomic instability, seizures, death). The washout is non-negotiable — never shortened for clinical urgency.`}
        className="mb-3"
      />

      {/* ── Day timeline ────────────────────────────────────────────── */}
      <View className="bg-surface border border-border rounded-2xl px-4 py-4">
        <Text className="text-muted text-xs uppercase tracking-wider mb-3">
          Washout timeline · {washoutDays} day{washoutDays === 1 ? '' : 's'}
        </Text>

        <TimelineStep
          dayLabel="Day 0"
          severity="from"
          title={`Stop ${fromDrug.genericName}`}
          body={`Discontinue ${fromDrug.genericName} ${fromDoseMg} mg. Counsel the patient about possible discontinuation symptoms over the washout window — these are NOT a reason to restart.`}
        />

        <TimelineStep
          dayLabel={`Days 1–${washoutDays}`}
          severity="warning"
          title="No antidepressant — washout window"
          body={
            direction === 'to_maoi'
              ? `Allow ${fromDrug.genericName} (and any active metabolites) to clear. Avoid all serotonergic agents: SSRIs, SNRIs, tramadol, triptans, linezolid, methylene blue, dextromethorphan, St John's wort.`
              : `Allow MAO-A activity to recover. Reversible MAOIs (e.g. moclobemide) clear quickly; irreversible MAOIs require a full 14 days. Avoid sympathomimetic drugs and tyramine-rich foods until washout is complete.`
          }
          emphasised
        />

        <TimelineStep
          dayLabel={`Day ${startDay}`}
          severity="to"
          title={`Start ${toDrug.genericName} at ${toDrug.dosing.startingDoseMg} mg`}
          body={`Begin at the recommended starting dose. Titrate to clinical response per ${toDrug.genericName}'s normal regimen.`}
          isLast
        />
      </View>
    </View>
  );
}

function TimelineStep({
  dayLabel,
  severity,
  title,
  body,
  emphasised,
  isLast,
}: {
  dayLabel: string;
  severity: 'from' | 'warning' | 'to';
  title: string;
  body: string;
  emphasised?: boolean;
  isLast?: boolean;
}) {
  const dotClass =
    severity === 'from'
      ? 'bg-from'
      : severity === 'to'
        ? 'bg-to'
        : 'bg-warning';

  return (
    <View className="flex-row mb-3">
      {/* Left rail — dot + line connector */}
      <View className="items-center mr-3" style={{ width: 32 }}>
        <View
          className={`w-8 h-8 rounded-full items-center justify-center ${dotClass}`}
        >
          <View className="w-2 h-2 rounded-full bg-white" />
        </View>
        {!isLast ? (
          <View className="w-0.5 flex-1 bg-border mt-1" style={{ minHeight: 12 }} />
        ) : null}
      </View>
      {/* Content */}
      <View className="flex-1">
        <Text className="text-muted text-eyebrow uppercase tracking-widest font-semibold mb-0.5">
          {dayLabel}
        </Text>
        <Text
          className={`text-base font-semibold mb-1 ${
            emphasised ? 'text-warning' : 'text-text'
          }`}
        >
          {title}
        </Text>
        <Text className="text-muted text-sm leading-5">{body}</Text>
      </View>
    </View>
  );
}
