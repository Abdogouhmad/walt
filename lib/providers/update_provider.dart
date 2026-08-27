import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:walt/features/settings/services/appinfo.dart';
import 'package:walt/data/services/notification_service.dart';
import 'package:walt/data/local/hive_service.dart';

class UpdateState {
  final bool isChecking;
  final bool isUpdating;
  final String? latestVersion;
  final String? downloadUrl;
  final String? changelog;
  final double downloadProgress;
  final String? errorMessage;
  final bool isUpdateAvailable;
  final int? apkSize;

  UpdateState({
    this.isChecking = false,
    this.isUpdating = false,
    this.latestVersion,
    this.downloadUrl,
    this.changelog,
    this.downloadProgress = 0.0,
    this.errorMessage,
    this.isUpdateAvailable = false,
    this.apkSize,
  });

  UpdateState copyWith({
    bool? isChecking,
    bool? isUpdating,
    String? latestVersion,
    String? downloadUrl,
    String? changelog,
    double? downloadProgress,
    String? errorMessage,
    bool? isUpdateAvailable,
    int? apkSize,
  }) {
    return UpdateState(
      isChecking: isChecking ?? this.isChecking,
      isUpdating: isUpdating ?? this.isUpdating,
      latestVersion: latestVersion ?? this.latestVersion,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      changelog: changelog ?? this.changelog,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
      isUpdateAvailable: isUpdateAvailable ?? this.isUpdateAvailable,
      apkSize: apkSize ?? this.apkSize,
    );
  }
}

class UpdateNotifier extends Notifier<UpdateState> {
  final _hive = HiveService.instance;

  @override
  UpdateState build() {
    return UpdateState();
  }

  Future<void> checkForUpdates({
    bool showNotificationIfAvailable = false,
  }) async {
    state = state.copyWith(isChecking: true, errorMessage: null);

    const String githubApiUrl =
        "https://api.github.com/repos/Abdogouhmad/walt/releases/latest";

    try {
      final response = await http.get(
        Uri.parse(githubApiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Walt-App-Updater',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String latestTag = data['tag_name'] ?? "";
        final String changelog = data['body'] ?? "";
        final List assets = data['assets'] ?? [];

        // Find the first .apk asset
        final apkAsset = assets.firstWhere(
          (asset) => asset['name'].toString().endsWith('.apk'),
          orElse: () => null,
        );

        if (apkAsset != null) {
          final String cleanLatestVersion = latestTag.replaceAll('v', '');
          final String currentVersion = Appinfo.version;
          final String downloadUrl = apkAsset['browser_download_url'];
          final int apkSize = apkAsset['size'] ?? 0;

          final bool isUpdateAvailable = cleanLatestVersion != currentVersion;

          state = state.copyWith(
            isChecking: false,
            latestVersion: cleanLatestVersion,
            downloadUrl: downloadUrl,
            changelog: changelog,
            isUpdateAvailable: isUpdateAvailable,
            apkSize: apkSize,
          );

          if (isUpdateAvailable && showNotificationIfAvailable) {
            final String lastNotifiedVersion =
                _hive.getSetting('lastNotifiedVersion', defaultValue: '')
                    as String;
            if (lastNotifiedVersion != cleanLatestVersion) {
              await NotificationService().showUpdateNotification(
                latestVersion: cleanLatestVersion,
                changelogSummary: changelog,
              );
              await _hive.saveSetting(
                'lastNotifiedVersion',
                cleanLatestVersion,
              );
            }
          }
        } else {
          state = state.copyWith(
            isChecking: false,
            errorMessage: "No APK found in the latest release.",
          );
        }
      } else {
        state = state.copyWith(
          isChecking: false,
          errorMessage:
              "Failed to check for updates: HTTP ${response.statusCode}",
        );
      }
    } catch (e) {
      state = state.copyWith(
        isChecking: false,
        errorMessage: "Error checking updates: $e",
      );
    }
  }

  void executeUpdate() {
    final downloadUrl = state.downloadUrl;
    if (downloadUrl == null) {
      state = state.copyWith(errorMessage: "No download URL available.");
      return;
    }

    state = state.copyWith(
      isUpdating: true,
      downloadProgress: 0.0,
      errorMessage: null,
    );

    try {
      OtaUpdate()
          .execute(downloadUrl, destinationFilename: 'walt-update.apk')
          .listen(
            (OtaEvent event) {
              switch (event.status) {
                case OtaStatus.DOWNLOADING:
                  final progress = double.tryParse(event.value ?? "0") ?? 0.0;
                  state = state.copyWith(downloadProgress: progress);
                  break;
                case OtaStatus.INSTALLING:
                  state = state.copyWith(
                    isUpdating: false,
                    downloadProgress: 100.0,
                  );
                  break;
                case OtaStatus.ALREADY_RUNNING_ERROR:
                  state = state.copyWith(
                    isUpdating: false,
                    errorMessage: "An update is already running.",
                  );
                  break;
                case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                  state = state.copyWith(
                    isUpdating: false,
                    errorMessage: "Permission denied to install the update.",
                  );
                  break;
                case OtaStatus.DOWNLOAD_ERROR:
                case OtaStatus.INTERNAL_ERROR:
                  state = state.copyWith(
                    isUpdating: false,
                    errorMessage: "Download failed: ${event.value}",
                  );
                  break;
                case OtaStatus.CHECKSUM_ERROR:
                  state = state.copyWith(
                    isUpdating: false,
                    errorMessage: "Checksum validation failed.",
                  );
                  break;
                default:
                  state = state.copyWith(
                    isUpdating: false,
                    errorMessage: "Something went wrong.",
                  );
              }
            },
            onError: (error) {
              state = state.copyWith(
                isUpdating: false,
                errorMessage: "Error: $error",
              );
            },
          );
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        errorMessage: "Failed to initialize update: $e",
      );
    }
  }
}

final updateProvider = NotifierProvider<UpdateNotifier, UpdateState>(() {
  return UpdateNotifier();
});
