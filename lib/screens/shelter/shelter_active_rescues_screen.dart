import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/pawmilya_palette.dart';
import 'rescue_in_progress_screen.dart';

class ShelterActiveRescuesScreen extends StatelessWidget {
  const ShelterActiveRescuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Rescues & Reports'), 
        backgroundColor: PawmilyaPalette.creamTop
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reports').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading rescues.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No active rescues or reports available.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final docId = docs[index].id;
              final data = docs[index].data() as Map<String, dynamic>;
              final status = (data['status'] ?? 'pending').toString().toLowerCase();
              final images = data['images'] as List<dynamic>?;
              String? firstImageBase64;
              
              if (images != null && images.isNotEmpty) {
                final imgString = images[0].toString();
                firstImageBase64 = imgString.contains(',') ? imgString.split(',').last : imgString;
              }

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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: (status == 'resolved' || status == 'completed' || status == 'registered')
                                ? Colors.green.withValues(alpha: 0.2) 
                                : Colors.orange.withValues(alpha: 0.2),
                            child: Icon(
                              Icons.report_problem_rounded, 
                              color: (status == 'resolved' || status == 'completed' || status == 'registered') ? Colors.green : Colors.orange, 
                              size: 28
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        data['type'] ?? 'Unknown Report', 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: PawmilyaPalette.textPrimary)
                                      )
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: (status == 'resolved' || status == 'completed' || status == 'registered') ? Colors.green : Colors.orange,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        data['location_address'] ?? 'No location provided', 
                                        maxLines: 1, 
                                        overflow: TextOverflow.ellipsis, 
                                        style: const TextStyle(color: Colors.grey)
                                      )
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (status == 'pending') ...[
                            TextButton.icon(
                              icon: const Icon(Icons.visibility),
                              label: const Text('View Details'),
                              onPressed: () {
                                _showDetailModal(context, data, firstImageBase64);
                              },
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check_circle, color: Colors.white),
                              label: const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                final user = FirebaseAuth.instance.currentUser;
                                String shelterName = 'Unknown Shelter';
                                if (user != null) {
                                  final shelterDoc = await FirebaseFirestore.instance.collection('shelters').doc(user.uid).get();
                                  if (shelterDoc.exists) {
                                    shelterName = shelterDoc.data()?['shelterName'] ?? 'Unknown Shelter';
                                  }
                                }

                                await FirebaseFirestore.instance.collection('reports').doc(docId).update({
                                  'status': 'in_progress',
                                  'rescued_by': shelterName,
                                });
                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => RescueInProgressScreen(
                                      reportData: data, 
                                      reportId: docId,
                                    )),
                                  );
                                }
                              },
                            ),
                          ] else if (status == 'in_progress') ...[
                            ElevatedButton.icon(
                              icon: const Icon(Icons.directions_run_rounded, color: Colors.white),
                              label: const Text('Rescue In Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => RescueInProgressScreen(
                                    reportData: data, 
                                    reportId: docId,
                                  )),
                                );
                              },
                            ),
                          ] else ...[
                            // Resolved state
                            TextButton.icon(
                              icon: const Icon(Icons.visibility, color: Colors.blueGrey),
                              label: const Text('View Details', style: TextStyle(color: Colors.blueGrey)),
                              onPressed: () {
                                _showDetailModal(context, data, firstImageBase64);
                              },
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.check_box, color: Colors.green),
                              label: const Text('Completed', style: TextStyle(color: Colors.green)),
                              onPressed: null,
                            ),
                          ]
                        ],
                      ),
                    ),
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

  void _showDetailModal(BuildContext context, Map<String, dynamic> data, String? base64Image) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(data['type'] ?? 'Report Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (base64Image != null && base64Image.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(base64Image),
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text('Location:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(data['location_address'] ?? 'Not provided'),
              const SizedBox(height: 12),
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(data['description'] ?? 'No description provided.'),
              const SizedBox(height: 12),
              const Text('Contact Information:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Name: ${data['contact_name'] ?? 'N/A'}'),
              Text('Phone: ${data['contact_phone'] ?? 'N/A'}'),
              Text('Email: ${data['contact_email'] ?? 'Anonymous'}'),
              if (data['rescued_by'] != null) ...[
                const SizedBox(height: 12),
                const Text('Handled By:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                Text('${data['rescued_by']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
              const SizedBox(height: 12),
              const Text('Provided Location:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(data['location_address'] ?? 'Not provided'),

              if (data['proof_image'] != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Rescue Proof:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(data['proof_image'].toString()),
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Text('Error loading proof image'),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
