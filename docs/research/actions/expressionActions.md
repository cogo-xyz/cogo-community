# Expression Actions

## Overview

Expression actions in CreateGo allow action flows to execute custom code, perform calculations, manipulate data, and implement complex business logic. These actions provide the flexibility to handle scenarios that require custom programming logic beyond the capabilities of built-in actions.

## Available Expression Actions

### 1. **ExpressionAction** - Execute custom expressions and code
### 2. **FunctionAction** - Call custom functions and methods
### 3. **VariableAction** - Manage variables and data storage
### 4. **TransformAction** - Data transformation and manipulation

## ExpressionAction

### Purpose
Execute custom expressions, calculations, and code logic within action flows.

### Action ID
```dart
ExpressionAction.id
```

### Parameters
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `expression` | `String` | ✅ | Expression or code to execute | `"#a + #b"` |
| `variables` | `Map<String, dynamic>` | ❌ | Variables available in expression | `{"a": 10, "b": 20}` |
| `returnValue` | `bool` | ❌ | Whether to return expression result | `true` |
| `storeResult` | `String` | ❌ | Variable name to store result | `"calculationResult"` |

### Basic Usage
```dart
BasicAction(
  id: "calculate_total",
  label: "Calculate Total",
  actionId: ExpressionAction.id,
  actionType: ActionType.basicAct,
  params: {
    "expression": "#quantity * #unitPrice * (1 - #discountRate)",
    "variables": {
      "quantity": 5,
      "unitPrice": 29.99,
      "discountRate": 0.1
    },
    "storeResult": "totalAmount"
  },
  executionMode: ExecutionMode.asyncMode,
)
```

### Mathematical Expressions
```dart
// Basic arithmetic
BasicAction(
  actionId: ExpressionAction.id,
  params: {
    "expression": "(#baseAmount + #taxAmount) * #exchangeRate",
    "storeResult": "finalAmount"
  }
)

// Complex calculations
BasicAction(
  actionId: ExpressionAction.id,
  params: {
    "expression": "Math.pow(#principal * (1 + #rate), #years)",
    "storeResult": "compoundInterest"
  }
)
```

### String Operations
```dart
// String concatenation and manipulation
BasicAction(
  actionId: ExpressionAction.id,
  params: {
    "expression": "#firstName + ' ' + #lastName + ' (' + #email + ')'",
    "storeResult": "fullUserInfo"
  }
)

// String formatting
BasicAction(
  actionId: ExpressionAction.id,
  params: {
    "expression": "`User ${#userId}: ${#userName} - ${#userRole}`",
    "storeResult": "formattedUserString"
  }
)
```

### Array and Object Operations
```dart
// Array operations
BasicAction(
  actionId: ExpressionAction.id,
  params: {
    "expression": "#userList.filter(user => user.status === 'active').map(user => user.name)",
    "storeResult": "activeUserNames"
  }
)

// Object operations
BasicAction(
  actionId: ExpressionAction.id,
  params: {
    "expression": "{...user, lastLogin: #now, status: 'online'}",
    "storeResult": "updatedUser"
  }
)
```

## FunctionAction

### Purpose
Call custom functions and methods with parameters and handle return values.

### Action ID
```dart
FunctionAction.id
```

### Parameters
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `functionName` | `String` | ✅ | Name of function to call | `"calculateTax"` |
| `parameters` | `List<dynamic>` | ❌ | Function parameters | `[100, 0.08]` |
| `storeResult` | `String` | ❌ | Variable name to store result | `"taxAmount"` |

### Basic Usage
```dart
BasicAction(
  id: "call_custom_function",
  label: "Call Custom Function",
  actionId: FunctionAction.id,
  actionType: ActionType.basicAct,
  params: {
    "functionName": "validateEmail",
    "parameters": ["#userEmail"],
    "storeResult": "isValidEmail"
  },
  executionMode: ExecutionMode.asyncMode,
)
```

### Function with Multiple Parameters
```dart
// Call function with multiple parameters
BasicAction(
  actionId: FunctionAction.id,
  params: {
    "functionName": "calculateShipping",
    "parameters": [
      "#orderWeight",
      "#shippingMethod",
      "#destinationCountry"
    ],
    "storeResult": "shippingCost"
  }
)
```

### Built-in Functions
```dart
// Use built-in utility functions
BasicAction(
  actionId: FunctionAction.id,
  params: {
    "functionName": "formatCurrency",
    "parameters": ["#amount", "#currency"],
    "storeResult": "formattedAmount"
  }
)

// Date and time functions
BasicAction(
  actionId: FunctionAction.id,
  params: {
    "functionName": "addDays",
    "parameters": ["#currentDate", 7],
    "storeResult": "nextWeekDate"
  }
)
```

## VariableAction

### Purpose
Create, modify, and manage variables and data storage within action flows.

### Action ID
```dart
VariableAction.id
```

### Parameters
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `operation` | `String` | ✅ | Variable operation (set, get, delete) | `"set"` |
| `name` | `String` | ✅ | Variable name | `"userCount"` |
| `value` | `dynamic` | ❌ | Variable value | `42` |
| `scope` | `String` | ❌ | Variable scope (local, global) | `"global"` |

### Basic Usage
```dart
BasicAction(
  id: "set_variable",
  label: "Set Variable",
  actionId: VariableAction.id,
  actionType: ActionType.basicAct,
  params: {
    "operation": "set",
    "name": "currentUserId",
    "value": "#userId",
    "scope": "global"
  },
  executionMode: ExecutionMode.asyncMode,
)
```

### Variable Operations
```dart
// Set variable
BasicAction(
  actionId: VariableAction.id,
  params: {
    "operation": "set",
    "name": "counter",
    "value": 0
  }
)

// Get variable
BasicAction(
  actionId: VariableAction.id,
  params: {
    "operation": "get",
    "name": "userPreferences",
    "storeResult": "preferences"
  }
)

// Delete variable
BasicAction(
  actionId: VariableAction.id,
  params: {
    "operation": "delete",
    "name": "temporaryData"
  }
)
```

### Variable Scoping
```dart
// Local variable (flow-scoped)
BasicAction(
  actionId: VariableAction.id,
  params: {
    "operation": "set",
    "name": "flowCounter",
    "value": 1,
    "scope": "local"
  }
)

// Global variable (application-scoped)
BasicAction(
  actionId: VariableAction.id,
  params: {
    "operation": "set",
    "name": "appVersion",
    "value": "1.2.3",
    "scope": "global"
  }
)
```

## TransformAction

### Purpose
Transform and manipulate data structures, formats, and types.

### Action ID
```dart
TransformAction.id
```

### Parameters
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `input` | `dynamic` | ✅ | Input data to transform | `"#rawData"` |
| `transformation` | `String` | ✅ | Transformation logic | `"JSON.parse"` |
| `storeResult` | `String` | ❌ | Variable name to store result | `"transformedData"` |

### Basic Usage
```dart
BasicAction(
  id: "transform_data",
  label: "Transform Data",
  actionId: TransformAction.id,
  actionType: ActionType.basicAct,
  params: {
    "input": "#apiResponse",
    "transformation": "data => data.map(item => ({id: item.id, name: item.name}))",
    "storeResult": "processedData"
  },
  executionMode: ExecutionMode.asyncMode,
)
```

### Data Type Transformations
```dart
// Convert string to number
BasicAction(
  actionId: TransformAction.id,
  params: {
    "input": "#stringNumber",
    "transformation": "parseFloat",
    "storeResult": "numericValue"
  }
)

// Convert to boolean
BasicAction(
  actionId: TransformAction.id,
  params: {
    "input": "#stringValue",
    "transformation": "value => value === 'true' || value === '1'",
    "storeResult": "booleanValue"
  }
)
```

### Data Structure Transformations
```dart
// Transform array structure
BasicAction(
  actionId: TransformAction.id,
  params: {
    "input": "#userList",
    "transformation": "users => users.reduce((acc, user) => {acc[user.id] = user; return acc;}, {})",
    "storeResult": "userMap"
  }
)

// Filter and sort data
BasicAction(
  actionId: TransformAction.id,
  params: {
    "input": "#productList",
    "transformation": "products => products.filter(p => p.price > 50).sort((a, b) => b.price - a.price)",
    "storeResult": "filteredProducts"
  }
)
```

## Expression Language Features

### Supported Data Types
- **Numbers**: `int`, `double`, `decimal`
- **Strings**: `String`, text literals
- **Booleans**: `true`, `false`
- **Arrays**: `List<dynamic>`
- **Objects**: `Map<String, dynamic>`
- **Null**: `null`

### Operators
- **Arithmetic**: `+`, `-`, `*`, `/`, `%`, `**`
- **Comparison**: `==`, `!=`, `>`, `>=`, `<`, `<=`
- **Logical**: `&&`, `||`, `!`
- **Assignment**: `=`, `+=`, `-=`, `*=`, `/=`
- **Bitwise**: `&`, `|`, `^`, `<<`, `>>`

### Built-in Functions
```dart
// Math functions
"Math.abs(-5)"           // Absolute value
"Math.round(3.7)"        // Round to nearest integer
"Math.max(10, 20)"       // Maximum value
"Math.min(10, 20)"       // Minimum value
"Math.pow(2, 3)"         // Power function

// String functions
"#text.length"            // String length
"#text.toUpperCase()"     // Convert to uppercase
"#text.toLowerCase()"     // Convert to lowercase
"#text.substring(0, 5)"   // Extract substring
"#text.includes('search')" // Check if contains

// Array functions
"#array.length"           // Array length
"#array.push('item')"     // Add item to array
"#array.pop()"            // Remove last item
"#array.indexOf('item')"  // Find item index
"#array.join(', ')"       // Join array elements
```

## Advanced Expression Features

### Conditional Expressions
```dart
// Ternary operator
BasicAction(
  actionId: ExpressionAction.id,
  params: {
    "expression": "#userAge >= 18 ? 'adult' : 'minor'",
    "storeResult": "userCategory"
  }
)

// Complex conditional logic
BasicAction(
  actionId: ExpressionAction.id,
  params: {
    "expression": "#userRole === 'admin' ? 'full_access' : #userRole === 'manager' ? 'limited_access' : 'read_only'",
    "storeResult": "accessLevel"
  }
)
```

### Function Definitions
```dart
// Define and use custom functions
BasicAction(
  actionId: ExpressionAction.id,
  params: {
    "expression": """
      const calculateDiscount = (amount, rate) => amount * rate;
      calculateDiscount(#orderTotal, #discountRate)
    """,
    "storeResult": "discountAmount"
  }
)
```

### Error Handling
```dart
// Safe expression evaluation
BasicAction(
  actionId: ExpressionAction.id,
  params: {
    "expression": """
      try {
        return #data / #divisor;
      } catch (error) {
        return 0;
      }
    """,
    "storeResult": "safeResult"
  }
)
```

## Integration with Other Actions

### Using Expression Results
```dart
// Use expression result in subsequent actions
ActionFlow(
  steps: [
    // Calculate value
    BasicAction(
      actionId: ExpressionAction.id,
      params: {
        "expression": "#basePrice * (1 + #taxRate)",
        "storeResult": "totalPrice"
      }
    ),
    
    // Use calculated value
    BasicAction(
      actionId: ShowPopupAction.id,
      params: {
        "title": "Total Price",
        "message": "Your total is: $#totalPrice"
      }
    )
  ]
)
```

### Conditional Execution Based on Expressions
```dart
// Use expression result in conditions
ActionFlow(
  steps: [
    // Evaluate condition
    BasicAction(
      actionId: ExpressionAction.id,
      params: {
        "expression": "#userScore >= 80 && #userAge >= 18",
        "storeResult": "isEligible"
      }
    ),
    
    // Use result in conditional action
    ConditionalAction(
      execute: "#isEligible",
      isTrue: [/* eligible actions */],
      isFalse: [/* not eligible actions */]
    )
  ]
)
```

## Performance Considerations

### Expression Optimization
```dart
// Cache expensive calculations
BasicAction(
  actionId: ExpressionAction.id,
  params: {
    "expression": "#expensiveCalculation",
    "storeResult": "cachedResult"
  }
)

// Use cached result multiple times
BasicAction(
  actionId: ShowPopupAction.id,
  params: {
    "message": "Result: #cachedResult"
  }
)
```

### Memory Management
```dart
// Clean up large variables when done
BasicAction(
  actionId: VariableAction.id,
  params: {
    "operation": "delete",
    "name": "largeDataSet"
  }
)
```

## Security Considerations

### Input Validation
```dart
// Validate input before using in expressions
BasicAction(
  actionId: ExpressionAction.id,
  params: {
    "expression": "#isValidInput(#userInput) ? #processInput(#userInput) : 'Invalid input'",
    "storeResult": "processedResult"
  }
)
```

### Safe Expression Evaluation
```dart
// Use safe evaluation for user-provided expressions
BasicAction(
  actionId: ExpressionAction.id,
  params: {
    "expression": "#sanitizedExpression",
    "safeMode": true,
    "allowedFunctions": ["Math.abs", "Math.round"]
  }
)
```

## Testing and Debugging

### Expression Testing
```dart
// Test expressions with sample data
BasicAction(
  actionId: ExpressionAction.id,
  params: {
    "expression": "#testExpression",
    "variables": {
      "testData": [1, 2, 3, 4, 5],
      "testValue": "sample"
    },
    "testMode": true
  }
)
```

### Debug Information
```dart
// Include debug information in expressions
BasicAction(
  actionId: ExpressionAction.id,
  params: {
    "expression": """
      console.log('Input:', #input);
      const result = #processInput(#input);
      console.log('Output:', result);
      return result;
    """,
    "debug": true
  }
)
```

## Best Practices

### 1. **Expression Clarity**
- Use descriptive variable names
- Break complex expressions into smaller parts
- Add comments for complex logic

### 2. **Error Prevention**
- Validate inputs before using in expressions
- Use safe evaluation modes for user input
- Handle potential errors gracefully

### 3. **Performance**
- Cache expensive calculations
- Avoid complex expressions in loops
- Use appropriate data structures

### 4. **Maintainability**
- Keep expressions simple and readable
- Document complex logic
- Use consistent naming conventions

## Common Patterns

### 1. **Data Processing Pipeline**
```dart
ActionFlow(
  steps: [
    // Extract data
    BasicAction(
      actionId: ExpressionAction.id,
      params: {
        "expression": "#rawData.filter(item => item.status === 'active')",
        "storeResult": "activeItems"
      }
    ),
    
    // Transform data
    BasicAction(
      actionId: TransformAction.id,
      params: {
        "input": "#activeItems",
        "transformation": "items => items.map(item => ({...item, processed: true}))",
        "storeResult": "processedItems"
      }
    ),
    
    // Calculate summary
    BasicAction(
      actionId: ExpressionAction.id,
      params: {
        "expression": "#processedItems.reduce((sum, item) => sum + item.value, 0)",
        "storeResult": "totalValue"
      }
    )
  ]
)
```

### 2. **Conditional Data Processing**
```dart
// Process data based on conditions
BasicAction(
  actionId: ExpressionAction.id,
  params: {
    "expression": """
      #userType === 'premium' ? 
        #data.map(item => ({...item, priority: 'high'})) :
        #data.map(item => ({...item, priority: 'normal'}))
    """,
    "storeResult": "prioritizedData"
  }
)
```

### 3. **Data Aggregation**
```dart
// Aggregate data by category
BasicAction(
  actionId: ExpressionAction.id,
  params: {
    "expression": """
      #orders.reduce((acc, order) => {
        const category = order.category;
        if (!acc[category]) acc[category] = [];
        acc[category].push(order);
        return acc;
      }, {})
    """,
    "storeResult": "ordersByCategory"
  }
)
```

## Related Actions

- **Conditional Actions**: For decision-making based on expression results
- **Database Actions**: For storing and retrieving expression results
- **REST API Actions**: For using expression results in API calls
- **Basic Actions**: For actions that use expression results

## Summary

Expression actions provide powerful programming capabilities within CreateGo action flows. They enable:

- **Custom logic** implementation for complex scenarios
- **Data manipulation** and transformation
- **Dynamic calculations** and computations
- **Flexible workflow** customization

Proper use of expression actions creates sophisticated, intelligent automation systems that can handle complex business logic and data processing requirements.
