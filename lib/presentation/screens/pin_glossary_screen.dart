import 'package:flutter/material.dart';

import '../../data/models/pin_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import '../helpers/pin_ui_helper.dart';
import '../widgets/detail_tag.dart';
import '../widgets/generic_glossary_screen.dart';
import '../widgets/glossary_filter_dropdown.dart';
import '../widgets/glossary_list_item.dart';
import 'pin_details_screen.dart';

class PinGlossaryScreen extends StatefulWidget {
  final LocalDataRepository repository;

  const PinGlossaryScreen({super.key, required this.repository});

  @override
  State<PinGlossaryScreen> createState() => _PinGlossaryScreenState();
}

class _PinGlossaryScreenState extends State<PinGlossaryScreen> {
  String _rarityFilter = 'ALL';
  String _collectionFilter = 'ALL';

  static const List<GlossaryFilterOption> _rarityOptions = [
    GlossaryFilterOption('ALL', 'All rarities'),
    GlossaryFilterOption('GENUINE', 'Genuine'),
    GlossaryFilterOption('HIGH_GRADE', 'High Grade'),
    GlossaryFilterOption('REMARKABLE', 'Remarkable'),
    GlossaryFilterOption('EXOTIC', 'Exotic'),
    GlossaryFilterOption('EXTRAORDINARY', 'Extraordinary'),
  ];

  List<GlossaryFilterOption> _collectionOptions(List<PinDto> items) {
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

  List<PinDto> _filterAndSort(List<PinDto> items, String query) {
    final filtered = items.where((pin) {
      if (_rarityFilter != 'ALL' && pin.rarity != _rarityFilter) {
        return false;
      }
      if (_collectionFilter != 'ALL' &&
          (pin.collection ?? '') != _collectionFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      final haystack = <String>[
        pin.name,
        pin.collection ?? '',
        pin.rarity,
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

  int _rarityOrder(PinDto pin) {
    switch (pin.rarity) {
      case 'GENUINE':
        return 0;
      case 'HIGH_GRADE':
        return 1;
      case 'REMARKABLE':
        return 2;
      case 'EXOTIC':
        return 3;
      case 'EXTRAORDINARY':
        return 4;
      default:
        return 999;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GenericGlossaryScreen<PinDto>(
      title: 'Pin Glossary',
      searchHint: 'Search by pin or collection...',
      future: widget.repository.loadPins(),
      filterAndSort: _filterAndSort,
      countLabelBuilder: (count) => '$count pins',
      emptyMessage: 'No pins found.',
      errorPrefix: 'Failed to load pins.',
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
      itemBuilder: (context, pin) {
        final color = PinUiHelper.rarityColor(pin);
        return GlossaryListItem(
          accentColor: color,
          imagePath: pin.pinImage,
          title: pin.name,
          subtitle: PinUiHelper.secondaryText(pin),
          tags: [
            DetailTag(text: PinUiHelper.rarityLabel(pin), color: color),
            if ((pin.collection ?? '').isNotEmpty)
              DetailTag(text: pin.collection!),
          ],
          onTap: () {
            AppNavigationHelper.pushScreen(
              context,
              PinDetailsScreen(repository: widget.repository, pin: pin),
            );
          },
        );
      },
    );
  }
}
