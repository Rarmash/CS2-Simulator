import 'package:flutter/material.dart';

import '../../core/utils/date_format_helper.dart';
import '../../data/models/container_dto.dart';
import '../../data/models/music_kit_dto.dart';
import '../../data/models/music_kit_group_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import '../helpers/music_kit_ui_helper.dart';
import '../widgets/collectible_details_card.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/detail_source_section.dart';
import '../widgets/detail_source_tile.dart';
import '../widgets/detail_tag.dart';

class MusicKitDetailsScreen extends StatelessWidget {
  final LocalDataRepository repository;
  final String musicKitName;
  final String? collection;

  const MusicKitDetailsScreen({
    super.key,
    required this.repository,
    required this.musicKitName,
    required this.collection,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titleFromName(musicKitName))),
      body: FutureBuilder<_MusicKitDetailsData>(
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
                  'Failed to load music kit details.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data =
              snapshot.data ??
              const _MusicKitDetailsData(group: null, containers: []);
          if (data.group == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Music kit data is missing.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final group = data.group!;
          final primary = group.primary;
          final rarityColor = MusicKitUiHelper.rarityColor(primary);

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              CollectibleDetailsCard(
                imagePath: primary.musicKitImage,
                title: primary.trackName,
                subtitle: MusicKitUiHelper.groupedSecondaryText(group),
                tags: [
                  DetailTag(
                    text: MusicKitUiHelper.rarityLabel(primary),
                    color: rarityColor,
                  ),
                  DetailTag(text: MusicKitUiHelper.groupedTypeLabel(group)),
                  if ((primary.collection ?? '').isNotEmpty)
                    DetailTag(text: primary.collection!),
                ],
                infoRows: [
                  if ((primary.artist ?? '').isNotEmpty)
                    DetailInfoRow(title: 'Artist', value: primary.artist!),
                  DetailInfoRow(title: 'Track', value: primary.trackName),
                  DetailInfoRow(
                    title: 'Rarity',
                    value: MusicKitUiHelper.rarityLabel(primary),
                  ),
                  DetailInfoRow(
                    title: 'Type',
                    value: MusicKitUiHelper.groupedTypeLabel(group),
                  ),
                  DetailInfoRow(
                    title: 'StatTrak™ variant',
                    value: _statTrakAvailabilityLabel(
                      hasRegular: group.hasRegular,
                      hasStatTrak: group.hasStatTrak,
                    ),
                  ),
                  if ((primary.collection ?? '').isNotEmpty)
                    DetailInfoRow(title: 'Series', value: primary.collection!),
                ],
              ),
              const SizedBox(height: 12),
              DetailSourceSection<ContainerDto>(
                title: 'Boxes',
                items: data.containers,
                emptyText: 'No music kit box sources found.',
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

  Future<_MusicKitDetailsData> _loadData() async {
    final group = await repository.loadMusicKitGroup(musicKitName, collection);
    final containers = await repository.loadContainersForMusicKitGroup(
      musicKitName,
      collection,
    );

    return _MusicKitDetailsData(group: group, containers: containers);
  }

  String _titleFromName(String fullName) {
    final dto = MusicKitDto(
      id: '',
      name: fullName,
      musicKitImage: '',
      rarity: '',
      collection: null,
      hasRegular: true,
      hasStatTrak: false,
    );
    return dto.trackName;
  }

  String _statTrakAvailabilityLabel({
    required bool hasRegular,
    required bool hasStatTrak,
  }) {
    if (hasRegular && hasStatTrak) {
      return 'Available';
    }
    if (hasStatTrak) {
      return 'Only variant';
    }
    return 'No';
  }
}

class _MusicKitDetailsData {
  final MusicKitGroupDto? group;
  final List<ContainerDto> containers;

  const _MusicKitDetailsData({required this.group, required this.containers});
}
