# Crop Rotation — Manual (M)

**Scale:** BioScale.farmSystem · **Spec id:** `crop_rotation` · **Duration:** 60s
**Score unit:** harvest

## Premise
You run a farm across many short seasons. Each season you assign crops to your
fields and **GROW** them. Crops belong to four **families**, and the soil
remembers what you planted. Rotate families well and harvests stay rich; plant
the same family twice in a row (monoculture) and yield + soil crash while pests
build. **Score = total harvest yield banked across all seasons.**

## The loop (one season)
1. **Pick a crop** — tap a card in the bottom tray. It becomes your "held" crop
   (highlighted). Plantable fields glow gold.
2. **Plant fields** — tap any field to plant the held crop there. Tap a planted
   field with an empty hand to clear it. Switch held crops anytime.
3. **GROW SEASON** — tap the big button. Every planted field is harvested at
   once; the soil and pest levels update; a new season begins. The button
   pulses once every field is planted.

Fields left empty lie **fallow**: no harvest, but soil rests (+nitrogen) and
pests fade — a deliberate recovery move.

## Crop families
| Crop | Family | Soil nitrogen | Notes |
|------|--------|---------------|-------|
| **Beans** | Legume | **+ restores** (nitrogen-fixing) | Modest yield; reloads the soil bar |
| **Corn** | Heavy Feeder (cereal) | **−− drains hard** | Huge ceiling, but only on rich soil |
| **Potatoes** | Root | − drains a little | **Breaks pest/disease cycles** |
| **Cabbage** | Brassica | − moderate | Steady all-rounder |

## Soil & yield rules
- **Nitrogen bar** (per field, bottom edge): green = rich, red = drained. Corn's
  yield scales heavily with it; legumes barely care.
- **Monoculture penalty:** repeating a family on a field cuts yield (×0.55,
  compounding each repeat), drains extra nitrogen, and spikes pests.
- **Rotation bonus:** planting a different family than last season keeps yield
  high (+12%) and eases pest pressure.
- **Pests & disease:** build up in repeated/continuous cropping (red bug ticks),
  and shave the harvest. **Roots reset them hard**; any rotation softens them.
- **Clean Rotation bonus:** a season with crops planted and zero monoculture
  grows a rotation streak and pays an escalating bonus.

## How to win
**Most total harvest yield when the 60s timer ends wins.** Plant fast, rotate
families, and use legumes/fallow to recover soil before planting heavy feeders.

## Accelerate
More fields unlock as seasons clear (4 → 6 → 8), monoculture crashes get
harsher, and pest/disease pressure ramps with the season level.

## Session (S)
Host-owned: the run auto-starts on `session.isRunning`, shows a calm "ready"
farm before the countdown, ends at 60s, and a fresh run re-enters cleanly via
`session.hostReset()`. The game keeps no state outside the widget.
