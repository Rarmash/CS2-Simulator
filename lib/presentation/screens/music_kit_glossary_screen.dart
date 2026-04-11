import 'package:flutter/material.dart';

import '../../data/models/music_kit_group_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import '../helpers/music_kit_ui_helper.dart';
import '../widgets/detail_tag.dart';
import '../widgets/generic_glossary_screen.dart';
import '../widgets/glossary_filter_dropdown.dart';
import '../widgets/glossary_list_item.dart';
import 'music_kit_details_screen.dart';

class MusicKitGlossaryScreen extends StatefulWidget {
  final LocalDataRepository repository;

  const MusicKitGlossaryScreen({super.key, required this.repository});

  @override
  State<MusicKitGlossaryScreen> createState() => _MusicKitGlossaryScreenState();
}

class _MusicKitGlossaryScreenState extends State<MusicKitGlossaryScreen> {
  String _variantFilter = 'ALL';
  String _seriesFilter = 'ALL';

  static const List<GlossaryFilterOption> _variantOptions = [
    GlossaryFilterOption('ALL', 'All variants'),
    GlossaryFilterOption('REGULAR_ONLY', 'Regular only'),
    GlossaryFilterOption('STATTRAK_ONLY', 'StatTrak only'),
    GlossaryFilterOption('BOTH', 'Both variants'),
  ];

  List<GlossaryFilterOption> _seriesOptions(List<MusicKitGroupDto> items) {
    final values =
        items
            .map((item) => (item.collection ?? '').trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return [
      const GlossaryFilterOption('ALL', 'All series'),
      ...values.map((value) => GlossaryFilterOption(value, value)),
    ];
  }

  Future<List<MusicKitGroupDto>> _loadEntries() {
    return widget.repository.loadGroupedMusicKits();
  }

  List<MusicKitGroupDto> _filterAndSort(
    List<MusicKitGroupDto> items,
    String query,
  ) {
    final filtered = items.where((entry) {
      if (_variantFilter == 'REGULAR_ONLY' &&
          (!entry.hasRegular || entry.hasStatTrak)) {
        return false;
      }
      if (_variantFilter == 'STATTRAK_ONLY' &&
          (!entry.hasStatTrak || entry.hasRegular)) {
        return false;
      }
      if (_variantFilter == 'BOTH' &&
          !(entry.hasRegular && entry.hasStatTrak)) {
        return false;
      }
      if (_seriesFilter != 'ALL' && (entry.collection ?? '') != _seriesFilter) {
        return false;
      }

      if (query.isEmpty) return true;
      final haystack = <String>[
        entry.name,
        entry.trackName,
        entry.artist ?? '',
        entry.collection ?? '',
        entry.rarity,
        if (entry.hasRegular) 'music kit',
        if (entry.hasStatTrak) 'stattrak',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();

    filtered.sort((a, b) {
      final rarityCompare = _rarityOrder(a).compareTo(_rarityOrder(b));
      if (rarityCompare != 0) return rarityCompare;
      final statTrakCompare = a.hasStatTrak == b.hasStatTrak
          ? 0
          : (a.hasStatTrak ? 1 : -1);
      if (statTrakCompare != 0) return statTrakCompare;
      return a.trackName.compareTo(b.trackName);
    });

    return filtered;
  }

  int _rarityOrder(MusicKitGroupDto musicKit) {
    switch (musicKit.rarity) {
      case 'HIGH_GRADE':
        return 0;
      default:
        return 999;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GenericGlossaryScreen<MusicKitGroupDto>(
      title: 'Music Kit Glossary',
      searchHint: 'Search by track, artist, or series...',
      future: _loadEntries(),
      filterAndSort: _filterAndSort,
      countLabelBuilder: (count) => '$count music kits',
      emptyMessage: 'No music kits found.',
      errorPrefix: 'Failed to load music kits.',
      headerControlsBuilder: (_, items) => [
        Row(
          children: [
            Expanded(
              child: GlossaryFilterDropdown(
                label: 'Variant',
                value: _variantFilter,
                options: _variantOptions,
                onChanged: (value) {
                  setState(() {
                    _variantFilter = value ?? 'ALL';
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlossaryFilterDropdown(
                label: 'Series',
                value: _seriesFilter,
                options: _seriesOptions(items),
                onChanged: (value) {
                  setState(() {
                    _seriesFilter = value ?? 'ALL';
                  });
                },
              ),
            ),
          ],
        ),
      ],
      collectedCountBuilder: (musicKit, collectedByItemId) =>
          musicKit.variants.fold<int>(
            0,
            (sum, variant) => sum + (collectedByItemId[variant.id] ?? 0),
          ),
      itemBuilder: (context, musicKit, collectedCount) {
        final color = MusicKitUiHelper.rarityColor(musicKit.primary);
        return GlossaryListItem(
          accentColor: color,
          imagePath: musicKit.imagePath,
          title: musicKit.trackName,
          subtitle: MusicKitUiHelper.groupedSecondaryText(musicKit),
          collectionInfo: collectedCount > 0
              ? 'Collected $collectedCount'
              : null,
          tags: [
            DetailTag(
              text: MusicKitUiHelper.rarityLabel(musicKit.primary),
              color: color,
            ),
            DetailTag(text: MusicKitUiHelper.groupedTypeLabel(musicKit)),
            if ((musicKit.collection ?? '').isNotEmpty)
              DetailTag(text: musicKit.collection!),
          ],
          onTap: () {
            AppNavigationHelper.pushScreen(
              context,
              MusicKitDetailsScreen(
                repository: widget.repository,
                musicKitName: musicKit.name,
                collection: musicKit.collection,
              ),
            );
          },
        );
      },
    );
  }
}
