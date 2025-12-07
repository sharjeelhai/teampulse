import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teampulse/services/firebase_service.dart';
import '../models/attendance_model.dart';
import '../utils/constants.dart';

class AttendanceRepository {
  final CollectionReference _attendanceCollection = FirebaseService.collection(
    AppConstants.attendanceCollection,
  );

  // Create attendance
  Future<String> createAttendance(AttendanceModel attendance) async {
    final doc = await _attendanceCollection.add(attendance.toMap());
    return doc.id;
  }

  // Get attendance by ID
  Future<AttendanceModel?> getAttendanceById(String attendanceId) async {
    final doc = await _attendanceCollection.doc(attendanceId).get();
    if (doc.exists) {
      return AttendanceModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }
    return null;
  }

  // Update attendance
  Future<void> updateAttendance(
    String attendanceId,
    Map<String, dynamic> data,
  ) async {
    await _attendanceCollection.doc(attendanceId).update(data);
  }

  // Delete attendance
  Future<void> deleteAttendance(String attendanceId) async {
    await _attendanceCollection.doc(attendanceId).delete();
  }

  // Get attendance by meeting
  Future<List<AttendanceModel>> getAttendanceByMeeting(String meetingId) async {
    final snapshot = await _attendanceCollection
        .where('meetingId', isEqualTo: meetingId)
        .get();
    return snapshot.docs
        .map(
          (doc) => AttendanceModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();
  }

  // Get attendance by meeting stream
  Stream<List<AttendanceModel>> getAttendanceByMeetingStream(String meetingId) {
    return _attendanceCollection
        .where('meetingId', isEqualTo: meetingId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AttendanceModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  // Get attendance by member
  Future<List<AttendanceModel>> getAttendanceByMember(String memberId) async {
    final snapshot = await _attendanceCollection
        .where('memberId', isEqualTo: memberId)
        .orderBy('markedAt', descending: true)
        .get();
    return snapshot.docs
        .map(
          (doc) => AttendanceModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();
  }

  // Get attendance by team
  Future<List<AttendanceModel>> getAttendanceByTeam(String teamId) async {
    final snapshot = await _attendanceCollection
        .where('teamId', isEqualTo: teamId)
        .orderBy('markedAt', descending: true)
        .get();
    return snapshot.docs
        .map(
          (doc) => AttendanceModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();
  }

  // Check if attendance exists for member in meeting
  Future<AttendanceModel?> getAttendanceByMemberAndMeeting(
    String memberId,
    String meetingId,
  ) async {
    final snapshot = await _attendanceCollection
        .where('memberId', isEqualTo: memberId)
        .where('meetingId', isEqualTo: meetingId)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return AttendanceModel.fromMap(
        snapshot.docs.first.data() as Map<String, dynamic>,
        snapshot.docs.first.id,
      );
    }
    return null;
  }

  // Batch create/update attendance
  Future<void> batchMarkAttendance(List<AttendanceModel> attendanceList) async {
    final batch = FirebaseService.firestore.batch();

    for (var attendance in attendanceList) {
      // Check if attendance already exists
      final existing = await getAttendanceByMemberAndMeeting(
        attendance.memberId,
        attendance.meetingId,
      );

      if (existing != null) {
        // Update existing
        batch.update(
          _attendanceCollection.doc(existing.id),
          attendance.toMap(),
        );
      } else {
        // Create new
        final newDoc = _attendanceCollection.doc();
        batch.set(newDoc, attendance.toMap());
      }
    }

    await batch.commit();
  }
}
