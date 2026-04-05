import 'package:flutter/material.dart';

import '../../core/utils/date_format_helper.dart';
import '../../data/models/container_dto.dart';
import '../../data/models/patch_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import '../helpers/patch_ui_helper.dart';
import '../widgets/collectible_details_card.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/detail_source_section.dart';
import '../widgets/detail_source_tile.dart';
import '../widgets/detail_tag.dart';

class PatchDetailsScreen extends StatelessWidget {
  final LocalDataRepository repository;
  final PatchDto patch;

  const PatchDetailsScreen({
    super.key,
    required this.repository,
    required this.patch,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = PatchUiHelper.rarityColor(patch);

    return Scaffold(
      appBar: AppBar(title: Text(patch.name)),
      body: FutureBuilder<List<ContainerDto>>(
        future: repository.loadContainersForPatch(patch.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load patch details.\n${snapshot.error}',
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
                imagePath: patch.patchImage,
                title: patch.name,
                subtitle: PatchUiHelper.secondaryText(patch),
                tags: [
                  DetailTag(
                    text: PatchUiHelper.rarityLabel(patch),
                    color: rarityColor,
                  ),
                  if ((patch.collection ?? '').isNotEmpty)
                    DetailTag(text: patch.collection!),
                ],
                infoRows: [
                  DetailInfoRow(
                    title: 'Rarity',
                    value: PatchUiHelper.rarityLabel(patch),
                  ),
                  if ((patch.collection ?? '').isNotEmpty)
                    DetailInfoRow(
                      title: 'Collection',
                      value: patch.collection!,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              DetailSourceSection<ContainerDto>(
                title: 'Sources',
                items: cases,
                emptyText: 'No patch sources found.',
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
