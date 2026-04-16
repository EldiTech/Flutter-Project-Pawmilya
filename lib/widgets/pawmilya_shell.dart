import 'package:flutter/material.dart';

import '../theme/pawmilya_palette.dart';

class PawmilyaShell extends StatelessWidget {
  const PawmilyaShell({
    super.key,
    required this.child,
    this.showBackButton = false,
    this.compactOnKeyboard = false,
  });

  final Widget child;
  final bool showBackButton;
  final bool compactOnKeyboard;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen =
        compactOnKeyboard && MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      body: DecoratedBox(
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
          fit: StackFit.expand,
          children: [
            const _SubtlePawPattern(),
            Positioned(
              top: -86,
              right: -28,
              child: _AmbientGlow(
                size: 210,
                color: PawmilyaPalette.gold.withValues(alpha: 0.16),
              ),
            ),
            Positioned(
              bottom: -95,
              left: -40,
              child: _AmbientGlow(
                size: 230,
                color: PawmilyaPalette.goldLight.withValues(alpha: 0.14),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  22,
                  keyboardOpen ? 8 : 14,
                  22,
                  keyboardOpen ? 10 : 18,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: keyboardOpen ? 38 : 42,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: showBackButton
                            ? _RoundIconButton(
                                icon: Icons.arrow_back_rounded,
                                onTap: () => Navigator.of(context).maybePop(),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    SizedBox(height: keyboardOpen ? 2 : 4),
                    if (!keyboardOpen) const _GlossyPawLogo(),
                    SizedBox(height: keyboardOpen ? 8 : 20),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: child,
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
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.68),
        border: Border.all(
          color: PawmilyaPalette.cardEdge.withValues(alpha: 0.75),
        ),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: PawmilyaPalette.textPrimary, size: 20),
        padding: EdgeInsets.zero,
        splashRadius: 20,
      ),
    );
  }
}

class _GlossyPawLogo extends StatelessWidget {
  const _GlossyPawLogo();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 126,
          height: 126,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                PawmilyaPalette.gold.withValues(alpha: 0.26),
                PawmilyaPalette.gold.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: PawmilyaPalette.creamTop,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.75),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: PawmilyaPalette.goldDark.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/app_logo.png',
              cacheWidth: 400, // Downscale image before storing in memory
              fit: BoxFit.contain,
              color: PawmilyaPalette.creamTop,
              colorBlendMode: BlendMode.multiply,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.pets_rounded,
                  size: 46,
                  color: PawmilyaPalette.goldDark,
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 22,
          child: Container(
            width: 54,
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.78),
                  Colors.white.withValues(alpha: 0.08),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SubtlePawPattern extends StatelessWidget {
  const _SubtlePawPattern();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: const [
          _PatternPaw(
            alignment: Alignment(-0.86, -0.64),
            size: 34,
            rotation: -0.3,
            opacity: 0.04,
          ),
          _PatternPaw(
            alignment: Alignment(-0.55, -0.28),
            size: 30,
            rotation: -0.24,
            opacity: 0.04,
          ),
          _PatternPaw(
            alignment: Alignment(-0.2, 0.08),
            size: 27,
            rotation: -0.18,
            opacity: 0.038,
          ),
          _PatternPaw(
            alignment: Alignment(0.16, 0.4),
            size: 24,
            rotation: -0.14,
            opacity: 0.035,
          ),
          _PatternPaw(
            alignment: Alignment(0.5, 0.7),
            size: 21,
            rotation: -0.1,
            opacity: 0.03,
          ),
          _PatternPaw(
            alignment: Alignment(0.82, -0.55),
            size: 28,
            rotation: 0.2,
            opacity: 0.032,
          ),
          _PatternPaw(
            alignment: Alignment(0.58, -0.2),
            size: 24,
            rotation: 0.16,
            opacity: 0.03,
          ),
        ],
      ),
    );
  }
}

class _PatternPaw extends StatelessWidget {
  const _PatternPaw({
    required this.alignment,
    required this.size,
    required this.rotation,
    required this.opacity,
  });

  final Alignment alignment;
  final double size;
  final double rotation;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.rotate(
        angle: rotation,
        child: Icon(
          Icons.pets_rounded,
          size: size,
          color: PawmilyaPalette.textSecondary.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
