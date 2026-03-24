class SkinDto {
  final String id;
  final String name;
  final String skinImage;
  final double floatTop;
  final double floatBottom;
  final bool isSouvenir;
  final String rarity;
  final String weaponType;
  final String itemKind;
  final String itemId;
  final String? collection;

  SkinDto({
    required this.id,
    required this.name,
    required this.skinImage,
    required this.floatTop,
    required this.floatBottom,
    required this.isSouvenir,
    required this.rarity,
    required this.weaponType,
    required this.itemKind,
    required this.itemId,
    required this.collection,
  });

  factory SkinDto.fromJson(Map<String, dynamic> json) {
    return SkinDto(
      id: json['id'] as String,
      name: json['name'] as String,
      skinImage: json['skinImage'] as String,
      floatTop: (json['floatTop'] as num).toDouble(),
      floatBottom: (json['floatBottom'] as num).toDouble(),
      isSouvenir: json['isSouvenir'] as bool,
      rarity: json['rarity'] as String,
      weaponType: json['weaponType'] as String,
      itemKind: json['itemKind'] as String,
      itemId: json['itemId'] as String,
      collection: json['collection'] as String?,
    );
  }

  String get itemDisplayName {
    switch (itemKind) {
      case 'WEAPON':
        return _mapWeapon(itemId);
      case 'KNIFE':
        return _mapKnife(itemId);
      case 'GLOVES':
        return _mapGloves(itemId);
      default:
        return itemId;
    }
  }

  bool get isKnife => weaponType == 'KNIFE';
  bool get isGloves => weaponType == 'GLOVES';
  bool get isSpecialItem => isKnife || isGloves;

  static String _mapWeapon(String id) {
    const map = {
      'CZ75_AUTO': 'CZ75-Auto',
      'DESERT_EAGLE': 'Desert Eagle',
      'DUAL_BERETTAS': 'Dual Berettas',
      'FIVE_SEVEN': 'Five-SeveN',
      'GLOCK_18': 'Glock-18',
      'P2000': 'P2000',
      'P250': 'P250',
      'R8_REVOLVER': 'R8 Revolver',
      'TEC_9': 'Tec-9',
      'USP_S': 'USP-S',
      'MAC_10': 'MAC-10',
      'MP5_SD': 'MP5-SD',
      'MP7': 'MP7',
      'MP9': 'MP9',
      'PP_BIZON': 'PP-Bizon',
      'P90': 'P90',
      'UMP_45': 'UMP-45',
      'MAG_7': 'MAG-7',
      'NOVA': 'Nova',
      'SAWED_OFF': 'Sawed-Off',
      'XM1014': 'XM1014',
      'M249': 'M249',
      'NEGEV': 'Negev',
      'FAMAS': 'FAMAS',
      'GALIL_AR': 'Galil AR',
      'M4A4': 'M4A4',
      'M4A1_S': 'M4A1-S',
      'AK_47': 'AK-47',
      'AUG': 'AUG',
      'SG_553': 'SG 553',
      'SSG_08': 'SSG 08',
      'AWP': 'AWP',
      'SCAR_20': 'SCAR-20',
      'G3SG1': 'G3SG1',
      'ZEUS_X27': 'Zeus x27',
    };
    return map[id] ?? id;
  }

  static String _mapKnife(String id) {
    const map = {
      'BAYONET': 'Bayonet',
      'BUTTERFLY': 'Butterfly Knife',
      'FALCHION': 'Falchion Knife',
      'FLIP': 'Flip Knife',
      'GUT': 'Gut Knife',
      'HUNTSMAN': 'Huntsman Knife',
      'KARAMBIT': 'Karambit',
      'M9_BAYONET': 'M9 Bayonet',
      'SHADOW_DAGGERS': 'Shadow Daggers',
      'NAVAJA': 'Navaja Knife',
      'STILETTO': 'Stiletto Knife',
      'TALON': 'Talon Knife',
      'URSUS': 'Ursus Knife',
      'BOWIE': 'Bowie Knife',
      'SKELETON': 'Skeleton Knife',
      'PARACORD': 'Paracord Knife',
      'SURVIVAL': 'Survival Knife',
      'NOMAD': 'Nomad Knife',
      'CLASSIC': 'Classic Knife',
      'KUKRI': 'Kukri Knife',
    };
    return map[id] ?? id;
  }

  static String _mapGloves(String id) {
    const map = {
      'BLOODHOUND': 'Bloodhound Gloves',
      'BROKEN_FANG': 'Broken Fang Gloves',
      'DRIVER': 'Driver Gloves',
      'HAND_WRAPS': 'Hand Wraps',
      'HYDRA': 'Hydra Gloves',
      'MOTO': 'Moto Gloves',
      'SPECIALIST': 'Specialist Gloves',
      'SPORT': 'Sport Gloves',
    };
    return map[id] ?? id;
  }
}