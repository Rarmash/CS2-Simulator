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

  Widget _buildCaseCard(BuildContext context, CaseDto caseDto) {
    final releaseDate = _formatReleaseDate(caseDto.releaseDate);

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

          final cases = List<CaseDto>.from(snapshot.data!)
            ..sort((a, b) {
              final ad = a.releaseDate ?? '9999-99-99';
              final bd = b.releaseDate ?? '9999-99-99';
              return ad.compareTo(bd);
            });

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = _crossAxisCount(constraints.maxWidth);
              final aspectRatio = _childAspectRatio(constraints.maxWidth);

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: cases.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: aspectRatio,
                ),
                itemBuilder: (context, index) {
                  return _buildCaseCard(context, cases[index]);
                },
              );
            },
          );
        },
      ),
    );
  }
}