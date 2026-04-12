import 'package:flutter/material.dart';

import '../../core/collection/collection_tracking_service.dart';
import '../../data/models/container_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/async_collection_loader.dart';
import '../widgets/chip_badge.dart';
import '../widgets/collection_list_card.dart';
import '../widgets/collection_source_progress_metadata.dart';
import '../widgets/responsive_collection_grid.dart';
import 'charm_collection_open_screen.dart';

class CharmCollectionListScreen extends StatefulWidget {
  final LocalDataRepository repository;

  const CharmCollectionListScreen({super.key, required this.repository});

  @override
  State<CharmCollectionListScreen> createState() =>
      _CharmCollectionListScreenState();
}

class _CharmCollectionListScreenState extends State<CharmCollectionListScreen> {
  late Future<List<ContainerDto>> _future;
  final CollectionTrackingService _collectionTracking =
      CollectionTrackingService();

  @override
  void initState() {
    super.initState();
    _future = widget.repository.loadCharmCollections();
  }

  Widget _buildCard(BuildContext context, ContainerDto collection) {
    final typeColor = SourceColorHelper.containerTypeColor(collection.type);
    final sourceColor = SourceColorHelper.collectibleSourceColor(
      collection.sourceType,
      collection.sourceId,
    );

    return CollectionListCard(
      imagePath: collection.containerImage,
      title: collection.name,
      releaseDate: collection.releaseDate,
      chips: [
        ChipBadge(label: collection.typeLabel, color: typeColor),
        if (collection.sourceTypeLabel != null)
          ChipBadge(label: collection.sourceTypeLabel!, color: sourceColor),
      ],
      metadata: [
        if ((collection.sourceName ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            collection.sourceName!,
            style: TextStyle(
              color: sourceColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        CollectionSourceProgressMetadata(
          container: collection,
          repository: widget.repository,
          trackingService: _collectionTracking,
        ),
      ],
      onTap: () {
        AppNavigationHelper.pushScreen(
          context,
          CharmCollectionOpenScreen(
            collection: collection,
            repository: widget.repository,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Charm Collections')),
      body: AsyncCollectionLoader<ContainerDto>(
        future: _future,
        builder: (context, items) {
          return ResponsiveCollectionGrid<ContainerDto>(
            items: items,
            emptyMessage: 'No charm collections found.',
            itemBuilder: _buildCard,
          );
        },
      ),
    );
  }
}
