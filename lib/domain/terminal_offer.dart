import '../data/models/skin_dto.dart';

class TerminalOffer {
  final SkinDto skin;
  final bool isStatTrak;
  final double? skinFloat;
  final String? exterior;
  final int offerIndex; // 1..5

  const TerminalOffer({
    required this.skin,
    required this.isStatTrak,
    required this.skinFloat,
    required this.exterior,
    required this.offerIndex,
  });
}