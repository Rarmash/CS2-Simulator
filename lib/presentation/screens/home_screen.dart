import 'package:flutter/material.dart';

import '../../core/settings/settings_controller.dart';
import '../../data/repositories/local_data_repository.dart';
import 'case_list_screen.dart';
import 'operation_collection_list_screen.dart';
import 'reward_collection_list_screen.dart';
import 'settings_screen.dart';
import 'skin_glossary_screen.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('CS2 Simulator'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    settingsController: settingsController,
                  ),
                ),
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
                _menuButton(
                  context,
                  title: '🎰 Open Cases',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CaseListScreen(
                          repository: repository,
                          settingsController: settingsController,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _menuButton(
                  context,
                  title: '📘 Skin Glossary',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SkinGlossaryScreen(
                          repository: repository,
                          settingsController: settingsController,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _menuButton(
                  context,
                  title: '🎖️ Operation / Armory Rewards',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RewardCollectionListScreen(
                          repository: repository,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _menuButton(
                  context,
                  title: '🗃️ Legacy Operation Collections',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OperationCollectionListScreen(
                          repository: repository,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _menuButton(
                  context,
                  title: '🔄 Trade-Up',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TradeUpScreen(repository: repository),
                      ),
                    );
                  },
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
        required String title,
        required VoidCallback onTap,
      }) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: onTap,
        child: Text(
          title,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}