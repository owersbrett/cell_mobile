# AGENT.md — Whose Idea?

> Context for an AI agent working on THIS game. Read this and GAME.md first, then EDUCATION.md.
> Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/somethings/whose_idea/`
  - Game code: `whose_idea_game.dart` (`WhoseIdeaGame` / `_WhoseIdeaGameState` / `_BgPainter`)
  - Question bank: `whose_idea_data.dart` (`IdeaField`, `IdeaQuestion`, `kWhoseIdeaBank`)
  - Docs: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/mini_game.dart`,
  `lib/models/bio_entity.dart` — read as needed, **no edits**.
- **Do NOT touch:** `lib/games/mini_game_registry.dart`, `lib/games/game_catalog.dart`, any other
  game folder, `mini_game_page.dart`, or anything outside this folder. The orchestrator wires the
  registry/catalog. Flag registry needs here; do not make them.

---

## Scene / exit contract

- `WhoseIdeaGame` is a registry mini-game driven by `MiniGameSession`.
- `widget.session.isRunning` gates the update loop — `_simulate` only runs while true; before that a
  calm ready/disclaimer state shows with inert options (the host overlays the countdown).
- Score is reported via `widget.session.addScore(pts)` on each correct answer; the streak
  high-water mark via `widget.session.noteStreak(streak)`.
- The game does **not** draw its own timer, score HUD chrome beyond the in-field readout, intro,
  results, or restart — those are the host's. It never calls `endEarly`.
- If the game throws, the host's error boundary shows an exit fallback. Never swallow exceptions.

---

## ⚠️ The attribution disclaimer is non-negotiable

Brett's explicit requirement: every attribution is **accepted, recorded history** — "history is
written by the winners" — **not** a claim of sole/first origination. This MUST stay visible:
1. The **ready-state card** (`_buildReadyState`) states it before play.
2. The **persistent footer** (`_buildDisclaimerFooter`) states it during play.
3. `GAME.md` and `EDUCATION.md` carry the full framing.

Do not remove or weaken any of these. When adding bank items, keep attributions to **widely-taught,
mainstream** credit, and use the `context` field to flag genuine disputes (it's the in-game place
where "the winners wrote it down" gets made honest).

---

## Files

| Role | Path |
|---|---|
| Game widget | `lib/games/somethings/whose_idea/whose_idea_game.dart` → `WhoseIdeaGame` |
| Question bank | `lib/games/somethings/whose_idea/whose_idea_data.dart` → `kWhoseIdeaBank` |
| Canonical spec | `lib/games/somethings/whose_idea/GAME.md` (rules live here — update first, then code) |
| Education | `lib/games/somethings/whose_idea/EDUCATION.md` |
| POTATUHS lens | `lib/games/somethings/whose_idea/POTATUHS.md` |
| Registry entry | `lib/games/mini_game_registry.dart` → id `whose_idea` (OUT OF SCOPE — see GAME.md for the literal) |

---

## Tunable constants (current values — all in `whose_idea_game.dart`)

| Constant | Value | What to tune it for |
|---|---|---|
| `_kMaxPoints` | 120 | Points for an instant correct answer. Raise to reward speed harder. |
| `_kFloorPoints` | 20 | Points for a very slow (≥ decay window) correct answer. |
| `_kDecayWindow` | 4.0 s | How long the speed bonus takes to decay max→floor. |
| `_kStreakStep` | 3 | Consecutive-correct count per +1× multiplier. Lower = more generous streaks. |
| `_kFactFlareDuration` | 2.4 s | Context-card dwell time before auto-advance (tap to skip). |
| `_kShakeDuration` | 0.45 s | Wrong-answer shake length. |
| `_kBurstCount` | 18 | Particles per correct-answer burst. |

Star tuning lives in the **registry spec** (`humanMax: 520`, `starThresholds: [150, 320, 520]`),
which is out of this agent's scope — flag changes for the orchestrator.

---

## Content guidelines for the bank (`whose_idea_data.dart`)

- Each `IdeaQuestion`: `field`, `idea` (prompt), `thinker` (correct), exactly **3** `distractors`
  (same broad field/era so it's not trivial), `era` (short tag), `context` (one line).
- Six fields exist (`IdeaField`): science, philosophy, mathematics, economics, politics, psychology.
  Each maps to a color/icon chip in `_kFieldStyles`. Adding a new field means adding a `_FieldStyle`.
- Keep ideas **historical big-ideas**, mainstream and widely taught — not niche or hyper-technical.
- Distractors should be plausible: a contemporary, a rival, or a thinker the idea is sometimes
  mis-credited to. Avoid anachronistic or absurd options.
- Prefer items where the `context` can teach something — especially contested credit, which is the
  game's thesis.

---

## Known TODOs / ideas (priority order)

1. **[LOW] Field balance.** The bank leans science/philosophy. Consider topping up economics and
   political theory so a 60 s run feels varied across fields.
2. **[LOW] Per-question speed bar.** There's no visible speed-bonus meter (the bonus decays
   silently). A thin shrinking bar under the prompt could make the speed incentive legible — keep
   it a small widget on the existing ticker, not a new 60fps subtree (see the codebase black-screen
   render-cost lesson).
3. **[INFO] Single `Ticker` + per-frame `setState`** mirrors Organ Rush and is fine for a discrete
   quiz (light subtree). Do not convert the whole thing to per-frame heavy rebuilds.

---

## Canvas-only rule

Background is a `CustomPainter` (`_BgPainter`): dark base, field-colored radial glow, two ambient
blurred orbs, deterministic star field, burst particles. **No PNG/JPEG/raster assets.** Keep it
light — the star field is deterministic precisely so `setState` doesn't shimmer it.
