from __future__ import annotations

import json
import re
import time
import zlib
from pathlib import Path
from typing import Any

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

CONTAINER_TYPE_OVERRIDES = {
    "Anubis Collection Package": "COLLECTION_PACKAGE",
    "The X-Ray Collection": "XRAY_PACKAGE",
    "X-Ray P250 Package": "XRAY_PACKAGE",
}

session = requests.Session()
session.headers.update({"User-Agent": "cs2-simulator-parser/2.1"})


def fetch_json(url: str) -> Any:
    response = session.get(url, timeout=TIMEOUT)
    response.raise_for_status()
    return response.json()


def ensure_dirs() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    CASES_DIR.mkdir(parents=True, exist_ok=True)
    SKINS_DIR.mkdir(parents=True, exist_ok=True)


def load_json_list(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
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


def existing_skin_key(skin: dict[str, Any]) -> tuple[str, str, str, str]:
    return (
        str(skin.get("itemKind", "")),
        str(skin.get("itemId", "")),
        canonical_name(str(skin.get("name", ""))),
        canonical_name(str(skin.get("phase") or skin.get("variantName") or "")),
    )


def existing_case_key(case: dict[str, Any]) -> str:
    return str(case.get("name", "")).strip()


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


def choose_collection_name(meta: dict[str, Any]) -> str | None:
    collections = meta.get("collections")
    if isinstance(collections, list) and collections:
        first = collections[0]
        if isinstance(first, dict):
            name = first.get("name")
            if name:
                return str(name)
    return None


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


def main() -> None:
    ensure_dirs()

    existing_skins = load_json_list(DATA_DIR / "skins.json")
    existing_cases = load_json_list(DATA_DIR / "cases.json")

    existing_skin_by_key: dict[tuple[str, str, str, str], dict[str, Any]] = {
        existing_skin_key(s): dict(s) for s in existing_skins
    }
    existing_case_by_name: dict[str, dict[str, Any]] = {
        existing_case_key(c): dict(c) for c in existing_cases
    }

    used_skin_ids = {
        int(s["id"]) for s in existing_skins if str(s.get("id", "")).isdigit()
    }
    used_case_ids = {
        int(c["id"]) for c in existing_cases if str(c.get("id", "")).isdigit()
    }

    next_skin_id = max(used_skin_ids, default=0) + 1
    next_case_id = max(used_case_ids, default=0) + 1

    print("Fetching crates.json ...")
    crates = fetch_json(CRATES_URL)

    print("Fetching skins.json ...")
    skins_data = fetch_json(SKINS_URL)

    new_cases: dict[str, dict[str, Any]] = {c["id"]: dict(c) for c in existing_cases}
    case_name_to_id: dict[str, str] = {
        str(c["name"]).strip(): str(c["id"])
        for c in existing_cases
    }

    supported_crates = [crate for crate in crates if is_supported_container(crate)]
    supported_crates.sort(key=lambda x: str(x.get("name", "")))

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

        case_record = {
            "id": case_id,
            "name": crate_name,
            "caseImage": f"assets/cases/{case_id}.png",
            "releaseDate": release_date,
            "type": infer_container_type(crate_name, crate.get("type")),
        }

        new_cases[case_id] = case_record
        case_name_to_id[crate_name] = case_id

        if crate.get("image"):
            download_file(str(crate["image"]), CASES_DIR / f"{case_id}.png")

    new_skins: dict[str, dict[str, Any]] = {}
    case_contents_map: dict[str, set[str]] = {case_id: set() for case_id in new_cases.keys()}

    created_skin_count = 0
    reused_skin_count = 0
    skipped_unknown_items = 0
    container_refs_created_from_skin_meta = 0

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
        collection_name = choose_collection_name(meta)
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
        }

        new_skins[skin_id] = skin_record
        existing_skin_by_key[key] = skin_record

        if image_url:
            download_file(image_url, SKINS_DIR / f"{skin_id}.png")

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

                    case_record = {
                        "id": case_id,
                        "name": crate_name,
                        "caseImage": f"assets/cases/{case_id}.png",
                        "releaseDate": release_date,
                        "type": infer_container_type(crate_name, crate_ref.get("type")),
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

    cases_out = sorted(
        new_cases.values(),
        key=lambda x: (
            x.get("releaseDate") or "9999-99-99",
            x.get("name", ""),
        ),
    )
    skins_out = sorted(new_skins.values(), key=lambda x: int(x["id"]))
    case_contents_out = sorted(
        (
            {
                "caseId": case_id,
                "skinIds": sort_numeric_str(list(skin_ids)),
            }
            for case_id, skin_ids in case_contents_map.items()
            if skin_ids
        ),
        key=lambda x: int(x["caseId"]),
    )

    write_json(DATA_DIR / "cases.json", cases_out)
    write_json(DATA_DIR / "skins.json", skins_out)
    write_json(DATA_DIR / "case_contents.json", case_contents_out)

    type_counts: dict[str, int] = {}
    for case in cases_out:
        container_type = str(case.get("type") or "UNKNOWN")
        type_counts[container_type] = type_counts.get(container_type, 0) + 1

    print("Done.")
    print(f"Containers: {len(cases_out)}")
    for container_type, count in sorted(type_counts.items()):
        print(f"  {container_type}: {count}")
    print(f"Skins: {len(skins_out)}")
    print(f"Case contents: {len(case_contents_out)}")
    print(f"Created skins: {created_skin_count}")
    print(f"Reused skins: {reused_skin_count}")
    print(f"Unknown items skipped: {skipped_unknown_items}")
    print(f"Containers created from skin.crates fallback: {container_refs_created_from_skin_meta}")


if __name__ == "__main__":
    main()