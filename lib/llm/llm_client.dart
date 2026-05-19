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
          'text': '我先把问题收束成三个维度：教育价值、社交循环、反信息茧房机制。每个人只抓一个核心矛盾。'
        },
        {
          'speaker': '莫奈',
          'role': 'Advocate',
          'text': '不要先做万能聊天室。先做一个让用户看到不同光线的 feed：同一个问题，被不同 mind 重新着色。'
        },
        {
          'speaker': '卡尔罗杰斯(Carl Rogers)',
          'role': 'Advocate',
          'text': '我会问：用户离开房间后，是更依赖 AI，还是更能听到自己的声音？这是教育产品的底线。'
        },
        {
          'speaker': '荣格(Jung)',
          'role': 'Advocate',
          'text': '反茧房不只是多样内容，而是安全地面对阴影：用户最不想承认的问题，常常带着最大的成长能量。'
        },
        {
          'speaker': 'You',
          'role': 'Builder',
          'text': '所以 MVP 应该是一个思想房间加公共动态，而不是单纯聊天工具。'
        },
        {
          'speaker': 'Room',
          'role': 'Host',
          'text': '总结：先验证“一个问题被三种高质量视角改写后，用户是否产生行动”。这比泛社交增长更能讲清 funding 故事。'
        }
      ]);
    }

    final system = messages.isEmpty ? '' : messages.first.content;
    final speaker = _extract(system, 'SPEAKER:', '\n') ?? 'Room';
    final role = _extract(system, 'ROLE:', '\n') ?? 'Host';
    final snippets = <String>[
      '我会先把这个问题切得更窄：用户到底在一次会话后获得了什么新的行动能力？没有这个指标，社交外壳只是奶油色的迷宫。',
      '这里有一个产品锚点：让每次讨论产出一张“视角地图”，再允许用户把其中一条发布到公共动态，形成学习与社交的闭环。',
      '如果要拿 funding，主题不必追热点。更好的叙事是：AI 让教育从内容分发变成认知协作，并且有可验证的留存和行动转化。',
      '我不同意只靠推荐多样性。需要一个 host 角色调度冲突、暂停跑偏、总结假设，否则多视角会变成漂亮的噪音。',
    ];
    final index = DateTime.now().millisecondsSinceEpoch % snippets.length;
    return '$speaker（$role）：${snippets[index]}';
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
