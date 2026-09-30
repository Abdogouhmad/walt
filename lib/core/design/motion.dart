/// Compatibility shim: the canonical motion tokens now live in
/// `core/theme/motion.dart` (they are theme, not "design constants").
///
/// This file is kept so existing `import 'package:walt/core/design/motion.dart'`
/// call sites keep resolving. New code should import
/// `package:walt/core/theme/motion.dart` directly.
library;

export '../theme/motion.dart';
