import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';
import '../widgets/floating_paws_bg.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _entryAnimationDuration = Duration(milliseconds: 700);
  static const Duration _stepSwitchDuration = Duration(milliseconds: 280);
  static const Duration _stepDotDuration = Duration(milliseconds: 240);
  static const Duration _stepLineDuration = Duration(milliseconds: 420);

  late AnimationController _fadeController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0; // 0, 1, 2

  // Step 1: Shelter Info
  final _shelterNameController = TextEditingController();
  final _addressController = TextEditingController();

  // Map state
  final MapController _mapController = MapController();
  final _mapSearchController = TextEditingController();
  LatLng? _markerPosition;
  String? _detectedAddress;
  String? _detectedCoords;
  bool _locationConfirmed = false;
  String? _confirmedAddress;
  bool _showAddressPreview = false;
  bool _isLocating = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _showSearchResults = false;
  Timer? _searchDebounce;

  // Step 2: Contact Info
  final _ownerNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();

  // Step 3: Security
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeTerms = false;

  String? _errorMessage;
  double _passwordStrength = 0;
  String _strengthLabel = '';
  Color _strengthColor = Colors.transparent;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: _entryAnimationDuration,
    );
    _fadeIn = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart),
        );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shelterNameController.dispose();
    _addressController.dispose();
    _mapSearchController.dispose();
    _searchDebounce?.cancel();
    _ownerNameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String value) {
    double strength = 0;
    if (value.length >= 6) strength += 0.2;
    if (value.length >= 10) strength += 0.2;
    if (RegExp(r'[A-Z]').hasMatch(value)) strength += 0.2;
    if (RegExp(r'[0-9]').hasMatch(value)) strength += 0.2;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) strength += 0.2;

    String label;
    Color color;
    if (strength <= 0.2) {
      label = 'Weak';
      color = const Color(0xFFEF4444);
    } else if (strength <= 0.4) {
      label = 'Fair';
      color = const Color(0xFFF97316);
    } else if (strength <= 0.6) {
      label = 'Good';
      color = const Color(0xFFEAB308);
    } else if (strength <= 0.8) {
      label = 'Strong';
      color = const Color(0xFF22C55E);
    } else {
      label = 'Very Strong';
      color = const Color(0xFF16A34A);
    }

    setState(() {
      _passwordStrength = strength;
      _strengthLabel = value.isEmpty ? '' : label;
      _strengthColor = color;
    });
  }

  // ─── MAP & GEOCODING METHODS ────────────────────────
  void _onMapTap(TapPosition tapPosition, LatLng point) {
    _placeMarker(point.latitude, point.longitude);
  }

  void _placeMarker(double lat, double lng) {
    if (_locationConfirmed) {
      setState(() {
        _locationConfirmed = false;
        _confirmedAddress = null;
        _addressController.text = '';
      });
    }
    setState(() {
      _markerPosition = LatLng(lat, lng);
      _showAddressPreview = true;
      _detectedAddress = 'Detecting address...';
      _detectedCoords = '';
    });
    _mapController.move(LatLng(lat, lng), _mapController.camera.zoom);
    _reverseGeocode(lat, lng);
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1',
      );
      final response = await http
          .get(
            uri,
            headers: {
              'Accept-Language': 'en',
              'User-Agent': 'Pawmilya/1.0 (flutter app)',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final addr =
            data['display_name'] ??
            '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
        if (!mounted) return;
        setState(() {
          _detectedAddress = addr;
          _detectedCoords =
              '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
        });
      } else {
        if (!mounted) return;
        setState(() {
          _detectedAddress =
              '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
          _detectedCoords =
              'Address lookup unavailable (code ${response.statusCode}) — coordinates saved.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _detectedAddress =
            '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
        _detectedCoords = 'Could not detect address — coordinates saved.';
      });
    }
  }

  void _confirmLocation() {
    if (_detectedAddress == null ||
        _detectedAddress == 'Detecting address...') {
      return;
    }
    setState(() {
      _locationConfirmed = true;
      _confirmedAddress = _detectedAddress;
      _showAddressPreview = false;
      _addressController.text = _detectedAddress!;
    });
  }

  void _resetLocation() {
    setState(() {
      _locationConfirmed = false;
      _confirmedAddress = null;
      _markerPosition = null;
      _showAddressPreview = false;
      _detectedAddress = null;
      _detectedCoords = null;
      _addressController.text = '';
    });
  }

  Future<void> _locateMe() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() => _isLocating = false);
        if (mounted) {
          setState(
            () =>
                _errorMessage = 'Location access denied. Tap the map manually.',
          );
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _mapController.move(LatLng(position.latitude, position.longitude), 16);
      _placeMarker(position.latitude, position.longitude);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Could not get location. Tap the map manually.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 3) {
      setState(() => _showSearchResults = false);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query.trim())}&format=json&limit=5&addressdetails=1',
        );
        final response = await http.get(
          uri,
          headers: {'Accept-Language': 'en'},
        );
        if (response.statusCode == 200) {
          final List results = json.decode(response.body);
          if (mounted) {
            setState(() {
              _searchResults = results.cast<Map<String, dynamic>>();
              _showSearchResults = results.isNotEmpty;
            });
          }
        }
      } catch (_) {
        if (mounted) setState(() => _showSearchResults = false);
      }
    });
  }

  void _pickSearchResult(double lat, double lng) {
    setState(() {
      _showSearchResults = false;
      _mapSearchController.clear();
    });
    _mapController.move(LatLng(lat, lng), 17);
    _placeMarker(lat, lng);
  }

  bool _validateCurrentStep() {
    setState(() => _errorMessage = null);
    switch (_currentStep) {
      case 0:
        if (_shelterNameController.text.trim().isEmpty) {
          setState(() => _errorMessage = 'Please enter shelter name');
          return false;
        }
        if (!_locationConfirmed) {
          setState(
            () => _errorMessage =
                'Please select and confirm shelter location on the map',
          );
          return false;
        }
        return true;
      case 1:
        if (_ownerNameController.text.trim().isEmpty) {
          setState(() => _errorMessage = 'Please enter owner/manager name');
          return false;
        }
        if (_contactController.text.trim().isEmpty) {
          setState(() => _errorMessage = 'Please enter contact number');
          return false;
        }
        if (_emailController.text.trim().isEmpty ||
            !RegExp(
              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
            ).hasMatch(_emailController.text.trim())) {
          setState(() => _errorMessage = 'Please enter a valid email');
          return false;
        }
        return true;
      case 2:
        if (_passwordController.text.length < 6) {
          setState(
            () => _errorMessage = 'Password must be at least 6 characters',
          );
          return false;
        }
        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() => _errorMessage = 'Passwords do not match');
          return false;
        }
        if (!_agreeTerms) {
          setState(
            () => _errorMessage = 'Please agree to Terms and Privacy Policy',
          );
          return false;
        }
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < 2) {
        setState(() {
          _currentStep++;
          _errorMessage = null;
        });
      } else {
        _onRegister();
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _errorMessage = null;
      });
    }
  }

  Future<void> _onRegister() async {
    if (_isSubmitting) return;

    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      final user = credential.user;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('shelter_users')
            .doc(user.uid)
            .set({
              'uid': user.uid,
              'shelterName': _shelterNameController.text.trim(),
              'ownerName': _ownerNameController.text.trim(),
              'contact': _contactController.text.trim(),
              'email': _emailController.text.trim(),
              'address': _confirmedAddress ?? _addressController.text.trim(),
              'lat': _markerPosition?.latitude,
              'lng': _markerPosition?.longitude,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      String message;
      switch (error.code) {
        case 'email-already-in-use':
          message = 'This email is already registered.';
          break;
        case 'invalid-email':
          message = 'Invalid email format.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Use a stronger password.';
          break;
        default:
          message = error.message ?? 'Registration failed. Please try again.';
      }

      if (!mounted) return;
      setState(() => _errorMessage = message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage = 'Registration failed. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBg,
      body: Stack(
        children: [
          const FloatingPawsBackground(),
          SafeArea(
            child: Column(
              children: [
                // ─── Top bar ───
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        elevation: 1,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          splashColor: AppColors.primary.withValues(alpha: 0.12),
                          highlightColor: AppColors.primary.withValues(
                            alpha: 0.06,
                          ),
                          onTap: () => _currentStep > 0
                              ? _prevStep()
                              : Navigator.of(context).pop(),
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Center(
                              child: FaIcon(
                                FontAwesomeIcons.arrowLeft,
                                size: 16,
                                color: AppColors.textMid,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.paw,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Pawmilya',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.quicksand(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // ─── Signup card ───
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: SlideTransition(
                          position: _slideUp,
                          child: _buildSignupCard(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupCard() {
    final isCompact = MediaQuery.of(context).size.width < 360;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 18 : 24,
        vertical: isCompact ? 24 : 32,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.10),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.06)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Icon header ───
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.houseChimney,
                size: 26,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Register Your Shelter',
            style: GoogleFonts.quicksand(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Set up your shelter on the Pawmilya platform',
            style: GoogleFonts.quicksand(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),

          // ─── Step indicators ───
          _buildStepIndicator(),
          const SizedBox(height: 24),

          // ─── Step content ───
          Form(
            key: _formKey,
            child: AnimatedSwitcher(
              duration: _stepSwitchDuration,
              layoutBuilder: (currentChild, previousChildren) {
                return currentChild ?? const SizedBox.shrink();
              },
              child: _buildCurrentStep(),
            ),
          ),

          // ─── Error message ───
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.circleExclamation,
                    size: 14,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // ─── Navigation buttons ───
          _buildNavigationButtons(),

          const SizedBox(height: 24),

          // ─── Login link ───
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 2,
            runSpacing: 2,
            children: [
              Text(
                'Already registered your shelter?',
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  splashColor: AppColors.primary.withValues(alpha: 0.12),
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(
                      'Log In',
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── STEP INDICATOR ───────────────────────────────────
  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepDot(0, 'Shelter'),
        _buildStepLine(0),
        _buildStepDot(1, 'Contact'),
        _buildStepLine(1),
        _buildStepDot(2, 'Security'),
      ],
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: _stepDotDuration,
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.1),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                '${step + 1}',
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.quicksand(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isActive ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isComplete = _currentStep > afterStep;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 2,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0,
                    end: isComplete ? 1 : 0,
                  ),
                  duration: _stepLineDuration,
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Container(
                      height: 2,
                      width: constraints.maxWidth * value,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── STEP CONTENT ─────────────────────────────────────
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1(key: const ValueKey(0));
      case 1:
        return _buildStep2(key: const ValueKey(1));
      case 2:
        return _buildStep3(key: const ValueKey(2));
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 1: Shelter Info with Map Picker
  Widget _buildStep1({Key? key}) {
    return Column(
      key: key,
      children: [
        _buildLabel('Shelter Name'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _shelterNameController,
          hint: 'Happy Paws Animal Shelter',
          icon: FontAwesomeIcons.houseChimney,
        ),
        const SizedBox(height: 18),
        _buildLabel('Shelter Location'),
        const SizedBox(height: 8),

        // ── Search bar ──
        Stack(
          clipBehavior: Clip.none,
          children: [
            TextFormField(
              controller: _mapSearchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              decoration: InputDecoration(
                hintText: 'Search for a place or address...',
                hintStyle: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: FaIcon(
                    FontAwesomeIcons.magnifyingGlass,
                    size: 16,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                suffixIcon: _mapSearchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _mapSearchController.clear();
                          setState(() => _showSearchResults = false);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: FaIcon(
                            FontAwesomeIcons.xmark,
                            size: 16,
                            color: AppColors.textMuted.withValues(alpha: 0.4),
                          ),
                        ),
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                filled: true,
                fillColor: AppColors.warmBg.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            // Search results dropdown
            if (_showSearchResults)
              Positioned(
                left: 0,
                right: 0,
                top: 52,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  shadowColor: AppColors.textDark.withValues(alpha: 0.12),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.08),
                      ),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(6),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final r = _searchResults[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _pickSearchResult(
                            double.parse(r['lat']),
                            double.parse(r['lon']),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.locationDot,
                                  size: 12,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    r['display_name'] ?? '',
                                    style: GoogleFonts.quicksand(
                                      fontSize: 13,
                                      color: AppColors.textDark,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Map ──
        Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.textDark.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(
                    14.5995,
                    120.9842,
                  ), // Manila default
                  initialZoom: 12,
                  onTap: _onMapTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.pawmilya.app',
                  ),
                  if (_markerPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _markerPosition!,
                          width: 42,
                          height: 42,
                          child: const _PawMarker(),
                        ),
                      ],
                    ),
                ],
              ),
              // Zoom controls
              Positioned(
                top: 10,
                right: 10,
                child: Column(
                  children: [
                    _mapZoomButton(FontAwesomeIcons.plus, () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom + 1,
                      );
                    }),
                    const SizedBox(height: 6),
                    _mapZoomButton(FontAwesomeIcons.minus, () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom - 1,
                      );
                    }),
                  ],
                ),
              ),
              // Locate me button
              Positioned(
                bottom: 10,
                right: 10,
                child: GestureDetector(
                  onTap: _isLocating ? null : _locateMe,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textDark.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isLocating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const FaIcon(
                                FontAwesomeIcons.crosshairs,
                                size: 14,
                                color: AppColors.textMid,
                              ),
                        const SizedBox(width: 6),
                        Text(
                          'Locate me',
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMid,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Hint overlay (before first tap)
              if (_markerPosition == null && !_locationConfirmed)
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 290),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textDark.withValues(alpha: 0.08),
                          blurRadius: 12,
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.handPointer,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tap the map to place your shelter pin',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.quicksand(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMid,
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

        // ── Address preview panel ──
        if (_showAddressPreview && !_locationConfirmed)
          Container(
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textDark.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: FaIcon(
                            FontAwesomeIcons.locationDot,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DETECTED ADDRESS',
                              style: GoogleFonts.quicksand(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMuted,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _detectedAddress ?? 'Loading...',
                              style: GoogleFonts.quicksand(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            if (_detectedCoords != null &&
                                _detectedCoords!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  _detectedCoords!,
                                  style: GoogleFonts.quicksand(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Confirm button
                GestureDetector(
                  onTap: _confirmLocation,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      border: Border(
                        top: BorderSide(
                          color: const Color(
                            0xFF22C55E,
                          ).withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.circleCheck,
                          size: 14,
                          color: Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Confirm This Location',
                          style: GoogleFonts.quicksand(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ── Confirmed badge ──
        if (_locationConfirmed && _confirmedAddress != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _confirmedAddress!,
                        style: GoogleFonts.quicksand(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _resetLocation,
                        child: Text(
                          'Change location',
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF22C55E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _mapZoomButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: FaIcon(icon, size: 12, color: AppColors.textMid)),
      ),
    );
  }

  // Step 2: Contact Info
  Widget _buildStep2({Key? key}) {
    return Column(
      key: key,
      children: [
        _buildLabel('Owner / Manager Name'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _ownerNameController,
          hint: 'Juan Dela Cruz',
          icon: FontAwesomeIcons.user,
        ),
        const SizedBox(height: 18),
        _buildLabel('Contact Number'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _contactController,
          hint: '09171234567',
          icon: FontAwesomeIcons.phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 18),
        _buildLabel('Email Address'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _emailController,
          hint: 'shelter@example.com',
          icon: FontAwesomeIcons.envelope,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  // Step 3: Security
  Widget _buildStep3({Key? key}) {
    return Column(
      key: key,
      children: [
        _buildLabel('Password'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _passwordController,
          hint: 'Create a strong password',
          icon: FontAwesomeIcons.lock,
          obscure: _obscurePassword,
          onChanged: _checkPasswordStrength,
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: FaIcon(
                _obscurePassword
                    ? FontAwesomeIcons.eye
                    : FontAwesomeIcons.eyeSlash,
                size: 16,
                color: AppColors.textMuted.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        // Password strength bar
        if (_strengthLabel.isNotEmpty) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _passwordStrength,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _strengthLabel,
              style: GoogleFonts.quicksand(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _strengthColor,
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        _buildLabel('Confirm Password'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _confirmPasswordController,
          hint: 'Re-enter your password',
          icon: FontAwesomeIcons.lock,
          obscure: _obscureConfirm,
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: FaIcon(
                _obscureConfirm
                    ? FontAwesomeIcons.eye
                    : FontAwesomeIcons.eyeSlash,
                size: 16,
                color: AppColors.textMuted.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        // Terms checkbox
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _agreeTerms,
                onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── NAVIGATION BUTTONS ───────────────────────────────
  Widget _buildNavigationButtons() {
    return Row(
      children: [
        // Back button (hidden on step 1)
        if (_currentStep > 0)
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  overlayColor: AppColors.primary.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.arrowLeft,
                        size: 12,
                        color: AppColors.textMid,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Back',
                        maxLines: 1,
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMid,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        // Next / Register button
        Expanded(
          child: SizedBox(
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  overlayColor: Colors.white.withValues(alpha: 0.14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 145;
                    final showTrailingArrow = _currentStep < 2 && !isCompact;
                    final showRegisterIcon =
                        _currentStep == 2 && !_isSubmitting && !isCompact;
                    final spacing = isCompact ? 6.0 : 8.0;
                    final label = _isSubmitting
                        ? (isCompact ? 'Please wait' : 'Please wait...')
                        : _currentStep == 2
                        ? (isCompact ? 'Register' : 'Register Shelter')
                        : 'Continue';

                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isSubmitting)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          if (showRegisterIcon)
                            const FaIcon(
                              FontAwesomeIcons.houseChimneyMedical,
                              size: 14,
                              color: Colors.white,
                            ),
                          if (_isSubmitting || showRegisterIcon)
                            SizedBox(width: spacing),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.quicksand(
                              fontSize: isCompact ? 13 : 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (showTrailingArrow) SizedBox(width: spacing),
                          if (showTrailingArrow)
                            const FaIcon(
                              FontAwesomeIcons.arrowRight,
                              size: 12,
                              color: Colors.white,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── SHARED WIDGETS ───────────────────────────────────
  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.quicksand(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    int maxLines = 1,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLines: obscure ? 1 : maxLines,
      onChanged: onChanged,
      style: GoogleFonts.quicksand(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.quicksand(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted.withValues(alpha: 0.4),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 12),
          child: FaIcon(
            icon,
            size: 16,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffixIcon,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: AppColors.warmBg.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
      ),
    );
  }
}

/// Custom paw-shaped map marker matching the website's custom-marker-icon
class _PawMarker extends StatelessWidget {
  const _PawMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: FaIcon(FontAwesomeIcons.paw, size: 18, color: Colors.white),
      ),
    );
  }
}