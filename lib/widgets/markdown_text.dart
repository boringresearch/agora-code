import 'package:flutter/material.dart';

import '../theme/agora_theme.dart';

class MarkdownText extends StatelessWidget {
  const MarkdownText({
    super.key,
    required this.text,
    required this.style,
    required this.color,
    this.codeBackground,
  });

  final String text;
  final TextStyle style;
  final Color color;
  final Color? codeBackground;

  @override
  Widget build(BuildContext context) {
    final blocks = _parseMarkdownBlocks(text);
    final background =
        codeBackground ?? AgoraColors.canvas.withValues(alpha: 0.86);
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < blocks.length; index++) ...[
            _MarkdownBlockView(
              block: blocks[index],
              style: style.copyWith(color: color),
              codeBackground: background,
            ),
            if (index != blocks.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

enum _MarkdownBlockType {
  paragraph,
  heading,
  bulletList,
  orderedList,
  quote,
  code
}

class _MarkdownBlock {
  const _MarkdownBlock(this.type, this.lines, {this.level = 0});

  final _MarkdownBlockType type;
  final List<String> lines;
  final int level;
}

class _MarkdownBlockView extends StatelessWidget {
  const _MarkdownBlockView({
    required this.block,
    required this.style,
    required this.codeBackground,
  });

  final _MarkdownBlock block;
  final TextStyle style;
  final Color codeBackground;

  @override
  Widget build(BuildContext context) {
    return switch (block.type) {
      _MarkdownBlockType.heading => SelectableText.rich(
          TextSpan(
              children: _inlineSpans(block.lines.join(' '), _headingStyle)),
        ),
      _MarkdownBlockType.bulletList => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: block.lines
              .map((line) => _ListLine(
                    marker: '•',
                    text: line,
                    style: style,
                    codeBackground: codeBackground,
                  ))
              .toList(),
        ),
      _MarkdownBlockType.orderedList => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < block.lines.length; index++)
              _ListLine(
                marker: '${index + 1}.',
                text: block.lines[index],
                style: style,
                codeBackground: codeBackground,
              ),
          ],
        ),
      _MarkdownBlockType.quote => Container(
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            border: Border(
                left: BorderSide(
                    color: style.color!.withValues(alpha: 0.32), width: 3)),
          ),
          child: SelectableText.rich(
            TextSpan(
                children: _inlineSpans(block.lines.join('\n'), _quoteStyle)),
          ),
        ),
      _MarkdownBlockType.code => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: codeBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AgoraColors.hair),
          ),
          child: SelectableText(
            block.lines.join('\n'),
            style: style.copyWith(
              fontFamily: 'monospace',
              fontSize: (style.fontSize ?? 14) - 1,
              height: 1.45,
            ),
          ),
        ),
      _ => SelectableText.rich(
          TextSpan(children: _inlineSpans(block.lines.join('\n'), style)),
        ),
    };
  }

  TextStyle get _headingStyle {
    final baseSize = style.fontSize ?? 15;
    final scale = switch (block.level) { 1 => 1.22, 2 => 1.13, _ => 1.06 };
    return style.copyWith(
      fontSize: baseSize * scale,
      height: 1.28,
      fontWeight: FontWeight.w800,
    );
  }

  TextStyle get _quoteStyle {
    return style.copyWith(
      color: style.color!.withValues(alpha: 0.78),
      fontStyle: FontStyle.italic,
    );
  }

  List<TextSpan> _inlineSpans(String value, TextStyle baseStyle) {
    final spans = <TextSpan>[];
    var index = 0;
    while (index < value.length) {
      final codeStart = value.indexOf('`', index);
      final boldStart = value.indexOf('**', index);
      final linkStart = value.indexOf('[', index);
      final italicStart = _findItalicStart(value, index);
      final starts = [codeStart, boldStart, linkStart, italicStart]
          .where((position) => position >= 0)
          .toList()
        ..sort();
      if (starts.isEmpty) {
        spans.add(TextSpan(text: value.substring(index), style: baseStyle));
        break;
      }
      final start = starts.first;
      if (start > index) {
        spans.add(
            TextSpan(text: value.substring(index, start), style: baseStyle));
      }

      if (start == codeStart) {
        final end = value.indexOf('`', start + 1);
        if (end < 0) {
          spans.add(TextSpan(text: value.substring(start), style: baseStyle));
          break;
        }
        spans.add(TextSpan(
          text: value.substring(start + 1, end),
          style: baseStyle.copyWith(
            fontFamily: 'monospace',
            backgroundColor: codeBackground,
            fontSize: (baseStyle.fontSize ?? 14) - 0.5,
          ),
        ));
        index = end + 1;
        continue;
      }

      if (start == boldStart) {
        final end = value.indexOf('**', start + 2);
        if (end < 0) {
          spans.add(TextSpan(text: value.substring(start), style: baseStyle));
          break;
        }
        spans.add(TextSpan(
          text: value.substring(start + 2, end),
          style: baseStyle.copyWith(fontWeight: FontWeight.w800),
        ));
        index = end + 2;
        continue;
      }

      if (start == linkStart) {
        final labelEnd = value.indexOf(']', start + 1);
        final urlStart = labelEnd >= 0 ? value.indexOf('(', labelEnd) : -1;
        final urlEnd = urlStart >= 0 ? value.indexOf(')', urlStart) : -1;
        if (labelEnd < 0 || urlStart != labelEnd + 1 || urlEnd < 0) {
          spans.add(TextSpan(
              text: value.substring(start, start + 1), style: baseStyle));
          index = start + 1;
          continue;
        }
        spans.add(TextSpan(
          text: value.substring(start + 1, labelEnd),
          style: baseStyle.copyWith(
            color: AgoraColors.violet,
            decoration: TextDecoration.underline,
            decorationColor: AgoraColors.violet,
          ),
        ));
        index = urlEnd + 1;
        continue;
      }

      final end = value.indexOf('*', start + 1);
      if (end < 0) {
        spans.add(TextSpan(text: value.substring(start), style: baseStyle));
        break;
      }
      spans.add(TextSpan(
        text: value.substring(start + 1, end),
        style: baseStyle.copyWith(fontStyle: FontStyle.italic),
      ));
      index = end + 1;
    }
    return spans;
  }

  int _findItalicStart(String value, int from) {
    var index = value.indexOf('*', from);
    while (index >= 0) {
      final previousIsStar = index > 0 && value[index - 1] == '*';
      final nextIsStar = index + 1 < value.length && value[index + 1] == '*';
      if (!previousIsStar && !nextIsStar) return index;
      index = value.indexOf('*', index + 1);
    }
    return -1;
  }
}

class _ListLine extends StatelessWidget {
  const _ListLine({
    required this.marker,
    required this.text,
    required this.style,
    required this.codeBackground,
  });

  final String marker;
  final String text;
  final TextStyle style;
  final Color codeBackground;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(marker,
                style: style.copyWith(fontWeight: FontWeight.w800)),
          ),
          Expanded(
            child: _MarkdownBlockView(
              block: _MarkdownBlock(_MarkdownBlockType.paragraph, [text]),
              style: style,
              codeBackground: codeBackground,
            ),
          ),
        ],
      ),
    );
  }
}

List<_MarkdownBlock> _parseMarkdownBlocks(String markdown) {
  final lines = markdown.replaceAll('\r\n', '\n').split('\n');
  final blocks = <_MarkdownBlock>[];
  final paragraph = <String>[];
  final list = <String>[];
  var listType = _MarkdownBlockType.bulletList;
  var inCode = false;
  final code = <String>[];

  void flushParagraph() {
    if (paragraph.isEmpty) return;
    blocks.add(
        _MarkdownBlock(_MarkdownBlockType.paragraph, [paragraph.join('\n')]));
    paragraph.clear();
  }

  void flushList() {
    if (list.isEmpty) return;
    blocks.add(_MarkdownBlock(listType, List<String>.from(list)));
    list.clear();
  }

  for (final rawLine in lines) {
    final line = rawLine.trimRight();
    final trimmed = line.trim();

    if (trimmed.startsWith('```')) {
      flushParagraph();
      flushList();
      if (inCode) {
        blocks.add(
            _MarkdownBlock(_MarkdownBlockType.code, List<String>.from(code)));
        code.clear();
        inCode = false;
      } else {
        inCode = true;
      }
      continue;
    }

    if (inCode) {
      code.add(rawLine);
      continue;
    }

    if (trimmed.isEmpty) {
      flushParagraph();
      flushList();
      continue;
    }

    final heading = RegExp(r'^(#{1,3})\s+(.+)$').firstMatch(trimmed);
    if (heading != null) {
      flushParagraph();
      flushList();
      blocks.add(_MarkdownBlock(
        _MarkdownBlockType.heading,
        [heading.group(2)!],
        level: heading.group(1)!.length,
      ));
      continue;
    }

    if (trimmed.startsWith('>')) {
      flushParagraph();
      flushList();
      blocks.add(_MarkdownBlock(_MarkdownBlockType.quote,
          [trimmed.replaceFirst(RegExp(r'^>\s?'), '')]));
      continue;
    }

    final bullet = RegExp(r'^[-*+]\s+(.+)$').firstMatch(trimmed);
    if (bullet != null) {
      flushParagraph();
      if (list.isNotEmpty && listType != _MarkdownBlockType.bulletList) {
        flushList();
      }
      listType = _MarkdownBlockType.bulletList;
      list.add(bullet.group(1)!);
      continue;
    }

    final ordered = RegExp(r'^\d+[.)]\s+(.+)$').firstMatch(trimmed);
    if (ordered != null) {
      flushParagraph();
      if (list.isNotEmpty && listType != _MarkdownBlockType.orderedList) {
        flushList();
      }
      listType = _MarkdownBlockType.orderedList;
      list.add(ordered.group(1)!);
      continue;
    }

    flushList();
    paragraph.add(line);
  }

  if (inCode && code.isNotEmpty) {
    blocks.add(_MarkdownBlock(_MarkdownBlockType.code, code));
  }
  flushParagraph();
  flushList();
  return blocks.isEmpty
      ? [
          _MarkdownBlock(_MarkdownBlockType.paragraph, [markdown])
        ]
      : blocks;
}
