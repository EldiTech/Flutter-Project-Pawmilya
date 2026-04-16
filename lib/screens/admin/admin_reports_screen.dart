import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/pawmilya_palette.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animal Reports'), backgroundColor: PawmilyaPalette.creamTop),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reports').orderBy('created_at', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading reports. Check index or connection.'));
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No reports available.'));

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
                // Remove the "data:image/jpeg;base64," prefix if it exists
                firstImageBase64 = imgString.contains(',') ? imgString.split(',').last : imgString;
              }

              // Color calculation based on detailed statuses
              Color statusColor = Colors.blue; // Default for Pending
              if (status == 'resolved' || status == 'completed' || status == 'registered') {
                statusColor = Colors.green;
              } else if (status == 'in_progress' || status == 'accepted') {
                statusColor = Colors.orange;
              } else if (status == 'rejected') {
                statusColor = Colors.red;
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
                            backgroundColor: statusColor.withValues(alpha: 0.2),
                            child: Icon(Icons.report_problem_rounded, color: statusColor, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(data['type'] ?? 'Unknown Report', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: PawmilyaPalette.textPrimary))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status.replaceAll('_', ' ').toUpperCase(),
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
                                    Expanded(child: Text(data['location_address'] ?? 'No location provided', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey))),
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
                              TextButton.icon(
                                icon: const Icon(Icons.visibility, color: Colors.blueGrey),
                                label: const Text('View', style: TextStyle(color: Colors.blueGrey)),
                                onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(data['type'] ?? 'Report Details'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (firstImageBase64 != null && firstImageBase64.isNotEmpty)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.memory(
                                              base64Decode(firstImageBase64),
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) => const SizedBox.shrink(),
                                            ),
                                          ),
                                        if (firstImageBase64 != null && firstImageBase64.isNotEmpty)
                                          const SizedBox(height: 16),
                                        const Text('Location:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(data['location_address'] ?? 'Not provided'),
                                        const SizedBox(height: 12),
                                        const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(data['description'] ?? 'No description provided.'),
                                        if (data['rescued_by'] != null) ...[
                                          const SizedBox(height: 12),
                                          Text(
                                            (status == 'resolved' || status == 'completed' || status == 'registered') ? 'Rescued By:' : 'Handled By:', 
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)
                                          ),
                                          Text('${data['rescued_by']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                        const SizedBox(height: 12),
                                        const Text('Contact Information:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text('Name: ${data['contact_name'] ?? 'N/A'}'),
                                        Text('Phone: ${data['contact_phone'] ?? 'N/A'}'),
                                        Text('Email: ${data['contact_email'] ?? 'N/A'}'),

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
                            },
                          ),
                          TextButton.icon(
                            icon: Icon(Icons.update, color: statusColor),
                            label: Text(status == 'resolved' || status == 'completed' || status == 'registered' ? 'Mark Pending' : 'Mark Resolved', style: TextStyle(color: statusColor)),
                            onPressed: () async {
                              // Reverting from Registered likely implies moving it back to Pending.
                              // If they don't want it to be reversible, we could disable the button 
                              // depending on the requirements, but toggling is the closest to existing behavior.
                              await FirebaseFirestore.instance.collection('reports').doc(docId).update({
                                'status': status == 'resolved' || status == 'completed' || status == 'registered' ? 'Pending' : 'Resolved'
                              });
                            },
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            label: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Report?'),
                                  content: const Text('Are you sure you want to permanently delete this report?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await FirebaseFirestore.instance.collection('reports').doc(docId).delete();
                              }
                            },
                          ),
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
}
