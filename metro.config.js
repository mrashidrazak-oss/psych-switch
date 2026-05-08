// Metro is React Native's bundler. We wrap Expo's default config with
// NativeWind so Tailwind classes resolve correctly during bundling.
const { getDefaultConfig } = require('expo/metro-config');
const { withNativeWind } = require('nativewind/metro');

const config = getDefaultConfig(__dirname);

module.exports = withNativeWind(config, { input: './global.css' });
