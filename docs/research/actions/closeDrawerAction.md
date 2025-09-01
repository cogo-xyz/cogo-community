# CloseDrawerAction - CreateGo

## Overview

The `CloseDrawerAction` is a UI control action that allows you to programmatically close navigation drawers or side panels in your CreateGo application. It provides a way to hide open drawers, returning the user to the main content area and improving the overall user experience by maintaining clean, uncluttered interfaces.

## Purpose

- **Drawer Management**: Close open navigation drawers and side panels
- **User Experience**: Return focus to main content after drawer interactions
- **Interface Cleanup**: Maintain clean, uncluttered app interfaces
- **Navigation Control**: Programmatically control drawer visibility states
- **Consistent Behavior**: Ensure uniform drawer closing across the app

## Parameters

### Required Parameters
None - `CloseDrawerAction` doesn't require any parameters to function.

### Optional Parameters
- **`drawerId`** (String): ID of the specific drawer to close
  - Useful when multiple drawers exist in the app
  - If not specified, closes the currently open drawer
  - Can target specific navigation drawers or side panels

- **`animationDuration`** (Duration): Duration of the closing animation
  - Default: 300ms (standard Material Design duration)
  - Use `Duration.zero` for instant closing
  - Longer durations create smoother animations

- **`curve`** (Curve): Animation curve for drawer closing
  - Default: `Curves.easeIn`
  - Common options: `Curves.easeInOut`, `Curves.bounceIn`, `Curves.elasticIn`

## Usage

### Basic Usage
```dart
// Close the currently open drawer
CloseDrawerAction()
```

### With Custom Animation
```dart
// Close drawer with custom animation
CloseDrawerAction(
  animationDuration: Duration(milliseconds: 500),
  curve: Curves.bounceIn
)
```

### Target Specific Drawer
```dart
// Close a specific drawer by ID
CloseDrawerAction(drawerId: "settings-drawer")
```

### Instant Closing
```dart
// Close drawer without animation
CloseDrawerAction(
  animationDuration: Duration.zero
)
```

## Integration with Action Flows

### Drawer Closing Patterns
- **User Interaction**: Close drawer after user selection
- **Navigation**: Close drawer when navigating to new screens
- **Timeout**: Auto-close drawer after inactivity
- **Error Handling**: Close drawer on errors or failures
- **Context Change**: Close drawer when app context changes

### Flow Control
- **Post-Selection**: Close drawer after user makes a choice
- **Navigation Flow**: Close drawer before screen transitions
- **Error Recovery**: Close drawer when operations fail
- **User Cancellation**: Close drawer when user cancels actions

## Common Use Cases

### 1. **Post-Selection Drawer Closing**
```dart
// Close drawer after user selects an option
ShowPopupAction(
  title: "Navigation",
  message: "Choose a destination:",
  actions: [
    PopupAction(label: "Home", action: "home"),
    PopupAction(label: "Profile", action: "profile"),
    PopupAction(label: "Cancel", action: "cancel")
  ]
)

SwitchAction(
  value: "popupResult",
  cases: [
    SwitchCase(
      value: "home",
      actions: [
        CloseDrawerAction(),
        NavigationAction(routePath: "/home")
      ]
    ),
    SwitchCase(
      value: "profile",
      actions: [
        CloseDrawerAction(),
        NavigationAction(routePath: "/profile")
      ]
    ),
    SwitchCase(
      value: "cancel",
      actions: [CloseDrawerAction()]
    )
  ]
)
```

### 2. **Settings Panel Management**
```dart
// Close settings drawer after saving changes
TryAction(
  actions: [
    SaveSettingsAction(settings: userSettings)
  ],
  then: [
    ShowPopupAction(
      title: "Settings Saved",
      message: "Your changes have been saved successfully."
    ),
    CloseDrawerAction(
      drawerId: "settings-drawer",
      animationDuration: Duration(milliseconds: 400)
    )
  ],
  catch: [
    ShowErrorPopupAction(
      title: "Save Failed",
      message: "Unable to save settings. Please try again."
    )
  ]
)
```

### 3. **Filter Panel Closing**
```dart
// Close filter drawer after applying filters
TryAction(
  actions: [
    ApplyFiltersAction(filters: selectedFilters)
  ],
  then: [
    CloseDrawerAction(
      drawerId: "filter-drawer",
      animationDuration: Duration(milliseconds: 300)
    ),
    RefreshDataAction()
  ],
  catch: [
    ShowErrorPopupAction(
      title: "Filter Error",
      message: "Unable to apply filters. Please try again."
    )
  ]
)
```

### 4. **Contextual Drawer Closing**
```dart
// Close appropriate drawer based on context
ExpressionAction(
  code: """
    let openDrawers = getOpenDrawers();
    let currentContext = getCurrentContext();
    
    if (currentContext === 'navigation' && openDrawers.includes('navigation-drawer')) {
      setVariable('drawerToClose', 'navigation-drawer');
    } else if (currentContext === 'settings' && openDrawers.includes('settings-drawer')) {
      setVariable('drawerToClose', 'settings-drawer');
    } else if (currentContext === 'filters' && openDrawers.includes('filter-drawer')) {
      setVariable('drawerToClose', 'filter-drawer');
    } else {
      setVariable('drawerToClose', null);
    }
  """
)

IfAction(
  condition: "drawerToClose != null",
  then: [
    CloseDrawerAction(
      drawerId: "drawerToClose",
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
- Close drawers after user interactions
- Provide visual feedback before closing
- Use smooth animations for better UX
- Consider accessibility needs

### 3. **Performance**
- Limit drawer closing frequency
- Use instant closing for programmatic updates
- Avoid closing drawers during heavy operations
- Consider device performance

### 4. **Context Awareness**
- Only close drawers when appropriate
- Check drawer state before closing
- Handle cases where no drawer is open
- Provide fallback behavior when needed

## Error Handling

### Common Scenarios
1. **No Drawer Open**: Attempting to close when no drawer is open
2. **Drawer Not Found**: Target drawer doesn't exist
3. **Animation Issues**: Invalid duration or curve parameters
4. **Context Problems**: No drawer context available

### Best Practices
- Always handle potential errors gracefully
- Check drawer state before closing
- Provide user feedback for drawer operations
- Log drawer actions for debugging

## Performance Considerations

### Execution Speed
- **Fast Execution**: Action executes quickly
- **Animation Overhead**: Smooth closing adds some processing
- **Memory Usage**: Minimal memory impact

### Optimization Tips
- Use instant closing for programmatic updates
- Limit drawer closing frequency
- Consider user's device performance
- Cache drawer states when possible

## Debugging

### Common Issues
1. **Drawer Not Closing**: Check if target drawer is open
2. **Wrong Drawer**: Verify drawerId parameter
3. **Animation Problems**: Check duration and curve parameters
4. **Context Issues**: Ensure proper drawer context

### Debug Tips
- Log drawer closing attempts
- Verify drawer configuration
- Test with different drawer IDs
- Check animation parameters

## Examples

### Complete Drawer Management Workflow
```dart
// Comprehensive drawer opening and closing workflow
ShowPopupAction(
  title: "App Navigation",
  message: "Choose what to open:",
  actions: [
    PopupAction(label: "Main Menu", action: "main"),
    PopupAction(label: "Settings", action: "settings"),
    PopupAction(label: "Filters", action: "filters")
  ]
)

SwitchAction(
  value: "popupResult",
  cases: [
    SwitchCase(
      value: "main",
      actions: [
        OpenDrawerAction(
          animationDuration: Duration(milliseconds: 300)
        ),
        // Wait for user selection
        WaitAction(duration: Duration(seconds: 2)),
        CloseDrawerAction(
          animationDuration: Duration(milliseconds: 300)
        )
      ]
    ),
    SwitchCase(
      value: "settings",
      actions: [
        OpenDrawerAction(
          drawerId: "settings-drawer",
          animationDuration: Duration(milliseconds: 400)
        ),
        // Wait for user interaction
        WaitAction(duration: Duration(seconds: 3)),
        CloseDrawerAction(
          drawerId: "settings-drawer",
          animationDuration: Duration(milliseconds: 400)
        )
      ]
    ),
    SwitchCase(
      value: "filters",
      actions: [
        OpenDrawerAction(
          drawerId: "filter-drawer",
          animationDuration: Duration(milliseconds: 300)
        ),
        // Wait for filter application
        WaitAction(duration: Duration(seconds: 2)),
        CloseDrawerAction(
          drawerId: "filter-drawer",
          animationDuration: Duration(milliseconds: 300)
        )
      ]
    )
  ]
)
```

### Smart Drawer State Management
```dart
// Intelligent drawer state management
ExpressionAction(
  code: """
    let openDrawers = getOpenDrawers();
    let userIntent = getUserIntent();
    let shouldCloseDrawer = false;
    let targetDrawer = null;
    
    if (userIntent === 'navigate' && openDrawers.length > 0) {
      shouldCloseDrawer = true;
      targetDrawer = openDrawers[0]; // Close first open drawer
    } else if (userIntent === 'cancel' && openDrawers.length > 0) {
      shouldCloseDrawer = true;
      targetDrawer = openDrawers[0];
    } else if (userIntent === 'timeout' && openDrawers.length > 0) {
      shouldCloseDrawer = true;
      targetDrawer = openDrawers[0];
    }
    
    setVariable('shouldCloseDrawer', shouldCloseDrawer);
    setVariable('targetDrawer', targetDrawer);
  """
)

IfAction(
  condition: "shouldCloseDrawer",
  then: [
    CloseDrawerAction(
      drawerId: "targetDrawer",
      animationDuration: Duration(milliseconds: 350)
    )
  ]
)
```

### Conditional Drawer Closing
```dart
// Close drawer based on user permissions and context
ExpressionAction(
  code: """
    let userRole = getUserRole();
    let currentScreen = getCurrentScreen();
    let openDrawers = getOpenDrawers();
    let drawerPermissions = getDrawerPermissions(userRole);
    
    if (currentScreen === 'dashboard' && openDrawers.includes('settings-drawer')) {
      if (!drawerPermissions.canAccessSettings) {
        setVariable('drawerToClose', 'settings-drawer');
        setVariable('closeReason', 'permission_denied');
      }
    } else if (currentScreen === 'search' && openDrawers.includes('filter-drawer')) {
      if (!drawerPermissions.canAccessFilters) {
        setVariable('drawerToClose', 'filter-drawer');
        setVariable('closeReason', 'permission_denied');
      }
    }
  """
)

IfAction(
  condition: "drawerToClose != null",
  then: [
    CloseDrawerAction(
      drawerId: "drawerToClose",
      animationDuration: Duration(milliseconds: 300)
    ),
    ShowErrorPopupAction(
      title: "Access Denied",
      message: "You don't have permission to access this drawer."
    )
  ]
)
```

## Conclusion

`CloseDrawerAction` is an essential tool for maintaining clean and organized user interfaces in your CreateGo applications. It enables programmatic control over drawer closing while maintaining good user experience and accessibility standards.

When used effectively with appropriate animations, proper error handling, and context awareness, it significantly improves the overall user experience by ensuring drawers close at the right time and in the right way. Remember to always consider user context, provide smooth animations, and handle edge cases gracefully for a professional drawer experience.

The key to successful drawer management is balancing functionality with user experience, providing appropriate feedback, and ensuring drawers close in the right context with the right timing to maintain a clean and intuitive interface.
