# EDUCATION.md — Bit Memory (nothings)

> The educational spine of Bit Memory. The game IS the lesson: by memorizing and replaying binary
> strings whose length doubles each level, the player physically experiences why every extra bit doubles
> what you can represent. Each milestone level fires a short, dismissible card; the full write-ups below
> are the canonical source for that copy.

- **Scale (cell):** nothings — the pre-matter scale. Binary is the most "nothing" thing there is: pure
  information, a single distinction between two states, before any physical stuff exists. A perfect fit
  for a scale that hosts the Big Bang.
- **Core concept:** a **bit** is one binary digit (0 or 1). `n` bits represent `2ⁿ` distinct values.
  Every bit you add **doubles** the range. The game's level ladder (1, 2, 4, 8, 16, 32, 64, 128 bits) is
  that doubling made tactile.

---

## The big idea: powers of two

| Bits | Values (2ⁿ) | Name | Where you've seen it |
|---|---|---|---|
| 1 | 2 | bit | on/off, true/false, a coin flip |
| 2 | 4 | — | 2-bit color, the 4 directions |
| 4 | 16 | **nibble** | one hex digit (0–F) |
| 8 | 256 | **byte** | one character, 8-bit games, 0–255 |
| 16 | 65,536 | word (2 bytes) | 16-bit consoles, Unicode BMP |
| 32 | 4,294,967,296 | dword (4 bytes) | IPv4, 32-bit systems, ~4 GB |
| 64 | 18,446,744,073,709,551,616 | qword (8 bytes) | modern CPUs, huge counters |
| 128 | ≈ 3.4 × 10³⁸ | — | UUIDs, crypto keys, IPv6 |

The single most important sentence in computing for a beginner: **add one bit, double the values.** The
game makes you feel it — going from a 4-bit nibble to an 8-bit byte isn't "twice as hard," it's a string
twice as long to hold in your head, and the payout doubles to match.

---

## Milestone cards (the in-game E)

Each card fires the first time the player reaches that level in a run. In-game copy is kept short; the
expanded version is here.

### Level 1 — 1 bit · "That's a bit!"
The smallest unit of information. A single binary digit: **0 or 1**. On or off, true or false, yes or no.
One bit distinguishes between exactly **2** possibilities. Everything else in computing is built by
stacking bits.

### Level 2 — 2 bits → 4 values
A second bit doesn't add 2 more values — it **doubles** to 4. Two bits count 0 through 3:

| Bits | Value |
|---|---|
| 00 | 0 |
| 01 | 1 |
| 10 | 2 |
| 11 | 3 |

This is the doubling rule appearing for the first time. Each new column on the left is worth twice the
column to its right (place value, base 2).

### Level 4 (4 bits) — "That's a nibble!"
Four bits → **16** values (0–15). Four bits is half a byte, which is why it's cheekily called a
**nibble**. Crucially, **one hexadecimal digit is exactly 4 bits**: hex runs 0–9 then A–F (10–15), so a
single hex character names any 4-bit pattern. **Two hex digits = one byte.** Hex exists precisely because
it lines up cleanly with groups of 4 bits — far easier for humans to read than long runs of 0s and 1s.

### Level 4 entry (8 bits) — "That's a byte!"
*(Game level 4 = 8 bits.)* Eight bits → **256** values (**0–255**). The byte is the fundamental unit of
storage — one byte usually holds one text character. This is the home of the **8-bit era** (the NES and
its peers). **255** is a number every gamer has hit without knowing why: max gold, max items, a stat
capped at 255 — because the designers stored it in a single byte and 255 is the largest value a byte
holds. A byte is also exactly **2 hexadecimal digits** (00–FF).

### Level 5 — 16 bits → 65,536 values
Sixteen bits (**2 bytes**, a "word") → **65,536** values (0–65,535). The **16-bit era** of the SNES and
Sega Genesis. The number **65,535** is the classic gold/item cap of countless 16-bit RPGs. If the value
is **signed** (one bit spent on the +/− sign), the cap is **32,767** instead — which is why some games
cap stats there. Same width, different interpretation.

### Level 6 — 32 bits → ~4.29 billion
Thirty-two bits (**4 bytes**) → **4,294,967,296** values (max **4,294,967,295**). This width defined a
generation of hardware: **32-bit operating systems**, the famous **~4 GB RAM limit** (2³² bytes of
addressable memory), and **IPv4** addresses (≈4.3 billion of them — which is why we ran out). The
**signed** 32-bit cap is **2,147,483,647**; the most famous overflow in pop-culture history happened when
**"Gangnam Style"** passed ~2.147 billion YouTube views and broke the counter, forcing a move to 64-bit.

### Level 7 — 64 bits → ~18.4 quintillion
Sixty-four bits (**8 bytes**) → **18,446,744,073,709,551,616** values. This is the width of **modern CPUs
and operating systems**. A 64-bit counter is, for everyday purposes, **limitless** — count a million per
second and it would take hundreds of thousands of years to overflow. The ~4 GB memory wall vanished here:
64-bit addressing can map more memory than any machine will hold for the foreseeable future.

### Level 8 — 128 bits → ~3.4 × 10³⁸
One hundred twenty-eight bits → about **340 undecillion** values — a number with 39 digits. It's so large
it's used for things that must be **globally unique without coordination**: **UUIDs** (random 128-bit IDs
that essentially never collide), **cryptographic keys** (a 128-bit key has more combinations than there
are atoms in many planets — brute force is hopeless), and **IPv6** addresses (enough to give every grain
of sand its own address, many times over). At 128 bits you have effectively enough numbers to name
everything that will ever exist.

---

## Why this is the right lesson for "nothings"

Binary is information stripped to its absolute floor: one distinction, repeated. Before particles, before
atoms, before a potato — there's the choice between two states. The Nothings scale already stages the Big
Bang ("something from nothing"); Bit Memory stages the informational version of the same idea: from a
single bit, by nothing but doubling, you can address the entire universe and everything in it.

## Potato angle

Every Potatuhs game, score and save lives as bits on a disk. The number on the results screen, the seed
that generated this run's string, the very pixels of a baked potato sprite — all of it is bytes. Bit
Memory is the game that makes a player feel the substrate the whole catalog is written on.
