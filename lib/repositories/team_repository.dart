import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/team_model.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';

class TeamRepository {
  final CollectionReference _teamsCollection = FirebaseService.collection(
    AppConstants.teamsCollection,
  );

  // Create team
  Future<String> createTeam(TeamModel team) async {
    debugPrint('🔧 Creating team: ${team.name} for chapter: ${team.chapterId}');
    final doc = await _teamsCollection.add(team.toMap());
    debugPrint('✅ Team created with ID: ${doc.id}');
    return doc.id;
  }

  // Get team by ID
  Future<TeamModel?> getTeamById(String teamId) async {
    final doc = await _teamsCollection.doc(teamId).get();
    if (doc.exists) {
      return TeamModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Get team stream
  Stream<TeamModel?> getTeamStream(String teamId) {
    return _teamsCollection.doc(teamId).snapshots().map((doc) {
      if (doc.exists) {
        return TeamModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  // Update team
  Future<void> updateTeam(String teamId, Map<String, dynamic> data) async {
    await _teamsCollection.doc(teamId).update(data);
  }

  // Delete team
  Future<void> deleteTeam(String teamId) async {
    await _teamsCollection.doc(teamId).delete();
  }

  // Get teams by chapter
  Future<List<TeamModel>> getTeamsByChapter(String chapterId) async {
    try {
      debugPrint('🔍 TeamRepository: Querying teams for chapterId: $chapterId');

      final snapshot = await _teamsCollection
          .where('chapterId', isEqualTo: chapterId)
          .get(); // Removed orderBy temporarily to test

      debugPrint('✅ TeamRepository: Found ${snapshot.docs.length} teams');

      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ No teams found for chapter: $chapterId');
      } else {
        debugPrint(
          '📋 Team names: ${snapshot.docs.map((d) => (d.data() as Map<String, dynamic>?)?['name']).join(', ')}',
        );
      }

      final teams = snapshot.docs
          .map(
            (doc) =>
                TeamModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();

      // Sort manually after fetching
      teams.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return teams;
    } catch (e) {
      debugPrint('❌ Error in getTeamsByChapter: $e');
      rethrow;
    }
  }

  // Get teams by chapter stream
  Stream<List<TeamModel>> getTeamsByChapterStream(String chapterId) {
    return _teamsCollection
        .where('chapterId', isEqualTo: chapterId)
        .snapshots()
        .map((snapshot) {
          final teams = snapshot.docs
              .map(
                (doc) => TeamModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

          // Sort manually
          teams.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return teams;
        });
  }

  // Get team by lead ID
  Future<TeamModel?> getTeamByLeadId(String leadId) async {
    final snapshot = await _teamsCollection
        .where('leadId', isEqualTo: leadId)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return TeamModel.fromMap(
        snapshot.docs.first.data() as Map<String, dynamic>,
        snapshot.docs.first.id,
      );
    }
    return null;
  }

  // Add member to team
  Future<void> addMemberToTeam(String teamId, String memberId) async {
    await _teamsCollection.doc(teamId).update({
      'memberIds': FieldValue.arrayUnion([memberId]),
    });
  }

  // Remove member from team
  Future<void> removeMemberFromTeam(String teamId, String memberId) async {
    await _teamsCollection.doc(teamId).update({
      'memberIds': FieldValue.arrayRemove([memberId]),
    });
  }

  // Get all teams
  Future<List<TeamModel>> getAllTeams() async {
    debugPrint('🔍 TeamRepository: Getting ALL teams (Super Admin)');
    final snapshot = await _teamsCollection.get();
    debugPrint('✅ TeamRepository: Found ${snapshot.docs.length} total teams');

    return snapshot.docs
        .map(
          (doc) =>
              TeamModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }
}
