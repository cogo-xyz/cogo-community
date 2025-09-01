# GoToLinkAction - CreateGo

## Overview

The `GoToLinkAction` is a navigation action that allows you to open external links, URLs, or deep links in your CreateGo application. It provides a way to navigate users to web content, external applications, or specific app sections while maintaining control over how and where links are opened.

## Purpose

- **External Navigation**: Open web URLs and external links
- **Deep Linking**: Navigate to specific app sections or content
- **Web Integration**: Provide access to web-based resources
- **User Experience**: Seamless navigation between app and web content
- **Link Management**: Control how and where links are opened

## Action ID

```dart
GoToLinkAction.id  // 'goToLink'
```

## Parameters

### Required Parameters
- **`url`** (String): The URL or link to navigate to
  - Must be a valid URL (e.g., "https://example.com")
  - Can be a deep link (e.g., "myapp://section/123")
  - Can be a relative path within the app
  - Supports both HTTP/HTTPS and custom schemes

### Optional Parameters
- **`openInApp`** (bool): Whether to open the link within the app
  - Default: `false` (opens in external browser/app)
  - `true`: Attempts to open link within the app
  - `false`: Opens link in external browser or app
  - Useful for keeping users in app context

- **`target`** (String): Target window or context for the link
  - Default: Empty string (uses default behavior)
  - `"_self"`: Open in current window/context
  - `"_blank"`: Open in new window/tab
  - `"_parent"`: Open in parent window
  - `"_top"`: Open in top-level window

- **`headers`** (Map<String, String>): Additional headers for the request
  - Default: Empty map (no additional headers)
  - Can include authentication tokens
  - Can include custom request headers
  - Useful for API calls or authenticated requests

## Usage

### Basic Usage
```dart
// Open external link in default browser
GoToLinkAction(url: "https://example.com")
```

### Open in App
```dart
// Open link within the app
GoToLinkAction(
  url: "https://docs.example.com",
  openInApp: true
)
```

### New Window Target
```dart
// Open link in new window/tab
GoToLinkAction(
  url: "https://example.com",
  target: "_blank"
)
```

### With Headers
```dart
// Open link with custom headers
GoToLinkAction(
  url: "https://api.example.com/data",
  headers: {
    "Authorization": "Bearer #authToken",
    "Content-Type": "application/json"
  }
)
```

### Deep Link
```dart
// Open deep link to app section
GoToLinkAction(
  url: "myapp://profile/settings",
  openInApp: true
)
```

## Integration with Action Flows

### Link Navigation Patterns
- **External Resources**: Open documentation, help pages, or external services
- **Deep Linking**: Navigate to specific app sections or content
- **Web Integration**: Provide access to web-based tools and resources
- **API Access**: Make authenticated requests to external APIs
- **User Guidance**: Direct users to relevant external content

### Flow Control
- **Link Validation**: Validate URLs before navigation
- **Target Control**: Control where and how links are opened
- **Error Handling**: Handle link opening failures gracefully
- **User Feedback**: Provide feedback about link navigation

### Navigation Behavior
When executed:
- The link is validated for format and accessibility
- Based on parameters, the link opens in the specified target
- User is navigated to the target content
- App maintains state during external navigation

## Common Use Cases

### 1. **External Documentation**
```dart
// Open external documentation
ShowPopupAction(
  title: "Help",
  message: "Would you like to view the documentation?",
  actions: [
    PopupAction(label: "View Docs", action: "docs"),
    PopupAction(label: "Cancel", action: "cancel")
  ]
)

IfAction(
  condition: "popupResult == 'docs'",
  then: [
    GoToLinkAction(
      url: "https://docs.example.com",
      target: "_blank"
    )
  ]
)
```

### 2. **Deep Link Navigation**
```dart
// Navigate to specific app section
ExpressionAction(
  code: """
    let userRole = getUserRole();
    let targetSection = '';
    
    if (userRole === 'admin') {
      targetSection = 'admin-dashboard';
    } else if (userRole === 'user') {
      targetSection = 'user-profile';
    } else {
      targetSection = 'public-home';
    }
    
    setVariable('deepLinkUrl', 'myapp://' + targetSection);
  """
)

GoToLinkAction(
  url: "deepLinkUrl",
  openInApp: true
)
```

### 3. **API Integration**
```dart
// Make authenticated API call
TryAction(
  actions: [
    // Get authentication token
    GetAuthTokenAction()
  ],
  then: [
    GoToLinkAction(
      url: "https://api.example.com/user-data",
      headers: {
        "Authorization": "Bearer #authToken",
        "Accept": "application/json"
      }
    )
  ],
  catch: [
    ShowErrorPopupAction(
      title: "Authentication Failed",
      message: "Unable to access user data."
    )
  ]
)
```

### 4. **External Service Access**
```dart
// Access external service
ShowPopupAction(
  title: "External Service",
  message: "This will open an external service. Continue?",
  actions: [
    PopupAction(label: "Continue", action: "continue"),
    PopupAction(label: "Cancel", action: "cancel")
  ]
)

IfAction(
  condition: "popupResult == 'continue'",
  then: [
    GoToLinkAction(
      url: "https://service.example.com",
      openInApp: false,
      target: "_blank"
    )
  ]
)
```

## Best Practices

### 1. **URL Management**
- Always validate URLs before navigation
- Use HTTPS for secure content
- Handle relative and absolute URLs properly
- Consider URL encoding for special characters

### 2. **Target Control**
- Use appropriate target values for different use cases
- Consider user experience when choosing targets
- Handle deep links appropriately
- Provide fallback behavior for unsupported links

### 3. **Security**
- Validate URLs for security
- Be cautious with user-generated URLs
- Consider content security policies
- Handle malicious content gracefully

### 4. **User Experience**
- Provide clear context about external links
- Handle link opening failures gracefully
- Consider user's current context
- Provide alternative navigation options

## Error Handling

### Common Scenarios
1. **Invalid URL**: Malformed or unsupported URL format
2. **Link Unavailable**: Target content no longer available
3. **Network Issues**: Connectivity problems
4. **App Not Found**: Deep link target app not installed

### Best Practices
- Always handle potential errors gracefully
- Provide user-friendly error messages
- Offer alternative content when possible
- Log link navigation attempts for debugging

## Performance Considerations

### Execution Speed
- **Fast Execution**: Action executes quickly
- **Link Opening**: External app/browser launch time
- **Memory Usage**: Minimal memory impact

### Optimization Tips
- Validate URLs before navigation
- Consider link opening frequency
- Handle link failures efficiently
- Cache link validation results when possible

## Debugging

### Common Issues
1. **Link Not Opening**: Check URL validity and permissions
2. **Wrong Target**: Verify target parameter values
3. **Headers Issues**: Check header format and values
4. **Deep Link Failures**: Verify deep link scheme support

### Debug Tips
- Log link navigation attempts
- Verify URL accessibility
- Test with different target values
- Check platform-specific link behavior

## Examples

### Complete Link Management System
```dart
// Comprehensive link management workflow
ShowPopupAction(
  title: "Link Navigation",
  message: "What would you like to do?",
  actions: [
    PopupAction(label: "Open Documentation", action: "docs"),
    PopupAction(label: "Access API", action: "api"),
    PopupAction(label: "Deep Link", action: "deep"),
    PopupAction(label: "External Service", action: "service"),
    PopupAction(label: "Cancel", action: "cancel")
  ]
)

SwitchAction(
  value: "popupResult",
  cases: [
    SwitchCase(
      value: "docs",
      actions: [
        GoToLinkAction(
          url: "https://docs.example.com",
          target: "_blank"
        )
      ]
    ),
    SwitchCase(
      value: "api",
      actions: [
        GoToLinkAction(
          url: "https://api.example.com",
          headers: {
            "Authorization": "Bearer #apiToken"
          }
        )
      ]
    ),
    SwitchCase(
      value: "deep",
      actions: [
        GoToLinkAction(
          url: "myapp://settings/profile",
          openInApp: true
        )
      ]
    ),
    SwitchCase(
      value: "service",
      actions: [
        GoToLinkAction(
          url: "https://service.example.com",
          openInApp: false,
          target: "_blank"
        )
      ]
    )
  ]
)
```

### Smart Link Navigation
```dart
// Intelligent link navigation based on context
ExpressionAction(
  code: """
    let userContext = getUserContext();
    let userRole = getUserRole();
    let deviceType = getDeviceType();
    
    let linkConfig = {};
    
    if (userContext === 'help' && userRole === 'admin') {
      linkConfig.url = 'https://admin.example.com/help';
      linkConfig.target = '_blank';
      linkConfig.openInApp = false;
    } else if (userContext === 'help' && userRole === 'user') {
      linkConfig.url = 'https://user.example.com/help';
      linkConfig.target = '_self';
      linkConfig.openInApp = true;
    } else if (userContext === 'api' && userRole === 'developer') {
      linkConfig.url = 'https://api.example.com/docs';
      linkConfig.target = '_blank';
      linkConfig.openInApp = false;
    } else {
      linkConfig.url = 'https://example.com';
      linkConfig.target = '_blank';
      linkConfig.openInApp = false;
    }
    
    setVariable('linkConfig', linkConfig);
  """
)

GoToLinkAction(
  url: "linkConfig.url",
  target: "linkConfig.target",
  openInApp: "linkConfig.openInApp"
)
```

### Conditional Link Opening
```dart
// Open links based on user permissions and context
ExpressionAction(
  code: """
    let userRole = getUserRole();
    let currentScreen = getCurrentScreen();
    let linkPermissions = getLinkPermissions(userRole);
    
    if (currentScreen === 'admin-panel' && linkPermissions.canAccessAdminLinks) {
      setVariable('targetUrl', 'https://admin.example.com');
      setVariable('canOpenLink', true);
    } else if (currentScreen === 'user-dashboard' && linkPermissions.canAccessUserLinks) {
      setVariable('targetUrl', 'https://user.example.com');
      setVariable('canOpenLink', true);
    } else if (currentScreen === 'public-view' && linkPermissions.canAccessPublicLinks) {
      setVariable('targetUrl', 'https://public.example.com');
      setVariable('canOpenLink', true);
    } else {
      setVariable('canOpenLink', false);
    }
  """
)

IfAction(
  condition: "canOpenLink",
  then: [
    GoToLinkAction(
      url: "targetUrl",
      target: "_blank"
    )
  ],
  else: [
    ShowErrorPopupAction(
      title: "Access Denied",
      message: "You don't have permission to access this link."
    )
  ]
)
```

## Conclusion

`GoToLinkAction` is a powerful tool for managing external navigation and deep linking in your CreateGo applications. It enables seamless integration with web content and external services while maintaining good user experience and security standards.

When used effectively with appropriate target control, security validation, and error handling, it significantly enhances the user experience by providing access to external resources and seamless navigation. Remember to always validate URLs, consider user context, and handle edge cases gracefully for a professional link navigation experience.

The key to successful link management is balancing functionality with user experience, providing appropriate navigation targets, and ensuring links open reliably across different platforms and contexts.
