import 'package:flutter/material.dart';

import '../../core/utils/date_format_helper.dart';
import '../../data/models/container_dto.dart';
import '../../data/models/charm_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import '../helpers/charm_ui_helper.dart';
import '../widgets/collectible_details_card.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/detail_source_section.dart';
import '../widgets/detail_source_tile.dart';
import '../widgets/detail_tag.dart';

class CharmDetailsScreen extends StatelessWidget {
  final LocalDataRepository repository;
  final CharmDto charm;

  const CharmDetailsScreen({
    super.key,
    required this.repository,
    required this.charm,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = CharmUiHelper.rarityColor(charm);

    return Scaffold(
      appBar: AppBar(title: Text(charm.name)),
      body: FutureBuilder<List<ContainerDto>>(
        future: repository.loadContainersForCharm(charm.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load charm details.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final cases = snapshot.data ?? const <ContainerDto>[];

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              CollectibleDetailsCard(
                imagePath: charm.charmImage,
                title: charm.name,
                subtitle: CharmUiHelper.secondaryText(charm),
                tags: [
                  DetailTag(
                    text: CharmUiHelper.rarityLabel(charm),
                    color: rarityColor,
                  ),
                  if ((charm.collection ?? '').isNotEmpty)
                    DetailTag(text: charm.collection!),
                ],
                infoRows: [
                  DetailInfoRow(
                    title: 'Rarity',
                    value: CharmUiHelper.rarityLabel(charm),
                  ),
                  if ((charm.collection ?? '').isNotEmpty)
                    DetailInfoRow(
                      title: 'Collection',
                      value: charm.collection!,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              DetailSourceSection<ContainerDto>(
                title: 'Collections',
                items: cases,
                emptyText: 'No charm collection sources found.',
                itemBuilder: (item) => DetailSourceTile(
                  imagePath: item.containerImage,
                  title: item.name,
                  subtitle: item.typeLabel,
                  trailing:
                      DateFormatHelper.formatReleaseDate(item.releaseDate) ??
                      '-',
                  onTap: () {
                    AppNavigationHelper.pushScreen(
                      context,
                      AppNavigationHelper.buildContainerOpenScreen(
                        containerDto: item,
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
}
