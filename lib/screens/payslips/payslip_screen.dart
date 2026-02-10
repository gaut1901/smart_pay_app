import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../data/models/payslip_model.dart';
import '../../data/services/payslip_service.dart';
import 'payslip_view_screen.dart';

class PayslipScreen extends StatefulWidget {
  const PayslipScreen({super.key});

  @override
  State<PayslipScreen> createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
  final PayslipService _payslipService = PayslipService();
  bool _isLoading = true;
  String? _error;
  PayslipLookupResponse? _lookupData;

  @override
  void initState() {
    super.initState();
    _loadLookupData();
  }

  Future<void> _loadLookupData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _payslipService.getPayslipLookup();
      setState(() {
        _lookupData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _viewPayslip(String salaryName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final template = _lookupData?.templates.isNotEmpty == true 
          ? _lookupData!.templates[0].templateName 
          : "";
      final html = await _payslipService.getPayslipHtml(salaryName, template);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PayslipViewScreen(
            htmlBase64: html,
            title: 'Payslip - $salaryName',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Payslips', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLookupData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadLookupData, child: const Text('Retry')),
                    ],
                  ),
                )
              : _lookupData == null || _lookupData!.periods.isEmpty
                  ? const Center(child: Text('No payslips available.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _lookupData!.periods.length,
                      itemBuilder: (context, index) {
                        final period = _lookupData!.periods[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: AppStyles.modernCardDecoration,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.receipt_long, color: AppColors.primary),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      period.salaryName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const Text('Salary Period', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                  ],
                                ),
                              ),
                              _ActionButton(
                                icon: Icons.visibility_outlined,
                                onTap: () => _viewPayslip(period.salaryName),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.primary.withValues(alpha: 0.05),
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }
}
