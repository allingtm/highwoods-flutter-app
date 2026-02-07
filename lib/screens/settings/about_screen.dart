import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../theme/app_theme.dart';
import '../../theme/app_color_palette.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.all(tokens.spacingLg),
        children: [
          _buildAppVersionTile(context),
          _buildSettingsTile(
            context,
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terms & Conditions coming soon')),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy Policy coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppVersionTile(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.hasData
            ? 'v${snapshot.data!.version} (${snapshot.data!.buildNumber})'
            : 'Loading...';

        return Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          margin: EdgeInsets.only(bottom: tokens.spacingSm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusMd),
          ),
          child: ListTile(
            leading: Icon(Icons.info_outline, color: colorScheme.onSurface),
            title: const Text(
              'App Version',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: Text(
              version,
              style: TextStyle(color: context.colors.textSecondary),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      margin: EdgeInsets.only(bottom: tokens.spacingSm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: ListTile(
        leading: Icon(icon, color: colorScheme.onSurface),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(color: context.colors.textSecondary),
              )
            : null,
        trailing: Icon(Icons.chevron_right, color: context.colors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
