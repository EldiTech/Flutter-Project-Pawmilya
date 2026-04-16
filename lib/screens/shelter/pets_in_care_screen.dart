import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/pawmilya_palette.dart';
import 'register_pet_screen.dart';
import 'edit_pet_screen.dart';
import 'put_for_adoption_screen.dart';
import 'add_pet_manually_screen.dart';

class PetsInCareScreen extends StatefulWidget {
  const PetsInCareScreen({super.key});

  @override
  State<PetsInCareScreen> createState() => _PetsInCareScreenState();
}

class _PetsInCareScreenState extends State<PetsInCareScreen> {
  String? shelterName;
  bool isLoading = true;

  Stream<QuerySnapshot>? _needsRegistrationStream;
  Stream<QuerySnapshot>? _registeredPetsStream;

  @override
  void initState() {
    super.initState();
    _fetchShelterData();
  }

  Future<void> _fetchShelterData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('shelters').doc(user.uid).get();
      if (doc.exists) {
        final fetchedShelterName = doc.data()?['shelterName'] ?? 'Unknown Shelter';
        setState(() {
          shelterName = fetchedShelterName;

          _needsRegistrationStream = FirebaseFirestore.instance
              .collection('reports')
              .where('status', isEqualTo: 'completed')
              .where('rescued_by', isEqualTo: fetchedShelterName)
              .snapshots();

          _registeredPetsStream = FirebaseFirestore.instance
              .collection('pets')
              .where('shelterId', isEqualTo: user.uid)
              .snapshots();

          isLoading = false;
        });
        return;
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pets In Care'), backgroundColor: PawmilyaPalette.creamTop),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (shelterName == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pets In Care'), backgroundColor: PawmilyaPalette.creamTop),
        body: const Center(child: Text('Unable to load shelter data.')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pets In Care'),
          backgroundColor: PawmilyaPalette.creamTop,
          bottom: const TabBar(
            labelColor: PawmilyaPalette.textPrimary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: PawmilyaPalette.goldDark,
            tabs: [
              Tab(text: 'Needs Registration'),
              Tab(text: 'Registered Pets'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: PawmilyaPalette.goldDark),
              tooltip: 'Add Pet Manually',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddPetManuallyScreen()),
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildNeedsRegistrationTab(),
            _buildRegisteredPetsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildNeedsRegistrationTab() {
    if (_needsRegistrationStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _needsRegistrationStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error loading reports.'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No rescues pending registration.', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildReportCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildRegisteredPetsTab() {
    if (_registeredPetsStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _registeredPetsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error loading registered pets.'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No pets registered yet.', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildPetCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildReportCard(String docId, Map<String, dynamic> data) {
    final proofImageBase64 = data['proof_image']?.toString();
    String? imageBase64;
    if (proofImageBase64 != null && proofImageBase64.isNotEmpty) {
      imageBase64 = proofImageBase64.contains(',') ? proofImageBase64.split(',').last : proofImageBase64;
    } else {
      final images = data['images'] as List<dynamic>?;
      if (images != null && images.isNotEmpty) {
        final imgString = images[0].toString();
        imageBase64 = imgString.contains(',') ? imgString.split(',').last : imgString;
      }
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imageBase64 != null && imageBase64.isNotEmpty) ...[
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.memory(
                base64Decode(imageBase64),
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(height: 200, color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 50, color: Colors.grey)),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['type'] ?? 'Unknown Animal', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: PawmilyaPalette.textPrimary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: PawmilyaPalette.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(child: Text('Found at: ${data['location_address'] ?? 'Unknown'}', style: const TextStyle(color: PawmilyaPalette.textSecondary), maxLines: 2)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PawmilyaPalette.gold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.app_registration),
                    label: const Text('Register as Pet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RegisterPetScreen(reportData: data, reportId: docId)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(String docId, Map<String, dynamic> data) {
    final imageUrl = data['imageUrl']?.toString();
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () => _showPetDetailsModal(context, docId, data),
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? imageUrl.startsWith('http')
                  ? Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 60, height: 60, color: Colors.grey, child: const Icon(Icons.pets)))
                  : Image.memory(base64Decode(imageUrl), width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 60, height: 60, color: Colors.grey, child: const Icon(Icons.pets)))
              : Container(width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.pets)),
        ),
        title: Text(data['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${data['breed'] ?? 'Mixed'} • ${data['age'] ?? '?'}'),
            const SizedBox(height: 4),
            Text('Status: ${data['status'] ?? 'available'}', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  void _showPetDetailsModal(BuildContext context, String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final imageUrl = data['imageUrl']?.toString();
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),
              ),
              if (imageUrl != null && imageUrl.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: imageUrl.startsWith('http')
                        ? Image.network(imageUrl, height: 150, width: 150, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(height: 150, width: 150, color: Colors.grey, child: const Icon(Icons.pets, size: 50)))
                        : Image.memory(base64Decode(imageUrl), height: 150, width: 150, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(height: 150, width: 150, color: Colors.grey, child: const Icon(Icons.pets, size: 50))),
                  ),
                ),
              const SizedBox(height: 16),
              Text(data['name'] ?? 'Unknown Pet', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: PawmilyaPalette.textPrimary), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('${data['breed'] ?? 'Mixed'} • ${data['age'] ?? '?'} • ${data['gender'] ?? 'Unknown'}', style: const TextStyle(fontSize: 16, color: PawmilyaPalette.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(data['description'] ?? 'No description provided.', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 24),
              if (data['status'] == 'sheltered' || data['status'] == 'available')
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PawmilyaPalette.gold,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.favorite, color: Colors.white),
                  label: const Text('Put for Adoption', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PutForAdoptionScreen(petId: docId, petData: data)),
                    );
                  },
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.edit, color: PawmilyaPalette.textPrimary),
                label: const Text('Edit Details', style: TextStyle(color: PawmilyaPalette.textPrimary, fontSize: 16)),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditPetScreen(petId: docId, initialData: data)),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: Colors.red,
                ),
                icon: const Icon(Icons.delete),
                label: const Text('Delete Pet', style: TextStyle(fontSize: 16)),
                onPressed: () => _confirmDeletePet(context, docId, data),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeletePet(BuildContext context, String docId, Map<String, dynamic> data) {
    Navigator.pop(context); // close previous bottom sheet
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Pet?'),
        content: const Text('Are you sure you want to remove this pet from the system? If it was rescued, it will be moved back to the Needs Registration tab.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // close dialog
              try {
                await FirebaseFirestore.instance.collection('pets').doc(docId).delete();
                
                // If it has a sourceReportId, update the report back to completed
                final String? reportId = data['sourceReportId'];
                if (reportId != null && reportId.isNotEmpty && reportId != 'manual_entry') {
                  await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
                    'status': 'completed',
                  });
                } else if (reportId == 'manual_entry') {
                  // Re-create it as a completed report so it shows in Needs Registration
                  await FirebaseFirestore.instance.collection('reports').add({
                    'type': data['type'] ?? 'Unknown Animal',
                    'location_address': data['location'] ?? 'Manual Entry Location',
                    'description': 'Deleted manual entry awaiting re-registration: ${data['description']}',
                    'status': 'completed',
                    'rescued_by': data['shelterName'] ?? 'Shelter',
                    'proof_image': data['imageUrl'], 
                    'contact_name': 'Shelter Add',
                    'created_at': FieldValue.serverTimestamp(),
                  });
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pet deleted successfully.')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete pet: $e')));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
