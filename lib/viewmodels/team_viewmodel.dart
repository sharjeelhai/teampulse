import 'package:flutter/foundation.dart';
import '../models/team_model.dart';
import '../repositories/team_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/chapter_repository.dart';

class TeamViewModel extends ChangeNotifier {
  final TeamRepository _teamRepository = TeamRepository();
  final UserRepository _userRepository = UserRepository();
  final ChapterRepository _chapterRepository = ChapterRepository();

  List<TeamModel> _teams = [];
  TeamModel? _selectedTeam;
  bool _isLoading = false;
  String? _errorMessage;

  List<TeamModel> get teams => _teams;
  TeamModel? get selectedTeam => _selectedTeam;
  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  // Load teams by chapter
  Future<void> loadTeamsByChapter(String chapterId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _teams = await _teamRepository.getTeamsByChapter(chapterId);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load teams';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load team by ID
  Future<void> loadTeamById(String teamId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _selectedTeam = await _teamRepository.getTeamById(teamId);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load team';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create team
  Future<String?> createTeam({
    required String chapterId,
    required String name,
    required String leadId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final team = TeamModel(
        id: '',
        chapterId: chapterId,
        name: name,
        leadId: leadId,
        memberIds: [],
        createdAt: DateTime.now(),
      );

      debugPrint('Saving team to Firestore...');
      final teamId = await _teamRepository.createTeam(team);
      debugPrint('Team created with ID: $teamId');

      // Add team to chapter
      await _chapterRepository.addTeamToChapter(chapterId, teamId);

      // Update the team lead's user record to include this team
      await _userRepository.updateUser(leadId, {'teamId': teamId});

      await loadTeamsByChapter(chapterId);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      return teamId;
    } catch (e) {
      _errorMessage = 'Failed to create team: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Update team
  Future<bool> updateTeam(String teamId, Map<String, dynamic> updates) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _teamRepository.updateTeam(teamId, updates);

      if (_selectedTeam != null) {
        await loadTeamById(teamId);
      }

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update team';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete team
  Future<bool> deleteTeam(String teamId, String chapterId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _teamRepository.deleteTeam(teamId);
      await _chapterRepository.removeTeamFromChapter(chapterId, teamId);

      await loadTeamsByChapter(chapterId);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete team';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Add member to team
  Future<bool> addMemberToTeam(String teamId, String memberId) async {
    try {
      await _teamRepository.addMemberToTeam(teamId, memberId);

      if (_selectedTeam != null && _selectedTeam!.id == teamId) {
        await loadTeamById(teamId);
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to add member';
      notifyListeners();
      return false;
    }
  }

  // Remove member from team
  Future<bool> removeMemberFromTeam(String teamId, String memberId) async {
    try {
      await _teamRepository.removeMemberFromTeam(teamId, memberId);

      if (_selectedTeam != null && _selectedTeam!.id == teamId) {
        await loadTeamById(teamId);
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to remove member';
      notifyListeners();
      return false;
    }
  }

  // Get team by lead ID
  Future<TeamModel?> getTeamByLeadId(String leadId) async {
    try {
      return await _teamRepository.getTeamByLeadId(leadId);
    } catch (e) {
      debugPrint('Error getting team by lead ID: $e');
      return null;
    }
  }

  // Load all teams (for super admin)
  Future<void> loadAllTeams() async {
    try {
      _isLoading = true;
      notifyListeners();

      _teams = await _teamRepository.getAllTeams();

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load teams';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Listen to teams stream
  Stream<List<TeamModel>> getTeamsByChapterStream(String chapterId) {
    return _teamRepository.getTeamsByChapterStream(chapterId);
  }
}
