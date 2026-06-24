// lib/screens/ringing_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/item_selector_service.dart';
import '../utils/app_theme.dart';
import 'camera_screen.dart';

class RingingScreen extends StatefulWidget {
  final int alarmId;
  const RingingScreen({super.key, required this.alarmId});

  @override
  State<RingingScreen> createState() => _RingingScreenState();
}

class _RingingScreenState extends State<RingingScreen>
    with TickerProviderStateMixin {
  late final SelectedItem _winner;
  late final List<SelectedItem> _cyclePool;

  int _cycleIndex = 0;
  bool _revealed = false;
  Timer? _cycleTimer;

  late AnimationController _ringAnim;
  late AnimationController _spinAnim;
  late AnimationController _revealAnim;
  late Animation<double> _revealScale;
  late Animation<double> _revealFade;

  @override
  void initState() {
    super.initState();
    _winner = ItemSelectorService.pickRandom();
    _cyclePool = List.of(ItemSelectorService.allItems)..shuffle();

    _ringAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _spinAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _revealAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _revealScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _revealAnim, curve: Curves.elasticOut),
    );
    _revealFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealAnim,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    Future.delayed(const Duration(milliseconds: 600), _startSelection);
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _ringAnim.dispose();
    _spinAnim.dispose();
    _revealAnim.dispose();
    super.dispose();
  }

  void _startSelection() {
    var step = 0;
    const totalSteps = 22;

    void tick() {
      if (!mounted) return;

      if (step >= totalSteps) {
        setState(() => _revealed = true);
        _spinAnim.stop();
        _revealAnim.forward();
        return;
      }

      setState(() {
        if (step >= totalSteps - 1) {
          _cycleIndex = _cyclePool.indexWhere((i) => i.name == _winner.name);
          if (_cycleIndex < 0) _cycleIndex = 0;
        } else {
          _cycleIndex = (_cycleIndex + 1) % _cyclePool.length;
        }
      });

      step++;
      final delay = step < 10
          ? 70
          : step < 16
              ? 110
              : step < 20
                  ? 180
                  : 320;
      _cycleTimer = Timer(Duration(milliseconds: delay), tick);
    }

    tick();
  }

  void _proceedToCamera() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => CameraScreen(
          alarmId: widget.alarmId,
          targetItem: _winner,
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.danger.withOpacity(0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withOpacity(0.05),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _revealed
                        ? _buildReveal()
                        : _buildSelectingAnimation(),
                  ),
                  if (_revealed) _buildActionButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _ringAnim,
      builder: (_, __) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.danger.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.danger
                        .withOpacity(0.3 + (_ringAnim.value * 0.3)),
                    blurRadius: 18 + (_ringAnim.value * 18),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.alarm_rounded,
                color: AppTheme.danger,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'WAKE UP!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _revealed
                  ? 'Find this object to stop the alarm'
                  : 'Picking your challenge...',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectingAnimation() {
    final current = _cyclePool[_cycleIndex];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _spinAnim,
          builder: (_, __) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: _spinAnim.value * 2 * pi,
                  child: Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.accent.withOpacity(0.25),
                        width: 2,
                      ),
                    ),
                    child: CustomPaint(
                      painter: _OrbitDotsPainter(_spinAnim.value),
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: -_spinAnim.value * pi,
                  child: Container(
                    width: 196,
                    height: 196,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.accentSecondary.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.surfaceElevated,
                        AppTheme.surfaceElevated.withOpacity(0.85),
                      ],
                    ),
                    border: Border.all(
                      color: AppTheme.accent.withOpacity(0.45),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withOpacity(0.15),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 90),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: Text(
                        current.emoji,
                        key: ValueKey(current.name),
                        style: const TextStyle(fontSize: 68),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 36),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.accent.withOpacity(0.8),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'SHUFFLING',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReveal() {
    return AnimatedBuilder(
      animation: _revealAnim,
      builder: (_, __) => Opacity(
        opacity: _revealFade.value,
        child: Transform.scale(
          scale: _revealScale.value,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.danger.withOpacity(0.2),
                      AppTheme.danger.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(
                    color: AppTheme.danger.withOpacity(0.6),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.danger.withOpacity(0.25),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _winner.emoji,
                    style: const TextStyle(fontSize: 88),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'FIND THIS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.danger,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _winner.name,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _proceedToCamera,
          icon: const Icon(Icons.camera_alt_rounded, size: 22),
          label: const Text('TAKE PHOTO'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.danger,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitDotsPainter extends CustomPainter {
  final double progress;

  _OrbitDotsPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const dotCount = 8;

    for (var i = 0; i < dotCount; i++) {
      final angle = (i / dotCount) * 2 * pi + progress * 2 * pi;
      final dotCenter = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      final paint = Paint()
        ..color = AppTheme.accent.withOpacity(0.35 + (i / dotCount) * 0.45)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dotCenter, 4, paint);
    }
  }

  @override
  bool shouldRepaint(_OrbitDotsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
