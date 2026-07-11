import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Atoms → "The Periodic Table" module (period 5, Z 37–54). Every entity
/// carries moduleId: 'atoms_periodic_table'. (Authored by module agent.)
const List<BioEntity> periodicElements37to54 = <BioEntity>[
  BioEntity(
    id: 'element_rb',
    scale: BioScale.atoms,
    position: 36,
    name: 'Rubidium',
    title: 'The Restless Red Flame',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A soft silvery alkali metal so eager to react it can ignite the instant it meets air.',
    longDescription:
        'Rubidium sits just below potassium and behaves like an even more excitable cousin — it fizzes violently in water and must be stored away from oxygen. Its name comes from the deep-red lines it paints in a spectroscope.\n\nToday its steadiest job is timekeeping: rubidium atomic clocks tick reliably enough to help synchronize phone networks and satellites.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Rb'],
          ['Atomic number', '37'],
          ['Group', '1 (alkali metals)'],
          ['Period', '5'],
          ['Category', 'Alkali metal'],
          ['State at 25°C', 'Solid (melts at just 39°C)'],
          ['Standout fact', 'Powers compact atomic clocks'],
        ],
      ),
      LessonSection.fact(
        title: 'Melts in your pocket',
        body:
            'Rubidium melts at about 39°C — barely above body temperature — so a warm day could turn a chunk of it to liquid.',
      ),
    ],
  ),
  BioEntity(
    id: 'element_sr',
    scale: BioScale.atoms,
    position: 37,
    name: 'Strontium',
    title: 'The Crimson Firework',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The alkaline earth metal that dyes fireworks and emergency flares a brilliant red.',
    longDescription:
        'Strontium is a reactive silvery metal in the same family as calcium, and it slips into bones and teeth almost as easily. When burned, its salts glow a vivid crimson — which is why it lights up flares and pyrotechnics.\n\nA radioactive version, strontium-90, is a hazardous fallout product because the body mistakes it for calcium and stores it in bone.',
    relatedIds: ['element_ca'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Sr'],
          ['Atomic number', '38'],
          ['Group', '2 (alkaline earth metals)'],
          ['Period', '5'],
          ['Category', 'Alkaline earth metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Makes fireworks red'],
        ],
      ),
      LessonSection.fact(
        title: 'The red in the sky',
        body:
            'That deep red in a fireworks show is almost always burning strontium salts.',
      ),
    ],
  ),
  BioEntity(
    id: 'element_y',
    scale: BioScale.atoms,
    position: 38,
    name: 'Yttrium',
    title: 'The Screen-Glow Metal',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A transition metal named after a tiny Swedish village that helped light old color TVs.',
    longDescription:
        'Yttrium is a silvery transition metal usually grouped with the rare earths, even though it is not especially rare. It was one of several elements discovered in ores from Ytterby, Sweden — a village that lent its name to four different elements.\n\nYttrium compounds once produced the red phosphor in color televisions and now strengthen superalloys, lasers, and superconductors.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Y'],
          ['Atomic number', '39'],
          ['Group', '3'],
          ['Period', '5'],
          ['Category', 'Transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Made the red glow in old color TVs'],
        ],
      ),
      LessonSection.fact(
        title: 'One village, four elements',
        body:
            'Ytterby, Sweden gave its name to yttrium, ytterbium, terbium, and erbium — the most elements ever named after one place.',
      ),
    ],
  ),
  BioEntity(
    id: 'element_zr',
    scale: BioScale.atoms,
    position: 39,
    name: 'Zirconium',
    title: 'The Reactor Armor',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A corrosion-proof metal that shields nuclear fuel and fakes diamonds as cubic zirconia.',
    longDescription:
        'Zirconium is a strong, silvery transition metal that shrugs off corrosion and lets neutrons pass through easily — a rare combination that makes it ideal for cladding nuclear fuel rods.\n\nIts oxide forms cubic zirconia, the sparkling diamond simulant, and it also shows up in surgical implants and heat-resistant ceramics.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Zr'],
          ['Atomic number', '40'],
          ['Group', '4'],
          ['Period', '5'],
          ['Category', 'Transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Clads nuclear reactor fuel rods'],
        ],
      ),
      LessonSection.fact(
        title: 'The fake diamond',
        body:
            'Cubic zirconia — the most famous diamond look-alike — is crystallized zirconium dioxide.',
      ),
    ],
  ),
  BioEntity(
    id: 'element_nb',
    scale: BioScale.atoms,
    position: 40,
    name: 'Niobium',
    title: 'The Superconductor Wire',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A ductile metal whose alloys stay superconducting inside MRI machines and particle colliders.',
    longDescription:
        'Niobium is a soft, grey transition metal that pairs with titanium and tin to form alloys that carry electricity without resistance when chilled. Those wires wind the powerful magnets inside MRI scanners and accelerators like the LHC.\n\nOnce called columbium in the United States, niobium also toughens steel used in pipelines and car frames.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Nb'],
          ['Atomic number', '41'],
          ['Group', '5'],
          ['Period', '5'],
          ['Category', 'Transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Superconducting magnet wire'],
        ],
      ),
      LessonSection.fact(
        title: 'Two names, one metal',
        body:
            'Niobium was long called "columbium" in America; the name niobium was only made official in 1949.',
      ),
    ],
  ),
  BioEntity(
    id: 'element_mo',
    scale: BioScale.atoms,
    position: 41,
    name: 'Molybdenum',
    title: 'The Heat-Proof Toughener',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A high-melting metal that hardens steel and quietly runs enzymes inside living cells.',
    longDescription:
        'Molybdenum boasts one of the highest melting points of all elements, so it strengthens steel that must survive engines, drills, and furnaces without softening.\n\nIt is also a genuine nutrient: enzymes in plants, animals, and microbes use molybdenum atoms to process nitrogen and sulfur.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Mo'],
          ['Atomic number', '42'],
          ['Group', '6'],
          ['Period', '5'],
          ['Category', 'Transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'A trace nutrient for life'],
        ],
      ),
      LessonSection.fact(
        title: 'Melts near 2,600°C',
        body:
            'Molybdenum stays solid until about 2,623°C, which is why it reinforces steels built for extreme heat.',
      ),
    ],
  ),
  BioEntity(
    id: 'element_tc',
    scale: BioScale.atoms,
    position: 42,
    name: 'Technetium',
    title: 'The First Made Element',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The lightest element with no stable form — every atom of it is radioactive.',
    longDescription:
        'Technetium filled a stubborn gap in the periodic table: for decades no one found it in nature because all of its isotopes are radioactive and decay away. In 1937 it became the first element created artificially in a lab, earning a name from the Greek for "artificial."\n\nA short-lived form, technetium-99m, is now the workhorse tracer for millions of medical imaging scans each year.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Tc'],
          ['Atomic number', '43'],
          ['Group', '7'],
          ['Period', '5'],
          ['Category', 'Transition metal (radioactive)'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'First element made by humans'],
        ],
      ),
      LessonSection.fact(
        title: 'Seen inside the body',
        body:
            'Technetium-99m emits gamma rays that cameras catch, making it the most common tracer in nuclear medicine scans.',
      ),
    ],
  ),
  BioEntity(
    id: 'element_ru',
    scale: BioScale.atoms,
    position: 43,
    name: 'Ruthenium',
    title: 'The Hard-Drive Whisper',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A rare platinum-group metal that hardens alloys and packs data tighter on hard drives.',
    longDescription:
        'Ruthenium is a brittle, silvery member of the platinum family. A whisper-thin layer of it in hard-drive coatings let engineers squeeze far more data onto each disk — a trick nicknamed "pixie dust."\n\nIt also hardens platinum jewelry, tips fountain pens, and drives catalysts used in industrial chemistry.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Ru'],
          ['Atomic number', '44'],
          ['Group', '8'],
          ['Period', '5'],
          ['Category', 'Transition metal (platinum group)'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Boosts hard-drive storage density'],
        ],
      ),
      LessonSection.fact(
        title: 'Pixie dust',
        body:
            'Engineers dubbed a three-atom-thick ruthenium layer "pixie dust" for how much it raised hard-drive capacity.',
      ),
    ],
  ),
  BioEntity(
    id: 'element_rh',
    scale: BioScale.atoms,
    position: 44,
    name: 'Rhodium',
    title: 'The Priceless Catalyst',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A dazzling silver-white metal — often the most expensive of all — that scrubs car exhaust clean.',
    longDescription:
        'Rhodium reflects light with a brilliant, tarnish-free shine, so it plates jewelry and mirrors. But its real value lies in catalytic converters, where it converts toxic exhaust gases into safer ones.\n\nBecause it is scarce and irreplaceable in that role, rhodium prices have at times soared far above gold.',
    relatedIds: ['element_pd'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Rh'],
          ['Atomic number', '45'],
          ['Group', '9'],
          ['Period', '5'],
          ['Category', 'Transition metal (platinum group)'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Cleans car exhaust in catalytic converters'],
        ],
      ),
      LessonSection.fact(
        title: 'Costlier than gold',
        body:
            'Rhodium has repeatedly traded at several times the price of gold, making it one of the most valuable metals on Earth.',
      ),
    ],
  ),
  BioEntity(
    id: 'element_pd',
    scale: BioScale.atoms,
    position: 45,
    name: 'Palladium',
    title: 'The Hydrogen Sponge',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A platinum-group metal that soaks up hydrogen like a sponge and cleans engine exhaust.',
    longDescription:
        'Palladium can absorb hundreds of times its own volume in hydrogen gas, a strange talent used in gas purification and storage research. Like rhodium, it is a star of catalytic converters.\n\nIts scarcity and demand make it, along with platinum and rhodium, one of the most traded precious metals in the world.',
    relatedIds: ['element_rh'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Pd'],
          ['Atomic number', '46'],
          ['Group', '10'],
          ['Period', '5'],
          ['Category', 'Transition metal (platinum group)'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Absorbs huge volumes of hydrogen'],
        ],
      ),
      LessonSection.fact(
        title: 'A metal sponge for gas',
        body:
            'Palladium can soak up roughly 900 times its own volume of hydrogen, then release it again when heated.',
      ),
    ],
  ),
  BioEntity(
    id: 'element_ag',
    scale: BioScale.atoms,
    position: 46,
    name: 'Silver',
    title: 'The Bright Conductor',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The best electrical conductor of any element, and a germ-killer humans have prized for millennia.',
    longDescription:
        'Silver conducts electricity and heat better than any other element and reflects light beautifully, which is why it lines mirrors, coins, and fine electronics. Ancient peoples stored water in silver vessels long before anyone understood why it stayed fresh.\n\nWe now know silver ions are toxic to microbes, so silver coats bandages, water filters, and touch surfaces to fight bacteria.',
    relatedIds: ['element_au', 'element_cu'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Ag'],
          ['Atomic number', '47'],
          ['Group', '11'],
          ['Period', '5'],
          ['Category', 'Transition metal (coinage metal)'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Best electrical conductor of all elements'],
        ],
      ),
      LessonSection.fact(
        title: 'The symbol puzzle',
        body:
            'Silver\'s symbol Ag comes from its Latin name argentum — the same root that named the country Argentina.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'Silver conducts electricity better than copper, yet most wiring is copper. Why don\'t we wire houses with silver?',
        answer:
            'Copper conducts almost as well but costs a tiny fraction as much. Silver\'s slim advantage isn\'t worth its price for everyday wiring, so it is saved for specialized, high-performance uses.',
      ),
    ],
  ),
  BioEntity(
    id: 'element_cd',
    scale: BioScale.atoms,
    position: 47,
    name: 'Cadmium',
    title: 'The Toxic Yellow',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A soft, poisonous metal that once brightened paints and still powers rechargeable batteries.',
    longDescription:
        'Cadmium is a soft, bluish-white metal whose compounds make vivid yellow, orange, and red pigments once loved by artists. It is also toxic and accumulates in the body, so its use is now tightly restricted.\n\nIts most familiar job is inside nickel-cadmium (NiCd) rechargeable batteries, though safer chemistries are steadily replacing them.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Cd'],
          ['Atomic number', '48'],
          ['Group', '12'],
          ['Period', '5'],
          ['Category', 'Transition metal (post-transition-like)'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Powers NiCd rechargeable batteries'],
        ],
      ),
      LessonSection.fact(
        title: 'Beautiful but poisonous',
        body:
            'Cadmium yellow gave painters a brilliant color for over a century, but the metal is toxic and now heavily regulated.',
      ),
    ],
  ),
  BioEntity(
    id: 'element_in',
    scale: BioScale.atoms,
    position: 48,
    name: 'Indium',
    title: 'The Touchscreen Metal',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A soft metal so useful in transparent screen coatings that it makes touchscreens possible.',
    longDescription:
        'Indium is a soft, silvery post-transition metal that is soft enough to leave a mark on paper and lets out a faint cry, or "tin scream," when bent. Blended into indium tin oxide, it forms a coating that is both electrically conductive and see-through.\n\nThat coating covers phone and tablet screens, letting them sense your touch while staying transparent.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'In'],
          ['Atomic number', '49'],
          ['Group', '13'],
          ['Period', '5'],
          ['Category', 'Post-transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Makes transparent touchscreen coatings'],
        ],
      ),
      LessonSection.fact(
        title: 'The invisible layer',
        body:
            'Indium tin oxide is transparent yet conducts electricity — the trick behind nearly every touchscreen.',
      ),
    ],
  ),
  BioEntity(
    id: 'element_sn',
    scale: BioScale.atoms,
    position: 49,
    name: 'Tin',
    title: 'The Bronze Age Partner',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The metal that alloyed with copper to make bronze and launched an entire age of tools.',
    longDescription:
        'Tin is a soft, silvery post-transition metal that resists corrosion, which is why "tin cans" are steel coated in a thin protective layer of it. Mixed with copper, tin makes bronze — the alloy so important that a whole era of human history is named after it.\n\nTin also joins solder, the metal glue that holds electronic circuits together.',
    relatedIds: ['element_cu', 'element_pb'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Sn'],
          ['Atomic number', '50'],
          ['Group', '14'],
          ['Period', '5'],
          ['Category', 'Post-transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Half of bronze; coats "tin" cans'],
        ],
      ),
      LessonSection.fact(
        title: 'The tin cry',
        body:
            'Bend a bar of pure tin and it crackles — a sound called the "tin cry," caused by its crystals rearranging.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'Bronze is much harder and more useful than pure copper. What did adding tin actually change?',
        answer:
            'Tin atoms are a different size than copper atoms, so they disrupt the neat rows in the metal. That makes it harder for the layers to slide past each other, so the alloy is stronger and holds an edge far better than soft copper alone.',
      ),
    ],
  ),
  BioEntity(
    id: 'element_sb',
    scale: BioScale.atoms,
    position: 50,
    name: 'Antimony',
    title: 'The Ancient Eyeliner',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A brittle metalloid used as kohl eye makeup in antiquity and as a flame retardant today.',
    longDescription:
        'Antimony is a silvery-grey metalloid — sharing traits of metals and non-metals. Ground into a black powder called kohl, its compounds lined the eyes of ancient Egyptians thousands of years ago.\n\nModern antimony hardens lead alloys in batteries and, as a compound, slows the spread of flames in plastics and fabrics.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Sb'],
          ['Atomic number', '51'],
          ['Group', '15'],
          ['Period', '5'],
          ['Category', 'Metalloid'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Used as flame retardant and ancient eye makeup'],
        ],
      ),
      LessonSection.fact(
        title: 'A symbol from Latin',
        body:
            'Antimony\'s symbol Sb comes from stibium, the Latin name for the eye-paint mineral it was made from.',
      ),
    ],
  ),
  BioEntity(
    id: 'element_te',
    scale: BioScale.atoms,
    position: 51,
    name: 'Tellurium',
    title: 'The Garlic-Breath Rarity',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A rare metalloid so unusual that a trace of it gives a person garlicky breath for weeks.',
    longDescription:
        'Tellurium is a brittle, silvery metalloid rarer than platinum in Earth\'s crust. Absorb even a tiny amount and your body converts it into compounds that leak out as a powerful garlic odor on the breath.\n\nDespite its scarcity, tellurium is prized in solar-panel films and in alloys that make steel and copper easier to machine.',
    relatedIds: ['element_se'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Te'],
          ['Atomic number', '52'],
          ['Group', '16'],
          ['Period', '5'],
          ['Category', 'Metalloid'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Trace exposure causes garlic breath'],
        ],
      ),
      LessonSection.fact(
        title: 'Named for Earth',
        body:
            'Tellurium takes its name from tellus, the Latin word for Earth.',
      ),
    ],
  ),
  BioEntity(
    id: 'element_i',
    scale: BioScale.atoms,
    position: 52,
    name: 'Iodine',
    title: 'The Thyroid Guardian',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A purple-vapor halogen your thyroid gland cannot make hormones without.',
    longDescription:
        'Iodine is a shiny, dark-grey halogen that skips liquid and turns straight to a violet vapor when warmed. Your thyroid gland needs it to build the hormones that control metabolism, so table salt is often "iodized" to prevent deficiency.\n\nDissolved in alcohol, iodine is also a classic wound antiseptic, and its radioactive form treats thyroid disease.',
    relatedIds: ['element_cl', 'element_br'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'I'],
          ['Atomic number', '53'],
          ['Group', '17 (halogens)'],
          ['Period', '5'],
          ['Category', 'Halogen (nonmetal)'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Essential for thyroid hormones'],
        ],
      ),
      LessonSection.fact(
        title: 'Solid to purple gas',
        body:
            'Warmed gently, iodine sublimes — it skips liquid entirely and becomes a striking violet vapor.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'Why do many countries add iodine to ordinary table salt?',
        answer:
            'Without enough dietary iodine, the thyroid can\'t make its hormones and swells into a goiter, and children can suffer stunted growth. Salt is eaten by nearly everyone in small daily amounts, so it\'s the perfect carrier to deliver iodine to a whole population.',
      ),
    ],
  ),
  BioEntity(
    id: 'element_xe',
    scale: BioScale.atoms,
    position: 53,
    name: 'Xenon',
    title: 'The Ion-Drive Gas',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A rare noble gas that powers spacecraft ion engines and blazes in bright headlights.',
    longDescription:
        'Xenon is a heavy, colorless noble gas so unreactive it was long thought incapable of forming compounds — until chemists proved otherwise. Passed through an electric current, it glows and drives bright xenon lamps and camera flashes.\n\nStripped into ions and hurled backward, xenon quietly propels ion-drive spacecraft across the solar system, and doctors even use it as a rare anesthetic.',
    relatedIds: ['element_kr', 'element_ne'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Xe'],
          ['Atomic number', '54'],
          ['Group', '18 (noble gases)'],
          ['Period', '5'],
          ['Category', 'Noble gas'],
          ['State at 25°C', 'Gas'],
          ['Standout fact', 'Propels spacecraft ion engines'],
        ],
      ),
      LessonSection.fact(
        title: 'A "lazy" gas that reacts',
        body:
            'Named from the Greek for "stranger," xenon was believed inert until 1962, when the first xenon compound overturned the idea that noble gases never react.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'An ion engine barely nudges a spacecraft — far gentler than a chemical rocket. So how does it move ships across the solar system?',
        answer:
            'It fires continuously for months or years. Because space has almost no friction, even a tiny, steady push keeps adding up, so the craft accelerates to enormous speeds over time while sipping very little xenon fuel.',
      ),
    ],
  ),
];
