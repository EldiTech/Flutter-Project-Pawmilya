import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/pawmilya_palette.dart';

class EditPetScreen extends StatefulWidget {
  final String petId;
  final Map<String, dynamic> initialData;

  const EditPetScreen({
    super.key,
    required this.petId,
    required this.initialData,
  });

  @override
  State<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends State<EditPetScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _ageController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;

  late String _selectedGender;
  late String _selectedType;
  File? _selectedImage;
  String? _existingImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['name'] ?? '');
    _breedController = TextEditingController(text: widget.initialData['breed'] ?? '');
    _ageController = TextEditingController(text: widget.initialData['age'] ?? '');
    _locationController = TextEditingController(text: widget.initialData['location'] ?? '');
    _descriptionController = TextEditingController(text: widget.initialData['description'] ?? '');

    _selectedGender = widget.initialData['gender'] ?? 'Male';
    _selectedType = widget.initialData['type'] ?? 'Dogs';
    _existingImageUrl = widget.initialData['imageUrl'];

    // Ensure valid dropdown values
    if (!['Dogs', 'Cats', 'Birds', 'Others'].contains(_selectedType)) {
      _selectedType = 'Dogs';
    }
    if (!['Male', 'Female'].contains(_selectedGender)) {
      _selectedGender = 'Male';
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _updatePet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
    });

    try {
      String? base64Image = _existingImageUrl;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        base64Image = base64Encode(bytes);
      }

      await FirebaseFirestore.instance.collection('pets').doc(widget.petId).update({
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'category': _selectedType, // Kept in sync with type as per original register pet logic
        'breed': _breedController.text.trim(),
        'age': _ageController.text.trim(),
        'gender': _selectedGender,
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': base64Image,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet details updated successfully!')),
        );
        Navigator.pop(context); // Go back to details or previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Pet Details'),
        backgroundColor: PawmilyaPalette.creamTop,
      ),
      body: _isUploading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Updating pet...', style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                          image: _selectedImage != null
                              ? DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                )
                              : _existingImageUrl != null && _existingImageUrl!.isNotEmpty
                                  ? (_existingImageUrl!.startsWith('http')
                                      ? DecorationImage(
                                          image: NetworkImage(_existingImageUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : DecorationImage(
                                          image: MemoryImage(base64Decode(_existingImageUrl!)),
                                          fit: BoxFit.cover,
                                        ))
                                  : null,
                        ),
                        child: _selectedImage == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty)
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Tap to change picture', style: TextStyle(color: Colors.grey)),
                                ],
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Pet Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pets),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Provide a name' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedType,
                            decoration: const InputDecoration(labelText: 'Species', border: OutlineInputBorder()),
                            items: ['Dogs', 'Cats', 'Birds', 'Others']
                                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedType = val!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedGender,
                            decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                            items: ['Male', 'Female']
                                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedGender = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _breedController,
                            decoration: const InputDecoration(labelText: 'Breed', border: OutlineInputBorder()),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location / Region', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: PawmilyaPalette.gold,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _updatePet,
                      child: const Text('Save Changes', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
