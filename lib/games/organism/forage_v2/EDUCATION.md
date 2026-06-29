# EDUCATION.md — Forage v2

> The E in GAMES. What a player actually learns, why the mechanic teaches it, and the real biology behind
> it. v2 keeps the entire lesson of `forage` and makes its headline equation **visible at the decision
> point** — see "Why v2 teaches it better" below.

## The lesson: an animal lives on an energy budget

Every animal runs a ledger it can never overdraw for long:

    net energy = energy in (food) − energy out (everything you do to get it and stay alive)

"Energy out" is not just exercise. It is **basal metabolism** (the cost of simply being alive — keeping
warm, pumping blood, repairing tissue) **plus** the cost of **foraging itself** — moving, searching,
chasing, fleeing. Food only counts as a gain *after* you subtract what it cost to obtain. A meal that
takes more energy to reach than it delivers is a net **loss**, even though you ate. Run the ledger
negative long enough and the animal starves. This game is that ledger, made playable.

## Why the mechanic teaches it (not just decorates it)

- **The energy meter is the ledger.** It rises when you eat and falls when you act — intake minus
  expenditure in real time, no hidden bookkeeping.
- **Movement costs energy, and the cost is charged against each meal.** When you eat, the game checks:
  did this food give more than the movement energy you spent reaching it? If yes → **EFFICIENT**
  (streak + bonus). If no → the chase was a net loss. This is **optimal foraging theory** turned into a
  scoreboard: foragers are selected to maximize energy *gained per energy spent*, not gross calories.
- **Resting is a real strategy.** Standing still spends only the basal drain, so waiting for nearby food
  lets the next bite come in cheap and efficient. Real animals rest, conserve, and forage in bursts.
- **Predators are an energy cost, not just a death threat.** Proximity drains energy (the metabolic cost
  of fear and flight); a bite costs a big chunk. Foraging is always a trade-off between getting food and
  not becoming food.
- **The budget tightens over the round.** Scarcer food, a rising basal drain, and multiplying predators
  model a harsh season (winter, drought) — expenditure climbs and intake falls exactly when energy
  management matters most.

## Why v2 teaches it *better* (the refinement)

The reference build proved the lesson only *after* a meal (a pop reading EFFICIENT or "cost N"). A player
learned that EFFICIENT was good but couldn't **aim** for it — the central variable, cost-since-last-meal,
was invisible at the one moment it matters: deciding whether to chase. v2 surfaces it:

- **The cost tether** draws the running price of movement as a line trailing from your last meal — you
  literally *see* the expenditure accumulate as you travel.
- **Food value-halos** shrink in real time. A far orb's halo collapses to a red break-even ring the
  instant `value − cost-so-far` goes negative — the optimal-foraging "ignore the far low-value prey" rule,
  rendered *before* you commit instead of regretted after.
- **The COST SINCE MEAL bar** flips to **NET LOSS — EAT NOW** when you cross break-even, turning the
  abstract inequality `value > cost` into a glanceable gauge.

The teach is now predictive, not post-hoc: you can plan the efficient meal, which is exactly what real
foragers do.

## The real biology

- **Basal metabolic rate (BMR)** is the energy burned at rest just to stay alive — a *large* share of the
  daily budget. That is the game's constant background drain.
- **Optimal foraging theory** predicts animals forage to maximize net energy intake rate: a predator
  should ignore a far-off, low-value prey if a closer or richer option exists, because travel and handling
  time are energy spent for nothing. The shrinking value-halo is this rule made visible.
- **Thermoregulation** is metabolically expensive for endotherms; cold *raises* expenditure — the harsher
  late-game drain and the cold vignette.
- **Energy reserves buffer the budget.** Animals bank energy as fat (and, for our potato forager, as
  starch); the meter is that reserve, and hitting zero is starvation.
- **Foraging trades off against predation risk** — a central tension in behavioral ecology, made literal
  by the fear-ring drain.

## What a player should be able to say afterward

- "Food is only a gain after you subtract what it cost to get — net energy, not gross."
- "I could *see* a far orb go net-negative before I reached it, so I turned back and ate nearby."
- "Just staying alive (and warm) burns energy constantly — that's basal metabolism."
- "Predators cost energy even when they don't catch you, because fleeing and fear are expensive."

## Stretch / discussion

- Why might a starving animal take *more* predation risk than a well-fed one?
- If moving costs energy, why don't animals just sit still? (Basal drain still runs — you must eat.)
- How does cold weather change the foraging math, and why do some animals hibernate instead?
- A potato sprouting in the dark burns its own stored starch with no food coming in — how long can it run
  a negative budget before it must reach light? (Its own forage clock.)
