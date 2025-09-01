# CloseBottomSheetAction - CreateGo

## Overview

The `CloseBottomSheetAction` is a UI control action that allows you to programmatically close bottom sheets in your CreateGo application. It provides a way to hide open bottom sheets, returning the user to the main content area and improving the overall user experience by maintaining clean, uncluttered interfaces.

## Purpose

- **Sheet Management**: Close open bottom sheets and panels
- **User Experience**: Return focus to main content after sheet interactions
- **Interface Cleanup**: Maintain clean, uncluttered app interfaces
- **Navigation Control**: Programmatically control bottom sheet visibility states
- **Consistent Behavior**: Ensure uniform bottom sheet closing across the app

## Parameters

### Required Parameters
None - `CloseBottomSheetAction` doesn't require any parameters to function.

### Optional Parameters
- **`sheetId`** (String): ID of the specific bottom sheet to close
  - Useful when multiple bottom sheets exist in the app
  - If not specified, closes the currently open bottom sheet
  - Can target specific action sheets, detail panels, or custom sheets

- **`animationDuration`** (Duration): Duration of the closing animation
  - Default: 300ms (standard Material Design duration)
  - Use `Duration.zero` for instant closing
  - Longer durations create smoother animations

- **`curve`** (Curve): Animation curve for sheet closing
  - Default: `Curves.easeIn`
  - Common options: `Curves.easeInOut`, `Curves.bounceIn`, `Curves.elasticIn`

## Usage

### Basic Usage
```dart
// Close the currently open bottom sheet
CloseBottomSheetAction()
```

### With Custom Animation
```dart
// Close bottom sheet with custom animation
CloseBottomSheetAction(
  animationDuration: Duration(milliseconds: 500),
  curve: Curves.bounceIn
)
```

### Target Specific Sheet
```dart
// Close a specific bottom sheet by ID
CloseBottomSheetAction(sheetId: "action-sheet")
```

### Instant Closing
```dart
// Close bottom sheet without animation
CloseBottomSheetAction(
  animationDuration: Duration.zero
)
```

## Integration with Action Flows

### Bottom Sheet Closing Patterns
- **User Interaction**: Close sheet after user selection or action
- **Navigation**: Close sheet when navigating to new screens
- **Timeout**: Auto-close sheet after inactivity
- **Error Handling**: Close sheet on errors or failures
- **Context Change**: Close sheet when app context changes

### Flow Control
- **Post-Selection**: Close sheet after user makes a choice
- **Navigation Flow**: Close sheet before screen transitions
- **Error Recovery**: Close sheet when operations fail
- **User Cancellation**: Close sheet when user cancels actions

## Common Use Cases

### 1. **Post-Selection Sheet Closing**
```dart
// Close action sheet after user selects an option
ShowPopupAction(
  title: "Action Selected",
  message: "Processing your selection...",
  actions: [
    PopupAction(label: "OK", action: "ok")
  ]
)

IfAction(
  condition: "popupResult == 'ok'",
  then: [
    CloseBottomSheetAction(
      sheetId: "action-sheet",
      animationDuration: Duration(milliseconds: 300)
    ),
    ProcessUserSelectionAction()
  ]
)
```

### 2. **Form Submission Closing**
```dart
// Close form sheet after successful submission
TryAction(
  actions: [
    SubmitFormAction(formData: userInput)
  ],
  then: [
    ShowPopupAction(
      title: "Success",
      message: "Your form has been submitted successfully."
    ),
    CloseBottomSheetAction(
      sheetId: "form-sheet",
      animationDuration: Duration(milliseconds: 400)
    )
  ],
  catch: [
    ShowErrorPopupAction(
      title: "Submission Failed",
      message: "Unable to submit form. Please try again."
    )
  ]
)
```

### 3. **Detail Panel Management**
```dart
// Close detail sheet after user interaction
ShowPopupAction(
  title: "Detail View",
  message: "What would you like to do?",
  actions: [
    PopupAction(label: "Edit", action: "edit"),
    PopupAction(label: "Close", action: "close")
  ]
)

SwitchAction(
  value: "popupResult",
  cases: [
    SwitchCase(
      value: "edit",
      actions: [
        CloseBottomSheetAction(
          sheetId: "detail-sheet",
          animationDuration: Duration(milliseconds: 300)
        ),
        OpenEditFormAction()
      ]
    ),
    SwitchCase(
      value: "close",
      actions: [
        CloseBottomSheetAction(
          sheetId: "detail-sheet",
          animationDuration: Duration(milliseconds: 300)
        )
      ]
    )
  ]
)
```

### 4. **Contextual Sheet Closing**
```dart
// Close appropriate sheet based on context
ExpressionAction(
  code: """
    let openSheets = getOpenBottomSheets();
    let currentContext = getCurrentContext();
    
    if (currentContext === 'action-completed' && openSheets.includes('action-sheet')) {
      setVariable('sheetToClose', 'action-sheet');
    } else if (currentContext === 'form-submitted' && openSheets.includes('form-sheet')) {
      setVariable('sheetToClose', 'form-sheet');
    } else if (currentContext === 'detail-viewed' && openSheets.includes('detail-sheet')) {
      setVariable('sheetToClose', 'detail-sheet');
    } else {
      setVariable('sheetToClose', null);
    }
  """
)

IfAction(
  condition: "sheetToClose != null",
  then: [
    CloseBottomSheetAction(
      sheetId: "sheetToClose",
      animationDuration: Duration(milliseconds: 350)
    )
  ]
)
```

## Best Practices

### 1. **Animation Timing**
- Keep animations under 500ms for responsiveness
- Use standard Material Design durations (300ms)
- Consider user preferences for motion
- Match animation style to app design

### 2. **User Experience**
- Close sheets after user interactions
- Provide visual feedback before closing
- Use smooth animations for better UX
- Consider accessibility needs

### 3. **Performance**
- Limit bottom sheet closing frequency
- Use instant closing for programmatic updates
- Avoid closing sheets during heavy operations
- Consider device performance

### 4. **Context Awareness**
- Only close sheets when appropriate
- Check sheet state before closing
- Handle cases where no sheet is open
- Provide fallback behavior when needed

## Error Handling

### Common Scenarios
1. **No Sheet Open**: Attempting to close when no sheet is open
2. **Sheet Not Found**: Target bottom sheet doesn't exist
3. **Animation Issues**: Invalid duration or curve parameters
4. **Context Problems**: No bottom sheet context available

### Best Practices
- Always handle potential errors gracefully
- Check sheet state before closing
- Provide user feedback for sheet operations
- Log sheet actions for debugging

## Performance Considerations

### Execution Speed
- **Fast Execution**: Action executes quickly
- **Animation Overhead**: Smooth closing adds some processing
- **Memory Usage**: Minimal memory impact

### Optimization Tips
- Use instant closing for programmatic updates
- Limit bottom sheet closing frequency
- Consider user's device performance
- Cache sheet states when possible

## Debugging

### Common Issues
1. **Sheet Not Closing**: Check if target sheet is open
2. **Wrong Sheet**: Verify sheetId parameter
3. **Animation Problems**: Check duration and curve parameters
4. **Context Issues**: Ensure proper bottom sheet context

### Debug Tips
- Log bottom sheet closing attempts
- Verify sheet configuration
- Test with different sheet IDs
- Check animation parameters

## Examples

### Complete Bottom Sheet Management Workflow
```dart
// Comprehensive bottom sheet opening and closing workflow
ShowPopupAction(
  title: "Content Options",
  message: "Choose what to display:",
  actions: [
    PopupAction(label: "Actions", action: "actions"),
    PopupAction(label: "Details", action: "details"),
    PopupAction(label: "Form", action: "form")
  ]
)

SwitchAction(
  value: "popupResult",
  cases: [
    SwitchCase(
      value: "actions",
      actions: [
        OpenBottomSheetAction(
          sheetId: "action-sheet",
          animationDuration: Duration(milliseconds: 300)
        ),
        // Wait for user selection
        WaitAction(duration: Duration(seconds: 2)),
        CloseBottomSheetAction(
          sheetId: "action-sheet",
          animationDuration: Duration(milliseconds: 300)
        )
      ]
    ),
    SwitchCase(
      value: "details",
      actions: [
        OpenBottomSheetAction(
          sheetId: "detail-sheet",
          animationDuration: Duration(milliseconds: 400)
        ),
        // Wait for user interaction
        WaitAction(duration: Duration(seconds: 3)),
        CloseBottomSheetAction(
          sheetId: "detail-sheet",
          animationDuration: Duration(milliseconds: 400)
        )
      ]
    ),
    SwitchCase(
      value: "form",
      actions: [
        OpenBottomSheetAction(
          sheetId: "form-sheet",
          isDismissible: false,
          enableDrag: false
        ),
        // Wait for form submission
        WaitAction(duration: Duration(seconds: 2)),
        CloseBottomSheetAction(
          sheetId: "form-sheet",
          animationDuration: Duration(milliseconds: 350)
        )
      ]
    )
  ]
)
```

### Smart Bottom Sheet State Management
```dart
// Intelligent bottom sheet state management
ExpressionAction(
  code: """
    let openSheets = getOpenBottomSheets();
    let userIntent = getUserIntent();
    let shouldCloseSheet = false;
    let targetSheet = null;
    
    if (userIntent === 'navigate' && openSheets.length > 0) {
      shouldCloseSheet = true;
      targetSheet = openSheets[0]; // Close first open sheet
    } else if (userIntent === 'cancel' && openSheets.length > 0) {
      shouldCloseSheet = true;
      targetSheet = openSheets[0];
    } else if (userIntent === 'timeout' && openSheets.length > 0) {
      shouldCloseSheet = true;
      targetSheet = openSheets[0];
    }
    
    setVariable('shouldCloseSheet', shouldCloseSheet);
    setVariable('targetSheet', targetSheet);
  """
)

IfAction(
  condition: "shouldCloseSheet",
  then: [
    CloseBottomSheetAction(
      sheetId: "targetSheet",
      animationDuration: Duration(milliseconds: 350)
    )
  ]
)
```

### Conditional Bottom Sheet Closing
```dart
// Close bottom sheet based on user permissions and context
ExpressionAction(
  code: """
    let userRole = getUserRole();
    let currentScreen = getCurrentScreen();
    let openSheets = getOpenBottomSheets();
    let sheetPermissions = getBottomSheetPermissions(userRole);
    
    if (currentScreen === 'item-list' && openSheets.includes('detail-sheet')) {
      if (!sheetPermissions.canAccessDetailSheet) {
        setVariable('sheetToClose', 'detail-sheet');
        setVariable('closeReason', 'permission_denied');
      }
    } else if (currentScreen === 'dashboard' && openSheets.includes('action-sheet')) {
      if (!sheetPermissions.canAccessActionSheet) {
        setVariable('sheetToClose', 'action-sheet');
        setVariable('closeReason', 'permission_denied');
      }
    }
  """
)

IfAction(
  condition: "sheetToClose != null",
  then: [
    CloseBottomSheetAction(
      sheetId: "sheetToClose",
      animationDuration: Duration(milliseconds: 300)
    ),
    ShowErrorPopupAction(
      title: "Access Denied",
      message: "You don't have permission to access this bottom sheet."
    )
  ]
)
```

## Conclusion

`CloseBottomSheetAction` is an essential tool for maintaining clean and organized user interfaces in your CreateGo applications. It enables programmatic control over bottom sheet closing while maintaining good user experience and accessibility standards.

When used effectively with appropriate animations, proper error handling, and context awareness, it significantly improves the overall user experience by ensuring bottom sheets close at the right time and in the right way. Remember to always consider user context, provide smooth animations, and handle edge cases gracefully for a professional bottom sheet experience.

The key to successful bottom sheet management is balancing functionality with user experience, providing appropriate feedback, and ensuring sheets close in the right context with the right timing to maintain a clean and intuitive interface that enhances rather than disrupts the user's workflow.
