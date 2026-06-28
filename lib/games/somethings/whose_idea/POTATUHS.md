# POTATUHS — Whose Idea?

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Whose Idea? — the somethings-scale idea-attribution quiz. Self-contained module
  (`lib/games/somethings/whose_idea/`); built to the GAMES rubric (Game + AGENT + Manual + Education),
  ready for the orchestrator to promote into the registry + MiniGameHost. Sibling of Organ Rush
  (`arcade/organ_quiz.dart`) — same genre, different content.

- **O — Objectives:** post the highest score when the 60s clock ends. Sub-goals: answer fast (the
  speed bonus is the bulk of the points) and keep a streak alive for the multiplier. In party play,
  outscore the table in a single round.

- **T — Tasks (the play to-do list):** read the big idea · pick the credited thinker from four
  same-field options · go fast (120 → 20 decay over ~4s) · stack 3-in-a-row for ×2, 6 for ×3 · read
  (or tap-skip) the context card · don't panic on a wrong tap (it costs 0, only the streak).

- **A — Automations (firing in the background):** the per-frame `Ticker` driving the question timer,
  the post-answer card countdown, the particle bursts, and the field-tinted `CustomPainter`
  background · auto-advance to the next question after the ~2.4s context window · the no-repeat
  shuffle that reshuffles the bank once exhausted · `noteStreak` quietly banking the run's best
  streak for the results screen.

- **T — Testing (experimental / in-flight):** the **field-balance** seam — the bank leans
  science/philosophy; topping up economics/political-theory is the tuning lever. The **content
  truth-test**: every item must be mainstream, widely-taught credit, with the `context` field used
  to flag genuine disputes. A future **visible speed bar** is the candidate juice upgrade (kept on
  the existing ticker, never a new heavy subtree — see the codebase render-cost lesson).

- **U — UX:** a field chip + the big idea up top · a 2×2 grid of thinker cards that resize to the
  viewport (never overflow) · a one-time **disclaimer ready-card** before play and a small
  **persistent disclaimer footer** during it · correct = green glow + burst, wrong = red shake ·
  a bottom-overlaid **context card** (thinker · era · one-line fact) that never steals choice space ·
  the host owns the clock/score/results, so the play area stays calm and legible.

- **H — Heuristics (how you actually win):** speed beats caution — a fast ×1 often outscores a slow
  ×2 · protect the streak once it's rolling (a wrong tap doesn't cost points but resets the
  multiplier you've been compounding) · recognize the *field* chip to narrow the plausible thinker ·
  tap-skip the card the instant you've read it to buy time for one more question.

- **S — Systems (what makes the world feel alive):** the **attribution thesis** is the living system —
  "history is written by the winners," surfaced honestly in the disclaimer and made concrete in
  every contested-credit card (Darwin/Wallace, Newton/Leibniz, Franklin's Photo 51, Stigler's law).
  The game's quiet argument is that naming an idea's owner is a *social* act, provisional and
  political — exactly the somethings-scale move of formless current → named, faced thing. Confident
  map on top, humble footnotes underneath.
