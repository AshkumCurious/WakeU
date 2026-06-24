// lib/services/item_selector_service.dart
import 'dart:math';
import '../utils/app_theme.dart';

class SelectedItem {
  final String name;
  final String emoji;
  final String mlLabel;
  final List<String> altLabels;

  const SelectedItem({
    required this.name,
    required this.emoji,
    required this.mlLabel,
    this.altLabels = const [],
  });

  List<String> get matchLabels => [mlLabel, ...altLabels];

  @override
  String toString() => '$emoji $name';
}

class ItemSelectorService {
  static final Random _random = Random();

  static SelectedItem _fromMap(Map<String, dynamic> item) {
    return SelectedItem(
      name: item['name'] as String,
      emoji: item['emoji'] as String,
      mlLabel: item['mlLabel'] as String,
      altLabels: List<String>.from(item['altLabels'] as List? ?? []),
    );
  }

  /// Returns a randomly selected item from the curated list
  static SelectedItem pickRandom() {
    final items = AppConstants.alarmItems;
    return _fromMap(items[_random.nextInt(items.length)]);
  }

  /// Returns N unique random items.
  static List<SelectedItem> pickMultiple(int count) {
    final capped = count.clamp(1, AppConstants.alarmItems.length);
    final items = List.of(AppConstants.alarmItems)..shuffle(_random);
    return items.take(capped).map(_fromMap).toList();
  }

  static List<SelectedItem> get allItems =>
      AppConstants.alarmItems.map(_fromMap).toList();
}
