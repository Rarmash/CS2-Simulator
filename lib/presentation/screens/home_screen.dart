import 'package:flutter/material.dart';

import '../../core/app/app_info.dart';
import '../../core/settings/settings_controller.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import 'agent_collection_list_screen.dart';
import 'charm_collection_list_screen.dart';
import 'container_list_screen.dart';
import 'glossary_hub_screen.dart';
import 'my_collection_screen.dart';
import 'operation_collection_list_screen.dart';
import 'patch_collection_list_screen.dart';
import 'player_list_screen.dart';
import 'reward_collection_list_screen.dart';
import 'settings_screen.dart';
import 'sticker_collection_list_screen.dart';
import 'team_list_screen.dart';
import 'tournament_list_screen.dart';
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
              AppNavigationHelper.pushScreen(
                context,
                SettingsScreen(settingsController: settingsController),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroSection(
                      onOpenContainers: () => _push(
                        context,
                        ContainerListScreen(
                          repository: repository,
                          settingsController: settingsController,
                        ),
                      ),
                      onGlossary: () => _push(
                        context,
                        GlossaryHubScreen(
                          repository: repository,
                          settingsController: settingsController,
                        ),
                      ),
                      onTradeUp: () =>
                          _push(context, TradeUpScreen(repository: repository)),
                      onCollection: () => _push(
                        context,
                        MyCollectionScreen(
                          repository: repository,
                          settingsController: settingsController,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ResponsiveSectionGrid(
                      minChildWidth: 290,
                      children: [
                        _HomeSectionCard(
                          icon: Icons.emoji_events,
                          title: 'Majors',
                          subtitle:
                              'Tournament history, teams, players, and linked event items.',
                          children: [
                            _ActionTile(
                              icon: Icons.emoji_events_outlined,
                              title: 'Browse Majors',
                              subtitle: 'CS:GO and CS2 tournament pages',
                              onTap: () => _push(
                                context,
                                TournamentListScreen(repository: repository),
                              ),
                            ),
                            _ActionTile(
                              icon: Icons.groups_2,
                              title: 'Major Teams',
                              subtitle:
                                  'Organizations, rosters, and placements',
                              onTap: () => _push(
                                context,
                                TeamListScreen(repository: repository),
                              ),
                            ),
                            _ActionTile(
                              icon: Icons.person_search,
                              title: 'Major Players',
                              subtitle:
                                  'Player histories and autograph context',
                              onTap: () => _push(
                                context,
                                PlayerListScreen(repository: repository),
                              ),
                            ),
                          ],
                        ),
                        _HomeSectionCard(
                          icon: Icons.auto_awesome,
                          title: 'Collections',
                          subtitle:
                              'Operation rewards, legacy collections, and other collection-style sources.',
                          children: [
                            _CompactActionChip(
                              icon: Icons.stars,
                              label: 'Operation / Armory Rewards',
                              onTap: () => _push(
                                context,
                                RewardCollectionListScreen(
                                  repository: repository,
                                ),
                              ),
                            ),
                            _CompactActionChip(
                              icon: Icons.collections_bookmark,
                              label: 'Legacy Operation Collections',
                              onTap: () => _push(
                                context,
                                OperationCollectionListScreen(
                                  repository: repository,
                                ),
                              ),
                            ),
                            _CompactActionChip(
                              icon: Icons.badge,
                              label: 'Agent Collections',
                              onTap: () => _push(
                                context,
                                AgentCollectionListScreen(
                                  repository: repository,
                                ),
                              ),
                            ),
                            _CompactActionChip(
                              icon: Icons.sell,
                              label: 'Sticker Collections',
                              onTap: () => _push(
                                context,
                                StickerCollectionListScreen(
                                  repository: repository,
                                ),
                              ),
                            ),
                            _CompactActionChip(
                              icon: Icons.style,
                              label: 'Patch Collections',
                              onTap: () => _push(
                                context,
                                PatchCollectionListScreen(
                                  repository: repository,
                                ),
                              ),
                            ),
                            _CompactActionChip(
                              icon: Icons.key,
                              label: 'Charm Collections',
                              onTap: () => _push(
                                context,
                                CharmCollectionListScreen(
                                  repository: repository,
                                ),
                              ),
                            ),
                          ],
                        ),
                        _HomeSectionCard(
                          icon: Icons.tune,
                          title: 'Explore',
                          subtitle:
                              'Pattern-aware browsing, finish variants, and simulator tools.',
                          children: [
                            _ActionTile(
                              icon: Icons.menu_book,
                              title: 'Item Glossary',
                              subtitle:
                                  'Browse skins, stickers, agents, music kits, and more',
                              onTap: () => _push(
                                context,
                                GlossaryHubScreen(
                                  repository: repository,
                                  settingsController: settingsController,
                                ),
                              ),
                            ),
                            _ActionTile(
                              icon: Icons.swap_horiz,
                              title: 'Trade-Up Simulator',
                              subtitle:
                                  'Preview outcomes, floats, and special-item odds',
                              onTap: () => _push(
                                context,
                                TradeUpScreen(repository: repository),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        appVersion,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
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

  void _push(BuildContext context, Widget screen) {
    AppNavigationHelper.pushScreen(context, screen);
  }
}

class _HeroSection extends StatelessWidget {
  final VoidCallback onOpenContainers;
  final VoidCallback onGlossary;
  final VoidCallback onTradeUp;
  final VoidCallback onCollection;

  const _HeroSection({
    required this.onOpenContainers,
    required this.onGlossary,
    required this.onTradeUp,
    required this.onCollection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.22),
            theme.colorScheme.secondary.withValues(alpha: 0.14),
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
          ],
        ),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Open, inspect, and compare the full CS item ecosystem.',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Containers, trade-ups, collection tracking, pattern-aware skin browsing, and full Major tournament history all live here now.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroButton(
                icon: Icons.inventory_2,
                title: 'Open Containers',
                onTap: onOpenContainers,
                emphasized: true,
              ),
              _HeroButton(
                icon: Icons.menu_book,
                title: 'Item Glossary',
                onTap: onGlossary,
              ),
              _HeroButton(
                icon: Icons.swap_horiz,
                title: 'Trade-Up',
                onTap: onTradeUp,
              ),
              _HeroButton(
                icon: Icons.inventory_2_outlined,
                title: 'My Collection',
                onTap: onCollection,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResponsiveSectionGrid extends StatelessWidget {
  final double minChildWidth;
  final List<Widget> children;

  const _ResponsiveSectionGrid({
    required this.minChildWidth,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / minChildWidth)
            .floor()
            .clamp(1, 3);
        final itemWidth =
            (constraints.maxWidth - ((crossAxisCount - 1) * 16)) /
            crossAxisCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _HomeSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _HomeSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
            const SizedBox(height: 14),
            ..._separated(children, const SizedBox(height: 10)),
          ],
        ),
      ),
    );
  }

  List<Widget> _separated(List<Widget> items, Widget separator) {
    if (items.isEmpty) {
      return const [];
    }

    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i != items.length - 1) {
        result.add(separator);
      }
    }
    return result;
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          color: Colors.white.withValues(alpha: 0.02),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CompactActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
          color: Colors.white.withValues(alpha: 0.02),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(label, style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool emphasized;

  const _HeroButton({
    required this.icon,
    required this.title,
    required this.onTap,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonChild = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon), const SizedBox(width: 8), Text(title)],
      ),
    );

    if (emphasized) {
      return FilledButton(onPressed: onTap, child: buttonChild);
    }

    return OutlinedButton(onPressed: onTap, child: buttonChild);
  }
}
