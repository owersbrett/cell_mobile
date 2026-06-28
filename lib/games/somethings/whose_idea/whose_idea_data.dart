// Whose Idea? — question bank for the idea-attribution quiz.
//
// Each item pairs a BIG IDEA / concept with the thinker that ACCEPTED, RECORDED
// history broadly credits with INTRODUCING it, three plausible same-era / same-
// field distractor thinkers, an era tag, and a one-line context card shown as a
// post-answer flare.
//
// ── ATTRIBUTION DISCLAIMER (load-bearing) ───────────────────────────────────
// "History is written by the winners." These attributions reflect the mainstream,
// collectively-agreed credit recorded by history — NOT a claim that any thinker
// absolutely, solely, or first originated the idea. Priority disputes (Newton vs.
// Leibniz on calculus), uncredited collaborators (Rosalind Franklin on DNA), and
// multiple independent discovery (Stigler's law of eponymy) are the rule, not the
// exception. The game teaches the attribution the culture agrees on, and the
// `context` lines surface the contest where it matters. See EDUCATION.md.

/// The broad discipline a big idea belongs to. Drives the category chip + color.
enum IdeaField { science, philosophy, mathematics, economics, politics, psychology }

class IdeaQuestion {
  /// Discipline bucket — used for the on-screen field chip and distractor pool.
  final IdeaField field;

  /// The big idea / concept shown as the prompt.
  final String idea;

  /// The thinker history broadly credits with introducing the idea (correct).
  final String thinker;

  /// Exactly three plausible distractor thinkers (same broad era/field).
  final List<String> distractors;

  /// Short era tag for the answer card ("1859", "c. 380 BCE").
  final String era;

  /// One-line context / fun-fact shown on the post-answer flare. Where the
  /// attribution is genuinely contested, this is where we say so.
  final String context;

  const IdeaQuestion({
    required this.field,
    required this.idea,
    required this.thinker,
    required this.distractors,
    required this.era,
    required this.context,
  });

  /// All four options, correct answer first. The game shuffles before showing.
  List<String> get options => [thinker, ...distractors];
}

const List<IdeaQuestion> kWhoseIdeaBank = [
  // ── SCIENCE ───────────────────────────────────────────────────────────────
  IdeaQuestion(
    field: IdeaField.science,
    idea: 'Evolution by natural selection',
    thinker: 'Charles Darwin',
    distractors: ['Jean-Baptiste Lamarck', 'Alfred Russel Wallace', 'Gregor Mendel'],
    era: '1859',
    context:
        'Wallace reached the same idea independently — they were read jointly in 1858, but Darwin\'s "Origin of Species" won him the lasting credit.',
  ),
  IdeaQuestion(
    field: IdeaField.science,
    idea: 'Heliocentrism — the Sun at the center',
    thinker: 'Nicolaus Copernicus',
    distractors: ['Galileo Galilei', 'Johannes Kepler', 'Ptolemy'],
    era: '1543',
    context:
        'Aristarchus of Samos proposed a Sun-centered cosmos ~1,800 years earlier, but the model is named for Copernicus, who revived it with math.',
  ),
  IdeaQuestion(
    field: IdeaField.science,
    idea: 'General relativity — gravity as curved spacetime',
    thinker: 'Albert Einstein',
    distractors: ['Isaac Newton', 'Niels Bohr', 'Max Planck'],
    era: '1915',
    context:
        'Mathematician David Hilbert derived the field equations almost simultaneously — but the theory is, and stays, Einstein\'s.',
  ),
  IdeaQuestion(
    field: IdeaField.science,
    idea: 'Universal gravitation and the laws of motion',
    thinker: 'Isaac Newton',
    distractors: ['Galileo Galilei', 'Robert Hooke', 'Johannes Kepler'],
    era: '1687',
    context:
        'Robert Hooke claimed Newton stole the inverse-square law from him — a feud that soured both men for life.',
  ),
  IdeaQuestion(
    field: IdeaField.science,
    idea: 'Germ theory — microbes cause disease',
    thinker: 'Louis Pasteur',
    distractors: ['Robert Koch', 'Joseph Lister', 'Edward Jenner'],
    era: '1860s',
    context:
        'Robert Koch supplied much of the hard proof, but Pasteur is the name the public attaches to germ theory.',
  ),
  IdeaQuestion(
    field: IdeaField.science,
    idea: 'Energy comes in discrete quanta',
    thinker: 'Max Planck',
    distractors: ['Albert Einstein', 'Niels Bohr', 'Werner Heisenberg'],
    era: '1900',
    context:
        'Planck called his own quantum a "desperate act" of math — he didn\'t fully believe it was physically real.',
  ),
  IdeaQuestion(
    field: IdeaField.science,
    idea: 'The double-helix structure of DNA',
    thinker: 'James Watson & Francis Crick',
    distractors: ['Rosalind Franklin', 'Linus Pauling', 'Gregor Mendel'],
    era: '1953',
    context:
        'Rosalind Franklin\'s X-ray "Photo 51" was crucial — and shown to Watson without her knowledge. A textbook case of credit gone to the winners.',
  ),
  IdeaQuestion(
    field: IdeaField.science,
    idea: 'The laws of inheritance (classical genetics)',
    thinker: 'Gregor Mendel',
    distractors: ['Charles Darwin', 'Jean-Baptiste Lamarck', 'Hugo de Vries'],
    era: '1866',
    context:
        'Mendel\'s pea-plant work was ignored for 35 years, then "rediscovered" by three botanists at once around 1900.',
  ),
  IdeaQuestion(
    field: IdeaField.science,
    idea: 'A unified theory of electromagnetism',
    thinker: 'James Clerk Maxwell',
    distractors: ['Michael Faraday', 'André-Marie Ampère', 'Nikola Tesla'],
    era: '1865',
    context:
        'Maxwell built on Faraday\'s experiments — Faraday had the physical intuition, Maxwell gave it the equations.',
  ),
  IdeaQuestion(
    field: IdeaField.science,
    idea: 'The periodic table of the elements',
    thinker: 'Dmitri Mendeleev',
    distractors: ['Antoine Lavoisier', 'John Dalton', 'Niels Bohr'],
    era: '1869',
    context:
        'Several chemists grouped elements by weight first, but Mendeleev left gaps and predicted the missing elements — and was right.',
  ),
  IdeaQuestion(
    field: IdeaField.science,
    idea: 'Continental drift — the continents move',
    thinker: 'Alfred Wegener',
    distractors: ['Charles Lyell', 'James Hutton', 'Charles Darwin'],
    era: '1912',
    context:
        'Wegener was mocked for decades; plate tectonics vindicated him only after his death on a Greenland expedition.',
  ),
  IdeaQuestion(
    field: IdeaField.science,
    idea: 'Vaccination against smallpox',
    thinker: 'Edward Jenner',
    distractors: ['Louis Pasteur', 'Robert Koch', 'Joseph Lister'],
    era: '1796',
    context:
        'Farmers and a few doctors had noticed cowpox protected against smallpox; Jenner ran the experiment that named the practice.',
  ),

  // ── PHILOSOPHY ─────────────────────────────────────────────────────────────
  IdeaQuestion(
    field: IdeaField.philosophy,
    idea: '"Cogito, ergo sum" — I think, therefore I am',
    thinker: 'René Descartes',
    distractors: ['Baruch Spinoza', 'Gottfried Leibniz', 'Immanuel Kant'],
    era: '1637',
    context:
        'Descartes sought one thing he could not doubt — and found it in the act of doubting itself.',
  ),
  IdeaQuestion(
    field: IdeaField.philosophy,
    idea: 'The allegory of the cave',
    thinker: 'Plato',
    distractors: ['Aristotle', 'Socrates', 'Pythagoras'],
    era: 'c. 380 BCE',
    context:
        'Plato wrote it as dialogue spoken by Socrates — so we read Socrates\' "voice," but the idea is credited to Plato\'s pen.',
  ),
  IdeaQuestion(
    field: IdeaField.philosophy,
    idea: 'The categorical imperative',
    thinker: 'Immanuel Kant',
    distractors: ['David Hume', 'John Locke', 'Jean-Jacques Rousseau'],
    era: '1785',
    context:
        'Act only on a rule you could will to be a universal law — Kant\'s test for any moral act.',
  ),
  IdeaQuestion(
    field: IdeaField.philosophy,
    idea: 'The social contract and the "general will"',
    thinker: 'Jean-Jacques Rousseau',
    distractors: ['Thomas Hobbes', 'John Locke', 'Montesquieu'],
    era: '1762',
    context:
        'Hobbes and Locke wrote social-contract theories too — Rousseau\'s book simply took the name as its title.',
  ),
  IdeaQuestion(
    field: IdeaField.philosophy,
    idea: 'The dialectic — thesis, antithesis, synthesis',
    thinker: 'Georg Wilhelm Friedrich Hegel',
    distractors: ['Immanuel Kant', 'Karl Marx', 'Johann Fichte'],
    era: 'c. 1807',
    context:
        'Hegel rarely used the neat "thesis-antithesis-synthesis" slogan himself — a later summarizer pinned it on him.',
  ),
  IdeaQuestion(
    field: IdeaField.philosophy,
    idea: 'Utilitarianism — the greatest good for the greatest number',
    thinker: 'Jeremy Bentham',
    distractors: ['John Stuart Mill', 'Immanuel Kant', 'David Hume'],
    era: 'c. 1789',
    context:
        'Bentham founded it; his student John Stuart Mill refined and popularized it — credit is often split between them.',
  ),
  IdeaQuestion(
    field: IdeaField.philosophy,
    idea: 'Existentialism — "existence precedes essence"',
    thinker: 'Jean-Paul Sartre',
    distractors: ['Albert Camus', 'Søren Kierkegaard', 'Martin Heidegger'],
    era: '1940s',
    context:
        'Kierkegaard and Heidegger laid the groundwork, but Sartre coined the slogan and made "existentialism" a movement.',
  ),
  IdeaQuestion(
    field: IdeaField.philosophy,
    idea: '"God is dead" and the will to power',
    thinker: 'Friedrich Nietzsche',
    distractors: ['Arthur Schopenhauer', 'Søren Kierkegaard', 'G.W.F. Hegel'],
    era: '1880s',
    context:
        'Nietzsche meant that faith\'s grip on the West had collapsed — a diagnosis, not a celebration.',
  ),
  IdeaQuestion(
    field: IdeaField.philosophy,
    idea: 'Empiricism — knowledge comes from the senses',
    thinker: 'John Locke',
    distractors: ['René Descartes', 'David Hume', 'George Berkeley'],
    era: '1689',
    context:
        'Locke\'s "blank slate" launched British empiricism; Berkeley and Hume then pushed it to startling conclusions.',
  ),

  // ── MATHEMATICS ────────────────────────────────────────────────────────────
  IdeaQuestion(
    field: IdeaField.mathematics,
    idea: 'The calculus',
    thinker: 'Isaac Newton',
    distractors: ['Gottfried Leibniz', 'Pierre de Fermat', 'Euclid'],
    era: '1660s–1680s',
    context:
        'Newton and Leibniz invented calculus independently and feuded bitterly over priority — today both are co-credited.',
  ),
  IdeaQuestion(
    field: IdeaField.mathematics,
    idea: 'Axiomatic geometry (the "Elements")',
    thinker: 'Euclid',
    distractors: ['Pythagoras', 'Archimedes', 'Thales'],
    era: 'c. 300 BCE',
    context:
        'Euclid mostly compiled and organized existing Greek geometry — but did it so well the field bears his name for 2,000 years.',
  ),
  IdeaQuestion(
    field: IdeaField.mathematics,
    idea: 'The Pythagorean theorem',
    thinker: 'Pythagoras',
    distractors: ['Euclid', 'Thales', 'Archimedes'],
    era: 'c. 530 BCE',
    context:
        'Babylonian tablets used the relationship a thousand years before Pythagoras — a classic case of Stigler\'s law of eponymy.',
  ),
  IdeaQuestion(
    field: IdeaField.mathematics,
    idea: 'The laws of planetary motion (elliptical orbits)',
    thinker: 'Johannes Kepler',
    distractors: ['Tycho Brahe', 'Nicolaus Copernicus', 'Galileo Galilei'],
    era: '1609',
    context:
        'Kepler cracked the orbits using Tycho Brahe\'s data — data Brahe had guarded jealously until his death.',
  ),
  IdeaQuestion(
    field: IdeaField.mathematics,
    idea: 'Set theory and the mathematics of infinity',
    thinker: 'Georg Cantor',
    distractors: ['Gottlob Frege', 'David Hilbert', 'Henri Poincaré'],
    era: '1870s',
    context:
        'Cantor proved some infinities are bigger than others — and was attacked so fiercely it likely worsened his depression.',
  ),
  IdeaQuestion(
    field: IdeaField.mathematics,
    idea: 'The incompleteness theorems',
    thinker: 'Kurt Gödel',
    distractors: ['David Hilbert', 'Bertrand Russell', 'Alan Turing'],
    era: '1931',
    context:
        'Gödel proved any rich-enough math system contains true statements it can never prove — shattering Hilbert\'s dream of a complete mathematics.',
  ),

  // ── ECONOMICS ──────────────────────────────────────────────────────────────
  IdeaQuestion(
    field: IdeaField.economics,
    idea: 'The "invisible hand" of free markets',
    thinker: 'Adam Smith',
    distractors: ['David Ricardo', 'John Maynard Keynes', 'Karl Marx'],
    era: '1776',
    context:
        'Smith used the famous phrase only a handful of times — later economists made it the slogan of his whole system.',
  ),
  IdeaQuestion(
    field: IdeaField.economics,
    idea: 'Surplus value and the critique of capital',
    thinker: 'Karl Marx',
    distractors: ['Friedrich Engels', 'Vladimir Lenin', 'Adam Smith'],
    era: '1867',
    context:
        'Friedrich Engels funded Marx for decades and edited the unfinished volumes of "Capital" after his death.',
  ),
  IdeaQuestion(
    field: IdeaField.economics,
    idea: 'Comparative advantage — why nations trade',
    thinker: 'David Ricardo',
    distractors: ['Adam Smith', 'Thomas Malthus', 'John Maynard Keynes'],
    era: '1817',
    context:
        'Ricardo\'s insight: even a country worse at everything still gains by trading — it remains the bedrock case for free trade.',
  ),
  IdeaQuestion(
    field: IdeaField.economics,
    idea: 'Government spending to steer the economy',
    thinker: 'John Maynard Keynes',
    distractors: ['Milton Friedman', 'Friedrich Hayek', 'Adam Smith'],
    era: '1936',
    context:
        'Keynes argued that in a slump the state should spend — reversing a century of leave-it-alone orthodoxy.',
  ),
  IdeaQuestion(
    field: IdeaField.economics,
    idea: 'Population grows faster than the food supply',
    thinker: 'Thomas Malthus',
    distractors: ['David Ricardo', 'Adam Smith', 'Charles Darwin'],
    era: '1798',
    context:
        'Malthus\'s grim arithmetic directly inspired Darwin\'s "struggle for existence" — one field\'s idea seeding another.',
  ),
  IdeaQuestion(
    field: IdeaField.economics,
    idea: '"Creative destruction" drives capitalism',
    thinker: 'Joseph Schumpeter',
    distractors: ['John Maynard Keynes', 'Friedrich Hayek', 'Karl Marx'],
    era: '1942',
    context:
        'Schumpeter saw innovation as a gale that constantly destroys old industries to build new ones.',
  ),

  // ── POLITICAL THEORY ───────────────────────────────────────────────────────
  IdeaQuestion(
    field: IdeaField.politics,
    idea: 'Separation of powers in government',
    thinker: 'Montesquieu',
    distractors: ['John Locke', 'Jean-Jacques Rousseau', 'Voltaire'],
    era: '1748',
    context:
        'Montesquieu\'s split into legislative, executive, and judicial branches became the skeleton of the U.S. Constitution.',
  ),
  IdeaQuestion(
    field: IdeaField.politics,
    idea: 'Life without government is "nasty, brutish, and short"',
    thinker: 'Thomas Hobbes',
    distractors: ['John Locke', 'Jean-Jacques Rousseau', 'Niccolò Machiavelli'],
    era: '1651',
    context:
        'Hobbes\'s "Leviathan" argued people trade freedom to an absolute sovereign to escape a war of all against all.',
  ),
  IdeaQuestion(
    field: IdeaField.politics,
    idea: 'Hard-nosed realism — power over morality in statecraft',
    thinker: 'Niccolò Machiavelli',
    distractors: ['Thomas Hobbes', 'John Locke', 'Sun Tzu'],
    era: '1532',
    context:
        'Some read "The Prince" as a sincere manual for tyrants, others as biting satire — scholars still argue which.',
  ),
  IdeaQuestion(
    field: IdeaField.politics,
    idea: 'Government rests on the consent of the governed',
    thinker: 'John Locke',
    distractors: ['Thomas Hobbes', 'Montesquieu', 'Jean-Jacques Rousseau'],
    era: '1689',
    context:
        'Locke\'s natural rights to "life, liberty, and property" echo almost word-for-word in the Declaration of Independence.',
  ),

  // ── PSYCHOLOGY ─────────────────────────────────────────────────────────────
  IdeaQuestion(
    field: IdeaField.psychology,
    idea: 'The unconscious mind and psychoanalysis',
    thinker: 'Sigmund Freud',
    distractors: ['Carl Jung', 'Alfred Adler', 'Wilhelm Wundt'],
    era: '1900',
    context:
        'Philosophers spoke of an unconscious before Freud — but he built the first full theory and clinical method around it.',
  ),
  IdeaQuestion(
    field: IdeaField.psychology,
    idea: 'The collective unconscious and archetypes',
    thinker: 'Carl Jung',
    distractors: ['Sigmund Freud', 'Alfred Adler', 'Ivan Pavlov'],
    era: '1910s',
    context:
        'Jung was Freud\'s heir-apparent until they split bitterly over how deep and shared the unconscious really goes.',
  ),
  IdeaQuestion(
    field: IdeaField.psychology,
    idea: 'Classical conditioning (the salivating dogs)',
    thinker: 'Ivan Pavlov',
    distractors: ['B.F. Skinner', 'John B. Watson', 'Sigmund Freud'],
    era: 'c. 1900',
    context:
        'Pavlov was a physiologist studying digestion — the conditioned reflex was almost an accidental discovery.',
  ),
  IdeaQuestion(
    field: IdeaField.psychology,
    idea: 'Operant conditioning — behavior shaped by reward',
    thinker: 'B.F. Skinner',
    distractors: ['Ivan Pavlov', 'John B. Watson', 'Edward Thorndike'],
    era: '1930s',
    context:
        'Edward Thorndike\'s "law of effect" came first; Skinner systematized it into the science of reinforcement.',
  ),
  IdeaQuestion(
    field: IdeaField.psychology,
    idea: 'The hierarchy of needs',
    thinker: 'Abraham Maslow',
    distractors: ['Carl Rogers', 'Sigmund Freud', 'Erik Erikson'],
    era: '1943',
    context:
        'The famous pyramid diagram wasn\'t drawn by Maslow himself — textbook writers added it decades later.',
  ),
];
