import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Atoms → "The Periodic Table" module, elements 55–71.
/// Caesium and Barium (Period 6 s-block), Lanthanum, and the lanthanide
/// series Cerium–Lutetium (Period 6 f-block). One BioEntity per element,
/// ascending atomic number. Every entity carries moduleId
/// 'atoms_periodic_table'.
const List<BioEntity> periodicElements55to71 = [
  // Z=55 — Cs — MARQUEE
  BioEntity(
    id: 'element_cs',
    scale: BioScale.atoms,
    position: 54,
    name: 'Caesium',
    title: 'The Golden Timekeeper',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A soft golden metal so eager to react it defines the second itself.',
    longDescription:
        'Caesium is one of only a few golden-tinted metals and melts at a '
        'temperature you could reach on a hot day (28°C). It is the most '
        'reactive metal you can hold, igniting on contact with air and '
        'exploding in water.\n\n'
        'Its outermost electron is so loosely held that a precise microwave '
        'frequency flips it predictably — and that flip is how we define the '
        'second. Every atomic clock on Earth listens to caesium.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Cs'],
          ['Atomic number', '55'],
          ['Group', '1'],
          ['Period', '6'],
          ['Category', 'Alkali metal'],
          ['State at 25°C', 'Solid (barely — melts at 28°C)'],
          ['Standout fact', 'Defines the SI second via atomic clocks'],
        ],
      ),
      LessonSection.fact(
        title: 'The second, defined',
        body:
            'One second = 9,192,631,770 oscillations of the microwave a '
            'caesium-133 atom absorbs. Time itself is measured in caesium.',
      ),
      LessonSection.thinkReveal(
        title: 'Reactive AND useful?',
        question:
            'How can the most reactive metal be trusted to keep the world\'s '
            'most stable clocks?',
        answer:
            'The clock never touches bulk caesium chemically. A beam of '
            'isolated caesium atoms is tickled by microwaves in a vacuum; the '
            'exact frequency they respond to is fixed by physics, not '
            'chemistry — so reactivity is irrelevant and the ticking is '
            'flawless.',
      ),
    ],
  ),

  // Z=56 — Ba — MARQUEE
  BioEntity(
    id: 'element_ba',
    scale: BioScale.atoms,
    position: 55,
    name: 'Barium',
    title: 'The X-Ray Milkshake',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A toxic metal whose safe salt lets doctors photograph your gut.',
    longDescription:
        'Barium is a soft, silvery alkaline-earth metal that is poisonous in '
        'soluble form. Yet insoluble barium sulfate is so safe you can '
        'swallow it: patients drink a "barium meal" so radiologists can see '
        'the digestive tract lit up on an X-ray.\n\n'
        'Barium also gives fireworks their vivid green flames and once coated '
        'the phosphor screens of old televisions.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Ba'],
          ['Atomic number', '56'],
          ['Group', '2'],
          ['Period', '6'],
          ['Category', 'Alkaline earth metal'],
          ['State at 25°C', 'Solid'],
          [
            'Standout fact',
            'Barium sulfate makes soft tissue visible on X-rays'
          ],
        ],
      ),
      LessonSection.fact(
        title: 'Green in the sky',
        body:
            'Barium salts burn bright green — the go-to element for green '
            'fireworks and emergency signal flares.',
      ),
      LessonSection.thinkReveal(
        title: 'Drink poison safely?',
        question:
            'Barium is toxic, so why is it safe to swallow a barium meal '
            'before an X-ray?',
        answer:
            'The meal is barium sulfate, which is essentially insoluble. It '
            'never dissolves into absorbable barium ions, so it passes '
            'straight through the gut — while its heavy nucleus still blocks '
            'X-rays and outlines the digestive tract.',
      ),
    ],
  ),

  // Z=57 — La (lanthanide series, Period 6)
  BioEntity(
    id: 'element_la',
    scale: BioScale.atoms,
    position: 56,
    name: 'Lanthanum',
    title: 'The Namesake',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The element that named a whole family — and helps you see through '
        'camera lenses.',
    longDescription:
        'Lanthanum lends its name to the lanthanides, the 15-element f-block '
        'row tucked beneath the main table. Its name comes from the Greek '
        '"to lie hidden," because it hid inside other minerals for decades.\n\n'
        'Today lanthanum oxide gives high-end camera and telescope lenses '
        'their high refractive index and low dispersion, and it once powered '
        'the nickel–metal-hydride batteries in hybrid cars.',
    relatedIds: ['element_ce'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'La'],
          ['Atomic number', '57'],
          ['Group', 'n/a (lanthanide)'],
          ['Period', '6'],
          ['Category', 'Lanthanide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Gives premium camera lenses their clarity'],
        ],
      ),
      LessonSection.fact(
        title: 'A family surname',
        body:
            'The 15 elements from lanthanum to lutetium are all "lanthanides" '
            '— the rare-earth row named after this single element.',
      ),
    ],
  ),

  // Z=58 — Ce
  BioEntity(
    id: 'element_ce',
    scale: BioScale.atoms,
    position: 57,
    name: 'Cerium',
    title: 'The Self-Cleaning Spark',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The most abundant rare earth — it polishes glass and cleans your '
        'oven.',
    longDescription:
        'Despite the "rare earth" label, cerium is more common in the crust '
        'than copper. It flips easily between two charge states, which makes '
        'it a chemical workhorse.\n\n'
        'Cerium oxide is the finest glass polish known, coats self-cleaning '
        'ovens, and scrubs pollutants in catalytic converters. Mixed into '
        '"mischmetal," cerium is the spark you strike from a lighter flint.',
    relatedIds: ['element_la'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Ce'],
          ['Atomic number', '58'],
          ['Group', 'n/a (lanthanide)'],
          ['Period', '6'],
          ['Category', 'Lanthanide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Most abundant rare-earth element'],
        ],
      ),
      LessonSection.fact(
        title: 'Rarer than rare',
        body:
            'Cerium is roughly as abundant as copper — proof that "rare '
            'earth" describes how hard they are to separate, not how scarce '
            'they are.',
      ),
    ],
  ),

  // Z=59 — Pr
  BioEntity(
    id: 'element_pr',
    scale: BioScale.atoms,
    position: 58,
    name: 'Praseodymium',
    title: 'The Welder\'s Goggles',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A green-tinged metal that shields welders\' eyes from blinding glare.',
    longDescription:
        'Praseodymium — "green twin" in Greek — was split from a mixture once '
        'thought to be a single element. Its salts glow a distinctive green.\n\n'
        'Alloyed into "didymium" glass, it filters the fierce yellow flare of '
        'welding and glassblowing, protecting the eyes. It also strengthens '
        'the powerful magnets used in aircraft engines.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Pr'],
          ['Atomic number', '59'],
          ['Group', 'n/a (lanthanide)'],
          ['Period', '6'],
          ['Category', 'Lanthanide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Filters glare in welding & glassblowing goggles'],
        ],
      ),
      LessonSection.fact(
        title: 'A twin discovery',
        body:
            'Praseodymium and neodymium were separated in 1885 from a single '
            'substance called "didymium" — meaning twin.',
      ),
    ],
  ),

  // Z=60 — Nd — MARQUEE
  BioEntity(
    id: 'element_nd',
    scale: BioScale.atoms,
    position: 59,
    name: 'Neodymium',
    title: 'The World\'s Strongest Magnet',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The tiny metal behind the most powerful magnets ever made — and your '
        'earbuds.',
    longDescription:
        'Neodymium forms the strongest permanent magnets known. A '
        'neodymium–iron–boron magnet the size of a coin can lift hundreds of '
        'times its own weight and snap fingers if handled carelessly.\n\n'
        'These magnets shrink the motors in electric cars, the generators in '
        'wind turbines, and the speakers in your headphones. Neodymium also '
        'colours "solar" glass purple and powers precise infrared lasers.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Nd'],
          ['Atomic number', '60'],
          ['Group', 'n/a (lanthanide)'],
          ['Period', '6'],
          ['Category', 'Lanthanide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Strongest permanent magnets ever made'],
        ],
      ),
      LessonSection.fact(
        title: 'Motors everywhere',
        body:
            'One electric car can contain over a kilogram of neodymium in its '
            'magnets — the reason this rare earth is called critical.',
      ),
      LessonSection.thinkReveal(
        title: 'Why so strong?',
        question:
            'What makes a neodymium magnet vastly stronger than a fridge '
            'magnet?',
        answer:
            'Neodymium\'s f-electrons carry huge unpaired magnetic moments. '
            'Locked into a rigid Nd₂Fe₁₄B crystal, their spins all point the '
            'same way and refuse to be flipped — so the field stays intense '
            'and permanent, far beyond ordinary iron magnets.',
      ),
    ],
  ),

  // Z=61 — Pm
  BioEntity(
    id: 'element_pm',
    scale: BioScale.atoms,
    position: 60,
    name: 'Promethium',
    title: 'The Radioactive Ghost',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The only rare earth with no stable form — it glows and then vanishes.',
    longDescription:
        'Promethium is radioactive with no stable isotope, so almost none '
        'exists naturally. Named after Prometheus, who stole fire, it is made '
        'in nuclear reactors.\n\n'
        'Its steady glow once powered luminous watch dials and still drives '
        'tiny nuclear batteries and thickness gauges. Blink and it decays: '
        'its longest-lived form is gone in a couple of decades.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Pm'],
          ['Atomic number', '61'],
          ['Group', 'n/a (lanthanide)'],
          ['Period', '6'],
          ['Category', 'Lanthanide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Only rare earth with no stable isotope'],
        ],
      ),
      LessonSection.fact(
        title: 'Vanishingly rare',
        body:
            'Earth\'s entire crust holds only a few hundred grams of '
            'promethium at any moment — it decays as fast as nature makes it.',
      ),
    ],
  ),

  // Z=62 — Sm
  BioEntity(
    id: 'element_sm',
    scale: BioScale.atoms,
    position: 61,
    name: 'Samarium',
    title: 'The Heat-Proof Magnet',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Its magnets keep working when others fail in the heat of a jet '
        'engine.',
    longDescription:
        'Samarium–cobalt magnets are slightly weaker than neodymium ones but '
        'keep their strength at scorching temperatures and resist corrosion. '
        'That makes them the choice for jet engines, missiles, and precision '
        'motors.\n\n'
        'Samarium was the first element named after a person — the mine '
        'official Samarsky — and one of its isotopes is used to date ancient '
        'rocks.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Sm'],
          ['Atomic number', '62'],
          ['Group', 'n/a (lanthanide)'],
          ['Period', '6'],
          ['Category', 'Lanthanide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Magnets that survive extreme heat'],
        ],
      ),
      LessonSection.fact(
        title: 'Named for a person',
        body:
            'Samarium is the first element ever named after a living person — '
            'the Russian mine official Vasili Samarsky-Bykhovets.',
      ),
    ],
  ),

  // Z=63 — Eu — MARQUEE
  BioEntity(
    id: 'element_eu',
    scale: BioScale.atoms,
    position: 62,
    name: 'Europium',
    title: 'The Anti-Counterfeit Glow',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The red in your old TV screen — and the secret ink that stops '
        'forgers.',
    longDescription:
        'Europium is the most reactive lanthanide and one of the rarest. Its '
        'true talent is fluorescence: europium compounds glow brilliant red '
        'and blue under UV light.\n\n'
        'For decades europium made the red phosphor in colour TVs and '
        'fluorescent lamps. Today it hides in euro banknotes as an anti-'
        'counterfeiting mark that lights up under UV — real money glows, '
        'forgeries stay dark.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Eu'],
          ['Atomic number', '63'],
          ['Group', 'n/a (lanthanide)'],
          ['Period', '6'],
          ['Category', 'Lanthanide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Anti-counterfeit glow in euro banknotes'],
        ],
      ),
      LessonSection.fact(
        title: 'The red pixel',
        body:
            'Europium phosphors gave older colour televisions their vivid red '
            '— without it, screens looked washed out.',
      ),
      LessonSection.thinkReveal(
        title: 'How do banknotes catch forgers?',
        question:
            'Why does a genuine euro note glow under UV while a photocopy '
            'doesn\'t?',
        answer:
            'Real notes are printed with europium compounds that absorb '
            'invisible UV light and re-emit it as bright visible colour. '
            'Ordinary printer ink and paper have no such phosphor, so a copied '
            'note stays dull under the same lamp — an instant, hard-to-fake '
            'tell.',
      ),
    ],
  ),

  // Z=64 — Gd
  BioEntity(
    id: 'element_gd',
    scale: BioScale.atoms,
    position: 63,
    name: 'Gadolinium',
    title: 'The MRI Brightener',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Injected in tiny doses, it makes tumours light up inside an MRI '
        'scanner.',
    longDescription:
        'Gadolinium has seven unpaired electrons — a magnetic sweet spot — so '
        'a safely bound gadolinium contrast agent sharpens MRI images, making '
        'tumours and blood vessels glow bright.\n\n'
        'It is also the champion neutron absorber, used to shut down nuclear '
        'reactors, and it becomes magnetic right around room temperature, a '
        'quirk explored for magnetic refrigeration.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Gd'],
          ['Atomic number', '64'],
          ['Group', 'n/a (lanthanide)'],
          ['Period', '6'],
          ['Category', 'Lanthanide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Contrast agent that brightens MRI scans'],
        ],
      ),
      LessonSection.fact(
        title: 'Neutron sponge',
        body:
            'Gadolinium absorbs neutrons better than any other element — a '
            'few atoms can help throttle a nuclear reactor.',
      ),
    ],
  ),

  // Z=65 — Tb
  BioEntity(
    id: 'element_tb',
    scale: BioScale.atoms,
    position: 64,
    name: 'Terbium',
    title: 'The Green Phosphor',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The green glow in energy-saving bulbs and a metal that changes shape '
        'in a magnetic field.',
    longDescription:
        'Terbium is a soft, silvery lanthanide whose compounds shine a pure '
        'green — the green phosphor in fluorescent lamps and older display '
        'screens.\n\n'
        'Alloyed as "Terfenol-D," terbium physically stretches and shrinks in '
        'a magnetic field, a property called magnetostriction used in sonar '
        'and precision actuators.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Tb'],
          ['Atomic number', '65'],
          ['Group', 'n/a (lanthanide)'],
          ['Period', '6'],
          ['Category', 'Lanthanide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Green phosphor in energy-saving lamps'],
        ],
      ),
      LessonSection.fact(
        title: 'A metal that flexes',
        body:
            'In a magnetic field, terbium alloys change length by enough to '
            'drive sonar transducers — the metal itself becomes the '
            'loudspeaker.',
      ),
    ],
  ),

  // Z=66 — Dy
  BioEntity(
    id: 'element_dy',
    scale: BioScale.atoms,
    position: 65,
    name: 'Dysprosium',
    title: 'The Magnet\'s Bodyguard',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A pinch of it lets high-tech magnets survive the heat of an EV motor.',
    longDescription:
        'Dysprosium\'s name means "hard to get" in Greek, and it lives up to '
        'it. Added to neodymium magnets, it lets them keep their strength at '
        'high temperature — essential inside electric-car motors and wind '
        'turbines.\n\n'
        'It also has extreme resistance to demagnetisation and is used in '
        'reactor control rods and in some cold-temperature scientific '
        'instruments.',
    relatedIds: ['element_nd'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Dy'],
          ['Atomic number', '66'],
          ['Group', 'n/a (lanthanide)'],
          ['Period', '6'],
          ['Category', 'Lanthanide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Keeps EV-motor magnets working when hot'],
        ],
      ),
      LessonSection.fact(
        title: '"Hard to get"',
        body:
            'The name dysprosium literally means "hard to obtain" — and its '
            'scarcity makes it one of the most strategically watched rare '
            'earths.',
      ),
    ],
  ),

  // Z=67 — Ho
  BioEntity(
    id: 'element_ho',
    scale: BioScale.atoms,
    position: 66,
    name: 'Holmium',
    title: 'The Surgical Laser',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Home to the strongest magnetic pull of any element — and a precise '
        'medical laser.',
    longDescription:
        'Holmium has the highest magnetic moment of any naturally occurring '
        'element, so it is used to make the very strongest laboratory '
        'magnets even stronger by concentrating their fields.\n\n'
        'The holmium laser is a surgeon\'s favourite for shattering kidney '
        'stones and trimming tissue with pinpoint accuracy.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Ho'],
          ['Atomic number', '67'],
          ['Group', 'n/a (lanthanide)'],
          ['Period', '6'],
          ['Category', 'Lanthanide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Highest magnetic moment of any element'],
        ],
      ),
      LessonSection.fact(
        title: 'Stones, meet laser',
        body:
            'Holmium lasers pulse through fibres thinner than a wire to blast '
            'kidney stones apart from inside the body.',
      ),
    ],
  ),

  // Z=68 — Er
  BioEntity(
    id: 'element_er',
    scale: BioScale.atoms,
    position: 67,
    name: 'Erbium',
    title: 'The Internet Amplifier',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The reason your data can cross an ocean of fibre without fading out.',
    longDescription:
        'Erbium is quietly one of the most important elements of the internet '
        'age. Doped into optical fibre, erbium atoms re-amplify light signals '
        'as they weaken, letting data race across oceans without electronic '
        'repeaters.\n\n'
        'Erbium also tints glass and glazes a soft pink, and powers lasers '
        'used in dermatology and dental surgery.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Er'],
          ['Atomic number', '68'],
          ['Group', 'n/a (lanthanide)'],
          ['Period', '6'],
          ['Category', 'Lanthanide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Amplifies light in undersea fibre-optic cables'],
        ],
      ),
      LessonSection.fact(
        title: 'Boosting the light',
        body:
            'Erbium-doped fibre amplifiers give tired laser pulses a fresh '
            'kick every so often — no erbium, no transoceanic internet.',
      ),
    ],
  ),

  // Z=69 — Tm
  BioEntity(
    id: 'element_tm',
    scale: BioScale.atoms,
    position: 68,
    name: 'Thulium',
    title: 'The Portable X-Ray',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The rarest stable rare earth — it makes X-rays you can carry into '
        'the field.',
    longDescription:
        'Thulium is the least abundant of the stable lanthanides, named after '
        'the mythical northern land Thule. A radioactive form of thulium '
        'emits X-rays, so it powers small, battery-free portable X-ray '
        'sources for medicine and field inspection.\n\n'
        'Thulium lasers are prized in surgery for cutting soft tissue with '
        'minimal bleeding.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Tm'],
          ['Atomic number', '69'],
          ['Group', 'n/a (lanthanide)'],
          ['Period', '6'],
          ['Category', 'Lanthanide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Powers portable, plug-free X-ray sources'],
        ],
      ),
      LessonSection.fact(
        title: 'Rarest of the stable',
        body:
            'Thulium is the scarcest lanthanide with a stable isotope — which '
            'long made it the most expensive of the rare earths.',
      ),
    ],
  ),

  // Z=70 — Yb
  BioEntity(
    id: 'element_yb',
    scale: BioScale.atoms,
    position: 69,
    name: 'Ytterbium',
    title: 'The Clock of the Future',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Its atoms tick so evenly they may one day out-clock caesium itself.',
    longDescription:
        'Ytterbium is one of four elements named after the single Swedish '
        'village of Ytterby. Its atoms trapped in laser light form optical '
        'clocks so stable they lose less than a second over the age of the '
        'universe — poised to redefine the second beyond caesium.\n\n'
        'Ytterbium also reacts to pressure by changing its electrical '
        'resistance, making it a handy stress gauge.',
    relatedIds: ['element_cs'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Yb'],
          ['Atomic number', '70'],
          ['Group', 'n/a (lanthanide)'],
          ['Period', '6'],
          ['Category', 'Lanthanide'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Basis for next-generation optical atomic clocks'],
        ],
      ),
      LessonSection.fact(
        title: 'Four elements, one village',
        body:
            'Ytterbium, yttrium, terbium and erbium are all named after '
            'Ytterby, Sweden — the most element-honoured place on Earth.',
      ),
    ],
  ),

  // Z=71 — Lu (closes the lanthanide series)
  BioEntity(
    id: 'element_lu',
    scale: BioScale.atoms,
    position: 70,
    name: 'Lutetium',
    title: 'The Cancer Hunter',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The last, densest lanthanide — a radioactive form seeks out and '
        'kills tumours.',
    longDescription:
        'Lutetium closes the lanthanide row: the smallest, densest and '
        'hardest of them, named after Lutetia, the Roman name for Paris.\n\n'
        'A radioactive form, lutetium-177, is attached to molecules that home '
        'in on cancer cells and destroy them from within — a fast-growing '
        'form of targeted radiotherapy. Stable lutetium also speeds up '
        'petroleum refining as a catalyst.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Lu'],
          ['Atomic number', '71'],
          ['Group', 'n/a (lanthanide)'],
          ['Period', '6'],
          ['Category', 'Lanthanide'],
          ['State at 25°C', 'Solid'],
          [
            'Standout fact',
            'Lu-177 delivers targeted radiotherapy to tumours'
          ],
        ],
      ),
      LessonSection.fact(
        title: 'Named for Paris',
        body:
            'Lutetium takes its name from Lutetia, the ancient Roman name for '
            'the city of Paris, where it was first isolated.',
      ),
    ],
  ),
];
