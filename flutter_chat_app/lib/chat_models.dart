// No Flutter-specific features required here

// Keep the old message structure for UI compatibility
enum MessageType {
  welcome,
  user,
  agent,
  assistant,
  error,
  offline,
  system,
}

class ChatMessage {
  final String text;
  final bool isUser;
  final MessageType messageType;
  final DateTime timestamp;
  final String? agentId;
  final String? traceId;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.messageType,
    required this.timestamp,
    this.agentId,
    this.traceId,
    this.metadata,
  });

  bool get isError => messageType == MessageType.error;
  bool get isSystem => messageType == MessageType.system;

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'messageType': messageType.index,
      'timestamp': timestamp.toIso8601String(),
      'agentId': agentId,
      'traceId': traceId,
      'metadata': metadata,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      messageType: MessageType.values[json['messageType'] as int],
      timestamp: DateTime.parse(json['timestamp'] as String),
      agentId: json['agentId'] as String?,
      traceId: json['traceId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

// Keep the old stream processing state for compatibility
class StreamProcessingState {
  String currentAgentId;
  String currentAgentName;
  String accumulatedCode;
  String currentLanguage;
  String currentTitle;
  bool hasReceivedComplete;
  bool hasStartedReceivingContent;

  StreamProcessingState({
    this.currentAgentId = '',
    this.currentAgentName = '',
    this.accumulatedCode = '',
    this.currentLanguage = '',
    this.currentTitle = '',
    this.hasReceivedComplete = false,
    this.hasStartedReceivingContent = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'currentAgentId': currentAgentId,
      'currentAgentName': currentAgentName,
      'accumulatedCode': accumulatedCode,
      'currentLanguage': currentLanguage,
      'currentTitle': currentTitle,
      'hasReceivedComplete': hasReceivedComplete,
      'hasStartedReceivingContent': hasStartedReceivingContent,
    };
  }

  void updateFromMap(Map<String, dynamic> map) {
    currentAgentId = map['currentAgentId'] ?? currentAgentId;
    currentAgentName = map['currentAgentName'] ?? currentAgentName;
    accumulatedCode = map['accumulatedCode'] ?? accumulatedCode;
    currentLanguage = map['currentLanguage'] ?? currentLanguage;
    currentTitle = map['currentTitle'] ?? currentTitle;
    hasReceivedComplete = map['hasReceivedComplete'] ?? hasReceivedComplete;
    hasStartedReceivingContent = map['hasStartedReceivingContent'] ?? hasStartedReceivingContent;
  }
}

// New API Response Model matching the specification
class CogoAgentApiResponse {
  final String taskType;
  final String title;
  final String response;
  final String traceId;

  const CogoAgentApiResponse({
    required this.taskType,
    required this.title,
    required this.response,
    required this.traceId,
  });

  factory CogoAgentApiResponse.fromJson(Map<String, dynamic> json) {
    return CogoAgentApiResponse(
      taskType: json['task_type'] as String,
      title: json['title'] as String,
      response: json['response'] as String,
      traceId: json['trace_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_type': taskType,
      'title': title,
      'response': response,
      'trace_id': traceId,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CogoAgentApiResponse &&
        other.taskType == taskType &&
        other.title == title &&
        other.response == response &&
        other.traceId == traceId;
  }

  @override
  int get hashCode {
    return Object.hash(taskType, title, response, traceId);
  }

  @override
  String toString() {
    return 'CogoAgentApiResponse(taskType: $taskType, title: $title, response: $response, traceId: $traceId)';
  }
}

/// Streaming Event Model for SSE responses
class CogoAgentStreamEvent {
  final String eventType;
  final String? token;
  final String? text;
  final String? traceId;
  final Map<String, dynamic>? data;

  const CogoAgentStreamEvent({
    required this.eventType,
    this.token,
    this.text,
    this.traceId,
    this.data,
  });

  factory CogoAgentStreamEvent.fromJson(Map<String, dynamic> json) {
    return CogoAgentStreamEvent(
      eventType: json['event_type'] as String,
      token: json['token'] as String?,
      text: json['text'] as String?,
      traceId: json['trace_id'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_type': eventType,
      if (token != null) 'token': token,
      if (text != null) 'text': text,
      if (traceId != null) 'trace_id': traceId,
      if (data != null) 'data': data,
    };
  }

  bool get isDelta => eventType == 'llm.delta';
  bool get isDone => eventType == 'llm.done';
  bool get isChatDone => eventType == 'chat.done';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CogoAgentStreamEvent &&
        other.eventType == eventType &&
        other.token == token &&
        other.text == text &&
        other.traceId == traceId;
  }

  @override
  int get hashCode {
    return Object.hash(eventType, token, text, traceId);
  }

  @override
  String toString() {
    return 'CogoAgentStreamEvent(eventType: $eventType, token: $token, text: $text, traceId: $traceId)';
  }
}

// Legacy compatibility - keep old names for existing code
class CogoAgentMessage extends ChatMessage {
  CogoAgentMessage({
    required super.text,
    required super.isUser,
    required super.messageType,
    required super.timestamp,
    super.agentId,
    super.traceId,
    super.metadata,
  });

  factory CogoAgentMessage.fromChatMessage(ChatMessage message) {
    return CogoAgentMessage(
      text: message.text,
      isUser: message.isUser,
      messageType: message.messageType,
      timestamp: message.timestamp,
      agentId: message.agentId,
      traceId: message.traceId,
      metadata: message.metadata,
    );
  }
}

enum MessageRole {
  user,
  assistant,
  system,
  error,
}

// Extension methods for backward compatibility
extension ChatMessageExtensions on ChatMessage {
  MessageRole get role {
    switch (messageType) {
      case MessageType.user:
        return MessageRole.user;
      case MessageType.agent:
        return MessageRole.assistant;
      case MessageType.system:
        return MessageRole.system;
      case MessageType.error:
        return MessageRole.error;
      default:
        return MessageRole.assistant;
    }
  }

  bool get isAssistant => messageType == MessageType.agent;
  bool get isSystem => messageType == MessageType.system;
}