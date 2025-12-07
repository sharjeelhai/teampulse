import 'package:flutter/foundation.dart';
import 'package:teampulse/repositories/meeting_repository.dart';
import '../models/meeting_model.dart';

class MeetingViewModel extends ChangeNotifier {
  final MeetingRepository _meetingRepository = MeetingRepository();

  List<MeetingModel> _meetings = [];
  MeetingModel? _selectedMeeting;
  bool _isLoading = false;
  String? _errorMessage;

  List<MeetingModel> get meetings => _meetings;
  MeetingModel? get selectedMeeting => _selectedMeeting;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load meetings by team
  Future<void> loadMeetingsByTeam(String teamId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _meetings = await _meetingRepository.getMeetingsByTeam(teamId);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load meetings';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load meetings by chapter
  Future<void> loadMeetingsByChapter(String chapterId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _meetings = await _meetingRepository.getMeetingsByChapter(chapterId);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load meetings';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load upcoming meetings
  Future<void> loadUpcomingMeetingsByTeam(String teamId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _meetings = await _meetingRepository.getUpcomingMeetingsByTeam(teamId);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load upcoming meetings';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load past meetings
  Future<void> loadPastMeetingsByTeam(String teamId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _meetings = await _meetingRepository.getPastMeetingsByTeam(teamId);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load past meetings';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load meeting by ID
  Future<void> loadMeetingById(String meetingId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _selectedMeeting = await _meetingRepository.getMeetingById(meetingId);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load meeting';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create meeting
  Future<String?> createMeeting({
    required String teamId,
    required String chapterId,
    required String topic,
    required String description,
    required DateTime dateTime,
    required String createdByLeadId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final meeting = MeetingModel(
        id: '',
        teamId: teamId,
        chapterId: chapterId,
        topic: topic,
        description: description,
        dateTime: dateTime,
        createdByLeadId: createdByLeadId,
        status: MeetingStatus.scheduled,
        createdAt: DateTime.now(),
      );

      final meetingId = await _meetingRepository.createMeeting(meeting);

      await loadMeetingsByTeam(teamId);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      return meetingId;
    } catch (e) {
      _errorMessage = 'Failed to create meeting';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Update meeting
  Future<bool> updateMeeting(
    String meetingId,
    Map<String, dynamic> updates,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _meetingRepository.updateMeeting(meetingId, updates);

      if (_selectedMeeting != null) {
        await loadMeetingById(meetingId);
      }

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update meeting';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete meeting
  Future<bool> deleteMeeting(String meetingId, String teamId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _meetingRepository.deleteMeeting(meetingId);

      await loadMeetingsByTeam(teamId);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete meeting';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update meeting status
  Future<bool> updateMeetingStatus(
    String meetingId,
    MeetingStatus status,
  ) async {
    return await updateMeeting(meetingId, {
      'status': status.toString().split('.').last,
    });
  }

  // Listen to meetings stream
  Stream<List<MeetingModel>> getMeetingsByTeamStream(String teamId) {
    return _meetingRepository.getMeetingsByTeamStream(teamId);
  }

  // Get meetings for a specific team from current meetings list
  List<MeetingModel> meetingsForTeam(String teamId) {
    return _meetings.where((meeting) => meeting.teamId == teamId).toList();
  }
}
