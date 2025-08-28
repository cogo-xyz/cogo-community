# COGO Agent – Designer Chatting Guide (End-User)

This guide helps designers (end users) use the COGO-Agent Chatting to move from screen design to dynamic behavior with minimal friction.

## 1. What You’ll Do via Chat

- Identify events and `#symbols` on your screen
- Map `#symbols` to variables (appData/uiState)
- Write/Refine BDD per event (Given-When-Then)
- Generate ActionFlow JSON from confirmed BDD
- (Optionally) Ask the Agent to run quick validations or produce samples

## 2. Core Prompts (Copy/Paste)

1) Propose events and symbols
```
Scan this screen and propose interactive events and #symbols. Use concise, meaningful names.
```

2) Map symbols to variables
```
Map the proposed #symbols to variables for <PageName>. Use #_appData.<page>.* and #_uiState.<page>.*.
```

3) Draft BDD for an event
```
Write BDD for #onLoginClicked using #userName and #password. Include success and error branches.
```

4) Refine the BDD
```
Refine the BDD to add validation for empty fields and set #errorMessage accordingly.
```

5) Generate ActionFlow
```
Compile the confirmed BDD into ActionFlow JSON. Mark undecided steps with actionType: "none".
```

## 3. Example Outputs

- Mapping
```
"#userName" → "#_appData.loginPage.userName"
"#isLoading" → "#_uiState.loginPage.isLoading"
```

- BDD (excerpt)
```
Given #userName and #password are provided
When #onLoginClicked occurs
Then call #restAPI:Login and set #errorMessage or navigate Home
```

- ActionFlow (excerpt)
```json
{
  "id": "loginProcessFlow",
  "actionType": "flow",
  "steps": [
    { "actionType": "basic", "actionId": "setProperty", "params": { "target": "#isLoading", "value": true }},
    { "actionType": "callback", "actionId": "restApi", "params": { "baseUrl": "#_appData.api.base", "path": "/login", "method": "POST", "body": { "u": "#userName", "p": "#password" }, "saveTo": "#_appData.session.auth" }},
    { "actionType": "basic", "actionId": "setProperty", "params": { "target": "#isLoading", "value": false }}
  ]
}
```

## 4. Tips

- Keep names short and clear; prefer `loginPage.userName` over ambiguous names.
- Confirm every symbol→variable mapping before generating BDD.
- For multi-page flows, specify the page context in your prompts.
- Ask the Agent to highlight undecided or risky steps.

## 5. Where Execution Happens

- The chat produces artifacts (mapping, BDD, ActionFlow). Heavy execution and long validations run on the Agent side, not in Chatting or Edge.

## 6. References

- Scenarios: `docs/manuals/COGO_User_Scenarios.md`
- Developer manual: `docs/manuals/Developer_Manual.md`
