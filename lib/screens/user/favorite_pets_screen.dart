import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/pawmilya_palette.dart';
import 'pet_details_screen.dart';

class FavoritePetsScreen extends StatefulWidget {
  const FavoritePetsScreen({super.key});

  @override
  State<FavoritePetsScreen> createState() => _FavoritePetsScreenState();
}

class _FavoritePetsScreenState extends State<FavoritePetsScreen> {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        backgroundColor: PawmilyaPalette.creamTop,
      ),
      body: _favorites.isEmpty
          ? const Center(
              child: Text(
                'No favorite pets yet.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pets').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: PawmilyaPalette.gold));
                }

                final docs = snapshot.data?.docs ?? [];
                
                // Filter locally because whereIn has a 10 item limit
                final filteredPets = docs.where((doc) => _favorites.contains(doc.id)).map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  return data;
                }).toList();

                if (filteredPets.isEmpty) {
                  return const Center(
                    child: Text(
                      'No favorite pets available right now.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(24).copyWith(bottom: 32),
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
            // Image Section
            Expanded(
              flex: 13,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    (pet['imageUrl'] != null && pet['imageUrl'].isNotEmpty)
                        ? (pet['imageUrl'].startsWith('http')
                            ? Image.network(pet['imageUrl'], fit: BoxFit.cover, errorBuilder: (c, e, s) => const ColoredBox(color: Colors.grey))
                            : Image.memory(base64Decode(pet['imageUrl'].split(',').last), fit: BoxFit.cover, errorBuilder: (c, e, s) => const ColoredBox(color: Colors.grey)))
                        : ColoredBox(
                            color: Colors.grey[200]!,
                            child: Icon(
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
                            '${pet['age'] ?? '?'}',
                            style: const TextStyle(
                              color: PawmilyaPalette.goldDark,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
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
