import 'skin_dto.dart';

class SkinGroupDto {
  final String key;
  final SkinDto primary;
  final List<SkinDto> variants;

  const SkinGroupDto({
    required this.key,
    required this.primary,
    required this.variants,
  });

  String get id => primary.id;
  String get name => primary.name;
  String get skinImage => primary.skinImage;
  String get itemDisplayName => primary.itemDisplayName;
  String get rarity => primary.rarity;
  String get weaponType => primary.weaponType;
  String get itemKind => primary.itemKind;
  String? get collection => primary.collection;
  bool get isSpecialItem => primary.isSpecialItem;
  bool get hasMultipleVariants => variants.length > 1;

  List<String> get variantLabels {
    final labels = <String>{};
    for (final variant in variants) {
      final label = variant.displayVariant;
      if (label != null && label.isNotEmpty) {
        labels.add(label);
      }
    }
    return labels.toList();
  }
}
