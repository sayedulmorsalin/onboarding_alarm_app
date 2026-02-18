import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onboarding_alarm_app/constants/app_colors.dart';
import 'package:onboarding_alarm_app/constants/app_strings.dart';
import 'package:onboarding_alarm_app/features/alarm/alarm_model.dart';
import 'package:onboarding_alarm_app/features/alarm/alarm_service.dart';
import 'package:onboarding_alarm_app/helpers/database_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class AlarmProvider extends ChangeNotifier {
  AlarmProvider(this._alarmService, this._dbHelper) {
    _loadAlarms();
  }

  final AlarmService _alarmService;
  final DatabaseHelper _dbHelper;
  final List<AlarmModel> _alarms = <AlarmModel>[];

  List<AlarmModel> get alarms => List<AlarmModel>.unmodifiable(_alarms);

  Future<void> _loadAlarms() async {
    final List<AlarmModel> alarms = await _dbHelper.getAlarms();
    _alarms.clear();
    _alarms.addAll(alarms);
    notifyListeners();
  }

  Future<void> addAlarm(DateTime dateTime) async {
    if (!dateTime.isAfter(DateTime.now())) {
      throw Exception(AppStrings.pastAlarmError);
    }

    final a = await Permission.notification.isGranted;
    final b = await Permission.scheduleExactAlarm.isGranted;

    if (!a || !b) {
      throw Exception('Please grant notification and exact alarm permissions.');
    }

    final int id = DateTime.now().microsecondsSinceEpoch % 2147483647;

    final AlarmModel alarm = AlarmModel(id: id, scheduledAt: dateTime);

    await _alarmService.scheduleAlarm(
      id: alarm.id,
      scheduledDateTime: alarm.scheduledAt,
      title: alarm.title,
      body: DateFormat('EEE, MMM d - hh:mm a').format(alarm.scheduledAt),
    );

    await _dbHelper.insertAlarm(alarm);
    await _loadAlarms();
  }

  Future<void> removeAlarm(int id) async {
    await _alarmService.cancelAlarm(id);
    await _dbHelper.deleteAlarm(id);
    await _loadAlarms();
  }
}

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final Set<int> _disabledAlarmIds = <int>{};

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay now = TimeOfDay.now();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? now,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  DateTime? _combinedDateTime() {
    if (_selectedDate == null || _selectedTime == null) {
      return null;
    }

    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }

  Future<void> _saveAlarm() async {
    final DateTime? dateTime = _combinedDateTime();

    if (dateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick both date and time.')),
      );
      return;
    }

    try {
      await context.read<AlarmProvider>().addAlarm(dateTime);

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedDate = null;
        _selectedTime = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarm scheduled successfully.')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _onAddAlarmPressed() async {
    await _pickDate();
    if (!mounted || _selectedDate == null) {
      return;
    }

    await _pickTime();
    if (!mounted || _selectedTime == null) {
      return;
    }

    await _saveAlarm();
  }

  @override
  Widget build(BuildContext context) {
    final AlarmProvider alarmProvider = context.watch<AlarmProvider>();
    final DateFormat dateFormat = DateFormat('EEE d MMM yyyy');
    final DateFormat timeFormat = DateFormat('h:mm a');

    return Scaffold(
      backgroundColor: const Color(0xFF09002F),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A013C), Color(0xFF0A2C72)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Selected Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28 / 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0x6A679233),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFFA7A9C4),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Add your location',
                        style: TextStyle(
                          color: Color(0xFFA7A9C4),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Alarms',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28 / 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: alarmProvider.alarms.isEmpty
                      ? const SizedBox.shrink()
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: alarmProvider.alarms.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (BuildContext context, int index) {
                            final AlarmModel alarm = alarmProvider.alarms[index];
                            final bool isEnabled = !_disabledAlarmIds.contains(
                              alarm.id,
                            );
                            return Container(
                              height: 56,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x6A679233),
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    timeFormat
                                        .format(alarm.scheduledAt)
                                        .toLowerCase(),
                                    style: const TextStyle(
                                      color: Color(0xFFE6E7F5),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    dateFormat.format(alarm.scheduledAt),
                                    style: const TextStyle(
                                      color: Color(0xFF9EA2C4),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Transform.scale(
                                    scale: 0.82,
                                    child: Switch(
                                      value: isEnabled,
                                      onChanged: (bool value) {
                                        setState(() {
                                          if (value) {
                                            _disabledAlarmIds.remove(alarm.id);
                                          } else {
                                            _disabledAlarmIds.add(alarm.id);
                                          }
                                        });
                                      },
                                      activeTrackColor: const Color(0xFF7A58FF),
                                      inactiveTrackColor: const Color(
                                        0xFF101437,
                                      ),
                                      activeThumbColor: Colors.white,
                                      inactiveThumbColor: Colors.white,
                                      trackOutlineColor:
                                          const WidgetStatePropertyAll(
                                            Colors.transparent,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 14),
                    child: GestureDetector(
                      onTap: _onAddAlarmPressed,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF4C00FF), Color(0xFF7817FF)],
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Container(
                    width: 74,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
