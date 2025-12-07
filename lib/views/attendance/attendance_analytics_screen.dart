import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:teampulse/models/attendance_model.dart';
import '../../viewmodels/attendance_viewmodel.dart';
import '../../utils/theme.dart';

class AttendanceAnalyticsScreen extends StatefulWidget {
  final String teamId;
  const AttendanceAnalyticsScreen({super.key, required this.teamId});

  @override
  State<AttendanceAnalyticsScreen> createState() =>
      _AttendanceAnalyticsScreenState();
}

class _AttendanceAnalyticsScreenState extends State<AttendanceAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<AttendanceViewModel>(
      context,
      listen: false,
    ).loadAttendanceByTeam(widget.teamId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Analytics')),
      body: Consumer<AttendanceViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = vm.attendanceList;
          final total = list.length;
          final present = list
              .where((a) => a.status == AttendanceStatus.present)
              .length;
          final late = list
              .where((a) => a.status == AttendanceStatus.late)
              .length;
          final absent = list
              .where((a) => a.status == AttendanceStatus.absent)
              .length;

          if (total == 0) {
            return const Center(
              child: Text(
                'No attendance data',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: present.toDouble(),
                          color: AppTheme.successGreen,
                          title: '$present',
                        ),
                        PieChartSectionData(
                          value: late.toDouble(),
                          color: AppTheme.warningOrange,
                          title: '$late',
                        ),
                        PieChartSectionData(
                          value: absent.toDouble(),
                          color: AppTheme.errorRed,
                          title: '$absent',
                        ),
                      ],
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Legend(
                      color: AppTheme.successGreen,
                      label: 'Present',
                      value: present,
                    ),
                    _Legend(
                      color: AppTheme.warningOrange,
                      label: 'Late',
                      value: late,
                    ),
                    _Legend(
                      color: AppTheme.errorRed,
                      label: 'Absent',
                      value: absent,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  const _Legend({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white60)),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
