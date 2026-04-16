import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/pawmilya_palette.dart';

import 'for_adoption_screen.dart';

class PutForAdoptionScreen extends StatefulWidget {
  final String petId;
  final Map<String, dynamic> petData;

  const PutForAdoptionScreen({
    super.key,
    required this.petId,
    required this.petData,
  });

  @override
  State<PutForAdoptionScreen> createState() => _PutForAdoptionScreenState();
}

class _PutForAdoptionScreenState extends State<PutForAdoptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _requirementsController = TextEditingController();
  final TextEditingController _feeController = TextEditingController();
  bool _isUrgent = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _requirementsController.text = widget.petData['adoptionRequirements']?.toString() ?? 'Loves to play, requires an active owner.';
    _feeController.text = widget.petData['adoptionFee']?.toString() ?? '0'; // default fee
    // Load existing urgent status if any, defaulting to false
    _isUrgent = widget.petData['isUrgent'] ?? false;
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance
          .collection('pets')
          .doc(widget.petId)
          .update({
            'status': 'available',
            'isUrgent': _isUrgent,
            'adoptionRequirements': _requirementsController.text.trim(),
            'adoptionFee': _feeController.text.trim(),
            'listedForAdoptionAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pet successfully listed for adoption!'),
          ),
        );
        Navigator.pop(context); // return to previous screen
        // Route to the "For Adoption" list screen automatically
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ForAdoptionScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to list for adoption: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.petData['imageUrl']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adoption Listing'),
        backgroundColor: PawmilyaPalette.creamTop,
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing listing...', style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: imageUrl.startsWith('http')
                              ? Image.network(
                                  imageUrl,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    height: 180,
                                    width: double.infinity,
                                    color: Colors.grey,
                                    child: const Icon(Icons.pets, size: 50),
                                  ),
                                )
                              : Image.memory(
                                  base64Decode(imageUrl),
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    height: 180,
                                    width: double.infinity,
                                    color: Colors.grey,
                                    child: const Icon(Icons.pets, size: 50),
                                  ),
                                ),
                        ),
                      )
                    else
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(Icons.pets, size: 64, color: Colors.grey),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      'Ready to list ${widget.petData['name'] ?? 'this pet'}?',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: PawmilyaPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add final details to make their adoption profile stand out.',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _requirementsController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Adoption Requirements / Notes',
                        border: OutlineInputBorder(),
                        hintText:
                            'E.g., Requires fenced yard, no other pets...',
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Please provide some requirements'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _feeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Adoption Fee (₱)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.money),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enter fee (can be 0)'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: SwitchListTile(
                        title: const Text('Mark as Urgent Adoption', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        subtitle: const Text('Is this pet in urgent need of a home right away?'),
                        value: _isUrgent,
                        activeThumbColor: Colors.white,
                        activeTrackColor: Colors.red,
                        onChanged: (val) {
                          setState(() {
                            _isUrgent = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: PawmilyaPalette.gold,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    icon: const Icon(Icons.favorite, color: Colors.white),
                    label: const Text(
                      'Put for Adoption',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _submitListing,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
