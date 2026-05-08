// Babel config — transforms our TS/JSX so React Native can run it.
//
// The `jsxImportSource: 'nativewind'` line is what lets us use Tailwind's
// `className="..."` on React Native components.
//
// We use a separate, simpler preset under the `test` Babel env so Jest can
// run pure-logic tests (engine, types) without dragging in RN's
// non-standard JS (Flow types in @react-native/js-polyfills, etc.).
module.exports = function (api) {
  // Cache must be keyed by NODE_ENV so the `test` branch below picks up
  // when Jest runs (and doesn't reuse the app build's cache).
  api.cache.using(() => process.env.NODE_ENV);
  const isTest = api.env('test');

  if (isTest) {
    return {
      presets: [
        ['@babel/preset-env', { targets: { node: 'current' } }],
        '@babel/preset-typescript',
      ],
    };
  }

  return {
    presets: [
      ['babel-preset-expo', { jsxImportSource: 'nativewind' }],
      'nativewind/babel',
    ],
  };
};
