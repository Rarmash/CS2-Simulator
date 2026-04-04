class CaseDto {
  final String id;
  final String name;
  final String caseImage;
  final String? releaseDate;
  final String type;
  final String? sourceType;
  final String? sourceId;
  final String? sourceName;

  CaseDto({
    required this.id,
    required this.name,
    required this.caseImage,
    required this.releaseDate,
    required this.type,
    required this.sourceType,
    required this.sourceId,
    required this.sourceName,
  });

  factory CaseDto.fromJson(Map<String, dynamic> json) {
    return CaseDto(
      id: json['id'] as String,
      name: json['name'] as String,
      caseImage: json['caseImage'] as String,
      releaseDate: json['releaseDate'] as String?,
      type: (json['type'] as String?) ?? 'CASE',
      sourceType: json['sourceType'] as String?,
      sourceId: json['sourceId'] as String?,
      sourceName: json['sourceName'] as String?,
    );
  }

  bool get isRegularCase => type == 'CASE';
  bool get isSouvenirPackage => type == 'SOUVENIR_PACKAGE';
  bool get isCollectionPackage => type == 'COLLECTION_PACKAGE';
  bool get isStickerCapsule => type == 'STICKER_CAPSULE';
  bool get isStickerCollection => type == 'STICKER_COLLECTION';
  bool get isPinCapsule => type == 'PIN_CAPSULE';
  bool get isMusicKitBox => type == 'MUSIC_KIT_BOX';
  bool get isGraffitiBox => type == 'GRAFFITI_BOX';
  bool get isPatchPack => type == 'PATCH_PACK';
  bool get isPatchCollection => type == 'PATCH_COLLECTION';
  bool get isCharmCollection => type == 'CHARM_COLLECTION';
  bool get isXrayPackage => type == 'XRAY_PACKAGE';
  bool get isTerminal => type == 'TERMINAL';

  String get typeLabel {
    switch (type) {
      case 'CASE':
        return 'Case';
      case 'SOUVENIR_PACKAGE':
        return 'Souvenir Package';
      case 'COLLECTION_PACKAGE':
        return 'Collection Package';
      case 'STICKER_CAPSULE':
        return 'Sticker Capsule';
      case 'STICKER_COLLECTION':
        return 'Sticker Collection';
      case 'PIN_CAPSULE':
        return 'Pin Capsule';
      case 'MUSIC_KIT_BOX':
        return 'Music Kit Box';
      case 'GRAFFITI_BOX':
        return 'Graffiti Box';
      case 'PATCH_PACK':
        return 'Patch Pack';
      case 'PATCH_COLLECTION':
        return 'Patch Collection';
      case 'CHARM_COLLECTION':
        return 'Charm Collection';
      case 'XRAY_PACKAGE':
        return 'X-Ray Package';
      case 'TERMINAL':
        return 'Terminal';
      default:
        return type;
    }
  }

  String? get sourceTypeLabel {
    switch (sourceType) {
      case 'OPERATION_REWARD':
        return 'Operation Reward';
      case 'ARMORY_REWARD':
        return 'Armory Reward';
      case 'LEGACY_OPERATION':
        return 'Legacy Operation';
      case 'GENERAL':
        return 'Collection';
      default:
        return null;
    }
  }
}
