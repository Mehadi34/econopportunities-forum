import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../models/post_model.dart';
import '../models/announcement_model.dart';
import '../models/resource_model.dart';
import '../models/notification_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== USERS ====================

  Stream<UserModel?> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
          (doc) => doc.exists ? UserModel.fromFirestore(doc) : null,
        );
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? UserModel.fromFirestore(doc) : null;
  }

  Stream<List<UserModel>> getUsersStream({
    UserRole? role,
    bool? isActive,
    String? searchQuery,
  }) {
    Query<Map<String, dynamic>> query = _db.collection('users');

    if (role != null) {
      query = query.where('role', isEqualTo: role.name);
    }
    if (isActive != null) {
      query = query.where('isActive', isEqualTo: isActive);
    }

    return query.orderBy('displayName').snapshots().map((snapshot) {
      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return users.where((u) {
          return u.displayName.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              (u.department?.toLowerCase().contains(q) ?? false) ||
              u.skills.any((s) => s.toLowerCase().contains(q)) ||
              u.interests.any((i) => i.toLowerCase().contains(q));
        }).toList();
      }

      return users;
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('users').doc(uid).update(data);
  }

  Future<void> updateUserRole(String uid, UserRole role) async {
    await _db.collection('users').doc(uid).update({'role': role.name});
  }

  Future<void> updateFcmToken(String uid, String token) async {
    await _db.collection('users').doc(uid).update({'fcmToken': token});
  }

  // ==================== EVENTS ====================

  Stream<List<EventModel>> getEventsStream({
    EventStatus? status,
    EventCategory? category,
    bool publishedOnly = true,
  }) {
    Query<Map<String, dynamic>> query = _db.collection('events');

    if (publishedOnly) {
      query = query.where('isPublished', isEqualTo: true);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }

    return query
        .orderBy('startDateTime', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => EventModel.fromFirestore(d)).toList());
  }

  Future<EventModel?> getEvent(String id) async {
    final doc = await _db.collection('events').doc(id).get();
    return doc.exists ? EventModel.fromFirestore(doc) : null;
  }

  Stream<EventModel?> getEventStream(String id) {
    return _db.collection('events').doc(id).snapshots().map(
          (doc) => doc.exists ? EventModel.fromFirestore(doc) : null,
        );
  }

  Future<String> createEvent(EventModel event) async {
    final doc = await _db.collection('events').add(event.toFirestore());
    return doc.id;
  }

  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('events').doc(id).update(data);
  }

  Future<void> deleteEvent(String id) async {
    await _db.collection('events').doc(id).delete();
  }

  Future<void> registerForEvent(String eventId, String userId) async {
    await _db.collection('events').doc(eventId).update({
      'registeredUsers': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> unregisterFromEvent(String eventId, String userId) async {
    await _db.collection('events').doc(eventId).update({
      'registeredUsers': FieldValue.arrayRemove([userId]),
    });
  }

  // ==================== POSTS ====================

  Stream<List<PostModel>> getPostsStream({
    PostCategory? category,
    String? authorId,
    bool approvedOnly = true,
  }) {
    Query<Map<String, dynamic>> query = _db.collection('posts');

    if (approvedOnly) {
      query = query.where('isApproved', isEqualTo: true);
    }
    query = query.where('isDeleted', isEqualTo: false);

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }
    if (authorId != null) {
      query = query.where('authorId', isEqualTo: authorId);
    }

    return query
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => PostModel.fromFirestore(d)).toList());
  }

  Future<PostModel?> getPost(String id) async {
    final doc = await _db.collection('posts').doc(id).get();
    return doc.exists ? PostModel.fromFirestore(doc) : null;
  }

  Stream<PostModel?> getPostStream(String id) {
    return _db.collection('posts').doc(id).snapshots().map(
          (doc) => doc.exists ? PostModel.fromFirestore(doc) : null,
        );
  }

  Future<String> createPost(PostModel post) async {
    final doc = await _db.collection('posts').add(post.toFirestore());
    return doc.id;
  }

  Future<void> updatePost(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('posts').doc(id).update(data);
  }

  Future<void> deletePost(String id) async {
    await _db.collection('posts').doc(id).update({'isDeleted': true});
  }

  Future<void> togglePostLike(String postId, String userId) async {
    final doc = await _db.collection('posts').doc(postId).get();
    final post = PostModel.fromFirestore(doc);
    if (post.isLikedBy(userId)) {
      await _db.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } else {
      await _db.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayUnion([userId]),
      });
    }
  }

  // ==================== COMMENTS ====================

  Stream<List<CommentModel>> getCommentsStream(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => CommentModel.fromFirestore(d)).toList());
  }

  Future<String> createComment(String postId, CommentModel comment) async {
    final doc = await _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add(comment.toFirestore());

    await _db.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });

    return doc.id;
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update({'isDeleted': true});

    await _db.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(-1),
    });
  }

  // ==================== ANNOUNCEMENTS ====================

  Stream<List<AnnouncementModel>> getAnnouncementsStream({
    bool publishedOnly = true,
  }) {
    Query<Map<String, dynamic>> query = _db.collection('announcements');

    if (publishedOnly) {
      query = query.where('isPublished', isEqualTo: true);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => AnnouncementModel.fromFirestore(d)).toList());
  }

  Future<String> createAnnouncement(AnnouncementModel announcement) async {
    final doc = await _db
        .collection('announcements')
        .add(announcement.toFirestore());
    return doc.id;
  }

  Future<void> updateAnnouncement(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('announcements').doc(id).update(data);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.collection('announcements').doc(id).delete();
  }

  Future<void> markAnnouncementRead(String id, String userId) async {
    await _db.collection('announcements').doc(id).update({
      'readBy': FieldValue.arrayUnion([userId]),
    });
  }

  // ==================== RESOURCES ====================

  Stream<List<ResourceModel>> getResourcesStream({
    ResourceCategory? category,
    ResourceType? type,
  }) {
    Query<Map<String, dynamic>> query =
        _db.collection('resources').where('isPublished', isEqualTo: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }
    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ResourceModel.fromFirestore(d)).toList());
  }

  Future<String> createResource(ResourceModel resource) async {
    final doc = await _db.collection('resources').add(resource.toFirestore());
    return doc.id;
  }

  Future<void> deleteResource(String id) async {
    await _db.collection('resources').doc(id).delete();
  }

  Future<void> incrementDownloadCount(String id) async {
    await _db.collection('resources').doc(id).update({
      'downloadCount': FieldValue.increment(1),
    });
  }

  // ==================== NOTIFICATIONS ====================

  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => NotificationModel.fromFirestore(d)).toList());
  }

  Stream<int> getUnreadNotificationCount(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Future<void> markNotificationRead(String id) async {
    await _db.collection('notifications').doc(id).update({'isRead': true});
  }

  Future<void> markAllNotificationsRead(String userId) async {
    final batch = _db.batch();
    final snapshot = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<String> createNotification(NotificationModel notification) async {
    final doc = await _db
        .collection('notifications')
        .add(notification.toFirestore());
    return doc.id;
  }

  // ==================== ANALYTICS ====================

  Future<Map<String, dynamic>> getAnalytics() async {
    final futures = await Future.wait([
      _db.collection('users').count().get(),
      _db.collection('events').count().get(),
      _db.collection('posts').where('isDeleted', isEqualTo: false).count().get(),
      _db.collection('announcements').count().get(),
      _db.collection('resources').count().get(),
    ]);

    return {
      'totalUsers': futures[0].count ?? 0,
      'totalEvents': futures[1].count ?? 0,
      'totalPosts': futures[2].count ?? 0,
      'totalAnnouncements': futures[3].count ?? 0,
      'totalResources': futures[4].count ?? 0,
    };
  }
}
