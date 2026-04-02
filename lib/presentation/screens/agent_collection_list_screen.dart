import 'package:flutter/material.dart';

import '../../data/models/agent_collection_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/responsive_grid_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/chip_badge.dart';
import '../widgets/collection_list_card.dart';
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AgentCollectionOpenScreen(
              collection: collection,
              repository: widget.repository,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agent Collections')),
      body: FutureBuilder<List<AgentCollectionDto>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = List<AgentCollectionDto>.from(snapshot.data!);
          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = ResponsiveGridHelper.listCrossAxisCount(
                constraints.maxWidth,
              );
              final aspectRatio = ResponsiveGridHelper.listChildAspectRatio(
                constraints.maxWidth,
              );

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: aspectRatio,
                ),
                itemBuilder: (context, index) => _buildCard(context, items[index]),
              );
            },
          );
        },
      ),
    );
  }
}
