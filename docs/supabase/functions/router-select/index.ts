// Supabase Edge Function: router-select
// Input: { service, intended_model?, context_tokens?, sla_ms?, cost_sensitivity?, domain_tags?, region?, tenant_id? }
// Output: { provider, model, region, base_url, headers_template }

import { serve } from 'https://deno.land/std@0.192.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!)
  const json = (status: number, body: unknown) => new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } })

  try {
    const body = await req.json().catch(() => ({})) as any
    const service = body.service
    if (!service || (service !== 'chat' && service !== 'embeddings')) return json(400, { error: 'service chat|embeddings required' })
    const intendedModel = body.intended_model as string | undefined
    const regionPref = body.region as string | undefined

    // Load enabled models for service
    const { data: models, error: mErr } = await supabase.from('llm_models').select('provider, model, service, context_limit, default_region, enabled, metadata').eq('enabled', true).eq('service', service)
    if (mErr) return json(500, { error: mErr.message })
    if (!models || models.length === 0) return json(404, { error: 'no_models' })

    // Prefer intended model if present and enabled
    let candidates = models
    if (intendedModel) candidates = candidates.filter((m: any) => m.model === intendedModel)

    // Basic health lookup (optional)
    let healthMap = new Map<string, { latency_ms?: number; error_rate?: number }>()
    const { data: health } = await supabase.from('provider_health').select('provider, region, latency_ms, error_rate')
    if (Array.isArray(health)) {
      for (const h of health) healthMap.set(`${h.provider}:${h.region || 'default'}`, { latency_ms: h.latency_ms, error_rate: Number(h.error_rate) })
    }

    // Score: lower latency and error rate preferred; simple tie-breaker by context limit
    const scored = candidates.map((m: any) => {
      const region = regionPref || m.default_region || 'default'
      const key = `${m.provider}:${region}`
      const hm = healthMap.get(key) || {}
      const latency = hm.latency_ms ?? 200
      const errorRate = hm.error_rate ?? 0.01
      const context = m.context_limit ?? 200000
      const score = latency * (1 + errorRate) - Math.min(context, 400000) / 1000
      return { ...m, region, score }
    }).sort((a: any, b: any) => a.score - b.score)

    const top = scored[0]
    if (!top) return json(404, { error: 'no_candidate' })

    // Provider base_url/headers
    const { data: prov, error: pErr } = await supabase.from('llm_providers').select('provider, base_url, headers_template').eq('provider', top.provider).maybeSingle()
    if (pErr) return json(500, { error: pErr.message })

    return json(200, {
      provider: top.provider,
      model: top.model,
      region: top.region,
      base_url: prov?.base_url || null,
      headers_template: prov?.headers_template || {}
    })
  } catch (e) {
    return json(500, { error: (e as Error).message })
  }
})


