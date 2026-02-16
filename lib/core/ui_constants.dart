import 'package:flutter/material.dart';

/// UI Constants based on SmartPayV4 design specifications
/// This file contains reusable styling constants for tables, buttons, and colors
/// to ensure consistency across all apply screens (Leave, Permission, Advance, etc.)

class UIConstants {
  // ============================================================================
  // COLOR PALETTE (from SmartPayV4)
  // ============================================================================
  
  /// Primary Red - Used for primary buttons, error messages (SmartPayV4 btn-primary)
  static const Color primaryRed = Color(0xFFDE3C4B);
  
  /// Navy/Black - Used for table headers, primary text
  static const Color navyBlack = Color(0xFF17223B);
  
  /// Table Header Background - Light gray
  static const Color tableHeaderBg = Color(0xFFECECEC);
  
  /// Border Gray - Table header bottom border
  static const Color borderGray = Color(0xFFE5E7EB);
  
  /// Border Gray (Table) - Table outer border
  static const Color tableBorderGray = Color(0xFFD9D9D9);
  
  /// Row Text - Table row text color
  static const Color rowText = Color(0xFF1E1E1E);
  
  /// Background - Page background
  static const Color background = Color(0xFFF8F9FB);
  
  /// Surface White - Cards, table rows
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  
  /// Orange - Update/Edit buttons when modifying
  static const Color updateOrange = Color(0xFFFF9800);
  
  /// Blue Info - View icons
  static const Color infoBlue = Color(0xFF1B84FF);

  // ============================================================================
  // TYPOGRAPHY
  // ============================================================================
  
  /// Font family from SmartPayV4
  static const String fontFamily = 'Calibri';
  
  /// Table header text style
  static const TextStyle tableHeaderStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: navyBlack,
  );
  
  /// Table row text style
  static const TextStyle tableRowStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: rowText,
  );
  
  /// Button text style
  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.white,
    fontWeight: FontWeight.w500,
  );

  // ============================================================================
  // TABLE STYLING
  // ============================================================================
  
  /// Table border radius
  static const double tableBorderRadius = 10.0;
  
  /// Table header padding
  static const double tableHeaderPadding = 10.0;
  
  /// Table decoration with rounded corners and border
  static BoxDecoration tableDecoration = BoxDecoration(
    color: surfaceWhite,
    borderRadius: BorderRadius.circular(tableBorderRadius),
    border: Border.all(color: tableBorderGray, width: 1),
  );
  
  /// DataTable theme matching SmartPayV4
  static DataTableThemeData getDataTableTheme() {
    return DataTableThemeData(
      headingRowColor: MaterialStateProperty.all(tableHeaderBg),
      dataRowColor: MaterialStateProperty.all(surfaceWhite),
      headingTextStyle: tableHeaderStyle,
      dataTextStyle: tableRowStyle,
      columnSpacing: 16,
      horizontalMargin: 12,
      dividerThickness: 1,
    );
  }

  // ============================================================================
  // BUTTON STYLES
  // ============================================================================
  
  /// Primary button style (Submit/Create) - RED from SmartPayV4
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryRed,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    textStyle: buttonTextStyle,
  );
  
  /// Update button style (Modify/Revise) - Orange
  static ButtonStyle updateButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: updateOrange,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    textStyle: buttonTextStyle,
  );
  
  /// Cancel button style - RED from SmartPayV4
  static ButtonStyle cancelButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryRed,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    textStyle: buttonTextStyle,
  );

  // ============================================================================
  // ACTION BUTTON BUILDERS
  // ============================================================================
  
  /// Build View action button (Blue)
  static Widget buildViewButton({required VoidCallback onPressed}) {
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        icon: const Icon(Icons.visibility, color: infoBlue, size: 18),
        tooltip: 'View',
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        iconSize: 18,
      ),
    );
  }
  
  /// Build Edit action button (Orange)
  static Widget buildEditButton({
    VoidCallback? onPressed,
    String tooltip = 'Edit',
  }) {
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        icon: const Icon(Icons.edit, color: updateOrange, size: 18),
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        iconSize: 18,
      ),
    );
  }
  
  /// Build Delete action button (Red)
  static Widget buildDeleteButton({
    VoidCallback? onPressed,
    String tooltip = 'Delete',
  }) {
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        icon: const Icon(Icons.delete, color: primaryRed, size: 18),
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        iconSize: 18,
      ),
    );
  }
  
  /// Build action buttons row (View, Edit, Delete)
  static Widget buildActionButtons({
    required VoidCallback onView,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    String editTooltip = 'Edit',
    String deleteTooltip = 'Delete',
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildViewButton(onPressed: onView),
        const SizedBox(width: 1),
        buildEditButton(onPressed: onEdit, tooltip: editTooltip),
        const SizedBox(width: 1),
        buildDeleteButton(onPressed: onDelete, tooltip: deleteTooltip),
      ],
    );
  }

  // ============================================================================
  // SEARCH & PAGINATION WIDGETS
  // ============================================================================
  
  /// Build search text field
  static Widget buildSearchField({
    required TextEditingController controller,
    String hintText = 'Search...',
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: borderGray),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: InputBorder.none,
          suffixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
        ),
      ),
    );
  }
  
  /// Build rows per page dropdown
  static Widget buildRowsPerPageDropdown({
    required int rowsPerPage,
    required Function(int?) onChanged,
  }) {
    return Row(
      children: [
        const Text(
          'Row Per Page',
          style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: borderGray),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Text('$rowsPerPage', style: const TextStyle(fontSize: 12)),
              const Icon(Icons.keyboard_arrow_down, size: 16, color: infoBlue),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Build pagination footer
  static Widget buildPaginationFooter({
    required int totalCount,
    int currentPage = 1,
    int rowsPerPage = 10,
  }) {
    final int startIndex = totalCount > 0 ? ((currentPage - 1) * rowsPerPage) + 1 : 0;
    final int endIndex = (currentPage * rowsPerPage) > totalCount ? totalCount : (currentPage * rowsPerPage);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $startIndex to $endIndex of $totalCount entries',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const Row(
            children: [
              Icon(Icons.chevron_left, color: Colors.grey),
              SizedBox(width: 16),
              Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Build table actions row (search + rows per page)
  static Widget buildTableActionsRow({
    required TextEditingController searchController,
    required int rowsPerPage,
    String searchHint = 'Search...',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildRowsPerPageDropdown(
          rowsPerPage: rowsPerPage,
          onChanged: (value) {}, // Placeholder - implement in actual usage
        ),
        const SizedBox(height: 12),
        buildSearchField(
          controller: searchController,
          hintText: searchHint,
        ),
      ],
    );
  }

  // ============================================================================
  // MODAL / DIALOG BUILDERS
  // ============================================================================

  /// Build a standard detail item row for modals
  static Widget buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700, // Bold label
                color: navyBlack,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontFamily: fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B5563), // Text gray 600
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show a premium view modal for details
  static void showViewModal({
    required BuildContext context,
    required String title,
    List<Widget>? children,
    Widget? body,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modal Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                color: primaryRed, // Primary Red Header
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              
              // Modal Body
              Flexible(
                child: body ?? SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: children ?? [],
                  ),
                ),
              ),
              
              // Modal Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                  color: Color(0xFFF9FAFB),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ============================================================================
  // SNACKBAR HELPERS
  // ============================================================================

  /// Show a success SnackBar with white text and black background
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show an error SnackBar with white text and black background (can customize color if needed, but keeping black as requested)
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black, // Still using black as per user requirement but could be primaryRed
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
