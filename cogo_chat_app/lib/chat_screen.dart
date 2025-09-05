import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chat_models.dart';
import 'chat_provider.dart';
import 'message_widget.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatProvider _provider = ChatProvider();
  
  StreamSubscription<ChatMessage>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  void _initializeChat() {
    // Initialize with the project ID
    _provider.initializeClient('65d9ce90-3f76-4fa0-a51d-5f0cd502cb4a');
    
    // Listen to message stream
    _messageSubscription = _provider.messageStream.listen((message) {
      if (mounted) {
        setState(() {});
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    _provider.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _provider.isTyping) return;

    _messageController.clear();
    
    print('📱 [StreamingChatScreen] Sending message: $message');
    await _provider.sendMessage(message);
    print('📱 [StreamingChatScreen] Provider.sendMessage completed');
    
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _provider,
      builder: (context, child) {
        return Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildChatArea(),
            ),
            _buildInputArea(),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF), // White header
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Agent info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COGO Agent',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000), // Cursor green
                ),
              ),
              const Text(
                'AI assistant for your project',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF666666), // Medium gray
                ),
              ),
              if (_provider.messages.isNotEmpty)
                Text(
                  '${_provider.messages.length} messages',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF999999), // Light gray
                  ),
                ),
            ],
          ),
          
          const Spacer(),
          
          // Connection status (minimal)
          Text(
            _provider.isConnected ? '●' : '○',
            style: TextStyle(
              fontSize: 8,
              color: _provider.isConnected ? const Color(0xFF000000) : const Color(0xFF999999),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Clear chat button
          Tooltip(
            message: 'Clear chat',
            child: InkWell(
              onTap: _provider.isTyping ? null : () {
                _provider.clearMessages();
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.clear_all,
                  size: 14,
                  color: _provider.isTyping 
                      ? const Color(0xFF999999)
                      : const Color(0xFF666666),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    if (_provider.messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(4),
      itemCount: _provider.messages.length + (_provider.isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _provider.messages.length) {
          return _buildTypingIndicator();
        }
        return _buildMessage(_provider.messages[index]);
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // Light gray
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 16,
                color: Color(0xFF000000), // Cursor green
              ),
              const SizedBox(width: 8),
              const Text(
                'COGO Agent is working...',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF000000), // Cursor green
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (_provider.currentTraceId != null) ...[
            const SizedBox(height: 4),
            Text(
              'Trace ID: ${_provider.currentTraceId!.substring(0, 8)}...',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF666666), // Medium gray
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: Color(0xFF9CA3AF), // Light gray
          ),
          const SizedBox(height: 16),
          const Text(
            'Start a conversation with your Cogo Agent',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280), // Medium gray
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          _buildQuickStartExamples(),
        ],
      ),
    );
  }

  Widget _buildQuickStartExamples() {
    final examples = [
      'test',
      'simple hello', 
      'bypass',
      'hello',
    ];

    return Column(
      children: [
        const Text(
          'Try asking:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF000000), // Dark text
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: examples.map((example) {
            return InkWell(
              onTap: () {
                _messageController.text = example;
                _sendMessage();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFFFFFFF),
                ),
                child: Text(
                  example,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF000000), // Dark text
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: const BoxDecoration(
            color: Color(0xFFFFFFFF), // White input area
            border: Border(
              top: BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFFFFFFF), // White input background
            ),
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: (event) {
                if (event is RawKeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.enter) {
                    if (HardwareKeyboard.instance.isControlPressed) {
                      // Ctrl+Enter: Insert new line
                      final currentText = _messageController.text;
                      final selection = _messageController.selection;
                      final newText = currentText.replaceRange(
                        selection.start,
                        selection.end,
                        '\n',
                      );
                      _messageController.text = newText;
                      _messageController.selection = TextSelection.collapsed(
                        offset: selection.start + 1,
                      );
                    } else {
                      // Enter: Send message
                      if (_messageController.text.trim().isNotEmpty) {
                        _sendMessage();
                      }
                    }
                  }
                }
              },
              child: TextField(
                controller: _messageController,
                style: const TextStyle(fontSize: 13, color: Color(0xFF000000)),
                maxLines: 5,
                minLines: 1,
                enabled: !_provider.isTyping,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onChanged: (value) {
                  setState(() {}); // Rebuild to update send button state
                },
                onTapOutside: (event) {
                  // Close keyboard when tapping outside
                  FocusScope.of(context).unfocus();
                },
                decoration: InputDecoration(
                contentPadding: const EdgeInsets.fromLTRB(12, 8, 48, 8),
                hintText: _provider.isTyping 
                    ? 'COGO is processing your request...' 
                    : 'Ask COGO Agent anything...',
                hintStyle: const TextStyle(
                  color: Color(0xFF999999), // Light gray
                  fontSize: 13,
                ),
                border: InputBorder.none,
                counterText: '',
                suffixIcon: _provider.isTyping
                    ? Tooltip(
                        message: 'Processing...',
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFF000000), // Cursor green
                            size: 16,
                          ),
                        ),
                      )
                    : Tooltip(
                        message: 'Send message',
                        child: InkWell(
                          onTap: _messageController.text.trim().isNotEmpty 
                              ? _sendMessage 
                              : null,
                          child: Icon(
                            Icons.send,
                            color: _messageController.text.trim().isNotEmpty 
                                ? const Color(0xFF000000) // Cursor green
                                : const Color(0xFF999999), // Light gray
                            size: 16,
                          ),
                        ),
                      ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message content
          _buildMessageContent(message),
          
          // Message actions with agent info
          if (!message.isUser && !message.isError)
            Align(
              alignment: Alignment.centerRight,
              child: buildMessageActions(
                message, 
                context,
                agentName: _extractAgentName(message.text),
                title: _extractTitle(message.text),
                response: message.text,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message) {
    return MessageWidget(message: message);
  }

  Widget buildMessageActions(ChatMessage message, BuildContext context, {
    required String agentName,
    required String title,
    required String response,
  }) {
    // Only show actions for agent messages with content
    if (message.isUser || message.isError || response.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildCopyButton(context, response, agentName, title),
        const SizedBox(width: 12),
        _buildApplyButton(context, response, agentName, title),
      ],
    );
  }

  Widget _buildCopyButton(BuildContext context, String response, String agentName, String title) {
    return Tooltip(
      message: 'Copy response content',
      child: InkWell(
        onTap: () => _handleCopyAction(context, response, agentName, title),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey.shade50,
          ),
          child:  Icon(
                Icons.copy,
                size: 14,
                color: Colors.grey.shade700,
              ),
        ),
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context, String response, String agentName, String title) {
    return Tooltip(
      message: 'Apply changes',
      child: InkWell(
        onTap: () => _handleApplyAction(context, response, agentName, title),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.shade300),
            borderRadius: BorderRadius.circular(4),
            color: Colors.blue.shade50,
          ),
          child: Icon(
                Icons.check_circle_outline,
                size: 14,
                color: Colors.blue.shade700,
              ),
        ),
      ),
    );
  }

  void _handleCopyAction(BuildContext context, String response, String agentName, String title) {
    try {
      Clipboard.setData(ClipboardData(text: response));
      _showToast('Copied response from $agentName');
    } catch (e) {
      _showToast('Failed to copy response: ${e.toString()}');
    }
  }

  void _handleApplyAction(BuildContext context, String response, String agentName, String title) {
    try {
      // Extract JSON from response
      final codeBlockRegex = RegExp(r'```json\n(.*?)\n```', dotAll: true);
      final jsonMatch = codeBlockRegex.firstMatch(response);
      
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(1)?.trim() ?? '';
        
        if (jsonString.isNotEmpty) {
          // Validate JSON
          jsonDecode(jsonString);
          
          // Apply the changes - create a temporary message for the logic
          final tempMessage = ChatMessage(
            text: response,
            isUser: false,
            messageType: MessageType.agent,
            timestamp: DateTime.now(),
            agentId: _provider.currentTraceId,
          );
          _provider.applyMessageToProject(tempMessage);
          _showToast('Applied changes from $agentName');
        } else {
          throw Exception('No JSON content found in response');
        }
      } else {
        // Handle non-JSON content (like BDD scenarios)
        final tempMessage = ChatMessage(
          text: response,
          isUser: false,
          messageType: MessageType.agent,
          timestamp: DateTime.now(),
          agentId: _provider.currentTraceId,
        );
        _provider.applyMessageToProject(tempMessage);
        _showToast('Applied changes from $agentName');
      }
    } catch (e) {
      _showToast('Cannot apply: ${e.toString()}');
    }
  }

  String _extractAgentName(String text) {
    final match = RegExp(r'AGENT: ([^*]+)\*\*').firstMatch(text);
    return match?.group(1)?.trim() ?? 'COGO Agent';
  }

  String _extractTitle(String text) {
    final match = RegExp(r'TITLE: \*([^*]+)\*').firstMatch(text);
    return match?.group(1)?.trim() ?? 'Response';
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}