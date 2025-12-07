import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/meeting_viewmodel.dart';
import '../../models/meeting_model.dart';
import '../../widgets/meeting_card.dart';
import '../../widgets/empty_state.dart';
import 'create_meeting_screen.dart';
import 'meeting_details_screen.dart';

class MeetingsListScreen extends StatefulWidget {
  final String? teamId;
  final String? chapterId;
  const MeetingsListScreen({super.key, this.teamId, this.chapterId});

  @override
  State<MeetingsListScreen> createState() => _MeetingsListScreenState();
}

class _MeetingsListScreenState extends State<MeetingsListScreen> {
  @override
  void initState() {
    super.initState();
    final vm = Provider.of<MeetingViewModel>(context, listen: false);
    if (widget.teamId != null) {
      vm.loadMeetingsByTeam(widget.teamId!);
    } else if (widget.chapterId != null) {
      vm.loadMeetingsByChapter(widget.chapterId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<MeetingViewModel>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Meetings')),
      floatingActionButton: widget.teamId != null
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreateMeetingScreen(
                      teamId: widget.teamId!,
                      chapterId: widget.chapterId ?? '',
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.meetings.isEmpty
          ? const Center(
              child: EmptyState(
                icon: Icons.event_available,
                title: 'No meetings',
                message: 'No meetings scheduled',
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                if (widget.teamId != null) {
                  return vm.loadMeetingsByTeam(widget.teamId!);
                }
                if (widget.chapterId != null) {
                  return vm.loadMeetingsByChapter(widget.chapterId!);
                }
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: vm.meetings.length,
                itemBuilder: (context, idx) {
                  final MeetingModel m = vm.meetings[idx];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MeetingCard(
                      meeting: m,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                MeetingDetailsScreen(meetingId: m.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
