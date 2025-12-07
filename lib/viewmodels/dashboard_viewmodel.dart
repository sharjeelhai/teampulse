import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:teampulse/models/attendance_model.dart';
import '../models/user_model.dart';
import '../repositories/chapter_repository.dart';
import '../repositories/team_repository.dart';
import '../repositories/meeting_repository.dart';
import '../repositories/attendance_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final ChapterRepository _chapterRepository = ChapterRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final MeetingRepository _meetingRepository = MeetingRepository();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();

  Map<String, dynamic> _stats = {};
  StreamSubscription? _chaptersSubscription;
  StreamSubscription? _teamsSubscription;
  StreamSubscription? _meetingsSubscription;

  Map<String, dynamic> get stats => _stats;
  // ignore: recursive_getters
  bool get isLoading => false;

  // Load dashboard stats based on role
  Future<void> loadDashboardStats(UserModel user) async {
    notifyListeners();

    // Cancel any existing listeners
    await _cancelListeners();

    try {
      switch (user.role) {
        case UserRole.superAdmin:
          await _loadSuperAdminStats();
          // Temporarily disable real-time listeners to prevent stack overflow
          // _setupSuperAdminListeners();
          break;
        case UserRole.chapterLead:
          if (user.chapterId != null) {
            await _loadChapterLeadStats(user.chapterId!);
            // Temporarily disable real-time listeners to prevent stack overflow
            // _setupChapterLeadListeners(user.chapterId!);
          }
          break;
        case UserRole.teamLead:
          if (user.teamId != null) {
            await _loadTeamLeadStats(user.teamId!);
            // Temporarily disable real-time listeners to prevent stack overflow
            // _setupTeamLeadListeners(user.teamId!);
          }
          break;
        case UserRole.member:
          await _loadMemberStats(user.id);
          break;
      }
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
    }

    notifyListeners();
  }

  Future<void> _loadSuperAdminStats() async {
    final chapters = await _chapterRepository.getAllChapters();

    int totalTeams = 0;
    int totalMeetings = 0;

    for (var chapter in chapters) {
      final teams = await _teamRepository.getTeamsByChapter(chapter.id);
      totalTeams += teams.length;

      final meetings = await _meetingRepository.getMeetingsByChapter(
        chapter.id,
      );
      totalMeetings += meetings.length;
    }

    _stats = {
      'totalChapters': chapters.length,
      'totalTeams': totalTeams,
      'totalMeetings': totalMeetings,
      'chapters': chapters,
    };
  }

  Future<void> _loadChapterLeadStats(String chapterId) async {
    final teams = await _teamRepository.getTeamsByChapter(chapterId);
    final meetings = await _meetingRepository.getMeetingsByChapter(chapterId);

    int totalMembers = 0;
    for (var team in teams) {
      totalMembers += team.memberIds.length;
    }

    final upcomingMeetings = meetings
        .where((m) => m.dateTime.isAfter(DateTime.now()))
        .toList();
    final pastMeetings = meetings
        .where((m) => m.dateTime.isBefore(DateTime.now()))
        .toList();

    _stats = {
      'totalTeams': teams.length,
      'totalMembers': totalMembers,
      'totalMeetings': meetings.length,
      'upcomingMeetings': upcomingMeetings.length,
      'pastMeetings': pastMeetings.length,
      'teams': teams,
      'recentMeetings': meetings.take(5).toList(),
    };
  }

  Future<void> _loadTeamLeadStats(String teamId) async {
    final team = await _teamRepository.getTeamById(teamId);
    if (team == null) return;

    final meetings = await _meetingRepository.getMeetingsByTeam(teamId);
    final attendance = await _attendanceRepository.getAttendanceByTeam(teamId);

    final upcomingMeetings = meetings
        .where((m) => m.dateTime.isAfter(DateTime.now()))
        .toList();
    final pastMeetings = meetings
        .where((m) => m.dateTime.isBefore(DateTime.now()))
        .toList();

    // Calculate average attendance
    double avgAttendance = 0.0;
    if (pastMeetings.isNotEmpty && team.memberIds.isNotEmpty) {
      int totalPresent = attendance
          .where((a) => a.status == AttendanceStatus.present)
          .length;
      int totalPossible = pastMeetings.length * team.memberIds.length;
      avgAttendance = totalPossible > 0
          ? (totalPresent / totalPossible) * 100
          : 0.0;
    }

    _stats = {
      'totalMembers': team.memberIds.length,
      'totalMeetings': meetings.length,
      'upcomingMeetings': upcomingMeetings.length,
      'pastMeetings': pastMeetings.length,
      'averageAttendance': avgAttendance,
      'recentMeetings': meetings.take(5).toList(),
    };
  }

  Future<void> _loadMemberStats(String memberId) async {
    final attendance = await _attendanceRepository.getAttendanceByMember(
      memberId,
    );

    final present = attendance
        .where((a) => a.status == AttendanceStatus.present)
        .length;
    final absent = attendance
        .where((a) => a.status == AttendanceStatus.absent)
        .length;
    final late = attendance
        .where((a) => a.status == AttendanceStatus.late)
        .length;

    final attendanceRate = attendance.isNotEmpty
        ? ((present + late) / attendance.length) * 100
        : 0.0;

    _stats = {
      'totalMeetings': attendance.length,
      'present': present,
      'absent': absent,
      'late': late,
      'attendanceRate': attendanceRate,
    };
  }

  Future<void> _cancelListeners() async {
    await _chaptersSubscription?.cancel();
    await _teamsSubscription?.cancel();
    await _meetingsSubscription?.cancel();
    _chaptersSubscription = null;
    _teamsSubscription = null;
    _meetingsSubscription = null;
  }

  // Refresh stats without full reload (useful for real-time updates)
  Future<void> refreshStats(UserModel user) async {
    try {
      switch (user.role) {
        case UserRole.superAdmin:
          await _loadSuperAdminStats();
          break;
        case UserRole.chapterLead:
          if (user.chapterId != null) {
            await _loadChapterLeadStats(user.chapterId!);
          }
          break;
        case UserRole.teamLead:
          if (user.teamId != null) {
            await _loadTeamLeadStats(user.teamId!);
          }
          break;
        case UserRole.member:
          await _loadMemberStats(user.id);
          break;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing dashboard stats: $e');
    }
  }

  // Dispose method to clean up listeners
  @override
  void dispose() {
    _cancelListeners();
    super.dispose();
  }
}
