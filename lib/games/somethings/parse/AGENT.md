# AGENT.md — Parse

> Context for an AI agent working on THIS game. Read this first. Stay in scope.

## Scope (hard boundary)
- **Work only within:** `lib/games/somethings/parse/`
  (`parse_game.dart`, `parse_data.dart`, and these docs).
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/mini_game.dart`
  — do NOT modify without explicit escalation.
- **Do not touch** other games, `mini_game_registry.dart`, `game_catalog.dart`,
  or the host/router. Registry/catalog wiring is the orchestrator's job.

## Module contract
- Public surface is exactly:
  `class ParseGame extends StatefulWidget { final MiniGameSession session; const ParseGame({super.key, required this.session}); }`
  plus `final List<LegendFrame> parseLegendFrames`.
- Imports allowed: `package:flutter/*`, `dart:math`, `../../mini_game.dart`,
  `../../../theme/potatuhs.dart`, `./parse_data.dart`. **Never** import another
  game's code.
- ONE `Ticker` drives ONE `CustomPainter` (background motes, particles, the
  card-timer bar, the fail flash) via a `ValueNotifier` repaint, behind a
  `RepaintBoundary`. The widget tree (HUD/card/chips) rebuilds on DISCRETE
  events only — never per tick. (The one exception: a short, event-triggered
  `AnimationController` for the fail shake — see Judgment calls.)
- The host owns clock/countdown/score/results. Gate all play on
  `session.isRunning`. Report via `session.addScore` and `session.noteStreak`.
  Never call `endEarly` — the game is always quittable via the host.

## Scene / exit contract
- Mounts inside an isolated scene; MUST NOT trap the player. If it throws, the
  global `ErrorWidget.builder` shows a fallback with an exit — never swallow it.

## Educational invariant (do not break)
The teaching lives IN the mechanic: the same construct wears different syntax
across languages, and the answer is the construct, not the language. Keep the
`tricky` snippets honest — the label must be the genuinely correct construct
(arrow/lambda = FUNCTION, Swift `protocol` / Python `Protocol` = INTERFACE,
`require(...)` = IMPORT, `class C(Enum)` = ENUM) and the `note` must explain the
tell. If you add snippets, keep them SHORT (1–4 lines), real, and idiomatic, and
keep ≥8 per construct spread across languages.

## Font exception (justified)
Code text uses `fontFamily: 'monospace'` with
`fontFamilyFallback: ['Menlo','Consolas','Roboto Mono']` — the ONE sanctioned
deviation from the Potatuhs fonts, for code legibility. ALL UI chrome (HUD,
chips, labels, captions) uses `Potatuhs.display/body/label`. Colours come from
`Potatuhs.*` or the small brand-adjacent code palette (`_kCode*`). No random hex.

## Tunable constants (in `parse_game.dart`)
- Scoring: `_kMaxPoints`, `_kFloorPoints`, `_kDecayWindow`, `_kStreakStep`.
- Reveal: `_kRevealCorrect`, `_kRevealWrong`, `_kShakeDuration`.
- Escalation: `_phaseFor` thresholds, `_kCardLimitStart`, `_kCardLimitEnd`,
  `_kRecentMemory`.
- Data: the snippet bank + `_kKeywords` tinter set live in `parse_data.dart` /
  `parse_game.dart`.

## Invariants to preserve
- `flutter analyze lib/games/somethings/parse/` → **zero** issues.
- The correct construct is ALWAYS present in the current chip set (phase
  restricts snippet constructs to what the chips can express).
- `parseLegendFrames` has ≥2 frames (currently 4) drawn with the game's OWN
  render vocabulary.

## Known bugs / TODOs
- `humanMax` (3200) and `starThresholds` ([900,1800,2900]) are first-pass —
  retune from real playtest data.
- Consider a "cheese" beat: reward a player who spots that the language chip is a
  red herring (they can ignore it entirely) once, in the company voice.
- Possible next pass: a 4th tier of constructs (TYPE ALIAS, DECORATOR).

## Assets
- Canvas-drawn / procedural + widgets ONLY. No PNG/JPEG.
