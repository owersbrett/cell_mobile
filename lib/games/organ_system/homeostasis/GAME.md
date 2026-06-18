# GAME.md — Homeostasis (reworked from "System Link")

> Canonical spec for the reworked Organ-System-scale game.

- **Scale (cell):** organSystem
- **Game id:** homeostasis (replaces `system_link` / legacy `OrganSystemGame`)
- **One-line concept:** Keep a body in balance. A set of organ-system functions, each its own
  quick-time / balance challenge — all about **homeostasis** (not too much, not too little).
- **Role:** solo high-score
- **Six-in-one?** yes — **6 micro-games per round, ~10 s each (~60 s total), randomly drawn from a
  wide pool** (below). No two rounds are the same.

## The unifying idea
Organ systems exist to hold the body in **homeostasis**. So every function here is a "stay in the
zone" challenge: a target you must hover near, fail by drifting too high OR too low. The lesson is
the through-line — balance is the job.

## Structure (locked)
A round = **6 micro-games, ~10 s each**, **randomly chosen** from the pool below. Each is its own
quick-time / balance challenge; a short banner names the system, then go. WarioWare cadence.

### Potato propaganda — plant rounds are the relief
The pool mixes **intense human-body homeostasis** challenges with **easy, chill plant/potato**
rounds. When a round toggles to a **plant/potato** function, it's **deliberately easy — a breather, a
reward.** Brand beat: the human body is a frantic balancing act; the potato life is calm and good.
Aim for roughly 1 plant relief round per ~3 human rounds (tune for pacing).

## The function pool

### Human systems (intense — the core homeostasis challenges)
1. **Lungs — Respiration (rhythm).** Breathe **in/out** to a **target breaths-per-minute**; score for
   staying near it. (swipe up = inhale / down = exhale, or hold-to-inhale / release-to-exhale)
2. **Heart — Circulation (BPM).** **Double-tap = a heartbeat;** hold the required BPM. Fall out of
   rhythm → **"ARRHYTHMIA."**
3. **Stomach — Digestion (acid balance).** Food pops in; tap regions to **release acid** — enough to
   digest, **too much = damage.**
4. **Liver — Detox (scrub).** **Scrub** toxins out before they build up.
5. **Kidneys — Filtration (valve balance).** Colored fluids each have a **preferred level;** work a
   **valve** to hold each near target.
6. **Pancreas — Blood sugar.** Glucose **spikes after a meal;** release **insulin** to bring it back
   into the zone (not too much → hypoglycemia).
7. **Skin — Thermoregulation.** Temperature drifts; **sweat** when too hot, **shiver** when too cold,
   to hold the zone.
8. **Nervous — Reflex.** Signals fire down a nerve; **tap each on time** (reaction). Miss = sluggish.
9. **Immune — Defense.** Pathogens invade; **tap them out** before they multiply.
10. **Muscles — Pace.** **Alternate-tap** (L/R) to hold a steady running/pumping rhythm.
11. **Bladder — Hold & release.** Hold... then **release at the right moment** (not too early/late).
12. **Inner ear — Balance.** **Tilt/drag** to keep the body upright/centered.

### Plant / potato systems (easy — relief rounds)
- **Photosynthesis.** Just **soak up the sun** — tap drifting light. Relaxing, generous.
- **Roots — Drink.** **Catch falling water drops.** Easy.
- **Stomata — Breathe.** Gently **open/close** the leaf pores. Calm.
- **Sprout — Grow.** **Hold to grow** a sprout. Satisfying, no fail.
- **Amyloplast — Store.** **Tap to pack starch** into the tuber. Cozy.

(Build with a handful to start; the pool is designed to grow — more systems = more variety per round.)

## Scoring (homeostasis framing)
- Each function scores by **proximity to its target/zone** over time (in-zone = points/sec; drifting
  out = no points or small penalty). No hard "deaths" except the heart's arrhythmia beat-fail.
- Optional global "vitals" meter: the better you balance everything, the higher the body's health/score.

## Educational blocks engaged (resolved)
Keep BOTH realms — they map cleanly onto the two round-types:
- **Human systems** (respiratory, circulatory, digestive, hepatic, renal, endocrine, immune, …) are
  the intense core challenges.
- The existing plant organSystem blocks become the **easy relief rounds**: **Root System** → roots
  drink, **Shoot System** → photosynthesis / stomata, **Vascular System** → transport/flow,
  **Reproductive System** → sprout/grow. So the potato blocks are kept and are the calm moments.
The lesson lands either way: **every system, human or plant, is fighting to stay in balance** — the
human ones just fight harder.

## Potato angle
Light here — homeostasis is a human-body story. A plant nod is optional (a plant also balances water
via stomata/turgor). Keep the focus on the balance lesson.

## Controls
Mixed per function: in/out gesture (lungs), double-tap rhythm (heart), tap regions (stomach), scrub
(liver), drag valves (kidneys). Canvas-drawn; no raster assets.

## Session / resume
Build to the **MiniGameSession** interface (takes a session, `session.isRunning`/`addScore`) so it
slots into the registry/Explore/picker/party. Persist active function, per-function balance state, score.

## Implementation
- New widget (e.g. `HomeostasisGame`) constructed `(session)`. Registry swap (point organSystem spec
  to it; rename) is a lead follow-up after the file exists.
