# AGENT.md — Vocab Engine (+ Finance Lingo)

> Context for an AI agent working on THIS engine. Read this and GAME.md first, then EDUCATION.md.
> Stay in scope.

---

## What this is

A **reusable, data-driven vocab engine** plus its first content bank. The engine (`VocabGame`) is
generic; it plays whatever `VocabBank` you hand it. The first bank is `kFinanceVocab` (the
`finance_vocab` / "Finance Lingo" instance). The headline rule of the whole module:

> **A new per-scale vocab game is a new `VocabBank` + a registry spec — NOT new game code.**
> Keep the engine generic. Resist baking finance-specific (or any domain-specific) logic into
> `vocab_game.dart`. Domain knowledge belongs in banks.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/vocab/`
  - Engine + models: `vocab_game.dart` (`VocabTerm`, `VocabBank`, `VocabGame` / `_VocabGameState` /
    `_BgPainter`).
  - Content banks: `vocab_banks.dart` (`kFinanceVocab`, plus any future banks).
  - Docs: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`.
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/theme/potatuhs.dart`,
  `lib/models/bio_entity.dart` — read as needed, **no edits**.
- **Do NOT touch:** `lib/games/mini_game_registry.dart`, `lib/games/game_catalog.dart`,
  `mini_game_host.dart`, any other game folder, or anything outside this folder. The orchestrator
  wires the registry/catalog. Flag registry needs here; do not make them.

---

## Scene / exit contract

- `VocabGame` is a registry mini-game driven by `MiniGameSession`.
- `widget.session.isRunning` gates the update loop — `_simulate` only runs while true; before that a
  calm ready state shows with inert options (the host overlays the countdown).
- Score via `widget.session.addScore(pts)` on each correct answer; streak high-water mark via
  `widget.session.noteStreak(streak)`.
- The game does **not** draw its own timer, intro, results, or restart — those are the host's. It
  never calls `endEarly`.
- If the game throws, the host's error boundary shows an exit fallback. Never swallow exceptions.

---

## Files

| Role | Path |
|---|---|
| Engine + models | `lib/games/vocab/vocab_game.dart` → `VocabGame`, `VocabTerm`, `VocabBank` |
| Content banks | `lib/games/vocab/vocab_banks.dart` → `kFinanceVocab` |
| Canonical spec | `lib/games/vocab/GAME.md` (rules live here — update first, then code) |
| Education | `lib/games/vocab/EDUCATION.md` |
| POTATUHS lens | `lib/games/vocab/POTATUHS.md` |
| Registry entry | `lib/games/mini_game_registry.dart` → id `finance_vocab` (OUT OF SCOPE — literal in GAME.md) |

---

## Tunable constants (current values — all in `vocab_game.dart`)

| Constant | Value | What to tune it for |
|---|---|---|
| `_kMaxPoints` | 120 | Points for an instant correct answer. Raise to reward speed harder. |
| `_kFloorPoints` | 20 | Points for a very slow (≥ decay window) correct answer. |
| `_kDecayWindowStart` | 4.0 s | Initial speed-bonus decay window. |
| `_kDecayWindowMin` | 2.0 s | Tightest the window shrinks to as the round escalates. |
| `_kDecayWindowStep` | 0.1 s | How much the window shortens per answered question. |
| `_kStreakStep` | 3 | Consecutive-correct count per +1× multiplier. Lower = more generous. |
| `_kCardDuration` | 2.4 s | Reinforcement-card dwell time before auto-advance (tap to skip). |
| `_kShakeDuration` | 0.45 s | Wrong-answer shake length. |
| `_kBurstCount` | 18 | Particles per correct-answer burst. |

Star tuning lives in the **registry spec** (`humanMax: 520`, `starThresholds: [150, 320, 520]`),
which is out of this agent's scope — flag changes for the orchestrator.

---

## Content guidelines for banks (`vocab_banks.dart`)

- Each `VocabTerm`: `term` (the correct answer), `definition` (plain-English prompt), ideally **3**
  `distractors` (plausible same-domain terms), and an optional one-line `note` for the card.
- Keep definitions **plain-English and self-contained** — a learner should be able to pick the term
  from the definition alone, without the term appearing inside its own definition.
- Distractors should be plausible: a sibling concept, a common confusion, or a near-synonym. The
  engine pads from the rest of the bank if a term supplies fewer than 3, but **always supply 3** so
  decoys stay on-topic.
- Aim for ~25–35 terms per bank so a 60 s run rarely repeats.
- Use the `note` to teach the extra beat — an example, a mnemonic, or the common mix-up.

## Adding a new scale's vocab game

1. Add a `VocabBank` to `vocab_banks.dart` (or a sibling data file that imports `vocab_game.dart`).
2. Flag the orchestrator to register a `MiniGameSpec` (new `id`/`name`/`scale`/`accent`/`icon`) whose
   `builder` is `(context, session) => VocabGame(session: session, bank: kYourBank)`.
3. That's it — no engine changes.

---

## Canvas-only rule

Background is a `CustomPainter` (`_BgPainter`): dark base, accent radial glow, two ambient blurred
orbs, deterministic star field, burst particles. **No PNG/JPEG/raster assets.** Keep it light — the
star field is deterministic precisely so `setState` doesn't shimmer it (see the codebase
black-screen render-cost lesson; do not convert to per-frame heavy subtrees).
