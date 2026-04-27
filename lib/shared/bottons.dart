import 'package:flutter/material.dart';

enum ButtonType { primary, secondary, text, textIcon, iconOnly, fab }

enum ButtonSize { small, medium, large, extended }

class AppButton extends StatelessWidget {
  final String? label;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isDestructive;
  final bool isFullWidth;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;

  const AppButton({
    super.key,
    this.label,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isDestructive = false,
    this.isFullWidth = false,
    this.iconColor,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
  }) : assert(
         type == ButtonType.iconOnly || type == ButtonType.fab || label != null,
         'label is required unless type is iconOnly or fab',
       ),
       assert(
         type != ButtonType.textIcon &&
                 type != ButtonType.iconOnly &&
                 type != ButtonType.fab ||
             icon != null,
         'icon is required for textIcon, iconOnly, and fab types',
       ),
       assert(
         type != ButtonType.fab || size != ButtonSize.extended || label != null,
         'label is required for extended FAB',
       );

  // ── sizing ────────────────────────────────────────────────────────────────

  double get _fontSize => switch (size) {
    ButtonSize.small => 13,
    ButtonSize.medium => 15,
    ButtonSize.large => 17,
    ButtonSize.extended => 15,
  };

  EdgeInsets get _padding => switch (size) {
    ButtonSize.small => const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ButtonSize.medium => const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 12,
    ),
    ButtonSize.large => const EdgeInsets.symmetric(
      horizontal: 28,
      vertical: 16,
    ),
    ButtonSize.extended => const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 12,
    ),
  };

  double get _iconSize => switch (size) {
    ButtonSize.small => 16,
    ButtonSize.medium => 20,
    ButtonSize.large => 24,
    ButtonSize.extended => 24,
  };

  double get _spinnerSize => switch (size) {
    ButtonSize.small => 14,
    ButtonSize.medium => 18,
    ButtonSize.large => 22,
    ButtonSize.extended => 18,
  };

  // ── helpers ───────────────────────────────────────────────────────────────

  VoidCallback? get _effectiveCallback => isLoading ? null : onPressed;

  Widget _spinner(Color color) => SizedBox(
    width: _spinnerSize,
    height: _spinnerSize,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      valueColor: AlwaysStoppedAnimation(color),
    ),
  );

  Widget _wrap(Widget child) =>
      isFullWidth ? SizedBox(width: double.infinity, child: child) : child;

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _wrap(switch (type) {
      ButtonType.primary => _buildPrimary(cs),
      ButtonType.secondary => _buildSecondary(cs),
      ButtonType.text => _buildText(cs),
      ButtonType.textIcon => _buildTextIcon(cs),
      ButtonType.iconOnly => _buildIconOnly(cs),
      ButtonType.fab => _buildFab(cs),
    });
  }

  Widget _buildPrimary(ColorScheme cs) {
    final bg = backgroundColor ?? (isDestructive ? cs.error : cs.primary);
    final fg = foregroundColor ?? (isDestructive ? cs.onError : cs.onPrimary);

    return ElevatedButton(
      onPressed: _effectiveCallback,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        padding: _padding,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w600),
        minimumSize: isFullWidth ? const Size(double.infinity, 0) : null,
      ),
      child: isLoading ? _spinner(fg) : Text(label!),
    );
  }

  Widget _buildSecondary(ColorScheme cs) {
    final color = foregroundColor ?? (isDestructive ? cs.error : cs.primary);

    return OutlinedButton(
      onPressed: _effectiveCallback,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: color),
        padding: _padding,
        textStyle: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w500),
        minimumSize: isFullWidth ? const Size(double.infinity, 0) : null,
      ),
      child: isLoading ? _spinner(color) : Text(label!),
    );
  }

  Widget _buildText(ColorScheme cs) {
    final color = foregroundColor ?? (isDestructive ? cs.error : cs.primary);

    return TextButton(
      onPressed: _effectiveCallback,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: _padding,
        textStyle: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w500),
        minimumSize: isFullWidth ? const Size(double.infinity, 0) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // The Text comes first
          Text(label!),

          // Show icon or spinner only if needed
          if (isLoading || icon != null) ...[
            const SizedBox(width: 5),
            isLoading ? _spinner(color) : Icon(icon, size: _iconSize),
          ],
        ],
      ),
    );
  }

  Widget _buildTextIcon(ColorScheme cs) {
    final color = foregroundColor ?? (isDestructive ? cs.error : cs.primary);

    return TextButton.icon(
      onPressed: _effectiveCallback,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: _padding,
        textStyle: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w500),
        minimumSize: isFullWidth ? const Size(double.infinity, 0) : null,
      ),
      label: Text(label!),
      icon: isLoading ? _spinner(color) : Icon(icon, size: _iconSize),
    );
  }

  Widget _buildIconOnly(ColorScheme cs) {
    final color =
        iconColor ??
        foregroundColor ??
        (isDestructive ? cs.error : cs.onSurfaceVariant);

    return IconButton(
      onPressed: _effectiveCallback,
      icon: isLoading ? _spinner(color) : Icon(icon, size: _iconSize),
      color: color,
      padding: _padding,
      tooltip: tooltip,
      style: IconButton.styleFrom(foregroundColor: color),
    );
  }

  Widget _buildFab(ColorScheme cs) {
    final bg = backgroundColor ?? cs.primaryContainer;
    final fg = foregroundColor ?? cs.onPrimaryContainer;
    final child = isLoading ? _spinner(fg) : Icon(icon, size: _iconSize);

    return switch (size) {
      ButtonSize.small => FloatingActionButton.small(
        onPressed: _effectiveCallback,
        backgroundColor: bg,
        foregroundColor: fg,
        tooltip: tooltip,
        child: child,
      ),
      ButtonSize.large => FloatingActionButton.large(
        onPressed: _effectiveCallback,
        backgroundColor: bg,
        foregroundColor: fg,
        tooltip: tooltip,
        child: child,
      ),
      ButtonSize.extended => FloatingActionButton.extended(
        onPressed: _effectiveCallback,
        backgroundColor: bg,
        foregroundColor: fg,
        tooltip: tooltip,
        icon: isLoading ? _spinner(fg) : Icon(icon, size: _iconSize),
        label: Text(
          label!,
          style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w600),
        ),
      ),
      _ => FloatingActionButton(
        onPressed: _effectiveCallback,
        backgroundColor: bg,
        foregroundColor: fg,
        tooltip: tooltip,
        child: child,
      ),
    };
  }
}
