import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/team_viewmodel.dart';
import '../../widgets/team_card.dart';
import '../../widgets/empty_state.dart';
import 'team_details_screen.dart';

class TeamsListScreen extends StatefulWidget {
  final String chapterId;
  const TeamsListScreen({super.key, required this.chapterId});

  @override
  State<TeamsListScreen> createState() => _TeamsListScreenState();
}

class _TeamsListScreenState extends State<TeamsListScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<TeamViewModel>(
      context,
      listen: false,
    ).loadTeamsByChapter(widget.chapterId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teams')),
      body: Consumer<TeamViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.teams.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.groups,
                title: 'No teams',
                message: 'Create a team to get started',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => vm.loadTeamsByChapter(widget.chapterId),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.teams.length,
              itemBuilder: (context, idx) {
                final t = vm.teams[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TeamCard(
                    team: t,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TeamDetailsScreen(teamId: t.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
