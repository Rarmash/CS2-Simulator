import 'package:flutter/material.dart';

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
            ],
          ),
        );
      },
    );
  }
}