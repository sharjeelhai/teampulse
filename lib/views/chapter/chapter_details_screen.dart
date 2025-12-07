import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chapter_viewmodel.dart';
import '../../viewmodels/team_viewmodel.dart';
import '../../widgets/team_card.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../utils/theme.dart';
import '../team/create_team_screen.dart';
import '../team/team_details_screen.dart';

class ChapterDetailsScreen extends StatefulWidget {
  final String chapterId;
  const ChapterDetailsScreen({super.key, required this.chapterId});

  @override
  State<ChapterDetailsScreen> createState() => _ChapterDetailsScreenState();
}

class _ChapterDetailsScreenState extends State<ChapterDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<ChapterViewModel>(
      context,
      listen: false,
    ).loadChapterById(widget.chapterId);
    Provider.of<TeamViewModel>(
      context,
      listen: false,
    ).loadTeamsByChapter(widget.chapterId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chapter Details')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  CreateTeamScreen(chapterId: widget.chapterId, leadEmail: ''),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer2<ChapterViewModel, TeamViewModel>(
        builder: (context, chapterVM, teamVM, child) {
          final chapter = chapterVM.selectedChapter;
          if (chapterVM.isLoading && chapter == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (chapter == null) {
            return const Center(
              child: Text(
                'Chapter not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
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
                            chapter.name.isNotEmpty
                                ? chapter.name[0].toUpperCase()
                                : 'C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chapter.name,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lead: ${chapter.leadId.isNotEmpty ? chapter.leadId : 'Unassigned'}',
                              style: const TextStyle(color: Colors.white60),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${chapter.teamIds.length} teams',
                              style: const TextStyle(color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Teams',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (teamVM.teams.isEmpty)
                  const EmptyState(
                    icon: Icons.groups,
                    title: 'No teams',
                    message: 'Create teams inside this chapter.',
                  )
                else
                  Column(
                    children: teamVM.teams
                        .map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TeamCard(
                              team: t,
                              onTap: () async {
                                // Defensive navigation: log and catch exceptions so taps don't silently fail
                                debugPrint('Team tapped: ${t.id}');
                                try {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          TeamDetailsScreen(teamId: t.id),
                                    ),
                                  );
                                } catch (e, st) {
                                  debugPrint(
                                    'Navigation to TeamDetailsScreen failed: $e\n$st',
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to open team.'),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
