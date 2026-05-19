import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class LlmConfig {
  const LlmConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.timeoutSeconds = 60,
  });

  final String baseUrl;
  final String apiKey;
  final String model;
  final int timeoutSeconds;

  bool get isConfigured => baseUrl.trim().isNotEmpty;

  factory LlmConfig.fromEnvironment() {
    const baseUrl = String.fromEnvironment('GEMMA_BASE_URL');
    const apiKey = String.fromEnvironment('GEMMA_API_KEY');
    const model = String.fromEnvironment(
      'GEMMA_MODEL',
      defaultValue: 'gemma-3-27b-it',
    );
    return LlmConfig(baseUrl: baseUrl, apiKey: apiKey, model: model);
  }
}

class LlmChatMessage {
  const LlmChatMessage({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

abstract class ChatClient {
  Future<String> complete(
    List<LlmChatMessage> messages, {
    double temperature = 0.72,
    int maxTokens = 900,
  });
}

class OpenAiCompatibleChatClient implements ChatClient {
  OpenAiCompatibleChatClient(this.config, {http.Client? client})
      : _client = client ?? http.Client();

  final LlmConfig config;
  final http.Client _client;

  @override
  Future<String> complete(
    List<LlmChatMessage> messages, {
    double temperature = 0.72,
    int maxTokens = 900,
  }) async {
    final uri = Uri.parse('${_trimRight(config.baseUrl)}/chat/completions');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (config.apiKey.trim().isNotEmpty)
        'Authorization': 'Bearer ${config.apiKey}',
    };
    final payload = {
      'model': config.model,
      'messages': messages.map((message) => message.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
    };

    final response = await _client
        .post(uri, headers: headers, body: jsonEncode(payload))
        .timeout(Duration(seconds: config.timeoutSeconds));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LlmException(
        'LLM endpoint returned HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const LlmException('LLM endpoint returned a non-object payload.');
    }
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const LlmException('LLM response did not contain choices.');
    }
    final first = choices.first;
    if (first is! Map<String, dynamic>) {
      throw const LlmException('LLM choice was malformed.');
    }
    final message = first['message'];
    if (message is Map<String, dynamic>) {
      final content = message['content'];
      if (content is String && content.trim().isNotEmpty) return content.trim();
    }
    final text = first['text'];
    if (text is String && text.trim().isNotEmpty) return text.trim();
    throw const LlmException('LLM response did not include text content.');
  }

  static String _trimRight(String value) {
    var result = value.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}

class LlmException implements Exception {
  const LlmException(this.message);
  final String message;

  @override
  String toString() => 'LlmException: $message';
}

class FakeChatClient implements ChatClient {
  @override
  Future<String> complete(
    List<LlmChatMessage> messages, {
    double temperature = 0.72,
    int maxTokens = 900,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 520));
    final joined = messages.map((message) => message.content).join('\n');
    if (joined.contains('JSON_ARRAY_DIALOGUE')) {
      return jsonEncode([
        {
          'speaker': 'Room',
          'role': 'Host',
          'text':
              'I will frame the room around three dimensions: educational value, the social loop, and the anti-echo-chamber mechanism. Each mind should focus on one core tension.'
        },
        {
          'speaker': 'Monet',
          'role': 'Advocate',
          'text':
              'Do not start with a universal chatbot. Start with a feed that lets users see different light: the same question recolored by different minds.'
        },
        {
          'speaker': 'Carl Rogers',
          'role': 'Advocate',
          'text':
              'My test is simple: after leaving the room, is the user more dependent on AI, or more able to hear their own voice? That is the baseline for an educational product.'
        },
        {
          'speaker': 'Jung',
          'role': 'Advocate',
          'text':
              'Escaping an echo chamber is not only about diverse content. It is about safely meeting the shadow: the question a user least wants to admit often carries the most growth energy.'
        },
        {
          'speaker': 'You',
          'role': 'Builder',
          'text':
              'So the MVP should be a thinking room connected to a public feed, not just another chat tool.'
        },
        {
          'speaker': 'Room',
          'role': 'Host',
          'text':
              'Summary: first validate whether one question, reframed by three high-quality perspectives, leads the user to act. That tells a stronger funding story than generic social growth.'
        }
      ]);
    }

    final system = messages.isEmpty ? '' : messages.first.content;
    final speaker = _extract(system, 'SPEAKER:', '\n') ?? 'Room';
    final role = _extract(system, 'ROLE:', '\n') ?? 'Host';
    final snippets = <String>[
      'I would narrow the problem first: what new action capability does the user gain after one session? Without that metric, the social shell is only a cream-colored maze.',
      'Here is a product anchor: every discussion should produce a perspective map, then let the user publish one insight back into the public feed so learning and social discovery reinforce each other.',
      'If you want funding, the theme does not need to chase trends. The stronger story is that AI moves education from content distribution to cognitive collaboration, with measurable retention and action conversion.',
      'I do not think recommendation diversity is enough. You need a host role that schedules disagreement, pauses drift, and summarizes hypotheses, otherwise many viewpoints become elegant noise.',
    ];
    final index = DateTime.now().millisecondsSinceEpoch % snippets.length;
    return '$speaker ($role): ${snippets[index]}';
  }

  String? _extract(String text, String start, String end) {
    final begin = text.indexOf(start);
    if (begin < 0) return null;
    final valueStart = begin + start.length;
    final finish = text.indexOf(end, valueStart);
    if (finish < 0) return text.substring(valueStart).trim();
    return text.substring(valueStart, finish).trim();
  }
}
