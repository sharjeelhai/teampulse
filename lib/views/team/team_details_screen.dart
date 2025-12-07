import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/team_viewmodel.dart';
import '../../viewmodels/meeting_viewmodel.dart';
import '../../models/team_model.dart';
import '../../models/meeting_model.dart';
import '../../models/user_model.dart';
import '../../widgets/member_card.dart';
import '../../repositories/user_repository.dart';
import '../meeting/meeting_details_screen.dart';

class TeamDetailsScreen extends StatefulWidget {
  final String teamId;
  const TeamDetailsScreen({super.key, required this.teamId});

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  final UserRepository _userRepository = UserRepository();
  final Map<String, UserModel?> _members = {};
  UserModel? _teamLead;

  @override
  void initState() {
    super.initState();
    // Load team and its meetings
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final teamVM = Provider.of<TeamViewModel>(context, listen: false);
      final meetingVM = Provider.of<MeetingViewModel>(context, listen: false);
      teamVM.loadTeamById(widget.teamId);
      meetingVM.loadMeetingsByTeam(widget.teamId);

      // Load member data and team lead data after team is loaded
      await _loadMemberData(teamVM);
      await _loadTeamLeadData(teamVM);
    });
  }

  Future<void> _loadTeamLeadData(TeamViewModel teamVM) async {
    if (teamVM.selectedTeam != null) {
      try {
        final lead = await _userRepository.getUserById(
          teamVM.selectedTeam!.leadId,
        );
        setState(() {
          _teamLead = lead;
        });
      } catch (e) {
        debugPrint(
          'Failed to load team lead ${teamVM.selectedTeam!.leadId}: $e',
        );
        setState(() {
          _teamLead = null;
        });
      }
    }
  }

  Future<void> _loadMemberData(TeamViewModel teamVM) async {
    if (teamVM.selectedTeam != null) {
      for (final memberId in teamVM.selectedTeam!.memberIds) {
        try {
          final user = await _userRepository.getUserById(memberId);
          setState(() {
            _members[memberId] = user;
          });
        } catch (e) {
          debugPrint('Failed to load member $memberId: $e');
          setState(() {
            _members[memberId] = null;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Defensive build wrapper: catch synchronous build errors and surface friendly UI
    try {
      return Scaffold(
        appBar: AppBar(title: const Text('Team Details')),
        body: Consumer2<TeamViewModel, MeetingViewModel>(
          builder: (context, teamVM, meetingVM, child) {
            if (teamVM.isLoading && teamVM.selectedTeam == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final TeamModel? team = teamVM.selectedTeam;
            if (team == null) {
              return const Center(child: Text('Team not found'));
            }

            // Load member data if not already loaded
            if (_members.isEmpty && team.memberIds.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadMemberData(teamVM);
              });
            }

            // Load team lead data if not already loaded
            if (_teamLead == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadTeamLeadData(teamVM);
              });
            }

            final List<MeetingModel> meetings = meetingVM.meetingsForTeam(
              team.id,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lead: ${_teamLead?.email ?? team.leadId}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Members',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (team.memberIds.isEmpty)
                    const Text('No members yet')
                  else
                    Column(
                      children: team.memberIds.map((mid) {
                        final member = _members[mid];
                        if (member == null) {
                          // Show loading or placeholder while member data loads
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                                title: Text('Loading member...'),
                              ),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: MemberCard(
                            member: member,
                            onTap: () {
                              debugPrint('Member tapped: ${member.name}');
                              // Optionally navigate to member profile if you have a screen
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Meetings',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to CreateMeetingScreen if implemented
                          // Keep try/catch when navigating
                          try {
                            Navigator.of(context).pushNamed(
                              '/meeting/create',
                              arguments: {'teamId': team.id},
                            );
                          } catch (e, st) {
                            debugPrint(
                              'Navigation to create meeting failed: $e\n$st',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Unable to open create meeting'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('New'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (meetings.isEmpty)
                    const Text('No meetings scheduled')
                  else
                    Column(
                      children: meetings.map((m) {
                        return ListTile(
                          title: Text(m.topic),
                          subtitle: Text(m.dateTime.toLocal().toString()),
                          onTap: () async {
                            debugPrint('Meeting tapped: ${m.id}');
                            try {
                              // Defensive navigation: ensure exceptions are caught
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MeetingDetailsScreen(meetingId: m.id),
                                ),
                              );
                            } catch (e, st) {
                              debugPrint(
                                'Navigation to MeetingDetailsScreen failed: $e\n$st',
                              );
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to open meeting'),
                                ),
                              );
                            }
                          },
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        ),
      );
    } catch (e, st) {
      debugPrint('Error building TeamDetailsScreen: $e\n$st');
      return Scaffold(
        appBar: AppBar(title: const Text('Team Details')),
        body: Center(child: Text('An error occurred loading this team.')),
      );
    }
  }
}
