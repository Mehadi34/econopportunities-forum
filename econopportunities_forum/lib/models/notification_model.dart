import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  newEvent,
  eventReminder,
  eventUpdate,
  newAnnouncement,
  newPost,
  commentOnPost,
  likeOnPost,
  newMember,
  roleChanged,
  mention,
  newResource,
  eventRegistration,
  general,
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;
  final String? imageUrl;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
    this.imageUrl,
    this.data,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final docData = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: docData['userId'] ?? '',
      title: docData['title'] ?? '',
      body: docData['body'] ?? '',
      type: _typeFromString(docData['type'] ?? 'general'),
      relatedId: docData['relatedId'],
      isRead: docData['isRead'] ?? false,
      createdAt: (docData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: docData['imageUrl'],
      data: docData['data'] != null
          ? Map<String, dynamic>.from(docData['data'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
      'data': data,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    String? relatedId,
    bool? isRead,
    DateTime? createdAt,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
    );
  }

  static NotificationType _typeFromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.general,
    );
  }
}
