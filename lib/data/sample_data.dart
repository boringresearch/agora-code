import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/agora_theme.dart';

const kCustomThinkersKey = 'one_to_one.custom_thinkers.v1';
const kDeletedThinkersKey = 'one_to_one.deleted_thinkers.v1';

List<MindProfile> buildAllThinkers({
  List<MindProfile> customThinkers = const [],
  Set<String> deletedIds = const {},
}) {
  const monet = MindProfile(
    id: 'monet',
    name: 'Monet',
    handle: '@monet',
    role: 'Advocate',
    description:
        'Use a creative lens to design for clarity, reflection, and atmosphere rather than raw consumption.',
    color: AgoraColors.violet,
  );
  final byId = <String, MindProfile>{
    monet.id: monet,
    for (final t in railThinkers) t.id: t,
    for (final t in suggestedThinkers) t.id: t,
    for (final t in customThinkers) t.id: t,
  };
  return byId.values.where((t) => !deletedIds.contains(t.id)).toList();
}

List<MindProfile> decodeThinkersSetting(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    final rows = decoded is List ? decoded : [decoded];
    return rows
        .whereType<Map>()
        .map((row) => _thinkerFromMap(Map<String, dynamic>.from(row)))
        .toList();
  } catch (_) {
    return const [];
  }
}

Set<String> decodeStringSet(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const {};
    return decoded.map((item) => item.toString()).toSet();
  } catch (_) {
    return const {};
  }
}

MindProfile _thinkerFromMap(Map<String, dynamic> json) {
  final name = (json['name'] ?? '').toString().trim();
  final id = (json['id'] ?? '').toString().trim();
  final handle = (json['handle'] ?? '@$id').toString();
  final role = (json['role'] ?? 'Custom thinker').toString();
  final description = (json['description'] ?? '').toString();
  final persona = (json['prompt'] ?? json['persona'] ?? '').toString();
  final colorRaw = json['color'];
  Color color = AgoraColors.accent;
  if (colorRaw is int) {
    color = Color(colorRaw);
  } else if (colorRaw is String && colorRaw.startsWith('#')) {
    final hex = colorRaw.substring(1);
    final parsed = int.tryParse(hex.length == 6 ? 'ff$hex' : hex, radix: 16);
    if (parsed != null) color = Color(parsed);
  }
  return MindProfile(
    id: id.isEmpty ? name.toLowerCase().replaceAll(' ', '_') : id,
    name: name,
    handle: handle,
    role: role,
    description: description,
    persona: persona,
    color: color,
  );
}

const railThinkers = <MindProfile>[
  MindProfile(
    id: 'socrates',
    name: 'Socrates',
    handle: '@socrates',
    role: 'Questioner',
    description: 'Ask about virtue, knowledge, and the examined life.',
    color: AgoraColors.accent,
  ),
  MindProfile(
    id: 'laozi',
    name: 'Laozi',
    handle: '@laozi',
    role: 'Harmonizer',
    description: 'Explore harmony, simplicity, and the Tao.',
    color: AgoraColors.green,
  ),
  MindProfile(
    id: 'nietzsche',
    name: 'Nietzsche',
    handle: '@nietzsche',
    role: 'Provocateur',
    description: 'Question values, meaning, and the will to power.',
    color: AgoraColors.pink,
  ),
  MindProfile(
    id: 'marie_curie',
    name: 'Marie Curie',
    handle: '@mariecurie',
    role: 'Empiricist',
    description: 'Discuss curiosity, discovery, and perseverance.',
    color: AgoraColors.violet,
  ),
];

const suggestedThinkers = <MindProfile>[
  MindProfile(
    id: 'plato',
    name: 'Plato',
    handle: '@plato',
    role: 'Questioner',
    description: 'Define the problem before racing toward answers.',
    color: AgoraColors.accent,
  ),
  MindProfile(
    id: 'wang_yangming',
    name: 'Wang Yangming',
    handle: '@wang',
    role: 'Unifier',
    description: 'Unite knowing and doing, then test the smallest action.',
    color: AgoraColors.green,
  ),
  MindProfile(
    id: 'marie_curie',
    name: 'Marie Curie',
    handle: '@mariecurie',
    role: 'Empiricist',
    description: 'Turn inspiration into evidence and runway math.',
    color: AgoraColors.pink,
  ),
  MindProfile(
    id: 'feynman',
    name: 'Feynman',
    handle: '@feynman',
    role: 'Explainer',
    description: 'Strip the question down until the mechanism is visible.',
    color: Color(0xFFA35A2E),
  ),
];

const feedPosts = <FeedPost>[
  FeedPost(
    id: 'post_ai_tool',
    author: 'Cel_01KQX67AHXIWSW6B9',
    handle: '@cel_01KQX67',
    timeLabel: '7h',
    body:
        'AI tools like Duolingo may offer a starting point, but true mastery requires disciplined, repetitive effort. I suspect many claims of "life-changing" results are anecdotal; where is the longitudinal data to prove systemic improvement across diverse populations?',
    avatarColor: AgoraColors.accent,
    verified: true,
    replyAuthor: 'Socrates',
    replyBody:
        'Consider: if this matters to you, what is the question beneath the question?',
    actionLabel: 'Ask a thinker',
    likes: 128,
    replies: 31,
  ),
  FeedPost(
    id: 'post_curie_quote',
    author: 'Marie Curie',
    handle: '@mariecurie',
    timeLabel: '18h',
    body:
        '"One never notices what has been done; one can only see what remains to be done."\n- Marie Curie',
    avatarColor: AgoraColors.pink,
    verified: true,
    actionLabel: 'Explore more quotes',
    likes: 2048,
    replies: 84,
  ),
  FeedPost(
    id: 'post_wang',
    author: 'Wang Yangming',
    handle: '@wang',
    timeLabel: '1d',
    body:
        'Knowing and not acting is not yet knowing. Try the tiniest action that would make your belief visible before sunset.',
    avatarColor: AgoraColors.green,
    verified: true,
    actionLabel: 'Reflect',
    likes: 318,
    replies: 42,
  ),
];

const promptSuggestions = <PromptSuggestion>[
  PromptSuggestion(
    icon: Icons.menu_book_outlined,
    text: 'What does success mean to you beyond achievement?',
    color: Color(0xFFEFE9FA),
  ),
  PromptSuggestion(
    icon: Icons.local_fire_department_outlined,
    text: 'How can I build discipline that lasts?',
    color: Color(0xFFFBE6EC),
  ),
  PromptSuggestion(
    icon: Icons.lightbulb_outline_rounded,
    text: 'What belief do I hold that might be limiting my growth?',
    color: Color(0xFFE1EBFA),
  ),
];

const activeConversations = <ActiveConversation>[
  ActiveConversation(
    title: 'AI is just a tool',
    withWhom: 'Socrates',
    messages: 7,
    timeLabel: '1h',
    color: AgoraColors.accent,
  ),
  ActiveConversation(
    title: 'The courage to ship',
    withWhom: 'Marie Curie',
    messages: 11,
    timeLabel: '4h',
    color: AgoraColors.pink,
  ),
  ActiveConversation(
    title: 'Quiet ambition',
    withWhom: 'Laozi',
    messages: 3,
    timeLabel: '1d',
    color: AgoraColors.green,
  ),
];

final demoRoomFallback = RoomSession(
  id: 'room_demo_fallback',
  topic: 'Should I quit freelance and go full-time on my studio?',
  background:
      'Maya is deciding whether to move from freelance design into a focused product studio.',
  outcomeType: 'decision_frame',
  runtimeMode: 'demo',
  agenda: const [
    AgendaItem(
      id: 'agenda_01',
      title: 'Define regret',
      question: 'Are you afraid of having tried, or having played safe?',
      purpose: 'open',
      requiredCoverage: [
        'real fear',
        'decision boundary',
        'what evidence matters'
      ],
    ),
    AgendaItem(
      id: 'agenda_02',
      title: 'Surface constraints',
      question: 'How much runway, and what would change the decision?',
      purpose: 'challenge',
      requiredCoverage: ['runway', 'burn rate', 'minimum viable proof'],
    ),
    AgendaItem(
      id: 'agenda_03',
      title: 'Commit to a test',
      question: 'What is the smallest honest experiment?',
      purpose: 'decide',
      requiredCoverage: ['five-month test', 'recurring client', 'review point'],
    ),
  ],
  participants: suggestedThinkers,
);

List<AgoraMessage> seedRoomMessages(RoomSession session) {
  final minds = session.participants.isNotEmpty
      ? session.participants
      : demoRoomFallback.participants;

  String nameAt(int index) => minds[index % minds.length].name;
  String idAt(int index) => minds[index % minds.length].id;
  String roleAt(int index) => minds[index % minds.length].role;

  final now = DateTime.now();
  return [
    AgoraMessage(
      id: 'seed_host',
      speakerId: 'room_host',
      speakerName: 'Room',
      role: 'Host',
      text:
          'Topic locked: ${session.topic}. I will pause the public feed, draft the agenda, and invite each mind to respond in turn.',
      kind: MessageKind.host,
      createdAt: now.subtract(const Duration(minutes: 5)),
    ),
    AgoraMessage(
      id: 'seed_1',
      speakerId: idAt(0),
      speakerName: nameAt(0),
      role: roleAt(0),
      text:
          'I see this first as a question of light: you are not asking for a feature list, but for a way to let users be illuminated by viewpoints outside themselves. Do not turn the recommendation system into artificial studio light.',
      kind: MessageKind.thinker,
      createdAt: now.subtract(const Duration(minutes: 4)),
    ),
    AgoraMessage(
      id: 'seed_2',
      speakerId: idAt(1),
      speakerName: nameAt(1),
      role: roleAt(1),
      text:
          'What I hear underneath the product question is this: will an educational AI social product create dependency in the name of growth? Define the quality of the relationship before defining the algorithmic metric.',
      kind: MessageKind.thinker,
      createdAt: now.subtract(const Duration(minutes: 3)),
    ),
    AgoraMessage(
      id: 'seed_user',
      speakerId: 'you',
      speakerName: 'You',
      role: 'Builder',
      text:
          'I want it to feel as natural as social media, but the outcome should be one more thinking angle for the user, not one more addictive loop.',
      kind: MessageKind.user,
      createdAt: now.subtract(const Duration(minutes: 2)),
    ),
  ];
}
