// Renders a prominent warning card. Used for MAOI washout, serotonin
// syndrome risk, discontinuation syndrome, anticholinergic rebound, etc.
// Per spec, these must appear ABOVE the schedule, not buried.
//
// As of v0.4.10 this is a thin wrapper over the unified <Banner>
// primitive — same stripe-left visual, mapped to Banner's tone scale.
import type { SafetySeverity } from '../utils/safetyFlags';
import { Banner, type BannerTone } from './Banner';

/** Map SafetySeverity → BannerTone. */
function severityTone(s: SafetySeverity): BannerTone {
  switch (s) {
    case 'info':    return 'info';
    case 'warning': return 'warning';
    case 'danger':  return 'danger';
  }
}

const EYEBROW: Record<SafetySeverity, string> = {
  info: 'Note',
  warning: 'Warning',
  danger: 'Danger',
};

export function SafetyFlag({
  severity = 'warning',
  title,
  body,
}: {
  severity?: SafetySeverity;
  title: string;
  body: string;
}) {
  return (
    <Banner
      tone={severityTone(severity)}
      eyebrow={EYEBROW[severity]}
      title={title}
      body={body}
      className="mb-3"
    />
  );
}
