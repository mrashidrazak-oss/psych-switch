import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useMemo, useState } from 'react';
import { Pressable, Share, Text, View } from 'react-native';
import { Banner, type BannerTone } from '../components/Banner';
import { CitationChips } from '../components/CitationChip';
import { CitationsPanel } from '../components/CitationsPanel';
import { ContextWarningsCard } from '../components/ContextWarningsCard';
import { CounsellingCard } from '../components/CounsellingCard';
import { DdiWarningsCard } from '../components/DdiWarningsCard';
import { AlternativesCard } from '../components/AlternativesCard';
import { CostComparisonCard } from '../components/CostComparisonCard';
import { DischargeSummaryCard } from '../components/DischargeSummaryCard';
import { PredictedAeCard } from '../components/PredictedAeCard';
import { PsychSwitchScoreCard } from '../components/PsychSwitchScoreCard';
import { OverlapIntensityChip } from '../components/OverlapIntensityChip';
import { ReportIssueButton } from '../components/ReportIssueButton';
import { ResultTabs, type ResultTab } from '../components/ResultTabs';
import { RuleProvenanceCard } from '../components/RuleProvenanceCard';
import { SaveCaseModal } from '../components/SaveCaseModal';
import { SpecialtyDepthCard } from '../components/SpecialtyDepthCard';
import { Toast } from '../components/Toast';
import { DiscontinuationCard } from '../components/DiscontinuationCard';
import { DoseEquivalencyPanel } from '../components/DoseEquivalencyPanel';
import { EvidenceBadge } from '../components/EvidenceBadge';
import { GanttChart } from '../components/GanttChart';
import { PkOverlayCard } from '../components/PkOverlayCard';
import { ReceptorOccupancyCard } from '../components/ReceptorOccupancyCard';
import { SafeBlock } from '../components/SafeBlock';
import { Icon } from '../components/Icon';
import { MonitoringChips } from '../components/MonitoringChips';
import { MonitoringPlanCard } from '../components/MonitoringPlanCard';
import { RationalePanel } from '../components/RationalePanel';
import { SafetyFlag } from '../components/SafetyFlag';
import { ScheduleSummaryCard } from '../components/ScheduleSummaryCard';
import { ScreenContainer } from '../components/ScreenContainer';
import { SegmentedControl } from '../components/SegmentedControl';
import { SwitchRow } from '../components/SwitchRow';
import { WashoutPanel } from '../components/WashoutPanel';
import { saveCase } from '../engine/caseManager';
import { gradeCitations, type EvidenceGrade } from '../engine/citations';
import { checkPair } from '../engine/ddi';
import { getDiscontinuationFlag } from '../engine/discontinuation';
import { generateMonitoringPlan } from '../engine/monitoring';
import { scheduleCaseReminders } from '../engine/notifications';
import {
  applyConservativeOverlap,
  assessOverlapIntensity,
} from '../engine/overlapIntensity';
import { getSettingsSync } from '../engine/settings';
import { predictAeProfile } from '../engine/predictedAeProfile';
import { computePsychSwitchScore } from '../engine/psychSwitchScore';
import { scaleSchedule } from '../engine/scaleSchedule';
import { assessSpecialty } from '../engine/specialty';
import {
  isComplete as ctxIsComplete,
  usePatientContext,
  warningsForDrug,
} from '../engine/patientContext';
import {
  deriveSafetyFlags,
  generateSwitchPlan,
  getDrug,
} from '../engine/switchingEngine';
import {
  adjustedDurationDays,
  compressSchedule,
  SPEED_BASIS,
  SPEED_LABEL,
  SPEED_SUBLABEL,
  TAPER_SPEEDS,
  type TaperSpeed,
} from '../engine/taperSpeed';
import type { Drug, Maudsley15Strategy, ScheduleStep, SwitchPlan } from '../engine/types';
import { getFlagDisplay } from '../utils/safetyFlags';
import type { RootStackParamList } from '../utils/navigation';
import { formatPlanForShare, formatWashoutForShare } from '../utils/sharePlan';
import {
  formatCounsellingCard,
  formatDischargeSummary,
  formatPdfHtml,
} from '../utils/formatDischarge';
import { exportPdf } from '../utils/exportPdf';

type Props = NativeStackScreenProps<RootStackParamList, 'Result'>;

// ── Shared action footer (Share + PDF + Start new switch) ──────────────────
// Used by every branch of ResultScreen so the user always has the same way
// to (a) share the plan, (b) export a PDF handout, (c) start a new switch.
function ResultActions({
  navigation,
  onShare,
  onExportPdf,
  shareLabel = 'Share schedule',
}: {
  navigation: NativeStackScreenProps<RootStackParamList, 'Result'>['navigation'];
  onShare: () => void;
  onExportPdf?: () => void;
  shareLabel?: string;
}) {
  // popToTop unmounts SwitchScreen, then navigate remounts it fresh — this
  // is what kills the "back button glitch" where SwitchScreen still showed
  // the old form state when the user came back to start over.
  const startNewSwitch = () => {
    navigation.popToTop();
    navigation.navigate('Switch');
  };

  return (
    <View className="mt-7">
      <Pressable
        onPress={onShare}
        className="bg-accent rounded-2xl py-4 flex-row items-center justify-center active:opacity-80"
        style={{
          shadowColor: '#3b82f6',
          shadowOffset: { width: 0, height: 4 },
          shadowOpacity: 0.2,
          shadowRadius: 10,
          elevation: 5,
        }}
      >
        <Icon name="share" size={18} color="#ffffff" />
        <Text className="text-white text-base font-semibold ml-2">
          {shareLabel}
        </Text>
      </Pressable>

      {onExportPdf && (
        <Pressable
          onPress={onExportPdf}
          className="bg-surface border border-border rounded-2xl py-4 mt-3 flex-row items-center justify-center active:opacity-70"
          accessibilityLabel="Export schedule as PDF"
        >
          <Icon name="document" size={16} color="#8b949e" />
          <Text className="text-text text-sm font-semibold ml-2">
            Export PDF
          </Text>
        </Pressable>
      )}

      <Pressable
        onPress={startNewSwitch}
        className="bg-surface border border-border rounded-2xl py-4 mt-3 flex-row items-center justify-center active:opacity-70"
      >
        <Icon name="refresh" size={16} color="#8b949e" />
        <Text className="text-text text-sm font-semibold ml-2">
          Start new switch
        </Text>
      </Pressable>

      <Text className="text-muted text-xs text-center mt-3 leading-4">
        Share opens the native sheet (WhatsApp, email, SMS). Export PDF
        opens the print sheet (Save to Files / AirDrop / Print).
      </Text>
    </View>
  );
}

export function ResultScreen({ route, navigation }: Props) {
  // ── All hooks MUST be called unconditionally before any early returns ──
  // (React Rules of Hooks — hook call order must be stable across renders.)
  const [viewMode, setViewMode] = useState<'summary' | 'detailed'>('summary');
  const [taperSpeed, setTaperSpeed] = useState<TaperSpeed>('standard');
  const [scheduleView, setScheduleView] = useState<'adapted' | 'reviewed'>('adapted');
  const [conservativeMode, setConservativeMode] = useState(false);
  const [savedCaseId, setSavedCaseId] = useState<string | null>(null);
  const [saveModalOpen, setSaveModalOpen] = useState(false);
  const [activeTab, setActiveTab] = useState<ResultTab>('schedule');
  const [toast, setToast] = useState<{ visible: boolean; message: string }>({
    visible: false,
    message: '',
  });
  const { ctx } = usePatientContext();

  const fromDrug = getDrug(route.params.fromDrugId);
  const toDrug = getDrug(route.params.toDrugId);

  if (!fromDrug || !toDrug) {
    return (
      <ScreenContainer>
        <SafetyFlag
          severity="danger"
          title="Drug not found"
          body="One of the selected drugs is not registered. This is a bug — please report it."
        />
      </ScreenContainer>
    );
  }

  const plan = generateSwitchPlan(route.params);

  // ── Clozapine redirect branch ─────────────────────────────────────
  if (plan.status === 'clozapine_redirect') {
    return (
      <ScreenContainer key="clozapine-redirect">
        <Text className="text-text text-2xl font-semibold mb-1">
          {plan.fromDrugName} → Clozapine
        </Text>
        <Text className="text-muted text-sm mb-4">
          Treatment-resistant schizophrenia — specialist initiation
        </Text>

        <Banner
          tone="warning"
          eyebrow="Not a standard cross-taper"
          title="Use the Clozapine module"
          body={plan.reason}
          className="mb-4"
        >
          <View className="bg-bg rounded-xl px-3 py-3 mt-3">
            <Text className="text-muted text-xs uppercase tracking-widest mb-1">
              Guidance
            </Text>
            <Text className="text-text text-sm leading-5">{plan.guidance}</Text>
          </View>
        </Banner>

        <View className="bg-surface border border-border rounded-2xl px-4 py-3">
          <Text className="text-muted text-xs uppercase tracking-widest mb-1">
            What to do next
          </Text>
          <Text className="text-text text-sm leading-5">
            Go back to Home and open the Clozapine module for the full
            inpatient or community titration schedule, FBC monitoring
            schedule, and safety considerations.
          </Text>
        </View>

        {/* ── Footer: open Clozapine module + start new switch ──────── */}
        <View className="mt-7">
          <Pressable
            onPress={() => {
              navigation.popToTop();
              navigation.navigate('ClozapineHome');
            }}
            className="bg-accent rounded-2xl py-4 flex-row items-center justify-center active:opacity-80"
            style={{
              shadowColor: '#3b82f6',
              shadowOffset: { width: 0, height: 4 },
              shadowOpacity: 0.2,
              shadowRadius: 10,
              elevation: 5,
            }}
          >
            <Icon name="shield" size={18} color="#ffffff" />
            <Text className="text-white text-base font-semibold ml-2">
              Open Clozapine module
            </Text>
          </Pressable>
          <Pressable
            onPress={() => {
              navigation.popToTop();
              navigation.navigate('Switch');
            }}
            className="bg-surface border border-border rounded-2xl py-4 mt-3 flex-row items-center justify-center active:opacity-70"
          >
            <Icon name="refresh" size={16} color="#8b949e" />
            <Text className="text-text text-sm font-semibold ml-2">
              Start new switch
            </Text>
          </Pressable>
        </View>
      </ScreenContainer>
    );
  }

  // ── MAOI washout branch ────────────────────────────────────────────
  if (plan.status === 'maoi_washout') {
    return (
      <WashoutResult
        navigation={navigation}
        fromDrug={fromDrug}
        toDrug={toDrug}
        fromDoseMg={route.params.fromDoseMg}
        plan={plan}
      />
    );
  }

  // ── Maudsley 15th guidance branch ─────────────────────────────────
  if (plan.status === 'maudsley_guidance') {
    return (
      <MaudsleyGuidanceResult
        navigation={navigation}
        fromDrug={fromDrug}
        toDrug={toDrug}
        fromDoseMg={route.params.fromDoseMg}
        toDoseMg={route.params.toDoseMg}
        plan={plan}
      />
    );
  }

  // ── No-rule fallback (Maudsley matrix doesn't cover this pair) ────
  if (plan.status === 'no_rule') {
    const profileFlags = deriveSafetyFlags(fromDrug, toDrug);
    return (
      <ScreenContainer>
        <Text className="text-text text-2xl font-semibold mb-1">
          {fromDrug.genericName} → {toDrug.genericName}
        </Text>
        <Text className="text-muted text-sm mb-4">
          {route.params.fromDoseMg} mg → {route.params.toDoseMg} mg
        </Text>

        <SafetyFlag
          severity="warning"
          title="No reviewed cross-taper rule"
          body={plan.reason}
        />

        {profileFlags.map((key) => {
          const d = getFlagDisplay(key);
          return (
            <SafetyFlag
              key={key}
              severity={d.severity}
              title={d.title}
              body={d.body}
            />
          );
        })}

        <View className="bg-surface border border-border rounded-2xl px-4 py-3 mt-2">
          <Text className="text-muted text-xs uppercase tracking-wider mb-1">
            What to do
          </Text>
          <Text className="text-text text-sm leading-5">
            Consult the primary reference for this pair directly — Maudsley
            15th edition (antidepressants or mood stabilizers chapters) or
            BAP 2020 psychosis guidelines. Do not extrapolate from similar
            drugs — half-life, active metabolites, and receptor-binding
            profiles differ significantly even within the same class.
          </Text>
        </View>

        {/* Start-new-switch CTA at the bottom */}
        <View className="mt-7">
          <Pressable
            onPress={() => {
              navigation.popToTop();
              navigation.navigate('Switch');
            }}
            className="bg-surface border border-border rounded-2xl py-4 flex-row items-center justify-center active:opacity-70"
          >
            <Icon name="refresh" size={16} color="#8b949e" />
            <Text className="text-text text-sm font-semibold ml-2">
              Start new switch
            </Text>
          </Pressable>
        </View>
      </ScreenContainer>
    );
  }

  // ── Reviewed cross-taper branch (status === 'ok') ─────────────────
  // viewMode and taperSpeed state are hoisted to the top of the component
  // (above all early returns) to satisfy the Rules of Hooks. They are only
  // meaningful here.

  // Speed adjustment only applies to true cross-tapers — `direct` is
  // already 1–2 days and `washout` is pharmacologically fixed.
  const speedSupported =
    plan.rule.strategy === 'cross-taper' ||
    plan.rule.strategy === 'plateau-cross-taper';
  const effectiveSpeed: TaperSpeed = speedSupported ? taperSpeed : 'standard';

  // ── Adaptive scaling ─────────────────────────────────────────────
  // Apply the user's actual doses to the reviewed reference schedule
  // (rounded to formulation, capped at clinical max, duplicate-merged).
  // The user can flip back to the unadapted reviewed schedule via
  // setScheduleView('reviewed') for verification.
  const scaleResult = useMemo(
    () => scaleSchedule({
      rule: plan.rule,
      fromDrug,
      toDrug,
      userFromDose: route.params.fromDoseMg,
      userToDose: route.params.toDoseMg,
    }),
    [plan.rule, fromDrug, toDrug, route.params.fromDoseMg, route.params.toDoseMg],
  );

  // Source schedule depends on whether the user is viewing the adapted
  // or reviewed view. The adapted view is the default — that's the
  // whole point of the scaler.
  const sourceSchedule =
    scheduleView === 'adapted' && scaleResult.adapted
      ? scaleResult.schedule
      : plan.schedule;

  // Conservative-mode transform — applied AFTER the adaptive scaler
  // so it operates on whatever the user is currently viewing. Reduces
  // Day 1's from-drug dose by ~25%, rounded to formulation, clamped
  // so the taper stays monotonic. Pure function, easy to revert.
  const conservativeResult = useMemo(
    () => (conservativeMode ? applyConservativeOverlap(sourceSchedule, fromDrug) : null),
    [conservativeMode, sourceSchedule, fromDrug],
  );
  const effectiveSchedule = conservativeResult?.schedule ?? sourceSchedule;

  const adjustedSchedule = compressSchedule(effectiveSchedule, effectiveSpeed);
  const adjustedDuration = adjustedDurationDays(
    plan.rule.durationDays,
    effectiveSpeed,
  );

  // Overlap-intensity assessment runs on the schedule the user is
  // currently looking at — including Conservative-mode mods if applied.
  const overlapAssessment = useMemo(
    () => assessOverlapIntensity({
      fromDrug,
      toDrug,
      schedule: adjustedSchedule,
    }),
    [fromDrug, toDrug, adjustedSchedule],
  );

  const onShare = async () => {
    const planForShare = { ...plan, schedule: adjustedSchedule };
    const message = formatPlanForShare(
      fromDrug,
      toDrug,
      planForShare,
      effectiveSpeed,
      adjustedDuration,
    );
    try {
      await Share.share({ message });
    } catch {
      // User cancelled or share unavailable — silent.
    }
  };

  // ── Engine outputs (memoized) ─────────────────────────────────────
  // Evidence grade is the rule's source-derived grade, demoted by one
  // notch when the schedule has been adapted to the user's doses (the
  // strategy is still reviewed; only the dose values are derived).
  const baseEvidenceGrade = useMemo(
    () => gradeCitations(plan.citations),
    [plan.citations],
  );
  const evidenceGrade: EvidenceGrade =
    scaleResult.adapted && scheduleView === 'adapted'
      ? demoteGrade(baseEvidenceGrade)
      : baseEvidenceGrade;
  const ddiHits = useMemo(
    () => checkPair(fromDrug.id, toDrug.id),
    [fromDrug.id, toDrug.id],
  );
  const discFlag = useMemo(
    () => getDiscontinuationFlag(fromDrug.id),
    [fromDrug.id],
  );
  const ctxWarnings = useMemo(() => {
    if (!ctxIsComplete(ctx)) return [];
    return [
      ...warningsForDrug(ctx, fromDrug.id),
      ...warningsForDrug(ctx, toDrug.id),
    ];
  }, [ctx, fromDrug.id, toDrug.id]);
  const monitoringPlan = useMemo(
    () => generateMonitoringPlan({
      fromDrugId: fromDrug.id,
      toDrugId: toDrug.id,
      context: ctx,
      durationDays: Math.max(adjustedDuration + 14, 90),
    }),
    [fromDrug.id, toDrug.id, ctx, adjustedDuration],
  );

  // ── Smart-layer outputs (memoized) ────────────────────────────────
  const psychScore = useMemo(
    () => computePsychSwitchScore({
      rule: plan.rule,
      fromDrug,
      toDrug,
      context: ctx,
      scaleResult,
      ddiHits,
      contextWarnings: ctxWarnings,
      evidenceGrade,
    }),
    [plan.rule, fromDrug, toDrug, ctx, scaleResult, ddiHits, ctxWarnings, evidenceGrade],
  );
  const aeProfile = useMemo(
    () => predictAeProfile(toDrug, fromDrug),
    [fromDrug, toDrug],
  );

  const specialtyAssessment = useMemo(
    () => assessSpecialty({
      fromDrugId: fromDrug.id,
      toDrugId: toDrug.id,
      fromDrugName: fromDrug.genericName,
      toDrugName: toDrug.genericName,
      context: ctx,
    }),
    [fromDrug.id, toDrug.id, fromDrug.genericName, toDrug.genericName, ctx],
  );

  // ── Workflow-loop formats ─────────────────────────────────────────
  // Memoized so cards don't recompute on every taper-speed keystroke.
  const formatInputs = useMemo(() => ({
    rule: plan.rule,
    fromDrug,
    toDrug,
    schedule: adjustedSchedule,
    monitoring: monitoringPlan,
    scaleResult,
    durationDays: adjustedDuration,
  }), [plan.rule, fromDrug, toDrug, adjustedSchedule, monitoringPlan, scaleResult, adjustedDuration]);

  const dischargeText = useMemo(() => formatDischargeSummary(formatInputs), [formatInputs]);
  const counsellingText = useMemo(() => formatCounsellingCard(formatInputs), [formatInputs]);

  const onExportPdf = async () => {
    const html = formatPdfHtml(formatInputs);
    await exportPdf({
      html,
      fileName: `${fromDrug.id}-to-${toDrug.id}.pdf`,
    });
  };

  // Persist + (optionally) schedule the monitoring reminders. Called
  // from the SaveCaseModal once the user confirms a label. Cross-
  // platform — works on iOS, Android and Web.
  const persistCase = async (label: string) => {
    const safeLabel = label || `${fromDrug.genericName} → ${toDrug.genericName}`;
    const saved = await saveCase({
      id: savedCaseId ?? undefined,
      label: safeLabel,
      fromDrugId: fromDrug.id,
      fromDoseMg: route.params.fromDoseMg,
      toDrugId: toDrug.id,
      toDoseMg: route.params.toDoseMg,
    });
    setSavedCaseId(saved.id);
    setSaveModalOpen(false);

    // Visible confirmation — replaces the silent Android fallback that
    // confused testers. Shows even on iOS where the modal already gave
    // tactile feedback, because consistency matters.
    setToast({
      visible: true,
      message: savedCaseId ? `Updated "${safeLabel}"` : `Saved "${safeLabel}"`,
    });

    // Schedule reminders silently if settings allow. Permission is
    // requested lazily by scheduleCaseReminders, so first-time users
    // get the OS prompt right when saving — natural moment for it.
    const settings = getSettingsSync();
    if (settings.remindersEnabled && settings.autoScheduleReminders) {
      scheduleCaseReminders({
        caseId: saved.id,
        caseLabel: safeLabel,
        startDate: new Date(saved.startedISO),
        hour: settings.reminderHour,
        monitoring: monitoringPlan,
      }).catch(() => { /* permission denied or platform limitation — silent */ });
    }
  };

  // Save case — opens the cross-platform SaveCaseModal. Replaces the
  // earlier Alert.prompt approach which was iOS-only and silently
  // no-op'd on Android.
  const onSaveCase = () => {
    setSaveModalOpen(true);
  };

  const defaultCaseLabel = `${fromDrug.genericName.slice(0, 4)} → ${toDrug.genericName.slice(0, 4)}`;

  return (
    <ScreenContainer>
      {/* ── Header ─────────────────────────────────────────────────── */}
      <View className="flex-row items-start justify-between mb-1">
        <Text className="text-text text-2xl font-semibold flex-1 pr-2">
          {fromDrug.genericName} → {toDrug.genericName}
        </Text>
        <Pressable
          onPress={onSaveCase}
          className="bg-surface border border-border rounded-xl px-2 py-1.5 active:opacity-70 flex-row items-center"
          accessibilityLabel="Save this case to local register"
        >
          <Text className={`text-base mr-1 ${savedCaseId ? 'text-warning' : 'text-muted'}`}>
            {savedCaseId ? '★' : '☆'}
          </Text>
          <Text className="text-text text-xs font-semibold">
            {savedCaseId ? 'Saved' : 'Save'}
          </Text>
        </Pressable>
      </View>
      <Text className="text-muted text-base mb-2">
        {formatRuleStrategy(plan.rule.strategy, adjustedDuration)}
        {effectiveSpeed !== 'standard' ? ' · adjusted speed' : ''}
      </Text>

      {/* ── Evidence badge + citation chip strip — the "show your work" line. */}
      <View className="flex-row flex-wrap items-center mb-2" style={{ gap: 6 }}>
        <EvidenceBadge grade={evidenceGrade} />
        {plan.citations.length > 0 && (
          <CitationChips citationKeys={plan.citations} max={3} compact />
        )}
      </View>

      {/* ── Overlap-intensity chip — Day 1 cross-taper safety signal. */}
      <View className="flex-row flex-wrap items-center mb-3" style={{ gap: 6 }}>
        <OverlapIntensityChip assessment={overlapAssessment} />
      </View>

      {/* ── PsychSwitch Score — single 0-100 number with breakdown ── */}
      <PsychSwitchScoreCard score={psychScore} />

      {/* ─────────────────────────────────────────────────────────────
          Below this line lives in tabs. The header above (drug pair,
          save, strategy, evidence, overlap, score) stays persistent
          so the clinician always sees the high-level signal. The four
          tabs split the 24+ cards by purpose: Schedule (the actual
          plan + safety), Insights (AE/cost/alternatives), Provenance
          (rules/citations/errata), Workflow (discharge/counselling).
          ─────────────────────────────────────────────────────────── */}
      <ResultTabs active={activeTab} onChange={setActiveTab} />

      {activeTab === 'schedule' && (
      <>
      {/* ── Taper-speed selector (only for compressible cross-tapers) ── */}
      {speedSupported && (
        <View className="mb-3">
          <TaperSpeedToggle speed={taperSpeed} onChange={setTaperSpeed} />
          {taperSpeed !== 'standard' && (
            <Banner
              tone="warning"
              eyebrow="Outside the reviewed schedule"
              className="mt-3"
            >
              <Text className="text-text text-xs leading-4">
                {SPEED_BASIS[taperSpeed]}
              </Text>
            </Banner>
          )}
        </View>
      )}

      {/* ── Summary / Detailed toggle ───────────────────────────────── */}
      <ViewToggle mode={viewMode} onChange={setViewMode} />

      {/* ── Conservative-mode toggle — softens Day 1 overlap by 25% on
          the from-drug. Only meaningful when the schedule has actual
          overlap (Day 1 fromDose > 0); we still render the toggle so
          the clinician learns it exists. */}
      <SwitchRow
        label={`Conservative mode${conservativeMode ? ' · on' : ''}`}
        description={
          conservativeMode && conservativeResult?.modified
            ? `Day 1 from-drug reduced by ${conservativeResult.deltaMg} mg.`
            : 'Reduce Day 1 from-drug by ~25% to soften overlap.'
        }
        value={conservativeMode}
        onChange={setConservativeMode}
        className="mt-3"
        accessibilityLabel={
          conservativeMode
            ? 'Conservative mode is on. Tap to revert to standard schedule.'
            : 'Conservative mode is off. Tap to soften Day 1 overlap.'
        }
      />

      {/* ── Adaptive-scaling banner ─────────────────────────────────
          Replaces the old "reference schedule, adapt yourself" banner.
          When the user's doses don't match the rule's reviewed doses,
          we adapt the schedule (round to formulation, cap at max,
          merge duplicates) and signal honestly. The user can flip
          back to the unadapted reviewed view. */}
      {!plan.dosesMatchReference && scaleResult.adapted && scaleResult.applied.mode !== 'no-scale' && (
        <Banner
          tone="info"
          eyebrow={scheduleView === 'adapted'
            ? 'Schedule adapted to your patient'
            : 'Showing reviewed reference'}
          className="mt-4"
          trailing={
            <Pressable
              onPress={() =>
                setScheduleView(scheduleView === 'adapted' ? 'reviewed' : 'adapted')
              }
              className="bg-bg border border-border rounded-lg px-2 py-1 active:opacity-70"
            >
              <Text className="text-text text-eyebrow font-bold uppercase tracking-widest">
                {scheduleView === 'adapted' ? 'View reviewed' : 'View adapted'}
              </Text>
            </Pressable>
          }
        >
          <Text className="text-text text-sm leading-5 mb-1">
            You entered{' '}
            <Text className="font-semibold">
              {plan.inputDoses.fromMg} mg → {plan.inputDoses.toMg} mg
            </Text>
            . Reviewed reference is{' '}
            <Text className="font-semibold">
              {plan.rule.doseRatios.fromCurrentDoseMg} mg →{' '}
              {plan.rule.doseRatios.toTargetDoseMg} mg
            </Text>
            {scheduleView === 'adapted' ? (
              <>
                {' '}— scaled{' '}
                <Text className="font-semibold">
                  {scaleResult.applied.fromFactor.toFixed(2)}× from /{' '}
                  {scaleResult.applied.toFactor.toFixed(2)}× to
                </Text>
                , rounded to formulation.
              </>
            ) : (
              '. Doses below are the unmodified reviewed reference for verification.'
            )}
          </Text>
          {scaleResult.warnings.length > 0 && scheduleView === 'adapted' && (
            <View className="mt-2 bg-bg/50 rounded-lg px-3 py-2">
              {scaleResult.warnings.slice(0, 4).map((w, i) => (
                <Text key={i} className="text-warning text-micro leading-4 mb-0.5">
                  • {w.message}
                </Text>
              ))}
              {scaleResult.warnings.length > 4 && (
                <Text className="text-muted text-eyebrow">
                  +{scaleResult.warnings.length - 4} more
                </Text>
              )}
            </View>
          )}
        </Banner>
      )}

      {/* No-scale notice for fixed protocols (LAI / washouts) where the
          input doses don't match — be explicit that scaling was bypassed. */}
      {!plan.dosesMatchReference && scaleResult.applied.mode === 'no-scale' && (
        <Banner
          tone="warning"
          eyebrow="Fixed protocol — schedule not scaled"
          className="mt-4"
        >
          <Text className="text-text text-sm leading-5">
            This rule's doses are dictated by the product PI or
            pharmacokinetics, not the patient's current dose.
            You entered{' '}
            <Text className="font-semibold">
              {plan.inputDoses.fromMg} mg → {plan.inputDoses.toMg} mg
            </Text>
            ; the schedule below uses the reviewed values.
          </Text>
        </Banner>
      )}

      {/* ── Safety flags (both modes — patient safety always visible) ── */}
      {plan.safetyFlags.map((key) => {
        const d = getFlagDisplay(key);
        return (
          <SafetyFlag
            key={key}
            severity={d.severity}
            title={d.title}
            body={d.body}
          />
        );
      })}

      {/* ── Patient-context warnings (always shown — drives bedside safety) */}
      <ContextWarningsCard
        warnings={ctxWarnings}
        hasContext={ctxIsComplete(ctx)}
      />

      {/* ── Discontinuation flag for the from-drug ─────────────────── */}
      {discFlag && (
        <DiscontinuationCard flag={discFlag} drugDisplayName={fromDrug.genericName} />
      )}

      {/* ── DDI checker for the overlap window ─────────────────────── */}
      <DdiWarningsCard hits={ddiHits} />

      <View className="mb-1" />

      {/* ── Strategy rationale (summary only — keeps detailed view clean) */}
      {viewMode === 'summary' && plan.rule.rationale ? (
        <RationalePanel rationale={plan.rule.rationale} />
      ) : null}

      {/* ── Reviewed dose equivalency (summary only) ────────────────── */}
      {viewMode === 'summary' ? (
        <DoseEquivalencyPanel
          fromDrug={fromDrug}
          toDrug={toDrug}
          rule={plan.rule}
        />
      ) : null}

      {/* ── At-a-glance monitoring chips (summary only) ─────────────── */}
      {viewMode === 'summary' && plan.safetyFlags.length > 0 ? (
        <MonitoringChips flags={plan.safetyFlags} />
      ) : null}

      {viewMode === 'summary' && (
        /* ── SUMMARY VIEW ─────────────────────────────────────────── */
        <ScheduleSummaryCard
          fromDrug={fromDrug}
          toDrug={toDrug}
          schedule={adjustedSchedule}
          ruleCitations={plan.citations}
        />
      )}

      {viewMode === 'detailed' && (
        /* ── DETAILED VIEW ────────────────────────────────────────── */
        <>
          <GanttChart
            fromDrug={fromDrug}
            toDrug={toDrug}
            schedule={adjustedSchedule}
          />

          {/* PK overlay — visualizes effective levels (uses pkSimulation
              engine). Wrapped in SafeBlock so any SVG render glitch
              stays contained and doesn't take down the rest of the view. */}
          <SafeBlock tag="PkOverlay">
            <PkOverlayCard
              schedule={adjustedSchedule}
              fromDrug={fromDrug}
              toDrug={toDrug}
            />
          </SafeBlock>

          {/* Receptor occupancy — educational sigmoid for SSRI/SNRI/etc.
              Auto-hidden for antipsychotics. */}
          <SafeBlock tag="ReceptorOccupancy">
            <ReceptorOccupancyCard
              drug={fromDrug}
              startDoseMg={route.params.fromDoseMg}
            />
          </SafeBlock>

          <MonitoringPlanCard plan={monitoringPlan} />
        </>
      )}
      </>
      )}

      {activeTab === 'insights' && (
      <>
        {/* ── Specialty depth — pregnancy / pediatric / geriatric ───
            Renders only when at least one specialty applies given the
            patient context. When pregnant / breastfeeding / pediatric /
            older-adult, this card dominates because subgroup decisions
            are exactly where general-purpose tools fail. */}
        <SpecialtyDepthCard assessment={specialtyAssessment} />

        {/* ── Predicted AE profile for the to-drug ─────────────────── */}
        <PredictedAeCard profile={aeProfile} />

        {/* ── Affordability hint (Malaysian formulary cost) ────────── */}
        <CostComparisonCard fromDrug={fromDrug} toDrug={toDrug} />

        {/* ── What-if alternatives (top 3 by smart picker) ──────────── */}
        <AlternativesCard
          fromDrug={fromDrug}
          currentToDrug={toDrug}
          context={ctx}
        />
      </>
      )}

      {activeTab === 'provenance' && (
      <>
        {/* ── Trust strip — reviewer, last-reviewed date, next-review
            due, evidence grade and rule ID. */}
        <RuleProvenanceCard
          rule={plan.rule}
          evidenceGrade={evidenceGrade}
          adapted={scaleResult.adapted && scheduleView === 'adapted'}
        />

        {/* ── Full citation panel ──────────────────────────────────── */}
        <CitationsPanel citations={plan.citations} />

        {/* ── Errata mechanism — turn user base into QA team ───────── */}
        <ReportIssueButton rule={plan.rule} />
      </>
      )}

      {activeTab === 'workflow' && (
      <>
        {/* ── Workflow-loop cards ────────────────────────────────────
            Discharge summary (clinician, EMR-paste-ready) and patient
            counselling card (plain language). Both collapsible so they
            don't crowd the screen by default. */}
        <DischargeSummaryCard text={dischargeText} />
        <CounsellingCard text={counsellingText} />
      </>
      )}

      {/* ── Footer actions (Share + Export PDF + Start new switch) ── */}
      <ResultActions
        navigation={navigation}
        onShare={onShare}
        onExportPdf={onExportPdf}
      />

      {/* ── Save case modal (cross-platform) + confirmation toast ── */}
      <SaveCaseModal
        visible={saveModalOpen}
        defaultLabel={defaultCaseLabel}
        onCancel={() => setSaveModalOpen(false)}
        onSave={persistCase}
      />
      <Toast
        visible={toast.visible}
        message={toast.message}
        tone="success"
        onHide={() => setToast({ visible: false, message: '' })}
      />
    </ScreenContainer>
  );
}

// ── Taper-speed and view toggles ──────────────────────────────────────────
// Both used to be hand-rolled segmented pills with their own theme constants
// and inline-styled Pressable rows. As of v0.4.11 they're thin shims around
// the unified <SegmentedControl> primitive (components/SegmentedControl.tsx).

type ViewMode = 'summary' | 'detailed';

function TaperSpeedToggle({
  speed,
  onChange,
}: {
  speed: TaperSpeed;
  onChange: (s: TaperSpeed) => void;
}) {
  const options = TAPER_SPEEDS.map((s) => ({
    value: s,
    label: SPEED_LABEL[s],
    sublabel: SPEED_SUBLABEL[s],
    accent: s !== 'standard',
  }));
  return (
    <SegmentedControl
      label="Taper speed"
      options={options}
      value={speed}
      onChange={onChange}
    />
  );
}

function ViewToggle({
  mode,
  onChange,
}: {
  mode: ViewMode;
  onChange: (m: ViewMode) => void;
}) {
  return (
    <SegmentedControl
      options={[
        { value: 'summary',  label: 'Summary'  },
        { value: 'detailed', label: 'Detailed' },
      ]}
      value={mode}
      onChange={onChange}
    />
  );
}

// ── Strategy label helpers ─────────────────────────────────────────────────
// Maps raw JSON strategy strings to human-readable labels.
const RULE_STRATEGY_LABEL: Record<string, string> = {
  direct: 'Direct switch',
  'cross-taper': 'Cross-taper',
  'plateau-cross-taper': 'Plateau cross-taper',
  washout: 'Washout',
};

function formatRuleStrategy(strategy: string, durationDays: number): string {
  const label = RULE_STRATEGY_LABEL[strategy] ?? strategy;
  return `${label} over ${durationDays} days`;
}

/**
 * When a schedule has been adapted from its reviewed reference, the
 * strategy is still grade-A reviewed but the dose values are derived,
 * so we drop the badge by one notch (A → B, B → C, …) for honest
 * signaling. D stays at D.
 */
function demoteGrade(g: EvidenceGrade): EvidenceGrade {
  switch (g) {
    case 'A': return 'B';
    case 'B': return 'C';
    case 'C': return 'D';
    case 'D': return 'D';
  }
}

// ── Maudsley 15th guidance sub-view ───────────────────────────────────────
// Renders strategy-level guidance + an indicative schedule when no specific
// reviewed rule exists for this pair.
const STRATEGY_LABEL: Record<string, string> = {
  direct_switch: 'Direct switch',
  cross_taper_cautiously: 'Cross-taper cautiously',
  taper_then_wait: 'Taper, stop, then wait',
  halve_and_add: 'Halve dose and add new drug',
  special: 'Complex switch — see detail',
};

const STRATEGY_TONE: Record<string, BannerTone> = {
  direct_switch: 'success',
  cross_taper_cautiously: 'warning',
  taper_then_wait: 'danger',
  halve_and_add: 'warning',
  special: 'warning',
};

function MaudsleyGuidanceResult({
  navigation,
  fromDrug,
  toDrug,
  fromDoseMg,
  toDoseMg,
  plan,
}: {
  navigation: NativeStackScreenProps<RootStackParamList, 'Result'>['navigation'];
  fromDrug: Drug;
  toDrug: Drug;
  fromDoseMg: number;
  toDoseMg: number;
  plan: Extract<SwitchPlan, { status: 'maudsley_guidance' }>;
}) {
  // Hooks first — Rules of Hooks: must be called unconditionally before
  // any early returns. This screen has no early returns, but keeping the
  // pattern consistent across the file prevents future regressions.
  const [taperSpeed, setTaperSpeed] = useState<TaperSpeed>('standard');

  const strategyTone = STRATEGY_TONE[plan.guidance.strategy] ?? 'warning';
  const strategyLabel = STRATEGY_LABEL[plan.guidance.strategy] ?? plan.guidance.strategy;

  // Speed only meaningfully scales the active-taper strategies. For
  // taper_then_wait the wait period is half-life-driven (e.g. fluoxetine's
  // 6-week washout) and must not compress; for direct_switch / special the
  // schedule is too short to warp.
  const speedSupported =
    plan.guidance.strategy === 'cross_taper_cautiously' ||
    plan.guidance.strategy === 'halve_and_add';
  const effectiveSpeed: TaperSpeed = speedSupported ? taperSpeed : 'standard';

  const baseSchedule = generateGuidanceSchedule(
    plan.guidance.strategy,
    fromDrug,
    toDrug,
    fromDoseMg,
    toDoseMg,
    plan.guidance.waitDays,
  );
  const indicativeSchedule =
    baseSchedule !== null && speedSupported
      ? compressSchedule(baseSchedule, effectiveSpeed)
      : baseSchedule;

  return (
    <ScreenContainer>
      <Text className="text-text text-2xl font-semibold mb-1">
        {fromDrug.genericName} → {toDrug.genericName}
      </Text>
      <Text className="text-muted text-sm mb-4">
        {fromDoseMg} mg → {toDoseMg} mg · Maudsley 15th guidance
      </Text>

      {/* Strategy headline card */}
      <Banner
        tone={strategyTone}
        eyebrow={`Strategy · ${strategyLabel}`}
        className="mb-4"
      >
        <Text className="text-text text-base font-bold mb-2">
          {plan.guidance.headline}
        </Text>
        <Text className="text-text text-sm leading-5 mb-3">
          {plan.guidance.detail}
        </Text>
        {plan.guidance.waitDays !== undefined && (
          <View className="bg-bg rounded-xl px-3 py-2 self-start">
            <Text className="text-muted text-xs uppercase tracking-wider mb-0.5">
              Wait period
            </Text>
            <Text className="text-text text-sm font-semibold">
              {plan.guidance.waitDays} day{plan.guidance.waitDays === 1 ? '' : 's'}
            </Text>
          </View>
        )}
      </Banner>

      {/* Taper-speed toggle (only for compressible strategies) */}
      {speedSupported && (
        <View className="mb-4">
          <TaperSpeedToggle speed={taperSpeed} onChange={setTaperSpeed} />
          {taperSpeed !== 'standard' && (
            <Banner
              tone="warning"
              eyebrow="Outside the reviewed schedule"
              className="mt-3"
            >
              <Text className="text-text text-xs leading-4">
                {SPEED_BASIS[taperSpeed]}
              </Text>
            </Banner>
          )}
        </View>
      )}

      {/* Safety flags */}
      {plan.safetyFlags.map((key) => {
        const d = getFlagDisplay(key);
        return (
          <SafetyFlag
            key={key}
            severity={d.severity}
            title={d.title}
            body={d.body}
          />
        );
      })}

      {/* At-a-glance monitoring chips */}
      {plan.safetyFlags.length > 0 ? (
        <MonitoringChips flags={plan.safetyFlags} />
      ) : null}

      {/* Indicative schedule — generated from strategy + doses */}
      {indicativeSchedule !== null ? (
        <View className="mb-4">
          {/* Warning banner: this schedule is generated, not clinician-reviewed */}
          <Banner
            tone="warning"
            eyebrow="Indicative schedule — not individually reviewed"
            className="mb-3"
          >
            <Text className="text-text text-xs leading-4">
              No specific reviewed rule exists for this pair. The schedule
              below is generated algorithmically from the Maudsley strategy
              and your entered doses. Treat it as a starting framework —
              adjust to the patient's clinical response, serum levels, and
              tolerability. Never use without clinical judgment.
            </Text>
          </Banner>
          <ScheduleSummaryCard
            fromDrug={fromDrug}
            toDrug={toDrug}
            schedule={indicativeSchedule}
          />
        </View>
      ) : (
        /* Special / complex strategy — no schedule can be generated */
        <View className="bg-surface border border-border rounded-2xl px-4 py-3 mb-4">
          <Text className="text-muted text-xs uppercase tracking-widest mb-1">
            Why no schedule?
          </Text>
          <Text className="text-text text-sm leading-5">
            This switch is too complex for a generic template. Maudsley 15th
            marks it as a specialist decision — consult the relevant chapter
            directly and consider specialist input. For mood stabilizers, the
            taper speed depends on serum levels and clinical stability rather
            than fixed days.
          </Text>
        </View>
      )}

      {/* Citations */}
      <CitationsPanel citations={plan.guidance.citations} />

      {/* Start-new-switch (no shareable schedule for guidance branches) */}
      <View className="mt-7">
        <Pressable
          onPress={() => {
            navigation.popToTop();
            navigation.navigate('Switch');
          }}
          className="bg-surface border border-border rounded-2xl py-4 flex-row items-center justify-center active:opacity-70"
        >
          <Icon name="refresh" size={16} color="#8b949e" />
          <Text className="text-text text-sm font-semibold ml-2">
            Start new switch
          </Text>
        </Pressable>
      </View>
    </ScreenContainer>
  );
}

// MAOI-washout sub-view. Kept inline (rather than a separate file) because
// it shares helpers and the screen routing gets simpler this way.
function WashoutResult({
  navigation,
  fromDrug,
  toDrug,
  fromDoseMg,
  plan,
}: {
  navigation: NativeStackScreenProps<RootStackParamList, 'Result'>['navigation'];
  fromDrug: Drug;
  toDrug: Drug;
  fromDoseMg: number;
  plan: Extract<SwitchPlan, { status: 'maoi_washout' }>;
}) {
  const onShare = async () => {
    const message = formatWashoutForShare(fromDrug, toDrug, fromDoseMg, plan);
    try {
      await Share.share({ message });
    } catch {
      // silent
    }
  };

  return (
    <ScreenContainer>
      <Text className="text-text text-2xl font-semibold mb-1">
        {fromDrug.genericName} → {toDrug.genericName}
      </Text>
      <Text className="text-muted text-base mb-4">
        Washout strategy — {plan.washoutDays} day
        {plan.washoutDays === 1 ? '' : 's'}
      </Text>

      {plan.safetyFlags.map((key) => {
        const d = getFlagDisplay(key);
        return (
          <SafetyFlag
            key={key}
            severity={d.severity}
            title={d.title}
            body={d.body}
          />
        );
      })}

      <View className="mb-4" />
      <WashoutPanel
        fromDrug={fromDrug}
        toDrug={toDrug}
        fromDoseMg={fromDoseMg}
        washoutDays={plan.washoutDays}
        direction={plan.direction}
      />

      <View className="mt-4 bg-surface border border-border rounded-2xl px-4 py-3">
        <Text className="text-muted text-xs uppercase tracking-wider mb-1">
          Why washout, not cross-taper
        </Text>
        <Text className="text-text text-sm leading-5">{plan.reason}</Text>
      </View>

      <ResultActions
        navigation={navigation}
        onShare={onShare}
        shareLabel="Share washout plan"
      />
    </ScreenContainer>
  );
}

// ── Indicative schedule generation ────────────────────────────────────────
// Generates a dose-by-day schedule from a Maudsley strategy category and the
// patient's entered doses. This is NOT a reviewed schedule — it is a
// framework derived algorithmically from the strategy. The ScheduleSummaryCard
// always shows it with an explicit "indicative — not reviewed" banner.
//
// Returns null for 'special' strategies that cannot be templated.

/** Snap a raw dose to the nearest available tablet increment. */
function nearestIncrement(dose: number, increments: number[]): number {
  if (dose <= 0 || !increments.length) return 0;
  const sorted = [...increments].sort((a, b) => a - b);
  return sorted.reduce(
    (best, inc) => (Math.abs(inc - dose) < Math.abs(best - dose) ? inc : best),
    sorted[0],
  );
}

function generateGuidanceSchedule(
  strategy: Maudsley15Strategy,
  fromDrug: Drug,
  toDrug: Drug,
  fromDoseMg: number,
  toDoseMg: number,
  waitDays?: number,
): ScheduleStep[] | null {
  /** Snap (fromDoseMg × pct) to the nearest fromDrug increment. */
  const snapFrom = (pct: number): number => {
    const target = fromDoseMg * pct;
    if (target <= 0) return 0;
    return nearestIncrement(target, fromDrug.dosing.increments);
  };

  const toStart = toDrug.dosing.startingDoseMg;
  let raw: ScheduleStep[];

  switch (strategy) {
    case 'direct_switch': {
      raw = [
        {
          day: 1,
          fromDoseMg: 0,
          toDoseMg: toStart,
          notes: `Stop ${fromDrug.genericName}. Start ${toDrug.genericName} at ${toStart} mg.`,
        },
      ];
      if (toStart < toDoseMg) {
        raw.push({
          day: 14,
          fromDoseMg: 0,
          toDoseMg: toDoseMg,
          notes: `Titrate ${toDrug.genericName} to ${toDoseMg} mg as tolerated.`,
        });
      }
      return raw;
    }

    case 'cross_taper_cautiously': {
      // Standard 4-week cross-taper:
      // Week 1: start to-drug at starting dose, keep from-drug at full dose
      // Week 2: from-drug ↓75%, to-drug → midpoint
      // Week 3: from-drug ↓50%, to-drug → target
      // Week 4: from-drug ↓25%
      // Day 28: stop from-drug
      const toMid = nearestIncrement(
        (toStart + toDoseMg) / 2,
        toDrug.dosing.increments,
      );
      raw = [
        {
          day: 1,
          fromDoseMg,
          toDoseMg: toStart,
          notes: `Start ${toDrug.genericName} at ${toStart} mg. Continue ${fromDrug.genericName} at current dose.`,
        },
        { day: 7, fromDoseMg: snapFrom(0.75), toDoseMg: toMid },
        {
          day: 14,
          fromDoseMg: snapFrom(0.5),
          toDoseMg: toDoseMg,
          notes: `${fromDrug.genericName} at half dose. ${toDrug.genericName} at target.`,
        },
        { day: 21, fromDoseMg: snapFrom(0.25), toDoseMg: toDoseMg },
        {
          day: 28,
          fromDoseMg: 0,
          toDoseMg: toDoseMg,
          notes: `Stop ${fromDrug.genericName}.`,
        },
      ];
      break;
    }

    case 'taper_then_wait': {
      const wait = waitDays ?? 14;
      raw = [
        {
          day: 1,
          fromDoseMg: snapFrom(0.75),
          toDoseMg: 0,
          notes: `Begin tapering ${fromDrug.genericName}.`,
        },
        { day: 7, fromDoseMg: snapFrom(0.5), toDoseMg: 0 },
        { day: 14, fromDoseMg: snapFrom(0.25), toDoseMg: 0 },
        {
          day: 21,
          fromDoseMg: 0,
          toDoseMg: 0,
          notes: `Stop ${fromDrug.genericName}. ${wait}-day washout begins.`,
        },
        {
          day: 21 + wait,
          fromDoseMg: 0,
          toDoseMg: toStart,
          notes: `Start ${toDrug.genericName} at ${toStart} mg. Titrate to target.`,
        },
      ];
      break;
    }

    case 'halve_and_add': {
      raw = [
        {
          day: 1,
          fromDoseMg: snapFrom(0.5),
          toDoseMg: toStart,
          notes: `Halve ${fromDrug.genericName}. Start ${toDrug.genericName} at ${toStart} mg.`,
        },
        {
          day: 14,
          fromDoseMg: snapFrom(0.25),
          toDoseMg: toDoseMg,
          notes: `Continue reducing ${fromDrug.genericName}. ${toDrug.genericName} at target dose.`,
        },
        {
          day: 28,
          fromDoseMg: 0,
          toDoseMg: toDoseMg,
          notes: `Stop ${fromDrug.genericName}.`,
        },
      ];
      break;
    }

    case 'special':
      return null; // Too complex to template; UI shows explanatory text instead.

    default:
      return null;
  }

  // Remove consecutive duplicate steps (can occur with very small doses
  // where multiple percentage targets snap to the same tablet increment).
  return raw.filter((step, i) => {
    if (i === 0) return true;
    const prev = raw[i - 1];
    return step.fromDoseMg !== prev.fromDoseMg || step.toDoseMg !== prev.toDoseMg;
  });
}
