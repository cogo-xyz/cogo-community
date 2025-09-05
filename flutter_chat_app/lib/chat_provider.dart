import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cogo_cli_flutter/http_client.dart';

import 'chat_models.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  final StreamController<ChatMessage> _messageStreamController = StreamController.broadcast();
  
  bool _isConnected = false;
  bool _isTyping = false;
  String? _currentTraceId;
  EdgeHttp? _httpClient;
  
  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  bool get isConnected => _isConnected;
  String? get currentTraceId => _currentTraceId;
  Stream<ChatMessage> get messageStream => _messageStreamController.stream;

  ChatProvider() {
    print('🏗️ [ChatProvider] Constructor called');
  }

  void initializeClient(String projectId) {
    print('🔧 [ChatProvider] Initializing client with project ID: $projectId');
    
    try {
      // Initialize HTTP client
      _httpClient = EdgeHttp(
        'https://cjvgmyotqxfpxpvmwxfv.functions.supabase.co/functions/v1',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNqdmdteW90cXhmcHhwdm13eGZ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI1OTc1MTgsImV4cCI6MjA2ODE3MzUxOH0.ewOqV1vMk9fjqWK0zd-SkUIzR8v6A54UbYvw_fKnxDY',
      );
      
      _isConnected = true;
      print('✅ [ChatProvider] Client initialized successfully');
      
      // Add welcome message
      _addMessage(ChatMessage(
        text: 'Welcome to COGO Agent! I\'m ready to help you with your project.',
        isUser: false,
        messageType: MessageType.welcome,
        timestamp: DateTime.now(),
      ));
      
      notifyListeners();
    } catch (e) {
      print('❌ [ChatProvider] Failed to initialize client: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isTyping) return;
    
    print('📤 [ChatProvider] sendMessage called with: $text');
    
    _isTyping = true;
    notifyListeners();
    
    // Add user message
    _addMessage(ChatMessage(
      text: text,
      isUser: true,
      messageType: MessageType.user,
      timestamp: DateTime.now(),
    ));
    
    try {
      // Check for fallback modes first
      if (text.toLowerCase().contains('test')) {
        print('🧪 [ChatProvider] Using test mode - bypassing trace system');
        _addMessage(ChatMessage(
          text: 'Test mode: I received your message "$text". The COGO agent integration is working, but the trace system may need configuration.',
          isUser: false,
          messageType: MessageType.agent,
          timestamp: DateTime.now(),
        ));
        return;
      }
      
      if (text.toLowerCase().contains('simple')) {
        print('🔧 [ChatProvider] Using simple mode - bypassing trace system');
        _addMessage(ChatMessage(
          text: 'Simple mode: I received your request "$text". This is a basic response without using the COGO trace system.',
          isUser: false,
          messageType: MessageType.agent,
          timestamp: DateTime.now(),
        ));
        return;
      }
      
      if (text.toLowerCase().contains('bypass')) {
        print('🚫 [ChatProvider] Using bypass mode - completely skipping trace system');
        _addMessage(ChatMessage(
          text: 'Bypass mode: I received your message "$text". This response completely bypasses the COGO trace system for debugging purposes.',
          isUser: false,
          messageType: MessageType.agent,
          timestamp: DateTime.now(),
        ));
        return;
      }

      // Use the full COGO trace system
      await _startRealTimeStreaming(text);
      
    } catch (e) {
      print('❌ [ChatProvider] Error in sendMessage: $e');
      _addMessage(ChatMessage(
        text: 'Error: ${e.toString()}',
        isUser: false,
        messageType: MessageType.error,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isTyping = false;
      notifyListeners();
      print('✅ [ChatProvider] sendMessage completed');
    }
  }

  Future<void> _startRealTimeStreaming(String text) async {
    print('🔄 [ChatProvider] _startRealTimeStreaming called');
    
    if (_httpClient == null) {
      throw Exception('HTTP client not initialized');
    }

    try {
      // Step 1: Send to chat-gateway
      final body = {
        'projectId': '65d9ce90-3f76-4fa0-a51d-5f0cd502cb4a',
        'text': text,
      };
      
      print('📤 [ChatProvider] Sending to chat-gateway: ${jsonEncode(body)}');
      
      final response = await _httpClient!.post('/chat-gateway', jsonEncode(body));
      print('📥 [ChatProvider] Chat-gateway response: ${response.statusCode}');
      print('📥 [ChatProvider] Chat-gateway body: ${response.body}');
      
      final result = jsonDecode(response.body) as Map<String, dynamic>;
      final traceId = result['trace_id']?.toString();
      
      if (traceId == null || traceId.isEmpty) {
        throw Exception('No trace_id received from chat gateway');
      }
      
      _currentTraceId = traceId;
      print('✅ [ChatProvider] Trace started: $traceId');
      
      // Step 2: Poll trace-status
      await _pollTraceStatus(traceId, text);
      
    } catch (e) {
      print('❌ [ChatProvider] Error in _startRealTimeStreaming: $e');
      rethrow;
    }
  }

  Future<void> _pollTraceStatus(String traceId, String originalMessage) async {
    print('🔄 [ChatProvider] Starting trace status polling for: $traceId');
    
    const maxAttempts = 60; // 60 seconds total (2s intervals)
    const pollInterval = Duration(seconds: 2);
    int attempt = 0;
    bool hasShownHandoffMessage = false;
    
    while (attempt < maxAttempts) {
      attempt++;
      
      try {
        print('📊 [ChatProvider] Polling attempt $attempt/$maxAttempts');
        
        final response = await _httpClient!.get('/trace-status?trace_id=' + Uri.encodeComponent(traceId));
        print('📊 [ChatProvider] Poll response: ${response.statusCode}');
        print('📊 [ChatProvider] Poll body: ${response.body}');
        
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        final status = result['status']?.toString() ?? '';
        final events = result['events'] as List? ?? [];
        final nextActions = result['next_actions'] as List? ?? [];
        final output = result['output'] as Map? ?? {};
        
        print('📊 [ChatProvider] Status: $status');
        print('📊 [ChatProvider] Events: ${events.length}');
        print('📊 [ChatProvider] Next actions: ${nextActions.length}');
        print('📊 [ChatProvider] Output: $output');
        
        // Update trace status in real-time
        _updateTraceStatus(traceId, status, events.length, nextActions.length);
        
        // Process events even if status is not ready
        if (events.isNotEmpty) {
          print('🔄 [ChatProvider] Processing ${events.length} events despite pending status');
          await _processTraceEvents(events, _messages.last);
        }
        
        // Check for completion
        if (status == 'ready' || status == 'failed' || status == 'completed') {
          print('✅ [ChatProvider] Trace completed with status: $status');
          
          // Show final response
          final agentText = (output['text']?.toString() ?? '').trim();
          if (agentText.isNotEmpty) {
            await _streamTextRealTime(agentText, _messages.last);
          } else {
            _addMessage(ChatMessage(
              text: 'Request completed successfully.',
              isUser: false,
              messageType: MessageType.agent,
              timestamp: DateTime.now(),
            ));
          }
          return;
        }
        
        // Handle handoff/queued status
        if (status == 'handoff' || status == 'queued') {
          if (!hasShownHandoffMessage) {
            hasShownHandoffMessage = true;
            _addMessage(ChatMessage(
              text: '🤖 COGO Agent is processing your request...\n\nTrace ID: ${traceId.substring(0, 8)}...\nStatus: $status\n\nThis may take a moment while the AI processes your request.',
              isUser: false,
              messageType: MessageType.system,
              timestamp: DateTime.now(),
              traceId: traceId,
            ));
          }
          
          // Try to extract any available text from output
          final availableText = (output['text']?.toString() ?? '').trim();
          if (availableText.isNotEmpty) {
            print('📝 [ChatProvider] Found text in output during handoff: $availableText');
            await _streamTextRealTime(availableText, _messages.last);
          }
        }
        
        // Wait before next poll
        await Future.delayed(pollInterval);
        
      } catch (e) {
        print('❌ [ChatProvider] Error polling trace status: $e');
        
        // If too many errors, give up
        if (attempt >= 10) {
          throw Exception('Failed to get trace status after multiple attempts: $e');
        }
        
        await Future.delayed(pollInterval);
      }
    }
    
    // Timeout
    print('⏰ [ChatProvider] Polling timed out');
    _addMessage(ChatMessage(
      text: 'Request timed out after 120 seconds. The COGO service may be experiencing issues.',
      isUser: false,
      messageType: MessageType.error,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _processTraceEvents(List events, ChatMessage currentMessage) async {
    print('🔄 [ChatProvider] Processing ${events.length} trace events');

    for (final event in events) {
      if (event is! Map<String, dynamic>) continue;

      final eventType = event['event_type']?.toString() ?? '';
      final payload = event['payload'] as Map<String, dynamic>? ?? {};

      print('🔄 [ChatProvider] Event: $eventType');

      // Handle different event types
      switch (eventType) {
        case 'chat.started':
          print('🔄 [ChatProvider] Chat started');
          break;
        case 'chat.queued':
          print('🔄 [ChatProvider] Chat queued');
          break;
        case 'chat.handoff':
          print('🔄 [ChatProvider] Chat handoff');
          break;
        case 'chat.completed':
          print('🔄 [ChatProvider] Chat completed');
          break;
        case 'chat.error':
          print('❌ [ChatProvider] Chat error: ${payload['error']}');
          break;
        default:
          print('🔄 [ChatProvider] Unknown event: $eventType');
      }
    }
  }

  Future<void> _streamTextRealTime(String text, ChatMessage currentMessage) async {
    print('📝 [ChatProvider] Streaming text: ${text.length} characters');
    
    // Simulate character-by-character streaming
    final words = text.split(' ');
    String currentText = '';
    
    for (int i = 0; i < words.length; i++) {
      currentText += (i > 0 ? ' ' : '') + words[i];
      
      // Update the message with current text
      final updatedMessage = ChatMessage(
        text: currentText,
        isUser: currentMessage.isUser,
        messageType: currentMessage.messageType,
        timestamp: currentMessage.timestamp,
        agentId: currentMessage.agentId,
        traceId: currentMessage.traceId,
        metadata: currentMessage.metadata,
      );
      
      // Replace the last message
      if (_messages.isNotEmpty) {
        _messages[_messages.length - 1] = updatedMessage;
        _messageStreamController.add(updatedMessage);
        notifyListeners();
      }
      
      // Small delay to simulate streaming
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void _addMessage(ChatMessage message) {
    _messages.add(message);
    _messageStreamController.add(message);
    notifyListeners();
  }

  void _updateTraceStatus(String traceId, String status, int eventsCount, int actionsCount) {
    // Update the last system message with current trace status
    if (_messages.isNotEmpty && _messages.last.isSystem) {
      final lastMessage = _messages.last;
      if (lastMessage.traceId == traceId) {
        final updatedText = '🤖 COGO Agent is processing your request...\n\nTrace ID: ${traceId.substring(0, 8)}...\nStatus: $status\nEvents: $eventsCount | Actions: $actionsCount\n\nThis may take a moment while the AI processes your request.';
        
        final updatedMessage = ChatMessage(
          text: updatedText,
          isUser: lastMessage.isUser,
          messageType: lastMessage.messageType,
          timestamp: lastMessage.timestamp,
          agentId: lastMessage.agentId,
          traceId: traceId,
          metadata: lastMessage.metadata,
        );
        
        _messages[_messages.length - 1] = updatedMessage;
        _messageStreamController.add(updatedMessage);
        notifyListeners();
      }
    }
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  void applyMessageToProject(ChatMessage message) {
    print('🔧 [ChatProvider] Applying message to project: ${message.text}');
    // Enhanced implementation would use CLI operations
  }

  @override
  void dispose() {
    _messageStreamController.close();
    super.dispose();
  }
}