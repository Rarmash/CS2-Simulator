import 'package:flutter/material.dart';

import '../../core/collection/collection_summary.dart';
import '../../core/collection/collection_tracking_service.dart';
import '../../core/utils/date_format_helper.dart';
import '../../data/models/agent_dto.dart';
import '../../data/models/container_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/agent_ui_helper.dart';
import '../helpers/app_navigation_helper.dart';
import '../widgets/collectible_details_card.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/detail_source_section.dart';
import '../widgets/detail_source_tile.dart';
import '../widgets/detail_tag.dart';
import 'agent_collection_open_screen.dart';

class AgentDetailsScreen extends StatelessWidget {
  final LocalDataRepository repository;
  final AgentDto agent;
  static final CollectionTrackingService _collectionTracking =
      CollectionTrackingService();

  const AgentDetailsScreen({
    super.key,
    required this.repository,
    required this.agent,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = AgentUiHelper.rarityColor(agent);

    return Scaffold(
      appBar: AppBar(title: Text(agent.name)),
      body: FutureBuilder<_AgentDetailsData>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load agent details.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data =
              snapshot.data ?? const _AgentDetailsData(collections: []);

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              CollectibleDetailsCard(
                imagePath: agent.agentImage,
                title: agent.name,
                subtitle: AgentUiHelper.secondaryText(agent),
                tags: [
                  DetailTag(
                    text: AgentUiHelper.rarityLabel(agent),
                    color: rarityColor,
                  ),
                  DetailTag(
                    text: agent.team == 'COUNTER-TERRORIST'
                        ? 'CT Side'
                        : 'T Side',
                  ),
                  if ((agent.collection ?? '').isNotEmpty)
                    DetailTag(text: agent.collection!),
                ],
                infoRows: [
                  DetailInfoRow(
                    title: 'Rarity',
                    value: AgentUiHelper.rarityLabel(agent),
                  ),
                  DetailInfoRow(
                    title: 'Team',
                    value: agent.team == 'COUNTER-TERRORIST'
                        ? 'Counter-Terrorist'
                        : 'Terrorist',
                  ),
                  if (data.collectedCount > 0)
                    DetailInfoRow(
                      title: 'Collected',
                      value: '${data.collectedCount}',
                    ),
                  if ((agent.collection ?? '').isNotEmpty)
                    DetailInfoRow(
                      title: 'Collection',
                      value: agent.collection!,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              DetailSourceSection<ContainerDto>(
                title: 'Agent Collections',
                items: data.collections,
                emptyText: 'No agent collection sources found.',
                itemBuilder: (item) => DetailSourceTile(
                  imagePath: item.containerImage,
                  title: item.name,
                  subtitle: item.sourceLabel,
                  trailing:
                      DateFormatHelper.formatReleaseDate(item.releaseDate) ??
                      '-',
                  onTap: () {
                    AppNavigationHelper.pushScreen(
                      context,
                      AgentCollectionOpenScreen(
                        collection: item,
                        repository: repository,
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

  Future<_AgentDetailsData> _loadData() async {
    final results = await Future.wait<dynamic>([
      repository.loadAgentCollectionsForAgent(agent.id),
      _collectionTracking.loadSummaries(),
    ]);

    final summaries = results[1] as List<CollectionSummary>;
    final collectedCount = summaries
        .where(
          (item) =>
              item.category == 'agent' && item.latestEntry.itemId == agent.id,
        )
        .fold<int>(0, (sum, item) => sum + item.count);

    return _AgentDetailsData(
      collections: results[0] as List<ContainerDto>,
      collectedCount: collectedCount,
    );
  }
}

class _AgentDetailsData {
  final List<ContainerDto> collections;
  final int collectedCount;

  const _AgentDetailsData({required this.collections, this.collectedCount = 0});
}
