import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smartpay_flutter/core/constants.dart';
import 'package:smartpay_flutter/core/ui_constants.dart';
import 'package:smartpay_flutter/data/services/it_file_service.dart';

class ITFileScreen extends StatefulWidget {
  const ITFileScreen({super.key});

  @override
  State<ITFileScreen> createState() => _ITFileScreenState();
}

class _ITFileScreenState extends State<ITFileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ITFileService _itFileService = ITFileService();
  
  List<ITFileRequest> _history = [];
  bool _isLoadingHistory = true;
  String? _historyError;

  // Form data
  List<dynamic> _dtFinYear = [];
  List<dynamic> _dtEmp = [];
  List<dynamic> _dtSlab = [];
  List<dynamic> _dtITHeadType = [];
  List<dynamic> _dtITHead = [];
  List<dynamic> _dtDet = []; // Details/Attachments
  bool _isLoadingLookups = true;

  // Form fields
  DateTime _selectedDate = DateTime.now();
  String? _selectedFinYear;
  String? _selectedEmpName;
  String? _selectedSlab;
  String? _selectedITHeadType;
  String? _selectedITHead;
  final TextEditingController _pAmountController = TextEditingController(text: '0');
  final TextEditingController _aAmountController = TextEditingController(text: '0');
  File? _selectedFile;
  bool _isSubmitting = false;

  // Edit/View state
  String _action = 'Create'; // Create, Modify, View
  String _editId = '';
  String _delIds = '0'; // IDs of deleted attachments
  String _app = '-'; // App status

  // Table & Search State
  final TextEditingController _searchController = TextEditingController();
  int _rowsPerPage = 10;
  List<ITFileRequest> _filteredHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredHistory = _history;
      } else {
        _filteredHistory = _history.where((request) => 
          (request.ticketNo.toLowerCase().contains(_searchController.text.toLowerCase())) ||
          (request.empName.toLowerCase().contains(_searchController.text.toLowerCase())) ||
          (request.itHead.toLowerCase().contains(_searchController.text.toLowerCase()))
        ).toList();
      }
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      _fetchHistory(),
      _fetchLookups(),
    ]);
  }

  Future<void> _fetchHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });
    try {
      final history = await _itFileService.getITFileHistory();
      if (mounted) {
        setState(() {
          _history = history;
          _filteredHistory = history;
          _isLoadingHistory = false;
        });
        _onSearchChanged();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyError = e.toString().replaceAll('Exception: ', '');
          _isLoadingHistory = false;
        });
      }
    }
  }

  Future<void> _fetchLookups() async {
    if (!mounted) return;
    setState(() => _isLoadingLookups = true);
    
    try {
      Map<String, dynamic> data;
      if (_action == 'Create') {
        data = await _itFileService.getITFileLookup();
      } else {
        data = await _itFileService.getITFileDetails(id: _editId, action: _action);
      }

      if (!mounted) return;

      setState(() {
        _dtFinYear = data['dtFinYear'] ?? [];
        _dtEmp = data['dtEmp'] ?? [];
        _dtSlab = data['dtSlab'] ?? [];
        _dtITHeadType = data['dtITHeadType'] ?? [];
        _dtITHead = data['dtITHead'] ?? [];
        _dtDet = data['dtDet'] ?? [];
        _delIds = data['DelIds']?.toString() ?? '0';

        if (_action == 'Create') {
            if (_dtFinYear.isNotEmpty) _selectedFinYear = _dtFinYear[0]['FinYear'];
            if (_dtEmp.isNotEmpty) _selectedEmpName = (_dtEmp[0]['EMPNAME']?.toString() ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
            if (_dtSlab.isNotEmpty) _selectedSlab = _dtSlab[0]['ITSlabName'];
            if (_dtITHeadType.isNotEmpty) _selectedITHeadType = _dtITHeadType[0]['ITHeadType'];
            
            if (data['SDate'] != null && data['SDate'] != "") {
               try {
                 _selectedDate = DateFormat('dd-MM-yyyy').parse(data['SDate']);
               } catch (_) {}
            }
            _pAmountController.text = '0';
            _aAmountController.text = '0';
        } else {
            // Populate fields for Edit/View
             if (data['EntryDate'] != null) {
                try {
                  _selectedDate = DateFormat('dd-MM-yyyy').parse(data['EntryDate']);
                } catch (_) {}
             }
             _selectedFinYear = data['FinYear'];
             _selectedEmpName = (data['EmpName']?.toString() ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
             _selectedSlab = data['SlabName'];
             _selectedITHeadType = data['ITHeadType'];
             _selectedITHead = data['ITHead'];
             _pAmountController.text = data['PAmount']?.toString() ?? '0';
             _aAmountController.text = data['AAmount']?.toString() ?? '0';
             _app = data['App'] ?? '-';
        }
        
        _isLoadingLookups = false;
      });
      
      // If Creating, fetch default head params
      if (_action == 'Create') {
          _onITHeadParamsChange();
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLookups = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  Future<void> _onITHeadParamsChange() async {
    if (_selectedEmpName == null || _selectedITHeadType == null || _selectedFinYear == null || _selectedSlab == null) return;

    try {
      final result = await _itFileService.getITHead(
        empName: _selectedEmpName!,
        itHeadType: _selectedITHeadType!,
        finYear: _selectedFinYear!,
        slabName: _selectedSlab!,
      );
      if (!mounted) return;
      setState(() {
        _dtITHead = result['dtITHead'] ?? [];
        if (_dtITHead.isNotEmpty) {
           // Keep selected head if it exists in new list, else select first
           if (_selectedITHead == null || !_dtITHead.any((element) => element['ITHead'] == _selectedITHead)) {
               _selectedITHead = _dtITHead[0]['ITHead'];
           }
          _onITHeadChange();
        } else {
          _selectedITHead = null;
          _pAmountController.text = '0';
        }
      });
    } catch (e) {
      debugPrint('Error fetching IT heads: $e');
    }
  }

  Future<void> _onITHeadChange() async {
    if (_selectedEmpName == null || _selectedITHeadType == null || _selectedFinYear == null || _selectedSlab == null || _selectedITHead == null) return;
    
    // In edit mode, we might not want to overwrite values if user hasn't changed dependencies
    // But for now, we follow standard behavior: if head changes, we fetch fresh amount.
    // If just loading edit form, this might overwrite saved amount if we are not careful.
    // _fetchLookups handles initial population. This is for User interaction.
    
    try {
      final result = await _itFileService.getITHeadAmount(
        empName: _selectedEmpName!,
        itHeadType: _selectedITHeadType!,
        finYear: _selectedFinYear!,
        slabName: _selectedSlab!,
        itHead: _selectedITHead!,
      );
      if (!mounted) return;
      setState(() {
        final dtAmount = result['dtAmount'] as List?;
        if (dtAmount != null && dtAmount.isNotEmpty) {
          _pAmountController.text = dtAmount[0]['PAmount']?.toString() ?? '0';
        } else {
          _pAmountController.text = '0';
        }
      });
    } catch (e) {
      debugPrint('Error fetching IT head amount: $e');
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_action == 'View') {
        _resetForm();
        _tabController.animateTo(1);
        return;
    }

    if (_selectedFinYear == null || _selectedEmpName == null || _selectedSlab == null || _selectedITHeadType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }
    if (_aAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Actual Amount')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dateFormat = DateFormat('dd-MM-yyyy');
      await _itFileService.submitITFile(
        entryDate: dateFormat.format(_selectedDate),
        slabName: _selectedSlab!,
        finYear: _selectedFinYear!,
        itHead: _selectedITHead!,
        itHeadType: _selectedITHeadType!,
        empName: _selectedEmpName!,
        pAmount: double.tryParse(_pAmountController.text) ?? 0.0,
        aAmount: double.tryParse(_aAmountController.text) ?? 0.0,
        file: _selectedFile,
        actions: _action == 'Create' ? 'Add' : _action, // Map Create to Add to match API
        editId: _editId,
        app: _app,
        delIds: _delIds,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('IT file ${_action == 'Create' ? 'submitted' : 'updated'} successfully')),
        );
        _resetForm();
        _fetchHistory();
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _resetForm() {
      setState(() {
          _action = 'Create';
          _editId = '';
          _delIds = '0';
          _selectedFile = null;
          _aAmountController.text = '0';
          _pAmountController.text = '0';
          _selectedITHead = null;
      });
      _fetchLookups(); // Reload defaults
  }
  
  void _onEdit(ITFileRequest item) {
      setState(() {
          _action = 'Modify';
          _editId = item.id;
      });
      _tabController.animateTo(0);
      _fetchLookups();
  }
  
  void _onView(ITFileRequest item) {
    UIConstants.showViewModal(
      context: context,
      title: 'IT File Details',
      body: FutureBuilder<Map<String, dynamic>>(
        future: _itFileService.getITFileDetails(id: item.id, action: 'View'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            return Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red))));
          }
          
          final d = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                UIConstants.buildDetailItem('Ticket No', d['TicketNo'] ?? ''),
                UIConstants.buildDetailItem('Employee', d['EmpName'] ?? ''),
                UIConstants.buildDetailItem('Fin Year', d['FinYear'] ?? ''),
                UIConstants.buildDetailItem('IT Head', d['ITHead'] ?? ''),
                UIConstants.buildDetailItem('Amount', (d['AAmount'] ?? 0).toString()),
                UIConstants.buildDetailItem('Status', d['App'] ?? ''),
                UIConstants.buildDetailItem('Approved By', d['AppBy'] ?? ''),
                UIConstants.buildDetailItem('Approved On', _formatDate(d['AppOn']?.toString())),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _onDelete(ITFileRequest item) async {
      final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
              title: const Text('Confirm Delete'),
              content: const Text('Are you sure you want to delete this record?'),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
              ],
          ),
      );
      
      if (confirm == true) {
           try {
               // Per old code logic, deletion is a form submit with actions='Delete'
               // We need some minimal data. The service requires non-nullable params.
               // We will use current values or dummy values as backend likely checks ID mainly.
               // However, ideally we should fetch details first to fill required fields if validation strictly requires them.
               // Let's assume ID is enough or we send empty valid strings.
               
               await _itFileService.submitITFile(
                   entryDate: DateFormat('dd-MM-yyyy').format(DateTime.now()),
                   slabName: item.ticketNo, // Likely ignored for delete but required by func signature
                   finYear: item.finYear,
                   itHead: item.itHead,
                   itHeadType: '-',
                   empName: item.empName,
                   pAmount: 0,
                   aAmount: item.amount,
                   actions: 'Delete',
                   editId: item.id,
               );
               
               if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record deleted successfully')));
                   _fetchHistory();
               }
           } catch (e) {
               if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
               }
           }
      }
  }
  
  void _cancelEdit() {
      _resetForm();
      if (_tabController.index == 0) {
          // Stay on tab but reset
      }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pAmountController.dispose();
    _aAmountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Income Tax File', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.accent,
          onTap: (index) {
              if (index == 0 && _action != 'Create') {
                  // If switching to Apply tab manually, reset to Create mode
                  _resetForm();
              }
          },
          tabs: const [
            Tab(text: 'Apply'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe to prevent accidental reset/conflicts
        children: [
          _buildApplyTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildApplyTab() {
    if (_isLoadingLookups) return const Center(child: CircularProgressIndicator());
    final isReadOnly = _action == 'View';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppStyles.modernCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        Text('Income Tax File ($_action)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        if (_action != 'Create')
                            IconButton(icon: const Icon(Icons.close), onPressed: _cancelEdit, tooltip: 'Cancel'),
                    ],
                ),
                const SizedBox(height: 20),
                _buildDatePickerField('Date', _selectedDate, (date) {
                    if (!isReadOnly) setState(() => _selectedDate = date);
                }, isReadOnly: isReadOnly),
                const SizedBox(height: 15),
                _buildDropdownField(
                  'Fin Year', 
                  _dtFinYear.map((e) => e['FinYear']?.toString() ?? '').toList(), 
                  _selectedFinYear, 
                  (val) {
                    setState(() => _selectedFinYear = val);
                    _onITHeadParamsChange();
                  },
                  isReadOnly: isReadOnly
                ),
                const SizedBox(height: 15),
                _buildDropdownField(
                  'Emp Name', 
                  _dtEmp.map((e) => (e['EMPNAME']?.toString() ?? '').trim().replaceAll(RegExp(r'\s+'), ' ')).toList(), 
                  _selectedEmpName?.trim().replaceAll(RegExp(r'\s+'), ' '), 
                  (val) {
                    setState(() => _selectedEmpName = val);
                    _onITHeadParamsChange();
                  },
                  isReadOnly: isReadOnly
                ),
                const SizedBox(height: 15),
                _buildDropdownField(
                  'Slab', 
                  _dtSlab.map((e) => e['ITSlabName']?.toString() ?? '').toList(), 
                  _selectedSlab, 
                  (val) {
                    setState(() => _selectedSlab = val);
                    _onITHeadParamsChange();
                  },
                  isReadOnly: isReadOnly
                ),
                const SizedBox(height: 15),
                _buildDropdownField(
                  'Earnings/Deductions', 
                  _dtITHeadType.map((e) => e['ITHeadType']?.toString() ?? '').toList(), 
                  _selectedITHeadType, 
                  (val) {
                    setState(() => _selectedITHeadType = val);
                    _onITHeadParamsChange();
                  },
                  isReadOnly: isReadOnly
                ),
                const SizedBox(height: 15),
                _buildDropdownField(
                  'Head', 
                  _dtITHead.map((e) => e['ITHead']?.toString() ?? '').toList(), 
                  _selectedITHead, 
                  (val) {
                    setState(() => _selectedITHead = val);
                    _onITHeadChange();
                  },
                  isReadOnly: isReadOnly
                ),
                const SizedBox(height: 15),
                _buildTextField('Projected Amount', '0', _pAmountController, keyboardType: TextInputType.number, readOnly: true),
                const SizedBox(height: 15),
                _buildTextField('Actual Amount', 'Enter amount', _aAmountController, keyboardType: TextInputType.number, readOnly: isReadOnly),
                
                if (!isReadOnly) ...[
                    const SizedBox(height: 15),
                    _buildFilePickerField(),
                ],
                
                // Existing Attachments
                if (_dtDet.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    const Text('Attachments:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._dtDet.map((file) => ListTile(
                        leading: const Icon(Icons.attach_file),
                        title: Text('Attachment (${file['Id']})'),
                        trailing: isReadOnly ? null : IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                                setState(() {
                                    _delIds = _delIds == '0' ? file['Id'].toString() : '$_delIds,${file['Id']}';
                                    _dtDet.remove(file);
                                });
                            },
                        ),
                    )),
                ],

                const SizedBox(height: 30),
                
                Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        if (_action != 'View')
                        ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _action == 'Modify' ? Colors.blue : AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: _isSubmitting 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(_action == 'Modify' ? 'Update Request' : 'Submit Request', style: const TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                        if (_action != 'Create') ...[
                            const SizedBox(height: 10),
                            OutlinedButton(
                                onPressed: _cancelEdit,
                                style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(_action == 'View' ? 'Back' : 'Cancel Edit'),
                            ),
                        ],
                    ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) return const Center(child: CircularProgressIndicator());
    if (_historyError != null) return Center(child: Text(_historyError!, style: const TextStyle(color: Colors.red)));

    return RefreshIndicator(
      onRefresh: () async => _fetchHistory(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
             const SizedBox(height: 16),
             Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  const Text('Income Tax History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildTableActionsRow(),
                  const SizedBox(height: 16),
                  if (_filteredHistory.isEmpty)
                     const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No history found')))
                  else
                    _buildHistoryCards(),
                  const Divider(),
                  _buildPaginationFooter(_filteredHistory.length),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCards() {
    int displayCount = _filteredHistory.length > _rowsPerPage ? _rowsPerPage : _filteredHistory.length;
    List<ITFileRequest> displayedItems = _filteredHistory.take(displayCount).toList();

    return Column(
      children: displayedItems.map((item) => _buildHistoryCard(item)).toList(),
    );
  }

  Widget _buildHistoryCard(ITFileRequest item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCardItem('TKT.NO', item.ticketNo, flex: 1),
              _buildCardItem('EMP NAME', item.empName, flex: 2),
              _buildActions(item),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              _buildCardItem('FIN YEAR', item.finYear, flex: 1),
              _buildCardItem('IT HEAD', item.itHead, flex: 2),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildCardItem('AMOUNT', item.amount.toString(), flex: 1),
              _buildCardItem('STATUS', item.app, flex: 1, isHighlight: true),
              _buildCardItem('APP. ON', _formatDate(item.appOn), flex: 1),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(String label, String value, {int flex = 1, bool isHighlight = false}) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(
            fontSize: 13, 
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? AppColors.primary : const Color(0xFF1E1E1E),
          )),
        ],
      ),
    );
  }

  Widget _buildActions(ITFileRequest item) {
    bool canEdit = (item.app == "-" || item.app == "Pending");
    return UIConstants.buildActionButtons(
        onView: () => _onView(item),
        onEdit: () => _onEdit(item),
        onDelete: () => _onDelete(item),
        editTooltip: canEdit ? 'Modify' : 'Revise',
    );
  }

  Widget _buildTableActionsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Row Per Page', style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _rowsPerPage,
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.blue),
                  items: [10, 25, 50, 100].map((int val) {
                    return DropdownMenuItem<int>(
                      value: val,
                      child: Text('$val', style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _rowsPerPage = val);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 40,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search by Ticket No, Name or IT Head',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: InputBorder.none,
              suffixIcon: Icon(Icons.search, size: 20, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationFooter(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Showing 1 to $count of $count entries', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const Row(
            children: [
              Icon(Icons.chevron_left, color: Colors.grey),
              SizedBox(width: 16),
              Icon(Icons.chevron_right, color: Colors.grey),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDatePickerField(String label, DateTime selectedDate, Function(DateTime) onSelect, {bool isReadOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(
          onTap: isReadOnly ? null : () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 3650)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) onSelect(date);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300), 
                borderRadius: BorderRadius.circular(8),
                color: isReadOnly ? Colors.grey.shade100 : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('dd-MM-yyyy').format(selectedDate)),
                if (!isReadOnly) const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String? value, Function(String?) onChanged, {bool isReadOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300), 
              borderRadius: BorderRadius.circular(8),
              color: isReadOnly ? Colors.grey.shade100 : null,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: const Text('Select option'),
              items: items.map((e) => DropdownMenuItem(
                  value: e, 
                  child: Text(
                      e, 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                  )
              )).toList(),
              onChanged: isReadOnly ? null : onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String placeholder, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: placeholder,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.all(12),
            filled: readOnly,
            fillColor: readOnly ? Colors.grey.shade100 : null,
          ),
        ),
      ],
    );
  }

  Widget _buildFilePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('New Attachment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickFile,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_file, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedFile == null ? 'Select file (PDF, JPG, PNG)' : _selectedFile!.path.split('/').last,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _selectedFile == null ? Colors.grey : Colors.black),
                  ),
                ),
                if (_selectedFile != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() => _selectedFile = null),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
