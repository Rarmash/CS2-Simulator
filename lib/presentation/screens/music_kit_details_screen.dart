import 'package:flutter/material.dart';

import '../../core/utils/date_format_helper.dart';
import '../../data/models/container_dto.dart';
import '../../data/models/music_kit_dto.dart';
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
              const _MusicKitDetailsData(variants: [], containers: []);
          if (data.variants.isEmpty) {
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

          final primary = data.primary;
          final rarityColor = MusicKitUiHelper.rarityColor(primary);
          final hasRegular = data.variants.any((item) => !item.isStatTrak);
          final hasStatTrak = data.variants.any((item) => item.isStatTrak);

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              CollectibleDetailsCard(
                imagePath: primary.musicKitImage,
                title: primary.trackName,
                subtitle: _subtitle(
                  primary,
                  hasRegular: hasRegular,
                  hasStatTrak: hasStatTrak,
                ),
                tags: [
                  DetailTag(
                    text: MusicKitUiHelper.rarityLabel(primary),
                    color: rarityColor,
                  ),
                  DetailTag(
                    text: _typeLabel(
                      hasRegular: hasRegular,
                      hasStatTrak: hasStatTrak,
                    ),
                  ),
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
                    value: _typeLabel(
                      hasRegular: hasRegular,
                      hasStatTrak: hasStatTrak,
                    ),
                  ),
                  DetailInfoRow(
                    title: 'StatTrakРІвЂћСћ variant',
                    value: _statTrakAvailabilityLabel(
                      hasRegular: hasRegular,
                      hasStatTrak: hasStatTrak,
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
    final allMusicKits = await repository.loadMusicKits();
    final variants = allMusicKits.where((musicKit) {
      return musicKit.name == musicKitName &&
          (musicKit.collection ?? '') == (collection ?? '');
    }).toList();

    final seenContainerIds = <String>{};
    final containers = <ContainerDto>[];
    for (final variant in variants) {
      final sources = await repository.loadContainersForMusicKit(variant.id);
      for (final item in sources) {
        if (seenContainerIds.add(item.id)) {
          containers.add(item);
        }
      }
    }
    containers.sort(
      (a, b) => (a.releaseDate ?? '9999-99-99').compareTo(
        b.releaseDate ?? '9999-99-99',
      ),
    );

    return _MusicKitDetailsData(variants: variants, containers: containers);
  }

  String _titleFromName(String fullName) {
    final dto = MusicKitDto(
      id: '',
      name: fullName,
      musicKitImage: '',
      rarity: '',
      collection: null,
      isStatTrak: false,
    );
    return dto.trackName;
  }

  String _subtitle(
    MusicKitDto musicKit, {
    required bool hasRegular,
    required bool hasStatTrak,
  }) {
    final parts = <String>[
      if ((musicKit.artist ?? '').isNotEmpty) musicKit.artist!,
      _typeLabel(hasRegular: hasRegular, hasStatTrak: hasStatTrak),
      if (hasRegular && hasStatTrak) 'Both variants',
      if ((musicKit.collection ?? '').isNotEmpty) musicKit.collection!,
    ];
    return parts.join(' | ');
  }

  String _typeLabel({required bool hasRegular, required bool hasStatTrak}) {
    if (hasRegular && hasStatTrak) {
      return 'Music Kit / StatTrakРІвЂћСћ';
    }
    if (hasStatTrak) {
      return 'StatTrakРІвЂћСћ Music Kit';
    }
    return 'Music Kit';
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
  final List<MusicKitDto> variants;
  final List<ContainerDto> containers;

  const _MusicKitDetailsData({
    required this.variants,
    required this.containers,
  });

  MusicKitDto get primary {
    final sorted = [...variants]
      ..sort((a, b) {
        if (a.isStatTrak == b.isStatTrak) {
          return a.id.compareTo(b.id);
        }
        return a.isStatTrak ? 1 : -1;
      });
    return sorted.first;
  }
}
