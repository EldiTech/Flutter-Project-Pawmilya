import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShelterEditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const ShelterEditProfileScreen({super.key, required this.initialData});

  @override
  State<ShelterEditProfileScreen> createState() => _ShelterEditProfileScreenState();
}

class _ShelterEditProfileScreenState extends State<ShelterEditProfileScreen> {
  // Basic
  late TextEditingController _nameCtrl;
  late TextEditingController _orgTypeCtrl;
  late TextEditingController _regNumCtrl;
  late TextEditingController _yearEstCtrl;

  // Address
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _postalCtrl;
  late TextEditingController _mapsUrlCtrl;

  // Contact
  late TextEditingController _phoneCtrl;
  late TextEditingController _altPhoneCtrl;
  late TextEditingController _websiteCtrl;

  // Admin
  late TextEditingController _adminNameCtrl;
  late TextEditingController _adminRoleCtrl;

  // Operations
  late TextEditingController _animalTypesCtrl;
  late TextEditingController _capacityCtrl;
  late TextEditingController _servicesCtrl;
  late TextEditingController _operatingHoursCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;

    _nameCtrl = TextEditingController(text: d['shelterName'] ?? '');
    _orgTypeCtrl = TextEditingController(text: d['organizationType'] ?? '');
    _regNumCtrl = TextEditingController(text: d['registrationNumber'] ?? '');
    _yearEstCtrl = TextEditingController(text: d['yearEstablished'] ?? '');

    final loc = d['location'] ?? {};
    _addressCtrl = TextEditingController(text: loc['fullAddress'] ?? '');
    _cityCtrl = TextEditingController(text: loc['cityProvince'] ?? '');
    _postalCtrl = TextEditingController(text: loc['postalCode'] ?? '');
    _mapsUrlCtrl = TextEditingController(text: loc['googleMapsUrl'] ?? '');

    final cnt = d['contact'] ?? {};
    _phoneCtrl = TextEditingController(text: cnt['phoneNumber'] ?? '');
    _altPhoneCtrl = TextEditingController(text: cnt['alternateContact'] ?? '');
    _websiteCtrl = TextEditingController(text: cnt['websiteUrl'] ?? '');

    final adm = d['adminDetails'] ?? {};
    _adminNameCtrl = TextEditingController(text: adm['fullName'] ?? '');
    _adminRoleCtrl = TextEditingController(text: adm['role'] ?? '');

    final ops = d['operations'] ?? {};
    _animalTypesCtrl = TextEditingController(text: ops['animalTypesAccepted'] ?? '');
    _capacityCtrl = TextEditingController(text: ops['capacity'] ?? '');
    _servicesCtrl = TextEditingController(text: ops['servicesOffered'] ?? '');
    _operatingHoursCtrl = TextEditingController(text: ops['operatingHours'] ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _orgTypeCtrl.dispose();
    _regNumCtrl.dispose();
    _yearEstCtrl.dispose();

    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _postalCtrl.dispose();
    _mapsUrlCtrl.dispose();

    _phoneCtrl.dispose();
    _altPhoneCtrl.dispose();
    _websiteCtrl.dispose();

    _adminNameCtrl.dispose();
    _adminRoleCtrl.dispose();

    _animalTypesCtrl.dispose();
    _capacityCtrl.dispose();
    _servicesCtrl.dispose();
    _operatingHoursCtrl.dispose();

    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      
      await FirebaseFirestore.instance.collection('shelters').doc(uid).update({
        'shelterName': _nameCtrl.text.trim(),
        'organizationType': _orgTypeCtrl.text.trim(),
        'registrationNumber': _regNumCtrl.text.trim(),
        'yearEstablished': _yearEstCtrl.text.trim(),
        
        'location.fullAddress': _addressCtrl.text.trim(),
        'location.cityProvince': _cityCtrl.text.trim(),
        'location.postalCode': _postalCtrl.text.trim(),
        'location.googleMapsUrl': _mapsUrlCtrl.text.trim(),

        'contact.phoneNumber': _phoneCtrl.text.trim(),
        'contact.alternateContact': _altPhoneCtrl.text.trim(),
        'contact.websiteUrl': _websiteCtrl.text.trim(),

        'adminDetails.fullName': _adminNameCtrl.text.trim(),
        'adminDetails.role': _adminRoleCtrl.text.trim(),

        'operations.animalTypesAccepted': _animalTypesCtrl.text.trim(),
        'operations.capacity': _capacityCtrl.text.trim(),
        'operations.servicesOffered': _servicesCtrl.text.trim(),
        'operations.operatingHours': _operatingHoursCtrl.text.trim(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: type,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: Icon(icon, color: const Color(0xFF7F8C8D)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDropdownField(String label, TextEditingController controller, IconData icon, List<String> options) {
    if (controller.text.isEmpty || !options.contains(controller.text)) {
      controller.text = options.first;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: controller.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: Icon(icon, color: const Color(0xFF7F8C8D)),
          ),
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() {
                controller.text = newValue;
              });
            }
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMultiSelectChoices(String label, TextEditingController controller, List<String> options) {
    List<String> selectedOptions = controller.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && options.contains(e))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: options.map((option) {
            final isSelected = selectedOptions.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              selectedColor: const Color(0xFF2C3E50),
              showCheckmark: false,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF2C3E50),
              ),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    if (!selectedOptions.contains(option)) {
                      selectedOptions.add(option);
                    }
                  } else {
                    selectedOptions.remove(option);
                  }
                  controller.text = selectedOptions.join(', ');
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF2C3E50),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildTextField('Shelter Name', _nameCtrl, Icons.storefront),
                    _buildDropdownField('Organization Type', _orgTypeCtrl, Icons.category, [
                      'Non-Profit Organization',
                      'Government Animal Control',
                      'Private Rescue Group',
                      'Foster Network',
                      'Other'
                    ]),
                    _buildTextField('Registration Number', _regNumCtrl, Icons.numbers),
                    _buildTextField('Year Established', _yearEstCtrl, Icons.calendar_today, type: TextInputType.number),

                    const SizedBox(height: 20),
                    const Text('Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildTextField('Full Address', _addressCtrl, Icons.location_on),
                    _buildTextField('City / Province', _cityCtrl, Icons.location_city),
                    _buildTextField('Postal Code', _postalCtrl, Icons.local_post_office, type: TextInputType.number),
                    _buildTextField('Google Maps URL', _mapsUrlCtrl, Icons.map, type: TextInputType.url),

                    const SizedBox(height: 20),
                    const Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildTextField('Phone Number', _phoneCtrl, Icons.phone, type: TextInputType.phone),
                    _buildTextField('Alternate Contact', _altPhoneCtrl, Icons.phone_android, type: TextInputType.phone),
                    _buildTextField('Website URL', _websiteCtrl, Icons.language, type: TextInputType.url),

                    const SizedBox(height: 20),
                    const Text('Admin / Owner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildTextField('Full Name', _adminNameCtrl, Icons.person),
                    _buildDropdownField('Role / Position', _adminRoleCtrl, Icons.work, [
                      'Admin/Owner',
                      'Manager',
                      'Coordinator',
                      'Staff',
                      'Volunteer',
                      'Other'
                    ]),

                    const SizedBox(height: 20),
                    const Text('Operations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildDropdownField('Animal Types Accepted', _animalTypesCtrl, Icons.pets, [
                      'Dogs & Cats',
                      'Dogs Only',
                      'Cats Only',
                      'All Domestic Animals',
                      'Exotic Pets',
                      'Other'
                    ]),
                    _buildTextField('Capacity', _capacityCtrl, Icons.format_list_numbered, type: TextInputType.number),
                    _buildMultiSelectChoices('Services Offered', _servicesCtrl, [
                      'Adoption & Foster',
                      'Medical & Veterinary Care',
                      'Spay & Neuter',
                      'Training & Rehabilitation',
                      'Rescue & Animal Control',
                      'All Full Services',
                      'Other'
                    ]),
                    _buildDropdownField('Operating Hours', _operatingHoursCtrl, Icons.access_time, [
                      '24/7',
                      'Mon-Fri 8AM - 5PM',
                      'Mon-Fri 9AM - 6PM',
                      'Open Daily 8AM - 5PM',
                      'Open Daily 9AM - 6PM',
                      'By Appointment Only',
                      'Other'
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
