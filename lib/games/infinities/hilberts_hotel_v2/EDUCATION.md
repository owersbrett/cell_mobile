# EDUCATION — Hilbert's Hotel v2

**Topic:** countable infinity, bijections, and the cardinal ℵ₀ (aleph-null).
**Big idea:** a *full* infinite hotel can still take in more guests — because
"making room" in the infinite is a **relabelling (bijection)**, not finding an
empty spot.

## The paradox (David Hilbert, 1924)
The Grand Hotel has one room for every counting number 1, 2, 3, … and **every
room is occupied**. In a finite hotel, "full" means "no more guests." In an
infinite hotel it does not — because there is no *last* room to overflow from.

The game teaches this by *enacting* the moves rather than describing them.

## The three legal moves (real bijections)

**1 guest — shift up, `n → n+1`.**
Ask every guest to move from room *n* to room *n+1*. Room 1 is now empty; the new
guest takes it. Nobody is doubled up — the map `n ↦ n+1` is a one-to-one
correspondence of ℕ onto {2, 3, 4, …}. *(Game: swipe →.)*

**One bus of ℵ₀ guests — double, `n → 2n`.**
Move the guest in room *n* to room *2n*. Now **every odd room** (1, 3, 5, …) is
empty — and there are infinitely many of them. Seat the *k*-th bus passenger in
room `2k − 1`. The map `n ↦ 2n` is a bijection of ℕ onto the even numbers;
combined with `k ↦ 2k − 1` for the bus, every guest — old and new — has a unique
room. *(Game: swipe ↑.)*

**Infinitely many buses, each with ℵ₀ guests — prime powers.**
Put the original resident of room *n* in room `2ⁿ`. Put seat *s* of bus *b* (where
`p_b` is the (b+1)-th prime: 3, 5, 7, 11, …) in room `p_b ^ s`. By the
**Fundamental Theorem of Arithmetic** (unique prime factorisation), no two of
these powers collide — every guest gets a private room. This is why ℵ₀ × ℵ₀ = ℵ₀:
the countable union of countable sets is still countable. *(Game: swipe ↓ — the
residents pack the powers of two and the buses flood the rest.)*

## The honest failure (taught, not hidden)
**Shift down, `n → n−1`** evicts the guest in room 1 — room 0 does not exist. It
is *not* a bijection of ℕ onto ℕ, so it is illegal. The game's `← left` swipe
performs exactly this and flashes the eviction. (Other classic illegal moves:
"send everyone to room 1" double-books it infinitely; "add a room at the end" —
there is no end.)

## Why it matters
ℵ₀ is the **smallest infinite cardinal**. Hilbert's Hotel is the intuition pump
for *countable* infinity; the natural next question — *are there infinities too
big to fit even with prime powers?* — leads to Cantor's diagonal argument and the
uncountability of the reals (a different, larger infinity). This game seats the
countable ones.

## Check for understanding
- Why can a full hotel still take one more guest, but a full *bus* (finite) cannot?
  *(ℕ has no last element; a finite set does.)*
- Why does `n → 2n` open infinitely many rooms, not just half? *(There are ℵ₀ odd
  numbers — "half of infinity" is still ℵ₀.)*
- Why must `n → n−1` fail? *(It has no room for the original guest 1.)*
