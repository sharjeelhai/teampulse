import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/attendance_viewmodel.dart';
import '../../widgets/app_card.dart';
import '../../widgets/attendance_badge.dart';
import '../../models/attendance_model.dart';
import '../../utils/extensions.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final String memberId;
  const AttendanceHistoryScreen({super.key, required this.memberId});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<AttendanceViewModel>(
      context,
      listen: false,
    ).loadAttendanceByMember(widget.memberId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance History')),
      body: Consumer<AttendanceViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.attendanceList.isEmpty) {
            return const Center(
              child: Text(
                'No attendance records',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vm.attendanceList.length,
            itemBuilder: (context, idx) {
              final AttendanceModel a = vm.attendanceList[idx];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.meetingId,
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              a.markedAt.toFormattedDateTime(),
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AttendanceBadge(status: a.status),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
