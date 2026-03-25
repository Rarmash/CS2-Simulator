class RewardCollectionDto {
  final String id;
  final String name;
  final String image;
  final String sourceType; // OPERATION | ARMORY
  final String sourceId; // BROKEN_FANG | RIPTIDE | ARMORY
  final String currency; // STARS | CREDITS
  final int cost;
  final String? releaseDate;

  RewardCollectionDto({
    required this.id,
    required this.name,
    required this.image,
    required this.sourceType,
    required this.sourceId,
    required this.currency,
    required this.cost,
    required this.releaseDate,
  });

  factory RewardCollectionDto.fromJson(Map<String, dynamic> json) {
    return RewardCollectionDto(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String,
      sourceType: json['sourceType'] as String,
      sourceId: json['sourceId'] as String,
      currency: json['currency'] as String,
      cost: (json['cost'] as num).toInt(),
      releaseDate: json['releaseDate'] as String?,
    );
  }

  bool get isOperation => sourceType == 'OPERATION';
  bool get isArmory => sourceType == 'ARMORY';

  String get sourceLabel {
    switch (sourceId) {
      case 'BROKEN_FANG':
        return 'Operation Broken Fang';
      case 'RIPTIDE':
        return 'Operation Riptide';
      case 'ARMORY':
        return 'The Armory';
      default:
        return sourceId
            .split('_')
            .map((part) {
          if (part.isEmpty) return part;
          final lower = part.toLowerCase();
          return lower[0].toUpperCase() + lower.substring(1);
        })
            .join(' ');
    }
  }

  String get currencyLabel {
    switch (currency) {
      case 'STARS':
        return 'Stars';
      case 'CREDITS':
        return 'Credits';
      default:
        return currency;
    }
  }

  String get actionLabel => 'Spend $cost $currencyLabel';
}