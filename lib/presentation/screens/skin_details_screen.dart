import 'package:flutter/material.dart';

import '../../core/settings/settings_controller.dart';
import '../../core/utils/date_format_helper.dart';
import '../../data/models/container_dto.dart';
import '../../data/models/skin_dto.dart';
import '../../data/repositories/local_data_repository.dart';
import '../../domain/skin_pattern_helper.dart';
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
    final patternFamily = SkinPatternHelper.patternFamilyLabel(skin);
    final patternExplanation = SkinPatternHelper.patternExplanation(skin);
    final patternOutcomes = SkinPatternHelper.possiblePatternOutcomes(skin);
    final hasPatternSection =
        patternFamily != null ||
        SkinPatternHelper.supportsPatternSeed(skin) ||
        patternExplanation != null ||
        patternOutcomes.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(skin.itemDisplayName)),
      body: FutureBuilder<_SkinSourcesData>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
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

          final data =
              snapshot.data ??
              const _SkinSourcesData(
                containers: [],
                rewardCollections: [],
                operationCollections: [],
                variants: [],
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
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.image_not_supported, size: 64),
                          ),
                        );

                        final info = Column(
                          crossAxisAlignment: narrow
                              ? CrossAxisAlignment.center
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              skin.itemDisplayName,
                              textAlign: narrow
                                  ? TextAlign.center
                                  : TextAlign.left,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              SkinUiHelper.secondaryText(skin),
                              textAlign: narrow
                                  ? TextAlign.center
                                  : TextAlign.left,
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
                              _infoRow('Variant', skin.variantName!),
                            if ((skin.phase ?? '').isNotEmpty)
                              _infoRow('Phase', skin.phase!),
                            if ((skin.apiPaintIndex ?? '').isNotEmpty)
                              _infoRow('Paint index', skin.apiPaintIndex!),
                            if (patternFamily case final value?)
                              _infoRow('Pattern family', value),
                            if (SkinPatternHelper.supportsPatternSeed(skin))
                              _infoRow('Pattern support', 'Seed-based'),
                            if (SkinPatternHelper.hasExplicitPhaseVariant(skin))
                              _infoRow(
                                'Phase logic',
                                'Explicit variant with weighted family odds',
                              ),
                            if (SkinPatternHelper.supportsPatternSeed(skin))
                              _infoRow(
                                'Pattern notes',
                                'Drops may derive seed-based pattern details',
                              ),
                          ],
                        );

                        if (narrow) {
                          return Column(
                            children: [image, const SizedBox(height: 16), info],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 4, child: image),
                            const SizedBox(width: 16),
                            Expanded(flex: 5, child: info),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (hasPatternSection) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pattern Behavior',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (patternExplanation != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            patternExplanation,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        if (patternOutcomes.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          for (final outcome in patternOutcomes)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.circle,
                                      size: 7,
                                      color: Colors.white54,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      outcome,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
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
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              if (data.variants.length > 1) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Finish Variants',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: data.variants
                              .map(
                                (variant) => _variantCard(
                                  context,
                                  variant,
                                  selected: variant.id == skin.id,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _sourceSection<ContainerDto>(
                title: 'Cases / Containers',
                items: data.containers,
                emptyText: 'This skin is not present in case/container data.',
                itemBuilder: (item) => _sourceTile(
                  imagePath: item.containerImage,
                  title: item.name,
                  subtitle: item.typeLabel,
                  trailing:
                      DateFormatHelper.formatReleaseDate(item.releaseDate) ??
                      '-',
                  onTap: () {
                    AppNavigationHelper.pushScreen(
                      context,
                      AppNavigationHelper.buildContainerOpenScreen(
                        containerDto: item,
                        repository: repository,
                        settingsController: settingsController,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              _sourceSection<ContainerDto>(
                title: 'Reward Collections / Armory',
                items: data.rewardCollections,
                emptyText: 'No reward collection sources found.',
                itemBuilder: (item) => _sourceTile(
                  imagePath: item.containerImage,
                  title: item.name,
                  subtitle: _rewardCollectionSubtitle(item),
                  trailing:
                      DateFormatHelper.formatReleaseDate(item.releaseDate) ??
                      '-',
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
              _sourceSection<ContainerDto>(
                title: 'Legacy Operation Collections',
                items: data.operationCollections,
                emptyText: 'No legacy operation collection sources found.',
                itemBuilder: (item) => _sourceTile(
                  imagePath: item.containerImage,
                  title: item.name,
                  subtitle: item.operationLabel,
                  trailing:
                      DateFormatHelper.formatReleaseDate(item.releaseDate) ??
                      '-',
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
      repository.loadContainersForSkin(skin.id),
      repository.loadRewardCollectionsForSkin(skin.id),
      repository.loadOperationCollectionsForSkin(skin.id),
      repository.loadSkinVariantsForSkin(skin.id),
    ]);

    return _SkinSourcesData(
      containers: results[0] as List<ContainerDto>,
      rewardCollections: results[1] as List<ContainerDto>,
      operationCollections: results[2] as List<ContainerDto>,
      variants: results[3] as List<SkinDto>,
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

  Widget _variantCard(
    BuildContext context,
    SkinDto variant, {
    required bool selected,
  }) {
    final rarityColor = SkinUiHelper.rarityColor(variant);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: selected
          ? null
          : () {
              AppNavigationHelper.replaceScreen(
                context,
                SkinDetailsScreen(
                  repository: repository,
                  settingsController: settingsController,
                  skin: variant,
                ),
              );
            },
      child: Container(
        width: 144,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? rarityColor : Colors.white12,
            width: selected ? 2 : 1,
          ),
          color: selected ? rarityColor.withValues(alpha: 0.1) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 70,
              child: Image.asset(
                variant.skinImage,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.image_not_supported, size: 28),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              variant.displayVariant ?? variant.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _rewardCollectionSubtitle(ContainerDto item) {
    final parts = <String>[item.sourceLabel, item.actionLabel];

    return parts.join(' РІР‚Сћ ');
  }
}

class _SkinSourcesData {
  final List<ContainerDto> containers;
  final List<ContainerDto> rewardCollections;
  final List<ContainerDto> operationCollections;
  final List<SkinDto> variants;

  const _SkinSourcesData({
    required this.containers,
    required this.rewardCollections,
    required this.operationCollections,
    required this.variants,
  });
}
