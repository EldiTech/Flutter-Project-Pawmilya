import 'package:flutter/material.dart';

import '../../navigation/fade_slide_route.dart';
import '../../services/auth_service.dart';
import '../../services/role_access_service.dart';
import '../../theme/pawmilya_palette.dart';
import '../../widgets/login_card.dart';
import '../../widgets/pawmilya_input_field.dart';
import '../../widgets/pawmilya_shell.dart';
import '../../widgets/primary_action_button.dart';
import 'shelter_dashboard_screen.dart';
import 'shelter_sign_up_screen.dart';

class ShelterLoginScreen extends StatefulWidget {
  const ShelterLoginScreen({super.key});

  @override
  State<ShelterLoginScreen> createState() => _ShelterLoginScreenState();
}

class _ShelterLoginScreenState extends State<ShelterLoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _credentialController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final AnimationController _entryController;
  late final AnimationController _tapController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;
  late final Animation<double> _buttonScale;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    )..forward();

    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );

    _buttonScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0.97,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 42,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.97,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 58,
      ),
    ]).animate(_tapController);
  }

  @override
  void dispose() {
    _credentialController.dispose();
    _passwordController.dispose();
    _entryController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {required bool isError}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? const Color(0xFF7D4D2A)
            : const Color(0xFF916239),
        content: Text(message),
      ),
    );
  }

  Future<void> _loginAsShelter() async {
    if (_isSubmitting) {
      return;
    }

    final credential = _credentialController.text.trim();
    final password = _passwordController.text.trim();

    if (credential.isEmpty) {
      _showMessage('Enter your shelter email.', isError: true);
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
      final authResult = await AuthService.instance.signInShelter(
        emailOrAdminId: credential,
        password: password,
      );

      final signedInUser = authResult.user;
      if (signedInUser == null) {
        await AuthService.instance.signOut();
        if (!mounted) {
          return;
        }
        _showMessage('Login failed. Please try again.', isError: true);
        return;
      }

      final accessResult = await RoleAccessService.instance.checkShelterAccess(
        user: signedInUser,
      );

      if (!accessResult.isAllowed) {
        await AuthService.instance.signOut();
        if (!mounted) {
          return;
        }
        _showMessage(accessResult.message, isError: true);
        return;
      }

      if (!mounted) {
        return;
      }

      await Navigator.of(context).pushReplacement(
        fadeSlideRoute(
          page: const ShelterDashboardScreen(),
          begin: const Offset(0.09, 0),
          durationMs: 500,
        ),
      );
    } catch (error) {
      if (mounted) {
        _showMessage(AuthService.instance.mapError(error), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PawmilyaShell(
      showBackButton: true,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideIn,
            child: LoginCard(
              structured: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Shelter Login',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: PawmilyaPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Access your shelter workspace',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: PawmilyaPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  PawmilyaInputField(
                    controller: _credentialController,
                    hintText: 'Shelter Email',
                    icon: Icons.home_work_rounded,
                    keyboardType: TextInputType.emailAddress,
                    playful: false,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Use the official shelter account email assigned to you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: PawmilyaPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  PawmilyaInputField(
                    controller: _passwordController,
                    hintText: 'Password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: true,
                    playful: false,
                  ),
                  const SizedBox(height: 18),
                  AnimatedBuilder(
                    animation: _tapController,
                    builder: (context, child) {
                      return PrimaryActionButton(
                        label: _isSubmitting
                            ? 'Signing In...'
                            : 'Log In as Shelter',
                        icon: Icons.cottage_rounded,
                        colors: const [
                          Color(0xFFC59051),
                          Color(0xFFAA6F38),
                          Color(0xFF845229),
                        ],
                        onTap: _isSubmitting ? null : _loginAsShelter,
                        scale: _buttonScale.value,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ShelterSignUpScreen(
                                  initialEmail: _credentialController.text
                                      .trim(),
                                ),
                              ),
                            );
                          },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: BorderSide(
                        color: PawmilyaPalette.shelterBrown.withValues(
                          alpha: 0.65,
                        ),
                      ),
                      foregroundColor: PawmilyaPalette.shelterBrown,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Register a Shelter',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
