# Cogo Chat App

A complete Flutter chat application that integrates the Cogo Chat SDK and CLI for advanced AI-powered conversations and design generation.

## Features

### 🚀 Core Features
- **Real-time Chat**: Interactive chat interface with the Cogo AI agent
- **Design Generation**: Specialized mode for generating UI designs and components
- **Dual Integration**: Uses both Cogo Chat SDK and CLI for maximum functionality
- **Modern UI**: Clean, responsive Material Design 3 interface
- **Configuration Management**: Easy setup and configuration of Supabase credentials

### 🔧 Technical Features
- **SDK Integration**: Direct integration with `cogo-chat-sdk-flutter`
- **CLI Integration**: Advanced features via `cogo-cli-flutter` command-line interface
- **State Management**: Provider pattern for reactive state management
- **Stream Processing**: Real-time message streaming and updates
- **Error Handling**: Comprehensive error handling and user feedback
- **Trace Tracking**: Full trace ID tracking for debugging and monitoring

## Architecture

The app is built with a modular architecture:

```
lib/
├── main.dart                 # App entry point with navigation
├── chat_provider.dart        # Basic chat functionality
├── advanced_chat_provider.dart # Advanced features with CLI integration
├── chat_models.dart          # Data models and message types
├── chat_screen.dart          # Basic chat interface
├── advanced_chat_screen.dart # Advanced chat with design mode
├── message_widget.dart       # Reusable message display component
└── config_screen.dart        # Configuration and settings
```

## Dependencies

The app uses the following key dependencies:

- **cogo_chat_sdk_flutter**: Core SDK for chat functionality
- **cogo_cli_flutter**: CLI integration for advanced features
- **provider**: State management
- **flutter_markdown**: Rich text rendering
- **dio**: HTTP client for API calls
- **shared_preferences**: Local storage

## Setup Instructions

### 1. Prerequisites

- Flutter SDK (>=3.3.0)
- Dart SDK
- Supabase project with Cogo integration
- Valid Supabase credentials

### 2. Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd cogo_chat_app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**:
   - Open the app and go to the Config tab
   - Enter your Supabase credentials:
     - Edge Base URL: `https://your-project.functions.supabase.co/functions/v1`
     - Anonymous Key: Your Supabase anonymous key
     - Supabase URL: `https://your-project.supabase.co`
     - Project ID: Your Cogo project UUID

### 3. Running the App

```bash
flutter run
```

## Usage

### Basic Chat Mode

1. **Navigate to the Chat tab**
2. **Enter your project ID** in the configuration
3. **Type your message** and press send
4. **View the AI response** in real-time

### Advanced Mode

1. **Navigate to the Advanced tab**
2. **Toggle between Chat and Design modes**:
   - **Chat Mode**: Regular conversation with the AI
   - **Design Mode**: Specialized for UI/UX design generation
3. **Enable CLI Mode** for advanced features:
   - More sophisticated response handling
   - Better error recovery
   - Enhanced trace tracking

### Configuration

1. **Go to the Config tab**
2. **Enter your Supabase credentials**
3. **Set your project ID**
4. **Test the connection**
5. **Save the configuration**

## API Integration

### Chat Gateway

The app uses the `/chat-gateway` endpoint for basic chat functionality:

```dart
final response = await httpClient.post('/chat-gateway', jsonEncode({
  'projectId': projectId,
  'text': userMessage,
}));
```

### Design Generation

For design generation, the app uses the SDK's design generation endpoint:

```dart
await sdkClient.designGenerate.stream(
  {'prompt': prompt, 'projectId': projectId},
  (event, data) {
    // Handle streaming response
  },
);
```

### CLI Integration

Advanced features use the CLI for complex operations:

```dart
final result = await Process.run('dart', [
  'run', 'packages/cogo-cli-flutter/bin/cogo_cli_flutter.dart',
  '--project-id', projectId,
  'chat-loop', '--message', message, '--auto'
]);
```

## Message Types

The app supports various message types:

- **User Messages**: Messages sent by the user
- **Agent Messages**: Responses from the Cogo AI
- **Error Messages**: Error notifications and debugging info
- **System Messages**: System notifications and status updates

## Error Handling

The app includes comprehensive error handling:

- **Network Errors**: Connection timeouts and network failures
- **API Errors**: HTTP status codes and API response errors
- **CLI Errors**: Command-line execution failures
- **Validation Errors**: Input validation and configuration errors

## Debugging

### Trace IDs

Every conversation includes trace IDs for debugging:

- **User Messages**: No trace ID (user-initiated)
- **Agent Messages**: Include trace ID for tracking
- **Error Messages**: Include error details and context

### Logging

The app includes detailed logging for debugging:

- **Request/Response Logging**: HTTP request and response details
- **CLI Execution Logging**: Command-line execution details
- **State Change Logging**: Provider state changes and updates

## Customization

### UI Themes

The app uses Material Design 3 theming:

```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
  useMaterial3: true,
)
```

### Message Styling

Messages are styled based on type and content:

- **User Messages**: Primary color with right alignment
- **Agent Messages**: Surface variant color with left alignment
- **Error Messages**: Red color with error icon
- **System Messages**: Orange color with info icon

## Troubleshooting

### Common Issues

1. **Connection Failed**:
   - Check Supabase credentials
   - Verify network connectivity
   - Ensure project ID is correct

2. **CLI Not Working**:
   - Check CLI path configuration
   - Verify environment variables
   - Ensure Dart SDK is installed

3. **Messages Not Sending**:
   - Check project ID configuration
   - Verify API endpoints
   - Check error logs for details

### Debug Mode

Enable debug mode for detailed logging:

```dart
if (kDebugMode) {
  // Debug logging enabled
}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:

- Check the troubleshooting section
- Review the error logs
- Open an issue on GitHub
- Contact the development team

## Changelog

### Version 1.0.0
- Initial release
- Basic chat functionality
- Advanced mode with CLI integration
- Design generation mode
- Configuration management
- Comprehensive error handling
