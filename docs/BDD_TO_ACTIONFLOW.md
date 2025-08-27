# BDD to ActionFlow – Design (COGO)

This document summarizes the hybrid compiler: rule-based parsing for Gherkin-like blocks and an optional LLM semantic interpretation via Supabase Edge chat (or chat-gateway).

## Pipeline
1) Parse BDD → {given, when, then, otherwise, but}
2) LLM semantic (optional): condition and messages
3) Generate ActionFlow (if/else, guards)
4) Validate with JSON Schema (AJV)
5) Compile & Run through `actionflow-compat` + SSE

## Security
- Dev: JWT/HMAC checks off per repo rules
- Prod: chat-gateway with short-lived JWT, rate limiting, HMAC

## Types & Schema
- `src/types/actionflow.ts`
- `src/schemas/actionflow.schema.json`

## Tests / Gates
- `smoke:bdd:e2e` – single scenario
- `gate:bdd:bundle` – 10 scenarios


