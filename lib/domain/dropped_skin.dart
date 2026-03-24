import '../data/models/skin_dto.dart';

class DroppedSkin {
  final SkinDto skin;
  final bool isStatTrak;
  final double? skinFloat;
  final String? exterior;

  const DroppedSkin({
    required this.skin,
    required this.isStatTrak,
    required this.skinFloat,
    required this.exterior,
  });

  bool get isVanillaKnife => skin.isKnife && skin.name == 'Vanilla';

  String get fullDisplayName {
    final prefix = isStatTrak ? 'StatTrak™ ' : '';
    return '$prefix${skin.itemDisplayName} | ${skin.name}';
  }
}