# CreateGo Action Flow JSON Structure Documentation

## Table of Contents
1. [Overview](#overview)
2. [JSON File Structure](#json-file-structure)
3. [Action Flow JSON Schema](#action-flow-json-schema)
4. [Action Types in JSON](#action-types-in-json)
5. [Real Examples Analysis](#real-examples-analysis)
6. [JSON to Action Flow Conversion](#json-to-action-flow-conversion)
7. [Common Patterns and Best Practices](#common-patterns-and-best-practices)
8. [Troubleshooting JSON Issues](#troubleshooting-json-issues)
9. [Integration with Database](#integration-with-database)

---

## Overview

The `action-flow-json.json` file contains the complete collection of action flows stored in the CreateGo system. Each entry represents a single action flow with its complete configuration, including all action steps, parameters, and execution logic.

This document explains the structure of this JSON file and how it maps to the CreateGo Action Flow system, providing developers and users with a clear understanding of how to work with and modify action flow configurations.

---

## JSON File Structure

The `action-flow-json.json` file is an array of action flow objects, where each object represents a complete action flow definition.

### Top-Level Structure

```json
[
  {
    "idx": 0,
    "id": 216,
    "name": "logintest",
    "is_flow": true,
    "body": "...",
    "project_id": 145,
    "description": "",
    "tags": [],
    "symbol_id": null,
    "folder_id": null,
    "is_folder": false
  },
  // ... more action flows
]
```

### Field Descriptions

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `idx` | `number` | Array index for ordering | `0`, `1`, `2` |
| `id` | `number` | Unique database identifier | `216`, `217`, `218` |
| `name` | `string` | Human-readable flow name | `"logintest"`, `"setLoginId"` |
| `is_flow` | `boolean` | Indicates this is an action flow | `true` |
| `body` | `string` | JSON string containing flow definition | `"{\"id\": \"\", \"label\": \"\", \"steps\": [...]}"` |
| `project_id` | `number` | Parent project identifier | `145` |
| `description` | `string` | Flow description (optional) | `""` |
| `tags` | `array` | Array of tags for categorization | `[]` |
| `symbol_id` | `number|null` | Associated symbol identifier | `null` |
| `folder_id` | `number|null` | Parent folder identifier | `null` |
| `is_folder` | `boolean` | Indicates if this is a folder | `false` |

---

## Action Flow JSON Schema

The `body` field contains a JSON string that represents the actual action flow configuration. This string must be parsed to access the flow structure.

### Parsed Body Structure

```json
{
  "id": "",
  "label": "",
  "steps": [
    // Array of action steps
  ],
  "flowId": "",
  "actionId": "",
  "description": "",
  "executionMode": "asyncMode"
}
```

### Body Field Descriptions

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `id` | `string` | Flow identifier | `""` |
| `label` | `string` | Display label | `""` |
| `steps` | `array` | Array of action steps | `[{...}, {...}]` |
| `flowId` | `string` | Flow reference ID | `""` |
| `actionId` | `string` | Action type identifier | `""` |
| `description` | `string` | Flow description | `""` |
| `executionMode` | `string` | Execution strategy | `"asyncMode"` |

---

## Action Types in JSON

The JSON contains several types of actions, each with different structures and purposes.

### 1. Basic Actions

Basic actions perform simple operations like navigation, API calls, and UI interactions.

#### Navigation Action
```json
{
  "id": "dd80fdd0-54e8-428f-a303-3256c5655485",
  "label": "moveSettings",
  "params": {
    "routePath": "/settings"
  },
  "actionId": "navigate",
  "actionType": "basic",
  "description": "",
  "executionMode": "async"
}
```

#### Show Popup Action
```json
{
  "id": "51ff08f1-898b-4ad4-889c-af23718a0060",
  "label": "loginDataShow",
  "params": {
    "title": "로그인정보",
    "message": "#loginUser.user.id"
  },
  "actionId": "showPopup",
  "actionType": "basic",
  "description": "",
  "executionMode": "async"
}
```

### 2. Expression Actions

Expression actions execute custom code and logic.

#### Simple Expression
```json
{
  "id": "d6c1e4c5-e664-48fb-8f2e-99cc7d01ee83",
  "label": "Expression",
  "params": null,
  "execute": "#loginId = payload['value']",
  "actionId": "expression",
  "actionType": "expression",
  "description": "Expression action description",
  "executionMode": "async"
}
```

#### Complex Expression
```json
{
  "id": "844c2b7c-24b9-4e06-bd29-7e7665794d98",
  "label": "Expression",
  "params": null,
  "execute": "#currentPincode = #currentPincode ?? \"\";\nprint(\"payload:\" + payload.key);\n#currentPincode = payload.key == \"B\" \r\n    ? (#currentPincode.length > 0 ? #currentPincode.substring(0, #currentPincode.length - 1) : #currentPincode)\r\n    : (#currentPincode.length < 12 ? #currentPincode + payload.key : #currentPincode);",
  "actionId": "expression",
  "actionType": "expression",
  "description": "Expression action description",
  "executionMode": "async"
}
```

### 3. Callback Actions

Callback actions handle API calls and responses with success/error handling.

#### REST API Call
```json
{
  "id": "ab13c0d0-a025-4dc8-8aca-d828036ccb3f",
  "label": "auth-login",
  "params": {
    "body": {
      "email": "#loginId",
      "password": "#loginPwd"
    },
    "path": "/auth-login",
    "method": "POST",
    "saveTo": "\"#loginUser\"",
    "authJwt": "#anonKey",
    "baseUrl": "#baseApiUrl"
  },
  "onError": [
    {
      "id": "f8c2d213-a367-4dcc-8ba3-655b87ffd07b",
      "label": "end",
      "params": null,
      "actionId": "callFlow",
      "actionType": "basic",
      "description": "",
      "executionMode": "async"
    }
  ],
  "actionId": "restApi",
  "onSuccess": [],
  "actionType": "callback",
  "description": "",
  "executionMode": "async"
}
```

### 4. Conditional Actions

Conditional actions implement decision-making logic.

#### Simple Conditional
```json
{
  "id": "1485a1b9-a962-4609-8f42-abac00af6d24",
  "label": "Conditional",
  "isTrue": [
    {
      "id": "4c9cf2e8-d8a3-4738-9e10-bda44f48518d",
      "label": "createWallet",
      "params": {
        "flowId": "275"
      },
      "actionId": "callFlow",
      "actionType": "basic",
      "description": "",
      "executionMode": "async"
    }
  ],
  "params": null,
  "execute": "#wallets.length < 1",
  "isFalse": [],
  "actionId": "conditional",
  "actionType": "conditional",
  "description": "Conditional action",
  "executionMode": "async"
}
```

### 5. Flow Call Actions

Flow call actions execute other action flows.

#### Call Flow
```json
{
  "id": "4c9cf2e8-d8a3-4738-9e10-bda44f48518d",
  "label": "createWallet",
  "params": {
    "flowId": "275"
  },
  "actionId": "callFlow",
  "actionType": "basic",
  "description": "",
  "executionMode": "async"
}
```

---

## Real Examples Analysis

Let's analyze some real examples from the JSON file to understand common patterns.

### Example 1: Login Flow (`logintest`)

**Purpose**: Display login information in a popup

**Structure**:
```json
{
  "idx": 0,
  "id": 216,
  "name": "logintest",
  "is_flow": true,
  "body": "{\"id\": \"\", \"label\": \"\", \"steps\": [{\"id\": \"51ff08f1-898b-4ad4-889c-af23718a0060\", \"label\": \"loginDataShow\", \"params\": {\"title\": \"로그인정보\", \"message\": \"#loginUser.user.id\"}, \"actionId\": \"showPopup\", \"actionType\": \"basic\", \"description\": \"\", \"executionMode\": \"async\"}], \"flowId\": \"\", \"actionId\": \"\", \"description\": \"\", \"executionMode\": \"asyncMode\"}",
  "project_id": 145
}
```

**Parsed Body**:
```json
{
  "id": "",
  "label": "",
  "steps": [
    {
      "id": "51ff08f1-898b-4ad4-889c-af23718a0060",
      "label": "loginDataShow",
      "params": {
        "title": "로그인정보",
        "message": "#loginUser.user.id"
      },
      "actionId": "showPopup",
      "actionType": "basic",
      "description": "",
      "executionMode": "async"
    }
  ],
  "flowId": "",
  "actionId": "",
  "description": "",
  "executionMode": "asyncMode"
}
```

**Analysis**:
- Single step flow that shows a popup
- Uses global symbol `#loginUser.user.id` for dynamic content
- Korean text indicates internationalization support

### Example 2: PIN Code Management (`typePincode`)

**Purpose**: Handle PIN code input with validation and UI updates

**Structure**: Complex multi-step flow with expressions and conditionals

**Key Features**:
- Multiple expression actions for PIN code logic
- Conditional actions for success/failure handling
- UI state management through expressions
- Complex string manipulation and validation

**Expression Analysis**:
```dart
// Initialize PIN code
#currentPincode = #currentPincode ?? "";

// Handle backspace (B key) or digit input
#currentPincode = payload.key == "B" 
    ? (#currentPincode.length > 0 ? #currentPincode.substring(0, #currentPincode.length - 1) : #currentPincode)
    : (#currentPincode.length < 12 ? #currentPincode + payload.key : #currentPincode);

// Update UI symbols based on PIN length
#_uiState.pincode.symbol_1 = (#currentPincode.length <= 6 ? #currentPincode.length >= 1 : #currentPincode.length >= 7) ? "#319CF3" : "#FFFFFF";
```

### Example 3: Authentication Flow (`authLogin`)

**Purpose**: Complete user authentication with wallet creation

**Structure**: Multi-step flow with API calls, expressions, and conditionals

**Flow Steps**:
1. **API Call**: Authenticate user credentials
2. **Expression**: Save user data and session
3. **Conditional**: Check if wallet exists
4. **Navigation**: Move to home page

**Key Patterns**:
- Error handling with `onError` callbacks
- Data persistence through expressions
- Conditional logic for wallet creation
- Flow chaining with `callFlow` actions

---

## JSON to Action Flow Conversion

The JSON structure needs to be converted to CreateGo Action Flow objects for execution.

### Conversion Process

#### 1. Parse Body String
```dart
// The body field is a JSON string that needs to be parsed
Map<String, dynamic> bodyJson = jsonDecode(actionFlowJson.body);
```

#### 2. Convert to ActionFlow Object
```dart
ActionFlow actionFlow = ActionFlow.fromJson(bodyJson);
```

#### 3. Process Action Steps
```dart
for (Map<String, dynamic> stepJson in bodyJson['steps']) {
  ActionStep step = ActionStep.fromJson(stepJson);
  actionFlow.steps.add(step);
}
```

### Conversion Examples

#### Basic Action Conversion
```json
// JSON Input
{
  "id": "step_123",
  "label": "Navigate Home",
  "params": {"routePath": "/home"},
  "actionId": "navigate",
  "actionType": "basic",
  "executionMode": "async"
}
```

```dart
// Converted ActionStep
ActionStep step = ActionStep.fromBasic(
  BasicAction(
    id: "step_123",
    label: "Navigate Home",
    actionType: ActionType.basicAct,
    actionId: "navigate",
    params: {"routePath": "/home"},
    executionMode: ExecutionMode.asyncMode,
  ),
);
```

#### Expression Action Conversion
```json
// JSON Input
{
  "id": "step_456",
  "label": "Calculate Total",
  "execute": "order.total = order.subtotal * (1 + taxRate)",
  "actionId": "expression",
  "actionType": "expression",
  "executionMode": "async"
}
```

```dart
// Converted ActionStep
ActionStep step = ActionStep.fromExpression(
  ExpressionAction(
    id: "step_456",
    label: "Calculate Total",
    actionType: ActionType.expressionAct,
    actionId: "expression",
    expressionExecute: "order.total = order.subtotal * (1 + taxRate)",
    executionMode: ExecutionMode.asyncMode,
  ),
);
```

---

## Common Patterns and Best Practices

### 1. Naming Conventions

#### Flow Names
- Use descriptive, action-oriented names
- Follow camelCase or snake_case consistently
- Include the main purpose in the name

**Examples**:
- `logintest` → `testLoginFlow`
- `setLoginId` → `setUserLoginId`
- `authLogin` → `authenticateUser`
- `moveSettings` → `navigateToSettings`

#### Action Labels
- Use clear, descriptive labels
- Include the expected outcome
- Keep labels concise but informative

**Examples**:
- `"loginDataShow"` → `"Display Login Info"`
- `"moveSettings"` → `"Navigate to Settings"`
- `"saveUserData"` → `"Save User Information"`

### 2. Parameter Organization

#### Structured Parameters
```json
// ✅ Well-organized parameters
"params": {
  "api": {
    "baseUrl": "#baseApiUrl",
    "path": "/auth-login",
    "method": "POST"
  },
  "data": {
    "email": "#loginId",
    "password": "#loginPwd"
  },
  "options": {
    "timeout": 30000,
    "retries": 3
  }
}

// ❌ Flat, unorganized parameters
"params": {
  "baseUrl": "#baseApiUrl",
  "path": "/auth-login",
  "method": "POST",
  "email": "#loginId",
  "password": "#loginPwd",
  "timeout": 30000,
  "retries": 3
}
```

#### Global Symbol Usage
```json
// ✅ Consistent global symbol usage
"params": {
  "message": "#loginUser.user.id",
  "authJwt": "#anonKey",
  "baseUrl": "#baseApiUrl"
}

// ❌ Inconsistent symbol usage
"params": {
  "message": "#loginUser.user.id",
  "authJwt": "anonKey",
  "baseUrl": "baseApiUrl"
}
```

### 3. Error Handling Patterns

#### Comprehensive Error Handling
```json
{
  "onError": [
    {
      "id": "error_handler_1",
      "label": "Log Error",
      "actionId": "expression",
      "actionType": "expression",
      "execute": "console.error('API Error:', #_currentResult.error)"
    },
    {
      "id": "error_handler_2",
      "label": "Show Error Popup",
      "actionId": "showPopup",
      "actionType": "basic",
      "params": {
        "title": "Error",
        "message": "#_currentResult.error.message"
      }
    }
  ]
}
```

### 4. Flow Organization

#### Logical Step Ordering
```json
{
  "steps": [
    // 1. Validation
    {"label": "Validate Input", "actionType": "expression"},
    
    // 2. Data Processing
    {"label": "Process Data", "actionType": "expression"},
    
    // 3. API Call
    {"label": "API Request", "actionType": "callback"},
    
    // 4. Response Handling
    {"label": "Handle Response", "actionType": "expression"},
    
    // 5. Navigation
    {"label": "Navigate", "actionType": "basic"}
  ]
}
```

---

## Troubleshooting JSON Issues

### Common Problems and Solutions

#### 1. Invalid JSON Structure

**Problem**: Malformed JSON in body field
```json
// ❌ Invalid JSON
"body": "{\"id\": \"\", \"steps\": [{\"id\": \"123\", \"label\": \"Step\", ...}"

// ✅ Valid JSON
"body": "{\"id\": \"\", \"steps\": [{\"id\": \"123\", \"label\": \"Step\"}]}"
```

**Solution**: Validate JSON structure before saving
```dart
try {
  Map<String, dynamic> parsed = jsonDecode(jsonString);
  // JSON is valid
} catch (e) {
  // Handle JSON parsing error
  print('Invalid JSON: $e');
}
```

#### 2. Missing Required Fields

**Problem**: Action step missing required fields
```json
// ❌ Missing required fields
{
  "label": "Step",
  "actionType": "basic"
  // Missing: id, actionId, executionMode
}

// ✅ Complete action step
{
  "id": "step_123",
  "label": "Step",
  "actionId": "navigate",
  "actionType": "basic",
  "executionMode": "async"
}
```

**Solution**: Validate required fields before conversion
```dart
bool isValidActionStep(Map<String, dynamic> step) {
  List<String> required = ['id', 'label', 'actionId', 'actionType', 'executionMode'];
  return required.every((field) => step.containsKey(field));
}
```

#### 3. Type Mismatches

**Problem**: Incorrect data types for fields
```json
// ❌ Wrong types
{
  "id": 123,           // Should be string
  "params": "string",  // Should be object
  "executionMode": 1   // Should be string
}

// ✅ Correct types
{
  "id": "123",
  "params": {},
  "executionMode": "async"
}
```

**Solution**: Type validation during conversion
```dart
String validateId(dynamic value) {
  if (value is String) return value;
  if (value is int) return value.toString();
  throw ArgumentError('Invalid ID type: ${value.runtimeType}');
}
```

#### 4. Circular References

**Problem**: Flows calling themselves or creating circular dependencies
```json
// ❌ Circular reference
{
  "id": "flow_1",
  "steps": [
    {
      "actionId": "callFlow",
      "params": {"flowId": "flow_1"}  // Calls itself
    }
  ]
}
```

**Solution**: Detect and prevent circular references
```dart
Set<String> detectCircularReferences(String flowId, Map<String, dynamic> flows) {
  Set<String> visited = {};
  Set<String> recursionStack = {};
  
  bool hasCycle(String currentFlowId) {
    if (recursionStack.contains(currentFlowId)) return true;
    if (visited.contains(currentFlowId)) return false;
    
    visited.add(currentFlowId);
    recursionStack.add(currentFlowId);
    
    // Check for callFlow actions
    // ... implementation
    
    recursionStack.remove(currentFlowId);
    return false;
  }
  
  hasCycle(flowId);
  return recursionStack;
}
```

---

## Integration with Database

### Database Schema Mapping

The JSON structure maps to database tables as follows:

#### Action Flow Table
```sql
CREATE TABLE action_flows (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  is_flow BOOLEAN DEFAULT true,
  body TEXT NOT NULL,
  project_id INTEGER NOT NULL,
  description TEXT,
  tags JSON,
  symbol_id INTEGER,
  folder_id INTEGER,
  is_folder BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Field Mappings
| JSON Field | Database Column | Type | Notes |
|------------|-----------------|------|-------|
| `id` | `id` | `INTEGER` | Primary key |
| `name` | `name` | `VARCHAR(255)` | Flow name |
| `is_flow` | `is_flow` | `BOOLEAN` | Flow indicator |
| `body` | `body` | `TEXT` | JSON string |
| `project_id` | `project_id` | `INTEGER` | Foreign key |
| `description` | `description` | `TEXT` | Optional |
| `tags` | `tags` | `JSON` | Array of strings |
| `symbol_id` | `symbol_id` | `INTEGER` | Optional |
| `folder_id` | `folder_id` | `INTEGER` | Optional |
| `is_folder` | `is_folder` | `BOOLEAN` | Folder indicator |

### Data Persistence

#### Saving Action Flow
```dart
Future<void> saveActionFlow(Map<String, dynamic> actionFlowJson) async {
  // Convert to database format
  Map<String, dynamic> dbRecord = {
    'name': actionFlowJson['name'],
    'is_flow': actionFlowJson['is_flow'],
    'body': actionFlowJson['body'],
    'project_id': actionFlowJson['project_id'],
    'description': actionFlowJson['description'] ?? '',
    'tags': jsonEncode(actionFlowJson['tags'] ?? []),
    'symbol_id': actionFlowJson['symbol_id'],
    'folder_id': actionFlowJson['folder_id'],
    'is_folder': actionFlowJson['is_folder'] ?? false,
  };
  
  // Insert or update in database
  await database.insert('action_flows', dbRecord);
}
```

#### Loading Action Flow
```dart
Future<Map<String, dynamic>?> loadActionFlow(int id) async {
  List<Map<String, dynamic>> results = await database.query(
    'action_flows',
    where: 'id = ?',
    whereArgs: [id],
  );
  
  if (results.isEmpty) return null;
  
  Map<String, dynamic> record = results.first;
  
  // Parse body JSON
  Map<String, dynamic> body = jsonDecode(record['body']);
  
  return {
    'id': record['id'],
    'name': record['name'],
    'is_flow': record['is_flow'] == 1,
    'body': body,
    'project_id': record['project_id'],
    'description': record['description'],
    'tags': jsonDecode(record['tags'] ?? '[]'),
    'symbol_id': record['symbol_id'],
    'folder_id': record['folder_id'],
    'is_folder': record['is_folder'] == 1,
  };
}
```

---

## Conclusion

The `action-flow-json.json` file serves as the central repository for all action flow definitions in the CreateGo system. Understanding its structure is essential for:

1. **Development**: Creating and modifying action flows programmatically
2. **Debugging**: Identifying issues in flow configurations
3. **Migration**: Moving flows between environments
4. **Integration**: Connecting with external systems
5. **Maintenance**: Updating and optimizing existing flows

### Key Takeaways

- **Structure**: Each entry represents a complete action flow with metadata and body
- **Body Field**: Contains the actual flow definition as a JSON string
- **Action Types**: Support for basic, expression, callback, conditional, and flow call actions
- **Global Symbols**: Use of `#` prefixed variables for cross-flow data sharing
- **Error Handling**: Comprehensive error handling through callback actions
- **Database Integration**: Direct mapping to database schema for persistence

### Best Practices

1. **Validate JSON**: Always validate JSON structure before saving
2. **Use Descriptive Names**: Choose clear, meaningful names for flows and actions
3. **Organize Parameters**: Group related parameters logically
4. **Handle Errors**: Implement comprehensive error handling
5. **Document Flows**: Add descriptions and tags for better organization
6. **Test Thoroughly**: Validate flows before deployment

By following these guidelines and understanding the JSON structure, developers can effectively work with the CreateGo Action Flow system and create robust, maintainable workflows.
