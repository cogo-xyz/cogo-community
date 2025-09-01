-- Seed providers/models/health for router-select smoke

-- Providers
insert into public.llm_providers (provider, base_url, headers_template, pricing, enabled)
values
  ('anthropic', 'https://api.anthropic.com', '{"x-api-key":"{{API_KEY}}"}'::jsonb, '{}', true),
  ('openai', 'https://api.openai.com/v1', '{"authorization":"Bearer {{API_KEY}}"}'::jsonb, '{}', true)
on conflict (provider) do update set base_url=excluded.base_url, headers_template=excluded.headers_template, enabled=excluded.enabled;

-- Models
insert into public.llm_models (provider, model, service, context_limit, default_region, cost_per_1k, enabled)
values
  ('anthropic', 'anthropic/claude-3.5-sonnet', 'chat', 200000, 'default', 0.0, true),
  ('anthropic', 'anthropic/claude-3.5-haiku', 'chat', 200000, 'default', 0.0, true),
  ('openai', 'openai/gpt-4o', 'chat', 128000, 'default', 0.0, true),
  ('openai', 'openai/text-embedding-3-large', 'embeddings', 8192, 'default', 0.0, true)
on conflict (provider, model) do update set service=excluded.service, enabled=excluded.enabled;

-- Health (reset and seed simple latencies)
delete from public.provider_health where provider in ('anthropic','openai');
insert into public.provider_health (provider, region, latency_ms, error_rate)
values
  ('anthropic','default',180,0.01),
  ('openai','default',220,0.01);


