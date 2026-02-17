import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smartpay_flutter/widgets/main_drawer.dart';
import '../../core/constants.dart';
import '../../data/models/team_model.dart';
import '../../data/services/team_service.dart';
import '../../data/services/auth_service.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final TeamService _teamService = TeamService();
  List<TeamMember> _teamMembers = [];
  List<TeamMember> _filteredTeamMembers = [];
  bool _isLoading = true;
  String? _error;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTeamMembers();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadTeamMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final members = await _teamService.getTeamMembers();
      setState(() {
        _teamMembers = members;
        _filteredTeamMembers = List.from(members); // Initialize filtered list
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        _filteredTeamMembers = []; // Clear filtered list on error
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterTeamMembers(_searchController.text);
  }

  void _filterTeamMembers(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredTeamMembers = List.from(_teamMembers);
      });
      return;
    }

    setState(() {
      _filteredTeamMembers = _teamMembers.where((member) {
        final lowerQuery = query.toLowerCase();
        return member.displayName.toLowerCase().contains(lowerQuery) ||
               member.empName.toLowerCase().contains(lowerQuery) ||
               member.empCode.toLowerCase().contains(lowerQuery) ||
               member.ticketNo.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: SvgPicture.asset(
          'assets/images/logo.svg',
          height: 30,
          color: Colors.white,
        ),
        centerTitle: true,
        elevation: 0,
      ),
      drawer: const MainDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Team Members',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or employee number...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _searchController.clear(); // Clear search when retrying
                          _loadTeamMembers();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _teamMembers.isEmpty
                  ? const Center(
                      child: Text('No team members found'),
                    )
                  : _filteredTeamMembers.isEmpty && _searchController.text.isNotEmpty
                      ? const Center(
                          child: Text('No team members found matching your search'),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            _searchController.clear(); // Clear search on refresh
                            await _loadTeamMembers();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _filteredTeamMembers.length,
                            itemBuilder: (context, index) {
                              final member = _filteredTeamMembers[index];
                              final color = AppColors.chartColors[index % AppColors.chartColors.length];
                              
                              return _buildTeamMemberCard(member, color);
                            },
                          ),
                        ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberCard(TeamMember member, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/team_detail',
            arguments: member,
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withValues(alpha: 0.1),
                backgroundImage: member.photoBase64 != null && member.photoBase64!.length > 100
                    ? MemoryImage(
                        base64Decode(member.photoBase64!.split(',').last),
                      )
                    : null,
                child: member.photoBase64 == null || member.photoBase64!.length <= 100
                    ? Icon(Icons.person, size: 30, color: color)
                    : null,
              ),
              const SizedBox(width: 16),
              // Member Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (member.desName != null && member.desName!.isNotEmpty)
                      Text(
                        member.desName!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (member.deptName != null && member.deptName!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              member.deptName!,
                              style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          member.ticketNo,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
