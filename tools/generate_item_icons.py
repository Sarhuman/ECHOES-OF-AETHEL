"""Own 64px vector placeholders. No downloaded art or proprietary game assets."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / "src/items/item_catalog.gd").read_text(encoding="utf-8")
items = {}
for match in re.finditer(r'"id":"(\w+)"', source):
    key = match.group(1)
    line = source[match.end():].splitlines()[0]
    slot = re.search(r'"slot":"(\w+)"', line)
    items[key] = slot.group(1) if slot else ("potion" if key.startswith(("hp_", "mana_")) else "material")
items.update(ether_ring="ring", worn_charm="charm")
for key in ("bronze_shard", "worn_fabric", "stone_dust"): items[key] = "material"
for key in ("quest_seal", "vigil_letter", "annotated_map"): items[key] = "quest"
out = ROOT / "assets/items/icons"
out.mkdir(parents=True, exist_ok=True)
manifest = []
for index, (key, slot) in enumerate(sorted(items.items())):
    n = index % 7
    if slot == "weapon":
        category = "weapons"
        if "sword" in key:
            shape = f'<path d="M32 8L{37+n} 22L34 42H39V46H34V57H29V46H24V42H29L27 22Z"/>'
        elif "mace" in key or "flail" in key:
            shape = f'<path d="M29 28V56H34V28M23 12L{37+n} 10L43 23L34 32L23 27Z"/>'
        else:
            shape = f'<path d="M28 11H33V57H28ZM33 13Q{51+n} 9 49 34L33 29ZM28 16L17 11V31L28 28"/>'
    elif slot in ("helm", "armor", "gloves", "boots", "cape", "shield", "belt"):
        category = "armor"
        shapes = {
            "helm": '<path d="M15 42V27Q17 10 32 10Q47 10 49 27V42L37 49V29H27V49ZM16 25H48M32 11V26"/>',
            "armor": '<path d="M20 12L27 17H37L44 12L54 24L45 31L43 53H21L19 31L10 24ZM27 17L32 30L37 17M23 45H41"/>',
            "gloves": '<path d="M19 54V31L13 23L18 19L24 27V12H29V25H31V9H36V25H38V13H43V29H45V20H50V37L42 54Z"/>',
            "boots": '<path d="M19 10H39L37 37L51 45V54H15V45L20 37ZM19 20H38M18 47H49"/>',
            "cape": '<path d="M25 10H39L49 55L32 49L15 55ZM25 10L32 21L39 10M32 21V46"/>',
            "shield": '<path d="M13 14L32 8L51 14V35Q48 48 32 57Q16 48 13 35ZM20 20L32 16L44 20V34L32 47L20 34Z"/>',
            "belt": '<path d="M8 24H56V40H8ZM26 20H39V44H26ZM30 29H35V35H30"/>',
        }
        shape = shapes[slot]
    elif slot in ("ring", "amulet", "charm"):
        category = "accessories"
        shape = f'<circle cx="32" cy="35" r="{16+n%3}"/><path d="M24 18L32 9L40 18L32 27ZM32 14V22"/>'
        if slot != "ring": shape += '<path d="M15 10Q10 46 24 52L32 59L40 52Q54 46 49 10M24 52L32 40L40 52"/>'
    elif slot == "potion":
        category = "potions"
        shape = f'<path d="M25 9H39V16H37V25Q{51+n} 33 48 49Q45 57 32 57Q19 57 16 49Q13 33 27 25V16H25ZM19 40H45M25 13H39"/>'
    elif slot == "quest":
        category = "quest"
        shape = f'<path d="M17 9H43L49 16V55H17ZM43 9V18H49M23 25H41M23 31H{36+n}M23 37H40M26 47L32 41L38 47L32 53Z"/>'
    else:
        category = "materials"
        shape = f'<path d="M11 39L23 {13+n}L39 11L54 32L44 53L23 55ZM23 18L28 34L39 11M28 34L44 53M28 34L12 39M28 34L54 32"/>'
    accent = "#AE4149" if key.startswith("hp_") else ("#597DB5" if key.startswith("mana_") else "#B8A058")
    # Small authored marks distinguish bases within each family without text sprites.
    marks = "".join(f'<path d="M{9+j*6} 61h3"/>' for j in range(index % 6 + 1))
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64"><title>{key} — original placeholder</title><rect width="64" height="64" rx="4" fill="#0B0A08"/><g fill="#282219" stroke="{accent}" stroke-width="2" stroke-linejoin="round">{shape}{marks}</g><path d="M4 15V4H15" fill="none" stroke="#5C4F3C"/></svg>\n'
    (out / (key + ".svg")).write_text(svg, encoding="utf-8")
    manifest.append({"id": key, "category": category, "placeholder": True, "size": 64})
lines = ["class_name AethelItemIcons", "extends RefCounted", "# Generated whitelist; external IDs cannot become resource paths.", "const TEXTURES := {"]
for key in sorted(items): lines.append(f' "{key}": preload("res://assets/items/icons/{key}.svg"),')
lines.append("}\n")
(ROOT / "src/items/item_icons.gd").write_text("\n".join(lines), encoding="utf-8")
(out / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
assert len(manifest) >= 30 and len({row["category"] for row in manifest}) == 6
print(f"Generated {len(manifest)} original vector placeholders in six categories")
