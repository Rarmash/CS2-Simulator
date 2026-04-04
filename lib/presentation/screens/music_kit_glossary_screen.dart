import 'package:flutter/material.dart';

import '../../data/models/music_kit_dto.dart';
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

  static const List<GlossaryFilterOption> _variantOptions = [
    GlossaryFilterOption('ALL', 'All variants'),
    GlossaryFilterOption('REGULAR_ONLY', 'Regular only'),
    GlossaryFilterOption('STATTRAK_ONLY', 'StatTrak only'),
    GlossaryFilterOption('BOTH', 'Both variants'),
  ];

  Future<List<_MusicKitGlossaryEntry>> _loadEntries() async {
    final items = await widget.repository.loadMusicKits();
    final grouped = <String, List<MusicKitDto>>{};
    for (final musicKit in items) {
      final key =
          '${musicKit.name.trim().toLowerCase()}|${(musicKit.collection ?? '').trim().toLowerCase()}';
      grouped.putIfAbsent(key, () => <MusicKitDto>[]).add(musicKit);
    }
    return grouped.values
        .map((variants) => _MusicKitGlossaryEntry.fromVariants(variants))
        .toList();
  }

  List<_MusicKitGlossaryEntry> _filterAndSort(
    List<_MusicKitGlossaryEntry> items,
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

  int _rarityOrder(_MusicKitGlossaryEntry musicKit) {
    switch (musicKit.rarity) {
      case 'HIGH_GRADE':
        return 0;
      default:
        return 999;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GenericGlossaryScreen<_MusicKitGlossaryEntry>(
      title: 'Music Kit Glossary',
      searchHint: 'Search by track, artist, or series...',
      future: _loadEntries(),
      filterAndSort: _filterAndSort,
      countLabelBuilder: (count) => '$count music kits',
      emptyMessage: 'No music kits found.',
      errorPrefix: 'Failed to load music kits.',
      headerControlsBuilder: (_) => [
        GlossaryFilterDropdown(
          label: 'Variant',
          value: _variantFilter,
          options: _variantOptions,
          onChanged: (value) {
            setState(() {
              _variantFilter = value ?? 'ALL';
            });
          },
        ),
      ],
      itemBuilder: (context, musicKit) {
        final color = MusicKitUiHelper.rarityColor(musicKit.primary);
        return GlossaryListItem(
          accentColor: color,
          imagePath: musicKit.imagePath,
          title: musicKit.trackName,
          subtitle: musicKit.subtitle,
          tags: [
            DetailTag(
              text: MusicKitUiHelper.rarityLabel(musicKit.primary),
              color: color,
            ),
            DetailTag(text: musicKit.typeLabel),
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

class _MusicKitGlossaryEntry {
  final String name;
  final String trackName;
  final String? artist;
  final String? collection;
  final String rarity;
  final bool hasRegular;
  final bool hasStatTrak;
  final String imagePath;
  final MusicKitDto primary;

  const _MusicKitGlossaryEntry({
    required this.name,
    required this.trackName,
    required this.artist,
    required this.collection,
    required this.rarity,
    required this.hasRegular,
    required this.hasStatTrak,
    required this.imagePath,
    required this.primary,
  });

  factory _MusicKitGlossaryEntry.fromVariants(List<MusicKitDto> variants) {
    final sorted = [...variants]
      ..sort((a, b) {
        if (a.isStatTrak == b.isStatTrak) {
          return a.id.compareTo(b.id);
        }
        return a.isStatTrak ? 1 : -1;
      });
    final primary = sorted.first;
    return _MusicKitGlossaryEntry(
      name: primary.name,
      trackName: primary.trackName,
      artist: primary.artist,
      collection: primary.collection,
      rarity: primary.rarity,
      hasRegular: sorted.any((item) => !item.isStatTrak),
      hasStatTrak: sorted.any((item) => item.isStatTrak),
      imagePath: primary.musicKitImage,
      primary: primary,
    );
  }

  String get typeLabel {
    if (hasRegular && hasStatTrak) {
      return 'Music Kit / StatTrak™';
    }
    if (hasStatTrak) {
      return 'StatTrak™ Music Kit';
    }
    return 'Music Kit';
  }

  String get subtitle {
    final parts = <String>[
      if ((artist ?? '').isNotEmpty) artist!,
      typeLabel,
      if (hasRegular && hasStatTrak) 'Both variants',
      if ((collection ?? '').isNotEmpty) collection!,
    ];
    return parts.join(' | ');
  }
}
