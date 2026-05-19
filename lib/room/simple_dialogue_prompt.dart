import '../models/models.dart';

String buildSinglePromptDialogue({
  required RoomSession session,
  required List<AgoraMessage> transcript,
}) {
  final minds = session.participants
      .map((mind) => '- ${mind.name}: role=${mind.role}; style=${_compact(mind.description)}')
      .join('\n');
  final agenda = session.agenda
      .map((item) => '- ${item.title}: ${item.question}')
      .join('\n');
  final recent = transcript.take(8).map((message) {
    return '${message.speakerName}: ${message.text}';
  }).join('\n');

  return '''
JSON_ARRAY_DIALOGUE
You are simulating a multi-person thinking room for Mind Agora.
Return only a valid JSON array. Each item must be an object with keys: speaker, role, text.
No markdown, no commentary, no code fence.

Room topic: ${session.topic}
Background: ${session.background}
Outcome type: ${session.outcomeType}

Participants:
$minds

Agenda:
$agenda

Recent transcript:
$recent

Write a complete 6 to 9 turn dialogue. Requirements:
1. The Room host frames the topic and summarizes at the end.
2. Each participant must speak in a recognizably different lens.
3. Include at least one respectful disagreement.
4. End with a concrete next experiment or product hypothesis.
5. Keep each message under 85 Chinese characters when possible.
''';
}

String _compact(String value) {
  final trimmed = value.replaceAll('\n', ' ').trim();
  if (trimmed.length <= 110) return trimmed;
  return '${trimmed.substring(0, 110)}...';
}
