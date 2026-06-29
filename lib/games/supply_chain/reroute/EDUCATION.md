# EDUCATION.md — Reroute! (disruption & resilience)

> What this game teaches: why a supply chain built on a single cheap supplier is **fragile**, and how
> **redundancy** and **diversification** keep production running through shocks. The mechanic IS the
> lesson — every time a storm closes your active route and you tap a backup to keep the factory fed,
> you are performing the core move of supply-chain resilience: **multi-sourcing**. The tension you
> feel — wanting the fast cheap farm, but watching it fail most — is the real **resilience-vs-
> efficiency tradeoff** that every operations manager lives with.

- **Scale:** `BioScale.supplyChain`.
- **Game:** `reroute`.
- **Sibling game on this scale:** `delivery` (static routing / shortest-path). Reroute is its
  *dynamic* counterpart — not finding one optimal route, but surviving a stream of disruptions.

---

## 1. The single-source trap

The cheapest way to feed a factory is usually to buy everything from **one** supplier — the closest,
biggest, lowest-cost farm. One contract, one route, one relationship, best price. On a calm day it
wins on every spreadsheet.

The problem is that it has a **single point of failure**. The day that one farm floods, that one
road closes, or that one port strikes, your input drops to **zero** — and a factory with no input
stops producing entirely. In the game this is the Backyard Farm: highest yield, right next door,
but the route most likely to be hit by a storm. Ride it alone and the first closure starves you.

Real examples of single-source / single-route shocks:
- **Port closures & canal blockages** — the 2021 Suez Canal blockage stalled ~12% of global trade
  for days; a single chokepoint, enormous downstream effect.
- **One-supplier component shortages** — the 2011 Tōhoku earthquake knocked out specialist factories
  that were the *sole* source of certain auto and electronics parts, idling plants worldwide.
- **Crop failures** — a drought or blight in one growing region empties a "cheap" agricultural source
  the way the game's drought empties a farm. (Potato history's own cautionary tale: the 1845–52 Irish
  famine was a *monoculture* failure — one crop, one variety, no diversity, no backup.)

---

## 2. The fix: redundancy and diversification

Resilient supply chains deliberately **do not** rely on one source. Two strategies, both in the game:

- **Redundancy** — keep more capacity/paths than you strictly need on a normal day, so a failure has
  a spare to fall back on. In the game, every idle route standing "READY" is redundancy: it costs you
  nothing while unused, and it's the thing that saves you when the active line breaks.
- **Diversification (multi-sourcing)** — spread supply across sources that **fail for different
  reasons**. A nearby farm and an overseas port don't flood in the same storm; a coastal port and an
  inland farm aren't hit by the same drought. The Overseas Port in the game is slow and low-yield —
  *inefficient* — but it has a low `failBias`: it rarely goes down. It is your **diverse backup**,
  and on the worst-shock rounds it is the only thing keeping the factory alive.

The skill the game trains is exactly this: don't just grab the best source — keep an eye on which
backups are healthy, and switch early. A player who keeps reroute options ready outlasts a player who
optimises purely for the highest-yield farm.

---

## 3. The resilience-vs-efficiency tradeoff

Here is the real tension, and the reason this isn't a solved problem in industry. Redundancy and
diversification **cost money**:
- Backup suppliers mean smaller orders, weaker bargaining power, higher unit prices.
- Spare capacity and safety stock sit idle, tying up cash.
- A diversified network is more complex to manage.

So "just-in-time, lowest-cost, single-source" is genuinely *more efficient* — right up until a shock,
when it is catastrophically *less resilient*. The game makes you feel both sides:
- The strong source keeps the silo **full**, so production runs **fast** (efficiency).
- But it fails most, and when it does you starve unless you've kept the slower backups alive.
- The slow Overseas Port keeps you running through shocks (resilience) but produces less while you're
  on it.

There is no free lunch. The high score belongs to the player who runs efficient when it's calm and
diversified when it counts — **buffering** (the silo) bridges the gap, giving you a few seconds of
production to reroute before the shock bites. That buffer is the in-game version of **safety stock**.

---

## 4. The vocabulary, mapped to the mechanic

| Real concept | In the game |
|---|---|
| Single point of failure | Riding one source; the first storm starves you |
| Supplier diversification / multi-sourcing | Switching among farms/ports that fail independently |
| Redundancy | The idle "READY" backup routes |
| Safety stock / buffer inventory | The factory's input **SILO** (gives you time to react) |
| Disruption / shock | Storm (route closure) and drought (source depletion) |
| Resilience vs efficiency tradeoff | Fast-but-fragile Backyard Farm vs slow-but-reliable Overseas Port |
| Cost of resilience | Lower yield when you fall back to the safe source |
| Just-in-time fragility | A small silo + one source = fastest, until it isn't |

---

## Association verdict

**Strong tie to the supply-chain scale.** Where the sibling `delivery` game teaches the *static*
optimisation problem (find the shortest route once), Reroute teaches the *dynamic* one that dominates
real operations: the world keeps breaking your plan, and survival comes from having alternatives
ready. Diversification, redundancy, buffering, and the cost of all three are not narrated over the
top of the game — they ARE the moment-to-moment decision the player makes. That is the best kind of
educational tie: you can't win without internalising the idea.
