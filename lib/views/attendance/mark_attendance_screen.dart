import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teampulse/utils/theme.dart';
import '../../models/user_model.dart';
import '../../widgets/app_card.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final String meetingId;
  final String teamId;

  const MarkAttendanceScreen({
    super.key,
    required this.meetingId,
    required this.teamId,
  });

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  bool _isLoading = false;
  Map<String, String> _attendanceStatus = {}; // memberId -> status
  List<UserModel> _members = [];
  String? _meetingTopic;
  DateTime? _meetingDateTime;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load meeting details
      final meetingDoc = await FirebaseFirestore.instance
          .collection('meetings')
          .doc(widget.meetingId)
          .get();

      if (meetingDoc.exists) {
        final meetingData = meetingDoc.data()!;
        _meetingTopic = meetingData['topic'];
        _meetingDateTime = (meetingData['dateTime'] as Timestamp).toDate();
      }

      // Load team members
      final membersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('teamId', isEqualTo: widget.teamId)
          .get();

      _members = membersSnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();

      // Load existing attendance records
      final attendanceSnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('meetingId', isEqualTo: widget.meetingId)
          .get();

      _attendanceStatus = {};
      for (var doc in attendanceSnapshot.docs) {
        final data = doc.data();
        _attendanceStatus[data['memberId']] = data['status'];
      }

      // Set default status for members without attendance
      for (var member in _members) {
        if (!_attendanceStatus.containsKey(member.id)) {
          _attendanceStatus[member.id] = 'absent';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => _isLoading = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (var member in _members) {
        final status = _attendanceStatus[member.id] ?? 'absent';

        // Check if attendance record exists
        final existingDocs = await FirebaseFirestore.instance
            .collection('attendance')
            .where('meetingId', isEqualTo: widget.meetingId)
            .where('memberId', isEqualTo: member.id)
            .get();

        if (existingDocs.docs.isNotEmpty) {
          // Update existing record
          final docRef = FirebaseFirestore.instance
              .collection('attendance')
              .doc(existingDocs.docs.first.id);
          batch.update(docRef, {
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Create new record
          final docRef = FirebaseFirestore.instance
              .collection('attendance')
              .doc();
          batch.set(docRef, {
            'id': docRef.id,
            'meetingId': widget.meetingId,
            'memberId': member.id,
            'teamId': widget.teamId,
            'status': status,
            'markedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance saved successfully! '),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving attendance: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateStatus(String memberId, String status) {
    setState(() {
      _attendanceStatus[memberId] = status;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return AppTheme.successGreen;
      case 'late':
        return AppTheme.warningOrange;
      case 'absent':
        return AppTheme.errorRed;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'late':
        return Icons.access_time;
      case 'absent':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Meeting Info Card
                if (_meetingTopic != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _meetingTopic!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (_meetingDateTime != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.white60,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_meetingDateTime!.day}/${_meetingDateTime!.month}/${_meetingDateTime!.year} at ${_meetingDateTime!.hour}:${_meetingDateTime!.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(color: Colors.white60),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          // Summary
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _SummaryChip(
                                label: 'Present',
                                count: _attendanceStatus.values
                                    .where((s) => s == 'present')
                                    .length,
                                color: AppTheme.successGreen,
                              ),
                              _SummaryChip(
                                label: 'Late',
                                count: _attendanceStatus.values
                                    .where((s) => s == 'late')
                                    .length,
                                color: AppTheme.warningOrange,
                              ),
                              _SummaryChip(
                                label: 'Absent',
                                count: _attendanceStatus.values
                                    .where((s) => s == 'absent')
                                    .length,
                                color: AppTheme.errorRed,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // Members List
                Expanded(
                  child: _members.isEmpty
                      ? const Center(
                          child: Text(
                            'No team members found',
                            style: TextStyle(color: Colors.white60),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _members.length,
                          itemBuilder: (context, index) {
                            final member = _members[index];
                            final status =
                                _attendanceStatus[member.id] ?? 'absent';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AppCard(
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppTheme.primaryPurple,
                                        child: Text(
                                          member.avatarInitials,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        member.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        member.email,
                                        style: const TextStyle(
                                          color: Colors.white60,
                                        ),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                            status,
                                          ).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: _getStatusColor(status),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getStatusIcon(status),
                                              size: 16,
                                              color: _getStatusColor(status),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              status.toUpperCase(),
                                              style: TextStyle(
                                                color: _getStatusColor(status),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Divider(height: 1),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _StatusButton(
                                              label: 'Present',
                                              icon: Icons.check_circle,
                                              color: AppTheme.successGreen,
                                              isSelected: status == 'present',
                                              onTap: () => _updateStatus(
                                                member.id,
                                                'present',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _StatusButton(
                                              label: 'Late',
                                              icon: Icons.access_time,
                                              color: AppTheme.warningOrange,
                                              isSelected: status == 'late',
                                              onTap: () => _updateStatus(
                                                member.id,
                                                'late',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _StatusButton(
                                              label: 'Absent',
                                              icon: Icons.cancel,
                                              color: AppTheme.errorRed,
                                              isSelected: status == 'absent',
                                              onTap: () => _updateStatus(
                                                member.id,
                                                'absent',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Save Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveAttendance,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isLoading ? 'Saving...' : 'Save Attendance'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white60),
        ),
      ],
    );
  }
}
