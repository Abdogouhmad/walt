import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walt/features/settings/widgets/update_required_screen.dart';
import 'package:walt/providers/update_provider.dart';

/// Startup gate for the OTA flow (spec §3.2 / §3.5).
///
/// Mounted above the app's Navigator via `MaterialApp.builder` so it can
/// replace the *entire* tree — including bottom navigation — when a mandatory
/// update is in effect. On first launch, performs a single, silent auto-check
/// (gated by the persisted "never checked" flag) that is non-blocking on any
/// failure. Auto-checking is always on: there is no opt-out.
class UpdateGate extends ConsumerStatefulWidget {
  final Widget child;

  const UpdateGate({super.key, required this.child});

  @override
  ConsumerState<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends ConsumerState<UpdateGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoCheck());
  }

  Future<void> _autoCheck() async {
    final state = ref.read(updateProvider);
    // If this device already completed a check on a previous launch the user
    // has seen its outcome (persisted "last result"); don't re-hit the network
    // on every cold start just to be polite about showing it again.
    if (state.checkResult != null) return;

    // Never let a background check block first frame: authorise afterwards.
    ref.read(updateProvider.notifier).checkForUpdates();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(updateProvider);

    if (state.isMandatory) {
      // Non-dismissible, non-skippable takeover. There is no back button, no
      // bottom nav: the only way out is to download and install. Any in-flight
      // navigation is simply hidden underneath until the update is installed.
      return const UpdateRequiredScreen();
    }

    return widget.child;
  }
}