# ShowLoadingDialogAction - CreateGo

## Overview

The `ShowLoadingDialogAction` is a UI feedback action that displays loading state dialogs to users during long-running operations. It provides a way to show loading indicators, progress states, and processing feedback through modal dialogs that can be configured with various options and automatically managed to prevent multiple overlapping dialogs.

## Purpose

- **Loading States**: Display loading indicators during operations
- **User Feedback**: Provide visual feedback for long-running processes
- **Progress Indication**: Show that operations are in progress
- **User Experience**: Prevent user confusion during processing
- **Dialog Management**: Automatically handle multiple loading states

## Action ID

```dart
ShowLoadingDialogAction.id  // 'showLoading'
```

## Parameters

### Required Parameters
- **`isShowing`** (bool): Whether to show or hide the loading dialog
  - `true`: Shows the loading dialog
  - `false`: Hides the loading dialog
  - Controls the visibility state of the loading indicator

### Optional Parameters
- **`dismissible`** (bool): Whether the loading dialog can be dismissed by user
  - Default: `false` (user cannot dismiss the dialog)
  - `true`: User can dismiss the dialog by tapping outside
  - `false`: User must wait for the operation to complete
  - Useful for critical operations that shouldn't be cancelled

## Usage

### Basic Usage
```dart
// Show loading dialog
ShowLoadingDialogAction(isShowing: true)
```

### With Dismissible Option
```dart
// Show dismissible loading dialog
ShowLoadingDialogAction(
  isShowing: true,
  dismissible: true
)
```

### Hide Loading Dialog
```dart
// Hide loading dialog
ShowLoadingDialogAction(isShowing: false)
```

### Dynamic Loading Control
```dart
// Control loading based on variable
ShowLoadingDialogAction(
  isShowing: "#shouldShowLoading",
  dismissible: "#canDismiss"
)
```

## Integration with Action Flows

### Loading State Patterns
- **Operation Start**: Show loading when starting long operations
- **Operation End**: Hide loading when operations complete
- **Error Handling**: Hide loading when errors occur
- **User Feedback**: Provide visual feedback during processing
- **State Management**: Control loading states programmatically

### Flow Control
- **Loading Display**: Show loading indicators at appropriate times
- **State Synchronization**: Keep loading state in sync with operations
- **Error Recovery**: Handle loading state in error scenarios
- **User Experience**: Ensure smooth loading transitions

### Loading Dialog Behavior
When executed:
- **Show Mode** (`isShowing: true`): Displays a loading dialog with spinner
- **Hide Mode** (`isShowing: false`): Closes any open loading dialog
- **Automatic Management**: Prevents multiple overlapping loading dialogs
- **Context Awareness**: Uses appropriate navigation context for display

## Common Use Cases

### 1. **API Call Loading States**
```dart
// Show loading during API call
ShowLoadingDialogAction(isShowing: true)

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
    // Hide loading on success
    ShowLoadingDialogAction(isShowing: false),
    ShowPopupAction(
      title: "Success",
      message: "Data submitted successfully!"
    )
  ],
  catch: [
    // Hide loading on error
    ShowLoadingDialogAction(isShowing: false),
    ShowErrorPopupAction(
      title: "Submission Failed",
      message: "Unable to submit data. Please try again."
    )
  ]
)
```

### 2. **Form Processing Loading**
```dart
// Show loading during form processing
ShowLoadingDialogAction(
  isShowing: true,
  dismissible: false
)

TryAction(
  actions: [
    // Process form data
    ProcessFormAction(formData: userFormData)
  ],
  then: [
    // Hide loading and show success
    ShowLoadingDialogAction(isShowing: false),
    ShowPopupAction(
      title: "Processing Complete",
      message: "Your form has been processed successfully!"
    )
  ],
  catch: [
    // Hide loading and show error
    ShowLoadingDialogAction(isShowing: false),
    ShowErrorPopupAction(
      title: "Processing Failed",
      message: "Unable to process your form. Please try again."
    )
  ]
)
```

### 3. **File Upload Loading**
```dart
// Show loading during file upload
ShowLoadingDialogAction(
  isShowing: true,
  dismissible: true
)

TryAction(
  actions: [
    // Upload file
    UploadFileAction(
      file: selectedFile,
      destination: "/uploads"
    )
  ],
  then: [
    // Hide loading on success
    ShowLoadingDialogAction(isShowing: false),
    ShowPopupAction(
      title: "Upload Complete",
      message: "File uploaded successfully!"
    )
  ],
  catch: [
    // Hide loading on error
    ShowLoadingDialogAction(isShowing: false),
    ShowErrorPopupAction(
      title: "Upload Failed",
      message: "Unable to upload file. Please try again."
    )
  ]
)
```

### 4. **Database Operation Loading**
```dart
// Show loading during database operations
ShowLoadingDialogAction(isShowing: true)

TryAction(
  actions: [
    // Execute database operation
    SqliteDataAction(
      method: "INSERT",
      query: "INSERT INTO users (name, email) VALUES (?, ?)",
      values: ["John Doe", "john@example.com"]
    )
  ],
  then: [
    // Hide loading on success
    ShowLoadingDialogAction(isShowing: false),
    ShowPopupAction(
      title: "Data Saved",
      message: "User data has been saved successfully!"
    )
  ],
  catch: [
    // Hide loading on error
    ShowLoadingDialogAction(isShowing: false),
    ShowErrorPopupAction(
      title: "Save Failed",
      message: "Unable to save user data. Please try again."
    )
  ]
)
```

## Best Practices

### 1. **Loading State Management**
- Always hide loading dialogs when operations complete
- Handle both success and error scenarios
- Use appropriate dismissible settings for different operations
- Prevent multiple overlapping loading dialogs

### 2. **User Experience**
- Show loading for operations longer than 500ms
- Provide clear feedback about what's happening
- Allow users to cancel non-critical operations
- Handle loading state in error scenarios

### 3. **Performance Considerations**
- Don't show loading for very quick operations
- Use loading states to indicate progress
- Consider operation duration when setting dismissible
- Provide fallback behavior for long operations

### 4. **Error Handling**
- Always hide loading dialogs in error scenarios
- Provide clear error messages after loading
- Consider retry mechanisms for failed operations
- Handle network timeouts appropriately

## Error Handling

### Common Scenarios
1. **Operation Timeout**: Long-running operations that exceed expectations
2. **Network Failures**: Connection issues during operations
3. **User Cancellation**: Users dismissing loading dialogs
4. **System Errors**: Unexpected failures during processing

### Best Practices
- Always handle loading state cleanup
- Provide meaningful error messages
- Consider retry mechanisms when appropriate
- Handle user cancellation gracefully

## Performance Considerations

### Execution Speed
- **Fast Execution**: Action executes quickly
- **Dialog Management**: Efficient loading dialog handling
- **Memory Usage**: Minimal memory impact
- **State Synchronization**: Fast loading state updates

### Optimization Tips
- Use loading states appropriately
- Avoid showing loading for quick operations
- Handle loading state cleanup efficiently
- Consider operation duration when showing loading

## Debugging

### Common Issues
1. **Loading Not Showing**: Check isShowing parameter and context
2. **Loading Not Hiding**: Verify loading state cleanup
3. **Multiple Dialogs**: Check for overlapping loading calls
4. **Context Issues**: Verify proper context availability

### Debug Tips
- Log loading state changes
- Verify loading parameters
- Check for multiple loading calls
- Monitor loading dialog lifecycle

## Examples

### Complete Loading Management System
```dart
// Comprehensive loading management workflow
ShowLoadingDialogAction(
  isShowing: true,
  dismissible: false
)

TryAction(
  actions: [
    // Perform complex operation
    ComplexOperationAction()
  ],
  then: [
    // Hide loading and show success
    ShowLoadingDialogAction(isShowing: false),
    ShowPopupAction(
      title: "Operation Complete",
      message: "Complex operation completed successfully!"
    )
  ],
  catch: [
    // Hide loading and show error
    ShowLoadingDialogAction(isShowing: false),
    ShowErrorPopupAction(
      title: "Operation Failed",
      message: "Complex operation failed. Please try again."
    )
  ]
)
```

### Smart Loading Control
```dart
// Intelligent loading control based on operation type
ExpressionAction(
  code: """
    let operationType = getOperationType();
    let operationDuration = getEstimatedDuration(operationType);
    
    let loadingConfig = {};
    
    if (operationDuration < 1000) {
      // Quick operation, no loading needed
      loadingConfig.showLoading = false;
    } else if (operationDuration < 5000) {
      // Medium operation, show loading
      loadingConfig.showLoading = true;
      loadingConfig.dismissible = true;
    } else {
      // Long operation, show loading with progress
      loadingConfig.showLoading = true;
      loadingConfig.dismissible = false;
    }
    
    setVariable('loadingConfig', loadingConfig);
  """
)

IfAction(
  condition: "loadingConfig.showLoading",
  then: [
    ShowLoadingDialogAction(
      isShowing: true,
      dismissible: "loadingConfig.dismissible"
    )
  ]
)
```

### Conditional Loading Management
```dart
// Control loading based on user permissions and context
ExpressionAction(
  code: """
    let userRole = getUserRole();
    let currentScreen = getCurrentScreen();
    let loadingPermissions = getLoadingPermissions(userRole);
    
    if (currentScreen === 'admin-panel' && loadingPermissions.canShowAdminLoading) {
      setVariable('canShowLoading', true);
      setVariable('loadingDismissible', false);
    } else if (currentScreen === 'user-dashboard' && loadingPermissions.canShowUserLoading) {
      setVariable('canShowLoading', true);
      setVariable('loadingDismissible', true);
    } else if (currentScreen === 'public-view' && loadingPermissions.canShowPublicLoading) {
      setVariable('canShowLoading', true);
      setVariable('loadingDismissible', true);
    } else {
      setVariable('canShowLoading', false);
    }
  """
)

IfAction(
  condition: "canShowLoading",
  then: [
    ShowLoadingDialogAction(
      isShowing: true,
      dismissible: "loadingDismissible"
    )
  ],
  else: [
    // Log that loading cannot be shown
    LogAction(
      message: "Loading dialog cannot be shown in current context"
    )
  ]
)
```

## Conclusion

`ShowLoadingDialogAction` is a powerful tool for managing loading states in your CreateGo applications. It enables clear user feedback during long-running operations while maintaining good user experience and performance standards.

When used effectively with appropriate timing, dismissible settings, and proper cleanup, it significantly enhances the user experience by providing clear feedback about ongoing operations. Remember to always handle loading state cleanup, provide meaningful user feedback, and consider operation duration for a professional loading experience.

The key to successful loading implementation is balancing feedback with performance, providing appropriate loading states, and ensuring smooth transitions between loading and completion states.
