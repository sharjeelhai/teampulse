import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teampulse/utils/theme.dart';
import 'package:teampulse/views/auth/login_screen.dart';
import 'package:teampulse/views/chapter/create_chapter_screen.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/team_viewmodel.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/app_card.dart';
import '../../widgets/team_card.dart';
import '../team/teams_list_screen.dart';
import '../team/create_team_screen.dart';
import '../meeting/meetings_list_screen.dart';
import '../profile/profile_screen.dart';

class ChapterLeadDashboard extends StatefulWidget {
  const ChapterLeadDashboard({super.key});

  @override
  State<ChapterLeadDashboard> createState() => _ChapterLeadDashboardState();
}

class _ChapterLeadDashboardState extends State<ChapterLeadDashboard> {
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
    final teamViewModel = Provider.of<TeamViewModel>(context, listen: false);

    if (authViewModel.currentUser != null) {
      await dashboardViewModel.loadDashboardStats(authViewModel.currentUser!);

      if (authViewModel.currentUser!.chapterId != null) {
        await teamViewModel.loadTeamsByChapter(
          authViewModel.currentUser!.chapterId!,
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
        title: const Text('Chapter Lead Dashboard'),
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
            final hasChapter = authViewModel.currentUser?.chapterId != null;

            // Show chapter creation UI if user doesn't have a chapter assigned
            if (!hasChapter) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "You don't have a chapter assigned.",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Please create a chapter to get started.",
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Consumer<AuthViewModel>(
                            builder: (context, authViewModel, child) {
                              return ElevatedButton.icon(
                                icon: const Icon(Icons.business),
                                label: const Text("Create Your Chapter"),
                                onPressed: () async {
                                  final result = await Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder: (_) => CreateChapterScreen(
                                            leadId:
                                                authViewModel.currentUser!.id,
                                          ),
                                        ),
                                      );

                                  if (result == true) {
                                    _loadData();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryPurple,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
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
                            authViewModel.currentUser?.avatarInitials ?? 'CL',
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
                                'Chapter Lead',
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
                    'Chapter Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Fixed Grid Layout for Stats with AspectRatio
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0, // Adjust this for card proportions
                    children: [
                      StatCard(
                        title: 'Teams',
                        value: '${stats['totalTeams'] ?? 0}',
                        icon: Icons.groups,
                        iconColor: AppTheme.primaryPurple,
                      ),
                      StatCard(
                        title: 'Members',
                        value: '${stats['totalMembers'] ?? 0}',
                        icon: Icons.people,
                        iconColor: AppTheme.secondaryCyan,
                      ),
                      StatCard(
                        title: 'Upcoming',
                        value: '${stats['upcomingMeetings'] ?? 0}',
                        icon: Icons.schedule,
                        iconColor: AppTheme.warningOrange,
                      ),
                      StatCard(
                        title: 'Completed',
                        value: '${stats['pastMeetings'] ?? 0}',
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
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.group_add,
                          label: 'Create Team',
                          onTap: () {
                            if (authViewModel.currentUser?.chapterId != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CreateTeamScreen(
                                    chapterId:
                                        authViewModel.currentUser!.chapterId!,
                                    leadEmail: '',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.list,
                          label: 'View Teams',
                          onTap: () {
                            if (authViewModel.currentUser?.chapterId != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TeamsListScreen(
                                    chapterId:
                                        authViewModel.currentUser!.chapterId!,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.event,
                          label: 'Meetings',
                          onTap: () {
                            if (authViewModel.currentUser?.chapterId != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MeetingsListScreen(
                                    chapterId:
                                        authViewModel.currentUser!.chapterId!,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Teams List
                  Consumer<TeamViewModel>(
                    builder: (context, teamViewModel, child) {
                      if (teamViewModel.teams.isEmpty) {
                        return AppCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: const [
                                Icon(
                                  Icons.groups_outlined,
                                  size: 60,
                                  color: Colors.white24,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No teams yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Create your first team to get started',
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Your Teams',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (authViewModel.currentUser?.chapterId !=
                                      null) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => TeamsListScreen(
                                          chapterId: authViewModel
                                              .currentUser!
                                              .chapterId!,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('View All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...teamViewModel.teams.take(5).map((team) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TeamCard(team: team),
                            );
                          }),
                        ],
                      );
                    },
                  ),
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
