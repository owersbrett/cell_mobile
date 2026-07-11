import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Organism → "The Kingdoms of Life": the great branches of living things.
/// Authored as teaching tools — hook, think-then-reveal, tables, landmark facts.
const List<BioEntity> organismKingdomsEntities = <BioEntity>[
  // ── 0 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'kingdom_organism',
    scale: BioScale.organism,
    position: 0,
    name: 'What Is an Organism?',
    title: 'One life, holding itself together',
    moduleId: 'organism_kingdoms',
    shortDescription:
        'An organism is a single living individual that maintains and rebuilds itself — from one bacterium to a blue whale.',
    longDescription:
        'An organism is one self-maintaining living individual. Whether it is a lone bacterium or a redwood tree, it takes in energy, holds its own boundary, repairs itself, and makes copies of itself. Life is stubborn organization: it fights the universe\'s tendency to fall apart.\n\n'
        'Biologists sort life into levels that nest inside each other — atoms build molecules, molecules build cells, cells build tissues and organs, and organs build the organism. Above the organism sit populations, ecosystems, and the whole biosphere. This module zooms out one more click: how the living world splits into its great branches.',
    relatedIds: [
      'kingdom_bacteria',
      'kingdom_animals',
      'kingdom_virus',
    ],
    sections: [
      LessonSection.fact(
        title: 'The hook',
        body:
            'You are made of ~30 trillion of your own cells — and carry roughly that many bacterial cells along for the ride. "One organism" is really a walking community.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'What one thing must every organism do that a rock, a river, or a fire does not?',
        answer:
            'Actively maintain and reproduce its own organized structure using energy. A fire consumes and spreads, but it does not repair itself or pass on a coded blueprint. Organisms carry instructions (DNA) and use energy to keep rebuilding themselves against decay.',
      ),
      LessonSection.table(
        title: 'The levels of life (small → large)',
        headers: ['Level', 'Example'],
        rows: [
          ['Atom', 'Carbon, oxygen'],
          ['Molecule', 'DNA, a protein'],
          ['Organelle', 'Mitochondrion, nucleus'],
          ['Cell', 'A neuron, a bacterium'],
          ['Tissue', 'Muscle, xylem'],
          ['Organ', 'Heart, leaf'],
          ['Organism', 'You, an oak tree'],
          ['Ecosystem', 'A forest, a reef'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'All known life shares one genetic code and one energy currency (ATP) — strong evidence every organism descends from a single common ancestor.',
      ),
    ],
  ),

  // ── 1 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'kingdom_bacteria',
    scale: BioScale.organism,
    position: 1,
    name: 'Bacteria',
    title: 'The tiny rulers of Earth',
    moduleId: 'organism_kingdoms',
    shortDescription:
        'Single-celled, no nucleus, everywhere — bacteria have run the planet for billions of years and outnumber every other living thing.',
    longDescription:
        'Bacteria are prokaryotes: single cells with no nucleus and no membrane-bound organelles. Their DNA floats free as a loop in the cytoplasm. They are ancient, abundant, and metabolically inventive — bacteria "invented" photosynthesis, nitrogen fixation, and countless chemical tricks long before complex life existed.\n\n'
        'They are the invisible engine of the biosphere: rotting leaves, fixing nitrogen for crops, curdling yogurt, and living in your gut by the trillions. A few cause disease, but the vast majority are harmless or essential.',
    relatedIds: [
      'kingdom_archaea',
      'kingdom_organism',
      'kingdom_virus',
    ],
    sections: [
      LessonSection.fact(
        title: 'The hook',
        body:
            'There are more bacteria in one gram of soil than there are people on Earth — roughly a billion cells in a pinch of dirt.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'A human cell has its DNA locked inside a nucleus. Where does a bacterium keep its DNA?',
        answer:
            'Nowhere special — it floats loose in the cytoplasm as a single circular loop (plus small extra rings called plasmids). No nucleus is the defining trait of a prokaryote. This is the deepest divide in biology: prokaryote (no nucleus) vs eukaryote (nucleus).',
      ),
      LessonSection.table(
        title: 'Prokaryote vs eukaryote',
        headers: ['Trait', 'Bacteria (prokaryote)', 'You (eukaryote)'],
        rows: [
          ['Nucleus', 'No', 'Yes'],
          ['DNA shape', 'Circular loop, loose', 'Linear, in nucleus'],
          ['Organelles', 'None (membrane-bound)', 'Many'],
          ['Typical size', '~1–2 µm', '~10–100 µm'],
          ['Cells', 'Single', 'Single or many'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'Some bacteria divide every ~20 minutes. From one cell, that is over a billion in about 10 hours — if food never ran out.',
      ),
    ],
  ),

  // ── 2 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'kingdom_archaea',
    scale: BioScale.organism,
    position: 2,
    name: 'Archaea',
    title: 'Life that loves the extremes',
    moduleId: 'organism_kingdoms',
    shortDescription:
        'They look like bacteria but are their own domain — thriving in boiling vents, acid, and salt where almost nothing else survives.',
    longDescription:
        'Archaea are also single-celled prokaryotes with no nucleus, so under a microscope they look like bacteria. But their genes and cell chemistry are so different that they form their own domain of life. Their cell membranes are built from unusual lipids that hold up under punishing conditions.\n\n'
        'Many are extremophiles: they live in boiling hydrothermal vents, hyper-salty lakes, and acidic springs. Others live quietly in ordinary places, including your gut — the methane-makers (methanogens) that turn hydrogen and CO₂ into methane are archaea.',
    relatedIds: [
      'kingdom_bacteria',
      'kingdom_organism',
    ],
    sections: [
      LessonSection.fact(
        title: 'The hook',
        body:
            'Some archaea grow happily above 100 °C — hotter than boiling water — in deep-sea vents where the pressure keeps the water liquid.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Archaea and bacteria are both tiny prokaryotes with no nucleus. So why are they placed in two totally separate domains of life?',
        answer:
            'Because looks lie. Genetic and biochemical evidence shows archaea are as different from bacteria as they are from us. Their membrane lipids, gene machinery, and RNA differ deeply — in some ways archaea are actually closer to eukaryotes than to bacteria. The three-domain tree (Bacteria, Archaea, Eukarya) is built on molecules, not appearance.',
      ),
      LessonSection.table(
        title: 'The three domains of life',
        headers: ['Domain', 'Nucleus?', 'Signature'],
        rows: [
          ['Bacteria', 'No', 'Everywhere; classic microbes'],
          ['Archaea', 'No', 'Extremes; unique membranes'],
          ['Eukarya', 'Yes', 'Protists, fungi, plants, animals'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'Archaea were only recognized as a separate domain in 1977, when Carl Woese compared their RNA — one of biology\'s biggest reclassifications.',
      ),
    ],
  ),

  // ── 3 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'kingdom_protists',
    scale: BioScale.organism,
    position: 3,
    name: 'Protists',
    title: 'The eukaryotic misfits',
    moduleId: 'organism_kingdoms',
    shortDescription:
        'The "leftover" kingdom — eukaryotes with a nucleus that aren\'t plants, animals, or fungi, from amoebas to giant kelp.',
    longDescription:
        'Protists are eukaryotes — their cells have a nucleus and organelles — but they don\'t fit the plant, animal, or fungus mold. They are the catch-all branch: mostly single-celled, though some (like kelp) grow huge. The group is wildly diverse and not a single tidy lineage; biologists treat "Protista" as a convenient bucket rather than one family.\n\n'
        'Some hunt like tiny animals (amoebas, paramecia). Some photosynthesize like plants (algae, diatoms). Some cause disease (the malaria parasite is a protist). Ocean phytoplankton — many of them protists — produce a large share of Earth\'s oxygen.',
    relatedIds: [
      'kingdom_organism',
      'kingdom_fungi',
      'kingdom_plants',
    ],
    sections: [
      LessonSection.fact(
        title: 'The hook',
        body:
            'Microscopic ocean protists (phytoplankton) generate an estimated tens of percent of the oxygen you breathe — rivaling all the world\'s forests.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'What is the single trait that lets us group amoebas, algae, and the malaria parasite together — even though they behave completely differently?',
        answer:
            'They are all eukaryotes (cells with a true nucleus) that are NOT plants, animals, or fungi. "Protist" is defined by what they lack — a mold to fit — rather than by shared ancestry. It is biology\'s honest "everything else" drawer.',
      ),
      LessonSection.table(
        title: 'Protists borrow every lifestyle',
        headers: ['Protist', 'Acts like a…', 'How it feeds'],
        rows: [
          ['Amoeba', 'Animal', 'Engulfs prey'],
          ['Diatom / algae', 'Plant', 'Photosynthesis'],
          ['Slime mold', 'Fungus', 'Absorbs decay'],
          ['Malaria parasite', 'Parasite', 'Lives in host cells'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'A single giant kelp can grow over 30 metres — yet it is still lumped with single-celled protists, because it isn\'t a true plant.',
      ),
    ],
  ),

  // ── 4 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'kingdom_fungi',
    scale: BioScale.organism,
    position: 4,
    name: 'Fungi',
    title: 'The great recyclers',
    moduleId: 'organism_kingdoms',
    shortDescription:
        'Not plants — fungi don\'t make their own food. They digest the world around them, and they\'re more closely related to you than to a tree.',
    longDescription:
        'Fungi are eukaryotes that feed by absorption: they release enzymes into their surroundings, break matter down outside their bodies, then soak up the nutrients. They are heterotrophs — they cannot photosynthesize — which makes them the planet\'s master decomposers, rotting dead wood and returning nutrients to the soil.\n\n'
        'Mushrooms are just the fruiting bodies; the real fungus is a hidden web of thread-like hyphae (the mycelium) spreading underground. Genetically, fungi branch closer to animals than to plants — a surprise that trips up almost everyone.',
    relatedIds: [
      'kingdom_animals',
      'kingdom_plants',
      'kingdom_organism',
    ],
    sections: [
      LessonSection.fact(
        title: 'The hook',
        body:
            'The largest known organism on Earth is a honey fungus in Oregon — its mycelium sprawls across ~9 square kilometres and may be thousands of years old.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Mushrooms grow in soil and don\'t move — so are fungi just weird plants?',
        answer:
            'No. Plants make their own food from sunlight (autotrophs); fungi cannot — they absorb nutrients from other organisms (heterotrophs), the way animals eat. On the tree of life, fungi and animals share a more recent common ancestor than either shares with plants. A mushroom is more your cousin than a tree is.',
      ),
      LessonSection.table(
        title: 'Fungi vs plants — the key split',
        headers: ['Trait', 'Fungi', 'Plants'],
        rows: [
          ['Makes own food?', 'No (heterotroph)', 'Yes (photosynthesis)'],
          ['Cell wall', 'Chitin', 'Cellulose'],
          ['Closest relatives', 'Animals', 'Algae'],
          ['Role', 'Decomposer', 'Producer'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'Fungi and plants team up: ~90% of land plants trade sugars for water and minerals with fungal partners at their roots (mycorrhizae).',
      ),
    ],
  ),

  // ── 5 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'kingdom_plants',
    scale: BioScale.organism,
    position: 5,
    name: 'Plants',
    title: 'The world\'s food-makers',
    moduleId: 'organism_kingdoms',
    shortDescription:
        'Plants capture sunlight and turn air and water into food and oxygen — the foundation almost every other organism eats from.',
    longDescription:
        'Plants are multicellular eukaryotes that make their own food through photosynthesis: using chlorophyll, they capture sunlight and combine carbon dioxide with water to build sugars, releasing oxygen as a by-product. They are the great autotrophs — "self-feeders" — and the base of nearly every food chain.\n\n'
        'Their cells carry rigid cellulose walls and green chloroplasts. From mosses to towering trees, plants built the breathable atmosphere over hundreds of millions of years and still capture the energy that feeds the living world.',
    relatedIds: [
      'kingdom_fungi',
      'kingdom_protists',
      'kingdom_organism',
    ],
    sections: [
      LessonSection.fact(
        title: 'The hook',
        body:
            'Nearly every atom of your body\'s food energy traces back to a plant (or algae) catching a photon of sunlight. Even a steak is grass, one step removed.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'A tree can add tonnes of solid wood over its life. Where does all that mass actually come from — the soil?',
        answer:
            'Mostly from thin air. The bulk of a plant\'s dry mass is carbon pulled from carbon dioxide in the atmosphere during photosynthesis, plus hydrogen and oxygen from water. Soil supplies water and small amounts of minerals — but a tree is, quite literally, built out of the sky.',
      ),
      LessonSection.table(
        title: 'Photosynthesis, in and out',
        headers: ['Goes in', 'Comes out'],
        rows: [
          ['Sunlight (energy)', 'Sugar (stored energy)'],
          ['Carbon dioxide', 'Oxygen'],
          ['Water', '—'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'The tallest living thing is a coast redwood over 115 metres tall — taller than a 35-storey building, grown mostly from air, water, and light.',
      ),
    ],
  ),

  // ── 6 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'kingdom_animals',
    scale: BioScale.organism,
    position: 6,
    name: 'Animals',
    title: 'The movers and eaters',
    moduleId: 'organism_kingdoms',
    shortDescription:
        'Multicellular eukaryotes that eat other organisms and — famously — move. From sponges to humans, the kingdom of muscle and nerve.',
    longDescription:
        'Animals are multicellular eukaryotes that must eat other organisms for energy — they are heterotrophs, like fungi, but they typically take food inside their bodies and digest it internally. Most can move under their own power at some stage of life, and many have muscles and nerves that let them react to the world fast.\n\n'
        'Animal cells have no cell wall and no chloroplasts, which is part of why animals are so flexible and fast. The kingdom runs from simple sponges and jellyfish to insects (by far the most numerous animals) up to mammals, including us.',
    relatedIds: [
      'kingdom_fungi',
      'kingdom_plants',
      'kingdom_organism',
    ],
    sections: [
      LessonSection.fact(
        title: 'The hook',
        body:
            'About 80% of all known animal species are insects. If you picked a random animal on Earth, the odds say it has six legs and an exoskeleton.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Both animals and fungi are heterotrophs that can\'t photosynthesize. So what makes an animal an animal, not a fungus?',
        answer:
            'How they eat and what they\'re built from. Fungi digest food outside their bodies and absorb it, and their walls are chitin. Animals usually ingest food and digest it inside, have no cell wall at all, and most develop muscles and nerves for movement. "Eating from the world" is shared; the body plan is not.',
      ),
      LessonSection.table(
        title: 'Animals vs plants vs fungi',
        headers: ['Trait', 'Animals', 'Plants', 'Fungi'],
        rows: [
          ['Feeds by', 'Ingesting', 'Photosynthesis', 'Absorbing'],
          ['Cell wall', 'None', 'Cellulose', 'Chitin'],
          ['Moves?', 'Usually', 'No', 'No'],
          ['Nerves/muscle', 'Often', 'No', 'No'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'The blue whale is the largest animal ever known — up to ~30 metres and 150+ tonnes, its heart the size of a small car.',
      ),
    ],
  ),

  // ── 7 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'kingdom_virus',
    scale: BioScale.organism,
    position: 7,
    name: 'Viruses — Alive or Not?',
    title: 'The edge of life',
    moduleId: 'organism_kingdoms',
    shortDescription:
        'A virus is genetic instructions in a protein shell — it can\'t eat, grow, or copy itself alone. Is that alive? Biology still argues.',
    longDescription:
        'A virus is not a cell. It is a package of genetic material (DNA or RNA) wrapped in a protein coat, sometimes with a lipid envelope — and nothing else. It has no metabolism, no way to make energy, and no way to reproduce on its own. Outside a host it is an inert particle.\n\n'
        'To multiply, a virus must hijack a living cell, forcing that cell\'s machinery to build copies of the virus. Because it can\'t self-reproduce and isn\'t made of cells, most biologists place viruses outside the tree of life — neither cleanly alive nor cleanly non-living.',
    relatedIds: [
      'kingdom_organism',
      'kingdom_bacteria',
    ],
    sections: [
      LessonSection.fact(
        title: 'The hook',
        body:
            'There are more virus particles on Earth than stars in the observable universe — an estimated 10³¹ of them, most in the oceans.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Every organism can maintain and reproduce itself. A virus can do neither without hijacking a host cell. So — is a virus alive?',
        answer:
            'There\'s no settled answer, and that\'s the honest lesson. Viruses evolve, carry genes, and adapt (life-like). But they have no cells, no metabolism, and cannot reproduce on their own — they are inert until they invade a cell (non-life-like). Most biologists call them "at the edge of life" and leave them off the tree of life entirely.',
      ),
      LessonSection.table(
        title: 'Virus vs a living cell',
        headers: ['Property', 'Virus', 'Living cell'],
        rows: [
          ['Made of cells?', 'No (acellular)', 'Yes'],
          ['Own metabolism?', 'No', 'Yes'],
          ['Reproduces alone?', 'No — needs a host', 'Yes'],
          ['Can evolve?', 'Yes', 'Yes'],
          ['In the tree of life?', 'No', 'Yes'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'Viruses are astonishingly small — most are ~20–300 nanometres, tens of times tinier than a bacterium, and invisible to ordinary light microscopes.',
      ),
    ],
  ),
];
