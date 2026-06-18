# AGENT.md — The Nucleus

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.
> **Status: UNBUILT — build from GAME.md.**

---

## Scope (hard boundary)

- **Work only within:** `lib/games/organelle/the_nucleus/` (docs + widget)
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/mini_game.dart`,
  `lib/games/mini_game_registry.dart` — read as needed, **no edits without explicit escalation**.
- **Do not touch** other games, other scale directories, the host/router, or
  `mini_game_page.dart`.

---

## Scene / exit contract

- This game mounts inside an isolated scene managed by `MiniGameHost`.
- The host owns the session timer, results screen, and exit affordance. Do NOT reimplement
  or intercept these.
- If the game throws, the host's error boundary surfaces an exit fallback. Never swallow
  exceptions silently.
- `widget.session.isRunning` gates gameplay. Only simulate / advance game state when `isRunning`
  is true. The Transcription Flash interlude should also respect `isRunning` — pause the
  animation if the session is paused.

---

## Files

| Role | Path |
|---|---|
| Game widget (to create) | `lib/games/organelle/the_nucleus/the_nucleus.dart` → `TheNucleusGame` |
| Canonical spec | `lib/games/organelle/the_nucleus/GAME.md` (rules live here — update first) |
| Manual entry | `lib/games/organelle/the_nucleus/MANUAL.md` |
| Scale education | `lib/games/organelle/EDUCATION.md` |
| Registry entry | `lib/games/mini_game_registry.dart` → `BioScale.organelle` |

---

## Tunable constants

| Constant | Value | Effect |
|---|---|---|
| `_kCodonLength` | 10 | Base pairs per codon run. Lower = faster gratification. |
| `_kChainCap` | 4 | Maximum chain multiplier. |
| `_kSpeedMin` | 1.0 | Nucleotide drift speed multiplier at t=0. |
| `_kSpeedMax` | 2.0 | Nucleotide drift speed multiplier at t=max. |
| `_kSpawnIntervalMin` | 0.5 s | Fastest spawn rate (end of session). |
| `_kSpawnIntervalMax` | 1.2 s | Slowest spawn rate (start of session). |
| `_kWrongPenalty` | 8 | Points deducted per wrong tap. |
| `_kPairScore` | 5 | Points per correct pair (before multiplier). |
| `_kStrandBonus` | 20 | Flat bonus per completed 10-pair run. |
| `_kFlashBonus` | 15 | Flat bonus per Transcription Flash. |
| `_kFlashDuration` | 3.0 s | Duration of the transcription interlude. Do not make this skip-able. |
| `_kHitRadius` | 44 px | Tap detection radius for nucleotides. |

---

## Base-pair rule table (load-bearing educational content — do NOT alter)

```
A (Adenine)  ↔  T (Thymine)
T (Thymine)  ↔  A (Adenine)
G (Guanine)  ↔  C (Cytosine)
C (Cytosine) ↔  G (Guanine)
```

Encode this as a const map. Any pairing deviation would teach wrong biology.

---

## Visual language (Canvas-only — no PNG/JPEG)

- **Nucleotides:** hexagonal rings (~28 px wide). A = warm red `#E53935`, T = amber `#FFB300`,
  G = sky-blue `#039BE5`, C = leaf-green `#43A047`. Letter label inside the hex; full name
  below on first appearance via a brief text fade.
- **Template strand panel:** horizontal rail in the bottom third. Hollow hex slots fill in as
  pairs are placed. Active slot has a gentle pulse (scale ±4%).
- **Double helix:** two parallel sinusoidal curves with rungs drawn as bond lines between them.
  Sits in the upper half of the canvas as decoration and lights up during the Transcription Flash.
- **mRNA strand:** single sinusoidal curve, pastel tones, grows letter by letter during the flash.
- **Nuclear pore:** ring of 8 small circles (~6 px each) arranged around a 16 px opening. Draws
  inside a visible arc of the nuclear membrane on the right edge.
- **Nucleolus:** diffuse glow cluster at center-left; pulses brighter when firing a ribosome.
- **Ribosome:** small orange filled circle (~10 px) that arcs from nucleolus toward nuclear pore
  during the flash.
- **Chain multiplier badge:** top-right corner, bold text `×2` / `×3` / `×4`. Hidden at ×1.

---

## Known bugs / TODOs

- **[BUILD]** Widget does not exist yet. Build from GAME.md.
- **[BUILD]** Register on `BioScale.organelle` in `mini_game_registry.dart` after widget is ready.
- **[TODO]** WOW overlay for the Transcription Flash: surface a one-line canvas text card
  ("This mRNA instruction could be building amylose — the starch inside every potato.") 1 s after
  flash begins. Auto-dismiss at flash end. Non-scoring.

---

## Assets

Canvas-drawn / procedural ONLY. No PNG, JPEG, or raster files. All text via `TextPainter`.
