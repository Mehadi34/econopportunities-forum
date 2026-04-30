import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/announcement_model.dart';
import '../../providers/announcements_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/empty_state.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isModerator = ref.watch(isModeratorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        actions: isModerator
            ? [
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Create Announcement',
                  onPressed: () => context.push('/admin/announcements/create'),
                ),
              ]
            : null,
      ),
      body: announcementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(announcementsProvider),
        ),
        data: (announcements) {
          if (announcements.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.campaign_outlined,
              title: 'No announcements yet',
              subtitle: 'Check back later for updates from the team',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(announcementsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: announcements.length,
              itemBuilder: (_, i) => _AnnouncementCard(
                announcement: announcements[i],
                currentUserId: currentUser?.uid,
                onTap: () async {
                  if (currentUser != null &&
                      !announcements[i].isReadBy(currentUser.uid)) {
                    await ref
                        .read(firestoreServiceProvider)
                        .markAnnouncementRead(
                            announcements[i].id, currentUser.uid);
                  }
                  if (context.mounted) {
                    context.push(
                        '/announcements/${announcements[i].id}');
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final String? currentUserId;
  final VoidCallback onTap;

  const _AnnouncementCard({
    required this.announcement,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = currentUserId != null &&
        announcement.isReadBy(currentUserId!);
    final isImportant = announcement.isImportant;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isImportant
            ? const BorderSide(color: AppColors.warning, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isImportant) ...[
                    const Icon(Icons.priority_high,
                        color: AppColors.warning, size: 18),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'IMPORTANT',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                    ),
                  ),
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                announcement.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    announcement.authorName,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const Spacer(),
                  const Icon(Icons.access_time,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(announcement.createdAt),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
