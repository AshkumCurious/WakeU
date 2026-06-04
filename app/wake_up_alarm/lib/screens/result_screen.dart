// lib/screens/result_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/item_selector_service.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';

class ResultScreen extends StatefulWidget {
  final bool success;
  final SelectedItem targetItem;
  final String detectedLabel;
  final double confidence;

  const ResultScreen({
    super.key,
    required this.success,
    required this.targetItem,
    required this.detectedLabel,
    required this.confidence,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainAnim;
  late AnimationController _particleAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _mainAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _particleAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnim, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _mainAnim,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );
    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
          parent: _mainAnim,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );

    _mainAnim.forward();

    if (widget.success) {
      // Auto-go home after 4 seconds
      Timer(const Duration(seconds: 4), _goHome);
    }
  }

  @override
  void dispose() {
    _mainAnim.dispose();
    _particleAnim.dispose();
    super.dispose();
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.success ? AppTheme.success : AppTheme.danger;
    final emoji = widget.success ? '🎉' : '❌';
    final title = widget.success ? 'GOOD MORNING!' : 'NOT QUITE!';
    final subtitle = widget.success
        ? 'Alarm stopped. Have a great day!'
        : 'That doesn\'t look like a ${widget.targetItem.name}';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Particles for success
            if (widget.success)
              Positioned.fill(child: _buildParticles()),

            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.15),
                          border: Border.all(color: color, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 56),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    FadeTransition(
                      opacity: _fadeAnim,
                      child: AnimatedBuilder(
                        animation: _slideAnim,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(0, _slideAnim.value),
                          child: child,
                        ),
                        child: Column(
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: color,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Detection details
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Column(
                                children: [
                                  _detailRow(
                                    'Looking for',
                                    '${widget.targetItem.emoji} ${widget.targetItem.name}',
                                  ),
                                  const SizedBox(height: 8),
                                  _detailRow(
                                    'Detected',
                                    widget.detectedLabel.isEmpty
                                        ? 'Nothing detected'
                                        : widget.detectedLabel,
                                    valueColor: widget.success
                                        ? AppTheme.success
                                        : AppTheme.danger,
                                  ),
                                  if (widget.confidence > 0) ...[
                                    const SizedBox(height: 8),
                                    _detailRow(
                                      'Confidence',
                                      '${(widget.confidence * 100).toStringAsFixed(0)}%',
                                      valueColor: widget.success
                                          ? AppTheme.success
                                          : AppTheme.danger,
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            if (!widget.success)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 20),
                                  label: const Text('TRY AGAIN'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.danger,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),

                            if (widget.success)
                              Text(
                                'Returning to home in a moment...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      AppTheme.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value,
      {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleAnim,
      builder: (_, __) {
        return CustomPaint(
          painter: _ParticlePainter(_particleAnim.value),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  static const _colors = [
    AppTheme.accent,
    AppTheme.success,
    AppTheme.accentSecondary,
    Colors.yellow,
    Colors.orange,
  ];

  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 20; i++) {
      final p = (progress + i / 20) % 1.0;
      final x = (size.width * ((i * 137.5) % 100) / 100);
      final y = size.height * p;
      final paint = Paint()
        ..color = _colors[i % _colors.length].withOpacity(1 - p)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 4, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
