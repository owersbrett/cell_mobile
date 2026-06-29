# AGENT.md — Transcribe

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

## Scope (hard boundary)
- **Work only within:** `lib/games/cell/transcribe/` — `transcribe_game.dart` and these docs.
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/games/fx.dart`,
  `lib/theme/potatuhs.dart`. Do NOT modify them without explicit escalation.
- **Do not touch** other games, the host (`mini_game_host.dart`), the router
  (`mini_game_page.dart`), the registry (`mini_game_registry.dart`) or the catalog
  (`game_catalog.dart`) beyond a scoped, authorized task. The `MiniGameSpec` for
  this game lives in the registry; the widget lives here.

## Scene / exit contract
- Mounts inside an isolated host scene; must never trap the player.
- The host owns the clock, countdown, score readout, results and exit. This widget
  renders ONLY the play area: read `session.isRunning`, report via
  `session.addScore` / `session.noteStreak`. Never reimplement the timer/results.
- Auto-start: the Ticker always runs but the sim only advances while
  `session.isRunning`. Before running it shows a calm `READ DNA · BUILD mRNA` hint.
- If it throws, the host error boundary must still let the player exit. Don't
  swallow errors or block exit on game state.

## Architecture (performance contract)
- **One `Ticker` → one `CustomPainter`.** `_StrandPainter` draws the scrolling
  strand, the mRNA chain, the transcription bubble, particles, pops and the timing
  bar. The Flutter tree on top is tiny (legend panel, 4 base buttons, optional
  amino overlay), so per-frame `setState` is cheap. Keep it that way — no
  per-frame setState over large widget subtrees.
- Imports are limited to `mini_game.dart`, `fx.dart`, `theme/potatuhs.dart`, and
  Flutter. Stay self-contained; do not import another game's code.

## Files
- Widget: `transcribe_game.dart` → `TranscribeGame`
- Spec: `GAME.md` (canonical rules — change rules THERE first, then code)
- Education: `EDUCATION.md`
- POTATUHS lens: `POTATUHS.md`
- Scale education ledger: `lib/games/cell/EDUCATION.md`

## Tunable constants (current implementation)
- `_kAccent = 0xFF18C99A` — strand mint-green.
- `_kSpacing = 60` — px between bases on the track.
- `_kBaseR = 22` — base orb radius.
- `_currentBaseTime()` — per-base timer ramps `3.0 → ~1.1s` over the 60s round.
- `_codonStage` gate — `_elapsed > 20 || _codonsDone >= 4`.
- Scoring — correct `5 × _mult`; clean codon `+15`; amino match `+20`; break `−4`.
- `_mult = (1 + _streak ~/ 5).clamp(1, 6)`.

## Invariants / gotchas
- `_codonTable` is the full standard genetic code (64 codons → 3-letter symbols).
  mRNA codons are read 5'→3' from the order bases were transcribed.
- The amino-match overlay is BONUS only — a wrong pick never penalizes; it reveals
  the answer (education). Core scoring comes from the always-fair pairing loop.
- A broken base still consumes a codon slot (`'-'`), which voids that codon — keep
  that, it mirrors a real frameshift-style failure.

## Known TODOs
- No high-score / resume persistence (host handles session lifecycle today).
- Codon stage amino choices are random distractors; could weight by amino family
  for a gentler learning curve.
