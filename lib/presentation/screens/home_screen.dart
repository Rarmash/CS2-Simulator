import 'package:flutter/material.dart';

import '../../core/app/app_info.dart';
import '../../core/settings/settings_controller.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import 'agent_collection_list_screen.dart';
import 'case_list_screen.dart';
import 'charm_collection_list_screen.dart';
import 'glossary_hub_screen.dart';
import 'operation_collection_list_screen.dart';
import 'patch_collection_list_screen.dart';
import 'reward_collection_list_screen.dart';
import 'settings_screen.dart';
import 'sticker_collection_list_screen.dart';
import 'tradeup_screen.dart';

class HomeScreen extends StatelessWidget {
  final LocalDataRepository repository;
  final SettingsController settingsController;

  const HomeScreen({
    super.key,
    required this.repository,
    required this.settingsController,
  });

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      _HomeMenuItem(
        icon: Icons.inventory_2,
        title: 'Open Containers',
        buildScreen: () => CaseListScreen(
          repository: repository,
          settingsController: settingsController,
        ),
      ),
      _HomeMenuItem(
        icon: Icons.menu_book,
        title: 'Item Glossary',
        buildScreen: () => GlossaryHubScreen(
          repository: repository,
          settingsController: settingsController,
        ),
      ),
      _HomeMenuItem(
        icon: Icons.stars,
        title: 'Operation / Armory Rewards',
        buildScreen: () => RewardCollectionListScreen(repository: repository),
      ),
      _HomeMenuItem(
        icon: Icons.collections_bookmark,
        title: 'Legacy Operation Collections',
        buildScreen: () =>
            OperationCollectionListScreen(repository: repository),
      ),
      _HomeMenuItem(
        icon: Icons.badge,
        title: 'Agent Collections',
        buildScreen: () => AgentCollectionListScreen(repository: repository),
      ),
      _HomeMenuItem(
        icon: Icons.sell,
        title: 'Sticker Collections',
        buildScreen: () => StickerCollectionListScreen(repository: repository),
      ),
      _HomeMenuItem(
        icon: Icons.style,
        title: 'Patch Collections',
        buildScreen: () => PatchCollectionListScreen(repository: repository),
      ),
      _HomeMenuItem(
        icon: Icons.key,
        title: 'Charm Collections',
        buildScreen: () => CharmCollectionListScreen(repository: repository),
      ),
      _HomeMenuItem(
        icon: Icons.swap_horiz,
        title: 'Trade-Up',
        buildScreen: () => TradeUpScreen(repository: repository),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CS2 Simulator'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              AppNavigationHelper.pushScreen(
                context,
                SettingsScreen(settingsController: settingsController),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < menuItems.length; i++) ...[
                  _menuButton(
                    context,
                    icon: menuItems[i].icon,
                    title: menuItems[i].title,
                    onTap: () {
                      AppNavigationHelper.pushScreen(
                        context,
                        menuItems[i].buildScreen(),
                      );
                    },
                  ),
                  if (i != menuItems.length - 1) const SizedBox(height: 16),
                ],
                const SizedBox(height: 20),
                Text(
                  appVersion,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

class _HomeMenuItem {
  final IconData icon;
  final String title;
  final Widget Function() buildScreen;

  const _HomeMenuItem({
    required this.icon,
    required this.title,
    required this.buildScreen,
  });
}
