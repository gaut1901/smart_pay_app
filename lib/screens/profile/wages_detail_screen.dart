import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../data/models/wages_model.dart';
import '../../data/services/profile_service.dart';

class WagesDetailScreen extends StatefulWidget {
  const WagesDetailScreen({super.key});

  @override
  State<WagesDetailScreen> createState() => _WagesDetailScreenState();
}

class _WagesDetailScreenState extends State<WagesDetailScreen> {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  String? _error;
  WagesModel? _wagesData;
  final TextEditingController _otWageController = TextEditingController();
  final TextEditingController _ctcController = TextEditingController();
  String? _selectedIncDate;

  @override
  void initState() {
    super.initState();
    _fetchWages();
  }

  Future<void> _fetchWages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _profileService.getWagesData();
      setState(() {
        _wagesData = data;
        _otWageController.text = data.otWage ?? '';
        _ctcController.text = data.ctc ?? '';
        if (data.dtIncDate.isNotEmpty) {
          _selectedIncDate = data.dtIncDate.first.incdate1;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _submitWages() async {
    if (_wagesData == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedWages = WagesModel(
        dtIncDate: _wagesData!.dtIncDate,
        dtEarn: _wagesData!.dtEarn,
        dtDed: _wagesData!.dtDed,
        dtCTC: _wagesData!.dtCTC,
        otWage: _otWageController.text,
        salaryType: _wagesData!.salaryType,
        incDate: _selectedIncDate,
        ctc: _ctcController.text,
      );

      final result = await _profileService.submitWages(updatedWages);
      
      if (mounted) {
        if (result['JSONResult'] == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wages detail updated successfully')),
          );
          Navigator.pop(context);
        } else {
          setState(() {
            _isLoading = false;
            _error = result['ErrorMsg'] ?? 'Failed to update wages';
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wages Detail'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 16),
                      if (_wagesData?.salaryType == 'CTC') ...[
                        _buildCTCCard(),
                        const SizedBox(height: 16),
                      ],
                      _buildComponentsTable('Salary Components', 'E'),
                      const SizedBox(height: 16),
                      if (_wagesData?.salaryType == 'CTC') ...[
                        _buildComponentsTable('Statutory Benefits', 'CTC'),
                        const SizedBox(height: 16),
                        _buildComponentsTable('Salary Deductions', 'CD'),
                        const SizedBox(height: 16),
                        _buildTakeHomeSection(),
                        const SizedBox(height: 16),
                      ],
                      _buildReimbursementTable(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitWages,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Update Wages', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _otWageController,
              decoration: const InputDecoration(
                labelText: 'OT Wages / Hour',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedIncDate,
              decoration: const InputDecoration(
                labelText: 'Increment On',
                border: OutlineInputBorder(),
              ),
              items: _wagesData?.dtIncDate.map((item) {
                return DropdownMenuItem<String>(
                  value: item.incdate1,
                  child: Text(item.incdate ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedIncDate = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTCCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: TextField(
          controller: _ctcController,
          decoration: const InputDecoration(
            labelText: 'CTC',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            // In a real app, you'd trigger calculation here
          },
        ),
      ),
    );
  }

  Widget _buildComponentsTable(String title, String edType) {
    final components = _wagesData?.dtEarn.where((e) => e.edtype == edType).toList() ?? [];
    if (components.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: Colors.grey.shade300),
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(2),
          },
          children: [
            TableRow(
              children: [
                Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.all(8.0),
                  child: const Text('Component', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.all(8.0),
                  child: const Text('%', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.all(8.0),
                  child: const Text('Monthly', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                ),
                Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.all(8.0),
                  child: const Text('Yearly', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                ),
              ],
            ),
            ...components.map((c) => TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(8.0), child: Text(c.edname ?? '')),
                Padding(padding: const EdgeInsets.all(8.0), child: Text(c.p?.toString() ?? '')),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(c.camount?.toStringAsFixed(2) ?? '0.00', textAlign: TextAlign.right),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(c.yamount?.toStringAsFixed(2) ?? '0.00', textAlign: TextAlign.right),
                ),
              ],
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildTakeHomeSection() {
    // Basic calculation for display
    double monthlyGross = 0;
    double yearlyGross = 0;
    double monthlyDed = 0;
    double yearlyDed = 0;

    for (var c in _wagesData?.dtEarn ?? []) {
      if (c.edtype == 'E') {
        monthlyGross += c.camount ?? 0;
        yearlyGross += c.yamount ?? 0;
      } else if (c.edtype == 'CD') {
        monthlyDed += c.camount ?? 0;
        yearlyDed += c.yamount ?? 0;
      }
    }

    return Column(
      children: [
        _buildSummaryRow('Gross Salary', monthlyGross, yearlyGross, Colors.grey.shade200),
        _buildSummaryRow('Total Deduction', monthlyDed, yearlyDed, Colors.grey.shade200),
        _buildSummaryRow('Take Home Salary', monthlyGross - monthlyDed, yearlyGross - yearlyDed, Colors.blue.shade50),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double monthly, double yearly, Color bgColor) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text(monthly.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text(yearly.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildReimbursementTable() {
    final reimbursements = _wagesData?.dtDed ?? [];
    if (reimbursements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reimbursement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: Colors.grey.shade300),
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              children: [
                Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.all(8.0),
                  child: const Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.all(8.0),
                  child: const Text('Unlim.', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.all(8.0),
                  child: const Text('Max Limit', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                ),
                Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.all(8.0),
                  child: const Text('Sal.', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            ...reimbursements.map((r) => TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(8.0), child: Text(r.edname ?? '')),
                Checkbox(value: r.unlimited, onChanged: (val) => setState(() => r.unlimited = val ?? false)),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: TextField(
                    decoration: const InputDecoration(isDense: true),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => r.maxAllowed = double.tryParse(val) ?? 0,
                    controller: TextEditingController(text: r.maxAllowed?.toString() ?? '0'),
                  ),
                ),
                Checkbox(value: r.salaryPay, onChanged: (val) => setState(() => r.salaryPay = val ?? false)),
              ],
            )),
          ],
        ),
      ],
    );
  }
}
