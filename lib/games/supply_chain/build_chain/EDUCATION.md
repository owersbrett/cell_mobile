# EDUCATION.md — Build the Chain: what a supply chain IS

> The E in GAMES. The lesson is the mechanic: assembling the stages in the right order
> **is** the definition of a supply chain. This file is the full write-up; the game
> reinforces it with a per-tile role card and a colour-coded "broken arrow" that shows
> exactly where an out-of-order chain snaps.

## The one idea

> **A supply chain is a named, ordered sequence of stages that moves a product from raw
> material to the customer — and the order is not optional.**

When you drop the Process tile before the Farm tile, goods can't flow: you can't fry a
potato you haven't grown. The red arrow in the game is that impossibility made visible.

## Upstream vs downstream

A supply chain has a direction, borrowed from a river:

- **Upstream** = toward the *source* — the raw material end (the Farm).
- **Downstream** = toward the *customer* — the consumption end (the Store).

Goods move **downstream**. Every stage takes what the stage before it produced, adds
value, and hands it to the next. "Order matters" is just this: each stage's input is the
previous stage's output. Break the order and a stage is asked for an input that doesn't
exist yet.

## The stages, in order (the potato chain)

| # | Stage | What it does | Why it sits here |
|---|---|---|---|
| 1 | 🌱 **Farm** | Grow and harvest the raw potatoes. | Nothing exists upstream of the raw material. |
| 2 | 🚿 **Wash & Sort** | Clean off the dirt; grade by size and quality. | You can only sort what's been harvested. |
| 3 | 🔍 **Quality Check** | Inspect; reject bruised or green spuds. | Catch defects *before* you spend money processing them. |
| 4 | 🏭 **Process** | Cut and cook into fries and chips. | Turns the raw crop into the actual product. |
| 5 | 📦 **Packaging** | Seal product into bags and boxes. | You package a finished product, not a raw one. |
| 6 | ❄️ **Cold Storage** | Keep it frozen and fresh until it ships. | Preserve the packaged goods through the wait. |
| 7 | 🏬 **Warehouse** | Hold finished stock until stores order it. | Buffer between making and selling. |
| 8 | 🚚 **Distribute** | Truck the product out to stores. | Moves stock from the buffer to the shelves. |
| 9 | 🏪 **Store** | Stock the shelves; sell to the customer. | The product reaches the person who eats it. |
| — | 🚢 **Export Port** | Ship overseas to distant markets. | An alternate downstream endpoint — a *branch* of the chain. |

The boundaries are real-world: a Quality Check sits **before** Process so you don't waste
energy frying rejects; Packaging comes **after** Process because you bag a finished good;
Distribute sits **between** Warehouse and Store because trucks carry stored stock to
shelves. These "you can't do X before Y" relationships are exactly what the game's order
constraint trains.

## Three things flow through a chain (not just goods)

A supply chain carries **three** flows at once:

1. **Goods flow downstream** — potatoes → fries → packaged bags → shelves. (This is what
   the game animates in the FLOW phase.)
2. **Information flows upstream** — a store running low sends an *order* back up the
   chain; that signal tells the warehouse to ship, the plant to make more, the farm to
   plant more. Demand pulls product through.
3. **Money flows upstream** — the customer pays the store, the store pays the
   distributor, and so on back to the farm. Cash moves opposite to the goods.

A healthy chain keeps all three moving. The game's **stall** mechanic is a stoppage in
the goods flow: one stage backs up, and until it's cleared, nothing downstream of it can
be served — a small lesson that a chain is only as fast as its slowest stage (its
**bottleneck**).

## Why order matters — the core takeaway

- Each stage **transforms** its input and passes an output forward. Out of order, the
  input simply isn't there yet.
- A chain is a **dependency sequence**: later stages depend on earlier ones, never the
  reverse. (You can warehouse only what's been processed; you can sell only what's been
  stocked.)
- The slowest or stalled stage is the **bottleneck** — it caps the throughput of the
  whole chain no matter how fast every other stage runs.
- **Branches** exist: the same processed, packaged product can go to a domestic Store or
  out an Export Port. The early stages are shared; the chain forks near the end.

## Why this matters beyond potatoes

Every physical product you own rode a supply chain: phones (mine metal → fabricate chips
→ assemble → distribute → retail), groceries, fuel, medicine. The same vocabulary —
upstream/downstream, stages, bottleneck, lead time, distribution — describes all of them.
Supply-chain disruptions (a stalled port, an empty warehouse) make the news precisely
because a break at one stage starves everything downstream of it. This game is the
smallest honest model of that system: name the stages, put them in order, keep them
flowing.

## Glossary

- **Supply chain** — the ordered set of stages a product passes through from raw material
  to customer.
- **Upstream / downstream** — toward the source / toward the customer. Goods move
  downstream; orders and money move upstream.
- **Stage** — one named step that transforms its input and passes it on (Farm, Process,
  Warehouse, …).
- **Bottleneck** — the slowest/stalled stage; it caps the whole chain's throughput.
- **Lead time** — how long goods take to travel the chain end to end.
- **Distribution** — the stage that moves finished stock to the points of sale.
- **Branch** — a fork in the chain where shared early stages split to different endpoints
  (domestic Store vs Export Port).
