# ScrollToPositionAction - CreateGo

## Overview

The `ScrollToPositionAction` is a UI control action that allows you to programmatically scroll to specific positions within scrollable views in your CreateGo application. It provides a way to control scroll position, navigate to specific content areas, and create smooth scrolling experiences for users.

## Purpose

- **Content Navigation**: Scroll to specific positions in scrollable content
- **User Experience**: Provide smooth scrolling to target areas
- **Content Focus**: Direct user attention to specific content sections
- **Navigation Control**: Programmatically control scroll behavior
- **Accessibility**: Help users navigate to specific content areas

## Action ID

```dart
ScrollToPositionAction.id  // 'scrollTo'
```

## Parameters

### Required Parameters
- **`position`** (double): The target scroll position to scroll to
  - Specified in pixels from the top of the scrollable content
  - `0.0` represents the top of the content
  - Positive values scroll down from the top
  - Can be dynamic using expressions or variables

### Optional Parameters
- **`duration`** (Duration): Duration of the scroll animation
  - Default: `Duration(milliseconds: 300)` (300ms)
  - Controls how long the scroll animation takes
  - Use `Duration.zero` for instant scrolling
  - Longer durations create smoother animations

- **`curve`** (Curve): Animation curve for the scroll animation
  - Default: `Curves.easeOut`
  - Controls the acceleration/deceleration of the scroll
  - Common options: `Curves.easeInOut`, `Curves.bounceOut`, `Curves.elasticOut`
  - Affects the visual feel of the scroll animation

- **`targetId`** (String): ID of the specific scrollable widget to target
  - Default: Empty string (targets the current scrollable context)
  - Useful when multiple scrollable widgets exist
  - Can target specific scroll views by their ID
  - Helps disambiguate which scrollable to control

## Usage

### Basic Usage
```dart
// Scroll to position 500 pixels from top
ScrollToPositionAction(position: 500.0)
```

### With Custom Animation
```dart
// Scroll with custom duration and curve
ScrollToPositionAction(
  position: 1000.0,
  duration: Duration(milliseconds: 500),
  curve: Curves.easeInOut
)
```

### Instant Scrolling
```dart
// Scroll instantly without animation
ScrollToPositionAction(
  position: 750.0,
  duration: Duration.zero
)
```

### Dynamic Position
```dart
// Scroll to dynamic position from variable
ScrollToPositionAction(
  position: "#targetScrollPosition"
)
```

### Target Specific Widget
```dart
// Scroll specific scrollable widget
ScrollToPositionAction(
  position: 300.0,
  targetId: "main-content-scroll"
)
```

## Integration with Action Flows

### Scroll Control Patterns
- **Content Navigation**: Scroll to specific sections or content areas
- **User Feedback**: Scroll to show results or updates
- **Form Navigation**: Scroll to form fields or validation errors
- **Content Focus**: Direct attention to important information
- **Navigation Aid**: Help users find specific content

### Flow Control
- **Position Calculation**: Calculate target scroll positions dynamically
- **Animation Control**: Customize scroll animation behavior
- **Widget Targeting**: Target specific scrollable widgets
- **Error Handling**: Handle scroll failures gracefully

### Scroll Behavior
When executed:
- The scrollable widget animates to the target position
- Animation follows the specified duration and curve
- Scroll position is updated to the target value
- User sees smooth scrolling animation

## Common Use Cases

### 1. **Content Section Navigation**
```dart
// Scroll to specific content sections
ShowPopupAction(
  title: "Navigation",
  message: "Where would you like to go?",
  actions: [
    PopupAction(label: "Top", action: "top"),
    PopupAction(label: "Content", action: "content"),
    PopupAction(label: "Bottom", action: "bottom"),
    PopupAction(label: "Cancel", action: "cancel")
  ]
)

SwitchAction(
  value: "popupResult",
  cases: [
    SwitchCase(
      value: "top",
      actions: [
        ScrollToPositionAction(position: 0.0)
      ]
    ),
    SwitchCase(
      value: "content",
      actions: [
        ScrollToPositionAction(
          position: 500.0,
          duration: Duration(milliseconds: 400)
        )
      ]
    ),
    SwitchCase(
      value: "bottom",
      actions: [
        ScrollToPositionAction(
          position: "#contentHeight",
          duration: Duration(milliseconds: 600)
        )
      ]
    )
  ]
)
```

### 2. **Form Field Navigation**
```dart
// Scroll to form fields with errors
ExpressionAction(
  code: """
    let errorFields = getFormErrorFields();
    let firstErrorField = errorFields[0];
    
    if (firstErrorField) {
      let fieldPosition = getFieldPosition(firstErrorField);
      setVariable('scrollPosition', fieldPosition);
      setVariable('hasErrors', true);
    } else {
      setVariable('hasErrors', false);
    }
  """
)

IfAction(
  condition: "hasErrors",
  then: [
    ScrollToPositionAction(
      position: "scrollPosition",
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOut
    ),
    ShowErrorPopupAction(
      title: "Form Errors",
      message: "Please fix the highlighted errors above."
    )
  ]
)
```

### 3. **Dynamic Content Loading**
```dart
// Scroll to newly loaded content
TryAction(
  actions: [
    // Load additional content
    LoadMoreContentAction()
  ],
  then: [
    // Scroll to show new content
    ScrollToPositionAction(
      position: "#previousContentHeight",
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOut
    )
  ],
  catch: [
    ShowErrorPopupAction(
      title: "Loading Failed",
      message: "Unable to load additional content."
    )
  ]
)
```

### 4. **User Preference Scrolling**
```dart
// Scroll based on user preferences
ExpressionAction(
  code: """
    let userPreferences = getUserPreferences();
    let scrollBehavior = userPreferences.scrollBehavior || 'default';
    
    let scrollDuration, scrollCurve;
    
    if (scrollBehavior === 'fast') {
      scrollDuration = 200;
      scrollCurve = 'easeOut';
    } else if (scrollBehavior === 'slow') {
      scrollDuration = 600;
      scrollCurve = 'easeInOut';
    } else {
      scrollDuration = 300;
      scrollCurve = 'easeOut';
    }
    
    setVariable('scrollDuration', scrollDuration);
    setVariable('scrollCurve', scrollCurve);
  """
)

ScrollToPositionAction(
  position: "#targetPosition",
  duration: "Duration(milliseconds: scrollDuration)",
  curve: "scrollCurve"
)
```

## Best Practices

### 1. **Position Calculation**
- Calculate scroll positions dynamically when possible
- Consider content height and viewport size
- Provide meaningful scroll targets
- Handle edge cases (very long content, small viewports)

### 2. **Animation Timing**
- Keep animations under 1000ms for responsiveness
- Use standard durations (200ms, 300ms, 500ms) for consistency
- Consider user preferences for motion
- Match animation style to app design

### 3. **User Experience**
- Provide visual feedback before scrolling
- Use smooth animations for better UX
- Avoid excessive scrolling during user interaction
- Consider accessibility needs

### 4. **Performance**
- Limit scroll frequency during heavy operations
- Use instant scrolling for programmatic updates
- Consider device performance for complex animations
- Cache scroll positions when appropriate

## Error Handling

### Common Scenarios
1. **Invalid Position**: Negative or extremely large scroll positions
2. **Widget Not Found**: Target scrollable widget doesn't exist
3. **Scroll Context**: No scrollable context available
4. **Animation Issues**: Invalid duration or curve parameters

### Best Practices
- Always validate scroll positions before execution
- Provide fallback scroll behavior when possible
- Handle scroll failures gracefully
- Log scroll attempts for debugging

## Performance Considerations

### Execution Speed
- **Fast Execution**: Action executes quickly
- **Animation Overhead**: Smooth scrolling adds some processing
- **Memory Usage**: Minimal memory impact

### Optimization Tips
- Use instant scrolling for programmatic updates
- Limit scroll frequency during heavy operations
- Consider device performance for complex animations
- Cache scroll positions when possible

## Debugging

### Common Issues
1. **Scroll Not Working**: Check if scrollable context exists
2. **Wrong Position**: Verify position calculation logic
3. **Animation Problems**: Check duration and curve parameters
4. **Target Issues**: Verify targetId parameter

### Debug Tips
- Log scroll position calculations
- Verify scrollable widget availability
- Test with different position values
- Check animation parameters

## Examples

### Complete Scroll Management System
```dart
// Comprehensive scroll management workflow
ShowPopupAction(
  title: "Scroll Control",
  message: "What would you like to do?",
  actions: [
    PopupAction(label: "Go to Top", action: "top"),
    PopupAction(label: "Go to Bottom", action: "bottom"),
    PopupAction(label: "Go to Section", action: "section"),
    PopupAction(label: "Custom Position", action: "custom"),
    PopupAction(label: "Cancel", action: "cancel")
  ]
)

SwitchAction(
  value: "popupResult",
  cases: [
    SwitchCase(
      value: "top",
      actions: [
        ScrollToPositionAction(
          position: 0.0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut
        )
      ]
    ),
    SwitchCase(
      value: "bottom",
      actions: [
        ScrollToPositionAction(
          position: "#totalContentHeight",
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut
        )
      ]
    ),
    SwitchCase(
      value: "section",
      actions: [
        // Show section selection
        ShowPopupAction(
          title: "Select Section",
          message: "Choose a section to scroll to:",
          actions: [
            PopupAction(label: "Introduction", action: "intro"),
            PopupAction(label: "Features", action: "features"),
            PopupAction(label: "Documentation", action: "docs"),
            PopupAction(label: "Cancel", action: "cancel")
          ]
        )
      ]
    ),
    SwitchCase(
      value: "custom",
      actions: [
        // Get custom position from user
        GetUserInputAction(
          prompt: "Enter scroll position (in pixels):",
          saveTo: "customScrollPosition"
        ),
        ScrollToPositionAction(
          position: "#customScrollPosition",
          duration: Duration(milliseconds: 400)
        )
      ]
    )
  ]
)
```

### Smart Scroll Positioning
```dart
// Intelligent scroll positioning based on context
ExpressionAction(
  code: """
    let currentContext = getCurrentContext();
    let userBehavior = getUserBehavior();
    let contentStructure = getContentStructure();
    
    let targetPosition, scrollDuration, scrollCurve;
    
    if (currentContext === 'reading') {
      // For reading context, scroll to last read position
      targetPosition = getLastReadPosition();
      scrollDuration = 400;
      scrollCurve = 'easeInOut';
    } else if (currentContext === 'searching') {
      // For search context, scroll to search results
      targetPosition = getSearchResultsPosition();
      scrollDuration = 300;
      scrollCurve = 'easeOut';
    } else if (currentContext === 'navigation') {
      // For navigation context, scroll to target section
      targetPosition = getTargetSectionPosition();
      scrollDuration = 500;
      scrollCurve = 'easeInOut';
    } else {
      // Default behavior
      targetPosition = 0.0;
      scrollDuration = 300;
      scrollCurve = 'easeOut';
    }
    
    setVariable('targetPosition', targetPosition);
    setVariable('scrollDuration', scrollDuration);
    setVariable('scrollCurve', scrollCurve);
  """
)

ScrollToPositionAction(
  position: "targetPosition",
  duration: "Duration(milliseconds: scrollDuration)",
  curve: "scrollCurve"
)
```

### Conditional Scroll Control
```dart
// Scroll based on user permissions and context
ExpressionAction(
  code: """
    let userRole = getUserRole();
    let currentScreen = getCurrentScreen();
    let scrollPermissions = getScrollPermissions(userRole);
    
    if (currentScreen === 'admin-panel' && scrollPermissions.canScrollToAdmin) {
      setVariable('targetPosition', getAdminSectionPosition());
      setVariable('canScroll', true);
    } else if (currentScreen === 'user-dashboard' && scrollPermissions.canScrollToUser) {
      setVariable('targetPosition', getUserSectionPosition());
      setVariable('canScroll', true);
    } else if (currentScreen === 'public-view' && scrollPermissions.canScrollToPublic) {
      setVariable('targetPosition', getPublicSectionPosition());
      setVariable('canScroll', true);
    } else {
      setVariable('canScroll', false);
    }
  """
)

IfAction(
  condition: "canScroll",
  then: [
    ScrollToPositionAction(
      position: "targetPosition",
      duration: Duration(milliseconds: 400),
      curve: Curves.easeOut
    )
  ],
  else: [
    ShowErrorPopupAction(
      title: "Scroll Restricted",
      message: "You don't have permission to scroll to this position."
    )
  ]
)
```

## Conclusion

`ScrollToPositionAction` is a powerful tool for creating smooth and controlled scrolling experiences in your CreateGo applications. It enables programmatic scroll control while maintaining good user experience and performance standards.

When used effectively with appropriate positioning, animation timing, and error handling, it significantly enhances the user experience by providing intuitive content navigation. Remember to always consider user context, provide smooth animations, and handle edge cases gracefully for a professional scrolling experience.

The key to successful scroll implementation is balancing functionality with user experience, providing appropriate animation timing, and ensuring scroll behavior is predictable and smooth across different content types and devices.
