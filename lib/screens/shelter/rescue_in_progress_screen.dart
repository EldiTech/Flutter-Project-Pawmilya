import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/pawmilya_palette.dart';

class RescueInProgressScreen extends StatefulWidget {
  final Map<String, dynamic> reportData;
  final String reportId;

  const RescueInProgressScreen({
    super.key,
    required this.reportData,
    required this.reportId,
  });

  @override
  State<RescueInProgressScreen> createState() => _RescueInProgressScreenState();
}

class _RescueInProgressScreenState extends State<RescueInProgressScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isConvertingImage = false;

  Future<void> _updateStatusWithProof(BuildContext context) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 800,
      );

      if (photo == null) {
        return; // User canceled the camera
      }
      
      setState(() {
        _isConvertingImage = true;
      });
      
      final bytes = await photo.readAsBytes();
      final base64Image = base64Encode(bytes);

      final user = FirebaseAuth.instance.currentUser;
      String shelterName = 'Unknown Shelter';
      if (user != null) {
        final shelterDoc = await FirebaseFirestore.instance.collection('shelters').doc(user.uid).get();
        if (shelterDoc.exists) {
          shelterName = shelterDoc.data()?['shelterName'] ?? 'Unknown Shelter';
        }
      }
      
      await FirebaseFirestore.instance.collection('reports').doc(widget.reportId).update({
        'status': 'completed',
        'proof_image': base64Image,
        'rescued_by': shelterName,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rescue completed successfully with proof!')),
      );
      Navigator.pop(context);

    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isConvertingImage = false;
        });
      }
    }
  }

  Future<void> _launchMaps(Map<String, dynamic> data) async {
    final address = data['location_address'];
    final lat = data['latitude'];
    final lng = data['longitude'];

    String urlStr;
    if (lat != null && lng != null) {
      urlStr = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    } else if (address != null && address.toString().isNotEmpty) {
      urlStr = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address.toString())}';
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No location data available.')),
        );
      }
      return;
    }
    
    final uri = Uri.parse(urlStr);
    try {
      // LaunchMode.externalApplication forces it to open in Google Maps instead of a browser view
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Maps right now.')),
        );
      }
    }
  }

  Future<void> _contactReporter(String? phone, String? email, bool allowContact) async {
    if (!allowContact) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The reporter requested not to be contacted directly.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Contact Reporter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              if (phone != null && phone.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.blue),
                  title: Text(phone),
                  subtitle: const Text('Call'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final uri = Uri.parse('tel:$phone');
                    try {
                      await launchUrl(uri);
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open phone dialer.')));
                    }
                  },
                ),
              if (phone != null && phone.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.message, color: Colors.green),
                  title: Text(phone),
                  subtitle: const Text('SMS'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final uri = Uri.parse('sms:$phone');
                    try {
                      await launchUrl(uri);
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open messaging app.')));
                    }
                  },
                ),
              if (email != null && email.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.red),
                  title: Text(email),
                  subtitle: const Text('Email'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final uri = Uri.parse('mailto:$email');
                    try {
                      await launchUrl(uri);
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open email client.')));
                    }
                  },
                ),
              if ((phone == null || phone.isEmpty) && (email == null || email.isEmpty))
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No contact information available.', style: TextStyle(color: Colors.grey)),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('reports').doc(widget.reportId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text('Error loading report data.')),
          );
        }

        final data = (snapshot.data!.data() as Map<String, dynamic>?) ?? widget.reportData;
        final status = (data['status'] ?? 'in_progress').toString().toLowerCase();
        
        final images = data['images'] as List<dynamic>?;
        String? base64Image;
        if (images != null && images.isNotEmpty) {
          final imgString = images[0].toString();
          base64Image = imgString.contains(',') ? imgString.split(',').last : imgString;
        }

        Color statusColor = Colors.orange;
        String statusText = 'Rescue Ongoing';
        
        if (status == 'resolved' || status == 'completed' || status == 'registered') {
          statusColor = Colors.green;
          statusText = 'Completed';
        } else if (status == 'in_progress' || status == 'accepted') {
          statusColor = Colors.orange;
          statusText = 'On the way / Rescue ongoing';
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Rescue In Progress'),
            backgroundColor: PawmilyaPalette.creamTop,
            elevation: 1,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Map / Image area
                if (base64Image != null && base64Image.isNotEmpty)
                  Image.memory(
                    base64Decode(base64Image),
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      height: 250,
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                    ),
                  )
                else
                  Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
                  ),

                // Status Banner
                Container(
                  color: statusColor,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.emergency_share, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          statusText.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Key Details
                      Text(
                        data['type'] ?? 'Unknown Report',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: PawmilyaPalette.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data['location_address'] ?? 'No location provided',
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Situation Description',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['description'] ?? 'No description provided.',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      
                      // Action Buttons for Navigation & Contact
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _launchMaps(data),
                              icon: const Icon(Icons.map, color: Colors.white),
                              label: const Text('Locate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _contactReporter(
                                data['contact_phone'],
                                data['contact_email'],
                                data['allow_contact'] ?? true,
                              ),
                              icon: const Icon(Icons.phone, color: Colors.white),
                              label: const Text('Contact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      const Text(
                        'Update Rescue Status',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: (status == 'resolved' || status == 'completed' || status == 'registered') || _isConvertingImage 
                                ? null 
                                : () => _updateStatusWithProof(context),
                              icon: _isConvertingImage 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.camera_alt),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green, side: const BorderSide(color: Colors.green),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              label: Text(
                                _isConvertingImage ? 'Uploading Proof...' : 'Provide Proof & Mark Completed', 
                                style: const TextStyle(fontWeight: FontWeight.bold)
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}