# CallFlowAction

## Overview

The `CallFlowAction` allows you to execute other action flows or individual actions from within the current flow, enabling modular and reusable workflow design. This action is essential for creating complex, hierarchical workflows by breaking them down into smaller, manageable pieces.

## Purpose

- **Flow Reusability**: Execute predefined action flows multiple times
- **Action Execution**: Execute individual actions by their ID
- **Modular Design**: Break complex workflows into smaller, focused flows
- **Code Organization**: Maintain clean, organized action flow structures
- **Dynamic Execution**: Call different flows based on runtime conditions

## Action ID

```dart
CallFlowAction.id  // 'callFlow'
```

## Parameters

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `flowId` | `String` | ❌ | ID of the action flow to execute | `"275"` |
| `actionId` | `String` | ❌ | ID of the individual action to execute | `"showPopup"` |
| `params` | `Map<String, dynamic>` | ❌ | Parameters to pass to the called flow/action | `{"key": "value"}` |

**Note**: Either `flowId` or `actionId` must be provided for the action to work.

## Basic Usage

### Execute Another Flow
```dart
BasicAction(
  id: "call_wallet_creation",
  label: "Create Wallet",
  actionId: CallFlowAction.id,
  actionType: ActionType.basicAct,
  params: {
    "flowId": "275"
  },
  executionMode: ExecutionMode.asyncMode,
)
```

### Execute Individual Action
```dart
BasicAction(
  id: "call_popup_action",
  label: "Show Popup",
  actionId: CallFlowAction.id,
  actionType: ActionType.basicAct,
  params: {
    "actionId": "showPopup",
    "params": {
      "message": "Hello World",
      "title": "Greeting"
    }
  },
  executionMode: ExecutionMode.asyncMode,
)
```

### With Dynamic Flow Selection
```dart
BasicAction(
  id: "call_dynamic_flow",
  label: "Execute Dynamic Flow",
  actionId: CallFlowAction.id,
  actionType: ActionType.basicAct,
  params: {
    "flowId": "#selectedFlowId"  // Use global symbol
  },
  executionMode: ExecutionMode.asyncMode,
)
```

## Integration with Action Flow System

### Flow Selection Dialog
When adding a CallFlowAction, the system presents a dialog allowing users to:
- **Browse existing flows**: See all available action flows
- **Search flows**: Find specific flows by name or description
- **Create new flows**: Generate new flows on-demand
- **Select target flow**: Choose which flow to execute

### Flow Execution Context
- **Parameter passing**: The called flow receives the current execution context
- **Result handling**: Results from the called flow are available in the parent flow
- **Error propagation**: Errors in called flows can be handled by the parent
- **State sharing**: Global symbols and context are shared between flows

## Use Cases

### 1. **Wallet Creation Flow**
```dart
// Main authentication flow calls wallet creation
BasicAction(
  id: "create_user_wallet",
  label: "Create User Wallet",
  actionId: CallFlowAction.id,
  params: {
    "flowId": "275"  // Wallet creation flow ID
  }
)
```

### 2. **Modular API Handling**
```dart
// Different API flows for different endpoints
BasicAction(
  id: "handle_user_api",
  label: "Handle User API",
  actionId: CallFlowAction.id,
  params: {
    "flowId": "#userApiFlowId"  // Dynamic flow selection
  }
)
```

### 3. **Individual Action Execution**
```dart
// Execute a specific action with parameters
BasicAction(
  id: "show_custom_popup",
  label: "Show Custom Popup",
  actionId: CallFlowAction.id,
  params: {
    "actionId": "showPopup",
    "params": {
      "message": "Custom message",
      "title": "Custom title"
    }
  }
)
```

### 4. **Conditional Flow Execution**
```dart
// Call different flows based on user role
ConditionalAction(
  execute: "user.role == 'admin'",
  isTrue: [
    BasicAction(
      actionId: CallFlowAction.id,
      params: {"flowId": "admin_flow_123"}
    )
  ],
  isFalse: [
    BasicAction(
      actionId: CallFlowAction.id,
      params: {"flowId": "user_flow_456"}
    )
  ]
)
```

## Flow Dependencies

### Circular Reference Prevention
The system automatically prevents circular references:
- **Self-calling flows**: A flow cannot call itself directly
- **Circular chains**: A → B → C → A patterns are detected and blocked
- **Maximum depth**: Limits the nesting level of flow calls

### Flow Validation
Before execution, the system validates:
- **Flow existence**: Target flow must exist in the system
- **Flow accessibility**: User must have permission to execute the flow
- **Flow integrity**: Target flow must be properly configured
- **Parameter compatibility**: Parameter types and requirements

## Error Handling

### Common Error Scenarios
1. **Flow not found**: Target flow ID doesn't exist
2. **Permission denied**: User lacks access to target flow
3. **Execution failure**: Target flow encounters runtime errors
4. **Parameter mismatch**: Required parameters are missing or invalid

### Error Recovery
```dart
// Handle flow execution errors
BasicAction(
  id: "call_flow_with_fallback",
  actionId: CallFlowAction.id,
  params: {"flowId": "primary_flow"},
  onError: [
    BasicAction(
      actionId: CallFlowAction.id,
      params: {"flowId": "fallback_flow"}
    )
  ]
)
```

## Performance Considerations

### Execution Modes
- **Async execution**: Non-blocking flow calls for better performance
- **Parallel execution**: Multiple flows can run simultaneously when possible
- **Resource management**: Efficient memory and CPU usage during flow execution

### Optimization Tips
1. **Keep flows focused**: Each flow should have a single, clear purpose
2. **Minimize dependencies**: Reduce the number of flows called from a single flow
3. **Parameter efficiency**: Pass only necessary data between flows
4. **Caching**: Reuse flow results when possible

## Best Practices

### 1. **Flow Naming Convention**
```dart
// Use descriptive names for flows
"create_user_wallet"
"process_payment"
"send_notification"
"validate_user_input"
```

### 2. **Parameter Documentation**
```dart
// Document expected parameters clearly
BasicAction(
  label: "Process Order",
  actionId: CallFlowAction.id,
  params: {
    "flowId": "order_processing",
    // Expected context: order, user, paymentMethod
  }
)
```

### 3. **Error Handling Strategy**
```dart
// Always provide fallback flows
BasicAction(
  actionId: CallFlowAction.id,
  params: {"flowId": "main_flow"},
  onError: [
    BasicAction(
      actionId: CallFlowAction.id,
      params: {"flowId": "error_recovery"}
    )
  ]
)
```

### 4. **Flow Granularity**
- **Too small**: Avoid creating flows with just 1-2 actions
- **Too large**: Break flows with 20+ actions into smaller pieces
- **Optimal size**: 5-15 actions per flow for maintainability

## Examples in Real Applications

### E-commerce Order Processing
```dart
// Main order flow
ActionFlow(
  steps: [
    // Validate order
    BasicAction(actionId: CallFlowAction.id, params: {"flowId": "validate_order"}),
    
    // Process payment
    BasicAction(actionId: CallFlowAction.id, params: {"flowId": "process_payment"}),
    
    // Send confirmation
    BasicAction(actionId: CallFlowAction.id, params: {"flowId": "send_confirmation"}),
    
    // Update inventory
    BasicAction(actionId: CallFlowAction.id, params: {"flowId": "update_inventory"})
  ]
)
```

### User Authentication System
```dart
// Authentication flow with role-based routing
ActionFlow(
  steps: [
    // Authenticate user
    BasicAction(actionId: CallFlowAction.id, params: {"flowId": "authenticate_user"}),
    
    // Route based on role
    ConditionalAction(
      execute: "user.role == 'admin'",
      isTrue: [
        BasicAction(actionId: CallFlowAction.id, params: {"flowId": "admin_dashboard"})
      ],
      isFalse: [
        BasicAction(actionId: CallFlowAction.id, params: {"flowId": "user_dashboard"})
      ]
    )
  ]
)
```

## Troubleshooting

### Common Issues

#### 1. **Flow Not Found Error**
**Problem**: Target flow ID doesn't exist
**Solution**: Verify the flow ID exists and is accessible

#### 2. **Parameter Missing Error**
**Problem**: Required parameters not passed to called flow
**Solution**: Ensure all required parameters are available in context

#### 3. **Circular Reference Error**
**Problem**: Flow calls create infinite loops
**Solution**: Review flow dependencies and remove circular references

#### 4. **Permission Denied Error**
**Problem**: User lacks access to target flow
**Solution**: Check user permissions and flow accessibility settings

### Debugging Tips
1. **Check flow ID**: Verify the target flow exists
2. **Review parameters**: Ensure all required data is available
3. **Test independently**: Run the target flow separately to verify it works
4. **Check permissions**: Verify user access to the target flow
5. **Review logs**: Check execution logs for detailed error information

## Related Actions

- **StopFlowAction**: Stop current flow execution
- **ConditionalAction**: Make decisions about which flows to call
- **LoopAction**: Call flows multiple times
- **SwitchAction**: Choose between multiple flow options

## Summary

The `CallFlowAction` is a powerful tool for creating modular, reusable workflows in CreateGo. By breaking complex processes into smaller, focused flows, developers can create maintainable and scalable automation systems. Proper use of this action enables:

- **Code reusability** across multiple workflows
- **Maintainability** through focused, single-purpose flows
- **Scalability** by composing complex processes from simple building blocks
- **Debugging** through isolated, testable flow components

When designing workflows, consider how `CallFlowAction` can help organize your automation logic into logical, reusable components.
