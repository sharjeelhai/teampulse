import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teampulse/viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/meeting_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/app_input.dart';
import '../../widgets/app_button.dart';
import '../../widgets/loading_overlay.dart';
import '../../utils/validators.dart';

class CreateMeetingScreen extends StatefulWidget {
  final String teamId;
  final String chapterId;
  const CreateMeetingScreen({
    super.key,
    required this.teamId,
    required this.chapterId,
  });

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _dateTime;

  @override
  void dispose() {
    _topicController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 18, minute: 0),
    );
    if (time == null) return;
    setState(() {
      _dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _createMeeting() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick date and time')),
      );
      return;
    }

    final auth = Provider.of<AuthViewModel>(context, listen: false);
    final vm = Provider.of<MeetingViewModel>(context, listen: false);
    final dashboardVM = Provider.of<DashboardViewModel>(context, listen: false);

    final id = await vm.createMeeting(
      teamId: widget.teamId,
      chapterId: widget.chapterId,
      topic: _topicController.text.trim(),
      description: _descController.text.trim(),
      dateTime: _dateTime!,
      createdByLeadId: auth.currentUser?.id ?? '',
    );

    if (id != null) {
      if (!mounted) return;

      // Refresh dashboard stats to reflect the new meeting
      if (auth.currentUser != null) {
        await dashboardVM.refreshStats(auth.currentUser!);
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting scheduled successfully')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(vm.errorMessage ?? 'Failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Meeting')),
      body: Consumer<MeetingViewModel>(
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
                      label: 'Topic',
                      controller: _topicController,
                      validator: (v) => Validators.validateRequired(v, 'Topic'),
                      readOnly: false,
                    ),
                    const SizedBox(height: 12),
                    AppInput(
                      label: 'Description',
                      readOnly: false,
                      controller: _descController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        _dateTime != null
                            ? _dateTime!.toLocal().toString()
                            : 'Pick date & time',
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: ElevatedButton(
                        onPressed: _pickDateTime,
                        child: const Text('Pick'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(text: 'Schedule', onPressed: _createMeeting),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
