import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/meeting_viewmodel.dart';
import '../../models/meeting_model.dart';

class MeetingDetailsScreen extends StatefulWidget {
  final String meetingId;
  const MeetingDetailsScreen({super.key, required this.meetingId});

  @override
  State<MeetingDetailsScreen> createState() => _MeetingDetailsScreenState();
}

class _MeetingDetailsScreenState extends State<MeetingDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MeetingViewModel>(
        context,
        listen: false,
      ).loadMeetingById(widget.meetingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        appBar: AppBar(title: const Text('Meeting Details')),
        body: Consumer<MeetingViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading && vm.selectedMeeting == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final MeetingModel? meeting = vm.selectedMeeting;
            if (meeting == null) {
              return const Center(child: Text('Meeting not found'));
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meeting.topic,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(meeting.description),
                  const SizedBox(height: 12),
                  Text('When: ${meeting.dateTime.toLocal().toString()}'),
                  const SizedBox(height: 12),
                  Text('Status: ${meeting.status}'),
                  // Add attendance/participants rendering here if you have data
                ],
              ),
            );
          },
        ),
      );
    } catch (e, st) {
      debugPrint('Error building MeetingDetailsScreen: $e\n$st');
      return Scaffold(
        appBar: AppBar(title: const Text('Meeting Details')),
        body: const Center(child: Text('Failed to load meeting details.')),
      );
    }
  }
}
