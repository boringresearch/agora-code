import 'dart:convert';

import 'package:flutter/material.dart';

import '../theme/agora_theme.dart';

enum AppSection {
  home,
  meetings,
  think,
  selfReflection,
  saved,
  quotes,
  thinkers,
  collections,
  notifications,
  messages,
}

extension AppSectionLabel on AppSection {
  String get label {
    return switch (this) {
      AppSection.home => 'Home',
      AppSection.meetings => 'Meetings',
      AppSection.think => 'Think Room',
      AppSection.selfReflection => 'Self-reflection',
      AppSection.saved => 'Saved',
      AppSection.quotes => 'Quotes',
      AppSection.thinkers => 'Thinkers',
      AppSection.collections => 'Collections',
      AppSection.notifications => 'Notifications',
      AppSection.messages => 'Messages',
    };
  }

  IconData get icon {
    return switch (this) {
      AppSection.home => Icons.home_outlined,
      AppSection.meetings => Icons.calendar_month_outlined,
      AppSection.think => Icons.auto_awesome_outlined,
      AppSection.selfReflection => Icons.explore_outlined,
      AppSection.saved => Icons.bookmark_border_rounded,
      AppSection.quotes => Icons.format_quote_rounded,
      AppSection.thinkers => Icons.groups_2_outlined,
      AppSection.collections => Icons.library_books_outlined,
      AppSection.notifications => Icons.notifications_none_rounded,
      AppSection.messages => Icons.mail_outline_rounded,
    };
  }
}

enum RoomMode { complex, singlePrompt }

extension RoomModeLabel on RoomMode {
  String get label => switch (this) {
        RoomMode.complex => 'Complex host mode',
        RoomMode.singlePrompt => 'Single prompt mode',
      };

  String get shortLabel => switch (this) {
        RoomMode.complex => 'Complex',
        RoomMode.singlePrompt => 'Prompt',
      };
}

enum MessageKind { user, thinker, host, system }

class MindProfile {
  const MindProfile({
    required this.id,
    required this.name,
    required this.handle,
    required this.role,
    required this.description,
    this.persona = '',
    this.prior = '',
    this.reflection = '',
    this.intent = '',
    this.color = AgoraColors.accent,
    this.isHost = false,
  });

  final String id;
  final String name;
  final String handle;
  final String role;
  final String description;
  final String persona;
  final String prior;
  final String reflection;
  final String intent;
  final Color color;
  final bool isHost;

  MindProfile copyWith({
    String? id,
    String? name,
    String? handle,
    String? role,
    String? description,
    String? persona,
    String? prior,
    String? reflection,
    String? intent,
    Color? color,
    bool? isHost,
  }) {
    return MindProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      handle: handle ?? this.handle,
      role: role ?? this.role,
      description: description ?? this.description,
      persona: persona ?? this.persona,
      prior: prior ?? this.prior,
      reflection: reflection ?? this.reflection,
      intent: intent ?? this.intent,
      color: color ?? this.color,
      isHost: isHost ?? this.isHost,
    );
  }

  factory MindProfile.fromRoomData(Map<String, dynamic> json, int index) {
    final id = (json['id'] ?? 'mind_$index').toString();
    final name = (json['name'] ?? id).toString();
    final persona = (json['persona'] ?? '').toString();
    final role = (json['roleFunction'] ?? 'participant').toString();
    final description = _descriptionFromPersona(persona, role);

    return MindProfile(
      id: id,
      name: name,
      handle: '@${_handleFromName(name)}',
      role: role,
      description: description,
      persona: persona,
      prior: (json['priorMd'] ?? '').toString(),
      reflection: (json['reflection'] ?? '').toString(),
      intent: (json['intent'] ?? '').toString(),
      isHost: json['isHost'] == true,
      color: _palette[index % _palette.length],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'handle': handle,
        'role': role,
        'description': description,
        'persona': persona,
        'prior': prior,
        'reflection': reflection,
        'intent': intent,
        'color': color.value,
        'isHost': isHost,
      };

  factory MindProfile.fromJson(Map<String, dynamic> json) {
    return MindProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      handle: json['handle'] as String? ?? '@mind',
      role: json['role'] as String? ?? 'participant',
      description: json['description'] as String? ?? '',
      persona: json['persona'] as String? ?? '',
      prior: json['prior'] as String? ?? '',
      reflection: json['reflection'] as String? ?? '',
      intent: json['intent'] as String? ?? '',
      color: Color(json['color'] as int? ?? AgoraColors.accent.value),
      isHost: json['isHost'] as bool? ?? false,
    );
  }

  static String _descriptionFromPersona(String persona, String fallback) {
    final lines = persona
        .split('\n')
        .map((line) => line.replaceAll('#', '').trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return fallback;
    return lines.length > 1 ? lines[1] : lines.first;
  }

  static String _handleFromName(String name) {
    final normalized = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fa5]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? 'mind' : normalized;
  }

  static const _palette = <Color>[
    AgoraColors.accent,
    AgoraColors.violet,
    AgoraColors.pink,
    AgoraColors.green,
    Color(0xFF9C7325),
    Color(0xFFA35A2E),
    Color(0xFF264FB1),
  ];
}

class AgendaItem {
  const AgendaItem({
    required this.id,
    required this.title,
    required this.question,
    this.purpose = 'open',
    this.status = 'pending',
    this.requiredCoverage = const [],
    this.allowedScope = const [],
    this.minTurns = 2,
    this.estimatedTurns = 4,
    this.maxTurns = 8,
  });

  final String id;
  final String title;
  final String question;
  final String purpose;
  final String status;
  final List<String> requiredCoverage;
  final List<String> allowedScope;
  final int minTurns;
  final int estimatedTurns;
  final int maxTurns;

  factory AgendaItem.fromRoomData(Map<String, dynamic> json, int index) {
    return AgendaItem(
      id: (json['id'] ?? 'agenda_${index + 1}').toString(),
      title: (json['title'] ?? 'Agenda ${index + 1}').toString(),
      question: (json['question'] ?? '').toString(),
      purpose: (json['purpose'] ?? 'open').toString(),
      status: (json['status'] ?? 'pending').toString(),
      requiredCoverage:
          _stringList(json['requiredCoverage'] ?? json['wantToHear']),
      allowedScope: _stringList(json['allowedScope'] ?? json['okToDriftTo']),
      minTurns: _intValue(json['minTurns'], 2),
      estimatedTurns: _intValue(json['estimatedTurns'], 4),
      maxTurns: _intValue(json['maxTurns'], 8),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'question': question,
        'purpose': purpose,
        'status': status,
        'requiredCoverage': requiredCoverage,
        'allowedScope': allowedScope,
        'minTurns': minTurns,
        'estimatedTurns': estimatedTurns,
        'maxTurns': maxTurns,
      };

  factory AgendaItem.fromJson(Map<String, dynamic> json) {
    return AgendaItem(
      id: json['id'] as String,
      title: json['title'] as String,
      question: json['question'] as String? ?? '',
      purpose: json['purpose'] as String? ?? 'open',
      status: json['status'] as String? ?? 'pending',
      requiredCoverage: _stringList(json['requiredCoverage']),
      allowedScope: _stringList(json['allowedScope']),
      minTurns: _intValue(json['minTurns'], 2),
      estimatedTurns: _intValue(json['estimatedTurns'], 4),
      maxTurns: _intValue(json['maxTurns'], 8),
    );
  }
}

class RoomSession {
  const RoomSession({
    required this.id,
    required this.topic,
    required this.background,
    required this.outcomeType,
    required this.runtimeMode,
    required this.agenda,
    required this.participants,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String topic;
  final String background;
  final String outcomeType;
  final String runtimeMode;
  final List<AgendaItem> agenda;
  final List<MindProfile> participants;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AgendaItem get activeAgenda => agenda.isEmpty
      ? const AgendaItem(
          id: 'agenda_demo', title: 'Open dialogue', question: '')
      : agenda.firstWhere(
          (item) => item.status != 'resolved',
          orElse: () => agenda.first,
        );

  factory RoomSession.fromRoomDataJson(Map<String, dynamic> json) {
    final agenda = (json['agenda'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList()
        .asMap()
        .entries
        .map((entry) => AgendaItem.fromRoomData(entry.value, entry.key))
        .toList();
    final participants = (json['participants'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList()
        .asMap()
        .entries
        .map((entry) => MindProfile.fromRoomData(entry.value, entry.key))
        .toList();

    return RoomSession(
      id: (json['id'] ?? 'room_demo').toString(),
      topic: (json['topic'] ?? 'Untitled room').toString(),
      background: (json['background'] ?? '').toString(),
      outcomeType: (json['outcomeType'] ?? 'perspective_map').toString(),
      runtimeMode: (json['runtimeMode'] ?? 'demo').toString(),
      agenda: agenda,
      participants: participants,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'topic': topic,
        'background': background,
        'outcomeType': outcomeType,
        'runtimeMode': runtimeMode,
        'agenda': agenda.map((item) => item.toJson()).toList(),
        'participants': participants.map((mind) => mind.toJson()).toList(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory RoomSession.fromJson(Map<String, dynamic> json) {
    return RoomSession(
      id: json['id'] as String,
      topic: json['topic'] as String,
      background: json['background'] as String? ?? '',
      outcomeType: json['outcomeType'] as String? ?? 'perspective_map',
      runtimeMode: json['runtimeMode'] as String? ?? 'demo',
      agenda: (json['agenda'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AgendaItem.fromJson)
          .toList(),
      participants: (json['participants'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MindProfile.fromJson)
          .toList(),
      createdAt: _dateOrNull(json['createdAt']),
      updatedAt: _dateOrNull(json['updatedAt']),
    );
  }

  static RoomSession fromPayload(String payload) {
    return RoomSession.fromJson(jsonDecode(payload) as Map<String, dynamic>);
  }
}

class AgoraMessage {
  const AgoraMessage({
    required this.id,
    required this.speakerId,
    required this.speakerName,
    required this.role,
    required this.text,
    required this.kind,
    required this.createdAt,
    this.replyTo,
  });

  final String id;
  final String speakerId;
  final String speakerName;
  final String role;
  final String text;
  final MessageKind kind;
  final DateTime createdAt;
  final String? replyTo;

  bool get isUser => kind == MessageKind.user;
  bool get isHost => kind == MessageKind.host;

  Map<String, dynamic> toJson() => {
        'id': id,
        'speakerId': speakerId,
        'speakerName': speakerName,
        'role': role,
        'text': text,
        'kind': kind.name,
        'createdAt': createdAt.toIso8601String(),
        'replyTo': replyTo,
      };

  factory AgoraMessage.fromJson(Map<String, dynamic> json) {
    return AgoraMessage(
      id: json['id'] as String,
      speakerId: json['speakerId'] as String,
      speakerName: json['speakerName'] as String,
      role: json['role'] as String? ?? '',
      text: json['text'] as String? ?? '',
      kind: MessageKind.values.firstWhere(
        (kind) => kind.name == json['kind'],
        orElse: () => MessageKind.thinker,
      ),
      createdAt: _dateOrNull(json['createdAt']) ?? DateTime.now(),
      replyTo: json['replyTo'] as String?,
    );
  }
}

class FeedPost {
  const FeedPost({
    required this.id,
    required this.author,
    required this.handle,
    required this.timeLabel,
    required this.body,
    required this.avatarColor,
    this.verified = false,
    this.replyAuthor,
    this.replyBody,
    this.actionLabel,
    this.likes = 0,
    this.replies = 0,
    this.comments = const [],
  });

  final String id;
  final String author;
  final String handle;
  final String timeLabel;
  final String body;
  final Color avatarColor;
  final bool verified;
  final String? replyAuthor;
  final String? replyBody;
  final String? actionLabel;
  final int likes;
  final int replies;
  final List<FeedComment> comments;

  FeedPost copyWith({
    String? id,
    String? author,
    String? handle,
    String? timeLabel,
    String? body,
    Color? avatarColor,
    bool? verified,
    String? replyAuthor,
    String? replyBody,
    String? actionLabel,
    int? likes,
    int? replies,
    List<FeedComment>? comments,
  }) {
    return FeedPost(
      id: id ?? this.id,
      author: author ?? this.author,
      handle: handle ?? this.handle,
      timeLabel: timeLabel ?? this.timeLabel,
      body: body ?? this.body,
      avatarColor: avatarColor ?? this.avatarColor,
      verified: verified ?? this.verified,
      replyAuthor: replyAuthor ?? this.replyAuthor,
      replyBody: replyBody ?? this.replyBody,
      actionLabel: actionLabel ?? this.actionLabel,
      likes: likes ?? this.likes,
      replies: replies ?? this.replies,
      comments: comments ?? this.comments,
    );
  }
}

class FeedComment {
  const FeedComment({
    required this.id,
    required this.author,
    required this.handle,
    required this.body,
    required this.timeLabel,
  });

  final String id;
  final String author;
  final String handle;
  final String body;
  final String timeLabel;
}

class PromptSuggestion {
  const PromptSuggestion({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;
}

class ActiveConversation {
  const ActiveConversation({
    required this.title,
    required this.withWhom,
    required this.messages,
    required this.timeLabel,
    required this.color,
  });

  final String title;
  final String withWhom;
  final int messages;
  final String timeLabel;
  final Color color;
}

List<String> _stringList(Object? value) {
  return (value as List? ?? []).map((item) => item.toString()).toList();
}

int _intValue(Object? value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime? _dateOrNull(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
