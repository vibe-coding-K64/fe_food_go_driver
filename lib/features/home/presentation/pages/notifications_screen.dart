import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../notifications/presentation/bloc/notification_bloc.dart';
import '../../../notifications/presentation/bloc/notification_event.dart';
import '../../../notifications/presentation/bloc/notification_state.dart';
import '../../../notifications/presentation/widgets/notification_item.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          NotificationBloc()..add(const LoadNotifications()),
      child: const _NotificationsScreenContent(),
    );
  }
}

class _NotificationsScreenContent extends StatelessWidget {
  const _NotificationsScreenContent();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        final hasUnread = state.unreadCount > 0;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.notifications),
            automaticallyImplyLeading: false,
            actions: [
              if (hasUnread)
                TextButton.icon(
                  onPressed: () {
                    context
                        .read<NotificationBloc>()
                        .add(const MarkAllNotificationsRead());
                  },
                  icon: Icon(Icons.done_all, color: primaryColor, size: 20),
                  label: Text(
                    l10n.markAllRead,
                    style: TextStyle(color: primaryColor, fontSize: 13),
                  ),
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context
                  .read<NotificationBloc>()
                  .add(const LoadNotifications());
            },
            child: _buildBody(context, state, isDark, primaryColor, l10n),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    NotificationState state,
    bool isDark,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
    if (state.status == NotificationLoadStatus.loading &&
        state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == NotificationLoadStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.errorLight,
            ),
            const SizedBox(height: 16),
            Text(state.errorMessage ?? 'Error loading notifications'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context
                    .read<NotificationBloc>()
                    .add(const LoadNotifications());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noNotifications,
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? AppColors.onBackgroundDark
                    : AppColors.onBackgroundLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.notifications.length,
      itemBuilder: (context, index) {
        final notification = state.notifications[index];
        return NotificationItem(
          notification: notification,
          onTap: () {
            final orderId = notification.orderId ?? notification.referenceId;
            if (orderId != null && orderId.isNotEmpty) {
              context
                  .read<NotificationBloc>()
                  .add(MarkNotificationRead(notification.id));
            }
          },
          onDismiss: () {
            context
                .read<NotificationBloc>()
                .add(DeleteNotification(notification.id));
          },
        );
      },
    );
  }
}
