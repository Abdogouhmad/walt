import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Appearance → "Reduce transparency".
///
/// Owned by the design system rather than the app: frosted surfaces are a UI
/// concern, and the nav pill — which lives here — has to honour the setting
/// too. The app overrides this provider with the user's stored choice; the
/// default is "off", so a surface rendered outside the app (a test, a preview)
/// is never accidentally opaque.
final reduceTransparencyProvider = Provider<bool>((ref) => false);
