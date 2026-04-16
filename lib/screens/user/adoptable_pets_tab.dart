import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/notification_service.dart';
import '../../theme/pawmilya_palette.dart';
import 'pet_details_screen.dart';
import 'favorite_pets_screen.dart';

class AdoptablePetsTab extends StatefulWidget {
  const AdoptablePetsTab({super.key});

  @override
  State<AdoptablePetsTab> createState() => _AdoptablePetsTabState();
}

class _AdoptablePetsTabState extends State<AdoptablePetsTab> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Dogs', 'Cats', 'Birds', 'Others'];
  List<String> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((doc) {
        if (doc.exists && mounted) {
          setState(() {
            _favorites = List<String>.from(doc.data()?['favorites'] ?? []);
          });
        }
      });
    }
  }

  Future<void> _toggleFavorite(String petId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    if (_favorites.contains(petId)) {
      await docRef.update({
        'favorites': FieldValue.arrayRemove([petId])
      });
    } else {
      await docRef.update({
        'favorites': FieldValue.arrayUnion([petId])
      });
      // Example of triggering a system notification for the user
      await NotificationService().createNotification(
        title: 'Pet Saved!',
        message: 'You have favorited this pet. We will let you know if their status changes.',
        recipientId: user.uid,
        type: 'system',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Find a Buddy',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: PawmilyaPalette.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Adopt, don\'t shop. Give them a loving home.',
                        style: TextStyle(
                          fontSize: 16,
                          color: PawmilyaPalette.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FavoritePetsScreen()),
                    );
                  },
                  icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 28),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by breed or name...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Categories Filter
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final isSelected = _selectedCategory == _categories[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = _categories[index]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? PawmilyaPalette.gold : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? PawmilyaPalette.gold : Colors.grey[200]!,
                      ),
                      boxShadow: [
                        if (!isSelected)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _categories[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : PawmilyaPalette.textSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Grid View of Pets
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pets').where('status', isEqualTo: 'available').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: PawmilyaPalette.gold));
                }

                final docs = snapshot.data?.docs ?? [];
                final pets = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id; // Added to pass document ID
                  return data;
                }).toList();

                final filteredPets = _selectedCategory == 'All'
                    ? pets
                    : pets.where((p) => p['type'] == _selectedCategory || p['category'] == _selectedCategory).toList();

                if (filteredPets.isEmpty) {
                  return const Center(
                    child: Text(
                      'No pets found in this category.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8).copyWith(bottom: 32),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: filteredPets.length,
                  itemBuilder: (context, index) {
                    final petMap = filteredPets[index];
                    return _buildPetCard(petMap);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(Map<String, dynamic> pet) {
    final petType = pet['type'] ?? pet['category'] ?? 'Dogs';
    final petId = pet['id'];
    final isFavorite = _favorites.contains(petId);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PetDetailsScreen(petData: pet)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image / Avatar Placeholder
          Expanded(
            flex: 11,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFEE8D6), // generic background color
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: (pet['imageUrl'] != null && pet['imageUrl'].isNotEmpty)
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: pet['imageUrl'].toString().startsWith('http')
                              ? Image.network(pet['imageUrl'], fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                              : Image.memory(base64Decode(pet['imageUrl']), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                        )
                      : Icon(
                          petType == 'Cats'
                              ? Icons.pets
                              : (petType == 'Birds' ? Icons.flutter_dash : Icons.catching_pokemon),
                          size: 50,
                          color: Colors.black12,
                        ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(petId),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                          size: 18, 
                          color: isFavorite ? Colors.redAccent : Colors.grey
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Pet Information
          Expanded(
            flex: 10,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          pet['name'] ?? 'Unknown Buddy',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: PawmilyaPalette.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        pet['gender'] == 'Male' ? Icons.male_rounded : Icons.female_rounded,
                        size: 18,
                        color: pet['gender'] == 'Male' ? Colors.blue[300] : Colors.pink[300],
                      ),
                    ],
                  ),
                  Text(
                    pet['breed'] ?? 'Unknown Breed',
                    style: TextStyle(
                      fontSize: 12,
                      color: PawmilyaPalette.textSecondary.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: PawmilyaPalette.gold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pet['age']?.toString() ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: PawmilyaPalette.gold,
                          ),
                        ),
                      ),
                      if (pet['isUrgent'] == true) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'URGENT',
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Icon(Icons.location_on_rounded, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          pet['distance']?.toString() ?? pet['location'] ?? 'Nearby',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[500]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}