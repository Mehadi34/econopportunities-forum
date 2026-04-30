import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, moderator, member }

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? bio;
  final String? department;
  final String? year;
  final String? phone;
  final List<String> skills;
  final List<String> interests;
  final UserRole role;
  final bool isEmailVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastSeen;
  final String? fcmToken;
  final Map<String, bool> notificationPreferences;
  final List<String> achievements;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.bio,
    this.department,
    this.year,
    this.phone,
    this.skills = const [],
    this.interests = const [],
    this.role = UserRole.member,
    this.isEmailVerified = false,
    this.isActive = true,
    required this.createdAt,
    this.lastSeen,
    this.fcmToken,
    this.notificationPreferences = const {
      'events': true,
      'announcements': true,
      'forum': true,
      'mentions': true,
    },
    this.achievements = const [],
  });

  String get roleDisplayName {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.moderator:
        return 'Moderator';
      case UserRole.member:
        return 'Member';
    }
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isModerator => role == UserRole.moderator || role == UserRole.admin;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      bio: data['bio'],
      department: data['department'],
      year: data['year'],
      phone: data['phone'],
      skills: List<String>.from(data['skills'] ?? []),
      interests: List<String>.from(data['interests'] ?? []),
      role: _roleFromString(data['role'] ?? 'member'),
      isEmailVerified: data['isEmailVerified'] ?? false,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      fcmToken: data['fcmToken'],
      notificationPreferences: Map<String, bool>.from(
          data['notificationPreferences'] ?? {}),
      achievements: List<String>.from(data['achievements'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bio': bio,
      'department': department,
      'year': year,
      'phone': phone,
      'skills': skills,
      'interests': interests,
      'role': role.name,
      'isEmailVerified': isEmailVerified,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'fcmToken': fcmToken,
      'notificationPreferences': notificationPreferences,
      'achievements': achievements,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? bio,
    String? department,
    String? year,
    String? phone,
    List<String>? skills,
    List<String>? interests,
    UserRole? role,
    bool? isEmailVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastSeen,
    String? fcmToken,
    Map<String, bool>? notificationPreferences,
    List<String>? achievements,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      department: department ?? this.department,
      year: year ?? this.year,
      phone: phone ?? this.phone,
      skills: skills ?? this.skills,
      interests: interests ?? this.interests,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      fcmToken: fcmToken ?? this.fcmToken,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      achievements: achievements ?? this.achievements,
    );
  }

  static UserRole _roleFromString(String role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'moderator':
        return UserRole.moderator;
      default:
        return UserRole.member;
    }
  }
}
