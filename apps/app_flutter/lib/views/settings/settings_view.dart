import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          _buildSection(
            context,
            'Audio',
            [
              _buildListTile(
                context,
                'Voice Settings',
                'Choose voice and adjust speed',
                Icons.record_voice_over,
                () => _showComingSoon(context),
              ),
              _buildListTile(
                context,
                'Audio Quality',
                'Select audio generation quality',
                Icons.high_quality,
                () => _showComingSoon(context),
              ),
            ],
          ),
          
          SizedBox(height: 24.h),
          
          _buildSection(
            context,
            'Storage',
            [
              _buildListTile(
                context,
                'Cache Management',
                'Manage audio cache and storage',
                Icons.storage,
                () => _showComingSoon(context),
              ),
              _buildListTile(
                context,
                'Downloaded Books',
                'View and manage downloaded books',
                Icons.library_books,
                () => context.pop(),
              ),
            ],
          ),
          
          SizedBox(height: 24.h),
          
          _buildSection(
            context,
            'Appearance',
            [
              _buildListTile(
                context,
                'Theme',
                'Light, dark, or system theme',
                Icons.palette,
                () => _showComingSoon(context),
              ),
              _buildListTile(
                context,
                'Text Size',
                'Adjust reading text size',
                Icons.text_fields,
                () => _showComingSoon(context),
              ),
            ],
          ),
          
          SizedBox(height: 24.h),
          
          _buildSection(
            context,
            'About',
            [
              _buildListTile(
                context,
                'Version',
                'v0.0.1 (MVP)',
                Icons.info,
                null,
              ),
              _buildListTile(
                context,
                'Licenses',
                'View open source licenses',
                Icons.gavel,
                () => _showLicensesDialog(context),
              ),
              _buildListTile(
                context,
                'Privacy Policy',
                'Read our privacy policy',
                Icons.privacy_tip,
                () => _showPrivacyDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16.w, bottom: 12.h),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon in v0.1!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showLicensesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open Source Licenses'),
        content: const SingleChildScrollView(
          child: Text(
            'This app uses the following open source libraries:\n\n'
            '• Flutter - Google Inc.\n'
            '• Riverpod - Remi Rousselet\n'
            '• just_audio - Ryan Heise\n'
            '• go_router - Flutter Team\n'
            '• flutter_rust_bridge - fzyzcjy\n'
            '• epub - Nguyen Duc Hoang\n'
            '• And many others...\n\n'
            'For TTS models:\n'
            '• Piper TTS - Mike Hansen\n'
            '• ONNX Runtime - Microsoft\n\n'
            'Public domain books from:\n'
            '• Project Gutenberg\n'
            '• Internet Archive\n'
            '• Open Library',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy-First Reading App\n\n'
            'This app is designed with privacy as a core principle:\n\n'
            '• No user accounts or personal data collection\n'
            '• All books and audio are stored locally on your device\n'
            '• TTS generation happens entirely offline using local AI models\n'
            '• No analytics, tracking, or telemetry\n'
            '• Only network requests are for downloading public domain books\n'
            '• No data is shared with third parties\n\n'
            'The only data stored is:\n'
            '• Downloaded book files (EPUB)\n'
            '• Generated audio cache\n'
            '• Your reading/listening positions\n'
            '• App settings and preferences\n\n'
            'All data remains on your device and can be deleted by uninstalling the app.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}