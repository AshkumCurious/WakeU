import 'package:alarm/alarm.dart';
import '../models/alarm_model.dart';

class AlarmSchedulerService {
  static Future<void> init() async {
    await Alarm.init();
  }

  static Future<void> scheduleAlarm(AlarmModel model) async {
    if (!model.isEnabled) return;

    DateTime alarmTime = model.scheduledTime;
    final now = DateTime.now();

    // If time has passed today, schedule for tomorrow (or next matching day)
    if (alarmTime.isBefore(now)) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }

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
        volumeSettings: const VolumeSettings.fixed());

    await Alarm.set(alarmSettings: settings);
  }

  static Future<void> cancelAlarm(int id) async {
    await Alarm.stop(id);
  }

  static Future<void> cancelAll() async {
    await Alarm.stopAll();
  }

  static bool isRinging(int id) {
    return Alarm.getAlarm(id) != null;
  }

  static Stream<AlarmSettings> get alarmStream => Alarm.ringStream.stream;
}
