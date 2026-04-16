import 'package:flutter/material.dart';

import '../navigation/fade_slide_route.dart';
import '../theme/pawmilya_palette.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/pawmilya_shell.dart';
import 'admin/admin_login_screen.dart';
import 'shelter/shelter_login_screen.dart';
import 'user/user_login_screen.dart';

enum PortalRole { user, admin, shelter }

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _titleFade;
  late final Animation<double> _cardsFade;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 860),
    )..forward();

    _titleFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0, 0.55, curve: Curves.easeOutCubic),
    );
    _cardsFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.28, 1, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _openRole(PortalRole role) {
    late final Widget next;
    late final Offset begin;

    switch (role) {
      case PortalRole.user:
        next = const UserLoginScreen();
        begin = const Offset(-0.08, 0);
        break;
      case PortalRole.admin:
        next = const AdminLoginScreen();
        begin = const Offset(0.08, 0);
        break;
      case PortalRole.shelter:
        next = const ShelterLoginScreen();
        begin = const Offset(0, 0.08);
        break;
    }

    Navigator.of(
      context,
    ).push(fadeSlideRoute(page: next, begin: begin, durationMs: 460));
  }

  @override
  Widget build(BuildContext context) {
    return PawmilyaShell(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeSlideIn(
                animation: _titleFade,
                begin: const Offset(0, 0.08),
                child: const Text(
                  'Log In',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: PawmilyaPalette.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeSlideIn(
                animation: _titleFade,
                begin: const Offset(0, 0.06),
                child: const Text(
                  'Select your portal to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: PawmilyaPalette.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FadeSlideIn(
                animation: _cardsFade,
                begin: const Offset(0, 0.08),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: PawmilyaPalette.cardEdge.withValues(alpha: 0.8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _PortalButton(
                        title: 'USER',
                        subtitle: 'Find and adopt pets',
                        icon: Icons.pets_rounded,
                        colors: const [
                          Color(0xFFE8B972),
                          Color(0xFFD79647),
                          Color(0xFFBD7433),
                        ],
                        onTap: () => _openRole(PortalRole.user),
                      ),
                      const SizedBox(height: 12),
                      _PortalButton(
                        title: 'ADMIN',
                        subtitle: 'Manage system data',
                        icon: Icons.admin_panel_settings_rounded,
                        colors: const [
                          Color(0xFFC99457),
                          Color(0xFFA96E38),
                          Color(0xFF7E4F27),
                        ],
                        onTap: () => _openRole(PortalRole.admin),
                      ),
                      const SizedBox(height: 12),
                      _PortalButton(
                        title: 'SHELTER',
                        subtitle: 'Manage pet listings',
                        icon: Icons.home_work_rounded,
                        colors: const [
                          Color(0xFFA6BF82),
                          Color(0xFF789359),
                          Color(0xFF566F42),
                        ],
                        onTap: () => _openRole(PortalRole.shelter),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortalButton extends StatelessWidget {
  const _PortalButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: const Color(0xFFFFF8EC), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFF8EC),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFF8EC),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFFFFF8EC),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
