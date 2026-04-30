import 'package:cloud_firestore/cloud_firestore.dart';

enum EventStatus { upcoming, ongoing, completed, cancelled }
enum EventCategory { workshop, seminar, networking, competition, social, other }

class EventModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String createdBy;
  final String createdByName;
  final EventCategory category;
  final EventStatus status;
  final int maxAttendees;
  final List<String> registeredUsers;
  final String? imageUrl;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> tags;
  final bool requiresApproval;
  final String? meetingLink;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startDateTime,
    required this.endDateTime,
    required this.createdBy,
    required this.createdByName,
    this.category = EventCategory.other,
    this.status = EventStatus.upcoming,
    this.maxAttendees = 0,
    this.registeredUsers = const [],
    this.imageUrl,
    this.isPublished = true,
    required this.createdAt,
    this.updatedAt,
    this.tags = const [],
    this.requiresApproval = false,
    this.meetingLink,
  });

  bool get isFull => maxAttendees > 0 && registeredUsers.length >= maxAttendees;
  int get availableSpots => maxAttendees > 0 ? maxAttendees - registeredUsers.length : -1;
  int get attendeeCount => registeredUsers.length;

  bool isUserRegistered(String userId) => registeredUsers.contains(userId);

  String get categoryDisplayName {
    switch (category) {
      case EventCategory.workshop:
        return 'Workshop';
      case EventCategory.seminar:
        return 'Seminar';
      case EventCategory.networking:
        return 'Networking';
      case EventCategory.competition:
        return 'Competition';
      case EventCategory.social:
        return 'Social';
      case EventCategory.other:
        return 'Other';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case EventStatus.upcoming:
        return 'Upcoming';
      case EventStatus.ongoing:
        return 'Ongoing';
      case EventStatus.completed:
        return 'Completed';
      case EventStatus.cancelled:
        return 'Cancelled';
    }
  }

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      startDateTime: (data['startDateTime'] as Timestamp).toDate(),
      endDateTime: (data['endDateTime'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? '',
      category: _categoryFromString(data['category'] ?? 'other'),
      status: _statusFromString(data['status'] ?? 'upcoming'),
      maxAttendees: data['maxAttendees'] ?? 0,
      registeredUsers: List<String>.from(data['registeredUsers'] ?? []),
      imageUrl: data['imageUrl'],
      isPublished: data['isPublished'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      tags: List<String>.from(data['tags'] ?? []),
      requiresApproval: data['requiresApproval'] ?? false,
      meetingLink: data['meetingLink'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'category': category.name,
      'status': status.name,
      'maxAttendees': maxAttendees,
      'registeredUsers': registeredUsers,
      'imageUrl': imageUrl,
      'isPublished': isPublished,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'tags': tags,
      'requiresApproval': requiresApproval,
      'meetingLink': meetingLink,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? createdBy,
    String? createdByName,
    EventCategory? category,
    EventStatus? status,
    int? maxAttendees,
    List<String>? registeredUsers,
    String? imageUrl,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    bool? requiresApproval,
    String? meetingLink,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      category: category ?? this.category,
      status: status ?? this.status,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      registeredUsers: registeredUsers ?? this.registeredUsers,
      imageUrl: imageUrl ?? this.imageUrl,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      meetingLink: meetingLink ?? this.meetingLink,
    );
  }

  static EventCategory _categoryFromString(String value) {
    return EventCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EventCategory.other,
    );
  }

  static EventStatus _statusFromString(String value) {
    return EventStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EventStatus.upcoming,
    );
  }
}
