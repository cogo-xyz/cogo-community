# NavigationAction - CreateGo

## Overview

The `NavigationAction` is a core navigation action that allows you to programmatically navigate between different screens, routes, and views within your CreateGo application. It provides a way to control app navigation, manage screen transitions, and create seamless user experiences through structured routing.

## Purpose

- **Screen Navigation**: Move between different app screens and views
- **Route Management**: Control app routing and navigation flow
- **User Experience**: Provide smooth transitions between app sections
- **Flow Control**: Manage navigation within action flows
- **Deep Linking**: Navigate to specific app locations programmatically

## Action ID

```dart
NavigationAction.id  // 'navigate'
```

## Parameters

### Required Parameters
- **`routePath`** (String): The route path to navigate to
  - Must be a valid route defined in your app
  - Can be absolute paths (e.g., "/home", "/profile/settings")
  - Can be relative paths (e.g., "../profile", "./settings")
  - Should match your app's routing configuration

### Optional Parameters
- **`arguments`** (Map<String, dynamic>): Data to pass to the target route
  - Default: Empty map (no arguments passed)
  - Can include any serializable data
  - Useful for passing context, IDs, or configuration
  - Data is available in the target screen

- **`replace`** (bool): Whether to replace the current route in the navigation stack
  - Default: `false` (adds new route to stack)
  - `true`: Replaces current route, user can't go back
  - `false`: Adds new route, user can navigate back
  - Useful for login/logout flows or preventing back navigation

- **`clearStack`** (bool): Whether to clear the entire navigation stack
  - Default: `false` (maintains navigation history)
  - `true`: Clears all previous routes, user can't go back
  - `false`: Maintains navigation stack
  - Useful for resetting app state or main navigation

## Usage

### Basic Usage
```dart
// Navigate to home screen
NavigationAction(routePath: "/home")
```

### With Arguments
```dart
// Navigate with data
NavigationAction(
  routePath: "/user-profile",
  arguments: {
    "userId": "123",
    "showEditButton": true
  }
)
```

### Replace Current Route
```dart
// Replace current route (can't go back)
NavigationAction(
  routePath: "/dashboard",
  replace: true
)
```

### Clear Navigation Stack
```dart
// Clear stack and navigate to main screen
NavigationAction(
  routePath: "/main",
  clearStack: true
)
```

### Dynamic Route
```dart
// Navigate to dynamic route
NavigationAction(
  routePath: "#targetRoute",
  arguments: "#routeArguments"
)
```

## Integration with Action Flows

### Navigation Patterns
- **Screen Transitions**: Move between different app screens
- **Flow Navigation**: Navigate based on user actions or conditions
- **Deep Navigation**: Navigate to nested or specific app sections
- **State Management**: Pass data and context between screens
- **User Flow Control**: Guide users through app workflows

### Flow Control
- **Route Validation**: Ensure target routes exist and are accessible
- **Argument Passing**: Pass necessary data to target screens
- **Navigation Stack Management**: Control user's ability to navigate back
- **Error Handling**: Handle navigation failures gracefully

### Navigation Behavior
When executed:
- The target route is validated for existence and accessibility
- Arguments are prepared and passed to the target screen
- Navigation stack is modified based on parameters
- User is transitioned to the target screen
- App state is updated accordingly

## Common Use Cases

### 1. **User Authentication Flow**
```dart
// Navigate after successful login
TryAction(
  actions: [
    // Attempt user login
    LoginUserAction(credentials: userCredentials)
  ],
  then: [
    // Navigate to dashboard
    NavigationAction(
      routePath: "/dashboard",
      clearStack: true
    )
  ],
  catch: [
    // Show error and stay on login screen
    ShowErrorPopupAction(
      title: "Login Failed",
      message: "Invalid credentials. Please try again."
    )
  ]
)
```

### 2. **Form Submission Navigation**
```dart
// Navigate after form submission
TryAction(
  actions: [
    // Submit form data
    SubmitFormAction(formData: userFormData)
  ],
  then: [
    // Navigate to success screen
    NavigationAction(
      routePath: "/success",
      arguments: {
        "submissionId": "#response.submissionId",
        "message": "Form submitted successfully!"
      }
    )
  ],
  catch: [
    // Navigate to error screen
    NavigationAction(
      routePath: "/error",
      arguments: {
        "errorMessage": "#error.message"
      }
    )
  ]
)
```

### 3. **Conditional Navigation**
```dart
// Navigate based on user role
ExpressionAction(
  code: """
    let userRole = getUserRole();
    let targetRoute = '';
    
    if (userRole === 'admin') {
      targetRoute = '/admin-dashboard';
    } else if (userRole === 'user') {
      targetRoute = '/user-dashboard';
    } else {
      targetRoute = '/public-home';
    }
    
    setVariable('targetRoute', targetRoute);
  """
)

NavigationAction(
  routePath: "targetRoute",
  arguments: {
    "userRole": "#userRole",
    "timestamp": "#currentTimestamp"
  }
)
```

### 4. **Multi-step Workflow**
```dart
// Navigate through workflow steps
ShowPopupAction(
  title: "Workflow",
  message: "Choose next step:",
  actions: [
    PopupAction(label: "Step 1", action: "step1"),
    PopupAction(label: "Step 2", action: "step2"),
    PopupAction(label: "Complete", action: "complete")
  ]
)

SwitchAction(
  value: "popupResult",
  cases: [
    SwitchCase(
      value: "step1",
      actions: [
        NavigationAction(
          routePath: "/workflow/step1",
          arguments: {
            "workflowId": "#currentWorkflowId",
            "step": 1
          }
        )
      ]
    ),
    SwitchCase(
      value: "step2",
      actions: [
        NavigationAction(
          routePath: "/workflow/step2",
          arguments: {
            "workflowId": "#currentWorkflowId",
            "step": 2
          }
        )
      ]
    ),
    SwitchCase(
      value: "complete",
      actions: [
        NavigationAction(
          routePath: "/workflow/complete",
          arguments: {
            "workflowId": "#currentWorkflowId",
            "completed": true
          },
          replace: true
        )
      ]
    )
  ]
)
```

## Best Practices

### 1. **Route Management**
- Use consistent route naming conventions
- Validate routes before navigation
- Handle route not found scenarios gracefully
- Consider route accessibility and permissions

### 2. **Argument Passing**
- Pass only necessary data to target screens
- Use meaningful argument names
- Handle missing or invalid arguments gracefully
- Consider argument size and performance

### 3. **Navigation Stack Control**
- Use `replace` for login/logout flows
- Use `clearStack` for main navigation resets
- Consider user experience when modifying navigation history
- Provide clear navigation feedback

### 4. **Error Handling**
- Always handle navigation failures gracefully
- Provide fallback navigation options
- Log navigation attempts for debugging
- Consider offline or error states

## Error Handling

### Common Scenarios
1. **Route Not Found**: Target route doesn't exist
2. **Permission Denied**: User lacks access to target route
3. **Invalid Arguments**: Arguments are malformed or invalid
4. **Navigation Failure**: System unable to perform navigation

### Best Practices
- Always handle potential errors gracefully
- Provide user-friendly error messages
- Offer alternative navigation options
- Log navigation attempts for debugging

## Performance Considerations

### Execution Speed
- **Fast Execution**: Action executes quickly
- **Route Resolution**: Route lookup and validation time
- **Screen Transition**: UI transition and rendering time
- **Memory Usage**: Minimal memory impact

### Optimization Tips
- Cache route information when possible
- Minimize argument data size
- Consider navigation frequency
- Optimize screen transitions

## Debugging

### Common Issues
1. **Navigation Not Working**: Check route existence and permissions
2. **Wrong Screen**: Verify route path and arguments
3. **Argument Issues**: Check argument format and values
4. **Stack Problems**: Verify navigation stack management

### Debug Tips
- Log navigation attempts and parameters
- Verify route configuration
- Test with different argument combinations
- Check navigation stack state

## Examples

### Complete Navigation Management System
```dart
// Comprehensive navigation management workflow
ShowPopupAction(
  title: "Navigation",
  message: "Where would you like to go?",
  actions: [
    PopupAction(label: "Home", action: "home"),
    PopupAction(label: "Profile", action: "profile"),
    PopupAction(label: "Settings", action: "settings"),
    PopupAction(label: "Help", action: "help"),
    PopupAction(label: "Logout", action: "logout"),
    PopupAction(label: "Cancel", action: "cancel")
  ]
)

SwitchAction(
  value: "popupResult",
  cases: [
    SwitchCase(
      value: "home",
      actions: [
        NavigationAction(
          routePath: "/home",
          arguments: {
            "refresh": true,
            "timestamp": "#currentTimestamp"
          }
        )
      ]
    ),
    SwitchCase(
      value: "profile",
      actions: [
        NavigationAction(
          routePath: "/user/profile",
          arguments: {
            "userId": "#currentUserId",
            "editable": true
          }
        )
      ]
    ),
    SwitchCase(
      value: "settings",
      actions: [
        NavigationAction(
          routePath: "/settings",
          arguments: {
            "category": "general"
          }
        )
      ]
    ),
    SwitchCase(
      value: "help",
      actions: [
        NavigationAction(
          routePath: "/help",
          arguments: {
            "topic": "navigation"
          }
        )
      ]
    ),
    SwitchCase(
      value: "logout",
      actions: [
        // Clear user session
        ClearUserSessionAction(),
        // Navigate to login screen
        NavigationAction(
          routePath: "/login",
          clearStack: true
        )
      ]
    )
  ]
)
```

### Smart Navigation System
```dart
// Intelligent navigation based on context
ExpressionAction(
  code: """
    let currentContext = getCurrentContext();
    let userRole = getUserRole();
    let userPreferences = getUserPreferences();
    
    let navigationConfig = {};
    
    if (currentContext === 'dashboard') {
      if (userRole === 'admin') {
        navigationConfig.route = '/admin/dashboard';
        navigationConfig.arguments = {
          'adminLevel': userRole.level,
          'showAnalytics': true
        };
      } else {
        navigationConfig.route = '/user/dashboard';
        navigationConfig.arguments = {
          'userId': userPreferences.userId,
          'showQuickActions': true
        };
      }
    } else if (currentContext === 'profile') {
      navigationConfig.route = '/user/profile';
      navigationConfig.arguments = {
        'userId': userPreferences.userId,
        'editable': userRole === 'admin' || userPreferences.canEditProfile
      };
    } else if (currentContext === 'settings') {
      navigationConfig.route = '/settings';
      navigationConfig.arguments = {
        'category': userPreferences.lastSettingsCategory || 'general'
      };
    }
    
    setVariable('navigationConfig', navigationConfig);
  """
)

NavigationAction(
  routePath: "navigationConfig.route",
  arguments: "navigationConfig.arguments"
)
```

### Conditional Navigation Control
```dart
// Navigate based on user permissions and context
ExpressionAction(
  code: """
    let userRole = getUserRole();
    let currentScreen = getCurrentScreen();
    let navigationPermissions = getNavigationPermissions(userRole);
    
    if (currentScreen === 'admin-panel' && navigationPermissions.canAccessAdminRoutes) {
      setVariable('targetRoute', '/admin/dashboard');
      setVariable('canNavigate', true);
    } else if (currentScreen === 'user-dashboard' && navigationPermissions.canAccessUserRoutes) {
      setVariable('targetRoute', '/user/profile');
      setVariable('canNavigate', true);
    } else if (currentScreen === 'public-view' && navigationPermissions.canAccessPublicRoutes) {
      setVariable('targetRoute', '/public/home');
      setVariable('canNavigate', true);
    } else {
      setVariable('canNavigate', false);
    }
  """
)

IfAction(
  condition: "canNavigate",
  then: [
    NavigationAction(
      routePath: "targetRoute",
      arguments: {
        "userRole": "#userRole",
        "timestamp": "#currentTimestamp"
      }
    )
  ],
  else: [
    ShowErrorPopupAction(
      title: "Navigation Restricted",
      message: "You don't have permission to access this route."
    )
  ]
)
```

## Conclusion

`NavigationAction` is a fundamental tool for managing app navigation and user flow in your CreateGo applications. It enables structured routing while maintaining good user experience and performance standards.

When used effectively with appropriate route management, argument passing, and navigation stack control, it significantly enhances the user experience by providing smooth and predictable navigation. Remember to always validate routes, handle errors gracefully, and consider user context for a professional navigation experience.

The key to successful navigation implementation is balancing functionality with user experience, providing clear navigation paths, and ensuring smooth transitions between app sections.
