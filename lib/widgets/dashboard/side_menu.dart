import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({
    super.key,
    this.isDrawer = false,
  });

  final bool isDrawer;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      color: Colors.white,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black12)),
            ),
            child: Center(
              child: Text(
                'Pawmilya',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerListTile(
                  title: 'Dashboard',
                  icon: Icons.dashboard_rounded,
                  press: () {},
                  isSelected: true,
                ),
                _DrawerListTile(
                  title: 'Manage Pets',
                  icon: Icons.pets_rounded,
                  press: () {},
                ),
                _DrawerListTile(
                  title: 'Applications',
                  icon: Icons.assignment_rounded,
                  press: () {},
                ),
                _DrawerListTile(
                  title: 'Settings',
                  icon: Icons.settings_rounded,
                  press: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isDrawer) {
      return Drawer(
        backgroundColor: Colors.white,
        elevation: 0,
        child: content,
      );
    }

    return content;
  }
}

class _DrawerListTile extends StatelessWidget {
  const _DrawerListTile({
    required this.title,
    required this.icon,
    required this.press,
    this.isSelected = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback press;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: press,
      horizontalTitleGap: 16.0,
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : Colors.grey,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      minVerticalPadding: 6,
    );
  }
}
