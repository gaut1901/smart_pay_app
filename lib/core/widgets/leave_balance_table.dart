import 'package:flutter/material.dart';
import '../constants.dart';

class LeaveBalanceTable extends StatelessWidget {
  final List<dynamic> balances;
  final String title;

  const LeaveBalanceTable({
    super.key,
    required this.balances,
    this.title = 'LEAVE BALANCE',
  });

  @override
  Widget build(BuildContext context) {
    if (balances.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F3F4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF1A335E),
                letterSpacing: 0.5,
              ),
            ),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 32,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: title.isEmpty 
                  ? BorderRadius.circular(8) 
                  : const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
            ),
            child: Table(
              columnWidths: const {
                0: IntrinsicColumnWidth(), // LEAVE
                1: FixedColumnWidth(80),   // OPENING
                2: FixedColumnWidth(80),   // CREDIT
                3: FixedColumnWidth(80),   // LAPS
                4: FixedColumnWidth(80),   // TAKEN
                5: FixedColumnWidth(80),   // PENDING
                6: FixedColumnWidth(80),   // CLOSING
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                // Header
                TableRow(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFB),
                  ),
                  children: [
                    _buildHeaderCell('LEAVE', alignLeft: true),
                    _buildHeaderCell('OPENING'),
                    _buildHeaderCell('CREDIT'),
                    _buildHeaderCell('LAPS'),
                    _buildHeaderCell('TAKEN'),
                    _buildHeaderCell('PENDING'),
                    _buildHeaderCell('CLOSING'),
                  ],
                ),
                // Data Rows
                ...balances.map((b) {
                  return TableRow(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade100),
                      ),
                    ),
                    children: [
                      _buildDataCell(_getValue(b, 'LEAVE'), alignLeft: true, isBold: true),
                      _buildDataCell(_getValue(b, 'OPENING')),
                      _buildDataCell(_getValue(b, 'CREDIT')),
                      _buildDataCell(_getValue(b, 'LAPS')),
                      _buildDataCell(_getValue(b, 'TAKEN')),
                      _buildDataCell(_getValue(b, 'PENDING')),
                      _buildDataCell(_getValue(b, 'CLOSING')),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String label, {bool alignLeft = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Text(
        label,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 10,
          color: Color(0xFF1A335E),
        ),
      ),
    );
  }

  Widget _buildDataCell(String value, {bool alignLeft = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Text(
        value,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          color: isBold ? Colors.black87 : Colors.black54,
        ),
      ),
    );
  }

  String _getValue(dynamic item, String column) {
    if (item == null) return '-';
    
    // Support mapping from various keys (API vs Model)
    final searchKeys = <String>[];
    switch (column) {
      case 'LEAVE':
        searchKeys.addAll(['leaveType', 'status', 'LeaveName', 'Status', 'LEAVE']);
        break;
      case 'OPENING':
        searchKeys.addAll(['yearOpen', 'YearOpen', 'Opening', 'OB', 'OPENING']);
        break;
      case 'CREDIT':
        searchKeys.addAll(['yearCredit', 'YearCredit', 'Credit', 'Entitle', 'CREDIT']);
        break;
      case 'LAPS':
        searchKeys.addAll(['yearLaps', 'YearLaps', 'Laps', 'LAPS']);
        break;
      case 'TAKEN':
        searchKeys.addAll(['yearTaken', 'YearTaken', 'Taken', 'TAKEN']);
        break;
      case 'PENDING':
        searchKeys.addAll(['pending', 'Pending', 'PENDING']);
        break;
      case 'CLOSING':
        searchKeys.addAll(['yearBalance', 'YearBalance', 'Balance', 'Closing', 'CLOSING']);
        break;
    }

    dynamic value;
    if (item is Map) {
      for (var key in searchKeys) {
        if (item.containsKey(key)) {
          value = item[key];
          break;
        }
      }
    } else {
      // Reflection-like check for objects (though crude in Dart without mirror)
      // Since we know our types are LeaveBalance or Map, we can try to access if it's a model
      try {
        if (column == 'LEAVE') value = item.leaveType;
        if (column == 'OPENING') value = item.yearOpen;
        if (column == 'CREDIT') value = item.yearCredit;
        if (column == 'LAPS') value = item.yearLaps;
        if (column == 'TAKEN') value = item.yearTaken;
        if (column == 'PENDING') value = item.pending;
        if (column == 'CLOSING') value = item.yearBalance;
      } catch (_) {}
    }

    if (value == null) return column == 'LEAVE' ? '-' : '0';
    
    if (value is double) {
       // Format as whole number if possible, else 1 decimal
       if (value == value.toInt()) return value.toInt().toString();
       return value.toStringAsFixed(1);
    }
    
    return value.toString();
  }
}
