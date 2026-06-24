import 'package:alarm/alarm.dart';
import '../models/alarm_model.dart';

class AlarmSchedulerService {
  static Future<void> init() async {
    await Alarm.init();
  }

  /// Next fire time using hour/minute from [model] and optional repeat days.
  /// [after] defaults to now; the returned time is always strictly after [after].
  static DateTime computeNextAlarmTime(
    AlarmModel model, {
    DateTime? after,
  }) {
    final now = after ?? DateTime.now();
    final hour = model.scheduledTime.hour;
    final minute = model.scheduledTime.minute;
    final repeats = model.repeatDays.any((d) => d);

    if (!repeats) {
      var candidate = DateTime(now.year, now.month, now.day, hour, minute);
      if (candidate.isAfter(now)) return candidate;
      return candidate.add(const Duration(days: 1));
    }

    final today = DateTime(now.year, now.month, now.day);
    for (var offset = 0; offset < 8; offset++) {
      final day = today.add(Duration(days: offset));
      final dayIndex = day.weekday % 7;
      if (!model.repeatDays[dayIndex]) continue;
      final candidate = DateTime(day.year, day.month, day.day, hour, minute);
      if (candidate.isAfter(now)) return candidate;
    }

    final nextDay = today.add(const Duration(days: 1));
    return DateTime(nextDay.year, nextDay.month, nextDay.day, hour, minute);
  }

  static Future<void> scheduleAlarm(AlarmModel model) async {
    if (!model.isEnabled) return;

    final alarmTime = computeNextAlarmTime(model);

    final settings = AlarmSettings(
      id: model.id,
      dateTime: alarmTime,
      assetAudioPath: 'assets/sounds/alert-alarm.wav',
      loopAudio: true,
      vibrate: model.vibrate,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      notificationSettings: NotificationSettings(
        title: model.label.isEmpty ? 'Wake Up! 🔔' : model.label,
        body: 'Find the object to stop the alarm',
        stopButton: 'Stop',
        icon: 'notification_icon',
      ),
      volumeSettings: const VolumeSettings.fixed(),
    );

    await Alarm.set(alarmSettings: settings);
  }

  /// Re-register enabled alarms after app launch or device reboot.
  static Future<void> syncAllAlarms(List<AlarmModel> alarms) async {
    for (final alarm in alarms) {
      if (await isRinging(alarm.id)) continue;
      await cancelAlarm(alarm.id);
      if (alarm.isEnabled) {
        await scheduleAlarm(alarm);
      }
    }
  }

  /// Stop the current ring and schedule the next occurrence for repeating alarms.
  static Future<void> handleAlarmDismissed(AlarmModel model) async {
    await cancelAlarm(model.id);
    if (model.isEnabled && model.repeatDays.any((d) => d)) {
      await scheduleAlarm(model);
    }
  }

  static Future<void> cancelAlarm(int id) async {
    await Alarm.stop(id);
  }

  static Future<void> cancelAll() async {
    await Alarm.stopAll();
  }

  static Future<bool> isRinging(int id) => Alarm.isRinging(id);
}
