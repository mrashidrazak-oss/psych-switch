// i18n scaffold — minimal, dependency-free.
//
// Single `t(key)` function with English as the source of truth and
// Bahasa Malaysia / Indonesia as targets. No pluralisation, no
// interpolation rules — clinical UI text is short and fully under
// our control, so a flat key→string map is sufficient.
//
// The point of this module is to wire UI labels so translations can
// land without code churn. Clinical content (rule rationales,
// schedule notes, citation paraphrases) stays in English until a
// native-speaker clinician reviews each translation.
import { getSettingsSync, type Locale } from '../engine/settings';

type Dict = Record<string, string>;

const EN: Dict = {
  // Home
  'home.tagline': 'Reviewed cross-titration schedules, depot protocols, and clozapine monitoring — built for the bedside.',
  'home.start_switch': 'Start a switch',
  'home.start_switch_sub': 'reviewed switching rules · cross-taper, washout, plateau',
  'home.search_placeholder': 'Search drugs or "X to Y"',
  'home.tools': 'Tools',
  'home.modules': 'Clinical modules',
  'home.about': 'About',
  'home.review': 'Review',
  'home.settings': 'Settings',
  'home.cases': 'Saved cases',
  'home.changelog': "What's new",
  'home.glossary': 'Glossary',
  'home.recents': 'Recent cases',
  'home.see_all': 'See all',
  'home.status_pending': 'Pre-release · pending clinical review',

  // Common
  'common.cancel': 'Cancel',
  'common.save': 'Save',
  'common.delete': 'Delete',
  'common.share': 'Share',
  'common.copy': 'Copy',
  'common.copied': 'Copied',
  'common.confirm': 'Confirm',
  'common.back': 'Back',
  'common.next': 'Next',
  'common.skip': 'Skip',
  'common.close': 'Close',
  'common.yes': 'Yes',
  'common.no': 'No',
  'common.search': 'Search',

  // Switch flow
  'switch.step': 'Step',
  'switch.from_drug': 'From drug',
  'switch.current_dose': 'Current dose',
  'switch.to_drug': 'To drug',
  'switch.target_dose': 'Target dose',
  'switch.show_schedule': 'Show switching schedule',
  'switch.previous_step': 'Previous step',
  'switch.back_to_home': 'Back to home',

  // Result
  'result.summary': 'Summary',
  'result.detailed': 'Detailed',
  'result.share_schedule': 'Share schedule',
  'result.export_pdf': 'Export PDF',
  'result.start_new': 'Start new switch',
  'result.discharge_summary': 'Discharge summary',
  'result.counselling_card': 'Patient counselling card',
  'result.report_issue': 'Report an issue with this rule',
  'result.psychswitch_score': 'PsychSwitch Score',
  'result.predicted_ae': 'Predicted side-effect profile',
  'result.alternatives': "What if this doesn't work out?",

  // Privacy
  'privacy.banner': 'Stored on this device only. No name, MRN, NRIC or DOB.',
};

const MS: Dict = {
  // Home
  'home.tagline': 'Jadual pertukaran ubat yang disemak, protokol depot, dan pemantauan klozapin — dibina untuk klinik.',
  'home.start_switch': 'Mula pertukaran',
  'home.start_switch_sub': 'peraturan pertukaran yang disemak · cross-taper, washout, plateau',
  'home.search_placeholder': 'Cari ubat atau "X kepada Y"',
  'home.tools': 'Alat',
  'home.modules': 'Modul klinikal',
  'home.about': 'Mengenai',
  'home.review': 'Semak',
  'home.settings': 'Tetapan',
  'home.cases': 'Kes yang disimpan',
  'home.changelog': 'Apa yang baru',
  'home.glossary': 'Glosari',
  'home.recents': 'Kes terkini',
  'home.see_all': 'Lihat semua',
  'home.status_pending': 'Pra-keluaran · menunggu semakan klinikal',

  // Common
  'common.cancel': 'Batal',
  'common.save': 'Simpan',
  'common.delete': 'Padam',
  'common.share': 'Kongsi',
  'common.copy': 'Salin',
  'common.copied': 'Disalin',
  'common.confirm': 'Sahkan',
  'common.back': 'Kembali',
  'common.next': 'Seterusnya',
  'common.skip': 'Langkau',
  'common.close': 'Tutup',
  'common.yes': 'Ya',
  'common.no': 'Tidak',
  'common.search': 'Cari',

  // Switch flow
  'switch.step': 'Langkah',
  'switch.from_drug': 'Ubat asal',
  'switch.current_dose': 'Dos semasa',
  'switch.to_drug': 'Ubat baru',
  'switch.target_dose': 'Dos sasaran',
  'switch.show_schedule': 'Papar jadual pertukaran',
  'switch.previous_step': 'Langkah sebelumnya',
  'switch.back_to_home': 'Kembali ke laman utama',

  // Result
  'result.summary': 'Ringkasan',
  'result.detailed': 'Terperinci',
  'result.share_schedule': 'Kongsi jadual',
  'result.export_pdf': 'Eksport PDF',
  'result.start_new': 'Mulakan pertukaran baru',
  'result.discharge_summary': 'Ringkasan discaj',
  'result.counselling_card': 'Kad kaunseling pesakit',
  'result.report_issue': 'Laporkan masalah dengan peraturan ini',
  'result.psychswitch_score': 'Skor PsychSwitch',
  'result.predicted_ae': 'Profil kesan sampingan dijangka',
  'result.alternatives': 'Bagaimana jika ini tidak berjaya?',

  // Privacy
  'privacy.banner': 'Disimpan pada peranti ini sahaja. Tiada nama, MRN, NRIC atau tarikh lahir.',
};

const ID: Dict = {
  // Home
  'home.tagline': 'Jadwal pergantian obat yang ditinjau, protokol depot, dan pemantauan klozapin — dibuat untuk klinik.',
  'home.start_switch': 'Mulai penggantian',
  'home.start_switch_sub': 'aturan penggantian yang ditinjau · cross-taper, washout, plateau',
  'home.search_placeholder': 'Cari obat atau "X ke Y"',
  'home.tools': 'Alat',
  'home.modules': 'Modul klinis',
  'home.about': 'Tentang',
  'home.review': 'Tinjau',
  'home.settings': 'Pengaturan',
  'home.cases': 'Kasus tersimpan',
  'home.changelog': 'Apa yang baru',
  'home.glossary': 'Glosarium',
  'home.recents': 'Kasus terbaru',
  'home.see_all': 'Lihat semua',
  'home.status_pending': 'Pra-rilis · menunggu tinjauan klinis',

  // Common
  'common.cancel': 'Batal',
  'common.save': 'Simpan',
  'common.delete': 'Hapus',
  'common.share': 'Bagikan',
  'common.copy': 'Salin',
  'common.copied': 'Tersalin',
  'common.confirm': 'Konfirmasi',
  'common.back': 'Kembali',
  'common.next': 'Lanjut',
  'common.skip': 'Lewati',
  'common.close': 'Tutup',
  'common.yes': 'Ya',
  'common.no': 'Tidak',
  'common.search': 'Cari',

  // Switch flow
  'switch.step': 'Langkah',
  'switch.from_drug': 'Obat asal',
  'switch.current_dose': 'Dosis saat ini',
  'switch.to_drug': 'Obat baru',
  'switch.target_dose': 'Dosis target',
  'switch.show_schedule': 'Tampilkan jadwal penggantian',
  'switch.previous_step': 'Langkah sebelumnya',
  'switch.back_to_home': 'Kembali ke beranda',

  // Result
  'result.summary': 'Ringkasan',
  'result.detailed': 'Detail',
  'result.share_schedule': 'Bagikan jadwal',
  'result.export_pdf': 'Ekspor PDF',
  'result.start_new': 'Mulai penggantian baru',
  'result.discharge_summary': 'Ringkasan pulang',
  'result.counselling_card': 'Kartu konseling pasien',
  'result.report_issue': 'Laporkan masalah dengan aturan ini',
  'result.psychswitch_score': 'Skor PsychSwitch',
  'result.predicted_ae': 'Profil efek samping yang diprediksi',
  'result.alternatives': 'Bagaimana jika ini tidak berhasil?',

  // Privacy
  'privacy.banner': 'Disimpan hanya di perangkat ini. Tidak ada nama, MRN, NIK atau tanggal lahir.',
};

const DICTS: Record<Locale, Dict> = { en: EN, ms: MS, id: ID };

/**
 * Translate a key. Falls back to English if the key is missing in the
 * active locale, and to the key itself if missing in English (signalling
 * a typo to the developer).
 */
export function t(key: string): string {
  const locale = getSettingsSync().locale;
  return DICTS[locale]?.[key] ?? EN[key] ?? key;
}

export function activeLocale(): Locale {
  return getSettingsSync().locale;
}

/**
 * Used by tests to verify translation coverage.
 */
export function _i18nDicts(): Record<Locale, Dict> {
  return DICTS;
}
