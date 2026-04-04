import 'package:flutter/material.dart';

import '../../data/models/sticker_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import '../helpers/sticker_ui_helper.dart';
import '../widgets/detail_tag.dart';
import '../widgets/generic_glossary_screen.dart';
import '../widgets/glossary_filter_dropdown.dart';
import '../widgets/glossary_list_item.dart';
import 'sticker_details_screen.dart';

class StickerGlossaryScreen extends StatefulWidget {
  final LocalDataRepository repository;

  const StickerGlossaryScreen({super.key, required this.repository});

  @override
  State<StickerGlossaryScreen> createState() => _StickerGlossaryScreenState();
}

class _StickerGlossaryScreenState extends State<StickerGlossaryScreen> {
  String _rarityFilter = 'ALL';
  String _sourceFilter = 'ALL';

  static const List<GlossaryFilterOption> _rarityOptions = [
    GlossaryFilterOption('ALL', 'All rarities'),
    GlossaryFilterOption('HIGH_GRADE', 'High Grade'),
    GlossaryFilterOption('REMARKABLE', 'Remarkable'),
    GlossaryFilterOption('EXOTIC', 'Exotic'),
    GlossaryFilterOption('EXTRAORDINARY', 'Extraordinary'),
    GlossaryFilterOption('CONTRABAND', 'Contraband'),
  ];

  List<GlossaryFilterOption> _sourceOptions(List<StickerDto> items) {
    final values = items
        .map((item) => item.sourceLabel.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return [
      const GlossaryFilterOption('ALL', 'All sources'),
      ...values.map((value) => GlossaryFilterOption(value, value)),
    ];
  }

  List<StickerDto> _filterAndSort(List<StickerDto> items, String query) {
    final filtered = items.where((sticker) {
      if (_rarityFilter != 'ALL' && sticker.rarity != _rarityFilter) {
        return false;
      }
      if (_sourceFilter != 'ALL' && sticker.sourceLabel != _sourceFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      final haystack = <String>[
        sticker.name,
        sticker.collection ?? '',
        sticker.tournament ?? '',
        sticker.stickerType,
        sticker.effect,
        sticker.rarity,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();

    filtered.sort((a, b) {
      final rarityCompare = _rarityOrder(a).compareTo(_rarityOrder(b));
      if (rarityCompare != 0) return rarityCompare;
      return a.name.compareTo(b.name);
    });

    return filtered;
  }

  int _rarityOrder(StickerDto sticker) {
    switch (sticker.rarity) {
      case 'HIGH_GRADE':
        return 0;
      case 'REMARKABLE':
        return 1;
      case 'EXOTIC':
        return 2;
      case 'EXTRAORDINARY':
        return 3;
      case 'CONTRABAND':
        return 4;
      default:
        return 999;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GenericGlossaryScreen<StickerDto>(
      title: 'Sticker Glossary',
      searchHint: 'Search by sticker, collection, tournament...',
      future: widget.repository.loadStickers(),
      filterAndSort: _filterAndSort,
      countLabelBuilder: (count) => '$count stickers',
      emptyMessage: 'No stickers found.',
      errorPrefix: 'Failed to load stickers.',
      headerControlsBuilder: (_, items) => [
        Row(
          children: [
            Expanded(
              child: GlossaryFilterDropdown(
                label: 'Rarity',
                value: _rarityFilter,
                options: _rarityOptions,
                onChanged: (value) {
                  setState(() {
                    _rarityFilter = value ?? 'ALL';
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlossaryFilterDropdown(
                label: 'Source',
                value: _sourceFilter,
                options: _sourceOptions(items),
                onChanged: (value) {
                  setState(() {
                    _sourceFilter = value ?? 'ALL';
                  });
                },
              ),
            ),
          ],
        ),
      ],
      itemBuilder: (context, sticker) {
        final color = StickerUiHelper.rarityColor(sticker);
        return GlossaryListItem(
          accentColor: color,
          imagePath: sticker.stickerImage,
          title: sticker.name,
          subtitle: StickerUiHelper.secondaryText(sticker),
          tags: [
            DetailTag(text: StickerUiHelper.rarityLabel(sticker), color: color),
            DetailTag(text: sticker.stickerTypeLabel),
            if (sticker.effect != 'OTHER')
              DetailTag(text: StickerUiHelper.effectLabel(sticker.effect)),
          ],
          onTap: () {
            AppNavigationHelper.pushScreen(
              context,
              StickerDetailsScreen(
                repository: widget.repository,
                sticker: sticker,
              ),
            );
          },
        );
      },
    );
  }
}
