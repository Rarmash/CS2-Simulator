import 'package:flutter/material.dart';

import '../../core/settings/settings_controller.dart';
import '../../data/models/case_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/responsive_grid_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/chip_badge.dart';
import '../widgets/collection_list_card.dart';
import 'case_open_screen.dart';
import 'graffiti_box_open_screen.dart';
import 'music_kit_box_open_screen.dart';
import 'patch_container_open_screen.dart';
import 'pin_container_open_screen.dart';
import 'sticker_container_open_screen.dart';

class CaseListScreen extends StatefulWidget {
  final LocalDataRepository repository;
  final SettingsController settingsController;

  const CaseListScreen({
    super.key,
    required this.repository,
    required this.settingsController,
  });

  @override
  State<CaseListScreen> createState() => _CaseListScreenState();
}

class _CaseListScreenState extends State<CaseListScreen> {
  late Future<List<CaseDto>> _casesFuture;

  static const String _filterAll = 'ALL';
  String _selectedFilter = _filterAll;

  @override
  void initState() {
    super.initState();
    _casesFuture = widget.repository.loadCases();
  }

  List<String> _availableFilters(List<CaseDto> cases) {
    final types = <String>{_filterAll};

    for (final caseDto in cases) {
      if (caseDto.isXrayPackage ||
          caseDto.isStickerCollection ||
          caseDto.isPatchCollection) {
        continue;
      }
      types.add(caseDto.type);
    }

    final ordered = <String>[_filterAll];
    const preferredOrder = [
      'CASE',
      'SOUVENIR_PACKAGE',
      'COLLECTION_PACKAGE',
      'STICKER_CAPSULE',
      'PIN_CAPSULE',
      'MUSIC_KIT_BOX',
      'GRAFFITI_BOX',
      'PATCH_PACK',
      'TERMINAL',
    ];

    for (final type in preferredOrder) {
      if (types.contains(type)) {
        ordered.add(type);
      }
    }

    for (final type in types) {
      if (!ordered.contains(type)) {
        ordered.add(type);
      }
    }

    return ordered;
  }

  String _filterLabel(String type) {
    switch (type) {
      case _filterAll:
        return 'All';
      case 'CASE':
        return 'Cases';
      case 'SOUVENIR_PACKAGE':
        return 'Souvenir';
      case 'COLLECTION_PACKAGE':
        return 'Collection';
      case 'STICKER_CAPSULE':
        return 'Sticker Capsule';
      case 'PIN_CAPSULE':
        return 'Pin Capsule';
      case 'MUSIC_KIT_BOX':
        return 'Music Kit Box';
      case 'GRAFFITI_BOX':
        return 'Graffiti Box';
      case 'PATCH_PACK':
        return 'Patch Pack';
      case 'TERMINAL':
        return 'Terminal';
      default:
        return type;
    }
  }

  List<CaseDto> _applyFilters(List<CaseDto> cases) {
    var filtered = List<CaseDto>.from(cases);

    filtered = filtered
        .where(
          (c) =>
              !c.isXrayPackage && !c.isStickerCollection && !c.isPatchCollection,
        )
        .toList();

    if (_selectedFilter != _filterAll) {
      filtered = filtered.where((c) => c.type == _selectedFilter).toList();
    }

    filtered.sort((a, b) {
      final ad = a.releaseDate ?? '9999-99-99';
      final bd = b.releaseDate ?? '9999-99-99';
      final byDate = ad.compareTo(bd);
      if (byDate != 0) return byDate;
      return a.name.compareTo(b.name);
    });

    return filtered;
  }

  Widget _buildFilterBar(List<CaseDto> allCases) {
    final filters = _availableFilters(allCases);

    if (_selectedFilter != _filterAll && !filters.contains(_selectedFilter)) {
      _selectedFilter = _filterAll;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: filters.map((type) {
          return ChoiceChip(
            label: Text(_filterLabel(type)),
            selected: _selectedFilter == type,
            onSelected: (_) {
              setState(() {
                _selectedFilter = type;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCaseCard(BuildContext context, CaseDto caseDto) {
    final typeColor = SourceColorHelper.containerTypeColor(caseDto.type);
    final chips = <Widget>[
      ChipBadge(label: caseDto.typeLabel, color: typeColor),
    ];

    if (caseDto.isStickerCollection && caseDto.sourceTypeLabel != null) {
      final sourceColor = SourceColorHelper.collectibleSourceColor(
        caseDto.sourceType,
        caseDto.sourceId,
      );
      chips.add(ChipBadge(label: caseDto.sourceTypeLabel!, color: sourceColor));

      if ((caseDto.sourceName ?? '').isNotEmpty) {
        chips.add(ChipBadge(label: caseDto.sourceName!, color: sourceColor));
      }
    }

    return CollectionListCard(
      imagePath: caseDto.caseImage,
      title: caseDto.name,
      releaseDate: caseDto.releaseDate,
      chips: chips,
      metadata: const [],
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                caseDto.isStickerCapsule || caseDto.isStickerCollection
                ? StickerContainerOpenScreen(
                    caseDto: caseDto,
                    repository: widget.repository,
                  )
                : caseDto.isPinCapsule
                ? PinContainerOpenScreen(
                    caseDto: caseDto,
                    repository: widget.repository,
                  )
                : caseDto.isMusicKitBox
                ? MusicKitBoxOpenScreen(
                    caseDto: caseDto,
                    repository: widget.repository,
                  )
                : caseDto.isGraffitiBox
                ? GraffitiBoxOpenScreen(
                    caseDto: caseDto,
                    repository: widget.repository,
                  )
                : caseDto.isPatchPack
                ? PatchContainerOpenScreen(
                    caseDto: caseDto,
                    repository: widget.repository,
                  )
                : CaseOpenScreen(
                    caseDto: caseDto,
                    repository: widget.repository,
                    settingsController: widget.settingsController,
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Container')),
      body: FutureBuilder<List<CaseDto>>(
        future: _casesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allCases = List<CaseDto>.from(snapshot.data!);
          final visibleCases = _applyFilters(allCases);

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = ResponsiveGridHelper.listCrossAxisCount(
                constraints.maxWidth,
              );
              final aspectRatio = ResponsiveGridHelper.listChildAspectRatio(
                constraints.maxWidth,
              );

              return Column(
                children: [
                  _buildFilterBar(allCases),
                  Expanded(
                    child: visibleCases.isEmpty
                        ? const Center(
                            child: Text(
                              'No containers match the selected filters.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: visibleCases.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: aspectRatio,
                                ),
                            itemBuilder: (context, index) {
                              return _buildCaseCard(
                                context,
                                visibleCases[index],
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
