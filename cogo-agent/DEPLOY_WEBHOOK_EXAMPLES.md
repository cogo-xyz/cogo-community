## Deploy Webhook Examples

Use `scripts/edge/deploy_all.sh --report=out.json --webhook=<url>` to send a JSON report to a webhook after deployment.

### Payload schema
```json
{
  "env": "dev|stg|prd|",
  "ref": "<supabase_project_ref>",
  "dry": 0,
  "missing": ["..."],
  "succeeded": ["json-get","json-list"],
  "failed": []
}
```

### Sample report
```json
{
  "env": "dev",
  "ref": "abcdefghijklmno",
  "dry": 0,
  "missing": [],
  "succeeded": ["json-set","json-merge","json-remove","json-get","json-list","json-generate","json-validate","chat","chat-gateway","trace-status","kg-upsert-schedule","artifacts-list"],
  "failed": []
}
```

### Generic webhook (e.g., httpbin)
```bash
bash scripts/edge/deploy_all.sh deploy --env=dev --report=/tmp/deploy.json --webhook="https://httpbin.org/post"
```

### Slack incoming webhook
Transform report to Slack blocks and POST to Slack webhook URL via a small wrapper service, or post directly with a minimal text payload:
```bash
WEBHOOK_URL="https://hooks.slack.com/services/T000/B000/XXXX"
jq -nc --arg text "COGO Edge deploy done: $(date -Is)" '{text:$text}' \
| curl -sS -H "Content-Type: application/json" --data-binary @- "$WEBHOOK_URL"
```

For rich formatting, create a lightweight relay that maps the report JSON to Slack blocks and use `scripts/edge/notify_webhook.sh` to send the original report to the relay.

## Deploy Webhook Examples

### Slack incoming webhook

```bash
WEBHOOK="https://hooks.slack.com/services/T000/B000/XXXX"
# Send JSON file produced by deploy_all.sh --report
curl -sS -X POST -H "Content-Type: application/json" \
  --data-binary @docs/quality/deploy-report.json "$WEBHOOK"
```

### Generic webhook (self-hosted)

```bash
WEBHOOK="https://example.com/deploy/report"
curl -sS -X POST -H "Content-Type: application/json" \
  --data-binary @docs/quality/deploy-report.json "$WEBHOOK"
```

### Using deploy_all.sh directly

```bash
PARALLEL=1 bash scripts/edge/deploy_all.sh deploy \
  --env=stg \
  --only=json-get,json-list,artifacts-list \
  --report=docs/quality/deploy-report.json \
  --webhook="$WEBHOOK"
```
