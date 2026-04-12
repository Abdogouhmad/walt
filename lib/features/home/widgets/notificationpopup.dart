import 'package:flutter/material.dart';
import 'package:walt/core/utils/context.dart';

class NotificationDropdown extends StatelessWidget {
  final List<Map<String, String>> notifications;

  const NotificationDropdown({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorAppScheme;

    return MenuAnchor(
      alignmentOffset: const Offset(0, 8),
      style: MenuStyle(
        minimumSize: const WidgetStatePropertyAll(Size(300, 0)),
        maximumSize: const WidgetStatePropertyAll(Size(300, 380)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 8),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      constraints: const BoxConstraints(
        minWidth: 300,
        maxWidth: 300,
        maxHeight: 380,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: colorScheme.primaryContainer,
        child: Icon(
          Icons.info_outline_rounded,
          size: 20,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        title,
        style: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        time,
        style: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
