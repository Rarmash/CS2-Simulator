import 'package:flutter/material.dart';

import '../../core/collection/collection_tracking_service.dart';
import '../../data/models/container_dto.dart';
import '../../data/models/skin_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/special_item_variant_helper.dart';
import 'collection_source_stats.dart';

class CollectionSourceProgressMetadata extends StatelessWidget {
  final ContainerDto container;
  final LocalDataRepository repository;
  final CollectionTrackingService trackingService;

  const CollectionSourceProgressMetadata({
    super.key,
    required this.container,
    required this.repository,
    required this.trackingService,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _loadTotalCount(),
      builder: (context, snapshot) {
        final totalCount = snapshot.data;
        if (totalCount == null || totalCount <= 0) {
          return const SizedBox.shrink();
        }

        return CollectionSourceStatsWidget(
          sourceName: container.name,
          sourceType: container.typeLabel,
          service: trackingService,
          totalCount: totalCount,
          compact: true,
        );
      },
    );
  }

  Future<int> _loadTotalCount() async {
    if (container.isAgentCollection) {
      final agents = await repository.loadAgentsForCollection(container.id);
      return agents.length;
    }

    if (container.isCharmCollection) {
      final charms = await repository.loadCharmsForContainer(container.id);
      return charms.length;
    }

    if (container.isStickerCollection || container.isStickerCapsule) {
      final stickers = await repository.loadStickersForContainer(container.id);
      return stickers.length;
    }

    if (container.isPatchCollection || container.isPatchPack) {
      final patches = await repository.loadPatchesForContainer(container.id);
      return patches.length;
    }

    if (container.isPinCapsule) {
      final pins = await repository.loadPinsForContainer(container.id);
      return pins.length;
    }

    if (container.isMusicKitBox) {
      final musicKits = await repository.loadMusicKitsForContainer(
        container.id,
      );
      return musicKits.length;
    }

    if (container.isGraffitiBox) {
      final graffiti = await repository.loadGraffitiForContainer(container.id);
      return graffiti.length;
    }

    final skins = await repository.loadSkinsForContainer(container.id);
    return _groupedSkinFamilyCount(skins);
  }

  int _groupedSkinFamilyCount(List<SkinDto> skins) {
    final families = <String, List<SkinDto>>{};
    for (final skin in skins) {
      final key = SpecialItemVariantHelper.familyKeyForSkin(skin);
      families.putIfAbsent(key, () => <SkinDto>[]).add(skin);
    }

    var count = 0;
    for (final family in families.values) {
      final shouldGroup =
          family.length > 1 &&
          SpecialItemVariantHelper.hasConfiguredVariantWeights(family);
      count += shouldGroup ? 1 : family.length;
    }
    return count;
  }
}
