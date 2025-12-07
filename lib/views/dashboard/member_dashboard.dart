import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:teampulse/utils/theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/meeting_viewmodel.dart';
import '../../viewmodels/attendance_viewmodel.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/app_card.dart';
import '../../widgets/meeting_card.dart';
import '../attendance/attendance_history_screen.dart';
import '../profile/profile_screen.dart';
import '../auth/login_screen.dart';

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final dashboardViewModel = Provider.of<DashboardViewModel>(
      context,
      listen: false,
    );
    final meetingViewModel = Provider.of<MeetingViewModel>(
      context,
      listen: false,
    );
    final attendanceViewModel = Provider.of<AttendanceViewModel>(
      context,
      listen: false,
    );

    if (authViewModel.currentUser != null) {
      await dashboardViewModel.loadDashboardStats(authViewModel.currentUser!);
      await attendanceViewModel.loadAttendanceByMember(
        authViewModel.currentUser!.id,
      );

      if (authViewModel.currentUser!.teamId != null) {
        await meetingViewModel.loadUpcomingMeetingsByTeam(
          authViewModel.currentUser!.teamId!,
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    await authViewModel.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Consumer2<AuthViewModel, DashboardViewModel>(
          builder: (context, authViewModel, dashboardViewModel, child) {
            if (dashboardViewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final stats = dashboardViewModel.stats;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  AppCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.primaryPurple,
                          child: Text(
                            authViewModel.currentUser?.avatarInitials ?? 'M',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${authViewModel.currentUser?.name ?? "Member"}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Team Member',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Attendance Stats
                  const Text(
                    'My Attendance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Total Meetings',
                          value: '${stats['totalMeetings'] ?? 0}',
                          icon: Icons.event,
                          iconColor: AppTheme.primaryPurple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Attendance Rate',
                          value:
                              '${(stats['attendanceRate'] ?? 0.0).toStringAsFixed(0)}%',
                          icon: Icons.check_circle,
                          iconColor: AppTheme.successGreen,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AttendanceHistoryScreen(
                                  memberId: authViewModel.currentUser!.id,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _VerticalStatCard(
                          title: 'Present',
                          value: '${stats['present'] ?? 0}',
                          icon: Icons.check,
                          iconColor: AppTheme.successGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _VerticalStatCard(
                          title: 'Late',
                          value: '${stats['late'] ?? 0}',
                          icon: Icons.access_time,
                          iconColor: AppTheme.warningOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _VerticalStatCard(
                          title: 'Absent',
                          value: '${stats['absent'] ?? 0}',
                          icon: Icons.close,
                          iconColor: AppTheme.errorRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Attendance Chart
                  if ((stats['totalMeetings'] ?? 0) > 0)
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Attendance Breakdown',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: [
                                  PieChartSectionData(
                                    value: (stats['present'] ?? 0).toDouble(),
                                    title: '${stats['present'] ?? 0}',
                                    color: AppTheme.successGreen,
                                    radius: 50,
                                    titleStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    value: (stats['late'] ?? 0).toDouble(),
                                    title: '${stats['late'] ?? 0}',
                                    color: AppTheme.warningOrange,
                                    radius: 50,
                                    titleStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    value: (stats['absent'] ?? 0).toDouble(),
                                    title: '${stats['absent'] ?? 0}',
                                    color: AppTheme.errorRed,
                                    radius: 50,
                                    titleStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _LegendItem(
                                color: AppTheme.successGreen,
                                label: 'Present',
                              ),
                              _LegendItem(
                                color: AppTheme.warningOrange,
                                label: 'Late',
                              ),
                              _LegendItem(
                                color: AppTheme.errorRed,
                                label: 'Absent',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Upcoming Meetings
                  Consumer<MeetingViewModel>(
                    builder: (context, meetingViewModel, child) {
                      if (meetingViewModel.meetings.isEmpty) {
                        return AppCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.event_available,
                                  size: 60,
                                  color: Colors.white24,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No upcoming meetings',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Check back later for new meetings',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white60,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upcoming Meetings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...meetingViewModel.meetings.take(5).map((meeting) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: MeetingCard(meeting: meeting),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                  // Add bottom padding for better scroll experience
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// Fixed Vertical Stat Card with proper layout
class _VerticalStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _VerticalStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon at top
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            // Value in the middle with FittedBox to prevent overflow
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Title at bottom
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white60,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
