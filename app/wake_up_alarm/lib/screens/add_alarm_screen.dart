// lib/screens/add_alarm_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/alarm_model.dart';
import '../services/alarm_storage_service.dart';
import '../utils/app_theme.dart';

class AddAlarmScreen extends StatefulWidget {
  final AlarmModel? existing;
  const AddAlarmScreen({super.key, this.existing});

  @override
  State<AddAlarmScreen> createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends State<AddAlarmScreen> {
  late DateTime _selectedTime;
  late List<bool> _repeatDays;
  late TextEditingController _labelController;
  late bool _vibrate;
  final _storage = AlarmStorageService();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedTime = widget.existing?.scheduledTime ??
        DateTime(now.year, now.month, now.day, now.hour, now.minute);
    _repeatDays =
        List.from(widget.existing?.repeatDays ?? List.filled(7, false));
    _labelController =
        TextEditingController(text: widget.existing?.label ?? '');
    _vibrate = widget.existing?.vibrate ?? true;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _save() {
    final now = DateTime.now();
    final normalized = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final alarm = AlarmModel(
      id: widget.existing?.id ?? _storage.generateId(),
      label: _labelController.text.trim(),
      scheduledTime: normalized,
      isEnabled: widget.existing?.isEnabled ?? true,
      repeatDays: _repeatDays,
      vibrate: _vibrate,
    );
    Navigator.pop(context, alarm);
  }

  void _applyRepeatPreset(List<bool> days) {
    setState(() => _repeatDays = List.from(days));
  }

  String get _previewTime {
    final h = _selectedTime.hour;
    final m = _selectedTime.minute.toString().padLeft(2, '0');
    final isPm = h >= 12;
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m ${isPm ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        leadingWidth: 80,
        title: Text(isEditing ? 'Edit alarm' : 'New alarm'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      _previewTime,
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w200,
                        color: AppTheme.textPrimary,
                        letterSpacing: -2,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTimePicker(),
                  const SizedBox(height: 36),
                  _sectionLabel('Label'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _labelController,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Morning, Work, …',
                    ),
                  ),
                  const SizedBox(height: 28),
                  _sectionLabel('Repeat'),
                  const SizedBox(height: 12),
                  _buildRepeatPresets(),
                  const SizedBox(height: 16),
                  _buildDayPicker(),
                  const SizedBox(height: 28),
                  _buildToggleRow(
                    'Vibrate',
                    _vibrate,
                    (v) => setState(() => _vibrate = v),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(isEditing ? 'Save changes' : 'Set alarm'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: AppTheme.textMuted,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildTimePicker() {
    return SizedBox(
      height: 180,
      child: CupertinoTheme(
        data: const CupertinoThemeData(
          brightness: Brightness.dark,
          textTheme: CupertinoTextThemeData(
            dateTimePickerTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          initialDateTime: _selectedTime,
          onDateTimeChanged: (dt) => setState(() => _selectedTime = dt),
          use24hFormat: false,
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildRepeatPresets() {
    const presets = <String, List<bool>>{
      'Once': [false, false, false, false, false, false, false],
      'Daily': [true, true, true, true, true, true, true],
      'Weekdays': [false, true, true, true, true, true, false],
      'Weekends': [true, false, false, false, false, false, true],
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.entries.map((entry) {
        final isActive = _repeatDays.toString() == entry.value.toString();
        return GestureDetector(
          onTap: () => _applyRepeatPreset(entry.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.surfaceElevated : AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? AppTheme.accentSecondary.withValues(alpha: 0.5)
                    : AppTheme.border.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
            child: Text(
              entry.key,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayPicker() {
    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final active = _repeatDays[i];
        return GestureDetector(
          onTap: () => setState(() => _repeatDays[i] = !_repeatDays[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: active ? AppTheme.textPrimary : AppTheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: active
                    ? AppTheme.textPrimary
                    : AppTheme.border.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
            child: Center(
              child: Text(
                dayLabels[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: active ? AppTheme.background : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildToggleRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          Switch(value: value, onChanged: onChanged),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
