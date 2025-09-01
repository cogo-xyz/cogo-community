# Basic Actions Overview - CreateGo

## Introduction

Basic Actions are the fundamental building blocks of CreateGo's automation system. They provide essential functionality for creating interactive applications, handling user interactions, managing data, and controlling application flow. These actions are designed to be simple, reliable, and easy to use while offering powerful capabilities for building complex workflows.

## What Are Basic Actions?

Basic Actions are predefined, built-in operations that can be executed within Action Flows. They represent common tasks that applications need to perform, such as:

- **Navigation and UI Control**: Moving between screens, showing popups, opening drawers
- **Data Operations**: Making API calls, database operations, file handling
- **Device Integration**: Calendar access, language management
- **Flow Control**: Starting/stopping flows, conditional logic, loops
- **User Feedback**: Displaying messages, loading states, error handling

## Categories of Basic Actions

### 1. **Flow Control Actions**
- **CallFlowAction** (`callFlow`): Executes another action flow or action
- **StopFlowAction** (`stopFlow`): Terminates the current action flow execution

### 2. **Navigation & UI Actions**
- **NavigationAction** (`navigate`): Navigate between screens and routes
- **ScrollToPositionAction** (`scrollTo`): Control scroll position in scrollable views
- **GoToLinkAction** (`goToLink`): Open external links or URLs
- **ShowPopupAction** (`showPopup`): Display informational popups to users
- **ShowErrorPopupAction** (`showErrorPopup`): Show error-specific popup messages
- **ShowLoadingDialogAction** (`showLoading`): Display loading states during operations
- **OpenDrawerAction** (`openDrawer`): Open navigation drawers or side panels
- **CloseDrawerAction** (`closeDrawer`): Close open drawers or side panels
- **OpenBottomSheetAction** (`openBottomSheet`): Open bottom sheet panels
- **CloseBottomSheetAction** (`closeBottomSheet`): Close bottom sheet panels

### 3. **Device & System Integration Actions**
- **OpenCalendarAction** (`openCalendar`): Access device calendar functionality
- **SelectLanguageAction** (`selectLanguage`): Present language selection interface
- **SetLanguageAction** (`setLanguage`): Set application language directly
- **ShowWebInPopupAction** (`showWebInPopup`): Display web content in popup windows

### 4. **Data & API Actions** (Callback Actions)
- **RestfulDataAction** (`restApi`): Make REST API calls to external services
- **SqliteDataAction** (`sqliteApi`): Execute SQLite database operations

## How Basic Actions Work

### Execution Flow
1. **Trigger**: Actions are triggered by events, user interactions, or other actions
2. **Parameter Validation**: Input parameters are validated before execution
3. **Execution**: The action performs its intended operation
4. **Result Handling**: Success/failure results are processed
5. **Flow Continuation**: The action flow continues to the next step

### Parameter System
Each basic action accepts specific parameters that define its behavior:
- **Required Parameters**: Must be provided for the action to work
- **Optional Parameters**: Enhance functionality but aren't essential
- **Dynamic Values**: Can use expressions, variables, or static values

### Error Handling
Basic actions include built-in error handling:
- **Validation Errors**: Parameter validation failures
- **Execution Errors**: Runtime operation failures
- **System Errors**: Device/permission related issues
- **Graceful Degradation**: Fallback behavior when possible

## Integration with Action Flows

### Sequential Execution
Basic actions execute in sequence within action flows, allowing you to:
- Chain multiple actions together
- Pass data between actions
- Create complex workflows from simple building blocks

### Conditional Logic
Actions can be combined with conditional logic:
- Execute actions based on conditions
- Skip actions when not needed
- Create branching workflows

### Data Flow
Actions can share data through:
- **Variables**: Store and retrieve values
- **Context**: Pass data between actions
- **Return Values**: Use action results in subsequent steps

## Best Practices

### 1. **Action Selection**
- Choose the most specific action for your needs
- Avoid complex workarounds when a simple action exists
- Consider performance implications for frequently used actions

### 2. **Parameter Management**
- Use meaningful parameter names
- Validate input data before passing to actions
- Leverage expressions for dynamic values

### 3. **Error Handling**
- Always handle potential errors
- Provide user-friendly error messages
- Implement fallback behaviors when possible

### 4. **Performance Optimization**
- Minimize unnecessary action executions
- Cache results when appropriate
- Use async actions for long-running operations

## Common Use Cases

### User Onboarding
```dart
// Example: Welcome flow
ShowPopupAction(message: "Welcome!", title: "Let's get started")
→ NavigationAction(routePath: "/onboarding")
→ OpenDrawerAction() // Show navigation options
```

### Data Entry Workflow
```dart
// Example: Form submission
ShowLoadingDialogAction(isShowing: true)
→ RestfulDataAction(method: "POST", baseUrl: "/api/save", body: formData)
→ ShowPopupAction(title: "Success", message: "Data saved!")
→ NavigationAction(routePath: "/dashboard")
```

### Device Integration
```dart
// Example: Calendar integration
OpenCalendarAction(initialValue: "2024-12-25", saveTo: "selectedDate")
→ ShowPopupAction(title: "Date Selected", message: "Date saved successfully!")
```

## Advanced Features

### Customization
Basic actions support customization through:
- **Theming**: Consistent with app design
- **Localization**: Multi-language support
- **Accessibility**: Screen reader and navigation support

### Extensibility
While basic actions are predefined, they can be extended through:
- **Parameter Expressions**: Dynamic value calculation
- **Action Combinations**: Multiple actions working together
- **Custom Logic**: Pre and post-action processing

## Troubleshooting

### Common Issues
1. **Permission Denied**: Device features require proper permissions
2. **Parameter Errors**: Invalid or missing required parameters
3. **Network Issues**: API actions may fail due to connectivity
4. **Device Limitations**: Some actions may not work on all devices

### Debugging Tips
- Check action parameters and values
- Verify device permissions
- Test on different devices/platforms
- Review action flow execution logs

## Conclusion

Basic Actions form the foundation of CreateGo's automation capabilities. They provide a comprehensive set of tools for building interactive applications, handling user interactions, and managing application flow. By understanding how these actions work and how to combine them effectively, developers can create powerful, user-friendly applications that leverage the full potential of the CreateGo platform.

The implemented basic actions cover the most common use cases while maintaining simplicity and reliability. Whether you're building a simple form or a complex workflow, these actions provide the building blocks you need to create engaging user experiences.
