import 'package:cloud_firestore/cloud_firestore.dart';

class ChapterModel {
  final String id;
  final String name;
  final String leadId;
  final List<String> teamIds;
  final DateTime createdAt;

  ChapterModel({
    required this.id,
    required this.name,
    required this.leadId,
    required this.teamIds,
    required this.createdAt,
  });

  factory ChapterModel.fromMap(Map<String, dynamic> map, String id) {
    return ChapterModel(
      id: id,
      name: map['name'] ?? '',
      leadId: map['leadId'] ?? '',
      teamIds: List<String>.from(map['teamIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'leadId': leadId,
      'teamIds': teamIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ChapterModel copyWith({
    String? id,
    String? name,
    String? leadId,
    List<String>? teamIds,
    DateTime? createdAt,
  }) {
    return ChapterModel(
      id: id ?? this.id,
      name: name ?? this.name,
      leadId: leadId ?? this.leadId,
      teamIds: teamIds ?? this.teamIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
