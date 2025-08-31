// Supabase Realtime helper to subscribe to broadcast events on trace:{traceId}
export type RealtimeTraceHandler = (event: string, payload: any) => void;

export function createSupabaseTraceSubscriber(supabase: any) {
  return async (
    traceId: string,
    onEvent: RealtimeTraceHandler,
    signal?: AbortSignal
  ): Promise<() => Promise<void>> => {
    const channelName = `trace:${traceId}`;
    let channel: any = null;
    let subscribed = false;
    let stopped = false;
    let retryTimer: any = null;

    const subscribe = () => {
      if (subscribed) return;
      if (stopped || signal?.aborted) return;
      channel = supabase.channel(channelName);
      channel
        .on('broadcast', { event: '*' }, (payload: any) => {
          try { onEvent(payload.event, payload.payload); } catch {}
        })
        .subscribe((status: string) => {
          if (status === 'SUBSCRIBED') subscribed = true;
          if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT' || status === 'CLOSED') {
            subscribed = false;
            if (stopped || signal?.aborted) return;
            if (retryTimer) { try { clearTimeout(retryTimer); } catch {} retryTimer = null; }
            retryTimer = setTimeout(() => { if (!stopped && !signal?.aborted) subscribe(); }, 1000);
          }
        });
    };

    subscribe();

    signal?.addEventListener('abort', async () => {
      stopped = true;
      if (retryTimer) { try { clearTimeout(retryTimer); } catch {} retryTimer = null; }
      if (channel) {
        try { await supabase.removeChannel(channel); } catch {}
        channel = null;
        subscribed = false;
      }
    });

    return async () => {
      stopped = true;
      if (retryTimer) { try { clearTimeout(retryTimer); } catch {} retryTimer = null; }
      if (channel) {
        try { await supabase.removeChannel(channel); } catch {}
        channel = null;
        subscribed = false;
      }
    };
  };
}

