import 'package:flutter/foundation.dart';
import 'package:teampulse/repositories/attendance_repository.dart';
import '../models/attendance_model.dart';

class AttendanceViewModel extends ChangeNotifier {
  final AttendanceRepository _attendanceRepository = AttendanceRepository();

  List<AttendanceModel> _attendanceList = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AttendanceModel> get attendanceList => _attendanceList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load attendance by meeting
  Future<void> loadAttendanceByMeeting(String meetingId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _attendanceList = await _attendanceRepository.getAttendanceByMeeting(
        meetingId,
      );

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load attendance';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load attendance by member
  Future<void> loadAttendanceByMember(String memberId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _attendanceList = await _attendanceRepository.getAttendanceByMember(
        memberId,
      );

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load attendance';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load attendance by team
  Future<void> loadAttendanceByTeam(String teamId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _attendanceList = await _attendanceRepository.getAttendanceByTeam(teamId);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load attendance';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark attendance (single)
  Future<bool> markAttendance({
    required String meetingId,
    required String memberId,
    required String teamId,
    required AttendanceStatus status,
    required String markedBy,
  }) async {
    try {
      // Check if already marked
      final existing = await _attendanceRepository
          .getAttendanceByMemberAndMeeting(memberId, meetingId);

      if (existing != null) {
        // Update existing
        await _attendanceRepository.updateAttendance(existing.id, {
          'status': status.toString().split('.').last,
          'markedAt': DateTime.now(),
          'markedBy': markedBy,
        });
      } else {
        // Create new
        final attendance = AttendanceModel(
          id: '',
          meetingId: meetingId,
          memberId: memberId,
          teamId: teamId,
          status: status,
          markedAt: DateTime.now(),
          markedBy: markedBy,
        );

        await _attendanceRepository.createAttendance(attendance);
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to mark attendance';
      notifyListeners();
      return false;
    }
  }

  // Batch mark attendance
  Future<bool> batchMarkAttendance(List<AttendanceModel> attendanceList) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _attendanceRepository.batchMarkAttendance(attendanceList);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Failed to mark attendance';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get attendance stats for member
  Map<String, int> getAttendanceStats(String memberId) {
    final memberAttendance = _attendanceList
        .where((a) => a.memberId == memberId)
        .toList();

    return {
      'total': memberAttendance.length,
      'present': memberAttendance
          .where((a) => a.status == AttendanceStatus.present)
          .length,
      'absent': memberAttendance
          .where((a) => a.status == AttendanceStatus.absent)
          .length,
      'late': memberAttendance
          .where((a) => a.status == AttendanceStatus.late)
          .length,
    };
  }

  // Calculate attendance percentage
  double getAttendancePercentage(String memberId) {
    final stats = getAttendanceStats(memberId);
    final total = stats['total'] ?? 0;
    if (total == 0) return 0.0;

    final present = (stats['present'] ?? 0) + (stats['late'] ?? 0);
    return (present / total) * 100;
  }

  // Listen to attendance stream
  Stream<List<AttendanceModel>> getAttendanceByMeetingStream(String meetingId) {
    return _attendanceRepository.getAttendanceByMeetingStream(meetingId);
  }
}
