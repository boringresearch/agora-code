import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';
import '../theme/agora_theme.dart';

class FileThinkerStore {
  static const _thinkersDirName = 'thinkers';
  static const _deletedIdsFileName = 'deleted_ids.json';

  late Directory _appDir;
  late Directory _thinkersDir;

  Future<void> init() async {
    _appDir = await getApplicationDocumentsDirectory();
    _thinkersDir = Directory(path.join(_appDir.path, _thinkersDirName));
    if (!await _thinkersDir.exists()) {
      await _thinkersDir.create(recursive: true);
    }
  }

  /// Get the path to the thinkers directory for external editing
  String get thinkersDirectoryPath => _thinkersDir.path;

  /// List all thinkers from individual files
  Future<List<MindProfile>> listThinkers() async {
    final thinkers = <MindProfile>[];

    if (!await _thinkersDir.exists()) {
      return thinkers;
    }

    final files = await _thinkersDir
        .list()
        .where((entity) =>
            entity is File &&
            path.basename(entity.path).endsWith('.md') &&
            path.basename(entity.path) != _deletedIdsFileName)
        .cast<File>()
        .toList();

    for (final file in files) {
      try {
        final thinker = await _readThinkerFromFile(file);
        if (thinker != null) {
          thinkers.add(thinker);
        }
      } catch (_) {
        // Skip invalid files
      }
    }

    return thinkers;
  }

  /// Save a thinker to a separate .md file
  Future<void> saveThinker(MindProfile thinker) async {
    final fileName = '${_sanitizeFileName(thinker.id)}.md';
    final filePath = path.join(_thinkersDir.path, fileName);
    final file = File(filePath);

    final content = _buildThinkerContent(thinker);
    await file.writeAsString(content);
  }

  /// Delete a thinker file and add to deleted list
  Future<void> deleteThinker(String thinkerId) async {
    final fileName = '${_sanitizeFileName(thinkerId)}.md';
    final filePath = path.join(_thinkersDir.path, fileName);
    final file = File(filePath);

    if (await file.exists()) {
      await file.delete();
    }

    // Add to deleted list
    final deletedIds = await _readDeletedIds();
    deletedIds.add(thinkerId);
    await _writeDeletedIds(deletedIds);
  }

  /// Get deleted thinker IDs
  Future<Set<String>> getDeletedIds() async {
    return await _readDeletedIds();
  }

  /// Clear deleted thinker IDs (restore all)
  Future<void> clearDeletedIds() async {
    await _writeDeletedIds({});
  }

  /// Read a thinker from a markdown file
  Future<MindProfile?> _readThinkerFromFile(File file) async {
    final content = await file.readAsString();
    final fileName = path.basenameWithoutExtension(file.path);

    // Parse frontmatter and content
    final parsed = _parseThinkerContent(content, fileName);
    if (parsed == null) return null;

    return MindProfile(
      id: parsed['id'] ?? fileName,
      name: parsed['name'] ?? fileName,
      handle: parsed['handle'] ?? '@${parsed['id'] ?? fileName}',
      role: parsed['role'] ?? 'Custom thinker',
      description: parsed['description'] ?? '',
      persona: parsed['persona'] ?? '',
      prior: parsed['prior'] ?? '',
      reflection: parsed['reflection'] ?? '',
      intent: parsed['intent'] ?? '',
      color: _parseColor(parsed['color']),
      isHost: parsed['isHost'] == 'true',
    );
  }

  /// Build markdown content for a thinker
  String _buildThinkerContent(MindProfile thinker) {
    final buffer = StringBuffer();

    buffer.writeln('---');
    buffer.writeln('id: ${thinker.id}');
    buffer.writeln('name: ${thinker.name}');
    buffer.writeln('handle: ${thinker.handle}');
    buffer.writeln('role: ${thinker.role}');
    buffer.writeln('description: ${thinker.description}');
    if (thinker.prior.isNotEmpty) {
      buffer.writeln('prior: ${thinker.prior}');
    }
    if (thinker.reflection.isNotEmpty) {
      buffer.writeln('reflection: ${thinker.reflection}');
    }
    if (thinker.intent.isNotEmpty) {
      buffer.writeln('intent: ${thinker.intent}');
    }
    buffer.writeln('color: ${_colorToString(thinker.color)}');
    buffer.writeln('isHost: ${thinker.isHost}');
    buffer.writeln('---');
    buffer.writeln();

    // Persona/prompt as the main content
    if (thinker.persona.isNotEmpty) {
      buffer.writeln(thinker.persona);
    }

    return buffer.toString();
  }

  /// Parse thinker markdown content
  Map<String, String>? _parseThinkerContent(String content, String fileName) {
    final result = <String, String>{};

    // Look for frontmatter between ---
    final frontmatterMatch =
        RegExp(r'^---\s*\n([\s\S]*?)\n---\s*\n([\s\S]*)$').firstMatch(content);

    if (frontmatterMatch != null) {
      final frontmatter = frontmatterMatch.group(1)!;
      final body = frontmatterMatch.group(2)!.trim();

      // Parse frontmatter key-value pairs
      for (final line in frontmatter.split('\n')) {
        final colonIndex = line.indexOf(':');
        if (colonIndex > 0) {
          final key = line.substring(0, colonIndex).trim();
          final value = line.substring(colonIndex + 1).trim();
          result[key] = value;
        }
      }

      // Body is the persona/prompt
      if (body.isNotEmpty) {
        result['persona'] = body;
      }
    } else {
      // No frontmatter, treat entire content as persona
      result['id'] = fileName;
      result['name'] = fileName;
      result['persona'] = content.trim();
    }

    return result;
  }

  /// Read deleted IDs from JSON file
  Future<Set<String>> _readDeletedIds() async {
    final filePath = path.join(_thinkersDir.path, _deletedIdsFileName);
    final file = File(filePath);

    if (!await file.exists()) {
      return {};
    }

    try {
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded.map((item) => item.toString()).toSet();
      }
    } catch (_) {
      // Return empty set on error
    }

    return {};
  }

  /// Write deleted IDs to JSON file
  Future<void> _writeDeletedIds(Set<String> ids) async {
    final filePath = path.join(_thinkersDir.path, _deletedIdsFileName);
    final file = File(filePath);
    await file.writeAsString(jsonEncode(ids.toList()));
  }

  /// Sanitize filename
  String _sanitizeFileName(String id) {
    return id
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Parse color from string
  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) {
      return AgoraColors.accent;
    }

    // Try named colors
    switch (colorStr.toLowerCase()) {
      case 'accent':
        return AgoraColors.accent;
      case 'violet':
        return AgoraColors.violet;
      case 'pink':
        return AgoraColors.pink;
      case 'green':
        return AgoraColors.green;
      case 'ink':
        return AgoraColors.ink;
      case 'cream':
        return AgoraColors.cream;
      default:
        break;
    }

    // Try hex color
    if (colorStr.startsWith('#')) {
      final hex = colorStr.substring(1);
      final parsed = int.tryParse(hex.length == 6 ? 'ff$hex' : hex, radix: 16);
      if (parsed != null) {
        return Color(parsed);
      }
    }

    return AgoraColors.accent;
  }

  /// Convert color to string
  String _colorToString(Color color) {
    // Check named colors
    if (color == AgoraColors.accent) return 'accent';
    if (color == AgoraColors.violet) return 'violet';
    if (color == AgoraColors.pink) return 'pink';
    if (color == AgoraColors.green) return 'green';
    if (color == AgoraColors.ink) return 'ink';
    if (color == AgoraColors.cream) return 'cream';

    // Return hex
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}
