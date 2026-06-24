import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm_model.dart';

class AlarmStorageService {
  static const _key = 'alarms_v1';
  static const _uuid = Uuid();

  Future<List<AlarmModel>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((s) => AlarmModel.fromJsonString(s)).toList();
  }

  Future<AlarmModel?> getAlarmById(int id) async {
    final alarms = await loadAlarms();
    for (final alarm in alarms) {
      if (alarm.id == id) return alarm;
    }
    return null;
  }

  Future<void> saveAlarms(List<AlarmModel> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      alarms.map((a) => a.toJsonString()).toList(),
    );
  }

  Future<AlarmModel> addAlarm(AlarmModel alarm) async {
    final alarms = await loadAlarms();
    alarms.add(alarm);
    await saveAlarms(alarms);
    return alarm;
  }

  Future<void> updateAlarm(AlarmModel updated) async {
    final alarms = await loadAlarms();
    final idx = alarms.indexWhere((a) => a.id == updated.id);
    if (idx >= 0) alarms[idx] = updated;
    await saveAlarms(alarms);
  }

  Future<void> deleteAlarm(int id) async {
    final alarms = await loadAlarms();
    alarms.removeWhere((a) => a.id == id);
    await saveAlarms(alarms);
  }

  int generateId() {
    final id = _uuid.v4().hashCode & 0x7FFFFFFF;
    return id == 0 ? 1 : id;
  }
}
