import 'package:cloud_firestore/cloud_firestore.dart';

enum MeetingStatus { scheduled, ongoing, completed, cancelled }

class MeetingModel {
  final String id;
  final String teamId;
  final String chapterId;
  final String topic;
  final String description;
  final DateTime dateTime;
  final String createdByLeadId;
  final MeetingStatus status;
  final DateTime createdAt;

  MeetingModel({
    required this.id,
    required this.teamId,
    required this.chapterId,
    required this.topic,
    required this.description,
    required this.dateTime,
    required this.createdByLeadId,
    required this.status,
    required this.createdAt,
  });

  factory MeetingModel.fromMap(Map<String, dynamic> map, String id) {
    return MeetingModel(
      id: id,
      teamId: map['teamId'] ?? '',
      chapterId: map['chapterId'] ?? '',
      topic: map['topic'] ?? '',
      description: map['description'] ?? '',
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      createdByLeadId: map['createdByLeadId'] ?? '',
      status: MeetingStatus.values.firstWhere(
        (e) => e.toString() == 'MeetingStatus.${map['status']}',
        orElse: () => MeetingStatus.scheduled,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'chapterId': chapterId,
      'topic': topic,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'createdByLeadId': createdByLeadId,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  MeetingModel copyWith({
    String? id,
    String? teamId,
    String? chapterId,
    String? topic,
    String? description,
    DateTime? dateTime,
    String? createdByLeadId,
    MeetingStatus? status,
    DateTime? createdAt,
  }) {
    return MeetingModel(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      chapterId: chapterId ?? this.chapterId,
      topic: topic ?? this.topic,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      createdByLeadId: createdByLeadId ?? this.createdByLeadId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
