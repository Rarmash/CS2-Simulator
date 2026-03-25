import json
import re
import shutil
from collections import defaultdict
from pathlib import Path


DATA_DIR = Path("assets/data")
SKINS_JSON = DATA_DIR / "skins.json"
CASE_CONTENTS_JSON = DATA_DIR / "case_contents.json"
SKINS_DIR = Path("assets/skins")


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


def skin_key(skin: dict) -> tuple[str, str, str]:
    return (
        str(skin.get("itemKind", "")),
        str(skin.get("itemId", "")),
        canonical_name(str(skin.get("name", ""))),
    )


def numeric_id_value(skin_id: str) -> int:
    try:
        return int(skin_id)
    except Exception:
        return 10**18


def has_existing_image(skin: dict) -> bool:
    skin_id = str(skin.get("id", ""))
    if not skin_id:
        return False
    return (SKINS_DIR / f"{skin_id}.png").exists()


def has_collection(skin: dict) -> bool:
    value = skin.get("collection")
    return isinstance(value, str) and value.strip() != ""


def has_valid_floats(skin: dict) -> bool:
    try:
        top = float(skin.get("floatTop"))
        bottom = float(skin.get("floatBottom"))
        return 0.0 <= top <= bottom <= 1.0
    except Exception:
        return False


def choose_canonical_skin(group: list[dict]) -> dict:
    def rank(skin: dict):
        return (
            0 if has_existing_image(skin) else 1,
            0 if has_collection(skin) else 1,
            0 if has_valid_floats(skin) else 1,
            numeric_id_value(str(skin.get("id", ""))),
        )

    return sorted(group, key=rank)[0]


def merge_skin_data(base: dict, group: list[dict]) -> dict:
    merged = dict(base)

    if not has_collection(merged):
        for skin in group:
            if has_collection(skin):
                merged["collection"] = skin["collection"]
                break

    if not has_valid_floats(merged):
        for skin in group:
            if has_valid_floats(skin):
                merged["floatTop"] = skin.get("floatTop")
                merged["floatBottom"] = skin.get("floatBottom")
                break

    if not merged.get("rarity"):
        for skin in group:
            if skin.get("rarity"):
                merged["rarity"] = skin["rarity"]
                break

    if not merged.get("weaponType"):
        for skin in group:
            if skin.get("weaponType"):
                merged["weaponType"] = skin["weaponType"]
                break

    if not merged.get("itemKind"):
        for skin in group:
            if skin.get("itemKind"):
                merged["itemKind"] = skin["itemKind"]
                break

    if not merged.get("itemId"):
        for skin in group:
            if skin.get("itemId"):
                merged["itemId"] = skin["itemId"]
                break

    merged["skinImage"] = f"assets/skins/{merged['id']}.png"

    return merged


def main() -> None:
    if not SKINS_JSON.exists():
        raise FileNotFoundError(f"Not found: {SKINS_JSON}")
    if not CASE_CONTENTS_JSON.exists():
        raise FileNotFoundError(f"Not found: {CASE_CONTENTS_JSON}")

    skins_backup = DATA_DIR / "skins.backup.before_dedupe.json"
    case_contents_backup = DATA_DIR / "case_contents.backup.before_dedupe.json"

    shutil.copy2(SKINS_JSON, skins_backup)
    shutil.copy2(CASE_CONTENTS_JSON, case_contents_backup)

    skins = json.loads(SKINS_JSON.read_text(encoding="utf-8"))
    case_contents = json.loads(CASE_CONTENTS_JSON.read_text(encoding="utf-8"))

    groups: dict[tuple[str, str, str], list[dict]] = defaultdict(list)
    for skin in skins:
        groups[skin_key(skin)].append(skin)

    duplicate_groups = {k: v for k, v in groups.items() if len(v) > 1}
    total_extra = sum(len(v) - 1 for v in duplicate_groups.values())

    print(f"Total skins before: {len(skins)}")
    print(f"Duplicate groups found: {len(duplicate_groups)}")
    print(f"Extra duplicate rows: {total_extra}")

    old_to_new_id: dict[str, str] = {}
    deduped_skins: list[dict] = []

    for key, group in groups.items():
        canonical = choose_canonical_skin(group)
        merged = merge_skin_data(canonical, group)
        deduped_skins.append(merged)

        canonical_id = str(merged["id"])
        for skin in group:
            old_to_new_id[str(skin["id"])] = canonical_id

    deduped_skins.sort(key=lambda s: numeric_id_value(str(s.get("id", ""))))

    rewritten_case_contents = []
    total_relinked_ids = 0

    for entry in case_contents:
        old_ids = [str(x) for x in entry.get("skinIds", [])]
        new_ids = []
        seen = set()

        for old_id in old_ids:
            new_id = old_to_new_id.get(old_id, old_id)
            if new_id != old_id:
                total_relinked_ids += 1
            if new_id not in seen:
                seen.add(new_id)
                new_ids.append(new_id)

        rewritten_case_contents.append({
            "caseId": str(entry["caseId"]),
            "skinIds": sorted(new_ids, key=numeric_id_value),
        })

    SKINS_JSON.write_text(
        json.dumps(deduped_skins, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    CASE_CONTENTS_JSON.write_text(
        json.dumps(rewritten_case_contents, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    used_skin_ids_after = {
        str(s["id"]) for s in deduped_skins
    }

    orphan_pngs = []
    if SKINS_DIR.exists():
        for png in SKINS_DIR.glob("*.png"):
            if png.stem not in used_skin_ids_after:
                orphan_pngs.append(str(png))

    print()
    print(f"Total skins after: {len(deduped_skins)}")
    print(f"Relinked skin ids inside case_contents: {total_relinked_ids}")
    print(f"Orphan PNG files left on disk: {len(orphan_pngs)}")
    print()
    print(f"Backup created: {skins_backup}")
    print(f"Backup created: {case_contents_backup}")

    if orphan_pngs:
        print()
        print("First orphan PNGs:")
        for path in orphan_pngs[:20]:
            print(f"  - {path}")

    print()
    print("Done.")


if __name__ == "__main__":
    main()