# OpenCalendarAction - CreateGo

## Overview

The `OpenCalendarAction` is a device integration action that allows you to programmatically open the device's calendar application or calendar picker. It provides a way to access calendar functionality, schedule events, view dates, and integrate calendar features into your CreateGo applications.

## Purpose

- **Calendar Access**: Open device calendar for date selection and event management
- **Date Picking**: Allow users to select dates for appointments, deadlines, or events
- **Event Scheduling**: Integrate calendar functionality for event creation and management
- **Device Integration**: Leverage native calendar capabilities across platforms
- **User Experience**: Provide seamless calendar access without leaving the app

## Action ID

```dart
OpenCalendarAction.id  // 'openCalendar'
```

## Parameters

### Required Parameters
None - `OpenCalendarAction` doesn't require any parameters to function.

### Optional Parameters
- **`initialValue`** (String): The initially selected date when calendar opens
  - Default: Current date (today)
  - Format: ISO 8601 date string (e.g., "2024-12-25")
  - Can be set to a specific date for context
  - Useful for pre-selecting dates based on user context

- **`saveTo`** (String): Variable name to store the selected date
  - Default: No automatic saving
  - When provided, selected date is automatically saved to the specified variable
  - Uses the global SymbolStore for variable storage
  - Date is saved in "YYYY-MM-DD" format

## Usage

### Basic Usage
```dart
// Open calendar with default settings
OpenCalendarAction()
```

### With Initial Date
```dart
// Open calendar with pre-selected date
OpenCalendarAction(
  initialValue: "2024-12-25"
)
```

### With Date Saving
```dart
// Open calendar and save selected date
OpenCalendarAction(
  initialValue: "2024-12-25",
  saveTo: "selectedDate"
)
```

### Dynamic Initial Date
```dart
// Open calendar with dynamic initial date
OpenCalendarAction(
  initialValue: "#currentDate",
  saveTo: "appointmentDate"
)
```

## Integration with Action Flows

### Calendar Integration Patterns
- **Date Selection**: Allow users to pick dates for events or deadlines
- **Event Scheduling**: Integrate with event creation workflows
- **Reminder Setting**: Use for setting reminder dates and times
- **Date Validation**: Ensure selected dates meet business requirements
- **Multi-step Workflows**: Use in complex scheduling processes

### Flow Control
- **User Input**: Wait for user to select a date
- **Validation**: Check if selected date meets requirements
- **Processing**: Use selected date in subsequent actions
- **Error Handling**: Handle cases where no date is selected

### Date Storage
When `saveTo` parameter is provided:
- Selected date is automatically stored in the global SymbolStore
- Date format is "YYYY-MM-DD" (ISO date format)
- Variable can be accessed using `#variableName` syntax
- If user cancels, variable is set to `null`

## Common Use Cases

### 1. **Event Scheduling**
```dart
// Open calendar for event scheduling
ShowPopupAction(
  title: "Schedule Event",
  message: "When would you like to schedule this event?",
  actions: [
    PopupAction(label: "Pick Date", action: "pick_date"),
    PopupAction(label: "Cancel", action: "cancel")
  ]
)

IfAction(
  condition: "popupResult == 'pick_date'",
  then: [
    OpenCalendarAction(
      initialValue: "#today",
      saveTo: "eventDate"
    )
  ]
)

// Use selected date
IfAction(
  condition: "#eventDate != null",
  then: [
    ShowPopupAction(
      title: "Date Selected",
      message: "Event scheduled for: #eventDate"
    )
  ]
)
```

### 2. **Appointment Booking**
```dart
// Open calendar for appointment booking
TryAction(
  actions: [
    // Check available time slots
    CheckAvailabilityAction(serviceId: selectedService)
  ],
  then: [
    OpenCalendarAction(
      initialValue: "#nextAvailableDate",
      saveTo: "appointmentDate"
    )
  ],
  catch: [
    ShowErrorPopupAction(
      title: "Service Unavailable",
      message: "Unable to check availability. Please try again."
    )
  ]
)
```

### 3. **Deadline Setting**
```dart
// Open calendar for setting project deadlines
ShowPopupAction(
  title: "Set Deadline",
  message: "When should this project be completed?",
  actions: [
    PopupAction(label: "Set Date", action: "set_deadline"),
    PopupAction(label: "Skip", action: "skip")
  ]
)

IfAction(
  condition: "popupResult == 'set_deadline'",
  then: [
    OpenCalendarAction(
      initialValue: "#projectStartDate",
      saveTo: "projectDeadline"
    )
  ]
)
```

### 4. **Date Validation Workflow**
```dart
// Open calendar and validate selected date
OpenCalendarAction(
  initialValue: "#currentDate",
  saveTo: "selectedDate"
)

// Validate selected date
IfAction(
  condition: "#selectedDate != null",
  then: [
    // Check if date is in the future
    IfAction(
      condition: "#selectedDate > #currentDate",
      then: [
        ShowPopupAction(
          title: "Date Valid",
          message: "Selected date: #selectedDate"
        )
      ],
      else: [
        ShowErrorPopupAction(
          title: "Invalid Date",
          message: "Please select a future date."
        )
      ]
    )
  ],
  else: [
    ShowPopupAction(
      title: "No Date Selected",
      message: "Please select a date to continue."
    )
  ]
)
```

## Best Practices

### 1. **Date Format Management**
- Use ISO 8601 format for date strings
- Provide meaningful initial dates based on context
- Handle date parsing errors gracefully
- Consider timezone implications

### 2. **User Experience**
- Use meaningful initial dates based on context
- Provide clear instructions about what the calendar is for
- Handle cases where no date is selected
- Consider user's current date context

### 3. **Integration**
- Validate selected dates before processing
- Handle calendar permission issues gracefully
- Consider platform-specific calendar behavior
- Provide fallback options when calendar is unavailable

### 4. **Variable Management**
- Use descriptive variable names for date storage
- Check if date was selected before using stored value
- Handle null values appropriately
- Consider variable scope and persistence

## Error Handling

### Common Scenarios
1. **Calendar Permission Denied**: User hasn't granted calendar access
2. **No Date Selected**: User cancels calendar without selecting a date
3. **Invalid Date Format**: Initial date string is malformed
4. **Device Calendar Unavailable**: Calendar app not available on device

### Best Practices
- Always handle potential errors gracefully
- Check calendar permissions before opening
- Provide user feedback for calendar operations
- Log calendar actions for debugging

## Performance Considerations

### Execution Speed
- **Fast Execution**: Action executes quickly
- **Calendar Launch**: Native calendar app launch time
- **Memory Usage**: Minimal memory impact

### Optimization Tips
- Limit calendar opening frequency
- Use appropriate initial dates
- Consider device performance
- Cache calendar states when possible

## Debugging

### Common Issues
1. **Calendar Not Opening**: Check calendar permissions
2. **Wrong Initial Date**: Verify initialValue format
3. **Date Not Saving**: Check saveTo parameter and SymbolStore
4. **Platform Differences**: Test on different devices

### Debug Tips
- Log calendar opening attempts
- Verify calendar permissions
- Test with different date formats
- Check platform-specific behavior

## Examples

### Complete Event Scheduling Workflow
```dart
// Comprehensive event scheduling workflow
ShowPopupAction(
  title: "Event Scheduling",
  message: "Let's schedule your event. What would you like to do?",
  actions: [
    PopupAction(label: "Pick Date & Time", action: "datetime"),
    PopupAction(label: "Pick Date Only", action: "date"),
    PopupAction(label: "Cancel", action: "cancel")
  ]
)

SwitchAction(
  value: "popupResult",
  cases: [
    SwitchCase(
      value: "datetime",
      actions: [
        OpenCalendarAction(
          initialValue: "#nextWeek",
          saveTo: "eventDate"
        ),
        // Additional time selection logic
        ShowPopupAction(
          title: "Time Selection",
          message: "Date selected: #eventDate. Now pick a time."
        )
      ]
    ),
    SwitchCase(
      value: "date",
      actions: [
        OpenCalendarAction(
          initialValue: "#nextWeek",
          saveTo: "eventDate"
        )
      ]
    ),
    SwitchCase(
      value: "cancel",
      actions: [
        ShowPopupAction(
          title: "Cancelled",
          message: "Event scheduling cancelled."
        )
      ]
    )
  ]
)
```

### Smart Date Selection
```dart
// Intelligent date selection based on context
ExpressionAction(
  code: """
    let currentDate = new Date();
    let eventType = getVariable('eventType');
    let businessHours = getBusinessHours();
    
    let initialDate, saveToVariable;
    
    if (eventType === 'meeting') {
      // For meetings, start from next business day
      initialDate = getNextBusinessDay(currentDate);
      saveToVariable = 'meetingDate';
    } else if (eventType === 'deadline') {
      // For deadlines, start from tomorrow
      initialDate = addDays(currentDate, 1);
      saveToVariable = 'deadlineDate';
    } else if (eventType === 'reminder') {
      // For reminders, start from current time
      initialDate = currentDate;
      saveToVariable = 'reminderDate';
    }
    
    setVariable('initialDate', initialDate);
    setVariable('saveToVariable', saveToVariable);
  """
)

OpenCalendarAction(
  initialValue: "initialDate",
  saveTo: "saveToVariable"
)
```

### Conditional Calendar Opening
```dart
// Open calendar based on user permissions and context
ExpressionAction(
  code: """
    let userRole = getUserRole();
    let currentScreen = getCurrentScreen();
    let calendarPermissions = getCalendarPermissions(userRole);
    
    if (currentScreen === 'event-creation' && calendarPermissions.canScheduleEvents) {
      setVariable('canOpenCalendar', true);
      setVariable('initialDate', getNextBusinessDay(new Date()));
      setVariable('saveToVariable', 'eventDate');
    } else if (currentScreen === 'deadline-setting' && calendarPermissions.canSetDeadlines) {
      setVariable('canOpenCalendar', true);
      setVariable('initialDate', addDays(new Date(), 7));
      setVariable('saveToVariable', 'deadlineDate');
    } else if (currentScreen === 'reminder-setting' && calendarPermissions.canSetReminders) {
      setVariable('canOpenCalendar', true);
      setVariable('initialDate', new Date());
      setVariable('saveToVariable', 'reminderDate');
    } else {
      setVariable('canOpenCalendar', false);
    }
  """
)

IfAction(
  condition: "canOpenCalendar",
  then: [
    OpenCalendarAction(
      initialValue: "initialDate",
      saveTo: "saveToVariable"
    )
  ],
  else: [
    ShowErrorPopupAction(
      title: "Access Denied",
      message: "You don't have permission to access the calendar."
    )
  ]
)
```

## Conclusion

`OpenCalendarAction` is a powerful tool for integrating calendar functionality into your CreateGo applications. It enables seamless access to device calendar capabilities while maintaining good user experience and accessibility standards.

When used effectively with appropriate initial dates, automatic date saving, and error handling, it significantly enhances the user experience by providing intuitive date selection. Remember to always consider user context, provide appropriate date restrictions, and handle edge cases gracefully for a professional calendar experience.

The key to successful calendar integration is balancing functionality with user experience, providing meaningful initial dates, and ensuring the calendar opens with the right context to meet user needs effectively.
