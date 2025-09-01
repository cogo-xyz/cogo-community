# ShowErrorPopupAction - CreateGo

## Overview

The `ShowErrorPopupAction` is a specialized UI feedback action that displays error-specific popup dialogs to users. It provides a way to show error messages, validation failures, and system errors through user-friendly popup dialogs that can be configured with various options and button configurations.

## Purpose

- **Error Communication**: Display error messages and validation failures
- **User Feedback**: Provide clear feedback about what went wrong
- **Error Handling**: Integrate with error handling workflows
- **User Experience**: Guide users through error resolution
- **Debugging Support**: Show error details for troubleshooting

## Action ID

```dart
ShowErrorPopupAction.id  // 'showErrorPopup'
```

## Parameters

### Required Parameters
- **`message`** (String): The error message to display
  - This is the primary error information shown to the user
  - Should be clear and actionable
  - Can include error details and resolution steps
  - Required for the action to function

### Optional Parameters
- **`title`** (String): The header text displayed at the top of the popup
  - Default: "Error" (standard error title)
  - Provides context for the error popup
  - Should be brief and descriptive
  - Can be customized for different error types

- **`buttonText`** (String): Text for the action button
  - Default: "OK" (standard confirmation button)
  - Creates a button that closes the popup
  - Should indicate the action the user should take
  - Useful for providing clear next steps

## Usage

### Basic Usage
```dart
// Show error popup with default settings
ShowErrorPopupAction(
  message: "An error occurred while processing your request."
)
```

### With Custom Title
```dart
// Show error popup with custom title
ShowErrorPopupAction(
  title: "Validation Error",
  message: "Please check your input and try again."
)
```

### With Custom Button
```dart
// Show error popup with custom button text
ShowErrorPopupAction(
  title: "Connection Failed",
  message: "Unable to connect to the server. Please check your internet connection.",
  buttonText: "Retry"
)
```

### Dynamic Error Message
```dart
// Show error popup with dynamic message
ShowErrorPopupAction(
  title: "API Error",
  message: "#errorMessage"
)
```

## Integration with Action Flows

### Error Handling Patterns
- **Validation Errors**: Show form validation failures
- **System Errors**: Display system or network errors
- **Permission Errors**: Show access denied messages
- **Resource Errors**: Display resource unavailable messages
- **User Input Errors**: Show user input validation failures

### Flow Control
- **Error Display**: Present error information clearly to users
- **User Guidance**: Provide actionable error messages
- **Error Recovery**: Guide users through error resolution
- **Flow Continuation**: Allow users to proceed after error acknowledgment

### Error Popup Behavior
When executed:
- The error popup is displayed with the specified message
- User must acknowledge the error by clicking the button
- Popup closes after user interaction
- Flow continues to the next action

## Common Use Cases

### 1. **Form Validation Errors**
```dart
// Show validation errors to user
TryAction(
  actions: [
    // Validate form data
    ValidateFormAction(formData: userFormData)
  ],
  then: [
    // Continue with form submission
    SubmitFormAction(formData: userFormData)
  ],
  catch: [
    // Show validation errors
    ShowErrorPopupAction(
      title: "Validation Error",
      message: "Please fix the following errors:\n\n#validationErrors",
      buttonText: "Fix Errors"
    )
  ]
)
```

### 2. **API Call Failures**
```dart
// Show API error messages
TryAction(
  actions: [
    // Make API call
    RestfulDataAction(
      method: "POST",
      baseUrl: "/api/submit",
      body: formData
    )
  ],
  then: [
    // Handle success
    ShowPopupAction(
      title: "Success",
      message: "Data submitted successfully!"
    )
  ],
  catch: [
    // Show API error
    ShowErrorPopupAction(
      title: "Submission Failed",
      message: "Unable to submit data: #error.message\n\nPlease try again later.",
      buttonText: "Retry"
    )
  ]
)
```

### 3. **Permission Denied Errors**
```dart
// Show permission error messages
ExpressionAction(
  code: """
    let userRole = getUserRole();
    let requiredPermission = getRequiredPermission();
    
    if (!userRole.hasPermission(requiredPermission)) {
      setVariable('permissionError', true);
      setVariable('errorMessage', 'You need ' + requiredPermission + ' permission to perform this action.');
    } else {
      setVariable('permissionError', false);
    }
  """
)

IfAction(
  condition: "permissionError",
  then: [
    ShowErrorPopupAction(
      title: "Access Denied",
      message: "errorMessage",
      buttonText: "Contact Admin"
    )
  ]
)
```

### 4. **System Resource Errors**
```dart
// Show system resource errors
ExpressionAction(
  code: """
    let availableMemory = getAvailableMemory();
    let requiredMemory = getRequiredMemory();
    
    if (availableMemory < requiredMemory) {
      setVariable('memoryError', true);
      setVariable('memoryMessage', 'Insufficient memory. Available: ' + availableMemory + 'MB, Required: ' + requiredMemory + 'MB');
    } else {
      setVariable('memoryError', false);
    }
  """
)

IfAction(
  condition: "memoryError",
  then: [
    ShowErrorPopupAction(
      title: "System Error",
      message: "memoryMessage",
      buttonText: "Close Applications"
    )
  ]
)
```

## Best Practices

### 1. **Error Message Content**
- Keep error messages clear and actionable
- Use appropriate titles for different error types
- Provide specific information about what went wrong
- Include resolution steps when possible

### 2. **User Experience**
- Make error messages user-friendly
- Avoid technical jargon when possible
- Provide clear next steps for users
- Consider user's technical expertise

### 3. **Error Categorization**
- Use consistent error titles for similar errors
- Group related errors with similar messaging
- Provide context-specific error information
- Consider error severity levels

### 4. **Button Design**
- Use descriptive button text
- Make button actions clear and obvious
- Provide meaningful next steps
- Consider user workflow after error

## Error Handling

### Common Scenarios
1. **Validation Failures**: Form input validation errors
2. **Network Errors**: Connection and API call failures
3. **Permission Issues**: Access denied and authorization errors
4. **System Errors**: Resource and system-level failures

### Best Practices
- Always provide meaningful error messages
- Include actionable information when possible
- Log error details for debugging
- Consider error recovery mechanisms

## Performance Considerations

### Execution Speed
- **Fast Execution**: Action executes quickly
- **UI Rendering**: Minimal overhead for dialog display
- **Memory Usage**: Low memory impact

### Optimization Tips
- Avoid showing multiple error popups simultaneously
- Use appropriate error message lengths
- Consider error popup frequency
- Cache error message templates when possible

## Debugging

### Common Issues
1. **Error Popup Not Showing**: Check message parameter and context
2. **Wrong Error Message**: Verify error message content and format
3. **Button Issues**: Check button text parameter
4. **Context Problems**: Verify error context availability

### Debug Tips
- Log error popup parameters before execution
- Verify error context availability
- Test with different error message formats
- Check error popup display logic

## Examples

### Complete Error Handling System
```dart
// Comprehensive error handling workflow
TryAction(
  actions: [
    // Attempt main operation
    MainOperationAction()
  ],
  then: [
    // Handle success
    ShowPopupAction(
      title: "Success",
      message: "Operation completed successfully!"
    )
  ],
  catch: [
    // Handle different error types
    SwitchAction(
      value: "#error.type",
      cases: [
        SwitchCase(
          value: "validation",
          actions: [
            ShowErrorPopupAction(
              title: "Validation Error",
              message: "#error.message",
              buttonText: "Fix Issues"
            )
          ]
        ),
        SwitchCase(
          value: "permission",
          actions: [
            ShowErrorPopupAction(
              title: "Access Denied",
              message: "#error.message",
              buttonText: "Contact Admin"
            )
          ]
        ),
        SwitchCase(
          value: "network",
          actions: [
            ShowErrorPopupAction(
              title: "Connection Error",
              message: "#error.message",
              buttonText: "Retry"
            )
          ]
        ),
        SwitchCase(
          value: "system",
          actions: [
            ShowErrorPopupAction(
              title: "System Error",
              message: "#error.message",
              buttonText: "Report Issue"
            )
          ]
        )
      ]
    )
  ]
)
```

### Smart Error Handling
```dart
// Intelligent error handling based on context
ExpressionAction(
  code: """
    let errorType = getErrorType();
    let userRole = getUserRole();
    let errorContext = getErrorContext();
    
    let errorConfig = {};
    
    if (errorType === 'validation') {
      errorConfig.title = 'Input Error';
      errorConfig.buttonText = 'Fix Issues';
      errorConfig.message = getValidationErrorMessage();
    } else if (errorType === 'permission') {
      if (userRole === 'admin') {
        errorConfig.title = 'Permission Issue';
        errorConfig.buttonText = 'Check Settings';
        errorConfig.message = getAdminPermissionMessage();
      } else {
        errorConfig.title = 'Access Denied';
        errorConfig.buttonText = 'Contact Admin';
        errorConfig.message = getUserPermissionMessage();
      }
    } else if (errorType === 'system') {
      errorConfig.title = 'System Error';
      errorConfig.buttonText = 'Report Issue';
      errorConfig.message = getSystemErrorMessage();
    }
    
    setVariable('errorConfig', errorConfig);
  """
)

ShowErrorPopupAction(
  title: "errorConfig.title",
  message: "errorConfig.message",
  buttonText: "errorConfig.buttonText"
)
```

### Conditional Error Display
```dart
// Show errors based on user permissions and context
ExpressionAction(
  code: """
    let userRole = getUserRole();
    let currentScreen = getCurrentScreen();
    let errorPermissions = getErrorPermissions(userRole);
    
    if (currentScreen === 'admin-panel' && errorPermissions.canSeeAdminErrors) {
      setVariable('errorTitle', 'Admin Error');
      setVariable('errorMessage', getDetailedErrorMessage());
      setVariable('canShowError', true);
    } else if (currentScreen === 'user-dashboard' && errorPermissions.canSeeUserErrors) {
      setVariable('errorTitle', 'User Error');
      setVariable('errorMessage', getUserFriendlyErrorMessage());
      setVariable('canShowError', true);
    } else if (currentScreen === 'public-view' && errorPermissions.canSeePublicErrors) {
      setVariable('errorTitle', 'General Error');
      setVariable('errorMessage', getGenericErrorMessage());
      setVariable('canShowError', true);
    } else {
      setVariable('canShowError', false);
    }
  """
)

IfAction(
  condition: "canShowError",
  then: [
    ShowErrorPopupAction(
      title: "errorTitle",
      message: "errorMessage",
      buttonText: "OK"
    )
  ],
  else: [
    // Log error without showing popup
    LogErrorAction(
      message: "Error occurred but user cannot see error details"
    )
  ]
)
```

## Conclusion

`ShowErrorPopupAction` is a specialized tool for displaying error messages in your CreateGo applications. It enables clear error communication while maintaining good user experience and accessibility standards.

When used effectively with appropriate error messages, meaningful titles, and actionable button text, it significantly enhances the user experience by providing clear feedback about what went wrong and how to proceed. Remember to always provide meaningful error messages, include actionable information when possible, and consider user context for a professional error handling experience.

The key to successful error popup implementation is balancing information with usability, providing clear guidance, and ensuring users understand what went wrong and how to resolve the issue.
