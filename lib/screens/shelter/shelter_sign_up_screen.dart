import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../services/auth_service.dart';
import '../../theme/pawmilya_palette.dart';
import '../../widgets/login_card.dart';
import '../../widgets/pawmilya_input_field.dart';
import '../../widgets/pawmilya_shell.dart';
import '../../widgets/primary_action_button.dart';

class ShelterSignUpScreen extends StatefulWidget {
  const ShelterSignUpScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ShelterSignUpScreen> createState() => _ShelterSignUpScreenState();
}

class _ShelterSignUpScreenState extends State<ShelterSignUpScreen>
    with SingleTickerProviderStateMixin {
  static const _stepTitles = [
    'Basic',
    'Address',
    'Contact',
    'Admin',
    'Facility',
    'Security',
  ];
  static const _organizationTypes = [
    'NGO',
    'Foundation',
    'City Pound',
    'Private Rescue',
    'Government Shelter',
    'Other',
  ];

  static const _animalTypesOptions = [
    'Dogs',
    'Cats',
    'Birds',
    'Small Mammals',
    'Reptiles',
  ];
  static const _operatingHoursOptions = [
    'Mon-Fri 8am-5pm',
    '24/7',
    'Weekends Only',
    'Appointments Only',
  ];
  static const _servicesOptions = [
    'Rescue',
    'Adoption',
    'Veterinary Care',
    'Fostering',
    'Rehabilitation',
    'Grooming',
    'Boarding',
  ];

  // Basic
  final _shelterNameCtrl = TextEditingController();
  final _regNumberCtrl = TextEditingController();
  final _yearEstablishedCtrl = TextEditingController();
  String? _selectedOrgType;

  // Address
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();
  LatLng? _pickedCoordinates;
  String _googleMapsUrl = '';
  bool _isResolvingAddress = false;
  DateTime? _lastGeocodeRequestAt;
  LatLng? _lastResolvedPoint;
  String _lastResolvedAddress = '';
  String _lastResolvedCity = '';
  String _lastResolvedPostalCode = '';

  // Contact
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _altContactCtrl = TextEditingController();
  final _websiteUrlCtrl = TextEditingController();

  // Admin
  final _adminNameCtrl = TextEditingController();
  final _adminRoleCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();

  // Facility
  final List<String> _selectedAnimalTypes = [];
  String? _selectedOperatingHours;
  final List<String> _selectedServices = [];

  // Security
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  final _shelterNameFocus = FocusNode();
  final _orgTypeFocus = FocusNode();
  final _regNumberFocus = FocusNode();
  final _yearEstablishedFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _cityFocus = FocusNode();
  final _postalCodeFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _altContactFocus = FocusNode();
  final _websiteUrlFocus = FocusNode();
  final _adminNameFocus = FocusNode();
  final _adminRoleFocus = FocusNode();
  final _capacityFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPassFocus = FocusNode();

  bool _agreeToTerms = false;

  late final AnimationController _tapController;
  late final Animation<double> _buttonScale;

  int _currentStep = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final prefilledEmail = widget.initialEmail.trim();
    if (prefilledEmail.isNotEmpty) {
      _emailCtrl.text = prefilledEmail;
    }

    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _buttonScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0.97,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.97,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 55,
      ),
    ]).animate(_tapController);
  }

  @override
  void dispose() {
    _shelterNameCtrl.dispose();
    _regNumberCtrl.dispose();
    _yearEstablishedCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _postalCodeCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _altContactCtrl.dispose();
    _websiteUrlCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminRoleCtrl.dispose();
    _capacityCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();

    _shelterNameFocus.dispose();
    _regNumberFocus.dispose();
    _yearEstablishedFocus.dispose();
    _orgTypeFocus.dispose();
    _addressFocus.dispose();
    _cityFocus.dispose();
    _postalCodeFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _altContactFocus.dispose();
    _websiteUrlFocus.dispose();
    _adminNameFocus.dispose();
    _adminRoleFocus.dispose();
    _capacityFocus.dispose();
    _passwordFocus.dispose();
    _confirmPassFocus.dispose();

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
        _focusNode(_shelterNameFocus);
        break;
      case 1:
        _focusNode(_addressFocus);
        break;
      case 2:
        _focusNode(_emailFocus);
        break;
      case 3:
        _focusNode(_adminNameFocus);
        break;
      case 4:
        break;
      case 5:
        _focusNode(_passwordFocus);
        break;
    }
  }

  void _submitStepFromKeyboard(String _) {
    FocusScope.of(context).unfocus();
    _onPrimaryAction();
  }

  bool _looksLikeEmail(String value) {
    final normalized = value.trim();
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized);
  }

  bool _looksLikePhoneNumber(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    return digitsOnly.length >= 7;
  }

  bool _isPositiveInteger(String value) {
    final parsed = int.tryParse(value.trim());
    return parsed != null && parsed > 0;
  }

  bool _isApproximatelySamePoint(LatLng a, LatLng b) {
    const tolerance = 0.00015;
    return (a.latitude - b.latitude).abs() <= tolerance &&
        (a.longitude - b.longitude).abs() <= tolerance;
  }

  bool _isLikelyInPhilippines(LatLng point) {
    return point.latitude >= 4.2 &&
        point.latitude <= 21.5 &&
        point.longitude >= 116.7 &&
        point.longitude <= 126.8;
  }

  String _buildGoogleMapsUrl(LatLng point) {
    return 'https://www.google.com/maps/search/?api=1&query=${point.latitude},${point.longitude}';
  }

  Future<void> _openMapPicker() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _MapPickerSheet(initialValue: _pickedCoordinates);
      },
    );

    if (!mounted || picked == null) {
      return;
    }

    if (!_isLikelyInPhilippines(picked)) {
      _showMessage(
        'Please pick a location inside the Philippines.',
        isError: true,
      );
      return;
    }

    setState(() {
      _pickedCoordinates = picked;
      _googleMapsUrl = _buildGoogleMapsUrl(picked);
    });
    await _autoFillAddressFromPin(picked);
  }

  Future<void> _autoFillAddressFromPin(LatLng point) async {
    final now = DateTime.now();
    final lastRequest = _lastGeocodeRequestAt;
    if (lastRequest != null &&
        now.difference(lastRequest) < const Duration(seconds: 2)) {
      _showMessage(
        'Please wait before requesting another address lookup.',
        isError: true,
      );
      return;
    }

    final cachedPoint = _lastResolvedPoint;
    if (cachedPoint != null && _isApproximatelySamePoint(cachedPoint, point)) {
      if (mounted) {
        setState(() {
          if (_lastResolvedAddress.isNotEmpty) {
            _addressCtrl.text = _lastResolvedAddress;
          }
          if (_lastResolvedCity.isNotEmpty) {
            _cityCtrl.text = _lastResolvedCity;
          }
          if (_lastResolvedPostalCode.isNotEmpty) {
            _postalCodeCtrl.text = _lastResolvedPostalCode;
          }
        });
      }
      _showMessage('Using cached address for this location.', isError: false);
      return;
    }

    if (mounted) {
      setState(() {
        _isResolvingAddress = true;
      });
    }
    _lastGeocodeRequestAt = now;

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': point.latitude.toString(),
        'lon': point.longitude.toString(),
        'addressdetails': '1',
      });

      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'Pawmilya/1.0 (shelter-signup)',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        if (mounted) {
          _showMessage(
            'Location pin saved. Address lookup failed.',
            isError: true,
          );
        }
        return;
      }

      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) {
        if (mounted) {
          _showMessage(
            'Location pin saved. Could not parse address.',
            isError: true,
          );
        }
        return;
      }

      final address = payload['address'];
      final addressData = address is Map<String, dynamic>
          ? address
          : <String, dynamic>{};
      final countryCode = (addressData['country_code'] ?? '')
          .toString()
          .toLowerCase();

      if (countryCode != 'ph') {
        if (mounted) {
          _showMessage('Only Philippine addresses are allowed.', isError: true);
        }
        return;
      }

      final road = (addressData['road'] ?? '').toString().trim();
      final houseNumber = (addressData['house_number'] ?? '').toString().trim();
      final suburb =
          (addressData['suburb'] ?? addressData['neighbourhood'] ?? '')
              .toString()
              .trim();

      final streetPieces = <String>[
        if (houseNumber.isNotEmpty) houseNumber,
        if (road.isNotEmpty) road,
        if (suburb.isNotEmpty) suburb,
      ];

      final displayName = (payload['display_name'] ?? '').toString().trim();
      final resolvedAddress = streetPieces.isNotEmpty
          ? streetPieces.join(', ')
          : (displayName.isNotEmpty
                ? displayName.split(',').take(3).join(', ').trim()
                : '');

      final resolvedCity =
          (addressData['city'] ??
                  addressData['town'] ??
                  addressData['municipality'] ??
                  addressData['village'] ??
                  addressData['county'] ??
                  addressData['state'] ??
                  '')
              .toString()
              .trim();

      final resolvedPostalCode = (addressData['postcode'] ?? '').toString().trim();

      _lastResolvedPoint = point;
      _lastResolvedAddress = resolvedAddress;
      _lastResolvedCity = resolvedCity;
      _lastResolvedPostalCode = resolvedPostalCode;

      if (mounted) {
        setState(() {
          if (resolvedAddress.isNotEmpty) {
            _addressCtrl.text = resolvedAddress;
          }
          if (resolvedCity.isNotEmpty) {
            _cityCtrl.text = resolvedCity;
          }
          if (resolvedPostalCode.isNotEmpty) {
            _postalCodeCtrl.text = resolvedPostalCode;
          }
        });

        if (resolvedAddress.isEmpty && resolvedCity.isEmpty) {
          _showMessage(
            'Location pin saved. Enter address details manually.',
            isError: true,
          );
        } else {
          _showMessage(
            'Location pin saved and address auto-filled.',
            isError: false,
          );
        }
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Location pin saved. Address lookup unavailable.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingAddress = false;
        });
      }
    }
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

  bool _validateStep() {
    switch (_currentStep) {
      case 0:
        if (_shelterNameCtrl.text.trim().isEmpty) {
          _showMessage('Shelter name is required.', isError: true);
          return false;
        }
        if (_selectedOrgType == null || _selectedOrgType!.trim().isEmpty) {
          _showMessage('Organization type is required.', isError: true);
          return false;
        }
        if (_regNumberCtrl.text.trim().isEmpty) {
          _showMessage('Registration number is required.', isError: true);
          return false;
        }
        return true;
      case 1:
        if (_addressCtrl.text.trim().isEmpty || _cityCtrl.text.trim().isEmpty) {
          _showMessage('Address and city are required.', isError: true);
          return false;
        }
        if (_pickedCoordinates == null || _googleMapsUrl.trim().isEmpty) {
          _showMessage(
            'Please pin your shelter location on the map.',
            isError: true,
          );
          return false;
        }
        return true;
      case 2:
        if (_emailCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
          _showMessage('Email and phone are required.', isError: true);
          return false;
        }
        if (!_looksLikeEmail(_emailCtrl.text)) {
          _showMessage('Please enter a valid email address.', isError: true);
          return false;
        }
        if (!_looksLikePhoneNumber(_phoneCtrl.text)) {
          _showMessage('Please enter a valid phone number.', isError: true);
          return false;
        }
        return true;
      case 3:
        if (_adminNameCtrl.text.trim().isEmpty ||
            _adminRoleCtrl.text.trim().isEmpty ||
            _capacityCtrl.text.trim().isEmpty) {
          _showMessage(
            'Admin name, role, and capacity are required.',
            isError: true,
          );
          return false;
        }
        if (!_isPositiveInteger(_capacityCtrl.text)) {
          _showMessage('Capacity must be a positive number.', isError: true);
          return false;
        }
        return true;
      case 4:
        if (_selectedAnimalTypes.isEmpty) {
          _showMessage('Please select at least one animal type.', isError: true);
          return false;
        }
        if (_selectedOperatingHours == null || _selectedOperatingHours!.isEmpty) {
          _showMessage('Please select operating hours.', isError: true);
          return false;
        }
        if (_selectedServices.isEmpty) {
          _showMessage('Please select at least one service offered.', isError: true);
          return false;
        }
        return true;
      case 5:
        final password = _passwordCtrl.text.trim();
        final confirmPassword = _confirmPassCtrl.text.trim();

        if (password.isEmpty) {
          _showMessage('Password is required.', isError: true);
          return false;
        }
        if (password.length < 8) {
          _showMessage(
            'Password must be at least 8 characters.',
            isError: true,
          );
          return false;
        }
        if (password != confirmPassword) {
          _showMessage('Passwords do not match.', isError: true);
          return false;
        }
        if (!_agreeToTerms) {
          _showMessage('You must agree before continuing.', isError: true);
          return false;
        }
        return true;
      default:
        return false;
    }
  }

  Future<void> _onPrimaryAction() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();
    if (!_validateStep()) {
      return;
    }

    if (_currentStep < _stepTitles.length - 1) {
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

    setState(() => _isSubmitting = true);
    _tapController.forward(from: 0);

    try {
      await AuthService.instance.createShelterAccount(
        shelterName: _shelterNameCtrl.text.trim(),
        organizationType: _selectedOrgType ?? '',
        registrationNumber: _regNumberCtrl.text.trim(),
        yearEstablished: _yearEstablishedCtrl.text.trim(),
        fullAddress: _addressCtrl.text.trim(),
        cityProvince: _cityCtrl.text.trim(),
        postalCode: _postalCodeCtrl.text.trim(),
        googleMapsUrl: _googleMapsUrl,
        email: _emailCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        alternateContact: _altContactCtrl.text.trim(),
        websiteUrl: _websiteUrlCtrl.text.trim(),
        username: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        adminFullName: _adminNameCtrl.text.trim(),
        adminRole: _adminRoleCtrl.text.trim(),
        animalTypesAccepted: _selectedAnimalTypes.join(', '),
        capacity: _capacityCtrl.text.trim(),
        servicesOffered: _selectedServices.join(', '),
        operatingHours: _selectedOperatingHours ?? '',
      );

      if (!mounted) {
        return;
      }
      
      // Sign out since the account needs verification first
      await AuthService.instance.signOut();
      
      if (!mounted) {
        return;
      }

      _showMessage('Shelter registered. Pending verification.', isError: false);
      
      // Go back to login screen 
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        _showMessage(AuthService.instance.mapError(e), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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
                    backgroundColor: PawmilyaPalette.cardEdge.withValues(
                      alpha: 0.45,
                    ),
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

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    FocusNode? focusNode,
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
        DropdownButtonFormField<String>(
          initialValue: value,
          focusNode: focusNode,
          isExpanded: true,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          menuMaxHeight: 260,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: PawmilyaPalette.goldDark,
          ),
          style: const TextStyle(
            color: PawmilyaPalette.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: PawmilyaPalette.textSecondary.withValues(alpha: 0.75),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.93),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            prefixIcon: Icon(icon, color: PawmilyaPalette.goldDark),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide(
                color: PawmilyaPalette.cardEdge.withValues(alpha: 0.85),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(
                color: PawmilyaPalette.goldDark,
                width: 1.4,
              ),
            ),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: _isSubmitting ? null : onChanged,
        ),
      ],
    );
  }

  Widget _buildMultiSelect({
    required String label,
    required List<String> options,
    required List<String> selected,
    required ValueChanged<String> onChanged,
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
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: _isSubmitting ? null : (_) => onChanged(option),
              selectedColor: PawmilyaPalette.gold.withValues(alpha: 0.3),
              checkmarkColor: PawmilyaPalette.goldDark,
              backgroundColor: Colors.white.withValues(alpha: 0.7),
              side: BorderSide(
                color: isSelected ? PawmilyaPalette.goldDark : PawmilyaPalette.cardEdge,
                width: isSelected ? 1.5 : 1,
              ),
              labelStyle: TextStyle(
                color: isSelected ? PawmilyaPalette.goldDark : PawmilyaPalette.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStepContent({required bool compactFields}) {
    if (_currentStep == 0) {
      return Column(
        key: const ValueKey<int>(0),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLabeledField(
            label: 'Shelter Name',
            controller: _shelterNameCtrl,
            hint: 'Enter shelter name',
            icon: Icons.pets_rounded,
            focusNode: _shelterNameFocus,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _focusNode(_orgTypeFocus),
          ),
          const SizedBox(height: 14),
          _buildDropdownField(
            label: 'Organization Type',
            hint: 'Select organization type',
            icon: Icons.category_rounded,
            value: _selectedOrgType,
            items: _organizationTypes,
            focusNode: _orgTypeFocus,
            onChanged: (value) {
              setState(() {
                _selectedOrgType = value;
              });
            },
          ),
          const SizedBox(height: 14),
          _buildLabeledField(
            label: 'Registration Number',
            controller: _regNumberCtrl,
            hint: 'Enter SEC, TIN, or Permit number',
            icon: Icons.badge_rounded,
            focusNode: _regNumberFocus,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _focusNode(_yearEstablishedFocus),
          ),
          const SizedBox(height: 14),
          _buildLabeledField(
            label: 'Year Established',
            controller: _yearEstablishedCtrl,
            hint: 'e.g. 2015',
            icon: Icons.calendar_today_rounded,
            keyboardType: TextInputType.number,
            focusNode: _yearEstablishedFocus,
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
            label: 'Full Address',
            controller: _addressCtrl,
            hint: 'Street, barangay, and details',
            icon: Icons.location_on_rounded,
            focusNode: _addressFocus,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _focusNode(_cityFocus),
          ),
          const SizedBox(height: 14),
          _buildLabeledField(
            label: 'City / Province',
            controller: _cityCtrl,
            hint: 'Enter city or municipality',
            icon: Icons.location_city_rounded,
            focusNode: _cityFocus,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _focusNode(_postalCodeFocus),
          ),
          const SizedBox(height: 14),
          _buildLabeledField(
            label: 'Postal Code',
            controller: _postalCodeCtrl,
            hint: 'e.g. 1000',
            icon: Icons.markunread_mailbox_rounded,
            keyboardType: TextInputType.number,
            focusNode: _postalCodeFocus,
            textInputAction: TextInputAction.done,
            onSubmitted: _submitStepFromKeyboard,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: (_isSubmitting || _isResolvingAddress)
                    ? null
                    : _openMapPicker,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: PawmilyaPalette.goldDark.withValues(alpha: 0.75),
                  ),
                  foregroundColor: PawmilyaPalette.goldDark,
                ),
                icon: const Icon(Icons.map_rounded),
                label: Text(
                  _pickedCoordinates == null ? 'Pick on Map' : 'Update Map Pin',
                ),
              ),
            ],
          ),
          if (_pickedCoordinates != null) ...[
            const SizedBox(height: 8),
            Text(
              'Pinned: ${_pickedCoordinates!.latitude.toStringAsFixed(5)}, ${_pickedCoordinates!.longitude.toStringAsFixed(5)}',
              style: const TextStyle(
                fontSize: 12,
                color: PawmilyaPalette.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (_isResolvingAddress) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: PawmilyaPalette.goldDark,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Fetching address from selected pin...',
                  style: TextStyle(
                    fontSize: 12,
                    color: PawmilyaPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }

    if (_currentStep == 2) {
      return Column(
        key: const ValueKey<int>(2),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLabeledField(
            label: 'Contact Email',
            controller: _emailCtrl,
            hint: 'shelter@email.com',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            focusNode: _emailFocus,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _focusNode(_phoneFocus),
          ),
          const SizedBox(height: 14),
          _buildLabeledField(
            label: 'Phone Number',
            controller: _phoneCtrl,
            hint: 'Primary contact number',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            focusNode: _phoneFocus,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _focusNode(_altContactFocus),
          ),
          const SizedBox(height: 14),
          _buildLabeledField(
            label: 'Alternate Contact',
            controller: _altContactCtrl,
            hint: 'Secondary phone or email (optional)',
            icon: Icons.contact_phone_rounded,
            keyboardType: TextInputType.text,
            focusNode: _altContactFocus,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _focusNode(_websiteUrlFocus),
          ),
          const SizedBox(height: 14),
          _buildLabeledField(
            label: 'Website / Social Media',
            controller: _websiteUrlCtrl,
            hint: 'URL of your platform (optional)',
            icon: Icons.language_rounded,
            keyboardType: TextInputType.url,
            focusNode: _websiteUrlFocus,
            textInputAction: TextInputAction.done,
            onSubmitted: _submitStepFromKeyboard,
          ),
        ],
      );
    }

    if (_currentStep == 3) {
      return Column(
        key: const ValueKey<int>(3),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLabeledField(
            label: 'Admin Full Name',
            controller: _adminNameCtrl,
            hint: 'Person in charge',
            icon: Icons.person_rounded,
            focusNode: _adminNameFocus,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _focusNode(_adminRoleFocus),
          ),
          const SizedBox(height: 14),
          if (compactFields) ...[
            _buildLabeledField(
              label: 'Admin Role',
              controller: _adminRoleCtrl,
              hint: 'Manager, Director, Coordinator...',
              icon: Icons.badge_rounded,
              focusNode: _adminRoleFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _focusNode(_capacityFocus),
            ),
            const SizedBox(height: 14),
            _buildLabeledField(
              label: 'Capacity',
              controller: _capacityCtrl,
              hint: 'Maximum number of animals',
              icon: Icons.warehouse_rounded,
              keyboardType: TextInputType.number,
              focusNode: _capacityFocus,
              textInputAction: TextInputAction.done,
              onSubmitted: _submitStepFromKeyboard,
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildLabeledField(
                    label: 'Admin Role',
                    controller: _adminRoleCtrl,
                    hint: 'Manager, Director...',
                    icon: Icons.badge_rounded,
                    focusNode: _adminRoleFocus,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _focusNode(_capacityFocus),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildLabeledField(
                    label: 'Capacity',
                    controller: _capacityCtrl,
                    hint: 'Max animals',
                    icon: Icons.warehouse_rounded,
                    keyboardType: TextInputType.number,
                    focusNode: _capacityFocus,
                    textInputAction: TextInputAction.done,
                    onSubmitted: _submitStepFromKeyboard,
                  ),
                ),
              ],
            ),
        ],
      );
    }

    if (_currentStep == 4) {
      return Column(
        key: const ValueKey<int>(4),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMultiSelect(
            label: 'Animal Types Accepted',
            options: _animalTypesOptions,
            selected: _selectedAnimalTypes,
            onChanged: (val) => setState(() {
              if (_selectedAnimalTypes.contains(val)) {
                _selectedAnimalTypes.remove(val);
              } else {
                _selectedAnimalTypes.add(val);
              }
            }),
          ),
          const SizedBox(height: 14),
          _buildDropdownField(
            label: 'Operating Hours',
            hint: 'Select operating hours',
            icon: Icons.access_time_rounded,
            value: _selectedOperatingHours,
            items: _operatingHoursOptions,
            onChanged: (val) => setState(() => _selectedOperatingHours = val),
          ),
          const SizedBox(height: 14),
          _buildMultiSelect(
            label: 'Services Offered',
            options: _servicesOptions,
            selected: _selectedServices,
            onChanged: (val) => setState(() {
              if (_selectedServices.contains(val)) {
                _selectedServices.remove(val);
              } else {
                _selectedServices.add(val);
              }
            }),
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey<int>(5),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabeledField(
          label: 'Password',
          controller: _passwordCtrl,
          hint: 'At least 8 characters',
          icon: Icons.lock_rounded,
          obscureText: true,
          focusNode: _passwordFocus,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _focusNode(_confirmPassFocus),
        ),
        const SizedBox(height: 14),
        _buildLabeledField(
          label: 'Confirm Password',
          controller: _confirmPassCtrl,
          hint: 'Re-enter your password',
          icon: Icons.lock_outline_rounded,
          obscureText: true,
          focusNode: _confirmPassFocus,
          textInputAction: TextInputAction.done,
          onSubmitted: _submitStepFromKeyboard,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PawmilyaPalette.cardEdge),
          ),
          child: CheckboxListTile(
            value: _agreeToTerms,
            onChanged: (value) {
              setState(() {
                _agreeToTerms = value ?? false;
              });
            },
            dense: true,
            visualDensity: VisualDensity.compact,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: PawmilyaPalette.goldDark,
            title: const Text(
              'I agree to the Terms and Privacy Policy.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton() {
    return PrimaryActionButton(
      label: _isSubmitting
          ? 'Registering...'
          : (_currentStep == _stepTitles.length - 1
                ? 'Register Shelter'
                : 'Continue'),
      icon: _currentStep == _stepTitles.length - 1
          ? Icons.how_to_reg_rounded
          : Icons.arrow_forward_rounded,
      colors: const [Color(0xFFE6B368), Color(0xFFD79647), Color(0xFFB97232)],
      onTap: _isSubmitting ? null : _onPrimaryAction,
      scale: _buttonScale.value,
    );
  }

  Widget _buildActionButtons({
    required bool compact,
    required bool keyboardOpen,
    required bool tightVertical,
  }) {
    final secondaryButton = OutlinedButton(
      onPressed: _isSubmitting ? null : _goToPreviousStep,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(color: PawmilyaPalette.gold.withValues(alpha: 0.65)),
        foregroundColor: PawmilyaPalette.goldDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: const Text(
        'Back',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    );

    if (keyboardOpen || _currentStep == 0) {
      return AnimatedBuilder(
        animation: _tapController,
        builder: (context, child) => _buildPrimaryButton(),
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
              builder: (context, child) => _buildPrimaryButton(),
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
            builder: (context, child) => _buildPrimaryButton(),
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
            builder: (context, child) => _buildPrimaryButton(),
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
          final compactFields = constraints.maxWidth < 320;
          final tightVertical = constraints.maxHeight < 640 || keyboardOpen;
          final allowsManualScroll = true;
          final compactHeader = constraints.maxHeight < 600 || keyboardOpen;

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
                      'Register Shelter',
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
                        'Simple guided setup',
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
                            'shelter-step-$_currentStep-$allowsManualScroll',
                          ),
                          primary: false,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 60),
                            child: _buildStepContent(
                              compactFields: compactFields,
                            ),
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

class _MapPickerSheet extends StatefulWidget {
  const _MapPickerSheet({this.initialValue});

  final LatLng? initialValue;

  @override
  State<_MapPickerSheet> createState() => _MapPickerSheetState();
}

class _MapPickerSheetState extends State<_MapPickerSheet> {
  static const _fallbackCenter = LatLng(14.5995, 120.9842);

  late LatLng _selected;
  final _mapController = MapController();
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  bool _isSearching = false;
  bool _isLocating = false;
  List<_MapSearchSuggestion> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue ?? _fallbackCenter;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isLikelyInPhilippines(LatLng point) {
    return point.latitude >= 4.2 &&
        point.latitude <= 21.5 &&
        point.longitude >= 116.7 &&
        point.longitude <= 126.8;
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      if (mounted) {
        setState(() {
          _suggestions = const [];
        });
      }
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _searchLocation(query: query, suggestionsOnly: true);
    });
  }

  Future<void> _searchLocation({
    String? query,
    bool suggestionsOnly = false,
  }) async {
    final normalizedQuery = (query ?? _searchCtrl.text).trim();
    if (normalizedQuery.isEmpty) {
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': normalizedQuery,
        'format': 'jsonv2',
        'limit': suggestionsOnly ? '5' : '1',
        'countrycodes': 'ph',
        'addressdetails': '1',
      });
      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'Pawmilya/1.0 (map-search)',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Search failed. Please try again.')),
          );
        }
        return;
      }

      final payload = jsonDecode(response.body);
      if (payload is! List) {
        return;
      }

      final parsedSuggestions = payload
          .whereType<Map<String, dynamic>>()
          .map((item) {
            final lat = double.tryParse((item['lat'] ?? '').toString());
            final lon = double.tryParse((item['lon'] ?? '').toString());
            if (lat == null || lon == null) {
              return null;
            }

            final point = LatLng(lat, lon);
            if (!_isLikelyInPhilippines(point)) {
              return null;
            }

            final address = item['address'];
            final addressData = address is Map<String, dynamic>
                ? address
                : <String, dynamic>{};
            final city =
                (addressData['city'] ??
                        addressData['town'] ??
                        addressData['municipality'] ??
                        addressData['village'] ??
                        '')
                    .toString();

            final title = (item['display_name'] ?? '')
                .toString()
                .split(',')
                .first
                .trim();
            return _MapSearchSuggestion(
              title: title.isEmpty ? 'Pinned location' : title,
              subtitle: city.isEmpty ? 'Philippines' : '$city, Philippines',
              point: point,
            );
          })
          .whereType<_MapSearchSuggestion>()
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _suggestions = parsedSuggestions;
      });

      if (parsedSuggestions.isEmpty && !suggestionsOnly) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No Philippine location found.')),
        );
        return;
      }

      if (parsedSuggestions.isNotEmpty && !suggestionsOnly) {
        _applySuggestion(parsedSuggestions.first);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search is unavailable right now.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _applySuggestion(_MapSearchSuggestion suggestion) {
    setState(() {
      _selected = suggestion.point;
      _searchCtrl.text = suggestion.title;
      _suggestions = const [];
    });
    _mapController.move(suggestion.point, 16);
  }

  Future<void> _autoLocate() async {
    setState(() {
      _isLocating = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location services.')),
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required.')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final point = LatLng(position.latitude, position.longitude);

      if (!_isLikelyInPhilippines(point)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Current location is outside the Philippines.'),
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _selected = point;
          _suggestions = const [];
        });
      }
      _mapController.move(point, 16);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto-locate is unavailable right now.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.78;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFCF4), Color(0xFFFFF6E5)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: PawmilyaPalette.cardEdge,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Pin Shelter Location',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: PawmilyaPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Search or tap map. Philippine addresses only.',
            style: TextStyle(
              fontSize: 12,
              color: PawmilyaPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PawmilyaPalette.cardEdge),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14A56628),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            textInputAction: TextInputAction.search,
                            onChanged: _onSearchChanged,
                            onSubmitted: (_) => _searchLocation(),
                            decoration: InputDecoration(
                              hintText: 'Search place or address in PH',
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: PawmilyaPalette.goldDark,
                              ),
                              isDense: true,
                              filled: true,
                              fillColor: const Color(0xFFFFF9EF),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: PawmilyaPalette.cardEdge,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: PawmilyaPalette.cardEdge,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: (_isSearching || _isLocating)
                              ? null
                              : _searchLocation,
                          style: FilledButton.styleFrom(
                            backgroundColor: PawmilyaPalette.goldDark,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                          ),
                          icon: _isSearching
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.travel_explore_rounded),
                          label: const Text('Search'),
                        ),
                        const SizedBox(width: 6),
                        IconButton.filled(
                          onPressed: (_isLocating || _isSearching)
                              ? null
                              : _autoLocate,
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFD89A52),
                          ),
                          icon: _isLocating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded),
                          tooltip: 'Use current location',
                        ),
                      ],
                    ),
                  ),
                  if (_suggestions.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 160),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          return ListTile(
                            dense: true,
                            visualDensity: const VisualDensity(vertical: -2),
                            leading: const Icon(
                              Icons.place_rounded,
                              color: PawmilyaPalette.goldDark,
                            ),
                            title: Text(
                              suggestion.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              suggestion.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _applySuggestion(suggestion),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selected,
                  initialZoom: 14,
                  onTap: (_, value) {
                    setState(() {
                      _selected = value;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.pawmilya.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selected,
                        width: 52,
                        height: 52,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_pin,
                          size: 44,
                          color: PawmilyaPalette.goldDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selected: ${_selected.latitude.toStringAsFixed(5)}, ${_selected.longitude.toStringAsFixed(5)}',
            style: const TextStyle(
              fontSize: 12,
              color: PawmilyaPalette.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: PawmilyaPalette.goldDark,
                    ),
                    onPressed: () => Navigator.of(context).pop(_selected),
                    child: const Text('Use this pin'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapSearchSuggestion {
  const _MapSearchSuggestion({
    required this.title,
    required this.subtitle,
    required this.point,
  });

  final String title;
  final String subtitle;
  final LatLng point;
}










