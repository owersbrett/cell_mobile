import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Atoms → "The Periodic Table" module. Entities carry moduleId:
/// 'atoms_periodic_table'. (Authored by module agent.)
const List<BioEntity> periodicElements87to103 = <BioEntity>[
  // 87 — Francium
  BioEntity(
    id: 'element_fr',
    scale: BioScale.atoms,
    position: 86,
    name: 'Francium',
    title: 'The Ghost Metal',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The most unstable of the natural elements — scientists estimate less than 30 grams exist on Earth at any moment.',
    longDescription:
        'Francium is an alkali metal that behaves like a heavier, wilder cousin of sodium and potassium, but almost nobody has ever seen a visible chunk of it. Its longest-lived isotope decays in about 22 minutes, so any atom that forms is gone almost as fast as it appears. It exists in Earth\'s crust only as a fleeting product of uranium and thorium decay.\n\nDiscovered in 1939 by Marguerite Perey in Paris, it was the last element found in nature rather than made in a lab. Perey named it after France.',
    relatedIds: ['element_ra', 'element_ac'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Fr'],
          ['Atomic number', '87'],
          ['Group', '1'],
          ['Period', '7'],
          ['Category', 'Alkali metal'],
          ['State at 25°C', 'Solid (never observed in bulk)'],
          ['Standout fact', 'Rarest naturally occurring element on Earth'],
        ],
      ),
      LessonSection.fact(
        title: 'Blink and it\'s gone',
        body:
            'Francium-223, its most stable form, has a half-life of just 22 minutes — you could never fill a jar with it.',
      ),
    ],
  ),

  // 88 — Radium (MARQUEE)
  BioEntity(
    id: 'element_ra',
    scale: BioScale.atoms,
    position: 87,
    name: 'Radium',
    title: 'Marie Curie\'s Glowing Prize',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The element that glowed in the dark, won two Nobel Prizes for the Curies, and quietly poisoned a generation of watch-dial painters.',
    longDescription:
        'Radium is an alkaline-earth metal that Marie and Pierre Curie painstakingly isolated in 1898 from tons of uranium ore. It is intensely radioactive — a gram of it glows faintly blue and stays warmer than its surroundings from its own decay. That eerie glow made it a sensation: radium was added to paints, toothpaste, and health tonics in the early 1900s before anyone understood the danger.\n\nThe "Radium Girls" — factory workers who licked radium-paint brushes to a fine point — suffered horrific radiation injuries, and their lawsuits helped create modern workplace-safety law. Marie Curie herself died of radiation-linked illness, her notebooks still too radioactive to handle safely today.',
    relatedIds: ['element_fr', 'element_u', 'element_ac'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Ra'],
          ['Atomic number', '88'],
          ['Group', '2'],
          ['Period', '7'],
          ['Category', 'Alkaline earth metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Glows in the dark from its own radioactivity'],
        ],
      ),
      LessonSection.fact(
        title: 'A Nobel element',
        body:
            'Isolating radium helped Marie Curie become the first person ever to win Nobel Prizes in two different sciences (Physics 1903, Chemistry 1911).',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'Radium paint made watch dials glow. Why did painting those dials turn out to be deadly?',
        answer:
            'The painters shaped their brushes with their lips, swallowing tiny amounts of radium. The body mistakes radium for calcium and stores it in bone, where its radiation destroyed jaws and marrow — the "Radium Girls" tragedy.',
      ),
    ],
  ),

  // 89 — Actinium
  BioEntity(
    id: 'element_ac',
    scale: BioScale.atoms,
    position: 88,
    name: 'Actinium',
    title: 'Namesake of the Actinides',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'So radioactive it glows pale blue in the dark, and it lends its name to the entire bottom row of the periodic table.',
    longDescription:
        'Actinium is the first of the actinides, the fourteen-plus-one heavy elements that fill the bottom strip of the periodic table. It is about 150 times more radioactive than radium, glowing faintly in the dark from the sheer energy of its decay. In pure form it is a soft, silvery metal, but it is so rare that most chemistry is done with mere traces.\n\nToday actinium-225 is being studied for "targeted alpha therapy," a cancer treatment that delivers a tiny radioactive payload directly to tumor cells.',
    relatedIds: ['element_ra', 'element_th'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Ac'],
          ['Atomic number', '89'],
          ['Group', 'n/a (actinide)'],
          ['Period', '7'],
          ['Category', 'Actinide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Gives the actinide series its name'],
        ],
      ),
      LessonSection.fact(
        title: 'Glows in the dark',
        body:
            'Actinium is so intensely radioactive that it emits a soft blue glow from ionizing the air around it.',
      ),
    ],
  ),

  // 90 — Thorium
  BioEntity(
    id: 'element_th',
    scale: BioScale.atoms,
    position: 89,
    name: 'Thorium',
    title: 'The Thunder-God Fuel',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Named for Thor, more abundant than uranium, and a long-promised alternative fuel for nuclear reactors.',
    longDescription:
        'Thorium is a weakly radioactive actinide with a half-life so long — 14 billion years — that Earth still holds most of the thorium it was born with. It is three to four times more common in the crust than uranium and was once used in gas-lamp mantles, which it made burn with a brilliant white light.\n\nIts big appeal is energy: thorium can be bred into fissile uranium-233 inside a reactor, and thorium fuel cycles promise abundant fuel with less long-lived waste. Molten-salt thorium reactors remain an active area of research.',
    relatedIds: ['element_ac', 'element_u', 'element_pa'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Th'],
          ['Atomic number', '90'],
          ['Group', 'n/a (actinide)'],
          ['Period', '7'],
          ['Category', 'Actinide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Candidate fuel for next-generation reactors'],
        ],
      ),
      LessonSection.fact(
        title: 'Older than the mountains',
        body:
            'Thorium-232 has a half-life of about 14 billion years — roughly the age of the universe.',
      ),
    ],
  ),

  // 91 — Protactinium
  BioEntity(
    id: 'element_pa',
    scale: BioScale.atoms,
    position: 90,
    name: 'Protactinium',
    title: 'The Rare Bridge Metal',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'One of the rarest and most expensive natural elements — its name means "parent of actinium."',
    longDescription:
        'Protactinium sits between thorium and uranium and is fantastically rare: it occurs only as a trace decay product in uranium ores. Isolating even small amounts is famously difficult, and it is both radioactive and chemically toxic. Its name comes from the fact that it decays into actinium — the "proto-actinium," or parent of actinium.\n\nOne practical use survives: protactinium-231 ratios in ocean sediments let scientists date deep-sea deposits and reconstruct past climate.',
    relatedIds: ['element_th', 'element_u'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Pa'],
          ['Atomic number', '91'],
          ['Group', 'n/a (actinide)'],
          ['Period', '7'],
          ['Category', 'Actinide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Among the rarest naturally occurring elements'],
        ],
      ),
      LessonSection.fact(
        title: 'Parent of actinium',
        body:
            'The name protactinium literally means "before actinium," because it decays into that element.',
      ),
    ],
  ),

  // 92 — Uranium (MARQUEE)
  BioEntity(
    id: 'element_u',
    scale: BioScale.atoms,
    position: 91,
    name: 'Uranium',
    title: 'The Atom That Splits',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The heaviest element found in useful quantities in nature — and the one whose splitting nucleus powers reactors and atomic bombs.',
    longDescription:
        'Uranium is a dense, silvery actinide named after the planet Uranus. It is only weakly radioactive on its own, but one isotope — uranium-235 — can undergo fission: struck by a neutron, its nucleus splits, releasing enormous energy and more neutrons that split more nuclei in a chain reaction. Controlled, that reaction powers nuclear plants; uncontrolled, it is the physics of the atomic bomb.\n\nUranium was the fuel of the first reactors and the 1945 Hiroshima bomb. Because natural uranium is mostly the non-fissile U-238, it must be "enriched" to concentrate U-235 — a difficult, tightly monitored process at the heart of nuclear policy.',
    relatedIds: ['element_th', 'element_np', 'element_pu'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'U'],
          ['Atomic number', '92'],
          ['Group', 'n/a (actinide)'],
          ['Period', '7'],
          ['Category', 'Actinide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Fuel for both nuclear power and atomic bombs'],
        ],
      ),
      LessonSection.fact(
        title: 'The naming pattern',
        body:
            'Uranium was named after Uranus; the next two elements, neptunium and plutonium, were named after Neptune and Pluto to continue the planetary sequence.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'Why does splitting a single uranium-235 nucleus lead to a "chain reaction"?',
        answer:
            'Each fission releases 2–3 free neutrons. Those neutrons strike other U-235 nuclei and split them too, each releasing more neutrons — an exponential cascade. Control it and you have a power plant; let it run free and you have a bomb.',
      ),
    ],
  ),

  // 93 — Neptunium
  BioEntity(
    id: 'element_np',
    scale: BioScale.atoms,
    position: 92,
    name: 'Neptunium',
    title: 'The First Beyond Uranium',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The first synthetic element ever made — the beginning of the "transuranium" elements past uranium.',
    longDescription:
        'Neptunium was created in 1940 at Berkeley by bombarding uranium with neutrons, making it the first element produced beyond uranium. Named after Neptune, the planet just past Uranus, it opened the door to a whole new region of the periodic table. Tiny traces do occur naturally in uranium ores, but essentially all neptunium is man-made.\n\nIt is a byproduct in nuclear reactors and is chiefly of interest to nuclear scientists studying waste and weapons materials.',
    relatedIds: ['element_u', 'element_pu'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Np'],
          ['Atomic number', '93'],
          ['Group', 'n/a (actinide)'],
          ['Period', '7'],
          ['Category', 'Actinide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'The first transuranium (synthetic) element'],
        ],
      ),
      LessonSection.fact(
        title: 'Past the edge',
        body:
            'Neptunium was the first element made heavier than uranium — the start of the transuranium elements.',
      ),
    ],
  ),

  // 94 — Plutonium (MARQUEE)
  BioEntity(
    id: 'element_pu',
    scale: BioScale.atoms,
    position: 93,
    name: 'Plutonium',
    title: 'The Reactor and the Bomb',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A man-made metal that fuels nuclear reactors, powers deep-space probes, and formed the core of the first atomic bomb ever detonated.',
    longDescription:
        'Plutonium is a dense, strange metal produced when uranium-238 absorbs a neutron inside a reactor. Its isotope plutonium-239 is readily fissile, which made it a weapons material: the Trinity test and the Nagasaki bomb both used plutonium cores. It is also a reactor fuel and, in the form of plutonium-238, a heat source — its steady decay powers radioisotope generators on spacecraft like Voyager and the Mars rovers.\n\nPlutonium is chemically peculiar (it has six different metallic forms) and dangerously radiotoxic if inhaled. Almost all of it is made by humans; only vanishing traces exist in nature.',
    relatedIds: ['element_u', 'element_np', 'element_am'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Pu'],
          ['Atomic number', '94'],
          ['Group', 'n/a (actinide)'],
          ['Period', '7'],
          ['Category', 'Actinide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Powers deep-space probes and atomic bombs alike'],
        ],
      ),
      LessonSection.fact(
        title: 'Fuel for the stars\' edge',
        body:
            'Plutonium-238\'s heat keeps the Voyager probes and Mars rovers running billions of kilometers from the Sun, where solar panels would be useless.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'Why is plutonium-238 used to power spacecraft instead of solar panels?',
        answer:
            'Its radioactive decay produces steady heat that a generator turns into electricity — no sunlight required. Far from the Sun, or during long dark periods, that reliable heat source outlasts and outperforms solar panels.',
      ),
    ],
  ),

  // 95 — Americium (MARQUEE)
  BioEntity(
    id: 'element_am',
    scale: BioScale.atoms,
    position: 94,
    name: 'Americium',
    title: 'The Smoke Detector Element',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The one synthetic element that lives in millions of homes — a speck of it sits inside most smoke detectors.',
    longDescription:
        'Americium is a man-made actinide first produced during the Manhattan Project and named after the Americas, echoing europium above it in the periodic table. Its most famous use is astonishingly ordinary: a tiny amount of americium-241 sits in ionization smoke detectors, emitting alpha particles that ionize the air so a small current flows. When smoke disrupts that current, the alarm sounds.\n\nBeyond the smoke detector, americium is used in industrial gauges that measure thickness and density, making it one of the most practically useful synthetic elements.',
    relatedIds: ['element_pu', 'element_cm'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Am'],
          ['Atomic number', '95'],
          ['Group', 'n/a (actinide)'],
          ['Period', '7'],
          ['Category', 'Actinide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Found inside most household smoke detectors'],
        ],
      ),
      LessonSection.fact(
        title: 'A synthetic element in your home',
        body:
            'A typical ionization smoke detector contains about 0.3 micrograms of americium-241 — a lab-made element quietly guarding your ceiling.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'How does a speck of americium actually detect smoke?',
        answer:
            'Its alpha particles ionize the air in the detector, letting a small steady current flow between two plates. Smoke particles absorb the ions and interrupt that current — the drop in current triggers the alarm.',
      ),
    ],
  ),

  // 96 — Curium
  BioEntity(
    id: 'element_cm',
    scale: BioScale.atoms,
    position: 95,
    name: 'Curium',
    title: 'Named for the Curies',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A silvery synthetic metal named to honor Marie and Pierre Curie — so radioactive it glows in the dark.',
    longDescription:
        'Curium is a man-made actinide first produced in 1944 and named after Marie and Pierre Curie, the pioneers of radioactivity. It is intensely radioactive, glowing with a soft purple light from its own energy. That self-heating property has made curium a candidate power source, and its isotopes drive the alpha-particle X-ray spectrometers that analyze rock and soil on Mars rovers.\n\nAll curium is synthetic, made in reactors and accelerators in minute amounts.',
    relatedIds: ['element_am', 'element_bk'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Cm'],
          ['Atomic number', '96'],
          ['Group', 'n/a (actinide)'],
          ['Period', '7'],
          ['Category', 'Actinide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Powers X-ray spectrometers on Mars rovers'],
        ],
      ),
      LessonSection.fact(
        title: 'A tribute in the table',
        body:
            'Curium honors Marie and Pierre Curie, mirroring gadolinium above it, which honors another scientist — a rare double naming pattern.',
      ),
    ],
  ),

  // 97 — Berkelium
  BioEntity(
    id: 'element_bk',
    scale: BioScale.atoms,
    position: 96,
    name: 'Berkelium',
    title: 'Made in Berkeley',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A synthetic element named for Berkeley, California, where a run of new elements was discovered.',
    longDescription:
        'Berkelium was first made in 1949 at the University of California, Berkeley, by bombarding americium with alpha particles. It is named after the city and university where a remarkable string of new elements was created. Only tiny amounts have ever been produced — measured in micrograms — so its chemistry is studied with extraordinary care.\n\nBerkelium-249 later served as the target material used to synthesize element 117, tennessine, one of the heaviest elements known.',
    relatedIds: ['element_cm', 'element_cf'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Bk'],
          ['Atomic number', '97'],
          ['Group', 'n/a (actinide)'],
          ['Period', '7'],
          ['Category', 'Actinide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Target material used to create element 117'],
        ],
      ),
      LessonSection.fact(
        title: 'A hometown element',
        body:
            'Berkelium is named after Berkeley, California — one of four elements (with californium, americium, and more) tied to that region\'s labs.',
      ),
    ],
  ),

  // 98 — Californium
  BioEntity(
    id: 'element_cf',
    scale: BioScale.atoms,
    position: 97,
    name: 'Californium',
    title: 'The Neutron Machine',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A powerful synthetic neutron source used to start reactors, scan for gold, and find landmines.',
    longDescription:
        'Californium, made at Berkeley in 1950 and named for the state, is one of the few synthetic elements with real practical uses. Its isotope californium-252 is a potent neutron emitter: a single microgram spits out billions of neutrons per second. That makes it invaluable for starting up nuclear reactors, scanning aircraft and cargo for explosives, prospecting for gold and silver, and detecting metal fatigue.\n\nIt is also one of the most expensive substances on Earth to produce, since only fractions of a gram are made worldwide each year.',
    relatedIds: ['element_bk', 'element_es'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Cf'],
          ['Atomic number', '98'],
          ['Group', 'n/a (actinide)'],
          ['Period', '7'],
          ['Category', 'Actinide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'A microgram emits billions of neutrons per second'],
        ],
      ),
      LessonSection.fact(
        title: 'A working synthetic element',
        body:
            'Californium-252 is used to jump-start nuclear reactors and to scan cargo and luggage for explosives.',
      ),
    ],
  ),

  // 99 — Einsteinium
  BioEntity(
    id: 'element_es',
    scale: BioScale.atoms,
    position: 98,
    name: 'Einsteinium',
    title: 'Born in an H-Bomb',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Discovered in the fallout of the first hydrogen bomb test and named for Albert Einstein.',
    longDescription:
        'Einsteinium was found in 1952 in the radioactive debris of "Ivy Mike," the first hydrogen bomb test, where the intense neutron flux fused lighter atoms into heavy new ones. It was named after Albert Einstein. It is purely synthetic, extraordinarily radioactive, and produced in such tiny quantities that visible amounts have only rarely been made.\n\nWith no practical use, einsteinium exists almost entirely for basic research into the chemistry of the heaviest elements.',
    relatedIds: ['element_cf', 'element_fm'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Es'],
          ['Atomic number', '99'],
          ['Group', 'n/a (actinide)'],
          ['Period', '7'],
          ['Category', 'Actinide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'First found in hydrogen-bomb fallout'],
        ],
      ),
      LessonSection.fact(
        title: 'A fiery birth',
        body:
            'Einsteinium and fermium were both first detected in the debris of the 1952 Ivy Mike thermonuclear test.',
      ),
    ],
  ),

  // 100 — Fermium
  BioEntity(
    id: 'element_fm',
    scale: BioScale.atoms,
    position: 99,
    name: 'Fermium',
    title: 'The Hundredth Atom',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Element 100 — the last of the heavy elements that can be made by neutron bombardment.',
    longDescription:
        'Fermium, atomic number 100, was discovered alongside einsteinium in the fallout of the first hydrogen bomb and named after physicist Enrico Fermi. It marks a boundary: it is the heaviest element that can be produced in a reactor by piling neutrons onto lighter atoms. Everything past it must be built by smashing whole nuclei together in accelerators.\n\nFermium is intensely radioactive and made only in trace amounts for research.',
    relatedIds: ['element_es', 'element_md'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Fm'],
          ['Atomic number', '100'],
          ['Group', 'n/a (actinide)'],
          ['Period', '7'],
          ['Category', 'Actinide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Heaviest element made by neutron bombardment'],
        ],
      ),
      LessonSection.fact(
        title: 'A round number and a hard limit',
        body:
            'At element 100, fermium marks the point past which new elements can only be forged by colliding heavy nuclei, not by adding neutrons.',
      ),
    ],
  ),

  // 101 — Mendelevium
  BioEntity(
    id: 'element_md',
    scale: BioScale.atoms,
    position: 100,
    name: 'Mendelevium',
    title: 'Made One Atom at a Time',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Named for the father of the periodic table and first identified from just seventeen atoms.',
    longDescription:
        'Mendelevium was created in 1955 by bombarding einsteinium with helium ions — and the original discovery rested on the detection of only about seventeen atoms. It is named after Dmitri Mendeleev, who arranged the first periodic table and predicted undiscovered elements. Its creation pioneered the single-atom techniques now used to study the heaviest elements.\n\nMendelevium is purely synthetic, exists only briefly, and has no use beyond research.',
    relatedIds: ['element_fm', 'element_no'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Md'],
          ['Atomic number', '101'],
          ['Group', 'n/a (actinide)'],
          ['Period', '7'],
          ['Category', 'Actinide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'First identified from about 17 atoms'],
        ],
      ),
      LessonSection.fact(
        title: 'A fitting namesake',
        body:
            'Mendelevium honors Dmitri Mendeleev, whose 1869 periodic table left gaps for elements not yet discovered.',
      ),
    ],
  ),

  // 102 — Nobelium
  BioEntity(
    id: 'element_no',
    scale: BioScale.atoms,
    position: 101,
    name: 'Nobelium',
    title: 'The Contested Element',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Named for Alfred Nobel, its discovery was disputed for years between rival labs.',
    longDescription:
        'Nobelium is a synthetic actinide named after Alfred Nobel, founder of the Nobel Prizes. Its discovery in the late 1950s and early 1960s was a tangle of competing claims from Swedish, American, and Soviet laboratories, and it took years for credit to be sorted out. It exists only as fleeting, intensely radioactive atoms.\n\nInterestingly, nobelium is unusual among the actinides in that its most stable oxidation state is +2 rather than +3, a quirk that fascinates chemists.',
    relatedIds: ['element_md', 'element_lr'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'No'],
          ['Atomic number', '102'],
          ['Group', 'n/a (actinide)'],
          ['Period', '7'],
          ['Category', 'Actinide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Discovery disputed among three nations\' labs'],
        ],
      ),
      LessonSection.fact(
        title: 'An odd one out',
        body:
            'Unlike most actinides, nobelium prefers a +2 oxidation state — a rare exception in its part of the table.',
      ),
    ],
  ),

  // 103 — Lawrencium
  BioEntity(
    id: 'element_lr',
    scale: BioScale.atoms,
    position: 102,
    name: 'Lawrencium',
    title: 'The Last Actinide',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Element 103 closes out the actinide series and honors the inventor of the cyclotron.',
    longDescription:
        'Lawrencium is the final element of the actinide series, capping the bottom row of the periodic table. It is named after Ernest Lawrence, inventor of the cyclotron — the particle accelerator that made the discovery of so many heavy elements possible. It was first synthesized in the early 1960s and, like its neighbors, exists only as a few short-lived atoms.\n\nCompleting the actinides, lawrencium marks the point where the next row hands the periodic table over to the "transactinide" superheavy elements.',
    relatedIds: ['element_no'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Lr'],
          ['Atomic number', '103'],
          ['Group', 'n/a (actinide)'],
          ['Period', '7'],
          ['Category', 'Actinide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'The final element of the actinide series'],
        ],
      ),
      LessonSection.fact(
        title: 'Named for the cyclotron man',
        body:
            'Lawrencium honors Ernest Lawrence, whose cyclotron opened the era of creating brand-new elements.',
      ),
    ],
  ),
];
