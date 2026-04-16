import 'package:flutter/material.dart';

import '../../navigation/fade_slide_route.dart';
import '../../services/auth_service.dart';
import '../../theme/pawmilya_palette.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/login_card.dart';
import '../../widgets/pawmilya_input_field.dart';
import '../../widgets/pawmilya_shell.dart';
import '../../widgets/primary_action_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_banned_screen.dart';
import 'user_home_screen.dart';
import 'user_sign_up_screen.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final AnimationController _entryController;
  late final AnimationController _tapController;
  late final Animation<double> _buttonScale;
  late final Animation<double> _buttonGlow;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..forward();

    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _buttonScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.96,
          end: 1.04,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.04,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_tapController);

    _buttonGlow = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 55,
      ),
    ]).animate(_tapController);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _entryController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  Animation<double> _segment(double start, double end) {
    return CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  bool _looksLikeEmail(String value) {
    final normalized = value.trim();
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized);
  }

  void _showMessage(String message, {required bool isError}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? const Color(0xFF8A5535)
            : const Color(0xFF9A6A3D),
        content: Text(message),
      ),
    );
  }

  Future<void> _goToUserHome() async {
    await Navigator.of(context).pushReplacement(
      fadeSlideRoute(
        page: const UserPage(),
        begin: const Offset(0, 0.05),
        durationMs: 520,
      ),
    );
  }

  Future<void> _loginAsUser() async {
    if (_isSubmitting) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      _showMessage('Email is required.', isError: true);
      return;
    }
    if (!_looksLikeEmail(email)) {
      _showMessage('Please enter a valid email address.', isError: true);
      return;
    }
    if (password.isEmpty) {
      _showMessage('Password is required.', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    _tapController.forward(from: 0);

    try {
      await AuthService.instance.signInUser(email: email, password: password);
      if (!mounted) {
        return;
      }
      await _goToUserHome();
    } catch (error) {
      if (mounted) {
        if (error is FirebaseAuthException && error.code == 'user-banned') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const UserBannedScreen()),
          );
        } else {
          _showMessage(AuthService.instance.mapError(error), isError: true);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _openCreateAccount() async {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return UserSignUpScreen(initialEmail: _emailController.text.trim());
        },
      ),
    );
  }

  Future<void> _forgotPassword() async {
    if (_isSubmitting) {
      return;
    }

    final email = _emailController.text.trim();
    if (!_looksLikeEmail(email)) {
      _showMessage('Enter your email first to reset password.', isError: true);
      return;
    }

    try {
      await AuthService.instance.sendPasswordReset(email: email);
      if (!mounted) {
        return;
      }
      _showMessage('Password reset email sent.', isError: false);
    } catch (error) {
      if (mounted) {
        _showMessage(AuthService.instance.mapError(error), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final headingAnim = _segment(0, 0.26);
    final emailAnim = _segment(0.16, 0.42);
    final passwordAnim = _segment(0.28, 0.54);
    final forgotAnim = _segment(0.38, 0.64);
    final loginAnim = _segment(0.5, 0.82);
    final createAnim = _segment(0.64, 1);

    return PawmilyaShell(
      showBackButton: true,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: LoginCard(
          structured: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeSlideIn(
                animation: headingAnim,
                begin: const Offset(0, 0.08),
                child: const Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          size: 20,
                          color: PawmilyaPalette.goldDark,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Welcome Back!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: PawmilyaPalette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Log in to continue caring for your pets',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: PawmilyaPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              FadeSlideIn(
                animation: emailAnim,
                begin: const Offset(0, 0.07),
                child: PawmilyaInputField(
                  controller: _emailController,
                  hintText: 'Email',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  playful: true,
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideIn(
                animation: passwordAnim,
                begin: const Offset(0, 0.07),
                child: PawmilyaInputField(
                  controller: _passwordController,
                  hintText: 'Password',
                  icon: Icons.lock_rounded,
                  obscureText: true,
                  playful: true,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FadeSlideIn(
                  animation: forgotAnim,
                  begin: const Offset(0.05, 0),
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: PawmilyaPalette.goldDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                animation: loginAnim,
                begin: const Offset(0, 0.06),
                child: AnimatedBuilder(
                  animation: _tapController,
                  builder: (context, child) {
                    return PrimaryActionButton(
                      label: _isSubmitting ? 'Please Wait...' : 'Log In',
                      icon: Icons.pets_rounded,
                      colors: const [
                        Color(0xFFE6B368),
                        Color(0xFFD79647),
                        Color(0xFFB97232),
                      ],
                      onTap: _isSubmitting ? null : _loginAsUser,
                      scale: _buttonScale.value,
                      glow: _buttonGlow.value,
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              FadeSlideIn(
                animation: createAnim,
                begin: const Offset(0, 0.06),
                child: OutlinedButton(
                  onPressed: _openCreateAccount,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    side: BorderSide(
                      color: PawmilyaPalette.gold.withValues(alpha: 0.65),
                    ),
                    foregroundColor: PawmilyaPalette.goldDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
