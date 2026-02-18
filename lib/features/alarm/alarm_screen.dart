import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onboarding_alarm_app/common_widgets/primary_button.dart';
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

  @override
  Widget build(BuildContext context) {
    final AlarmProvider alarmProvider = context.watch<AlarmProvider>();
    final DateFormat dateFormat = DateFormat('EEE, MMM d, yyyy');
    final DateFormat timeFormat = DateFormat('hh:mm a');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.alarmTitle),
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickDate,
                                  icon: const Icon(
                                    Icons.calendar_month,
                                    color: AppColors.primary,
                                  ),
                                  label: Text(
                                    _selectedDate == null
                                        ? 'Select Date'
                                        : dateFormat.format(_selectedDate!),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickTime,
                                  icon: const Icon(
                                    Icons.access_time,
                                    color: AppColors.primary,
                                  ),
                                  label: Text(
                                    _selectedTime == null
                                        ? 'Select Time'
                                        : _selectedTime!.format(context),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: AppStrings.addAlarm,
                            onPressed: _saveAlarm,
                            icon: Icons.alarm_add,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Scheduled Alarms',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (alarmProvider.alarms.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text(
                          AppStrings.noAlarms,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    else
                      ...alarmProvider.alarms.map(
                        (AlarmModel alarm) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.primaryLight,
                                child: Icon(
                                  Icons.alarm,
                                  color: AppColors.surface,
                                ),
                              ),
                              title: Text(
                                timeFormat.format(alarm.scheduledAt),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                dateFormat.format(alarm.scheduledAt),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              trailing: IconButton(
                                onPressed: () {
                                  context.read<AlarmProvider>().removeAlarm(
                                    alarm.id,
                                  );
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
