# membrane_gate — UX Teardown
scale: organelle · duration: 60s · scoreUnit: molecules
## Scores (1–5)  → TOTAL: 21/35
- Instant legibility: 2 — 12 molecule types (7 wanted / 5 unwanted) to discriminate by 8.5px labels (`GameFx.text(... 8.5 ...)` line 582) and abstract glyphs; the killer is color collision — Toxin is green `0xFF8BC34A` (line 88) sitting right next to Na⁺ green `0xFFAED581` (line 77), so the eye cannot pre-attentively sort good from bad.
- Affordance clarity: 3 — single verb (`onTapUp`, line 263) reads as a tap game, but the core mechanic is *restraint* (don't-tap), which no affordance teaches; taps below `_membraneY` silently no-op (line 266) with zero feedback.
- Juice & feedback: 4 — genuinely rich and within budget: one `Ticker`→one `CustomPainter` via `_RepaintNotifier`, particle slurp (lines 293–300), `_channelGlow` protein lighting, gold `_thrive` nucleus pulse, red `_flash` toxin overlay, vitality-driven cytoplasm. Loses a point: zero audio (rubric is audio-visual) and `_paintReady` is the only onboarding.
- Fair/readable competition: 2 — the live score is NEVER drawn in-widget; `_paintHud` only shows a streak pill and only when `_streak >= 5` (line 667). Relies entirely on host chrome, scores can go negative (`addScore(-_kToxinPenalty)`), and there is no catch-up/rubber-band — a hot streak (×3) snowballs unbounded vs a cold player. Pure parallel solo score-attack, fine for pass-and-play but standing is illegible mid-round.
- Skill depth: 3 — discrimination + timing + restraint is a real loop, mimic share rises (`wantedShare` lerp 0.62→0.46, line 228), but the mastery payoff is capped hard: `_mult = (1 + _streak ~/ 5).clamp(1, 3)` (line 144) flatlines at ×3 after a 10-streak, so there's nothing to chase past ~15s of clean play.
- Pace & climax: 3 — three knobs accelerate honestly on `_progress` (spawn 1.05→0.42s, fall 74→184px/s), but there is NO finish event: no final-10s frenzy, no klaxon, no last-molecule flourish — the clock just stops. It ramps but doesn't climax.
- Polish: 4 — strongly on-brand cytoplasm/membrane (Potatuhs orange heads, sienna tails, gold nucleus), custom per-molecule glyphs, clean perf (`shouldRepaint => false` + repaint listenable). Dinged by the same-hue molecule palette that fights the brand-vs-readability line.

## Top 2–3 UX failures (concrete, cite the mechanic)
1. No on-screen score. `_paintHud` (lines 666–691) paints a streak pill only, gated on `_streak >= 5`. In a party/pass-and-play context players cannot see their own running total or each other's, so "who's winning" is invisible until the host results screen — fatal for live competition.
2. Color-collision discrimination. Wanted Na⁺ (`0xFFAED581`) and unwanted Toxin (`0xFF8BC34A`) are both saturated greens (lines 77, 88); Heavy metal grey vs CO₂ grey similarly. The go/no-go decision is forced onto 8.5px text labels under fast descent — the game's central skill is bottlenecked on reading, not perception.
3. Restraint has no affordance and the punish is asymmetric/quiet. Letting a wanted molecule starve only resets streak with a faint `'missed'` pop (line 250) — no score loss, no urgency — so the optimal-but-unfun strategy is to spam-tap nothing risky. Meanwhile the "don't tap" rule is never demonstrated, only stated in `_paintReady` text.

## Redesign brief — what membrane_gate_v2 MUST change to clear the bar
- Draw a large live score + a slim opponent/par marker in-widget; never depend on host chrome for the number that decides the game.
- Re-key wanted vs unwanted on a pre-attentive channel that survives motion: one palette family (e.g. cool/luminous) for wanted, one (e.g. desaturated/jagged-silhouette) for unwanted, so silhouette alone sorts them — keep the scientific labels but stop making them load-bearing.
- Add a climax: last 10s spawn surge + visual/audio shift + a "final molecule" beat, and add audio hits (good slurp, toxin buzz, streak chime) — the juice budget is already there.
- Lift or re-shape the mastery ceiling: let the multiplier climb past ×3 (or add a perfect-window bonus) so a clean run keeps paying off across a full 60s.
- Add a light catch-up so a behind player isn't dead: e.g. trailing player gets a brief slow-fall or a high-value "rescue nutrient" — keeps party rounds tense to the buzzer.

## Keep (the education + what already works — do not lose)
- The selective-permeability model is the whole point: WANTED = O₂/CO₂ (simple diffusion), H₂O (aquaporin), Na⁺/K⁺ (ion channel), Glucose (glucose transporter), Amino (carrier); UNWANTED = Toxin/Virus/Bacterium/Heavy-metal/Waste bounce. This taxonomy (`_kWanted`/`_kUnwanted`, lines 70–98) and the three embedded channel proteins that light up by transport type (`_lightChannel`, lines 319–334; aquaporin/glucose/ion slots in `_paintMembrane`) ARE the lesson — diffusion vs facilitated vs aquaporin transport. Do not flatten it into "tap good circles."
- The per-intake channel one-liner pop (`m.def.channel`, lines 303–306) teaching WHICH route each molecule uses — preserve this; it's the difference between a reflex game and a biology lesson.
- The default-impermeable, active-selection framing (membrane keeps things out for free; importing is the work) and the potato-tuber angle (pull in water/ions/glucose, keep rot-microbes out) from GAME.md — the brand+pedagogy hook.
- The single-Ticker/single-Painter perf architecture and vitality/nucleus feedback system — solid, reusable.
