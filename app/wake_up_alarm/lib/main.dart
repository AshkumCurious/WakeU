// lib/main.dart
import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/alarm_scheduler_service.dart';
import 'screens/home_screen.dart';
import 'screens/ringing_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
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

  @override
  void initState() {
    super.initState();
    _listenToAlarmRings();
    _checkIfAlarmAlreadyRinging();
  }

  void _listenToAlarmRings() {
    AlarmSchedulerService.alarmStream.listen((alarmSettings) {
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => RingingScreen(alarmId: alarmSettings.id),
        ),
        (route) => false,
      );
    });
  }

  Future<void> _checkIfAlarmAlreadyRinging() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final alarms = await Alarm.getAlarms();
    final ringingAlarms =
        alarms.where((a) => Alarm.getAlarm(a.id) != null).toList();

    if (ringingAlarms.isNotEmpty && mounted) {
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => RingingScreen(alarmId: ringingAlarms.first.id),
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
