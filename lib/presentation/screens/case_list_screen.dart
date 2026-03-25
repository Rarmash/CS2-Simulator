import 'package:flutter/material.dart';

import '../../data/models/case_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import 'case_open_screen.dart';

class CaseListScreen extends StatefulWidget {
  final LocalDataRepository repository;

  const CaseListScreen({super.key, required this.repository});

  @override
  State<CaseListScreen> createState() => _CaseListScreenState();
}

class _CaseListScreenState extends State<CaseListScreen> {
  late Future<List<CaseDto>> _casesFuture;

  static const String _filterAll = 'ALL';
  String _selectedFilter = _filterAll;

  @override
  void initState() {
    super.initState();
    _casesFuture = widget.repository.loadCases();
  }

  String? _formatReleaseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    final parts = raw.split('-');
    if (parts.length != 3) return raw;

    const months = {
      '01': 'Jan',
      '02': 'Feb',
      '03': 'Mar',
      '04': 'Apr',
      '05': 'May',
      '06': 'Jun',
      '07': 'Jul',
      '08': 'Aug',
      '09': 'Sep',
      '10': 'Oct',
      '11': 'Nov',
      '12': 'Dec',
    };

    final year = parts[0];
    final month = months[parts[1]] ?? parts[1];
    final day = parts[2];

    return '$day $month $year';
  }

  int _crossAxisCount(double width) {
    if (width >= 1500) return 4;
    if (width >= 1100) return 3;
    if (width >= 700) return 2;
    return 1;
  }

  double _childAspectRatio(double width) {
    if (width >= 1100) return 1.45;
    if (width >= 700) return 1.35;
    return 2.4;
  }

  Color _typeColor(CaseDto caseDto) {
    if (caseDto.isSouvenirPackage) return Colors.amber;
    if (caseDto.isCollectionPackage) return Colors.lightBlueAccent;
    if (caseDto.isTerminal) return Colors.deepPurpleAccent;
    return Colors.blueAccent;
  }

  List<String> _availableFilters(List<CaseDto> cases) {
    final types = <String>{_filterAll};

    for (final caseDto in cases) {
      if (caseDto.isXrayPackage) continue;
      types.add(caseDto.type);
    }

    final ordered = <String>[_filterAll];
    const preferredOrder = [
      'CASE',
      'SOUVENIR_PACKAGE',
      'COLLECTION_PACKAGE',
      'TERMINAL',
    ];

    for (final type in preferredOrder) {
      if (types.contains(type)) {
        ordered.add(type);
      }
    }

    for (final type in types) {
      if (!ordered.contains(type)) {
        ordered.add(type);
      }
    }

    return ordered;
  }

  String _filterLabel(String type) {
    switch (type) {
      case _filterAll:
        return 'All';
      case 'CASE':
        return 'Cases';
      case 'SOUVENIR_PACKAGE':
        return 'Souvenir';
      case 'COLLECTION_PACKAGE':
        return 'Collection';
      case 'TERMINAL':
        return 'Terminal';
      default:
        return type;
    }
  }

  List<CaseDto> _applyFilters(List<CaseDto> cases) {
    var filtered = List<CaseDto>.from(cases);

    filtered = filtered.where((c) => !c.isXrayPackage).toList();

    if (_selectedFilter != _filterAll) {
      filtered = filtered.where((c) => c.type == _selectedFilter).toList();
    }

    filtered.sort((a, b) {
      final ad = a.releaseDate ?? '9999-99-99';
      final bd = b.releaseDate ?? '9999-99-99';
      final byDate = ad.compareTo(bd);
      if (byDate != 0) return byDate;
      return a.name.compareTo(b.name);
    });

    return filtered;
  }

  Widget _buildFilterBar(List<CaseDto> allCases) {
    final filters = _availableFilters(allCases);

    if (_selectedFilter != _filterAll && !filters.contains(_selectedFilter)) {
      _selectedFilter = _filterAll;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: filters.map((type) {
          return ChoiceChip(
            label: Text(_filterLabel(type)),
            selected: _selectedFilter == type,
            onSelected: (_) {
              setState(() {
                _selectedFilter = type;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCaseCard(BuildContext context, CaseDto caseDto) {
    final releaseDate = _formatReleaseDate(caseDto.releaseDate);
    final typeColor = _typeColor(caseDto);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CaseOpenScreen(
              caseDto: caseDto,
              repository: widget.repository,
            ),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Colors.white10,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 320;

              final image = Image.asset(
                caseDto.caseImage,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.inventory_2,
                  size: 56,
                ),
              );

              final textBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: typeColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      caseDto.typeLabel,
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    caseDto.name,
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (releaseDate != null)
                    Text(
                      'Released: $releaseDate',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                ],
              );

              if (constraints.maxWidth < 500) {
                return Row(
                  children: [
                    SizedBox(
                      width: 92,
                      height: 92,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: image,
                      ),
                    ),
                    Expanded(child: textBlock),
                  ],
                );
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: image,
                    ),
                  ),
                  textBlock,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Case'),
      ),
      body: FutureBuilder<List<CaseDto>>(
        future: _casesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allCases = List<CaseDto>.from(snapshot.data!);
          final visibleCases = _applyFilters(allCases);

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = _crossAxisCount(constraints.maxWidth);
              final aspectRatio = _childAspectRatio(constraints.maxWidth);

              return Column(
                children: [
                  _buildFilterBar(allCases),
                  Expanded(
                    child: visibleCases.isEmpty
                        ? const Center(
                      child: Text(
                        'No containers match the selected filters.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                        : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: visibleCases.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: aspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        return _buildCaseCard(context, visibleCases[index]);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}