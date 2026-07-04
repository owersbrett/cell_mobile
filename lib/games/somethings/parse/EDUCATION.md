# EDUCATION.md — Parse

**Subject:** programming fundamentals — recognizing the seven core code
constructs by their shape, across six languages, independent of surface syntax.

**Scale (cell):** somethings — the "first distinctions" scale. The very first
thing you do when reading code is decide *what a block of symbols IS*. Parse
drills exactly that first distinction.

## What the player learns (by doing, not reading)
The teaching is the mechanic: to score, the player must correctly name what each
snippet IS, so they build a durable mental model of each construct.

1. **FUNCTION** — a named (or anonymous) block that takes inputs and does work /
   returns a value. The tell is the *role*, not the keyword: a Python `def`, a
   JS `function`, a JS arrow `(n) => n * 2`, a Python `lambda`, a Kotlin
   single-expression `fun f() = …`, or an anonymous callback are ALL functions —
   even when assigned to a `const` or `val`.
2. **CLASS** — a blueprint bundling data + behaviour. `class` in most languages;
   Kotlin `data class`, a Python `@dataclass`, a JS anonymous `class expression`,
   and a Java `abstract class` are all still classes.
3. **VARIABLE** — a named binding to a value. `let` / `const` / `var` / `val` /
   a bare `x = 0` / a typed `x: int = 0`. The trap: a `const`/`val` bound to a
   *function value* is a function, not a variable — the value decides.
4. **INTERFACE** — a contract of members with no (or default) implementation.
   TypeScript / Java / Kotlin `interface`; Swift spells it **`protocol`**; Python
   uses a **`Protocol`** subclass. Same idea, different words.
5. **LOOP** — repeated execution: `for`, `while`, `for…of`, `for…in`, Kotlin
   ranges (`1..100`), Swift `repeat…while`.
6. **IMPORT** — pulling in external code: `import`, `from … import`, TS
   `import type`, and the CommonJS idiom `const x = require(...)` (which *looks*
   like a variable but IS an import).
7. **ENUM** — a fixed set of named values: `enum`, Kotlin `enum class`, a TS
   `const enum`, a Python `class C(Enum)`.

## The core idea
**Surface syntax varies; the construct is the invariant.** The language chip is
deliberately shown so the player learns to *ignore* it and read structure. The
tricky snippets (arrow-as-function, protocol-as-interface, require-as-import,
Enum-subclass-as-enum) are where the real learning happens — each reveal prints
the tell so the lesson lands even on a miss.

## Vocabulary surfaced in play
function · lambda · arrow function · class · data class · interface · protocol ·
variable · binding · loop · import · module · enum · construct · keyword vs.
role.

## Languages covered
Python · Swift · Kotlin · Java · TypeScript · JavaScript.

## Career / real-world hook
This is the literal first skill of reading any unfamiliar codebase or reviewing a
pull request: skim a block and know what it is. It's also the mental model behind
syntax highlighters, linters, and the parser stage of every compiler — hence the
name.
