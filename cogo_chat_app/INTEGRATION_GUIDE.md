# Cogo Chat Flutter Integration Guide

This guide shows how to integrate the existing Cogo UI components with the SDK and CLI to create a fully functional chat application.

## Overview

The integration combines three main components:

1. **Existing UI Components** (`cogo-agent-ui/`)
   - `cogo_agent_models.dart` - Message models and data structures
   - `cogo_agent_chat_logic.dart` - Chat logic and state management
   - `cogo_agent_chat_view.dart` - UI components and widgets
   - `cogo_cli_runner.dart` - CLI integration utilities

2. **Cogo Chat SDK** (`packages/cogo-chat-sdk-flutter/`)
   - Direct API communication
   - Real-time streaming
   - Design generation
   - Trace status polling

3. **Cogo CLI** (`packages/cogo-cli-flutter/`)
   - Advanced command execution
   - Batch operations
   - File management
   - Complex workflows

## Integration Steps

### Step 1: Setup Dependencies

Add the required dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Cogo packages
  cogo_chat_sdk_flutter:
    path: ../packages/cogo-chat-sdk-flutter
  cogo_cli_flutter:
    path: ../packages/cogo-cli-flutter
  
  # UI dependencies
  cupertino_icons: ^1.0.8
  shared_preferences: ^2.2.2
  dio: ^5.4.0
  provider: ^6.1.1
  flutter_markdown: ^0.6.18+2
```

### Step 2: Import Existing UI Components

Copy the existing UI components to your project:

```dart
// Copy these files from cogo-agent-ui/
import 'cogo_agent_models.dart';
import 'cogo_agent_chat_logic.dart';
import 'cogo_agent_chat_view.dart';
import 'cogo_cli_runner.dart';
```

### Step 3: Create Enhanced Chat Provider

Create a new provider that integrates SDK and CLI:

```dart
import 'package:cogo_chat_sdk_flutter/cogo_chat_client.dart';
import 'package:cogo_cli_flutter/http_client.dart';
import 'cogo_agent_models.dart';

class EnhancedChatProvider extends ChangeNotifier {
  final CogoChatClient _sdkClient;
  final EdgeHttp _httpClient;
  final CogoCliRunner _cliRunner;
  
  // Your existing chat logic here
  // Enhanced with SDK and CLI integration
}
```

### Step 4: Configure SDK Client

Initialize the SDK client with your Supabase credentials:

```dart
final sdkClient = CogoChatClient(
  edgeBase: 'https://your-project.functions.supabase.co/functions/v1',
  anonKey: 'your-anon-key',
  supabaseUrl: 'https://your-project.supabase.co',
);
```

### Step 5: Configure CLI Runner

Set up the CLI runner for advanced features:

```dart
final cliRunner = CogoCliRunner(
  projectId: 'your-project-id',
  timeout: const Duration(seconds: 60),
  logDir: '.cogo/session',
  verbose: kDebugMode,
);
```

## Usage Examples

### Basic Chat with SDK

```dart
// Send a message using the SDK
Future<void> sendMessage(String text) async {
  final response = await _httpClient.post('/chat-gateway', jsonEncode({
    'projectId': _projectId,
    'text': text,
  }));
  
  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);
    final traceId = responseData['trace_id'];
    
    // Poll for result
    await _pollForResult(traceId);
  }
}
```

### Design Generation with SDK

```dart
// Generate designs using the SDK
Future<void> generateDesign(String prompt) async {
  final abortController = StreamController<void>();
  
  await _sdkClient.designGenerate.stream(
    {'prompt': prompt, 'projectId': _projectId},
    (event, data) {
      if (event == 'delta' && data['text'] != null) {
        // Handle streaming response
        _addMessage(data['text']);
      } else if (event == 'done') {
        abortController.add(null);
      }
    },
    abort: abortController,
  );
}
```

### Advanced Features with CLI

```dart
// Use CLI for complex operations
Future<void> runAdvancedCommand(String message) async {
  final result = await _cliRunner.runJson([
    'chat-loop',
    '--message', message,
    '--auto',
    '--max-steps', '3',
  ]);
  
  // Handle CLI result
  _addMessage(result['response'] ?? 'No response');
}
```

## Configuration

### Environment Variables

Set up your environment variables:

```bash
export SUPABASE_PROJECT_ID=your-project-id
export SUPABASE_ANON_KEY=your-anon-key
export SUPABASE_EDGE=https://your-project.functions.supabase.co/functions/v1
export SUPABASE_URL=https://your-project.supabase.co
```

### Project Configuration

Configure your project in the app:

```dart
void updateConfig({
  String? edgeBase,
  String? anonKey,
  String? supabaseUrl,
  String? projectId,
}) {
  // Update configuration
  _edgeBase = edgeBase ?? _edgeBase;
  _anonKey = anonKey ?? _anonKey;
  _supabaseUrl = supabaseUrl ?? _supabaseUrl;
  _projectId = projectId ?? _projectId;
  
  // Reinitialize clients
  _initializeClients();
}
```

## UI Integration

### Using Existing Components

The existing UI components can be used directly:

```dart
// Use the existing chat view
CogoAgentChatView()

// Use the existing message widget
CogoAgentMessageWidget(message: message)

// Use the existing chat logic
CogoAgentChatLogic()
```

### Custom Integration

Create custom widgets that use the existing components:

```dart
class CustomChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Custom Chat')),
      body: Column(
        children: [
          // Use existing components
          CogoAgentChatView(),
          // Add custom features
          CustomFeatureWidget(),
        ],
      ),
    );
  }
}
```

## Error Handling

### SDK Errors

Handle SDK errors gracefully:

```dart
try {
  await _sdkClient.designGenerate.stream(/* ... */);
} catch (e) {
  _addMessage(ChatMessage(
    text: 'SDK Error: $e',
    messageType: MessageType.error,
    // ...
  ));
}
```

### CLI Errors

Handle CLI execution errors:

```dart
try {
  final result = await _cliRunner.runJson(args);
} catch (e) {
  if (e is CogoCliException) {
    _addMessage(ChatMessage(
      text: 'CLI Error: ${e.message}',
      messageType: MessageType.error,
      // ...
    ));
  }
}
```

## Testing

### Unit Tests

Test individual components:

```dart
test('should send message via SDK', () async {
  final provider = EnhancedChatProvider();
  await provider.sendMessage('Hello');
  expect(provider.messages.length, greaterThan(0));
});
```

### Integration Tests

Test the full integration:

```dart
testWidgets('should display chat interface', (tester) async {
  await tester.pumpWidget(MyApp());
  expect(find.byType(CogoAgentChatView), findsOneWidget);
});
```

## Deployment

### Build Configuration

Configure your build for different environments:

```dart
// Development
const String edgeBase = 'https://dev-project.functions.supabase.co/functions/v1';

// Production
const String edgeBase = 'https://prod-project.functions.supabase.co/functions/v1';
```

### Environment-specific Settings

Use different configurations for different environments:

```dart
class Config {
  static String get edgeBase {
    if (kDebugMode) {
      return 'https://dev-project.functions.supabase.co/functions/v1';
    } else {
      return 'https://prod-project.functions.supabase.co/functions/v1';
    }
  }
}
```

## Troubleshooting

### Common Issues

1. **SDK Connection Failed**
   - Check Supabase credentials
   - Verify network connectivity
   - Ensure project ID is correct

2. **CLI Not Working**
   - Check CLI path configuration
   - Verify environment variables
   - Ensure Dart SDK is installed

3. **UI Components Not Rendering**
   - Check import statements
   - Verify widget tree structure
   - Check for missing dependencies

### Debug Mode

Enable debug logging:

```dart
if (kDebugMode) {
  print('Debug: Sending message: $message');
  print('Debug: Response: $response');
}
```

## Best Practices

1. **Use Provider for State Management**
   - Centralize state in providers
   - Use ChangeNotifier for reactive updates
   - Separate UI and business logic

2. **Handle Errors Gracefully**
   - Always wrap API calls in try-catch
   - Provide meaningful error messages
   - Log errors for debugging

3. **Optimize Performance**
   - Use const constructors where possible
   - Implement proper disposal of resources
   - Use efficient data structures

4. **Test Thoroughly**
   - Write unit tests for business logic
   - Test UI components in isolation
   - Test integration between components

## Conclusion

This integration guide shows how to combine the existing Cogo UI components with the SDK and CLI to create a fully functional chat application. The key is to leverage the existing components while adding the new functionality provided by the SDK and CLI.

The result is a powerful chat application that can:
- Send and receive messages in real-time
- Generate designs using AI
- Execute complex commands via CLI
- Handle errors gracefully
- Provide a great user experience

Follow the steps in this guide to integrate these components into your own Flutter application.
