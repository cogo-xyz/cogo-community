# SelectLanguageAction - CreateGo

## Overview

The `SelectLanguageAction` is a localization action that allows users to choose their preferred language from a list of available options. It provides a way to present language selection interfaces, handle user language preferences, and integrate with the app's internationalization system.

## Purpose

- **Language Selection**: Present available languages for user selection
- **Localization Support**: Enable users to choose their preferred language
- **User Experience**: Provide intuitive language switching capabilities
- **Internationalization**: Integrate with multi-language app systems
- **Accessibility**: Support users in their native language

## Action ID

```dart
SelectLanguageAction.id  // 'selectLanguage'
```

## Parameters

### Required Parameters
- **`languages`** (List<String>): List of language codes available for selection
  - Must be provided for the action to work
  - Format: List of ISO 639-1 language codes (e.g., ["en", "es", "fr"])
  - Can be restricted to specific language subsets
  - Default fallback: ["en"] if not provided

## Usage

### Basic Usage
```dart
// Open language selection with default languages
SelectLanguageAction(
  languages: ["en", "es", "fr", "de", "zh", "ja"]
)
```

### With Specific Language List
```dart
// Open language selection with restricted options
SelectLanguageAction(
  languages: ["en", "es", "fr", "de", "it"]
)
```

### Dynamic Language List
```dart
// Use dynamic language list from variables
SelectLanguageAction(
  languages: "#availableLanguages"
)
```

### Minimal Language Options
```dart
// Open language selection with minimal options
SelectLanguageAction(
  languages: ["en", "es"]
)
```

## Integration with Action Flows

### Language Selection Patterns
- **Initial Setup**: Allow users to choose language during first app launch
- **Settings Integration**: Provide language switching in app settings
- **User Preference**: Remember and apply user language choices
- **Dynamic Switching**: Allow language changes during app usage
- **Accessibility**: Support users with different language needs

### Flow Control
- **User Input**: Wait for user to select a language
- **Validation**: Ensure selected language is supported
- **Application**: Apply language change to the app
- **Persistence**: Save language preference for future use

### Language Application
When a language is selected:
- The app language is automatically changed using `SetCurrentLanguage`
- The language preference is stored in the global variable store
- The variable `#_appData.currentLanguage` is updated
- The popup automatically closes after selection

## Common Use Cases

### 1. **First App Launch**
```dart
// Language selection during initial app setup
ShowPopupAction(
  title: "Welcome",
  message: "Please select your preferred language:",
  actions: [
    PopupAction(label: "Choose Language", action: "select_language"),
    PopupAction(label: "Continue in English", action: "continue_english")
  ]
)

IfAction(
  condition: "popupResult == 'select_language'",
  then: [
    SelectLanguageAction(
      languages: ["en", "es", "fr", "de", "zh", "ja"]
    )
  ]
)
```

### 2. **Settings Language Change**
```dart
// Language switching in app settings
ShowPopupAction(
  title: "Language Settings",
  message: "What would you like to change?",
  actions: [
    PopupAction(label: "Change Language", action: "change_language"),
    PopupAction(label: "Cancel", action: "cancel")
  ]
)

IfAction(
  condition: "popupResult == 'change_language'",
  then: [
    SelectLanguageAction(
      languages: "#supportedLanguages"
    )
  ]
)
```

### 3. **User Preference Management**
```dart
// Language preference management
TryAction(
  actions: [
    // Get user's current language preference
    GetUserLanguagePreferenceAction()
  ],
  then: [
    SelectLanguageAction(
      languages: "#supportedLanguages"
    )
  ],
  catch: [
    ShowErrorPopupAction(
      title: "Language Error",
      message: "Unable to load language preferences."
    )
  ]
)
```

### 4. **Accessibility Support**
```dart
// Language selection for accessibility
ShowPopupAction(
  title: "Accessibility",
  message: "Would you like to change the app language?",
  actions: [
    PopupAction(label: "Change Language", action: "change"),
    PopupAction(label: "Keep Current", action: "keep")
  ]
)

IfAction(
  condition: "popupResult == 'change'",
  then: [
    SelectLanguageAction(
      languages: ["en", "es", "fr", "de"]
    )
  ]
)
```

## Best Practices

### 1. **Language Presentation**
- Show language names in their native script when possible
- Include country flags for better visual recognition
- Group languages by region or family when appropriate
- Provide clear language descriptions for complex cases

### 2. **User Experience**
- Pre-select the current language for context
- Provide clear instructions about language selection
- Handle language changes gracefully without data loss
- Consider user's location and device language settings

### 3. **Integration**
- Validate selected languages before applying
- Handle unsupported language selections gracefully
- Consider fallback languages when primary choice unavailable
- Test language switching across different app states

### 4. **Accessibility**
- Ensure language selection is screen reader compatible
- Provide keyboard navigation for language options
- Consider users with different language proficiency levels
- Support right-to-left (RTL) languages appropriately

## Error Handling

### Common Scenarios
1. **Unsupported Language**: User selects language not supported by app
2. **Language Loading Failed**: Unable to load language resources
3. **Invalid Language Code**: Malformed or invalid language identifier
4. **Resource Missing**: Language resources not available for selected language

### Best Practices
- Always handle potential errors gracefully
- Provide fallback language options
- Show user-friendly error messages
- Log language selection attempts for debugging

## Performance Considerations

### Execution Speed
- **Fast Execution**: Action executes quickly
- **Language Loading**: Resource loading time for new language
- **Memory Usage**: Minimal memory impact

### Optimization Tips
- Cache language resources when possible
- Lazy load language-specific content
- Consider language switching frequency
- Optimize language resource loading

## Debugging

### Common Issues
1. **Language Not Changing**: Check language resource availability
2. **Wrong Language Displayed**: Verify language code format
3. **Resource Loading Failed**: Check language resource files
4. **Fallback Issues**: Verify fallback language configuration

### Debug Tips
- Log language selection attempts
- Verify language resource availability
- Test with different language combinations
- Check platform-specific language support

## Examples

### Complete Language Setup Workflow
```dart
// Comprehensive language setup workflow
ShowPopupAction(
  title: "Language Setup",
  message: "Let's set up your preferred language:",
  actions: [
    PopupAction(label: "Choose Language", action: "choose"),
    PopupAction(label: "Auto-detect", action: "auto"),
    PopupAction(label: "Skip for now", action: "skip")
  ]
)

SwitchAction(
  value: "popupResult",
  cases: [
    SwitchCase(
      value: "choose",
      actions: [
        SelectLanguageAction(
          languages: ["en", "es", "fr", "de", "zh", "ja", "ko", "ar"]
        )
      ]
    ),
    SwitchCase(
      value: "auto",
      actions: [
        // Auto-detect user's preferred language
        AutoDetectLanguageAction()
      ]
    ),
    SwitchCase(
      value: "skip",
      actions: [
        ShowPopupAction(
          title: "Language Setup Skipped",
          message: "You can change language later in settings."
        )
      ]
    )
  ]
)
```

### Smart Language Selection
```dart
// Intelligent language selection based on context
ExpressionAction(
  code: """
    let userLocation = getUserLocation();
    let deviceLanguage = getDeviceLanguage();
    let userPreferences = getUserPreferences();
    let availableLanguages = getAvailableLanguages();
    
    let suggestedLanguages = [];
    
    // Add device language if supported
    if (availableLanguages.includes(deviceLanguage)) {
      suggestedLanguages.push(deviceLanguage);
    }
    
    // Add location-based language suggestions
    if (userLocation === 'US' && availableLanguages.includes('en')) {
      suggestedLanguages.push('en');
    } else if (userLocation === 'ES' && availableLanguages.includes('es')) {
      suggestedLanguages.push('es');
    } else if (userLocation === 'FR' && availableLanguages.includes('fr')) {
      suggestedLanguages.push('fr');
    }
    
    // Add user's previously selected languages
    if (userPreferences.previousLanguages) {
      userPreferences.previousLanguages.forEach(lang => {
        if (availableLanguages.includes(lang) && !suggestedLanguages.includes(lang)) {
          suggestedLanguages.push(lang);
        }
      });
    }
    
    setVariable('suggestedLanguages', suggestedLanguages);
  """
)

SelectLanguageAction(
  languages: "suggestedLanguages"
)
```

### Conditional Language Selection
```dart
// Language selection based on user permissions and context
ExpressionAction(
  code: """
    let userRole = getUserRole();
    let currentScreen = getCurrentScreen();
    let languagePermissions = getLanguagePermissions(userRole);
    
    if (currentScreen === 'admin-panel' && languagePermissions.canAccessAllLanguages) {
      setVariable('availableLanguages', getAllSupportedLanguages());
    } else if (currentScreen === 'user-settings' && languagePermissions.canChangeLanguage) {
      setVariable('availableLanguages', getUserAccessibleLanguages());
    } else if (currentScreen === 'public-view') {
      setVariable('availableLanguages', getPublicLanguages());
    } else {
      setVariable('availableLanguages', ['en']); // Default to English only
    }
    
    setVariable('canSelectLanguage', availableLanguages.length > 1);
  """
)

IfAction(
  condition: "canSelectLanguage",
  then: [
    SelectLanguageAction(
      languages: "availableLanguages"
    )
  ],
  else: [
    ShowPopupAction(
      title: "Language Restricted",
      message: "Language selection is not available in this context."
    )
  ]
)
```

## Conclusion

`SelectLanguageAction` is a powerful tool for creating inclusive and user-friendly multi-language experiences in your CreateGo applications. It enables seamless language selection while maintaining good user experience and accessibility standards.

When used effectively with appropriate language options, visual enhancements, and error handling, it significantly enhances the user experience by providing intuitive language switching capabilities. Remember to always consider user context, provide meaningful language options, and handle edge cases gracefully for a professional language selection experience.

The key to successful language integration is balancing functionality with user experience, providing clear language options, and ensuring language changes are applied smoothly across the entire application.
