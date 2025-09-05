import 'dart:async';
import 'dart:convert';
import 'dart:html' as html; // Web-only localStorage
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ChatApp());
}

class ChatApp extends StatefulWidget {
  const ChatApp({super.key});
  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _urlCtl = TextEditingController();
  final TextEditingController _keyCtl = TextEditingController();
  final TextEditingController _projCtl = TextEditingController();
  final List<String> _messages = <String>[];
  String _lang = 'en';
  bool _busy = false;

  Map<String, Map<String, String>> get i18n => {
    'en': {
      'title': 'COGO Chat (Web)',
      'placeholder': 'Type a message...',
      'send': 'Send',
      'settings': 'Settings',
      'url': 'Supabase URL',
      'key': 'Supabase Key',
      'project': 'Project ID',
      'save': 'Save',
      'cancel': 'Cancel',
    },
    'ko': {
      'title': 'COGO 채팅 (웹)',
      'placeholder': '메시지를 입력하세요...',
      'send': '보내기',
      'settings': '설정',
      'url': 'Supabase URL',
      'key': 'Supabase Key',
      'project': 'Project ID',
      'save': '저장',
      'cancel': '취소',
    },
  };

  String t(String key) => i18n[_lang]?[key] ?? key;

  String get supabaseUrl => _urlCtl.text.trim();
  String get supabaseKey => _keyCtl.text.trim();
  String get projectId => _projCtl.text.trim();

  @override
  void initState() {
    super.initState();
    // Load settings from localStorage
    final s = html.window.localStorage;
    _urlCtl.text = s['cogo_supabase_url'] ?? '';
    _keyCtl.text = s['cogo_supabase_key'] ?? '';
    _projCtl.text = s['cogo_project_id'] ?? '';
  }

  Future<void> _openSettings() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('settings')),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _urlCtl, decoration: InputDecoration(labelText: t('url'))),
              TextField(controller: _keyCtl, decoration: InputDecoration(labelText: t('key'))),
              TextField(controller: _projCtl, decoration: InputDecoration(labelText: t('project'))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t('cancel'))),
          ElevatedButton(
            onPressed: () {
              final s = html.window.localStorage;
              s['cogo_supabase_url'] = _urlCtl.text.trim();
              s['cogo_supabase_key'] = _keyCtl.text.trim();
              s['cogo_project_id'] = _projCtl.text.trim();
              setState(() {});
              Navigator.of(ctx).pop();
            },
            child: Text(t('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || supabaseUrl.isEmpty || supabaseKey.isEmpty || projectId.isEmpty) return;
    setState(() { _busy = true; });
    try {
      final base = supabaseUrl.replaceAll(RegExp(r'/+
$'), '');
      final uri = Uri.parse('$base/functions/v1/chat-gateway');
      final resp = await http.post(
        uri,
        headers: {
          'authorization': 'Bearer $supabaseKey',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'payload': {
            'projectId': projectId,
            'text': text,
            'lang': _lang,
          }
        }),
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        setState(() { _messages.add('> $text'); });
      } else {
        setState(() { _messages.add('[error] ${resp.statusCode}: ${resp.body}'); });
      }
    } catch (e) {
      setState(() { _messages.add('[exception] $e'); });
    } finally {
      setState(() { _busy = false; _controller.clear(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'COGO Chat',
      home: Scaffold(
        appBar: AppBar(
          title: Text(t('title')),
          actions: [
            IconButton(onPressed: _openSettings, icon: const Icon(Icons.settings), tooltip: t('settings')),
            DropdownButton<String>(
              value: _lang,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('EN')),
                DropdownMenuItem(value: 'ko', child: Text('KO')),
              ],
              onChanged: (v) => setState(() { _lang = v ?? 'en'; }),
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, i) => Text(_messages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(hintText: t('placeholder')),
                      onSubmitted: (_) => _busy ? null : _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _busy ? null : _send,
                    child: Text(_busy ? '...' : t('send')),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
