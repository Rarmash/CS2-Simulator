import 'package:flutter/material.dart';

import '../../data/models/patch_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import '../helpers/patch_ui_helper.dart';
import '../widgets/detail_tag.dart';
import '../widgets/generic_glossary_screen.dart';
import '../widgets/glossary_filter_dropdown.dart';
import '../widgets/glossary_list_item.dart';
import 'patch_details_screen.dart';

class PatchGlossaryScreen extends StatefulWidget {
  final LocalDataRepository repository;

  const PatchGlossaryScreen({super.key, required this.repository});

  @override
  State<PatchGlossaryScreen> createState() => _PatchGlossaryScreenState();
}

class _PatchGlossaryScreenState extends State<PatchGlossaryScreen> {
  String _rarityFilter = 'ALL';
  String _collectionFilter = 'ALL';

  static const List<GlossaryFilterOption> _rarityOptions = [
    GlossaryFilterOption('ALL', 'All rarities'),
    GlossaryFilterOption('HIGH_GRADE', 'High Grade'),
    GlossaryFilterOption('REMARKABLE', 'Remarkable'),
    GlossaryFilterOption('EXOTIC', 'Exotic'),
  ];

  List<GlossaryFilterOption> _collectionOptions(List<PatchDto> items) {
    final values =
        items
            .map((item) => (item.collection ?? '').trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return [
      const GlossaryFilterOption('ALL', 'All collections'),
      ...values.map((value) => GlossaryFilterOption(value, value)),
    ];
  }

  List<PatchDto> _filterAndSort(List<PatchDto> items, String query) {
    final filtered = items.where((patch) {
      if (_rarityFilter != 'ALL' && patch.rarity != _rarityFilter) {
        return false;
      }
      if (_collectionFilter != 'ALL' &&
          (patch.collection ?? '') != _collectionFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      final haystack = <String>[
        patch.name,
        patch.collection ?? '',
        patch.rarity,
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

  int _rarityOrder(PatchDto patch) {
    switch (patch.rarity) {
      case 'HIGH_GRADE':
        return 0;
      case 'REMARKABLE':
        return 1;
      case 'EXOTIC':
        return 2;
      default:
        return 999;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GenericGlossaryScreen<PatchDto>(
      title: 'Patch Glossary',
      searchHint: 'Search by patch or collection...',
      future: widget.repository.loadPatches(),
      filterAndSort: _filterAndSort,
      countLabelBuilder: (count) => '$count patches',
      emptyMessage: 'No patches found.',
      errorPrefix: 'Failed to load patches.',
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
                label: 'Collection',
                value: _collectionFilter,
                options: _collectionOptions(items),
                onChanged: (value) {
                  setState(() {
                    _collectionFilter = value ?? 'ALL';
                  });
                },
              ),
            ),
          ],
        ),
      ],
      collectedCountBuilder: (patch, collectedByItemId) =>
          collectedByItemId[patch.id] ?? 0,
      itemBuilder: (context, patch, collectedCount) {
        final color = PatchUiHelper.rarityColor(patch);
        return GlossaryListItem(
          accentColor: color,
          imagePath: patch.patchImage,
          title: patch.name,
          subtitle: PatchUiHelper.secondaryText(patch),
          collectionInfo: collectedCount > 0
              ? 'Collected $collectedCount'
              : null,
          tags: [
            DetailTag(text: PatchUiHelper.rarityLabel(patch), color: color),
            if ((patch.collection ?? '').isNotEmpty)
              DetailTag(text: patch.collection!),
          ],
          onTap: () {
            AppNavigationHelper.pushScreen(
              context,
              PatchDetailsScreen(repository: widget.repository, patch: patch),
            );
          },
        );
      },
    );
  }
}
