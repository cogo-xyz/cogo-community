export type SseHandler = (event: string, data: string) => void;
export type TypedEvent =
  | 'ready' | 'meta' | 'progress' | 'queued' | 'handoff'
  | 'rag.item' | 'rag.done' | 'llm.done' | 'ui.generate'
  | 'page.ready' | 'page.chunk' | 'page.includes'
  | 'cli.plan' | 'cli.apply' | 'cli.done' | 'keepalive' | 'aborted' | 'error' | 'done';

export async function stream(url: string, headers: Record<string, string>, onEvent: SseHandler, body?: unknown, signal?: AbortSignal): Promise<void> {
  const resp = await fetch(url, { method: 'POST', headers: { accept: 'text/event-stream', ...headers }, body: body != null ? JSON.stringify(body) : undefined, signal });
  if (!resp.ok || !resp.body) throw new Error(`SSE error: ${resp.status}`);
  const reader = resp.body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';
  while (true) {
    const { value, done } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value, { stream: true });
    let idx = -1;
    while ((idx = buffer.indexOf('\n\n')) >= 0) {
      const raw = buffer.slice(0, idx).trimEnd();
      buffer = buffer.slice(idx + 2);
      let event = 'message'; let data = '';
      for (const line of raw.split('\n')) {
        if (line.startsWith('event: ')) event = line.slice(7).trim();
        if (line.startsWith('data: ')) data += line.slice(6);
      }
      onEvent(event, data);
    }
  }
}

export async function streamToFinal<T = unknown>(url: string, headers: Record<string, string>, body?: unknown, options?: { signal?: AbortSignal; onEvent?: (event: TypedEvent, data: string) => void }): Promise<T> {
  let final: T | undefined;
  await stream(url, headers, (ev, data) => {
    options?.onEvent?.(ev as TypedEvent, data);
    if (ev === 'done') {
      try { final = JSON.parse(data) as T; } catch { /* swallow */ }
    }
  }, body, options?.signal);
  if (final === undefined) throw new Error('No final done frame received');
  return final;
}
