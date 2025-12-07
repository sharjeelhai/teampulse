import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../utils/theme.dart';

class AttendanceBadge extends StatelessWidget {
  final AttendanceStatus status;
  final bool isCompact;

  const AttendanceBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(), size: isCompact ? 14 : 16, color: _getColor()),
          if (!isCompact) ...[
            const SizedBox(width: 6),
            Text(
              _getText(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getColor(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case AttendanceStatus.present:
        return AppTheme.successGreen;
      case AttendanceStatus.absent:
        return AppTheme.errorRed;
      case AttendanceStatus.late:
        return AppTheme.warningOrange;
    }
  }

  IconData _getIcon() {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.late:
        return Icons.access_time;
    }
  }

  String _getText() {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
    }
  }
}
