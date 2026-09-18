# Pixel RPG Starter Pack

Source: https://store.godotengine.org/asset/morbidember/pixel-rpg-starter-pack/

Author: MorbidEmber — support at https://ko-fi.com/morbidember

Version: v1.1 (store flags this version unstable; art-only pack, no code).

License: MIT (`MIT License.txt` in this folder). Author notes: no AI used;
not permitted for NFTs or AI training. No attribution required by the
license, but credit MorbidEmber when convenient.

## What it is

64 hand-made pixel-art item icons, each a standalone 64×64 PNG plus one
combined 512×512 `tilemap/RPG_Fantasy_Starter_Pack.png`. Art only — no
scenes, scripts, or nodes. Import `Nearest`, `Mipmaps Off` like all pixel art.

## Contents (`tiles/`, 64 files)

- **Weapons (19):** dagger, short/long sword, katana, tanto, odachi, naginata,
  bow loaded/unloaded, arrow, wood-splitting axe, labrys, lance, pike, shovel,
  pickaxe, frying pan, skuriken, kanabo, flail, mace.
- **Potions & ingredients (13):** red/blue/green potions, empty bottle,
  crystal, eyeball, roots, snowberries, feathers, magic dust, spider eggs.
- **Food & dishes (16):** chicken egg, apple, carrot, potato, wheat, rice
  panicles, cabbage, onion, red meat, codfish, blueberries, blackberry, pie
  (blueberry slice), cabbage pancake, beef stew, cod donburi.
- **Gear & loot (16):** backpack LVL 1–3, pouch LVL 1–3, book, tome, rope,
  bomb, inkwell, cauldron, chest, gold single/small pile/large pile.

## Planned uses in Blue Berry

- `blueberries_01.png` / `blackberry_01.png` → health/score pickup
  (PLAN Sprint 2 blueberry pickup).
- `potion_red_01.png` → heal drop; `chest_closed_01.png` → wave reward chest.
- `bomb_01.png` → screen-clear pickup (stretch).
- Rest: HUD inventory icons when that system lands. Keep files here and
  reference by path — do not copy into `sprites/`.
