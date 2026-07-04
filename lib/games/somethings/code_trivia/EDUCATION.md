# EDUCATION.md — Code Trivia (game-level ledger)

> What this game teaches and how the mechanic carries it. Placed on the
> **somethings** scale by orchestrator decision; it teaches general programming
> literacy, not the scale's geometry blocks (see the scale-level
> `lib/games/somethings/EDUCATION.md` for that ledger).

- **Scale (cell):** somethings
- **Game id:** `code_trivia`
- **Teaching mechanic:** active recall under time pressure + corrective
  feedback. Every miss (wrong tap OR fuse-out) reveals the correct answer with
  a one-line **why** — the player cannot fail without being taught. Streak
  scoring rewards consolidated knowledge; the shrinking fuse forces recall to
  become automatic rather than deliberative.

## Blocks
| Block | Title | Short description | Engaged by | Strength |
|---|---|---|---|---|
| Language identity | Who's who of languages | Recognize languages by signature syntax (`fun`, `fn`, `println!`, `#`, indentation) and by creator/company. | tiers 1–3 | ✅ core |
| Language relationships | How languages relate | TypeScript = JS + static types; Kotlin on the JVM; TS → JS; Wasm in the browser. | tiers 2–3 | ✅ |
| Tooling concepts | Compiler / interpreter / linter / JIT | What each actually does, and compiled-vs-interpreted as a concept. | tiers 2–3 | ✅ |
| Git basics | Version control verbs | clone, commit, branch, stash, rebase, fast-forward — what each does. | tiers 1–3 | ✅ |
| HTTP | Verbs + status codes | GET/POST/PUT/PATCH/DELETE semantics, idempotency, 404/500. | tiers 1–3 | ✅ |
| Big-O | Cost of common operations | O(1) hash/array/head-insert, O(log n) binary search, O(n) scan, O(n log n) quicksort, growth-rate ordering. | tiers 2–3 | ✅ |
| Core vocabulary | API / IDE / regex / bug / boolean / recursion / race condition | The words programmers use, defined plainly. | tiers 1–3 | ✅ |
| History-lite | The famous firsts | Guido/Python, Linus/Linux+Git, Ritchie/C, Stroustrup/C++, Eich/JS ~1995 — only famous, uncontested facts. | tiers 2–3 | ✅ |

## Where the teaching lives (not cosmetic)
1. **The why-line** — the single highest-value surface. Authored per question in
   `code_trivia_data.dart`; it names the answer AND contrasts the distractors
   ("Kotlin uses `fun`; Swift and Go use `func`, Rust uses `fn`").
2. **Near-miss distractors (tier 3)** — discriminating between plausible
   answers is where real understanding is tested (Ritchie vs Kernighan vs
   Thompson; O(n log n) vs O(n²)).
3. **The fuse** — recall speed is the difference between recognizing a fact and
   owning it; the speed bonus pays for fluency, not just correctness.

## Association verdict
**KEEP** — the teach-on-miss loop is structural, not decorative. Growth path:
more tier-3 content, and (later) per-topic sub-banks so a run can be themed
(git night, big-O night).

## Potato angle
Light: the burning fuse is the hot potato — the question is too hot to hold.
No forced potato content in the bank.
