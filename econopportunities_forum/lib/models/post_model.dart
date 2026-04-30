import 'package:cloud_firestore/cloud_firestore.dart';

enum PostCategory {
  general,
  economics,
  opportunities,
  projects,
  introductions,
  help,
  announcements,
  events,
}

class PostModel {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final PostCategory category;
  final List<String> likes;
  final int commentCount;
  final List<String> tags;
  final bool isPinned;
  final bool isApproved;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? imageUrl;

  PostModel({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    this.category = PostCategory.general,
    this.likes = const [],
    this.commentCount = 0,
    this.tags = const [],
    this.isPinned = false,
    this.isApproved = true,
    this.isDeleted = false,
    required this.createdAt,
    this.updatedAt,
    this.imageUrl,
  });

  int get likeCount => likes.length;
  bool isLikedBy(String userId) => likes.contains(userId);

  String get categoryDisplayName {
    switch (category) {
      case PostCategory.general:
        return 'General';
      case PostCategory.economics:
        return 'Economics';
      case PostCategory.opportunities:
        return 'Opportunities';
      case PostCategory.projects:
        return 'Projects';
      case PostCategory.introductions:
        return 'Introductions';
      case PostCategory.help:
        return 'Help & Questions';
      case PostCategory.announcements:
        return 'Announcements';
      case PostCategory.events:
        return 'Events';
    }
  }

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      category: _categoryFromString(data['category'] ?? 'general'),
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      isPinned: data['isPinned'] ?? false,
      isApproved: data['isApproved'] ?? true,
      isDeleted: data['isDeleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'category': category.name,
      'likes': likes,
      'commentCount': commentCount,
      'tags': tags,
      'isPinned': isPinned,
      'isApproved': isApproved,
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'imageUrl': imageUrl,
    };
  }

  PostModel copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    String? authorPhotoUrl,
    PostCategory? category,
    List<String>? likes,
    int? commentCount,
    List<String>? tags,
    bool? isPinned,
    bool? isApproved,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imageUrl,
  }) {
    return PostModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      category: category ?? this.category,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      isApproved: isApproved ?? this.isApproved,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  static PostCategory _categoryFromString(String value) {
    return PostCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PostCategory.general,
    );
  }
}

class CommentModel {
  final String id;
  final String postId;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final List<String> likes;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? parentCommentId;

  CommentModel({
    required this.id,
    required this.postId,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    this.likes = const [],
    this.isDeleted = false,
    required this.createdAt,
    this.updatedAt,
    this.parentCommentId,
  });

  int get likeCount => likes.length;
  bool isLikedBy(String userId) => likes.contains(userId);

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      postId: data['postId'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      likes: List<String>.from(data['likes'] ?? []),
      isDeleted: data['isDeleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      parentCommentId: data['parentCommentId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'likes': likes,
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'parentCommentId': parentCommentId,
    };
  }
}
