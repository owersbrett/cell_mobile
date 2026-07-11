# Say What? — Agent (A)

You are the dedicated agent for the **Say What?** mini-game
(`lib/games/somethings/say_what/say_what_game.dart`). You own this game's
design, content bank, balance and polish. Do not touch other games, the
registry, the catalog, or the host — coordinate those edits through the
orchestrator.

## Module contract
- Public surface is exactly:
  `class SayWhatGame extends StatefulWidget { final MiniGameSession session; const SayWhatGame({super.key, required this.session}); }`
  plus the exported `List<LegendFrame> sayWhatLegendFrames` (the visual manual)
  and the content types (`SayWhatItem`, `kSayWhatBank`, the enums).
- Imports allowed: `package:flutter/*`, `dart:math`, `../../mini_game.dart`,
  `../../../theme/potatuhs.dart`. **Never** import another game's code.
- One `Ticker` → one `CustomPainter` (`_BgPainter`) for continuous motion.
  `setState` fires once per tick to reflect timers; the moving background +
  particles live on the painter, not in per-frame widget rebuilds.
- The host owns clock/countdown/score/results. Gate all play on
  `session.isRunning`. Report via `session.addScore` and `session.noteStreak`;
  never call `endEarly` (there is no fail state — the clock ends the round).

## Content invariant (do not break)
Every `SayWhatItem` must be **decodable by ear**: read `sounds` out loud and it
must plausibly land on `answer`, while the three `distractors` are near-misses
(look-alike spellings or wrong parses) — never nonsense. Tag `difficulty`
honestly (easy = short/obvious, hard = long/multi-word or subtle). Pig-latin
items carry `kind: SayWhatKind.pigLatin` and are drawn only on the special
round; keep at least a few in the bank. The correct answer is `options.first`;
the game shuffles before showing.

## Balance knobs
- `_kBaseDecay` / `_kMinDecay` — the read window (shrinks with round progress).
- `_drawRegular` "heat" = `progress + streak/12` — the difficulty ramp.
- `_kPigLatinEvery` — pig-latin cadence (every 5 correct).
- Pig-latin `+30` variety bonus; `_kMaxPoints` / `_kFloorPoints` speed band.
- `humanMax` / `starThresholds` live in the registry spec — tune from playtest.

## Invariants to preserve
- `flutter analyze lib/games/somethings/say_what/` → **zero** issues.
- No raster assets; procedural Canvas + Flutter widgets only.
- Palette + fonts from `lib/theme/potatuhs.dart` (no random hex, no `'Avenir'`).
- ATTRACT autopilot (`_autoStep`) taps the correct answer at a human pace
  (`autoPilotInterval ~1.15s`) so the demo is watchable, not superhuman.

## Good next passes
- Grow the bank (target 80–100), spread across all five `SayWhatKind`s.
- A "double-take" hard tier where two distractors are *also* valid readings.
- Regional/accent packs (British vs. American homophones) as a themed sub-bank.
- Tune `humanMax` / `starThresholds` from real playtest data.
