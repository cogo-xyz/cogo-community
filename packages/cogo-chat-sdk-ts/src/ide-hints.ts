export type IdeHints = {
  toast?: string;
  toast_ko?: string;
  toast_en?: string;
  toast_ru?: string;
  toast_th?: string;
  toast_ja?: string;
  open_file?: string;
  highlight?: { path: string; range: [number, number] };
  next_action?: string;
  [k: string]: unknown;
};

export function selectToast(hints: IdeHints | null | undefined, preferred: string = 'en'): string | undefined {
  if (!hints) return undefined;
  const lang = (preferred || 'en').toLowerCase();
  const map: Record<string, string | undefined> = {
    en: hints.toast_en ?? hints.toast,
    ko: hints.toast_ko ?? hints.toast,
    ru: hints.toast_ru ?? hints.toast,
    th: hints.toast_th ?? hints.toast,
    ja: hints.toast_ja ?? hints.toast,
  };
  return map[lang] ?? hints.toast;
}


