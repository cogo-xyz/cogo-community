# Conditional Actions

## Overview

Conditional actions in CreateGo allow action flows to make decisions and execute different paths based on conditions, expressions, and data values. These actions are essential for creating dynamic, intelligent workflows that can adapt to different scenarios and user inputs.

## Available Conditional Actions

### 1. **ConditionalAction** - If/else decision logic
### 2. **SwitchAction** - Multi-branch case selection
### 3. **LoopAction** - Iterative operations with conditions
### 4. **WaitAction** - Conditional waiting and delays

## ConditionalAction

### Purpose
Execute different action sequences based on boolean conditions and expressions.

### Action ID
```dart
ConditionalAction.id
```

### Parameters
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `execute` | `String` | ✅ | Boolean expression to evaluate | `"user.age >= 18"` |
| `isTrue` | `List<Action>` | ❌ | Actions to execute when condition is true | `[BasicAction(...)]` |
| `isFalse` | `List<Action>` | ❌ | Actions to execute when condition is false | `[BasicAction(...)]` |
| `operator` | `String` | ❌ | Comparison operator (default: "==") | `">="` |

### Basic Usage
```dart
ConditionalAction(
  execute: "user.isAuthenticated",
  isTrue: [
    BasicAction(
      actionId: NavigationAction.id,
      params: {"routePath": "/dashboard"}
    )
  ],
  isFalse: [
    BasicAction(
      actionId: NavigationAction.id,
      params: {"routePath": "/login"}
    )
  ]
)
```

### Complex Conditions
```dart
// Multiple conditions with logical operators
ConditionalAction(
  execute: "user.age >= 18 && user.hasValidLicense && user.insuranceStatus == 'active'",
  isTrue: [
    BasicAction(
      actionId: "approve_application",
      params: {"status": "approved"}
    )
  ],
  isFalse: [
    BasicAction(
      actionId: "reject_application",
      params: {"reason": "Requirements not met"}
    )
  ]
)
```

### Nested Conditions
```dart
// Nested conditional logic
ConditionalAction(
  execute: "user.role == 'admin'",
  isTrue: [
    ConditionalAction(
      execute: "user.permissions.includes('delete_users')",
      isTrue: [
        BasicAction(
          actionId: "show_delete_button",
          params: {"visible": true}
        )
      ],
      isFalse: [
        BasicAction(
          actionId: "show_delete_button",
          params: {"visible": false}
        )
      ]
    )
  ],
  isFalse: [
    BasicAction(
      actionId: "show_delete_button",
      params: {"visible": false}
    )
  ]
)
```

## SwitchAction

### Purpose
Execute different action sequences based on multiple possible values (similar to switch/case statements).

### Action ID
```dart
SwitchAction.id
```

### Parameters
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `value` | `String` | ✅ | Value to compare against | `"#userRole"` |
| `cases` | `Map<String, List<Action>>` | ✅ | Case values and corresponding actions | `{"admin": [...], "user": [...]}` |
| `default` | `List<Action>` | ❌ | Default actions when no case matches | `[BasicAction(...)]` |

### Basic Usage
```dart
SwitchAction(
  value: "#userRole",
  cases: {
    "admin": [
      BasicAction(
        actionId: NavigationAction.id,
        params: {"routePath": "/admin/dashboard"}
      )
    ],
    "manager": [
      BasicAction(
        actionId: NavigationAction.id,
        params: {"routePath": "/manager/dashboard"}
      )
    ],
    "user": [
      BasicAction(
        actionId: NavigationAction.id,
        params: {"routePath": "/user/dashboard"}
      )
    ]
  },
  default: [
    BasicAction(
      actionId: NavigationAction.id,
      params: {"routePath": "/unauthorized"}
    )
  ]
)
```

### Dynamic Case Values
```dart
// Use expressions in case values
SwitchAction(
  value: "#orderStatus",
  cases: {
    "#pendingStatus": [
      BasicAction(
        actionId: "show_pending_actions",
        params: {"orderId": "#orderId"}
      )
    ],
    "#processingStatus": [
      BasicAction(
        actionId: "show_processing_info",
        params: {"orderId": "#orderId"}
      )
    ],
    "#completedStatus": [
      BasicAction(
        actionId: "show_completion_summary",
        params: {"orderId": "#orderId"}
      )
    ]
  }
)
```

## LoopAction

### Purpose
Execute actions multiple times based on conditions, counters, or data collections.

### Action ID
```dart
LoopAction.id
```

### Parameters
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `condition` | `String` | ✅ | Loop continuation condition | `"#counter < 10"` |
| `actions` | `List<Action>` | ✅ | Actions to execute in each iteration | `[BasicAction(...)]` |
| `maxIterations` | `int` | ❌ | Maximum number of iterations | `100` |
| `counter` | `String` | ❌ | Variable name for iteration counter | `"loopCounter"` |

### Basic Usage
```dart
LoopAction(
  condition: "#counter < 5",
  counter: "counter",
  actions: [
    BasicAction(
      actionId: "process_item",
      params: {"itemIndex": "#counter"}
    ),
    BasicAction(
      actionId: "increment_counter",
      params: {"counter": "#counter + 1"}
    )
  ]
)
```

### Array Iteration
```dart
// Loop through array items
LoopAction(
  condition: "#currentIndex < #userList.length",
  counter: "currentIndex",
  actions: [
    BasicAction(
      actionId: "process_user",
      params: {
        "user": "#userList[#currentIndex]",
        "index": "#currentIndex"
      }
    ),
    BasicAction(
      actionId: "increment_index",
      params: {"currentIndex": "#currentIndex + 1"}
    )
  ]
)
```

### Conditional Loop Exit
```dart
// Exit loop based on conditions
LoopAction(
  condition: "#shouldContinue && #counter < 100",
  counter: "counter",
  actions: [
    BasicAction(
      actionId: "check_condition",
      params: {"shouldContinue": "#evaluateCondition()"}
    ),
    ConditionalAction(
      execute: "#shouldContinue == false",
      isTrue: [
        BasicAction(
          actionId: "break_loop",
          params: {"reason": "Condition met"}
        )
      ]
    )
  ]
)
```

## WaitAction

### Purpose
Pause action flow execution for a specified duration or until a condition is met.

### Action ID
```dart
WaitAction.id
```

### Parameters
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `duration` | `int` | ❌ | Wait duration in milliseconds | `5000` |
| `until` | `String` | ❌ | Condition to wait for | `"#dataReady == true"` |
| `timeout` | `int` | ❌ | Maximum wait time in milliseconds | `30000` |

### Basic Usage
```dart
// Wait for specific duration
WaitAction(
  duration: 3000,  // Wait 3 seconds
  actions: [
    BasicAction(
      actionId: "show_loading",
      params: {"message": "Processing..."}
    )
  ]
)
```

### Conditional Waiting
```dart
// Wait until condition is met
WaitAction(
  until: "#apiResponse != null",
  timeout: 30000,  // 30 second timeout
  actions: [
    BasicAction(
      actionId: "check_api_status",
      params: {"endpoint": "/api/status"}
    )
  ]
)
```

## Condition Expressions

### Comparison Operators
- **`==`** - Equal to
- **`!=`** - Not equal to
- **`>`** - Greater than
- **`>=`** - Greater than or equal to
- **`<`** - Less than
- **`<=`** - Less than or equal to

### Logical Operators
- **`&&`** - Logical AND
- **`||`** - Logical OR
- **`!`** - Logical NOT

### String Operations
```dart
// String comparisons
ConditionalAction(
  execute: "#userName.startsWith('admin') || #userRole == 'superuser'",
  isTrue: [/* admin actions */],
  isFalse: [/* regular user actions */]
)
```

### Array Operations
```dart
// Array checks
ConditionalAction(
  execute: "#userPermissions.includes('delete') && #userPermissions.length > 0",
  isTrue: [/* delete permission actions */],
  isFalse: [/* no delete permission actions */]
)
```

### Numeric Operations
```dart
// Numeric comparisons
ConditionalAction(
  execute: "#orderTotal >= 100 && #orderTotal <= 1000",
  isTrue: [/* apply discount */],
  isFalse: [/* no discount */]
)
```

## Advanced Conditional Logic

### Function Calls in Conditions
```dart
// Use function results in conditions
ConditionalAction(
  execute: "#isValidEmail(#userEmail) && #isStrongPassword(#userPassword)",
  isTrue: [
    BasicAction(
      actionId: "create_user",
      params: {"email": "#userEmail", "password": "#userPassword"}
    )
  ],
  isFalse: [
    BasicAction(
      actionId: "show_validation_error",
      params: {"message": "Invalid email or weak password"}
    )
  ]
)
```

### Complex Boolean Logic
```dart
// Complex boolean expressions
ConditionalAction(
  execute: """
    (#userAge >= 18 && #userAge <= 65) &&
    (#userIncome >= 50000 || #userCreditScore >= 700) &&
    !#userHasBankruptcy &&
    (#userEmploymentStatus == 'employed' || #userEmploymentStatus == 'self-employed')
  """,
  isTrue: [/* approve loan */],
  isFalse: [/* reject loan */]
)
```

### Pattern Matching
```dart
// Pattern-based conditions
SwitchAction(
  value: "#fileExtension",
  cases: {
    "jpg": [/* handle JPEG */],
    "png": [/* handle PNG */],
    "gif": [/* handle GIF */],
    "pdf": [/* handle PDF */]
  },
  default: [/* handle unknown format */]
)
```

## Error Handling in Conditions

### Safe Condition Evaluation
```dart
// Handle potential null/undefined values
ConditionalAction(
  execute: "#user != null && #user.permissions != null && #user.permissions.includes('admin')",
  isTrue: [/* admin actions */],
  isFalse: [/* fallback actions */]
)
```

### Fallback Conditions
```dart
// Provide fallback logic
ConditionalAction(
  execute: "#primaryCondition",
  isTrue: [/* primary actions */],
  isFalse: [
    ConditionalAction(
      execute: "#secondaryCondition",
      isTrue: [/* secondary actions */],
      isFalse: [/* fallback actions */]
    )
  ]
)
```

## Performance Considerations

### Condition Optimization
```dart
// Optimize condition evaluation order
ConditionalAction(
  execute: "#quickCheck && #expensiveCheck",  // Quick check first
  isTrue: [/* actions */],
  isFalse: [/* actions */]
)
```

### Loop Performance
```dart
// Limit loop iterations
LoopAction(
  condition: "#counter < 1000",  // Reasonable limit
  maxIterations: 1000,
  actions: [/* loop actions */]
)
```

## Best Practices

### 1. **Condition Clarity**
- Use descriptive variable names
- Break complex conditions into smaller parts
- Add comments for complex logic

### 2. **Error Prevention**
- Always handle edge cases
- Provide default/fallback actions
- Validate data before using in conditions

### 3. **Performance**
- Order conditions from fastest to slowest
- Limit loop iterations
- Use appropriate data structures

### 4. **Maintainability**
- Keep conditions simple and readable
- Document complex logic
- Use consistent naming conventions

## Common Patterns

### 1. **User Role-Based Access**
```dart
ConditionalAction(
  execute: "user.role == 'admin'",
  isTrue: [/* admin features */],
  isFalse: [
    ConditionalAction(
      execute: "user.role == 'manager'",
      isTrue: [/* manager features */],
      isFalse: [/* regular user features */]
    )
  ]
)
```

### 2. **Data Validation Flow**
```dart
ActionFlow(
  steps: [
    ConditionalAction(
      execute: "#validateRequiredFields()",
      isTrue: [
        ConditionalAction(
          execute: "#validateDataFormat()",
          isTrue: [/* process data */],
          isFalse: [/* show format error */]
        )
      ],
      isFalse: [/* show required field error */]
    )
  ]
)
```

### 3. **Retry Logic**
```dart
LoopAction(
  condition: "#attempts < 3 && #success == false",
  counter: "attempts",
  actions: [
    BasicAction(
      actionId: "try_operation",
      params: {"attempt": "#attempts"}
    ),
    ConditionalAction(
      execute: "#operationResult.success",
      isTrue: [
        BasicAction(
          actionId: "set_success",
          params: {"success": true}
        )
      ]
    )
  ]
)
```

## Related Actions

- **Expression Actions**: For complex condition evaluation
- **Basic Actions**: For actions executed within conditions
- **Loop Actions**: For iterative conditional execution
- **Wait Actions**: For conditional delays

## Summary

Conditional actions are fundamental for creating intelligent, adaptive workflows in CreateGo. They enable:

- **Dynamic decision making** based on data and user input
- **Adaptive workflows** that respond to different scenarios
- **Complex business logic** implementation
- **User experience personalization** based on conditions

Proper use of conditional actions creates powerful, flexible automation systems that can handle various scenarios and user needs.
