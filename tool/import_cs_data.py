from __future__ import annotations

import json
import re
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

OUT_ROOT = Path(".")
ASSETS_DIR = OUT_ROOT / "assets"
DATA_DIR = ASSETS_DIR / "data"
CASES_DIR = ASSETS_DIR / "cases"
SKINS_DIR = ASSETS_DIR / "skins"
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

session = requests.Session()
session.headers.update({"User-Agent": "cs2-simulator-parser/4.4"})


def fetch_json(url: str) -> Any:
    response = session.get(url, timeout=TIMEOUT)
    response.raise_for_status()
    return response.json()


def ensure_dirs() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    CASES_DIR.mkdir(parents=True, exist_ok=True)
    SKINS_DIR.mkdir(parents=True, exist_ok=True)
    REWARD_COLLECTIONS_DIR.mkdir(parents=True, exist_ok=True)
    OPERATION_COLLECTIONS_DIR.mkdir(parents=True, exist_ok=True)
    TOURNAMENT_LOGOS_DIR.mkdir(parents=True, exist_ok=True)


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


def parse_release_date(crate: dict[str, Any]) -> str:
    date = crate.get("first_sale_date")
    if date:
        return str(date).split("T")[0]
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


def main() -> None:
    ensure_dirs()

    reward_source_overrides = load_reward_overrides()
    operation_collection_overrides = load_operation_overrides()

    existing_skins = load_json_list(DATA_DIR / "skins.json")
    existing_cases = load_json_list(DATA_DIR / "cases.json")
    existing_reward_collections = load_json_list(DATA_DIR / "reward_collections.json")
    existing_operation_collections = load_json_list(DATA_DIR / "operation_collections.json")

    existing_skin_by_key: dict[tuple[str, str, str, str], dict[str, Any]] = {
        existing_skin_key(s): dict(s) for s in existing_skins
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
    used_case_ids = {
        int(c["id"]) for c in existing_cases if str(c.get("id", "")).isdigit()
    }
    used_reward_ids = {
        int(c["id"]) for c in existing_reward_collections if str(c.get("id", "")).isdigit()
    }
    used_operation_ids = {
        int(c["id"]) for c in existing_operation_collections if str(c.get("id", "")).isdigit()
    }

    next_skin_id = max(used_skin_ids, default=0) + 1
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
            release_date = parse_release_date(crate)

        container_type = infer_container_type(crate_name, crate.get("type"))

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
        }

        new_cases[case_id] = case_record
        case_name_to_id[crate_name] = case_id

        if crate.get("image"):
            download_file(str(crate["image"]), CASES_DIR / f"{case_id}.png")

    new_skins: dict[str, dict[str, Any]] = {}
    skin_id_by_full_name: dict[str, str] = {}

    case_contents_map: dict[str, set[str]] = {
        case_id: set() for case_id in new_cases.keys()
    }
    reward_contents_map: dict[str, set[str]] = {
        collection_id: set() for collection_id in new_reward_collections.keys()
    }
    operation_contents_map: dict[str, set[str]] = {
        collection_id: set() for collection_id in new_operation_collections.keys()
    }

    created_skin_count = 0
    reused_skin_count = 0
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
                        release_date = "2000-01-01"

                    container_type = infer_container_type(crate_name, crate_ref.get("type"))

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

    cases_out = sorted(
        new_cases.values(),
        key=lambda x: (x.get("releaseDate") or "9999-99-99", x.get("name", "")),
    )
    skins_out = sorted(new_skins.values(), key=lambda x: int(x["id"]))

    case_contents_out = sorted(
        (
            {"caseId": case_id, "skinIds": sort_numeric_str(list(skin_ids))}
            for case_id, skin_ids in case_contents_map.items()
            if skin_ids
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
    write_json(DATA_DIR / "case_contents.json", case_contents_out)
    write_json(DATA_DIR / "reward_collections.json", reward_collections_out)
    write_json(DATA_DIR / "reward_collection_contents.json", reward_collection_contents_out)
    write_json(DATA_DIR / "operation_collections.json", operation_collections_out)
    write_json(DATA_DIR / "operation_collection_contents.json", operation_collection_contents_out)

    print("Done.")
    print(f"Containers: {len(cases_out)}")
    print(f"Reward collections: {len(reward_collections_out)}")
    print(f"Operation collections: {len(operation_collections_out)}")
    print(f"Skins: {len(skins_out)}")
    print(f"Case contents: {len(case_contents_out)}")
    print(f"Reward collection contents: {len(reward_collection_contents_out)}")
    print(f"Operation collection contents: {len(operation_collection_contents_out)}")
    print(f"Created skins: {created_skin_count}")
    print(f"Reused skins: {reused_skin_count}")
    print(f"Unknown items skipped: {skipped_unknown_items}")
    print(f"Containers created from skin.crates fallback: {container_refs_created_from_skin_meta}")
    print(f"Reward collections created: {reward_collections_created}")
    print(f"Operation collections created: {operation_collections_created}")
    print(f"Tournament logos downloaded: {tournament_logos_created}")


if __name__ == "__main__":
    main()