import 'package:cloud_firestore/cloud_firestore.dart';

enum ResourceType { document, pdf, image, video, link, other }
enum ResourceCategory { study, events, templates, gallery, reports, other }

class ResourceModel {
  final String id;
  final String title;
  final String description;
  final String uploadedBy;
  final String uploadedByName;
  final ResourceType type;
  final ResourceCategory category;
  final String? fileUrl;
  final String? thumbnailUrl;
  final String? link;
  final int? fileSize;
  final String? fileName;
  final int downloadCount;
  final List<String> likes;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> tags;

  ResourceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.uploadedBy,
    required this.uploadedByName,
    this.type = ResourceType.other,
    this.category = ResourceCategory.other,
    this.fileUrl,
    this.thumbnailUrl,
    this.link,
    this.fileSize,
    this.fileName,
    this.downloadCount = 0,
    this.likes = const [],
    this.isPublished = true,
    required this.createdAt,
    this.updatedAt,
    this.tags = const [],
  });

  int get likeCount => likes.length;
  bool isLikedBy(String userId) => likes.contains(userId);

  String get typeDisplayName {
    switch (type) {
      case ResourceType.document:
        return 'Document';
      case ResourceType.pdf:
        return 'PDF';
      case ResourceType.image:
        return 'Image';
      case ResourceType.video:
        return 'Video';
      case ResourceType.link:
        return 'Link';
      case ResourceType.other:
        return 'Other';
    }
  }

  String get categoryDisplayName {
    switch (category) {
      case ResourceCategory.study:
        return 'Study Materials';
      case ResourceCategory.events:
        return 'Events';
      case ResourceCategory.templates:
        return 'Templates';
      case ResourceCategory.gallery:
        return 'Gallery';
      case ResourceCategory.reports:
        return 'Reports';
      case ResourceCategory.other:
        return 'Other';
    }
  }

  String get fileSizeFormatted {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '${fileSize}B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  factory ResourceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ResourceModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      uploadedBy: data['uploadedBy'] ?? '',
      uploadedByName: data['uploadedByName'] ?? '',
      type: _typeFromString(data['type'] ?? 'other'),
      category: _categoryFromString(data['category'] ?? 'other'),
      fileUrl: data['fileUrl'],
      thumbnailUrl: data['thumbnailUrl'],
      link: data['link'],
      fileSize: data['fileSize'],
      fileName: data['fileName'],
      downloadCount: data['downloadCount'] ?? 0,
      likes: List<String>.from(data['likes'] ?? []),
      isPublished: data['isPublished'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'uploadedBy': uploadedBy,
      'uploadedByName': uploadedByName,
      'type': type.name,
      'category': category.name,
      'fileUrl': fileUrl,
      'thumbnailUrl': thumbnailUrl,
      'link': link,
      'fileSize': fileSize,
      'fileName': fileName,
      'downloadCount': downloadCount,
      'likes': likes,
      'isPublished': isPublished,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'tags': tags,
    };
  }

  static ResourceType _typeFromString(String value) {
    return ResourceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ResourceType.other,
    );
  }

  static ResourceCategory _categoryFromString(String value) {
    return ResourceCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ResourceCategory.other,
    );
  }
}
