import { CogoClient } from './client.js';
import { stream, streamToFinal } from './sse.js';
import type { ChatResponse, EditorContext, IntentBlock } from './types.js';

export type GenerateRequest = {
  text?: string;
  prompt?: string;
  intent?: IntentBlock;
  editor_context?: EditorContext;
  dev_cli_simulate?: boolean;
  // dev only
  dev_abort_after_ms?: number;
};

export class ChatEndpoints {
  constructor(private client: CogoClient) {}

  async designGenerate(req: GenerateRequest): Promise<ChatResponse> {
    const url = `${(this.client as any).base}/design-generate`;
    const res = await fetch(url, { method: 'POST', headers: { 'content-type': 'application/json', ...(this.client as any).headers() }, body: JSON.stringify(req) });
    return await res.json();
  }

  async streamDesignGenerate(req: GenerateRequest, onEvent: (event: string, data: string) => void, opts?: { signal?: AbortSignal; idempotency_key?: string }): Promise<void> {
    const url = `${this.client.baseUrl()}/design-generate`;
    const headers = { 'content-type': 'application/json', accept: 'text/event-stream', ...this.client.headers(), ...(opts?.idempotency_key ? { 'idempotency-key': opts.idempotency_key } : {}) };
    await stream(url, headers, onEvent, req, opts?.signal);
  }
  async streamDesignGenerateToFinal(req: GenerateRequest, opts?: { signal?: AbortSignal; onEvent?: (event: any, data: string) => void; idempotency_key?: string }): Promise<any> {
    const url = `${this.client.baseUrl()}/design-generate`;
    const headers = { 'content-type': 'application/json', accept: 'text/event-stream', ...this.client.headers(), ...(opts?.idempotency_key ? { 'idempotency-key': opts.idempotency_key } : {}) };
    return await streamToFinal(url, headers, req, { signal: opts?.signal, onEvent: opts?.onEvent });
  }

  // figma-context scan (SSE)
  async streamFigmaContext(body: Record<string, unknown>, onEvent: (event: string, data: string) => void, opts?: { signal?: AbortSignal; idempotency_key?: string }): Promise<void> {
    const url = `${this.client.baseUrl()}/figma-context/stream`;
    const headers = { 'content-type': 'application/json', accept: 'text/event-stream', ...this.client.headers(), ...(opts?.idempotency_key ? { 'idempotency-key': opts.idempotency_key } : {}) };
    await stream(url, headers, onEvent, body, opts?.signal);
  }

  // compat: variables derive
  async compatVariablesDerive(payload: Record<string, unknown>): Promise<ChatResponse> {
    const url = `${this.client.baseUrl()}/figma-compat/uui/variables/derive`;
    const res = await fetch(url, { method: 'POST', headers: { 'content-type': 'application/json', ...this.client.headers() }, body: JSON.stringify(payload) });
    return await res.json();
  }

  // compat: symbols map
  async compatSymbolsMap(payload: Record<string, unknown>): Promise<ChatResponse> {
    const url = `${this.client.baseUrl()}/figma-compat/uui/symbols/map`;
    const res = await fetch(url, { method: 'POST', headers: { 'content-type': 'application/json', ...this.client.headers() }, body: JSON.stringify(payload) });
    return await res.json();
  }

  // intent-resolve: info/capabilities
  async intentCapabilities(): Promise<any> {
    const url = `${this.client.baseUrl()}/intent-resolve/info`;
    const res = await fetch(url, { headers: this.client.headers() });
    return await res.json();
  }
  async intentResolve(text: string): Promise<any> {
    const url = `${this.client.baseUrl()}/intent-resolve`;
    const res = await fetch(url, { method: 'POST', headers: { 'content-type': 'application/json', ...this.client.headers() }, body: JSON.stringify({ text }) });
    return await res.json();
  }

  // attachments: presign / ingest / result
  async attachmentsPresign(payload: Record<string, unknown>): Promise<any> {
    const url = `${this.client.baseUrl()}/figma-compat/uui/presign`;
    const res = await fetch(url, { method: 'POST', headers: { 'content-type': 'application/json', ...this.client.headers() }, body: JSON.stringify(payload) });
    return await res.json();
  }
  async attachmentsIngest(payload: Record<string, unknown>): Promise<any> {
    const url = `${this.client.baseUrl()}/figma-compat/uui/ingest`;
    const res = await fetch(url, { method: 'POST', headers: { 'content-type': 'application/json', ...this.client.headers() }, body: JSON.stringify(payload) });
    return await res.json();
  }
  async attachmentsResult(traceId: string): Promise<any> {
    const url = `${this.client.baseUrl()}/figma-compat/uui/ingest/result?traceId=${encodeURIComponent(traceId)}`;
    const res = await fetch(url, { headers: this.client.headers() });
    return await res.json();
  }

  // BDD / ActionFlow / Data Action
  async bddGenerate(payload: Record<string, unknown>): Promise<ChatResponse> {
    const url = `${this.client.baseUrl()}/figma-compat/uui/bdd/generate`;
    const res = await fetch(url, { method: 'POST', headers: { 'content-type': 'application/json', ...this.client.headers() }, body: JSON.stringify(payload) });
    return await res.json();
  }
  async bddRefine(payload: Record<string, unknown>): Promise<ChatResponse> {
    const url = `${this.client.baseUrl()}/figma-compat/uui/bdd/refine`;
    const res = await fetch(url, { method: 'POST', headers: { 'content-type': 'application/json', ...this.client.headers() }, body: JSON.stringify(payload) });
    return await res.json();
  }
  async actionflowGenerate(payload: Record<string, unknown>): Promise<ChatResponse> {
    const url = `${this.client.baseUrl()}/figma-compat/uui/actionflow/generate`;
    const res = await fetch(url, { method: 'POST', headers: { 'content-type': 'application/json', ...this.client.headers() }, body: JSON.stringify(payload) });
    return await res.json();
  }
  async actionflowRefine(payload: Record<string, unknown>): Promise<ChatResponse> {
    const url = `${this.client.baseUrl()}/figma-compat/uui/actionflow/refine`;
    const res = await fetch(url, { method: 'POST', headers: { 'content-type': 'application/json', ...this.client.headers() }, body: JSON.stringify(payload) });
    return await res.json();
  }
  async dataActionGenerate(payload: Record<string, unknown>): Promise<ChatResponse> {
    const url = `${this.client.baseUrl()}/figma-compat/uui/data_action/generate`;
    const res = await fetch(url, { method: 'POST', headers: { 'content-type': 'application/json', ...this.client.headers() }, body: JSON.stringify(payload) });
    return await res.json();
  }
}
