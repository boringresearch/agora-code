import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../llm/llm_client.dart';
import '../models/models.dart';
import 'simple_dialogue_prompt.dart';

class RoomOrchestrator {
  RoomOrchestrator(this.client);

  final ChatClient client;
  final _uuid = const Uuid();

  Future<AgoraMessage> runNextComplexTurn({
    required RoomSession session,
    required List<AgoraMessage> transcript,
    required int agendaIndex,
  }) async {
    final mind = _chooseSpeaker(session, transcript);
    final agenda = _agendaAt(session, agendaIndex);
    final system = _complexSystemPrompt(session: session, agenda: agenda, mind: mind);
    final user = _complexUserPrompt(transcript: transcript, agenda: agenda);
    final raw = await client.complete([
      LlmChatMessage(role: 'system', content: system),
      LlmChatMessage(role: 'user', content: user),
    ]);
    final cleaned = _stripSpeakerPrefix(raw, mind.name);

    return AgoraMessage(
      id: _uuid.v4(),
      speakerId: mind.id,
      speakerName: mind.name,
      role: mind.role,
      text: cleaned,
      kind: mind.isHost ? MessageKind.host : MessageKind.thinker,
      createdAt: DateTime.now(),
    );
  }

  Future<List<AgoraMessage>> runSinglePromptSimulation({
    required RoomSession session,
    required List<AgoraMessage> transcript,
  }) async {
    final prompt = buildSinglePromptDialogue(session: session, transcript: transcript);
    final raw = await client.complete([
      const LlmChatMessage(
        role: 'system',
        content:
            'You generate structured dialogue JSON for a reflective AI social room.',
      ),
      LlmChatMessage(role: 'user', content: prompt),
    ], maxTokens: 1400);

    final parsed = _tryParseDialogue(raw, session);
    if (parsed.isNotEmpty) return parsed;
    return _fallbackDialogue(session);
  }

  MindProfile _chooseSpeaker(RoomSession session, List<AgoraMessage> transcript) {
    final participants = session.participants.isEmpty ? <MindProfile>[] : session.participants;
    if (participants.isEmpty) {
      return const MindProfile(
        id: 'room_host',
        name: 'Room',
        handle: '@room',
        role: 'Host',
        description: 'Moderates the conversation.',
        isHost: true,
      );
    }
    final thinkerTurns = transcript.where((message) => !message.isUser).length;
    return participants[thinkerTurns % participants.length];
  }

  AgendaItem _agendaAt(RoomSession session, int index) {
    if (session.agenda.isEmpty) {
      return const AgendaItem(
        id: 'agenda_open',
        title: 'Open exploration',
        question: 'What is the real question beneath the question?',
      );
    }
    final safeIndex = index.clamp(0, session.agenda.length - 1).toInt();
    return session.agenda[safeIndex];
  }

  String _complexSystemPrompt({
    required RoomSession session,
    required AgendaItem agenda,
    required MindProfile mind,
  }) {
    return '''
You are a participant in Mind Agora, a moderated thinking room.
SPEAKER: ${mind.name}
ROLE: ${mind.role}

Room topic: ${session.topic}
Background: ${session.background}
Current agenda: ${agenda.title}
Agenda question: ${agenda.question}
Required coverage: ${agenda.requiredCoverage.join(' | ')}
Allowed drift: ${agenda.allowedScope.join(' | ')}

Persona:
${mind.persona.isEmpty ? mind.description : mind.persona}

Prior / reflection / intent packet:
${mind.prior}
${mind.reflection}
${mind.intent}

Rules:
- Speak as this mind, not as a generic assistant.
- One focused message only. No markdown headings.
- Use the current agenda, but respond to the live transcript.
- Be concrete and product-oriented when possible.
- Respectfully disagree if needed.
- Keep it under 120 Chinese characters unless nuance is essential.
''';
  }

  String _complexUserPrompt({
    required List<AgoraMessage> transcript,
    required AgendaItem agenda,
  }) {
    final recent = transcript.reversed.take(10).toList().reversed.map((message) {
      return '${message.speakerName} (${message.role}): ${message.text}';
    }).join('\n');
    return '''
Current agenda purpose: ${agenda.purpose}
Recent transcript:
$recent

Continue the discussion with one valuable turn.
''';
  }

  String _stripSpeakerPrefix(String raw, String speakerName) {
    var value = raw.trim();
    final patterns = [
      '$speakerName：',
      '$speakerName:',
      '$speakerName（',
      '$speakerName (',
    ];
    for (final pattern in patterns) {
      if (value.startsWith(pattern)) {
        final cut = value.indexOf(pattern.contains('（') || pattern.contains('(') ? '：' : pattern);
        if (cut >= 0 && cut + pattern.length < value.length) {
          value = value.substring(cut + pattern.length).trim();
        }
      }
    }
    return value.replaceAll(RegExp(r'^[-\s]+'), '').trim();
  }

  List<AgoraMessage> _tryParseDialogue(String raw, RoomSession session) {
    try {
      final start = raw.indexOf('[');
      final end = raw.lastIndexOf(']');
      if (start < 0 || end <= start) return [];
      final list = jsonDecode(raw.substring(start, end + 1));
      if (list is! List) return [];
      return list.whereType<Map<String, dynamic>>().map((item) {
        final speaker = (item['speaker'] ?? 'Room').toString();
        final role = (item['role'] ?? _roleForSpeaker(session, speaker)).toString();
        final isUser = speaker.toLowerCase() == 'you' || speaker == '用户';
        final isHost = speaker.toLowerCase() == 'room' || role.toLowerCase() == 'host';
        return AgoraMessage(
          id: _uuid.v4(),
          speakerId: _idForSpeaker(session, speaker),
          speakerName: speaker,
          role: role,
          text: (item['text'] ?? '').toString(),
          kind: isUser
              ? MessageKind.user
              : isHost
                  ? MessageKind.host
                  : MessageKind.thinker,
          createdAt: DateTime.now(),
        );
      }).where((message) => message.text.trim().isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  String _roleForSpeaker(RoomSession session, String speaker) {
    final match = session.participants.where((mind) => mind.name == speaker).firstOrNull;
    return match?.role ?? 'Thinker';
  }

  String _idForSpeaker(RoomSession session, String speaker) {
    final match = session.participants.where((mind) => mind.name == speaker).firstOrNull;
    if (match != null) return match.id;
    if (speaker.toLowerCase() == 'you') return 'you';
    return speaker.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fa5]+'), '_');
  }

  List<AgoraMessage> _fallbackDialogue(RoomSession session) {
    final now = DateTime.now();
    return [
      AgoraMessage(
        id: _uuid.v4(),
        speakerId: 'room',
        speakerName: 'Room',
        role: 'Host',
        text: '我们先把问题变成实验：AI 社交必须证明它让用户多一个视角，而不是多一次停留。',
        kind: MessageKind.host,
        createdAt: now,
      ),
      AgoraMessage(
        id: _uuid.v4(),
        speakerId: session.participants.isEmpty ? 'mind' : session.participants.first.id,
        speakerName: session.participants.isEmpty ? 'Thinker' : session.participants.first.name,
        role: session.participants.isEmpty ? 'Thinker' : session.participants.first.role,
        text: '先做思想启发型聊天室，再让高质量总结流入社交动态。公共 feed 不要喂相似内容，要展示同题异解。',
        kind: MessageKind.thinker,
        createdAt: now.add(const Duration(seconds: 1)),
      ),
    ];
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
