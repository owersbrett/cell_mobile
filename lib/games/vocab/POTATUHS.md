# POTATUHS — Vocab Engine (+ Finance Lingo)

> The POTATUHS lens applied to one module: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** A **reusable vocab engine** (`VocabGame`) + its first content bank (`kFinanceVocab`
  → the `finance_vocab` / "Finance Lingo" instance, `BioScale.financial`). Self-contained module
  (`lib/games/vocab/`); built to the GAMES rubric (Game + AGENT + Manual + Education), ready for the
  orchestrator to promote into the registry + MiniGameHost. Sibling of Organ Rush
  (`arcade/organ_quiz.dart`) and Whose Idea? (`somethings/whose_idea/`) — same genre, but the engine
  is **data-driven**, so it's a *factory* for per-scale vocab games, not a single title.

- **O — Objectives:** post the highest score when the 60 s clock ends. Sub-goals: answer fast (the
  speed bonus is the bulk of the points, and the window tightens as you go) and keep a streak alive
  for the multiplier. In party play, outscore the table in a single round.

- **T — Tasks (the play to-do list):** read the definition · pick the matching term from four options
  · go fast (120 → 20 decay, and the window shrinks each question) · stack 3-in-a-row for ×2, 6 for
  ×3 · read (or tap-skip) the reinforcement card · don't panic on a wrong tap (it costs 0, only the
  streak).

- **A — Automations (firing in the background):** the per-frame `Ticker` driving the question timer,
  the post-answer card countdown, the particle bursts, and the accent-tinted `CustomPainter`
  background · the **escalating** decay window that recomputes off the answered count · auto-advance
  after the ~2.4 s card window · the no-repeat shuffle that reshuffles once the bank is exhausted ·
  per-question option assembly (correct term + 3 distractors, padded from the bank if short) ·
  `noteStreak` quietly banking the run's best streak for the results screen.

- **T — Testing (experimental / in-flight):** the **reusability seam** — the engine must stay generic;
  the test is that adding a new scale's vocab game requires only a new `VocabBank` + a registry spec,
  zero engine edits. The **content truth-test**: every definition must let a learner pick the term
  *without* the term appearing in its own definition, and distractors must be genuine same-domain
  confusions. Future juice candidate: a visible shrinking speed bar (kept on the existing ticker,
  never a new heavy subtree — see the codebase render-cost lesson).

- **U — UX:** a domain chip + the definition up top · a 2×2 grid of term cards that resize to the
  viewport (never overflow) · a calm **ready card** before play · correct = green glow + burst, wrong
  = red shake · a bottom-overlaid **reinforcement card** (term · definition · note) that never steals
  choice space · the host owns the clock/score/results, so the play area stays calm and legible.

- **H — Heuristics (how you actually win):** speed beats caution — a fast ×1 often outscores a slow
  ×2, and the window only gets tighter · protect the streak once it's rolling (a wrong tap doesn't
  cost points but resets the multiplier you've been compounding) · learn the distractor *pairs* (the
  classic confusions — liquidity/solvency, bull/bear, asset/liability) so the decoys stop fooling you
  · tap-skip the card the instant you've read it to buy time for one more question.

- **S — Systems (what makes the world feel alive):** the **active-recall loop** is the living system —
  one generic engine that turns any word list into a fluency drill, with the reinforcement card
  closing the learning loop on every single answer. The quiet argument of the module is that
  **vocabulary is the entry fee to every scale**, and that teaching it should be *cheap and uniform*
  everywhere — so the engine is built as a factory: one loop, one feel, a different `VocabBank` per
  domain. Confident drill on top, a growing curriculum of banks underneath.
