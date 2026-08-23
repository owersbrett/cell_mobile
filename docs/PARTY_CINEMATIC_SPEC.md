# Party Cinematic Spec — the bar-night overhaul

> LOCKED requirements (Brett, 2026-07-06, cyummu→yumutsu). Companion to `MAPS_SPEC.md` —
> this spec fills in the ceremony/item/event systems the maps spec already assumed
> ("Most Items Used/Held", "Most Stolen-From", event/powerUp/shop spaces).
> Rules are the asset; this document outranks the implementation.

## Why this exists (the field evidence)

Real 4-person bar playtest: one player declined to play at all (declining IS feedback);
a habitual casual-game player quit after 3 rounds — "I'm over it." Diagnosed causes:

1. **No shared ceremony after a round.** Nobody saw how everyone did; no winner was
   declared; the game just moved on. ("Super lame.")
2. **No immediate interactivity layer.** Nothing was *yours* from minute one.
3. **No narrative pulse.** No opening ceremony (who's the host? how do I win? how do I
   play? how do I steer toward games I like?), no per-round flair, nothing looming.
4. **The board is illegible.** Bare nodes; shops invisible; path unclear; interaction
   is aimless drag-and-tap.
5. **Potato purchasing is opaque** even to the developer.

Every system below is an absolute requirement, not a nice-to-have.

## Engine facts this spec builds on (verified 2026-07-06)

- Turn cycle: `PartyController` loops players; after the last lands,
  `_startMiniGameRound()` fires (party_controller.dart:580, 992). `round` increments in
  `confirmMiniGameResults()` (:1131). Lengths: `kPartyRoundCounts = [7, 28, 90]`.
- A flat results screen already exists (`_MiniRoundResultsScreen`, party_page.dart:3304)
  — phase `minigameResults` is shared, so all clients already see it. It lacks any
  winner moment.
- Lockstep: player taps → `PartyInputKind` input log; all randomness via the host
  random tape (`_tape.next(n)`), replayed on clients. New mechanics add an input kind
  (APPEND-only for index stability) + tape draws. Cutscenes must be presentation-only.
- Economy today: **diamonds** (spendable), **potatoes**
  (the win), **ATP** (roll boosts), 7 `PowerUp` items, `kMaxItems = 3`.
- Roaming board entities already exist: the mischief ops (Peeler/Masher) — the ghosts
  extend this system.
- Feedback today is local-only (`RankStore`, SharedPreferences). No Firebase path.

---

## 1. Opening ceremony (REVISED 2026-07-07, Brett: yumutsu)

**VOICE LAW: "uhhh…" belongs to RUSS ALONE.** It is his catchphrase, never a
company-wide tic. Butter is smooth, earnest, never hedges, never winks. Every line in
every cutscene is written to the character profiles in
`~/Potatuhs/info/company/characters/`.

**The board carries the rules; the characters carry the personality.** The old
sequential speech-panel format (rules delivered as monologue pages) is dead. Shape:

1. **A rules board** — one always-visible panel holding ALL the information at once
   (WIN / ROUNDS / THE WHEEL rows), scannable like a manual page.
2. **A dialogue strip below it** — real character portraits (`assets/characters/`,
   the allowed raster exception) with procedural expressions (mood-driven motion +
   painted badges — `party_dialogue.dart`). Butter MCs; then the characters the
   players ACTUALLY PICKED banter back and forth, each in their profile voice.
   Banter is a pure function of the shared roster — identical on every client.

Skippable, tap-through (SKIP always visible); the last beat flows into the opening
spin (§2). Networking: client-local presentation during the opening wheel phase.

## 2. The wheel (REVISED 2026-07-07, Brett: yumutsu — STOP is now SKILL)

One wheel widget, four cadences. **STOP is a real skill input**: the segment under the
pointer at the moment of the press IS the outcome. The spinner's client passes that
segment through the lockstep log (`wheelStop`, value = segment + 1; value 0 = legacy
tape draw for old logs and autoplay), so every client replays the same landing. The
wheel spins slow enough to read (one revolution / 2.4 s), never reverses on the stop,
and eases forward ~1–2 revolutions onto the called segment — read it, time it, win it.

**After the settle, nothing auto-advances.** Butter (portrait + expression) explains
what the landed prize actually does, and the spinner drives the game forward with
CONTINUE. Results that land while a payoff is being read queue behind it. This is the
general pacing law: **the state machine never plunges the player into the next state —
every state change lands, is explained, and waits for the player to move the game
forward.**

| Spin | When | Who | Table |
|---|---|---|---|
| **Opening** | game start (with ceremony) | every player | items only |
| **Checkpoint** | every 4 rounds — rounds 5, 9, 13… | every player | middle table |
| **Winner** | after each mini-game ceremony | round winner only — **down_the_hole & through_the_aether only** (into_the_void wants less wheel) | winner table — **all-positive; a winner's spin can never deduct** (punishing the round winner disincentivizes winning) |
| **Final** | game end, before awards | every player | high-stakes table |

**Opening table (items only):** doubleDie · twinDice · freezeRay · swapper ·
voidShield · one existing power-up slot (accelerator/mitochondria class). Pool is
extensible — more items over time is the explicit intent.

**Middle table:** small diamond grants (common) · an item (sometimes) · a **bad item /
penalty** (sometimes — lose diamonds, drop a held item) · a single potato (**rare**) ·
"random" (re-draw across the whole table).

**Final table (the swing):** 1 potato · **multiple potatoes** (rare) · diamond pile ·
penalties · a protective item (feeds the "Most Items Held (final)" award).

## 3. New items (join the existing 7 PowerUps)

| Item | Effect | Notes |
|---|---|---|
| **doubleDie** | your next roll uses one die with faces 2·4·6·8·10·12 | armed like accelerator |
| **twinDice** | your next roll is 2d6 | distinct from accelerator's bonus die |
| **freezeRay** | target player's next turn is skipped (frozen visual on their token) | target choice = input value; blocked by voidShield → feeds stolenFromCount economy of aggression |
| **swapper** | swap board positions with a chosen player | target choice = input value; blocked by voidShield |

Targeted-item use is a `useItem` variant carrying a target slot. All new enum cases are
appended, never inserted.

## 4. Round ceremony (after every mini-game)

Upgrade `_MiniRoundResultsScreen` into a ceremony every player sees:

1. **Podium reveal** — staged 3rd → 2nd → 1st (portrait, name, score), escalating juice.
2. **WINNER banner** — the round has a declared winner, full-screen moment, confetti/
   glow per GAME_DESIGN's bar (procedural only). Ties: shared podium step.
3. **Deltas** — diamonds awarded, roundWins/L's tallied visibly.
4. **Winner spin** (Hole/Aether only) — the winner's wheel, everyone watches.
5. **Flair beat** (§5), then next round.

Presentation-only where possible; the winner spin is the only new shared input.

## 5. Per-round flair + the Potato Shack ghosts

**Every round gets a beat.** Short (~4–6s), auto-advancing, tap-skippable, never
disruptive. A cutscene overlay system (portrait + speech bubble, Butter/Russ voice)
driven off shared state (round number, last winner, last game) — deterministic, zero
tape draws.

- **After round 1 (the debut):** *"uhhh... did you hear that? The ghosts from the
  Potato Shack are on the loose!"* → **ghosts spawn on the board** and persist for the
  rest of the game.
- **Rounds 2+:** rotating beats — banter about the mini-game just played (name +
  winner worked into template lines), ghost sightings/escalation, map-themed teasers.
  Never the same beat twice in a row.

**Ghost behavior (extends the ops system):** roaming tokens that navigate the board
*strangely* — drift a few spaces per turn-cycle along the path, occasionally jump/
teleport (tape-drawn). A ghost sharing your landing space **steals diamonds**
(increments the victim's `stolenFromCount` — feeding the existing award), blocked by
voidShield. Visible at all times; the node viewer (§6) reports them.

## 6. Board readability + interaction model

**Visuals** (board layer of party_page.dart, procedural painters only, palette from
`potatuhs.dart`):
- Space types readable at a glance: shops as unmistakable market stalls, events as
  living "?" orbs, gain/lose as clear +/− gems, powerUps electric — not bare circles.
- **Path flow is visible**: direction cues between consecutive spaces; forks readable.
- Region theming per section; the **destination anchor (order 87) is a landmark** you
  can't miss — it is both the race target and where potatoes are bought.
- Diamonds on the path visible (they're eaten by traversal).

**Interaction:**
- **Drag = pan.** Dragging is panning mode, nothing else (InteractiveViewer stays).
- **Tap = focus.** Tapping a node clips the camera to it and opens the **node viewer**
  (upgraded `_SpaceInspector`): space type + exactly what it does, occupants (players,
  ghosts, ops), shop inventory when it's a shop, jump/fork destinations.
- **Chevron navigation from focus:** left/right steps focus node-to-node along path
  `order` (up/down or an explicit chooser at forks). The viewer is aware of every
  persistent element on the space it shows.

**Standings viewer:** accessible at any time from the board HUD — every player's
potatoes, diamonds, ATP, held items, board position/region, roundWins. Tapping a
player token = focus their node + their card in the viewer.

## 7. Post-mini-game feedback (the improvement loop)

- After the round ceremony: a one-tap, **non-blocking** "Did you like that game?"
  👍/👎 + optional short note. Skippable instantly; never gates progression.
- Skipped prompts accumulate; a **pending-feedback badge** sits on the profile avatar
  (home `_AccountButton`, and in-party) prompting review of pending games.
- Storage: RTDB `cell/feedback/<gameId>/<pushId>` →
  `{uid | 'anon', rating: up|down, note?, ts, source: party|solo}`. **Anonymous is the
  majority path** and must work. Mirrors into local RankStore. RTDB rules must permit
  anonymous pushes to this path (rules SSOT at `~/Potatuhs/.config`, `/deploy-rules`).

## 8. Build order (each chunk lands analyze-clean & deployable)

1. Round ceremony (§4, minus winner spin) — kills the lamest moment first.
2. Wheel + new items + opening ceremony (§1–§3) — includes winner spin into §4.
3. Cutscene system + ghosts (§5).
4. Board readability + node viewer + standings + purchase legibility (§6).
5. Feedback loop (§7).

Map dials live with the map: into_the_void has **no winner spins**; checkpoint cadence
(every 4) applies to all lengths (WEEK gets rounds 1-opening, 5-checkpoint, final).
