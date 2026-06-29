# EDUCATION.md — Hilbert's Hotel: countable infinity and bijections

> The E in GAMES. The lesson is the mechanic: a **full** infinite hotel can *still* take in more guests,
> because "full" and "no room" mean different things once the rooms never end. Each rule you tap is a
> **bijection** — a perfect one-to-one rematch of guests to rooms — and seeing the rooms shift is seeing
> a bijection happen. This file is the full write-up; the game reinforces it with a per-answer card.

## The one idea

> **An infinite set can be put in one-to-one correspondence with a *proper part* of itself. That is what
> makes it infinite — and it is why a full ℵ₀ hotel always has room for more.**

The hotel has one room for every counting number: `1, 2, 3, 4, …`. "Full" means every room has a guest.
For a *finite* hotel, full means turn-away. For this hotel, full does **not** mean no room — because you
can always *rearrange* the guests into a new perfect matching that leaves rooms open.

## What "the same size" means — bijections

You cannot count an infinite set to compare sizes, so mathematicians use a sharper test:

> Two sets have the **same size (cardinality)** if you can pair their members **one-to-one with none
> left over** on either side — a **bijection**.

This is just the everyday "every seat has exactly one ticket-holder and every ticket-holder has exactly
one seat" test, applied to infinity. Every rule in the game is a bijection from guests to rooms:

- **`n → n+1`** pairs guest `n` with room `n+1`. Every guest gets a unique room; **room 1 is left over**
  for the new arrival. One guest fits into a "full" hotel.
- **`n → 2n`** pairs guest `n` with room `2n` (all the even rooms). It is still one-to-one and onto the
  evens, so **every odd room is now free** — and there are infinitely many odd rooms (ℵ₀ of them), exactly
  enough for an entire infinite **bus**.

The punchline: `{1, 2, 3, …}` and the even numbers `{2, 4, 6, …}` are **the same size**, even though one
sits *inside* the other. That is impossible for finite sets and ordinary for infinite ones.

## ℵ₀ — the size of "countable"

The size of the counting numbers is written **ℵ₀** ("aleph-null"), the smallest infinity. A set is
**countably infinite** if you can list its members `1st, 2nd, 3rd, …` so that every member eventually
appears — i.e. you can biject it with `{1, 2, 3, …}`. The game's three arrivals are a tour of facts about
ℵ₀ that look paradoxical but are just bijections:

| Arrival | Bijection trick | What it proves |
|---|---|---|
| **1 new guest** | `n → n+1` | `ℵ₀ + 1 = ℵ₀` |
| **one bus (ℵ₀ guests)** | `n → 2n`, bus → odd rooms | `ℵ₀ + ℵ₀ = ℵ₀` |
| **ℵ₀ buses, each ℵ₀** | prime powers (below) | `ℵ₀ × ℵ₀ = ℵ₀` |

## Infinitely many buses — the prime-powers room plan

Now ℵ₀ buses arrive, each with ℵ₀ seats. You must place ℵ₀ × ℵ₀ new guests **plus** the residents, all
into the single list of rooms `1, 2, 3, …`, with no collisions. The clean trick uses **unique prime
factorization** (every whole number factors into primes in exactly one way):

- send each **resident** in room `n` to room **2ⁿ**,
- send **bus `b`, seat `s`** to room **`pᵇ ˢ`** where `pᵇ` is the `b`-th **odd** prime (`3, 5, 7, 11, …`)
  — i.e. `3ˢ` for bus 1, `5ˢ` for bus 2, and so on.

Because `2`, `3ˢ`, `5ˢ`, `7ˢ`, … are powers of *distinct* primes, no two assignments ever land on the
same room — unique factorization guarantees it. So **ℵ₀ × ℵ₀ guests still fit**: the product of two
countable infinities is countable. (The `n → 2n` rule *opens* ℵ₀ rooms, but it does not by itself say how
to slot ℵ₀ separate buses into them without a second pairing — which is exactly why it is the *wrong*
answer for many buses and the prime-power plan is right.)

## Why the failing rules really fail

The distractors aren't arbitrary — each breaks the bijection in a specific way, and the game shows it:

- **All → room 1** — maps every guest to the *same* room. That is not one-to-one; it double-books room 1
  infinitely. A valid plan must send different guests to different rooms.
- **`n → n−1`** — guest 1 maps to "room 0", which does not exist. The map must land *inside* the room set;
  shifting *down* pushes guest 1 out the bottom. (Shifting *up* is fine — there is no top.)
- **Add a room at the end** — there is no last room to add after; the corridor has no end. You make room
  in an infinite hotel by *rearranging*, never by appending.

## Why this matters (beyond the game)

Hilbert's Hotel is a thought experiment David Hilbert used to teach that infinity does not obey the
arithmetic of finite quantities. The same bijection idea powers real results:

- the **rationals are countable** (you can snake a diagonal through the grid of fractions),
- the **reals are *not*** countable — Cantor's diagonal argument shows no list can hit every real, so
  there are *strictly bigger* infinities than ℵ₀,
- and that "some infinities are bigger than others" reshaped the foundations of mathematics.

Every time you tap the right rule and watch a full hotel make room, you are performing the move at the
heart of all of it: **rematch the same elements one-to-one and the impossible becomes routine.**

## Glossary

- **Bijection** — a one-to-one, onto pairing between two sets; the test for "same size".
- **Cardinality** — the size of a set, compared via bijections rather than counting.
- **Countably infinite** — same size as the counting numbers; can be listed `1st, 2nd, 3rd, …`.
- **ℵ₀ (aleph-null)** — the cardinality of the counting numbers; the smallest infinity.
- **Unique prime factorization** — every whole number > 1 is a product of primes in exactly one way;
  the no-collision guarantee behind the prime-powers room plan.
