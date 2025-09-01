# StopFlowAction - CreateGo

## Overview

The `StopFlowAction` is a flow control action that allows you to programmatically terminate the execution of the current action flow. It provides a way to stop workflow execution, handle error conditions, or implement conditional flow termination based on business logic or user input.

## Purpose

- **Flow Termination**: Stop the current action flow execution
- **Error Handling**: Terminate flows when errors occur
- **Conditional Logic**: Stop flows based on specific conditions
- **User Control**: Allow users to cancel or stop workflows
- **Resource Management**: Prevent unnecessary action execution

## Action ID

```dart
StopFlowAction.id  // 'stopFlow'
```

## Parameters

### Required Parameters
None - `StopFlowAction` doesn't require any parameters to function.

### Optional Parameters
- **`reason`** (String): Reason for stopping the flow
  - Default: Empty string (no specific reason)
  - Can be used for logging and debugging
  - Useful for understanding why flow was stopped
  - Can include error details or user feedback

## Usage

### Basic Usage
```dart
// Stop flow execution
StopFlowAction()
```

### With Reason
```dart
// Stop flow with specific reason
StopFlowAction(reason: "User cancelled the operation")
```

### Dynamic Reason
```dart
// Stop flow with dynamic reason
StopFlowAction(reason: "#stopReason")
```

### Conditional Stop
```dart
// Stop flow based on condition
IfAction(
  condition: "userWantsToStop",
  then: [
    StopFlowAction(reason: "User requested to stop")
  ]
)
```

## Integration with Action Flows

### Flow Control Patterns
- **Error Termination**: Stop flow when critical errors occur
- **User Cancellation**: Allow users to stop workflows
- **Conditional Termination**: Stop based on business logic
- **Resource Protection**: Prevent excessive resource usage
- **Flow Management**: Control complex workflow execution

### Flow Control
- **Immediate Termination**: Flow stops immediately when executed
- **Clean Exit**: No further actions are executed
- **State Preservation**: Current flow state is maintained
- **Error Propagation**: Stop reason can be logged or handled

### Flow Behavior
When executed:
- The current action flow execution is immediately terminated
- No further actions in the flow are executed
- The flow returns to its caller or parent context
- The stop reason is available for logging or handling

## Common Use Cases

### 1. **Error Condition Handling**
```dart
// Stop flow when critical error occurs
TryAction(
  actions: [
    // Attempt critical operation
    CriticalOperationAction()
  ],
  then: [
    // Continue with success flow
    ContinueFlowAction()
  ],
  catch: [
    // Stop flow on critical error
    StopFlowAction(reason: "Critical operation failed: #error.message")
  ]
)
```

### 2. **User Cancellation**
```dart
// Allow user to cancel workflow
ShowPopupAction(
  title: "Workflow in Progress",
  message: "Do you want to continue?",
  actions: [
    PopupAction(label: "Continue", action: "continue"),
    PopupAction(label: "Cancel", action: "cancel")
  ]
)

IfAction(
  condition: "popupResult == 'cancel'",
  then: [
    StopFlowAction(reason: "User cancelled the workflow")
  ]
)
```

### 3. **Conditional Flow Termination**
```dart
// Stop flow based on business logic
ExpressionAction(
  code: """
    let userRole = getUserRole();
    let requiredPermission = getRequiredPermission();
    
    if (!userRole.hasPermission(requiredPermission)) {
      setVariable('shouldStop', true);
      setVariable('stopReason', 'User lacks required permission: ' + requiredPermission);
    } else {
      setVariable('shouldStop', false);
    }
  """
)

IfAction(
  condition: "shouldStop",
  then: [
    StopFlowAction(reason: "stopReason")
  ]
)
```

### 4. **Resource Protection**
```dart
// Stop flow if resource limits exceeded
ExpressionAction(
  code: """
    let currentMemory = getCurrentMemoryUsage();
    let memoryLimit = getMemoryLimit();
    
    if (currentMemory > memoryLimit) {
      setVariable('memoryExceeded', true);
      setVariable('memoryUsage', currentMemory);
    } else {
      setVariable('memoryExceeded', false);
    }
  """
)

IfAction(
  condition: "memoryExceeded",
  then: [
    StopFlowAction(
      reason: "Memory limit exceeded: #memoryUsage MB"
    )
  ]
)
```

## Best Practices

### 1. **Flow Termination Logic**
- Use clear and descriptive stop reasons
- Stop flows only when necessary
- Consider alternative flow paths when possible
- Log stop reasons for debugging and monitoring

### 2. **Error Handling**
- Stop flows on critical errors
- Provide meaningful error information
- Consider recovery mechanisms when appropriate
- Handle stop reasons appropriately

### 3. **User Experience**
- Allow users to cancel long-running workflows
- Provide clear feedback about flow termination
- Consider confirmation dialogs for important stops
- Handle user cancellation gracefully

### 4. **Resource Management**
- Stop flows that consume excessive resources
- Implement timeout mechanisms for long-running flows
- Monitor flow execution for resource issues
- Provide fallback behavior when possible

## Error Handling

### Common Scenarios
1. **Critical Errors**: Unrecoverable errors that require flow termination
2. **User Cancellation**: User requests to stop the workflow
3. **Resource Issues**: Memory, timeout, or other resource constraints
4. **Business Logic**: Conditions that require flow termination

### Best Practices
- Always provide meaningful stop reasons
- Handle stop reasons appropriately in calling code
- Log flow termination for debugging
- Consider recovery mechanisms when possible

## Performance Considerations

### Execution Speed
- **Instant Execution**: Action executes immediately
- **No Overhead**: Minimal processing required
- **Memory Usage**: No additional memory allocation
- **Clean Termination**: Efficient flow cleanup

### Optimization Tips
- Use stop actions sparingly
- Consider alternative flow control mechanisms
- Monitor flow termination frequency
- Optimize flow logic to minimize unnecessary stops

## Debugging

### Common Issues
1. **Unexpected Termination**: Flow stops when not expected
2. **Missing Stop Reasons**: No information about why flow stopped
3. **Incorrect Stop Conditions**: Flow stops on wrong conditions
4. **Resource Issues**: Flow stops due to resource constraints

### Debug Tips
- Log all flow termination events
- Verify stop conditions and logic
- Monitor resource usage during flow execution
- Test flow termination scenarios thoroughly

## Examples

### Complete Flow Control System
```dart
// Comprehensive flow control workflow
ShowPopupAction(
  title: "Flow Control",
  message: "What would you like to do?",
  actions: [
    PopupAction(label: "Continue", action: "continue"),
    PopupAction(label: "Pause", action: "pause"),
    PopupAction(label: "Stop", action: "stop"),
    PopupAction(label: "Cancel", action: "cancel")
  ]
)

SwitchAction(
  value: "popupResult",
  cases: [
    SwitchCase(
      value: "continue",
      actions: [
        // Continue normal flow execution
        ContinueFlowAction()
      ]
    ),
    SwitchCase(
      value: "pause",
      actions: [
        // Pause flow execution
        PauseFlowAction()
      ]
    ),
    SwitchCase(
      value: "stop",
      actions: [
        // Stop flow execution
        StopFlowAction(reason: "User requested to stop the flow")
      ]
    ),
    SwitchCase(
      value: "cancel",
      actions: [
        // Cancel flow execution
        StopFlowAction(reason: "User cancelled the flow")
      ]
    )
  ]
)
```

### Smart Flow Termination
```dart
// Intelligent flow termination based on context
ExpressionAction(
  code: """
    let currentContext = getCurrentContext();
    let userRole = getUserRole();
    let flowProgress = getFlowProgress();
    
    let shouldStop, stopReason;
    
    if (currentContext === 'error' && userRole !== 'admin') {
      shouldStop = true;
      stopReason = 'Non-admin user cannot proceed after error';
    } else if (flowProgress > 90 && userRole === 'user') {
      shouldStop = true;
      stopReason = 'User flow completed successfully';
    } else if (currentContext === 'timeout') {
      shouldStop = true;
      stopReason = 'Flow execution timeout exceeded';
    } else {
      shouldStop = false;
    }
    
    setVariable('shouldStop', shouldStop);
    setVariable('stopReason', stopReason);
  """
)

IfAction(
  condition: "shouldStop",
  then: [
    StopFlowAction(reason: "stopReason")
  ]
)
```

### Conditional Flow Control
```dart
// Stop flow based on user permissions and context
ExpressionAction(
  code: """
    let userRole = getUserRole();
    let currentScreen = getCurrentScreen();
    let flowPermissions = getFlowPermissions(userRole);
    
    if (currentScreen === 'admin-panel' && !flowPermissions.canExecuteAdminFlows) {
      setVariable('canExecuteFlow', false);
      setVariable('stopReason', 'User lacks permission to execute admin flows');
    } else if (currentScreen === 'user-dashboard' && !flowPermissions.canExecuteUserFlows) {
      setVariable('canExecuteFlow', false);
      setVariable('stopReason', 'User lacks permission to execute user flows');
    } else if (currentScreen === 'public-view' && !flowPermissions.canExecutePublicFlows) {
      setVariable('canExecuteFlow', false);
      setVariable('stopReason', 'User lacks permission to execute public flows');
    } else {
      setVariable('canExecuteFlow', true);
    }
  """
)

IfAction(
  condition: "!canExecuteFlow",
  then: [
    StopFlowAction(reason: "stopReason")
  ],
  else: [
    // Continue with flow execution
    ContinueFlowAction()
  ]
)
```

## Conclusion

`StopFlowAction` is a powerful tool for controlling flow execution in your CreateGo applications. It enables intelligent workflow termination while maintaining good user experience and resource management standards.

When used effectively with appropriate stop conditions, meaningful reasons, and error handling, it significantly enhances the reliability and user control of your action flows. Remember to always provide clear stop reasons, handle termination gracefully, and consider alternative flow paths when possible for a professional flow control experience.

The key to successful flow termination is balancing control with user experience, providing meaningful feedback, and ensuring flows stop only when necessary and appropriate.
