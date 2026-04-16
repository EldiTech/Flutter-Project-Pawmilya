import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'shelter_edit_profile_screen.dart';
import 'shelter_settings_screen.dart';
import 'shelter_active_rescues_screen.dart';
import 'pets_in_care_screen.dart';
import 'for_adoption_screen.dart';
import 'funds_screen.dart';
import 'shelter_applications_screen.dart';
import 'shelter_room_screen.dart';
import '../notifications_screen.dart';

class ShelterMenuScreen extends StatelessWidget {
  const ShelterMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Shelter Management'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF2C3E50),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShelterSettingsScreen()),
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dynamic Shelter Profile Section
              const _ShelterProfileSection(),

              const SizedBox(height: 24),

              const Text(
                'Operations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 16),

              // Grid Menu
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                   _DashboardCard(
                    title: 'Active Rescues',
                    icon: Icons.health_and_safety_rounded,
                    color: const Color(0xFFE74C3C),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ShelterActiveRescuesScreen(),
                        ),
                      );
                    },
                  ),
                  _DashboardCard(
                    title: 'Shelter Rooms',
                    icon: Icons.meeting_room_rounded,
                    color: const Color(0xFF8E44AD),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ShelterRoomScreen(),
                        ),
                      );
                    },
                  ),
                  _DashboardCard(
                    title: 'Pets in Care',
                    icon: Icons.pets_rounded,
                    color: const Color(0xFFF39C12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PetsInCareScreen(),
                        ),
                      );
                    },
                  ),
                  _DashboardCard(
                    title: 'For Adoption',
                    icon: Icons.volunteer_activism_rounded,
                    color: const Color(0xFFE84393),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForAdoptionScreen(),
                        ),
                      );
                    },
                  ),
                  _DashboardCard(
                    title: 'Adoption Tracking',
                    icon: Icons.assignment_rounded,
                    color: const Color(0xFF3498DB),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ShelterApplicationsScreen(),
                        ),
                      );
                    },
                  ),
                  _DashboardCard(
                    title: 'Funds',
                    icon: Icons.account_balance_wallet_rounded,
                    color: const Color(0xFF16A085),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FundsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShelterProfileSection extends StatelessWidget {
  const _ShelterProfileSection();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('shelters').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final shelterName = data?['shelterName'] ?? 'Unknown Shelter';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECF0F1),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFBDC3C7), width: 1),
                    ),
                    child: const Icon(Icons.storefront_rounded, size: 36, color: Color(0xFF7F8C8D)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                shelterName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: Color(0xFF3498DB), size: 18),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Verified Shelter',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3498DB),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_square, color: Color(0xFF95A5A6)),
                    onPressed: () {
                      if (data != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShelterEditProfileScreen(initialData: data),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      }
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title section coming soon!')),
        );
      },
      borderRadius: BorderRadius.circular(20),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50), // Dark text for readability
              ),
            ),
          ],
        ),
      ),
    );
  }
}