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
      backgroundColor: const Color(0xFFF8F9FB), // AppColors.background
      appBar: AppBar(
        title: const Text('Wages Details', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
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
                      _buildComponentsList('Salary Components', 'E'),
                      const SizedBox(height: 16),
                      if (_wagesData?.salaryType == 'CTC') ...[
                        _buildComponentsList('Statutory Benefits', 'CTC'),
                        const SizedBox(height: 16),
                        _buildComponentsList('Salary Deductions', 'CD'),
                        const SizedBox(height: 16),
                        _buildTakeHomeSection(),
                        const SizedBox(height: 16),
                      ],
                      _buildReimbursementList(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitWages,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDE3C4B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Update Wages', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _otWageController,
            decoration: InputDecoration(
              labelText: 'OT Wages / Hour',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.all(12),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedIncDate,
            decoration: InputDecoration(
              labelText: 'Increment On',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
    );
  }

  Widget _buildCTCCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _ctcController,
        decoration: InputDecoration(
          labelText: 'CTC',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.all(12),
        ),
        keyboardType: TextInputType.number,
        onChanged: (value) {
          // In a real app, you'd trigger calculation here
        },
      ),
    );
  }

  Widget _buildComponentsList(String title, String edType) {
    final components = _wagesData?.dtEarn.where((e) => e.edtype == edType).toList() ?? [];
    if (components.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...components.map((c) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(c.edname ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('${c.p?.toString() ?? 0}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Monthly', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(c.camount?.toStringAsFixed(2) ?? '0.00', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Yearly', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(c.yamount?.toStringAsFixed(2) ?? '0.00', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildTakeHomeSection() {
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Salary Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSummaryItem('Gross Salary', monthlyGross, yearlyGross),
          const Divider(height: 24),
          _buildSummaryItem('Total Deduction', monthlyDed, yearlyDed),
          const Divider(height: 24),
          _buildSummaryItem('Take Home Salary', monthlyGross - monthlyDed, yearlyGross - yearlyDed, isHighlight: true),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double monthly, double yearly, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: TextStyle(
          fontSize: 14, 
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
          color: isHighlight ? Colors.blue : Colors.black87
        ))),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(monthly.toStringAsFixed(2), style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              fontSize: 14
            )),
            Text('Monthly', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(yearly.toStringAsFixed(2), style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              fontSize: 14
            )),
            Text('Yearly', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildReimbursementList() {
    final reimbursements = _wagesData?.dtDed ?? [];
    if (reimbursements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reimbursement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...reimbursements.map((r) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.edname ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Unlimited', style: TextStyle(fontSize: 13)),
                      value: r.unlimited, 
                      onChanged: (val) => setState(() => r.unlimited = val ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                  ),
                  Expanded(
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Salary', style: TextStyle(fontSize: 13)),
                      value: r.salaryPay, 
                      onChanged: (val) => setState(() => r.salaryPay = val ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: r.maxAllowed?.toString() ?? '0'),
                onChanged: (val) => r.maxAllowed = double.tryParse(val) ?? 0,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Max Limit',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }
}
