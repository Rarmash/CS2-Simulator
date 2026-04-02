import 'package:flutter/material.dart';

import '../../core/settings/settings_controller.dart';
import '../../core/utils/date_format_helper.dart';
import '../../data/models/case_dto.dart';
import '../../data/models/operation_collection_dto.dart';
import '../../data/models/reward_collection_dto.dart';
import '../../data/models/skin_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../helpers/app_navigation_helper.dart';
import '../helpers/skin_ui_helper.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/detail_source_section.dart';
import '../widgets/detail_source_tile.dart';
import '../widgets/detail_tag.dart';
import '../widgets/float_cap_bar.dart';
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
                            errorBuilder: (_, _, _) => const Icon(
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
                    AppNavigationHelper.pushScreen(
                      context,
                      AppNavigationHelper.buildContainerOpenScreen(
                        caseDto: item,
                        repository: repository,
                        settingsController: settingsController,
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
                    AppNavigationHelper.pushScreen(
                      context,
                      RewardCollectionOpenScreen(
                        collection: item,
                        repository: repository,
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
                    AppNavigationHelper.pushScreen(
                      context,
                      OperationCollectionOpenScreen(
                        collection: item,
                        repository: repository,
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
    return DetailTag(text: text, color: color);
  }

  Widget _infoRow(String title, String value) {
    return DetailInfoRow(title: title, value: value);
  }

  Widget _sourceSection<T>({
    required String title,
    required List<T> items,
    required String emptyText,
    required Widget Function(T item) itemBuilder,
  }) {
    return DetailSourceSection<T>(
      title: title,
      items: items,
      emptyText: emptyText,
      itemBuilder: itemBuilder,
    );
  }

  Widget _sourceTile({
    required String imagePath,
    required String title,
    required String subtitle,
    required String trailing,
    required VoidCallback onTap,
  }) {
    return DetailSourceTile(
      imagePath: imagePath,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
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
