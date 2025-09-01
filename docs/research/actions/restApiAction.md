# REST API Actions

## Overview

REST API actions in CreateGo allow action flows to communicate with external services, fetch data, and perform CRUD operations through HTTP requests. These actions are essential for integrating with web services, databases, and third-party APIs.

## Available REST API Actions

### 1. **GetAction** - HTTP GET Requests
### 2. **PostAction** - HTTP POST Requests  
### 3. **PutAction** - HTTP PUT Requests
### 4. **DeleteAction** - HTTP DELETE Requests
### 5. **PatchAction** - HTTP PATCH Requests

## Common Parameters

All REST API actions share these common parameters:

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `url` | `String` | ✅ | API endpoint URL | `"https://api.example.com/users"` |
| `headers` | `Map<String, String>` | ❌ | HTTP headers | `{"Authorization": "Bearer #token"}` |
| `timeout` | `int` | ❌ | Request timeout in milliseconds | `30000` |
| `retryCount` | `int` | ❌ | Number of retry attempts | `3` |
| `retryDelay` | `int` | ❌ | Delay between retries in milliseconds | `1000` |

## GetAction

### Purpose
Retrieve data from external APIs using HTTP GET requests.

### Action ID
```dart
GetAction.id
```

### Parameters
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `url` | `String` | ✅ | API endpoint URL | `"https://api.example.com/users"` |
| `queryParams` | `Map<String, dynamic>` | ❌ | URL query parameters | `{"page": "1", "limit": "10"}` |

### Basic Usage
```dart
BasicAction(
  id: "fetch_users",
  label: "Fetch Users",
  actionId: GetAction.id,
  actionType: ActionType.basicAct,
  params: {
    "url": "https://api.example.com/users",
    "headers": {
      "Authorization": "Bearer #accessToken",
      "Content-Type": "application/json"
    },
    "queryParams": {
      "page": "1",
      "limit": "20",
      "status": "active"
    }
  },
  executionMode: ExecutionMode.asyncMode,
)
```

### Response Handling
```dart
// Handle successful response
BasicAction(
  actionId: GetAction.id,
  params: {"url": "https://api.example.com/users"},
  onSuccess: [
    // Store response data
    BasicAction(
      actionId: "store_data",
      params: {"data": "#response.data", "key": "users"}
    ),
    
    // Process user data
    BasicAction(
      actionId: "process_users",
      params: {"users": "#response.data.users"}
    )
  ]
)
```

## PostAction

### Purpose
Send data to external APIs using HTTP POST requests.

### Action ID
```dart
PostAction.id
```

### Parameters
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `url` | `String` | ✅ | API endpoint URL | `"https://api.example.com/users"` |
| `body` | `Map<String, dynamic>` | ❌ | Request body data | `{"name": "John", "email": "john@example.com"}` |

### Basic Usage
```dart
BasicAction(
  id: "create_user",
  label: "Create User",
  actionId: PostAction.id,
  actionType: ActionType.basicAct,
  params: {
    "url": "https://api.example.com/users",
    "headers": {
      "Authorization": "Bearer #accessToken",
      "Content-Type": "application/json"
    },
    "body": {
      "name": "#userName",
      "email": "#userEmail",
      "role": "#userRole"
    }
  },
  executionMode: ExecutionMode.asyncMode,
)
```

### Form Data Submission
```dart
// Submit form data
BasicAction(
  actionId: PostAction.id,
  params: {
    "url": "https://api.example.com/forms/submit",
    "headers": {
      "Content-Type": "application/x-www-form-urlencoded"
    },
    "body": {
      "firstName": "#firstName",
      "lastName": "#lastName",
      "email": "#email",
      "phone": "#phone"
    }
  }
)
```

## PutAction

### Purpose
Update existing resources using HTTP PUT requests.

### Action ID
```dart
PutAction.id
```

### Parameters
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `url` | `String` | ✅ | API endpoint URL | `"https://api.example.com/users/123"` |
| `body` | `Map<String, dynamic>` | ❌ | Request body data | `{"name": "Updated Name"}` |

### Basic Usage
```dart
BasicAction(
  id: "update_user",
  label: "Update User",
  actionId: PutAction.id,
  actionType: ActionType.basicAct,
  params: {
    "url": "https://api.example.com/users/#userId",
    "headers": {
      "Authorization": "Bearer #accessToken",
      "Content-Type": "application/json"
    },
    "body": {
      "name": "#newUserName",
      "email": "#newUserEmail",
      "updatedAt": "#currentTimestamp"
    }
  },
  executionMode: ExecutionMode.asyncMode,
)
```

## DeleteAction

### Purpose
Remove resources using HTTP DELETE requests.

### Action ID
```dart
DeleteAction.id
```

### Parameters
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `url` | `String` | ✅ | API endpoint URL | `"https://api.example.com/users/123"` |

### Basic Usage
```dart
BasicAction(
  id: "delete_user",
  label: "Delete User",
  actionId: DeleteAction.id,
  actionType: ActionType.basicAct,
  params: {
    "url": "https://api.example.com/users/#userId",
    "headers": {
      "Authorization": "Bearer #accessToken"
    }
  },
  executionMode: ExecutionMode.asyncMode,
)
```

## PatchAction

### Purpose
Partially update resources using HTTP PATCH requests.

### Action ID
```dart
PatchAction.id
```

### Parameters
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `url` | `String` | ✅ | API endpoint URL | `"https://api.example.com/users/123"` |
| `body` | `Map<String, dynamic>` | ❌ | Partial update data | `{"status": "inactive"}` |

### Basic Usage
```dart
BasicAction(
  id: "update_user_status",
  label: "Update User Status",
  actionId: PatchAction.id,
  actionType: ActionType.basicAct,
  params: {
    "url": "https://api.example.com/users/#userId",
    "headers": {
      "Authorization": "Bearer #accessToken",
      "Content-Type": "application/json"
    },
    "body": {
      "status": "#newStatus",
      "lastModified": "#currentTimestamp"
    }
  },
  executionMode: ExecutionMode.asyncMode,
)
```

## Authentication

### Bearer Token Authentication
```dart
// Use bearer token from context
BasicAction(
  actionId: GetAction.id,
  params: {
    "url": "https://api.example.com/protected",
    "headers": {
      "Authorization": "Bearer #accessToken",
      "Content-Type": "application/json"
    }
  }
)
```

### API Key Authentication
```dart
// Use API key in headers
BasicAction(
  actionId: GetAction.id,
  params: {
    "url": "https://api.example.com/data",
    "headers": {
      "X-API-Key": "#apiKey",
      "Content-Type": "application/json"
    }
  }
)
```

### Basic Authentication
```dart
// Use username/password
BasicAction(
  actionId: GetAction.id,
  params: {
    "url": "https://api.example.com/data",
    "headers": {
      "Authorization": "Basic #base64Credentials",
      "Content-Type": "application/json"
    }
  }
)
```

## Error Handling

### HTTP Error Responses
```dart
// Handle different HTTP status codes
BasicAction(
  actionId: GetAction.id,
  params: {"url": "https://api.example.com/users"},
  onError: [
    // Handle 401 Unauthorized
    ConditionalAction(
      execute: "#response.statusCode == 401",
      isTrue: [
        BasicAction(
          actionId: "refresh_token",
          params: {"retryRequest": true}
        )
      ],
      isFalse: [
        // Handle other errors
        BasicAction(
          actionId: "log_error",
          params: {"error": "#response.error", "statusCode": "#response.statusCode"}
        )
      ]
    )
  ]
)
```

### Network Errors
```dart
// Handle network failures
BasicAction(
  actionId: GetAction.id,
  params: {"url": "https://api.example.com/users"},
  onError: [
    // Retry with exponential backoff
    BasicAction(
      actionId: "retry_request",
      params: {
        "url": "https://api.example.com/users",
        "retryCount": "#retryCount + 1",
        "maxRetries": 3
      }
    ),
    
    // Fallback to cached data
    BasicAction(
      actionId: "use_cached_data",
      params: {"cacheKey": "users"}
    )
  ]
)
```

## Response Processing

### JSON Response Handling
```dart
// Process JSON response
BasicAction(
  actionId: GetAction.id,
  params: {"url": "https://api.example.com/users"},
  onSuccess: [
    // Extract specific data
    BasicAction(
      actionId: "extract_data",
      params: {
        "users": "#response.data.users",
        "totalCount": "#response.data.pagination.total",
        "currentPage": "#response.data.pagination.page"
      }
    ),
    
    // Transform data
    BasicAction(
      actionId: "transform_users",
      params: {
        "rawUsers": "#users",
        "transformedUsers": "#rawUsers.map(user => {id: user.id, name: user.name, email: user.email})"
      }
    )
  ]
)
```

### XML Response Handling
```dart
// Handle XML responses
BasicAction(
  actionId: GetAction.id,
  params: {
    "url": "https://api.example.com/data",
    "headers": {"Accept": "application/xml"}
  },
  onSuccess: [
    // Parse XML response
    BasicAction(
      actionId: "parse_xml",
      params: {"xmlData": "#response.data"}
    )
  ]
)
```

## Advanced Features

### Request Interceptors
```dart
// Add request logging
BasicAction(
  actionId: GetAction.id,
  params: {
    "url": "https://api.example.com/users",
    "interceptors": {
      "beforeRequest": [
        BasicAction(
          actionId: "log_request",
          params: {"url": "#url", "method": "GET", "timestamp": "#now"}
        )
      ],
      "afterResponse": [
        BasicAction(
          actionId: "log_response",
          params: {"statusCode": "#response.statusCode", "responseTime": "#responseTime"}
        )
      ]
    }
  }
)
```

### Request Chaining
```dart
// Chain multiple API calls
ActionFlow(
  steps: [
    // First API call
    BasicAction(
      actionId: GetAction.id,
      params: {
        "url": "https://api.example.com/users/#userId",
        "storeAs": "userData"
      }
    ),
    
    // Second API call using data from first
    BasicAction(
      actionId: GetAction.id,
      params: {
        "url": "https://api.example.com/users/#userData.id/permissions",
        "storeAs": "userPermissions"
      }
    ),
    
    // Process combined data
    BasicAction(
      actionId: "process_user_info",
      params: {
        "user": "#userData",
        "permissions": "#userPermissions"
      }
    )
  ]
)
```

## Performance Optimization

### Caching Strategies
```dart
// Implement response caching
BasicAction(
  actionId: GetAction.id,
  params: {
    "url": "https://api.example.com/users",
    "cache": {
      "enabled": true,
      "ttl": 300000,  // 5 minutes
      "key": "users_list"
    }
  }
)
```

### Batch Requests
```dart
// Batch multiple requests
BasicAction(
  actionId: "batch_api_calls",
  params: {
    "requests": [
      {"method": "GET", "url": "https://api.example.com/users"},
      {"method": "GET", "url": "https://api.example.com/products"},
      {"method": "GET", "url": "https://api.example.com/orders"}
    ],
    "concurrent": true,
    "maxConcurrent": 3
  }
)
```

## Security Considerations

### Input Validation
```dart
// Validate URL before making request
BasicAction(
  actionId: GetAction.id,
  params: {
    "url": "#validatedUrl",  // Ensure this is validated
    "headers": {
      "Authorization": "Bearer #validatedToken"  // Ensure this is validated
    }
  }
)
```

### Rate Limiting
```dart
// Implement rate limiting
BasicAction(
  actionId: GetAction.id,
  params: {
    "url": "https://api.example.com/users",
    "rateLimit": {
      "enabled": true,
      "maxRequests": 100,
      "timeWindow": 60000  // 1 minute
    }
  }
)
```

## Testing and Debugging

### Mock API Testing
```dart
// Use mock API for testing
BasicAction(
  actionId: GetAction.id,
  params: {
    "url": "#isTestMode ? 'https://mockapi.example.com/users' : 'https://api.example.com/users'",
    "testMode": "#isTestMode"
  }
)
```

### Request Logging
```dart
// Log all request details
BasicAction(
  actionId: GetAction.id,
  params: {
    "url": "https://api.example.com/users",
    "debug": true,
    "logLevel": "verbose"
  }
)
```

## Best Practices

### 1. **URL Management**
- Use environment variables for base URLs
- Implement URL validation
- Handle relative vs absolute URLs

### 2. **Error Handling**
- Always implement error handling
- Use appropriate HTTP status codes
- Provide meaningful error messages

### 3. **Performance**
- Implement request caching
- Use connection pooling
- Optimize payload sizes

### 4. **Security**
- Validate all inputs
- Use HTTPS for sensitive data
- Implement proper authentication

## Related Actions

- **Database Actions**: For local data operations
- **Expression Actions**: For data processing
- **Conditional Actions**: For response-based logic
- **Loop Actions**: For batch processing

## Summary

REST API actions are fundamental for integrating CreateGo applications with external services. They provide:

- **Data integration** with web services and APIs
- **Real-time communication** with external systems
- **Data synchronization** across different platforms
- **Service orchestration** for complex workflows

Proper use of REST API actions enables powerful integrations while maintaining security, performance, and reliability.
