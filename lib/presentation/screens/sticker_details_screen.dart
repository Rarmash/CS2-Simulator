import 'package:flutter/material.dart';

import '../../core/utils/date_format_helper.dart';
import '../../data/models/container_dto.dart';
import '../../data/models/sticker_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import '../helpers/sticker_ui_helper.dart';
import '../widgets/collectible_details_card.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/detail_source_section.dart';
import '../widgets/detail_source_tile.dart';
import '../widgets/detail_tag.dart';

class StickerDetailsScreen extends StatelessWidget {
  final LocalDataRepository repository;
  final StickerDto sticker;

  const StickerDetailsScreen({
    super.key,
    required this.repository,
    required this.sticker,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = StickerUiHelper.rarityColor(sticker);

    return Scaffold(
      appBar: AppBar(title: Text(sticker.name)),
      body: FutureBuilder<List<ContainerDto>>(
        future: repository.loadContainersForSticker(sticker.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load sticker details.\n${snapshot.error}',
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
                imagePath: sticker.stickerImage,
                title: sticker.name,
                subtitle: StickerUiHelper.secondaryText(sticker),
                tags: [
                  DetailTag(
                    text: StickerUiHelper.rarityLabel(sticker),
                    color: rarityColor,
                  ),
                  DetailTag(text: sticker.stickerTypeLabel),
                  if (sticker.effect != 'OTHER')
                    DetailTag(
                      text: StickerUiHelper.effectLabel(sticker.effect),
                    ),
                  if ((sticker.collection ?? '').isNotEmpty)
                    DetailTag(text: sticker.collection!),
                  if ((sticker.tournament ?? '').isNotEmpty)
                    DetailTag(text: sticker.tournament!),
                ],
                infoRows: [
                  DetailInfoRow(
                    title: 'Rarity',
                    value: StickerUiHelper.rarityLabel(sticker),
                  ),
                  DetailInfoRow(title: 'Type', value: sticker.stickerTypeLabel),
                  DetailInfoRow(
                    title: 'Effect',
                    value: StickerUiHelper.effectLabel(sticker.effect),
                  ),
                  if ((sticker.collection ?? '').isNotEmpty)
                    DetailInfoRow(
                      title: 'Collection',
                      value: sticker.collection!,
                    ),
                  if ((sticker.tournament ?? '').isNotEmpty)
                    DetailInfoRow(
                      title: 'Tournament',
                      value: sticker.tournament!,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              DetailSourceSection<ContainerDto>(
                title: 'Containers',
                items: cases,
                emptyText: 'No sticker container sources found.',
                itemBuilder: (item) {
                  final subtitleParts = <String>[item.typeLabel];
                  if (item.sourceTypeLabel != null) {
                    subtitleParts.add(item.sourceTypeLabel!);
                  }
                  return DetailSourceTile(
                    imagePath: item.containerImage,
                    title: item.name,
                    subtitle: subtitleParts.join(' вЂў '),
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
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
