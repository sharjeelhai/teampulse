import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meeting_model.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';

class MeetingRepository {
  final CollectionReference _meetingsCollection = FirebaseService.collection(
    AppConstants.meetingsCollection,
  );

  // Create meeting
  Future<String> createMeeting(MeetingModel meeting) async {
    final doc = await _meetingsCollection.add(meeting.toMap());
    return doc.id;
  }

  // Get meeting by ID
  Future<MeetingModel?> getMeetingById(String meetingId) async {
    final doc = await _meetingsCollection.doc(meetingId).get();
    if (doc.exists) {
      return MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Get meeting stream
  Stream<MeetingModel?> getMeetingStream(String meetingId) {
    return _meetingsCollection.doc(meetingId).snapshots().map((doc) {
      if (doc.exists) {
        return MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  // Update meeting
  Future<void> updateMeeting(
    String meetingId,
    Map<String, dynamic> data,
  ) async {
    await _meetingsCollection.doc(meetingId).update(data);
  }

  // Delete meeting
  Future<void> deleteMeeting(String meetingId) async {
    await _meetingsCollection.doc(meetingId).delete();
  }

  // Get meetings by team
  Future<List<MeetingModel>> getMeetingsByTeam(String teamId) async {
    final snapshot = await _meetingsCollection
        .where('teamId', isEqualTo: teamId)
        .orderBy('dateTime', descending: true)
        .get();
    return snapshot.docs
        .map(
          (doc) =>
              MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  // Get meetings by team stream
  Stream<List<MeetingModel>> getMeetingsByTeamStream(String teamId) {
    return _meetingsCollection
        .where('teamId', isEqualTo: teamId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => MeetingModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  // Get meetings by chapter
  Future<List<MeetingModel>> getMeetingsByChapter(String chapterId) async {
    final snapshot = await _meetingsCollection
        .where('chapterId', isEqualTo: chapterId)
        .orderBy('dateTime', descending: true)
        .get();
    return snapshot.docs
        .map(
          (doc) =>
              MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  // Get upcoming meetings by team
  Future<List<MeetingModel>> getUpcomingMeetingsByTeam(String teamId) async {
    final now = DateTime.now();
    final snapshot = await _meetingsCollection
        .where('teamId', isEqualTo: teamId)
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('dateTime', descending: false)
        .get();
    return snapshot.docs
        .map(
          (doc) =>
              MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  // Get past meetings by team
  Future<List<MeetingModel>> getPastMeetingsByTeam(String teamId) async {
    final now = DateTime.now();
    final snapshot = await _meetingsCollection
        .where('teamId', isEqualTo: teamId)
        .where('dateTime', isLessThan: Timestamp.fromDate(now))
        .orderBy('dateTime', descending: true)
        .get();
    return snapshot.docs
        .map(
          (doc) =>
              MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }
}
