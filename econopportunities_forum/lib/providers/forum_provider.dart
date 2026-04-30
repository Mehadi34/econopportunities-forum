import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';

final postsProvider =
    StreamProvider.family<List<PostModel>, PostCategory?>((ref, category) {
  return ref
      .watch(firestoreServiceProvider)
      .getPostsStream(category: category);
});

final allPostsProvider = StreamProvider<List<PostModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getPostsStream();
});

final postDetailProvider =
    StreamProvider.family<PostModel?, String>((ref, id) {
  return ref.watch(firestoreServiceProvider).getPostStream(id);
});

final commentsProvider =
    StreamProvider.family<List<CommentModel>, String>((ref, postId) {
  return ref.watch(firestoreServiceProvider).getCommentsStream(postId);
});
