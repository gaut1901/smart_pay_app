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
  Map<DateTime, List<ShiftRecord>> _shifts = {};
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
      final Map<DateTime, List<ShiftRecord>> shiftMap = {};
      
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
            
            if (!shiftMap.containsKey(normalizedDate)) {
              shiftMap[normalizedDate] = [];
            }
            shiftMap[normalizedDate]!.add(shift);
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
    return _shifts[normalizedDay] ?? [];
  }

  Color _hexToColor(String hex) {
    final colorMap = {
      'BROWN': Colors.brown,
      'RED': Colors.red,
      'BLUE': Colors.blue,
      'GREEN': Colors.green,
      'YELLOW': Colors.yellow,
      'ORANGE': Colors.orange,
      'PURPLE': Colors.purple,
      'PINK': Colors.pink,
      'GREY': Colors.grey,
      'BLACK': Colors.black,
      'WHITE': Colors.white,
      'CYAN': Colors.cyan,
      'TEAL': Colors.teal,
      'INDIGO': Colors.indigo,
      'LIME': Colors.lime,
      'AMBER': Colors.amber,
    };

    String upperHex = hex.toUpperCase().trim();
    if (colorMap.containsKey(upperHex)) {
      return colorMap[upperHex]!;
    }

    try {
      if (hex.startsWith('#')) {
        hex = hex.substring(1);
      }
      if (hex.length == 3) {
        hex = hex.split('').map((e) => e + e).join('');
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
          defaultBuilder: (context, day, focusedDay) {
            return _buildCalendarCell(day, isToday: false, isSelected: false);
          },
          todayBuilder: (context, day, focusedDay) {
            return _buildCalendarCell(day, isToday: true, isSelected: false);
          },
          selectedBuilder: (context, day, focusedDay) {
            return _buildCalendarCell(day, isToday: false, isSelected: true);
          },
          markerBuilder: (context, date, events) {
            if (events != null && events.length > 0) {
              final shifts = events.cast<ShiftRecord>();
              // Use the first shift's color for all markers on this day for consistency
              final dayColor = _hexToColor(shifts[0].colorCode);
              return Positioned(
                bottom: 2,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...shifts.take(3).map((shift) {
                      return Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 1.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dayColor,
                        ),
                      );
                    }),
                    if (shifts.length > 3)
                      Text(
                        '+',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: dayColor),
                      ),
                  ],
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildCalendarCell(DateTime day, {bool isToday = false, bool isSelected = false}) {
    if (isSelected) {
      return Container(
        margin: const EdgeInsets.all(4.0),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Text(
          '${day.day}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (isToday) {
      return Container(
        margin: const EdgeInsets.all(4.0),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        child: Text(
          '${day.day}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(4.0),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: const TextStyle(color: AppColors.textDark),
      ),
    );
  }

  Widget _buildShiftDetails() {
    final selectedShifts = _selectedDay != null ? _getEventsForDay(_selectedDay!) : <ShiftRecord>[];

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
            ],
          ),
          const Divider(height: 30),
          if (selectedShifts.length > 0)
            Expanded(
              child: ListView.separated(
                itemCount: selectedShifts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final shift = selectedShifts[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _hexToColor(shift.colorCode).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _hexToColor(shift.colorCode).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _hexToColor(shift.colorCode).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.work_history,
                            color: _hexToColor(shift.colorCode),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shift.shiftName,
                                style: TextStyle(
                                  fontSize: UIConstants.fontSizeSectionHeader, 
                                  fontWeight: FontWeight.bold, 
                                  color: _hexToColor(shift.colorCode),
                                ),
                              ),
                              Text(
                                'Shift Assigned',
                                style: TextStyle(color: AppColors.textGray.withValues(alpha: 0.7), fontSize: UIConstants.fontSizeSmall),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: _hexToColor(shift.colorCode).withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
