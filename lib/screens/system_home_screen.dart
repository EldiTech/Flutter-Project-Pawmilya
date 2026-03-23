import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/dashboard_stats.dart';
import '../models/shelter_profile.dart';
import '../providers/dashboard_provider.dart';
import '../screens/animal_management_screen.dart';
import '../screens/applications_screen.dart';
import '../screens/employee_management_screen.dart';
import '../screens/landing_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/shelter_room_screen.dart';
import '../theme/app_theme.dart';
import '../screens/view_records_screen.dart';
import '../widgets/dashboard/stats_grid.dart';

class SystemHomeScreen extends StatefulWidget {
  const SystemHomeScreen({super.key});

  @override
  State<SystemHomeScreen> createState() => _SystemHomeScreenState();
}

class _SystemHomeScreenState extends State<SystemHomeScreen> {
  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedNavItem = 'Home';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DashboardProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final profile = _resolvedProfile(provider.profile);
        final stats = provider.stats;

        return Scaffold(
          key: _mobileScaffoldKey,
          backgroundColor: AppColors.warmBg,
          appBar: _buildAppBar(profile),
          drawer: _buildDrawer(profile),
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              context.read<DashboardProvider>().initialize();
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth < 600 ? 16.0 : 24.0;

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: _DashboardContent(
                        stats: stats,
                        isLoading: provider.isLoading,
                        errorMessage: provider.error,
                        firstName: _firstName(profile),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  ShelterProfile _resolvedProfile(ShelterProfile? profile) {
    final user = FirebaseAuth.instance.currentUser;
    final fallbackEmail = user?.email ?? '';

    return profile ?? ShelterProfile.empty(fallbackEmail: fallbackEmail);
  }

  String _displayName(ShelterProfile profile) {
    if (profile.ownerName.trim().isNotEmpty) return profile.ownerName.trim();
    if (profile.shelterName.trim().isNotEmpty) return profile.shelterName.trim();
    if (profile.email.trim().isNotEmpty) return profile.email.trim();
    return 'User';
  }

  String _firstName(ShelterProfile profile) {
    final name = _displayName(profile);
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'User';

    if (trimmed.contains(' ')) {
      return trimmed.split(' ').first;
    }

    if (trimmed.contains('@')) {
      final local = trimmed.split('@').first.trim();
      if (local.isNotEmpty) return local;
    }

    return trimmed;
  }

  AppBar _buildAppBar(ShelterProfile profile) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        onPressed: () => _mobileScaffoldKey.currentState?.openDrawer(),
        icon: const Icon(Icons.menu, color: AppColors.textDark),
        tooltip: 'Open menu',
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'System Dashboard',
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          Text(
            'Shelter operations overview',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _AnimatedProfileButton(
            initial: _firstName(profile).characters.first.toUpperCase(),
            onTap: () => _showProfileSheet(profile),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(ShelterProfile profile) {
    final primaryItems = <({String label, IconData icon})>[
      (label: 'Home', icon: Icons.home_rounded),
      (label: 'Pets', icon: Icons.pets_rounded),
      (label: 'Services', icon: Icons.medical_services_rounded),
    ];

    final managementItems = <({String label, IconData icon})>[
      (label: 'Animal Management', icon: Icons.pets_rounded),
      (label: 'Employee Management', icon: Icons.badge_rounded),
      (label: 'View Records', icon: Icons.folder_open_rounded),
      (label: 'Applications', icon: Icons.assignment_turned_in_rounded),
      (label: 'Reports', icon: Icons.query_stats_rounded),
      (label: 'Shelter Room', icon: Icons.home_work_rounded),
    ];

    final accountItems = <({String label, IconData icon})>[
      (label: 'Settings', icon: Icons.settings_rounded),
      (label: 'Logout', icon: Icons.logout_rounded),
    ];

    final items = <({String label, IconData icon})>[
      ...primaryItems,
      ...managementItems,
      ...accountItems,
    ];

    final primaryEndIndex = primaryItems.length - 1;
    final managementEndIndex = primaryItems.length + managementItems.length - 1;

    return Drawer(
      backgroundColor: Colors.white,
      width: 300,
      child: SafeArea(
        child: Column(
          children: [
            _DrawerProfileHeader(
              name: _displayName(profile),
              email: profile.email.trim().isEmpty ? 'No email available' : profile.email.trim(),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    index == primaryEndIndex || index == managementEndIndex
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1),
                      )
                    : const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _DrawerNavTile(
                    icon: item.icon,
                    label: item.label,
                    selected: _selectedNavItem == item.label,
                    onTap: () async {
                      Navigator.of(context).pop();

                      if (item.label == 'Logout') {
                        await context.read<DashboardProvider>().stopForSignOut();
                        await FirebaseAuth.instance.signOut();
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LandingScreen()),
                          (_) => false,
                        );
                        return;
                      }

                      if (!mounted) return;
                      setState(() => _selectedNavItem = item.label);
                      await _handleNavigation(item.label);
                    },
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Divider(height: 1),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  const Icon(Icons.favorite_outline, color: AppColors.textMuted, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pawmilya Admin Panel',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeatureNotice(String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label is available in this build.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _handleNavigation(String label) async {
    Widget? target;
    switch (label) {
      case 'Home':
        return;
      case 'Pets':
      case 'Animal Management':
        target = const AnimalManagementScreen();
        break;
      case 'Applications':
        target = const ApplicationsScreen();
        break;
      case 'Employee Management':
        target = const EmployeeManagementScreen();
        break;
      case 'Shelter Room':
        target = const ShelterRoomScreen();
        break;
      case 'Reports':
        target = const ReportsScreen();
        break;
      case 'View Records':
        target = const ViewRecordsScreen();
        break;
      default:
        _showFeatureNotice(label);
        return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => target!),
    );
  }

  void _showProfileSheet(ShelterProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 320),
        reverseDuration: Duration(milliseconds: 220),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SingleChildScrollView(
              child: _ProfileCard(profile: profile),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.stats,
    required this.isLoading,
    required this.errorMessage,
    required this.firstName,
  });

  final DashboardStats stats;
  final bool isLoading;
  final String? errorMessage;
  final String firstName;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLarge = constraints.maxWidth >= 1000;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WelcomeCard(firstName: firstName, stats: stats),
            const SizedBox(height: 16),
            if (isLoading) ...[
              const LinearProgressIndicator(
                minHeight: 3,
                color: AppColors.primary,
                backgroundColor: AppColors.warmAccent,
              ),
              const SizedBox(height: 16),
            ],
            if (!isLarge) ...[
              const _SectionTitle(title: 'Overview', subtitle: 'Live shelter metrics'),
              const SizedBox(height: 12),
              StatsGrid(stats: stats),
            ] else ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(title: 'Overview', subtitle: 'Live shelter metrics'),
                  const SizedBox(height: 12),
                  StatsGrid(stats: stats),
                ],
              ),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: errorMessage!),
            ],
          ],
        );
      },
    );
  }
}

class _DrawerProfileHeader extends StatelessWidget {
  const _DrawerProfileHeader({
    required this.name,
    required this.email,
  });

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'U' : name.trim().characters.first.toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              child: Text(
                initial,
                style: GoogleFonts.quicksand(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: selected ? 1 : 0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: Color.lerp(
              Colors.transparent,
              AppColors.warmAccent.withValues(alpha: 0.6),
              value,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: child,
        );
      },
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Icon(
            icon,
            key: ValueKey<bool>(selected),
            color: selected ? AppColors.primary : AppColors.textMuted,
          ),
        ),
        title: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            color: selected ? AppColors.primary : AppColors.textDark,
          ),
          child: Text(label),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _AnimatedProfileButton extends StatefulWidget {
  const _AnimatedProfileButton({
    required this.initial,
    required this.onTap,
  });

  final String initial;
  final VoidCallback onTap;

  @override
  State<_AnimatedProfileButton> createState() => _AnimatedProfileButtonState();
}

class _AnimatedProfileButtonState extends State<_AnimatedProfileButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.92 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onHighlightChanged: (value) {
          setState(() => _pressed = value);
        },
        onTap: widget.onTap,
        child: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.warmAccent.withValues(alpha: 0.4),
          child: Text(
            widget.initial,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.quicksand(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.firstName, required this.stats});

  final String firstName;
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $firstName',
                  style: GoogleFonts.quicksand(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You have ${stats.pendingApplications} pending applications and ${stats.totalAnimals} animals in care.',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.paw,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final ShelterProfile profile;

  String _safeValue(String value) {
    return value.trim().isEmpty ? '—' : value.trim();
  }

  @override
  Widget build(BuildContext context) {
    final createdAtText = profile.createdAt == null
        ? '—'
        : MaterialLocalizations.of(context).formatFullDate(profile.createdAt!);

    final fields = <({String label, String value})>[
      (label: 'Shelter', value: _safeValue(profile.shelterName)),
      (label: 'Owner', value: _safeValue(profile.ownerName)),
      (label: 'Email', value: _safeValue(profile.email)),
      (label: 'Contact', value: _safeValue(profile.contact)),
      (label: 'Address', value: _safeValue(profile.address)),
      (label: 'Registered', value: createdAtText),
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Shelter Profile', subtitle: 'Basic registration details'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 360 ? 2 : 1;
              final tileWidth =
                  (constraints.maxWidth - ((crossAxisCount - 1) * 10)) / crossAxisCount;

              return GridView.builder(
                itemCount: fields.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: tileWidth / 76,
                ),
                itemBuilder: (context, index) {
                  final field = fields[index];
                  return _ProfileField(label: field.label, value: field.value);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warmBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.warmAccent.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}