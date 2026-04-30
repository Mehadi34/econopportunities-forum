import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/post_model.dart';
import '../../providers/forum_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/user_avatar.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike(PostModel post, String userId) async {
    try {
      await ref
          .read(firestoreServiceProvider)
          .togglePostLike(post.id, userId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _submitComment(PostModel post, String userId, String displayName,
      String? photoUrl) async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final comment = CommentModel(
        id: '',
        postId: post.id,
        content: content,
        authorId: userId,
        authorName: displayName,
        authorPhotoUrl: photoUrl,
        createdAt: DateTime.now(),
      );
      await ref
          .read(firestoreServiceProvider)
          .createComment(post.id, comment);
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(firestoreServiceProvider).deletePost(postId);
    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Post deleted')));
    }
  }

  Future<void> _deleteComment(String postId, String commentId) async {
    await ref
        .read(firestoreServiceProvider)
        .deleteComment(postId, commentId);
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final commentsAsync = ref.watch(commentsProvider(widget.postId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isModerator = ref.watch(isModeratorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussion'),
        actions: postAsync.valueOrNull != null
            ? [
                if (currentUser != null &&
                    (postAsync.value!.authorId == currentUser.uid ||
                        isModerator))
                  PopupMenuButton(
                    itemBuilder: (_) => [
                      if (postAsync.value!.authorId == currentUser.uid)
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Edit'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: AppColors.error),
                          title: Text('Delete',
                              style: TextStyle(color: AppColors.error)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    onSelected: (v) {
                      if (v == 'delete') _deletePost(widget.postId);
                    },
                  ),
              ]
            : null,
      ),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (post) {
          if (post == null) {
            return const Center(child: Text('Post not found'));
          }
          final isLiked =
              currentUser != null && post.isLikedBy(currentUser.uid);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _PostContent(
                      post: post,
                      isLiked: isLiked,
                      onLike: currentUser != null
                          ? () => _toggleLike(post, currentUser.uid)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    commentsAsync.when(
                      loading: () => const Center(
                          child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      )),
                      error: (e, _) =>
                          Center(child: Text('Error loading comments: $e')),
                      data: (comments) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${comments.length} Comments',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          ...comments.map(
                            (c) => _CommentCard(
                              comment: c,
                              canDelete: currentUser != null &&
                                  (c.authorId == currentUser.uid ||
                                      isModerator),
                              onDelete: () =>
                                  _deleteComment(post.id, c.id),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (currentUser != null) ...[
                const Divider(height: 1),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    8 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Row(
                    children: [
                      UserAvatar(
                        photoUrl: currentUser.photoUrl,
                        displayName: currentUser.displayName,
                        radius: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Write a comment...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          maxLines: 3,
                          minLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _submitComment(
                                  post,
                                  currentUser.uid,
                                  currentUser.displayName,
                                  currentUser.photoUrl,
                                ),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PostContent extends StatelessWidget {
  final PostModel post;
  final bool isLiked;
  final VoidCallback? onLike;

  const _PostContent({
    required this.post,
    required this.isLiked,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Chip(
              label: Text(post.categoryDisplayName,
                  style: const TextStyle(fontSize: 11)),
              backgroundColor: AppColors.primary.withOpacity(0.1),
              labelStyle: const TextStyle(color: AppColors.primary),
              visualDensity: VisualDensity.compact,
            ),
            if (post.isPinned) ...[
              const SizedBox(width: 8),
              const Icon(Icons.push_pin, size: 16, color: AppColors.warning),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          post.title,
          style:
              Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            UserAvatar(
              photoUrl: post.authorPhotoUrl,
              displayName: post.authorName,
              radius: 18,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.authorName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(timeago.format(post.createdAt),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (post.imageUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(post.imageUrl!, width: double.infinity,
                fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
        ],
        Text(post.content, style: Theme.of(context).textTheme.bodyMedium),
        if (post.tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: post.tags
                .map((t) => Chip(
                      label: Text(t, style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onLike,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? AppColors.error : AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likeCount}',
                      style: TextStyle(
                        color: isLiked
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Row(
              children: [
                const Icon(Icons.comment_outlined,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${post.commentCount}',
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  final CommentModel comment;
  final bool canDelete;
  final VoidCallback onDelete;

  const _CommentCard({
    required this.comment,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            photoUrl: comment.authorPhotoUrl,
            displayName: comment.authorName,
            radius: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.authorName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(timeago.format(comment.createdAt),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                    if (canDelete) ...[
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: AppColors.error),
                        onPressed: onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(comment.content,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
