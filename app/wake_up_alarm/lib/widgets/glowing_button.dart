// lib/widgets/glowing_button.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Simple primary action button — no glow or animation.
class GlowingButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final IconData? icon;
  final double? width;

  const GlowingButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color ?? AppTheme.textPrimary,
          foregroundColor: AppTheme.background,
          minimumSize: const Size.fromHeight(52),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}

class AlarmCard extends StatelessWidget {
  final String timeString;
  final String label;
  final String repeatString;
  final bool isEnabled;
  final bool isNext;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const AlarmCard({
    super.key,
    required this.timeString,
    required this.label,
    required this.repeatString,
    required this.isEnabled,
    this.isNext = false,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final parts = timeString.split(' ');
    final time = parts.isNotEmpty ? parts[0] : timeString;
    final period = parts.length > 1 ? parts[1] : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedOpacity(
          opacity: isEnabled ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: isNext
                  ? AppTheme.surfaceElevated
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isNext
                    ? AppTheme.accentSecondary.withValues(alpha: 0.35)
                    : AppTheme.border.withValues(alpha: 0.6),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w300,
                              color: isEnabled
                                  ? AppTheme.textPrimary
                                  : AppTheme.textMuted,
                              letterSpacing: -1,
                              height: 1,
                            ),
                          ),
                          if (period.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              period,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: isEnabled
                                    ? AppTheme.textSecondary
                                    : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label.isEmpty ? 'Alarm' : label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: isEnabled
                              ? AppTheme.textSecondary
                              : AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        repeatString,
                        style: TextStyle(
                          fontSize: 13,
                          color: isEnabled
                              ? AppTheme.textMuted
                              : AppTheme.textMuted.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: (_) => onToggle(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
