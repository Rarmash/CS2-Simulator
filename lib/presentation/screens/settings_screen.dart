import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app/app_info.dart';
import '../../core/settings/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsController settingsController;

  const SettingsScreen({
    super.key,
    required this.settingsController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: ListView(
            children: [
              SwitchListTile(
                title: const Text('Enable X-Ray opening'),
                subtitle: const Text(
                  'Regular cases reveal the item first. You can then claim or destroy it.',
                ),
                value: settingsController.xrayOpeningEnabled,
                onChanged: (value) async {
                  await settingsController.setXrayOpeningEnabled(value);
                },
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('App Version'),
                subtitle: Text(appVersion),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                subtitle: const Text('Version, license, and project info'),
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 52,
                        height: 52,
                        color: theme.colorScheme.primaryContainer,
                        child: Image.asset(
                          'assets/app_icon/latest_case.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appDisplayName,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appLegalese,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _AboutInfoTile(
                  icon: Icons.new_releases_outlined,
                  title: 'Version',
                  value: appVersion,
                ),
                const SizedBox(height: 12),
                _AboutInfoTile(
                  icon: Icons.gavel_outlined,
                  title: 'License',
                  value: 'AGPL-3.0',
                ),
                const SizedBox(height: 12),
                _AboutInfoTile(
                  icon: Icons.code_outlined,
                  title: 'GitHub',
                  value: appRepositoryUrl,
                  helperText: 'Tap to copy',
                  onTap: () async {
                    await Clipboard.setData(
                      const ClipboardData(text: appRepositoryUrl),
                    );
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('GitHub link copied')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _AboutInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? helperText;
  final VoidCallback? onTap;

  const _AboutInfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.helperText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (helperText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        helperText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
