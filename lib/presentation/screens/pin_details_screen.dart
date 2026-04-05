import 'package:flutter/material.dart';

import '../../core/utils/date_format_helper.dart';
import '../../data/models/container_dto.dart';
import '../../data/models/pin_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import '../helpers/pin_ui_helper.dart';
import '../widgets/collectible_details_card.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/detail_source_section.dart';
import '../widgets/detail_source_tile.dart';
import '../widgets/detail_tag.dart';

class PinDetailsScreen extends StatelessWidget {
  final LocalDataRepository repository;
  final PinDto pin;

  const PinDetailsScreen({
    super.key,
    required this.repository,
    required this.pin,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = PinUiHelper.rarityColor(pin);

    return Scaffold(
      appBar: AppBar(title: Text(pin.name)),
      body: FutureBuilder<List<ContainerDto>>(
        future: repository.loadContainersForPin(pin.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load pin details.\n${snapshot.error}',
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
                imagePath: pin.pinImage,
                title: pin.name,
                subtitle: PinUiHelper.secondaryText(pin),
                tags: [
                  DetailTag(
                    text: PinUiHelper.rarityLabel(pin),
                    color: rarityColor,
                  ),
                  if ((pin.collection ?? '').isNotEmpty)
                    DetailTag(text: pin.collection!),
                ],
                infoRows: [
                  DetailInfoRow(
                    title: 'Rarity',
                    value: PinUiHelper.rarityLabel(pin),
                  ),
                  if ((pin.collection ?? '').isNotEmpty)
                    DetailInfoRow(title: 'Collection', value: pin.collection!),
                ],
              ),
              const SizedBox(height: 12),
              DetailSourceSection<ContainerDto>(
                title: 'Containers',
                items: cases,
                emptyText: 'No pin capsule sources found.',
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
