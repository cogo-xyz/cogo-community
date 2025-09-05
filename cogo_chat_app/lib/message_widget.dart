import 'package:flutter/material.dart';
import 'dart:convert';
import 'chat_models.dart';

class MessageWidget extends StatefulWidget {
  final ChatMessage message;
  final bool isStreaming;
  final String? streamingText;
  
  const MessageWidget({
    super.key, 
    required this.message,
    this.isStreaming = false,
    this.streamingText,
  });

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message content - JSON or regular text
          _buildMessageContent(),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    // Check if message contains JSON
    if (_isJsonResponse()) {
      return _buildExpandableJson();
    }
    
    // Check if it's a system/processing message
    if (widget.message.isSystem || _isProcessingMessage()) {
      return _buildProcessingMessage();
    }
    
    // Regular text message
    return SelectableText(
      _getDisplayText(),
      style: TextStyle(
        color: _getTextColor(),
        fontSize: 13,
        height: 1.4,
      ),
    );
  }

  String _getDisplayText() {
    return widget.isStreaming && widget.streamingText != null 
        ? widget.streamingText! 
        : widget.message.text;
  }

  bool _isProcessingMessage() {
    final text = _getDisplayText().toLowerCase();
    return text.contains('processing') || 
           text.contains('working on it') || 
           text.contains('please wait') ||
           text.contains('cogo is');
  }

  Widget _buildProcessingMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // Light gray
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: Color(0xFF000000), // Cursor green
              ),
              SizedBox(width: 8),
              Text(
                'COGO Agent',
                style: TextStyle(
                  color: Color(0xFF000000), // Cursor green
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getDisplayText(),
            style: const TextStyle(
              color: Color(0xFF000000), // Dark text
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  bool _isJsonResponse() {
    final text = _getDisplayText().trim();
    if (text.isEmpty) return false;
    
    // Check if it looks like JSON (starts with { or [)
    if (text.startsWith('{') || text.startsWith('[')) {
      try {
        jsonDecode(text);
        return true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  Widget _buildExpandableJson() {
    final text = _getDisplayText();
    Map<String, dynamic> jsonData;
    
    try {
      jsonData = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      // Fallback to regular text if JSON parsing fails
      return SelectableText(
        text,
        style: TextStyle(
          color: _getTextColor(),
          fontSize: 13,
          height: 1.4,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with expand/collapse
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'JSON Response',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${jsonData.length} keys',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // JSON content
          if (_isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SelectableText(
                const JsonEncoder.withIndent('  ').convert(jsonData),
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  height: 1.3,
                ),
              ),
            ),
          
          // Preview when collapsed
          if (!_isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SelectableText(
                _getJsonPreview(jsonData),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  height: 1.3,
                ),
                maxLines: 2,
              ),
            ),
        ],
      ),
    );
  }

  String _getJsonPreview(Map<String, dynamic> json) {
    final keys = json.keys.take(3).toList();
    if (keys.isEmpty) return '{}';
    
    final preview = keys.map((key) {
      final value = json[key];
      if (value is Map) return '$key: {...}';
      if (value is List) return '$key: [...]';
      return '$key: $value';
    }).join(', ');
    
    return '{$preview${keys.length < json.length ? ', ...' : ''}}';
  }

  Color _getTextColor() {
    if (widget.message.isError) return const Color(0xFFEF4444); // Red
    if (widget.message.isSystem) return const Color(0xFF666666); // Medium gray
    if (widget.message.isUser) return const Color(0xFF000000); // Dark text
    return const Color(0xFF000000); // Dark text
  }
}