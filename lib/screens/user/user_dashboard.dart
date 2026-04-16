import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/pawmilya_palette.dart';
import '../notifications_screen.dart';
import 'report_animal_screen.dart';
import 'adoptable_pets_tab.dart';
import 'jemoy_space_tab.dart';
import 'user_settings_tab.dart';
import 'pet_details_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  late final List<Widget> _pages = [
    HomeDashboardTab(
      onSeeAllAdopt: () {
        setState(() {
          _currentIndex = 2;
        });
      },
    ),
    const ReportAnimalTab(),
    const AdoptablePetsTab(),
    const JemoySpaceTab(),
    const UserSettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final glow = 0.84 + (0.16 * _pulseController.value);

          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  PawmilyaPalette.creamTop,
                  PawmilyaPalette.creamMid,
                  PawmilyaPalette.creamBottom,
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -80,
                  right: -70,
                  child: _GlowOrb(size: 240, glow: glow),
                ),
                Positioned(
                  bottom: -110,
                  left: -80,
                  child: _GlowOrb(size: 280, glow: glow * 0.92),
                ),
                child!, // AnimatedSwitcher (Pages)
              ],
            ),
          );
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFD08E43),
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_problem_rounded),
              label: 'Report',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets_rounded),
              label: 'Adopt',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.catching_pokemon_rounded), // Using pet-face like icon for Jemoy
              label: 'Jemoy',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeDashboardTab extends StatefulWidget {
  final VoidCallback? onSeeAllAdopt;
  const HomeDashboardTab({super.key, this.onSeeAllAdopt});

  @override
  State<HomeDashboardTab> createState() => _HomeDashboardTabState();
}

class _HomeDashboardTabState extends State<HomeDashboardTab> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'User';

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $userName 👋',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: PawmilyaPalette.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ready to find your new best friend?',
                              style: TextStyle(
                                fontSize: 16,
                                color: PawmilyaPalette.textSecondary.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_none, size: 28, color: PawmilyaPalette.textPrimary),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => NotificationsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                _buildCategories(),
                const SizedBox(height: 28),
                _buildFeaturedCarousel(),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildSectionHeader('Available for Adoption', onSeeAll: widget.onSeeAllAdopt),
                ),
                const SizedBox(height: 16),
                _buildAvailableCarousel(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: PawmilyaPalette.textPrimary,
          ),
        ),
        TextButton(
          onPressed: onSeeAll ?? () {},
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFD08E43),
          ),
          child: const Text('See All', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildAvailableCarousel() {
    Query query = FirebaseFirestore.instance.collection('pets').where('status', isEqualTo: 'available');
    if (_selectedCategory != 'All') {
      query = query.where('type', isEqualTo: _selectedCategory);
    }
    
    return SizedBox(
      height: 240,
      child: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading pets'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No pets available for adoption.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final pet = docs[index].data() as Map<String, dynamic>;
              return SizedBox(
                width: 180,
                child: _PetCard(pet: pet, index: index),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCategories() {
    final categories = ['All', 'Dogs', 'Cats'];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == categories[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = categories[index]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFD08E43) : Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                categories[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : PawmilyaPalette.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedCarousel() {
    Query query = FirebaseFirestore.instance.collection('pets').where('status', isEqualTo: 'available').where('isUrgent', isEqualTo: true);
    if (_selectedCategory != 'All') {
      query = query.where('type', isEqualTo: _selectedCategory);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: const [
              Icon(Icons.local_fire_department_rounded, color: Colors.deepOrange, size: 20),
              SizedBox(width: 8),
              Text(
                'Urgent Adoptions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: PawmilyaPalette.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: StreamBuilder<QuerySnapshot>(
            stream: query.limit(5).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading urgent pets'));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No urgent adoptions right now.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final pet = docs[index].data() as Map<String, dynamic>;
                  final petType = pet['type'] ?? pet['category'] ?? 'Dogs';

                    return GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (context) => FractionallySizedBox(
                            heightFactor: 0.9,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              child: PetDetailsScreen(petData: pet),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 280,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                          ),
                          child: (pet['imageUrl'] != null && pet['imageUrl'].isNotEmpty)
                            ? ClipRRect(
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                                child: pet['imageUrl'].toString().startsWith('http')
                                    ? Image.network(pet['imageUrl'], fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                                    : Image.memory(base64Decode(pet['imageUrl']), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                              )
                            : Icon(petType == 'Cats' ? Icons.pets : Icons.catching_pokemon_rounded, size: 40, color: Colors.grey),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Urgent', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 8),
                                Text(pet['name'] ?? 'Buddy $index', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PawmilyaPalette.textPrimary)),
                                const SizedBox(height: 4),
                                Text(pet['description'] ?? 'Needs immediate home', style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
          ),
        ),
      ],
    );
  }
}

class _PetCard extends StatelessWidget {
  final Map<String, dynamic> pet;
  final int index;
  const _PetCard({required this.pet, required this.index});

  @override
  Widget build(BuildContext context) {
    final petType = pet['type'] ?? pet['category'] ?? 'Dogs';
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => FractionallySizedBox(
            heightFactor: 0.9,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: PetDetailsScreen(petData: pet),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                color: Colors.grey[200],
                child: Center(
                  child: (pet['imageUrl'] != null && pet['imageUrl'].isNotEmpty)
                      ? pet['imageUrl'].toString().startsWith('http')
                          ? Image.network(pet['imageUrl'], fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                          : Image.memory(base64Decode(pet['imageUrl']), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                      : Icon(
                          petType == 'Cats' ? Icons.pets : Icons.catching_pokemon_rounded,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    pet['name'] ?? 'Pet ${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: PawmilyaPalette.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pet['location'] ?? pet['distance']?.toString() ?? 'City Shelter',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
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

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.glow});

  final double size;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            PawmilyaPalette.goldLight.withValues(alpha: 0.18 * glow),
            PawmilyaPalette.gold.withValues(alpha: 0.1 * glow),
            Colors.transparent,
          ],
          stops: const [0.1, 0.5, 1],
        ),
      ),
    );
  }
}
