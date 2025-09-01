# Database Actions

## Overview

Database actions in CreateGo allow action flows to perform local database operations including CRUD operations, queries, and data management. These actions provide persistent storage capabilities for applications and enable data-driven workflows.

## Available Database Actions

### 1. **InsertAction** - Insert new records
### 2. **SelectAction** - Query existing records
### 3. **UpdateAction** - Modify existing records
### 4. **DeleteAction** - Remove records
### 5. **ExecuteAction** - Run custom SQL statements
### 6. **TransactionAction** - Execute multiple operations atomically

## Common Parameters

All database actions share these common parameters:

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `table` | `String` | ✅ | Database table name | `"users"` |
| `database` | `String` | ❌ | Database name (default: main) | `"app_data"` |
| `timeout` | `int` | ❌ | Query timeout in milliseconds | `5000` |

## InsertAction

### Purpose
Insert new records into database tables.

### Action ID
```dart
InsertAction.id
```

### Parameters
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `table` | `String` | ✅ | Target table name | `"users"` |
| `data` | `Map<String, dynamic>` | ✅ | Data to insert | `{"name": "John", "email": "john@example.com"}` |
| `returnId` | `bool` | ❌ | Return inserted record ID | `true` |

### Basic Usage
```dart
BasicAction(
  id: "create_user",
  label: "Create User",
  actionId: InsertAction.id,
  actionType: ActionType.basicAct,
  params: {
    "table": "users",
    "data": {
      "name": "#userName",
      "email": "#userEmail",
      "role": "#userRole",
      "created_at": "#now"
    },
    "returnId": true
  },
  executionMode: ExecutionMode.asyncMode,
)
```

### Batch Insert
```dart
// Insert multiple records
BasicAction(
  actionId: InsertAction.id,
  params: {
    "table": "products",
    "data": [
      {
        "name": "Product 1",
        "price": 29.99,
        "category": "electronics"
      },
      {
        "name": "Product 2",
        "price": 19.99,
        "category": "clothing"
      }
    ]
  }
)
```

## SelectAction

### Purpose
Query and retrieve data from database tables.

### Action ID
```dart
SelectAction.id
```

### Parameters
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `table` | `String` | ✅ | Source table name | `"users"` |
| `columns` | `List<String>` | ❌ | Columns to select (default: all) | `["id", "name", "email"]` |
| `where` | `Map<String, dynamic>` | ❌ | WHERE conditions | `{"status": "active"}` |
| `orderBy` | `String` | ❌ | ORDER BY clause | `"created_at DESC"` |
| `limit` | `int` | ❌ | Maximum records to return | `100` |
| `offset` | `int` | ❌ | Number of records to skip | `0` |

### Basic Usage
```dart
BasicAction(
  id: "fetch_users",
  label: "Fetch Users",
  actionId: SelectAction.id,
  actionType: ActionType.basicAct,
  params: {
    "table": "users",
    "columns": ["id", "name", "email", "role"],
    "where": {
      "status": "active",
      "role": "#userRole"
    },
    "orderBy": "created_at DESC",
    "limit": 50
  },
  executionMode: ExecutionMode.asyncMode,
)
```

### Complex Queries
```dart
// Advanced query with multiple conditions
BasicAction(
  actionId: SelectAction.id,
  params: {
    "table": "orders",
    "columns": ["id", "total", "status", "created_at"],
    "where": {
      "user_id": "#userId",
      "status": ["pending", "processing"],
      "total": {">": 100}
    },
    "orderBy": "created_at DESC",
    "limit": 20
  }
)
```

### Join Queries
```dart
// Query with table joins
BasicAction(
  actionId: SelectAction.id,
  params: {
    "table": "orders",
    "joins": [
      {
        "table": "users",
        "on": "orders.user_id = users.id",
        "type": "INNER"
      }
    ],
    "columns": [
      "orders.id",
      "orders.total",
      "users.name",
      "users.email"
    ],
    "where": {"orders.status": "completed"}
  }
)
```

## UpdateAction

### Purpose
Modify existing records in database tables.

### Action ID
```dart
UpdateAction.id
```

### Parameters
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `table` | `String` | ✅ | Target table name | `"users"` |
| `data` | `Map<String, dynamic>` | ✅ | Data to update | `{"status": "inactive"}` |
| `where` | `Map<String, dynamic>` | ✅ | WHERE conditions | `{"id": "123"}` |
| `returnAffected` | `bool` | ❌ | Return number of affected rows | `true` |

### Basic Usage
```dart
BasicAction(
  id: "update_user",
  label: "Update User",
  actionId: UpdateAction.id,
  actionType: ActionType.basicAct,
  params: {
    "table": "users",
    "data": {
      "name": "#newUserName",
      "email": "#newUserEmail",
      "updated_at": "#now"
    },
    "where": {
      "id": "#userId"
    },
    "returnAffected": true
  },
  executionMode: ExecutionMode.asyncMode,
)
```

### Conditional Updates
```dart
// Update based on conditions
BasicAction(
  actionId: UpdateAction.id,
  params: {
    "table": "products",
    "data": {
      "price": "#newPrice",
      "updated_at": "#now"
    },
    "where": {
      "category": "#category",
      "status": "active"
    }
  }
)
```

## DeleteAction

### Purpose
Remove records from database tables.

### Action ID
```dart
DeleteAction.id
```

### Parameters
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `table` | `String` | ✅ | Target table name | `"users"` |
| `where` | `Map<String, dynamic>` | ✅ | WHERE conditions | `{"id": "123"}` |
| `returnAffected` | `bool` | ❌ | Return number of affected rows | `true` |

### Basic Usage
```dart
BasicAction(
  id: "delete_user",
  label: "Delete User",
  actionId: DeleteAction.id,
  actionType: ActionType.basicAct,
  params: {
    "table": "users",
    "where": {
      "id": "#userId"
    },
    "returnAffected": true
  },
  executionMode: ExecutionMode.asyncMode,
)
```

### Soft Delete
```dart
// Mark records as deleted instead of removing
BasicAction(
  actionId: UpdateAction.id,
  params: {
    "table": "users",
    "data": {
      "deleted_at": "#now",
      "status": "deleted"
    },
    "where": {
      "id": "#userId"
    }
  }
)
```

## ExecuteAction

### Purpose
Execute custom SQL statements for complex operations.

### Action ID
```dart
ExecuteAction.id
```

### Parameters
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `sql` | `String` | ✅ | SQL statement to execute | `"SELECT COUNT(*) FROM users"` |
| `params` | `List<dynamic>` | ❌ | SQL parameters | `["active", 100]` |

### Basic Usage
```dart
BasicAction(
  id: "custom_query",
  label: "Custom Query",
  actionId: ExecuteAction.id,
  actionType: ActionType.basicAct,
  params: {
    "sql": "SELECT u.name, COUNT(o.id) as order_count FROM users u LEFT JOIN orders o ON u.id = o.user_id WHERE u.status = ? GROUP BY u.id HAVING order_count > ?",
    "params": ["active", 5]
  },
  executionMode: ExecutionMode.asyncMode,
)
```

### Complex SQL Operations
```dart
// Multi-table operations
BasicAction(
  actionId: ExecuteAction.id,
  params: {
    "sql": """
      UPDATE products p 
      SET p.stock = p.stock - o.quantity 
      FROM order_items oi 
      JOIN orders o ON oi.order_id = o.id 
      WHERE oi.product_id = p.id AND o.status = 'confirmed'
    """
  }
)
```

## TransactionAction

### Purpose
Execute multiple database operations atomically.

### Action ID
```dart
TransactionAction.id
```

### Parameters
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `operations` | `List<Map>` | ✅ | List of database operations | `[{"action": "insert", "table": "users", "data": {...}}]` |
| `rollbackOnError` | `bool` | ❌ | Rollback on any error (default: true) | `true` |

### Basic Usage
```dart
BasicAction(
  id: "create_order_transaction",
  label: "Create Order Transaction",
  actionId: TransactionAction.id,
  actionType: ActionType.basicAct,
  params: {
    "operations": [
      {
        "action": "insert",
        "table": "orders",
        "data": {
          "user_id": "#userId",
          "total": "#orderTotal",
          "status": "pending"
        }
      },
      {
        "action": "insert",
        "table": "order_items",
        "data": "#orderItems"
      },
      {
        "action": "update",
        "table": "users",
        "data": {"last_order_at": "#now"},
        "where": {"id": "#userId"}
      }
    ],
    "rollbackOnError": true
  },
  executionMode: ExecutionMode.asyncMode,
)
```

## Data Types and Validation

### Supported Data Types
- **Text**: `String`, `char`, `varchar`, `text`
- **Numbers**: `int`, `bigint`, `real`, `double`, `decimal`
- **Boolean**: `bool`, `boolean`
- **Date/Time**: `datetime`, `timestamp`, `date`
- **Binary**: `blob`, `binary`
- **JSON**: `json`, `jsonb`

### Data Validation
```dart
// Validate data before insertion
BasicAction(
  actionId: InsertAction.id,
  params: {
    "table": "users",
    "data": {
      "name": "#validatedName",      // Ensure this is validated
      "email": "#validatedEmail",    // Ensure this is validated
      "age": "#validatedAge"         // Ensure this is validated
    },
    "validate": true
  }
)
```

## Error Handling

### Database Errors
```dart
// Handle database operation errors
BasicAction(
  actionId: InsertAction.id,
  params: {
    "table": "users",
    "data": {"name": "#userName", "email": "#userEmail"}
  },
  onError: [
    // Log the error
    BasicAction(
      actionId: "log_error",
      params: {
        "error": "#error",
        "operation": "insert_user",
        "table": "users"
      }
    ),
    
    // Try alternative approach
    BasicAction(
      actionId: "store_in_cache",
      params: {"data": {"name": "#userName", "email": "#userEmail"}}
    )
  ]
)
```

### Constraint Violations
```dart
// Handle unique constraint violations
BasicAction(
  actionId: InsertAction.id,
  params: {"table": "users", "data": {"email": "#userEmail"}},
  onError: [
    ConditionalAction(
      execute: "#error.code == 'UNIQUE_CONSTRAINT'",
      isTrue: [
        // Email already exists, update instead
        BasicAction(
          actionId: UpdateAction.id,
          params: {
            "table": "users",
            "data": {"last_login": "#now"},
            "where": {"email": "#userEmail"}
          }
        )
      ],
      isFalse: [
        // Handle other errors
        BasicAction(actionId: "handle_error")
      ]
    )
  ]
)
```

## Performance Optimization

### Indexing
```dart
// Create indexes for better performance
BasicAction(
  actionId: ExecuteAction.id,
  params: {
    "sql": "CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)"
  }
)
```

### Query Optimization
```dart
// Use specific columns instead of SELECT *
BasicAction(
  actionId: SelectAction.id,
  params: {
    "table": "users",
    "columns": ["id", "name", "email"],  // Only needed columns
    "where": {"status": "active"},
    "limit": 100
  }
)
```

### Batch Operations
```dart
// Batch multiple operations
BasicAction(
  actionId: "batch_insert",
  params: {
    "table": "products",
    "batchSize": 1000,
    "data": "#productList"
  }
)
```

## Security Considerations

### SQL Injection Prevention
```dart
// Use parameterized queries
BasicAction(
  actionId: SelectAction.id,
  params: {
    "table": "users",
    "where": {"email": "#userEmail"}  // Use parameters, not string concatenation
  }
)
```

### Input Sanitization
```dart
// Sanitize user input
BasicAction(
  actionId: InsertAction.id,
  params: {
    "table": "users",
    "data": {
      "name": "#sanitizedUserName",    // Ensure this is sanitized
      "email": "#sanitizedUserEmail"   // Ensure this is sanitized
    }
  }
)
```

### Access Control
```dart
// Check user permissions before database operations
ConditionalAction(
  execute: "user.hasPermission('write_users')",
  isTrue: [
    BasicAction(
      actionId: InsertAction.id,
      params: {"table": "users", "data": "#userData"}
    )
  ],
  isFalse: [
    BasicAction(
      actionId: "show_error",
      params: {"message": "Insufficient permissions"}
    )
  ]
)
```

## Testing and Debugging

### Database Testing
```dart
// Use test database for development
BasicAction(
  actionId: SelectAction.id,
  params: {
    "table": "users",
    "database": "#isTestMode ? 'test_db' : 'main_db'"
  }
)
```

### Query Logging
```dart
// Log all database operations
BasicAction(
  actionId: SelectAction.id,
  params: {
    "table": "users",
    "where": {"status": "active"},
    "logQuery": true,
    "logLevel": "debug"
  }
)
```

### Performance Monitoring
```dart
// Monitor query performance
BasicAction(
  actionId: SelectAction.id,
  params: {
    "table": "users",
    "where": {"status": "active"},
    "monitorPerformance": true,
    "timeout": 10000
  }
)
```

## Best Practices

### 1. **Data Validation**
- Always validate data before database operations
- Use appropriate data types
- Implement constraint checking

### 2. **Error Handling**
- Handle all possible database errors
- Provide meaningful error messages
- Implement fallback strategies

### 3. **Performance**
- Use indexes for frequently queried columns
- Limit result sets with WHERE clauses
- Use transactions for multiple operations

### 4. **Security**
- Use parameterized queries
- Validate and sanitize all inputs
- Implement proper access controls

## Related Actions

- **REST API Actions**: For external data operations
- **Expression Actions**: For data processing and validation
- **Conditional Actions**: For data-driven decision making
- **Loop Actions**: For batch data processing

## Summary

Database actions provide essential data persistence capabilities in CreateGo applications. They enable:

- **Data storage** and retrieval for applications
- **Complex data operations** with SQL support
- **Transaction management** for data integrity
- **Performance optimization** through indexing and query optimization

Proper use of database actions ensures reliable data management while maintaining performance and security.
