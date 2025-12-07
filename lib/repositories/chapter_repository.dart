import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teampulse/services/firebase_service.dart';
import '../models/chapter_model.dart';
import '../utils/constants.dart';

class ChapterRepository {
  final CollectionReference _chaptersCollection = FirebaseService.collection(
    AppConstants.chaptersCollection,
  );

  // Create chapter
  Future<String> createChapter(ChapterModel chapter) async {
    final doc = await _chaptersCollection.add(chapter.toMap());
    return doc.id;
  }

  // Get chapter by ID
  Future<ChapterModel?> getChapterById(String chapterId) async {
    final doc = await _chaptersCollection.doc(chapterId).get();
    if (doc.exists) {
      return ChapterModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Get chapter stream
  Stream<ChapterModel?> getChapterStream(String chapterId) {
    return _chaptersCollection.doc(chapterId).snapshots().map((doc) {
      if (doc.exists) {
        return ChapterModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  // Update chapter
  Future<void> updateChapter(
    String chapterId,
    Map<String, dynamic> data,
  ) async {
    await _chaptersCollection.doc(chapterId).update(data);
  }

  // Delete chapter
  Future<void> deleteChapter(String chapterId) async {
    await _chaptersCollection.doc(chapterId).delete();
  }

  // Get all chapters
  Future<List<ChapterModel>> getAllChapters() async {
    final snapshot = await _chaptersCollection
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map(
          (doc) =>
              ChapterModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  // Get all chapters stream
  Stream<List<ChapterModel>> getAllChaptersStream() {
    return _chaptersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ChapterModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  // Get chapter by lead ID
  Future<ChapterModel?> getChapterByLeadId(String leadId) async {
    final snapshot = await _chaptersCollection
        .where('leadId', isEqualTo: leadId)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return ChapterModel.fromMap(
        snapshot.docs.first.data() as Map<String, dynamic>,
        snapshot.docs.first.id,
      );
    }
    return null;
  }

  // Add team to chapter
  Future<void> addTeamToChapter(String chapterId, String teamId) async {
    await _chaptersCollection.doc(chapterId).update({
      'teamIds': FieldValue.arrayUnion([teamId]),
    });
  }

  // Remove team from chapter
  Future<void> removeTeamFromChapter(String chapterId, String teamId) async {
    await _chaptersCollection.doc(chapterId).update({
      'teamIds': FieldValue.arrayRemove([teamId]),
    });
  }
}
