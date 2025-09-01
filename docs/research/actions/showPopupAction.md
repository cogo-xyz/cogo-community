# ShowPopupAction - CreateGo

## Overview

The `ShowPopupAction` is a UI feedback action that displays customizable popup dialogs to users. It provides a way to show informational messages, confirmations, and user interactions through modal dialogs that can be configured with various options and button configurations.

## Purpose

- **User Feedback**: Display important information and messages to users
- **User Interaction**: Collect user input through button selections
- **Confirmation Dialogs**: Ask users to confirm actions or decisions
- **Information Display**: Show help text, instructions, or status updates
- **Modal Communication**: Present content without navigating away from current context

## Action ID

```dart
ShowPopupAction.id  // 'showPopup'
```

## Parameters

### Required Parameters
- **`message`** (String): The main content text to display in the popup
  - This is the primary information shown to the user
  - Should be clear and concise
  - Can include line breaks and formatting

### Optional Parameters
- **`title`** (String): The header text displayed at the top of the popup
  - Default: Empty string (no title shown)
  - Provides context for the popup content
  - Should be brief and descriptive

- **`closeButtonText`** (String): Text for the close/cancel button
  - Default: No close button shown
  - When provided, creates a close button that returns the `closeButtonValue`
  - Useful for providing an escape option

- **`closeButtonValue`** (dynamic): Value returned when close button is pressed
  - Default: No specific value
  - Can be any data type (string, number, boolean, etc.)
  - Useful for conditional logic based on user choice

- **`confirmButtonText`** (String): Text for the confirm/action button
  - Default: No confirm button shown
  - When provided, creates a primary action button
  - Should indicate the action that will be taken

- **`confirmButtonValue`** (dynamic): Value returned when confirm button is pressed
  - Default: No specific value
  - Can be any data type
  - Useful for conditional logic based on user choice

- **`width`** (double): Custom width for the popup dialog
  - Default: Auto-sized based on content
  - Can be specified in pixels
  - Useful for controlling popup dimensions

- **`height`** (double): Custom height for the popup dialog
  - Default: Auto-sized based on content
  - Can be specified in pixels
  - Useful for controlling popup dimensions

## Usage

### Basic Usage
```dart
// Simple message popup
ShowPopupAction(message: "Operation completed successfully!")
```

### With Title
```dart
// Popup with title and message
ShowPopupAction(
  title: "Success",
  message: "Your data has been saved successfully."
)
```

### Confirmation Dialog
```dart
// Confirmation popup with two buttons
ShowPopupAction(
  title: "Confirm Action",
  message: "Are you sure you want to delete this item?",
  closeButtonText: "Cancel",
  closeButtonValue: "cancelled",
  confirmButtonText: "Delete",
  confirmButtonValue: "confirmed"
)
```

### Custom Sized Popup
```dart
// Popup with custom dimensions
ShowPopupAction(
  title: "Large Content",
  message: "This popup has custom dimensions for better content display.",
  width: 600.0,
  height: 400.0
)
```

## Integration with Action Flows

### Popup Result Handling
The popup returns the button value when a button is pressed:
- **Close button**: Returns `closeButtonValue` or `null` if no value specified
- **Confirm button**: Returns `confirmButtonValue` or `null` if no value specified
- **No buttons**: Returns `null` when dialog is dismissed

### Flow Control
- **User Input**: Wait for user to make a selection
- **Conditional Logic**: Use returned values to determine next actions
- **Error Handling**: Handle cases where no selection is made
- **Default Values**: Provide fallback behavior for missing selections

## Common Use Cases

### 1. **Information Display**
```dart
// Show informational message
ShowPopupAction(
  title: "Welcome",
  message: "Thank you for using our application! We're here to help you get started."
)
```

### 2. **User Confirmation**
```dart
// Confirm user action
ShowPopupAction(
  title: "Confirm Payment",
  message: "You are about to charge $99.99 to your account. Do you want to continue?",
  closeButtonText: "Cancel",
  closeButtonValue: "cancelled",
  confirmButtonText: "Confirm Payment",
  confirmButtonValue: "confirmed"
)

// Handle user choice
IfAction(
  condition: "popupResult == 'confirmed'",
  then: [
    ProcessPaymentAction(amount: 99.99)
  ],
  else: [
    ShowPopupAction(
      title: "Payment Cancelled",
      message: "Payment was cancelled. No charges were made."
    )
  ]
)
```

### 3. **Error Notification**
```dart
// Show error message
ShowPopupAction(
  title: "Error",
  message: "Unable to connect to the server. Please check your internet connection and try again.",
  confirmButtonText: "OK",
  confirmButtonValue: "acknowledged"
)
```

### 4. **Success Confirmation**
```dart
// Show success message
ShowPopupAction(
  title: "Success",
  message: "Your profile has been updated successfully!",
  confirmButtonText: "Continue",
  confirmButtonValue: "continue"
)
```

## Best Practices

### 1. **Message Content**
- Keep messages clear and concise
- Use appropriate titles for context
- Avoid technical jargon when possible
- Provide actionable information when relevant

### 2. **Button Design**
- Use descriptive button text
- Limit to 2 buttons maximum for clarity
- Make button actions obvious
- Provide meaningful return values

### 3. **User Experience**
- Don't overuse popups
- Ensure popups are dismissible
- Consider popup size for content
- Test on different screen sizes

### 4. **Accessibility**
- Use clear, readable text
- Ensure sufficient color contrast
- Provide meaningful button labels
- Consider screen reader compatibility

## Error Handling

### Common Scenarios
1. **No User Selection**: User dismisses popup without making a choice
2. **Invalid Parameters**: Missing required message parameter
3. **Context Issues**: Popup shown without proper context
4. **Button Configuration**: Misconfigured button parameters

### Best Practices
- Always handle potential popup results
- Provide default values for missing parameters
- Test popup behavior in different scenarios
- Log popup interactions for debugging

## Performance Considerations

### Execution Speed
- **Fast Execution**: Action executes quickly
- **UI Rendering**: Minimal overhead for dialog display
- **Memory Usage**: Low memory impact

### Optimization Tips
- Avoid showing multiple popups simultaneously
- Use appropriate popup sizes
- Consider popup frequency in workflows
- Cache popup content when possible

## Debugging

### Common Issues
1. **Popup Not Showing**: Check context and parameters
2. **Wrong Button Values**: Verify button configuration
3. **Size Issues**: Check width and height parameters
4. **Result Handling**: Verify popup result processing

### Debug Tips
- Log popup parameters before execution
- Verify context availability
- Test with different parameter combinations
- Check popup result handling logic

## Examples

### Complete User Workflow
```dart
// Multi-step user interaction workflow
ActionFlow(
  steps: [
    // Step 1: Show welcome message
    ShowPopupAction(
      title: "Welcome",
      message: "Let's get started with your profile setup.",
      confirmButtonText: "Begin Setup",
      confirmButtonValue: "start"
    ),
    
    // Step 2: Handle user choice
    IfAction(
      condition: "popupResult == 'start'",
      then: [
        // Show profile form
        ShowPopupAction(
          title: "Profile Setup",
          message: "Please fill out your profile information in the form below.",
          confirmButtonText: "I'm Ready",
          confirmButtonValue: "ready"
        )
      ],
      else: [
        // User cancelled
        ShowPopupAction(
          title: "Setup Cancelled",
          message: "You can complete your profile setup later from the settings menu."
        )
      ]
    )
  ]
)
```

### Smart Popup Management
```dart
// Intelligent popup display based on context
ExpressionAction(
  code: """
    let userContext = getUserContext();
    let popupTitle, popupMessage, showConfirmButton;
    
    if (userContext === 'first_time_user') {
      popupTitle = 'Welcome!';
      popupMessage = 'This is your first time here. Let us show you around!';
      showConfirmButton = true;
    } else if (userContext === 'returning_user') {
      popupTitle = 'Welcome Back!';
      popupMessage = 'Great to see you again. Here are your recent updates.';
      showConfirmButton = false;
    } else {
      popupTitle = 'Hello!';
      popupMessage = 'How can we help you today?';
      showConfirmButton = true;
    }
    
    setVariable('popupTitle', popupTitle);
    setVariable('popupMessage', popupMessage);
    setVariable('showConfirmButton', showConfirmButton);
  """
)

ShowPopupAction(
  title: "popupTitle",
  message: "popupMessage",
  confirmButtonText: "showConfirmButton ? 'Continue' : null",
  confirmButtonValue: "continue"
)
```

## Conclusion

`ShowPopupAction` is a versatile tool for user communication in your CreateGo applications. It provides flexible popup dialogs that can be customized for various use cases while maintaining good user experience standards.

When used effectively with appropriate content, button configuration, and result handling, it significantly enhances user interaction by providing clear feedback and collecting user input in an intuitive way. Remember to always consider user experience, provide meaningful content, and handle popup results appropriately for a professional user interface.

The key to successful popup implementation is balancing functionality with simplicity, ensuring users can easily understand and interact with the content while maintaining the flow of your application.
