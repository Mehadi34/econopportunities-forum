import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/post_model.dart';
import '../../providers/forum_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/user_avatar.dart';

class ManageForumScreen extends ConsumerStatefulWidget {
  const ManageForumScreen({super.key});

  @override
  ConsumerState<ManageForumScreen> createState() =>
      _ManageForumScreenState();
}

class _ManageForumScreenState extends ConsumerState<ManageForumScreen> {
  bool _showPendingOnly = false;

  Future<void> _approvePost(PostModel post) async {
    try {
      await ref
          .read(firestoreServiceProvider)
          .updatePost(post.id, {'isApproved': true});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post by ${post.authorName} approved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _togglePin(PostModel post) async {
    try {
      await ref.read(firestoreServiceProvider).updatePost(post.id, {
        'isPinned': !post.isPinned,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  post.isPinned ? 'Post unpinned' : 'Post pinned')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deletePost(PostModel post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Post'),
        content: Text(
            'Delete "${post.title}" by ${post.authorName}? Cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(firestoreServiceProvider).deletePost(post.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Post deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(allPostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Forum'),
        actions: [
          Row(
            children: [
              const Text('Pending',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
              Switch(
                value: _showPendingOnly,
                onChanged: (v) => setState(() => _showPendingOnly = v),
                activeColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(message: e.toString()),
        data: (posts) {
          var filtered = posts;
          if (_showPendingOnly) {
            filtered = filtered.where((p) => !p.isApproved).toList();
          }

          if (filtered.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.forum_outlined,
              title: _showPendingOnly
                  ? 'No pending posts'
                  : 'No posts yet',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _AdminPostCard(
              post: filtered[i],
              onApprove: filtered[i].isApproved
                  ? null
                  : () => _approvePost(filtered[i]),
              onTogglePin: () => _togglePin(filtered[i]),
              onDelete: () => _deletePost(filtered[i]),
              onView: () => context.push('/forum/${filtered[i].id}'),
            ),
          );
        },
      ),
    );
  }
}

class _AdminPostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onApprove;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const _AdminPostCard({
    required this.post,
    required this.onApprove,
    required this.onTogglePin,
    required this.onDelete,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  photoUrl: post.authorPhotoUrl,
                  displayName: post.authorName,
                  radius: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(timeago.format(post.createdAt),
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11)),
                    ],
                  ),
                ),
                if (!post.isApproved)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PENDING',
                      style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                if (post.isPinned) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.push_pin,
                      size: 16, color: AppColors.warning),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post.title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              post.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: [
                if (onApprove != null)
                  ActionChip(
                    label: const Text('Approve',
                        style: TextStyle(fontSize: 11)),
                    avatar: const Icon(Icons.check, size: 14),
                    backgroundColor: AppColors.success.withOpacity(0.1),
                    labelStyle: const TextStyle(color: AppColors.success),
                    onPressed: onApprove,
                    visualDensity: VisualDensity.compact,
                  ),
                ActionChip(
                  label: Text(post.isPinned ? 'Unpin' : 'Pin',
                      style: const TextStyle(fontSize: 11)),
                  avatar: Icon(
                    post.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                    size: 14,
                  ),
                  backgroundColor: AppColors.warning.withOpacity(0.1),
                  labelStyle: const TextStyle(color: AppColors.warning),
                  onPressed: onTogglePin,
                  visualDensity: VisualDensity.compact,
                ),
                ActionChip(
                  label: const Text('View', style: TextStyle(fontSize: 11)),
                  avatar: const Icon(Icons.visibility, size: 14),
                  onPressed: onView,
                  visualDensity: VisualDensity.compact,
                ),
                ActionChip(
                  label:
                      const Text('Delete', style: TextStyle(fontSize: 11)),
                  avatar: const Icon(Icons.delete, size: 14, color: AppColors.error),
                  backgroundColor: AppColors.error.withOpacity(0.1),
                  labelStyle: const TextStyle(color: AppColors.error),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
