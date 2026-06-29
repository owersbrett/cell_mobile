# AGENT.md — Transcribe v2

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/cell/transcribe_v2/` — the widget
  (`transcribe_v2_game.dart` → `TranscribeV2Game` / `_TranscribeV2GameState` / `_StrandPainter`) and
  these docs (GAME.md, AGENT.md, EDUCATION.md, POTATUHS.md).
- **Read-only shared kit:** `lib/games/mini_game.dart` (`MiniGameSession`), `lib/games/fx.dart`
  (`GameFx`, `FxParticle`, `FxBurst`, `FxPop`), `lib/theme/potatuhs.dart`. No edits without escalation.
- **Do not touch** other games, other scales, `mini_game_registry.dart`, `game_catalog.dart`,
  `mini_game_host.dart`, or `mini_game_page.dart`. (The orchestrator wires the registry/catalog.)

---

## Why this game exists

It is the **UX-refined alternative** to `transcribe`, built to the teardown brief in
`docs/ux_pass/teardowns/transcribe.md`. It ships **alongside** the original (coexist-then-judge). The
original's failures it fixes:

1. **Two timed tasks fought for one thumb** — the amino overlay popped as a second tappable layer while
   the base countdown kept draining below (double jeopardy). → Closing a codon now **PAUSES the base
   bar** and the SAME bottom bank **morphs** into the amino choices. The translate has its own soft
   timer that gates only the translate bonus and **never** the base streak. Do **not** reintroduce a
   simultaneous overlay or a draining base timer during translate.
2. **Runaway snowball (×6 mult + +20)** — uncatchable lead, illegible standing. → Streak multiplier
   **capped ×3**; codon/translate bonuses are flat and trailing-player-bankable. Do **not** uncap it.
3. **Vertical eye-travel killed the <3s read** — legend top, action middle, buttons bottom. → The active
   read-zone is dropped **low, right above the bank**; the ghost wears a complement-coloured pairing
   ring that fades with mastery. Keep the read-zone compressed.
4. **No climax** → FINAL TRANSCRIPTION surge (last 10s, faster, ×2) + a **PROTEIN ASSEMBLED** end
   reveal. Keep both.
5. **Zero audio** → haptic snaps (`_haptic`) carry the beat (the kit has no audio engine). Keep them.

The **education is preserved verbatim**: the A→U/T→A/C→G/G→C pairing with **U-replaces-T**, the full
64-entry `_codonTable` (Stop codons included), and the "every 3 clean bases = a codon = an amino acid"
assembly. Don't simplify the genetic code to chase feel.

---

## Dependency rule (from EXTRACTION_RECIPE.md)

Imports **only** `dart:math`, `package:flutter/material.dart`, `package:flutter/scheduler.dart`,
`package:flutter/services.dart` (haptics), `../../mini_game.dart`, `../../fx.dart`, and
`../../../theme/potatuhs.dart`. No external symbols, no dependency on any other game. Keep it that way.

---

## Scene / exit contract

- `TranscribeV2Game` takes a `MiniGameSession` and is fully host-driven.
- `widget.session.isRunning` gates the sim. When false it shows a calm ready strand + READ DNA · BUILD
  mRNA hint; it auto-runs (`_resetForPlay`) when the host flips `isRunning`.
- One end flourish (`_showEnd`) fires the first frame `session.phase == finished` (PROTEIN ASSEMBLED
  reveal + gold burst).
- Scores via `widget.session.addScore(n)`; streak high-water via `widget.session.noteStreak(...)`. It
  never calls `endEarly`.
- The host owns the 60s clock, countdown, score HUD, opponents and results. The game renders only the
  play area (never a results/restart screen). If it throws, the host error boundary catches it.

---

## Performance contract

- **One `Ticker` → one `CustomPainter` (via the `_Repaint` notifier) → NO per-frame `setState`.** The
  build is a single `GestureDetector` wrapping one `CustomPaint` under a `RepaintBoundary`; the painter
  repaints off the `repaint` pump reading live state. Taps mutate fields; the next ticked frame shows
  them. `shouldRepaint` returns `false` (repaint is driven by the listenable, not delegate diffing).
- The four base buttons and the amino choices are **drawn in the painter** and hit-tested by
  `_baseBtnRect` / `_aminoBtnRect` (same geometry the painter draws) — no widget-tree buttons.
- `dt` clamped to `0.05 s` so a stutter can't drain the bar in one frame.

---

## Tunable constants

| Constant / getter | Value | Tune for |
|---|---|---|
| base correct points | `6 × mult` | Per-base reward. |
| `mult` cap | `3` | Streak multiplier CAP. **Keep capped** (anti-runaway). |
| streak step | every `4` | Correct-in-a-row per `+1×`. |
| `_currentBaseTime` | `2.6s → 1.0s` | Base timer ramp, early → late. |
| codon bonus | `+8` | Closing a clean codon. |
| translate bonus | `+24` | Correct amino pick. |
| `_translateT` | `3.4s` | Soft translate timer (bonus only, never base streak). |
| `_interactiveTranslate` | `_codonsDone >= 2` | First 2 codons auto-reveal, then interactive. |
| `_kSurgeAt` | `10.0` | Seconds-remaining the FINAL TRANSCRIPTION climax begins. |
| `scaffoldAlpha` | `1.0 → 0.12` | Pairing-ring scaffold fade by progress. |

---

## Known TODOs

1. **[LOW] Star thresholds are a first estimate** (`[400, 850, 1300]`, `humanMax 1400`). Re-tune from
   playtests.
2. **[LOW] Drop-and-resume not persisted** — strand/codon/protein reset on mount.
3. **[INFO] `shouldRepaint` returns false** — correct; the painter repaints via the `_Repaint`
   listenable.

---

## Canvas-only rule

All rendering is `CustomPainter` via `GameFx` + raw `Canvas`. **No PNG/JPEG/raster assets.** The painter
draws: `GameFx.atmosphere`, the always-on pairing legend, the HUD (mult/streak/codon dots), the DNA +
mRNA rails, the trailing chain, the active read-zone (base orb + complement-tinted ghost ring + timing
bar), the protein strip, the canvas button bank (bases OR amino choices), the surge vignette + banner,
the PROTEIN ASSEMBLED end reveal, and `FxBurst`/`FxPop` juice.
