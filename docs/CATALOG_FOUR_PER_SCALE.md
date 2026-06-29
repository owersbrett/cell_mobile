# Goal — Four Games Per Scale

> **The standard:** every one of the 22 `BioScale` categories carries **at least
> 4 enabled, GAMES-complete mini-games**. No category is a ghost town; every rung
> of the zoom — from THE VOID to INFINITY — is a real, replayable place to play
> and learn.

This is a season-1 **GAMES**-objective declaration: the rubric is the gate, not a
vibe. A game counts toward the four only when it satisfies all five GAMES
criteria (Game · Agent.md · Manual/GAME.md · Education · Session) AND is wired
into `MiniGameRegistry` as an `enabled` spec.

---

## Completion gate (machine-checkable)

`test/games/four_per_scale_test.dart` — asserts every `BioScale` has **≥ 4**
enabled `MiniGameRegistry` specs. The goal is complete when **that test passes**.
The loop runs until it's green, then deploys.

---

## Current state (start of goal)

**7 / 22 categories already clear ≥4** (all built this cadence):
`farmSystem 6 · supplyChain 5 · financial 5 · planets 4 · solarSystems 4 ·
galactic 4 · cosmicStructures 4`.

**15 categories short → 41 games to build.** The biology core
(atoms → ecosystem, the heart of "Explore the Cell") is 9 scales × 3 = **27**.

---

## The build contract (every game)

- **Self-contained module:** its own folder under `lib/games/<scale>/<game>/`,
  importing only framework utils (`mini_game.dart`, `fx.dart`,
  `theme/potatuhs.dart`). Never imports another game.
- **GAMES docs in-folder:** `GAME.md` (M), `AGENT.md` (A), `EDUCATION.md` (E),
  `POTATUHS.md`.
- **Host contract:** host owns clock / 3·2·1 countdown / score HUD / results; the
  game renders only the play area, reports via `addScore`/`noteStreak`,
  auto-starts on `session.isRunning`.
- **Length — under 80 seconds.** A round must play in **< 80s**: most **60**,
  some **45**, can be **30**, even **15** for snappy reflex games. Pick the
  duration that fits the mechanic (`durationSeconds` in the spec). Enforced by the
  gate test.
- **Performance:** one Ticker → one `CustomPainter`; no per-frame `setState` over
  big trees (the black-screen/jitter guardrail).
- **The bar (all enforced):** an **education component** (E — the lesson lives in
  the mechanic, not a popup), **progressive difficulty** (it accelerates), and
  coherence (theme = mechanic = lesson). Plus the full **GAMES**: **G**ame (the
  widget) · **A**gent.md · **M**anual/GAME.md · **E**ducation.md · **S**ession
  (host-owned clean close/re-enter).
- **Variance — no two games alike.** Spread the core *verb* across the catalog so
  the player meets genuinely different play every time. Archetypes to rotate
  through: classify · sort/route · balance (keep-in-band) · time/rhythm ·
  drag-place/order · aim/trajectory · build/assemble · estimate/gauge · gesture
  (pinch/stretch/hold) · dodge/survive · resource/economy · memory · microgame
  gauntlet. Don't hand two scales the same verb in the same wave; when a scale
  only needs a "know the terms" game, prefer the shared **Vocab engine** (add a
  bank) over yet another bespoke quiz. Every game still carries **one focused
  teaching target** — a single concept it exists to teach.
- **Wiring is the orchestrator's job** (registry + catalog), so parallel game
  agents never collide on shared files.

---

## The 41 — per-scale concepts

### Physics / abstract
- **nothings** (+3):
  - **Tzimtzum** (pinch/stretch and HOLD a **constant rate** for a target time —
    the app says "pinch for 3s"; pinching too fast is penalized, too slow
    under-scores, **steady the whole way = ideal**. The primordial contraction
    that withdraws to make space for creation. Duration ~45s, several prompts).
  - **The Wait** (pure time perception in the void: a command gives a number N
    (1–10); the screen goes **black**; you must feel the seconds and **tap at N**.
    On tap the screen **flashes white** and freezes the elapsed timestamp in black
    text. **6 rounds of 10s each** (60s total), N random each round; score =
    closeness to the target time).
  - **Quantum Foam** (pop virtual particle–antiparticle pairs before they
    annihilate — energy flickering out of the vacuum).
- **somethings** (+1): **Pattern Lock** (read the rule, continue the sequence —
  emergence from simple rules).
- **particles** (+2): **Standard Model** (classify quarks / leptons / bosons) ·
  **Decay Chain** (time unstable decays, match the products).
- **atoms** (+3): **Electron Shells** (fill 2-8-8 to stabilize) · **Isotopes**
  (set protons/neutrons → name element & isotope) · **Half-Life** (time
  radioactive decay; read what remains).
- **molecular** (+3): **Bond Type** (ionic vs covalent vs metallic) · **pH
  Balance** (titrate acid/base to neutral) · **Phase Change** (heat/cool to hit
  solid / liquid / gas).

### Biology core (Explore the Cell's heart)
- **organelle** (+3): **Organelle Match** (function ↔ organelle) · **Powerhouse**
  (mitochondria: glucose + O₂ → ATP) · **Membrane Gate** (osmosis/diffusion — pass
  the right molecules).
- **cell** (+3): **Cell Type** (plant / animal / bacterial classify) · **Osmosis**
  (set tonicity; don't burst or shrivel) · **Transcribe** (DNA → mRNA → protein).
- **tissue** (+3): **Tissue Type** (epithelial / connective / muscle / nervous) ·
  **Skin Layers** (stack epidermis → dermis → hypodermis) · **Twitch** (sarcomere
  / muscle-contraction timing).
- **organ** (+3): **Organ Match** (organ ↔ function) · **Heartbeat** (route blood
  through the chambers in order) · **Nephron** (filter blood, reabsorb the good).
- **organSystem** (+3): **Digest** (order the digestive tract) · **Circulate**
  (pump blood on the correct circuit) · **Reflex** (reflex-arc timing,
  stimulus → response).
- **organism** (+3): **Life Cycle** (order the stages; metamorphosis) ·
  **Homeostasis** (balance temp / water / sugar against drift) · **Forage**
  (energy in vs out — survival economy).
- **ecosystem** (+3): **Food Web** (wire who-eats-whom / energy pyramid) ·
  **Predator–Prey** (balance populations; boom & bust) · **Nutrient Cycle**
  (route carbon / nitrogen / water).

### Cosmology / abstract
- **infinities** (+2): **Converge** (Zeno: stack ½+¼+⅛… toward the limit; tell
  convergent from divergent) · **Hilbert's Hotel** (countable infinity &
  cardinality — fit infinitely many guests).
- **multiverseAll** (+3): **Branch** (many-worlds: split timelines on choices) ·
  **Superposition** (collapse quantum states by measuring at the right moment) ·
  **Bubbles** (eternal inflation — nucleate bubble universes).
- **universeAll** (+3): **Powers of Ten** (zoom the scale ladder, order
  magnitudes) · **Cosmic Timeline** (order the epochs Big Bang → now) ·
  **Constants** (tune the fundamental constants to keep a universe habitable).

---

## Execution — the loop

A self-paced loop drives this to completion:

1. **Wire** any completed game agents into `MiniGameRegistry` + `GameCatalog`;
   keep `flutter analyze` clean.
2. **Spawn** the next wave of game agents for the remaining gap scales (per the
   concepts above) — biology core first (it's the app's heart).
3. **Re-check** the gate (`four_per_scale_test`).
4. When the gate is **green** (all 22 categories ≥4): run **`/deploy`** to push
   everything live, then **end the loop**.

`humanMax` / star thresholds are first-pass per game and flagged for a later
on-device tuning sweep — not a blocker for the count.
