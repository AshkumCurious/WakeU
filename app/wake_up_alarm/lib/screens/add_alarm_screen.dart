// lib/screens/add_alarm_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/alarm_model.dart';
import '../services/alarm_storage_service.dart';
import '../utils/app_theme.dart';
import '../widgets/glowing_button.dart';

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
    _repeatDays = List.from(
        widget.existing?.repeatDays ?? List.filled(7, false));
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
    final alarm = AlarmModel(
      id: widget.existing?.id ?? _storage.generateId(),
      label: _labelController.text.trim(),
      scheduledTime: _selectedTime,
      isEnabled: true,
      repeatDays: _repeatDays,
      vibrate: _vibrate,
    );
    Navigator.pop(context, alarm);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.existing != null ? 'Edit Alarm' : 'New Alarm'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'SAVE',
              style: TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimePicker(),
            const SizedBox(height: 32),
            _buildLabelField(),
            const SizedBox(height: 24),
            _buildRepeatDays(),
            const SizedBox(height: 24),
            _buildToggleRow(
              'Vibrate',
              Icons.vibration_rounded,
              _vibrate,
              (v) => setState(() => _vibrate = v),
            ),
            const SizedBox(height: 48),
            Center(
              child: GlowingButton(
                label: 'SAVE ALARM',
                icon: Icons.check_rounded,
                onTap: _save,
                width: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        initialDateTime: _selectedTime,
        onDateTimeChanged: (dt) =>
            setState(() => _selectedTime = dt),
        use24hFormat: false,
        backgroundColor: Colors.transparent,
      ),
    );
  }

  Widget _buildLabelField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LABEL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _labelController,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'e.g. Morning alarm',
            hintStyle:
                const TextStyle(color: AppTheme.textMuted, fontSize: 16),
            filled: true,
            fillColor: AppTheme.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.accent, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildRepeatDays() {
    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'REPEAT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final active = _repeatDays[i];
            return GestureDetector(
              onTap: () =>
                  setState(() => _repeatDays[i] = !_repeatDays[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      active ? AppTheme.accent : AppTheme.surfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active ? AppTheme.accent : AppTheme.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    dayLabels[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: active
                          ? AppTheme.background
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildToggleRow(
    String label,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 15)),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.accent,
            activeTrackColor: AppTheme.accent.withOpacity(0.2),
            inactiveThumbColor: AppTheme.textMuted,
            inactiveTrackColor: AppTheme.border,
          ),
        ],
      ),
    );
  }
}
