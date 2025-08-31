import { z } from 'zod';
import { stream } from './sse.js';

export const MetaSchema = z.object({ trace_id: z.string(), envelope_version: z.string().optional(), intent: z.any().optional(), editor_context: z.any().optional() });
export const CliPlanSchema = z.object({ trace_id: z.string(), actions: z.array(z.any()) });
export const CliApplySchema = z.object({ trace_id: z.string(), action_id: z.string().optional(), status: z.string(), message: z.string().optional(), diff: z.any().optional() });
export const DoneSchema = z.object({ trace_id: z.string() }).catchall(z.any());
export const ErrorSchema = z.object({ code: z.string(), message: z.string(), retryable: z.boolean().optional(), trace_id: z.string().optional(), details: z.any().optional() });
export const QueuedSchema = z.object({ trace_id: z.string(), estimate_ms: z.number().optional(), reason: z.string().optional(), job_id: z.string().optional() });
export const HandoffSchema = z.object({ trace_id: z.string(), job_id: z.string(), reason: z.string().optional() });

export type TypedHandlers = Partial<{
  meta: (v: z.infer<typeof MetaSchema>) => void;
  'cli.plan': (v: z.infer<typeof CliPlanSchema>) => void;
  'cli.apply': (v: z.infer<typeof CliApplySchema>) => void;
  queued: (v: z.infer<typeof QueuedSchema>) => void;
  handoff: (v: z.infer<typeof HandoffSchema>) => void;
  done: (v: z.infer<typeof DoneSchema>) => void;
  error: (v: z.infer<typeof ErrorSchema>) => void;
}> & { fallback?: (event: string, data: string) => void };

export async function streamTyped(url: string, headers: Record<string, string>, body?: unknown, opts?: { signal?: AbortSignal; handlers?: TypedHandlers }) {
  // Ensure deterministic close on done/error using an internal AbortController (handoff doesn't force-close)
  const ac = new AbortController();
  if (opts?.signal) {
    try { opts.signal.addEventListener('abort', () => { try { ac.abort(); } catch {} }); } catch {}
  }
  try {
    await stream(url, headers, (ev, data) => {
      try {
        if (ev === 'meta') opts?.handlers?.meta?.(MetaSchema.parse(JSON.parse(data)));
        else if (ev === 'cli.plan') opts?.handlers?.['cli.plan']?.(CliPlanSchema.parse(JSON.parse(data)));
        else if (ev === 'cli.apply') opts?.handlers?.['cli.apply']?.(CliApplySchema.parse(JSON.parse(data)));
        else if (ev === 'queued') opts?.handlers?.queued?.(QueuedSchema.parse(JSON.parse(data)));
        else if (ev === 'handoff') opts?.handlers?.handoff?.(HandoffSchema.parse(JSON.parse(data)));
        else if (ev === 'done') opts?.handlers?.done?.(DoneSchema.parse(JSON.parse(data)));
        else if (ev === 'error') opts?.handlers?.error?.(ErrorSchema.parse(JSON.parse(data)));
        else opts?.handlers?.fallback?.(ev, data);
        if (ev === 'done' || ev === 'error') {
          try { ac.abort(); } catch {}
        }
      } catch { opts?.handlers?.fallback?.(ev, data); }
    }, body, ac.signal);
  } catch (e: any) {
    const name = (e && (e.name || e.constructor?.name)) || '';
    const msg = String(e?.message || e || '');
    if (!/AbortError/i.test(name) && !/aborted/i.test(msg)) throw e;
  }
}

export function aggregateCli() {
  const state = { total: 0, running: 0, success: 0, failed: 0, last: undefined as undefined | any };
  return {
    onPlan(v: any) { state.total = (v?.actions?.length ?? state.total) as number; },
    onApply(v: any) { state.last = v; if (v?.status === 'running') state.running++; if (v?.status === 'success') state.success++; if (v?.status === 'error') state.failed++; },
    snapshot() { return { ...state }; }
  };
}

// Subscribe or fallback: consumer should wire this to Supabase Realtime
// Async subscriber: returns an async unsubscribe fn; accepts optional AbortSignal
export type TraceSubscriber = (traceId: string, onEvent: (name: string, payload: any) => void, signal?: AbortSignal) => Promise<() => Promise<void>>;

// Start with SSE; switch/augment with Realtime on queued/handoff or idle
export async function streamOrRealtime(
  url: string,
  headers: Record<string, string>,
  body: any,
  opts: {
    signal?: AbortSignal;
    handlers?: TypedHandlers;
    subscribeTrace?: TraceSubscriber;
    idleMs?: number;
  } = {}
) {
  let traceId: string | undefined;
  let lastProgressAt = Date.now();
  let unsubscribeRt: (() => Promise<void>) | null = null;
  const idleMs = Math.max(5000, opts.idleMs ?? 15000);

  // Internal abort to guarantee close on done/error/handoff
  const ac = new AbortController();
  if (opts.signal) {
    try { opts.signal.addEventListener('abort', () => { try { ac.abort(); } catch {} }); } catch {}
  }

  const onFallback = (ev: string, data: string) => {
    if (ev === 'progress') lastProgressAt = Date.now();
    opts.handlers?.fallback?.(ev, data);
  };

  try {
    try {
      await stream(url, headers, async (ev, raw) => {
        try {
          const data = raw ? JSON.parse(raw) : {};
          if (!traceId && typeof data?.trace_id === 'string') traceId = data.trace_id;
          if (ev === 'queued') opts.handlers?.queued?.(QueuedSchema.parse(data));
          else if (ev === 'handoff') opts.handlers?.handoff?.(HandoffSchema.parse(data));
          else if (ev === 'meta') opts.handlers?.meta?.(MetaSchema.parse(data));
          else if (ev === 'cli.plan') opts.handlers?.['cli.plan']?.(CliPlanSchema.parse(data));
          else if (ev === 'cli.apply') opts.handlers?.['cli.apply']?.(CliApplySchema.parse(data));
          else if (ev === 'done') opts.handlers?.done?.(DoneSchema.parse(data));
          else if (ev === 'error') opts.handlers?.error?.(ErrorSchema.parse(data));
          else onFallback(ev, raw);

          // Auto-subscribe on queued/handoff
          if (!unsubscribeRt && opts.subscribeTrace && traceId && (ev === 'queued' || ev === 'handoff')) {
            unsubscribeRt = await opts.subscribeTrace(traceId, (name, payload) => {
              try {
                if (name === 'done') opts.handlers?.done?.(DoneSchema.parse(payload));
                else if (name === 'error') opts.handlers?.error?.(ErrorSchema.parse(payload));
                else if (name === 'progress') { lastProgressAt = Date.now(); opts.handlers?.fallback?.('progress', JSON.stringify(payload)); }
                else opts.handlers?.fallback?.(name, JSON.stringify(payload));
              } catch {}
            }, ac.signal);
          }

          // Ensure deterministic close (do not force-close on handoff; allow SSE to deliver 'done')
          if (ev === 'done' || ev === 'error') {
            try { ac.abort(); } catch {}
          }
        } catch { onFallback(ev, raw); }
      }, body, ac.signal);
    } catch (e: any) {
      const name = (e && (e.name || e.constructor?.name)) || '';
      const msg = String(e?.message || e || '');
      if (!/AbortError/i.test(name) && !/aborted/i.test(msg)) throw e;
    }

    // Idle fallback: if no progress for idleMs and trace exists, subscribe
    if (!unsubscribeRt && opts.subscribeTrace && traceId && Date.now() - lastProgressAt > idleMs) {
      unsubscribeRt = await opts.subscribeTrace(traceId, (name, payload) => {
        try { if (name === 'done') opts.handlers?.done?.(DoneSchema.parse(payload)); else opts.handlers?.fallback?.(name, JSON.stringify(payload)); } catch {}
      }, ac.signal);
    }
  } finally {
    if (unsubscribeRt) try { await unsubscribeRt(); } catch {}
  }
}


