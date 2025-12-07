import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teampulse/viewmodels/auth_viewmodel.dart';
import 'package:teampulse/views/admin/user_management_screen.dart';
import '../../viewmodels/chapter_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../utils/theme.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/app_card.dart';
import '../chapter/chapters_list_screen.dart';
import '../chapter/create_chapter_screen.dart';
import '../profile/profile_screen.dart';
import '../auth/login_screen.dart';
import '../team/all_teams_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
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
    final chapterViewModel = Provider.of<ChapterViewModel>(
      context,
      listen: false,
    );

    if (authViewModel.currentUser != null) {
      await dashboardViewModel.loadDashboardStats(authViewModel.currentUser!);
      await chapterViewModel.loadAllChapters();
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
        title: const Text('Super Admin Dashboard'),
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
                            authViewModel.currentUser?.avatarInitials ?? 'SA',
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
                                'Welcome, ${authViewModel.currentUser?.name ?? "Admin"}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Super Administrator',
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
                    'Global Statistics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StatCard(
                    title: 'Total Chapters',
                    value: '${stats['totalChapters'] ?? 0}',
                    icon: Icons.business,
                    iconColor: AppTheme.primaryPurple,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ChaptersListScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  StatCard(
                    title: 'Total Teams',
                    value: '${stats['totalTeams'] ?? 0}',
                    icon: Icons.groups,
                    iconColor: AppTheme.secondaryCyan,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AllTeamsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  StatCard(
                    title: 'Total Meetings',
                    value: '${stats['totalMeetings'] ?? 0}',
                    icon: Icons.event,
                    iconColor: AppTheme.successGreen,
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
                          icon: Icons.add_business,
                          label: 'Create Chapter',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CreateChapterScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.list,
                          label: 'View Chapters',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ChaptersListScreen(),
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
                        child: _QuickActionButton(
                          icon: Icons.people,
                          label: 'User Management',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const UserManagementScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: SizedBox(), // Empty space for future buttons
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent Chapters
                  Consumer<ChapterViewModel>(
                    builder: (context, chapterViewModel, child) {
                      if (chapterViewModel.chapters.isEmpty) {
                        return const SizedBox();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recent Chapters',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...chapterViewModel.chapters.take(5).map((chapter) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AppCard(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            AppTheme.primaryPurple,
                                            AppTheme.secondaryCyan,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          chapter.name
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            chapter.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${chapter.teamIds.length} teams',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white60,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 32, color: AppTheme.primaryPurple),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
