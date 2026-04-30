import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/notification_model.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/empty_state.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (userId == null) return;
    try {
      await ref
          .read(firestoreServiceProvider)
          .markAllNotificationsRead(userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _markRead(WidgetRef ref, String notificationId) async {
    try {
      await ref
          .read(firestoreServiceProvider)
          .markNotificationRead(notificationId);
    } catch (_) {}
  }

  void _navigate(BuildContext context, NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.newEvent:
      case NotificationType.eventReminder:
      case NotificationType.eventUpdate:
      case NotificationType.eventRegistration:
        if (notification.relatedId != null) {
          context.push('/events/${notification.relatedId}');
        }
        break;
      case NotificationType.newAnnouncement:
        if (notification.relatedId != null) {
          context.push('/announcements/${notification.relatedId}');
        }
        break;
      case NotificationType.newPost:
      case NotificationType.commentOnPost:
      case NotificationType.likeOnPost:
      case NotificationType.mention:
        if (notification.relatedId != null) {
          context.push('/forum/${notification.relatedId}');
        }
        break;
      case NotificationType.newMember:
        if (notification.relatedId != null) {
          context.push('/members/${notification.relatedId}');
        }
        break;
      case NotificationType.newResource:
        context.push('/resources');
        break;
      case NotificationType.roleChanged:
      case NotificationType.general:
        break;
    }
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.newEvent:
      case NotificationType.eventReminder:
      case NotificationType.eventUpdate:
      case NotificationType.eventRegistration:
        return Icons.event;
      case NotificationType.newAnnouncement:
        return Icons.campaign;
      case NotificationType.newPost:
        return Icons.forum;
      case NotificationType.commentOnPost:
        return Icons.comment;
      case NotificationType.likeOnPost:
        return Icons.favorite;
      case NotificationType.newMember:
        return Icons.person_add;
      case NotificationType.roleChanged:
        return Icons.manage_accounts;
      case NotificationType.mention:
        return Icons.alternate_email;
      case NotificationType.newResource:
        return Icons.folder;
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  Color _colorForType(NotificationType type) {
    switch (type) {
      case NotificationType.newEvent:
      case NotificationType.eventReminder:
      case NotificationType.eventUpdate:
      case NotificationType.eventRegistration:
        return AppColors.primary;
      case NotificationType.newAnnouncement:
        return AppColors.warning;
      case NotificationType.newPost:
      case NotificationType.commentOnPost:
        return AppColors.secondary;
      case NotificationType.likeOnPost:
        return AppColors.error;
      case NotificationType.newMember:
        return AppColors.success;
      case NotificationType.roleChanged:
        return AppColors.info;
      case NotificationType.mention:
        return AppColors.accent;
      case NotificationType.newResource:
        return AppColors.primaryDark;
      case NotificationType.general:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(context, ref),
            child: const Text('Mark all read',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(message: e.toString()),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.notifications_none,
              title: 'No notifications',
              subtitle: 'You\'re all caught up!',
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final n = notifications[i];
              return _NotificationTile(
                notification: n,
                icon: _iconForType(n.type),
                color: _colorForType(n.type),
                onTap: () async {
                  if (!n.isRead) await _markRead(ref, n.id);
                  if (context.mounted) _navigate(context, n);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: notification.isRead
          ? null
          : AppColors.primary.withOpacity(0.05),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight:
              notification.isRead ? FontWeight.normal : FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notification.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(
            timeago.format(notification.createdAt),
            style: const TextStyle(
                fontSize: 11, color: AppColors.textLight),
          ),
        ],
      ),
      trailing: notification.isRead
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
      isThreeLine: true,
      onTap: onTap,
    );
  }
}
