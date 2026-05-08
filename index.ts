// App entry point.
// Required because pnpm's nested node_modules layout breaks the default
// `expo/AppEntry.js` (it uses a relative path `../../App` that assumes
// npm/yarn's flat layout). Registering the root component locally is
// pnpm-safe and the SDK 54+ recommended pattern.
import { registerRootComponent } from 'expo';
import App from './App';

registerRootComponent(App);
