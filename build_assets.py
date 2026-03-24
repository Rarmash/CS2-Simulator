from __future__ import annotations

import json
import re
import time
import zlib
from pathlib import Path
from typing import Any, Optional

import requests

CRATES_URL = "https://raw.githubusercontent.com/ByMykel/CSGO-API/main/public/api/en/crates.json"
SKINS_URL = "https://raw.githubusercontent.com/ByMykel/CSGO-API/main/public/api/en/skins.json"

OUT_ROOT = Path(".")
ASSETS_DIR = OUT_ROOT / "assets"
DATA_DIR = ASSETS_DIR / "data"
CASES_DIR = ASSETS_DIR / "cases"
SKINS_DIR = ASSETS_DIR / "skins"

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

session = requests.Session()
session.headers.update({"User-Agent": "cs2-simulator-parser/1.1"})


def fetch_json(url: str) -> Any:
    r = session.get(url, timeout=TIMEOUT)
    r.raise_for_status()
    return r.json()


def ensure_dirs() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    CASES_DIR.mkdir(parents=True, exist_ok=True)
    SKINS_DIR.mkdir(parents=True, exist_ok=True)


def load_json_list(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data: Any) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def safe_float(value: Any, default: float) -> float:
    if value is None:
        return default
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def sort_numeric_str(values: list[str]) -> list[str]:
    return sorted(values, key=lambda x: int(x))

def parse_release_date(crate: dict) -> str:
    date = crate.get("first_sale_date")
    if date:
        return date.split("T")[0]
    return "2000-01-01"


def canonical_name(name: str) -> str:
    n = name.strip()
    n = n.replace("StatTrak™ ", "")
    n = n.replace("Souvenir ", "")
    n = n.replace("★ ", "")
    n = re.sub(r"\s+\((Factory New|Minimal Wear|Field-Tested|Well-Worn|Battle-Scarred)\)$", "", n)
    return n.strip().lower()


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
        "CZ75-Auto", "Desert Eagle", "Dual Berettas", "Five-SeveN", "Glock-18",
        "P2000", "P250", "R8 Revolver", "Tec-9", "USP-S", "Zeus x27",
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


def build_skin_meta_lookup(skins_data: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    lookup: dict[str, dict[str, Any]] = {}
    for skin in skins_data:
        lookup[canonical_name(skin["name"])] = skin
    return lookup


def make_stable_numeric_id(source_id: str, prefix: int) -> str:
    digits = re.findall(r"\d+", source_id)
    if digits:
        joined = "".join(digits)
        if joined:
            return str(int(joined))
    value = zlib.crc32(source_id.encode("utf-8")) % 100_000_000
    return str(prefix + value)


def download_file(url: str, path: Path) -> None:
    if path.exists():
        return
    try:
        with session.get(url, stream=True, timeout=TIMEOUT) as r:
            r.raise_for_status()
            with path.open("wb") as f:
                for chunk in r.iter_content(chunk_size=1024 * 32):
                    if chunk:
                        f.write(chunk)
    except Exception as e:
        print(f"[WARN] failed to download {url} -> {path}: {e}")


def existing_skin_key(skin: dict[str, Any]) -> tuple[str, str, str]:
    return (
        skin["itemKind"],
        skin["itemId"],
        canonical_name(skin["name"]),
    )


def main() -> None:
    ensure_dirs()

    existing_skins = load_json_list(DATA_DIR / "skins.json")
    existing_cases = load_json_list(DATA_DIR / "cases.json")
    existing_case_contents = load_json_list(DATA_DIR / "case_contents.json")

    existing_skin_by_key: dict[tuple[str, str, str], dict[str, Any]] = {
        existing_skin_key(s): s for s in existing_skins
    }
    existing_case_by_name: dict[str, dict[str, Any]] = {
        c["name"]: c for c in existing_cases
    }
    existing_case_content_by_case_id: dict[str, dict[str, Any]] = {
        c["caseId"]: c for c in existing_case_contents
    }

    used_skin_ids = {int(s["id"]) for s in existing_skins if str(s.get("id", "")).isdigit()}
    used_case_ids = {int(c["id"]) for c in existing_cases if str(c.get("id", "")).isdigit()}

    next_skin_id = max(used_skin_ids, default=0) + 1
    next_case_id = max(used_case_ids, default=0) + 1

    print("Fetching crates.json ...")
    crates = fetch_json(CRATES_URL)

    print("Fetching skins.json ...")
    skins_data = fetch_json(SKINS_URL)
    skins_lookup = build_skin_meta_lookup(skins_data)

    new_skins = {s["id"]: dict(s) for s in existing_skins}
    new_cases = {c["id"]: dict(c) for c in existing_cases}
    new_case_contents = {c["caseId"]: dict(c) for c in existing_case_contents}

    filtered_cases = [crate for crate in crates if crate.get("type") == "Case"]
    filtered_cases.sort(key=lambda c: c["name"])

    for crate in filtered_cases:
        existing_case = existing_case_by_name.get(crate["name"])
        if existing_case:
            case_id = existing_case["id"]
        else:
            case_id = str(next_case_id)
            next_case_id += 1

        release_date = parse_release_date(crate)

        new_cases[case_id] = {
            "id": case_id,
            "name": crate["name"],
            "caseImage": f"assets/cases/{case_id}.png",
            "releaseDate": release_date,
        }

        if crate.get("image"):
            download_file(crate["image"], CASES_DIR / f"{case_id}.png")

        skin_ids_for_case: list[str] = []

        for item in crate.get("contains", []) + crate.get("contains_rare", []):
            full_name = item["name"]
            base_item_name, skin_name = split_item_and_skin(full_name)

            try:
                item_kind, item_id, fallback_weapon_type = infer_item_kind_and_id(base_item_name)
            except ValueError:
                print(f"[WARN] skip unknown item: {full_name}")
                continue

            lookup_key = canonical_name(full_name)
            meta = skins_lookup.get(lookup_key)

            if meta is None:
                plain_name = f"{base_item_name} | {skin_name}" if skin_name != "Vanilla" else base_item_name
                meta = skins_lookup.get(canonical_name(plain_name))

            if meta is not None:
                float_top = safe_float(meta.get("min_float"), 0.0)
                float_bottom = safe_float(meta.get("max_float"), 1.0)
                if float_bottom < float_top:
                    float_bottom = 1.0

                is_souvenir = bool(meta.get("souvenir", False))
                rarity = RARITY_MAP.get(
                    meta.get("rarity", {}).get("name"),
                    RARITY_MAP.get(item.get("rarity", {}).get("name"), "MIL_SPEC"),
                )
                weapon_type = WEAPON_TYPE_MAP.get(
                    meta.get("category", {}).get("name"),
                    fallback_weapon_type,
                )
                image_url = item.get("image") or meta.get("image")
            else:
                float_top = 0.0
                float_bottom = 1.0
                is_souvenir = False
                rarity = RARITY_MAP.get(item.get("rarity", {}).get("name"), "MIL_SPEC")
                weapon_type = fallback_weapon_type
                image_url = item.get("image")

            key = (item_kind, item_id, canonical_name(skin_name))
            existing_skin = existing_skin_by_key.get(key)

            if existing_skin:
                skin_id = existing_skin["id"]
            else:
                source_item_id = item.get("id", "")
                candidate = make_stable_numeric_id(source_item_id, 800_000_000)
                if candidate.isdigit() and int(candidate) not in used_skin_ids and candidate not in new_skins:
                    skin_id = candidate
                    used_skin_ids.add(int(candidate))
                else:
                    while next_skin_id in used_skin_ids:
                        next_skin_id += 1
                    skin_id = str(next_skin_id)
                    used_skin_ids.add(next_skin_id)
                    next_skin_id += 1

            new_skins[skin_id] = {
                "id": skin_id,
                "name": skin_name,
                "skinImage": f"assets/skins/{skin_id}.png",
                "floatTop": round(float_top, 6),
                "floatBottom": round(float_bottom, 6),
                "isSouvenir": is_souvenir,
                "rarity": rarity,
                "weaponType": weapon_type,
                "itemKind": item_kind,
                "itemId": item_id,
            }

            skin_ids_for_case.append(skin_id)

            if image_url:
                download_file(image_url, SKINS_DIR / f"{skin_id}.png")

            time.sleep(0.01)

        old_case_content = existing_case_content_by_case_id.get(case_id)
        old_ids = old_case_content["skinIds"] if old_case_content else []
        merged_ids = sort_numeric_str(list({*old_ids, *skin_ids_for_case}))

        new_case_contents[case_id] = {
            "caseId": case_id,
            "skinIds": merged_ids,
        }

    cases_out = sorted(
        new_cases.values(),
        key=lambda x: x.get("releaseDate", "9999-99-99")
    )
    skins_out = sorted(new_skins.values(), key=lambda x: int(x["id"]))
    case_contents_out = sorted(new_case_contents.values(), key=lambda x: int(x["caseId"]))

    write_json(DATA_DIR / "cases.json", cases_out)
    write_json(DATA_DIR / "skins.json", skins_out)
    write_json(DATA_DIR / "case_contents.json", case_contents_out)

    print(f"Done. Cases: {len(cases_out)}, skins: {len(skins_out)}, case_contents: {len(case_contents_out)}")


if __name__ == "__main__":
    main()