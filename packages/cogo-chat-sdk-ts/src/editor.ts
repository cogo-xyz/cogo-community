import type { EditorContext } from './types.js';

export type Selection = { path: string; range: [number, number] };

export function buildEditorContext(params: {
  openFiles?: string[];
  activeFile?: string;
  selection?: Selection;
}): EditorContext {
  const ctx: EditorContext = {};
  if (params.openFiles && params.openFiles.length) ctx.open_files = params.openFiles;
  if (params.activeFile) ctx.active_file = params.activeFile;
  if (params.selection) ctx.selection = params.selection;
  return ctx;
}


