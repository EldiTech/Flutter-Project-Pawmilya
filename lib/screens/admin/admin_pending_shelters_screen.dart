import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/pawmilya_palette.dart';
import '../../services/email_service.dart';

class AdminPendingSheltersScreen extends StatelessWidget {
  const AdminPendingSheltersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Shelters'), backgroundColor: PawmilyaPalette.creamTop),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('shelters').where('status', isEqualTo: 'pending_verification').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No pending applications.'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final docId = docs[index].id;
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: PawmilyaPalette.gold,
                            child: Icon(Icons.maps_home_work_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['shelterName'] ?? 'Unknown Shelter', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: PawmilyaPalette.textPrimary)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.email, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(data['contact']?['email'] ?? 'No email', style: const TextStyle(color: Colors.grey))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('PENDING', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: TextButton.icon(
                                icon: const Icon(Icons.visibility, color: Colors.blueGrey),
                                label: const Text('View', style: TextStyle(color: Colors.blueGrey)),
                                onPressed: () {
                                  showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(data['shelterName'] ?? 'Shelter Details'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildDetailSection('Basic Info', [
                                          'Name: ${data['shelterName'] ?? 'N/A'}',
                                          'Type: ${data['organizationType'] ?? 'N/A'}',
                                          'Registration No.: ${data['registrationNumber'] ?? 'N/A'}',
                                          'Established: ${data['yearEstablished'] ?? 'N/A'}',
                                        ]),
                                        _buildDetailSection('Contact Info', [
                                          'Email: ${data['contact']?['email'] ?? 'N/A'}',
                                          'Phone: ${data['contact']?['phoneNumber'] ?? 'N/A'}',
                                          'Alt Contact: ${data['contact']?['alternateContact'] ?? 'N/A'}',
                                          'Website: ${data['contact']?['websiteUrl'] ?? 'N/A'}',
                                        ]),
                                        _buildDetailSection('Location', [
                                          'Address: ${data['location']?['fullAddress'] ?? 'N/A'}',
                                          'City/Province: ${data['location']?['cityProvince'] ?? 'N/A'}',
                                          'Postal Code: ${data['location']?['postalCode'] ?? 'N/A'}',
                                        ]),
                                        _buildDetailSection('Admin Details', [
                                          'Full Name: ${data['adminDetails']?['fullName'] ?? 'N/A'}',
                                          'Role: ${data['adminDetails']?['role'] ?? 'N/A'}',
                                          'Username: ${data['accountDetails']?['username'] ?? 'N/A'}',
                                        ]),
                                        _buildDetailSection('Operations & Facilities', [
                                          'Animal Types: ${data['operations']?['animalTypesAccepted'] ?? 'N/A'}',
                                          'Capacity: ${data['operations']?['capacity'] ?? 'N/A'}',
                                          'Services: ${data['operations']?['servicesOffered'] ?? 'N/A'}',
                                          'Operating Hours: ${data['operations']?['operatingHours'] ?? 'N/A'}',
                                        ]),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                                  ],
                                ),
                              );
                            },
                          ),
                            ),
                          ),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: TextButton.icon(
                                icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent),
                                label: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Reject Shelter'),
                                  content: const Text('Are you sure you want to reject this shelter application?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await FirebaseFirestore.instance.collection('shelters').doc(docId).update({'status': 'rejected'});
                                
                                EmailService.instance.sendEmail(
                                  to: data['contact']?['email'] ?? '',
                                  subject: 'Application Update',
                                  message: 'Unfortunately, your shelter application has been rejected. If you feel this is a mistake, you may re-apply using correct credentials.',
                                );
                                
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shelter application rejected.')));
                                }
                              }
                            },
                          ),
                            ),
                          ),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                                label: const Text('Approve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Approve Shelter'),
                                  content: const Text('Are you sure you want to approve this shelter application?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Approve', style: TextStyle(color: Colors.green)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await FirebaseFirestore.instance.collection('shelters').doc(docId).update({'status': 'approved'});
                                
                                EmailService.instance.sendEmail(
                                  to: data['contact']?['email'] ?? '',
                                  subject: 'Application Approved',
                                  message: 'Congratulations! Your shelter application has been approved. You can now log in and access the system.',
                                );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shelter successfully approved!')));
                                }
                              }
                            },
                          ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> details) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: PawmilyaPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          ...details.map((detail) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  detail,
                  style: const TextStyle(fontSize: 14),
                ),
              )),
          const Divider(),
        ],
      ),
    );
  }
}
