# ShowWebInPopupAction - CreateGo

## Overview

The `ShowWebInPopupAction` is a web content action that displays web pages, URLs, or HTML content within a popup dialog. It provides a way to show web content without navigating away from the current context, enabling users to view external websites, embedded content, or custom HTML while maintaining their current workflow.

## Purpose

- **Web Content Display**: Show web pages and URLs in popup dialogs
- **Content Embedding**: Display external web content within the app
- **User Experience**: Provide web access without losing current context
- **Content Integration**: Embed web-based tools and resources
- **Modal Web Viewing**: Present web content in a controlled popup environment

## Action ID

```dart
ShowWebInPopupAction.id  // 'showWebInPopup'
```

## Parameters

### Required Parameters
- **`url`** (String): The URL or web address to display in the popup
  - Must be a valid URL (e.g., "https://example.com", "http://localhost:3000")
  - Can include query parameters and fragments
  - Should be accessible from the device/network
  - Invalid URLs may result in error display

### Optional Parameters
- **`title`** (String): The title displayed in the popup header
  - Default: Empty string (no title shown)
  - Provides context for the web content
  - Should be descriptive and relevant to the content
  - Useful for identifying the popup content

- **`width`** (double): Custom width for the web popup dialog
  - Default: Auto-sized based on content
  - Can be specified in pixels
  - Useful for controlling popup dimensions
  - Consider screen size when setting custom width

- **`height`** (double): Custom height for the web popup dialog
  - Default: Auto-sized based on content
  - Can be specified in pixels
  - Useful for controlling popup dimensions
  - Consider screen size when setting custom height

## Usage

### Basic Usage
```dart
// Show a website in popup
ShowWebInPopupAction(url: "https://example.com")
```

### With Custom Title
```dart
// Show website with custom title
ShowWebInPopupAction(
  url: "https://docs.example.com",
  title: "Documentation"
)
```

### With Custom Dimensions
```dart
// Show website with custom size
ShowWebInPopupAction(
  url: "https://dashboard.example.com",
  title: "Analytics Dashboard",
  width: 800.0,
  height: 600.0
)
```

### Dynamic URL
```dart
// Show website based on variable
ShowWebInPopupAction(
  url: "#targetWebsite",
  title: "#websiteTitle"
)
```

## Integration with Action Flows

### Web Content Patterns
- **External Resources**: Display external websites and tools
- **Documentation**: Show help and documentation pages
- **Embedded Tools**: Present web-based applications
- **Content Preview**: Show web content previews
- **Resource Access**: Provide access to web resources

### Flow Control
- **Content Display**: Show web content at appropriate times
- **User Interaction**: Handle web content interactions
- **Error Handling**: Manage web loading failures
- **Context Management**: Maintain app context during web viewing

### Web Popup Behavior
When executed:
- **URL Validation**: Validates the provided URL format
- **Popup Creation**: Creates a popup dialog with web content
- **Content Loading**: Loads the specified web content
- **User Interaction**: Allows users to interact with web content
- **Context Preservation**: Maintains current app state and context

## Common Use Cases

### 1. **Documentation Display**
```dart
// Show documentation in popup
ShowPopupAction(
  title: "Help Options",
  message: "What would you like to view?",
  actions: [
    PopupAction(label: "User Guide", action: "guide"),
    PopupAction(label: "API Docs", action: "api"),
    PopupAction(label: "Examples", action: "examples"),
    PopupAction(label: "Cancel", action: "cancel")
  ]
)

SwitchAction(
  value: "popupResult",
  cases: [
    SwitchCase(
      value: "guide",
      actions: [
        ShowWebInPopupAction(
          url: "https://docs.example.com/user-guide",
          title: "User Guide",
          width: 900.0,
          height: 700.0
        )
      ]
    ),
    SwitchCase(
      value: "api",
      actions: [
        ShowWebInPopupAction(
          url: "https://docs.example.com/api-reference",
          title: "API Documentation",
          width: 1000.0,
          height: 800.0
        )
      ]
    ),
    SwitchCase(
      value: "examples",
      actions: [
        ShowWebInPopupAction(
          url: "https://docs.example.com/examples",
          title: "Code Examples",
          width: 800.0,
          height: 600.0
        )
      ]
    )
  ]
)
```

### 2. **External Tool Integration**
```dart
// Show external tool in popup
ShowPopupAction(
  title: "External Tools",
  message: "Select a tool to open:",
  actions: [
    PopupAction(label: "Calculator", action: "calculator"),
    PopupAction(label: "Notepad", action: "notepad"),
    PopupAction(label: "Calendar", action: "calendar"),
    PopupAction(label: "Cancel", action: "cancel")
  ]
)

SwitchAction(
  value: "popupResult",
  cases: [
    SwitchCase(
      value: "calculator",
      actions: [
        ShowWebInPopupAction(
          url: "https://calculator.example.com",
          title: "Online Calculator",
          width: 400.0,
          height: 500.0
        )
      ]
    ),
    SwitchCase(
      value: "notepad",
      actions: [
        ShowWebInPopupAction(
          url: "https://notepad.example.com",
          title: "Online Notepad",
          width: 600.0,
          height: 500.0
        )
      ]
    ),
    SwitchCase(
      value: "calendar",
      actions: [
        ShowWebInPopupAction(
          url: "https://calendar.example.com",
          title: "Online Calendar",
          width: 800.0,
          height: 600.0
        )
      ]
    ),
    SwitchCase(
      value: "convert",
      actions: [
        ShowWebInPopupAction(
          url: "https://converter.example.com",
          title: "Unit Converter",
          width: 500.0,
          height: 400.0
        )
      ]
    )
  ]
)
```

### 3. **Content Preview**
```dart
// Show web content preview
ShowPopupAction(
  title: "Content Preview",
  message: "Would you like to preview this content?",
  actions: [
    PopupAction(label: "Preview", action: "preview"),
    PopupAction(label: "Skip", action: "skip")
  ]
)

IfAction(
  condition: "popupResult == 'preview'",
  then: [
    ShowWebInPopupAction(
      url: "#contentPreviewUrl",
      title: "Content Preview",
      width: 700.0,
      height: 500.0
    )
  ]
)
```

### 4. **Resource Access**
```dart
// Show web resource in popup
TryAction(
  actions: [
    // Check if resource is available
    CheckResourceAvailabilityAction(resourceUrl: "#resourceUrl")
  ],
  then: [
    // Show resource in popup
    ShowWebInPopupAction(
      url: "#resourceUrl",
      title: "#resourceTitle",
      width: "#resourceWidth",
      height: "#resourceHeight"
    )
  ],
  catch: [
    // Show error if resource unavailable
    ShowErrorPopupAction(
      title: "Resource Unavailable",
      message: "The requested web resource is not available."
    )
  ]
)
```

## Best Practices

### 1. **URL Management**
- Always validate URLs before displaying
- Use HTTPS URLs when possible for security
- Handle invalid or inaccessible URLs gracefully
- Consider URL accessibility and permissions

### 2. **User Experience**
- Provide meaningful titles for web content
- Use appropriate popup dimensions for content
- Consider screen size and device capabilities
- Handle web content loading states

### 3. **Content Integration**
- Ensure web content is relevant to user context
- Handle web content interactions appropriately
- Consider content security and permissions
- Provide fallback options for web content

### 4. **Error Handling**
- Handle web content loading failures
- Provide user-friendly error messages
- Offer alternative content options
- Log web content access attempts

## Error Handling

### Common Scenarios
1. **Invalid URL**: Malformed or unsupported URL format
2. **Network Issues**: Connection problems or timeouts
3. **Content Unavailable**: Web content not accessible
4. **Permission Denied**: Access restrictions to web content
5. **Content Loading Failed**: Web page fails to load

### Best Practices
- Always validate URLs before use
- Handle network failures gracefully
- Provide meaningful error messages
- Offer alternative content options

## Performance Considerations

### Execution Speed
- **Fast Execution**: Action executes quickly
- **Web Content Loading**: Depends on web content size and network
- **Popup Creation**: Minimal overhead for dialog creation
- **Memory Usage**: Varies based on web content complexity

### Optimization Tips
- Use appropriate popup dimensions
- Consider web content loading time
- Cache frequently accessed web content
- Optimize web content for mobile devices

## Debugging

### Common Issues
1. **Web Content Not Loading**: Check URL validity and accessibility
2. **Popup Not Displaying**: Verify popup parameters and context
3. **Content Display Issues**: Check web content compatibility
4. **Network Problems**: Verify network connectivity and permissions

### Debug Tips
- Log web content access attempts
- Verify URL format and accessibility
- Test with different web content types
- Monitor network connectivity

## Examples

### Complete Web Content Management System
```dart
// Comprehensive web content management workflow
ShowPopupAction(
  title: "Web Content Manager",
  message: "What type of web content would you like to view?",
  actions: [
    PopupAction(label: "Documentation", action: "docs"),
    PopupAction(label: "Tools", action: "tools"),
    PopupAction(label: "Resources", action: "resources"),
    PopupAction(label: "Custom URL", action: "custom"),
    PopupAction(label: "Cancel", action: "cancel")
  ]
)

SwitchAction(
  value: "popupResult",
  cases: [
    SwitchCase(
      value: "docs",
      actions: [
        // Show documentation options
        ShowPopupAction(
          title: "Documentation",
          message: "Select documentation to view:",
          actions: [
            PopupAction(label: "Getting Started", action: "getting-started"),
            PopupAction(label: "User Manual", action: "user-manual"),
            PopupAction(label: "API Reference", action: "api-ref"),
            PopupAction(label: "Tutorials", action: "tutorials")
          ]
        ),
        // Handle documentation selection
        SwitchAction(
          value: "popupResult",
          cases: [
            SwitchCase(
              value: "getting-started",
              actions: [
                ShowWebInPopupAction(
                  url: "https://docs.example.com/getting-started",
                  title: "Getting Started Guide",
                  width: 900.0,
                  height: 700.0
                )
              ]
            ),
            SwitchCase(
              value: "user-manual",
              actions: [
                ShowWebInPopupAction(
                  url: "https://docs.example.com/user-manual",
                  title: "User Manual",
                  width: 1000.0,
                  height: 800.0
                )
              ]
            ),
            SwitchCase(
              value: "api-ref",
              actions: [
                ShowWebInPopupAction(
                  url: "https://docs.example.com/api-reference",
                  title: "API Reference",
                  width: 1100.0,
                  height: 800.0
                )
              ]
            ),
            SwitchCase(
              value: "tutorials",
              actions: [
                ShowWebInPopupAction(
                  url: "https://docs.example.com/tutorials",
                  title: "Tutorials",
                  width: 900.0,
                  height: 700.0
                )
              ]
            )
          ]
        )
      ]
    ),
    SwitchCase(
      value: "tools",
      actions: [
        // Show tool options
        ShowPopupAction(
          title: "Online Tools",
          message: "Select a tool to open:",
          actions: [
            PopupAction(label: "Calculator", action: "calc"),
            PopupAction(label: "Notepad", action: "note"),
            PopupAction(label: "Calendar", action: "cal"),
            PopupAction(label: "Converter", action: "convert")
          ]
        ),
        // Handle tool selection
        SwitchAction(
          value: "popupResult",
          cases: [
            SwitchCase(
              value: "calc",
              actions: [
                ShowWebInPopupAction(
                  url: "https://calculator.example.com",
                  title: "Online Calculator",
                  width: 400.0,
                  height: 500.0
                )
              ]
            ),
            SwitchCase(
              value: "note",
              actions: [
                ShowWebInPopupAction(
                  url: "https://notepad.example.com",
                  title: "Online Notepad",
                  width: 600.0,
                  height: 500.0
                )
              ]
            ),
            SwitchCase(
              value: "cal",
              actions: [
                ShowWebInPopupAction(
                  url: "https://calendar.example.com",
                  title: "Online Calendar",
                  width: 800.0,
                  height: 600.0
                )
              ]
            ),
            SwitchCase(
              value: "convert",
              actions: [
                ShowWebInPopupAction(
                  url: "https://converter.example.com",
                  title: "Unit Converter",
                  width: 500.0,
                  height: 400.0
                )
              ]
            )
          ]
        )
      ]
    ),
    SwitchCase(
      value: "resources",
      actions: [
        // Show resource options
        ShowPopupAction(
          title: "Web Resources",
          message: "Select a resource to view:",
          actions: [
            PopupAction(label: "News", action: "news"),
            PopupAction(label: "Weather", action: "weather"),
            PopupAction(label: "Maps", action: "maps"),
            PopupAction(label: "Search", action: "search")
          ]
        ),
        // Handle resource selection
        SwitchAction(
          value: "popupResult",
          cases: [
            SwitchCase(
              value: "news",
              actions: [
                ShowWebInPopupAction(
                  url: "https://news.example.com",
                  title: "Latest News",
                  width: 900.0,
                  height: 700.0
                )
              ]
            ),
            SwitchCase(
              value: "weather",
              actions: [
                ShowWebInPopupAction(
                  url: "https://weather.example.com",
                  title: "Weather Information",
                  width: 600.0,
                  height: 500.0
                )
              ]
            ),
            SwitchCase(
              value: "maps",
              actions: [
                ShowWebInPopupAction(
                  url: "https://maps.example.com",
                  title: "Interactive Maps",
                  width: 1000.0,
                  height: 700.0
                )
              ]
            ),
            SwitchCase(
              value: "search",
              actions: [
                ShowWebInPopupAction(
                  url: "https://search.example.com",
                  title: "Web Search",
                  width: 800.0,
                  height: 600.0
                )
              ]
            )
          ]
        )
      ]
    ),
    SwitchCase(
      value: "custom",
      actions: [
        // Get custom URL from user
        ShowPopupAction(
          title: "Custom URL",
          message: "Enter the URL you want to view:",
          actions: [
            PopupAction(label: "Enter URL", action: "enter"),
            PopupAction(label: "Cancel", action: "cancel")
          ]
        ),
        // Handle custom URL input
        IfAction(
          condition: "popupResult == 'enter'",
          then: [
            // Get URL input from user (this would need a custom input action)
            GetUserInputAction(
              prompt: "Enter URL:",
              placeholder: "https://example.com"
            ),
            // Show custom URL in popup
            ShowWebInPopupAction(
              url: "#userInput",
              title: "Custom Web Content",
              width: 800.0,
              height: 600.0
            )
          ]
        )
      ]
    )
  ]
)
```

### Smart Web Content Management
```dart
// Intelligent web content display based on context
ExpressionAction(
  code: """
    let userContext = getUserContext();
    let currentScreen = getCurrentScreen();
    let userPreferences = getUserPreferences();
    let webContentConfig = {};
    
    if (userContext === 'learning' && currentScreen === 'tutorial') {
      webContentConfig.url = 'https://docs.example.com/tutorials';
      webContentConfig.title = 'Tutorial Documentation';
      webContentConfig.width = 900;
      webContentConfig.height = 700;
    } else if (userContext === 'development' && currentScreen === 'code-editor') {
      webContentConfig.url = 'https://docs.example.com/api-reference';
      webContentConfig.title = 'API Reference';
      webContentConfig.width = 1000;
      webContentConfig.height = 800;
    } else if (userContext === 'support' && currentScreen === 'help') {
      webContentConfig.url = 'https://support.example.com';
      webContentConfig.title = 'Support Center';
      webContentConfig.width = 800;
      webContentConfig.height = 600;
    } else if (userPreferences.favoriteWebResource) {
      webContentConfig.url = userPreferences.favoriteWebResource;
      webContentConfig.title = 'Your Favorite Resource';
      webContentConfig.width = 800;
      webContentConfig.height = 600;
    } else {
      webContentConfig.url = 'https://docs.example.com';
      webContentConfig.title = 'Documentation';
      webContentConfig.width = 900;
      webContentConfig.height = 700;
    }
    
    setVariable('webContentConfig', webContentConfig);
  """
)

ShowWebInPopupAction(
  url: "#webContentConfig.url",
  title: "#webContentConfig.title",
  width: "#webContentConfig.width",
  height: "#webContentConfig.height"
)
```

### Conditional Web Content Display
```dart
// Control web content display based on user permissions and context
ExpressionAction(
  code: """
    let userRole = getUserRole();
    let currentScreen = getCurrentScreen();
    let webContentPermissions = getWebContentPermissions(userRole);
    let canShowWebContent = false;
    let webContentConfig = {};
    
    if (currentScreen === 'admin-panel' && webContentPermissions.canAccessAdminWebContent) {
      canShowWebContent = true;
      webContentConfig.url = 'https://admin.example.com/dashboard';
      webContentConfig.title = 'Admin Dashboard';
      webContentConfig.width = 1000;
      webContentConfig.height = 800;
    } else if (currentScreen === 'user-dashboard' && webContentPermissions.canAccessUserWebContent) {
      canShowWebContent = true;
      webContentConfig.url = 'https://user.example.com/tools';
      webContentConfig.title = 'User Tools';
      webContentConfig.width = 800;
      webContentConfig.height = 600;
    } else if (currentScreen === 'public-view' && webContentPermissions.canAccessPublicWebContent) {
      canShowWebContent = true;
      webContentConfig.url = 'https://public.example.com/info';
      webContentConfig.title = 'Public Information';
      webContentConfig.width = 700;
      webContentConfig.height = 500;
    }
    
    setVariable('canShowWebContent', canShowWebContent);
    setVariable('webContentConfig', webContentConfig);
  """
)

IfAction(
  condition: "canShowWebContent",
  then: [
    ShowWebInPopupAction(
      url: "#webContentConfig.url",
      title: "#webContentConfig.title",
      width: "#webContentConfig.width",
      height: "#webContentConfig.height"
    )
  ],
  else: [
    ShowErrorPopupAction(
      title: "Access Restricted",
      message: "You don't have permission to access web content in this context."
    )
  ]
)
```

## Conclusion

`ShowWebInPopupAction` is a powerful tool for integrating web content into your CreateGo applications. It enables seamless web content display while maintaining good user experience and context preservation.

When used effectively with appropriate URL validation, content management, and error handling, it significantly enhances the user experience by providing access to external web resources without disrupting workflow. Remember to always validate URLs, handle web content appropriately, and provide fallback options for a professional web integration experience.

The key to successful web content integration is balancing functionality with user experience, ensuring content relevance, and maintaining app context during web content viewing.
