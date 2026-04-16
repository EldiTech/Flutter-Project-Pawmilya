import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/pawmilya_palette.dart';

class FundsScreen extends StatefulWidget {
  const FundsScreen({super.key});

  @override
  State<FundsScreen> createState() => _FundsScreenState();
}

class _FundsScreenState extends State<FundsScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;

  void _showAddFundsDialog({bool isAdoption = false}) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PawmilyaPalette.creamTop,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isAdoption ? 'Simulate Adoption Payment' : 'Add Funds', style: const TextStyle(color: PawmilyaPalette.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isAdoption ? 'Receive payment from a new pet adoption.' : 'Simulate receiving a grant or donation.',
              style: const TextStyle(color: PawmilyaPalette.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount (₱)',
                prefixIcon: const Icon(Icons.attach_money, color: PawmilyaPalette.goldDark),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: PawmilyaPalette.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PawmilyaPalette.shelterGold,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (_user == null) return;
              final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
              if (amount <= 0) return;

              final shelterRef = FirebaseFirestore.instance.collection('shelters').doc(_user.uid);

              await FirebaseFirestore.instance.runTransaction((transaction) async {
                final snap = await transaction.get(shelterRef);
                double currentBalance = 0.0;
                if (snap.exists && snap.data() != null && snap.data()!.containsKey('balance')) {
                  currentBalance = (snap.data()!['balance'] as num).toDouble();
                }

                transaction.set(shelterRef, {'balance': currentBalance + amount}, SetOptions(merge: true));

                final transRef = shelterRef.collection('transactions').doc();
                transaction.set(transRef, {
                  'amount': amount,
                  'type': 'income',
                  'category': isAdoption ? 'adoption' : 'donation',
                  'description': isAdoption ? 'Adoption Fee Payment' : 'Manual Fund Addition',
                  'timestamp': FieldValue.serverTimestamp(),
                });
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isAdoption ? 'Adoption payment received!' : 'Funds added successfully!'), backgroundColor: Colors.green),
                );
              }
            },
            child: Text(isAdoption ? 'Process Payment' : 'Add Funds'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: Center(child: Text('User not logged in.')));
    }

    final shelterRef = FirebaseFirestore.instance.collection('shelters').doc(_user.uid);

    return Scaffold(
      backgroundColor: PawmilyaPalette.creamMid,
      appBar: AppBar(
        title: const Text('Financial Overview', style: TextStyle(color: PawmilyaPalette.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: PawmilyaPalette.creamTop,
        elevation: 0,
        iconTheme: const IconThemeData(color: PawmilyaPalette.textPrimary),
      ),
      body: Column(
        children: [
          // Balance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: PawmilyaPalette.creamTop,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: StreamBuilder<DocumentSnapshot>(
              stream: shelterRef.snapshots(),
              builder: (context, snapshot) {
                double balance = 0.0;
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  if (data.containsKey('balance')) {
                    balance = (data['balance'] as num).toDouble();
                  }
                }

                return Column(
                  children: [
                    const Text('Available Balance', style: TextStyle(color: PawmilyaPalette.textSecondary, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      '₱${balance.toStringAsFixed(2)}',
                      style: const TextStyle(color: PawmilyaPalette.textPrimary, fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PawmilyaPalette.goldDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onPressed: () => _showAddFundsDialog(isAdoption: false),
                          icon: const Icon(Icons.add_card, size: 20),
                          label: const Text('Add Funds', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onPressed: () => _showAddFundsDialog(isAdoption: true),
                          icon: const Icon(Icons.pets, size: 20),
                          label: const Text('Adoption Pay', style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    )
                  ],
                );
              },
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PawmilyaPalette.textPrimary),
              ),
            ),
          ),

          // Transactions List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: shelterRef.collection('transactions').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: PawmilyaPalette.shelterGold));
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No transactions yet.', style: TextStyle(color: PawmilyaPalette.textSecondary)),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isIncome = data['type'] == 'income';
                    final amount = (data['amount'] ?? 0.0) as num;
                    final desc = data['description'] ?? 'Transaction';
                    
                    DateTime? date;
                    if (data['timestamp'] != null) {
                      date = (data['timestamp'] as Timestamp).toDate();
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
                          child: Icon(
                            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                        title: Text(desc, style: const TextStyle(fontWeight: FontWeight.bold, color: PawmilyaPalette.textPrimary)),
                        subtitle: Text(
                          date != null ? '${date.month}/${date.day}/${date.year}' : 'Pending',
                          style: const TextStyle(color: PawmilyaPalette.textSecondary, fontSize: 12),
                        ),
                        trailing: Text(
                          '${isIncome ? '+' : '-'} ₱${amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                          ),
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
}
