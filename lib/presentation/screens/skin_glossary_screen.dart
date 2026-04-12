import 'package:flutter/material.dart';

import '../../core/collection/collection_summary.dart';
import '../../core/collection/collection_tracking_service.dart';
import '../../core/settings/settings_controller.dart';
import '../../data/models/skin_group_dto.dart';
import '../../data/models/skin_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/skin_pattern_helper.dart';
import '../helpers/app_navigation_helper.dart';
import '../helpers/skin_ui_helper.dart';
import '../widgets/detail_tag.dart';
import '../widgets/glossary_list_item.dart';
import 'skin_details_screen.dart';

class SkinGlossaryScreen extends StatefulWidget {
  final LocalDataRepository repository;
  final SettingsController settingsController;

  const SkinGlossaryScreen({
    super.key,
    required this.repository,
    required this.settingsController,
  });

  @override
  State<SkinGlossaryScreen> createState() => _SkinGlossaryScreenState();
}

class _SkinGlossaryScreenState extends State<SkinGlossaryScreen> {
  late final Future<_SkinGlossaryData> _future;
  final TextEditingController _searchController = TextEditingController();
  final CollectionTrackingService _collectionTracking =
      CollectionTrackingService();

  String _query = '';
  String _rarityFilter = 'ALL';
  String _typeFilter = 'ALL';
  String _patternFilter = 'ALL';

  static const List<_DropdownItem> _rarityItems = [
    _DropdownItem('ALL', 'All rarities'),
    _DropdownItem('CONSUMER', 'Consumer Grade'),
    _DropdownItem('INDUSTRIAL', 'Industrial Grade'),
    _DropdownItem('MIL_SPEC', 'Mil-Spec'),
    _DropdownItem('RESTRICTED', 'Restricted'),
    _DropdownItem('CLASSIFIED', 'Classified'),
    _DropdownItem('COVERT', 'Covert'),
    _DropdownItem('CONTRABAND', 'Contraband'),
    _DropdownItem('EXTRAORDINARY', 'Extraordinary'),
  ];

  static const List<_DropdownItem> _typeItems = [
    _DropdownItem('ALL', 'All types'),
    _DropdownItem('WEAPON', 'Weapons'),
    _DropdownItem('KNIFE', 'Knives'),
    _DropdownItem('GLOVES', 'Gloves'),
  ];

  static const List<_DropdownItem> _patternItems = [
    _DropdownItem('ALL', 'All finishes'),
    _DropdownItem('PATTERN', 'Pattern-sensitive'),
    _DropdownItem('SEED', 'Seed-based'),
    _DropdownItem('PHASE', 'Phase-based'),
  ];

  @override
  void initState() {
    super.initState();
    _future = _loadData();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<_SkinGlossaryData> _loadData() async {
    final results = await Future.wait([
      widget.repository.loadSkinGroups(),
      _collectionTracking.loadSummaries(),
    ]);

    final summaries = results[1] as List<CollectionSummary>;
    final collectedByItemId = <String, int>{};
    for (final summary in summaries.where((item) => item.category == 'skin')) {
      collectedByItemId[summary.latestEntry.itemId] =
          (collectedByItemId[summary.latestEntry.itemId] ?? 0) + summary.count;
    }

    return _SkinGlossaryData(
      groups: results[0] as List<SkinGroupDto>,
      collectedByItemId: collectedByItemId,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SkinGroupDto> _applyFilters(List<SkinGroupDto> skins) {
    final filtered = skins.where((group) {
      final skin = group.primary;

      if (_rarityFilter != 'ALL' && group.rarity != _rarityFilter) {
        return false;
      }

      if (_typeFilter != 'ALL' && group.itemKind != _typeFilter) {
        return false;
      }

      if (!_matchesPatternFilter(skin)) {
        return false;
      }

      if (_query.isEmpty) return true;

      final haystack = <String>[
        skin.name,
        skin.itemDisplayName,
        skin.collection ?? '',
        skin.finishCatalogName ?? '',
        skin.variantName ?? '',
        skin.phase ?? '',
        group.variantLabels.join(' '),
        skin.rarity,
        skin.weaponType,
        skin.itemKind,
      ].join(' ').toLowerCase();

      return haystack.contains(_query);
    }).toList();

    filtered.sort((a, b) {
      final specialCompare = (a.isSpecialItem ? 1 : 0).compareTo(
        b.isSpecialItem ? 1 : 0,
      );
      if (specialCompare != 0) return specialCompare;

      final rarityCompare = _rarityOrder(
        a.primary,
      ).compareTo(_rarityOrder(b.primary));
      if (rarityCompare != 0) return rarityCompare;

      final weaponCompare = a.itemDisplayName.compareTo(b.itemDisplayName);
      if (weaponCompare != 0) return weaponCompare;

      return a.name.compareTo(b.name);
    });

    return filtered;
  }

  bool _matchesPatternFilter(SkinDto skin) {
    switch (_patternFilter) {
      case 'ALL':
        return true;
      case 'PATTERN':
        return SkinPatternHelper.supportsPatternSeed(skin) ||
            SkinPatternHelper.hasExplicitPhaseVariant(skin);
      case 'SEED':
        return SkinPatternHelper.supportsPatternSeed(skin);
      case 'PHASE':
        return SkinPatternHelper.hasExplicitPhaseVariant(skin);
      default:
        return true;
    }
  }

  int _rarityOrder(SkinDto skin) {
    if (skin.isSpecialItem) return 999;

    switch (skin.rarity) {
      case 'CONSUMER':
        return 0;
      case 'INDUSTRIAL':
        return 1;
      case 'MIL_SPEC':
        return 2;
      case 'RESTRICTED':
        return 3;
      case 'CLASSIFIED':
        return 4;
      case 'COVERT':
        return 5;
      case 'CONTRABAND':
        return 6;
      case 'EXTRAORDINARY':
        return 7;
      default:
        return 9999;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skin Glossary')),
      body: FutureBuilder<_SkinGlossaryData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load skins.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data =
              snapshot.data ??
              const _SkinGlossaryData(groups: [], collectedByItemId: {});
          final skins = data.groups;
          final filtered = _applyFilters(skins);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText:
                            'Search by skin, weapon, collection, finish...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear',
                                onPressed: () {
                                  _searchController.clear();
                                },
                                icon: const Icon(Icons.clear),
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _rarityFilter,
                            decoration: InputDecoration(
                              labelText: 'Rarity',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            items: _rarityItems
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                    value: e.value,
                                    child: Text(e.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _rarityFilter = value ?? 'ALL';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _typeFilter,
                            decoration: InputDecoration(
                              labelText: 'Type',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            items: _typeItems
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                    value: e.value,
                                    child: Text(e.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _typeFilter = value ?? 'ALL';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _patternFilter,
                      decoration: InputDecoration(
                        labelText: 'Pattern behavior',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: _patternItems
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e.value,
                              child: Text(e.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _patternFilter = value ?? 'ALL';
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${filtered.length} skins',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Nothing found.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      )
                    : ListView.separated(
                        cacheExtent: 1200,
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final group = filtered[index];
                          final skin = group.primary;
                          final rarityColor = SkinUiHelper.rarityColor(skin);
                          final collectedCount = group.variants.fold<int>(
                            0,
                            (sum, variant) =>
                                sum + (data.collectedByItemId[variant.id] ?? 0),
                          );

                          return GlossaryListItem(
                            accentColor: rarityColor,
                            imagePath: group.skinImage,
                            title: group.itemDisplayName,
                            subtitle: _subtitle(group),
                            collectionInfo: collectedCount > 0
                                ? 'Collected $collectedCount'
                                : null,
                            tags: [
                              _pill(
                                SkinUiHelper.rarityLabel(group.primary),
                                color: rarityColor,
                              ),
                              _pill(
                                group.itemKind == 'WEAPON'
                                    ? SkinUiHelper.weaponTypeLabel(
                                        group.weaponType,
                                      )
                                    : group.itemKind == 'KNIFE'
                                    ? 'Knife'
                                    : 'Gloves',
                              ),
                              if ((group.collection ?? '').isNotEmpty)
                                _pill(group.collection!),
                              if (SkinPatternHelper.hasExplicitPhaseVariant(
                                group.primary,
                              ))
                                _pill('Phase-based'),
                              if (SkinPatternHelper.supportsPatternSeed(
                                group.primary,
                              ))
                                _pill('Seed-based'),
                              if (SkinPatternHelper.patternFamilyLabel(
                                    group.primary,
                                  )
                                  case final patternFamily?)
                                _pill(patternFamily),
                              if (group.hasMultipleVariants)
                                _pill('${group.variants.length} variants'),
                            ],
                            onTap: () {
                              AppNavigationHelper.pushScreen(
                                context,
                                SkinDetailsScreen(
                                  repository: widget.repository,
                                  settingsController: widget.settingsController,
                                  skin: group.primary,
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _pill(String text, {Color? color}) {
    return DetailTag(text: text, color: color);
  }

  String _subtitle(SkinGroupDto group) {
    final labels = group.variantLabels;
    if (labels.isNotEmpty) {
      return '${group.name} • ${labels.join(', ')}';
    }
    return group.name;
  }
}

class _SkinGlossaryData {
  final List<SkinGroupDto> groups;
  final Map<String, int> collectedByItemId;

  const _SkinGlossaryData({
    required this.groups,
    required this.collectedByItemId,
  });
}

class _DropdownItem {
  final String value;
  final String label;

  const _DropdownItem(this.value, this.label);
}
