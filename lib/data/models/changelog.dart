/// Pure helpers for turning the release's raw `CHANGELOG.md` slice (the
/// manifest's `releaseNotes`) into the bits the UI and the notification need.
///
/// Kept free of Flutter imports so they are unit-testable.
library;

import 'package:intl/intl.dart';

final RegExp _headingRe = RegExp(r'^#{1,6}\s*');
final RegExp _bulletRe = RegExp(r'^\s*[-*+]\s+');
final RegExp _fenceRe = RegExp(r'^\s*```');

/// Drops Markdown syntax from a single line so it can be used as notification
/// body text, where styling is impossible.
String stripMarkdown(String line) {
  return line
      .replaceAll(_fenceRe, '')
      .replaceAll(_headingRe, '')
      .replaceAll(_bulletRe, '')
      .replaceAll(RegExp(r'`([^`]*)`'), r'$1')
      .replaceAll(RegExp(r'\*\*([^*]*)\*\*'), r'$1')
      .replaceAll(RegExp(r'(?<!\*)\*([^*]+)\*(?!\*)'), r'$1')
      .replaceAll(RegExp(r'_([^_]+)_'), r'$1')
      .trim();
}

/// The first meaningful, non-heading line of a changelog — the one-line summary
/// used for the update notification body. Falls back to an empty string so the
/// caller can substitute generic copy.
String firstChangelogLine(String notes) {
  for (final raw in notes.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (_fenceRe.hasMatch(line)) continue;
    if (_headingRe.hasMatch(line)) continue;
    if (_bulletRe.hasMatch(line)) continue;
    if (line == '---') continue;
    return stripMarkdown(line);
  }
  return '';
}

/// The version heading of a changelog slice, e.g. `## 0.7.0 — Soft updates`
/// yields `0.7.0`. Returns null when there is no heading at all.
String? changelogVersionTitle(String notes) {
  for (final raw in notes.split('\n')) {
    final line = raw.trim();
    final match = _headingRe.firstMatch(line);
    if (match == null) continue;
    final rest = line.substring(match.end).trim();
    if (rest.isEmpty) continue;
    // `0.7.0`, `v0.7.0`, `## [0.7.0] - 2024-01-01`
    final semver = RegExp(r'v?\d+\.\d+(\.\d+)?').firstMatch(rest);
    if (semver != null) return semver.group(0)!.replaceFirst('v', '');
    return rest.split(RegExp(r'\s+[—–-]\s+')).first;
  }
  return null;
}

/// Short, user-facing date for the About / banner surfaces.
String formatReleaseDate(DateTime? date) {
  if (date == null) return '';
  return DateFormat.yMMMd().format(date.toLocal());
}
