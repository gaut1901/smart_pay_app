import 'package:flutter/material.dart';
import 'package:smartpay_flutter/core/ui_constants.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../data/models/shift_model.dart';
import '../../data/services/shift_service.dart';

class ShiftScreen extends StatefulWidget {
  const ShiftScreen({super.key});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  final ShiftService _shiftService = ShiftService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, ShiftRecord> _shifts = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadShifts();
  }

  Future<void> _loadShifts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _shiftService.getShiftSchedule();
      final Map<DateTime, ShiftRecord> shiftMap = {};
      
      for (var shift in response.shifts) {
        try {
          // Format is dd-MM-yyyy
          final parts = shift.date.split('-');
          if (parts.length == 3) {
            final date = DateTime(
              int.parse(parts[2]), // year
              int.parse(parts[1]), // month
              int.parse(parts[0]), // day
            );
            // Normalize to midnight for comparison
            final normalizedDate = DateTime(date.year, date.month, date.day);
            shiftMap[normalizedDate] = shift;
          }
        } catch (e) {
          // Skip invalid dates
        }
      }

      setState(() {
        _shifts = shiftMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<ShiftRecord> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    if (_shifts.containsKey(normalizedDay)) {
      return [_shifts[normalizedDay]!];
    }
    return [];
  }

  Color _hexToColor(String hex) {
    try {
      if (hex.startsWith('#')) {
        hex = hex.substring(1);
      }
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Shift Schedule', style: UIConstants.pageTitleStyle),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShifts,
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
                      ElevatedButton(
                        onPressed: _loadShifts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildCalendar(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _buildShiftDetails(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: AppStyles.modernCardDecoration,
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          }
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        eventLoader: _getEventsForDay,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: UIConstants.fontSizePageTitle, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isNotEmpty) {
              final shift = events.first as ShiftRecord;
              return Positioned(
                bottom: 1,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hexToColor(shift.colorCode),
                  ),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildShiftDetails() {
    final selectedShift = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.modernCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedDay != null ? DateFormat('EEEE, MMM d, yyyy').format(_selectedDay!) : 'Select a date',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: UIConstants.fontSizeSectionHeader, color: AppColors.primary),
              ),
              if (selectedShift.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _hexToColor(selectedShift.first.colorCode),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Shift Assigned',
                    style: TextStyle(color: Colors.white, fontSize: UIConstants.fontSizeSmall, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const Divider(height: 30),
          if (selectedShift.isNotEmpty)
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _hexToColor(selectedShift.first.colorCode).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.work_history,
                    color: _hexToColor(selectedShift.first.colorCode),
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedShift.first.shiftName,
                      style: TextStyle(fontSize: UIConstants.fontSizePageTitle, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    Text(
                      'Shift Timing',
                      style: TextStyle(color: AppColors.textGray, fontSize: UIConstants.fontSizeBody),
                    ),
                  ],
                ),
              ],
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 40, color: AppColors.textGray),
                    SizedBox(height: 10),
                    Text('No shift assigned for this date', style: TextStyle(color: AppColors.textGray)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
