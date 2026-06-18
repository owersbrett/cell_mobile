# AGENT.md — <Game Name>

> Context for an AI agent working on THIS game. Read this first. Stay in scope.

## Scope (hard boundary)
- **Work only within:** `<this game's directory>`
- **Read-only shared kit:** `lib/games/shared/` (fx, design kit, scene host) — do NOT modify
  without explicit escalation.
- **Do not touch** other games or the host/router.

## Scene / exit contract
- This game mounts inside an isolated scene. It MUST NOT trap the player.
- Exit and timer/results are owned by the host (`MiniGameHost`) — do not reimplement them.
- If the game throws, the error boundary shows a fallback with an exit. Never swallow that.

## Files
- Widget: `<game_id>.dart`
- Spec: `GAME.md` (canonical rules — obey it; if rules change, update GAME.md first)
- Manual: `MANUAL.md`

## Tunable constants
<list the named constants and what they do>

## Known bugs / TODOs
<from the audit; keep current>

## Assets
- Canvas-drawn / procedural ONLY. No PNG/JPEG.
