import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Atoms → "The Periodic Table" module, elements 11–20 (Na → Ca).
/// One BioEntity per element, ascending atomic number. `moduleId` is the
/// mandatory `'atoms_periodic_table'` string on every entity.
const List<BioEntity> periodicElements11to20 = [
  // ── 11 · Na · Sodium ── MARQUEE ─────────────────────────────────────────
  BioEntity(
    id: 'element_na',
    scale: BioScale.atoms,
    position: 10,
    name: 'Sodium',
    title: 'The Metal That Explodes in Water',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A soft silver metal so reactive it bursts into flame the instant it touches water — yet you eat it every day locked safely inside salt.',
    longDescription:
        'Sodium is an alkali metal so eager to give away its single outer electron that a lump dropped in water skates around fizzing, then ignites. Store it under oil and it stays a soft, cuttable silver.\n\n'
        'Tame that fury by pairing it with chlorine and you get sodium chloride — table salt. Your nerves fire and your muscles contract because sodium ions pump in and out of your cells, so the same element that explodes in a bucket keeps your heart beating.',
    relatedIds: ['element_cl', 'element_k'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Na'],
          ['Atomic number', '11'],
          ['Group', '1 (alkali metals)'],
          ['Period', '3'],
          ['Category', 'Alkali metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Reacts violently with water, bursting into flame'],
        ],
      ),
      LessonSection.fact(
        title: 'Why "Na"?',
        body:
            'The symbol comes from the Latin "natrium" — the same root as natron, the mineral salt ancient Egyptians used to preserve mummies.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'If pure sodium explodes in water, how can we safely sprinkle it on food?',
        answer:
            'In table salt the sodium has already handed its extra electron to chlorine, forming stable Na⁺ and Cl⁻ ions. The reactive lone electron is gone, so the compound is calm and edible.',
      ),
    ],
  ),

  // ── 12 · Mg · Magnesium ─────────────────────────────────────────────────
  BioEntity(
    id: 'element_mg',
    scale: BioScale.atoms,
    position: 11,
    name: 'Magnesium',
    title: 'The Metal That Burns Blinding White',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Once lit, magnesium blazes a white so intense old photographers used it as flash powder — and it sits at the heart of every green leaf.',
    longDescription:
        'Magnesium is a light, silvery structural metal, but its party trick is fire: a strip once ignited burns with a searing white glare that water cannot easily extinguish. Early photography and fireworks leaned on that flash.\n\n'
        'Biologically it is quieter but essential — a magnesium atom sits at the core of every chlorophyll molecule, the pigment that lets plants capture sunlight. Without it, the green world would go dark.',
    relatedIds: ['element_ca'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Mg'],
          ['Atomic number', '12'],
          ['Group', '2 (alkaline earth metals)'],
          ['Period', '3'],
          ['Category', 'Alkaline earth metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Burns with a blinding white flame; core of chlorophyll'],
        ],
      ),
      LessonSection.fact(
        title: 'Light and strong',
        body:
            'Alloyed with aluminium, magnesium makes some of the lightest structural metals used — in laptops, car wheels, and aircraft parts.',
      ),
    ],
  ),

  // ── 13 · Al · Aluminium ─────────────────────────────────────────────────
  BioEntity(
    id: 'element_al',
    scale: BioScale.atoms,
    position: 12,
    name: 'Aluminium',
    title: 'Once More Precious Than Gold',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The most abundant metal in Earth\'s crust was once so hard to purify that emperors served guests on aluminium plates while everyone else used gold.',
    longDescription:
        'Aluminium is everywhere — it makes up about 8% of the crust — yet it clings so tightly to oxygen that for most of history no one could isolate it cheaply. In the 1800s it briefly outvalued gold, and Napoleon III reserved aluminium cutlery for his most honored guests.\n\n'
        'An electric smelting process changed all that, and aluminium became the workhorse of foil, cans, and aircraft. A thin invisible oxide skin forms instantly on its surface, which is why it resists corrosion so well.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Al'],
          ['Atomic number', '13'],
          ['Group', '13'],
          ['Period', '3'],
          ['Category', 'Post-transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Most abundant metal in Earth\'s crust'],
        ],
      ),
      LessonSection.fact(
        title: 'Self-healing skin',
        body:
            'Scratch aluminium and a fresh oxide layer seals the wound in moments — that self-repairing film is why it does not rust away like iron.',
      ),
    ],
  ),

  // ── 14 · Si · Silicon ── MARQUEE ────────────────────────────────────────
  BioEntity(
    id: 'element_si',
    scale: BioScale.atoms,
    position: 13,
    name: 'Silicon',
    title: 'The Element That Thinks',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'From beach sand to the brains of every computer — silicon is the semiconductor that an entire valley was named after.',
    longDescription:
        'Silicon is the second most abundant element in the crust, mostly locked up as silica in sand, quartz, and rock. Purify it into a flawless crystal and it becomes a semiconductor: a material that conducts electricity only when you tell it to.\n\n'
        'That switchable behavior is the foundation of the transistor, and billions of transistors etched onto a fingernail of silicon make a microchip. Silicon Valley, and the modern world of computing, rides on this one element.',
    relatedIds: ['element_al'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Si'],
          ['Atomic number', '14'],
          ['Group', '14'],
          ['Period', '3'],
          ['Category', 'Metalloid'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'The semiconductor at the heart of every computer chip'],
        ],
      ),
      LessonSection.fact(
        title: 'Sand to circuits',
        body:
            'Second most abundant element in the crust — the same silica in a handful of beach sand is refined into the wafers that run your phone.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'Metals conduct electricity and glass insulates. Why is a "semiconductor" so useful for computers?',
        answer:
            'Because it can be switched between conducting and not conducting. A transistor uses a small voltage to flip silicon on or off, and an on/off switch is exactly the 1 and 0 a computer needs.',
      ),
    ],
  ),

  // ── 15 · P · Phosphorus ─────────────────────────────────────────────────
  BioEntity(
    id: 'element_p',
    scale: BioScale.atoms,
    position: 14,
    name: 'Phosphorus',
    title: 'The Light-Bearer',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Discovered by boiling down urine, this glowing element gives its name to matches, DNA\'s backbone, and the very word "phosphorescent."',
    longDescription:
        'Phosphorus was first isolated by an alchemist who evaporated buckets of urine hoping to make gold — instead he got a waxy substance that glowed eerily in the dark. Its name means "light-bearer." White phosphorus is dangerously flammable; the red form coats the striking strip of a matchbox.\n\n'
        'Life could not exist without it. Phosphate groups form the backbone of DNA and RNA, and the energy molecule ATP hands out power one phosphate bond at a time. It is also a key crop nutrient in fertilizer.',
    relatedIds: ['element_s'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'P'],
          ['Atomic number', '15'],
          ['Group', '15'],
          ['Period', '3'],
          ['Category', 'Reactive nonmetal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Forms the backbone of DNA and the energy currency ATP'],
        ],
      ),
      LessonSection.fact(
        title: 'The glow that named it',
        body:
            'White phosphorus glows faintly as it slowly reacts with air — the origin of the word "phosphorescence."',
      ),
    ],
  ),

  // ── 16 · S · Sulfur ─────────────────────────────────────────────────────
  BioEntity(
    id: 'element_s',
    scale: BioScale.atoms,
    position: 15,
    name: 'Sulfur',
    title: 'The Brimstone Element',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The yellow "brimstone" of volcanoes and legend — and the reason rotten eggs, skunks, and struck matches all share that unforgettable stink.',
    longDescription:
        'Sulfur is a bright yellow solid found in pure crusts around volcanic vents; the old word "brimstone" is simply "burning stone." Many of its compounds are famously smelly — hydrogen sulfide is the rotten-egg gas, and sulfur compounds give skunk spray and garlic their punch.\n\n'
        'Industrially it is a giant: most mined sulfur becomes sulfuric acid, one of the most produced chemicals on Earth and a rough gauge of a nation\'s industrial output. In the body, sulfur helps proteins fold by forming bridges between amino acids.',
    relatedIds: ['element_p', 'element_cl'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'S'],
          ['Atomic number', '16'],
          ['Group', '16 (chalcogens)'],
          ['Period', '3'],
          ['Category', 'Reactive nonmetal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Turned into sulfuric acid, the world\'s most-made chemical'],
        ],
      ),
      LessonSection.fact(
        title: 'The industrial yardstick',
        body:
            'Sulfuric acid production is so central to manufacturing that economists once used it to estimate how industrialized a country was.',
      ),
    ],
  ),

  // ── 17 · Cl · Chlorine ── MARQUEE ───────────────────────────────────────
  BioEntity(
    id: 'element_cl',
    scale: BioScale.atoms,
    position: 16,
    name: 'Chlorine',
    title: 'The Poison Gas That Purifies Water',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A green-yellow gas deadly enough to be a WWI weapon — yet the same element makes tap water safe to drink and joins sodium to become table salt.',
    longDescription:
        'Chlorine is a choking green-yellow gas, so hungry for electrons that it attacks almost anything. It was used as a chemical weapon in World War I, and even a whiff bleaches color and kills microbes.\n\n'
        'That same germ-killing ferocity, used in tiny doses, disinfects drinking water and swimming pools — chlorine has saved more lives from waterborne disease than almost any other chemical. Bonded to sodium, it loses its menace entirely and becomes the salt on your fries.',
    relatedIds: ['element_na', 'element_ar'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Cl'],
          ['Atomic number', '17'],
          ['Group', '17 (halogens)'],
          ['Period', '3'],
          ['Category', 'Halogen (reactive nonmetal)'],
          ['State at 25°C', 'Gas'],
          ['Standout fact', 'Disinfects drinking water; half of table salt'],
        ],
      ),
      LessonSection.fact(
        title: 'One electron short',
        body:
            'Chlorine needs just one more electron to fill its outer shell — which is exactly why it grabs sodium\'s spare so eagerly to form salt.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'Sodium explodes and chlorine is poisonous. So why is the compound they form perfectly safe to eat?',
        answer:
            'When they react, sodium gives its extra electron to chlorine. Both end up with stable, full outer shells as Na⁺ and Cl⁻ ions locked in a crystal — the reactive traits vanish, leaving harmless table salt.',
      ),
    ],
  ),

  // ── 18 · Ar · Argon ─────────────────────────────────────────────────────
  BioEntity(
    id: 'element_ar',
    scale: BioScale.atoms,
    position: 17,
    name: 'Argon',
    title: 'The Lazy Gas',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Named from the Greek for "lazy," this noble gas is so unreactive it fills lightbulbs and shields welds — and it\'s the third most common gas in the air you breathe.',
    longDescription:
        'Argon is a noble gas with a full outer electron shell, which makes it almost completely inert — its name comes from the Greek "argos," meaning idle or lazy. It refuses to react, so it makes an ideal protective blanket.\n\n'
        'That indifference is useful: argon fills incandescent bulbs so the hot filament does not burn up, shields molten metal during welding, and preserves old documents. Surprisingly, it is the most abundant noble gas on Earth, making up nearly 1% of the atmosphere.',
    relatedIds: ['element_cl', 'element_k'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Ar'],
          ['Atomic number', '18'],
          ['Group', '18 (noble gases)'],
          ['Period', '3'],
          ['Category', 'Noble gas'],
          ['State at 25°C', 'Gas'],
          ['Standout fact', 'Third most abundant gas in the atmosphere (~0.9%)'],
        ],
      ),
      LessonSection.fact(
        title: 'Hiding in plain air',
        body:
            'Every breath you take is nearly 1% argon — more common than carbon dioxide, yet it does nothing at all inside you because it refuses to react.',
      ),
    ],
  ),

  // ── 19 · K · Potassium ── MARQUEE ───────────────────────────────────────
  BioEntity(
    id: 'element_k',
    scale: BioScale.atoms,
    position: 18,
    name: 'Potassium',
    title: 'The Spark in Every Heartbeat',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Even more explosive in water than sodium, potassium also carries the electrical signal that fires your nerves — and a banana is packed with it.',
    longDescription:
        'Potassium is an alkali metal that reacts with water even more violently than sodium, often igniting a lilac flame on contact. Its symbol "K" comes from "kalium," from the Arabic word for the plant ash it was first extracted from.\n\n'
        'Inside living cells it is indispensable. The rhythmic movement of potassium ions across cell membranes generates the electrical impulses that fire nerves and beat the heart, working in a constant push-pull with sodium. That is why bananas and leafy greens are prized for potassium.',
    relatedIds: ['element_na', 'element_ca'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'K'],
          ['Atomic number', '19'],
          ['Group', '1 (alkali metals)'],
          ['Period', '4'],
          ['Category', 'Alkali metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Its ions fire your nerves and heartbeat'],
        ],
      ),
      LessonSection.fact(
        title: 'Why "K"?',
        body:
            'The symbol derives from "kalium," rooted in the Arabic "al-qali" — the plant ashes (potash) that gave potassium its English name too.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'Sodium and potassium are both explosive metals. Why does your body need BOTH working together?',
        answer:
            'Nerve and muscle cells create electrical signals by pumping sodium out and potassium in, then letting them rush back. The voltage difference between the two ions is the spark — one alone cannot make the signal.',
      ),
    ],
  ),

  // ── 20 · Ca · Calcium ── MARQUEE ────────────────────────────────────────
  BioEntity(
    id: 'element_ca',
    scale: BioScale.atoms,
    position: 19,
    name: 'Calcium',
    title: 'The Scaffolding of Life',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The metal you are literally built from — calcium hardens your bones and teeth, and the same element makes chalk, marble, and seashells.',
    longDescription:
        'Calcium is a soft, reactive alkaline earth metal you would never recognize in its pure form — because nature never leaves it pure. It is always bound in compounds: as calcium carbonate it is limestone, marble, chalk, coral, and seashells; as calcium phosphate it is the mineral that hardens your skeleton and teeth.\n\n'
        'Beyond structure, calcium ions act as a chemical messenger inside cells, triggering muscle contraction and helping blood clot. It is the most abundant metal in the human body.',
    relatedIds: ['element_mg', 'element_k'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Ca'],
          ['Atomic number', '20'],
          ['Group', '2 (alkaline earth metals)'],
          ['Period', '4'],
          ['Category', 'Alkaline earth metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Most abundant metal in the human body; builds bone'],
        ],
      ),
      LessonSection.fact(
        title: 'One element, many faces',
        body:
            'Chalk, marble, seashells, coral, and your own bones are all held together by calcium compounds.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'Pure calcium is a soft, reactive metal — so how can it make something as hard as bone or marble?',
        answer:
            'Bone and marble are not pure calcium. Calcium is combined with phosphate or carbonate into rigid crystals. The ionic bonds in those crystals give the hardness, while the lone metal stays soft and reactive.',
      ),
    ],
  ),
];
