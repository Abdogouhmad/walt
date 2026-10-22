import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether a modal sheet is on screen right now.
///
/// A sheet is pushed on the **root** navigator, so it paints *over* the app
/// shell: the floating nav pill and the FAB end up behind the modal barrier,
/// dimmed and then covered by the sheet itself. The shell watches this signal
/// and slides its chrome out of the way while a sheet is open, so the two never
/// fight for the same pixels.
///
/// The signal lives in the design system because both halves of the problem do:
/// the sheet that raises it and the chrome that has to yield to it.
final modalSheetOpenProvider = NotifierProvider<ModalSheetSignal, bool>(
  ModalSheetSignal.new,
);

/// Tracks how many modal sheets are stacked and exposes that as one flag.
///
/// Sheets can nest — a sheet may open another — so the count is what decides
/// whether the chrome may come back: only when the *last* sheet closes.
class ModalSheetSignal extends Notifier<bool> {
  int _depth = 0;

  @override
  bool build() {
    _depth = 0;
    return false;
  }

  /// Raises the flag: a sheet has been pushed.
  void open() {
    _depth++;
    state = true;
  }

  /// Lowers the flag: a sheet has been dismissed.
  void close() {
    if (_depth > 0) _depth--;
    state = _depth > 0;
  }
}
