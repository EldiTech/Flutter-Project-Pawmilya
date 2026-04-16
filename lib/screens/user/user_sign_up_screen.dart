import 'package:flutter/material.dart';

import '../../navigation/fade_slide_route.dart';
import '../../services/auth_service.dart';
import '../../theme/pawmilya_palette.dart';
import '../../widgets/login_card.dart';
import '../../widgets/pawmilya_input_field.dart';
import '../../widgets/pawmilya_shell.dart';
import '../../widgets/primary_action_button.dart';
import 'user_home_screen.dart';

class UserSignUpScreen extends StatefulWidget {
  const UserSignUpScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<UserSignUpScreen> createState() => _UserSignUpScreenState();
}

class _UserSignUpScreenState extends State<UserSignUpScreen>
    with SingleTickerProviderStateMixin {
  static const _stepTitles = ['Profile', 'Contact', 'Security'];

  final _usernameController = TextEditingController();
  final _realNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _numberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _usernameFocus = FocusNode();
  final _realNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _numberFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  late final AnimationController _tapController;
  late final Animation<double> _buttonScale;

  int _currentStep = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final prefilledEmail = widget.initialEmail.trim();
    if (prefilledEmail.isNotEmpty) {
      _emailController.text = prefilledEmail;
    }

    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _passwordController.addListener(_onSecurityInputChanged);
    _confirmPasswordController.addListener(_onSecurityInputChanged);

    _buttonScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0.97).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.97, end: 1).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 55,
      ),
    ]).animate(_tapController);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onSecurityInputChanged);
    _confirmPasswordController.removeListener(_onSecurityInputChanged);

    _usernameController.dispose();
    _realNameController.dispose();
    _emailController.dispose();
    _numberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameFocus.dispose();
    _realNameFocus.dispose();
    _emailFocus.dispose();
    _numberFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _focusNode(FocusNode node) {
    if (!mounted) {
      return;
    }
    FocusScope.of(context).requestFocus(node);
  }

  void _focusFirstFieldForStep(int step) {
    switch (step) {
      case 0:
        _focusNode(_usernameFocus);
        break;
      case 1:
        _focusNode(_emailFocus);
        break;
      case 2:
        _focusNode(_passwordFocus);
        break;
    }
  }

  void _submitStepFromKeyboard(String _) {
    FocusScope.of(context).unfocus();
    _onPrimaryAction();
  }

  void _onSecurityInputChanged() {
    if (!mounted || _currentStep != 2) {
      return;
    }
    setState(() {});
  }

  bool _looksLikeEmail(String value) {
    final normalized = value.trim();
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized);
  }

  bool _looksLikePhoneNumber(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    return digitsOnly.length >= 7;
  }

  int _passwordStrengthScore(String password) {
    var score = 0;

    if (password.length >= 8) {
      score++;
    }
    if (RegExp(r'[A-Z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      score++;
    }

    return score;
  }

  bool _isStrongPassword(String password) {
    return _passwordStrengthScore(password) >= 4;
  }

  Color _passwordStrengthColor(int score) {
    if (score >= 4) {
      return const Color(0xFF4F8B3B);
    }
    if (score >= 3) {
      return const Color(0xFFC58B2C);
    }
    return const Color(0xFFB04A3A);
  }

  String _passwordStrengthLabel(int score) {
    if (score >= 4) {
      return 'Strong';
    }
    if (score >= 3) {
      return 'Medium';
    }
    return 'Weak';
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

  Future<void> _goToUserPage() async {
    await Navigator.of(context).pushReplacement(
      fadeSlideRoute(
        page: const UserPage(),
        begin: const Offset(0, 0.05),
        durationMs: 520,
      ),
    );
  }

  bool _validateStepOne() {
    final username = _usernameController.text.trim();
    final realName = _realNameController.text.trim();

    if (username.isEmpty) {
      _showMessage('Username is required.', isError: true);
      return false;
    }
    if (realName.isEmpty) {
      _showMessage('Full name is required.', isError: true);
      return false;
    }

    return true;
  }

  bool _validateStepTwo() {
    final email = _emailController.text.trim();
    final number = _numberController.text.trim();

    if (email.isEmpty) {
      _showMessage('Email is required.', isError: true);
      return false;
    }
    if (!_looksLikeEmail(email)) {
      _showMessage('Enter a valid email address.', isError: true);
      return false;
    }
    if (!_looksLikePhoneNumber(number)) {
      _showMessage('Enter a valid contact number.', isError: true);
      return false;
    }

    return true;
  }

  bool _validateStepThree() {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty) {
      _showMessage('Password is required.', isError: true);
      return false;
    }
    if (!_isStrongPassword(password)) {
      _showMessage(
        'Use 8+ chars with upper, lower, number, and symbol.',
        isError: true,
      );
      return false;
    }
    if (confirmPassword.isEmpty) {
      _showMessage('Confirm your password.', isError: true);
      return false;
    }
    if (password != confirmPassword) {
      _showMessage('Passwords do not match.', isError: true);
      return false;
    }

    return true;
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _validateStepOne();
      case 1:
        return _validateStepTwo();
      case 2:
        return _validateStepThree();
      default:
        return false;
    }
  }

  Future<void> _onPrimaryAction() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (!_validateCurrentStep()) {
      return;
    }

    if (_currentStep < 2) {
      final nextStep = _currentStep + 1;
      setState(() {
        _currentStep = nextStep;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusFirstFieldForStep(nextStep);
        }
      });
      return;
    }

    await _createAccount();
  }

  void _goToPreviousStep() {
    if (_isSubmitting) {
      return;
    }

    if (_currentStep == 0) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _currentStep--;
    });
  }

  Future<void> _createAccount() async {
    if (_isSubmitting) {
      return;
    }

    final username = _usernameController.text.trim();
    final realName = _realNameController.text.trim();
    final email = _emailController.text.trim();
    final number = _numberController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isSubmitting = true;
    });

    _tapController.forward(from: 0);

    try {
      await AuthService.instance.createUserAccount(
        email: email,
        password: password,
        username: username,
        realName: realName,
        phoneNumber: number,
      );
      if (!mounted) {
        return;
      }
      _showMessage('Account created successfully.', isError: false);
      await _goToUserPage();
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

  Widget _buildStepHeader({required bool compact}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PawmilyaPalette.cardEdge.withValues(alpha: 0.75),
        ),
      ),
      child: compact
          ? Row(
              children: [
                Text(
                  'Step ${_currentStep + 1}/${_stepTitles.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: PawmilyaPalette.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  _stepTitles[_currentStep],
                  style: const TextStyle(
                    fontSize: 14,
                    color: PawmilyaPalette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step ${_currentStep + 1} of ${_stepTitles.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: PawmilyaPalette.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _stepTitles[_currentStep],
                  style: const TextStyle(
                    fontSize: 15,
                    color: PawmilyaPalette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / _stepTitles.length,
                    minHeight: 7,
                    color: PawmilyaPalette.goldDark,
                    backgroundColor:
                        PawmilyaPalette.cardEdge.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: PawmilyaPalette.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        PawmilyaInputField(
          controller: controller,
          hintText: hint,
          icon: icon,
          keyboardType: keyboardType,
          obscureText: obscureText,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          playful: true,
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    if (_currentStep == 0) {
      return Column(
        key: const ValueKey<int>(0),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLabeledField(
            label: 'Username',
            controller: _usernameController,
            hint: 'Enter your username',
            icon: Icons.person_outline_rounded,
            focusNode: _usernameFocus,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _focusNode(_realNameFocus),
          ),
          const SizedBox(height: 14),
          _buildLabeledField(
            label: 'Full Name',
            controller: _realNameController,
            hint: 'Enter your full name',
            icon: Icons.badge_outlined,
            focusNode: _realNameFocus,
            textInputAction: TextInputAction.done,
            onSubmitted: _submitStepFromKeyboard,
          ),
        ],
      );
    }

    if (_currentStep == 1) {
      return Column(
        key: const ValueKey<int>(1),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLabeledField(
            label: 'Email',
            controller: _emailController,
            hint: 'you@example.com',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            focusNode: _emailFocus,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _focusNode(_numberFocus),
          ),
          const SizedBox(height: 14),
          _buildLabeledField(
            label: 'Mobile Number',
            controller: _numberController,
            hint: 'Enter your contact number',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            focusNode: _numberFocus,
            textInputAction: TextInputAction.done,
            onSubmitted: _submitStepFromKeyboard,
          ),
        ],
      );
    }

    final strengthScore = _passwordStrengthScore(_passwordController.text);
    final strengthColor = _passwordStrengthColor(strengthScore);
    final strengthLabel = _passwordStrengthLabel(strengthScore);
    final confirmPassword = _confirmPasswordController.text.trim();
    final showMismatch =
        confirmPassword.isNotEmpty &&
        _passwordController.text.trim() != confirmPassword;

    return Column(
      key: const ValueKey<int>(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabeledField(
          label: 'Password',
          controller: _passwordController,
          hint: 'Create a secure password',
          icon: Icons.lock_rounded,
          obscureText: true,
          focusNode: _passwordFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _focusNode(_confirmPasswordFocus),
        ),
        const SizedBox(height: 14),
        _buildLabeledField(
          label: 'Confirm Password',
          controller: _confirmPasswordController,
          hint: 'Re-enter your password',
          icon: Icons.lock_outline_rounded,
          obscureText: true,
          focusNode: _confirmPasswordFocus,
          textInputAction: TextInputAction.done,
          onSubmitted: _submitStepFromKeyboard,
        ),
        const SizedBox(height: 10),
        Text(
          'Strength: $strengthLabel',
          style: TextStyle(
            fontSize: 12.5,
            color: strengthColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: strengthScore / 5,
            minHeight: 7,
            color: strengthColor,
            backgroundColor: PawmilyaPalette.cardEdge.withValues(alpha: 0.4),
          ),
        ),
        if (showMismatch) ...[
          const SizedBox(height: 6),
          const Text(
            'Passwords do not match.',
            style: TextStyle(
              color: Color(0xFFB04A3A),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons({
    required bool compact,
    required bool keyboardOpen,
    required bool tightVertical,
  }) {
    PrimaryActionButton buildPrimaryButton() {
      return PrimaryActionButton(
        label: _isSubmitting
            ? 'Creating...'
            : (_currentStep == 2 ? 'Create Account' : 'Continue'),
        icon: _currentStep == 2
            ? Icons.person_add_alt_1_rounded
            : Icons.arrow_forward_rounded,
        colors: const [
          Color(0xFFE6B368),
          Color(0xFFD79647),
          Color(0xFFB97232),
        ],
        onTap: _isSubmitting ? null : _onPrimaryAction,
        scale: _buttonScale.value,
      );
    }

    final secondaryButton = OutlinedButton(
      onPressed: _isSubmitting ? null : _goToPreviousStep,
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
        'Back',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    );

    if (keyboardOpen || _currentStep == 0) {
      return AnimatedBuilder(
        animation: _tapController,
        builder: (context, child) => buildPrimaryButton(),
      );
    }

    if (compact) {
      if (tightVertical) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isSubmitting ? null : _goToPreviousStep,
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: PawmilyaPalette.goldDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedBuilder(
              animation: _tapController,
              builder: (context, child) => buildPrimaryButton(),
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          secondaryButton,
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _tapController,
            builder: (context, child) => buildPrimaryButton(),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 1, child: secondaryButton),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: AnimatedBuilder(
            animation: _tapController,
            builder: (context, child) => buildPrimaryButton(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PawmilyaShell(
      showBackButton: true,
      compactOnKeyboard: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          final keyboardOpen = bottomInset > 0;
          final horizontalPadding = constraints.maxWidth < 380 ? 0.0 : 8.0;
          final compactActions = constraints.maxWidth < 300;
          final tightVertical = constraints.maxHeight < 630 || keyboardOpen;
          final allowsManualScroll = keyboardOpen;
          final compactHeader = constraints.maxHeight < 580 || keyboardOpen;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: SizedBox(
              height: constraints.maxHeight,
              child: LoginCard(
                structured: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: keyboardOpen ? 22 : (compactHeader ? 24 : 27),
                        fontWeight: FontWeight.w700,
                        color: PawmilyaPalette.textPrimary,
                      ),
                    ),
                    if (!compactHeader) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Simple 3-step setup',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: PawmilyaPalette.textSecondary,
                        ),
                      ),
                    ],
                    SizedBox(height: keyboardOpen ? 8 : 14),
                    _buildStepHeader(compact: keyboardOpen),
                    SizedBox(height: keyboardOpen ? 8 : 14),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, animation) {
                          final slide = Tween<Offset>(
                            begin: const Offset(0.03, 0),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: slide,
                              child: child,
                            ),
                          );
                        },
                        child: SingleChildScrollView(
                          key: ValueKey<String>(
                            'user-step-$_currentStep-$allowsManualScroll',
                          ),
                          primary: false,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          physics: allowsManualScroll
                              ? const BouncingScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: _buildStepContent(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: keyboardOpen ? 8 : 14),
                    _buildActionButtons(
                      compact: compactActions,
                      keyboardOpen: keyboardOpen,
                      tightVertical: tightVertical,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}