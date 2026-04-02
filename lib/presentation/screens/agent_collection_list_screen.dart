import 'package:flutter/material.dart';

import '../../data/models/agent_collection_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/async_collection_loader.dart';
import '../widgets/chip_badge.dart';
import '../widgets/collection_list_card.dart';
import '../widgets/responsive_collection_grid.dart';
import 'agent_collection_open_screen.dart';

class AgentCollectionListScreen extends StatefulWidget {
  final LocalDataRepository repository;

  const AgentCollectionListScreen({super.key, required this.repository});

  @override
  State<AgentCollectionListScreen> createState() =>
      _AgentCollectionListScreenState();
}

class _AgentCollectionListScreenState extends State<AgentCollectionListScreen> {
  late Future<List<AgentCollectionDto>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.loadAgentCollections();
  }

  Widget _buildCard(BuildContext context, AgentCollectionDto collection) {
    final color = SourceColorHelper.operationColor(collection.operationId);

    return CollectionListCard(
      imagePath: collection.image,
      title: collection.name,
      releaseDate: collection.releaseDate,
      chips: [ChipBadge(label: 'Agent Collection', color: color)],
      metadata: [
        const SizedBox(height: 8),
        Text(
          collection.operationName,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
      onTap: () {
        AppNavigationHelper.pushScreen(
          context,
          AgentCollectionOpenScreen(
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
      appBar: AppBar(title: const Text('Agent Collections')),
      body: AsyncCollectionLoader<AgentCollectionDto>(
        future: _future,
        builder: (context, items) {
          return ResponsiveCollectionGrid<AgentCollectionDto>(
            items: items,
            emptyMessage: 'No agent collections found.',
            itemBuilder: _buildCard,
          );
        },
      ),
    );
  }
}
