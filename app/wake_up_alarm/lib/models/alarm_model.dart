// lib/models/alarm_model.dart
import 'dart:convert';

class AlarmModel {
  final int id;
  final String label;
  final DateTime scheduledTime;
  final bool isEnabled;
  final List<bool> repeatDays; // Sun=0 ... Sat=6
  final bool vibrate;
  final String sound;

  const AlarmModel({
    required this.id,
    required this.label,
    required this.scheduledTime,
    this.isEnabled = true,
    List<bool>? repeatDays,
    this.vibrate = true,
    this.sound = 'default',
  }) : repeatDays = repeatDays ??
            const [false, false, false, false, false, false, false];

  AlarmModel copyWith({
    int? id,
    String? label,
    DateTime? scheduledTime,
    bool? isEnabled,
    List<bool>? repeatDays,
    bool? vibrate,
    String? sound,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      label: label ?? this.label,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? this.repeatDays,
      vibrate: vibrate ?? this.vibrate,
      sound: sound ?? this.sound,
    );
  }

  String get timeString {
    final h = scheduledTime.hour;
    final m = scheduledTime.minute.toString().padLeft(2, '0');
    final isPm = h >= 12;
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m ${isPm ? 'PM' : 'AM'}';
  }

  String get repeatString {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final active = <String>[];
    for (int i = 0; i < repeatDays.length; i++) {
      if (repeatDays[i]) active.add(days[i]);
    }
    if (active.isEmpty) return 'Once';
    if (active.length == 7) return 'Every day';
    if (active.length == 5 &&
        !repeatDays[0] &&
        !repeatDays[6]) return 'Weekdays';
    if (active.length == 2 && repeatDays[0] && repeatDays[6]) return 'Weekends';
    return active.join(', ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'scheduledTime': scheduledTime.toIso8601String(),
        'isEnabled': isEnabled,
        'repeatDays': repeatDays,
        'vibrate': vibrate,
        'sound': sound,
      };

  factory AlarmModel.fromJson(Map<String, dynamic> json) => AlarmModel(
        id: json['id'],
        label: json['label'],
        scheduledTime: DateTime.parse(json['scheduledTime']),
        isEnabled: json['isEnabled'] ?? true,
        repeatDays: List<bool>.from(json['repeatDays']),
        vibrate: json['vibrate'] ?? true,
        sound: json['sound'] ?? 'default',
      );

  String toJsonString() => jsonEncode(toJson());
  factory AlarmModel.fromJsonString(String s) =>
      AlarmModel.fromJson(jsonDecode(s));
}
