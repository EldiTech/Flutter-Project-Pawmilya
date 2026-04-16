import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/pawmilya_palette.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Users'), backgroundColor: PawmilyaPalette.creamTop),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'user').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No users found.'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final docId = docs[index].id;
              final data = docs[index].data() as Map<String, dynamic>;
              final isBanned = data['status'] == 'banned';
              
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: isBanned ? Colors.red.withValues(alpha: 0.1) : PawmilyaPalette.creamMid,
                    child: Icon(Icons.person, color: isBanned ? Colors.red : PawmilyaPalette.goldDark, size: 28),
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(data['realName'] ?? data['name'] ?? data['username'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      if (isBanned)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Text('BANNED', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                  subtitle: Text(data['email'] ?? 'No email', style: TextStyle(color: Colors.grey[600])),
                  children: [
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(data['phoneNumber'] ?? data['phone'] ?? 'No phone provided'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(child: Text(data['address'] ?? 'No address provided')),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: Icon(isBanned ? Icons.restore : Icons.block, color: isBanned ? Colors.green : Colors.orange),
                                label: Text(isBanned ? 'Unban' : 'Ban User', style: TextStyle(color: isBanned ? Colors.green : Colors.orange)),
                                onPressed: () async {
                                  await FirebaseFirestore.instance.collection('users').doc(docId).update({'status': isBanned ? 'active' : 'banned'});
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isBanned ? 'User restored.' : 'User banned.')));
                                  }
                                },
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.delete_forever, size: 18),
                                label: const Text('Delete'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Permanent Delete?'),
                                      content: Text('Delete ${data['realName'] ?? data['name'] ?? data['username'] ?? 'this user'} permanently? This cannot be undone.'),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await FirebaseFirestore.instance.collection('users').doc(docId).delete();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
