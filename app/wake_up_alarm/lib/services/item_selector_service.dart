// lib/services/item_selector_service.dart
import 'dart:math';
import '../utils/app_theme.dart';

class SelectedItem {
  final String name;
  final String emoji;
  final String mlLabel;

  const SelectedItem({
    required this.name,
    required this.emoji,
    required this.mlLabel,
  });

  @override
  String toString() => '$emoji $name';
}

class ItemSelectorService {
  static final Random _random = Random();

  /// Returns a randomly selected item from the curated list
  static SelectedItem pickRandom() {
    final items = AppConstants.alarmItems;
    final picked = items[_random.nextInt(items.length)];
    return SelectedItem(
      name: picked['name'] as String,
      emoji: picked['emoji'] as String,
      mlLabel: picked['mlLabel'] as String,
    );
  }

  /// Returns N unique random items (for showing the full list UI)
  static List<SelectedItem> pickMultiple(int count) {
    final items = List.of(AppConstants.alarmItems)..shuffle(_random);
    return items
        .take(count)
        .map((e) => SelectedItem(
              name: e['name'] as String,
              emoji: e['emoji'] as String,
              mlLabel: e['mlLabel'] as String,
            ))
        .toList();
  }

  static List<SelectedItem> get allItems => AppConstants.alarmItems
      .map((e) => SelectedItem(
            name: e['name'] as String,
            emoji: e['emoji'] as String,
            mlLabel: e['mlLabel'] as String,
          ))
      .toList();
}
