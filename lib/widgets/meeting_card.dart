import 'package:flutter/material.dart';
import '../models/meeting_model.dart';
import '../utils/theme.dart';
import '../utils/extensions.dart';
import 'app_card.dart';

class MeetingCard extends StatelessWidget {
  final MeetingModel meeting;
  final VoidCallback? onTap;

  const MeetingCard({super.key, required this.meeting, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPast = meeting.dateTime.isPast();
    final isToday = meeting.dateTime.isToday();

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  meeting.status.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                ),
              ),
              const Spacer(),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warningOrange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            meeting.topic,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            meeting.description,
            style: const TextStyle(fontSize: 14, color: Colors.white60),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: isPast ? Colors.white38 : AppTheme.secondaryCyan,
              ),
              const SizedBox(width: 8),
              Text(
                meeting.dateTime.toFormattedDate(),
                style: TextStyle(
                  fontSize: 12,
                  color: isPast ? Colors.white38 : Colors.white70,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time,
                size: 16,
                color: isPast ? Colors.white38 : AppTheme.secondaryCyan,
              ),
              const SizedBox(width: 8),
              Text(
                meeting.dateTime.toFormattedTime(),
                style: TextStyle(
                  fontSize: 12,
                  color: isPast ? Colors.white38 : Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (meeting.status) {
      case MeetingStatus.scheduled:
        return AppTheme.primaryPurple;
      case MeetingStatus.ongoing:
        return AppTheme.warningOrange;
      case MeetingStatus.completed:
        return AppTheme.successGreen;
      case MeetingStatus.cancelled:
        return AppTheme.errorRed;
    }
  }
}
