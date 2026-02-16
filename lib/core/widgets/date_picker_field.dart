import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Global constant for consistent height across all filter components
const double _kFilterComponentHeight = 48.0;

/// A reusable date picker field widget with consistent styling
/// Ensures full date is visible without truncation
class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime selectedDate;
  final VoidCallback onTap;
  final double? height;

  const DatePickerField({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onTap,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? _kFilterComponentHeight,
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 11),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            suffixIcon: const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.calendar_today, size: 14),
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
            ),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              DateFormat('dd-MM-yyyy').format(selectedDate),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ),
    );
  }
}

/// A row containing two date pickers and a search button
/// All components have consistent height for perfect alignment
class DateFilterRow extends StatelessWidget {
  final DateTime fromDate;
  final DateTime toDate;
  final VoidCallback onFromDateTap;
  final VoidCallback onToDateTap;
  final VoidCallback onSearch;
  final bool isLoading;

  const DateFilterRow({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.onFromDateTap,
    required this.onToDateTap,
    required this.onSearch,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: DatePickerField(
            label: 'From Date',
            selectedDate: fromDate,
            onTap: onFromDateTap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: DatePickerField(
            label: 'To Date',
            selectedDate: toDate,
            onTap: onToDateTap,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: _kFilterComponentHeight,
          width: _kFilterComponentHeight,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(4),
            ),
            child: IconButton(
              icon: isLoading 
                ? const SizedBox(
                    width: 18, 
                    height: 18, 
                    child: CircularProgressIndicator(
                      color: Colors.white, 
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.search, color: Colors.white, size: 18),
              onPressed: isLoading ? null : onSearch,
              tooltip: 'Search',
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}

/// A reusable search input field with consistent height
/// Matches the height of date picker fields
class SearchInputField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final double? height;

  const SearchInputField({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? _kFilterComponentHeight,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 12),
          prefixIcon: const Icon(Icons.search, size: 18),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
        ),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

/// Complete reusable date range filter with search
/// Combines date pickers, search input, and rows per page dropdown
class CommonDateRangeFilter extends StatelessWidget {
  final DateTime fromDate;
  final DateTime toDate;
  final VoidCallback onFromDateTap;
  final VoidCallback onToDateTap;
  final VoidCallback onSearch;
  final bool isLoading;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final int? rowsPerPage;
  final ValueChanged<int?>? onRowsPerPageChanged;
  final bool showSearchField;
  final bool showRowsPerPage;

  const CommonDateRangeFilter({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.onFromDateTap,
    required this.onToDateTap,
    required this.onSearch,
    this.isLoading = false,
    this.searchController,
    this.onSearchChanged,
    this.rowsPerPage,
    this.onRowsPerPageChanged,
    this.showSearchField = true,
    this.showRowsPerPage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Date filter row
        DateFilterRow(
          fromDate: fromDate,
          toDate: toDate,
          onFromDateTap: onFromDateTap,
          onToDateTap: onToDateTap,
          onSearch: onSearch,
          isLoading: isLoading,
        ),
        
        // Search and rows per page row
        if (showSearchField || showRowsPerPage) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              // Rows per page dropdown
              if (showRowsPerPage && rowsPerPage != null) ...[
                const Text('Rows: ', style: TextStyle(fontSize: 12)),
                SizedBox(
                  height: _kFilterComponentHeight,
                  child: DropdownButton<int>(
                    value: rowsPerPage,
                    items: [10, 25, 50, 100]
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text('$e', style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                    onChanged: onRowsPerPageChanged,
                    underline: Container(),
                    isDense: true,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              
              // Search field
              if (showSearchField)
                Expanded(
                  child: SearchInputField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
