// Tiny isolating error boundary used around individual visualization
// cards (PK overlay, crossover chart, receptor occupancy) so a render
// failure in one chart doesn't bring down the whole Result screen.
//
// The big app-wide ErrorBoundary in App.tsx is still there as the
// outer net — but for non-critical decorative content like a chart we
// prefer to silently swallow + log, rather than show the user a full
// "something went wrong" screen.
//
// Use sparingly. Only wrap content that the user can lose without
// losing the *core* clinical workflow (i.e. wrap the PK chart, never
// the schedule itself).
import { Component, type ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
  /** Optional debug tag — printed to the dev console when the boundary catches. */
  tag?: string;
}
interface State {
  errored: boolean;
}

export class SafeBlock extends Component<Props, State> {
  state: State = { errored: false };

  static getDerivedStateFromError(): State {
    return { errored: true };
  }

  componentDidCatch(error: Error) {
    if (__DEV__) {
      // eslint-disable-next-line no-console
      console.warn(`[SafeBlock${this.props.tag ? `:${this.props.tag}` : ''}]`, error.message);
    }
  }

  render() {
    if (this.state.errored) return this.props.fallback ?? null;
    return this.props.children;
  }
}
