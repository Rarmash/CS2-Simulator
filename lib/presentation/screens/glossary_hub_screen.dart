import 'package:flutter/material.dart';

import '../../core/settings/settings_controller.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import 'agent_glossary_screen.dart';
import 'charm_glossary_screen.dart';
import 'graffiti_glossary_screen.dart';
import 'music_kit_glossary_screen.dart';
import 'patch_glossary_screen.dart';
import 'pin_glossary_screen.dart';
import 'skin_glossary_screen.dart';
import 'sticker_glossary_screen.dart';

class GlossaryHubScreen extends StatelessWidget {
  final LocalDataRepository repository;
  final SettingsController settingsController;

  const GlossaryHubScreen({
    super.key,
    required this.repository,
    required this.settingsController,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _GlossaryHubItem(
        icon: Icons.menu_book,
        title: 'Skins',
        buildScreen: () => SkinGlossaryScreen(
          repository: repository,
          settingsController: settingsController,
        ),
      ),
      _GlossaryHubItem(
        icon: Icons.sell,
        title: 'Stickers',
        buildScreen: () => StickerGlossaryScreen(repository: repository),
      ),
      _GlossaryHubItem(
        icon: Icons.badge,
        title: 'Agents',
        buildScreen: () => AgentGlossaryScreen(repository: repository),
      ),
      _GlossaryHubItem(
        icon: Icons.push_pin,
        title: 'Pins',
        buildScreen: () => PinGlossaryScreen(repository: repository),
      ),
      _GlossaryHubItem(
        icon: Icons.library_music,
        title: 'Music Kits',
        buildScreen: () => MusicKitGlossaryScreen(repository: repository),
      ),
      _GlossaryHubItem(
        icon: Icons.brush,
        title: 'Graffiti',
        buildScreen: () => GraffitiGlossaryScreen(repository: repository),
      ),
      _GlossaryHubItem(
        icon: Icons.style,
        title: 'Patches',
        buildScreen: () => PatchGlossaryScreen(repository: repository),
      ),
      _GlossaryHubItem(
        icon: Icons.key,
        title: 'Charms',
        buildScreen: () => CharmGlossaryScreen(repository: repository),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Item Glossary')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: () {
                        AppNavigationHelper.pushScreen(
                          context,
                          item.buildScreen(),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon),
                          const SizedBox(width: 10),
                          Text(
                            item.title,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlossaryHubItem {
  final IconData icon;
  final String title;
  final Widget Function() buildScreen;

  const _GlossaryHubItem({
    required this.icon,
    required this.title,
    required this.buildScreen,
  });
}
