import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/providers/update_provider.dart';

/// Runs one silent OTA check shortly after the first frame.
///
/// Walt never blocks the app on an update — there is no takeover screen, no
/// route guard and no `mandatory` gate. This widget only kicks off a background
/// fetch; the result surfaces as a local notification and a dismissible card in
/// Settings, and a failed check (offline, HTTP error) leaves the app untouched.
class SoftUpdateBootstrap extends ConsumerStatefulWidget {
  const SoftUpdateBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SoftUpdateBootstrap> createState() =>
      _SoftUpdateBootstrapState();
}

class _SoftUpdateBootstrapState extends ConsumerState<SoftUpdateBootstrap> {
  @override
  void initState() {
    super.initState();
    // After the first frame: never hold up the initial paint on the network.
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    final notifier = ref.read(updateProvider.notifier);
    if (ref.read(updateProvider).checkResult != null) return;
    // checkForUpdates swallows every failure, so a missing network is a no-op.
    await notifier.checkForUpdates();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
