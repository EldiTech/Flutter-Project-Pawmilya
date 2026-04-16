import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../navigation/fade_slide_route.dart';
import '../theme/pawmilya_palette.dart';
import 'role_selection_screen.dart';

class EnterSystemLandingScreen extends StatefulWidget {
  const EnterSystemLandingScreen({super.key});

  @override
  State<EnterSystemLandingScreen> createState() =>
      _EnterSystemLandingScreenState();
}

class _EnterSystemLandingScreenState extends State<EnterSystemLandingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ambientController;
  late final AnimationController _entranceController;
  late final AnimationController _buttonTapController;

  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _buttonScale;
  late final Animation<double> _buttonGlow;

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _buttonTapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
          ),
        );

    _textFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.28, 0.78, curve: Curves.easeOutCubic),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.28, 0.78, curve: Curves.easeOutCubic),
          ),
        );

    _buttonFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
    );
    _buttonSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _buttonScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 28,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.96,
          end: 1.04,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 37,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.04,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
    ]).animate(_buttonTapController);

    _buttonGlow = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 42,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 58,
      ),
    ]).animate(_buttonTapController);
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _entranceController.dispose();
    _buttonTapController.dispose();
    super.dispose();
  }

  Future<void> _enterSystem() async {
    if (_isNavigating) {
      return;
    }

    _buttonTapController.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) {
      return;
    }

    setState(() {
      _isNavigating = true;
    });

    await Navigator.of(context).pushReplacement(
      fadeSlideRoute(
        page: const RoleSelectionScreen(),
        begin: const Offset(0, 0.08),
        durationMs: 520,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgTop = Color(0xFFFAF4EA);
    const bgBottom = Color(0xFFF1E5D4);
    const amber = Color(0xFFD28734);
    const warmBrown = Color(0xFF8B5724);
    const warmMuted = Color(0xFFB58C5D);

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_ambientController, _buttonTapController]),
        builder: (context, child) {
          final spin = _ambientController.value * 2 * math.pi;
          final glowPulse = 0.65 + (math.sin(spin) + 1) * 0.16;
          final logoLift = math.sin(spin * 0.9) * -4;
          final buttonScale = _buttonScale.value;
          final buttonGlow = _buttonGlow.value;

          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [bgTop, Color(0xFFF5EBDC), bgBottom],
                  ),
                ),
              ),
              const _SubtlePawTrail(),
              Positioned(
                top: -86,
                right: -48,
                child: Container(
                  width: 244,
                  height: 244,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        amber.withValues(alpha: 0.2 * glowPulse),
                        amber.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -95,
                left: -46,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(
                          0xFFF0CFA7,
                        ).withValues(alpha: 0.24 * glowPulse),
                        const Color(0xFFF0CFA7).withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FadeTransition(
                                opacity: _logoFade,
                                child: SlideTransition(
                                  position: _logoSlide,
                                  child: Transform.translate(
                                    offset: Offset(0, logoLift),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: 230,
                                          height: 230,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: [
                                                amber.withValues(
                                                  alpha: 0.22 * glowPulse,
                                                ),
                                                amber.withValues(alpha: 0),
                                              ],
                                            ),
                                          ),
                                        ),
                                        CustomPaint(
                                          size: const Size(242, 242),
                                          painter: _SoftOrbitPainter(
                                            glowOpacity:
                                                0.42 +
                                                (math.sin(spin) + 1) * 0.08,
                                          ),
                                        ),
                                        Container(
                                          width: 182,
                                          height: 182,
                                          decoration: BoxDecoration(
                                            color: PawmilyaPalette.creamTop,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: amber.withValues(
                                                  alpha: 0.28 * glowPulse,
                                                ),
                                                blurRadius: 28,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: Image.asset(
                                              'assets/images/app_logo.png',
                                              cacheWidth: 800, // Scales down image decode size out of memory
                                              fit: BoxFit.contain,
                                              color: PawmilyaPalette.creamTop,
                                              colorBlendMode: BlendMode.multiply,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return const Icon(
                                                      Icons.pets_rounded,
                                                      size: 64,
                                                      color: Color(0xFFB97331),
                                                    );
                                                  },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              FadeTransition(
                                opacity: _textFade,
                                child: SlideTransition(
                                  position: _textSlide,
                                  child: const Column(
                                    children: [
                                      Text(
                                        'Pawmilya',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 42,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.4,
                                          color: warmBrown,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'Your Pet, Your Family',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: 0.22,
                                          color: warmMuted,
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
                      FadeTransition(
                        opacity: _buttonFade,
                        child: SlideTransition(
                          position: _buttonSlide,
                          child: Transform.scale(
                            scale: buttonScale,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 430),
                              child: Container(
                                width: double.infinity,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFE3A754),
                                      Color(0xFFC67E36),
                                      Color(0xFFA8642C),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFB16C2F).withValues(
                                        alpha: 0.28 + (0.18 * buttonGlow),
                                      ),
                                      blurRadius: 14 + (12 * buttonGlow),
                                      spreadRadius: 1 + (1.4 * buttonGlow),
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(30),
                                    onTap: _isNavigating ? null : _enterSystem,
                                    child: const Center(
                                      child: Text(
                                        'Enter System',
                                        style: TextStyle(
                                          color: Color(0xFFFFF6E8),
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.25,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
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

class _SubtlePawTrail extends StatelessWidget {
  const _SubtlePawTrail();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment(-0.84, 0.5),
            child: _TrailPawMark(size: 46, rotation: -0.52, opacity: 0.07),
          ),
          Align(
            alignment: Alignment(-0.54, 0.22),
            child: _TrailPawMark(size: 40, rotation: -0.48, opacity: 0.06),
          ),
          Align(
            alignment: Alignment(-0.22, -0.04),
            child: _TrailPawMark(size: 35, rotation: -0.42, opacity: 0.055),
          ),
          Align(
            alignment: Alignment(0.11, -0.3),
            child: _TrailPawMark(size: 31, rotation: -0.36, opacity: 0.05),
          ),
          Align(
            alignment: Alignment(0.42, -0.56),
            child: _TrailPawMark(size: 27, rotation: -0.32, opacity: 0.045),
          ),
        ],
      ),
    );
  }
}

class _TrailPawMark extends StatelessWidget {
  const _TrailPawMark({
    required this.size,
    required this.rotation,
    required this.opacity,
  });

  final double size;
  final double rotation;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Icon(
        Icons.pets_rounded,
        size: size,
        color: const Color(0xFFBB9A72).withValues(alpha: opacity),
      ),
    );
  }
}

class _SoftOrbitPainter extends CustomPainter {
  const _SoftOrbitPainter({required this.glowOpacity});

  final double glowOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.43;
    final midRadius = size.width * 0.36;
    final innerRadius = size.width * 0.29;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0xFFDFC49E).withValues(alpha: 0.42 * glowOpacity);

    canvas.drawCircle(center, outerRadius, ringPaint);
    canvas.drawCircle(
      center,
      midRadius,
      ringPaint..color = const Color(0xFFE8D4B8).withValues(alpha: 0.3),
    );
    canvas.drawCircle(
      center,
      innerRadius,
      ringPaint..color = const Color(0xFFF1E4D0).withValues(alpha: 0.25),
    );

    final nodePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFF7E7).withValues(alpha: 0.78 * glowOpacity);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFFE8D1AF).withValues(alpha: 0.34);

    final points = <Offset>[];
    for (int i = 0; i < 9; i++) {
      final theta = 2 * math.pi * i / 9;
      final p = Offset(
        center.dx + math.cos(theta) * outerRadius,
        center.dy + math.sin(theta) * outerRadius,
      );
      points.add(p);
      canvas.drawCircle(p, 2.2, nodePaint);
    }

    for (int i = 0; i < points.length; i += 3) {
      final next = (i + 3) % points.length;
      canvas.drawLine(points[i], points[next], linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SoftOrbitPainter oldDelegate) {
    return oldDelegate.glowOpacity != glowOpacity;
  }
}
