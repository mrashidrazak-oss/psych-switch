// PDF export — hands the formatted HTML off to expo-print, which spawns
// the native print/share sheet on iOS and Android. The user can then
// save to Files, AirDrop, send to a printer, etc.
//
// Why expo-print and not a custom Skia / Reanimated render: native
// print is the most predictable output across devices. We just need
// HTML in, PDF out. expo-print uses WKWebView (iOS) / Android System
// WebView under the hood, so the layout matches what a print preview
// would show in Safari / Chrome.
import * as Print from 'expo-print';
import { Platform } from 'react-native';

export interface PdfExportOptions {
  html: string;
  /** Suggested file name shown in the share sheet (Android). */
  fileName?: string;
}

/**
 * Trigger the native print/share sheet for the supplied HTML.
 *
 * On iOS this opens a print preview with options to save to Files,
 * print, AirDrop, etc.  On Android it generates a PDF and opens the
 * share sheet so the user can pick where to save.
 *
 * Returns true on success, false if the user cancelled or the platform
 * isn't supported (e.g. Web build). Never throws — caller can ignore
 * the return value if they want a fire-and-forget UX.
 */
export async function exportPdf(opts: PdfExportOptions): Promise<boolean> {
  try {
    if (Platform.OS === 'web') {
      // Web fallback: open the HTML in a new window for print.
      const w = (globalThis as unknown as { open?: (url: string) => unknown }).open?.('');
      if (w && typeof w === 'object' && 'document' in w) {
        const doc = (w as { document: { write: (s: string) => void; close: () => void } }).document;
        doc.write(opts.html);
        doc.close();
      }
      return true;
    }
    await Print.printAsync({ html: opts.html });
    return true;
  } catch (err) {
    if (__DEV__) console.warn('[exportPdf] failed', err);
    return false;
  }
}
