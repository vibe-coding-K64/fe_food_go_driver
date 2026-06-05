import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/notification_state.dart';

class NotificationItem extends StatelessWidget {
  final DriverNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationItem({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  IconData _iconForType(int type) {
    switch (type) {
      case 11:
        return Icons.delivery_dining;
      case 12:
        return Icons.check_circle;
      case 13:
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(int type) {
    switch (type) {
      case 11:
        return AppColors.info;
      case 12:
        return AppColors.success;
      case 13:
        return AppColors.errorLight;
      default:
        return AppColors.primaryLight;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';

    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _colorForType(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.errorLight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        elevation: notification.isRead ? 0 : 1,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: notification.isRead
            ? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
            : (isDark
                ? AppColors.primaryContainerDark.withValues(alpha: 0.3)
                : AppColors.primaryLight.withValues(alpha: 0.05)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_iconForType(notification.type),
                      color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.onSurfaceDark
                                    : AppColors.onSurfaceLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.errorLight,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.onBackgroundDark
                              : AppColors.onBackgroundLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.outlineDark
                              : AppColors.outlineLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
