import 'package:flutter/material.dart';

import '../../data/models/charm_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import '../helpers/charm_ui_helper.dart';
import '../widgets/detail_tag.dart';
import '../widgets/generic_glossary_screen.dart';
import '../widgets/glossary_filter_dropdown.dart';
import '../widgets/glossary_list_item.dart';
import 'charm_details_screen.dart';

class CharmGlossaryScreen extends StatefulWidget {
  final LocalDataRepository repository;

  const CharmGlossaryScreen({super.key, required this.repository});

  @override
  State<CharmGlossaryScreen> createState() => _CharmGlossaryScreenState();
}

class _CharmGlossaryScreenState extends State<CharmGlossaryScreen> {
  String _rarityFilter = 'ALL';
  String _collectionFilter = 'ALL';

  static const List<GlossaryFilterOption> _rarityOptions = [
    GlossaryFilterOption('ALL', 'All rarities'),
    GlossaryFilterOption('HIGH_GRADE', 'High Grade'),
    GlossaryFilterOption('REMARKABLE', 'Remarkable'),
    GlossaryFilterOption('EXTRAORDINARY', 'Extraordinary'),
    GlossaryFilterOption('EXOTIC', 'Exotic'),
  ];

  List<GlossaryFilterOption> _collectionOptions(List<CharmDto> items) {
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

  List<CharmDto> _filterAndSort(List<CharmDto> items, String query) {
    final filtered = items.where((charm) {
      if (_rarityFilter != 'ALL' && charm.rarity != _rarityFilter) {
        return false;
      }
      if (_collectionFilter != 'ALL' &&
          (charm.collection ?? '') != _collectionFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      final haystack = <String>[
        charm.name,
        charm.collection ?? '',
        charm.rarity,
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

  int _rarityOrder(CharmDto charm) {
    switch (charm.rarity) {
      case 'HIGH_GRADE':
        return 0;
      case 'REMARKABLE':
        return 1;
      case 'EXOTIC':
        return 2;
      case 'EXTRAORDINARY':
        return 3;
      default:
        return 999;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GenericGlossaryScreen<CharmDto>(
      title: 'Charm Glossary',
      searchHint: 'Search by charm or collection...',
      future: widget.repository.loadCharms(),
      filterAndSort: _filterAndSort,
      countLabelBuilder: (count) => '$count charms',
      emptyMessage: 'No charms found.',
      errorPrefix: 'Failed to load charms.',
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
      itemBuilder: (context, charm) {
        final color = CharmUiHelper.rarityColor(charm);
        return GlossaryListItem(
          accentColor: color,
          imagePath: charm.charmImage,
          title: charm.name,
          subtitle: CharmUiHelper.secondaryText(charm),
          tags: [
            DetailTag(text: CharmUiHelper.rarityLabel(charm), color: color),
            if ((charm.collection ?? '').isNotEmpty)
              DetailTag(text: charm.collection!),
          ],
          onTap: () {
            AppNavigationHelper.pushScreen(
              context,
              CharmDetailsScreen(repository: widget.repository, charm: charm),
            );
          },
        );
      },
    );
  }
}
