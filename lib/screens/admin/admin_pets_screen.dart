import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/pawmilya_palette.dart';

class AdminPetsScreen extends StatefulWidget {
  const AdminPetsScreen({super.key});

  @override
  State<AdminPetsScreen> createState() => _AdminPetsScreenState();
}

class _AdminPetsScreenState extends State<AdminPetsScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Pets'),
        backgroundColor: PawmilyaPalette.creamTop,
      ),
      body: Column(
        children: [
          // Filter Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('For Adoption'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Urgent'),
                ],
              ),
            ),
          ),
          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pets').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No pets found.'));
                }

                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (_selectedFilter == 'For Adoption') {
                    return data['status'] == 'available';
                  } else if (_selectedFilter == 'Urgent') {
                    return data['status'] == 'available' &&
                        data['isUrgent'] == true;
                  }
                  return true;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Text(
                      'No pets found for filter: ',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final docId = filteredDocs[index].id;
                    final data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    final imageUrl = data['imageUrl'];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        onTap: () =>
                            _showAdminPetDetailsModal(context, docId, data),
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:
                              imageUrl != null && imageUrl.toString().isNotEmpty
                              ? imageUrl.toString().startsWith('http')
                                    ? Image.network(
                                        imageUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) =>
                                            const Icon(Icons.pets, size: 40),
                                      )
                                    : Image.memory(
                                        base64Decode(imageUrl.toString()),
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) =>
                                            const Icon(Icons.pets, size: 40),
                                      )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  color: PawmilyaPalette.gold.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: const Icon(
                                    Icons.pets_rounded,
                                    color: PawmilyaPalette.goldDark,
                                    size: 32,
                                  ),
                                ),
                        ),
                        title: Text(
                          data['name'] ?? 'Unknown Pet',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: PawmilyaPalette.textPrimary,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              "${data['breed'] ?? 'Unknown'} • ${data['age'] ?? '?'} • ${data['gender'] ?? '?'}",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    text: 'Status: ',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            data['status']
                                                ?.toString()
                                                .toUpperCase() ??
                                            'UNKNOWN',
                                        style: TextStyle(
                                          color: data['status'] == 'available'
                                              ? Colors.green
                                              : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (data['isUrgent'] == true) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'URGENT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.red,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : PawmilyaPalette.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: PawmilyaPalette.gold,
      backgroundColor: Colors.white,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = label;
          });
        }
      },
    );
  }

  void _showAdminPetDetailsModal(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (imageUrl != null && imageUrl.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: imageUrl.startsWith('http')
                        ? Image.network(
                            imageUrl,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              height: 150,
                              width: 150,
                              color: Colors.grey,
                              child: const Icon(Icons.pets, size: 50),
                            ),
                          )
                        : Image.memory(
                            base64Decode(imageUrl),
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              height: 150,
                              width: 150,
                              color: Colors.grey,
                              child: const Icon(Icons.pets, size: 50),
                            ),
                          ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                data['name'] ?? 'Unknown Pet',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: PawmilyaPalette.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "${data['breed'] ?? 'Unknown'} • ${data['age'] ?? '?'} • ${data['gender'] ?? '?'}",
                style: const TextStyle(
                  fontSize: 16,
                  color: PawmilyaPalette.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Description',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: PawmilyaPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data['description'] ?? 'No description provided.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: PawmilyaPalette.goldDark,
                ),
                icon: const Icon(Icons.edit),
                label: const Text(
                  'Edit Status',
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showEditStatusDialog(context, docId);
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Pet', style: TextStyle(fontSize: 16)),
                onPressed: () {
                  Navigator.pop(ctx);
                  _confirmDeletePet(context, docId, data['name']);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showEditStatusDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Status'),
        content: const Text('Mark this pet as Adopted or Unavailable?'),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('pets')
                  .doc(docId)
                  .update({'status': 'adopted'});
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text(
              'Mark Adopted',
              style: TextStyle(color: Colors.green),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePet(
    BuildContext context,
    String docId,
    String? petName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing?'),
        content: Text('Are you sure you want to remove ${petName ?? 'this pet'} from the app?'),        
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      FirebaseFirestore.instance.collection('pets').doc(docId).delete();
    }
  }
}
