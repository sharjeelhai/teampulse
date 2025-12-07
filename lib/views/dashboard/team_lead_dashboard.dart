import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teampulse/utils/theme.dart';
import 'package:teampulse/views/auth/login_screen.dart';
import 'package:teampulse/views/team/create_team_screen.dart';
import 'package:teampulse/views/team/manage_members_screen.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/meeting_viewmodel.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/app_card.dart';
import '../../widgets/meeting_card.dart';
import '../meeting/create_meeting_screen.dart';
import '../meeting/meetings_list_screen.dart';
import '../team/team_details_screen.dart';
import '../attendance/mark_attendance_screen.dart';
import '../profile/profile_screen.dart';

class TeamLeadDashboard extends StatefulWidget {
  const TeamLeadDashboard({super.key});

  @override
  State<TeamLeadDashboard> createState() => _TeamLeadDashboardState();
}

class _TeamLeadDashboardState extends State<TeamLeadDashboard> {
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

    if (authViewModel.currentUser != null) {
      await dashboardViewModel.loadDashboardStats(authViewModel.currentUser!);

      if (authViewModel.currentUser!.teamId != null) {
        await meetingViewModel.loadMeetingsByTeam(
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
        title: const Text('Team Lead Dashboard'),
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
      floatingActionButton: Consumer<AuthViewModel>(
        builder: (context, authViewModel, child) {
          if (authViewModel.currentUser?.teamId == null ||
              authViewModel.currentUser?.chapterId == null) {
            return const SizedBox();
          }

          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CreateMeetingScreen(
                    teamId: authViewModel.currentUser!.teamId!,
                    chapterId: authViewModel.currentUser!.chapterId!,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Schedule Meeting'),
            backgroundColor: AppTheme.primaryPurple,
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Consumer2<AuthViewModel, DashboardViewModel>(
          builder: (context, authViewModel, dashboardViewModel, child) {
            if (dashboardViewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final stats = dashboardViewModel.stats;
            final currentUser = authViewModel.currentUser;
            final hasTeam = currentUser?.teamId != null;
            final hasChapter = currentUser?.chapterId != null;

            // Show team creation UI if user doesn't have required assignments
            if (!hasTeam || !hasChapter) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTeamSetupUI(authViewModel, hasChapter),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await authViewModel.loadUserFromLocal();
                          setState(() {});
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh My Data'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

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
                            authViewModel.currentUser?.avatarInitials ?? 'TL',
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
                                'Welcome, ${authViewModel.currentUser?.name ?? "Lead"}',
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
                                'Team Lead',
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

                  // Stats
                  const Text(
                    'Team Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Fixed Grid Layout for Stats
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0, // Fixed from 1.4 to prevent overflow
                    children: [
                      StatCard(
                        title: 'Members',
                        value: '${stats['totalMembers'] ?? 0}',
                        icon: Icons.people,
                        iconColor: AppTheme.primaryPurple,
                        onTap: () {
                          if (authViewModel.currentUser?.teamId != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TeamDetailsScreen(
                                  teamId: authViewModel.currentUser!.teamId!,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      StatCard(
                        title: 'Meetings',
                        value: '${stats['totalMeetings'] ?? 0}',
                        icon: Icons.event,
                        iconColor: AppTheme.secondaryCyan,
                      ),
                      StatCard(
                        title: 'Upcoming',
                        value: '${stats['upcomingMeetings'] ?? 0}',
                        icon: Icons.schedule,
                        iconColor: AppTheme.warningOrange,
                      ),
                      StatCard(
                        title: 'Attendance',
                        value:
                            '${(stats['averageAttendance'] ?? 0.0).toStringAsFixed(0)}%',
                        icon: Icons.check_circle,
                        iconColor: AppTheme.successGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // First Row: Manage Members, New Meeting, Team Details
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.person_add,
                          label: 'Manage Members',
                          onTap: () {
                            if (authViewModel.currentUser?.teamId != null) {
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) => ManageMembersScreen(
                                        teamId:
                                            authViewModel.currentUser!.teamId!,
                                      ),
                                    ),
                                  )
                                  .then((_) => _loadData());
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.add_circle,
                          label: 'New Meeting',
                          onTap: () {
                            if (authViewModel.currentUser?.teamId != null &&
                                authViewModel.currentUser?.chapterId != null) {
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) => CreateMeetingScreen(
                                        teamId:
                                            authViewModel.currentUser!.teamId!,
                                        chapterId: authViewModel
                                            .currentUser!
                                            .chapterId!,
                                      ),
                                    ),
                                  )
                                  .then((_) => _loadData());
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.groups,
                          label: 'Team Details',
                          onTap: () {
                            if (authViewModel.currentUser?.teamId != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TeamDetailsScreen(
                                    teamId: authViewModel.currentUser!.teamId!,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Second Row: Mark Attendance, All Meetings
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.check_circle,
                          label: 'Mark Attendance',
                          onTap: () {
                            if (authViewModel.currentUser?.teamId != null) {
                              _showMarkAttendanceDialog(context, authViewModel);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.list,
                          label: 'All Meetings',
                          onTap: () {
                            if (authViewModel.currentUser?.teamId != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MeetingsListScreen(
                                    teamId: authViewModel.currentUser!.teamId!,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Empty space for symmetry
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Upcoming Meetings
                  Consumer<MeetingViewModel>(
                    builder: (context, meetingViewModel, child) {
                      final upcomingMeetings = meetingViewModel.meetings
                          .where((m) => m.dateTime.isAfter(DateTime.now()))
                          .toList();

                      if (upcomingMeetings.isEmpty) {
                        return AppCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: const [
                                Icon(
                                  Icons.event_available,
                                  size: 60,
                                  color: Colors.white24,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No upcoming meetings',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Schedule a meeting to get started',
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
                          ...upcomingMeetings.take(5).map((meeting) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: MeetingCard(meeting: meeting),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showMarkAttendanceDialog(
    BuildContext context,
    AuthViewModel authViewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => Consumer<MeetingViewModel>(
        builder: (context, meetingVM, child) {
          final allMeetings = meetingVM.meetings;

          if (allMeetings.isEmpty) {
            return AlertDialog(
              title: const Text('No Meetings'),
              content: const Text('No meetings found. Create a meeting first.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          }

          return AlertDialog(
            title: const Text('Select Meeting'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allMeetings.length,
                itemBuilder: (context, index) {
                  final meeting = allMeetings[index];
                  final isPast = meeting.dateTime.isBefore(DateTime.now());

                  return ListTile(
                    leading: Icon(
                      isPast ? Icons.history : Icons.schedule,
                      color: isPast ? Colors.white60 : AppTheme.primaryPurple,
                    ),
                    title: Text(
                      meeting.topic,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      meeting.dateTime.toLocal().toString().split('.')[0],
                      style: const TextStyle(color: Colors.white60),
                    ),
                    trailing: isPast
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Past',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => MarkAttendanceScreen(
                                meetingId: meeting.id,
                                teamId: authViewModel.currentUser!.teamId!,
                              ),
                            ),
                          )
                          .then((_) => _loadData());
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTeamSetupUI(AuthViewModel authViewModel, bool hasChapter) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryPurple, AppTheme.secondaryCyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurple.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.groups, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome, Team Lead!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            hasChapter
                ? 'You need to create a team within your chapter to manage meetings.'
                : 'You need to be assigned to a chapter first. Please contact a chapter lead or super admin.',
            style: const TextStyle(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          if (hasChapter) ...[
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => CreateTeamScreen(
                            chapterId: authViewModel.currentUser!.chapterId!,
                            leadEmail: authViewModel.currentUser!.email,
                          ),
                        ),
                      )
                      .then((result) async {
                        if (result == true) {
                          await authViewModel.loadUserFromLocal();
                          _loadData();
                        }
                      });
                },
                icon: const Icon(Icons.group_add, color: Colors.white),
                label: const Text(
                  'Create Your Team',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: AppTheme.primaryPurple),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
