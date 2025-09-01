# OpenBottomSheetAction - CreateGo

## Overview

The `OpenBottomSheetAction` is a UI control action that allows you to programmatically open bottom sheets in your CreateGo application. Bottom sheets are sliding panels that emerge from the bottom of the screen, providing additional content, options, or actions without navigating away from the current context.

## Purpose

- **Content Display**: Show additional information or options
- **User Interaction**: Provide quick access to related actions
- **Context Preservation**: Keep users in current view while showing more content
- **Mobile UX**: Follow mobile design patterns for bottom-up interactions
- **Action Menus**: Present action choices without full screen navigation

## Parameters

### Required Parameters
None - `OpenBottomSheetAction` doesn't require any parameters to function.

### Optional Parameters
- **`sheetId`** (String): ID of the specific bottom sheet to open
  - Useful when multiple bottom sheets exist in the app
  - If not specified, opens the default/primary bottom sheet
  - Can target specific action sheets, detail panels, or custom sheets

- **`animationDuration`** (Duration): Duration of the opening animation
  - Default: 300ms (standard Material Design duration)
  - Use `Duration.zero` for instant opening
  - Longer durations create smoother animations

- **`curve`** (Curve): Animation curve for sheet opening
  - Default: `Curves.easeOut`
  - Common options: `Curves.easeInOut`, `Curves.bounceOut`, `Curves.elasticOut`

- **`isDismissible`** (bool): Whether user can dismiss by tapping outside
  - Default: `true` (allows user to dismiss)
  - `false`: Forces user to use action buttons
  - Important for critical action sheets

- **`enableDrag`** (bool): Whether user can drag to dismiss
  - Default: `true` (allows drag dismissal)
  - `false`: Disables drag-to-dismiss functionality
  - Useful for important content that shouldn't be accidentally dismissed

## Usage

### Basic Usage
```dart
// Open the default bottom sheet
OpenBottomSheetAction()
```

### With Custom Animation
```dart
// Open bottom sheet with custom animation
OpenBottomSheetAction(
  animationDuration: Duration(milliseconds: 500),
  curve: Curves.bounceOut
)
```

### Target Specific Sheet
```dart
// Open a specific bottom sheet by ID
OpenBottomSheetAction(sheetId: "action-sheet")
```

### Non-Dismissible Sheet
```dart
// Open bottom sheet that user must interact with
OpenBottomSheetAction(
  sheetId: "confirmation-sheet",
  isDismissible: false,
  enableDrag: false
)
```

## Integration with Action Flows

### Bottom Sheet Types Supported
- **Action Sheets**: Present action choices to users
- **Detail Panels**: Show additional information about items
- **Form Sheets**: Collect user input in context
- **Media Sheets**: Display media content or galleries
- **Custom Sheets**: App-specific bottom panel content

### Context Awareness
- **Current View**: Automatically targets the active bottom sheet context
- **Multiple Sheets**: Use `sheetId` to specify which sheet to open
- **Sheet State**: Respects current sheet open/closed state
- **Content Context**: Maintains relevance to current screen content

## Common Use Cases

### 1. **Action Sheet Presentation**
```dart
// Open action sheet for item options
ShowPopupAction(
  title: "Item Options",
  message: "What would you like to do with this item?",
  actions: [
    PopupAction(label: "Show Actions", action: "actions"),
    PopupAction(label: "Cancel", action: "cancel")
  ]
)

IfAction(
  condition: "popupResult == 'actions'",
  then: [
    OpenBottomSheetAction(
      sheetId: "item-actions-sheet",
      animationDuration: Duration(milliseconds: 300)
    )
  ]
)
```

### 2. **Detail Information Display**
```dart
// Open detail sheet for selected item
IfAction(
  condition: "selectedItem != null",
  then: [
    OpenBottomSheetAction(
      sheetId: "item-detail-sheet",
      animationDuration: Duration(milliseconds: 400)
    )
  ]
)
```

### 3. **Form Input Collection**
```dart
// Open form sheet for user input
ShowPopupAction(
  title: "Add Comment",
  message: "Would you like to add a comment?",
  actions: [
    PopupAction(label: "Add Comment", action: "comment"),
    PopupAction(label: "Skip", action: "skip")
  ]
)

IfAction(
  condition: "popupResult == 'comment'",
  then: [
    OpenBottomSheetAction(
      sheetId: "comment-form-sheet",
      isDismissible: false,
      enableDrag: false
    )
  ]
)
```

### 4. **Media Content Display**
```dart
// Open media sheet for image gallery
IfAction(
  condition: "hasMediaContent",
  then: [
    OpenBottomSheetAction(
      sheetId: "media-gallery-sheet",
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
- Use bottom sheets for related content and actions
- Keep content relevant to current context
- Provide clear dismissal options when appropriate
- Consider accessibility needs

### 3. **Performance**
- Limit bottom sheet opening frequency
- Use instant opening for programmatic updates
- Avoid opening sheets during heavy operations
- Consider device performance

### 4. **Content Design**
- Keep content concise and focused
- Use appropriate dismissal behavior
- Provide clear action buttons
- Consider screen size constraints

## Error Handling

### Common Scenarios
1. **Sheet Not Found**: Target bottom sheet doesn't exist
2. **Sheet Already Open**: Attempting to open an open sheet
3. **Animation Issues**: Invalid duration or curve parameters
4. **Context Problems**: No bottom sheet context available

### Best Practices
- Always handle potential errors gracefully
- Check sheet availability before opening
- Provide user feedback for sheet operations
- Log sheet actions for debugging

## Performance Considerations

### Execution Speed
- **Fast Execution**: Action executes quickly
- **Animation Overhead**: Smooth opening adds some processing
- **Memory Usage**: Minimal memory impact

### Optimization Tips
- Use instant opening for programmatic updates
- Limit bottom sheet opening frequency
- Consider user's device performance
- Cache sheet states when possible

## Debugging

### Common Issues
1. **Sheet Not Opening**: Check if target sheet exists
2. **Wrong Sheet**: Verify sheetId parameter
3. **Animation Problems**: Check duration and curve parameters
4. **Context Issues**: Ensure proper bottom sheet context

### Debug Tips
- Log bottom sheet opening attempts
- Verify sheet configuration
- Test with different sheet IDs
- Check animation parameters

## Examples

### Complete Bottom Sheet Management System
```dart
// Comprehensive bottom sheet management workflow
ShowPopupAction(
  title: "Content Options",
  message: "Choose what to display:",
  actions: [
    PopupAction(label: "Actions", action: "actions"),
    PopupAction(label: "Details", action: "details"),
    PopupAction(label: "Form", action: "form"),
    PopupAction(label: "Media", action: "media")
  ]
)

SwitchAction(
  value: "popupResult",
  cases: [
    SwitchCase(
      value: "actions",
      actions: [
        ShowPopupAction(title: "Opening", message: "Opening action sheet..."),
        OpenBottomSheetAction(
          sheetId: "action-sheet",
          animationDuration: Duration(milliseconds: 300)
        )
      ]
    ),
    SwitchCase(
      value: "details",
      actions: [
        ShowPopupAction(title: "Opening", message: "Opening detail sheet..."),
        OpenBottomSheetAction(
          sheetId: "detail-sheet",
          animationDuration: Duration(milliseconds: 400)
        )
      ]
    ),
    SwitchCase(
      value: "form",
      actions: [
        ShowPopupAction(title: "Opening", message: "Opening form sheet..."),
        OpenBottomSheetAction(
          sheetId: "form-sheet",
          isDismissible: false,
          enableDrag: false
        )
      ]
    ),
    SwitchCase(
      value: "media",
      actions: [
        ShowPopupAction(title: "Opening", message: "Opening media sheet..."),
        OpenBottomSheetAction(
          sheetId: "media-sheet",
          animationDuration: Duration(milliseconds: 350)
        )
      ]
    )
  ]
)
```

### Smart Bottom Sheet Context Management
```dart
// Intelligent bottom sheet opening based on context
ExpressionAction(
  code: """
    let context = getCurrentContext();
    let availableSheets = getAvailableBottomSheets();
    let userPreferences = getUserPreferences();
    
    if (context === 'item-selected' && availableSheets.includes('detail-sheet')) {
      setVariable('targetSheet', 'detail-sheet');
      setVariable('animationDuration', 400);
    } else if (context === 'action-needed' && availableSheets.includes('action-sheet')) {
      setVariable('targetSheet', 'action-sheet');
      setVariable('animationDuration', 300);
    } else if (context === 'form-input' && availableSheets.includes('form-sheet')) {
      setVariable('targetSheet', 'form-sheet');
      setVariable('animationDuration', 350);
    } else if (availableSheets.includes('default-sheet')) {
      setVariable('targetSheet', 'default-sheet');
      setVariable('animationDuration', 300);
    } else {
      setVariable('targetSheet', null);
    }
    
    setVariable('canOpenSheet', targetSheet !== null);
  """
)

IfAction(
  condition: "canOpenSheet",
  then: [
    OpenBottomSheetAction(
      sheetId: "targetSheet",
      animationDuration: "animationDuration"
    )
  ],
  else: [
    ShowErrorPopupAction(
      title: "No Sheet Available",
      message: "No appropriate bottom sheet is available in this context."
    )
  ]
)
```

### Conditional Bottom Sheet Opening
```dart
// Open bottom sheet based on user permissions and context
ExpressionAction(
  code: """
    let userRole = getUserRole();
    let currentScreen = getCurrentScreen();
    let sheetPermissions = getBottomSheetPermissions(userRole);
    
    if (currentScreen === 'item-list' && sheetPermissions.canAccessDetailSheet) {
      setVariable('sheetToOpen', 'detail-sheet');
    } else if (currentScreen === 'dashboard' && sheetPermissions.canAccessActionSheet) {
      setVariable('sheetToOpen', 'action-sheet');
    } else if (currentScreen === 'profile' && sheetPermissions.canAccessFormSheet) {
      setVariable('sheetToOpen', 'form-sheet');
    } else {
      setVariable('sheetToOpen', null);
    }
  """
)

IfAction(
  condition: "sheetToOpen != null",
  then: [
    OpenBottomSheetAction(
      sheetId: "sheetToOpen",
      animationDuration: Duration(milliseconds: 350)
    )
  ],
  else: [
    ShowErrorPopupAction(
      title: "Access Denied",
      message: "You don't have permission to access this bottom sheet."
    )
  ]
)
```

## Conclusion

`OpenBottomSheetAction` is a powerful tool for creating engaging and contextually relevant user experiences in your CreateGo applications. It enables programmatic control over bottom sheet opening while maintaining good user experience and accessibility standards.

When used effectively with appropriate animations, proper error handling, and context awareness, it significantly enhances the user experience by providing quick access to related content and actions without disrupting the current workflow. Remember to always consider user context, provide smooth animations, and handle edge cases gracefully for a professional bottom sheet experience.

The key to successful bottom sheet implementation is balancing functionality with user experience, providing relevant content, and ensuring sheets open in the right context with the right timing to enhance rather than disrupt the user's current task.
