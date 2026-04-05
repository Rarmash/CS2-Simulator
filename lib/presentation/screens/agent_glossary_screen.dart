import 'package:flutter/material.dart';

import '../../data/models/agent_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/agent_ui_helper.dart';
import '../helpers/app_navigation_helper.dart';
import '../widgets/detail_tag.dart';
import '../widgets/generic_glossary_screen.dart';
import '../widgets/glossary_filter_dropdown.dart';
import '../widgets/glossary_list_item.dart';
import 'agent_details_screen.dart';

class AgentGlossaryScreen extends StatefulWidget {
  final LocalDataRepository repository;

  const AgentGlossaryScreen({super.key, required this.repository});

  @override
  State<AgentGlossaryScreen> createState() => _AgentGlossaryScreenState();
}

class _AgentGlossaryScreenState extends State<AgentGlossaryScreen> {
  String _rarityFilter = 'ALL';
  String _sideFilter = 'ALL';
  String _collectionFilter = 'ALL';

  static const List<GlossaryFilterOption> _rarityOptions = [
    GlossaryFilterOption('ALL', 'All rarities'),
    GlossaryFilterOption('DISTINGUISHED', 'Distinguished'),
    GlossaryFilterOption('EXCEPTIONAL', 'Exceptional'),
    GlossaryFilterOption('SUPERIOR', 'Superior'),
    GlossaryFilterOption('MASTER', 'Master'),
  ];

  static const List<GlossaryFilterOption> _sideOptions = [
    GlossaryFilterOption('ALL', 'All sides'),
    GlossaryFilterOption('COUNTER-TERRORIST', 'CT Side'),
    GlossaryFilterOption('TERRORIST', 'T Side'),
  ];

  List<GlossaryFilterOption> _collectionOptions(List<AgentDto> items) {
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

  List<AgentDto> _filterAndSort(List<AgentDto> items, String query) {
    final filtered = items.where((agent) {
      if (_rarityFilter != 'ALL' && agent.rarity != _rarityFilter) {
        return false;
      }
      if (_sideFilter != 'ALL' && agent.team != _sideFilter) {
        return false;
      }
      if (_collectionFilter != 'ALL' &&
          (agent.collection ?? '') != _collectionFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      final haystack = <String>[
        agent.name,
        agent.collection ?? '',
        agent.team,
        agent.rarity,
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

  int _rarityOrder(AgentDto agent) {
    switch (agent.rarity) {
      case 'DISTINGUISHED':
        return 0;
      case 'EXCEPTIONAL':
        return 1;
      case 'SUPERIOR':
        return 2;
      case 'MASTER':
        return 3;
      default:
        return 999;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GenericGlossaryScreen<AgentDto>(
      title: 'Agent Glossary',
      searchHint: 'Search by agent, collection, team...',
      future: widget.repository.loadAgents(),
      filterAndSort: _filterAndSort,
      countLabelBuilder: (count) => '$count agents',
      emptyMessage: 'No agents found.',
      errorPrefix: 'Failed to load agents.',
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
                label: 'Side',
                value: _sideFilter,
                options: _sideOptions,
                onChanged: (value) {
                  setState(() {
                    _sideFilter = value ?? 'ALL';
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GlossaryFilterDropdown(
          label: 'Collection',
          value: _collectionFilter,
          options: _collectionOptions(items),
          onChanged: (value) {
            setState(() {
              _collectionFilter = value ?? 'ALL';
            });
          },
        ),
      ],
      itemBuilder: (context, agent) {
        final color = AgentUiHelper.rarityColor(agent);
        return GlossaryListItem(
          accentColor: color,
          imagePath: agent.agentImage,
          title: agent.name,
          subtitle: AgentUiHelper.secondaryText(agent),
          tags: [
            DetailTag(text: AgentUiHelper.rarityLabel(agent), color: color),
            DetailTag(
              text: agent.team == 'COUNTER-TERRORIST' ? 'CT Side' : 'T Side',
            ),
            if ((agent.collection ?? '').isNotEmpty)
              DetailTag(text: agent.collection!),
          ],
          onTap: () {
            AppNavigationHelper.pushScreen(
              context,
              AgentDetailsScreen(repository: widget.repository, agent: agent),
            );
          },
        );
      },
    );
  }
}
