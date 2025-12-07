import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { superAdmin, chapterLead, teamLead, member }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? chapterId;
  final String? teamId;
  final String avatarInitials;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.chapterId,
    this.teamId,
    required this.avatarInitials,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${map['role']}',
        orElse: () => UserRole.member,
      ),
      chapterId: map['chapterId'],
      teamId: map['teamId'],
      avatarInitials: map['avatarInitials'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'chapterId': chapterId,
      'teamId': teamId,
      'avatarInitials': avatarInitials,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? chapterId,
    String? teamId,
    String? avatarInitials,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      chapterId: chapterId ?? this.chapterId,
      teamId: teamId ?? this.teamId,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
