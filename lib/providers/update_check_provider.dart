import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/data/local/hive_service.dart';
import 'package:walt/data/services/update_service.dart';

final hiveServiceProvider = Provider<HiveService>(
  (ref) => HiveService.instance,
);

final updateServiceProvider = Provider<UpdateService>(
  (ref) => const UpdateService(),
);

/// Hive keys for the update settings.
const String kLastUpdateCheckKey = 'last_update_check_ms';
const String kLastUpdateCheckResultKey = 'last_update_check_result';
const String kLastUpdateNotifiedKey = 'last_update_notified_version';

/// Timestamp of the last update check, for the "last checked" label.
/// `null` when never checked.
final lastUpdateCheckProvider =
    NotifierProvider<LastUpdateCheckNotifier, DateTime?>(
      LastUpdateCheckNotifier.new,
    );

class LastUpdateCheckNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    final hive = ref.watch(hiveServiceProvider);
    final ms = hive.getSetting(kLastUpdateCheckKey);
    return ms is int ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  Future<void> markChecked(UpdateCheckResult result) async {
    final now = DateTime.now();
    state = now;
    final hive = ref.read(hiveServiceProvider);
    await hive.saveSetting(kLastUpdateCheckKey, now.millisecondsSinceEpoch);
    await ref.read(lastUpdateCheckResultProvider.notifier).markResult(result);
  }
}

/// Outcome of the most recent update check as persisted across launches.
/// `null` means the app has never completed a check.
final lastUpdateCheckResultProvider =
    NotifierProvider<LastUpdateCheckResultNotifier, UpdateCheckResult?>(
      LastUpdateCheckResultNotifier.new,
    );

class LastUpdateCheckResultNotifier extends Notifier<UpdateCheckResult?> {
  @override
  UpdateCheckResult? build() {
    final hive = ref.watch(hiveServiceProvider);
    final name = hive.getSetting(kLastUpdateCheckResultKey);
    if (name is! String) return null;
    return UpdateCheckResult.values.asNameMap()[name];
  }

  Future<void> markResult(UpdateCheckResult result) async {
    state = result;
    await ref
        .read(hiveServiceProvider)
        .saveSetting(kLastUpdateCheckResultKey, result.name);
  }
}
