import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/settings_model.dart';

class AIService {
  final TerminalSettings settings;

  AIService(this.settings);

  Future<String> sendMessage(String message, {String? context}) async {
    switch (settings.aiProvider) {
      case AIProvider.ollama:
        return _sendToOllama(message, context: context);
      case AIProvider.openai:
        return _sendToOpenAI(message, context: context);
      case AIProvider.gemini:
        return _sendToGemini(message, context: context);
      case AIProvider.none:
        return 'AI is not configured. Please configure an AI provider in settings.';
    }
  }

  Future<String> _sendToOllama(String message, {String? context}) async {
    final endpoint = settings.aiApiEndpoint.isNotEmpty
        ? settings.aiApiEndpoint
        : 'http://localhost:11434';

    try {
      final response = await http.post(
        Uri.parse('$endpoint/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': settings.ollamaModel,
          'prompt': _buildPrompt(message, context),
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] as String? ?? 'No response from Ollama';
      } else {
        return 'Ollama error: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      return 'Failed to connect to Ollama: $e';
    }
  }

  Future<String> _sendToOpenAI(String message, {String? context}) async {
    if (settings.aiApiKey.isEmpty) {
      return 'OpenAI API key is not configured.';
    }

    final endpoint = settings.aiApiEndpoint.isNotEmpty
        ? settings.aiApiEndpoint
        : 'https://api.openai.com/v1';

    try {
      final response = await http.post(
        Uri.parse('$endpoint/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${settings.aiApiKey}',
        },
        body: jsonEncode({
          'model': settings.openaiModel,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a helpful terminal assistant. Help users with command-line tasks, shell commands, and programming questions. Be concise and practical.',
            },
            if (context != null) {'role': 'user', 'content': 'Context: $context'},
            {'role': 'user', 'content': message},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String? ??
            'No response from OpenAI';
      } else {
        return 'OpenAI error: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      return 'Failed to connect to OpenAI: $e';
    }
  }

  Future<String> _sendToGemini(String message, {String? context}) async {
    if (settings.aiApiKey.isEmpty) {
      return 'Gemini API key is not configured.';
    }

    final endpoint = settings.aiApiEndpoint.isNotEmpty
        ? settings.aiApiEndpoint
        : 'https://generativelanguage.googleapis.com/v1beta';

    try {
      final response = await http.post(
        Uri.parse(
            '$endpoint/models/${settings.geminiModel}:generateContent?key=${settings.aiApiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': _buildPrompt(message, context)},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 2048,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] as String? ??
            'No response from Gemini';
      } else {
        return 'Gemini error: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      return 'Failed to connect to Gemini: $e';
    }
  }

  String _buildPrompt(String message, String? context) {
    final buffer = StringBuffer();
    buffer.writeln(
        'You are a helpful terminal assistant. Help users with command-line tasks, shell commands, and programming questions. Be concise and practical.');
    if (context != null && context.isNotEmpty) {
      buffer.writeln('\nTerminal context:');
      buffer.writeln(context);
    }
    buffer.writeln('\nUser question: $message');
    return buffer.toString();
  }

  bool get isConfigured => settings.aiProvider != AIProvider.none;

  String get providerName {
    switch (settings.aiProvider) {
      case AIProvider.ollama:
        return 'Ollama (${settings.ollamaModel})';
      case AIProvider.openai:
        return 'OpenAI (${settings.openaiModel})';
      case AIProvider.gemini:
        return 'Gemini (${settings.geminiModel})';
      case AIProvider.none:
        return 'Not configured';
    }
  }
}
