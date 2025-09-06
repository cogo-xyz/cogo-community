Subject: COGO Agent Backend - Traces Not Processing

Issue: Chat gateway creates traces but they remain in "pending" status indefinitely.

Symptoms:
- HTTP /chat-gateway returns 200 with trace_id
- Trace status stays "pending" for 60+ seconds
- No events generated during processing
- Backend returns "Echo: [input]" instead of AI responses

Expected Behavior:
- Traces should transition from "pending" to "ready" within seconds
- COGO agent should process the request and return AI-generated responses
- Events should be generated during processing

Root Cause Suspected:
- COGO agent service not running or not processing traces
- Message queue/worker not functioning
- Database state management issues

Trace ID for investigation: 33b86f57-6586-42e5-bac7-f56a9b29ffc0


## 📊 **Client-Side Logs**
```
🚀 COGO: Sending message to chat-gateway
📤 COGO: Request body: {"projectId":"65d9ce90-3f76-4fa0-a51d-5f0cd502cb4a","text":"Build a login form"}
📥 COGO: Response status: 200
📥 COGO: Response data: {ok: true, output: {text: Echo: Build a login form}, trace_id: 33b86f57-6586-42e5-bac7-f56a9b29ffc0}
✅ COGO: Trace started successfully: 33b86f57-6586-42e5-bac7-f56a9b29ffc0
🔄 COGO: Processing trace response for: 33b86f57-6586-42e5-bac7-f56a9b29ffc0
⏳ COGO: Waiting for trace: 33b86f57-6586-42e5-bac7-f56a9b29ffc0 (60s timeout)
🔄 COGO: Attempt 3 - Status: pending (5s)
🔄 COGO: Attempt 6 - Status: pending (14s)
🔄 COGO: Attempt 9 - Status: pending (24s)
🔄 COGO: Attempt 12 - Status: pending (37s)
🔄 COGO: Attempt 15 - Status: pending (53s)
⏰ COGO: Timeout after 65s (status: pending)
⏰ COGO: Trace timeout - trying fallback approach
🔍 COGO: Final trace status: pending
🔍 COGO: Events: 0
🔍 COGO: Next actions: 0
🔍 COGO: Output: {}
🔍 COGO: Full response: {"ok":true,"trace_id":"33b86f57-6586-42e5-bac7-f56a9b29ffc0","status":"pending","events":[]}
```