// lib/main.dart
import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/alarm_scheduler_service.dart';
import 'screens/home_screen.dart';
import 'screens/ringing_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await AlarmSchedulerService.init();

  runApp(const WakeUpAlarmApp());
}

class WakeUpAlarmApp extends StatefulWidget {
  const WakeUpAlarmApp({super.key});

  @override
  State<WakeUpAlarmApp> createState() => _WakeUpAlarmAppState();
}

class _WakeUpAlarmAppState extends State<WakeUpAlarmApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AlarmSet>? _ringingSubscription;

  @override
  void initState() {
    super.initState();
    _listenToAlarmRings();
    _checkIfAlarmAlreadyRinging();
  }

  @override
  void dispose() {
    _ringingSubscription?.cancel();
    super.dispose();
  }

  void _listenToAlarmRings() {
    _ringingSubscription = Alarm.ringing.listen((alarmSet) {
      if (alarmSet.alarms.isEmpty) return;
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => RingingScreen(alarmId: alarmSet.alarms.first.id),
        ),
        (route) => false,
      );
    });
  }

  Future<void> _checkIfAlarmAlreadyRinging() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final ringing = Alarm.ringing.value;
    if (ringing.alarms.isNotEmpty && mounted) {
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => RingingScreen(alarmId: ringing.alarms.first.id),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wake Up!',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      navigatorKey: _navigatorKey,
      home: const HomeScreen(),
    );
  }
}
