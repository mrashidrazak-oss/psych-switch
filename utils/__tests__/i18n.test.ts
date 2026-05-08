import { _i18nDicts } from '../i18n';

describe('i18n dictionaries', () => {
  test('every locale carries the same set of keys', () => {
    const dicts = _i18nDicts();
    const enKeys = new Set(Object.keys(dicts.en));
    for (const locale of ['ms', 'id'] as const) {
      const localeKeys = new Set(Object.keys(dicts[locale]));
      const missing = [...enKeys].filter((k) => !localeKeys.has(k));
      const extra = [...localeKeys].filter((k) => !enKeys.has(k));
      expect({ locale, missing, extra }).toEqual({ locale, missing: [], extra: [] });
    }
  });

  test('every English value is non-empty', () => {
    for (const [k, v] of Object.entries(_i18nDicts().en)) {
      expect(v.length).toBeGreaterThan(0);
      expect(k.length).toBeGreaterThan(0);
    }
  });

  test('keys follow dot-notation namespacing', () => {
    for (const k of Object.keys(_i18nDicts().en)) {
      expect(k).toMatch(/^[a-z]+\.[a-z_]+$/);
    }
  });
});
