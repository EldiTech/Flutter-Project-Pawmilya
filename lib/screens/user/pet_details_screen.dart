import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme/pawmilya_palette.dart';
import 'adoption_checkout_screen.dart';

class PetDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> petData;

  const PetDetailsScreen({super.key, required this.petData});

  @override
  Widget build(BuildContext context) {
    final petType = petData['type'] ?? petData['category'] ?? 'Dogs';
    final name = petData['name'] ?? 'Unknown Buddy';
    final breed = petData['breed'] ?? 'Unknown Breed';
    final age = petData['age']?.toString() ?? 'Unknown Age';
    final gender = petData['gender'] ?? 'Unknown';
    final description = petData['description'] ?? 'No description available.';
    final adoptionFee = petData['adoptionFee']?.toString() ?? '500.00'; 

    return Scaffold(
      backgroundColor: PawmilyaPalette.creamTop,
      appBar: AppBar(
        title: Text(name, style: const TextStyle(color: PawmilyaPalette.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: PawmilyaPalette.textPrimary),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE8D6),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: (petData['imageUrl'] != null && petData['imageUrl'].isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: petData['imageUrl'].toString().startsWith('http')
                              ? Image.network(petData['imageUrl'], fit: BoxFit.cover)
                              : Image.memory(base64Decode(petData['imageUrl']), fit: BoxFit.cover),
                        )
                      : Icon(
                          petType == 'Cats' ? Icons.pets : (petType == 'Birds' ? Icons.flutter_dash : Icons.catching_pokemon),
                          size: 80,
                          color: Colors.black12,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: PawmilyaPalette.textPrimary)),
                      ),
                      Text('₱$adoptionFee', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('$breed • $age • $gender', style: const TextStyle(fontSize: 16, color: PawmilyaPalette.textSecondary)),
                  const SizedBox(height: 24),
                  const Text('About Me', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: PawmilyaPalette.textPrimary)),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(fontSize: 15, height: 1.5, color: PawmilyaPalette.textSecondary.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PawmilyaPalette.shelterGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdoptionCheckoutScreen(petData: petData)),
                  );
                },
                child: const Text('Adopt Me Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
