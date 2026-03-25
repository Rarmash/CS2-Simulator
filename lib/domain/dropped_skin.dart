import '../data/models/skin_dto.dart';

class DroppedSkin {
  final SkinDto skin;
  final bool isStatTrak;
  final bool isSouvenir;
  final double? skinFloat;
  final String? exterior;

  const DroppedSkin({
    required this.skin,
    required this.isStatTrak,
    required this.isSouvenir,
    required this.skinFloat,
    required this.exterior,
  });

  bool get isVanillaKnife => skin.isKnife && skin.name == 'Vanilla';

  String get fullDisplayName {
    final star = skin.isSpecialItem ? '★ ' : '';
    final souvenirPrefix = isSouvenir ? 'Souvenir ' : '';
    final statTrakPrefix = isStatTrak ? 'StatTrak™ ' : '';
    return '$star$souvenirPrefix$statTrakPrefix${skin.itemDisplayName} | ${skin.name}';
  }
}