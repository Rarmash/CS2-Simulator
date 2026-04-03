import 'dart:io';

const baseUrl =
    'https://raw.githubusercontent.com/ByMykel/CSGO-API/main/public/api/en';
const cratesUrl = '$baseUrl/crates.json';
const skinsUrl = '$baseUrl/skins.json';
const collectionsUrl = '$baseUrl/collections.json';
const stickersUrl = '$baseUrl/stickers.json';
const musicKitsUrl = '$baseUrl/music_kits.json';
const agentsUrl = '$baseUrl/agents.json';
const graffitiUrl = '$baseUrl/graffiti.json';
const patchesUrl = '$baseUrl/patches.json';

const timeoutSeconds = 30;

final outRoot = Directory.current;
final assetsDir = Directory('${outRoot.path}/assets');
final dataDir = Directory('${assetsDir.path}/data');
final casesDir = Directory('${assetsDir.path}/cases');
final skinsDir = Directory('${assetsDir.path}/skins');
final stickersDir = Directory('${assetsDir.path}/stickers');
final pinsDir = Directory('${assetsDir.path}/pins');
final musicKitsDir = Directory('${assetsDir.path}/music_kits');
final agentsDir = Directory('${assetsDir.path}/agents');
final graffitiDir = Directory('${assetsDir.path}/graffiti');
final patchesDir = Directory('${assetsDir.path}/patches');
final rewardCollectionsDir = Directory('${assetsDir.path}/reward_collections');
final operationCollectionsDir = Directory(
  '${assetsDir.path}/operation_collections',
);
final agentCollectionsDir = Directory('${assetsDir.path}/agent_collections');
final tournamentLogosDir = Directory('${assetsDir.path}/tournament_logos');

final rewardOverridesPath = File(
  '${outRoot.path}/reward_collection_overrides.json',
);
final operationOverridesPath = File(
  '${outRoot.path}/operation_collection_overrides.json',
);

const rarityMap = <String, String>{
  'Consumer Grade': 'CONSUMER',
  'Industrial Grade': 'INDUSTRIAL',
  'Mil-Spec Grade': 'MIL_SPEC',
  'Restricted': 'RESTRICTED',
  'Classified': 'CLASSIFIED',
  'Covert': 'COVERT',
  'Contraband': 'CONTRABAND',
  'Extraordinary': 'EXTRAORDINARY',
};

const stickerRarityMap = <String, String>{
  'High Grade': 'HIGH_GRADE',
  'Remarkable': 'REMARKABLE',
  'Exotic': 'EXOTIC',
  'Extraordinary': 'EXTRAORDINARY',
  'Contraband': 'CONTRABAND',
  'Default': 'DEFAULT',
};

const pinRarityMap = <String, String>{
  'High Grade': 'HIGH_GRADE',
  'Remarkable': 'REMARKABLE',
  'Exotic': 'EXOTIC',
  'Extraordinary': 'EXTRAORDINARY',
  'Default': 'DEFAULT',
};

const musicKitRarityMap = <String, String>{
  'High Grade': 'HIGH_GRADE',
  'Default': 'DEFAULT',
};

const agentRarityMap = <String, String>{
  'Distinguished': 'DISTINGUISHED',
  'Exceptional': 'EXCEPTIONAL',
  'Superior': 'SUPERIOR',
  'Master': 'MASTER',
};

const graffitiRarityMap = <String, String>{
  'Base Grade': 'BASE_GRADE',
  'High Grade': 'HIGH_GRADE',
  'Remarkable': 'REMARKABLE',
  'Exotic': 'EXOTIC',
};

const patchRarityMap = <String, String>{
  'High Grade': 'HIGH_GRADE',
  'Remarkable': 'REMARKABLE',
  'Exotic': 'EXOTIC',
};

const agentCollectionSourceOverrides = <String, Map<String, String>>{
  'Shattered Web Agents': {
    'operationId': 'SHATTERED_WEB',
    'operationName': 'Operation Shattered Web',
    'releaseDate': '2019-11-18',
  },
  'Broken Fang Agents': {
    'operationId': 'BROKEN_FANG',
    'operationName': 'Operation Broken Fang',
    'releaseDate': '2020-12-03',
  },
  'Operation Riptide Agents': {
    'operationId': 'RIPTIDE',
    'operationName': 'Operation Riptide',
    'releaseDate': '2021-09-21',
  },
};

const patchCollectionSourceOverrides = <String, Map<String, String>>{
  'Operation Riptide Patch Collection': {
    'sourceType': 'OPERATION_REWARD',
    'sourceId': 'RIPTIDE',
    'sourceName': 'Operation Riptide',
    'releaseDate': '2021-09-21',
  },
  'Metal Skill Group Patch Collection': {
    'sourceType': 'GENERAL',
    'sourceId': 'METAL_SKILL_GROUP',
    'sourceName': 'Metal Skill Group',
    'releaseDate': '2020-02-24',
  },
};

const stickerCollectionSourceOverrides = <String, Map<String, String>>{
  'Shattered Web Sticker Collection': {
    'sourceType': 'LEGACY_OPERATION',
    'sourceId': 'SHATTERED_WEB',
    'sourceName': 'Operation Shattered Web',
    'releaseDate': '2019-11-18',
  },
  'Broken Fang Sticker Collection': {
    'sourceType': 'OPERATION_REWARD',
    'sourceId': 'BROKEN_FANG',
    'sourceName': 'Operation Broken Fang',
    'releaseDate': '2020-12-03',
  },
  'Operation Riptide Sticker Collection': {
    'sourceType': 'OPERATION_REWARD',
    'sourceId': 'RIPTIDE',
    'sourceName': 'Operation Riptide',
    'releaseDate': '2021-09-21',
  },
  'Riptide Surf Shop Sticker Collection': {
    'sourceType': 'OPERATION_REWARD',
    'sourceId': 'RIPTIDE',
    'sourceName': 'Operation Riptide',
    'releaseDate': '2021-09-21',
  },
  'Recoil Sticker Collection': {
    'sourceType': 'OPERATION_REWARD',
    'sourceId': 'BROKEN_FANG',
    'sourceName': 'Operation Broken Fang',
    'releaseDate': '2020-12-03',
  },
  'Character Craft Sticker Pack': {
    'sourceType': 'ARMORY_REWARD',
    'sourceId': 'ARMORY',
    'sourceName': 'The Armory',
    'releaseDate': '2024-10-02',
  },
  'Elemental Craft Sticker Pack': {
    'sourceType': 'ARMORY_REWARD',
    'sourceId': 'ARMORY',
    'sourceName': 'The Armory',
    'releaseDate': '2024-10-02',
  },
  '2025 Community Sticker Collection': {
    'sourceType': 'ARMORY_REWARD',
    'sourceId': 'ARMORY',
    'sourceName': 'The Armory',
    'releaseDate': '2025-10-02',
  },
  'Sugarface 2 Sticker Collection': {
    'sourceType': 'ARMORY_REWARD',
    'sourceId': 'ARMORY',
    'sourceName': 'The Armory',
    'releaseDate': '2025-10-02',
  },
};

const weaponTypeMap = <String, String>{
  'Pistols': 'PISTOL',
  'SMGs': 'SMG',
  'Sniper Rifles': 'SNIPER_RIFLE',
  'Rifles': 'RIFLE',
  'Knife': 'KNIFE',
  'Knives': 'KNIFE',
  'Shotguns': 'SHOTGUN',
  'Machineguns': 'MACHINE_GUN',
  'Machine Guns': 'MACHINE_GUN',
  'Gloves': 'GLOVES',
  'Equipment': 'EQUIPMENT',
};

const weaponIdMap = <String, String>{
  'CZ75-Auto': 'CZ75_AUTO',
  'Desert Eagle': 'DESERT_EAGLE',
  'Dual Berettas': 'DUAL_BERETTAS',
  'Five-SeveN': 'FIVE_SEVEN',
  'Glock-18': 'GLOCK_18',
  'P2000': 'P2000',
  'P250': 'P250',
  'R8 Revolver': 'R8_REVOLVER',
  'Tec-9': 'TEC_9',
  'USP-S': 'USP_S',
  'MAC-10': 'MAC_10',
  'MP5-SD': 'MP5_SD',
  'MP7': 'MP7',
  'MP9': 'MP9',
  'PP-Bizon': 'PP_BIZON',
  'P90': 'P90',
  'UMP-45': 'UMP_45',
  'MAG-7': 'MAG_7',
  'Nova': 'NOVA',
  'Sawed-Off': 'SAWED_OFF',
  'XM1014': 'XM1014',
  'M249': 'M249',
  'Negev': 'NEGEV',
  'FAMAS': 'FAMAS',
  'Galil AR': 'GALIL_AR',
  'M4A4': 'M4A4',
  'M4A1-S': 'M4A1_S',
  'AK-47': 'AK_47',
  'AUG': 'AUG',
  'SG 553': 'SG_553',
  'SSG 08': 'SSG_08',
  'AWP': 'AWP',
  'SCAR-20': 'SCAR_20',
  'G3SG1': 'G3SG1',
  'Zeus x27': 'ZEUS_X27',
};

const knifeIdMap = <String, String>{
  'Bayonet': 'BAYONET',
  'Butterfly Knife': 'BUTTERFLY',
  'Falchion Knife': 'FALCHION',
  'Flip Knife': 'FLIP',
  'Gut Knife': 'GUT',
  'Huntsman Knife': 'HUNTSMAN',
  'Karambit': 'KARAMBIT',
  'M9 Bayonet': 'M9_BAYONET',
  'Shadow Daggers': 'SHADOW_DAGGERS',
  'Navaja Knife': 'NAVAJA',
  'Stiletto Knife': 'STILETTO',
  'Talon Knife': 'TALON',
  'Ursus Knife': 'URSUS',
  'Bowie Knife': 'BOWIE',
  'Skeleton Knife': 'SKELETON',
  'Paracord Knife': 'PARACORD',
  'Survival Knife': 'SURVIVAL',
  'Nomad Knife': 'NOMAD',
  'Classic Knife': 'CLASSIC',
  'Kukri Knife': 'KUKRI',
};

const glovesIdMap = <String, String>{
  'Bloodhound Gloves': 'BLOODHOUND',
  'Broken Fang Gloves': 'BROKEN_FANG',
  'Driver Gloves': 'DRIVER',
  'Hand Wraps': 'HAND_WRAPS',
  'Hydra Gloves': 'HYDRA',
  'Moto Gloves': 'MOTO',
  'Specialist Gloves': 'SPECIALIST',
  'Sport Gloves': 'SPORT',
};

const containerTypeOverrides = <String, String>{
  'Anubis Collection Package': 'COLLECTION_PACKAGE',
  'The X-Ray Collection': 'XRAY_PACKAGE',
  'X-Ray P250 Package': 'XRAY_PACKAGE',
};

const legacyCaseOverrides = <Map<String, Object>>[
  {
    'name': 'Huntsman Weapon Case (Legacy)',
    'baseCaseName': 'Huntsman Weapon Case',
    'type': 'CASE',
    'releaseDate': '2014-05-01',
    'copyImageFromBase': true,
    'copySpecialItemsFromBase': true,
    'contents': [
      'Tec-9 | Isaac',
      'SSG 08 | Slashed',
      'Dual Berettas | Retribution',
      'Galil AR | Kami',
      'P90 | Desert Warfare',
      'CZ75-Auto | Poison Dart',
      'AUG | Torque',
      'PP-Bizon | Antique',
      'MAC-10 | Curse',
      'XM1014 | Heaven Guard',
      'M4A1-S | Atomic Alloy',
      'SCAR-20 | Cyrex',
      'USP-S | Orion',
      'AK-47 | Vulcan',
      'M4A4 | Howl',
    ],
  },
];

const collectionNameAliases = <String, String>{};

const defaultRewardSourceOverrides = <String, Map<String, Object>>{
  'The Ancient Collection': {
    'sourceType': 'OPERATION',
    'sourceId': 'BROKEN_FANG',
    'currency': 'STARS',
    'cost': 4,
    'releaseDate': '2020-12-03',
  },
  'The Control Collection': {
    'sourceType': 'OPERATION',
    'sourceId': 'BROKEN_FANG',
    'currency': 'STARS',
    'cost': 4,
    'releaseDate': '2020-12-03',
  },
  'The Havoc Collection': {
    'sourceType': 'OPERATION',
    'sourceId': 'BROKEN_FANG',
    'currency': 'STARS',
    'cost': 4,
    'releaseDate': '2020-12-03',
  },
  'The 2021 Dust 2 Collection': {
    'sourceType': 'OPERATION',
    'sourceId': 'RIPTIDE',
    'currency': 'STARS',
    'cost': 4,
    'releaseDate': '2021-09-21',
  },
  'The 2021 Mirage Collection': {
    'sourceType': 'OPERATION',
    'sourceId': 'RIPTIDE',
    'currency': 'STARS',
    'cost': 4,
    'releaseDate': '2021-09-21',
  },
  'The 2021 Train Collection': {
    'sourceType': 'OPERATION',
    'sourceId': 'RIPTIDE',
    'currency': 'STARS',
    'cost': 4,
    'releaseDate': '2021-09-21',
  },
  'The 2021 Vertigo Collection': {
    'sourceType': 'OPERATION',
    'sourceId': 'RIPTIDE',
    'currency': 'STARS',
    'cost': 4,
    'releaseDate': '2021-09-21',
  },
  'The Overpass 2024 Collection': {
    'sourceType': 'ARMORY',
    'sourceId': 'ARMORY',
    'currency': 'CREDITS',
    'cost': 4,
    'releaseDate': '2024-10-02',
  },
  'The Graphic Design Collection': {
    'sourceType': 'ARMORY',
    'sourceId': 'ARMORY',
    'currency': 'CREDITS',
    'cost': 4,
    'releaseDate': '2024-10-02',
  },
  'The Sport & Field Collection': {
    'sourceType': 'ARMORY',
    'sourceId': 'ARMORY',
    'currency': 'CREDITS',
    'cost': 4,
    'releaseDate': '2024-10-02',
  },
  'The Train 2025 Collection': {
    'sourceType': 'ARMORY',
    'sourceId': 'ARMORY',
    'currency': 'CREDITS',
    'cost': 4,
    'releaseDate': '2025-03-31',
  },
};

const defaultOperationCollectionOverrides = <Map<String, String>>[
  {
    'name': 'The Aztec Collection',
    'operationId': 'PAYBACK',
    'operationName': 'Operation Payback',
    'releaseDate': '2013-04-25',
  },
  {
    'name': 'The Assault Collection',
    'operationId': 'PAYBACK',
    'operationName': 'Operation Payback',
    'releaseDate': '2013-04-25',
  },
  {
    'name': 'The Office Collection',
    'operationId': 'PAYBACK',
    'operationName': 'Operation Payback',
    'releaseDate': '2013-04-25',
  },
  {
    'name': 'The Nuke Collection',
    'operationId': 'PAYBACK',
    'operationName': 'Operation Payback',
    'releaseDate': '2013-04-25',
  },
  {
    'name': 'The Vertigo Collection',
    'operationId': 'PAYBACK',
    'operationName': 'Operation Payback',
    'releaseDate': '2013-04-25',
  },
  {
    'name': 'The Inferno Collection',
    'operationId': 'PAYBACK',
    'operationName': 'Operation Payback',
    'releaseDate': '2013-04-25',
  },
  {
    'name': 'The Militia Collection',
    'operationId': 'PAYBACK',
    'operationName': 'Operation Payback',
    'releaseDate': '2013-04-25',
  },
  {
    'name': 'Alpha Collection',
    'operationId': 'BRAVO',
    'operationName': 'Operation Bravo',
    'releaseDate': '2013-09-19',
  },
  {
    'name': 'The Italy Collection',
    'operationId': 'BRAVO',
    'operationName': 'Operation Bravo',
    'releaseDate': '2013-09-19',
  },
  {
    'name': 'The Dust 2 Collection',
    'operationId': 'BRAVO',
    'operationName': 'Operation Bravo',
    'releaseDate': '2013-09-19',
  },
  {
    'name': 'The Dust Collection',
    'operationId': 'BRAVO',
    'operationName': 'Operation Bravo',
    'releaseDate': '2013-09-19',
  },
  {
    'name': 'The Lake Collection',
    'operationId': 'BRAVO',
    'operationName': 'Operation Bravo',
    'releaseDate': '2013-09-19',
  },
  {
    'name': 'The Safehouse Collection',
    'operationId': 'BRAVO',
    'operationName': 'Operation Bravo',
    'releaseDate': '2013-09-19',
  },
  {
    'name': 'The Mirage Collection',
    'operationId': 'BRAVO',
    'operationName': 'Operation Bravo',
    'releaseDate': '2013-09-19',
  },
  {
    'name': 'The Train Collection',
    'operationId': 'BRAVO',
    'operationName': 'Operation Bravo',
    'releaseDate': '2013-09-19',
  },
  {
    'name': 'The Bank Collection',
    'operationId': 'PHOENIX',
    'operationName': 'Operation Phoenix',
    'releaseDate': '2014-02-20',
  },
  {
    'name': 'The Baggage Collection',
    'operationId': 'BREAKOUT',
    'operationName': 'Operation Breakout',
    'releaseDate': '2014-07-01',
  },
  {
    'name': 'The Cache Collection',
    'operationId': 'BREAKOUT',
    'operationName': 'Operation Breakout',
    'releaseDate': '2014-07-01',
  },
  {
    'name': 'The Overpass Collection',
    'operationId': 'BREAKOUT',
    'operationName': 'Operation Breakout',
    'releaseDate': '2014-07-01',
  },
  {
    'name': 'The Cobblestone Collection',
    'operationId': 'BREAKOUT',
    'operationName': 'Operation Breakout',
    'releaseDate': '2014-07-01',
  },
  {
    'name': 'The Chop Shop Collection',
    'operationId': 'BLOODHOUND',
    'operationName': 'Operation Bloodhound',
    'releaseDate': '2015-05-26',
  },
  {
    'name': 'The Rising Sun Collection',
    'operationId': 'BLOODHOUND',
    'operationName': 'Operation Bloodhound',
    'releaseDate': '2015-05-26',
  },
  {
    'name': 'The Gods and Monsters Collection',
    'operationId': 'BLOODHOUND',
    'operationName': 'Operation Bloodhound',
    'releaseDate': '2015-05-26',
  },
  {
    'name': 'The Norse Collection',
    'operationId': 'SHATTERED_WEB',
    'operationName': 'Operation Shattered Web',
    'releaseDate': '2019-11-18',
  },
  {
    'name': 'The St. Marc Collection',
    'operationId': 'SHATTERED_WEB',
    'operationName': 'Operation Shattered Web',
    'releaseDate': '2019-11-18',
  },
  {
    'name': 'The Canals Collection',
    'operationId': 'SHATTERED_WEB',
    'operationName': 'Operation Shattered Web',
    'releaseDate': '2019-11-18',
  },
];

const mapSuffixes = <String>[
  'Dust 2',
  'Dust II',
  'Train',
  'Inferno',
  'Mirage',
  'Nuke',
  'Overpass',
  'Ancient',
  'Anubis',
  'Vertigo',
  'Cobblestone',
  'Cache',
  'Canals',
  'St. Marc',
  'Safehouse',
  'Lake',
  'Italy',
  'Office',
  'Assault',
  'Militia',
  'Baggage',
  'Bank',
  'Aztec',
  'Chop Shop',
  'Gods and Monsters',
  'Rising Sun',
  'Control',
  'Havoc',
];

const tournamentNameAliases = <String, String>{
  'Antwerp 2022': 'PGL Antwerp 2022',
  'Stockholm 2021': 'PGL Stockholm 2021',
  'Rio 2022': 'IEM Rio 2022',
  'Paris 2023': 'BLAST.tv Paris 2023',
  'Copenhagen 2024': 'PGL Copenhagen 2024',
  'Shanghai 2024': 'Perfect World Shanghai 2024',
  'Austin 2025': 'BLAST.tv Austin 2025',
  'Budapest 2025': 'StarLadder Budapest 2025',
  'Katowice 2019': 'IEM Katowice 2019',
  'Krakow 2017': 'PGL Kraków 2017',
  'London 2018': 'FACEIT London 2018',
  'Boston 2018': 'ELEAGUE Boston 2018',
  'Atlanta 2017': 'ELEAGUE Atlanta 2017',
  'Berlin 2019': 'StarLadder Berlin 2019',
  'DreamHack 2013': 'DreamHack Winter 2013',
  'DreamHack 2014': 'DreamHack Winter 2014',
  'Cologne 2016': 'ESL One Cologne 2016',
  'EMS One': 'EMS One Katowice 2014',
};

const tournamentStartDates = <String, String>{
  'Antwerp 2022': '2022-05-09',
  'Rio 2022': '2022-10-31',
  'Paris 2023': '2023-05-08',
  'Copenhagen 2024': '2024-03-17',
  'Shanghai 2024': '2024-11-30',
  'Austin 2025': '2025-06-03',
  'Budapest 2025': '2025-11-24',
};

const tournamentContainerStartDates = <String, String>{
  'DreamHack 2013': '2013-11-28',
  '2020 RMR': '2021-01-27',
  'EMS One 2014': '2014-03-13',
  'EMS Katowice 2014': '2014-03-13',
  'Cologne 2015': '2015-08-14',
  'Cluj-Napoca 2015': '2015-10-28',
  'ESL One Cologne 2014': '2014-08-14',
  'DreamHack 2014': '2014-11-27',
  'ESL One Katowice 2015': '2015-03-12',
  'ESL One Cologne 2015': '2015-08-14',
  'DreamHack Cluj-Napoca 2015': '2015-10-28',
  'MLG Columbus 2016': '2016-03-29',
  'Cologne 2016': '2016-07-08',
  'Atlanta 2017': '2017-01-22',
  'Krakow 2017': '2017-07-16',
  'Boston 2018': '2018-01-12',
  'London 2018': '2018-09-05',
  'Katowice 2019': '2019-02-13',
  'Berlin 2019': '2019-08-23',
  'Stockholm 2021': '2021-10-26',
  'Antwerp 2022': '2022-05-09',
  'Rio 2022': '2022-10-31',
  'Paris 2023': '2023-05-08',
  'Copenhagen 2024': '2024-03-17',
  'Shanghai 2024': '2024-11-30',
  'Austin 2025': '2025-06-03',
  'Budapest 2025': '2025-11-24',
};

const containerReleaseDateOverrides = <String, String>{
  'CS:GO Weapon Case': '2013-08-14',
  'CS:GO Weapon Case 2': '2013-11-08',
  'CS:GO Weapon Case 3': '2014-02-12',
  'Operation Bravo Case': '2013-09-19',
  'Winter Offensive Weapon Case': '2013-12-18',
  'Operation Phoenix Weapon Case': '2014-02-20',
  'Huntsman Weapon Case (Legacy)': '2014-05-01',
  'Huntsman Weapon Case': '2014-05-01',
  'Operation Breakout Weapon Case': '2014-07-01',
  'eSports 2013 Case': '2013-08-14',
  'eSports 2013 Winter Case': '2013-12-18',
  'eSports 2014 Summer Case': '2014-07-10',
  'Operation Vanguard Weapon Case': '2014-11-11',
  'Chroma Case': '2015-01-08',
  'Chroma 2 Case': '2015-04-15',
  'Falchion Case': '2015-05-26',
  'Shadow Case': '2015-09-17',
  'Revolver Case': '2015-12-08',
  'Operation Wildfire Case': '2016-02-17',
  'Chroma 3 Case': '2016-04-27',
  'Gamma Case': '2016-06-15',
  'Gamma 2 Case': '2016-08-18',
  'Glove Case': '2016-11-28',
  'Spectrum Case': '2017-03-15',
  'Operation Hydra Case': '2017-05-23',
  'Spectrum 2 Case': '2017-09-14',
  'Clutch Case': '2018-02-14',
  'Horizon Case': '2018-08-02',
  'Danger Zone Case': '2018-12-06',
  'Prisma Case': '2019-03-13',
  'Shattered Web Case': '2019-11-18',
  'CS20 Case': '2019-10-18',
  'Prisma 2 Case': '2020-03-31',
  'Fracture Case': '2020-08-06',
  'Operation Broken Fang Case': '2020-12-03',
  'Snakebite Case': '2021-05-03',
  'Operation Riptide Case': '2021-09-22',
  'Dreams & Nightmares Case': '2022-01-20',
  'Recoil Case': '2022-07-01',
  'Revolution Case': '2023-02-09',
  'Kilowatt Case': '2024-02-06',
  'Gallery Case': '2024-10-02',
  'Fever Case': '2025-03-31',
  'Sticker Capsule': '2014-01-29',
  'Sticker Capsule 2': '2014-01-29',
  'Community Sticker Capsule 1': '2014-06-11',
  'Enfu Sticker Capsule': '2015-04-22',
  'Pinups Capsule': '2015-12-01',
  'Slid3 Capsule': '2015-12-01',
  'Team Roles Capsule': '2015-12-01',
  'Bestiary Capsule': '2016-08-16',
  'Sugarface Capsule': '2016-08-16',
  'Perfect World Sticker Capsule 1': '2017-09-15',
  'Perfect World Sticker Capsule 2': '2017-09-15',
  'Community Capsule 2018': '2017-12-11',
  'Skill Groups Capsule': '2018-11-15',
  'Feral Predators Capsule': '2019-04-15',
  'Chicken Capsule': '2019-06-10',
  'CS20 Sticker Capsule': '2019-10-16',
  'Halo Capsule': '2019-11-25',
  'Half-Life: Alyx Sticker Capsule': '2020-03-23',
  'Warhammer 40,000 Sticker Capsule': '2020-05-28',
  'Poorly Drawn Capsule': '2021-02-14',
  '2021 Community Sticker Capsule': '2021-09-02',
  'Battlefield 2042 Sticker Capsule': '2021-10-07',
  'The Boardroom Sticker Capsule': '2022-02-20',
  '10 Year Birthday Sticker Capsule': '2022-06-15',
  'Espionage Sticker Capsule': '2023-01-05',
  'Ambush Sticker Capsule': '2024-01-25',
  'Warhammer 40,000 Adeptus Astartes Sticker Capsule': '2025-05-22',
  'Warhammer 40,000 Imperium Sticker Capsule': '2025-05-22',
  'Warhammer 40,000 Traitor Astartes Sticker Capsule': '2025-05-22',
  'Warhammer 40,000 Xenos Sticker Capsule': '2025-05-22',
  'Collectible Pins Capsule Series 1': '2016-06-01',
  'Collectible Pins Capsule Series 2': '2016-09-28',
  'Collectible Pins Capsule Series 3': '2018-03-01',
  'Half-Life: Alyx Collectible Pins Capsule': '2020-03-23',
  'StatTrak™ Radicals Box': '2016-08-16',
  'Community Graffiti Box 1': '2016-10-06',
  'CS:GO Graffiti Box': '2016-10-06',
  'Perfect World Graffiti Box': '2017-09-14',
  'CS:GO Patch Pack': '2020-02-24',
  'Metal Skill Group Patch Collection': '2020-02-24',
  'Half-Life: Alyx Patch Pack': '2020-03-23',
  'Operation Riptide Patch Collection': '2021-09-21',
  'Stockholm 2021 Legends Patch Pack': '2021-10-26',
  'Stockholm 2021 Challengers Patch Pack': '2021-10-26',
  'Stockholm 2021 Contenders Patch Pack': '2021-10-26',
  'Masterminds Music Kit Box': '2020-04-22',
  'StatTrak™ Masterminds Music Kit Box': '2020-04-22',
  'Tacticians Music Kit Box': '2021-07-20',
  'StatTrak™ Tacticians Music Kit Box': '2021-07-20',
  'Initiators Music Kit Box': '2022-08-15',
  'StatTrak™ Initiators Music Kit Box': '2022-08-15',
  'NIGHTMODE Music Kit Box': '2024-01-24',
  'StatTrak™ NIGHTMODE Music Kit Box': '2024-01-24',
  'Masterminds 2 Music Kit Box': '2024-08-15',
  'StatTrak™ Masterminds 2 Music Kit Box': '2024-08-15',
  'Deluge Music Kit Box': '2025-06-27',
  'StatTrak™ Deluge Music Kit Box': '2025-06-27',
  'The X-Ray Collection': '2019-09-30',
  'X-Ray P250 Package': '2019-09-30',
  'Anubis Collection Package': '2023-03-22',
  'Sealed Genesis Terminal': '2025-09-16',
  'Sealed Dead Hand Terminal': '2026-03-11',
};
