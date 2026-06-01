import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:walt/features/settings/services/appinfo.dart';

class OtaUpdateScreen extends StatefulWidget {
  const OtaUpdateScreen({super.key});

  @override
  State<OtaUpdateScreen> createState() => _OtaUpdateScreenState();
}

class _OtaUpdateScreenState extends State<OtaUpdateScreen> {
  String _statusMessage = "Checking for updates...";
  double _progress = 0.0;
  bool _isUpdating = false;
  bool _isChecking = true;
  String? _latestVersion;
  String? _downloadUrl;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
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
        final List assets = data['assets'] ?? [];

        // Find the first .apk asset
        final apkAsset = assets.firstWhere(
          (asset) => asset['name'].toString().endsWith('.apk'),
          orElse: () => null,
        );

        if (apkAsset != null) {
          setState(() {
            _latestVersion = latestTag.replaceAll('v', '');
            _downloadUrl = apkAsset['browser_download_url'];
            _isChecking = false;

            // Simple version comparison (can be improved)
            if (_latestVersion != Appinfo.version) {
              _statusMessage = "New version available: v$_latestVersion";
            } else {
              _statusMessage = "You are on the latest version.";
            }
          });
        } else {
          setState(() {
            _statusMessage = "No APK found in the latest release.";
            _isChecking = false;
          });
        }
      } else {
        setState(() {
          _statusMessage = "Failed to check for updates: ${response.statusCode}";
          _isChecking = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error checking updates: $e";
        _isChecking = false;
      });
    }
  }

  void _executeOtaUpdate() {
    if (_downloadUrl == null) return;

    setState(() {
      _isUpdating = true;
      _statusMessage = "Starting update...";
    });

    try {
      OtaUpdate()
          .execute(_downloadUrl!, destinationFilename: 'walt-update.apk')
          .listen(
        (OtaEvent event) {
          setState(() {
            switch (event.status) {
              case OtaStatus.DOWNLOADING:
                _statusMessage = "Downloading update...";
                _progress = double.tryParse(event.value ?? "0") ?? 0.0;
                break;
              case OtaStatus.INSTALLING:
                _statusMessage = "Opening installer...";
                _isUpdating = false;
                break;
              case OtaStatus.ALREADY_RUNNING_ERROR:
                _statusMessage = "An update is already running.";
                _isUpdating = false;
                break;
              case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                _statusMessage = "Permission denied to install the update.";
                _isUpdating = false;
                break;
              case OtaStatus.DOWNLOAD_ERROR:
              case OtaStatus.INTERNAL_ERROR:
                _statusMessage = "Download failed: ${event.value}";
                _isUpdating = false;
                break;
              case OtaStatus.CHECKSUM_ERROR:
                _statusMessage = "Checksum validation failed.";
                _isUpdating = false;
                break;
              default:
                _statusMessage = "Something went wrong.";
                _isUpdating = false;
            }
          });
        },
        onError: (error) {
          setState(() {
            _statusMessage = "Error: $error";
            _isUpdating = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _statusMessage = "Failed to initialize update: $e";
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canUpdate = _downloadUrl != null && _latestVersion != Appinfo.version;

    return Scaffold(
      appBar: AppBar(title: const Text("App Update")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.system_update_alt_rounded,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 32),
            Text(
              "Current Version: v${Appinfo.version}",
              style: theme.textTheme.titleMedium,
            ),
            if (_latestVersion != null) ...[
              const SizedBox(height: 8),
              Text(
                "Latest Version: v$_latestVersion",
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: canUpdate ? theme.colorScheme.primary : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (_isChecking)
              const CircularProgressIndicator()
            else ...[
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 48),
              if (_isUpdating) ...[
                LinearProgressIndicator(
                  value: _progress / 100,
                  backgroundColor: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  minHeight: 12,
                ),
                const SizedBox(height: 16),
                Text(
                  "${_progress.toStringAsFixed(0)}%",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ] else if (canUpdate)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _executeOtaUpdate,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text("Update Now"),
                  ),
                )
              else if (!_isChecking)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _checkForUpdate,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text("Check Again"),
                  ),
                ),
            ],
            const SizedBox(height: 24),
            if (!_isUpdating && !_isChecking)
              Text(
                "Updating will download the latest APK from GitHub and prompt you to install it.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
