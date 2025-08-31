export type EditorContext = {
  open_files?: string[];
  active_file?: string;
  selection?: { path: string; range: [number, number] };
};

export type IntentBlock = {
  text?: string;
  language?: string;
  keywords?: string[];
  parsed?: Record<string, unknown>;
  confidence?: number;
};

export type CliAction = {
  id: string;
  tool: string;
  command: string;
  args?: string[];
  input_artifact_ref?: string;
  target?: Record<string, unknown>;
  idempotency_key?: string;
  dry_run?: boolean;
  apply_strategy?: string;
  conflict_strategy?: string;
  depends_on?: string[];
};

export type ChatResponse = {
  task_type: string;
  title?: string;
  response?: string;
  trace_id: string;
  intent?: { intent?: IntentBlock } | IntentBlock;
  artifacts?: Record<string, unknown>;
  cli_actions?: CliAction[];
  execution?: Record<string, unknown>;
  envelope_version?: string;
  meta?: { editor_context?: EditorContext } & Record<string, unknown>;
  error?: { code: string; message: string; retryable?: boolean; details?: unknown };
};

export type Capabilities = {
  ok: boolean;
  envelope_version?: string;
  capabilities_version?: string;
  server_version?: string;
  task_type?: string[];
  task_types?: string[];
  intent_keywords?: string[];
  limits?: Record<string, unknown>;
  sse_events?: string[];
  dev_flags?: unknown;
  dev_flags_summary?: Record<string, boolean> | null;
  task_type_details?: Record<string, unknown> | null;
  editor_context?: unknown;
  editor_context_support?: boolean | null;
  requires_source?: string | null;
};

export type ErrorFrame = { code: string; message: string; retryable?: boolean; details?: unknown; trace_id?: string };
