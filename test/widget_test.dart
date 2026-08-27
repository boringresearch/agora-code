import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:mind_agora_flutter/data/sample_data.dart';
import 'package:mind_agora_flutter/llm/llm_client.dart';
import 'package:mind_agora_flutter/main.dart';
import 'package:mind_agora_flutter/models/models.dart';
import 'package:mind_agora_flutter/storage/local_store.dart';

void main() {
  testWidgets('renders the Mind Agora home feed', (WidgetTester tester) async {
    await tester.pumpWidget(MindAgoraApp(
      store: _FakeLocalStore(),
      chatClient: FakeChatClient(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('For You'), findsOneWidget);
    expect(find.text('Quotes'), findsWidgets);
  });

  testWidgets('user can create a feed post and comment',
      (WidgetTester tester) async {
    final store = _FakeLocalStore();
    await tester.pumpWidget(MindAgoraApp(
      store: store,
      chatClient: FakeChatClient(),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
      _textFieldWithHint('Share a question, quote, or reflection...'),
      'Post button test reflection',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Post'));
    await tester.pumpAndSettle();

    expect(find.text('Post button test reflection'), findsOneWidget);
    expect(store.storedFeedPosts.first.body, 'Post button test reflection');

    await tester.tap(find.widgetWithText(TextButton, 'Reply').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      _textFieldWithHint('Write a comment...'),
      'This comment can be posted now',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Comment'));
    await tester.pumpAndSettle();

    expect(find.text('This comment can be posted now'), findsOneWidget);
    expect(find.text('1 replies'), findsOneWidget);
    expect(
      store.storedFeedPosts.first.comments.single.body,
      'This comment can be posted now',
    );

    await tester.tap(find.byTooltip('Post options').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete post'));
    await tester.pumpAndSettle();

    expect(find.text('Post button test reflection'), findsNothing);
    expect(find.text('This comment can be posted now'), findsNothing);
    expect(find.text('Post deleted.'), findsOneWidget);
    expect(
      store.storedFeedPosts
          .where((post) => post.body == 'Post button test reflection'),
      isEmpty,
    );
  });

  test('seeded Think Room example dialogue is in English', () {
    final messages = seedRoomMessages(demoRoomFallback);
    expect(messages, isNotEmpty);
    for (final message in messages) {
      expect(
        RegExp(r'[\u4e00-\u9fff]').hasMatch(message.text),
        isFalse,
        reason: 'Message should be English: ${message.text}',
      );
    }
  });
}

Finder _textFieldWithHint(String hintText) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.hintText == hintText,
  );
}

class _FakeLocalStore implements LocalStore {
  final List<RoomSession> sessions = <RoomSession>[];
  final Map<String, List<AgoraMessage>> messages =
      <String, List<AgoraMessage>>{};
  final List<FeedPost> storedFeedPosts = <FeedPost>[];
  final Map<String, String> settings = <String, String>{};

  @override
  Future<void> init() async {}

  @override
  Future<List<RoomSession>> listSessions() async => sessions;

  @override
  Future<List<AgoraMessage>> listMessages(String roomId) async {
    return messages[roomId] ?? <AgoraMessage>[];
  }

  @override
  Future<List<FeedPost>> listFeedPosts() async {
    return List<FeedPost>.from(storedFeedPosts);
  }

  @override
  Future<String?> readSetting(String key) async => settings[key];

  @override
  Future<void> saveMessage(String roomId, AgoraMessage message) async {
    messages.putIfAbsent(roomId, () => <AgoraMessage>[]).add(message);
  }

  @override
  Future<void> saveFeedPost(FeedPost post) async {
    storedFeedPosts.removeWhere((item) => item.id == post.id);
    storedFeedPosts.add(post);
    storedFeedPosts.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
  }

  @override
  Future<void> saveSession(RoomSession session) async {
    sessions.removeWhere((item) => item.id == session.id);
    sessions.add(session);
  }

  @override
  Future<void> saveSetting(String key, String value) async {
    settings[key] = value;
  }

  @override
  Future<void> deleteFeedPost(String postId) async {
    storedFeedPosts.removeWhere((post) => post.id == postId);
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    sessions.removeWhere((session) => session.id == sessionId);
    messages.remove(sessionId);
  }
}
