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

  static const List<GlossaryFilterOption> _rarityOptions = [
    GlossaryFilterOption('ALL', 'All rarities'),
    GlossaryFilterOption('HIGH_GRADE', 'High Grade'),
    GlossaryFilterOption('REMARKABLE', 'Remarkable'),
    GlossaryFilterOption('EXOTIC', 'Exotic'),
  ];

  List<PatchDto> _filterAndSort(List<PatchDto> items, String query) {
    final filtered = items.where((patch) {
      if (_rarityFilter != 'ALL' && patch.rarity != _rarityFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      final haystack = <String>[patch.name, patch.collection ?? '', patch.rarity]
          .join(' ')
          .toLowerCase();
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
      headerControlsBuilder: (_) => [
        GlossaryFilterDropdown(
          label: 'Rarity',
          value: _rarityFilter,
          options: _rarityOptions,
          onChanged: (value) {
            setState(() {
              _rarityFilter = value ?? 'ALL';
            });
          },
        ),
      ],
      itemBuilder: (context, patch) {
        final color = PatchUiHelper.rarityColor(patch);
        return GlossaryListItem(
          accentColor: color,
          imagePath: patch.patchImage,
          title: patch.name,
          subtitle: PatchUiHelper.secondaryText(patch),
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
