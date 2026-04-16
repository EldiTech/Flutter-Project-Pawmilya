import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/pawmilya_palette.dart';
import 'package:intl/intl.dart';

class AdminFundsScreen extends StatelessWidget {
  const AdminFundsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PawmilyaPalette.creamBottom,
      appBar: AppBar(
        title: const Text('Platform Funds', style: TextStyle(color: PawmilyaPalette.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: PawmilyaPalette.creamTop,
        elevation: 0,
        iconTheme: const IconThemeData(color: PawmilyaPalette.textPrimary),
      ),
      body: Column(
        children: [
          // Total Balance Card
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('admin').doc('funds').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('Error loading funds.'));
              if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator());

              double totalFunds = 0;
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                totalFunds = (data['totalBalance'] as num?)?.toDouble() ?? 0.0;
              }

              return Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE0A95F), Color(0xFFB86C2E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: PawmilyaPalette.gold.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 36),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Platform Funds', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                        Text('₱${totalFunds.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Transaction History list
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PawmilyaPalette.textPrimary)),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('admin')
                          .doc('funds')
                          .collection('transactions')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return const Center(child: Text('Error loading history.'));
                        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Center(child: Text('No transactions yet.', style: TextStyle(color: PawmilyaPalette.textSecondary)));
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final tx = docs[index].data() as Map<String, dynamic>;
                            final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                            final date = tx['timestamp'] != null 
                                ? DateFormat('MMM dd, yyyy - hh:mm a').format((tx['timestamp'] as Timestamp).toDate()) 
                                : 'Recent';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.green.shade50,
                                    child: Icon(Icons.arrow_downward_rounded, color: Colors.green.shade400, size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(tx['description'] ?? '5% Platform Fee', style: const TextStyle(fontWeight: FontWeight.bold, color: PawmilyaPalette.textPrimary)),
                                        const SizedBox(height: 4),
                                        Text(date, style: const TextStyle(fontSize: 12, color: PawmilyaPalette.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Text('+₱${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}