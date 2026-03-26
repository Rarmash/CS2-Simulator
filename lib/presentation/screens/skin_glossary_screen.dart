import 'package:flutter/material.dart';

import '../../core/settings/settings_controller.dart';
import '../../data/models/skin_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/skin_ui_helper.dart';
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
  late final Future<List<SkinDto>> _future;
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  String _rarityFilter = 'ALL';
  String _typeFilter = 'ALL';

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

  @override
  void initState() {
    super.initState();
    _future = widget.repository.loadSkins();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SkinDto> _applyFilters(List<SkinDto> skins) {
    final filtered = skins.where((skin) {
      if (_rarityFilter != 'ALL' && skin.rarity != _rarityFilter) {
        return false;
      }

      if (_typeFilter != 'ALL' && skin.itemKind != _typeFilter) {
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
        skin.rarity,
        skin.weaponType,
        skin.itemKind,
      ].join(' ').toLowerCase();

      return haystack.contains(_query);
    }).toList();

    filtered.sort((a, b) {
      final specialCompare =
      (a.isSpecialItem ? 1 : 0).compareTo(b.isSpecialItem ? 1 : 0);
      if (specialCompare != 0) return specialCompare;

      final rarityCompare = _rarityOrder(a).compareTo(_rarityOrder(b));
      if (rarityCompare != 0) return rarityCompare;

      final weaponCompare = a.itemDisplayName.compareTo(b.itemDisplayName);
      if (weaponCompare != 0) return weaponCompare;

      return a.name.compareTo(b.name);
    });

    return filtered;
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
      appBar: AppBar(
        title: const Text('Skin Glossary'),
      ),
      body: FutureBuilder<List<SkinDto>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
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

          final skins = snapshot.data ?? const <SkinDto>[];
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
                            value: _rarityFilter,
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
                            value: _typeFilter,
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
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final skin = filtered[index];
                    final rarityColor = SkinUiHelper.rarityColor(skin);

                    return RepaintBoundary(
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SkinDetailsScreen(
                                  repository: widget.repository,
                                  settingsController:
                                  widget.settingsController,
                                  skin: skin,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: rarityColor,
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment:
                                CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 96,
                                    height: 72,
                                    child: Image.asset(
                                      skin.skinImage,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.low,
                                      isAntiAlias: false,
                                      gaplessPlayback: true,
                                      cacheWidth: 256,
                                      errorBuilder: (_, __, ___) =>
                                      const Icon(
                                        Icons.image_not_supported,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          skin.itemDisplayName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          SkinUiHelper.secondaryText(skin),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _pill(
                                              SkinUiHelper.rarityLabel(
                                                  skin),
                                              color: rarityColor,
                                            ),
                                            _pill(
                                              skin.itemKind == 'WEAPON'
                                                  ? SkinUiHelper
                                                  .weaponTypeLabel(
                                                skin.weaponType,
                                              )
                                                  : skin.itemKind ==
                                                  'KNIFE'
                                                  ? 'Knife'
                                                  : 'Gloves',
                                            ),
                                            if ((skin.collection ?? '')
                                                .isNotEmpty)
                                              _pill(skin.collection!),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.white38,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Colors.white24).withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color ?? Colors.white24,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DropdownItem {
  final String value;
  final String label;

  const _DropdownItem(this.value, this.label);
}