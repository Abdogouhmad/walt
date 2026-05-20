import 'package:flutter/material.dart';
import 'package:walt/core/constants/app_colors.dart';
import 'package:walt/core/utils/context.dart';
import 'package:walt/shared/bottons.dart';
import 'package:walt/shared/text_ui.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final double? topPadding;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onActionPressed,
    this.topPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(
          top: topPadding ?? context.h(60),
          left: context.w(32),
          right: context.w(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(context.w(24)),
              decoration: BoxDecoration(
                color: context.colorAppScheme.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: context.w(48),
                color: context.colorAppScheme.primary.withAlpha(150),
              ),
            ),
            SizedBox(height: context.h(24)),
            UiText(
              text: title,
              type: UiTextType.titleLarge,
              style: TextStyle(
                color: context.colorAppScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.h(8)),
            UiText(
              text: subtitle,
              type: UiTextType.bodyMedium,
              style: TextStyle(color: context.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              SizedBox(height: context.h(32)),
              AppButton(
                label: actionLabel!,
                onPressed: onActionPressed!,
                type: ButtonType.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
