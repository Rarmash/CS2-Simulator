import 'package:flutter/material.dart';

import '../../data/models/case_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/responsive_grid_helper.dart';
import '../helpers/source_color_helper.dart';
import '../widgets/chip_badge.dart';
import '../widgets/collection_list_card.dart';
import 'patch_collection_open_screen.dart';

class PatchCollectionListScreen extends StatefulWidget {
  final LocalDataRepository repository;

  const PatchCollectionListScreen({super.key, required this.repository});

  @override
  State<PatchCollectionListScreen> createState() =>
      _PatchCollectionListScreenState();
}

class _PatchCollectionListScreenState extends State<PatchCollectionListScreen> {
  late Future<List<CaseDto>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.loadPatchCollections();
  }

  Widget _buildCard(BuildContext context, CaseDto collection) {
    final typeColor = SourceColorHelper.containerTypeColor(collection.type);
    final sourceColor = SourceColorHelper.collectibleSourceColor(
      collection.sourceType,
      collection.sourceId,
    );

    return CollectionListCard(
      imagePath: collection.caseImage,
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
      ],
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatchCollectionOpenScreen(
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
      appBar: AppBar(title: const Text('Patch Collections')),
      body: FutureBuilder<List<CaseDto>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = List<CaseDto>.from(snapshot.data!);
          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = ResponsiveGridHelper.listCrossAxisCount(
                constraints.maxWidth,
              );
              final aspectRatio = ResponsiveGridHelper.listChildAspectRatio(
                constraints.maxWidth,
              );

              return items.isEmpty
                  ? const Center(
                      child: Text(
                        'No patch collections found.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: aspectRatio,
                      ),
                      itemBuilder: (context, index) =>
                          _buildCard(context, items[index]),
                    );
            },
          );
        },
      ),
    );
  }
}
