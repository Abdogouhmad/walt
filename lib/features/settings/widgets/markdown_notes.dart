import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:walt/core/design/radius.dart';

/// Renders a `CHANGELOG.md` slice as real Markdown.
///
/// This is the single place the changelog is drawn, so headings, bullets,
/// `**bold**` and `` `code` `` all render properly instead of leaking their
/// source syntax into the UI the way a hand-rolled line parser did.
class MarkdownNotes extends StatelessWidget {
  const MarkdownNotes({super.key, required this.notes, this.selectable = true});

  final String notes;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final trimmed = notes.trim();
    if (trimmed.isEmpty) {
      return Text(
        'No release notes for this version.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    final body = MarkdownBody(
      data: trimmed,
      selectable: selectable,
      // Everything comes from the type scale; Markdown only tints it.
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: theme.textTheme.bodyMedium,
        listBullet: theme.textTheme.bodyMedium,
        h1: theme.textTheme.headlineSmall,
        h2: theme.textTheme.titleLarge,
        h3: theme.textTheme.titleMedium,
        h4: theme.textTheme.titleMedium,
        code: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          fontFeatures: const [FontFeature.tabularFigures()],
          backgroundColor: scheme.surfaceContainerHighest,
        ),
        codeblockDecoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        codeblockPadding: const EdgeInsets.all(AppRadius.sm),
        blockquoteDecoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        a: theme.textTheme.bodyMedium?.copyWith(color: scheme.primary),
      ),
    );

    return body;
  }
}
