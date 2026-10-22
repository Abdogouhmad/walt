import 'package:flutter/material.dart';
import 'package:walt/features/settings/widgets/markdown_notes.dart';

import 'ota_info_card.dart';

/// "What's new" card rendering the CHANGELOG section shipped in the manifest
/// as real Markdown (spec §7.4).
class OtaChangelogCard extends StatelessWidget {
  final String notes;

  const OtaChangelogCard({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    return OtaInfoCard(
      title: 'What\'s new',
      icon: Icons.new_releases_outlined,
      children: [Flexible(child: MarkdownNotes(notes: notes))],
    );
  }
}
