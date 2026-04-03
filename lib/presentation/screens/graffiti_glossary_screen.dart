import 'package:flutter/material.dart';

import '../../data/models/graffiti_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import '../helpers/graffiti_ui_helper.dart';
import '../widgets/detail_tag.dart';
import '../widgets/generic_glossary_screen.dart';
import '../widgets/glossary_filter_dropdown.dart';
import '../widgets/glossary_list_item.dart';
import 'graffiti_details_screen.dart';

class GraffitiGlossaryScreen extends StatefulWidget {
  final LocalDataRepository repository;

  const GraffitiGlossaryScreen({super.key, required this.repository});

  @override
  State<GraffitiGlossaryScreen> createState() => _GraffitiGlossaryScreenState();
}

class _GraffitiGlossaryScreenState extends State<GraffitiGlossaryScreen> {
  String _rarityFilter = 'ALL';

  static const List<GlossaryFilterOption> _rarityOptions = [
    GlossaryFilterOption('ALL', 'All rarities'),
    GlossaryFilterOption('BASE_GRADE', 'Base Grade'),
    GlossaryFilterOption('HIGH_GRADE', 'High Grade'),
    GlossaryFilterOption('REMARKABLE', 'Remarkable'),
    GlossaryFilterOption('EXOTIC', 'Exotic'),
  ];

  List<GraffitiDto> _filterAndSort(List<GraffitiDto> items, String query) {
    final filtered = items.where((graffiti) {
      if (_rarityFilter != 'ALL' && graffiti.rarity != _rarityFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      final haystack = <String>[
        graffiti.name,
        graffiti.collection ?? '',
        graffiti.rarity,
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

  int _rarityOrder(GraffitiDto graffiti) {
    switch (graffiti.rarity) {
      case 'BASE_GRADE':
        return 0;
      case 'HIGH_GRADE':
        return 1;
      case 'REMARKABLE':
        return 2;
      case 'EXOTIC':
        return 3;
      default:
        return 999;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GenericGlossaryScreen<GraffitiDto>(
      title: 'Graffiti Glossary',
      searchHint: 'Search by graffiti or collection...',
      future: widget.repository.loadGraffiti(),
      filterAndSort: _filterAndSort,
      countLabelBuilder: (count) => '$count graffiti',
      emptyMessage: 'No graffiti found.',
      errorPrefix: 'Failed to load graffiti.',
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
      itemBuilder: (context, graffiti) {
        final color = GraffitiUiHelper.rarityColor(graffiti);
        return GlossaryListItem(
          accentColor: color,
          imagePath: graffiti.graffitiImage,
          title: graffiti.name,
          subtitle: GraffitiUiHelper.secondaryText(graffiti),
          tags: [
            DetailTag(text: GraffitiUiHelper.rarityLabel(graffiti), color: color),
            if ((graffiti.collection ?? '').isNotEmpty)
              DetailTag(text: graffiti.collection!),
          ],
          onTap: () {
            AppNavigationHelper.pushScreen(
              context,
              GraffitiDetailsScreen(
                repository: widget.repository,
                graffiti: graffiti,
              ),
            );
          },
        );
      },
    );
  }
}
