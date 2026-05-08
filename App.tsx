// App entry. Wires up:
//  - the global Tailwind CSS (NativeWind)
//  - safe-area context (for notched phones)
//  - native-stack navigation
//  - the first-launch disclaimer gate
import './global.css';

import { NavigationContainer, DefaultTheme } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { StatusBar } from 'expo-status-bar';
import { useEffect } from 'react';
import { LogBox, View } from 'react-native';
import { configureForeground } from './engine/notifications';
import { useSettings } from './engine/settings';
import { initSentry } from './utils/sentry';

// Suppress known-harmless library warnings:
//
//  1. NativeWind's css-interop registers className on the *deprecated*
//     core SafeAreaView. Known issue; harmless.
//  2. expo-notifications loudly warns that Expo Go SDK 53+ no longer
//     supports REMOTE push registration. We only use LOCAL scheduled
//     notifications — those still work fine. Filtering these so the
//     console isn't drowned in a feature we don't use.
LogBox.ignoreLogs([
  'SafeAreaView has been deprecated',
  'expo-notifications: Android Push notifications',
  '`expo-notifications` functionality is not fully supported in Expo Go',
]);
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { DisclaimerModal, useDisclaimerGate } from './components/DisclaimerModal';
import { ErrorBoundary } from './components/ErrorBoundary';
import { OnboardingTour } from './components/OnboardingTour';
import { AboutScreen } from './screens/AboutScreen';
import { AdverseEffectsScreen } from './screens/AdverseEffectsScreen';
import { CaseManagerScreen } from './screens/CaseManagerScreen';
import { ChangelogScreen } from './screens/ChangelogScreen';
import { ClozapineAncCheckerScreen } from './screens/ClozapineAncCheckerScreen';
import { DepotHomeScreen } from './screens/DepotHomeScreen';
import { EquivalencyScreen } from './screens/EquivalencyScreen';
import { ErrataScreen } from './screens/ErrataScreen';
import { GlossaryScreen } from './screens/GlossaryScreen';
import { MaintenaScreen } from './screens/MaintenaScreen';
import { PatientContextScreen } from './screens/PatientContextScreen';
import { PrivacyScreen } from './screens/PrivacyScreen';
import { SettingsScreen } from './screens/SettingsScreen';
import { TermsScreen } from './screens/TermsScreen';
import { TrinzaScreen } from './screens/TrinzaScreen';
import { ReviewDashboardScreen } from './screens/ReviewDashboardScreen';
import { SustennaScreen } from './screens/SustennaScreen';
import { ClozapineCommunityCriteriaScreen } from './screens/ClozapineCommunityCriteriaScreen';
import { ClozapineHomeScreen } from './screens/ClozapineHomeScreen';
import { ClozapineInitiationScreen } from './screens/ClozapineInitiationScreen';
import { ClozapineMonitoringScreen } from './screens/ClozapineMonitoringScreen';
import { ClozapineRechallengeScreen } from './screens/ClozapineRechallengeScreen';
import { HomeScreen } from './screens/HomeScreen';
import { LithiumTaperingScreen } from './screens/LithiumTaperingScreen';
import { MoodStabilizerDetailScreen } from './screens/MoodStabilizerDetailScreen';
import { MoodStabilizerHomeScreen } from './screens/MoodStabilizerHomeScreen';
import { QtcStackerScreen } from './screens/QtcStackerScreen';
import { RamadanModeScreen } from './screens/RamadanModeScreen';
import { ResultScreen } from './screens/ResultScreen';
import { SwitchScreen } from './screens/SwitchScreen';
import type { RootStackParamList } from './utils/navigation';

const Stack = createNativeStackNavigator<RootStackParamList>();

// Single source of truth for the app-wide dark background. Used
// across every wrapper layer (root view, SafeAreaProvider, navigator
// screenOptions, navigation theme) so navigation transitions never
// flash through to a system-default white background.
const BG = '#0b0f14';

// Force a dark navigation theme so the header bar matches the app body.
const NavTheme = {
  ...DefaultTheme,
  dark: true,
  colors: {
    ...DefaultTheme.colors,
    background: BG,
    card: BG,
    text: '#e6edf3',
    border: '#1f2933',
    primary: '#3b82f6',
    notification: '#ef4444',
  },
};

export default function App() {
  const { acknowledged, acknowledge } = useDisclaimerGate();
  const { settings, loaded } = useSettings();

  // Init Sentry once the user's crash-report preference has loaded and is
  // opted-in. The init function itself is idempotent + a no-op in dev,
  // without a DSN, or when the toggle is off.
  useEffect(() => {
    if (loaded && settings.crashReports) initSentry();
  }, [loaded, settings.crashReports]);

  // Configure local-notification foreground behaviour exactly once on
  // mount. The handler decides what notifications look like when the
  // app is in the foreground; without it, scheduled notifications are
  // silently delivered with no banner.
  useEffect(() => {
    configureForeground();
  }, []);

  // While we read AsyncStorage, render an empty dark view so we don't flash
  // light content.
  if (acknowledged === null) {
    return <View style={{ flex: 1, backgroundColor: BG }} />;
  }

  return (
    // Every wrapper layer gets an explicit dark backgroundColor.
    // Without this, the underlying UIView (iOS) / Window (Android)
    // shows its default opaque-white background during navigation
    // transitions — visible as a brief white flicker between screens
    // and on back/swipe-pop. NativeWind's `bg-bg` resolves at
    // render-time but native-stack pushes its destination view
    // BEFORE React paints, so the className isn't enough on its own.
    <GestureHandlerRootView style={{ flex: 1, backgroundColor: BG }}>
      <SafeAreaProvider style={{ backgroundColor: BG }}>
        <StatusBar style="light" />
        <DisclaimerModal visible={!acknowledged} onAcknowledge={acknowledge} />
        {/* Onboarding shows AFTER disclaimer is acknowledged. Both are
            modals, but they don't stack — onboarding's AsyncStorage
            check happens after first render so the disclaimer wins
            the first paint. */}
        {acknowledged && <OnboardingTour />}
        <ErrorBoundary>
        <NavigationContainer theme={NavTheme}>
          <Stack.Navigator
            screenOptions={{
              headerStyle: { backgroundColor: BG },
              headerTintColor: '#e6edf3',
              headerTitleStyle: { fontWeight: '600' },
              // contentStyle paints the underlying view that
              // react-native-screens creates *before* the React
              // children render. With a dark colour here the
              // transition no longer flashes white on push or pop.
              contentStyle: { backgroundColor: BG },
              // Ensures the iOS large-title header sub-area also
              // matches; without this it can read the system
              // light-mode background even when the nav theme is dark.
              headerShadowVisible: false,
              // Tighter slide on iOS = less of the underlying
              // window visible during the animation, further
              // reducing any flicker.
              animation: 'default',
            }}
          >
            <Stack.Screen
              name="Home"
              component={HomeScreen}
              options={{ title: 'PsychSwitch' }}
            />
            <Stack.Screen
              name="Switch"
              component={SwitchScreen}
              options={{ title: 'New switch' }}
            />
            <Stack.Screen
              name="Result"
              component={ResultScreen}
              options={{ title: 'Schedule' }}
            />
            <Stack.Screen
              name="About"
              component={AboutScreen}
              options={{ title: 'About' }}
            />
            <Stack.Screen
              name="ClozapineHome"
              component={ClozapineHomeScreen}
              options={{ title: 'Clozapine' }}
            />
            <Stack.Screen
              name="ClozapineInitiation"
              component={ClozapineInitiationScreen}
              options={{ title: 'Titration' }}
            />
            <Stack.Screen
              name="ClozapineMonitoring"
              component={ClozapineMonitoringScreen}
              options={{ title: 'Monitoring' }}
            />
            <Stack.Screen
              name="ClozapineAncChecker"
              component={ClozapineAncCheckerScreen}
              options={{ title: 'ANC / WBC checker' }}
            />
            <Stack.Screen
              name="ClozapineRechallenge"
              component={ClozapineRechallengeScreen}
              options={{ title: 'Interruption restart' }}
            />
            <Stack.Screen
              name="ClozapineCommunityCriteria"
              component={ClozapineCommunityCriteriaScreen}
              options={{ title: 'Community initiation' }}
            />
            <Stack.Screen
              name="MoodStabilizerHome"
              component={MoodStabilizerHomeScreen}
              options={{ title: 'Mood stabilizers' }}
            />
            <Stack.Screen
              name="MoodStabilizerDetail"
              component={MoodStabilizerDetailScreen}
              options={{ title: 'Drug profile' }}
            />
            <Stack.Screen
              name="LithiumTapering"
              component={LithiumTaperingScreen}
              options={{ title: 'Stopping lithium' }}
            />
            <Stack.Screen
              name="DepotHome"
              component={DepotHomeScreen}
              options={{ title: 'LAI Depot Initiation' }}
            />
            <Stack.Screen
              name="Sustenna"
              component={SustennaScreen}
              options={{ title: 'Invega Sustenna' }}
            />
            <Stack.Screen
              name="Maintena"
              component={MaintenaScreen}
              options={{ title: 'Abilify Maintena' }}
            />
            <Stack.Screen
              name="Trinza"
              component={TrinzaScreen}
              options={{ title: 'Invega Trinza (PP3M)' }}
            />
            <Stack.Screen
              name="ReviewDashboard"
              component={ReviewDashboardScreen}
              options={{ title: 'Review Dashboard' }}
            />
            <Stack.Screen
              name="QtcStacker"
              component={QtcStackerScreen}
              options={{ title: 'QTc stacker' }}
            />
            <Stack.Screen
              name="RamadanMode"
              component={RamadanModeScreen}
              options={{ title: 'Ramadan mode' }}
            />
            <Stack.Screen
              name="Equivalency"
              component={EquivalencyScreen}
              options={{ title: 'Dose equivalents' }}
            />
            <Stack.Screen
              name="AdverseEffects"
              component={AdverseEffectsScreen}
              options={{ title: 'Adverse-effect lookup' }}
            />
            <Stack.Screen
              name="PatientContext"
              component={PatientContextScreen}
              options={{ title: 'Patient context' }}
            />
            <Stack.Screen
              name="CaseManager"
              component={CaseManagerScreen}
              options={{ title: 'Saved cases' }}
            />
            <Stack.Screen
              name="Settings"
              component={SettingsScreen}
              options={{ title: 'Settings' }}
            />
            <Stack.Screen
              name="Changelog"
              component={ChangelogScreen}
              options={{ title: "What's new" }}
            />
            <Stack.Screen
              name="Privacy"
              component={PrivacyScreen}
              options={{ title: 'Privacy' }}
            />
            <Stack.Screen
              name="Terms"
              component={TermsScreen}
              options={{ title: 'Terms of use' }}
            />
            <Stack.Screen
              name="Glossary"
              component={GlossaryScreen}
              options={{ title: 'Glossary' }}
            />
            <Stack.Screen
              name="Errata"
              component={ErrataScreen}
              options={{ title: 'Errata' }}
            />
          </Stack.Navigator>
        </NavigationContainer>
        </ErrorBoundary>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
