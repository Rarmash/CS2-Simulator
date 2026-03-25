import json
import re
from collections import defaultdict
from pathlib import Path


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


def main() -> None:
    path = Path("assets/data/skins.json")
    skins = json.loads(path.read_text(encoding="utf-8"))

    groups: dict[tuple[str, str, str], list[dict]] = defaultdict(list)

    for skin in skins:
        groups[skin_key(skin)].append(skin)

    duplicate_groups = {k: v for k, v in groups.items() if len(v) > 1}

    total_duplicates = sum(len(v) - 1 for v in duplicate_groups.values())

    print(f"Total skins: {len(skins)}")
    print(f"Duplicate groups: {len(duplicate_groups)}")
    print(f"Extra duplicate records: {total_duplicates}")
    print()

    if not duplicate_groups:
        print("No duplicates found.")
        return

    for (item_kind, item_id, skin_name), items in sorted(
        duplicate_groups.items(),
        key=lambda x: (x[0][0], x[0][1], x[0][2]),
    ):
        print("=" * 80)
        print(f"Duplicate key: {item_kind} | {item_id} | {skin_name}")
        print(f"Count: {len(items)}")

        for skin in items:
            print(
                f"  id={skin.get('id')} | "
                f"name={skin.get('name')} | "
                f"rarity={skin.get('rarity')} | "
                f"collection={skin.get('collection')}"
            )

    print()
    print("Done.")


if __name__ == "__main__":
    main()