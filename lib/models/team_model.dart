import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String id;
  final String chapterId;
  final String name;
  final String leadId;
  final List<String> memberIds;
  final DateTime createdAt;

  TeamModel({
    required this.id,
    required this.chapterId,
    required this.name,
    required this.leadId,
    required this.memberIds,
    required this.createdAt,
  });

  factory TeamModel.fromMap(Map<String, dynamic> map, String id) {
    return TeamModel(
      id: id,
      chapterId: map['chapterId'] ?? '',
      name: map['name'] ?? '',
      leadId: map['leadId'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chapterId': chapterId,
      'name': name,
      'leadId': leadId,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  TeamModel copyWith({
    String? id,
    String? chapterId,
    String? name,
    String? leadId,
    List<String>? memberIds,
    DateTime? createdAt,
  }) {
    return TeamModel(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      name: name ?? this.name,
      leadId: leadId ?? this.leadId,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
