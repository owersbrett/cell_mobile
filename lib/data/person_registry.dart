/// The people registry — every real human name-dropped in LEARN content gets a
/// tappable profile card. This is the SSOT for who those people are.
///
/// How linking works: [PersonRegistry.match] scans lesson text for any [aliases]
/// string (case-sensitive, whole-word) and returns the [Person] so the renderer
/// can make that span tappable. Add a person here the moment their name lands in
/// content — a name with no entry simply renders as plain text (no dead links).
///
/// Facts are the payload of the card: 2–4 tight, genuinely-interesting lines
/// (teaching tool, not word vomit). [url] opens the reader's browser to learn
/// more (Wikipedia by default — a stable, always-available destination).
library;

class Person {
  final String id;
  final String fullName;

  /// Every literal spelling that appears in content (e.g. 'Leibniz',
  /// 'Gottfried Leibniz'). Matched case-sensitively as whole words.
  final List<String> aliases;

  /// Lifespan line, e.g. '1646–1716' or 'b. 1942'.
  final String lifespan;

  /// One-line identity, e.g. 'Mathematician & philosopher'.
  final String role;

  /// 2–4 short, interesting facts. Each is one card row.
  final List<String> facts;

  /// Learn-more destination (opens in the reader's browser).
  final String url;

  const Person({
    required this.id,
    required this.fullName,
    required this.aliases,
    required this.lifespan,
    required this.role,
    required this.facts,
    required this.url,
  });

  /// The card medallion monogram — first letters of the first and last words.
  String get monogram {
    final parts =
        fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class PersonRegistry {
  PersonRegistry._();

  static const List<Person> all = _people;

  /// Longest aliases first, so 'Gottfried Leibniz' wins over 'Leibniz' when both
  /// could match at the same spot.
  static final List<PersonAlias> _sortedAliases = () {
    final out = <PersonAlias>[];
    for (final p in _people) {
      for (final a in p.aliases) {
        out.add(PersonAlias(a, p));
      }
    }
    out.sort((x, y) => y.text.length.compareTo(x.text.length));
    return out;
  }();

  static Person? byId(String id) {
    for (final p in _people) {
      if (p.id == id) return p;
    }
    return null;
  }

  static List<PersonAlias> get aliasesByLengthDesc => _sortedAliases;
}

/// One matchable name form paired with the person it resolves to.
class PersonAlias {
  final String text;
  final Person person;
  const PersonAlias(this.text, this.person);
}

const List<Person> _people = [
  Person(
    id: 'leibniz',
    fullName: 'Gottfried Leibniz',
    aliases: ['Gottfried Leibniz', 'Leibniz'],
    lifespan: '1646–1716',
    role: 'Mathematician & philosopher',
    facts: [
      'Co-invented calculus independently of Newton — and it is his notation (∫ and dx) that the world still uses.',
      'Published a full account of binary arithmetic in 1703, reading the 1s and 0s theologically as "creation from the void".',
      'Built a mechanical calculator, the Stepped Reckoner, that could multiply and divide — centuries before electronics.',
    ],
    url: 'https://en.wikipedia.org/wiki/Gottfried_Wilhelm_Leibniz',
  ),
  Person(
    id: 'boole',
    fullName: 'George Boole',
    aliases: ['George Boole', 'Boole'],
    lifespan: '1815–1864',
    role: 'Mathematician & logician',
    facts: [
      'Largely self-taught, he became a professor without ever holding a university degree.',
      'Showed in 1854 that logic itself — AND, OR, NOT — could be done as algebra on just two values.',
      'His "Boolean algebra" sat unused for over 80 years until it became the mathematical bedrock of every digital computer.',
    ],
    url: 'https://en.wikipedia.org/wiki/George_Boole',
  ),
  Person(
    id: 'shannon',
    fullName: 'Claude Shannon',
    aliases: ['Claude Shannon', 'Shannon'],
    lifespan: '1916–2001',
    role: 'Founder of information theory',
    facts: [
      'His 1948 paper founded information theory and was the first to put the word "bit" in print — a term he credited to colleague John Tukey.',
      'As a grad student he showed electrical switches could carry out Boolean logic, the idea every chip is built on.',
      'An inveterate tinkerer, he built a juggling machine, a rocket-powered frisbee, and a maze-solving mechanical mouse.',
    ],
    url: 'https://en.wikipedia.org/wiki/Claude_Shannon',
  ),
  Person(
    id: 'godel',
    fullName: 'Kurt Gödel',
    aliases: ['Kurt Gödel', 'Gödel'],
    lifespan: '1906–1978',
    role: 'Logician',
    facts: [
      'His 1931 incompleteness theorems proved that any consistent mathematical system has true statements it can never prove.',
      'It quietly ended a century-long dream of putting all of mathematics on one complete, provable foundation.',
      'A close friend of Einstein at Princeton, he even found solutions to relativity that allow travel into the past.',
    ],
    url: 'https://en.wikipedia.org/wiki/Kurt_G%C3%B6del',
  ),
  Person(
    id: 'cantor',
    fullName: 'Georg Cantor',
    aliases: ['Georg Cantor', 'Cantor'],
    lifespan: '1845–1918',
    role: 'Mathematician',
    facts: [
      'Proved that some infinities are literally bigger than others — the infinity of the reals dwarfs the infinity of counting numbers.',
      'Created set theory, now the shared language underlying nearly all of modern mathematics.',
      'His ideas were attacked as "a disease" in his lifetime; today they are foundational and uncontroversial.',
    ],
    url: 'https://en.wikipedia.org/wiki/Georg_Cantor',
  ),
  Person(
    id: 'newton',
    fullName: 'Isaac Newton',
    aliases: ['Isaac Newton', 'Newton'],
    lifespan: '1643–1727',
    role: 'Physicist & mathematician',
    facts: [
      'His law of universal gravitation explained the fall of an apple and the orbit of the Moon with a single equation.',
      'Co-invented calculus, split white light into the spectrum with a prism, and built the first reflecting telescope.',
      'Later ran England\'s Royal Mint, personally hunting down counterfeiters and sending several to the gallows.',
    ],
    url: 'https://en.wikipedia.org/wiki/Isaac_Newton',
  ),
  Person(
    id: 'einstein',
    fullName: 'Albert Einstein',
    aliases: ['Albert Einstein', 'Einstein'],
    lifespan: '1879–1955',
    role: 'Theoretical physicist',
    facts: [
      'In one 1905 "miracle year" he published relativity, E=mc², and the work on light quanta that seeded quantum theory.',
      'His Nobel Prize was for the photoelectric effect — not relativity, which remained too controversial.',
      'General relativity recast gravity not as a force but as the curving of spacetime itself.',
    ],
    url: 'https://en.wikipedia.org/wiki/Albert_Einstein',
  ),
  Person(
    id: 'galileo',
    fullName: 'Galileo Galilei',
    aliases: ['Galileo Galilei', 'Galileo'],
    lifespan: '1564–1642',
    role: 'Astronomer & physicist',
    facts: [
      'Turned a new invention — the telescope — to the sky and found Jupiter\'s moons, ending Earth-centred certainty.',
      'Championed the idea that the Earth orbits the Sun, and was tried by the Inquisition and put under house arrest for it.',
      'Often called the "father of the scientific method" for insisting nature be read through experiment and measurement.',
    ],
    url: 'https://en.wikipedia.org/wiki/Galileo_Galilei',
  ),
  Person(
    id: 'kepler',
    fullName: 'Johannes Kepler',
    aliases: ['Johannes Kepler', 'Kepler'],
    lifespan: '1571–1630',
    role: 'Astronomer & mathematician',
    facts: [
      'Discovered that planets orbit in ellipses, not perfect circles — his three laws still govern spaceflight today.',
      'Worked from Tycho Brahe\'s obsessively precise observations, wringing the truth out of the raw numbers.',
      'Also wrote what many call the first science-fiction story, a dreamt voyage to the Moon.',
    ],
    url: 'https://en.wikipedia.org/wiki/Johannes_Kepler',
  ),
  Person(
    id: 'hubble',
    fullName: 'Edwin Hubble',
    aliases: ['Edwin Hubble', 'Hubble'],
    lifespan: '1889–1953',
    role: 'Astronomer',
    facts: [
      'Proved the "spiral nebulae" were entire other galaxies — overnight the known universe grew a billionfold.',
      'Found that distant galaxies race away from us faster the farther they are: the first evidence of an expanding universe.',
      'The Hubble Space Telescope carries his name.',
    ],
    url: 'https://en.wikipedia.org/wiki/Edwin_Hubble',
  ),
  Person(
    id: 'planck',
    fullName: 'Max Planck',
    aliases: ['Max Planck', 'Planck'],
    lifespan: '1858–1947',
    role: 'Theoretical physicist',
    facts: [
      'To fix a stubborn problem about hot glowing objects, he proposed in 1900 that energy comes in discrete packets — quanta.',
      'That reluctant guess launched quantum mechanics, arguably the most successful theory in all of physics.',
      'The Planck length and Planck time — the smallest physically meaningful scales — bear his name.',
    ],
    url: 'https://en.wikipedia.org/wiki/Max_Planck',
  ),
  Person(
    id: 'bohr',
    fullName: 'Niels Bohr',
    aliases: ['Niels Bohr', 'Bohr'],
    lifespan: '1885–1962',
    role: 'Physicist',
    facts: [
      'His 1913 model of the atom put electrons in fixed orbits that jump between energy levels — the "quantum leap".',
      'His Copenhagen institute became the beating heart of quantum physics, training a generation of laureates.',
      'Debated the meaning of quantum theory with Einstein for decades in one of science\'s greatest intellectual duels.',
    ],
    url: 'https://en.wikipedia.org/wiki/Niels_Bohr',
  ),
  Person(
    id: 'heisenberg',
    fullName: 'Werner Heisenberg',
    aliases: ['Werner Heisenberg', 'Heisenberg'],
    lifespan: '1901–1976',
    role: 'Theoretical physicist',
    facts: [
      'His uncertainty principle says you cannot know a particle\'s exact position and momentum at once — a hard limit of nature.',
      'His 1925 breakthrough at just 23 became the first complete formulation of quantum mechanics — soon recast as "matrix mechanics" by Born and Jordan.',
      'Led Germany\'s wartime nuclear program, a role still debated by historians.',
    ],
    url: 'https://en.wikipedia.org/wiki/Werner_Heisenberg',
  ),
  Person(
    id: 'schrodinger',
    fullName: 'Erwin Schrödinger',
    aliases: ['Erwin Schrödinger', 'Schrödinger'],
    lifespan: '1887–1961',
    role: 'Theoretical physicist',
    facts: [
      'His wave equation is to quantum mechanics what Newton\'s laws are to everyday motion.',
      'Invented the "Schrödinger\'s cat" thought experiment to show how strange quantum superposition becomes at human scale.',
      'His little book "What Is Life?" inspired the biologists who went on to discover the structure of DNA.',
    ],
    url: 'https://en.wikipedia.org/wiki/Erwin_Schr%C3%B6dinger',
  ),
  Person(
    id: 'dirac',
    fullName: 'Paul Dirac',
    aliases: ['Paul Dirac', 'Dirac'],
    lifespan: '1902–1984',
    role: 'Theoretical physicist',
    facts: [
      'His equation married quantum mechanics with relativity — and predicted antimatter before anyone had seen it.',
      'Antimatter (the positron) was found four years later, exactly as the math demanded.',
      'Famously terse and precise, he is a patron saint of the idea that beautiful equations tend to be true.',
    ],
    url: 'https://en.wikipedia.org/wiki/Paul_Dirac',
  ),
  Person(
    id: 'pauli',
    fullName: 'Wolfgang Pauli',
    aliases: ['Wolfgang Pauli', 'Pauli'],
    lifespan: '1900–1958',
    role: 'Theoretical physicist',
    facts: [
      'His exclusion principle — no two electrons in the same state — is why atoms have structure and matter is solid.',
      'Predicted the neutrino in 1930 to save energy conservation; it took 26 years to detect.',
      'Colleagues joked about the "Pauli effect": experiments would break the moment he walked into the lab.',
    ],
    url: 'https://en.wikipedia.org/wiki/Wolfgang_Pauli',
  ),
  Person(
    id: 'maxwell',
    fullName: 'James Clerk Maxwell',
    aliases: ['James Clerk Maxwell', 'Maxwell'],
    lifespan: '1831–1879',
    role: 'Physicist',
    facts: [
      'His four equations unified electricity and magnetism — and revealed that light itself is an electromagnetic wave.',
      'Produced the first durable colour photograph in 1861.',
      'His statistical work on gases underpins the entire field of thermodynamics.',
    ],
    url: 'https://en.wikipedia.org/wiki/James_Clerk_Maxwell',
  ),
  Person(
    id: 'feynman',
    fullName: 'Richard Feynman',
    aliases: ['Richard Feynman', 'Feynman'],
    lifespan: '1918–1988',
    role: 'Theoretical physicist',
    facts: [
      'Shared a Nobel Prize for quantum electrodynamics and invented the "Feynman diagrams" physicists sketch to this day.',
      'On live TV he dunked an O-ring in ice water to expose the cause of the Challenger disaster.',
      'A legendary teacher and prankster who cracked safes at Los Alamos for fun.',
    ],
    url: 'https://en.wikipedia.org/wiki/Richard_Feynman',
  ),
  Person(
    id: 'wheeler',
    fullName: 'John Wheeler',
    aliases: ['John Wheeler', 'Wheeler'],
    lifespan: '1911–2008',
    role: 'Theoretical physicist',
    facts: [
      'Popularised the term "black hole" and coined "wormhole" and "it from bit".',
      'Worked with Bohr on nuclear fission and mentored Feynman and many other giants.',
      'Championed the radical idea that information may be the deepest layer of physical reality.',
    ],
    url: 'https://en.wikipedia.org/wiki/John_Archibald_Wheeler',
  ),
  Person(
    id: 'turing',
    fullName: 'Alan Turing',
    aliases: ['Alan Turing', 'Turing'],
    lifespan: '1912–1954',
    role: 'Mathematician & computing pioneer',
    facts: [
      'His 1936 "Turing machine" defined what it means for anything to be computable — the blueprint of every computer.',
      'Helped crack the Nazi Enigma code at Bletchley Park, shortening World War II by an estimated two years.',
      'Proposed the "Turing test" for machine intelligence, still argued over in the age of AI.',
    ],
    url: 'https://en.wikipedia.org/wiki/Alan_Turing',
  ),
  Person(
    id: 'von-neumann',
    fullName: 'John von Neumann',
    aliases: ['John von Neumann', 'von Neumann'],
    lifespan: '1903–1957',
    role: 'Mathematician & polymath',
    facts: [
      'The "von Neumann architecture" — a processor sharing memory for code and data — describes almost every computer built since.',
      'Made deep contributions to quantum mechanics, game theory, and the design of the atomic bomb.',
      'His mental arithmetic and recall were so fast a colleague joked he "learned to do a remarkable imitation of" a human being.',
    ],
    url: 'https://en.wikipedia.org/wiki/John_von_Neumann',
  ),
  Person(
    id: 'wiener',
    fullName: 'Norbert Wiener',
    aliases: ['Norbert Wiener', 'Wiener'],
    lifespan: '1894–1964',
    role: 'Mathematician',
    facts: [
      'Founded cybernetics — the science of control and feedback in animals and machines alike.',
      'A child prodigy who graduated high school at 11 and earned his Harvard PhD at 18.',
      'His wartime work on guided anti-aircraft fire seeded modern ideas of automation and self-correcting systems.',
    ],
    url: 'https://en.wikipedia.org/wiki/Norbert_Wiener',
  ),
  Person(
    id: 'de-morgan',
    fullName: 'Augustus De Morgan',
    aliases: ['Augustus De Morgan', 'De Morgan'],
    lifespan: '1806–1871',
    role: 'Mathematician & logician',
    facts: [
      '"De Morgan\'s laws" — how NOT distributes over AND and OR — are drilled into every logic and programming student.',
      'He introduced the modern term "mathematical induction" and gave it an early rigorous treatment.',
      'A witty writer, he coined much of the vocabulary of modern symbolic logic.',
    ],
    url: 'https://en.wikipedia.org/wiki/Augustus_De_Morgan',
  ),
  Person(
    id: 'euler',
    fullName: 'Leonhard Euler',
    aliases: ['Leonhard Euler', 'Euler'],
    lifespan: '1707–1783',
    role: 'Mathematician',
    facts: [
      'The most prolific mathematician in history — his collected works fill some 80 large volumes.',
      'Gave us the notation e, i, and f(x), and the "most beautiful equation", e^(iπ)+1=0.',
      'Kept producing landmark mathematics for years after going completely blind.',
    ],
    url: 'https://en.wikipedia.org/wiki/Leonhard_Euler',
  ),
  Person(
    id: 'gauss',
    fullName: 'Carl Friedrich Gauss',
    aliases: ['Carl Friedrich Gauss', 'Gauss'],
    lifespan: '1777–1855',
    role: 'Mathematician',
    facts: [
      'Called the "Prince of Mathematicians"; as a schoolboy he summed 1 to 100 in seconds by pairing the ends.',
      'Contributed foundational work to number theory, statistics, geometry, and the study of magnetism.',
      'The bell curve (Gaussian distribution) and the unit of magnetic field both carry his name.',
    ],
    url: 'https://en.wikipedia.org/wiki/Carl_Friedrich_Gauss',
  ),
  Person(
    id: 'riemann',
    fullName: 'Bernhard Riemann',
    aliases: ['Bernhard Riemann', 'Riemann'],
    lifespan: '1826–1866',
    role: 'Mathematician',
    facts: [
      'His curved-space geometry, largely unused for some 60 years, became the exact mathematics Einstein needed for general relativity.',
      'The Riemann hypothesis, about the pattern of the primes, is one of the greatest unsolved problems in mathematics.',
      'Reshaped how mathematicians think about integration, surfaces, and higher dimensions — all before dying at 39.',
    ],
    url: 'https://en.wikipedia.org/wiki/Bernhard_Riemann',
  ),
  Person(
    id: 'cauchy',
    fullName: 'Augustin-Louis Cauchy',
    aliases: ['Augustin-Louis Cauchy', 'Cauchy'],
    lifespan: '1789–1857',
    role: 'Mathematician',
    facts: [
      'Put calculus on rigorous footing by defining limits and continuity precisely — the version taught today.',
      'One of the most prolific mathematicians ever, with concepts across analysis, physics, and group theory named for him.',
    ],
    url: 'https://en.wikipedia.org/wiki/Augustin-Louis_Cauchy',
  ),
  Person(
    id: 'weierstrass',
    fullName: 'Karl Weierstrass',
    aliases: ['Karl Weierstrass', 'Weierstrass'],
    lifespan: '1815–1897',
    role: 'Mathematician',
    facts: [
      'The "father of modern analysis", he made the foundations of calculus airtight with the ε–δ definition of a limit.',
      'Spent years as an obscure schoolteacher before a single paper vaulted him to a Berlin professorship.',
      'Built a curve that is continuous everywhere yet has a well-defined slope nowhere — a jagged "monster" that stunned mathematicians.',
    ],
    url: 'https://en.wikipedia.org/wiki/Karl_Weierstrass',
  ),
  Person(
    id: 'hilbert',
    fullName: 'David Hilbert',
    aliases: ['David Hilbert', 'Hilbert'],
    lifespan: '1862–1943',
    role: 'Mathematician',
    facts: [
      'In 1900 he posed 23 unsolved problems that steered a century of mathematical research.',
      'His dream of a complete, provable mathematics was the very thing Gödel later showed to be impossible.',
      '"Hilbert space" is a cornerstone of quantum mechanics.',
    ],
    url: 'https://en.wikipedia.org/wiki/David_Hilbert',
  ),
  Person(
    id: 'poincare',
    fullName: 'Henri Poincaré',
    aliases: ['Henri Poincaré', 'Poincaré'],
    lifespan: '1854–1912',
    role: 'Mathematician & physicist',
    facts: [
      'A founder of chaos theory: he found that even three orbiting bodies can behave unpredictably forever.',
      'Came within a whisker of special relativity before Einstein.',
      'The Poincaré conjecture stood for a century until Grigori Perelman proved it (2002–03); he then declined both the Fields Medal and a million-dollar prize.',
    ],
    url: 'https://en.wikipedia.org/wiki/Henri_Poincar%C3%A9',
  ),
  Person(
    id: 'noether',
    fullName: 'Emmy Noether',
    aliases: ['Emmy Noether', 'Noether'],
    lifespan: '1882–1935',
    role: 'Mathematician',
    facts: [
      'Noether\'s theorem links every symmetry in physics to a conservation law — why energy and momentum are conserved.',
      'Einstein praised her as the most significant creative mathematical genius since the higher education of women began.',
      'She lectured for years without pay or title because universities refused to hire a woman.',
    ],
    url: 'https://en.wikipedia.org/wiki/Emmy_Noether',
  ),
  Person(
    id: 'laplace',
    fullName: 'Pierre-Simon Laplace',
    aliases: ['Pierre-Simon Laplace', 'Laplace'],
    lifespan: '1749–1827',
    role: 'Mathematician & astronomer',
    facts: [
      'Imagined "Laplace\'s demon" — an intellect that, knowing every particle, could predict the entire future.',
      'Showed the solar system is stable over vast timescales, work sometimes called celestial mechanics\' bible.',
      'Made statistics and probability into rigorous mathematical tools.',
    ],
    url: 'https://en.wikipedia.org/wiki/Pierre-Simon_Laplace',
  ),
  Person(
    id: 'fibonacci',
    fullName: 'Leonardo Fibonacci',
    aliases: ['Leonardo Fibonacci', 'Fibonacci'],
    lifespan: 'c. 1170–1250',
    role: 'Mathematician',
    facts: [
      'His 1202 book introduced Europe to the Hindu–Arabic digits 0–9 we still use, replacing clumsy Roman numerals.',
      'The Fibonacci sequence (1, 1, 2, 3, 5, 8…) appears in sunflower spirals, pinecones, and shells.',
    ],
    url: 'https://en.wikipedia.org/wiki/Fibonacci',
  ),
  Person(
    id: 'brahmagupta',
    fullName: 'Brahmagupta',
    aliases: ['Brahmagupta'],
    lifespan: '598–668',
    role: 'Indian mathematician & astronomer',
    facts: [
      'Wrote the first known rules for arithmetic with zero as a number in its own right, in 628 CE.',
      'Worked freely with negative numbers, describing them as "debts" centuries before Europe accepted them.',
    ],
    url: 'https://en.wikipedia.org/wiki/Brahmagupta',
  ),
  Person(
    id: 'ramanujan',
    fullName: 'Srinivasa Ramanujan',
    aliases: ['Srinivasa Ramanujan', 'Ramanujan'],
    lifespan: '1887–1920',
    role: 'Mathematician',
    facts: [
      'A largely self-taught clerk from India who mailed astonishing formulas to Cambridge and stunned the mathematical world.',
      'Filled notebooks with thousands of results — some only proven true decades after his death at 32.',
      'Said his theorems came to him in dreams from a family goddess.',
    ],
    url: 'https://en.wikipedia.org/wiki/Srinivasa_Ramanujan',
  ),
  Person(
    id: 'lie',
    fullName: 'Sophus Lie',
    aliases: ['Sophus Lie', 'Lie'],
    lifespan: '1842–1899',
    role: 'Mathematician',
    facts: [
      '"Lie groups" — his mathematics of continuous symmetry — are now central to modern particle physics.',
      'Was briefly jailed as a suspected spy while hiking across France, and did mathematics in his cell.',
    ],
    url: 'https://en.wikipedia.org/wiki/Sophus_Lie',
  ),
  Person(
    id: 'klein',
    fullName: 'Felix Klein',
    aliases: ['Felix Klein', 'Klein'],
    lifespan: '1849–1925',
    role: 'Mathematician',
    facts: [
      'Reframed geometry as the study of what stays unchanged under a group of transformations — the "Erlangen program".',
      'The Klein bottle, a surface with no inside or outside, is named for him.',
    ],
    url: 'https://en.wikipedia.org/wiki/Felix_Klein',
  ),
  Person(
    id: 'ruelle',
    fullName: 'David Ruelle',
    aliases: ['David Ruelle', 'Ruelle'],
    lifespan: 'b. 1935',
    role: 'Mathematical physicist',
    facts: [
      'Co-coined the term "strange attractor", a key idea in how order hides inside chaos.',
      'Helped build the modern mathematical theory of turbulence and chaotic systems.',
    ],
    url: 'https://en.wikipedia.org/wiki/David_Ruelle',
  ),
  Person(
    id: 'takens',
    fullName: 'Floris Takens',
    aliases: ['Floris Takens', 'Takens'],
    lifespan: '1940–2010',
    role: 'Mathematician',
    facts: [
      'Takens\' theorem shows you can reconstruct a whole chaotic system\'s behaviour from a single stream of measurements.',
      'With Ruelle, proposed the modern picture of how smooth flows tip over into turbulence.',
    ],
    url: 'https://en.wikipedia.org/wiki/Floris_Takens',
  ),
  Person(
    id: 'russell',
    fullName: 'Bertrand Russell',
    aliases: ['Bertrand Russell', 'Russell'],
    lifespan: '1872–1970',
    role: 'Philosopher & logician',
    facts: [
      'His paradox about "the set of all sets that don\'t contain themselves" shook the foundations of mathematics.',
      'Spent a decade co-writing Principia Mathematica, trying to derive all math from pure logic.',
      'Won the Nobel Prize in Literature and was jailed twice for anti-war activism.',
    ],
    url: 'https://en.wikipedia.org/wiki/Bertrand_Russell',
  ),
  Person(
    id: 'hawking',
    fullName: 'Stephen Hawking',
    aliases: ['Stephen Hawking', 'Hawking'],
    lifespan: '1942–2018',
    role: 'Theoretical physicist',
    facts: [
      'Showed that black holes aren\'t truly black — they slowly glow and evaporate via "Hawking radiation".',
      'Did his most famous work while living for decades with motor neurone disease, speaking through a voice synthesizer.',
      '"A Brief History of Time" sold more than 25 million copies and put cosmology on bestseller lists.',
    ],
    url: 'https://en.wikipedia.org/wiki/Stephen_Hawking',
  ),
  Person(
    id: 'aristotle',
    fullName: 'Aristotle',
    aliases: ['Aristotle'],
    lifespan: '384–322 BCE',
    role: 'Greek philosopher',
    facts: [
      'Tutored by Plato and tutor to Alexander the Great, he wrote foundational works on logic, biology, ethics, and physics.',
      'Invented formal logic — the syllogism — which stood essentially unchallenged for 2,000 years.',
      'His mistaken physics (heavier things fall faster) also ruled unquestioned until Galileo tested it.',
    ],
    url: 'https://en.wikipedia.org/wiki/Aristotle',
  ),
  Person(
    id: 'plato',
    fullName: 'Plato',
    aliases: ['Plato'],
    lifespan: 'c. 428–348 BCE',
    role: 'Greek philosopher',
    facts: [
      'Founded the Academy in Athens, often called the Western world\'s first university.',
      'His "theory of Forms" — that perfect ideals lie behind imperfect reality — still shapes how we talk about mathematics.',
      'Nearly all his work survives as dialogues starring his teacher, Socrates.',
    ],
    url: 'https://en.wikipedia.org/wiki/Plato',
  ),
  Person(
    id: 'aquinas',
    fullName: 'Thomas Aquinas',
    aliases: ['Thomas Aquinas', 'Aquinas'],
    lifespan: '1225–1274',
    role: 'Philosopher & theologian',
    facts: [
      'Fused Aristotle\'s philosophy with Christian theology in his monumental Summa Theologica.',
      'His "Five Ways" are still the classic philosophical arguments for a first cause of the universe.',
    ],
    url: 'https://en.wikipedia.org/wiki/Thomas_Aquinas',
  ),
  Person(
    id: 'descartes',
    fullName: 'René Descartes',
    aliases: ['René Descartes', 'Descartes'],
    lifespan: '1596–1650',
    role: 'Philosopher & mathematician',
    facts: [
      '"I think, therefore I am" was his bedrock of certainty after doubting everything else.',
      'Invented the coordinate system — those x and y axes are "Cartesian" after him — linking algebra to geometry.',
      'Framed the mind–body problem that consciousness researchers still wrestle with today.',
    ],
    url: 'https://en.wikipedia.org/wiki/Ren%C3%A9_Descartes',
  ),
  Person(
    id: 'spinoza',
    fullName: 'Baruch Spinoza',
    aliases: ['Baruch Spinoza', 'Spinoza'],
    lifespan: '1632–1677',
    role: 'Philosopher',
    facts: [
      'Argued that God and Nature are one and the same infinite substance — radical enough to get him expelled from his community.',
      'Ground optical lenses for a living rather than accept a university chair that might curb his freedom.',
      'Einstein said he believed in "Spinoza\'s God" — the order of nature itself.',
    ],
    url: 'https://en.wikipedia.org/wiki/Baruch_Spinoza',
  ),
  Person(
    id: 'hegel',
    fullName: 'Georg Wilhelm Friedrich Hegel',
    aliases: ['Georg Wilhelm Friedrich Hegel', 'Hegel'],
    lifespan: '1770–1831',
    role: 'Philosopher',
    facts: [
      'His "dialectic" — ideas colliding and resolving into higher ones — shaped philosophy, history, and politics for two centuries.',
      'Aimed to capture the whole of reality as a single unfolding system of thought.',
    ],
    url: 'https://en.wikipedia.org/wiki/Georg_Wilhelm_Friedrich_Hegel',
  ),
  Person(
    id: 'parmenides',
    fullName: 'Parmenides',
    aliases: ['Parmenides'],
    lifespan: 'c. 515 BCE–?',
    role: 'Greek philosopher',
    facts: [
      'Argued that change is an illusion and reality is one single, unchanging whole — "what is, is".',
      'His challenge forced later Greeks to explain how motion and variety are even possible.',
    ],
    url: 'https://en.wikipedia.org/wiki/Parmenides',
  ),
  Person(
    id: 'chalmers',
    fullName: 'David Chalmers',
    aliases: ['David Chalmers', 'Chalmers'],
    lifespan: 'b. 1966',
    role: 'Philosopher of mind',
    facts: [
      'Coined the "hard problem of consciousness": why any physical process feels like anything at all from the inside.',
      'A leading modern voice on whether machines could ever be conscious.',
    ],
    url: 'https://en.wikipedia.org/wiki/David_Chalmers',
  ),
  Person(
    id: 'tegmark',
    fullName: 'Max Tegmark',
    aliases: ['Max Tegmark', 'Tegmark'],
    lifespan: 'b. 1967',
    role: 'Physicist & cosmologist',
    facts: [
      'Proposes the "mathematical universe hypothesis" — that reality is not merely described by math but literally is math.',
      'An MIT professor who also co-founded a leading institute on the risks and future of artificial intelligence.',
    ],
    url: 'https://en.wikipedia.org/wiki/Max_Tegmark',
  ),
  Person(
    id: 'wigner',
    fullName: 'Eugene Wigner',
    aliases: ['Eugene Wigner', 'Wigner'],
    lifespan: '1902–1995',
    role: 'Theoretical physicist',
    facts: [
      'Won a Nobel Prize for bringing symmetry principles into the heart of quantum physics.',
      'His essay on "the unreasonable effectiveness of mathematics" asks why abstract math describes nature so eerily well.',
    ],
    url: 'https://en.wikipedia.org/wiki/Eugene_Wigner',
  ),
  Person(
    id: 'weinberg',
    fullName: 'Steven Weinberg',
    aliases: ['Steven Weinberg', 'Weinberg'],
    lifespan: '1933–2021',
    role: 'Theoretical physicist',
    facts: [
      'Shared a Nobel Prize for unifying two of nature\'s forces into the "electroweak" interaction.',
      'His book "The First Three Minutes" is a classic account of the newborn universe.',
      'Chased a "final theory" that would explain all of physics from one set of laws.',
    ],
    url: 'https://en.wikipedia.org/wiki/Steven_Weinberg',
  ),
  Person(
    id: 'hoyle',
    fullName: 'Fred Hoyle',
    aliases: ['Fred Hoyle', 'Hoyle'],
    lifespan: '1915–2001',
    role: 'Astronomer',
    facts: [
      'Worked out how stars forge carbon and heavier elements — the origin of the atoms in your body.',
      'Coined the term "Big Bang", ironically, while arguing against the theory.',
    ],
    url: 'https://en.wikipedia.org/wiki/Fred_Hoyle',
  ),
  Person(
    id: 'rubin',
    fullName: 'Vera Rubin',
    aliases: ['Vera Rubin', 'Rubin'],
    lifespan: '1928–2016',
    role: 'Astronomer',
    facts: [
      'Her measurements of spinning galaxies gave the strongest early evidence that most of the universe is invisible dark matter.',
      'Persisted through an era that barred women from major observatories, and inspired generations of astronomers.',
    ],
    url: 'https://en.wikipedia.org/wiki/Vera_Rubin',
  ),
  Person(
    id: 'casimir',
    fullName: 'Hendrik Casimir',
    aliases: ['Hendrik Casimir', 'Casimir'],
    lifespan: '1909–2000',
    role: 'Physicist',
    facts: [
      'Predicted that empty space itself pushes two nearby plates together — the "Casimir effect", a force from the vacuum.',
      'The effect proves that even a perfect vacuum is fizzing with quantum energy.',
    ],
    url: 'https://en.wikipedia.org/wiki/Hendrik_Casimir',
  ),
  Person(
    id: 'lamoreaux',
    fullName: 'Steve Lamoreaux',
    aliases: ['Steve Lamoreaux', 'Lamoreaux'],
    lifespan: 'b. 1958',
    role: 'Physicist',
    facts: [
      'In 1997 he made the first precise measurement of the Casimir force, confirming energy really can be drawn from the vacuum.',
    ],
    url: 'https://en.wikipedia.org/wiki/Steve_Lamoreaux',
  ),
  Person(
    id: 'torricelli',
    fullName: 'Evangelista Torricelli',
    aliases: ['Evangelista Torricelli', 'Torricelli'],
    lifespan: '1608–1647',
    role: 'Physicist & mathematician',
    facts: [
      'Invented the barometer in 1643 and created the first sustained vacuum, overturning "nature abhors a vacuum".',
      'The "torr", a unit of pressure, is named after him.',
    ],
    url: 'https://en.wikipedia.org/wiki/Evangelista_Torricelli',
  ),
  Person(
    id: 'guericke',
    fullName: 'Otto von Guericke',
    aliases: ['Otto von Guericke', 'Guericke'],
    lifespan: '1602–1686',
    role: 'Scientist & inventor',
    facts: [
      'Staged the famous Magdeburg hemispheres demo: two teams of horses couldn\'t pull apart two evacuated copper bowls.',
      'Built the first vacuum pump, turning the vacuum from philosophy into experiment.',
    ],
    url: 'https://en.wikipedia.org/wiki/Otto_von_Guericke',
  ),
  Person(
    id: 'wohler',
    fullName: 'Friedrich Wöhler',
    aliases: ['Friedrich Wöhler', 'Wöhler'],
    lifespan: '1800–1882',
    role: 'Chemist',
    facts: [
      'In 1828 he made urea — a substance of life — from plain chemicals, shattering the idea of a magical "vital force".',
      'That single experiment is often said to have founded organic chemistry.',
    ],
    url: 'https://en.wikipedia.org/wiki/Friedrich_W%C3%B6hler',
  ),
  Person(
    id: 'golgi',
    fullName: 'Camillo Golgi',
    aliases: ['Camillo Golgi', 'Golgi'],
    lifespan: '1843–1926',
    role: 'Physician & biologist',
    facts: [
      'His silver-staining method let scientists see individual nerve cells for the first time.',
      'The Golgi apparatus, the cell\'s packaging and shipping centre, bears his name.',
      'Shared the Nobel Prize with a rival whose opposing theory of the brain turned out to be the correct one.',
    ],
    url: 'https://en.wikipedia.org/wiki/Camillo_Golgi',
  ),
  Person(
    id: 'democritus',
    fullName: 'Democritus',
    aliases: ['Democritus'],
    lifespan: 'c. 460–370 BCE',
    role: 'Greek philosopher',
    facts: [
      'Proposed 2,400 years ago that everything is made of tiny indivisible pieces — "atoms" — separated by empty void.',
      'Reasoned his way there with no instruments at all; modern physics proved him broadly right.',
      'Known as the "laughing philosopher" for his cheerful outlook.',
    ],
    url: 'https://en.wikipedia.org/wiki/Democritus',
  ),

  // ── Chemistry / the elements ──
  Person(
    id: 'dmitri-mendeleev',
    fullName: 'Dmitri Mendeleev',
    aliases: ['Dmitri Mendeleev', 'Mendeleev'],
    lifespan: '1834–1907',
    role: 'Russian chemist who created the periodic table',
    facts: [
      'Arranged the first widely recognized periodic table (1869), ordering the elements by atomic weight and chemical family.',
      'Left gaps for undiscovered elements and predicted their properties — later found as scandium, gallium, and germanium.',
      'Element 101, mendelevium, is named in his honor.',
    ],
    url: 'https://en.wikipedia.org/wiki/Dmitri_Mendeleev',
  ),
  Person(
    id: 'vasili-samarsky-bykhovets',
    fullName: 'Vasili Samarsky-Bykhovets',
    aliases: ['Vasili Samarsky-Bykhovets', 'Samarsky'],
    lifespan: '1803–1870',
    role: 'Russian mining engineer — first person an element was named for',
    facts: [
      'As chief of the Russian mining corps, he gave mineralogists the Ural ore in which the mineral samarskite was found.',
      'Through that mineral the element samarium bears his name — making him the first person ever honored in an element.',
    ],
    url: 'https://en.wikipedia.org/wiki/Vassili_Samarsky-Bykhovets',
  ),
  Person(
    id: 'marie-curie',
    fullName: 'Marie Curie',
    aliases: ['Marie Curie'],
    lifespan: '1867–1934',
    role: 'Physicist & chemist, pioneer of radioactivity',
    facts: [
      'With her husband Pierre she discovered polonium (named for her native Poland) and radium in 1898.',
      'The only person ever to win Nobel Prizes in two different sciences — Physics (1903) and Chemistry (1911).',
      'Died of a blood disease linked to years of radiation exposure; element 96, curium, honors her and Pierre.',
    ],
    url: 'https://en.wikipedia.org/wiki/Marie_Curie',
  ),
  Person(
    id: 'pierre-curie',
    fullName: 'Pierre Curie',
    aliases: ['Pierre Curie'],
    lifespan: '1859–1906',
    role: 'French physicist, co-discoverer of radioactivity',
    facts: [
      'Shared the 1903 Nobel Prize in Physics with Marie Curie and Henri Becquerel for research on radioactivity.',
      'Helped isolate polonium and radium, and earlier discovered piezoelectricity with his brother.',
      'Killed in 1906 slipping under a horse-drawn cart in Paris; element 96, curium, honors him and Marie.',
    ],
    url: 'https://en.wikipedia.org/wiki/Pierre_Curie',
  ),
  Person(
    id: 'marguerite-perey',
    fullName: 'Marguerite Perey',
    aliases: ['Marguerite Perey', 'Perey'],
    lifespan: '1909–1975',
    role: 'French physicist who discovered francium',
    facts: [
      'Discovered francium in 1939 — the last element to be found in nature rather than made in a lab.',
      'Began as Marie Curie\'s assistant, then became the first woman elected to the French Académie des Sciences.',
    ],
    url: 'https://en.wikipedia.org/wiki/Marguerite_Perey',
  ),
  Person(
    id: 'glenn-seaborg',
    fullName: 'Glenn T. Seaborg',
    aliases: ['Glenn T. Seaborg', 'Glenn Seaborg', 'Seaborg'],
    lifespan: '1912–1999',
    role: 'American chemist, co-discoverer of plutonium',
    facts: [
      'Co-discovered ten elements including plutonium; shared the 1951 Nobel Prize in Chemistry.',
      'His actinide concept reshaped the periodic table into its modern form.',
      'Element 106, seaborgium, was the first element officially named after a living person.',
    ],
    url: 'https://en.wikipedia.org/wiki/Glenn_T._Seaborg',
  ),
  Person(
    id: 'lise-meitner',
    fullName: 'Lise Meitner',
    aliases: ['Lise Meitner', 'Meitner'],
    lifespan: '1878–1968',
    role: 'Austrian-Swedish physicist who explained nuclear fission',
    facts: [
      'With her nephew Otto Frisch, gave the theoretical explanation of nuclear fission (1938–39).',
      'Was passed over for the 1944 Nobel Prize, which went to her collaborator Otto Hahn alone.',
      'Element 109, meitnerium, is named in her honor.',
    ],
    url: 'https://en.wikipedia.org/wiki/Lise_Meitner',
  ),
  Person(
    id: 'otto-hahn',
    fullName: 'Otto Hahn',
    aliases: ['Otto Hahn'],
    lifespan: '1879–1968',
    role: 'German chemist, "father of nuclear chemistry"',
    facts: [
      'With Fritz Strassmann, discovered nuclear fission in 1938 by showing uranium splits into lighter elements.',
      'Won the 1944 Nobel Prize in Chemistry alone, though Lise Meitner supplied the theory behind the result.',
    ],
    url: 'https://en.wikipedia.org/wiki/Otto_Hahn',
  ),
  Person(
    id: 'wilhelm-rontgen',
    fullName: 'Wilhelm Conrad Röntgen',
    aliases: ['Wilhelm Conrad Röntgen', 'Wilhelm Röntgen', 'Röntgen'],
    lifespan: '1845–1923',
    role: 'German physicist who discovered X-rays',
    facts: [
      'Discovered X-rays in 1895 while studying cathode rays — and won the first-ever Nobel Prize in Physics (1901).',
      'Element 111, roentgenium, is named after him.',
    ],
    url: 'https://en.wikipedia.org/wiki/Wilhelm_R%C3%B6ntgen',
  ),
  Person(
    id: 'nicolaus-copernicus',
    fullName: 'Nicolaus Copernicus',
    aliases: ['Nicolaus Copernicus', 'Copernicus'],
    lifespan: '1473–1543',
    role: 'Renaissance astronomer who moved the Sun to the center',
    facts: [
      'Placed the Sun, not the Earth, at the center of the cosmos — the heliocentric model.',
      'His 1543 book triggered the Copernican Revolution; element 112, copernicium, is named for him.',
    ],
    url: 'https://en.wikipedia.org/wiki/Nicolaus_Copernicus',
  ),
  Person(
    id: 'georgy-flyorov',
    fullName: 'Georgy Flyorov',
    aliases: ['Georgy Flyorov'],
    lifespan: '1913–1990',
    role: 'Soviet nuclear physicist, superheavy-element pioneer',
    facts: [
      'Co-discovered spontaneous nuclear fission and founded the Dubna laboratory that made the heaviest elements.',
      'His 1942 letter to Stalin, noting the West had gone silent on fission, helped launch the Soviet bomb program.',
      'Element 114, flerovium, is named after him and his lab.',
    ],
    url: 'https://en.wikipedia.org/wiki/Georgy_Flyorov',
  ),
  Person(
    id: 'yuri-oganessian',
    fullName: 'Yuri Oganessian',
    aliases: ['Yuri Oganessian', 'Oganessian'],
    lifespan: 'b. 1933',
    role: 'Nuclear physicist, leader of superheavy-element synthesis',
    facts: [
      'Directed the Dubna research that synthesized the heaviest known elements using fusion of nuclei.',
      'Element 118, oganesson, is named after him — the only element named for a person still living.',
    ],
    url: 'https://en.wikipedia.org/wiki/Yuri_Oganessian',
  ),
  Person(
    id: 'ernest-rutherford',
    fullName: 'Ernest Rutherford',
    aliases: ['Ernest Rutherford'],
    lifespan: '1871–1937',
    role: 'New Zealand-born physicist, "father of nuclear physics"',
    facts: [
      'Discovered the atomic nucleus with the gold-foil experiment (1909) and named alpha, beta, and gamma radiation.',
      'First to artificially split the atom (1917); won the 1908 Nobel Prize in Chemistry.',
      'Element 104, rutherfordium, is named in his honor.',
    ],
    url: 'https://en.wikipedia.org/wiki/Ernest_Rutherford',
  ),
  Person(
    id: 'ernest-lawrence',
    fullName: 'Ernest Lawrence',
    aliases: ['Ernest Lawrence'],
    lifespan: '1901–1958',
    role: 'American physicist, inventor of the cyclotron',
    facts: [
      'Invented the cyclotron particle accelerator (1939 Nobel Prize) — the machine that created many new elements.',
      'Two US national laboratories and element 103, lawrencium, are named after him.',
    ],
    url: 'https://en.wikipedia.org/wiki/Ernest_Lawrence',
  ),
  Person(
    id: 'enrico-fermi',
    fullName: 'Enrico Fermi',
    aliases: ['Enrico Fermi'],
    lifespan: '1901–1954',
    role: 'Italian-American physicist, "architect of the nuclear age"',
    facts: [
      'Built the first self-sustaining nuclear chain reaction (Chicago Pile-1) in 1942.',
      'Won the 1938 Nobel Prize in Physics; element 100, fermium, is named for him.',
    ],
    url: 'https://en.wikipedia.org/wiki/Enrico_Fermi',
  ),
  Person(
    id: 'alfred-nobel',
    fullName: 'Alfred Nobel',
    aliases: ['Alfred Nobel'],
    lifespan: '1833–1896',
    role: 'Swedish chemist who endowed the Nobel Prizes',
    facts: [
      'Invented dynamite in 1867, a safer way to handle explosive nitroglycerin.',
      'Left most of his fortune to fund the Nobel Prizes; element 102, nobelium, is named for him.',
    ],
    url: 'https://en.wikipedia.org/wiki/Alfred_Nobel',
  ),
  Person(
    id: 'louis-camille-maillard',
    fullName: 'Louis-Camille Maillard',
    aliases: ['Louis-Camille Maillard'],
    lifespan: '1878–1936',
    role: 'French chemist and physician',
    facts: [
      'Described the 1912 browning reaction between amino acids and sugars that gives roasted and fried food its color and flavor.',
      'Also researched kidney disorders and how the body handles urea.',
    ],
    url: 'https://en.wikipedia.org/wiki/Louis_Camille_Maillard',
  ),

  // ── Particle physics ──
  Person(
    id: 'jj-thomson',
    fullName: 'J. J. Thomson',
    aliases: ['J.J. Thomson'],
    lifespan: '1856–1940',
    role: 'British physicist who discovered the electron',
    facts: [
      'Showed in 1897 that cathode rays are streams of tiny negative particles — the electron, the first subatomic particle found.',
      'Won the 1906 Nobel Prize; seven of his research assistants went on to win Nobels of their own.',
    ],
    url: 'https://en.wikipedia.org/wiki/J._J._Thomson',
  ),
  Person(
    id: 'frederick-reines',
    fullName: 'Frederick Reines',
    aliases: ['Reines'],
    lifespan: '1918–1998',
    role: 'American physicist who co-detected the neutrino',
    facts: [
      'With Clyde Cowan, ran the 1956 reactor experiment that first detected the neutrino — 26 years after it was predicted.',
      'Received the 1995 Nobel Prize for the detection; Cowan had died and could not share it.',
    ],
    url: 'https://en.wikipedia.org/wiki/Frederick_Reines',
  ),
  Person(
    id: 'clyde-cowan',
    fullName: 'Clyde Cowan',
    aliases: ['Cowan'],
    lifespan: '1919–1974',
    role: 'American physicist, co-detector of the neutrino',
    facts: [
      'Equal partner with Frederick Reines on the 1956 experiment that first caught a neutrino.',
      'Died two decades before the discovery earned the 1995 Nobel Prize, which cannot be awarded posthumously.',
    ],
    url: 'https://en.wikipedia.org/wiki/Clyde_Cowan',
  ),
  Person(
    id: 'ii-rabi',
    fullName: 'Isidor Isaac Rabi',
    aliases: ['I.I. Rabi'],
    lifespan: '1898–1988',
    role: 'American physicist; namer of the muon puzzle',
    facts: [
      'On learning the muon was an unpredicted heavy copy of the electron, he famously quipped "Who ordered that?"',
      'Won the 1944 Nobel Prize for the resonance method that later became the basis of NMR and MRI.',
    ],
    url: 'https://en.wikipedia.org/wiki/Isidor_Isaac_Rabi',
  ),
  Person(
    id: 'carl-anderson',
    fullName: 'Carl David Anderson',
    aliases: ['Carl David Anderson'],
    lifespan: '1905–1991',
    role: 'American physicist who discovered the positron and muon',
    facts: [
      'His 1932 cloud-chamber photo of the positron was the first proof of antimatter, winning a Nobel Prize at 31.',
      'In 1936, with his student Seth Neddermeyer, he discovered the muon in cosmic rays.',
    ],
    url: 'https://en.wikipedia.org/wiki/Carl_David_Anderson',
  ),
  Person(
    id: 'seth-neddermeyer',
    fullName: 'Seth Neddermeyer',
    aliases: ['Neddermeyer'],
    lifespan: '1907–1988',
    role: 'American physicist who co-discovered the muon',
    facts: [
      'As Carl Anderson\'s graduate student, co-discovered the muon in cosmic-ray tracks in 1936.',
      'Later proposed the implosion design for the plutonium bomb during the Manhattan Project.',
    ],
    url: 'https://en.wikipedia.org/wiki/Seth_Neddermeyer',
  ),
  Person(
    id: 'leon-lederman',
    fullName: 'Leon M. Lederman',
    aliases: ['Lederman'],
    lifespan: '1922–2018',
    role: 'American experimental physicist',
    facts: [
      'Co-ran the 1962 Brookhaven experiment showing the muon neutrino is a distinct particle from the electron neutrino.',
      'Shared the 1988 Nobel Prize for that discovery and the neutrino-beam method it introduced.',
    ],
    url: 'https://en.wikipedia.org/wiki/Leon_M._Lederman',
  ),
  Person(
    id: 'melvin-schwartz',
    fullName: 'Melvin Schwartz',
    aliases: ['Schwartz'],
    lifespan: '1932–2006',
    role: 'American physicist',
    facts: [
      'Devised the neutrino-beam technique that made the 1962 two-neutrino experiment possible.',
      'Shared the 1988 Nobel Prize with Lederman and Steinberger.',
    ],
    url: 'https://en.wikipedia.org/wiki/Melvin_Schwartz',
  ),
  Person(
    id: 'jack-steinberger',
    fullName: 'Jack Steinberger',
    aliases: ['Steinberger'],
    lifespan: '1921–2020',
    role: 'German-born American particle physicist',
    facts: [
      'Co-authored the 1962 experiment that discovered the muon neutrino as a second neutrino flavor.',
      'Shared the 1988 Nobel Prize with Lederman and Schwartz.',
    ],
    url: 'https://en.wikipedia.org/wiki/Jack_Steinberger',
  ),
  Person(
    id: 'martin-perl',
    fullName: 'Martin Perl',
    aliases: ['Martin Perl', 'Perl'],
    lifespan: '1927–2014',
    role: 'American physicist who discovered the tau lepton',
    facts: [
      'Found the tau — the heaviest lepton — at SLAC in the mid-1970s, opening the third generation of matter.',
      'Shared the 1995 Nobel Prize with Frederick Reines for pioneering lepton physics.',
    ],
    url: 'https://en.wikipedia.org/wiki/Martin_Lewis_Perl',
  ),
  Person(
    id: 'murray-gell-mann',
    fullName: 'Murray Gell-Mann',
    aliases: ['Gell-Mann'],
    lifespan: '1929–2019',
    role: 'American physicist who proposed the quark',
    facts: [
      'In 1964 he proposed that particles like protons are built from "quarks" — a word he took from James Joyce\'s Finnegans Wake.',
      'Won the 1969 Nobel Prize for classifying the elementary particles.',
    ],
    url: 'https://en.wikipedia.org/wiki/Murray_Gell-Mann',
  ),
  Person(
    id: 'george-zweig',
    fullName: 'George Zweig',
    aliases: ['Zweig'],
    lifespan: 'b. 1937',
    role: 'Physicist, independent proposer of the quark model',
    facts: [
      'In 1964, independently of Gell-Mann, proposed the same building blocks of matter but called them "aces".',
      'Later switched from particle physics to neuroscience, studying how the ear hears.',
    ],
    url: 'https://en.wikipedia.org/wiki/George_Zweig',
  ),
  Person(
    id: 'takaaki-kajita',
    fullName: 'Takaaki Kajita',
    aliases: ['Takaaki Kajita'],
    lifespan: 'b. 1959',
    role: 'Japanese physicist; neutrino oscillation',
    facts: [
      'His 1998 Super-Kamiokande results showed neutrinos change flavor in flight — proof that they have mass.',
      'Shared the 2015 Nobel Prize with Arthur McDonald for discovering neutrino oscillations.',
    ],
    url: 'https://en.wikipedia.org/wiki/Takaaki_Kajita',
  ),
  Person(
    id: 'arthur-mcdonald',
    fullName: 'Arthur B. McDonald',
    aliases: ['Arthur McDonald', 'McDonald'],
    lifespan: 'b. 1943',
    role: 'Canadian physicist; solar-neutrino oscillation',
    facts: [
      'Showed by 2001 that the Sun\'s "missing" neutrinos had changed flavor, not vanished.',
      'Shared the 2015 Nobel Prize with Takaaki Kajita for discovering neutrino oscillations.',
    ],
    url: 'https://en.wikipedia.org/wiki/Arthur_B._McDonald',
  ),
  Person(
    id: 'peter-higgs',
    fullName: 'Peter Higgs',
    aliases: ['Peter Higgs'],
    lifespan: '1929–2024',
    role: 'British physicist who predicted the Higgs boson',
    facts: [
      'In 1964 proposed the field that gives particles mass, predicting a new particle found at CERN in 2012 — nearly 50 years later.',
      'Shared the 2013 Nobel Prize with François Englert once the boson was confirmed.',
    ],
    url: 'https://en.wikipedia.org/wiki/Peter_Higgs',
  ),
  Person(
    id: 'francois-englert',
    fullName: 'François Englert',
    aliases: ['François Englert', 'Englert'],
    lifespan: '1932–2026',
    role: 'Belgian physicist, co-proposer of the mass-giving field',
    facts: [
      'With Robert Brout in 1964, described the field that gives particles mass — independently of and just before Higgs.',
      'Shared the 2013 Nobel Prize with Peter Higgs after the Higgs boson was found.',
    ],
    url: 'https://en.wikipedia.org/wiki/Fran%C3%A7ois_Englert',
  ),

  // ── Mathematics / logic / philosophy of the infinite ──
  Person(
    id: 'leopold-kronecker',
    fullName: 'Leopold Kronecker',
    aliases: ['Leopold Kronecker', 'Kronecker'],
    lifespan: '1823–1891',
    role: 'German mathematician and finitist',
    facts: [
      'Held that mathematics must be built from whole numbers by finite steps, and bitterly rejected Cantor\'s infinities.',
      'His attacks on Cantor are the classic example of how fiercely the new theory of infinity was resisted.',
    ],
    url: 'https://en.wikipedia.org/wiki/Leopold_Kronecker',
  ),
  Person(
    id: 'george-berkeley',
    fullName: 'George Berkeley',
    aliases: ['Bishop Berkeley'],
    lifespan: '1685–1753',
    role: 'Irish philosopher and bishop, critic of early calculus',
    facts: [
      'In 1734 he mocked the shaky logic of infinitesimals as "the ghosts of departed quantities".',
      'His critique was fair enough that it stood until Cauchy and Weierstrass made calculus rigorous a century later.',
    ],
    url: 'https://en.wikipedia.org/wiki/George_Berkeley',
  ),
  Person(
    id: 'abraham-robinson',
    fullName: 'Abraham Robinson',
    aliases: ['Abraham Robinson', 'Robinson'],
    lifespan: '1918–1974',
    role: 'Mathematician & logician, founder of non-standard analysis',
    facts: [
      'Around 1960 he built the hyperreal numbers — a rigorous system with genuine infinitesimals.',
      'His work vindicated Leibniz\'s original infinitesimal calculus roughly three centuries later.',
    ],
    url: 'https://en.wikipedia.org/wiki/Abraham_Robinson',
  ),
  Person(
    id: 'oliver-heaviside',
    fullName: 'Oliver Heaviside',
    aliases: ['Heaviside'],
    lifespan: '1850–1925',
    role: 'Self-taught English engineer, physicist & mathematician',
    facts: [
      'His operational calculus got correct answers decades before it was rigorously justified.',
      'He also recast Maxwell\'s equations into the compact vector form used today.',
    ],
    url: 'https://en.wikipedia.org/wiki/Oliver_Heaviside',
  ),
  Person(
    id: 'paul-cohen',
    fullName: 'Paul Cohen',
    aliases: ['Paul Cohen'],
    lifespan: '1934–2007',
    role: 'American mathematician & logician',
    facts: [
      'Proved in 1963 that the continuum hypothesis cannot be settled from the standard axioms of set theory — it is independent.',
      'Won the Fields Medal (1966), the only one ever awarded for mathematical logic.',
    ],
    url: 'https://en.wikipedia.org/wiki/Paul_Cohen',
  ),
  Person(
    id: 'john-conway',
    fullName: 'John Horton Conway',
    aliases: ['Conway'],
    lifespan: '1937–2020',
    role: 'English mathematician; games, groups, and play',
    facts: [
      'In the 1970s he built the surreal numbers — a vast number system holding the reals, infinities, and infinitesimals at once.',
      'Also invented the cellular automaton "Game of Life".',
    ],
    url: 'https://en.wikipedia.org/wiki/John_Horton_Conway',
  ),
  Person(
    id: 'jerome-keisler',
    fullName: 'Howard Jerome Keisler',
    aliases: ['Keisler'],
    lifespan: 'b. 1936',
    role: 'American mathematician & logician',
    facts: [
      'Wrote a first-year calculus textbook that teaches the subject directly with infinitesimals instead of limits.',
      'A student of Alfred Tarski, he worked in model theory.',
    ],
    url: 'https://en.wikipedia.org/wiki/Jerome_Keisler',
  ),
  Person(
    id: 'joseph-louis-lagrange',
    fullName: 'Joseph-Louis Lagrange',
    aliases: ['Joseph-Louis Lagrange'],
    lifespan: '1736–1813',
    role: 'Italian-French mathematician & astronomer',
    facts: [
      'The prime notation for a derivative, f′(x), is his.',
      'Founded the calculus of variations and rebuilt mechanics into what is now called Lagrangian mechanics.',
    ],
    url: 'https://en.wikipedia.org/wiki/Joseph-Louis_Lagrange',
  ),
  Person(
    id: 'pierre-de-fermat',
    fullName: 'Pierre de Fermat',
    aliases: ['Pierre de Fermat'],
    lifespan: '1607–1665',
    role: 'French lawyer and mathematician',
    facts: [
      'His method for finding maxima and minima anticipated the derivative — a smooth peak has zero slope.',
      'A founder of analytic geometry and probability, famous for Fermat\'s Last Theorem.',
    ],
    url: 'https://en.wikipedia.org/wiki/Pierre_de_Fermat',
  ),
  Person(
    id: 'alexis-clairaut',
    fullName: 'Alexis Clairaut',
    aliases: ['Alexis Clairaut'],
    lifespan: '1713–1765',
    role: 'French mathematician, astronomer & geophysicist',
    facts: [
      'His theorem says a well-behaved function\'s mixed second partial derivatives are equal — order of differentiation doesn\'t matter.',
      'Joined the expedition that confirmed Newton\'s prediction that the Earth is flattened at the poles.',
    ],
    url: 'https://en.wikipedia.org/wiki/Alexis_Clairaut',
  ),
  Person(
    id: 'george-green',
    fullName: 'George Green',
    aliases: ['George Green'],
    lifespan: '1793–1841',
    role: 'Self-taught English mathematical physicist — a miller by trade',
    facts: [
      'Largely self-educated while running his family\'s corn mill, he introduced the potential function and an early form of Green\'s theorem in 1828.',
      'His "Green\'s functions" became a central tool for solving the equations of physics.',
    ],
    url: 'https://en.wikipedia.org/wiki/George_Green_(mathematician)',
  ),
  Person(
    id: 'george-stokes',
    fullName: 'George Gabriel Stokes',
    aliases: ['George Gabriel Stokes'],
    lifespan: '1819–1903',
    role: 'Irish mathematician & physicist',
    facts: [
      'Stokes\' theorem, tying a surface integral to a loop around its edge, generalizes the Fundamental Theorem of Calculus.',
      'Co-authored the Navier–Stokes equations of fluid flow and held Newton\'s Cambridge chair for 54 years.',
    ],
    url: 'https://en.wikipedia.org/wiki/Sir_George_Stokes,_1st_Baronet',
  ),
  Person(
    id: 'philip-anderson',
    fullName: 'Philip Warren Anderson',
    aliases: ['Philip Anderson'],
    lifespan: '1923–2020',
    role: 'American theoretical physicist, founder of condensed-matter physics',
    facts: [
      'His 1972 essay "More Is Different" argued each level of nature has real laws you can\'t read off the level below — a landmark statement of emergence.',
      'Shared the 1977 Nobel Prize for work on disordered and magnetic materials.',
    ],
    url: 'https://en.wikipedia.org/wiki/Philip_W._Anderson',
  ),
  Person(
    id: 'nagarjuna',
    fullName: 'Nāgārjuna',
    aliases: ['Nāgārjuna'],
    lifespan: 'c. 150–250',
    role: 'Indian Buddhist philosopher, founder of Madhyamaka',
    facts: [
      'Developed śūnyatā ("emptiness") — that things have no fixed independent essence, existing only through dependence, not that nothing is real.',
      'His "Fundamental Verses on the Middle Way" shaped Buddhist thought for over a thousand years.',
    ],
    url: 'https://en.wikipedia.org/wiki/Nagarjuna',
  ),

  // ── Cosmology & the great-minds debate ──
  Person(
    id: 'hugh-everett',
    fullName: 'Hugh Everett III',
    aliases: ['Hugh Everett III', 'Hugh Everett', 'Everett'],
    lifespan: '1930–1982',
    role: 'Physicist who proposed the many-worlds interpretation',
    facts: [
      'His 1957 thesis proposed applying the Schrödinger equation to the observer too, doing away with wave-function collapse.',
      'Ignored in his lifetime, he left physics for defense analysis and never published a follow-up.',
    ],
    url: 'https://en.wikipedia.org/wiki/Hugh_Everett_III',
  ),
  Person(
    id: 'bryce-dewitt',
    fullName: 'Bryce DeWitt',
    aliases: ['Bryce DeWitt', 'DeWitt'],
    lifespan: '1923–2004',
    role: 'American theoretical physicist in quantum gravity',
    facts: [
      'Popularized Everett\'s idea in the 1970s, and the label "many-worlds" stuck through the anthology he co-edited.',
      'Formulated the Wheeler–DeWitt equation, a cornerstone of canonical quantum gravity.',
    ],
    url: 'https://en.wikipedia.org/wiki/Bryce_DeWitt',
  ),
  Person(
    id: 'neill-graham',
    fullName: 'Neill Graham',
    aliases: ['Neill Graham'],
    lifespan: '1941–2015',
    role: 'Physicist, co-editor of the many-worlds anthology',
    facts: [
      'With Bryce DeWitt, co-edited the 1973 volume that reprinted Everett\'s work and popularized the many-worlds name.',
    ],
    url: 'https://en.wikipedia.org/wiki/Hugh_Everett_III',
  ),
  Person(
    id: 'david-deutsch',
    fullName: 'David Deutsch',
    aliases: ['David Deutsch', 'Deutsch'],
    lifespan: 'b. 1953',
    role: 'British physicist, a founder of quantum computation',
    facts: [
      'Defined the universal quantum computer in 1985, years before any hardware existed.',
      'Argues that a quantum computer\'s parallel calculations are evidence the other worlds are real.',
    ],
    url: 'https://en.wikipedia.org/wiki/David_Deutsch',
  ),
  Person(
    id: 'alan-guth',
    fullName: 'Alan Guth',
    aliases: ['Alan Guth', 'Guth'],
    lifespan: 'b. 1947',
    role: 'American physicist who proposed cosmic inflation',
    facts: [
      'In 1980 proposed inflation — a burst of exponential expansion in the first instant — to explain why the universe is so uniform and flat.',
      'Won the 2014 Kavli Prize in Astrophysics for the theory.',
    ],
    url: 'https://en.wikipedia.org/wiki/Alan_Guth',
  ),
  Person(
    id: 'andrei-linde',
    fullName: 'Andrei Linde',
    aliases: ['Andrei Linde', 'Linde'],
    lifespan: 'b. 1948',
    role: 'Russian-American physicist of inflationary cosmology',
    facts: [
      'His "chaotic" and "eternal" inflation showed the process never fully stops — forever budding off new bubble universes.',
      'A professor of physics at Stanford University.',
    ],
    url: 'https://en.wikipedia.org/wiki/Andrei_Linde',
  ),
  Person(
    id: 'leonard-susskind',
    fullName: 'Leonard Susskind',
    aliases: ['Leonard Susskind', 'Susskind'],
    lifespan: 'b. 1940',
    role: 'American theoretical physicist, a father of string theory',
    facts: [
      'Introduced the string-theory "landscape" of vast numbers of possible universes.',
      'Gave the first precise string interpretation of the holographic principle.',
    ],
    url: 'https://en.wikipedia.org/wiki/Leonard_Susskind',
  ),
  Person(
    id: 'sean-carroll',
    fullName: 'Sean Carroll',
    aliases: ['Sean Carroll', 'Carroll'],
    lifespan: 'b. 1966',
    role: 'Physicist & science communicator, defender of many-worlds',
    facts: [
      'His 2019 book "Something Deeply Hidden" argues many-worlds is the simplest reading of quantum mechanics.',
      'Homewood Professor of Natural Philosophy at Johns Hopkins University.',
    ],
    url: 'https://en.wikipedia.org/wiki/Sean_M._Carroll',
  ),
  Person(
    id: 'karl-popper',
    fullName: 'Karl Popper',
    aliases: ['Karl Popper', 'Popper'],
    lifespan: '1902–1994',
    role: 'Philosopher of science, champion of falsifiability',
    facts: [
      'Argued a theory is scientific only if it could in principle be proven wrong — one black swan refutes "all swans are white".',
      'Also defended the "open society" against totalitarianism.',
    ],
    url: 'https://en.wikipedia.org/wiki/Karl_Popper',
  ),
  Person(
    id: 'pierre-duhem',
    fullName: 'Pierre Duhem',
    aliases: ['Pierre Duhem', 'Duhem'],
    lifespan: '1861–1916',
    role: 'French physicist & philosopher of science',
    facts: [
      'Argued a hypothesis is never tested alone — it comes bundled with assumptions, so no single experiment cleanly refutes it.',
      'Also recovered how sophisticated medieval science really was.',
    ],
    url: 'https://en.wikipedia.org/wiki/Pierre_Duhem',
  ),
  Person(
    id: 'quine',
    fullName: 'Willard Van Orman Quine',
    aliases: ['W.V.O. Quine', 'Quine'],
    lifespan: '1908–2000',
    role: 'American philosopher & logician',
    facts: [
      'His confirmation holism holds that theories face experience as whole webs, not isolated claims.',
      'His essay "Two Dogmas of Empiricism" reshaped 20th-century philosophy.',
    ],
    url: 'https://en.wikipedia.org/wiki/Willard_Van_Orman_Quine',
  ),
  Person(
    id: 'martin-rees',
    fullName: 'Martin Rees',
    aliases: ['Martin Rees'],
    lifespan: 'b. 1942',
    role: 'British cosmologist and Astronomer Royal',
    facts: [
      'Argues that extending well-tested physics past our horizon — where it implies other universes — is reasonable, not reckless.',
      'His early work helped show that supermassive black holes power quasars.',
    ],
    url: 'https://en.wikipedia.org/wiki/Martin_Rees',
  ),
  Person(
    id: 'george-ellis',
    fullName: 'George F. R. Ellis',
    aliases: ['George Ellis', 'Ellis'],
    lifespan: 'b. 1939',
    role: 'South African cosmologist, multiverse skeptic',
    facts: [
      'His 2014 essay with Joe Silk warned that loosening the demand for testability to admit the multiverse could erode science itself.',
      'Co-authored the 1973 classic "The Large Scale Structure of Space-Time" with Stephen Hawking.',
    ],
    url: 'https://en.wikipedia.org/wiki/George_F._R._Ellis',
  ),
  Person(
    id: 'joe-silk',
    fullName: 'Joseph Silk',
    aliases: ['Joe Silk'],
    lifespan: 'b. 1942',
    role: 'Cosmologist known for Silk damping',
    facts: [
      'With George Ellis, argued the multiverse — if untestable — does not deserve the name of science.',
      '"Silk damping", the smoothing of small ripples in the cosmic microwave background, is named after him.',
    ],
    url: 'https://en.wikipedia.org/wiki/Joseph_Silk',
  ),
  Person(
    id: 'paul-steinhardt',
    fullName: 'Paul Steinhardt',
    aliases: ['Paul Steinhardt', 'Steinhardt'],
    lifespan: 'b. 1952',
    role: 'Physicist; early inflation architect turned critic',
    facts: [
      'Argues eternal inflation predicts a multiverse where anything can happen somewhere — so it predicts everything, and thus nothing.',
      'Co-introduced the idea of quasicrystals and later helped find one in nature.',
    ],
    url: 'https://en.wikipedia.org/wiki/Paul_Steinhardt',
  ),
  Person(
    id: 'brandon-carter',
    fullName: 'Brandon Carter',
    aliases: ['Brandon Carter', 'Carter'],
    lifespan: 'b. 1942',
    role: 'Australian physicist who named the anthropic principle',
    facts: [
      'Introduced the anthropic principle in 1973 — precisely to warn against assuming our place in the cosmos is typical.',
      'Also found the Carter constant, a conserved quantity for orbits around spinning black holes.',
    ],
    url: 'https://en.wikipedia.org/wiki/Brandon_Carter',
  ),
  Person(
    id: 'ludwig-boltzmann',
    fullName: 'Ludwig Boltzmann',
    aliases: ['Ludwig Boltzmann', 'Boltzmann'],
    lifespan: '1844–1906',
    role: 'Austrian physicist, founder of statistical mechanics',
    facts: [
      'Gave entropy its statistical meaning; rare fluctuations in his framework power the "Boltzmann brain" argument.',
      'His entropy formula, S = k ln W, is engraved on his tombstone.',
    ],
    url: 'https://en.wikipedia.org/wiki/Ludwig_Boltzmann',
  ),
  Person(
    id: 'william-of-ockham',
    fullName: 'William of Ockham',
    aliases: ['William of Ockham'],
    lifespan: 'c. 1287–1347',
    role: 'English medieval philosopher, namesake of Occam\'s razor',
    facts: [
      'Occam\'s razor — "don\'t multiply entities beyond necessity" — is credited to him, though it doesn\'t say which entities to count.',
      'A pioneer of nominalism and a major figure of medieval thought.',
    ],
    url: 'https://en.wikipedia.org/wiki/William_of_Ockham',
  ),

  // ── Astronomy ──
  Person(
    id: 'henrietta-leavitt',
    fullName: 'Henrietta Swan Leavitt',
    aliases: ['Henrietta Leavitt', 'Leavitt'],
    lifespan: '1868–1921',
    role: 'American astronomer who found the cosmic "standard candle"',
    facts: [
      'Working as a Harvard "computer", she found in 1912 that a Cepheid star\'s pulse period reveals its true brightness.',
      'This gave astronomers the first reliable yardstick for galaxy distances — the rung Edwin Hubble later climbed.',
    ],
    url: 'https://en.wikipedia.org/wiki/Henrietta_Swan_Leavitt',
  ),
  Person(
    id: 'vesto-slipher',
    fullName: 'Vesto Slipher',
    aliases: ['Vesto Slipher'],
    lifespan: '1875–1969',
    role: 'American astronomer, first to measure galaxy velocities',
    facts: [
      'In 1912 he measured the first radial velocity of a spiral galaxy (Andromeda) at Lowell Observatory.',
      'His finding that most spirals are receding gave Hubble the raw data behind the expanding universe.',
    ],
    url: 'https://en.wikipedia.org/wiki/Vesto_Slipher',
  ),
  Person(
    id: 'carl-sagan',
    fullName: 'Carl Sagan',
    aliases: ['Carl Sagan'],
    lifespan: '1934–1996',
    role: 'Astronomer & science communicator',
    facts: [
      'Co-wrote and narrated the 1980 series "Cosmos", one of the most-watched science programs ever made.',
      'Popularized the idea that "we are made of star-stuff" — our heavy atoms were forged inside stars.',
    ],
    url: 'https://en.wikipedia.org/wiki/Carl_Sagan',
  ),
  Person(
    id: 'benoit-mandelbrot',
    fullName: 'Benoit Mandelbrot',
    aliases: ['Benoit Mandelbrot'],
    lifespan: '1924–2010',
    role: 'Mathematician, father of fractal geometry',
    facts: [
      'Coined the word "fractal" in 1975 for shapes that repeat their structure across scales.',
      'The Mandelbrot set generates endless self-similar detail from one simple repeated rule.',
    ],
    url: 'https://en.wikipedia.org/wiki/Benoit_Mandelbrot',
  ),
  Person(
    id: 'jan-oort',
    fullName: 'Jan Oort',
    aliases: ['Jan Oort'],
    lifespan: '1900–1992',
    role: 'Dutch astronomer who mapped the Milky Way',
    facts: [
      'In 1950 proposed the vast shell of icy bodies around the Sun that now bears his name — the Oort Cloud.',
      'His 1932 study of stellar motions found more mass than visible stars could explain — an early hint of dark matter.',
    ],
    url: 'https://en.wikipedia.org/wiki/Jan_Oort',
  ),
  Person(
    id: 'arno-penzias',
    fullName: 'Arno Penzias',
    aliases: ['Penzias'],
    lifespan: '1933–2024',
    role: 'Physicist, co-discoverer of the cosmic microwave background',
    facts: [
      'In 1965, with Robert Wilson, traced a persistent hiss in a Bell Labs antenna to radiation filling all of space.',
      'Shared the 1978 Nobel Prize for the discovery, which confirmed the hot Big Bang.',
    ],
    url: 'https://en.wikipedia.org/wiki/Arno_Allan_Penzias',
  ),
  Person(
    id: 'robert-wilson',
    fullName: 'Robert Woodrow Wilson',
    aliases: ['Robert Woodrow Wilson'],
    lifespan: 'b. 1936',
    role: 'Radio astronomer, co-discoverer of the cosmic microwave background',
    facts: [
      'With Arno Penzias, detected in 1965 the faint microwave glow left over from the early universe.',
      'Shared the 1978 Nobel Prize in Physics for the discovery.',
    ],
    url: 'https://en.wikipedia.org/wiki/Robert_Woodrow_Wilson',
  ),
  Person(
    id: 'ralph-alpher',
    fullName: 'Ralph Alpher',
    aliases: ['Alpher'],
    lifespan: '1921–2007',
    role: 'American cosmologist who predicted the CMB',
    facts: [
      'In 1948, with Robert Herman, predicted that a hot Big Bang would leave a faint relic radiation filling space.',
      'The forecast was overlooked until Penzias and Wilson stumbled onto the radiation in 1965.',
    ],
    url: 'https://en.wikipedia.org/wiki/Ralph_Asher_Alpher',
  ),
  Person(
    id: 'robert-herman',
    fullName: 'Robert Herman',
    aliases: ['Robert Herman'],
    lifespan: '1914–1997',
    role: 'American physicist who co-predicted the CMB',
    facts: [
      'With Ralph Alpher in 1948, predicted the temperature of the Big Bang\'s relic radiation decades before it was seen.',
      'Later became a pioneer of traffic-flow theory, applying physics to moving cars.',
    ],
    url: 'https://en.wikipedia.org/wiki/Robert_Herman',
  ),

  // ── Deep-future cosmology ──
  Person(
    id: 'fred-adams',
    fullName: 'Fred Adams',
    aliases: ['Fred Adams'],
    lifespan: 'b. 1961',
    role: 'American astrophysicist of the far future',
    facts: [
      'With Gregory Laughlin, wrote "The Five Ages of the Universe" (1999), charting the cosmos in powers of ten years.',
      'Their scheme names the Stelliferous, Degenerate, Black Hole, and Dark eras of deep time.',
    ],
    url: 'https://en.wikipedia.org/wiki/Fred_Adams',
  ),
  Person(
    id: 'gregory-laughlin',
    fullName: 'Gregory Laughlin',
    aliases: ['Laughlin'],
    lifespan: 'b. 1966',
    role: 'American astrophysicist, co-author of the deep-future timeline',
    facts: [
      'With Fred Adams, charted the fate of the universe from the last stars to evaporating black holes.',
      'A professor of astronomy and astrophysics at Yale University.',
    ],
    url: 'https://en.wikipedia.org/wiki/Gregory_P._Laughlin',
  ),

  // ── Life, chemistry of life, agriculture & economics ──
  Person(
    id: 'carl-linnaeus',
    fullName: 'Carl Linnaeus',
    aliases: ['Carl Linnaeus', 'Linnaeus'],
    lifespan: '1707–1778',
    role: 'Swedish botanist, founder of biological classification',
    facts: [
      'Invented the two-word Latin naming system used for every species, coining "Homo sapiens" in 1758.',
      'Beside Homo sapiens he wrote no description — only "nosce te ipsum" ("know thyself").',
    ],
    url: 'https://en.wikipedia.org/wiki/Carl_Linnaeus',
  ),
  Person(
    id: 'carl-woese',
    fullName: 'Carl Woese',
    aliases: ['Carl Woese', 'Woese'],
    lifespan: '1928–2012',
    role: 'Microbiologist who discovered life\'s third domain',
    facts: [
      'By comparing RNA, showed in 1977 that Archaea are a separate domain — splitting life into Bacteria, Archaea, and Eukarya.',
      'His use of RNA as a molecular clock founded modern phylogenetics.',
    ],
    url: 'https://en.wikipedia.org/wiki/Carl_Woese',
  ),
  Person(
    id: 'robert-paine',
    fullName: 'Robert T. Paine',
    aliases: ['Robert Paine'],
    lifespan: '1933–2016',
    role: 'American ecologist who defined the keystone species',
    facts: [
      'Removed one predatory sea star from a tidepool and watched diversity collapse — showing how a single species can hold an ecosystem together.',
      'Coined the term "keystone species", borrowing the image of the wedge stone that keeps an arch standing.',
    ],
    url: 'https://en.wikipedia.org/wiki/Robert_T._Paine_(zoologist)',
  ),
  Person(
    id: 'norman-borlaug',
    fullName: 'Norman Borlaug',
    aliases: ['Norman Borlaug', 'Borlaug'],
    lifespan: '1914–2009',
    role: 'Agronomist, central figure of the Green Revolution',
    facts: [
      'Bred short, sturdy high-yield wheat that could carry heavy fertilizer without toppling, multiplying harvests across the world.',
      'Won the 1970 Nobel Peace Prize; his work is credited with saving on the order of a billion people from starvation.',
    ],
    url: 'https://en.wikipedia.org/wiki/Norman_Borlaug',
  ),
  Person(
    id: 'david-ricardo',
    fullName: 'David Ricardo',
    aliases: ['David Ricardo'],
    lifespan: '1772–1823',
    role: 'British economist of comparative advantage',
    facts: [
      'Proved both parties gain from trade if each specializes in what it is relatively best at — even when one is worse at everything.',
      'Laid out comparative advantage in 1817, still a cornerstone of trade theory.',
    ],
    url: 'https://en.wikipedia.org/wiki/David_Ricardo',
  ),
  Person(
    id: 'hau-lee',
    fullName: 'Hau L. Lee',
    aliases: ['Hau L. Lee'],
    lifespan: 'b. 1952',
    role: 'Stanford operations professor',
    facts: [
      'Co-authored the landmark 1997 paper on the "bullwhip effect" — how small demand wobbles amplify into wild swings upstream.',
      'The paper named concrete, fixable causes: order batching, price swings, and rationing games.',
    ],
    url: 'https://en.wikipedia.org/wiki/Hau_L._Lee',
  ),
  Person(
    id: 'v-padmanabhan',
    fullName: 'V. Padmanabhan',
    aliases: ['Padmanabhan'],
    lifespan: 'Contemporary',
    role: 'Marketing scholar of supply chains',
    facts: [
      'Co-authored the 1997 study that named and modeled the bullwhip effect.',
      'His work joins marketing and operations — how ordering and pricing distort demand information up a supply chain.',
    ],
    url: 'https://en.wikipedia.org/wiki/Bullwhip_effect',
  ),
  Person(
    id: 'seungjin-whang',
    fullName: 'Seungjin Whang',
    aliases: ['Whang'],
    lifespan: 'Contemporary',
    role: 'Stanford operations professor',
    facts: [
      'Co-authored the 1997 bullwhip-effect paper with Hau Lee and V. Padmanabhan.',
      'Their analysis reframed the bullwhip effect as a systems problem, not just poor management.',
    ],
    url: 'https://en.wikipedia.org/wiki/Bullwhip_effect',
  ),
  Person(
    id: 'gregor-mendel',
    fullName: 'Gregor Mendel',
    aliases: ['Mendel', 'Mendelian'],
    lifespan: '1822–1884',
    role: 'Augustinian friar, founder of genetics',
    facts: [
      'Turned pea-plant breeding into a science, discovering the basic laws of inheritance.',
      'His methods underlie hybrid crops and the predictable yield jumps of modern agriculture.',
    ],
    url: 'https://en.wikipedia.org/wiki/Gregor_Mendel',
  ),
  Person(
    id: 'justus-von-liebig',
    fullName: 'Justus von Liebig',
    aliases: ['Liebig'],
    lifespan: '1803–1873',
    role: 'German chemist, founder of agricultural chemistry',
    facts: [
      'His Law of the Minimum: a crop is capped by whichever nutrient is scarcest, not the ones in surplus.',
      'Championed nitrogen and minerals as plant nutrients — the "father of the fertilizer industry".',
    ],
    url: 'https://en.wikipedia.org/wiki/Justus_von_Liebig',
  ),
  Person(
    id: 'hans-krebs',
    fullName: 'Hans Krebs',
    aliases: ['Krebs'],
    lifespan: '1900–1981',
    role: 'Biochemist who mapped the citric acid cycle',
    facts: [
      'Worked out the Krebs cycle — the hub of cellular respiration that extracts energy from food inside mitochondria.',
      'Shared the 1953 Nobel Prize in Physiology or Medicine for the discovery.',
    ],
    url: 'https://en.wikipedia.org/wiki/Hans_Krebs_(biochemist)',
  ),
  Person(
    id: 'louis-antoine-ranvier',
    fullName: 'Louis-Antoine Ranvier',
    aliases: ['Ranvier'],
    lifespan: '1835–1922',
    role: 'French histologist of the nervous system',
    facts: [
      'In 1878 described the regular gaps along a nerve fiber — the nodes of Ranvier, where the signal leaps from node to node.',
      'Helped turn histology from description into an experimental science.',
    ],
    url: 'https://en.wikipedia.org/wiki/Louis-Antoine_Ranvier',
  ),
  Person(
    id: 'johannes-van-der-waals',
    fullName: 'Johannes Diderik van der Waals',
    aliases: ['Van der Waals', 'van der Waals'],
    lifespan: '1837–1923',
    role: 'Dutch physicist of forces between molecules',
    facts: [
      'First to build molecular size and weak attraction into the gas laws — the forces now named after him.',
      'Individually tiny, van der Waals forces summed over a surface let a gecko cling to glass; he won the 1910 Nobel Prize.',
    ],
    url: 'https://en.wikipedia.org/wiki/Johannes_Diderik_van_der_Waals',
  ),
  Person(
    id: 'fritz-haber',
    fullName: 'Fritz Haber',
    aliases: ['Haber process'],
    lifespan: '1868–1934',
    role: 'German chemist who pulled fertilizer from the air',
    facts: [
      'Found how to turn the air\'s inert nitrogen into ammonia — the basis of the synthetic fertilizer that now feeds much of humanity.',
      'Won the 1918 Nobel Prize in Chemistry, but also directed Germany\'s WWI chemical-weapons program.',
    ],
    url: 'https://en.wikipedia.org/wiki/Fritz_Haber',
  ),
  Person(
    id: 'carl-bosch',
    fullName: 'Carl Bosch',
    aliases: ['Carl Bosch'],
    lifespan: '1874–1940',
    role: 'German chemical engineer',
    facts: [
      'Scaled Haber\'s lab reaction into the industrial Haber–Bosch process, making cheap nitrogen fertilizer possible worldwide.',
      'Shared the 1931 Nobel Prize in Chemistry for high-pressure chemical methods.',
    ],
    url: 'https://en.wikipedia.org/wiki/Carl_Bosch',
  ),
];
