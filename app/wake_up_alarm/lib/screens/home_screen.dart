// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alarm_model.dart';
import '../services/alarm_storage_service.dart';
import '../services/alarm_scheduler_service.dart';
import '../utils/app_theme.dart';
import '../widgets/glowing_button.dart';
import 'add_alarm_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = AlarmStorageService();
  List<AlarmModel> _alarms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    final alarms = await _storage.loadAlarms();
    await AlarmSchedulerService.syncAllAlarms(alarms);
    if (!mounted) return;
    setState(() {
      _alarms = alarms..sort((a, b) {
        final aMin = a.scheduledTime.hour * 60 + a.scheduledTime.minute;
        final bMin = b.scheduledTime.hour * 60 + b.scheduledTime.minute;
        return aMin.compareTo(bMin);
      });
      _loading = false;
    });
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  AlarmModel? get _nextEnabledAlarm {
    final enabled = _alarms.where((a) => a.isEnabled).toList();
    if (enabled.isEmpty) return null;
    final now = DateTime.now();
    AlarmModel? closest;
    Duration? closestDiff;
    for (final alarm in enabled) {
      final next = AlarmSchedulerService.computeNextAlarmTime(alarm, after: now);
      final diff = next.difference(now);
      if (closestDiff == null || diff < closestDiff) {
        closest = alarm;
        closestDiff = diff;
      }
    }
    return closest;
  }

  Future<void> _toggleAlarm(AlarmModel alarm) async {
    final updated = alarm.copyWith(isEnabled: !alarm.isEnabled);
    await _storage.updateAlarm(updated);
    if (updated.isEnabled) {
      await AlarmSchedulerService.scheduleAlarm(updated);
    } else {
      await AlarmSchedulerService.cancelAlarm(updated.id);
    }
    await _loadAlarms();
  }

  Future<void> _deleteAlarm(AlarmModel alarm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete this alarm?'),
        content: Text(
          alarm.label.isEmpty
              ? alarm.timeString
              : '${alarm.timeString} · ${alarm.label}',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await AlarmSchedulerService.cancelAlarm(alarm.id);
    await _storage.deleteAlarm(alarm.id);
    await _loadAlarms();
  }

  Future<void> _openAlarmEditor([AlarmModel? existing]) async {
    final result = await Navigator.push<AlarmModel>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => AddAlarmScreen(existing: existing),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
    if (result == null) return;

    if (existing != null) {
      await _storage.updateAlarm(result);
    } else {
      await _storage.addAlarm(result);
    }
    await AlarmSchedulerService.cancelAlarm(result.id);
    if (result.isEnabled) {
      await AlarmSchedulerService.scheduleAlarm(result);
    }
    await _loadAlarms();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE, MMMM d').format(DateTime.now());
    final nextAlarm = _nextEnabledAlarm;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.accentSecondary,
                  strokeWidth: 2,
                ),
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(dateLabel, nextAlarm)),
                  if (_alarms.isEmpty)
                    SliverFillRemaining(child: _buildEmptyState())
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final alarm = _alarms[i];
                          final isNext =
                              nextAlarm?.id == alarm.id && alarm.isEnabled;
                          return AlarmCard(
                            timeString: alarm.timeString,
                            label: alarm.label,
                            repeatString: alarm.repeatString,
                            isEnabled: alarm.isEnabled,
                            isNext: isNext,
                            onToggle: () => _toggleAlarm(alarm),
                            onDelete: () => _deleteAlarm(alarm),
                            onTap: () => _openAlarmEditor(alarm),
                          );
                        },
                        childCount: _alarms.length,
                      ),
                    ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAlarmEditor(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildHeader(String dateLabel, AlarmModel? nextAlarm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateLabel,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          if (nextAlarm != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  const Icon(
                    Icons.alarm_outlined,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Next alarm',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${nextAlarm.timeString} · ${nextAlarm.label.isEmpty ? 'Alarm' : nextAlarm.label}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_alarms.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text(
              'Your alarms',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.alarm_outlined,
              size: 48,
              color: AppTheme.textMuted.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 20),
            const Text(
              'No alarms yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap + to add one. When it rings, you\'ll find an object to turn it off.',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
