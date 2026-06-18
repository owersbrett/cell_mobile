# AGENT.md — Big Bang

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

## Scope (hard boundary)
- **Work only within:** this game's code + docs. **What Explore shows for nothings is
  `lib/games/arcade/big_bang_arcade.dart` (`BigBangArcade`)** — the registry intercepts before the
  legacy switch, so the legacy `big_bang_game.dart` (`BigBangGame`) is dead code for nothings.
  Docs live at `lib/games/nothings/big_bang/`. The light-collection redesign (GAME.md) supersedes
  both; the arcade tap-base is the closer starting point.
- **Read-only shared kit:** `lib/games/` fx/design helpers, `lib/theme/potatuhs.dart` — do NOT
  modify without explicit escalation.
- **Do not touch** other games, the router (`mini_game_page.dart` `_buildGame`), or
  `mini_game_registry.dart` beyond what a scoped task explicitly authorizes.

## Scene / exit contract
- Mounts inside an isolated scene; must never trap the player.
- If it throws, the scene's error boundary must still let the player exit and continue the
  session. Do not swallow errors or block exit on game state.
- Timer/results/exit are host-owned — don't reimplement them.

## Files
- Widget (current): `lib/views/screens/mini_game_page/games/big_bang_game.dart` → `BigBangGame`
- Spec: `GAME.md` (canonical rules — obey it; change rules there FIRST)
- Manual: `MANUAL.md`
- Education ledger (scale): `lib/games/nothings/EDUCATION.md`

## Tunable constants (current implementation)
- `_timeRemaining = 22.0` — starting clock (seconds)
- `_growRate = 95.0` — bubble grow speed (px/s); hard ceiling ~200 px radius
- `_kElements` thresholds: `10/25/44/68/96/130/170/215/270` (H→He→Li→C→N→O→Ne→Si→**Fe**)
- Win at matterProgress **270** (Iron)
- Spawn interval `2.0 → 0.45 s`, drift `40 → 100 px/s`, life `7.0 → 3.5 s` over ~30 s
- Spawn mix: normal 45%, chain 25%, antimatter 18%, time 12%
- Scoring: size match 1/2/5 pts (>18% / <18% / <6%); antimatter −5 pts/−2 s; expiry −1.5 s

## Known bugs / TODOs
- `_secondLastHitPos` (and `_secondLastHitTime`) tracked but `_secondLastHitPos` never read — dead.
- **No high-score persistence** and **no drop/resume persistence** — GAME.md requires resume.
- No audio hooks (project is Canvas/visual-first; fine, but note for parity).
- **Consolidation decision pending:** legacy `BigBangGame` vs registry `BigBangArcade`
  (`lib/games/arcade/big_bang_arcade.dart`). See GAME.md "Open decision." Do not delete either
  until Brett confirms the canonical one.
- **Migration TODO:** move the widget under `lib/games/nothings/big_bang/big_bang.dart` and
  update the router; deferred (touches shared routing — escalate first).

## Assets
- Canvas-drawn / procedural ONLY. Particle bursts, shockwave ripples, starfield, periodic-symbol
  element flashes. No PNG/JPEG.
