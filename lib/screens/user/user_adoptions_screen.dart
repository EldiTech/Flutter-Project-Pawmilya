import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/pawmilya_palette.dart';
import '../chat/chat_screen.dart';

class UserAdoptionsScreen extends StatelessWidget {
  const UserAdoptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in.')));
    }

    return Scaffold(
      backgroundColor: PawmilyaPalette.creamBottom,
      appBar: AppBar(
        title: const Text(
          'My Adoptions',
          style: TextStyle(
            color: PawmilyaPalette.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: PawmilyaPalette.creamTop,
        elevation: 0,
        iconTheme: const IconThemeData(color: PawmilyaPalette.textPrimary),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('adoptions')
            .where('adopterId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: PawmilyaPalette.gold),    
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'You have not adopted any pets yet.',
                style: TextStyle(color: PawmilyaPalette.textSecondary),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final adoptionId = docs[index].id;
              final data = docs[index].data() as Map<String, dynamic>;
              return _UserAdoptionCard(adoptionId: adoptionId, data: data);
            },
          );
        },
      ),
    );
  }
}

class _UserAdoptionCard extends StatelessWidget {
  final String adoptionId;
  final Map<String, dynamic> data;

  const _UserAdoptionCard({required this.adoptionId, required this.data});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'On the Way':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      case 'Processing':
      default:
        return PawmilyaPalette.gold;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'On the Way':
        return Icons.local_shipping_rounded;
      case 'Completed':
        return Icons.verified_rounded;
      case 'Processing':
      default:
        return Icons.access_time_filled_rounded;
    }
  }

  Future<void> _openMaps(BuildContext context, String address) async {
    final query = Uri.encodeComponent(address);
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open map.')));
      }
    }
  }

  Future<void> _uploadProofPicture(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (pickedFile == null) return;

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Uploading proof...')));
    }

    try {
      String fileName = 'proof_$adoptionId.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(
        'adoption_proofs/$fileName',
      );
      UploadTask uploadTask = storageRef.putFile(File(pickedFile.path));
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('adoptions')
          .doc(adoptionId)
          .update({'proofImageUrl': downloadUrl});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proof uploaded successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final petName = data['petName'] ?? 'Unknown Pet';
    final petImage = data['petImageUrl'] ?? '';
    final adopterAddress = data['adopterAddress'] ?? '';
    final proofImage = data['proofImageUrl'] ?? '';
    final date = data['timestamp'] != null
        ? DateFormat(
            'MMM dd, yyyy - hh:mm a',
          ).format((data['timestamp'] as Timestamp).toDate())
        : 'Unknown Date';
    final status = data['status'] ?? 'Processing';
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: petImage.isNotEmpty
                    ? (petImage.startsWith('http')
                          ? Image.network(
                              petImage,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            )
                          : Image.memory(
                              base64Decode(petImage),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ))
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.pets, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      petName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: PawmilyaPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Adoption Date: \n$date',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    if (adopterAddress.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: PawmilyaPalette.gold,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            adopterAddress,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Icon(icon, size: 20, color: color),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (proofImage.isNotEmpty) ...[
            const Text(
              'Proof of Adoption:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: PawmilyaPalette.textPrimary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                proofImage,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Action Buttons: Track and Upload Proof
          Row(
            children: [
              if (adopterAddress.isNotEmpty)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openMaps(context, adopterAddress),
                    icon: const Icon(
                      Icons.map_rounded,
                      size: 16,
                      color: Colors.blue,
                    ),
                    label: const Text(
                      'Track',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              if (adopterAddress.isNotEmpty &&
                  (status == 'On the Way' ||
                      status == 'Completed' ||
                      status == 'Processing'))
                const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _uploadProofPicture(context),
                  icon: const Icon(
                    Icons.camera_alt_rounded,
                    size: 16,
                    color: PawmilyaPalette.gold,
                  ),
                  label: Text(
                    proofImage.isEmpty ? 'Add Proof' : 'Update Proof',
                    style: const TextStyle(
                      color: PawmilyaPalette.gold,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: PawmilyaPalette.gold),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: PawmilyaPalette.gold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ChatScreen(adoptionId: adoptionId, data: data),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
              label: const Text(
                'Chat with Shelter',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
