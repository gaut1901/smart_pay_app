import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import '../models/team_model.dart';
import 'auth_service.dart';

class TeamService {
  /// Get all team members from the dedicated team API
  Future<List<TeamMember>> getTeamMembers() async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.team}');
    
    try {
      developer.log('TeamService: Fetching team members from $url');
      final response = await http.get(
        url,
        headers: user.toHeaders(),
      );

      developer.log('TeamService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final teamData = jsonDecode(data['response']);

        // Log all available keys to debug which key holds team members
        developer.log('TeamService: Response keys: ${teamData.keys.toList()}');

        // Try known possible keys for team member list
        List? teamList = teamData['dtTeam'] as List?;
        if (teamList == null || teamList.isEmpty) {
          teamList = teamData['dtTeamMem'] as List?;
        }
        if (teamList == null || teamList.isEmpty) {
          teamList = teamData['dtMember'] as List?;
        }
        if (teamList == null || teamList.isEmpty) {
          teamList = teamData['dtEmp'] as List?;
        }
        if (teamList == null || teamList.isEmpty) {
          teamList = teamData['dtTeamMembers'] as List?;
        }

        developer.log('TeamService: Found ${teamList?.length ?? 0} team members');

        if (teamList == null) {
          // Throw so the error surfaces in the UI with available keys
          throw Exception(
            'Team member list not found in API response.\n'
            'Available keys: ${teamData.keys.toList()}',
          );
        }
        
        return teamList.map((json) => TeamMember.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load team members: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('TeamService: Error fetching team members: $e');
      rethrow;
    }
  }

  /// Get team member details by employee code
  Future<TeamMember?> getTeamMemberDetails(String empCode) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    // In SmartPayV4, details are often part of the dashboard API when a member is selected
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.dashboard}?sdate=$dateStr');
    
    try {
      final headers = user.toHeaders();
      headers['UserData_memberempcode'] = empCode;
      
      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dashboardData = jsonDecode(data['response']);
        
        final empList = dashboardData['dt_Emp'] as List?;
        if (empList == null || empList.isEmpty) return null;
        
        final empData = empList[0];
        return TeamMember.fromJson(empData);
      } else {
        throw Exception('Failed to load team member details: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get approval counts for a team member
  Future<TeamMemberApprovals> getTeamMemberApprovals(String empCode) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.approvalStatus}');
    
    try {
      final headers = user.toHeaders();
      headers['UserData_memberempcode'] = empCode;
      
      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final approvalsData = jsonDecode(data['response']);
        
        return TeamMemberApprovals.fromJson(approvalsData);
      } else {
        throw Exception('Failed to load approvals: ${response.statusCode}');
      }
    } catch (e) {
      return TeamMemberApprovals();
    }
  }
}
