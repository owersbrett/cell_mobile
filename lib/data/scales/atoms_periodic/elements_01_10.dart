import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// The Periodic Table — elements 1 through 10 (Hydrogen → Neon).
///
/// One [BioEntity] per element, ordered by atomic number via `position = Z - 1`,
/// so the full 118-element table sorts cleanly across modules. Every entity
/// carries `moduleId: 'atoms_periodic_table'`.
const List<BioEntity> periodicElements01to10 = [
  // ── 1 · Hydrogen ─────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_h',
    scale: BioScale.atoms,
    position: 0,
    name: 'Hydrogen',
    title: 'The First Spark',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The lightest, oldest, and most abundant element — nearly every atom in the universe started as hydrogen.',
    longDescription:
        'Hydrogen is a single proton with a single electron, the simplest atom possible. Forged in the first minutes after the Big Bang, it still makes up about three-quarters of all ordinary matter and fuels every star, including our Sun.\n\n'
        'On Earth it rarely floats free — it prefers to bond, locking into water and into nearly every molecule life is built from. Light enough to escape our gravity entirely, loose hydrogen drifts off into space.',
    relatedIds: ['element_he', 'element_o'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'H'],
          ['Atomic number', '1'],
          ['Group', '1'],
          ['Period', '1'],
          ['Category', 'Nonmetal'],
          ['State at 25°C', 'Gas'],
          ['Standout fact', 'The most abundant element in the universe'],
        ],
      ),
      LessonSection.fact(
        title: 'Star fuel',
        body:
            'The Sun fuses about 600 million tonnes of hydrogen into helium every single second — that fusion is where sunlight comes from.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'If hydrogen is the most common element in the universe, why is there almost no pure hydrogen gas in Earth\'s atmosphere?',
        answer:
            'It is so light that our gravity can\'t hold it — free hydrogen molecules move fast enough to leak into space. What stays behind is hydrogen bonded into heavier molecules like water (H₂O), which are far too heavy to escape.',
      ),
    ],
  ),

  // ── 2 · Helium ───────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_he',
    scale: BioScale.atoms,
    position: 1,
    name: 'Helium',
    title: 'The Unbreakable Loner',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A noble gas so content on its own that it refuses to bond with anything — and it was discovered on the Sun before it was found on Earth.',
    longDescription:
        'Helium\'s outer electron shell is completely full, so it has no reason to react — it forms no natural compounds at all. That aloofness, plus its extreme lightness, makes it the gas that lifts balloons and airships.',
    relatedIds: ['element_h', 'element_ne'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'He'],
          ['Atomic number', '2'],
          ['Group', '18'],
          ['Period', '1'],
          ['Category', 'Noble gas'],
          ['State at 25°C', 'Gas'],
          ['Standout fact', 'Discovered in sunlight before it was found on Earth'],
        ],
      ),
      LessonSection.fact(
        title: 'Found in the Sun',
        body:
            'Helium is named after Helios, the Greek Sun god — astronomers spotted its signature in the Sun\'s spectrum in 1868, decades before anyone isolated it on Earth.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'Helium and hydrogen are both super-light gases. Why do we fill balloons and blimps with helium instead of the even lighter hydrogen?',
        answer:
            'Hydrogen is flammable and can explode, while helium is completely inert and won\'t burn. Helium gives up a little lift for a lot of safety — a tradeoff the Hindenburg disaster made unforgettable.',
      ),
    ],
  ),

  // ── 3 · Lithium ──────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_li',
    scale: BioScale.atoms,
    position: 2,
    name: 'Lithium',
    title: 'The Featherweight Metal',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The lightest metal on the table — so light it floats on water, and it powers nearly every phone and electric car battery.',
    longDescription:
        'Lithium is a soft, silvery alkali metal that is light enough to float and reactive enough to fizz in water. That eagerness to give up its single outer electron makes it perfect for storing and releasing energy.\n\n'
        'Rechargeable lithium-ion batteries turned it into one of the most strategically important elements of the modern age.',
    relatedIds: ['element_h'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Li'],
          ['Atomic number', '3'],
          ['Group', '1'],
          ['Period', '2'],
          ['Category', 'Alkali metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'The least dense metal — it floats on water'],
        ],
      ),
      LessonSection.fact(
        title: 'Battery of the world',
        body:
            'Nearly every smartphone, laptop, and electric car runs on lithium-ion batteries, making this soft metal a linchpin of clean energy.',
      ),
    ],
  ),

  // ── 4 · Beryllium ────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_be',
    scale: BioScale.atoms,
    position: 3,
    name: 'Beryllium',
    title: 'The Stiff and the Sneaky',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A rare, ultra-stiff metal that lets X-rays pass right through it — but its dust is quietly toxic.',
    longDescription:
        'Beryllium is remarkably rigid and light, so aerospace engineers prize it for parts that must stay perfectly stiff, like mirror frames on space telescopes. It is also nearly transparent to X-rays, which makes it the go-to window material for X-ray instruments.\n\n'
        'The catch: inhaling its dust can cause a serious lung disease, so it demands careful handling.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Be'],
          ['Atomic number', '4'],
          ['Group', '2'],
          ['Period', '2'],
          ['Category', 'Alkaline earth metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Nearly transparent to X-rays'],
        ],
      ),
      LessonSection.fact(
        title: 'Telescope-grade stiffness',
        body:
            'The James Webb Space Telescope\'s mirrors are built from beryllium because it barely warps as it cools to the frigid temperatures of deep space.',
      ),
    ],
  ),

  // ── 5 · Boron ────────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_b',
    scale: BioScale.atoms,
    position: 4,
    name: 'Boron',
    title: 'The In-Betweener',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A metalloid that can\'t decide if it\'s a metal — it makes heat-proof glass and helps control nuclear reactors.',
    longDescription:
        'Boron sits on the staircase between metals and nonmetals, behaving a bit like each. Added to glass it produces borosilicate — the tough, heat-shock-resistant material of laboratory beakers and kitchen bakeware.\n\n'
        'Because boron greedily absorbs neutrons, it is also used in control rods that dampen nuclear reactions.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'B'],
          ['Atomic number', '5'],
          ['Group', '13'],
          ['Period', '2'],
          ['Category', 'Metalloid'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Soaks up neutrons in nuclear reactor control rods'],
        ],
      ),
      LessonSection.fact(
        title: 'Kitchen chemistry',
        body:
            'That oven-safe glass dish that survives going straight from freezer to oven is borosilicate glass — boron is what stops it from cracking under thermal shock.',
      ),
    ],
  ),

  // ── 6 · Carbon ───────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_c',
    scale: BioScale.atoms,
    position: 5,
    name: 'Carbon',
    title: 'The Backbone of Life',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The element that links up with itself endlessly — the scaffolding of every living thing, from diamonds to DNA.',
    longDescription:
        'Carbon\'s four bonding sites let it form long chains, rings, and lattices, giving rise to millions of different molecules — more than every other element combined. That versatility is exactly why life is carbon-based.\n\n'
        'The same element appears as soft, dark graphite in your pencil and as the hardest natural material, diamond, depending only on how its atoms are arranged.',
    relatedIds: ['element_o', 'element_h', 'element_n'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'C'],
          ['Atomic number', '6'],
          ['Group', '14'],
          ['Period', '2'],
          ['Category', 'Nonmetal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Forms more compounds than all other elements combined'],
        ],
      ),
      LessonSection.fact(
        title: 'Same atom, two extremes',
        body:
            'Graphite (pencil lead) and diamond are both pure carbon — the only difference is the geometry of how the atoms are bonded together.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'Why is life on Earth built around carbon rather than some other element?',
        answer:
            'Carbon can form four strong, stable bonds and, crucially, bond to itself over and over — chaining into the long, branching, ring-shaped molecules (proteins, DNA, sugars) that complex life requires. No other common element offers that much structural versatility.',
      ),
    ],
  ),

  // ── 7 · Nitrogen ─────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_n',
    scale: BioScale.atoms,
    position: 6,
    name: 'Nitrogen',
    title: 'The Silent Majority',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'It makes up most of the air you breathe, yet you barely notice it — and cracking its triple bond feeds the planet.',
    longDescription:
        'Nitrogen fills 78% of the atmosphere, but as N₂ its two atoms are lashed together by one of the strongest bonds in chemistry, so it drifts along inertly while your body actually uses the oxygen.\n\n'
        'Life needs nitrogen for proteins and DNA, but almost nothing can break that triple bond. Bacteria and the industrial Haber process do it, converting airborne nitrogen into fertilizer that feeds billions.',
    relatedIds: ['element_o', 'element_c'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'N'],
          ['Atomic number', '7'],
          ['Group', '15'],
          ['Period', '2'],
          ['Category', 'Nonmetal'],
          ['State at 25°C', 'Gas'],
          ['Standout fact', 'Makes up about 78% of Earth\'s atmosphere'],
        ],
      ),
      LessonSection.fact(
        title: 'Feeding the world',
        body:
            'The Haber-Bosch process pulls nitrogen straight from the air to make fertilizer — it is estimated to sustain roughly half the people alive today.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'Nitrogen is all around us in the air, yet plants can starve for it. How can something so abundant be so scarce to life?',
        answer:
            'Atmospheric nitrogen is locked as N₂, held by a triple bond most organisms simply cannot break. Only special bacteria (and industrial factories) can "fix" it into usable forms, so the bottleneck is availability, not abundance.',
      ),
    ],
  ),

  // ── 8 · Oxygen ───────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_o',
    scale: BioScale.atoms,
    position: 7,
    name: 'Oxygen',
    title: 'The Breath of Fire',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The element you can\'t live minutes without — it powers your cells and every flame, yet it once poisoned the planet.',
    longDescription:
        'Oxygen is fiercely reactive: it drives the respiration that keeps your cells alive and the combustion of every fire. Combined with hydrogen it makes water, and it is the most abundant element by mass in Earth\'s crust.\n\n'
        'Billions of years ago, early microbes flooded the air with oxygen in what\'s called the Great Oxidation Event — a mass die-off for the life that couldn\'t tolerate it, and the opening for everything that could.',
    relatedIds: ['element_h', 'element_c', 'element_n'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'O'],
          ['Atomic number', '8'],
          ['Group', '16'],
          ['Period', '2'],
          ['Category', 'Nonmetal'],
          ['State at 25°C', 'Gas'],
          ['Standout fact', 'Most abundant element by mass in Earth\'s crust'],
        ],
      ),
      LessonSection.fact(
        title: 'The oxygen catastrophe',
        body:
            'When photosynthetic microbes first pumped oxygen into the air, it was toxic to most life of the time — one of the largest extinction events in history, and the reason we can breathe today.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'Both breathing and burning consume oxygen. What do a campfire and your body actually have in common?',
        answer:
            'Both are oxidation — oxygen combining with fuel to release energy. Fire does it fast and hot; your cells do it slowly and in careful, controlled steps (respiration). Chemically it\'s the same trick, just at very different speeds.',
      ),
    ],
  ),

  // ── 9 · Fluorine ─────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_f',
    scale: BioScale.atoms,
    position: 8,
    name: 'Fluorine',
    title: 'The Most Aggressive Element',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The most reactive element of all — it will burn glass and even attack materials that "can\'t" burn.',
    longDescription:
        'Fluorine is the hungriest element on the table, snatching electrons from almost anything it touches. In its raw form it is dangerously corrosive, reacting with substances most chemicals leave alone.\n\n'
        'Tamed into compounds, though, it turns gentle: fluoride strengthens tooth enamel, and fluorine-based coatings give us non-stick pans.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'F'],
          ['Atomic number', '9'],
          ['Group', '17'],
          ['Period', '2'],
          ['Category', 'Halogen'],
          ['State at 25°C', 'Gas'],
          ['Standout fact', 'The most reactive element on the periodic table'],
        ],
      ),
      LessonSection.fact(
        title: 'From ferocious to friendly',
        body:
            'The same wildly aggressive element, once bonded, gives us tooth-protecting fluoride toothpaste and the slick Teflon coating on non-stick pans.',
      ),
    ],
  ),

  // ── 10 · Neon ────────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_ne',
    scale: BioScale.atoms,
    position: 9,
    name: 'Neon',
    title: 'The Glowing Recluse',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A noble gas so unreactive it forms zero compounds — but zap it with electricity and it blazes with that famous orange-red glow.',
    longDescription:
        'Neon\'s electron shells are full, so it never bonds with anything — it is one of the truly inert noble gases. What it does do spectacularly is glow: pass an electric current through neon and it emits a vivid reddish-orange light.\n\n'
        'That glow launched an entire aesthetic of "neon" signs, even though most colorful tube signs actually use other gases.',
    relatedIds: ['element_he'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Ne'],
          ['Atomic number', '10'],
          ['Group', '18'],
          ['Period', '2'],
          ['Category', 'Noble gas'],
          ['State at 25°C', 'Gas'],
          ['Standout fact', 'Forms no known stable compounds at all'],
        ],
      ),
      LessonSection.fact(
        title: 'True neon is orange',
        body:
            'Only the reddish-orange tubes are actually neon gas — the blues, greens, and pinks of a "neon" sign come from other gases and coatings.',
      ),
    ],
  ),
];
