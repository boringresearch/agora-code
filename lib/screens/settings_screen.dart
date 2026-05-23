import 'package:flutter/material.dart';

import '../llm/llm_client.dart';
import '../storage/local_store.dart';
import '../theme/agora_theme.dart';
import '../widgets/avatar.dart';
import '../widgets/chip.dart';
import '../widgets/soft_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.store,
    required this.chatClient,
  });

  final LocalStore store;
  final ChatClient chatClient;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _testing = false;
  bool _showKey = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final baseUrl = await widget.store.readSetting(LlmSettingsKeys.baseUrl);
    final apiKey = await widget.store.readSetting(LlmSettingsKeys.apiKey);
    final model = await widget.store.readSetting(LlmSettingsKeys.model);
    if (!mounted) return;
    _baseUrlController.text =
        baseUrl?.trim().isNotEmpty == true ? baseUrl!.trim() : '/api/llm';
    _apiKeyController.text = apiKey ?? '';
    _modelController.text =
        model?.trim().isNotEmpty == true ? model!.trim() : 'gpt-5.5';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _status = null;
    });
    try {
      await widget.store.saveSetting(
        LlmSettingsKeys.baseUrl,
        _baseUrlController.text.trim(),
      );
      await widget.store.saveSetting(
        LlmSettingsKeys.apiKey,
        _apiKeyController.text.trim(),
      );
      await widget.store.saveSetting(
        LlmSettingsKeys.model,
        _modelController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _status = 'Saved. New chats will use this API config.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = 'Save failed: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _test() async {
    await _save();
    if (!mounted) return;
    setState(() {
      _testing = true;
      _status = 'Testing connection...';
    });
    try {
      final result = await widget.chatClient.complete(
        const [
          LlmChatMessage(
            role: 'user',
            content: 'Reply with exactly: ok',
          ),
        ],
        temperature: 0,
        maxTokens: 16,
      );
      if (!mounted) return;
      setState(() => _status = 'Connected: ${result.trim()}');
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = 'Connection failed: $error');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _clear() async {
    _baseUrlController.text = '/api/llm';
    _apiKeyController.clear();
    _modelController.text = 'gpt-5.5';
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 110),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const ThinkerAvatar(
                      name: 'You',
                      size: 52,
                      dark: true,
                      showInitial: true,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Settings',
                              style: displayStyle(
                                  fontSize: 30, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('Local API configuration for real LLM chat.',
                              style: bodyStyle(
                                  fontSize: 14, color: AgoraColors.inkSoft)),
                        ],
                      ),
                    ),
                    const AgoraChip(
                      label: 'stored locally',
                      icon: Icons.lock_outline_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SoftCard(
                  padding: const EdgeInsets.all(22),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('LLM API',
                                style: displayStyle(
                                    fontSize: 19, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text(
                              'Use /api/llm for the local same-origin proxy, or another OpenAI-compatible base URL. The API key is saved in this browser/device setting, not in the source code.',
                              style: bodyStyle(
                                  fontSize: 13.5,
                                  color: AgoraColors.inkSoft,
                                  height: 1.45),
                            ),
                            const SizedBox(height: 18),
                            _SettingsField(
                              label: 'Base URL',
                              controller: _baseUrlController,
                              icon: Icons.link_rounded,
                              hintText: '/api/llm',
                            ),
                            const SizedBox(height: 14),
                            _SettingsField(
                              label: 'API key',
                              controller: _apiKeyController,
                              icon: Icons.key_rounded,
                              hintText: 'sk-...',
                              obscureText: !_showKey,
                              suffix: IconButton(
                                onPressed: () =>
                                    setState(() => _showKey = !_showKey),
                                icon: Icon(_showKey
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                tooltip: _showKey ? 'Hide key' : 'Show key',
                              ),
                            ),
                            const SizedBox(height: 14),
                            _SettingsField(
                              label: 'Model',
                              controller: _modelController,
                              icon: Icons.memory_rounded,
                              hintText: 'gpt-5.5',
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed:
                                      _saving || _testing ? null : _clear,
                                  icon: const Icon(Icons.restart_alt_rounded),
                                  label: const Text('Reset fields'),
                                ),
                                const Spacer(),
                                FilledButton.icon(
                                  onPressed: _saving || _testing ? null : _save,
                                  icon: _saving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.save_outlined),
                                  label: const Text('Save'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AgoraColors.ink,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                FilledButton.icon(
                                  onPressed: _saving || _testing ? null : _test,
                                  icon: _testing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.bolt_rounded),
                                  label: const Text('Test connection'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AgoraColors.accent,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            if (_status != null) ...[
                              const SizedBox(height: 14),
                              Text(
                                _status!,
                                style: bodyStyle(
                                  fontSize: 13,
                                  color: _status!.contains('failed')
                                      ? AgoraColors.pink
                                      : AgoraColors.inkSoft,
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsField extends StatelessWidget {
  const _SettingsField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.hintText,
    this.obscureText = false,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: bodyStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AgoraColors.mute,
            )),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18),
            suffixIcon: suffix,
            hintText: hintText,
          ),
          style: bodyStyle(fontSize: 14, color: AgoraColors.ink),
        ),
      ],
    );
  }
}
