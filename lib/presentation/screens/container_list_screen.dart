import 'package:flutter/material.dart';

import '../../core/settings/settings_controller.dart';
import '../../data/models/container_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/async_collection_loader.dart';
import '../widgets/chip_badge.dart';
import '../widgets/collection_filter_bar.dart';
import '../widgets/collection_list_card.dart';
import '../widgets/responsive_collection_grid.dart';

class ContainerListScreen extends StatefulWidget {
  final LocalDataRepository repository;
  final SettingsController settingsController;

  const ContainerListScreen({
    super.key,
    required this.repository,
    required this.settingsController,
  });

  @override
  State<ContainerListScreen> createState() => _ContainerListScreenState();
}

class _ContainerListScreenState extends State<ContainerListScreen> {
  late Future<List<ContainerDto>> _containersFuture;

  static const String _filterAll = 'ALL';
  String _selectedFilter = _filterAll;

  @override
  void initState() {
    super.initState();
    _containersFuture = widget.repository.loadContainers();
  }

  List<String> _availableFilters(List<ContainerDto> containers) {
    final types = <String>{_filterAll};

    for (final containerDto in containers) {
      if (containerDto.isXrayPackage ||
          containerDto.isStickerCollection ||
          containerDto.isPatchCollection ||
          containerDto.isCharmCollection ||
          containerDto.isAgentCollection ||
          containerDto.isRewardCollection ||
          containerDto.isOperationCollection) {
        continue;
      }
      types.add(containerDto.type);
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

  List<ContainerDto> _applyFilters(List<ContainerDto> containers) {
    var filtered = List<ContainerDto>.from(containers);

    filtered = filtered
        .where(
          (c) =>
              !c.isXrayPackage &&
              !c.isStickerCollection &&
              !c.isPatchCollection &&
              !c.isCharmCollection &&
              !c.isAgentCollection &&
              !c.isRewardCollection &&
              !c.isOperationCollection,
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

  Widget _buildFilterBar(List<ContainerDto> allContainers) {
    final filters = _availableFilters(allContainers);

    if (_selectedFilter != _filterAll && !filters.contains(_selectedFilter)) {
      _selectedFilter = _filterAll;
    }

    return CollectionFilterBar<String>(
      items: filters,
      selectedItem: _selectedFilter,
      labelBuilder: _filterLabel,
      onSelected: (type) {
        setState(() {
          _selectedFilter = type;
        });
      },
    );
  }

  Widget _buildCaseCard(BuildContext context, ContainerDto containerDto) {
    final typeColor = SourceColorHelper.containerTypeColor(containerDto.type);
    final chips = <Widget>[
      ChipBadge(label: containerDto.typeLabel, color: typeColor),
    ];

    if (containerDto.isStickerCollection &&
        containerDto.sourceTypeLabel != null) {
      final sourceColor = SourceColorHelper.collectibleSourceColor(
        containerDto.sourceType,
        containerDto.sourceId,
      );
      chips.add(
        ChipBadge(label: containerDto.sourceTypeLabel!, color: sourceColor),
      );

      if ((containerDto.sourceName ?? '').isNotEmpty) {
        chips.add(
          ChipBadge(label: containerDto.sourceName!, color: sourceColor),
        );
      }
    }

    return CollectionListCard(
      imagePath: containerDto.containerImage,
      title: containerDto.name,
      releaseDate: containerDto.releaseDate,
      chips: chips,
      metadata: const [],
      onTap: () {
        AppNavigationHelper.pushScreen(
          context,
          AppNavigationHelper.buildContainerOpenScreen(
            containerDto: containerDto,
            repository: widget.repository,
            settingsController: widget.settingsController,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Container')),
      body: AsyncCollectionLoader<ContainerDto>(
        future: _containersFuture,
        builder: (context, allContainers) {
          final visibleContainers = _applyFilters(allContainers);

          return ResponsiveCollectionGrid<ContainerDto>(
            items: visibleContainers,
            emptyMessage: 'No containers match the selected filters.',
            header: _buildFilterBar(allContainers),
            itemBuilder: _buildCaseCard,
          );
        },
      ),
    );
  }
}
