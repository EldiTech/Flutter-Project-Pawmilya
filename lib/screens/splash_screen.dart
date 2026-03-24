import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import 'landing_screen.dart';
import 'system_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _ambientController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoTilt;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _cardOpacity;
  late final Animation<double> _cardSlide;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);

    _logoScale = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
    );
    _logoTilt = Tween<double>(begin: -0.32, end: 0.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );
    _titleOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.35, 0.75, curve: Curves.easeIn),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.35, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.55, 0.95, curve: Curves.easeIn),
    );
    _cardOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.2, 0.85, curve: Curves.easeIn),
    );
    _cardSlide = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.2, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _introController.forward();

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        final currentUser = FirebaseAuth.instance.currentUser;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                currentUser != null
                ? const SystemHomeScreen()
                : const LandingScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBg,
      body: AnimatedBuilder(
        animation: _ambientController,
        builder: (context, _) {
          final ambientValue = _ambientController.value;

          return Stack(
            fit: StackFit.expand,
            children: [
              _AnimatedBackdrop(ambientValue: ambientValue),
              Center(
                child: Transform.translate(
                  offset: Offset(0, _cardSlide.value),
                  child: FadeTransition(
                    opacity: _cardOpacity,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 28),
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppColors.warmAccent.withValues(alpha: 0.6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            blurRadius: 30,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ScaleTransition(
                            scale: _logoScale,
                            child: AnimatedBuilder(
                              animation: _ambientController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _logoTilt.value,
                                  child: child,
                                );
                              },
                              child: Container(
                                width: 124,
                                height: 124,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.warmAccent.withValues(alpha: 0.75),
                                      AppColors.primaryLight.withValues(alpha: 0.45),
                                    ],
                                  ),
                                ),
                                child: const Center(
                                  child: FaIcon(
                                    FontAwesomeIcons.paw,
                                    size: 54,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SlideTransition(
                            position: _titleSlide,
                            child: FadeTransition(
                              opacity: _titleOpacity,
                              child: Text(
                                'Pawmilya',
                                style: GoogleFonts.quicksand(
                                  fontSize: 50,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          FadeTransition(
                            opacity: _subtitleOpacity,
                            child: Text(
                              'Shelter Management System',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.quicksand(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          FadeTransition(
                            opacity: _subtitleOpacity,
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppColors.primary.withValues(alpha: 0.7),
                                backgroundColor: AppColors.warmAccent.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnimatedBackdrop extends StatelessWidget {
  const _AnimatedBackdrop({required this.ambientValue});

  final double ambientValue;

  @override
  Widget build(BuildContext context) {
    final shiftA = (ambientValue - 0.5) * 22;
    final shiftB = (0.5 - ambientValue) * 28;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.warmBg,
                AppColors.warmBg.withValues(alpha: 0.95),
              ],
            ),
          ),
        ),
        Positioned(
          top: -80 + shiftA,
          right: -40,
          child: _SoftBlob(
            size: 230,
            color: AppColors.primaryLight.withValues(alpha: 0.16),
          ),
        ),
        Positioned(
          bottom: -120 + shiftB,
          left: -60,
          child: _SoftBlob(
            size: 280,
            color: AppColors.warmAccent.withValues(alpha: 0.26),
          ),
        ),
        Positioned(
          bottom: 120 - shiftA,
          right: -70,
          child: _SoftBlob(
            size: 180,
            color: AppColors.primary.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }
}

class _SoftBlob extends StatelessWidget {
  const _SoftBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
