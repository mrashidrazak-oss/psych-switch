// App-wide error boundary.
//
// Catches React render errors and shows a graceful fallback rather than
// the white screen of death. Wired up in App.tsx around <NavigationContainer>.
//
// Sentry hook: when the user opts into crash reports (Settings → Privacy),
// `reportCrash` is called from componentDidCatch. We deliberately keep the
// telemetry layer pluggable so different builds can wire Sentry / Bugsnag
// / Crashlytics without touching every screen.
import { Component, type ErrorInfo, type ReactNode } from 'react';
import { Pressable, Text, View } from 'react-native';
import { Icon } from './Icon';
import { getSettingsSync } from '../engine/settings';

interface Props {
  children: ReactNode;
}
interface State {
  error: Error | null;
}

// Pluggable crash reporter — replaced at build time when wiring Sentry.
let _reportCrash: (err: Error, info?: ErrorInfo) => void = () => {};
export function setCrashReporter(fn: (err: Error, info?: ErrorInfo) => void) {
  _reportCrash = fn;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { error };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    // Respect the user's opt-in.
    if (getSettingsSync().crashReports) {
      try { _reportCrash(error, info); } catch {}
    }
    // Always keep a console trace for `expo start` / Flipper.
    if (__DEV__) console.error('[ErrorBoundary]', error, info);
  }

  reset = () => this.setState({ error: null });

  render() {
    if (!this.state.error) return this.props.children;

    return (
      <View className="flex-1 bg-bg justify-center items-center px-6">
        <View className="w-12 h-12 rounded-2xl bg-danger/15 border border-danger/30 items-center justify-center mb-4">
          <Icon name="shield" size={20} color="#ef4444" />
        </View>
        <Text className="text-text text-xl font-bold mb-1">Something went wrong</Text>
        <Text className="text-muted text-sm leading-5 text-center mb-4">
          The app hit an unexpected error. Your local data is safe.
        </Text>

        <View className="bg-surface border border-border rounded-2xl px-4 py-3 mb-5 max-w-full">
          <Text className="text-muted text-eyebrow uppercase tracking-widest mb-1">
            Detail
          </Text>
          <Text className="text-text text-xs" numberOfLines={4}>
            {this.state.error.message || String(this.state.error)}
          </Text>
        </View>

        <Pressable
          onPress={this.reset}
          className="bg-accent rounded-2xl px-6 py-3 active:opacity-80"
        >
          <Text className="text-white text-sm font-semibold">Reload screen</Text>
        </Pressable>
      </View>
    );
  }
}
