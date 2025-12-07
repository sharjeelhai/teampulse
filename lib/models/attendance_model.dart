import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, absent, late }

class AttendanceModel {
  final String id;
  final String meetingId;
  final String memberId;
  final String teamId;
  final AttendanceStatus status;
  final DateTime markedAt;
  final String markedBy;

  AttendanceModel({
    required this.id,
    required this.meetingId,
    required this.memberId,
    required this.teamId,
    required this.status,
    required this.markedAt,
    required this.markedBy,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceModel(
      id: id,
      meetingId: map['meetingId'] ?? '',
      memberId: map['memberId'] ?? '',
      teamId: map['teamId'] ?? '',
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString() == 'AttendanceStatus. ${map['status']}',
        orElse: () => AttendanceStatus.absent,
      ),
      markedAt: (map['markedAt'] as Timestamp).toDate(),
      markedBy: map['markedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'meetingId': meetingId,
      'memberId': memberId,
      'teamId': teamId,
      'status': status.toString().split('.').last,
      'markedAt': Timestamp.fromDate(markedAt),
      'markedBy': markedBy,
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? meetingId,
    String? memberId,
    String? teamId,
    AttendanceStatus? status,
    DateTime? markedAt,
    String? markedBy,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      memberId: memberId ?? this.memberId,
      teamId: teamId ?? this.teamId,
      status: status ?? this.status,
      markedAt: markedAt ?? this.markedAt,
      markedBy: markedBy ?? this.markedBy,
    );
  }
}
