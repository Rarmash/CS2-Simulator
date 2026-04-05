import 'music_kit_dto.dart';

class MusicKitGroupDto {
  final String name;
  final String trackName;
  final String? artist;
  final String? collection;
  final String rarity;
  final bool hasRegular;
  final bool hasStatTrak;
  final String imagePath;
  final List<MusicKitDto> variants;

  const MusicKitGroupDto({
    required this.name,
    required this.trackName,
    required this.artist,
    required this.collection,
    required this.rarity,
    required this.hasRegular,
    required this.hasStatTrak,
    required this.imagePath,
    required this.variants,
  });

  factory MusicKitGroupDto.fromVariants(List<MusicKitDto> variants) {
    final sorted = [...variants]..sort(_compareMusicKitVariants);
    final primary = sorted.first;

    return MusicKitGroupDto(
      name: primary.name,
      trackName: primary.trackName,
      artist: primary.artist,
      collection: primary.collection,
      rarity: primary.rarity,
      hasRegular: sorted.any((item) => item.hasRegular),
      hasStatTrak: sorted.any((item) => item.hasStatTrak),
      imagePath: primary.musicKitImage,
      variants: sorted,
    );
  }

  MusicKitDto get primary => variants.first;

  static int _compareMusicKitVariants(MusicKitDto a, MusicKitDto b) {
    final aOrder = a.hasRegular && !a.hasStatTrak
        ? 0
        : (a.hasRegular && a.hasStatTrak ? 1 : 2);
    final bOrder = b.hasRegular && !b.hasStatTrak
        ? 0
        : (b.hasRegular && b.hasStatTrak ? 1 : 2);
    if (aOrder == bOrder) {
      return a.id.compareTo(b.id);
    }
    return aOrder.compareTo(bOrder);
  }
}
