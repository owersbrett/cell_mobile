# EDUCATION.md — Whose Idea?

> What this game teaches: a map of **big ideas → their commonly-credited originators** across six
> disciplines and their eras, AND — just as importantly — a thoughtful look at **attribution itself**:
> why credit is contested, why "history is written by the winners," and why the same idea so often
> gets discovered more than once.
>
> The in-game per-answer **context cards** are the bite-sized version of everything below.

- **Scale (cell):** somethings
- **Game on this scale:** `whose_idea` (this game) — joins "Corners" on the somethings scale.
- **Source data:** `whose_idea_data.dart` (`kWhoseIdeaBank`, ~41 items).

---

## Part 1 — The map of ideas → credited originators

The bank spans six fields. Below is the attribution the culture broadly agrees on, with the era and
a note on the contest where one exists.

### Science

| Big idea | Credited to | Era | Note |
|---|---|---|---|
| Evolution by natural selection | Charles Darwin | 1859 | Alfred Russel Wallace co-arrived; joint 1858 reading, Darwin's book won the name. |
| Heliocentrism | Nicolaus Copernicus | 1543 | Aristarchus proposed it ~1,800 years earlier. |
| General relativity | Albert Einstein | 1915 | David Hilbert derived the equations almost simultaneously. |
| Universal gravitation & motion | Isaac Newton | 1687 | Robert Hooke claimed the inverse-square law was his. |
| Germ theory | Louis Pasteur | 1860s | Robert Koch supplied much of the proof. |
| Energy quanta | Max Planck | 1900 | Planck called it a "desperate act" he barely believed. |
| DNA double helix | Watson & Crick | 1953 | Rosalind Franklin's Photo 51 was shown to Watson without her knowledge. |
| Laws of inheritance | Gregor Mendel | 1866 | Ignored 35 years, then rediscovered by three botanists at once. |
| Electromagnetic theory | James Clerk Maxwell | 1865 | Built on Faraday's experiments and intuition. |
| Periodic table | Dmitri Mendeleev | 1869 | Others grouped elements first; he predicted the gaps. |
| Continental drift | Alfred Wegener | 1912 | Mocked for decades; vindicated by plate tectonics after his death. |
| Smallpox vaccination | Edward Jenner | 1796 | Folk knowledge of cowpox preceded his experiment. |

### Philosophy

| Big idea | Credited to | Era |
|---|---|---|
| "Cogito, ergo sum" | René Descartes | 1637 |
| The allegory of the cave | Plato | c. 380 BCE |
| The categorical imperative | Immanuel Kant | 1785 |
| The social contract / general will | Jean-Jacques Rousseau | 1762 |
| The dialectic | G.W.F. Hegel | c. 1807 |
| Utilitarianism | Jeremy Bentham | c. 1789 |
| Existentialism ("existence precedes essence") | Jean-Paul Sartre | 1940s |
| "God is dead" / will to power | Friedrich Nietzsche | 1880s |
| Empiricism | John Locke | 1689 |

### Mathematics

| Big idea | Credited to | Era | Note |
|---|---|---|---|
| The calculus | Isaac Newton (and Leibniz) | 1660s–80s | Independent co-invention; a bitter priority war — both are co-credited today. |
| Axiomatic geometry (Elements) | Euclid | c. 300 BCE | Largely a compilation of earlier Greek geometry. |
| The Pythagorean theorem | Pythagoras | c. 530 BCE | Babylonian tablets used it ~1,000 years earlier. |
| Laws of planetary motion | Johannes Kepler | 1609 | Cracked using Tycho Brahe's guarded data. |
| Set theory / infinity | Georg Cantor | 1870s | Attacked fiercely in his lifetime. |
| Incompleteness theorems | Kurt Gödel | 1931 | Shattered Hilbert's dream of complete mathematics. |

### Economics

| Big idea | Credited to | Era |
|---|---|---|
| The invisible hand | Adam Smith | 1776 |
| Surplus value / critique of capital | Karl Marx | 1867 |
| Comparative advantage | David Ricardo | 1817 |
| Demand management by government | John Maynard Keynes | 1936 |
| Population vs. food supply | Thomas Malthus | 1798 |
| Creative destruction | Joseph Schumpeter | 1942 |

### Political theory

| Big idea | Credited to | Era |
|---|---|---|
| Separation of powers | Montesquieu | 1748 |
| Life "nasty, brutish, and short" / Leviathan | Thomas Hobbes | 1651 |
| Power-realism ("The Prince") | Niccolò Machiavelli | 1532 |
| Consent of the governed | John Locke | 1689 |

### Psychology

| Big idea | Credited to | Era |
|---|---|---|
| The unconscious / psychoanalysis | Sigmund Freud | 1900 |
| Collective unconscious / archetypes | Carl Jung | 1910s |
| Classical conditioning | Ivan Pavlov | c. 1900 |
| Operant conditioning | B.F. Skinner | 1930s |
| Hierarchy of needs | Abraham Maslow | 1943 |

---

## Part 2 — On attribution itself (the real lesson)

This is the part most quizzes leave out, and it is the heart of this game.

### "History is written by the winners"

Every answer in this game is an attribution the **collective broadly agrees on** — the version that
got written into the textbooks. That is not the same as being true in the strong sense of "this one
person, alone, first, with no one else." Credit is a **social outcome**: it goes to whoever
published in the right language, in the right journal, with the right reputation, at the right
moment — and to whoever told the story afterward. The game's persistent footer and ready-state card
exist to keep this honest: we teach the recorded credit, and we never pretend it is the whole truth.

### Priority disputes

When two people reach an idea near the same time, the result is often a **priority dispute** — a
fight over who got there first. The canonical case is **Newton vs. Leibniz** on the calculus: they
developed it independently, and the feud poisoned relations between English and Continental
mathematics for a century. Newton's notation lost; Leibniz's `dy/dx` is what students still write.
Both are now co-credited — but only after the bitterness.

### Multiple (independent) discovery

Priority disputes happen so often because **multiple discovery** is the norm, not the exception.
Ideas tend to arrive when the surrounding knowledge makes them *possible*, so more than one prepared
mind reaches them at once:

- **Darwin and Wallace** both arrived at natural selection; a joint paper was read in 1858.
- **Newton and Leibniz** both invented calculus.
- **Mendel's** genetics was independently "rediscovered" by three botanists around 1900.
- Oxygen, the telephone, and the theory of evolution all have rival simultaneous claimants.

The sociologist Robert Merton called this the phenomenon of **"multiples,"** and argued that
singletons (true lone discoveries) are actually the rare case.

### Stigler's law of eponymy

Statistician Stephen Stigler proposed, half in jest, **"no scientific discovery is named after its
original discoverer."** The Pythagorean theorem was used by Babylonians a millennium before
Pythagoras. The fittingly self-aware twist: Stigler credited the *idea of his own law* to Robert
Merton — making the law an example of itself.

### The uncredited

"The winners wrote it down" also means some contributors get **erased**. **Rosalind Franklin's**
X-ray crystallography (Photo 51) was essential to the DNA double helix, yet she was shown little
credit in her lifetime and was not eligible for the 1962 Nobel (she had died in 1958). **Tycho
Brahe's** decades of naked-eye observations made Kepler's laws possible. **Friedrich Engels**
funded Marx and finished "Capital" after his death. Behind almost every clean attribution is a
collaborator, a rival, or a predecessor the headline left out.

### So why credit anyone at all?

Because attribution is still useful: it gives us a shared shorthand, a map of who pushed which idea
into the world and made it stick. The healthy stance is to **hold the credit and the contest at the
same time** — to know that "Darwin = natural selection" is a true and useful fact about *history*,
while also knowing Wallace was right there beside him. That double awareness — confident map,
humble footnotes — is exactly what this game tries to build.

---

## Association verdict

**Strong tie to the somethings scale's theme of naming and individuation** — the somethings scale is
where formless "stuff" becomes *named, distinct things*. Attribution is the same move applied to
ideas: a diffuse intellectual current gets a name and a face attached to it. The game teaches both
the names the culture settled on **and** the seam where that naming is provisional and political —
the most intellectually honest framing the format allows.
