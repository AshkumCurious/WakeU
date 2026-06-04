// lib/screens/ringing_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/alarm_scheduler_service.dart';
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
  late List<SelectedItem> _items;
  SelectedItem? _selectedItem;
  int _selectionIndex = -1;
  bool _selectionComplete = false;
  Timer? _rouletteTimer;
  Timer? _pulseTimer;
  int _rouletteStep = 0;
  int _totalRouletteSteps = 0;

  late AnimationController _ringAnim;
  late AnimationController _scaleAnim;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _items = ItemSelectorService.pickMultiple(6);

    _ringAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scaleAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleAnim, curve: Curves.elasticOut),
    );

    // Start the roulette after a short delay
    Future.delayed(const Duration(milliseconds: 800), _startRoulette);
  }

  @override
  void dispose() {
    _rouletteTimer?.cancel();
    _pulseTimer?.cancel();
    _ringAnim.dispose();
    _scaleAnim.dispose();
    super.dispose();
  }

  void _startRoulette() {
    _totalRouletteSteps = 20 + (_items.length * 2);
    _rouletteStep = 0;
    _runRoulette();
  }

  void _runRoulette() {
    if (_rouletteStep >= _totalRouletteSteps) {
      // Lock on final item
      final finalIndex =
          (_items.length - 1) % _items.length; // last item or picked
      final picked =
          ItemSelectorService.pickRandom(); // truly random final pick
      // Find closest match in displayed items or just use picked
      int lockedIndex = _rouletteStep % _items.length;
      setState(() {
        _selectionIndex = lockedIndex;
        _selectedItem = _items[lockedIndex];
        _selectionComplete = true;
      });
      _scaleAnim.forward();
      return;
    }

    final delay = _rouletteStep < 10
        ? 80
        : _rouletteStep < 15
            ? 120
            : _rouletteStep < 18
                ? 200
                : 350;

    _rouletteTimer = Timer(Duration(milliseconds: delay), () {
      setState(() {
        _selectionIndex = _rouletteStep % _items.length;
      });
      _rouletteStep++;
      _runRoulette();
    });
  }

  void _proceedToCamera() {
    if (_selectedItem == null) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => CameraScreen(
          alarmId: widget.alarmId,
          targetItem: _selectedItem!,
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
    return WillPopScope(
      onWillPop: () async => false, // can't back out
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildItemGrid(),
              const SizedBox(height: 24),
              if (_selectionComplete) _buildActionSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _ringAnim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
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
                    blurRadius: 20 + (_ringAnim.value * 20),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.alarm_rounded,
                color: AppTheme.danger,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
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
            const Text(
              'Find the selected object to stop the alarm',
              style: TextStyle(
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

  Widget _buildItemGrid() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemCount: _items.length,
          itemBuilder: (_, i) {
            final item = _items[i];
            final isHighlighted = i == _selectionIndex;
            final isLocked = _selectionComplete && isHighlighted;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isLocked
                    ? AppTheme.danger.withOpacity(0.15)
                    : isHighlighted
                        ? AppTheme.accent.withOpacity(0.15)
                        : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isLocked
                      ? AppTheme.danger
                      : isHighlighted
                          ? AppTheme.accent
                          : AppTheme.border,
                  width: isHighlighted ? 2 : 1,
                ),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: (isLocked ? AppTheme.danger : AppTheme.accent)
                              .withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.emoji,
                    style: TextStyle(
                      fontSize: isHighlighted ? 36 : 30,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isHighlighted
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionSection() {
    final item = _selectedItem!;
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppTheme.danger.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.emoji,
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FIND THIS OBJECT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.danger,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
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
          ],
        ),
      ),
    );
  }
}
