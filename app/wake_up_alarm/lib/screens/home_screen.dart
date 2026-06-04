// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _storage = AlarmStorageService();
  List<AlarmModel> _alarms = [];
  bool _loading = true;
  late AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadAlarms();
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    super.dispose();
  }

  Future<void> _loadAlarms() async {
    final alarms = await _storage.loadAlarms();
    setState(() {
      _alarms = alarms..sort((a, b) {
        final aMin = a.scheduledTime.hour * 60 + a.scheduledTime.minute;
        final bMin = b.scheduledTime.hour * 60 + b.scheduledTime.minute;
        return aMin.compareTo(bMin);
      });
      _loading = false;
    });
    _fabAnim.forward();
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
    await AlarmSchedulerService.cancelAlarm(alarm.id);
    await _storage.deleteAlarm(alarm.id);
    await _loadAlarms();
  }

  void _openAddAlarm() async {
    final result = await Navigator.push<AlarmModel>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const AddAlarmScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
    if (result != null) {
      await _storage.addAlarm(result);
      await AlarmSchedulerService.scheduleAlarm(result);
      await _loadAlarms();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),
            )
          else if (_alarms.isEmpty)
            _buildEmptyState()
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final alarm = _alarms[i];
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 300 + (i * 80)),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - v)),
                        child: child,
                      ),
                    ),
                    child: AlarmCard(
                      timeString: alarm.timeString,
                      label: alarm.label,
                      repeatString: alarm.repeatString,
                      isEnabled: alarm.isEnabled,
                      onToggle: () => _toggleAlarm(alarm),
                      onDelete: () => _deleteAlarm(alarm),
                      onTap: () => _openAddAlarm(),
                    ),
                  );
                },
                childCount: _alarms.length,
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabAnim, curve: Curves.elasticOut),
        child: GlowingButton(
          label: 'NEW ALARM',
          icon: Icons.add,
          onTap: _openAddAlarm,
          color: AppTheme.accent,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      backgroundColor: AppTheme.background,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'WAKE UP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Alarms',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -1.5,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.alarm_off_rounded,
                color: AppTheme.accent,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No alarms set',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the button below to add your first alarm',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
