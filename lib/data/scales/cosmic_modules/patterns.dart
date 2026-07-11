import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Cosmic Structures → "Patterns That Repeat".
///
/// The crown-jewel abstract module: the features of reality that recur across
/// EVERY scale — Fibonacci, the golden ratio, fractals, spirals, symmetry,
/// power laws, branching. Wondrous AND honest: real math is separated from
/// pop-science numerology throughout.
const List<BioEntity> cosmicPatternsEntities = <BioEntity>[
  // ---------------------------------------------------------------------------
  // 0 — WHY NATURE REUSES PATTERNS
  // ---------------------------------------------------------------------------
  BioEntity(
    id: 'cosmic_patterns_why_reuse',
    scale: BioScale.cosmicStructures,
    position: 0,
    name: 'Why Nature Reuses Patterns',
    title: 'The Same Forms Everywhere',
    moduleId: 'cosmicStructures_patterns',
    shortDescription:
        'A sunflower, a hurricane, and a spiral galaxy share a shape — because the same math is the cheapest solution to the same problem.',
    longDescription:
        'Nature has no design office. Yet the same forms — spirals, branches, '
        'hexagons, fractals — turn up in a seed head, a lung, a river delta, and '
        'the cosmic web. This is not mysticism. The same physical constraints '
        '(minimise energy, pack tightly, fill space, grow with limited materials) '
        'have the same mathematical answers, so evolution and physics both keep '
        'rediscovering them.\n\n'
        'Think of a pattern as a shortcut nature reuses because inventing a fresh '
        'one every time would be wasteful. A soap bubble does not "know" geometry, '
        'yet it finds the minimal surface. A tree does not compute fractals, yet it '
        'branches like one. The pattern is what is left when everything expensive '
        'has been optimised away.',
    relatedIds: [
      'cosmic_patterns_fibonacci',
      'cosmic_patterns_fractals',
      'cosmic_patterns_power_laws',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'Hold a pinecone in one hand and picture a spiral galaxy in the other. '
            'They are separated by twenty-odd orders of magnitude in size — and '
            'they curl the same way. Why should the very large and the very small '
            'rhyme? Because reality reuses a small toolkit of patterns, and this '
            'module is the toolkit.',
      ),
      LessonSection.fact(
        title: 'One toolkit, every scale',
        body:
            'The recurring forms — Fibonacci packing, the golden angle, fractals, '
            'spirals, symmetry, power laws, and branching — appear from DNA (nm) '
            'to the cosmic web (~100 million light-years). That is a span of over '
            '30 orders of magnitude sharing a handful of shapes.',
      ),
      LessonSection.table(
        title: 'Why the same forms keep winning',
        headers: ['Constraint nature faces', 'Pattern it produces', 'Seen in'],
        rows: [
          ['Pack the most into the least space', 'Golden-angle / hexagons', 'Seeds, honeycomb, eyes'],
          ['Deliver stuff everywhere efficiently', 'Branching networks', 'Lungs, rivers, blood, roots'],
          ['Grow while keeping the same shape', 'Logarithmic spirals', 'Shells, horns, galaxies'],
          ['Minimise energy / surface', 'Symmetry & minimal surfaces', 'Bubbles, crystals, planets'],
          ['No special scale to prefer', 'Fractals & power laws', 'Coastlines, cities, quakes'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If nature has no designer, how do a sunflower and a galaxy end up '
            'with the same spiral? Is it a coincidence, a copy, or a cause?',
        answer:
            'A cause — the same one, arrived at independently. Neither copied the '
            'other. Both obey a rule (grow by adding at a fixed rotation, or under '
            'gravity that acts the same at every radius) whose only stable outcome '
            'is that spiral. When independent systems reach the same form from the '
            'same math, scientists call it convergence. The pattern is the '
            'fingerprint of the constraint, not of a designer.',
      ),
      LessonSection.thinkReveal(
        title: 'Down to the potato',
        question:
            'Where is the "reuse a cheap pattern" logic hiding inside a single '
            'potato plant?',
        answer:
            'Everywhere. Its leaves spiral up the stem at the golden angle so no '
            'leaf fully shades the one below (packing). Its roots branch like a '
            'river network to reach water with minimal tissue (delivery). The '
            'starch granules inside a potato cell grow in concentric rings, laid '
            'down layer on layer — the same "grow while keeping shape" trick a '
            'seashell uses. One humble tuber runs three of this module\'s patterns '
            'at once.',
      ),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 1 — THE FIBONACCI SEQUENCE
  // ---------------------------------------------------------------------------
  BioEntity(
    id: 'cosmic_patterns_fibonacci',
    scale: BioScale.cosmicStructures,
    position: 1,
    name: 'The Fibonacci Sequence',
    title: '0, 1, 1, 2, 3, 5, 8, 13…',
    moduleId: 'cosmicStructures_patterns',
    shortDescription:
        'Add the last two numbers to get the next. This one rule is written into sunflower seeds, pinecone scales, and pineapple skins.',
    longDescription:
        'The Fibonacci sequence starts 0, 1 and then each term is the sum of the '
        'previous two: 1, 2, 3, 5, 8, 13, 21, 34, 55, 89… That is the entire rule. '
        'It looks like a number game, but count the spirals on a sunflower head, a '
        'pinecone, or a pineapple and you keep landing on Fibonacci numbers — '
        '34 and 55, or 55 and 89, running in opposite directions.\n\n'
        'The reason is not magic: a plant that adds each new seed or leaf at a '
        'fixed turn (the golden angle — see the next lesson) automatically stacks '
        'its parts into two families of interlocking spirals, and the counts of '
        'those spirals are consecutive Fibonacci numbers. Fibonacci is the '
        'visible fingerprint; the golden angle is the pen.',
    relatedIds: [
      'cosmic_patterns_golden_ratio',
      'cosmic_patterns_spirals',
      'cosmic_patterns_why_reuse',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'Pick up a pinecone and count the spirals twisting one way, then the '
            'other. You will almost always get two neighbouring Fibonacci numbers '
            '— 8 and 13, or 13 and 21. The cone never took a maths class. So who '
            'told it to count?',
      ),
      LessonSection.table(
        title: 'The sequence, and how each term is built',
        headers: ['Position', 'Term', 'Built from'],
        rows: [
          ['1st, 2nd', '0, 1', 'the two seeds'],
          ['3rd', '1', '0 + 1'],
          ['4th', '2', '1 + 1'],
          ['5th', '3', '1 + 2'],
          ['6th', '5', '2 + 3'],
          ['7th', '8', '3 + 5'],
          ['8th', '13', '5 + 8'],
          ['9th', '21', '8 + 13'],
          ['10th', '34', '13 + 21'],
        ],
      ),
      LessonSection.fact(
        title: 'Spiral counts are Fibonacci',
        body:
            'A sunflower head typically shows 34 spirals one way and 55 the other '
            '— or 55 and 89 in big heads. Both counts are consecutive Fibonacci '
            'numbers. The pattern is real and measurable, not a rounding trick.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'The next Fibonacci number after 89 — what is it, and how did you '
            'get it without knowing the sequence by heart?',
        answer:
            '144. You add the previous two: 55 + 89 = 144. That single rule '
            '(each term = sum of the two before it) generates the whole infinite '
            'sequence, which is exactly why it is so easy for a growing plant to '
            '"use" it — no memory of the pattern is needed, only the last two steps.',
      ),
      LessonSection.thinkReveal(
        title: 'Honesty check',
        question:
            'You will read that "galaxies are Fibonacci." Is a spiral galaxy '
            'literally built from the sequence 1, 1, 2, 3, 5…?',
        answer:
            'No — and this is where pop-science overreaches. A galaxy is a '
            'logarithmic spiral shaped by gravity and density waves, not a count '
            'of discrete seeds. Fibonacci NUMBERS genuinely appear in plants '
            'because growth is discrete (one seed at a time). Galaxies share the '
            'golden-ratio SPIRAL geometry loosely at best. Keep the two claims '
            'separate: real Fibonacci counting lives in plants; galaxies rhyme '
            'with the golden spiral, they do not tally Fibonacci numbers.',
      ),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 2 — THE GOLDEN RATIO & GOLDEN ANGLE
  // ---------------------------------------------------------------------------
  BioEntity(
    id: 'cosmic_patterns_golden_ratio',
    scale: BioScale.cosmicStructures,
    position: 2,
    name: 'The Golden Ratio & Golden Angle',
    title: 'φ ≈ 1.618 and the 137.5° Turn',
    moduleId: 'cosmicStructures_patterns',
    shortDescription:
        'The most stubbornly irrational number hides a rotation — ~137.5° — that packs seeds so no two ever overlap.',
    longDescription:
        'The golden ratio φ (phi) is (1 + √5) / 2 ≈ 1.6180339887…, the number you '
        'get when the ratio of consecutive Fibonacci terms settles down: '
        '5/3, 8/5, 13/8, 21/13 all zero in on φ. It has a unique property: it is '
        'the "most irrational" number — the hardest of all numbers to approximate '
        'with simple fractions.\n\n'
        'Turn that ratio into a rotation and you get the golden angle, '
        '≈ 137.5° (a full 360° split in the golden proportion). A plant that '
        'places each new leaf or seed 137.5° around from the last never lets a new '
        'part line up with an old one — because φ resists every simple fraction, '
        'nothing ever stacks or shades. That is real phyllotaxis: the golden angle '
        'is nature\'s optimal packing rule, and Fibonacci spirals are its shadow.',
    relatedIds: [
      'cosmic_patterns_fibonacci',
      'cosmic_patterns_spirals',
      'cosmic_patterns_symmetry',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'Suppose you must arrange a thousand seeds on a flat disc so none '
            'crowd and none waste space. What single turn between one seed and the '
            'next would you use? Nature answered long ago: 137.5°. Not 137, not '
            '138 — and the reason is one of the most beautiful facts in maths.',
      ),
      LessonSection.fact(
        title: 'φ = (1 + √5) / 2',
        body:
            'φ ≈ 1.6180339887. Its defining trick: φ = 1 + 1/φ. Square it and you '
            'just add one (φ² = φ + 1 ≈ 2.618). No other positive number does that.',
      ),
      LessonSection.table(
        title: 'Fibonacci ratios converge on φ',
        headers: ['Ratio', 'Value', 'Distance from φ'],
        rows: [
          ['3 / 2', '1.5000', 'far'],
          ['5 / 3', '1.6667', 'closer'],
          ['8 / 5', '1.6000', 'closer'],
          ['13 / 8', '1.6250', 'closer'],
          ['21 / 13', '1.6154', 'closer still'],
          ['89 / 55', '1.61818…', 'nearly exact'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Why would a plant use 137.5° instead of a clean angle like 90° or '
            '120°? What goes wrong with the tidy numbers?',
        answer:
            'Clean angles repeat. Turn by 90° and every 4th seed lines up in a '
            'spoke; turn by 120° and every 3rd seed does — leaving big empty gaps '
            'and overlapping columns. Because 90° and 120° are simple fractions of '
            '360°, they close back on themselves. The golden angle comes from φ, '
            'the number that resists simple fractions harder than any other, so '
            'the seeds NEVER realign into spokes. Every new seed drops into the '
            'largest remaining gap. The result is the densest, most even packing '
            'possible — which is exactly what a sunflower needs.',
      ),
      LessonSection.thinkReveal(
        title: 'Honesty check',
        question:
            'The Parthenon, credit cards, the "perfect face" — is the golden '
            'ratio really the secret of all beauty?',
        answer:
            'Mostly no. The phyllotaxis result is rock-solid maths — seeds really '
            'do pack best at the golden angle. But "φ is in the Parthenon / the '
            'Mona Lisa / your face" is largely retrofitted numerology: you can '
            'draw a rectangle to match almost anything, and studies find no '
            'reliable preference for φ in art or faces. Respect the biology; be '
            'skeptical of the aesthetics folklore. Real φ = optimal packing; myth '
            'φ = a number people force onto whatever they admire.',
      ),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 3 — FRACTALS & SELF-SIMILARITY
  // ---------------------------------------------------------------------------
  BioEntity(
    id: 'cosmic_patterns_fractals',
    scale: BioScale.cosmicStructures,
    position: 3,
    name: 'Fractals & Self-Similarity',
    title: 'The Same Shape at Every Zoom',
    moduleId: 'cosmicStructures_patterns',
    shortDescription:
        'Zoom into a coastline, a fern, or the cosmic web and you keep meeting the same shape — a form with a fractional dimension.',
    longDescription:
        'A fractal is a shape that looks the same, or nearly the same, at every '
        'level of zoom — this is self-similarity. A fern frond is a smaller copy '
        'of the whole fern; a river\'s tributaries branch like the river; a bay '
        'has coves that have coves. Because detail never smooths out, a fractal '
        'has a fractional (non-integer) dimension: a coastline is "wigglier than a '
        'line but not a filled area," so its dimension sits between 1 and 2.\n\n'
        'This leads to the famous coastline paradox: the length of a coast has no '
        'single answer — measure with a shorter ruler and you catch more wiggles, '
        'and the total grows without limit. The mathematician Benoit Mandelbrot '
        'named these objects "fractals" (1975) and built the Mandelbrot set, an '
        'endlessly detailed shape from one tiny rule.',
    relatedIds: [
      'cosmic_patterns_branching',
      'cosmic_patterns_power_laws',
      'cosmic_patterns_why_reuse',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'How long is the coast of Britain? Trick question — there is no single '
            'answer. Use a 100 km ruler and you get one number; use a 1 km ruler '
            'and you catch every headland, and the total balloons. The closer you '
            'look, the longer it gets, forever. That is a fractal talking.',
      ),
      LessonSection.fact(
        title: 'A dimension that is not a whole number',
        body:
            'The coast of Britain has a fractal dimension of about 1.25; the '
            'craggier west coast of Norway is near 1.5. A smooth line is 1, a '
            'filled square is 2 — real coastlines live in between.',
      ),
      LessonSection.table(
        title: 'Self-similarity from the cell to the cosmos',
        headers: ['Fractal object', 'What repeats when you zoom', 'Rough dimension'],
        rows: [
          ['Coastline', 'Bays within bays within bays', '~1.25'],
          ['Fern frond', 'Each leaflet is a mini-fern', '~1.7'],
          ['Human lung', '23 generations of branching tubes', '~2.97'],
          ['River network', 'Tributaries of tributaries', '~1.8'],
          ['Cosmic web', 'Filaments and voids, clumped at every scale', '~2 (large-scale)'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If a shape is truly self-similar, what happens to its detail as you '
            'zoom in — and why does that break ordinary "length"?',
        answer:
            'The detail never runs out. A normal curve, zoomed in far enough, '
            'looks straight; a fractal keeps showing new wiggles at every '
            'magnification. Since each finer ruler traces those extra wiggles, the '
            'measured length keeps rising instead of settling — so "length" is the '
            'wrong tool. The right measure is the fractal dimension, which captures '
            'HOW the detail fills space rather than pretending the wiggles stop.',
      ),
      LessonSection.thinkReveal(
        title: 'Down to the cell',
        question:
            'Your lungs and a river delta solve completely different jobs. Why do '
            'they end up the same fractal shape?',
        answer:
            'Both must connect one point to an enormous surface using as little '
            'material and space as possible. A lung packs the area of a tennis '
            'court into your chest by branching ~23 times, each branch a smaller '
            'copy of the last — dimension ~2.97, almost filling its volume. A river '
            'drains a whole landscape into one mouth by the same repeated '
            'branching. Same constraint (fill space to deliver/collect), same '
            'fractal answer — a theme you have now seen from potato roots to the '
            'cosmic web.',
      ),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 4 — SPIRALS ACROSS SCALES
  // ---------------------------------------------------------------------------
  BioEntity(
    id: 'cosmic_patterns_spirals',
    scale: BioScale.cosmicStructures,
    position: 4,
    name: 'Spirals Across Scales',
    title: 'From DNA to Hurricanes to Galaxies',
    moduleId: 'cosmicStructures_patterns',
    shortDescription:
        'The double helix, a snail shell, a hurricane, and a spiral galaxy all curl by the same law — grow, and turn as you go.',
    longDescription:
        'A spiral is what you get when something grows outward while also turning. '
        'The most common one in nature is the logarithmic spiral, which widens by '
        'a constant factor each turn, so it keeps the same shape as it grows — a '
        'property called self-similarity (there it is again). A snail can add shell '
        'without redesigning it; a galaxy can span 100,000 light-years yet look '
        'like a scaled-up whirlpool.\n\n'
        'Spirals appear because the underlying rules are the same at every scale: '
        'add material at a fixed proportional rate (shells, horns), or let a '
        'rotating disc bunch up under gravity (galaxies, hurricanes, water down a '
        'drain). Even DNA is a helix — a spiral marched along an axis — because '
        'that is the tightest, most stable way to stack flat rungs and store a '
        'long code in a tiny space.',
    relatedIds: [
      'cosmic_patterns_golden_ratio',
      'cosmic_patterns_fibonacci',
      'cosmic_patterns_symmetry',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'Water spiralling down a drain, the arms of a hurricane, the sweep of '
            'the Milky Way, the twist of your own DNA — four spirals across nine '
            'orders of magnitude. One shape, one reason: grow (or flow) while you '
            'turn.',
      ),
      LessonSection.fact(
        title: 'The logarithmic spiral keeps its shape',
        body:
            'A logarithmic (equiangular) spiral crosses every radius at the same '
            'angle and widens by a constant ratio per turn. That is why a nautilus '
            'can grow 100-fold and still look "the same shell," just bigger.',
      ),
      LessonSection.table(
        title: 'Spirals from the molecular to the galactic',
        headers: ['Spiral', 'Scale', 'What drives the twist'],
        rows: [
          ['DNA double helix', '~2 nm wide', 'Stable stacking of base pairs'],
          ['Snail / nautilus shell', 'cm', 'Growth by a constant proportion'],
          ['Water down a drain', 'm', 'Angular momentum of the flow'],
          ['Hurricane', '~500 km', 'Rotation + rising, condensing air'],
          ['Spiral galaxy', '~100,000 ly', 'Gravity + density waves in a spinning disc'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'A snail must add to its shell for years without ever rebuilding it. '
            'What kind of spiral lets it grow bigger without changing shape?',
        answer:
            'A logarithmic spiral. Because it widens by a constant FACTOR each '
            'turn (not a constant amount), every new section is a scaled copy of '
            'the old — the shell stays the same shape while getting larger. The '
            'snail just keeps secreting shell at its lip; the geometry does the '
            'rest. A spiral that grew by a fixed amount each turn (an Archimedean '
            'spiral, like a rolled-up rug) would change proportions and would not '
            'suit an animal that must keep fitting its home.',
      ),
      LessonSection.thinkReveal(
        title: 'Honesty check',
        question:
            'Is the nautilus shell a "golden spiral" — the famous φ spiral?',
        answer:
            'No, and this is a classic myth. The nautilus IS a logarithmic spiral, '
            'but its growth factor is roughly 1.3 per turn, not φ ≈ 1.618. '
            'Measurements of real shells scatter well away from the golden spiral. '
            'So keep the true claim: nautilus shells are logarithmic spirals (real, '
            'elegant). Drop the false one: they are not golden spirals. Logarithmic '
            'spirals are everywhere; the golden one is just a single special member '
            'of that family, and nature rarely picks exactly it.',
      ),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 5 — SYMMETRY
  // ---------------------------------------------------------------------------
  BioEntity(
    id: 'cosmic_patterns_symmetry',
    scale: BioScale.cosmicStructures,
    position: 5,
    name: 'Symmetry',
    title: 'The Deep Order Physics Is Built On',
    moduleId: 'cosmicStructures_patterns',
    shortDescription:
        'From a snowflake\'s six arms to the laws of physics themselves, symmetry is sameness under change — and it dictates what is possible.',
    longDescription:
        'Symmetry means a thing looks unchanged after some operation — rotate a '
        'snowflake by 60° and it matches itself; flip a butterfly and its wings '
        'agree. But symmetry runs far deeper than pretty shapes. In physics, a '
        'symmetry is any change you can make to your experiment that leaves the '
        'laws the same: run it today or tomorrow (time), here or a mile away '
        '(space), facing north or east (rotation).\n\n'
        'Emmy Noether proved the stunning payoff (Noether\'s theorem, 1918): every '
        'continuous symmetry of the laws produces a conserved quantity. Time '
        'symmetry gives conservation of energy; space symmetry gives conservation '
        'of momentum; rotational symmetry gives angular momentum. Symmetry is not '
        'decoration on top of physics — it is the scaffolding the laws hang from, '
        'and the search for symmetries (and how they break) built the whole theory '
        'of particles.',
    relatedIds: [
      'cosmic_patterns_why_reuse',
      'cosmic_patterns_spirals',
      'cosmic_patterns_power_laws',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'Every snowflake is different — but every snowflake has exactly six '
            'arms. That six-fold symmetry is not luck; it is dictated by the shape '
            'of a single water molecule. Now scale the idea up: what if the same '
            'principle that gives a snowflake six arms also tells the universe that '
            'energy can never be created or destroyed?',
      ),
      LessonSection.fact(
        title: 'Noether\'s theorem',
        body:
            'For every continuous symmetry of nature\'s laws there is a conserved '
            'quantity. Symmetry in TIME → energy is conserved. Symmetry in SPACE → '
            'momentum is conserved. Rotational symmetry → angular momentum. Proved '
            'by Emmy Noether, 1918.',
      ),
      LessonSection.table(
        title: 'Symmetry from crystals to the cosmos',
        headers: ['Thing', 'Symmetry it shows', 'Why'],
        rows: [
          ['Snowflake', '6-fold rotation', 'Water molecule\'s bond angle'],
          ['Butterfly / human', 'Bilateral (mirror)', 'Efficient body plan, movement'],
          ['Salt crystal', 'Cubic (translational)', 'Repeating ionic lattice'],
          ['Laws of physics', 'Time / space / rotation', 'Yield conservation laws'],
          ['Fundamental particles', 'Gauge symmetries', 'Dictate the forces themselves'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Physicists say the universe is symmetric "in time." What everyday '
            'law of nature does that symmetry hand you for free?',
        answer:
            'Conservation of energy. "Symmetric in time" means the laws of physics '
            'are the same today as tomorrow — an experiment gives the same result '
            'whenever you run it. Noether\'s theorem says that exact sameness '
            'GUARANTEES energy is conserved. So the reason a perpetual-motion '
            'machine is impossible traces straight back to the fact that time '
            'doesn\'t change the rules. Symmetry is not just pretty; it is why the '
            'bookkeeping of the universe always balances.',
      ),
      LessonSection.thinkReveal(
        title: 'Down to the atom',
        question:
            'Broken symmetry can matter as much as symmetry. Where does a tiny '
            'imbalance in the early universe show up in the potato you eat?',
        answer:
            'In the very fact that matter exists. The early universe was nearly '
            'symmetric between matter and antimatter — but a slight symmetry '
            'breaking left a tiny excess of matter (about one extra particle per '
            'billion). Everything you see, including the atoms in a potato, is that '
            'leftover billionth. Perfect symmetry would have annihilated into pure '
            'light. So symmetry builds the laws — and its careful breaking builds '
            'the stuff those laws act on.',
      ),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 6 — POWER LAWS & SCALING
  // ---------------------------------------------------------------------------
  BioEntity(
    id: 'cosmic_patterns_power_laws',
    scale: BioScale.cosmicStructures,
    position: 6,
    name: 'Power Laws & Scaling',
    title: 'Why Big and Small Obey One Rule',
    moduleId: 'cosmicStructures_patterns',
    shortDescription:
        'Earthquakes, cities, word frequencies, and animal metabolism all follow rules with no favourite size — the pattern of no scale.',
    longDescription:
        'A power law says one quantity varies as another raised to a fixed power: '
        'double the input, and the output changes by the same factor no matter '
        'where you started. That "no matter where you started" is the magic — a '
        'power law is scale-invariant, with no special or typical size. Plot it on '
        'log–log axes and it becomes a straight line, the signature of the '
        'pattern.\n\n'
        'These rules are everywhere. The Gutenberg–Richter law: small earthquakes '
        'are common, huge ones rare, in a fixed power-law ratio. Zipf\'s law: the '
        'most common word ("the") appears about twice as often as the 2nd, three '
        'times as often as the 3rd. Kleiber\'s law: an animal\'s metabolic rate '
        'scales as its mass to the 3/4 power — a mouse and a whale, and even a '
        'potato cell\'s energy budget, sit on the same line across 20 orders of '
        'magnitude in mass.',
    relatedIds: [
      'cosmic_patterns_fractals',
      'cosmic_patterns_branching',
      'cosmic_patterns_why_reuse',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'A mouse\'s heart races; an elephant\'s thumps slowly. Yet plot every '
            'animal\'s metabolism against its body mass and they fall on one '
            'straight line — a whale and a shrew, differing a millionfold in size, '
            'obeying the same 3/4-power rule. What kind of law treats big and small '
            'as the same?',
      ),
      LessonSection.fact(
        title: 'Kleiber\'s 3/4 law',
        body:
            'Metabolic rate ∝ (body mass)^(3/4). It holds from microbes to blue '
            'whales — over ~20 orders of magnitude of mass — one of biology\'s '
            'broadest quantitative laws, tied to the fractal branching of supply '
            'networks.',
      ),
      LessonSection.table(
        title: 'Power laws with no favourite size',
        headers: ['Power law', 'What it governs', 'The scaling rule'],
        rows: [
          ['Gutenberg–Richter', 'Earthquake sizes', '10× bigger ⇒ ~10× rarer'],
          ['Zipf\'s law', 'Word / city-size frequency', 'nth ≈ 1/n of the top rank'],
          ['Kleiber\'s law', 'Metabolic rate', '∝ mass^(3/4)'],
          ['Cosmic clustering', 'Galaxy distribution', 'Power-law correlation with distance'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'What does it MEAN for a rule to be "scale-invariant," and why does '
            'that make a power law look like a straight line on log–log paper?',
        answer:
            'Scale-invariant means zooming in or out doesn\'t change the rule — '
            'there is no special size where things behave differently; the ratio '
            'between "twice as big" and "half as often" is the same everywhere. '
            'Taking the logarithm of a power law y = x^k turns it into log y = '
            'k·log x, the equation of a straight line with slope k. So a straight '
            'log–log plot is the fingerprint of a process with no favourite scale '
            '— the exact opposite of a bell curve, which has a clear "typical" '
            'value.',
      ),
      LessonSection.thinkReveal(
        title: 'Why 3/4?',
        question:
            'Why should metabolism scale as mass^(3/4) instead of the "obvious" '
            'mass^(1) — one gram, one unit of fuel?',
        answer:
            'Because life is fed through branching networks, not by bulk. Nutrients '
            'reach cells via fractal delivery systems — blood vessels, plant '
            'vasculature, a potato\'s root and phloem network (the next lesson). '
            'Optimising those space-filling networks to service a 3-D body makes '
            'supply — and so metabolism — grow more slowly than mass, and the '
            'geometry works out to the 3/4 power. Big animals are more energy-'
            'efficient per gram not by choice but because their fractal plumbing '
            'forces it. Power laws and branching networks are two faces of one coin.',
      ),
    ],
  ),

  // ---------------------------------------------------------------------------
  // 7 — BRANCHING NETWORKS
  // ---------------------------------------------------------------------------
  BioEntity(
    id: 'cosmic_patterns_branching',
    scale: BioScale.cosmicStructures,
    position: 7,
    name: 'Branching Networks',
    title: 'Nature\'s Delivery System',
    moduleId: 'cosmicStructures_patterns',
    shortDescription:
        'Trees, blood vessels, lightning, rivers, and the cosmic web all branch — because splitting again and again is the cheapest way to reach everywhere.',
    longDescription:
        'When something must reach every point of a space from a single source — '
        'or drain a whole space back to one exit — the winning solution is almost '
        'always to branch: split into two, then split again, then again. Your '
        'lungs and arteries do it, a tree\'s canopy and roots do it, a river '
        'gathers a continent through it, and lightning finds ground by forking '
        'through the air. The branches are fractal (a bough looks like a small '
        'tree), and they obey scaling rules like Kleiber\'s law.\n\n'
        'Astonishingly, the very largest structure known — the cosmic web — is a '
        'branching network too: galaxies strung along filaments that meet at '
        'clusters, threading around vast empty voids, gravity having drawn matter '
        'into a tree-like scaffold that spans hundreds of millions of light-years. '
        'From the capillaries in a potato leaf to the skeleton of the universe, '
        'branching is how nature delivers.',
    relatedIds: [
      'cosmic_patterns_fractals',
      'cosmic_patterns_power_laws',
      'cosmic_patterns_why_reuse',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'Look at a bare tree in winter, a diagram of your lungs, a bolt of '
            'lightning, a river seen from space, and a map of the cosmic web. Blur '
            'your eyes and you cannot tell which is which. The universe\'s biggest '
            'structure and the veins in a leaf are built the same way — by '
            'branching.',
      ),
      LessonSection.fact(
        title: 'One design, every scale',
        body:
            'The human lung branches ~23 times to pack a ~70 m² gas-exchange '
            'surface into your chest. The cosmic web threads galaxies along '
            'filaments across ~100 million light-years. Same delivery/collection '
            'logic, ~28 orders of magnitude apart.',
      ),
      LessonSection.table(
        title: 'Branching networks across reality',
        headers: ['Network', 'Source ↔ destination', 'What it moves'],
        rows: [
          ['Tree (canopy + roots)', 'Trunk ↔ leaves & soil', 'Water, sugar, light capture'],
          ['Blood vessels', 'Heart ↔ every cell', 'Oxygen, fuel, waste'],
          ['River network', 'Springs ↔ river mouth', 'Water off a whole landscape'],
          ['Lightning', 'Cloud ↔ ground', 'Electric charge, fastest path'],
          ['Cosmic web', 'Voids ↔ galaxy clusters', 'Matter, drawn by gravity'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'A tree delivering sap and a river collecting rain do opposite jobs — '
            'one distributes, one gathers. Why do they end up the same branched '
            'shape?',
        answer:
            'Because distributing FROM a point and collecting TO a point are the '
            'same problem run backwards. Both must connect a single hub to every '
            'part of a 2-D or 3-D space using the least length of channel. The '
            'cheapest way to touch everywhere is to keep splitting — a fractal, '
            'space-filling tree. Reverse the flow and a delivery network becomes a '
            'collection network with the identical geometry. That is why a river '
            'delta and a lung, or roots and a canopy, are mirror images of one '
            'solution.',
      ),
      LessonSection.thinkReveal(
        title: 'The whole module in one image',
        question:
            'The cosmic web is the biggest branching network we know. Which OTHER '
            'patterns from this module are hiding inside it?',
        answer:
            'Nearly all of them. It BRANCHES (this lesson) into filaments and '
            'clusters. It is FRACTAL — clumpy and self-similar across a wide range '
            'of scales. Its galaxy clustering follows a POWER LAW with distance — '
            'no favourite scale. And it echoes the SPIRAL/gravity dynamics that '
            'shape the galaxies strung along it. The cosmic web is this module\'s '
            'grand finale: the universe\'s largest object, built from the same tiny '
            'toolkit of patterns as a pinecone, a lung, and a potato root.',
      ),
    ],
  ),
];
