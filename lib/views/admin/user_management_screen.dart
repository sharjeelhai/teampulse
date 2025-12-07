import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/chapter_repository.dart';
import '../../repositories/team_repository.dart';
import '../../models/chapter_model.dart';
import '../../models/team_model.dart';
import '../../utils/theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/loading_overlay.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _debugUserIdController = TextEditingController();
  final UserRepository _userRepository = UserRepository();
  final ChapterRepository _chapterRepository = ChapterRepository();
  final TeamRepository _teamRepository = TeamRepository();

  List<UserModel> _users = [];
  List<ChapterModel> _chapters = [];
  List<TeamModel> _teams = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userRepository.getAllUsers();
      final chapters = await _chapterRepository.getAllChapters();
      final teams = await _teamRepository.getAllTeams();

      setState(() {
        _users = users;
        _chapters = chapters;
        _teams = teams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    }
  }

  Future<void> _debugLookupUser(String userId) async {
    try {
      final user = await _userRepository.getUserById(userId);
      if (user != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('User Found'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${user.id}'),
                Text('Email: ${user.email}'),
                Text('Name: ${user.name}'),
                Text('Role: ${user.role}'),
                Text('Chapter ID: ${user.chapterId ?? 'Not assigned'}'),
                Text('Team ID: ${user.teamId ?? 'Not assigned'}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not found')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _assignChapterToUser(UserModel user, String? chapterId) async {
    try {
      print('Assigning chapter $chapterId to user ${user.id} (${user.email})');
      await _userRepository.updateUser(user.id, {'chapterId': chapterId});
      print('Successfully updated user ${user.id} with chapterId: $chapterId');

      // If assigning chapter to chapter lead, also update the chapter's leadId
      if (user.role == UserRole.chapterLead && chapterId != null) {
        await _chapterRepository.updateChapter(chapterId, {'leadId': user.id});
      }

      // Refresh data
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chapter assigned successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to assign chapter: $e')));
      }
    }
  }

  Future<void> _assignTeamToUser(UserModel user, String? teamId) async {
    try {
      await _userRepository.updateUser(user.id, {'teamId': teamId});

      // If assigning team to team lead, also update the team's leadId
      if (user.role == UserRole.teamLead && teamId != null) {
        await _teamRepository.updateTeam(teamId, {'leadId': user.id});
      }

      // Refresh data
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team assigned successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to assign team: $e')));
      }
    }
  }

  Future<void> _updateUserRole(UserModel user, UserRole newRole) async {
    try {
      await _userRepository.updateUser(user.id, {
        'role': newRole.toString().split('.').last,
      });

      // Clear chapter and team assignments if role is changed to member
      if (newRole == UserRole.member) {
        await _userRepository.updateUser(user.id, {
          'chapterId': null,
          'teamId': null,
        });
      }

      // Refresh data
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update role: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            // Debug user lookup
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _debugUserIdController,
                      decoration: const InputDecoration(
                        labelText: 'User ID to lookup',
                        hintText: 'Enter user ID...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final userId = _debugUserIdController.text.trim();
                      if (userId.isNotEmpty) {
                        _debugLookupUser(userId);
                      }
                    },
                    child: const Text('Lookup'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _users.isEmpty
                  ? const Center(child: Text('No users found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppCard(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // User info
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppTheme.primaryPurple,
                                        child: Text(
                                          user.avatarInitials,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              user.email,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white60,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Role management
                                  Row(
                                    children: [
                                      const Text(
                                        'Role: ',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      DropdownButton<UserRole>(
                                        value: user.role,
                                        dropdownColor: AppTheme.backgroundDark,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        items: UserRole.values.map((role) {
                                          return DropdownMenuItem(
                                            value: role,
                                            child: Text(
                                              role.toString().split('.').last,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (newRole) {
                                          if (newRole != null &&
                                              newRole != user.role) {
                                            _updateUserRole(user, newRole);
                                          }
                                        },
                                      ),
                                    ],
                                  ),

                                  // Chapter assignment (for chapter leads and team leads)
                                  if (user.role == UserRole.chapterLead ||
                                      user.role == UserRole.teamLead) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Text(
                                          'Chapter: ',
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        Expanded(
                                          child: DropdownButton<String?>(
                                            value: user.chapterId,
                                            dropdownColor:
                                                AppTheme.backgroundDark,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                            hint: const Text('Select Chapter'),
                                            items: [
                                              const DropdownMenuItem<String?>(
                                                value: null,
                                                child: Text('None'),
                                              ),
                                              ..._chapters.map((chapter) {
                                                return DropdownMenuItem(
                                                  value: chapter.id,
                                                  child: Text(chapter.name),
                                                );
                                              }),
                                            ],
                                            onChanged: (chapterId) {
                                              _assignChapterToUser(
                                                user,
                                                chapterId,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  // Team assignment (for team leads only)
                                  if (user.role == UserRole.teamLead) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Text(
                                          'Team: ',
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        Expanded(
                                          child: DropdownButton<String?>(
                                            value: user.teamId,
                                            dropdownColor:
                                                AppTheme.backgroundDark,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                            hint: const Text('Select Team'),
                                            items: [
                                              const DropdownMenuItem<String?>(
                                                value: null,
                                                child: Text('None'),
                                              ),
                                              ..._teams
                                                  .where(
                                                    (team) =>
                                                        team.chapterId ==
                                                        user.chapterId,
                                                  )
                                                  .map((team) {
                                                    return DropdownMenuItem(
                                                      value: team.id,
                                                      child: Text(team.name),
                                                    );
                                                  }),
                                            ],
                                            onChanged: (teamId) {
                                              _assignTeamToUser(user, teamId);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
