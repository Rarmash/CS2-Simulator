from __future__ import annotations

import json
import re
import sys
import time
import zlib
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

import requests

BASE_URL = "https://raw.githubusercontent.com/ByMykel/CSGO-API/main/public/api/en"
CRATES_URL = f"{BASE_URL}/crates.json"
SKINS_URL = f"{BASE_URL}/skins.json"
COLLECTIONS_URL = f"{BASE_URL}/collections.json"
STICKERS_URL = f"{BASE_URL}/stickers.json"
MUSIC_KITS_URL = f"{BASE_URL}/music_kits.json"

OUT_ROOT = Path(".")
ASSETS_DIR = OUT_ROOT / "assets"
DATA_DIR = ASSETS_DIR / "data"
CASES_DIR = ASSETS_DIR / "cases"
SKINS_DIR = ASSETS_DIR / "skins"
STICKERS_DIR = ASSETS_DIR / "stickers"
PINS_DIR = ASSETS_DIR / "pins"
MUSIC_KITS_DIR = ASSETS_DIR / "music_kits"
REWARD_COLLECTIONS_DIR = ASSETS_DIR / "reward_collections"
OPERATION_COLLECTIONS_DIR = ASSETS_DIR / "operation_collections"
TOURNAMENT_LOGOS_DIR = ASSETS_DIR / "tournament_logos"

TIMEOUT = 30

RARITY_MAP = {
    "Consumer Grade": "CONSUMER",
    "Industrial Grade": "INDUSTRIAL",
    "Mil-Spec Grade": "MIL_SPEC",
    "Restricted": "RESTRICTED",
    "Classified": "CLASSIFIED",
    "Covert": "COVERT",
    "Contraband": "CONTRABAND",
    "Extraordinary": "EXTRAORDINARY",
}

STICKER_RARITY_MAP = {
    "High Grade": "HIGH_GRADE",
    "Remarkable": "REMARKABLE",
    "Exotic": "EXOTIC",
    "Extraordinary": "EXTRAORDINARY",
    "Contraband": "CONTRABAND",
    "Default": "DEFAULT",
}

PIN_RARITY_MAP = {
    "High Grade": "HIGH_GRADE",
    "Remarkable": "REMARKABLE",
    "Exotic": "EXOTIC",
    "Extraordinary": "EXTRAORDINARY",
    "Default": "DEFAULT",
}

MUSIC_KIT_RARITY_MAP = {
    "High Grade": "HIGH_GRADE",
    "Default": "DEFAULT",
}

STICKER_COLLECTION_SOURCE_OVERRIDES: dict[str, dict[str, str]] = {
    "Shattered Web Sticker Collection": {
        "sourceType": "LEGACY_OPERATION",
        "sourceId": "SHATTERED_WEB",
        "sourceName": "Operation Shattered Web",
        "releaseDate": "2019-11-18",
    },
    "Broken Fang Sticker Collection": {
        "sourceType": "OPERATION_REWARD",
        "sourceId": "BROKEN_FANG",
        "sourceName": "Operation Broken Fang",
        "releaseDate": "2020-12-03",
    },
    "Operation Riptide Sticker Collection": {
        "sourceType": "OPERATION_REWARD",
        "sourceId": "RIPTIDE",
        "sourceName": "Operation Riptide",
        "releaseDate": "2021-09-21",
    },
    "Riptide Surf Shop Sticker Collection": {
        "sourceType": "OPERATION_REWARD",
        "sourceId": "RIPTIDE",
        "sourceName": "Operation Riptide",
        "releaseDate": "2021-09-21",
    },
    "Recoil Sticker Collection": {
        "sourceType": "OPERATION_REWARD",
        "sourceId": "BROKEN_FANG",
        "sourceName": "Operation Broken Fang",
        "releaseDate": "2020-12-03",
    },
    "Character Craft Sticker Pack": {
        "sourceType": "ARMORY_REWARD",
        "sourceId": "ARMORY",
        "sourceName": "The Armory",
        "releaseDate": "2024-10-02",
    },
    "Elemental Craft Sticker Pack": {
        "sourceType": "ARMORY_REWARD",
        "sourceId": "ARMORY",
        "sourceName": "The Armory",
        "releaseDate": "2024-10-02",
    },
    "2025 Community Sticker Collection": {
        "sourceType": "ARMORY_REWARD",
        "sourceId": "ARMORY",
        "sourceName": "The Armory",
        "releaseDate": "2025-10-02",
    },
    "Sugarface 2 Sticker Collection": {
        "sourceType": "ARMORY_REWARD",
        "sourceId": "ARMORY",
        "sourceName": "The Armory",
        "releaseDate": "2025-10-02",
    },
}

WEAPON_TYPE_MAP = {
    "Pistols": "PISTOL",
    "SMGs": "SMG",
    "Sniper Rifles": "SNIPER_RIFLE",
    "Rifles": "RIFLE",
    "Knife": "KNIFE",
    "Knives": "KNIFE",
    "Shotguns": "SHOTGUN",
    "Machineguns": "MACHINE_GUN",
    "Machine Guns": "MACHINE_GUN",
    "Gloves": "GLOVES",
    "Equipment": "EQUIPMENT",
}

WEAPON_ID_MAP = {
    "CZ75-Auto": "CZ75_AUTO",
    "Desert Eagle": "DESERT_EAGLE",
    "Dual Berettas": "DUAL_BERETTAS",
    "Five-SeveN": "FIVE_SEVEN",
    "Glock-18": "GLOCK_18",
    "P2000": "P2000",
    "P250": "P250",
    "R8 Revolver": "R8_REVOLVER",
    "Tec-9": "TEC_9",
    "USP-S": "USP_S",
    "MAC-10": "MAC_10",
    "MP5-SD": "MP5_SD",
    "MP7": "MP7",
    "MP9": "MP9",
    "PP-Bizon": "PP_BIZON",
    "P90": "P90",
    "UMP-45": "UMP_45",
    "MAG-7": "MAG_7",
    "Nova": "NOVA",
    "Sawed-Off": "SAWED_OFF",
    "XM1014": "XM1014",
    "M249": "M249",
    "Negev": "NEGEV",
    "FAMAS": "FAMAS",
    "Galil AR": "GALIL_AR",
    "M4A4": "M4A4",
    "M4A1-S": "M4A1_S",
    "AK-47": "AK_47",
    "AUG": "AUG",
    "SG 553": "SG_553",
    "SSG 08": "SSG_08",
    "AWP": "AWP",
    "SCAR-20": "SCAR_20",
    "G3SG1": "G3SG1",
    "Zeus x27": "ZEUS_X27",
}

KNIFE_ID_MAP = {
    "Bayonet": "BAYONET",
    "Butterfly Knife": "BUTTERFLY",
    "Falchion Knife": "FALCHION",
    "Flip Knife": "FLIP",
    "Gut Knife": "GUT",
    "Huntsman Knife": "HUNTSMAN",
    "Karambit": "KARAMBIT",
    "M9 Bayonet": "M9_BAYONET",
    "Shadow Daggers": "SHADOW_DAGGERS",
    "Navaja Knife": "NAVAJA",
    "Stiletto Knife": "STILETTO",
    "Talon Knife": "TALON",
    "Ursus Knife": "URSUS",
    "Bowie Knife": "BOWIE",
    "Skeleton Knife": "SKELETON",
    "Paracord Knife": "PARACORD",
    "Survival Knife": "SURVIVAL",
    "Nomad Knife": "NOMAD",
    "Classic Knife": "CLASSIC",
    "Kukri Knife": "KUKRI",
}

GLOVES_ID_MAP = {
    "Bloodhound Gloves": "BLOODHOUND",
    "Broken Fang Gloves": "BROKEN_FANG",
    "Driver Gloves": "DRIVER",
    "Hand Wraps": "HAND_WRAPS",
    "Hydra Gloves": "HYDRA",
    "Moto Gloves": "MOTO",
    "Specialist Gloves": "SPECIALIST",
    "Sport Gloves": "SPORT",
}

CONTAINER_TYPE_OVERRIDES = {
    "Anubis Collection Package": "COLLECTION_PACKAGE",
    "The X-Ray Collection": "XRAY_PACKAGE",
    "X-Ray P250 Package": "XRAY_PACKAGE",
}

LEGACY_CASE_OVERRIDES: list[dict[str, Any]] = [
    {
        "name": "Huntsman Weapon Case (Legacy)",
        "baseCaseName": "Huntsman Weapon Case",
        "type": "CASE",
        "releaseDate": "2014-05-01",
        "copyImageFromBase": True,
        "copySpecialItemsFromBase": True,
        "contents": [
            "Tec-9 | Isaac",
            "SSG 08 | Slashed",
            "Dual Berettas | Retribution",
            "Galil AR | Kami",
            "P90 | Desert Warfare",
            "CZ75-Auto | Poison Dart",
            "AUG | Torque",
            "PP-Bizon | Antique",
            "MAC-10 | Curse",
            "XM1014 | Heaven Guard",
            "M4A1-S | Atomic Alloy",
            "SCAR-20 | Cyrex",
            "USP-S | Orion",
            "AK-47 | Vulcan",
            "M4A4 | Howl",
        ],
    },
]

COLLECTION_NAME_ALIASES: dict[str, str] = {}

DEFAULT_REWARD_SOURCE_OVERRIDES: dict[str, dict[str, Any]] = {
    "The Ancient Collection": {
        "sourceType": "OPERATION",
        "sourceId": "BROKEN_FANG",
        "currency": "STARS",
        "cost": 4,
        "releaseDate": "2020-12-03",
    },
    "The Control Collection": {
        "sourceType": "OPERATION",
        "sourceId": "BROKEN_FANG",
        "currency": "STARS",
        "cost": 4,
        "releaseDate": "2020-12-03",
    },
    "The Havoc Collection": {
        "sourceType": "OPERATION",
        "sourceId": "BROKEN_FANG",
        "currency": "STARS",
        "cost": 4,
        "releaseDate": "2020-12-03",
    },
    "The 2021 Dust 2 Collection": {
        "sourceType": "OPERATION",
        "sourceId": "RIPTIDE",
        "currency": "STARS",
        "cost": 4,
        "releaseDate": "2021-09-21",
    },
    "The 2021 Mirage Collection": {
        "sourceType": "OPERATION",
        "sourceId": "RIPTIDE",
        "currency": "STARS",
        "cost": 4,
        "releaseDate": "2021-09-21",
    },
    "The 2021 Train Collection": {
        "sourceType": "OPERATION",
        "sourceId": "RIPTIDE",
        "currency": "STARS",
        "cost": 4,
        "releaseDate": "2021-09-21",
    },
    "The 2021 Vertigo Collection": {
        "sourceType": "OPERATION",
        "sourceId": "RIPTIDE",
        "currency": "STARS",
        "cost": 4,
        "releaseDate": "2021-09-21",
    },
    "The Overpass 2024 Collection": {
        "sourceType": "ARMORY",
        "sourceId": "ARMORY",
        "currency": "CREDITS",
        "cost": 4,
        "releaseDate": "2024-10-02",
    },
    "The Graphic Design Collection": {
        "sourceType": "ARMORY",
        "sourceId": "ARMORY",
        "currency": "CREDITS",
        "cost": 4,
        "releaseDate": "2024-10-02",
    },
    "The Sport & Field Collection": {
        "sourceType": "ARMORY",
        "sourceId": "ARMORY",
        "currency": "CREDITS",
        "cost": 4,
        "releaseDate": "2024-10-02",
    },
    "The Train 2025 Collection": {
        "sourceType": "ARMORY",
        "sourceId": "ARMORY",
        "currency": "CREDITS",
        "cost": 4,
        "releaseDate": "2025-03-31",
    },
}

DEFAULT_OPERATION_COLLECTION_OVERRIDES: list[dict[str, Any]] = [
    {"name": "The Aztec Collection", "operationId": "PAYBACK", "operationName": "Operation Payback", "releaseDate": "2013-04-25"},
    {"name": "The Assault Collection", "operationId": "PAYBACK", "operationName": "Operation Payback", "releaseDate": "2013-04-25"},
    {"name": "The Office Collection", "operationId": "PAYBACK", "operationName": "Operation Payback", "releaseDate": "2013-04-25"},
    {"name": "The Nuke Collection", "operationId": "PAYBACK", "operationName": "Operation Payback", "releaseDate": "2013-04-25"},
    {"name": "The Vertigo Collection", "operationId": "PAYBACK", "operationName": "Operation Payback", "releaseDate": "2013-04-25"},
    {"name": "The Inferno Collection", "operationId": "PAYBACK", "operationName": "Operation Payback", "releaseDate": "2013-04-25"},
    {"name": "The Militia Collection", "operationId": "PAYBACK", "operationName": "Operation Payback", "releaseDate": "2013-04-25"},
    {"name": "Alpha Collection", "operationId": "BRAVO", "operationName": "Operation Bravo", "releaseDate": "2013-09-19"},
    {"name": "The Italy Collection", "operationId": "BRAVO", "operationName": "Operation Bravo", "releaseDate": "2013-09-19"},
    {"name": "The Dust 2 Collection", "operationId": "BRAVO", "operationName": "Operation Bravo", "releaseDate": "2013-09-19"},
    {"name": "The Dust Collection", "operationId": "BRAVO", "operationName": "Operation Bravo", "releaseDate": "2013-09-19"},
    {"name": "The Lake Collection", "operationId": "BRAVO", "operationName": "Operation Bravo", "releaseDate": "2013-09-19"},
    {"name": "The Safehouse Collection", "operationId": "BRAVO", "operationName": "Operation Bravo", "releaseDate": "2013-09-19"},
    {"name": "The Mirage Collection", "operationId": "BRAVO", "operationName": "Operation Bravo", "releaseDate": "2013-09-19"},
    {"name": "The Train Collection", "operationId": "BRAVO", "operationName": "Operation Bravo", "releaseDate": "2013-09-19"},
    {"name": "The Bank Collection", "operationId": "PHOENIX", "operationName": "Operation Phoenix", "releaseDate": "2014-02-20"},
    {"name": "The Baggage Collection", "operationId": "BREAKOUT", "operationName": "Operation Breakout", "releaseDate": "2014-07-01"},
    {"name": "The Cache Collection", "operationId": "BREAKOUT", "operationName": "Operation Breakout", "releaseDate": "2014-07-01"},
    {"name": "The Overpass Collection", "operationId": "BREAKOUT", "operationName": "Operation Breakout", "releaseDate": "2014-07-01"},
    {"name": "The Cobblestone Collection", "operationId": "BREAKOUT", "operationName": "Operation Breakout", "releaseDate": "2014-07-01"},
    {"name": "The Chop Shop Collection", "operationId": "BLOODHOUND", "operationName": "Operation Bloodhound", "releaseDate": "2015-05-26"},
    {"name": "The Rising Sun Collection", "operationId": "BLOODHOUND", "operationName": "Operation Bloodhound", "releaseDate": "2015-05-26"},
    {"name": "The Gods and Monsters Collection", "operationId": "BLOODHOUND", "operationName": "Operation Bloodhound", "releaseDate": "2015-05-26"},
    {"name": "The Norse Collection", "operationId": "SHATTERED_WEB", "operationName": "Operation Shattered Web", "releaseDate": "2019-11-18"},
    {"name": "The St. Marc Collection", "operationId": "SHATTERED_WEB", "operationName": "Operation Shattered Web", "releaseDate": "2019-11-18"},
    {"name": "The Canals Collection", "operationId": "SHATTERED_WEB", "operationName": "Operation Shattered Web", "releaseDate": "2019-11-18"},
]

REWARD_OVERRIDES_PATH = OUT_ROOT / "reward_collection_overrides.json"
OPERATION_OVERRIDES_PATH = OUT_ROOT / "operation_collection_overrides.json"

MAP_SUFFIXES = [
    "Dust 2",
    "Dust II",
    "Train",
    "Inferno",
    "Mirage",
    "Nuke",
    "Overpass",
    "Ancient",
    "Anubis",
    "Vertigo",
    "Cobblestone",
    "Cache",
    "Canals",
    "St. Marc",
    "Safehouse",
    "Lake",
    "Italy",
    "Office",
    "Assault",
    "Militia",
    "Baggage",
    "Bank",
    "Aztec",
    "Chop Shop",
    "Gods and Monsters",
    "Rising Sun",
    "Control",
    "Havoc",
]

TOURNAMENT_NAME_ALIASES = {
    "Antwerp 2022": "PGL Antwerp 2022",
    "Stockholm 2021": "PGL Stockholm 2021",
    "Rio 2022": "IEM Rio 2022",
    "Paris 2023": "BLAST.tv Paris 2023",
    "Copenhagen 2024": "PGL Copenhagen 2024",
    "Shanghai 2024": "Perfect World Shanghai 2024",
    "Austin 2025": "BLAST.tv Austin 2025",
    "Budapest 2025": "StarLadder Budapest 2025",
    "Katowice 2019": "IEM Katowice 2019",
    "Krakow 2017": "PGL Kraków 2017",
    "London 2018": "FACEIT London 2018",
    "Boston 2018": "ELEAGUE Boston 2018",
    "Atlanta 2017": "ELEAGUE Atlanta 2017",
    "Berlin 2019": "StarLadder Berlin 2019",
    "DreamHack 2013": "DreamHack Winter 2013",
    "DreamHack 2014": "DreamHack Winter 2014",
    "Cologne 2016": "ESL One Cologne 2016",
    "EMS One": "EMS One Katowice 2014",
}

TOURNAMENT_START_DATES = {
    "Antwerp 2022": "2022-05-09",
    "Rio 2022": "2022-10-31",
    "Paris 2023": "2023-05-08",
    "Copenhagen 2024": "2024-03-17",
    "Shanghai 2024": "2024-11-30",
    "Austin 2025": "2025-06-03",
    "Budapest 2025": "2025-11-24",
}

TOURNAMENT_CONTAINER_START_DATES = {
    "DreamHack 2013": "2013-11-28",
    "2020 RMR": "2021-01-27",
    "EMS One 2014": "2014-03-13",
    "EMS Katowice 2014": "2014-03-13",
    "Cologne 2015": "2015-08-14",
    "Cluj-Napoca 2015": "2015-10-28",
    "ESL One Cologne 2014": "2014-08-14",
    "DreamHack 2014": "2014-11-27",
    "ESL One Katowice 2015": "2015-03-12",
    "ESL One Cologne 2015": "2015-08-14",
    "DreamHack Cluj-Napoca 2015": "2015-10-28",
    "MLG Columbus 2016": "2016-03-29",
    "Cologne 2016": "2016-07-08",
    "Atlanta 2017": "2017-01-22",
    "Krakow 2017": "2017-07-16",
    "Boston 2018": "2018-01-12",
    "London 2018": "2018-09-05",
    "Katowice 2019": "2019-02-13",
    "Berlin 2019": "2019-08-23",
    "Stockholm 2021": "2021-10-26",
    "Antwerp 2022": "2022-05-09",
    "Rio 2022": "2022-10-31",
    "Paris 2023": "2023-05-08",
    "Copenhagen 2024": "2024-03-17",
    "Shanghai 2024": "2024-11-30",
    "Austin 2025": "2025-06-03",
    "Budapest 2025": "2025-11-24",
}

CONTAINER_RELEASE_DATE_OVERRIDES: dict[str, str] = {
    # Cases
    "CS:GO Weapon Case": "2013-08-14",
    "CS:GO Weapon Case 2": "2013-11-08",
    "CS:GO Weapon Case 3": "2014-02-12",
    "Operation Bravo Case": "2013-09-19",
    "Winter Offensive Weapon Case": "2013-12-18",
    "Operation Phoenix Weapon Case": "2014-02-20",
    "Huntsman Weapon Case (Legacy)": "2014-05-01",
    "Huntsman Weapon Case": "2014-05-01",
    "Operation Breakout Weapon Case": "2014-07-01",
    "eSports 2013 Case": "2013-08-14",
    "eSports 2013 Winter Case": "2013-12-18",
    "eSports 2014 Summer Case": "2014-07-10",
    "Operation Vanguard Weapon Case": "2014-11-11",
    "Chroma Case": "2015-01-08",
    "Chroma 2 Case": "2015-04-15",
    "Falchion Case": "2015-05-26",
    "Shadow Case": "2015-09-17",
    "Revolver Case": "2015-12-08",
    "Operation Wildfire Case": "2016-02-17",
    "Chroma 3 Case": "2016-04-27",
    "Gamma Case": "2016-06-15",
    "Gamma 2 Case": "2016-08-18",
    "Glove Case": "2016-11-28",
    "Spectrum Case": "2017-03-15",
    "Operation Hydra Case": "2017-05-23",
    "Spectrum 2 Case": "2017-09-14",
    "Clutch Case": "2018-02-14",
    "Horizon Case": "2018-08-02",
    "Danger Zone Case": "2018-12-06",
    "Prisma Case": "2019-03-13",
    "Shattered Web Case": "2019-11-18",
    "CS20 Case": "2019-10-18",
    "Prisma 2 Case": "2020-03-31",
    "Fracture Case": "2020-08-06",
    "Operation Broken Fang Case": "2020-12-03",
    "Snakebite Case": "2021-05-03",
    "Operation Riptide Case": "2021-09-22",
    "Dreams & Nightmares Case": "2022-01-20",
    "Recoil Case": "2022-07-01",
    "Revolution Case": "2023-02-09",
    "Kilowatt Case": "2024-02-06",
    "Gallery Case": "2024-10-02",
    "Fever Case": "2025-03-31",
    # Sticker capsules
    "Sticker Capsule": "2014-01-29",
    "Sticker Capsule 2": "2014-01-29",
    "Community Sticker Capsule 1": "2014-06-11",
    "Enfu Sticker Capsule": "2015-04-22",
    "Pinups Capsule": "2015-12-01",
    "Slid3 Capsule": "2015-12-01",
    "Team Roles Capsule": "2015-12-01",
    "Bestiary Capsule": "2016-08-16",
    "Sugarface Capsule": "2016-08-16",
    "Perfect World Sticker Capsule 1": "2017-09-15",
    "Perfect World Sticker Capsule 2": "2017-09-15",
    "Community Capsule 2018": "2017-12-11",
    "Skill Groups Capsule": "2018-11-15",
    "Feral Predators Capsule": "2019-04-15",
    "Chicken Capsule": "2019-06-10",
    "CS20 Sticker Capsule": "2019-10-16",
    "Halo Capsule": "2019-11-25",
    "Half-Life: Alyx Sticker Capsule": "2020-03-23",
    "Warhammer 40,000 Sticker Capsule": "2020-05-28",
    "Poorly Drawn Capsule": "2021-02-14",
    "2021 Community Sticker Capsule": "2021-09-02",
    "Battlefield 2042 Sticker Capsule": "2021-10-07",
    "The Boardroom Sticker Capsule": "2022-02-20",
    "10 Year Birthday Sticker Capsule": "2022-06-15",
    "Espionage Sticker Capsule": "2023-01-05",
    "Ambush Sticker Capsule": "2024-01-25",
    "Warhammer 40,000 Adeptus Astartes Sticker Capsule": "2025-05-22",
    "Warhammer 40,000 Imperium Sticker Capsule": "2025-05-22",
    "Warhammer 40,000 Traitor Astartes Sticker Capsule": "2025-05-22",
    "Warhammer 40,000 Xenos Sticker Capsule": "2025-05-22",
    # Pin capsules
    "Collectible Pins Capsule Series 1": "2016-06-01",
    "Collectible Pins Capsule Series 2": "2016-09-28",
    "Collectible Pins Capsule Series 3": "2018-03-01",
    "Half-Life: Alyx Collectible Pins Capsule": "2020-03-23",
    # Music kit boxes
    "StatTrak™ Radicals Box": "2016-08-16",
    "Masterminds Music Kit Box": "2020-04-22",
    "StatTrak™ Masterminds Music Kit Box": "2020-04-22",
    "Tacticians Music Kit Box": "2021-07-20",
    "StatTrak™ Tacticians Music Kit Box": "2021-07-20",
    "Initiators Music Kit Box": "2022-08-15",
    "StatTrak™ Initiators Music Kit Box": "2022-08-15",
    "NIGHTMODE Music Kit Box": "2024-01-24",
    "StatTrak™ NIGHTMODE Music Kit Box": "2024-01-24",
    "Masterminds 2 Music Kit Box": "2024-08-15",
    "StatTrak™ Masterminds 2 Music Kit Box": "2024-08-15",
    "Deluge Music Kit Box": "2025-06-27",
    "StatTrak™ Deluge Music Kit Box": "2025-06-27",
    # Special containers
    "The X-Ray Collection": "2019-09-30",
    "X-Ray P250 Package": "2019-09-30",
    "Anubis Collection Package": "2023-03-22",
    "Sealed Genesis Terminal": "2025-09-16",
    "Sealed Dead Hand Terminal": "2026-03-11",
}

session = requests.Session()
session.headers.update({"User-Agent": "cs2-simulator-parser/4.4"})

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")


def fetch_json(url: str) -> Any:
    response = session.get(url, timeout=TIMEOUT)
    response.raise_for_status()
    return response.json()


def ensure_dirs() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    CASES_DIR.mkdir(parents=True, exist_ok=True)
    SKINS_DIR.mkdir(parents=True, exist_ok=True)
    STICKERS_DIR.mkdir(parents=True, exist_ok=True)
    PINS_DIR.mkdir(parents=True, exist_ok=True)
    MUSIC_KITS_DIR.mkdir(parents=True, exist_ok=True)
    REWARD_COLLECTIONS_DIR.mkdir(parents=True, exist_ok=True)
    OPERATION_COLLECTIONS_DIR.mkdir(parents=True, exist_ok=True)
    TOURNAMENT_LOGOS_DIR.mkdir(parents=True, exist_ok=True)


def reset_collectible_outputs() -> None:
    for data_path in [
        DATA_DIR / "stickers.json",
        DATA_DIR / "sticker_contents.json",
        DATA_DIR / "pins.json",
        DATA_DIR / "pin_contents.json",
        DATA_DIR / "music_kits.json",
        DATA_DIR / "music_kit_contents.json",
    ]:
        if data_path.exists():
            data_path.unlink()

    ensure_dirs()


def load_json_list(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    return json.loads(path.read_text(encoding="utf-8"))


def load_json_any(path: Path) -> Any:
    if not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data: Any) -> None:
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def safe_float(value: Any, default: float) -> float:
    if value is None:
        return default
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def sort_numeric_str(values: list[str]) -> list[str]:
    return sorted(values, key=lambda x: int(x))


def normalize_release_date_string(value: Any) -> str | None:
    text = str(value or "").strip()
    if not text:
        return None

    text = text.split("T")[0].strip().replace("/", "-")
    parts = text.split("-")
    if len(parts) != 3:
        return None

    year, month, day = parts
    if not (year.isdigit() and month.isdigit() and day.isdigit()):
        return None

    return f"{int(year):04d}-{int(month):02d}-{int(day):02d}"


def parse_release_date(crate: dict[str, Any]) -> str:
    normalized = normalize_release_date_string(crate.get("first_sale_date"))
    if normalized:
        return normalized
    return "2000-01-01"


def canonical_name(name: str) -> str:
    n = name.strip()
    n = n.replace("StatTrak™ ", "")
    n = n.replace("Souvenir ", "")
    n = n.replace("★ ", "")
    n = re.sub(
        r"\s+\((Factory New|Minimal Wear|Field-Tested|Well-Worn|Battle-Scarred)\)$",
        "",
        n,
    )
    return n.strip().lower()


def normalize_collection_name(name: str | None) -> str | None:
    if not name:
        return None
    cleaned = str(name).strip()
    return COLLECTION_NAME_ALIASES.get(cleaned, cleaned)


def normalize_name_key(value: str | None) -> str:
    text = str(value or "").strip().lower()
    text = text.replace("blast.tv", "blast tv")
    text = text.replace("cs:go", "csgo")
    text = text.replace("cs2", "cs 2")
    text = text.replace("kraków", "krakow")
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def make_safe_slug(value: str | None) -> str:
    text = str(value or "").strip().lower()
    text = text.replace("blast.tv", "blast_tv")
    text = text.replace("kraków", "krakow")
    text = re.sub(r"[^a-z0-9]+", "_", text)
    text = re.sub(r"_+", "_", text).strip("_")
    return text or "unknown"


def tournament_name_candidates(raw_name: str | None) -> list[str]:
    text = str(raw_name or "").strip()
    if not text:
        return []

    candidates = {normalize_name_key(text)}

    match = re.match(r"^(.*?)(?:\s+)(\d{4})$", text)
    if match:
        left = match.group(1).strip()
        year = match.group(2).strip()
        candidates.add(normalize_name_key(f"{year} {left}"))

    match = re.match(r"^(\d{4})(?:\s+)(.*)$", text)
    if match:
        year = match.group(1).strip()
        right = match.group(2).strip()
        candidates.add(normalize_name_key(f"{right} {year}"))

    return [c for c in candidates if c]


def infer_tournament_name_from_souvenir_package(crate_name: str) -> str | None:
    name = crate_name.strip()
    if not name.lower().endswith("souvenir package"):
        return None

    base = re.sub(r"\s+souvenir package$", "", name, flags=re.IGNORECASE).strip()
    if not base:
        return None

    known_suffixes = sorted(set(MAP_SUFFIXES), key=len, reverse=True)

    for suffix in known_suffixes:
        if base.lower().endswith(f" {suffix.lower()}"):
            return base[: -(len(suffix) + 1)].strip()

    parts = base.split()
    if len(parts) >= 3:
        return " ".join(parts[:-1]).strip()

    return base


def infer_tournament_name_from_sticker_capsule(crate_name: str) -> str | None:
    name = str(crate_name).strip()
    if not name.lower().endswith("capsule"):
        return None

    known_names = sorted(TOURNAMENT_START_DATES.keys(), key=len, reverse=True)
    for tournament_name in known_names:
        if name.startswith(f"{tournament_name} "):
            return tournament_name

    return None


def infer_tournament_container_date(crate_name: str) -> str | None:
    name = str(crate_name).strip()
    normalized_name = normalize_name_key(name)
    known_names = sorted(TOURNAMENT_CONTAINER_START_DATES.keys(), key=len, reverse=True)

    for tournament_name in known_names:
        normalized_tournament_name = normalize_name_key(tournament_name)
        if (
            name.startswith(f"{tournament_name} ")
            or name == tournament_name
            or normalized_tournament_name in normalized_name
        ):
            return TOURNAMENT_CONTAINER_START_DATES[tournament_name]

    return None


def expand_tournament_name_variants(name: str | None) -> list[str]:
    if not name:
        return []

    variants = [name]
    alias = TOURNAMENT_NAME_ALIASES.get(name)
    if alias and alias not in variants:
        variants.append(alias)

    # обратные мягкие варианты на случай, если в API лежит короткое имя
    for short_name, official_name in TOURNAMENT_NAME_ALIASES.items():
        if official_name == name and short_name not in variants:
            variants.append(short_name)

    return variants


def split_item_and_skin(full_name: str) -> tuple[str, str]:
    name = full_name.strip()

    if name.startswith("★ "):
        name = name[2:].strip()

    if " | " in name:
        base, skin_name = name.split(" | ", 1)
        return base.strip(), skin_name.strip()

    return name.strip(), "Vanilla"


def infer_item_kind_and_id(base_item_name: str) -> tuple[str, str, str]:
    if base_item_name in GLOVES_ID_MAP:
        return "GLOVES", GLOVES_ID_MAP[base_item_name], "GLOVES"

    if base_item_name in KNIFE_ID_MAP:
        return "KNIFE", KNIFE_ID_MAP[base_item_name], "KNIFE"

    if base_item_name in WEAPON_ID_MAP:
        weapon_id = WEAPON_ID_MAP[base_item_name]
        weapon_type = infer_weapon_type_from_weapon_name(base_item_name)
        return "WEAPON", weapon_id, weapon_type

    raise ValueError(f"Unknown item base name: {base_item_name}")


def infer_weapon_type_from_weapon_name(name: str) -> str:
    pistols = {
        "CZ75-Auto",
        "Desert Eagle",
        "Dual Berettas",
        "Five-SeveN",
        "Glock-18",
        "P2000",
        "P250",
        "R8 Revolver",
        "Tec-9",
        "USP-S",
        "Zeus x27",
    }
    smgs = {"MAC-10", "MP5-SD", "MP7", "MP9", "PP-Bizon", "P90", "UMP-45"}
    shotguns = {"MAG-7", "Nova", "Sawed-Off", "XM1014"}
    machine_guns = {"M249", "Negev"}
    rifles = {"FAMAS", "Galil AR", "M4A4", "M4A1-S", "AK-47", "AUG", "SG 553"}
    snipers = {"SSG 08", "AWP", "SCAR-20", "G3SG1"}

    if name in pistols:
        return "EQUIPMENT" if name == "Zeus x27" else "PISTOL"
    if name in smgs:
        return "SMG"
    if name in shotguns:
        return "SHOTGUN"
    if name in machine_guns:
        return "MACHINE_GUN"
    if name in rifles:
        return "RIFLE"
    if name in snipers:
        return "SNIPER_RIFLE"

    raise ValueError(f"Cannot infer weapon type for: {name}")


def is_supported_container(crate: dict[str, Any]) -> bool:
    crate_type = str(crate.get("type") or "").strip()
    crate_name = str(crate.get("name") or "").strip()
    lower_name = crate_name.lower()
    lower_type = crate_type.lower()

    if crate_name in CONTAINER_TYPE_OVERRIDES:
        return True

    if crate_type == "Case":
        return True
    if crate_type == "Souvenir Package":
        return True
    if "souvenir package" in lower_name:
        return True
    if "collection package" in lower_name:
        return True
    if "patch" in lower_name or "patch" in lower_type:
        return False
    if crate_type == "Pins" or "pins" in lower_type:
        return True
    if crate_type == "Music Kit Box" or "music kit box" in lower_type:
        return True
    if "capsule" in lower_name:
        return True
    if "terminal" in lower_name or "terminal" in lower_type:
        return True
    if "x-ray" in lower_name or "xray" in lower_name:
        return True

    return False


def infer_container_type(crate_name: str | None, crate_type: str | None) -> str:
    crate_name = str(crate_name or "").strip()
    crate_type = str(crate_type or "").strip()

    if crate_name in CONTAINER_TYPE_OVERRIDES:
        return CONTAINER_TYPE_OVERRIDES[crate_name]

    lower_name = crate_name.lower()
    lower_type = crate_type.lower()

    if "terminal" in lower_name or "terminal" in lower_type:
        return "TERMINAL"

    if "x-ray" in lower_name or "xray" in lower_name:
        return "XRAY_PACKAGE"

    if "souvenir package" in lower_name or "souvenir package" in lower_type:
        return "SOUVENIR_PACKAGE"

    if "collection package" in lower_name or "collection package" in lower_type:
        return "COLLECTION_PACKAGE"

    if crate_type == "Pins" or "pins" in lower_type:
        return "PIN_CAPSULE"

    if crate_type == "Music Kit Box" or "music kit box" in lower_type:
        return "MUSIC_KIT_BOX"

    if lower_name.endswith("sticker collection"):
        return "STICKER_COLLECTION"

    if "capsule" in lower_name:
        return "STICKER_CAPSULE"

    if crate_type == "Case":
        return "CASE"

    return "CASE"


def make_stable_numeric_id(source_id: str, prefix: int) -> str:
    digits = re.findall(r"\d+", source_id)
    if digits:
        joined = "".join(digits)
        if joined:
            return str(int(joined))

    value = zlib.crc32(source_id.encode("utf-8")) % 100_000_000
    return str(prefix + value)


def detect_image_extension(url: str, content_type: str | None = None) -> str:
    content_type = (content_type or "").lower()

    if "image/svg+xml" in content_type:
        return ".svg"
    if "image/png" in content_type:
        return ".png"
    if "image/webp" in content_type:
        return ".webp"
    if "image/jpeg" in content_type or "image/jpg" in content_type:
        return ".jpg"

    parsed = urlparse(url)
    lower_path = parsed.path.lower()

    if lower_path.endswith(".svg"):
        return ".svg"
    if lower_path.endswith(".png"):
        return ".png"
    if lower_path.endswith(".webp"):
        return ".webp"
    if lower_path.endswith(".jpg") or lower_path.endswith(".jpeg"):
        return ".jpg"

    return ".png"


def download_file(url: str, path: Path) -> None:
    if not url or path.exists():
        return

    try:
        with session.get(url, stream=True, timeout=TIMEOUT) as response:
            response.raise_for_status()
            with path.open("wb") as f:
                for chunk in response.iter_content(chunk_size=1024 * 32):
                    if chunk:
                        f.write(chunk)
    except Exception as exc:
        print(f"[WARN] failed to download {url} -> {path}: {exc}")


def download_file_with_real_extension(url: str, path_without_ext: Path) -> str | None:
    if not url:
        return None

    try:
        response = session.get(url, timeout=TIMEOUT)
        response.raise_for_status()

        ext = detect_image_extension(
            url=url,
            content_type=response.headers.get("Content-Type"),
        )

        final_path = path_without_ext.with_suffix(ext)

        if final_path.exists():
            return ext

        final_path.parent.mkdir(parents=True, exist_ok=True)
        final_path.write_bytes(response.content)
        return ext

    except Exception as exc:
        print(f"[WARN] failed to download {url} -> {path_without_ext}: {exc}")
        return None


def existing_skin_key(skin: dict[str, Any]) -> tuple[str, str, str, str]:
    return (
        str(skin.get("itemKind", "")),
        str(skin.get("itemId", "")),
        canonical_name(str(skin.get("name", ""))),
        canonical_name(str(skin.get("phase") or skin.get("variantName") or "")),
    )


def existing_sticker_key(sticker: dict[str, Any]) -> tuple[str, str, str, str]:
    return (
        canonical_name(str(sticker.get("name", ""))),
        str(sticker.get("stickerType", "")).strip().upper(),
        str(sticker.get("effect", "")).strip().upper(),
        canonical_name(str(sticker.get("collection") or sticker.get("tournament") or "")),
    )


def existing_pin_key(pin: dict[str, Any]) -> tuple[str, str]:
    return (
        canonical_name(str(pin.get("name", ""))),
        canonical_name(str(pin.get("collection", ""))),
    )


def existing_music_kit_key(music_kit: dict[str, Any]) -> tuple[str, str, bool]:
    return (
        canonical_name(str(music_kit.get("name", ""))),
        canonical_name(str(music_kit.get("collection", ""))),
        bool(music_kit.get("isStatTrak")),
    )


def existing_case_key(case: dict[str, Any]) -> str:
    return str(case.get("name", "")).strip()


def full_skin_name_key(name: str) -> str:
    return canonical_name(name)


def reward_key_from_item(item: dict[str, Any]) -> str:
    return normalize_collection_name(str(item.get("name", "")).strip()) or ""


def operation_key(name: str, operation_id: str) -> str:
    normalized_name = normalize_collection_name(name) or name
    return f"{operation_id}::{normalized_name}"


def extract_phase_and_variant(
    *,
    full_skin_name: str,
    pattern_name: str | None,
    explicit_phase: str | None,
) -> tuple[str | None, str | None]:
    pattern_name = (pattern_name or "").strip()
    explicit_phase = (explicit_phase or "").strip()
    full_skin_name = full_skin_name.strip()

    if explicit_phase:
        return explicit_phase, explicit_phase

    if not pattern_name:
        return None, None

    full_canon = canonical_name(full_skin_name)
    pattern_canon = canonical_name(pattern_name)

    if full_canon == pattern_canon:
        return None, None

    prefix = pattern_name + " "
    if full_skin_name.startswith(prefix):
        suffix = full_skin_name[len(prefix):].strip()
        if suffix:
            return suffix, suffix

    return None, None


def choose_collection_name_and_image(meta: dict[str, Any]) -> tuple[str | None, str | None]:
    collections = meta.get("collections")
    if isinstance(collections, list) and collections:
        first = collections[0]
        if isinstance(first, dict):
            raw_name = first.get("name")
            raw_image = first.get("image")
            normalized_name = normalize_collection_name(str(raw_name)) if raw_name else None
            image = str(raw_image) if raw_image else None
            return normalized_name, image
    return None, None


def choose_image_url(meta: dict[str, Any]) -> str | None:
    image = meta.get("image")
    if image:
        return str(image)
    return None


def normalize_sticker_name(name: str) -> str:
    normalized = str(name).strip()
    if " | " in normalized:
        _, sticker_name = normalized.split(" | ", 1)
        return sticker_name.strip()
    return normalized


def infer_sticker_type(meta: dict[str, Any]) -> str:
    raw_type = str(meta.get("type", "")).strip().lower()
    if raw_type == "autograph":
        return "AUTOGRAPH"
    if raw_type == "event":
        return "EVENT"
    return "STICKER"


def infer_sticker_container_type(crate_name: str | None) -> str:
    normalized_name = str(crate_name or "").strip()
    if normalized_name in CONTAINER_TYPE_OVERRIDES:
        return CONTAINER_TYPE_OVERRIDES[normalized_name]

    name = normalized_name.lower()

    if name.endswith("sticker collection") or name.endswith("sticker pack"):
        return "STICKER_COLLECTION"

    return "STICKER_CAPSULE"


def infer_pin_collection(crate_name: str | None) -> str | None:
    name = str(crate_name or "").strip()
    if not name:
        return None

    match = re.match(r"^Collectible Pins Capsule Series (\d+)$", name)
    if match:
        return f"Series {match.group(1)}"

    name = re.sub(r"\s+Collectible Pins Capsule$", "", name).strip()
    name = re.sub(r"\s+Pins Capsule$", "", name).strip()
    return name or None


def infer_music_kit_collection(crate_name: str | None) -> str | None:
    name = str(crate_name or "").strip()
    if not name:
        return None

    name = name.replace("StatTrak™ ", "").strip()
    name = re.sub(r"\s+Music Kit Box$", "", name).strip()
    name = re.sub(r"\s+Box$", "", name).strip()
    return name or None


def normalize_music_kit_name(name: str | None) -> tuple[str, bool]:
    normalized = str(name or "").strip()
    is_stat_trak = normalized.startswith("StatTrak™ ")

    if is_stat_trak:
        normalized = normalized[len("StatTrak™ ") :].strip()

    if normalized.startswith("Music Kit | "):
        normalized = normalized[len("Music Kit | ") :].strip()

    return normalized, is_stat_trak


def make_hashed_numeric_id(source_id: str, prefix: int) -> str:
    value = zlib.crc32(source_id.encode("utf-8")) % 100_000_000
    return str(prefix + value)


def resolve_sticker_collection_source(
    collection_name: str | None,
) -> dict[str, str | None]:
    normalized_name = str(collection_name or "").strip()
    source = STICKER_COLLECTION_SOURCE_OVERRIDES.get(normalized_name, {})
    return {
        "sourceType": str(source.get("sourceType") or "").strip() or None,
        "sourceId": str(source.get("sourceId") or "").strip() or None,
        "sourceName": str(source.get("sourceName") or "").strip() or None,
        "releaseDate": str(source.get("releaseDate") or "").strip() or None,
    }


def get_explicit_phase(meta: dict[str, Any]) -> str | None:
    direct = meta.get("phase")
    if direct:
        return str(direct)

    original = meta.get("original")
    if isinstance(original, dict):
        phase = original.get("phase")
        if phase:
            return str(phase)

    return None


def load_reward_overrides() -> dict[str, dict[str, Any]]:
    overrides = {
        normalize_collection_name(k) or k: dict(v)
        for k, v in DEFAULT_REWARD_SOURCE_OVERRIDES.items()
    }

    if REWARD_OVERRIDES_PATH.exists():
        try:
            user_data = load_json_any(REWARD_OVERRIDES_PATH)
            if isinstance(user_data, dict):
                for name, meta in user_data.items():
                    if isinstance(meta, dict):
                        normalized_name = normalize_collection_name(str(name).strip()) or str(name).strip()
                        overrides[normalized_name] = dict(meta)
        except Exception as exc:
            print(f"[WARN] failed to load {REWARD_OVERRIDES_PATH}: {exc}")

    return overrides


def load_operation_overrides() -> list[dict[str, Any]]:
    entries = [dict(x) for x in DEFAULT_OPERATION_COLLECTION_OVERRIDES]

    if OPERATION_OVERRIDES_PATH.exists():
        try:
            user_data = load_json_any(OPERATION_OVERRIDES_PATH)
            if isinstance(user_data, list):
                for item in user_data:
                    if isinstance(item, dict):
                        entries.append(dict(item))
        except Exception as exc:
            print(f"[WARN] failed to load {OPERATION_OVERRIDES_PATH}: {exc}")

    normalized_entries: list[dict[str, Any]] = []
    for item in entries:
        name = normalize_collection_name(str(item.get("name", "")).strip())
        operation_id = str(item.get("operationId", "")).strip()
        operation_name = str(item.get("operationName", "")).strip()
        if not name or not operation_id or not operation_name:
            continue
        normalized_entries.append({
            "name": name,
            "operationId": operation_id,
            "operationName": operation_name,
            "releaseDate": item.get("releaseDate"),
        })

    return normalized_entries


def build_collection_image_map(skins_data: list[dict[str, Any]]) -> dict[str, str]:
    result: dict[str, str] = {}
    for skin_meta in skins_data:
        collection_name, collection_image = choose_collection_name_and_image(skin_meta)
        if collection_name and collection_image and collection_name not in result:
            result[collection_name] = collection_image
    return result


def build_collection_meta_map(
    collections_data: list[dict[str, Any]],
) -> dict[str, dict[str, str]]:
    result: dict[str, dict[str, str]] = {}

    for collection in collections_data:
        collection_name = normalize_collection_name(str(collection.get("name", "")).strip())
        collection_image = str(collection.get("image", "")).strip()
        crates = collection.get("crates")

        if not collection_name or not collection_image or not isinstance(crates, list):
            continue

        for crate in crates:
            if not isinstance(crate, dict):
                continue

            crate_name = str(crate.get("name", "")).strip()
            if not crate_name:
                continue

    return result


def build_tournament_logo_map(
    stickers_data: list[dict[str, Any]],
) -> dict[str, str]:
    result: dict[str, str] = {}

    for sticker in stickers_data:
        if not isinstance(sticker, dict):
            continue

        tournament = sticker.get("tournament")
        image = str(sticker.get("image", "")).strip()
        sticker_type = str(sticker.get("type", "")).strip().lower()

        if not isinstance(tournament, dict) or not image:
            continue

        if sticker_type != "event":
            continue

        tournament_name = str(tournament.get("name", "")).strip()
        if not tournament_name:
            continue

        for key in tournament_name_candidates(tournament_name):
            result.setdefault(key, image)

    return result


def find_existing_logo_path_by_slug(logo_slug: str) -> str | None:
    for ext in (".png", ".svg", ".webp", ".jpg"):
        candidate = TOURNAMENT_LOGOS_DIR / f"{logo_slug}{ext}"
        if candidate.exists():
            return f"assets/tournament_logos/{logo_slug}{ext}"
    return None


def resolve_souvenir_logo_and_name(
    crate_name: str,
    tournament_logo_by_name: dict[str, str],
) -> tuple[str | None, str | None]:
    parsed_name = infer_tournament_name_from_souvenir_package(crate_name)
    if not parsed_name:
        return None, None

    for variant in expand_tournament_name_variants(parsed_name):
        for key in tournament_name_candidates(variant):
            logo_url = tournament_logo_by_name.get(key)
            if logo_url:
                return variant, logo_url

    return parsed_name, None


def resolve_container_release_date(
    *,
    crate_name: str,
    container_type: str,
    crate_meta: dict[str, Any] | None = None,
    existing_release_date: Any = None,
) -> str:
    explicit = CONTAINER_RELEASE_DATE_OVERRIDES.get(crate_name)
    if explicit:
        return explicit

    tournament_start_date = infer_tournament_container_date(crate_name)
    if tournament_start_date:
        return tournament_start_date

    existing = normalize_release_date_string(existing_release_date)
    if existing:
        return existing

    return "2000-01-01"


def main() -> None:
    ensure_dirs()
    reset_collectible_outputs()

    reward_source_overrides = load_reward_overrides()
    operation_collection_overrides = load_operation_overrides()

    all_existing_cases = load_json_list(DATA_DIR / "cases.json")
    existing_skins = load_json_list(DATA_DIR / "skins.json")
    existing_stickers: list[dict[str, Any]] = []
    existing_pins: list[dict[str, Any]] = []
    existing_music_kits: list[dict[str, Any]] = []
    existing_cases = [
        item
        for item in all_existing_cases
        if str(item.get("type", "")).strip().upper()
        not in {"STICKER_CAPSULE", "STICKER_COLLECTION", "PIN_CAPSULE", "MUSIC_KIT_BOX"}
    ]
    existing_reward_collections = load_json_list(DATA_DIR / "reward_collections.json")
    existing_operation_collections = load_json_list(DATA_DIR / "operation_collections.json")

    existing_skin_by_key: dict[tuple[str, str, str, str], dict[str, Any]] = {
        existing_skin_key(s): dict(s) for s in existing_skins
    }
    existing_sticker_by_key: dict[tuple[str, str, str, str], dict[str, Any]] = {
        existing_sticker_key(s): dict(s) for s in existing_stickers
    }
    existing_pin_by_key: dict[tuple[str, str], dict[str, Any]] = {
        existing_pin_key(p): dict(p) for p in existing_pins
    }
    existing_music_kit_by_key: dict[tuple[str, str, bool], dict[str, Any]] = {
        existing_music_kit_key(m): dict(m) for m in existing_music_kits
    }
    existing_case_by_name: dict[str, dict[str, Any]] = {
        existing_case_key(c): dict(c) for c in existing_cases
    }
    existing_reward_by_key: dict[str, dict[str, Any]] = {
        reward_key_from_item(c): dict(c) for c in existing_reward_collections
    }
    existing_operation_by_key: dict[str, dict[str, Any]] = {
        operation_key(str(c.get("name", "")), str(c.get("operationId", ""))): dict(c)
        for c in existing_operation_collections
    }

    used_skin_ids = {
        int(s["id"]) for s in existing_skins if str(s.get("id", "")).isdigit()
    }
    used_sticker_ids = {
        int(s["id"]) for s in existing_stickers if str(s.get("id", "")).isdigit()
    }
    used_pin_ids = {
        int(p["id"]) for p in existing_pins if str(p.get("id", "")).isdigit()
    }
    used_music_kit_ids = {
        int(m["id"]) for m in existing_music_kits if str(m.get("id", "")).isdigit()
    }
    used_case_ids = {
        int(c["id"]) for c in all_existing_cases if str(c.get("id", "")).isdigit()
    }
    used_reward_ids = {
        int(c["id"]) for c in existing_reward_collections if str(c.get("id", "")).isdigit()
    }
    used_operation_ids = {
        int(c["id"]) for c in existing_operation_collections if str(c.get("id", "")).isdigit()
    }

    next_skin_id = max(used_skin_ids, default=0) + 1
    next_sticker_id = max(used_sticker_ids, default=900_000_000) + 1
    next_pin_id = max(used_pin_ids, default=950_000_000) + 1
    next_music_kit_id = max(used_music_kit_ids, default=970_000_000) + 1
    next_case_id = max(used_case_ids, default=0) + 1
    next_reward_id = max(used_reward_ids, default=10_000) + 1
    next_operation_id = max(used_operation_ids, default=20_000) + 1

    print("Fetching crates.json ...")
    crates = fetch_json(CRATES_URL)

    print("Fetching skins.json ...")
    skins_data = fetch_json(SKINS_URL)

    print("Fetching collections.json ...")
    collections_data = fetch_json(COLLECTIONS_URL)

    print("Fetching stickers.json ...")
    stickers_data = fetch_json(STICKERS_URL)

    print("Fetching music_kits.json ...")
    music_kits_data = fetch_json(MUSIC_KITS_URL)

    collection_image_by_name = build_collection_image_map(skins_data)
    collection_meta_by_crate_name = build_collection_meta_map(collections_data)
    tournament_logo_by_name = build_tournament_logo_map(stickers_data)

    print(f"Tournament logo candidates: {len(tournament_logo_by_name)}")
    print("Tournament logo keys:")
    for key in sorted(tournament_logo_by_name.keys()):
        print(f"  {key}")

    new_cases: dict[str, dict[str, Any]] = {c["id"]: dict(c) for c in existing_cases}
    case_name_to_id: dict[str, str] = {
        str(c["name"]).strip(): str(c["id"])
        for c in existing_cases
    }

    new_reward_collections: dict[str, dict[str, Any]] = {
        c["id"]: dict(c) for c in existing_reward_collections
    }
    reward_name_to_id: dict[str, str] = {
        reward_key_from_item(c): str(c["id"])
        for c in existing_reward_collections
    }

    new_operation_collections: dict[str, dict[str, Any]] = {
        c["id"]: dict(c) for c in existing_operation_collections
    }
    operation_key_to_id: dict[str, str] = {
        operation_key(str(c.get("name", "")), str(c.get("operationId", ""))): str(c["id"])
        for c in existing_operation_collections
    }

    supported_crates = [crate for crate in crates if is_supported_container(crate)]
    supported_crates.sort(key=lambda x: str(x.get("name", "")))

    unresolved_release_dates: list[str] = []
    for crate in supported_crates:
        crate_name = str(crate.get("name", "")).strip()
        if not crate_name:
            continue

        container_type = infer_container_type(crate_name, crate.get("type"))
        release_date = resolve_container_release_date(
            crate_name=crate_name,
            container_type=container_type,
            crate_meta=None,
            existing_release_date=None,
        )
        if release_date == "2000-01-01":
            unresolved_release_dates.append(f"{container_type}: {crate_name}")

    if unresolved_release_dates:
        preview = "\n".join(unresolved_release_dates[:20])
        raise RuntimeError(
            "Missing hardcoded release dates for supported containers:\n"
            f"{preview}"
        )

    souvenir_crates = [
        crate for crate in supported_crates
        if infer_container_type(crate.get("name"), crate.get("type")) == "SOUVENIR_PACKAGE"
    ]
    print(f"Souvenir crates: {len(souvenir_crates)}")

    tournament_logos_created = 0

    for crate in supported_crates:
        crate_name = str(crate.get("name", "")).strip()
        if not crate_name:
            continue

        existing_case = existing_case_by_name.get(crate_name)
        if existing_case:
            case_id = str(existing_case["id"])
            release_date = existing_case.get("releaseDate")
        else:
            case_id = str(next_case_id)
            next_case_id += 1
            release_date = None

        container_type = infer_container_type(crate_name, crate.get("type"))
        release_date = resolve_container_release_date(
            crate_name=crate_name,
            container_type=container_type,
            crate_meta=crate,
            existing_release_date=release_date,
        )

        collection_name = None
        collection_image = None
        tournament_name = None
        tournament_logo_rel = None

        collection_meta = collection_meta_by_crate_name.get(crate_name)

        if container_type == "SOUVENIR_PACKAGE":
            tournament_name, tournament_logo_url = resolve_souvenir_logo_and_name(
                crate_name,
                tournament_logo_by_name,
            )

            if tournament_name:
                logo_slug = make_safe_slug(tournament_name)
                existing_logo_rel = find_existing_logo_path_by_slug(logo_slug)
                if existing_logo_rel:
                    tournament_logo_rel = existing_logo_rel
                elif tournament_logo_url:
                    ext = download_file_with_real_extension(
                        tournament_logo_url,
                        TOURNAMENT_LOGOS_DIR / logo_slug,
                    )
                    if ext:
                        tournament_logo_rel = f"assets/tournament_logos/{logo_slug}{ext}"
                        tournament_logos_created += 1

            print(
                f"[SOUVENIR] crate={crate_name} | "
                f"parsed_tournament={tournament_name} | "
                f"logo_found={'yes' if tournament_logo_rel else 'no'}"
            )

        case_record = {
            "id": case_id,
            "name": crate_name,
            "caseImage": f"assets/cases/{case_id}.png",
            "releaseDate": release_date,
            "type": container_type,
            "tournamentName": tournament_name,
            "tournamentLogo": tournament_logo_rel,
            "sourceType": None,
            "sourceId": None,
            "sourceName": None,
        }

        new_cases[case_id] = case_record
        case_name_to_id[crate_name] = case_id

        if crate.get("image"):
            download_file(str(crate["image"]), CASES_DIR / f"{case_id}.png")

    new_skins: dict[str, dict[str, Any]] = {}
    new_stickers: dict[str, dict[str, Any]] = {}
    new_pins: dict[str, dict[str, Any]] = {}
    new_music_kits: dict[str, dict[str, Any]] = {}
    skin_id_by_full_name: dict[str, str] = {}

    case_contents_map: dict[str, set[str]] = {
        case_id: set() for case_id in new_cases.keys()
    }
    sticker_contents_map: dict[str, set[str]] = {}
    pin_contents_map: dict[str, set[str]] = {}
    music_kit_contents_map: dict[str, set[str]] = {}
    reward_contents_map: dict[str, set[str]] = {
        collection_id: set() for collection_id in new_reward_collections.keys()
    }
    operation_contents_map: dict[str, set[str]] = {
        collection_id: set() for collection_id in new_operation_collections.keys()
    }

    created_skin_count = 0
    created_sticker_count = 0
    created_pin_count = 0
    created_music_kit_count = 0
    reused_skin_count = 0
    reused_sticker_count = 0
    reused_pin_count = 0
    reused_music_kit_count = 0
    skipped_unknown_items = 0
    container_refs_created_from_skin_meta = 0
    reward_collections_created = 0
    operation_collections_created = 0

    for meta in skins_data:
        full_name = str(meta.get("name", "")).strip()
        if not full_name or " | " not in full_name:
            continue

        base_item_name, full_skin_name = split_item_and_skin(full_name)

        try:
            item_kind, item_id, fallback_weapon_type = infer_item_kind_and_id(base_item_name)
        except ValueError:
            skipped_unknown_items += 1
            continue

        pattern_obj = meta.get("pattern") if isinstance(meta.get("pattern"), dict) else {}
        pattern_name = str(pattern_obj.get("name") or "").strip() or None
        explicit_phase = get_explicit_phase(meta)
        phase, variant_name = extract_phase_and_variant(
            full_skin_name=full_skin_name,
            pattern_name=pattern_name,
            explicit_phase=explicit_phase,
        )

        float_top = safe_float(meta.get("min_float"), 0.0)
        float_bottom = safe_float(meta.get("max_float"), 1.0)
        if float_bottom < float_top:
            float_bottom = 1.0

        rarity = RARITY_MAP.get(
            str((meta.get("rarity") or {}).get("name")),
            "MIL_SPEC",
        )
        weapon_type = WEAPON_TYPE_MAP.get(
            str((meta.get("category") or {}).get("name")),
            fallback_weapon_type,
        )
        collection_name, _collection_image = choose_collection_name_and_image(meta)
        image_url = choose_image_url(meta)

        key = (
            item_kind,
            item_id,
            canonical_name(full_skin_name),
            canonical_name(phase or variant_name or ""),
        )

        existing_skin = existing_skin_by_key.get(key)

        if existing_skin:
            skin_id = str(existing_skin["id"])
            reused_skin_count += 1
        else:
            source_skin_id = str(meta.get("id", ""))
            candidate = make_stable_numeric_id(source_skin_id, 800_000_000)

            if (
                candidate.isdigit()
                and int(candidate) not in used_skin_ids
                and candidate not in new_skins
            ):
                skin_id = candidate
                used_skin_ids.add(int(candidate))
            else:
                while next_skin_id in used_skin_ids:
                    next_skin_id += 1
                skin_id = str(next_skin_id)
                used_skin_ids.add(next_skin_id)
                next_skin_id += 1

            created_skin_count += 1

        reward_meta = reward_source_overrides.get(collection_name or "")
        operation_metas = [
            item for item in operation_collection_overrides
            if item["name"] == collection_name
        ]

        old_skin = new_skins.get(skin_id) or existing_skin or {}

        skin_record = {
            "id": skin_id,
            "name": full_skin_name,
            "skinImage": f"assets/skins/{skin_id}.png",
            "floatTop": round(float_top, 6),
            "floatBottom": round(float_bottom, 6),
            "rarity": rarity,
            "weaponType": weapon_type,
            "itemKind": item_kind,
            "itemId": item_id,
            "collection": collection_name if collection_name else old_skin.get("collection"),
            "finishCatalogName": pattern_name or old_skin.get("finishCatalogName"),
            "variantName": variant_name if variant_name else old_skin.get("variantName"),
            "phase": phase if phase else old_skin.get("phase"),
            "apiPaintIndex": str(meta.get("paint_index")) if meta.get("paint_index") is not None else old_skin.get("apiPaintIndex"),
            "collectionSourceType": reward_meta.get("sourceType") if reward_meta else old_skin.get("collectionSourceType"),
            "collectionSourceId": reward_meta.get("sourceId") if reward_meta else old_skin.get("collectionSourceId"),
            "isRewardCollection": bool(reward_meta) if reward_meta else old_skin.get("isRewardCollection", False),
            "operationCollectionIds": [x["operationId"] for x in operation_metas] if operation_metas else old_skin.get("operationCollectionIds", []),
            "isOperationCollection": bool(operation_metas) if operation_metas else old_skin.get("isOperationCollection", False),
        }

        new_skins[skin_id] = skin_record
        existing_skin_by_key[key] = skin_record
        skin_id_by_full_name[full_skin_name_key(f"{base_item_name} | {full_skin_name}")] = skin_id

        if image_url:
            download_file(image_url, SKINS_DIR / f"{skin_id}.png")

        if reward_meta and collection_name:
            reward_key = collection_name
            existing_reward = existing_reward_by_key.get(reward_key)
            if existing_reward:
                reward_id = str(existing_reward["id"])
            elif reward_key in reward_name_to_id:
                reward_id = reward_name_to_id[reward_key]
            else:
                reward_id = str(next_reward_id)
                next_reward_id += 1

            reward_name_to_id[reward_key] = reward_id

            collection_image = collection_image_by_name.get(collection_name)
            image_ext = None
            if collection_image:
                image_ext = download_file_with_real_extension(
                    collection_image,
                    REWARD_COLLECTIONS_DIR / reward_id,
                )

            if image_ext is None:
                old_reward = new_reward_collections.get(reward_id) or existing_reward or {}
                old_image = str(old_reward.get("image") or "").strip()
                image_ext = Path(old_image).suffix if old_image else ".png"
                if not image_ext:
                    image_ext = ".png"

            reward_record = {
                "id": reward_id,
                "name": collection_name,
                "image": f"assets/reward_collections/{reward_id}{image_ext}",
                "sourceType": reward_meta["sourceType"],
                "sourceId": reward_meta["sourceId"],
                "currency": reward_meta.get("currency", "STARS"),
                "cost": int(reward_meta.get("cost", 4)),
                "releaseDate": reward_meta.get("releaseDate"),
            }

            if reward_id not in new_reward_collections:
                reward_collections_created += 1

            new_reward_collections[reward_id] = reward_record
            reward_contents_map.setdefault(reward_id, set()).add(skin_id)

        for operation_meta in operation_metas:
            op_key = operation_key(collection_name or "", operation_meta["operationId"])
            existing_operation = existing_operation_by_key.get(op_key)

            if existing_operation:
                op_id = str(existing_operation["id"])
            elif op_key in operation_key_to_id:
                op_id = operation_key_to_id[op_key]
            else:
                op_id = str(next_operation_id)
                next_operation_id += 1

            operation_key_to_id[op_key] = op_id

            collection_image = collection_image_by_name.get(collection_name or "")
            image_ext = None
            if collection_image:
                image_ext = download_file_with_real_extension(
                    collection_image,
                    OPERATION_COLLECTIONS_DIR / op_id,
                )

            if image_ext is None:
                old_operation = new_operation_collections.get(op_id) or existing_operation or {}
                old_image = str(old_operation.get("image") or "").strip()
                image_ext = Path(old_image).suffix if old_image else ".png"
                if not image_ext:
                    image_ext = ".png"

            operation_record = {
                "id": op_id,
                "name": collection_name,
                "image": f"assets/operation_collections/{op_id}{image_ext}",
                "operationId": operation_meta["operationId"],
                "operationName": operation_meta["operationName"],
                "releaseDate": operation_meta.get("releaseDate"),
            }

            if op_id not in new_operation_collections:
                operation_collections_created += 1

            new_operation_collections[op_id] = operation_record
            operation_contents_map.setdefault(op_id, set()).add(skin_id)

        crates_refs = meta.get("crates")
        if isinstance(crates_refs, list):
            for crate_ref in crates_refs:
                if not isinstance(crate_ref, dict):
                    continue

                crate_name = str(crate_ref.get("name", "")).strip()
                if not crate_name:
                    continue

                case_id = case_name_to_id.get(crate_name)
                if case_id is None:
                    existing_case = existing_case_by_name.get(crate_name)
                    if existing_case:
                        case_id = str(existing_case["id"])
                        release_date = existing_case.get("releaseDate")
                    else:
                        case_id = str(next_case_id)
                        next_case_id += 1
                        release_date = None

                    container_type = "STICKER_CAPSULE"
                    release_date = resolve_container_release_date(
                        crate_name=crate_name,
                        container_type=container_type,
                        crate_meta=crate_ref if isinstance(crate_ref, dict) else None,
                        existing_release_date=release_date,
                    )

                    collection_name = None
                    collection_image = None
                    tournament_name = None
                    tournament_logo_rel = None

                    collection_meta = collection_meta_by_crate_name.get(crate_name)

                    if container_type == "SOUVENIR_PACKAGE":
                        tournament_name, tournament_logo_url = resolve_souvenir_logo_and_name(
                            crate_name,
                            tournament_logo_by_name,
                        )

                        if tournament_name:
                            logo_slug = make_safe_slug(tournament_name)
                            existing_logo_rel = find_existing_logo_path_by_slug(logo_slug)
                            if existing_logo_rel:
                                tournament_logo_rel = existing_logo_rel
                            elif tournament_logo_url:
                                ext = download_file_with_real_extension(
                                    tournament_logo_url,
                                    TOURNAMENT_LOGOS_DIR / logo_slug,
                                )
                                if ext:
                                    tournament_logo_rel = f"assets/tournament_logos/{logo_slug}{ext}"
                                    tournament_logos_created += 1

                    case_record = {
                        "id": case_id,
                        "name": crate_name,
                        "caseImage": f"assets/cases/{case_id}.png",
                        "releaseDate": release_date,
                        "type": container_type,
                        "tournamentName": tournament_name,
                        "tournamentLogo": tournament_logo_rel,
                        "sourceType": None,
                        "sourceId": None,
                        "sourceName": None,
                    }

                    new_cases[case_id] = case_record
                    case_name_to_id[crate_name] = case_id
                    case_contents_map.setdefault(case_id, set())
                    container_refs_created_from_skin_meta += 1

                    image = crate_ref.get("image")
                    if image:
                        download_file(str(image), CASES_DIR / f"{case_id}.png")

                case_contents_map.setdefault(case_id, set()).add(skin_id)

        time.sleep(0.003)

    sticker_collection_name_to_id: dict[str, str] = {}

    for meta in stickers_data:
        raw_name = str(meta.get("name", "")).strip()
        sticker_name = normalize_sticker_name(raw_name)
        if not sticker_name:
            continue

        sticker_type = infer_sticker_type(meta)
        effect = str(meta.get("effect", "Other")).strip().upper() or "OTHER"
        rarity = STICKER_RARITY_MAP.get(
            str((meta.get("rarity") or {}).get("name")),
            "HIGH_GRADE",
        )

        collection_name, _collection_image = choose_collection_name_and_image(meta)
        tournament = meta.get("tournament") if isinstance(meta.get("tournament"), dict) else {}
        tournament_name = str(tournament.get("name", "")).strip() or None
        image_url = choose_image_url(meta)

        key = (
            canonical_name(sticker_name),
            sticker_type,
            effect,
            canonical_name(collection_name or tournament_name or ""),
        )
        existing_sticker = existing_sticker_by_key.get(key)

        if existing_sticker:
            sticker_id = str(existing_sticker["id"])
            reused_sticker_count += 1
        else:
            source_sticker_id = str(meta.get("id", ""))
            candidate = make_stable_numeric_id(source_sticker_id, 900_000_000)

            if (
                candidate.isdigit()
                and int(candidate) not in used_sticker_ids
                and candidate not in new_stickers
            ):
                sticker_id = candidate
                used_sticker_ids.add(int(candidate))
            else:
                while next_sticker_id in used_sticker_ids:
                    next_sticker_id += 1
                sticker_id = str(next_sticker_id)
                used_sticker_ids.add(next_sticker_id)
                next_sticker_id += 1

            created_sticker_count += 1

        sticker_record = {
            "id": sticker_id,
            "name": sticker_name,
            "stickerImage": f"assets/stickers/{sticker_id}.png",
            "rarity": rarity,
            "stickerType": sticker_type,
            "effect": effect,
            "collection": collection_name,
            "tournament": tournament_name,
        }

        new_stickers[sticker_id] = sticker_record
        existing_sticker_by_key[key] = sticker_record

        if image_url:
            download_file(image_url, STICKERS_DIR / f"{sticker_id}.png")

        crates_refs = meta.get("crates")
        if isinstance(crates_refs, list):
            for crate_ref in crates_refs:
                if not isinstance(crate_ref, dict):
                    continue

                crate_name = str(crate_ref.get("name", "")).strip()
                if not crate_name:
                    continue

                case_id = case_name_to_id.get(crate_name)
                if case_id is None:
                    existing_case = existing_case_by_name.get(crate_name)
                    if existing_case:
                        case_id = str(existing_case["id"])
                        release_date = existing_case.get("releaseDate")
                    else:
                        case_id = str(next_case_id)
                        next_case_id += 1
                        release_date = None

                    container_type = infer_sticker_container_type(crate_name)
                    release_date = resolve_container_release_date(
                        crate_name=crate_name,
                        container_type=container_type,
                        crate_meta=crate_ref if isinstance(crate_ref, dict) else None,
                        existing_release_date=release_date,
                    )
                    source_meta = (
                        resolve_sticker_collection_source(crate_name)
                        if container_type == "STICKER_COLLECTION"
                        else {"sourceType": None, "sourceId": None, "sourceName": None, "releaseDate": None}
                    )
                    if source_meta["releaseDate"]:
                        release_date = source_meta["releaseDate"]

                    case_record = {
                        "id": case_id,
                        "name": crate_name,
                        "caseImage": f"assets/cases/{case_id}.png",
                        "releaseDate": release_date,
                        "type": container_type,
                        "tournamentName": None,
                        "tournamentLogo": None,
                        "sourceType": source_meta["sourceType"],
                        "sourceId": source_meta["sourceId"],
                        "sourceName": source_meta["sourceName"],
                    }

                    new_cases[case_id] = case_record
                    case_name_to_id[crate_name] = case_id
                    container_refs_created_from_skin_meta += 1

                    image = crate_ref.get("image")
                    if image:
                        download_file(str(image), CASES_DIR / f"{case_id}.png")
                else:
                    container_type = infer_sticker_container_type(crate_name)
                    existing_case_record = new_cases.get(case_id)
                    if existing_case_record:
                        release_date = resolve_container_release_date(
                            crate_name=crate_name,
                            container_type=container_type,
                            crate_meta=crate_ref if isinstance(crate_ref, dict) else None,
                            existing_release_date=existing_case_record.get("releaseDate"),
                        )
                        source_meta = (
                            resolve_sticker_collection_source(crate_name)
                            if container_type == "STICKER_COLLECTION"
                            else {"sourceType": None, "sourceId": None, "sourceName": None, "releaseDate": None}
                        )
                        if source_meta["releaseDate"]:
                            release_date = source_meta["releaseDate"]

                        existing_case_record["releaseDate"] = release_date
                        existing_case_record["type"] = container_type
                        existing_case_record["sourceType"] = source_meta["sourceType"]
                        existing_case_record["sourceId"] = source_meta["sourceId"]
                        existing_case_record["sourceName"] = source_meta["sourceName"]

                sticker_contents_map.setdefault(case_id, set()).add(sticker_id)

        collections_refs = meta.get("collections")
        if isinstance(collections_refs, list):
            for collection_ref in collections_refs:
                if not isinstance(collection_ref, dict):
                    continue

                collection_name = normalize_collection_name(
                    str(collection_ref.get("name", "")).strip()
                )
                if not collection_name:
                    continue

                case_id = sticker_collection_name_to_id.get(collection_name)
                if case_id is None:
                    existing_case = existing_case_by_name.get(collection_name)
                    if existing_case:
                        case_id = str(existing_case["id"])
                        release_date = existing_case.get("releaseDate")
                    elif collection_name in case_name_to_id:
                        case_id = case_name_to_id[collection_name]
                        release_date = new_cases.get(case_id, {}).get("releaseDate")
                    else:
                        case_id = str(next_case_id)
                        next_case_id += 1
                        release_date = "2000-01-01"

                    source_meta = resolve_sticker_collection_source(collection_name)
                    if source_meta["releaseDate"]:
                        release_date = source_meta["releaseDate"]

                    case_record = {
                        "id": case_id,
                        "name": collection_name,
                        "caseImage": f"assets/cases/{case_id}.png",
                        "releaseDate": release_date,
                        "type": "STICKER_COLLECTION",
                        "tournamentName": None,
                        "tournamentLogo": None,
                        "sourceType": source_meta["sourceType"],
                        "sourceId": source_meta["sourceId"],
                        "sourceName": source_meta["sourceName"],
                    }

                    new_cases[case_id] = case_record
                    case_name_to_id[collection_name] = case_id
                    sticker_collection_name_to_id[collection_name] = case_id

                    image = collection_ref.get("image")
                    if image:
                        download_file(str(image), CASES_DIR / f"{case_id}.png")

                sticker_contents_map.setdefault(case_id, set()).add(sticker_id)
                existing_case_record = new_cases.get(case_id)
                if existing_case_record:
                    source_meta = resolve_sticker_collection_source(collection_name)
                    existing_case_record["type"] = "STICKER_COLLECTION"
                    existing_case_record["sourceType"] = source_meta["sourceType"]
                    existing_case_record["sourceId"] = source_meta["sourceId"]
                    existing_case_record["sourceName"] = source_meta["sourceName"]
                    if source_meta["releaseDate"]:
                        existing_case_record["releaseDate"] = source_meta["releaseDate"]

        time.sleep(0.001)

    for crate in supported_crates:
        crate_name = str(crate.get("name", "")).strip()
        if not crate_name:
            continue

        if infer_container_type(crate_name, crate.get("type")) != "PIN_CAPSULE":
            continue

        case_id = case_name_to_id.get(crate_name)
        if case_id is None:
            continue

        pin_collection = infer_pin_collection(crate_name)
        contains = crate.get("contains")
        if not isinstance(contains, list):
            continue

        for collectible in contains:
            if not isinstance(collectible, dict):
                continue

            pin_name = str(collectible.get("name", "")).strip()
            if not pin_name:
                continue

            rarity = PIN_RARITY_MAP.get(
                str((collectible.get("rarity") or {}).get("name")),
                "HIGH_GRADE",
            )
            image_url = str(collectible.get("image", "")).strip() or None

            key = (
                canonical_name(pin_name),
                canonical_name(pin_collection or ""),
            )
            existing_pin = existing_pin_by_key.get(key)

            if existing_pin:
                pin_id = str(existing_pin["id"])
                reused_pin_count += 1
            else:
                source_pin_id = str(collectible.get("id", ""))
                candidate = make_stable_numeric_id(source_pin_id, 950_000_000)

                if (
                    candidate.isdigit()
                    and int(candidate) not in used_pin_ids
                    and candidate not in new_pins
                ):
                    pin_id = candidate
                    used_pin_ids.add(int(candidate))
                else:
                    while next_pin_id in used_pin_ids:
                        next_pin_id += 1
                    pin_id = str(next_pin_id)
                    used_pin_ids.add(next_pin_id)
                    next_pin_id += 1

                created_pin_count += 1

            pin_record = {
                "id": pin_id,
                "name": pin_name,
                "pinImage": f"assets/pins/{pin_id}.png",
                "rarity": rarity,
                "collection": pin_collection,
            }

            new_pins[pin_id] = pin_record
            existing_pin_by_key[key] = pin_record

            if image_url:
                download_file(image_url, PINS_DIR / f"{pin_id}.png")

            pin_contents_map.setdefault(case_id, set()).add(pin_id)

    music_kit_meta_by_id: dict[str, dict[str, Any]] = {
        str(item.get("id", "")).strip(): item
        for item in music_kits_data
        if isinstance(item, dict) and str(item.get("id", "")).strip()
    }

    for crate in supported_crates:
        crate_name = str(crate.get("name", "")).strip()
        if not crate_name:
            continue

        if infer_container_type(crate_name, crate.get("type")) != "MUSIC_KIT_BOX":
            continue

        case_id = case_name_to_id.get(crate_name)
        if case_id is None:
            continue

        music_kit_collection = infer_music_kit_collection(crate_name)
        contains = crate.get("contains")
        if not isinstance(contains, list):
            continue

        for collectible in contains:
            if not isinstance(collectible, dict):
                continue

            raw_name = str(collectible.get("name", "")).strip()
            music_kit_name, is_stat_trak = normalize_music_kit_name(raw_name)
            if not music_kit_name:
                continue

            source_music_kit_id = str(collectible.get("id", "")).strip()
            if not source_music_kit_id:
                continue

            music_kit_meta = music_kit_meta_by_id.get(source_music_kit_id, {})
            rarity = MUSIC_KIT_RARITY_MAP.get(
                str((collectible.get("rarity") or {}).get("name"))
                or str((music_kit_meta.get("rarity") or {}).get("name")),
                "HIGH_GRADE",
            )
            image_url = (
                str(collectible.get("image", "")).strip()
                or str(music_kit_meta.get("image", "")).strip()
                or None
            )

            key = (
                canonical_name(music_kit_name),
                canonical_name(music_kit_collection or ""),
                is_stat_trak,
            )
            existing_music_kit = existing_music_kit_by_key.get(key)

            if existing_music_kit:
                music_kit_id = str(existing_music_kit["id"])
                reused_music_kit_count += 1
            else:
                candidate = make_hashed_numeric_id(source_music_kit_id, 970_000_000)

                if (
                    candidate.isdigit()
                    and int(candidate) not in used_music_kit_ids
                    and candidate not in new_music_kits
                ):
                    music_kit_id = candidate
                    used_music_kit_ids.add(int(candidate))
                else:
                    while next_music_kit_id in used_music_kit_ids:
                        next_music_kit_id += 1
                    music_kit_id = str(next_music_kit_id)
                    used_music_kit_ids.add(next_music_kit_id)
                    next_music_kit_id += 1

                created_music_kit_count += 1

            music_kit_record = {
                "id": music_kit_id,
                "name": music_kit_name,
                "musicKitImage": f"assets/music_kits/{music_kit_id}.png",
                "rarity": rarity,
                "collection": music_kit_collection,
                "isStatTrak": is_stat_trak,
            }

            new_music_kits[music_kit_id] = music_kit_record
            existing_music_kit_by_key[key] = music_kit_record

            if image_url:
                download_file(image_url, MUSIC_KITS_DIR / f"{music_kit_id}.png")

            music_kit_contents_map.setdefault(case_id, set()).add(music_kit_id)

    for legacy_case in LEGACY_CASE_OVERRIDES:
        legacy_name = str(legacy_case.get("name", "")).strip()
        if not legacy_name:
            continue

        existing_case = existing_case_by_name.get(legacy_name)
        if existing_case:
            legacy_case_id = str(existing_case["id"])
        elif legacy_name in case_name_to_id:
            legacy_case_id = case_name_to_id[legacy_name]
        else:
            legacy_case_id = str(next_case_id)
            next_case_id += 1

        base_case_name = str(legacy_case.get("baseCaseName", "")).strip()
        base_case_id = case_name_to_id.get(base_case_name)
        base_case = new_cases.get(base_case_id) if base_case_id else None

        case_image_path = f"assets/cases/{legacy_case_id}.png"

        legacy_case_record = {
            "id": legacy_case_id,
            "name": legacy_name,
            "caseImage": case_image_path,
            "releaseDate": str(legacy_case.get("releaseDate") or "2000-01-01"),
            "type": str(legacy_case.get("type") or "CASE"),
            "tournamentName": None,
            "tournamentLogo": None,
            "sourceType": None,
            "sourceId": None,
            "sourceName": None,
        }

        new_cases[legacy_case_id] = legacy_case_record
        case_name_to_id[legacy_name] = legacy_case_id
        case_contents_map.setdefault(legacy_case_id, set())

        if legacy_case.get("copyImageFromBase") and base_case:
            base_image_rel = str(base_case.get("caseImage") or "").strip()
            base_image_name = Path(base_image_rel).name
            base_image_path = CASES_DIR / base_image_name
            legacy_image_path = CASES_DIR / f"{legacy_case_id}.png"

            if base_image_path.exists() and not legacy_image_path.exists():
                legacy_image_path.write_bytes(base_image_path.read_bytes())

        for full_skin_name in legacy_case.get("contents", []):
            if not isinstance(full_skin_name, str):
                continue

            skin_id = skin_id_by_full_name.get(full_skin_name_key(full_skin_name))
            if skin_id is None:
                print(
                    f"[WARN] legacy case '{legacy_name}' references missing skin: {full_skin_name}"
                )
                continue

            case_contents_map.setdefault(legacy_case_id, set()).add(skin_id)

        if legacy_case.get("copySpecialItemsFromBase") and base_case_id:
            base_skin_ids = case_contents_map.get(base_case_id, set())
            for skin_id in base_skin_ids:
                skin = new_skins.get(skin_id)
                if not skin:
                    continue
                weapon_type = str(skin.get("weaponType", ""))
                item_kind = str(skin.get("itemKind", ""))
                if weapon_type in {"KNIFE", "GLOVES"} or item_kind in {"KNIFE", "GLOVES"}:
                    case_contents_map.setdefault(legacy_case_id, set()).add(skin_id)

    for case_record in new_cases.values():
        case_name = str(case_record.get("name", "")).strip()
        forced_type = CONTAINER_TYPE_OVERRIDES.get(case_name)
        if forced_type:
            case_record["type"] = forced_type

    cases_out = sorted(
        new_cases.values(),
        key=lambda x: (x.get("releaseDate") or "9999-99-99", x.get("name", "")),
    )
    skins_out = sorted(new_skins.values(), key=lambda x: int(x["id"]))
    stickers_out = sorted(new_stickers.values(), key=lambda x: int(x["id"]))
    pins_out = sorted(new_pins.values(), key=lambda x: int(x["id"]))
    music_kits_out = sorted(new_music_kits.values(), key=lambda x: int(x["id"]))

    case_contents_out = sorted(
        (
            {"caseId": case_id, "skinIds": sort_numeric_str(list(skin_ids))}
            for case_id, skin_ids in case_contents_map.items()
            if skin_ids
        ),
        key=lambda x: int(x["caseId"]),
    )
    sticker_contents_out = sorted(
        (
            {"caseId": case_id, "stickerIds": sort_numeric_str(list(sticker_ids))}
            for case_id, sticker_ids in sticker_contents_map.items()
            if sticker_ids
        ),
        key=lambda x: int(x["caseId"]),
    )
    pin_contents_out = sorted(
        (
            {"caseId": case_id, "pinIds": sort_numeric_str(list(pin_ids))}
            for case_id, pin_ids in pin_contents_map.items()
            if pin_ids
        ),
        key=lambda x: int(x["caseId"]),
    )
    music_kit_contents_out = sorted(
        (
            {"caseId": case_id, "musicKitIds": sort_numeric_str(list(music_kit_ids))}
            for case_id, music_kit_ids in music_kit_contents_map.items()
            if music_kit_ids
        ),
        key=lambda x: int(x["caseId"]),
    )

    reward_collections_out = sorted(
        new_reward_collections.values(),
        key=lambda x: (x.get("sourceType", ""), x.get("releaseDate") or "9999-99-99", x.get("name", "")),
    )
    reward_collection_contents_out = sorted(
        (
            {"rewardCollectionId": reward_id, "skinIds": sort_numeric_str(list(skin_ids))}
            for reward_id, skin_ids in reward_contents_map.items()
            if skin_ids
        ),
        key=lambda x: int(x["rewardCollectionId"]),
    )

    operation_collections_out = sorted(
        new_operation_collections.values(),
        key=lambda x: (x.get("operationName", ""), x.get("releaseDate") or "9999-99-99", x.get("name", "")),
    )
    operation_collection_contents_out = sorted(
        (
            {"operationCollectionId": op_id, "skinIds": sort_numeric_str(list(skin_ids))}
            for op_id, skin_ids in operation_contents_map.items()
            if skin_ids
        ),
        key=lambda x: int(x["operationCollectionId"]),
    )

    write_json(DATA_DIR / "cases.json", cases_out)
    write_json(DATA_DIR / "skins.json", skins_out)
    write_json(DATA_DIR / "stickers.json", stickers_out)
    write_json(DATA_DIR / "pins.json", pins_out)
    write_json(DATA_DIR / "music_kits.json", music_kits_out)
    write_json(DATA_DIR / "case_contents.json", case_contents_out)
    write_json(DATA_DIR / "sticker_contents.json", sticker_contents_out)
    write_json(DATA_DIR / "pin_contents.json", pin_contents_out)
    write_json(DATA_DIR / "music_kit_contents.json", music_kit_contents_out)
    write_json(DATA_DIR / "reward_collections.json", reward_collections_out)
    write_json(DATA_DIR / "reward_collection_contents.json", reward_collection_contents_out)
    write_json(DATA_DIR / "operation_collections.json", operation_collections_out)
    write_json(DATA_DIR / "operation_collection_contents.json", operation_collection_contents_out)

    print("Done.")
    print(f"Containers: {len(cases_out)}")
    print(f"Reward collections: {len(reward_collections_out)}")
    print(f"Operation collections: {len(operation_collections_out)}")
    print(f"Skins: {len(skins_out)}")
    print(f"Stickers: {len(stickers_out)}")
    print(f"Pins: {len(pins_out)}")
    print(f"Music kits: {len(music_kits_out)}")
    print(f"Case contents: {len(case_contents_out)}")
    print(f"Sticker contents: {len(sticker_contents_out)}")
    print(f"Pin contents: {len(pin_contents_out)}")
    print(f"Music kit contents: {len(music_kit_contents_out)}")
    print(f"Reward collection contents: {len(reward_collection_contents_out)}")
    print(f"Operation collection contents: {len(operation_collection_contents_out)}")
    print(f"Created skins: {created_skin_count}")
    print(f"Created stickers: {created_sticker_count}")
    print(f"Created pins: {created_pin_count}")
    print(f"Created music kits: {created_music_kit_count}")
    print(f"Reused skins: {reused_skin_count}")
    print(f"Reused stickers: {reused_sticker_count}")
    print(f"Reused pins: {reused_pin_count}")
    print(f"Reused music kits: {reused_music_kit_count}")
    print(f"Unknown items skipped: {skipped_unknown_items}")
    print(f"Containers created from skin.crates fallback: {container_refs_created_from_skin_meta}")
    print(f"Reward collections created: {reward_collections_created}")
    print(f"Operation collections created: {operation_collections_created}")
    print(f"Tournament logos downloaded: {tournament_logos_created}")


if __name__ == "__main__":
    main()
