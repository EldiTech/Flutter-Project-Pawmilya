import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';
import '../../theme/pawmilya_palette.dart';

class AdoptionCheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> petData;

  const AdoptionCheckoutScreen({super.key, required this.petData});

  @override
  State<AdoptionCheckoutScreen> createState() => _AdoptionCheckoutScreenState();
}

class _AdoptionCheckoutScreenState extends State<AdoptionCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String _paymentMethod = 'Credit / Debit Card';
  bool _isProcessing = false;
  bool _isLoadingUserData = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (mounted) {
            setState(() {
              _nameController.text = data['realName'] ?? data['name'] ?? data['username'] ?? '';
              _contactController.text = data['phoneNumber'] ?? data['contact'] ?? data['phone'] ?? '';
              _addressController.text = data['address'] ?? '';
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
      }
    }
  }

  void _processPayment() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final petId = widget.petData['id'];
      final shelterId = widget.petData['shelterId']; 
      final feeString = widget.petData['adoptionFee']?.toString() ?? '500.0';
      final double adoptionFee = double.tryParse(feeString) ?? 500.0;
      final double platformFee = adoptionFee * 0.05;
      final double totalAmount = adoptionFee + platformFee;
      final petName = widget.petData['name'] ?? 'Pet';

      if (petId == null) throw Exception('Pet ID is missing.');

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. Perform all READS first (Firestore requirement)
        DocumentSnapshot? shelterSnap;
        DocumentReference? shelterRef;
        if (shelterId != null) {
          shelterRef = FirebaseFirestore.instance.collection('shelters').doc(shelterId);
          shelterSnap = await transaction.get(shelterRef);
        }

        final adminFundsRef = FirebaseFirestore.instance.collection('admin').doc('funds');
        final adminFundsSnap = await transaction.get(adminFundsRef);

        // 2. Perform all WRITES
        // Update the Pet Status
        final petRef = FirebaseFirestore.instance.collection('pets').doc(petId);
        transaction.update(petRef, {'status': 'processing adoption'});

        // Transfer adoption fee to Shelter Balance
        if (shelterRef != null && shelterSnap != null && shelterSnap.exists && shelterSnap.data() != null) {
          final data = shelterSnap.data() as Map<String, dynamic>;
          double currentBalance = 0.0;
          if (data.containsKey('balance')) {
            currentBalance = (data['balance'] as num).toDouble();
          }
          transaction.update(shelterRef, {'balance': currentBalance + adoptionFee});
          
          // Log as transaction history for shelter UI
          final shelterTransRef = shelterRef.collection('transactions').doc();
          transaction.set(shelterTransRef, {
            'amount': adoptionFee,
            'type': 'income',
            'category': 'adoption',
            'description': 'Adoption Fee: $petName',
            'timestamp': FieldValue.serverTimestamp(),
          });
        }

        // Add 5% to Admin Platform Funds
        double adminBalance = 0.0;
        if (adminFundsSnap.exists && adminFundsSnap.data() != null) {
          final adminData = adminFundsSnap.data() as Map<String, dynamic>;
          if (adminData.containsKey('totalBalance')) {
            adminBalance = (adminData['totalBalance'] as num).toDouble();
          }
        }
        transaction.set(adminFundsRef, {'totalBalance': adminBalance + platformFee}, SetOptions(merge: true));
        
        final adminTransRef = adminFundsRef.collection('transactions').doc();
        transaction.set(adminTransRef, {
          'amount': platformFee,
          'type': 'platform_fee',
          'description': '5% Fee from $petName Adoption',
          'shelterId': shelterId ?? 'unknown',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // 3. Create an adoption record
        final adoptionRef = FirebaseFirestore.instance.collection('adoptions').doc();
        transaction.set(adoptionRef, {
          'petId': petId,
          'petName': petName,
          'petImageUrl': widget.petData['imageUrl'] ?? '',
          'shelterId': shelterId ?? 'unknown',            'shelterName': widget.petData['shelterName'] ?? 'Partner Shelter',          'status': 'Processing', // 'Processing', 'On the Way', 'Completed'
          'adopterId': user?.uid ?? 'guest',
          'adopterName': _nameController.text.trim(),
          'adopterContact': _contactController.text.trim(),
          'adopterAddress': _addressController.text.trim(),
          'feeAmount': totalAmount,
          'adoptionFeeOnly': adoptionFee,
          'platformFee': platformFee,
          'paymentMethod': _paymentMethod,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      // Send a notification to the user about their adoption application
      if (user?.uid != null) {
        await NotificationService().createNotification(
          title: 'Adoption Application Submitted',
          message: 'Your adoption application for $petName is now processing. The shelter will contact you soon.',
          recipientId: user!.uid,
          type: 'adoption',
        );
      }

      if (mounted) {
        setState(() => _isProcessing = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: PawmilyaPalette.creamTop,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Payment Successful!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: PawmilyaPalette.textPrimary)),
            const SizedBox(height: 12),
            Text(
              'Thank you for adopting ${widget.petData['name']}! The shelter has received your adoption fee.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: PawmilyaPalette.textSecondary),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: PawmilyaPalette.shelterGold, foregroundColor: Colors.white),
            onPressed: () {
              // Pop the dialog and go back to the user dashboard
              Navigator.of(context).pop(); // dismiss dialog
              Navigator.of(context).pop(); // dismiss checkout screen
              Navigator.of(context).pop(); // dismiss pet details screen
            },
            child: const Center(child: Text('Return Home')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feeString = widget.petData['adoptionFee']?.toString() ?? '500.00';
    final double adoptionFee = double.tryParse(feeString) ?? 500.0;
    final double platformFee = adoptionFee * 0.05;
    final double totalAmount = adoptionFee + platformFee;

    return Scaffold(
      backgroundColor: PawmilyaPalette.creamMid,
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(color: PawmilyaPalette.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: PawmilyaPalette.textPrimary),
      ),
        body: _isProcessing || _isLoadingUserData
          ? const Center(child: CircularProgressIndicator(color: PawmilyaPalette.shelterGold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Billing Summary Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Billing Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PawmilyaPalette.textPrimary)),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Adoption Fee for ${widget.petData['name']}', style: const TextStyle(color: PawmilyaPalette.textSecondary)),
                              Text('₱${adoptionFee.toStringAsFixed(2)}', style: const TextStyle(color: PawmilyaPalette.textPrimary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Platform Processing Fee (5%)', style: TextStyle(color: PawmilyaPalette.textSecondary)),
                              Text('₱${platformFee.toStringAsFixed(2)}', style: const TextStyle(color: PawmilyaPalette.textPrimary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PawmilyaPalette.textPrimary)),
                              Text('₱${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    const Text('Adopter Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PawmilyaPalette.textPrimary)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDeco('Full Name', Icons.person),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contactController,
                      decoration: _inputDeco('Phone Number', Icons.phone),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: _inputDeco('Full Address', Icons.home),
                      maxLines: 2,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),

                    const SizedBox(height: 32),
                    const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PawmilyaPalette.textPrimary)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _paymentMethod,
                      decoration: _inputDeco('Select Method', Icons.payments),
                      items: const [
                        DropdownMenuItem(value: 'Credit / Debit Card', child: Text('Credit / Debit Card')),
                        DropdownMenuItem(value: 'GCash', child: Text('GCash')),
                        DropdownMenuItem(value: 'Maya', child: Text('Maya')),
                        DropdownMenuItem(value: 'Cash on Arrival', child: Text('Cash on Arrival')),
                      ],
                      onChanged: (val) => setState(() => _paymentMethod = val!),
                    ),

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _processPayment,
                        child: Text('Pay ₱${totalAmount.toStringAsFixed(2)} Now', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: PawmilyaPalette.textSecondary),
      prefixIcon: Icon(icon, color: PawmilyaPalette.textSecondary),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}