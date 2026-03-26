import 'package:flutter/material.dart';

import '../../core/settings/settings_controller.dart';
import '../../core/utils/date_format_helper.dart';
import '../../data/models/case_dto.dart';
import '../../data/models/operation_collection_dto.dart';
import '../../data/models/reward_collection_dto.dart';
import '../../data/models/skin_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/skin_ui_helper.dart';
import '../widgets/float_cap_bar.dart';
import 'case_open_screen.dart';
import 'operation_collection_open_screen.dart';
import 'reward_collection_open_screen.dart';

class SkinDetailsScreen extends StatelessWidget {
  final LocalDataRepository repository;
  final SettingsController settingsController;
  final SkinDto skin;

  const SkinDetailsScreen({
    super.key,
    required this.repository,
    required this.settingsController,
    required this.skin,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = SkinUiHelper.rarityColor(skin);

    return Scaffold(
      appBar: AppBar(
        title: Text(skin.itemDisplayName),
      ),
      body: FutureBuilder<_SkinSourcesData>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load skin details.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data ??
              const _SkinSourcesData(
                cases: [],
                rewardCollections: [],
                operationCollections: [],
              );

          return ListView(
            cacheExtent: 1000,
            padding: const EdgeInsets.all(12),
            children: [
              RepaintBoundary(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final narrow = constraints.maxWidth < 700;

                        final image = Container(
                          alignment: Alignment.center,
                          child: Image.asset(
                            skin.skinImage,
                            height: narrow ? 150 : 200,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.low,
                            isAntiAlias: false,
                            gaplessPlayback: true,
                            cacheWidth: narrow ? 420 : 640,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_not_supported,
                              size: 64,
                            ),
                          ),
                        );

                        final info = Column(
                          crossAxisAlignment: narrow
                              ? CrossAxisAlignment.center
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              skin.itemDisplayName,
                              textAlign:
                              narrow ? TextAlign.center : TextAlign.left,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              SkinUiHelper.secondaryText(skin),
                              textAlign:
                              narrow ? TextAlign.center : TextAlign.left,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _tag(
                                  SkinUiHelper.rarityLabel(skin),
                                  color: rarityColor,
                                ),
                                _tag(
                                  skin.itemKind == 'WEAPON'
                                      ? SkinUiHelper.weaponTypeLabel(
                                    skin.weaponType,
                                  )
                                      : skin.itemKind == 'KNIFE'
                                      ? 'Knife'
                                      : 'Gloves',
                                ),
                                if ((skin.collection ?? '').isNotEmpty)
                                  _tag(skin.collection!),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _infoRow(
                              'Weapon / slot',
                              SkinUiHelper.weaponTypeLabel(skin.weaponType),
                            ),
                            if ((skin.finishCatalogName ?? '').isNotEmpty)
                              _infoRow(
                                'Finish catalog',
                                skin.finishCatalogName!,
                              ),
                            if ((skin.variantName ?? '').isNotEmpty)
                              _infoRow(
                                'Variant',
                                skin.variantName!,
                              ),
                            if ((skin.phase ?? '').isNotEmpty)
                              _infoRow(
                                'Phase',
                                skin.phase!,
                              ),
                            if ((skin.apiPaintIndex ?? '').isNotEmpty)
                              _infoRow(
                                'Paint index',
                                skin.apiPaintIndex!,
                              ),
                          ],
                        );

                        if (narrow) {
                          return Column(
                            children: [
                              image,
                              const SizedBox(height: 16),
                              info,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: image,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 5,
                              child: info,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Float Cap',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FloatCapBar(
                        minFloat: skin.floatTop,
                        maxFloat: skin.floatBottom,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Red segment shows the valid float range for this skin.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _sourceSection<CaseDto>(
                title: 'Cases / Containers',
                items: data.cases,
                emptyText: 'This skin is not present in case/container data.',
                itemBuilder: (item) => _sourceTile(
                  imagePath: item.caseImage,
                  title: item.name,
                  subtitle: item.typeLabel,
                  trailing:
                  DateFormatHelper.formatReleaseDate(item.releaseDate) ?? '-',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CaseOpenScreen(
                          caseDto: item,
                          repository: repository,
                          settingsController: settingsController,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              _sourceSection<RewardCollectionDto>(
                title: 'Reward Collections / Armory',
                items: data.rewardCollections,
                emptyText: 'No reward collection sources found.',
                itemBuilder: (item) => _sourceTile(
                  imagePath: item.image,
                  title: item.name,
                  subtitle: _rewardCollectionSubtitle(item),
                  trailing:
                  DateFormatHelper.formatReleaseDate(item.releaseDate) ?? '-',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RewardCollectionOpenScreen(
                          collection: item,
                          repository: repository,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              _sourceSection<OperationCollectionDto>(
                title: 'Legacy Operation Collections',
                items: data.operationCollections,
                emptyText: 'No legacy operation collection sources found.',
                itemBuilder: (item) => _sourceTile(
                  imagePath: item.image,
                  title: item.name,
                  subtitle: item.operationLabel,
                  trailing:
                  DateFormatHelper.formatReleaseDate(item.releaseDate) ?? '-',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OperationCollectionOpenScreen(
                          collection: item,
                          repository: repository,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<_SkinSourcesData> _loadData() async {
    final results = await Future.wait<dynamic>([
      repository.loadCasesForSkin(skin.id),
      repository.loadRewardCollectionsForSkin(skin.id),
      repository.loadOperationCollectionsForSkin(skin.id),
    ]);

    return _SkinSourcesData(
      cases: results[0] as List<CaseDto>,
      rewardCollections: results[1] as List<RewardCollectionDto>,
      operationCollections: results[2] as List<OperationCollectionDto>,
    );
  }

  Widget _tag(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Colors.white24).withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color ?? Colors.white24,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceSection<T>({
    required String title,
    required List<T> items,
    required String emptyText,
    required Widget Function(T item) itemBuilder,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title (${items.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(
                emptyText,
                style: const TextStyle(
                  color: Colors.white70,
                ),
              )
            else
              ...items.map(itemBuilder),
          ],
        ),
      ),
    );
  }

  Widget _sourceTile({
    required String imagePath,
    required String title,
    required String subtitle,
    required String trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      imagePath,
                      width: 34,
                      height: 34,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.low,
                      isAntiAlias: false,
                      gaplessPlayback: true,
                      cacheWidth: 96,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      trailing,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Colors.white38,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _rewardCollectionSubtitle(RewardCollectionDto item) {
    final parts = <String>[
      item.sourceLabel,
      item.actionLabel,
    ];

    return parts.join(' • ');
  }
}

class _SkinSourcesData {
  final List<CaseDto> cases;
  final List<RewardCollectionDto> rewardCollections;
  final List<OperationCollectionDto> operationCollections;

  const _SkinSourcesData({
    required this.cases,
    required this.rewardCollections,
    required this.operationCollections,
  });
}