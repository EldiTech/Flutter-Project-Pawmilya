import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/pawmilya_palette.dart';
import '../enter_system_landing_screen.dart';
import 'admin_pets_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_users_screen.dart';
import 'admin_pending_shelters_screen.dart';
import 'admin_active_shelters_screen.dart';
import 'admin_funds_screen.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  late Future<int> _totalPets;
  late Future<int> _activeShelters;
  late Future<int> _activeUsers;
  late Future<int> _pendingApps;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _totalPets = FirebaseFirestore.instance
        .collection('pets')
        .count()
        .get()
        .then((res) => res.count ?? 0);
    _activeShelters = FirebaseFirestore.instance
        .collection('shelters')
        .where('status', isEqualTo: 'approved')
        .count()
        .get()
        .then((res) => res.count ?? 0);
    _activeUsers = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'user')
        .count()
        .get()
        .then((res) => res.count ?? 0);
    _pendingApps = FirebaseFirestore.instance
        .collection('shelters')
        .where('status', isEqualTo: 'pending_verification')
        .count()
        .get()
        .then((res) => res.count ?? 0);
  }

  Future<void> _refreshData() async {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Clean, light gray background
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: PawmilyaPalette.gold,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildDashboardSummary(),
                const SizedBox(height: 32),
                _buildSectionTitle('📌 Management'),
                const SizedBox(height: 12),
                _buildManagementCard(
                  context,
                  title: 'Manage Listed Pets',
                  icon: Icons.pets_rounded,
                  color: PawmilyaPalette.gold,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AdminPetsScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<int>(
                  future: _pendingApps,
                  builder: (context, snapshot) {
                    int badgeCount = snapshot.data ?? 0;
                    return _buildManagementCard(
                      context,
                      title: 'Shelter Applications',
                      icon: Icons.assignment_rounded,
                      color: PawmilyaPalette.gold,
                      badgeCount: badgeCount,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const AdminPendingSheltersScreen()),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                FutureBuilder<int>(
                  future: _activeShelters,
                  builder: (context, snapshot) {
                    return _buildManagementCard(
                      context,
                      title: 'Active Shelters',
                      icon: Icons.store_mall_directory_rounded,
                      color: PawmilyaPalette.gold,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const AdminActiveSheltersScreen()),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('💰 Financials'),
                const SizedBox(height: 12),
                _buildManagementCard(
                  context,
                  title: 'Platform Funds (5% Fee)',
                  icon: Icons.account_balance_wallet_rounded,
                  color: Colors.green,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AdminFundsScreen()),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('📌 Monitoring'),
                const SizedBox(height: 12),
                _buildManagementCard(
                  context,
                  title: 'Manage Reports',
                  icon: Icons.warning_rounded,
                  color: PawmilyaPalette.gold,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AdminReportsScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _buildManagementCard(
                  context,
                  title: 'Active Users',
                  icon: Icons.people_alt_rounded,
                  color: PawmilyaPalette.gold,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AdminUsersScreen()),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('📌 System'),
                const SizedBox(height: 12),
                _buildManagementCard(
                  context,
                  title: 'Settings',
                  subtitle: 'Change admin password',
                  icon: Icons.settings_rounded,
                  color: Colors.blueGrey,
                  onTap: () => _showChangePasswordDialog(context),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hello, Admin 👋',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: PawmilyaPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your system efficiently',
              style: TextStyle(
                fontSize: 14,
                color: PawmilyaPalette.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        PopupMenuButton<String>(
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) async {
            if (value == 'logout') {
              await AuthService.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const EnterSystemLandingScreen(),
                  ),
                  (route) => false,
                );
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          child: const CircleAvatar(
            radius: 24,
            backgroundColor: PawmilyaPalette.creamTop,
            child: Icon(
              Icons.admin_panel_settings_rounded,
              color: PawmilyaPalette.gold,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardSummary() {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatFutureCard(
          title: 'Total Pets',
          future: _totalPets,
          icon: Icons.pets_rounded,
          color: Colors.orange,
        ),
        _buildStatFutureCard(
          title: 'Active Shelters',
          future: _activeShelters,
          icon: Icons.home_work_rounded,
          color: Colors.green,
        ),
        _buildStatFutureCard(
          title: 'Active Users',
          future: _activeUsers,
          icon: Icons.people_alt_rounded,
          color: Colors.blue,
        ),
        _buildStatFutureCard(
          title: 'Pending Apps',
          future: _pendingApps,
          icon: Icons.pending_actions_rounded,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatFutureCard({
    required String title,
    required Future<int> future,
    required IconData icon,
    required Color color,
  }) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) {
        Widget countWidget;
        if (snapshot.connectionState == ConnectionState.waiting) {
          countWidget = SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
          );
        } else if (snapshot.hasError) {
          countWidget = const Text(
            'Err',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          );
        } else {
          countWidget = Text(
            (snapshot.data ?? 0).toString(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: PawmilyaPalette.textPrimary,
            ),
          );
        }
        return _buildStatCard(title, countWidget, icon, color);
      },
    );
  }

  Widget _buildStatCard(
    String title,
    Widget countWidget,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              countWidget,
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: PawmilyaPalette.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: PawmilyaPalette.textPrimary,
        letterSpacing: 0.5,
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Change Password'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: oldPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Old Password',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your old password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New Password',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm New Password',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value != newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: PawmilyaPalette.textSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PawmilyaPalette.gold,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setState(() => isSubmitting = true);

                          try {
                            await AuthService.instance.changePassword(
                              oldPassword: oldPasswordController.text,
                              newPassword: newPasswordController.text,
                            );

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password updated successfully.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            if (!dialogContext.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AuthService.instance.mapError(e)),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            if (dialogContext.mounted) {
                              setState(() => isSubmitting = false);
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required Color color,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 16.0,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: PawmilyaPalette.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: PawmilyaPalette.textSecondary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
