import 'package:flutter/material.dart';

import '../../theme/pawmilya_palette.dart';
import '../../widgets/primary_action_button.dart';
import 'admin_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _pulseController;

  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _titleFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.1, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _buttonFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.45, 1, curve: Curves.easeOut),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.5, 1, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _showManageMessage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AdminManagementScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final glow = 0.84 + (0.16 * _pulseController.value);

          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  PawmilyaPalette.creamTop,
                  PawmilyaPalette.creamMid,
                  PawmilyaPalette.creamBottom,
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -80,
                  right: -70,
                  child: _GlowOrb(size: 240, glow: glow),
                ),
                Positioned(
                  bottom: -110,
                  left: -80,
                  child: _GlowOrb(size: 280, glow: glow * 0.92),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        FadeTransition(
                          opacity: _titleFade,
                          child: SlideTransition(
                            position: _titleSlide,
                            child: Column(
                              children: [
                                const Text(
                                  'Welcome Admin',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 44,
                                    height: 1.02,
                                    fontWeight: FontWeight.w800,
                                    color: PawmilyaPalette.textPrimary,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Control shelter workflows, review updates, and keep Pawmilya running smoothly.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: PawmilyaPalette.textSecondary.withValues(alpha: 0.95),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(flex: 3),
                        FadeTransition(
                          opacity: _buttonFade,
                          child: SlideTransition(
                            position: _buttonSlide,
                            child: Column(
                              children: [
                                PrimaryActionButton(
                                  label: 'Manage the App',
                                  icon: Icons.dashboard_customize_rounded,
                                  colors: const [
                                    Color(0xFFE0A95F),
                                    Color(0xFFD08E43),
                                    Color(0xFFB86C2E),
                                  ],
                                  glow: 0.7,
                                  onTap: _showManageMessage,
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).popUntil((route) => route.isFirst);
                                  },
                                  child: const Text(
                                    'Back to Role Select',
                                    style: TextStyle(
                                      color: PawmilyaPalette.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
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
          );
        },
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.glow});

  final double size;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            PawmilyaPalette.goldLight.withValues(alpha: 0.18 * glow),
            PawmilyaPalette.gold.withValues(alpha: 0.1 * glow),
            Colors.transparent,
          ],
          stops: const [0.1, 0.5, 1],
        ),
      ),
    );
  }
}
