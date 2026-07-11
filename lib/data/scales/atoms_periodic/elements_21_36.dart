import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Atoms → "The Periodic Table" module. Entities carry moduleId:
/// 'atoms_periodic_table'. Period-4 (Z 21–36): the first full row of
/// transition metals (Sc–Zn) plus the p-block run (Ga–Kr). One BioEntity
/// per element, ascending atomic number.
const List<BioEntity> periodicElements21to36 = <BioEntity>[
  // ── 21 · Scandium ──────────────────────────────────────────────────────
  BioEntity(
    id: 'element_sc',
    scale: BioScale.atoms,
    position: 20,
    name: 'Scandium',
    title: 'The Lightweight Metal Mendeleev Predicted',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The first transition metal, and a gap Mendeleev left blank years before anyone found it.',
    longDescription:
        'Scandium opens the transition-metal block. It is light, silvery, and rare '
        'in concentrated form, so it stayed hidden until 1879.\n\n'
        'Mendeleev had already sketched a placeholder for it — "eka-boron" — from '
        'the shape of his table alone, one of chemistry\'s great predictive wins.',
    relatedIds: ['element_ti', 'element_ca'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Sc'],
          ['Atomic number', '21'],
          ['Group', '3'],
          ['Period', '4'],
          ['Category', 'Transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Predicted as "eka-boron" before its discovery'],
        ],
      ),
      LessonSection.fact(
        title: 'Aluminium\'s stiffening partner',
        body:
            'A pinch of scandium in aluminium makes an alloy strong enough for '
            'aerospace frames and high-end bike parts.',
      ),
    ],
  ),

  // ── 22 · Titanium (MARQUEE) ────────────────────────────────────────────
  BioEntity(
    id: 'element_ti',
    scale: BioScale.atoms,
    position: 21,
    name: 'Titanium',
    title: 'Strong as Steel, Nearly Half the Weight',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The strength-to-weight champion of engineering metals, and biocompatible enough to live inside your body.',
    longDescription:
        'Titanium matches steel for strength while weighing about 45% less, and it '
        'shrugs off corrosion thanks to an instant oxide skin.\n\n'
        'It is so unreactive with living tissue that surgeons build hip implants '
        'and tooth roots from it, while its white oxide (TiO₂) brightens paint, '
        'sunscreen, and toothpaste.',
    relatedIds: ['element_sc', 'element_v', 'element_fe'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Ti'],
          ['Atomic number', '22'],
          ['Group', '4'],
          ['Period', '4'],
          ['Category', 'Transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Best strength-to-weight ratio of any metal'],
        ],
      ),
      LessonSection.fact(
        title: 'The white in everything',
        body:
            'Titanium dioxide is the brightest white pigment known — it hides '
            'inside paint, paper, sunscreen, and most toothpaste.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'Titanium is very reactive with oxygen, yet objects made of it barely corrode. How can both be true?',
        answer:
            'It reacts so fast that a microscopically thin, tough oxide layer '
            'forms the instant metal meets air. That skin seals the surface and '
            'stops any further reaction — self-healing armor a few atoms thick.',
      ),
    ],
  ),

  // ── 23 · Vanadium ──────────────────────────────────────────────────────
  BioEntity(
    id: 'element_v',
    scale: BioScale.atoms,
    position: 22,
    name: 'Vanadium',
    title: 'The Rainbow-Colored Steel Toughener',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Named for a Norse goddess of beauty because its compounds bloom in a rainbow of colors.',
    longDescription:
        'Vanadium is a hard, silvery metal whose ions shift through purple, green, '
        'blue, and yellow depending on their charge — the reason it was named after '
        'Vanadís, a Norse goddess of beauty.\n\n'
        'Its main job is quiet but huge: a small amount turns ordinary steel into '
        'the tough, shock-resistant "vanadium steel" used for wrenches and tools.',
    relatedIds: ['element_ti', 'element_cr'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'V'],
          ['Atomic number', '23'],
          ['Group', '5'],
          ['Period', '4'],
          ['Category', 'Transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Its four common ions are four different colors'],
        ],
      ),
      LessonSection.fact(
        title: 'Batteries for the grid',
        body:
            'Vanadium flow batteries store renewable energy at grid scale by '
            'pumping charged liquid vanadium between tanks.',
      ),
    ],
  ),

  // ── 24 · Chromium ──────────────────────────────────────────────────────
  BioEntity(
    id: 'element_cr',
    scale: BioScale.atoms,
    position: 23,
    name: 'Chromium',
    title: 'The Shine That Never Rusts',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The mirror-bright plating on chrome trim and the reason stainless steel stays stainless.',
    longDescription:
        'Chromium takes a brilliant polish and forms a self-repairing oxide film, '
        'which is why chrome plating stays shiny for decades.\n\n'
        'Blend it into steel above about 11% and you get stainless steel; its '
        'compounds also color emeralds green and rubies red.',
    relatedIds: ['element_v', 'element_mn', 'element_fe'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Cr'],
          ['Atomic number', '24'],
          ['Group', '6'],
          ['Period', '4'],
          ['Category', 'Transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Makes steel "stainless" and gems red or green'],
        ],
      ),
      LessonSection.fact(
        title: 'Colorful by name',
        body:
            'Its name comes from the Greek "chroma" (color) — nearly all chromium '
            'compounds are vividly colored.',
      ),
    ],
  ),

  // ── 25 · Manganese ─────────────────────────────────────────────────────
  BioEntity(
    id: 'element_mn',
    scale: BioScale.atoms,
    position: 24,
    name: 'Manganese',
    title: 'The Metal Inside Every Steel Rail',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A hard, brittle metal that makes steel tough — and helps split water inside every green leaf.',
    longDescription:
        'Manganese is too brittle to use alone, but almost all steel contains it '
        'because it scavenges sulfur and oxygen and hardens the alloy for rails, '
        'helmets, and safes.\n\n'
        'Life needs it too: a cluster of manganese atoms at the heart of '
        'photosynthesis is what pries oxygen out of water molecules.',
    relatedIds: ['element_cr', 'element_fe'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Mn'],
          ['Atomic number', '25'],
          ['Group', '7'],
          ['Period', '4'],
          ['Category', 'Transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Splits water to release oxygen in photosynthesis'],
        ],
      ),
      LessonSection.fact(
        title: 'The purple test-tube metal',
        body:
            'Potassium permanganate is a deep purple manganese compound used to '
            'disinfect water and treat wounds.',
      ),
    ],
  ),

  // ── 26 · Iron (MARQUEE) ────────────────────────────────────────────────
  BioEntity(
    id: 'element_fe',
    scale: BioScale.atoms,
    position: 25,
    name: 'Iron',
    title: 'The Metal That Built Civilization — and Carries Your Breath',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The core of the Earth, the heart of steel, and the atom that ferries oxygen through your blood.',
    longDescription:
        'Iron is the most-used metal on Earth and the main ingredient of steel. '
        'The planet\'s molten iron core generates the magnetic field that shields '
        'us from solar wind.\n\n'
        'Inside you, iron sits at the center of hemoglobin, grabbing oxygen in '
        'your lungs and releasing it to every cell — the reason blood is red.',
    relatedIds: ['element_mn', 'element_co', 'element_ni'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Fe'],
          ['Atomic number', '26'],
          ['Group', '8'],
          ['Period', '4'],
          ['Category', 'Transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Carries oxygen in your blood via hemoglobin'],
        ],
      ),
      LessonSection.fact(
        title: 'The end of the line for stars',
        body:
            'Fusion in stars stops at iron — building heavier elements costs '
            'energy instead of releasing it, so iron marks a star\'s dying stage.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'Why does a star collapse and often explode once its core turns to iron?',
        answer:
            'Fusing lighter nuclei releases energy that props the star up against '
            'gravity. But fusing iron absorbs energy instead of releasing it, so '
            'the outward push vanishes — gravity wins, the core collapses, and a '
            'supernova can follow.',
      ),
    ],
  ),

  // ── 27 · Cobalt ────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_co',
    scale: BioScale.atoms,
    position: 26,
    name: 'Cobalt',
    title: 'The Blue of Ancient Glass',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The deep blue in medieval glass, the magnet in jet engines, and the metal in your phone battery.',
    longDescription:
        'Cobalt has colored glass and ceramics an intense blue for millennia — '
        '"cobalt blue" is still the pigment\'s name.\n\n'
        'It stays magnetic at high temperatures, making it vital for jet-engine '
        'superalloys, and it is a key ingredient in the lithium-ion batteries that '
        'power phones and electric cars.',
    relatedIds: ['element_fe', 'element_ni'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Co'],
          ['Atomic number', '27'],
          ['Group', '9'],
          ['Period', '4'],
          ['Category', 'Transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'The blue pigment in glass for over 2,000 years'],
        ],
      ),
      LessonSection.fact(
        title: 'Hiding in vitamin B₁₂',
        body:
            'A single cobalt atom sits at the center of vitamin B₁₂, essential '
            'for making red blood cells and DNA.',
      ),
    ],
  ),

  // ── 28 · Nickel ────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_ni',
    scale: BioScale.atoms,
    position: 27,
    name: 'Nickel',
    title: 'The Coin Metal From Deep Space',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Named after a mischievous goblin, it plates coins, resists rust, and rains down in meteorites.',
    longDescription:
        'Nickel is tough, corrosion-resistant, and magnetic, so it plates coins and '
        'strengthens stainless steel and superalloys.\n\n'
        'Miners named its ore "kupfernickel" ("Old Nick\'s copper") because it '
        'looked like copper ore but yielded no copper. Much of Earth\'s accessible '
        'nickel arrived in ancient iron-nickel meteorites.',
    relatedIds: ['element_fe', 'element_co', 'element_cu'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Ni'],
          ['Atomic number', '28'],
          ['Group', '10'],
          ['Period', '4'],
          ['Category', 'Transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Named for a goblin who "stole" the copper'],
        ],
      ),
      LessonSection.fact(
        title: 'Rechargeable workhorse',
        body:
            'Nickel-metal-hydride and nickel-rich lithium batteries power hybrids '
            'and electric vehicles worldwide.',
      ),
    ],
  ),

  // ── 29 · Copper (MARQUEE) ──────────────────────────────────────────────
  BioEntity(
    id: 'element_cu',
    scale: BioScale.atoms,
    position: 28,
    name: 'Copper',
    title: 'The Wire That Wired the World',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The first metal humans mastered and still the metal that carries our electricity.',
    longDescription:
        'Copper conducts electricity better than any metal but silver, and it is '
        'far cheaper — so it fills the wires and cables behind modern life.\n\n'
        'It was also the first metal worked by humans and, alloyed with tin, gave '
        'the Bronze Age its name. Exposed to weather, it grows the green patina '
        'that coats the Statue of Liberty.',
    relatedIds: ['element_ni', 'element_zn'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Cu'],
          ['Atomic number', '29'],
          ['Group', '11'],
          ['Period', '4'],
          ['Category', 'Transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Second-best electrical conductor, first for wiring'],
        ],
      ),
      LessonSection.fact(
        title: 'Naturally germ-killing',
        body:
            'Copper surfaces kill many bacteria and viruses on contact, which is '
            'why hospitals fit copper doorknobs and rails.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'The Statue of Liberty is copper, yet it\'s green. What turned it that color?',
        answer:
            'Over decades, copper reacts with air, moisture, and pollutants to '
            'form a thin layer of copper carbonate and sulfate — the green '
            'patina. Like titanium\'s oxide, this coating protects the metal '
            'underneath from further corrosion.',
      ),
    ],
  ),

  // ── 30 · Zinc (MARQUEE) ────────────────────────────────────────────────
  BioEntity(
    id: 'element_zn',
    scale: BioScale.atoms,
    position: 29,
    name: 'Zinc',
    title: 'The Bodyguard Metal',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'It sacrifices itself to stop iron from rusting — and runs hundreds of reactions inside your cells.',
    longDescription:
        'Zinc coats steel as galvanizing: it corrodes in the steel\'s place, '
        'protecting bridges and car bodies for decades even when the coating gets '
        'scratched.\n\n'
        'It is also a nutritional essential — hundreds of your enzymes need a zinc '
        'atom to work, supporting immunity, healing, and taste.',
    relatedIds: ['element_cu', 'element_ga'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Zn'],
          ['Atomic number', '30'],
          ['Group', '12'],
          ['Period', '4'],
          ['Category', 'Transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Galvanizing: it rusts so iron doesn\'t have to'],
        ],
      ),
      LessonSection.fact(
        title: 'Half of brass',
        body:
            'Brass is copper mixed with zinc — the golden alloy of instruments, '
            'doorknobs, and plumbing fittings.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'A galvanized bucket gets scratched to bare steel. Why doesn\'t rust spread from the scratch?',
        answer:
            'Zinc is more reactive than iron, so it corrodes first — a '
            '"sacrificial" anode. Even at a scratch, the surrounding zinc gives '
            'up electrons to protect the exposed iron, so the steel survives '
            'while the zinc slowly wears away.',
      ),
    ],
  ),

  // ── 31 · Gallium ───────────────────────────────────────────────────────
  BioEntity(
    id: 'element_ga',
    scale: BioScale.atoms,
    position: 30,
    name: 'Gallium',
    title: 'The Metal That Melts in Your Hand',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A silvery metal so low-melting it turns liquid from the warmth of your palm.',
    longDescription:
        'Gallium is solid at room temperature but melts at about 30°C, so a chunk '
        'held in a warm hand becomes a shimmering liquid — a classic party trick.\n\n'
        'Its real value is in electronics: gallium arsenide and gallium nitride '
        'run the fast chips, LEDs, and radio circuits in phones and blue-light '
        'displays.',
    relatedIds: ['element_zn', 'element_ge', 'element_al'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Ga'],
          ['Atomic number', '31'],
          ['Group', '13'],
          ['Period', '4'],
          ['Category', 'Post-transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Melts at body-warm temperature (~30°C)'],
        ],
      ),
      LessonSection.fact(
        title: 'The other predicted element',
        body:
            'Mendeleev foretold gallium as "eka-aluminium"; its 1875 discovery, '
            'matching his numbers, helped prove the periodic table.',
      ),
    ],
  ),

  // ── 32 · Germanium ─────────────────────────────────────────────────────
  BioEntity(
    id: 'element_ge',
    scale: BioScale.atoms,
    position: 31,
    name: 'Germanium',
    title: 'The Semiconductor Before Silicon',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The metalloid that ran the very first transistors, before silicon took over the world.',
    longDescription:
        'Germanium is a brittle, grey metalloid that behaves partway between metal '
        'and nonmetal. The first working transistor in 1947 was built from it, '
        'launching the electronic age.\n\n'
        'Silicon later became cheaper and easier, but germanium still shines in '
        'fiber-optic cores, infrared lenses, and high-speed chip layers.',
    relatedIds: ['element_ga', 'element_as', 'element_si'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Ge'],
          ['Atomic number', '32'],
          ['Group', '14'],
          ['Period', '4'],
          ['Category', 'Metalloid'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Home of the first transistor (1947)'],
        ],
      ),
      LessonSection.fact(
        title: 'Third predicted element',
        body:
            'Mendeleev\'s "eka-silicon" — germanium\'s 1886 discovery matched his '
            'forecast almost exactly, another triumph for the table.',
      ),
    ],
  ),

  // ── 33 · Arsenic ───────────────────────────────────────────────────────
  BioEntity(
    id: 'element_as',
    scale: BioScale.atoms,
    position: 32,
    name: 'Arsenic',
    title: 'The King of Poisons',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A tasteless, colorless poison of history — and, in tiny doses, a genuine semiconductor dopant.',
    longDescription:
        'Arsenic is a metalloid whose soluble compounds are highly toxic and, '
        'being tasteless, were the notorious poison of royal courts — the "king of '
        'poisons."\n\n'
        'Today it is used deliberately in tiny amounts to dope semiconductors '
        '(gallium arsenide) and once tinted Victorian wallpapers a deadly green.',
    relatedIds: ['element_ge', 'element_se'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'As'],
          ['Atomic number', '33'],
          ['Group', '15'],
          ['Period', '4'],
          ['Category', 'Metalloid'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'The tasteless "king of poisons"'],
        ],
      ),
      LessonSection.fact(
        title: 'Sublimes, not melts',
        body:
            'At normal pressure grey arsenic skips liquid entirely, turning '
            'straight from solid to vapor when heated.',
      ),
    ],
  ),

  // ── 34 · Selenium ──────────────────────────────────────────────────────
  BioEntity(
    id: 'element_se',
    scale: BioScale.atoms,
    position: 33,
    name: 'Selenium',
    title: 'The Element That Sees Light',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Its conductivity jumps in the light, which is how the first photocopiers and light meters worked.',
    longDescription:
        'Selenium is a nonmetal whose electrical conductivity rises sharply when '
        'light hits it — the property behind early photocells, light meters, and '
        'xerographic copying.\n\n'
        'In trace amounts it is an essential nutrient, built into antioxidant '
        'enzymes; too much, though, is toxic. It also gives glass its ruby-red tint.',
    relatedIds: ['element_as', 'element_br'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Se'],
          ['Atomic number', '34'],
          ['Group', '16'],
          ['Period', '4'],
          ['Category', 'Nonmetal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Conducts more electricity in the light'],
        ],
      ),
      LessonSection.fact(
        title: 'Named for the Moon',
        body:
            'Its name comes from "selene," Greek for Moon, as a companion to the '
            'Earth-named element tellurium.',
      ),
    ],
  ),

  // ── 35 · Bromine (MARQUEE) ─────────────────────────────────────────────
  BioEntity(
    id: 'element_br',
    scale: BioScale.atoms,
    position: 34,
    name: 'Bromine',
    title: 'The Only Liquid Nonmetal',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A dense, red-brown liquid at room temperature — one of just two elements that are liquid at 25°C.',
    longDescription:
        'Bromine is a heavy, red-brown, fuming liquid — the only nonmetal liquid '
        'at room temperature, and one of only two liquid elements alongside mercury.\n\n'
        'A member of the halogen family, it is corrosive and choking (its name '
        'means "stench"). It has been used in flame retardants, film chemistry, '
        'and pool sanitizers.',
    relatedIds: ['element_se', 'element_kr', 'element_cl'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Br'],
          ['Atomic number', '35'],
          ['Group', '17'],
          ['Period', '4'],
          ['Category', 'Halogen (nonmetal)'],
          ['State at 25°C', 'Liquid'],
          ['Standout fact', 'The only nonmetal that is liquid at room temperature'],
        ],
      ),
      LessonSection.fact(
        title: 'Royal purple\'s source',
        body:
            'Ancient "Tyrian purple" dye, worth more than gold, was a '
            'bromine-containing compound harvested from sea snails.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'Only two elements are liquid at 25°C. Bromine is one — what is the other?',
        answer:
            'Mercury, the liquid metal. Bromine (a nonmetal) and mercury (a '
            'metal) are the only two elements that are liquids at ordinary room '
            'temperature and pressure.',
      ),
    ],
  ),

  // ── 36 · Krypton ───────────────────────────────────────────────────────
  BioEntity(
    id: 'element_kr',
    scale: BioScale.atoms,
    position: 35,
    name: 'Krypton',
    title: 'The Hidden Noble Gas',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A rare, unreactive gas whose name means "hidden" — and, briefly, the ruler of the meter itself.',
    longDescription:
        'Krypton is a colorless, odorless noble gas found in trace amounts in the '
        'air. Being nearly inert, it fills high-performance light bulbs and lasers '
        'and gives a whitish glow in discharge tubes.\n\n'
        'From 1960 to 1983 the meter was officially defined by wavelengths of '
        'orange light from krypton-86 — for two decades this gas defined length itself.',
    relatedIds: ['element_br', 'element_ar'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Kr'],
          ['Atomic number', '36'],
          ['Group', '18'],
          ['Period', '4'],
          ['Category', 'Noble gas'],
          ['State at 25°C', 'Gas'],
          ['Standout fact', 'Once defined the length of the meter (1960–1983)'],
        ],
      ),
      LessonSection.fact(
        title: '"Hidden" by name',
        body:
            'Krypton comes from the Greek "kryptos" (hidden) — it was buried in '
            'trace amounts of liquefied air when discovered in 1898.',
      ),
    ],
  ),
];
