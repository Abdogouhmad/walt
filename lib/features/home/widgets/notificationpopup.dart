import 'package:flutter/material.dart';
import 'package:walt/core/utils/context.dart';

class NotificationDropdown extends StatelessWidget {
  final List<Map<String, String>> notifications;

  const NotificationDropdown({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorAppScheme;

    return MenuAnchor(
      alignmentOffset: Offset(0, context.h(8)),
      style: MenuStyle(
        minimumSize: WidgetStatePropertyAll(Size(context.w(300), 0)),
        maximumSize:
            WidgetStatePropertyAll(Size(context.w(300), context.h(380))),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: context.h(8)),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.r(16)),
          ),
        ),
        elevation: const WidgetStatePropertyAll(3),
        surfaceTintColor: WidgetStatePropertyAll(colorScheme.surfaceTint),
      ),
      builder: (context, controller, child) {
        return IconButton(
          onPressed: () {
            controller.isOpen ? controller.close() : controller.open();
          },
          icon: Badge(
            isLabelVisible: notifications.isNotEmpty,
            backgroundColor: colorScheme.primary,
            label: notifications.isNotEmpty
                ? Text(notifications.length.toString())
                : null,
            child: Icon(
              Icons.notifications_outlined,
              color: colorScheme.onSurface,
            ),
          ),
        );
      },
      menuChildren: notifications.isEmpty
          ? [_buildEmptyState(context)]
          : notifications
                .map(
                  (notif) =>
                      _NotifTile(title: notif["title"]!, time: notif["time"]!),
                )
                .toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = context.colorAppScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: context.w(300),
        maxWidth: context.w(300),
        maxHeight: context.h(380),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(24),
          vertical: context.h(48),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: context.w(64),
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: context.h(16)),
            Text(
              'No notifications yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: context.sp(16),
              ),
            ),
            SizedBox(height: context.h(8)),
            Text(
              'You\'re all caught up!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: context.sp(14),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final String title;
  final String time;

  const _NotifTile({required this.title, required this.time});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: context.w(20),
        vertical: context.h(6),
      ),
      leading: CircleAvatar(
        radius: context.r(20),
        backgroundColor: colorScheme.primaryContainer,
        child: Icon(
          Icons.info_outline_rounded,
          size: context.w(20),
          color: colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        title,
        style: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
          fontSize: context.sp(16),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        time,
        style: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontSize: context.sp(12),
        ),
      ),
    );
  }
}
