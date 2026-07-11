import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Universe (All) → "The Fate of Everything" module.
/// How the universe might end — near-future to the deepest deep future.
/// Cosmology gate: heat death / Big Freeze is the LEADING scenario; the
/// "eras" follow Adams & Laughlin's timeline in powers of 10 years; Big Rip
/// and Big Crunch and cyclic models are flagged as speculative / disfavored.
const List<BioEntity> universeFateEntities = <BioEntity>[
  // ─────────────────────────────────────────────────────────────────────────
  // 0 — The Three Possible Fates
  // ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'universe_fate_three_fates',
    scale: BioScale.universeAll,
    position: 0,
    name: 'The Three Possible Fates',
    title: 'It All Depends on Dark Energy',
    moduleId: 'universeAll_fate',
    shortDescription:
        'The universe has three classic endings — and which one comes true hangs almost entirely on how dark energy behaves.',
    longDescription:
        'For most of the 20th century cosmologists thought the ending was a tug-of-war between expansion and gravity: either the universe expands forever (open), coasts to a halt (flat), or recollapses (closed). Then in 1998 we discovered the expansion is accelerating, driven by "dark energy."\n\nThat changes everything. The fate is no longer just about how much matter there is — it is about what dark energy does over cosmic time. If it stays constant, we freeze. If it strengthens, we get torn apart. If it reverses, we crunch. Everything downstream in this module follows from that one uncertainty.',
    relatedIds: ['universe_fate_heat_death', 'universe_fate_after'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'Nobody knows how the universe ends — but we do know exactly which knob decides it. That knob is dark energy, the mysterious pressure making the cosmos expand faster and faster. Turn it three different ways and you get three different apocalypses.',
      ),
      LessonSection.thinkReveal(
        title: 'Think First',
        question:
            'Before 1998, the fate of the universe was thought to depend mostly on the total amount of MATTER. What discovery flipped the question to being about dark energy instead?',
        answer:
            'The discovery that the expansion of the universe is ACCELERATING, not slowing down. Two teams measuring distant supernovae in 1998 found the universe expanding faster over time — implying a repulsive "dark energy." Now ~68% of the universe\'s energy is dark energy, and its behavior, not matter\'s gravity, sets the fate.',
      ),
      LessonSection.table(
        title: 'The Three Classic Fates',
        headers: ['Fate', 'Dark energy behavior', 'Status'],
        rows: [
          ['Heat Death / Big Freeze', 'Stays constant (w ≈ −1)', 'LEADING — fits current data'],
          ['Big Rip', 'Strengthens ("phantom", w < −1)', 'Speculative — not favored'],
          ['Big Crunch', 'Weakens or reverses; gravity wins', 'Disfavored by current data'],
        ],
      ),
      LessonSection.fact(
        title: 'The Deciding Number',
        body:
            'w ≈ −1. This "equation of state" parameter measures dark energy\'s pressure. If w = −1 exactly, we freeze. If w < −1, we rip. Current data pins w very close to −1 — which is why heat death leads.',
      ),
      LessonSection.fact(
        title: 'Energy Budget Today',
        body:
            '~68% dark energy · ~27% dark matter · ~5% ordinary matter. The fate is written by the biggest slice — the one we understand least.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 1 — The Last Stars
  // ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'universe_fate_last_stars',
    scale: BioScale.universeAll,
    position: 1,
    name: 'The Last Stars',
    title: 'When the Lights Go Out',
    moduleId: 'universeAll_fate',
    shortDescription:
        'Star formation is a phase, not a fixture — the last new star ignites around 100 trillion years from now, closing the Stelliferous Era.',
    longDescription:
        'We live in the Stelliferous Era — the "Age of Stars," when galaxies still make new suns from cold gas. It feels permanent. It is not. Galaxies burn through their gas faster than they can recycle it, and eventually the fuel runs out.\n\nCosmologists estimate the last stars will form roughly 100 trillion (10¹⁴) years from now. The longest-lived stars — tiny red dwarfs sipping their fuel — will keep glowing for trillions of years after that, but no new ones will light. When the final red dwarf fades, the universe goes dark. This closes the first great chapter of Adams & Laughlin\'s deep-future timeline.',
    relatedIds: ['universe_fate_degenerate', 'universe_fate_three_fates'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'The night sky full of stars is a temporary feature of a very young universe. Star formation has a beginning, a peak (which already passed billions of years ago), and an end. We are watching the tail end of the fireworks.',
      ),
      LessonSection.thinkReveal(
        title: 'Think First',
        question:
            'Red dwarf stars are far dimmer than the Sun. Why does that make them the LAST stars still shining, long after Sun-like stars are gone?',
        answer:
            'Because they burn their fuel incredibly slowly. A red dwarf fuses hydrogen so gradually that it can last for TRILLIONS of years — far longer than the Sun\'s ~10-billion-year lifespan. Being dim and stingy with fuel is exactly what lets them outlast every brighter star. The last light in the cosmos will be a fading red dwarf.',
      ),
      LessonSection.table(
        title: 'Timeline of Starlight',
        headers: ['Epoch', 'Time from now', 'What happens'],
        rows: [
          ['Peak star formation', '~11 billion years ago', 'Already behind us'],
          ['Sun dies', '~5–8 billion years', 'Sun becomes red giant, then white dwarf'],
          ['Last new stars form', '~100 trillion (10¹⁴) yrs', 'Galactic gas exhausted'],
          ['Last red dwarfs fade', 'up to ~10¹⁴–10¹⁵ yrs', 'Stelliferous Era ends — darkness'],
        ],
      ),
      LessonSection.fact(
        title: 'The Closing Date',
        body:
            '~10¹⁴ years — 100 trillion years. That is roughly 7,000 times the current age of the universe (~13.8 billion years). We are astonishingly early.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 2 — The Degenerate Era
  // ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'universe_fate_degenerate',
    scale: BioScale.universeAll,
    position: 2,
    name: 'The Degenerate Era',
    title: 'A Universe of Corpses',
    moduleId: 'universeAll_fate',
    shortDescription:
        'After the last star fades, only stellar remnants remain — white dwarfs, neutron stars, and black holes drifting in the dark.',
    longDescription:
        'Once star formation ends, the universe enters the Degenerate Era — named for the "degenerate matter" that makes up dead stars, where quantum pressure, not fusion, holds them up. There is no more starlight being made. The cosmos is populated by corpses: cooling white dwarfs, neutron stars, and black holes.\n\nThis era spans an almost unimaginable stretch — from about 10¹⁵ to 10³⁹ years. Over that time, the big open question is whether protons decay. If they do (this is UNCONFIRMED), then even the white dwarfs and neutron stars slowly evaporate atom by atom, leaving only radiation and black holes behind. If protons are stable, the remnants simply cool toward absolute zero.',
    relatedIds: ['universe_fate_last_stars', 'universe_fate_black_hole'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'Picture a galaxy with no living stars — just billions of cold, dead cinders drifting in blackness. That is the Degenerate Era. The universe becomes a graveyard, and even the gravestones may slowly crumble.',
      ),
      LessonSection.thinkReveal(
        title: 'Think First',
        question:
            'White dwarfs and neutron stars no longer fuse anything. So what actually holds them up against their own gravity, and why is that different from a living star?',
        answer:
            'Quantum "degeneracy pressure." A living star pushes back against gravity with the outward pressure of fusion. A dead remnant has no fusion — instead, the Pauli exclusion principle forbids electrons (in white dwarfs) or neutrons (in neutron stars) from being squeezed into the same state. That quantum resistance is what "degenerate matter" means, and it is what holds the corpse together.',
      ),
      LessonSection.table(
        title: 'The Inhabitants',
        headers: ['Remnant', 'Left behind by', 'Held up by'],
        rows: [
          ['White dwarf', 'Sun-like stars', 'Electron degeneracy pressure'],
          ['Neutron star', 'Massive stars (supernova)', 'Neutron degeneracy pressure'],
          ['Black hole', 'The most massive stars', 'Nothing — gravity won'],
          ['Brown dwarf', 'Failed stars', 'Never ignited'],
        ],
      ),
      LessonSection.fact(
        title: 'Duration',
        body:
            '~10¹⁵ to 10³⁹ years. If proton decay is real (still UNCONFIRMED), ordinary matter evaporates near the end of this window, leaving only black holes and radiation.',
      ),
      LessonSection.fact(
        title: 'The Big "If"',
        body:
            'Proton decay has never been observed. Experiments put the proton half-life at more than ~10³⁴ years. Whether protons decay at all is one of the great open questions of physics.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 3 — The Black Hole Era
  // ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'universe_fate_black_hole',
    scale: BioScale.universeAll,
    position: 3,
    name: 'The Black Hole Era',
    title: 'When Even Black Holes Die',
    moduleId: 'universeAll_fate',
    shortDescription:
        'Black holes outlast everything else — and then they too evaporate, one particle at a time, over unthinkable spans of time.',
    longDescription:
        'When even the dead stars are gone, black holes are the last massive objects standing. This is the Black Hole Era, from roughly 10⁴⁰ to 10¹⁰⁰ years. For a while, black holes dominate the universe entirely.\n\nBut black holes are not truly eternal. Stephen Hawking showed that they slowly leak energy — Hawking radiation — and therefore shrink and eventually evaporate. The catch is how slow this is: a stellar-mass black hole takes about 10⁶⁷ years to evaporate, and a supermassive black hole up to ~10¹⁰⁰ years. When the last, largest black hole finally pops out of existence in a faint flash, the universe has nothing left but a thin haze of low-energy particles.',
    relatedIds: ['universe_fate_degenerate', 'universe_fate_heat_death'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'A black hole seems like the ultimate forever-object — nothing escapes it. Hawking\'s shocking insight was that black holes DO leak, glow faintly, and eventually die. The bigger the black hole, the slower it fades — so the very last event in the material universe is a giant black hole winking out.',
      ),
      LessonSection.thinkReveal(
        title: 'Think First',
        question:
            'Counter-intuitively, SMALLER black holes evaporate FASTER and hotter than bigger ones. Why would a tiny black hole die sooner than a supermassive one?',
        answer:
            'Because Hawking temperature is inversely proportional to mass. A small black hole is HOTTER, radiates more furiously, loses mass quickly, gets even hotter, and runs away to a final burst. A supermassive black hole is barely warmer than absolute zero, so it leaks agonizingly slowly. That is why stellar black holes evaporate in ~10⁶⁷ years but the biggest take up to ~10¹⁰⁰ years.',
      ),
      LessonSection.table(
        title: 'Evaporation Timescales',
        headers: ['Black hole', 'Mass scale', 'Time to evaporate'],
        rows: [
          ['Stellar-mass', '~1–10 Suns', '~10⁶⁷ years'],
          ['Supermassive', 'millions–billions of Suns', 'up to ~10¹⁰⁰ years'],
          ['The last one', 'largest surviving', 'ends the Black Hole Era'],
        ],
      ),
      LessonSection.fact(
        title: 'Hawking Radiation',
        body:
            'Black holes are not perfectly black. They emit a faint thermal glow (Hawking radiation), lose mass, and evaporate — turning the "eternal" object into a very, very slow-burning candle.',
      ),
      LessonSection.fact(
        title: 'The Final Span',
        body:
            '~10⁴⁰ to 10¹⁰⁰ years. After the last black hole evaporates, the observable contents of the universe are essentially just cold, dilute radiation and stray particles.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 4 — Heat Death & the Big Freeze
  // ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'universe_fate_heat_death',
    scale: BioScale.universeAll,
    position: 4,
    name: 'Heat Death & the Big Freeze',
    title: 'The Leading Ending',
    moduleId: 'universeAll_fate',
    shortDescription:
        'The favored fate: maximum entropy — a universe grown cold, dark, empty, and forever still, with no usable energy left anywhere.',
    longDescription:
        'This is the ending most cosmologists expect, and it is the terminus of all the eras before it: the Dark Era, or "heat death," sometimes called the Big Freeze. Accelerating expansion keeps stretching everything apart. Stars die, remnants evaporate, black holes evaporate, and the universe approaches maximum entropy — the state where energy is spread out so evenly that no useful work can ever be done again.\n\nHeat death is not fire but stillness. Space grows ever colder, ever emptier, ever darker. Galaxies beyond our local group are already receding so fast they will vanish over the horizon. The final universe is a near-perfect, near-uniform cold — endless, and effectively without events. This is the leading scenario precisely because it follows naturally from constant dark energy (w ≈ −1).',
    relatedIds: ['universe_fate_black_hole', 'universe_fate_after', 'universe_fate_three_fates'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'We picture the "end of the world" as an explosion. The real leading candidate is the opposite: nothing happening, forever. Heat death is a universe so spread-out and evenly cold that no star can shine, no engine can turn, and no event can ever occur again.',
      ),
      LessonSection.thinkReveal(
        title: 'Think First',
        question:
            'Heat death is defined as MAXIMUM ENTROPY. Why does maximum entropy mean the end of all activity, even though energy is still technically present?',
        answer:
            'Because usable energy requires a DIFFERENCE — hot vs. cold, dense vs. sparse. Work happens when energy flows from a concentrated place to an empty one. At maximum entropy, energy is spread perfectly evenly, so there are no differences left to exploit. The energy still exists but is "unusable." No temperature gradient means no flow, no work, no change — heat death.',
      ),
      LessonSection.table(
        title: 'The Eras Leading to the Freeze',
        headers: ['Era', 'Timescale', 'Dominant objects'],
        rows: [
          ['Stelliferous (Age of Stars)', 'now → ~10¹⁴ yrs', 'Living stars'],
          ['Degenerate', '~10¹⁵ → 10³⁹ yrs', 'White dwarfs, neutron stars'],
          ['Black Hole', '~10⁴⁰ → 10¹⁰⁰ yrs', 'Black holes'],
          ['Dark (Heat Death)', 'beyond ~10¹⁰⁰ yrs', 'Cold dilute radiation only'],
        ],
      ),
      LessonSection.fact(
        title: 'Why It Leads',
        body:
            'Heat death is favored because it needs no exotic physics — just dark energy staying constant (w ≈ −1), which is exactly what current data suggests.',
      ),
      LessonSection.fact(
        title: 'The Final State',
        body:
            'Maximum entropy: cold, dark, sparse, and event-free. Not a bang, not a crunch — a permanent, uniform stillness.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 5 — What Comes After?
  // ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'universe_fate_after',
    scale: BioScale.universeAll,
    position: 5,
    name: 'What Comes After?',
    title: 'The Honest Unknowns',
    moduleId: 'universeAll_fate',
    shortDescription:
        'Beyond the leading freeze lie the speculative endings — the Big Rip, bouncing and cyclic universes, and new bubbles budding off the old.',
    longDescription:
        'Heat death is the leading scenario, but it is not proven — and physics has bolder, stranger alternatives that are genuinely open questions, not settled answers. Honesty matters here: these are hypotheses at the edge of what we can test.\n\nSome models let dark energy strengthen into a "Big Rip" that tears atoms apart in a finite time. Others propose cyclic or bouncing universes, where a crunch or transition seeds a fresh Big Bang, endlessly. Still others suggest our vacuum could "decay" or bud off new bubble universes. We flag all of these clearly as speculation — the deep future is one of the frontiers where our best answer is still, honestly, "we do not yet know."',
    relatedIds: ['universe_fate_heat_death', 'universe_fate_three_fates'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'It would be dishonest to end with certainty. The freeze is our best guess — but the tools that would confirm it (a real theory of dark energy, of quantum gravity, of the vacuum) do not exist yet. So the last word of this module is a set of open questions, clearly labeled as such.',
      ),
      LessonSection.thinkReveal(
        title: 'Think First',
        question:
            'The Big Rip requires dark energy to be "phantom" energy (w < −1). Why does that specific condition let it rip apart even atoms, when ordinary heat death cannot?',
        answer:
            'Because phantom dark energy GROWS stronger over time and its repulsion accelerates without limit. In heat death, expansion stretches the space between galaxies but never overpowers the forces binding galaxies, stars, or atoms. Phantom energy keeps intensifying until, in a finite time, its outward pull exceeds gravity, then chemical bonds, then even the nuclear forces — shredding galaxies, then stars, then atoms. Current data does not favor w < −1, so this stays speculative.',
      ),
      LessonSection.table(
        title: 'Speculative Endings (Open Questions)',
        headers: ['Idea', 'Core requirement', 'How solid?'],
        rows: [
          ['Big Rip', 'Phantom dark energy (w < −1)', 'Speculative — data disfavors'],
          ['Big Crunch', 'Expansion reverses; gravity wins', 'Disfavored by current data'],
          ['Cyclic / bouncing', 'A crunch or bounce seeds a new bang', 'Speculative model'],
          ['Vacuum decay / new bubbles', 'Our vacuum is not truly stable', 'Speculative / untested'],
        ],
      ),
      LessonSection.fact(
        title: 'The Honest Bottom Line',
        body:
            'Leading science: heat death (Big Freeze). Everything on this page is a hypothesis, not a conclusion. The fate of everything is still an open question.',
      ),
      LessonSection.fact(
        title: 'Why We Cannot Yet Decide',
        body:
            'All of these depend on physics we do not have — the true nature of dark energy, quantum gravity, and whether the vacuum is stable. Until then: honest uncertainty.',
      ),
    ],
  ),
];
