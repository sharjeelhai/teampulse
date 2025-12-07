import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teampulse/models/user_model.dart';
import 'package:teampulse/repositories/user_repository.dart';
import 'package:teampulse/viewmodels/auth_viewmodel.dart';
import 'package:teampulse/viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/team_viewmodel.dart';
import '../../viewmodels/chapter_viewmodel.dart';
import '../../widgets/app_input.dart';
import '../../widgets/app_button.dart';
import '../../widgets/loading_overlay.dart';
import '../../utils/validators.dart';
import '../../utils/theme.dart';

class CreateTeamScreen extends StatefulWidget {
  final String chapterId;
  final String? leadEmail; // Optional lead email to auto-fill
  const CreateTeamScreen({super.key, required this.chapterId, this.leadEmail});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late final TextEditingController _leadIdController;
  final _memberSearchController = TextEditingController();
  final UserRepository _userRepository = UserRepository();
  List<UserModel> _availableMembers = [];
  final List<String> _selectedMemberIds = [];
  bool _searchingMembers = false;

  @override
  void initState() {
    super.initState();
    _leadIdController = TextEditingController(text: widget.leadEmail);
    _memberSearchController.addListener(() {
      _searchMembers(_memberSearchController.text);
    });
    _loadAvailableMembers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _leadIdController.dispose();
    _memberSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableMembers() async {
    try {
      // Load members from the same chapter who don't have a team assigned
      final allUsers = await _userRepository.getAllUsers();
      setState(() {
        _availableMembers = allUsers
            .where(
              (user) =>
                  user.role == UserRole.member &&
                  user.chapterId == widget.chapterId &&
                  user.teamId == null,
            )
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading members: $e');
    }
  }

  Future<void> _createTeam() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = Provider.of<TeamViewModel>(context, listen: false);
    final userRepository = UserRepository();
    final dashboardVM = Provider.of<DashboardViewModel>(context, listen: false);
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final chapterVM = Provider.of<ChapterViewModel>(context, listen: false);

    String leadIdToUse;

    print('Team Creation Debug:');
    print('  Widget chapterId: ${widget.chapterId}');
    print('  Widget leadEmail: ${widget.leadEmail}');

    // Check if current user is a chapter lead or team lead
    final currentUser = authVM.currentUser;
    final isChapterLead = currentUser?.role == UserRole.chapterLead;
    final isTeamLead = currentUser?.role == UserRole.teamLead;

    if (widget.leadEmail != null && widget.leadEmail!.isNotEmpty) {
      // Auto-filled with user email (for team leads creating their own team)
      print('  Looking up user by email: ${widget.leadEmail}');
      final user = await userRepository.getUserByEmail(widget.leadEmail!);
      print('  User lookup result: ${user != null ? 'found' : 'not found'}');
      if (user != null) {
        print(
          '  User details: id=${user.id}, role=${user.role}, chapterId=${user.chapterId}, teamId=${user.teamId}',
        );
      }
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Current user not found in database')),
        );
        return;
      }
      // Validate that the user has the right role and permissions
      if (user.role != UserRole.teamLead) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only team leads can be assigned as team leads'),
          ),
        );
        return;
      }

      if (user.chapterId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team lead must be assigned to a chapter first'),
          ),
        );
        return;
      }

      if (user.chapterId != widget.chapterId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team lead must belong to the same chapter'),
          ),
        );
        return;
      }

      if (user.teamId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This team lead already has a team assigned'),
          ),
        );
        return;
      }

      leadIdToUse = user.id;
    } else {
      // User entered an email, look up the user ID
      final email = _leadIdController.text.trim();
      if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter team lead email')),
        );
        return;
      }

      final user = await userRepository.getUserByEmail(email);
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user found with this email')),
        );
        return;
      }

      // Validate the user is a team lead
      if (user.role != UserRole.teamLead) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected user must be a team lead')),
        );
        return;
      }

      // Validate chapter assignment
      if (user.chapterId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team lead must be assigned to a chapter first'),
          ),
        );
        return;
      }

      // If current user is a team lead, they can only create teams in their chapter
      // If current user is a chapter lead, they can create teams in their chapter
      if (isTeamLead && user.chapterId != widget.chapterId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can only create teams in your assigned chapter'),
          ),
        );
        return;
      }

      if (isChapterLead && user.chapterId != widget.chapterId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team lead must belong to your chapter'),
          ),
        );
        return;
      }

      // Check if team lead already has a team
      if (user.teamId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This team lead already has a team assigned'),
          ),
        );
        return;
      }

      debugPrint('Found user ID: ${user.id} for email: $email');
      leadIdToUse = user.id;
    }

    final id = await vm.createTeam(
      chapterId: widget.chapterId,
      name: _nameController.text.trim(),
      leadId: leadIdToUse,
    );

    if (id != null) {
      // Add selected members to the team
      if (_selectedMemberIds.isNotEmpty) {
        for (final memberId in _selectedMemberIds) {
          await vm.addMemberToTeam(id, memberId);
          // Update member's teamId
          await _userRepository.updateUser(memberId, {'teamId': id});
        }
      }

      if (!mounted) return;

      // Refresh dashboard stats and chapters to reflect the new team
      if (authVM.currentUser != null) {
        await dashboardVM.refreshStats(authVM.currentUser!);
      }
      // Refresh chapters to update team counts
      await chapterVM.loadAllChapters();

      Navigator.of(context).pop(true); // Return true to indicate success
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Team created successfully${_selectedMemberIds.isNotEmpty ? ' with ${_selectedMemberIds.length} member(s)' : ''}',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'Failed to create team')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Team')),
      body: Consumer<TeamViewModel>(
        builder: (context, vm, child) {
          return LoadingOverlay(
            isLoading: vm.isLoading,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppInput(
                      label: 'Team Name',
                      controller: _nameController,
                      validator: Validators.validateName,
                      readOnly: false,
                    ),
                    const SizedBox(height: 16),
                    AppInput(
                      label:
                          widget.leadEmail != null &&
                              widget.leadEmail!.isNotEmpty
                          ? 'Team Lead Email (auto-filled)'
                          : 'Team Lead Email (required)',
                      readOnly:
                          widget.leadEmail != null &&
                          widget.leadEmail!.isNotEmpty,
                      controller: _leadIdController,
                      hint: 'teamlead@example.com',
                      keyboardType: TextInputType.emailAddress,
                      validator:
                          (widget.leadEmail != null &&
                              widget.leadEmail!.isNotEmpty)
                          ? null
                          : Validators.validateEmail,
                    ),
                    const SizedBox(height: 24),

                    // Add Members Section
                    const Text(
                      'Add Team Members (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppInput(
                      label: 'Search Members',
                      controller: _memberSearchController,
                      hint: 'Search by name or email...',
                      readOnly: false,
                    ),
                    const SizedBox(height: 12),
                    if (_selectedMemberIds.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedMemberIds.map((memberId) {
                          final member = _availableMembers.firstWhere(
                            (m) => m.id == memberId,
                          );
                          return Chip(
                            label: Text(member.name),
                            onDeleted: () {
                              setState(() {
                                _selectedMemberIds.remove(memberId);
                              });
                            },
                            backgroundColor: AppTheme.primaryPurple.withOpacity(
                              0.2,
                            ),
                            deleteIconColor: Colors.white,
                            labelStyle: const TextStyle(color: Colors.white),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _searchingMembers
                          ? const Center(child: CircularProgressIndicator())
                          : _availableMembers.isEmpty
                          ? const Center(
                              child: Text(
                                'No available members',
                                style: TextStyle(color: Colors.white60),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _availableMembers.length,
                              itemBuilder: (context, index) {
                                final member = _availableMembers[index];
                                final isSelected = _selectedMemberIds.contains(
                                  member.id,
                                );
                                return CheckboxListTile(
                                  title: Text(
                                    member.name,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    member.email,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        if (!_selectedMemberIds.contains(
                                          member.id,
                                        )) {
                                          _selectedMemberIds.add(member.id);
                                        }
                                      } else {
                                        _selectedMemberIds.remove(member.id);
                                      }
                                    });
                                  },
                                  activeColor: AppTheme.primaryPurple,
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(text: 'Create Team', onPressed: _createTeam),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _searchMembers(String query) {
    setState(() {
      _searchingMembers = true;
    });

    if (query.isEmpty) {
      _loadAvailableMembers();
      setState(() {
        _searchingMembers = false;
      });
      return;
    }

    // Filter members by search query
    final filtered = _availableMembers
        .where(
          (member) =>
              member.name.toLowerCase().contains(query.toLowerCase()) ||
              member.email.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    setState(() {
      _availableMembers = filtered;
      _searchingMembers = false;
    });
  }
}
