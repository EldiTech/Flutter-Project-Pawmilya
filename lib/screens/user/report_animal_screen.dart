import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/notification_service.dart';
import '../../theme/pawmilya_palette.dart';
import '../../widgets/primary_action_button.dart';
import 'my_reports_screen.dart';

class ReportAnimalTab extends StatefulWidget {
  const ReportAnimalTab({super.key});

  @override
  State<ReportAnimalTab> createState() => _ReportAnimalTabState();
}

class _ReportAnimalTabState extends State<ReportAnimalTab> with AutomaticKeepAliveClientMixin<ReportAnimalTab> {
  @override
  bool get wantKeepAlive => true;

  int _currentStep = 0;
  String? _selectedReportType;
  bool _useCurrentLocation = false;
  bool _isLoadingLocation = false;
  bool _allowContact = true;
  bool _isSubmitted = false;
  bool _isSubmitting = false;
  String _loadingStatus = '';

  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];

  LatLng? _currentPosition;
  final MapController _mapController = MapController();

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final List<String> _reportTypes = [
    'Lost Animal',
    'Injured Animal',
    'Abuse / Neglect',
    'Stray Animal',
  ];

  final List<IconData> _reportIcons = [
    Icons.search_rounded,
    Icons.local_hospital_rounded,
    Icons.warning_rounded,
    Icons.pets_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (mounted) {
          setState(() {
            _nameController.text = user.displayName ?? '';
            _phoneController.text = user.phoneNumber ?? '';
            _emailController.text = user.email ?? '';
          });
        }
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (mounted) {
            setState(() {
              _nameController.text = data['realName'] ?? data['name'] ?? data['username'] ?? user.displayName ?? '';
              _phoneController.text = data['phoneNumber'] ?? data['contact'] ?? data['phone'] ?? user.phoneNumber ?? '';
              _emailController.text = data['email'] ?? user.email ?? '';
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReportType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a report type.')),
      );
      return;
    }
    if (_locationController.text.isEmpty && !_useCurrentLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a location.')),
      );
      return;
    }
    if (_allowContact && (_nameController.text.isEmpty || (_phoneController.text.isEmpty && _emailController.text.isEmpty))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide your contact name and at least a phone number or email.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _loadingStatus = 'Preparing submission...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      // 1. Process Images to Base64 (if any)
      List<String> base64Images = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        setState(() {
          _loadingStatus = 'Processing photo ${i + 1} of ${_selectedImages.length}...';
        });
        
        var file = _selectedImages[i];
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        
        // Add a standard prefix so it can be easily identified/rendered later
        base64Images.add('data:image/jpeg;base64,$base64String');
      }

      setState(() {
        _loadingStatus = 'Saving report to database...';
      });

      // 2. Save Report Data to Firestore
      await FirebaseFirestore.instance.collection('reports').add({
        'type': _selectedReportType,
        'location_address': _locationController.text,
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
        'description': _descriptionController.text,
        'contact_name': _nameController.text,
        'contact_phone': _phoneController.text,
        'contact_email': _emailController.text,
        'allow_contact': _allowContact,
        'images': base64Images,
        'status': 'Pending',
        'reporter_id': user?.uid,
        'time_of_sighting': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      });

      if (user?.uid != null) {
        await NotificationService().createNotification(
          title: 'Report Submitted',
          message: 'Your report for $_selectedReportType at ${_locationController.text} has been successfully submitted.',
          recipientId: user!.uid,
          type: 'rescue',
        );
      }

      if (mounted) {
        setState(() {
          _isSubmitted = true;
          _isSubmitting = false;
          _loadingStatus = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _loadingStatus = '';
        });
        _showError('Failed to submit report: $e');
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 50, 
        maxWidth: 800,
        maxHeight: 800,
      );
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((f) => File(f.path)));
        });
      }
    } catch (e) {
      _showError('Failed to pick images: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLoadingLocation = false);
      _showError('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLoadingLocation = false);
        _showError('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _isLoadingLocation = false);
      _showError('Location permissions are permanently denied.');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final newTarget = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentPosition = newTarget;
          _useCurrentLocation = true;
          // _locationController.clear();
        });
        
        // Wait for the FlutterMap to actually be rendered before moving the controller
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(newTarget, 16.0);
          }
        });
      }

      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1');
      final response = await http.get(url, headers: {
        'User-Agent': 'PawmilyaApp/1.0.0 (contact@pawmilya.com)',
        'Accept-Language': 'en-US,en;q=0.9',
      }).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['display_name'] != null) {
          if (mounted) {
             setState(() {
                _locationController.text = data['display_name'];
             });
          }
        } else {
             setState(() {
                _locationController.text = '${position.latitude}, ${position.longitude}';
             });
        }
      } else {
             setState(() {
                _locationController.text = '${position.latitude}, ${position.longitude}';
             });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
         if (_currentPosition != null) {
            _locationController.text = '${_currentPosition!.latitude}, ${_currentPosition!.longitude}';
         }
      });
      }
    } finally {
      if (mounted) {
         setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _handleMapTap(LatLng point) async {
    setState(() {
      _currentPosition = point;
      _useCurrentLocation = false;
      _isLoadingLocation = true;
    });

    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1');
      final response = await http.get(url, headers: {
        'User-Agent': 'PawmilyaApp/1.0.0 (contact@pawmilya.com)',
        'Accept-Language': 'en-US,en;q=0.9',
      }).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['display_name'] != null) {
          if (mounted) {
             setState(() {
                _locationController.text = data['display_name'];
             });
          }
        } else {
             setState(() {
                _locationController.text = '${point.latitude}, ${point.longitude}';
             });
        }
      } else {
             setState(() {
                _locationController.text = '${point.latitude}, ${point.longitude}';
             });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
         _locationController.text = '${point.latitude}, ${point.longitude}';
      });
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? PawmilyaPalette.gold : Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Type();
      case 1:
        return _buildStep2Location();
      case 2:
        return _buildStep3PhotosAndDesc();
      case 3:
        return _buildStep4ContactAndReview();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1Type() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What are you reporting?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: PawmilyaPalette.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the category that best fits the situation.',
          style: TextStyle(fontSize: 14, color: PawmilyaPalette.textSecondary.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: _reportTypes.length,
          itemBuilder: (context, index) {
            final isSelected = _selectedReportType == _reportTypes[index];
            return GestureDetector(
              onTap: () => setState(() => _selectedReportType = _reportTypes[index]),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? PawmilyaPalette.gold.withValues(alpha: 0.1) : Colors.white,
                  border: Border.all(
                    color: isSelected ? PawmilyaPalette.gold : Colors.grey.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _reportIcons[index],
                      size: 40,
                      color: isSelected ? PawmilyaPalette.gold : PawmilyaPalette.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _reportTypes[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? PawmilyaPalette.gold : PawmilyaPalette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStep2Location() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Where is the animal?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: PawmilyaPalette.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'Accurate location helps rescuers respond faster.',
          style: TextStyle(fontSize: 14, color: PawmilyaPalette.textSecondary.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 24),
        InkWell(
          onTap: () {
            if (!_useCurrentLocation) {
              _getCurrentLocation();
            } else {
              setState(() {
                _useCurrentLocation = false;
                _currentPosition = null;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _useCurrentLocation ? PawmilyaPalette.gold.withValues(alpha: 0.1) : Colors.white,
              border: Border.all(color: _useCurrentLocation ? PawmilyaPalette.gold : Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.my_location_rounded, color: _useCurrentLocation ? PawmilyaPalette.gold : PawmilyaPalette.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isLoadingLocation ? 'Locating...' : 'Use Current Location',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _useCurrentLocation ? PawmilyaPalette.gold : PawmilyaPalette.textPrimary,
                    ),
                  ),
                ),
                if (_isLoadingLocation)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: PawmilyaPalette.gold),
                  )
                else if (_useCurrentLocation) 
                  const Icon(Icons.check_circle_rounded, color: PawmilyaPalette.gold),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('OR', style: TextStyle(color: Colors.grey))),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _locationController,
          maxLines: 2,
          minLines: 1,
          decoration: InputDecoration(
            labelText: 'Address or location details',
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.location_on_rounded),
          ),
          onChanged: (val) {
            // Uncheck the "use current location" toggle if they manually edit the address
            if (_useCurrentLocation) {
              setState(() {
                 _useCurrentLocation = false;
                 _currentPosition = null; // optional: clears the map pin if you want
              });
            }
          },
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _currentPosition == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_rounded, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Enter an address or use current location', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentPosition!,
                      initialZoom: 15.0,
                      onTap: (tapPosition, point) => _handleMapTap(point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.pawmilya',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentPosition!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 60), // Added extra safety padding at bottom
      ],
    );
  }

  Widget _buildStep3PhotosAndDesc() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Provide Details',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: PawmilyaPalette.textPrimary),
        ),
        const SizedBox(height: 24),
        const Text('Add Photos (Optional but recommended)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ..._selectedImages.map((file) => Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    file,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImages.remove(file)),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            )),
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: PawmilyaPalette.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PawmilyaPalette.gold, style: BorderStyle.solid, width: 2),
                ),
                child: const Icon(Icons.add_a_photo_rounded, color: PawmilyaPalette.gold, size: 32),
              ),
            ),
          ],
        ),
        if (_selectedImages.isEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Upload clear photos showing the animal and its current condition.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
        const SizedBox(height: 32),
        const Text('Description (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe what you saw (condition, behavior, injuries, etc.)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStep4ContactAndReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Information',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: PawmilyaPalette.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'In case rescuers need more information.',
          style: TextStyle(fontSize: 14, color: PawmilyaPalette.textSecondary.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Your Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[100],
            prefixIcon: const Icon(Icons.person_rounded),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          readOnly: true,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[100],
            prefixIcon: const Icon(Icons.phone_rounded),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          readOnly: true,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email Address',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[100],
            prefixIcon: const Icon(Icons.email_rounded),
          ),
        ),
        const SizedBox(height: 20),
        SwitchListTile(
          title: const Text('Allow rescuers to contact me', style: TextStyle(fontWeight: FontWeight.w600)),
          activeThumbColor: PawmilyaPalette.gold,
          contentPadding: EdgeInsets.zero,
          value: _allowContact,
          onChanged: (val) => setState(() => _allowContact = val),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Review Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
              const SizedBox(height: 12),
              
              _ReviewRow(icon: Icons.category_rounded, label: 'Type', value: _selectedReportType ?? "Not selected"),
              _ReviewRow(
                icon: Icons.location_on_rounded, 
                label: 'Location', 
                value: _locationController.text.isNotEmpty ? _locationController.text : (_useCurrentLocation ? "Current Location" : "Not provided"),
              ),
              _ReviewRow(
                icon: Icons.image_rounded, 
                label: 'Photos', 
                value: '${_selectedImages.length} attached',
              ),
              if (_descriptionController.text.isNotEmpty)
                _ReviewRow(
                  icon: Icons.notes_rounded, 
                  label: 'Description', 
                  value: _descriptionController.text,
                ),
              _ReviewRow(
                icon: Icons.person_rounded, 
                label: 'Name', 
                value: '$_allowContact' == 'true' ? _nameController.text : 'Anonymous',
              ),
              if ('$_allowContact' == 'true' && _phoneController.text.isNotEmpty)
                _ReviewRow(
                  icon: Icons.phone_rounded, 
                  label: 'Phone', 
                  value: _phoneController.text,
                ),
              if ('$_allowContact' == 'true' && _emailController.text.isNotEmpty)
                _ReviewRow(
                  icon: Icons.email_rounded, 
                  label: 'Email', 
                  value: _emailController.text,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
          ),
          const SizedBox(height: 24),
          const Text(
            'Report Sent Successfully',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: PawmilyaPalette.textPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            'Our team will review it shortly. You can track the status in your reports.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: PawmilyaPalette.textSecondary.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hourglass_empty_rounded, color: Colors.blue),
                SizedBox(width: 8),
                Text('Status: Pending', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          PrimaryActionButton(
            label: 'Back to Home',
            icon: Icons.home_rounded,
            colors: const [PawmilyaPalette.goldLight, PawmilyaPalette.gold],
            onTap: () {
              // Navigating or resetting state
              setState(() {
                _isSubmitted = false;
                _currentStep = 0;
                _selectedReportType = null;
                _locationController.clear();
                _descriptionController.clear();
                _selectedImages.clear();
              });
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isSubmitted) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _buildSuccessScreen(),
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Report an Animal',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: PawmilyaPalette.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Help us respond quickly by providing details',
                        style: TextStyle(
                          fontSize: 16,
                          color: PawmilyaPalette.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyReportsScreen()),
                    );
                  },
                  icon: const Icon(Icons.history_rounded, size: 28),
                  color: PawmilyaPalette.gold,
                  tooltip: 'My Reports',
                ),
              ],
            ),
          ),
          
          _buildProgressBar(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40),
              child: _buildStepContent(),
            ),
          ),

          // Bottom Navigation Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Back', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  )
                else
                  const Spacer(),

                if (_currentStep > 0) const SizedBox(width: 16),

                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () {
                      if (_currentStep == 0 && _selectedReportType == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a report type.')));
                        return;
                      }
                      if (_currentStep == 1 && _locationController.text.isEmpty && !_useCurrentLocation) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a location.')));
                        return;
                      }

                      if (_currentStep < 3) {
                        setState(() => _currentStep++);
                      } else {
                        _submitReport();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PawmilyaPalette.gold,
                      disabledBackgroundColor: PawmilyaPalette.gold.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSubmitting 
                      ? const SizedBox(
                          height: 24, 
                          width: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                        )
                      : Text(
                          _currentStep == 3 ? 'Submit Report' : 'Next Step',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                  ),
                ),
              ],
            ),
          ),
          
          if (_isSubmitting && _loadingStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _loadingStatus,
                style: TextStyle(
                  color: PawmilyaPalette.textSecondary.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReviewRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue[400]),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
