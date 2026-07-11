import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Atoms → "The Periodic Table" module: elements 72–86 (Hafnium → Radon).
/// Period-6 tail: the third-row transition metals (Hf–Hg, beginning right after
/// the lanthanides) plus the heavy p-block (Tl–Rn). One BioEntity per element,
/// ascending atomic number.
const List<BioEntity> periodicElements72to86 = [
  // ── 72 · Hf · Hafnium ─────────────────────────────────────────────
  BioEntity(
    id: 'element_hf',
    scale: BioScale.atoms,
    position: 71,
    name: 'Hafnium',
    title: 'The reactor’s heat shield',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The first transition metal after the lanthanides — and a control rod that swallows neutrons whole.',
    longDescription:
        'Hafnium hides inside zirconium ore, chemically almost identical to its neighbor above it, which is why it was one of the last stable elements to be discovered (1923). Separating the two is a nightmare — yet nuclear engineers need the split badly.\n\nHafnium eats neutrons voraciously, so it makes superb reactor control rods; zirconium, its near-twin, must be almost hafnium-free to do the opposite job of letting neutrons pass. Same-looking metals, opposite nuclear personalities.',
    relatedIds: ['element_ta', 'element_w'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Hf'],
          ['Atomic number', '72'],
          ['Group', '4'],
          ['Period', '6'],
          ['Category', 'Transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'First element found after the lanthanide gap'],
        ],
      ),
      LessonSection.fact(
        title: 'Twin trouble',
        body:
            'Hafnium and zirconium are so alike that pure zirconium is defined partly by how little hafnium is left in it.',
      ),
    ],
  ),

  // ── 73 · Ta · Tantalum ────────────────────────────────────────────
  BioEntity(
    id: 'element_ta',
    scale: BioScale.atoms,
    position: 72,
    name: 'Tantalum',
    title: 'The pinch of metal in your phone',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A corrosion-proof metal so body-friendly it goes inside skulls — and inside nearly every phone capacitor.',
    longDescription:
        'Tantalum shrugs off acids that dissolve most metals, and the body barely notices it, so surgeons use it for implants and bone plates. Named for Tantalus, the myth-figure doomed to reach for water he could never drink — a nod to how it refuses to absorb acid.\n\nIts real fame is the tantalum capacitor: a tiny, reliable store of charge that let phones and laptops shrink. Much of it comes from coltan ore, which ties the shiny gadget in your pocket to hard questions about where the metal was mined.',
    relatedIds: ['element_hf', 'element_w'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Ta'],
          ['Atomic number', '73'],
          ['Group', '5'],
          ['Period', '6'],
          ['Category', 'Transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Backbone of the capacitors in your phone'],
        ],
      ),
      LessonSection.fact(
        title: 'Named after a punishment',
        body:
            'Tantalus could never drink the water at his lips; tantalum can never soak up acid — same idea, same name.',
      ),
    ],
  ),

  // ── 74 · W · Tungsten (MARQUEE) ───────────────────────────────────
  BioEntity(
    id: 'element_w',
    scale: BioScale.atoms,
    position: 73,
    name: 'Tungsten',
    title: 'The metal that laughs at fire',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The highest melting point of any metal — 3,422°C — which is why old light bulbs glowed with a tungsten thread.',
    longDescription:
        'Tungsten is the champion of heat. No other metal stays solid to a higher temperature: 3,422°C, hot enough that it can glow white without melting. That is exactly why incandescent bulbs strung a hair-thin tungsten filament across the gap — crank current through it, it glows, and it doesn’t droop.\n\nIt is also punishingly dense, nearly as heavy as gold, and its carbide is one of the hardest things in a workshop — the tips of drills, saw blades, and armor-piercing rounds. Its symbol W comes from "wolfram," its old German name.',
    relatedIds: ['element_ta', 'element_re'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'W'],
          ['Atomic number', '74'],
          ['Group', '6'],
          ['Period', '6'],
          ['Category', 'Transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Highest melting point of any metal (3,422°C)'],
        ],
      ),
      LessonSection.fact(
        title: 'A W from wolfram',
        body:
            'Tungsten’s odd symbol W comes from wolfram, its historic name — the ore once "devoured" tin during smelting like a wolf.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'Why was tungsten the perfect choice for the glowing thread inside an old light bulb?',
        answer:
            'A bulb filament has to get white-hot without melting. Tungsten has the highest melting point of any metal (3,422°C), so it can glow brightly for hours while staying solid — almost any other metal would melt through first.',
      ),
    ],
  ),

  // ── 75 · Re · Rhenium ─────────────────────────────────────────────
  BioEntity(
    id: 'element_re',
    scale: BioScale.atoms,
    position: 74,
    name: 'Rhenium',
    title: 'The last stable element found',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The final naturally-occurring stable element discovered (1925), now keeping jet engines from melting.',
    longDescription:
        'Rhenium was the last stable element with a predicted slot on the table to actually be found — spotted in 1925, filling a long-empty gap. It is genuinely rare, scattered thinly through the crust rather than pooled into ores.\n\nToday its main job is heroic: alloyed into the turbine blades of jet engines, it lets them run hotter without deforming, squeezing out more thrust and efficiency. A huge share of the world’s rhenium quietly flies overhead.',
    relatedIds: ['element_w', 'element_os'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Re'],
          ['Atomic number', '75'],
          ['Group', '7'],
          ['Period', '6'],
          ['Category', 'Transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Last stable element to be discovered (1925)'],
        ],
      ),
      LessonSection.fact(
        title: 'Riding in the engine',
        body:
            'Most rhenium ends up in jet-engine turbine blades, letting them spin white-hot without warping.',
      ),
    ],
  ),

  // ── 76 · Os · Osmium ──────────────────────────────────────────────
  BioEntity(
    id: 'element_os',
    scale: BioScale.atoms,
    position: 75,
    name: 'Osmium',
    title: 'The densest thing you can hold',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The densest naturally-occurring element — a fist-sized lump would strain to lift.',
    longDescription:
        'Osmium is the densest element found in nature: pack the same volume as water and it weighs about 22.6 times as much. A cube you could cup in one hand outweighs a big bag of groceries.\n\nIt is a platinum-group metal, hard and brittle, and its name comes from the Greek for "smell" — its oxide is toxic and reeks. Old fountain-pen nibs were tipped with osmium alloys precisely because it resists wear.',
    relatedIds: ['element_ir', 'element_re'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Os'],
          ['Atomic number', '76'],
          ['Group', '8'],
          ['Period', '6'],
          ['Category', 'Transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Densest naturally-occurring element (≈22.6 g/cm³)'],
        ],
      ),
      LessonSection.fact(
        title: 'Named for its stink',
        body:
            'Osmium comes from the Greek osme, "smell" — its oxide is sharp, toxic, and unmistakable.',
      ),
    ],
  ),

  // ── 77 · Ir · Iridium ─────────────────────────────────────────────
  BioEntity(
    id: 'element_ir',
    scale: BioScale.atoms,
    position: 76,
    name: 'Iridium',
    title: 'The fingerprint of the dinosaur killer',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Vanishingly rare in Earth’s crust but common in asteroids — a spike of it marks the day the dinosaurs died.',
    longDescription:
        'Iridium is almost absent from Earth’s surface — most of it sank to the core long ago — yet it is relatively abundant in asteroids. So when geologists found a worldwide layer of iridium-rich clay at exactly the time the dinosaurs vanished, it became the smoking gun for a giant impact 66 million years ago.\n\nOne of the densest and most corrosion-proof metals known, iridium anchors precision standards and shows up in tough spark-plug tips.',
    relatedIds: ['element_os', 'element_pt'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Ir'],
          ['Atomic number', '77'],
          ['Group', '9'],
          ['Period', '6'],
          ['Category', 'Transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Its worldwide clay layer flagged the dinosaur-killing impact'],
        ],
      ),
      LessonSection.fact(
        title: 'A line drawn in iridium',
        body:
            'A thin iridium-rich layer circles the globe at the exact rock boundary where the dinosaurs disappear — asteroid dust.',
      ),
    ],
  ),

  // ── 78 · Pt · Platinum (MARQUEE) ──────────────────────────────────
  BioEntity(
    id: 'element_pt',
    scale: BioScale.atoms,
    position: 77,
    name: 'Platinum',
    title: 'The catalyst in your tailpipe',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A prized precious metal that also does chemistry’s dirty work — cleaning car exhaust as it flows past.',
    longDescription:
        'Platinum is rarer than gold and just as coveted for jewelry, but its quiet superpower is catalysis: it speeds up chemical reactions without being used up. That is why a catalytic converter is stuffed with a platinum-group coating — exhaust gases touch it and toxic molecules get rearranged into harmless ones.\n\nIt is dense, corrosion-proof, and body-safe enough for some medical uses. Spanish explorers first dismissed it as "little silver" (platina) getting in the way of their gold.',
    relatedIds: ['element_ir', 'element_au'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Pt'],
          ['Atomic number', '78'],
          ['Group', '10'],
          ['Period', '6'],
          ['Category', 'Transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'The catalyst that cleans car exhaust'],
        ],
      ),
      LessonSection.fact(
        title: 'Once "little silver"',
        body:
            'Platina means "little silver" — Spanish miners saw it as a nuisance clogging their gold. Now it costs more than gold.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'A catalytic converter cleans your car’s exhaust but never wears out chemically. What does platinum do that lets it work over and over?',
        answer:
            'Platinum is a catalyst: it speeds up reactions that turn toxic exhaust gases into safer ones, but it is not consumed by those reactions. It keeps helping molecules react for the life of the car.',
      ),
    ],
  ),

  // ── 79 · Au · Gold (MARQUEE) ──────────────────────────────────────
  BioEntity(
    id: 'element_au',
    scale: BioScale.atoms,
    position: 78,
    name: 'Gold',
    title: 'The metal that never tarnishes',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'So chemically inert it stays bright for millennia — which is exactly why we made it money.',
    longDescription:
        'Gold’s magic is that it does almost nothing. It barely reacts with air, water, or most acids, so a gold coin buried for 3,000 years comes out shining. That reliability — not just its glow — is why cultures everywhere turned it into currency and treasure.\n\nIt is also wonderfully soft and workable: one gram can be beaten into a sheet nearly a square meter wide. And it conducts electricity without corroding, so a whisper of gold plates the contacts inside phones and computers. Its symbol Au is from the Latin aurum.',
    relatedIds: ['element_pt', 'element_hg'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Au'],
          ['Atomic number', '79'],
          ['Group', '11'],
          ['Period', '6'],
          ['Category', 'Transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'So unreactive it never tarnishes'],
        ],
      ),
      LessonSection.fact(
        title: 'Beaten thin',
        body:
            'Gold is so malleable that one gram can be hammered into gold leaf covering nearly a square meter.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'Why did so many separate civilizations independently choose gold — not iron or copper — as money and treasure?',
        answer:
            'Gold barely reacts with anything, so it never rusts, tarnishes, or crumbles. A gold object stays bright and intact for thousands of years, making it a trustworthy, lasting store of value — unlike metals that corrode away.',
      ),
    ],
  ),

  // ── 80 · Hg · Mercury (MARQUEE) ───────────────────────────────────
  BioEntity(
    id: 'element_hg',
    scale: BioScale.atoms,
    position: 79,
    name: 'Mercury',
    title: 'The metal that pours',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The only metal that is liquid at room temperature — a silvery pool you could tip out of a cup.',
    longDescription:
        'Mercury is the odd one out: at room temperature it is a shimmering liquid, rolling into beads instead of standing as a solid bar. That gave it a starring role in old thermometers and barometers, where it rose and fell smoothly with heat and pressure.\n\nBut it is also a potent poison that builds up in the body and the food chain, which is why thermometers and switches have mostly abandoned it. Its symbol Hg comes from hydrargyrum, Greek for "water-silver."',
    relatedIds: ['element_au', 'element_tl'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Hg'],
          ['Atomic number', '80'],
          ['Group', '12'],
          ['Period', '6'],
          ['Category', 'Transition metal'],
          ['State at 25°C', 'Liquid'],
          ['Standout fact', 'The only metal that is liquid at room temperature'],
        ],
      ),
      LessonSection.fact(
        title: 'Water-silver',
        body:
            'Its symbol Hg comes from hydrargyrum, "water-silver" — a metal that flows like water.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'Nearly every metal is a hard solid you could bang on. What makes mercury so unusual that you can pour it?',
        answer:
            'Mercury is the only metal that stays liquid at ordinary room temperature. Its atoms hold together weakly enough that it flows and beads instead of standing solid — which is why it once filled thermometers.',
      ),
    ],
  ),

  // ── 81 · Tl · Thallium ────────────────────────────────────────────
  BioEntity(
    id: 'element_tl',
    scale: BioScale.atoms,
    position: 80,
    name: 'Thallium',
    title: 'The poisoner’s poison',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A colorless, tasteless poison once called "inheritance powder" — discovered by a bright green flame.',
    longDescription:
        'Thallium was found in 1861 by its brilliant green spectral line — its name comes from the Greek for "green shoot." As a compound it is odorless and tasteless, yet deadly, which earned it a grim reputation in real and fictional poisonings.\n\nBecause it once had few legitimate uses beyond rat poison (now largely banned) it became a favorite of murder-mystery writers. Modern uses are careful and industrial: infrared optics and some electronics.',
    relatedIds: ['element_hg', 'element_pb'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Tl'],
          ['Atomic number', '81'],
          ['Group', '13'],
          ['Period', '6'],
          ['Category', 'Post-transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Named for the bright green flame that revealed it'],
        ],
      ),
      LessonSection.fact(
        title: 'A green shoot',
        body:
            'Thallium comes from thallos, "green shoot" — for the vivid green line it flashed in the spectroscope.',
      ),
    ],
  ),

  // ── 82 · Pb · Lead (MARQUEE) ──────────────────────────────────────
  BioEntity(
    id: 'element_pb',
    scale: BioScale.atoms,
    position: 81,
    name: 'Lead',
    title: 'The soft, heavy, slow poison',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Dense, soft, and easy to shape — which is why the Romans loved it and why it quietly harmed them.',
    longDescription:
        'Lead is heavy, soft enough to cut with a knife, and melts at a low temperature, so ancient engineers used it for pipes, cups, and paint. The Romans plumbed whole cities with it — the word "plumbing" comes from plumbum, lead’s Latin name and the source of its symbol Pb.\n\nBut lead is a cumulative poison, especially for children’s brains. Over the 20th century it was pulled out of gasoline, paint, and pipes as that danger became undeniable. It still shields us usefully: dense enough to block X-rays and gamma rays.',
    relatedIds: ['element_tl', 'element_bi'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Pb'],
          ['Atomic number', '82'],
          ['Group', '14'],
          ['Period', '6'],
          ['Category', 'Post-transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'Dense enough to shield you from X-rays'],
        ],
      ),
      LessonSection.fact(
        title: 'Plumbum, the plumber’s metal',
        body:
            'The word plumbing comes from plumbum, lead’s Latin name — Romans piped their cities with it.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'The dentist drapes a heavy apron over you before an X-ray. Why is that apron lined with lead?',
        answer:
            'Lead is extremely dense, so its packed atoms absorb X-rays before they can pass through. The apron soaks up stray radiation and shields the parts of you that don’t need to be imaged.',
      ),
    ],
  ),

  // ── 83 · Bi · Bismuth ─────────────────────────────────────────────
  BioEntity(
    id: 'element_bi',
    scale: BioScale.atoms,
    position: 82,
    name: 'Bismuth',
    title: 'The rainbow crystal in your stomach medicine',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A heavy metal that’s oddly harmless — it soothes upset stomachs and grows dazzling iridescent crystals.',
    longDescription:
        'Bismuth breaks the "heavy metals are toxic" rule: it is remarkably low in toxicity, which is why it is the active ingredient in pink stomach remedies. Grown slowly, it forms stair-stepped hopper crystals coated in a shimmering oil-slick of oxide colors.\n\nIt is also nearly the heaviest element that is (for all practical purposes) stable, and it is used in low-melting alloys and as a friendlier replacement for lead in some solders and shot.',
    relatedIds: ['element_pb', 'element_po'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Bi'],
          ['Atomic number', '83'],
          ['Group', '15'],
          ['Period', '6'],
          ['Category', 'Post-transition metal'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'A heavy metal gentle enough for stomach medicine'],
        ],
      ),
      LessonSection.fact(
        title: 'Oil-slick crystals',
        body:
            'Cooled slowly, bismuth grows geometric hopper crystals cloaked in a rainbow oxide sheen — a favorite of collectors.',
      ),
    ],
  ),

  // ── 84 · Po · Polonium ────────────────────────────────────────────
  BioEntity(
    id: 'element_po',
    scale: BioScale.atoms,
    position: 83,
    name: 'Polonium',
    title: 'The Curies’ radioactive namesake',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The intensely radioactive element Marie Curie found first — and named for her homeland, Poland.',
    longDescription:
        'Polonium was the first element Marie and Pierre Curie isolated from radioactive ore, in 1898. Marie named it for Poland, then partitioned and erased from the map — a political statement folded into chemistry.\n\nIt is fiercely radioactive: a gram would glow blue with its own energy and generate enough heat to be dangerous. That intense, portable heat gave it real uses in early spacecraft power sources — and, infamously, it has been used as a poison.',
    relatedIds: ['element_bi', 'element_at'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Po'],
          ['Atomic number', '84'],
          ['Group', '16'],
          ['Period', '6'],
          ['Category', 'Metalloid (radioactive)'],
          ['State at 25°C', 'Solid'],
          ['Standout fact', 'First element the Curies isolated (1898)'],
        ],
      ),
      LessonSection.fact(
        title: 'Named for a lost country',
        body:
            'Marie Curie named polonium after Poland, which had been wiped off the map — a scientist’s quiet protest.',
      ),
    ],
  ),

  // ── 85 · At · Astatine ────────────────────────────────────────────
  BioEntity(
    id: 'element_at',
    scale: BioScale.atoms,
    position: 84,
    name: 'Astatine',
    title: 'The rarest element on Earth',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'So scarce and unstable that Earth’s entire crust holds less than a teaspoon at any moment.',
    longDescription:
        'Astatine is the rarest naturally-occurring element there is. It forms only briefly as heavier elements decay, and it vanishes almost as fast — its longest-lived form lasts only hours. At any instant the whole planet’s crust contains perhaps a fraction of a gram.',
    relatedIds: ['element_po', 'element_rn'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'At'],
          ['Atomic number', '85'],
          ['Group', '17'],
          ['Period', '6'],
          ['Category', 'Halogen (radioactive)'],
          ['State at 25°C', 'Solid (presumed)'],
          ['Standout fact', 'The rarest naturally-occurring element on Earth'],
        ],
      ),
      LessonSection.fact(
        title: 'Blink and it’s gone',
        body:
            'Astatine’s name means "unstable." No one has ever seen a visible lump — it decays away before enough can gather.',
      ),
    ],
  ),

  // ── 86 · Rn · Radon (MARQUEE) ─────────────────────────────────────
  BioEntity(
    id: 'element_rn',
    scale: BioScale.atoms,
    position: 85,
    name: 'Radon',
    title: 'The invisible gas seeping up from the ground',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A colorless, odorless, radioactive noble gas that leaks out of rock and can pool in basements.',
    longDescription:
        'Radon is a noble gas — chemically aloof like helium or neon — but radioactive. It forms as uranium in soil and rock slowly decays, then seeps upward as an invisible, scentless gas. Outdoors it disperses harmlessly, but it can collect inside homes, especially basements.\n\nBecause you cannot see, smell, or taste it, radon is easy to ignore — yet breathing it long-term makes it the second-leading cause of lung cancer after smoking. Test kits are the only way to catch it.',
    relatedIds: ['element_at', 'element_po'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Rn'],
          ['Atomic number', '86'],
          ['Group', '18'],
          ['Period', '6'],
          ['Category', 'Noble gas (radioactive)'],
          ['State at 25°C', 'Gas'],
          ['Standout fact', 'Second-leading cause of lung cancer after smoking'],
        ],
      ),
      LessonSection.fact(
        title: 'A noble gas you can’t sense',
        body:
            'Radon has no color, smell, or taste — the only way to know it’s pooling in a basement is to test for it.',
      ),
      LessonSection.thinkReveal(
        title: 'Think it through',
        question:
            'Radon is a noble gas, like harmless helium. So why do people test their basements for it?',
        answer:
            'Unlike helium, radon is radioactive — it forms as uranium in soil decays and seeps up into homes. Being a gas, it can build up indoors where you breathe it, and its radiation makes it a leading cause of lung cancer. Being noble doesn’t make it safe.',
      ),
    ],
  ),
];
