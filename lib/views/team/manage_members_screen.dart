import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/team_viewmodel.dart';
import '../../repositories/user_repository.dart';
import '../../widgets/app_input.dart';
import '../../widgets/empty_state.dart';

class ManageMembersScreen extends StatefulWidget {
  final String teamId;
  const ManageMembersScreen({super.key, required this.teamId});

  @override
  State<ManageMembersScreen> createState() => _ManageMembersScreenState();
}

class _ManageMembersScreenState extends State<ManageMembersScreen> {
  final _searchController = TextEditingController();
  final UserRepository _userRepo = UserRepository();
  List users = [];
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
    });
    final results = await _userRepo.searchUsersByName(q);
    setState(() {
      users = results;
      _searching = false;
    });
  }

  Future<void> _addMember(String memberId) async {
    final vm = Provider.of<TeamViewModel>(context, listen: false);
    final ok = await vm.addMemberToTeam(widget.teamId, memberId);
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Member added')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(vm.errorMessage ?? 'Failed')));
    }
  }

  Future<void> _removeMember(String memberId) async {
    final vm = Provider.of<TeamViewModel>(context, listen: false);
    final ok = await vm.removeMemberFromTeam(widget.teamId, memberId);
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Member removed')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(vm.errorMessage ?? 'Failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<TeamViewModel>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Members')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppInput(
              label: 'Search users',
              controller: _searchController,
              hint: 'Enter name',
              prefixIcon: Icons.search,
              readOnly: false,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _searching ? null : _searchUsers,
              icon: const Icon(Icons.search),
              label: const Text('Search'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _searching
                  ? const Center(child: CircularProgressIndicator())
                  : users.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off,
                      title: 'No results',
                      message: 'Search for users to add',
                    )
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, idx) {
                        final u = users[idx];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF6C63FF),
                            child: Text(u.name.getInitials()),
                          ),
                          title: Text(
                            u.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            u.email,
                            style: const TextStyle(color: Colors.white60),
                          ),
                          trailing:
                              vm.selectedTeam != null &&
                                  vm.selectedTeam!.memberIds.contains(u.id)
                              ? ElevatedButton(
                                  onPressed: () => _removeMember(u.id),
                                  child: const Text('Remove'),
                                )
                              : ElevatedButton(
                                  onPressed: () => _addMember(u.id),
                                  child: const Text('Add'),
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
