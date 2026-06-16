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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          final cardWidth = wide
              ? (constraints.maxWidth - 48 - 12) / 2
              : constraints.maxWidth - 32;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HubIntroCard(),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final item in items)
                          SizedBox(
                            width: cardWidth,
                            child: _GlossaryHubCard(
                              item: item,
                              onTap: () {
                                AppNavigationHelper.pushScreen(
                                  context,
                                  item.buildScreen(),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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

class _HubIntroCard extends StatelessWidget {
  const _HubIntroCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Browse Every Item Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'Open the full glossary by category and jump from collection tracking straight into detailed item pages.',
              style: TextStyle(color: Colors.white70, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlossaryHubCard extends StatelessWidget {
  final _GlossaryHubItem item;
  final VoidCallback onTap;

  const _GlossaryHubCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          color: Colors.white.withValues(alpha: 0.03),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withValues(alpha: 0.06),
              ),
              child: Icon(item.icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
