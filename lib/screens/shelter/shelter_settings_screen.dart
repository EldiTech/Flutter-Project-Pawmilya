import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ShelterSettingsScreen extends StatefulWidget {
  const ShelterSettingsScreen({super.key});

  @override
  State<ShelterSettingsScreen> createState() => _ShelterSettingsScreenState();
}

class _ShelterSettingsScreenState extends State<ShelterSettingsScreen> {
  // Mock states for immediate visual feedback
  bool _pushEnabled = true;
  bool _emailEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF2C3E50),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _buildSectionHeader('Preferences'),
          _buildSwitchTile(
            icon: Icons.notifications_active_outlined,
            title: 'Push Notifications',
            value: _pushEnabled,
            onChanged: (val) => setState(() => _pushEnabled = val),
          ),
          _buildSwitchTile(
            icon: Icons.email_outlined,
            title: 'Email Alerts',
            value: _emailEnabled,
            onChanged: (val) => setState(() => _emailEnabled = val),
          ),
          _buildListTile(
            icon: Icons.color_lens_outlined,
            title: 'App Theme',
            onTap: () => _handleAppTheme(context),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Support & Legal'),
          _buildListTile(
            icon: Icons.help_outline,
            title: 'Help Center',
            onTap: () => _handleHelpCenter(context),
          ),
          _buildListTile(
            icon: Icons.policy_outlined,
            title: 'Privacy Policy',
            onTap: () => _handlePrivacyPolicy(context),
          ),
          _buildListTile(
            icon: Icons.info_outline,
            title: 'About Pawmilya',
            onTap: () => _handleAbout(context),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Log Out',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _handleLogout(context),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, top: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2C3E50)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      color: Colors.white,
      child: SwitchListTile(
        secondary: Icon(icon, color: const Color(0xFF2C3E50)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        value: value,
        activeThumbColor: const Color(0xFFE6B368),
        onChanged: onChanged,
      ),
    );
  }

  void _handleAppTheme(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('App Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: const Text('Light Theme'),
              leading: const Icon(Icons.light_mode),
              trailing: const Icon(Icons.check, color: Color(0xFFE6B368)),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              title: const Text('Dark Theme'),
              leading: const Icon(Icons.dark_mode),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              title: const Text('System Default'),
              leading: const Icon(Icons.settings_system_daydream),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _handleHelpCenter(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.support_agent, color: Color(0xFFE6B368)),
            SizedBox(width: 8),
            Text('Help Center'),
          ],
        ),
        content: const Text(
          'For technical support or inquiries, please contact:\n\n'
          'Email: support@pawmilya.org\n'
          'Phone: 1-800-PAWMILYA\n\n'
          'We typically respond within 24-48 hours.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFFE6B368)),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _handlePrivacyPolicy(BuildContext context) {
    _showMockContentDialog(
      context,
      title: 'Privacy Policy',
      content:
          'At Pawmilya, we value your privacy.\n\n'
          'We collect shelter and user information solely for the purpose of animal adoptions, reporting rescues, and management.\n\n'
          'Your data is securely stored on Firebase, encrypted at rest, and never sold to third parties.',
    );
  }

  void _handleAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Pawmilya App',
      applicationVersion: 'Version 1.0.0-Beta (Shelter)',
      applicationIcon: const Icon(
        Icons.pets,
        size: 48,
        color: Color(0xFFE6B368),
      ),
      applicationLegalese: '© 2026 Pawmilya Corporation.\nAll rights reserved.',
      children: [
        const SizedBox(height: 20),
        const Text(
          'Building a unified platform to connect pounds, shelters, '
          'and animal lovers to streamline adoptions and rescues.',
        ),
      ],
    );
  }

  void _showMockContentDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(height: 1.4)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Color(0xFFE6B368))),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out of your shelter account?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
