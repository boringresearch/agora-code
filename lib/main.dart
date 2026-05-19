import 'package:flutter/material.dart';

import 'llm/llm_client.dart';
import 'screens/app_shell.dart';
import 'storage/local_store.dart';
import 'storage/local_store_factory.dart';
import 'theme/agora_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = createLocalStore();
  await store.init();

  final config = LlmConfig.fromEnvironment();
  final chatClient = config.isConfigured
      ? OpenAiCompatibleChatClient(config)
      : FakeChatClient();

  runApp(MindAgoraApp(store: store, chatClient: chatClient));
}

class MindAgoraApp extends StatelessWidget {
  const MindAgoraApp({
    super.key,
    required this.store,
    required this.chatClient,
  });

  final LocalStore store;
  final ChatClient chatClient;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mind Agora',
      theme: buildAgoraTheme(),
      home: AppShell(store: store, chatClient: chatClient),
    );
  }
}
