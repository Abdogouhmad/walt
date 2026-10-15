import 'package:flutter/material.dart';

/// The Walt brand mark — the shipped launcher icon, drawn as a widget.
///
/// The asset (`assets/icon/walt_icon.png`) is a full-bleed squircle whose
/// transparent corners already trace the app-icon silhouette, so it is shown
/// unclipped at any [size]. Going through this widget instead of a raw
/// [Image.asset] also keeps the decode cheap: the source is 1024×1024 (~4 MB
/// once decoded), so it is down-sampled to the pixels actually drawn instead of
/// being held at full resolution in the image cache.
class WaltLogo extends StatelessWidget {
  const WaltLogo({super.key, this.size = 40, this.semanticLabel = 'Walt'});

  /// Edge length of the square mark, in logical pixels.
  final double size;

  /// Screen-reader description. Pass `null` when a label already says it.
  final String? semanticLabel;

  static const String _asset = 'assets/icon/walt_icon.png';

  @override
  Widget build(BuildContext context) {
    // Decode at draw size: 1024² RGBA is ~4 MB in the image cache, while a
    // 40 dp mark at 3× is only ~120² (~56 KB). The source is square, so the
    // width alone fixes the height and the aspect ratio can never distort.
    final decode = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return Image.asset(
      _asset,
      width: size,
      height: size,
      cacheWidth: decode,
      filterQuality: FilterQuality.medium,
      semanticLabel: semanticLabel,
      gaplessPlayback: true,
    );
  }
}
