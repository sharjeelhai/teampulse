import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chapter_viewmodel.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import 'create_chapter_screen.dart';
import 'chapter_details_screen.dart';
import '../../utils/theme.dart';

class ChaptersListScreen extends StatefulWidget {
  const ChaptersListScreen({super.key});

  @override
  State<ChaptersListScreen> createState() => _ChaptersListScreenState();
}

class _ChaptersListScreenState extends State<ChaptersListScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<ChapterViewModel>(context, listen: false).loadAllChapters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chapters')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateChapterScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer<ChapterViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.chapters.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.business,
                title: 'No chapters yet',
                message: 'Create a chapter to get started.',
                actionText: 'Create Chapter',
                onAction: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateChapterScreen(),
                    ),
                  );
                },
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: vm.loadAllChapters,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.chapters.length,
              itemBuilder: (context, index) {
                final c = vm.chapters[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: ListTile(
                      leading: Container(
                        width: 54,
                        height: 54,
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
                            c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        c.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${c.teamIds.length} teams',
                        style: const TextStyle(color: Colors.white60),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white38,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ChapterDetailsScreen(chapterId: c.id),
                          ),
                        );
                      },
                    ),
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
