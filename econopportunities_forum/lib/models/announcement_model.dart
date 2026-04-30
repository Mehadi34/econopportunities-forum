import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String? imageUrl;
  final bool isImportant;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;
  final List<String> readBy;
  final String? link;
  final String? linkText;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.imageUrl,
    this.isImportant = false,
    this.isPublished = true,
    required this.createdAt,
    this.updatedAt,
    this.expiresAt,
    this.readBy = const [],
    this.link,
    this.linkText,
  });

  bool isReadBy(String userId) => readBy.contains(userId);
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      imageUrl: data['imageUrl'],
      isImportant: data['isImportant'] ?? false,
      isPublished: data['isPublished'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      readBy: List<String>.from(data['readBy'] ?? []),
      link: data['link'],
      linkText: data['linkText'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'imageUrl': imageUrl,
      'isImportant': isImportant,
      'isPublished': isPublished,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'readBy': readBy,
      'link': link,
      'linkText': linkText,
    };
  }

  AnnouncementModel copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    String? imageUrl,
    bool? isImportant,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    List<String>? readBy,
    String? link,
    String? linkText,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      imageUrl: imageUrl ?? this.imageUrl,
      isImportant: isImportant ?? this.isImportant,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      readBy: readBy ?? this.readBy,
      link: link ?? this.link,
      linkText: linkText ?? this.linkText,
    );
  }
}
