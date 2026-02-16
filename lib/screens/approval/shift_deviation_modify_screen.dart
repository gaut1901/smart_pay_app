import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../core/api_config.dart';
import '../../data/services/auth_service.dart';

class ShiftDeviationModifyScreen extends StatefulWidget {
  final Map<String, dynamic> details;
  final String id;

  const ShiftDeviationModifyScreen({
    super.key,
    required this.details,
    required this.id,
  });

  @override
  State<ShiftDeviationModifyScreen> createState() => _ShiftDeviationModifyScreenState();
}

class _ShiftDeviationModifyScreenState extends State<ShiftDeviationModifyScreen> {
  String? _selectedEmployee;
  List<String> _employeeOptions = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final List<dynamic> dtEmp = widget.details['dtEmp'] ?? [];
    _employeeOptions = dtEmp.map((e) => e['EmpName']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    
    _selectedEmployee = (widget.details['EmpNames'] != null && widget.details['EmpNames'] is List && widget.details['EmpNames'].isNotEmpty) 
        ? widget.details['EmpNames'][0].toString() 
        : (widget.details['EmpNames']?.toString() ?? '');

    if (_selectedEmployee != null && !_employeeOptions.contains(_selectedEmployee)) {
      if (_employeeOptions.isNotEmpty) {
        // _selectedEmployee = _employeeOptions[0];
      } else {
        _selectedEmployee = null;
      }
    }
  }

  Future<void> _submitModification(String status) async {
    if (_selectedEmployee == null || _selectedEmployee!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an employee')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      final postData = {
        "EditId": widget.id,
        "SDate": widget.details['SDate'],
        "StartDate": widget.details['StartDate'],
        "EndDate": widget.details['EndDate'],
        "GroupName": widget.details['GroupName'],
        "DShiftName": widget.details['DShiftName'],
        "EmpNames": [_selectedEmployee],
        "App": status,
        "Actions": "Modify",
      };

      final url = Uri.parse('${ApiConfig.baseUrl}api/attn/ShiftDevApproval/');
      final response = await http.post(
        url,
        headers: user.toHeaders(),
        body: jsonEncode(postData),
      );

      if (!mounted) return;
      
      if (response.statusCode == 200) {
        final resp = jsonDecode(response.body);
        final respData = jsonDecode(resp['response']);
        if (respData['JSONResult'].toString() == '0') {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request $status successfully')));
          Navigator.pop(context, true); // Return to list and refresh
        } else {
          throw Exception(respData['error'] ?? 'Submission failed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Modify Shift Deviation', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Modify Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(height: 32),
                  
                  const Text('Employees', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _employeeOptions.contains(_selectedEmployee) ? _selectedEmployee : null,
                        hint: const Text('Select Employee'),
                        items: _employeeOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedEmployee = val;
                          });
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildDetailRow('Group Name', widget.details['GroupName'] ?? '-'),
                  _buildDetailRow('Deviated Shift', widget.details['DShiftName'] ?? '-'),
                  _buildDetailRow('Start Date', widget.details['StartDate'] ?? '-'),
                  _buildDetailRow('End Date', widget.details['EndDate'] ?? '-'),
                  _buildDetailRow('Entry Date', widget.details['SDate'] ?? '-'),
                  
                  const SizedBox(height: 40),
                  
                  if (_isSubmitting)
                    const Center(child: CircularProgressIndicator())
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _submitModification('Rejected'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _submitModification('Approved'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textDark)),
          const Divider(height: 16, thickness: 0.5),
        ],
      ),
    );
  }
}
