# SetLanguageAction - CreateGo

## Overview

The `SetLanguageAction` is a localization action that allows you to programmatically change the application's language setting. It provides a way to dynamically switch between different language options, update user preferences, and maintain language consistency across the application through the global SymbolStore.

## Purpose

- **Language Switching**: Change app language dynamically during runtime
- **User Preferences**: Update and persist user language choices
- **Localization Control**: Manage app localization programmatically
- **Multi-language Support**: Enable seamless language transitions
- **User Experience**: Provide localized content based on user choice

## Action ID

```dart
SetLanguageAction.id  // 'setLanguage'
```

## Parameters

### Required Parameters
- **`language`** (String): The language code to set for the application
  - Must be a valid ISO 639-1 language code (e.g., "en", "es", "fr", "de")
  - Examples: "en" (English), "es" (Spanish), "fr" (French), "de" (German)
  - Should match supported languages in your app configuration
  - Invalid language codes may result in fallback to default language

## Usage

### Basic Usage
```dart
// Set language to English
SetLanguageAction(language: "en")
```

### Set Spanish Language
```dart
// Set language to Spanish
SetLanguageAction(language: "es")
```

### Dynamic Language Setting
```dart
// Set language based on variable
SetLanguageAction(language: "#userPreferredLanguage")
```

### Language from User Selection
```dart
// Set language from user choice
IfAction(
  condition: "userLanguageChoice == 'french'",
  then: [
    SetLanguageAction(language: "fr")
  ],
  else: [
    SetLanguageAction(language: "en")
  ]
)
```

## Integration with Action Flows

### Language Management Patterns
- **User Preference**: Set language based on user selection
- **System Default**: Set language to system default
- **Dynamic Switching**: Change language during app usage
- **Preference Persistence**: Save language choice for future sessions
- **Context Awareness**: Set language based on user context

### Flow Control
- **Language Initialization**: Set initial language when app starts
- **User Choice Handling**: Process user language preferences
- **Dynamic Updates**: Update language during app usage
- **Error Recovery**: Handle invalid language codes gracefully

### Language Setting Behavior
When executed:
- **Language Validation**: Validates the provided language code
- **SymbolStore Update**: Updates the global language variable
- **App Localization**: Triggers app-wide language change
- **Persistence**: Language choice is saved for future sessions
- **Fallback Handling**: Falls back to default language if invalid

## Common Use Cases

### 1. **User Language Preference**
```dart
// Set language based on user preference
ShowPopupAction(
  title: "Language Selection",
  message: "Choose your preferred language:",
  actions: [
    PopupAction(label: "English", action: "en"),
    PopupAction(label: "Español", action: "es"),
    PopupAction(label: "Français", action: "fr"),
    PopupAction(label: "Deutsch", action: "de")
  ]
)

SwitchAction(
  value: "popupResult",
  cases: [
    SwitchCase(
      value: "en",
      actions: [
        SetLanguageAction(language: "en"),
        ShowPopupAction(
          title: "Language Changed",
          message: "Language set to English"
        )
      ]
    ),
    SwitchCase(
      value: "es",
      actions: [
        SetLanguageAction(language: "es"),
        ShowPopupAction(
          title: "Idioma Cambiado",
          message: "Idioma establecido en Español"
        )
      ]
    ),
    SwitchCase(
      value: "fr",
      actions: [
        SetLanguageAction(language: "fr"),
        ShowPopupAction(
          title: "Langue Changée",
          message: "Langue définie en Français"
        )
      ]
    ),
    SwitchCase(
      value: "de",
      actions: [
        SetLanguageAction(language: "de"),
        ShowPopupAction(
          title: "Sprache Geändert",
          message: "Sprache auf Deutsch eingestellt"
        )
      ]
    )
  ]
)
```

### 2. **System Language Detection**
```dart
// Set language based on system locale
ExpressionAction(
  code: """
    let systemLanguage = getSystemLanguage();
    let supportedLanguages = ['en', 'es', 'fr', 'de'];
    
    if (supportedLanguages.includes(systemLanguage)) {
      setVariable('targetLanguage', systemLanguage);
    } else {
      setVariable('targetLanguage', 'en'); // Default fallback
    }
  """
)

SetLanguageAction(language: "#targetLanguage")
```

### 3. **Language from Settings**
```dart
// Set language from stored user settings
TryAction(
  actions: [
    // Get user's saved language preference
    GetUserPreferenceAction(preference: "language")
  ],
  then: [
    // Set language to saved preference
    SetLanguageAction(language: "#userPreference"),
    ShowPopupAction(
      title: "Language Restored",
      message: "Your language preference has been restored."
    )
  ],
  catch: [
    // Fallback to default language
    SetLanguageAction(language: "en"),
    ShowPopupAction(
      title: "Default Language",
      message: "Using default language (English)."
    )
  ]
)
```

### 4. **Conditional Language Setting**
```dart
// Set language based on user role and context
ExpressionAction(
  code: """
    let userRole = getUserRole();
    let currentRegion = getCurrentRegion();
    let languageConfig = {};
    
    if (userRole === 'admin') {
      if (currentRegion === 'europe') {
        languageConfig.language = 'de';
        languageConfig.message = 'Admin language set to German for European region.';
      } else {
        languageConfig.language = 'en';
        languageConfig.message = 'Admin language set to English.';
      }
    } else if (userRole === 'user') {
      if (currentRegion === 'latin_america') {
        languageConfig.language = 'es';
        languageConfig.message = 'User language set to Spanish for Latin American region.';
      } else {
        languageConfig.language = 'en';
        languageConfig.message = 'User language set to English.';
      }
    } else {
      languageConfig.language = 'en';
      languageConfig.message = 'Default language set to English.';
    }
    
    setVariable('languageConfig', languageConfig);
  """
)

SetLanguageAction(language: "#languageConfig.language")

ShowPopupAction(
  title: "Language Updated",
  message: "#languageConfig.message"
)
```

## Best Practices

### 1. **Language Code Management**
- Use standard ISO 639-1 language codes
- Validate language codes before setting
- Provide fallback to default language
- Handle unsupported language codes gracefully

### 2. **User Experience**
- Allow users to change language easily
- Remember user language preferences
- Provide clear language selection options
- Handle language changes smoothly

### 3. **Integration**
- Coordinate with other localization systems
- Update UI elements after language change
- Handle dynamic content localization
- Consider cultural and regional differences

### 4. **Error Handling**
- Validate language codes before use
- Provide fallback language options
- Handle unsupported languages gracefully
- Log language change attempts

## Error Handling

### Common Scenarios
1. **Invalid Language Code**: Unsupported or malformed language codes
2. **Language Not Available**: Language not supported by the app
3. **System Limitations**: Platform-specific language restrictions
4. **Localization Issues**: Missing translation resources

### Best Practices
- Always validate language codes
- Provide meaningful error messages
- Offer fallback language options
- Handle edge cases gracefully

## Performance Considerations

### Execution Speed
- **Fast Execution**: Action executes quickly
- **Language Validation**: Minimal overhead for code validation
- **SymbolStore Update**: Fast variable storage update
- **Memory Usage**: Minimal memory impact

### Optimization Tips
- Cache supported language lists
- Validate language codes efficiently
- Minimize language change frequency
- Consider language resource loading

## Debugging

### Common Issues
1. **Language Not Changing**: Check language code validity
2. **Wrong Language**: Verify language code format
3. **UI Not Updating**: Check localization system integration
4. **Preference Not Saved**: Verify SymbolStore integration

### Debug Tips
- Log language change attempts
- Verify language code format
- Check supported language list
- Monitor SymbolStore updates

## Examples

### Complete Language Management System
```dart
// Comprehensive language management workflow
ShowPopupAction(
  title: "Language Settings",
  message: "Configure your language preferences:",
  actions: [
    PopupAction(label: "Auto-detect", action: "auto"),
    PopupAction(label: "Manual Selection", action: "manual"),
    PopupAction(label: "Reset to Default", action: "reset"),
    PopupAction(label: "Cancel", action: "cancel")
  ]
)

SwitchAction(
  value: "popupResult",
  cases: [
    SwitchCase(
      value: "auto",
      actions: [
        // Auto-detect system language
        ExpressionAction(
          code: """
            let systemLanguage = getSystemLanguage();
            let supportedLanguages = ['en', 'es', 'fr', 'de', 'it', 'pt'];
            
            if (supportedLanguages.includes(systemLanguage)) {
              setVariable('detectedLanguage', systemLanguage);
              setVariable('detectionMessage', 'System language detected: ' + systemLanguage);
            } else {
              setVariable('detectedLanguage', 'en');
              setVariable('detectionMessage', 'System language not supported, using English.');
            }
          """
        ),
        SetLanguageAction(language: "#detectedLanguage"),
        ShowPopupAction(
          title: "Language Detected",
          message: "#detectionMessage"
        )
      ]
    ),
    SwitchCase(
      value: "manual",
      actions: [
        // Show manual language selection
        ShowPopupAction(
          title: "Select Language",
          message: "Choose your preferred language:",
          actions: [
            PopupAction(label: "English", action: "en"),
            PopupAction(label: "Español", action: "es"),
            PopupAction(label: "Français", action: "fr"),
            PopupAction(label: "Deutsch", action: "de"),
            PopupAction(label: "Italiano", action: "it"),
            PopupAction(label: "Português", action: "pt")
          ]
        ),
        // Handle language selection
        SwitchAction(
          value: "popupResult",
          cases: [
            SwitchCase(
              value: "en",
              actions: [SetLanguageAction(language: "en")]
            ),
            SwitchCase(
              value: "es",
              actions: [SetLanguageAction(language: "es")]
            ),
            SwitchCase(
              value: "fr",
              actions: [SetLanguageAction(language: "fr")]
            ),
            SwitchCase(
              value: "de",
              actions: [SetLanguageAction(language: "de")]
            ),
            SwitchCase(
              value: "it",
              actions: [SetLanguageAction(language: "it")]
            ),
            SwitchCase(
              value: "pt",
              actions: [SetLanguageAction(language: "pt")]
            )
          ]
        ),
        ShowPopupAction(
          title: "Language Updated",
          message: "Your language preference has been updated."
        )
      ]
    ),
    SwitchCase(
      value: "reset",
      actions: [
        // Reset to default language
        SetLanguageAction(language: "en"),
        ShowPopupAction(
          title: "Language Reset",
          message: "Language has been reset to English (default)."
        )
      ]
    )
  ]
)
```

### Smart Language Detection
```dart
// Intelligent language detection based on multiple factors
ExpressionAction(
  code: """
    let systemLanguage = getSystemLanguage();
    let userRegion = getUserRegion();
    let userPreferences = getUserPreferences();
    let appContext = getAppContext();
    
    let languageDecision = {};
    
    // Priority 1: User's explicit preference
    if (userPreferences.language) {
      languageDecision.language = userPreferences.language;
      languageDecision.reason = 'User preference';
    }
    // Priority 2: Region-based language
    else if (userRegion === 'spain' || userRegion === 'mexico') {
      languageDecision.language = 'es';
      languageDecision.reason = 'Regional preference (Spanish)';
    }
    else if (userRegion === 'france' || userRegion === 'canada') {
      languageDecision.language = 'fr';
      languageDecision.reason = 'Regional preference (French)';
    }
    else if (userRegion === 'germany' || userRegion === 'austria') {
      languageDecision.language = 'de';
      languageDecision.reason = 'Regional preference (German)';
    }
    // Priority 3: System language
    else if (['en', 'es', 'fr', 'de'].includes(systemLanguage)) {
      languageDecision.language = systemLanguage;
      languageDecision.reason = 'System language';
    }
    // Priority 4: Default fallback
    else {
      languageDecision.language = 'en';
      languageDecision.reason = 'Default fallback';
    }
    
    setVariable('languageDecision', languageDecision);
  """
)

SetLanguageAction(language: "#languageDecision.language")

ShowPopupAction(
  title: "Language Set",
  message: "Language set to #languageDecision.language (#languageDecision.reason)"
)
```

### Conditional Language Management
```dart
// Control language based on user permissions and context
ExpressionAction(
  code: """
    let userRole = getUserRole();
    let currentScreen = getCurrentScreen();
    let timeOfDay = getTimeOfDay();
    let languagePermissions = getLanguagePermissions(userRole);
    
    let languageConfig = {};
    
    if (currentScreen === 'admin-panel' && languagePermissions.canUseAdminLanguages) {
      if (timeOfDay === 'business') {
        languageConfig.language = 'en';
        languageConfig.message = 'Admin panel language set to English for business hours.';
      } else {
        languageConfig.language = 'en';
        languageConfig.message = 'Admin panel language set to English for after-hours.';
      }
    } else if (currentScreen === 'user-dashboard' && languagePermissions.canUseUserLanguages) {
      languageConfig.language = '#userPreferredLanguage';
      languageConfig.message = 'User dashboard language set to your preference.';
    } else if (currentScreen === 'public-view' && languagePermissions.canUsePublicLanguages) {
      languageConfig.language = '#systemLanguage';
      languageConfig.message = 'Public view language set to system default.';
    } else {
      languageConfig.language = 'en';
      languageConfig.message = 'Default language set to English.';
    }
    
    setVariable('languageConfig', languageConfig);
  """
)

IfAction(
  condition: "languageConfig.language != '#currentLanguage'",
  then: [
    SetLanguageAction(language: "#languageConfig.language"),
    ShowPopupAction(
      title: "Language Updated",
      message: "#languageConfig.message"
    )
  ],
  else: [
    ShowPopupAction(
      title: "Language Status",
      message: "Language is already set to your preference."
    )
  ]
)
```

## Conclusion

`SetLanguageAction` is a powerful tool for managing application localization in your CreateGo applications. It enables dynamic language switching while maintaining good user experience and performance standards.

When used effectively with proper language validation, user preference handling, and error management, it significantly enhances the user experience by providing localized content and language flexibility. Remember to always validate language codes, handle user preferences appropriately, and provide fallback options for a professional localization experience.

The key to successful language implementation is balancing flexibility with reliability, providing clear language options, and ensuring smooth transitions between different language settings.
