import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

const cellEntities = <BioEntity>[
  BioEntity(
    id: 'cell_guard',
    scale: BioScale.cell,
    position: 0,
    name: 'Guard Cell',
    title: 'The Gatekeeper',
    shortDescription: 'Paired kidney-shaped cells on leaf surfaces that open and close stomata to regulate gas exchange and water loss.',
    longDescription:
        'Guard cells come in pairs, and between each pair sits a stoma — the adjustable pore through which a plant breathes. When the two guard cells swell with water they bow apart and the pore opens; when they lose water and go flaccid, the pore seals shut. That single toggle governs the plant\'s hardest daily trade: open the pore to let carbon dioxide in for photosynthesis, and water vapor escapes with every second it stays open.\n\n'
        'To manage that trade, guard cells read the environment — light, humidity, internal CO₂, and the stress hormone abscisic acid (ABA) — and pump potassium ions in or out to change their own turgor. Because they set how much biomass a crop builds per drop of water used, guard-cell behavior is a direct lever on drought tolerance. C4 crops like corn concentrate CO₂ internally, so they can keep stomata more closed and still photosynthesize, which is why they outlast C3 crops in heat.',
    zoomInIds: ['organelle_central_vacuole', 'organelle_chloroplast', 'organelle_mitochondria'],
    zoomOutIds: ['tissue_dermal'],
    relatedIds: ['organ_leaf', 'cell_mesophyll', 'ecosystem_water_cycle'],
    sections: [
      LessonSection.table(
        title: 'The stomatal toggle',
        headers: ['State', 'Guard cells', 'CO₂ intake', 'Water loss', 'Typical trigger'],
        rows: [
          ['Open', 'Turgid (swollen)', 'High', 'High', 'Light, low internal CO₂, moist air'],
          ['Closed', 'Flaccid (limp)', 'None', 'Low', 'Darkness, drought, ABA hormone'],
        ],
      ),
      LessonSection.table(
        title: 'How a pore opens — the ion pump',
        headers: ['Step', 'What happens'],
        rows: [
          ['1', 'Guard cells actively pump K⁺ (potassium) ions inward'],
          ['2', 'Water potential drops, so water follows by osmosis'],
          ['3', 'Cells swell; uneven wall thickening makes them bow apart'],
          ['4', 'The pore between them opens for gas exchange'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Placement',
        question: 'Most stomata sit on the shaded underside of a leaf, not the sunlit top. Why would a plant hide its breathing pores from the light it needs?',
        answer: 'Photosynthesis happens inside the leaf regardless of where the pore is — the CO₂ just has to get in. But the underside is cooler and shaded, so an open pore there loses far less water to evaporation than one baking on the top surface. The plant separates the two jobs: capture light with the whole upper face, but do the risky business of opening pores where evaporation is weakest.',
      ),
      LessonSection.thinkReveal(
        title: 'The C4 advantage',
        question: 'Corn (C4) grows more biomass per liter of water than wheat (C3) in hot weather. What lets it keep its stomata more closed and still thrive?',
        answer: 'C4 plants run a CO₂-concentrating pump that stacks carbon dioxide up inside special bundle-sheath cells before fixing it. Because the internal CO₂ supply is rich, the plant does not need to fling its stomata wide to grab more from the air — it can crack them narrower, lose less water, and still feed photosynthesis. In cool, wet climates that machinery costs more energy than it saves, which is why C3 crops still dominate there.',
      ),
      LessonSection.fact(
        title: 'A tiny door with total control',
        body: 'Stomata cover only ~1–2% of a leaf\'s surface — yet nearly all of the plant\'s CO₂ intake and ~95% of its water loss pass through that sliver.',
      ),
    ],
  ),
  BioEntity(
    id: 'cell_root_hair',
    scale: BioScale.cell,
    position: 1,
    name: 'Root Hair Cell',
    title: 'The Nutrient Seeker',
    shortDescription: 'Elongated root cells with finger-like extensions that dramatically increase the absorptive surface area for water and minerals.',
    longDescription:
        'A root hair cell pushes a single thin projection out into the soil, and that one extension can multiply the cell\'s absorbing surface up to ~15 times. This is the border crossing where the mineral world becomes the biological one: water enters by osmosis, and dissolved nutrients — nitrate, phosphate, potassium — enter partly by diffusion but mostly by active transport, which costs ATP because the cell must haul them in against their concentration gradient.\n\n'
        'That energy bill is why root hair cells are stuffed with mitochondria and why damaged or oxygen-starved roots stop feeding the plant — no ATP, no uptake. The thin shell of soil clinging to the root hairs, the rhizosphere, is one of the most crowded microbial habitats on Earth, and the bacteria and fungi living there can either trade nutrients with the plant or compete for them.',
    zoomInIds: ['organelle_mitochondria', 'organelle_plasma_membrane', 'organelle_central_vacuole'],
    zoomOutIds: ['tissue_dermal'],
    relatedIds: ['molecular_air', 'organ_root', 'ecosystem_rhizosphere', 'ecosystem_soil_biome'],
    sections: [
      LessonSection.table(
        title: 'Two ways in',
        headers: ['Substance', 'Mechanism', 'Needs ATP?', 'Moves...'],
        rows: [
          ['Water', 'Osmosis', 'No', 'Down its water potential, into the cell'],
          ['Nitrate / phosphate / K⁺', 'Active transport', 'Yes', 'Against its gradient (soil is dilute)'],
        ],
      ),
      LessonSection.table(
        title: 'Built for absorption',
        headers: ['Adaptation', 'Payoff'],
        rows: [
          ['Long, thin hair projection', 'Up to ~15× more surface area for uptake'],
          ['Very thin cell wall', 'Short path for water and ions to cross'],
          ['Packed with mitochondria', 'ATP supply for active transport'],
          ['No chloroplasts', 'None wasted — it lives underground in the dark'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Powered by the dark',
        question: 'A root hair cell has almost no chloroplasts but is crammed with mitochondria. What does that combination tell you about its job?',
        answer: 'It lives in soil, where there is no light, so chloroplasts would be useless — it makes no food of its own. Instead its work is pulling minerals in against their gradient, which is pure active transport, and active transport runs on ATP. The dense mitochondria are the giveaway: this is a cell that burns energy importing nutrients, not one that captures energy from light.',
      ),
      LessonSection.thinkReveal(
        title: 'Wet soil, wilting plant',
        question: 'Over-fertilize a field or let salt build up, and plants can wilt even though the soil is soaking wet. What went wrong at the root hair?',
        answer: 'Osmosis follows water potential. Normally the soil solution is more dilute than the root, so water flows in. Dump in too much fertilizer salt and the soil solution becomes more concentrated than the cell — now water flows the wrong way, out of the root and into the soil. The plant is surrounded by water it cannot drink. This "physiological drought" is why over-fertilizing scorches crops.',
      ),
      LessonSection.fact(
        title: 'A basketball court underground',
        body: 'A single rye plant was measured to grow ~14 billion root hairs — a combined absorptive surface larger than a basketball court, all packed into a pot of soil.',
      ),
    ],
  ),
  BioEntity(
    id: 'cell_mesophyll',
    scale: BioScale.cell,
    position: 2,
    name: 'Mesophyll Cell',
    title: 'The Photosynthesis Factory',
    shortDescription: 'Chloroplast-packed cells in the leaf interior where most photosynthesis occurs.',
    longDescription:
        'Mesophyll cells fill the interior of the leaf, each one packed with ~40–50 chloroplasts, and they are where most of a plant\'s photosynthesis actually happens. They come in two crews with different builds. Palisade mesophyll — tall columnar cells stacked just under the upper surface — is arranged to catch as much light as possible. Spongy mesophyll below it is loosely packed with big air gaps that connect to the stomata, so CO₂ can diffuse freely to every working cell.\n\n'
        'That vertical division of labor — light capture up top, gas exchange down below — is why leaf thickness tracks light history. Sun-grown leaves stack more palisade layers and run thicker; shade leaves stay thin. Because mesophyll density sets a crop\'s photosynthetic ceiling, canopy management and planting density are really arguments about how much mesophyll gets good light.',
    zoomInIds: ['organelle_chloroplast', 'organelle_mitochondria', 'organelle_plasmodesmata'],
    zoomOutIds: ['tissue_ground'],
    relatedIds: ['molecular_carbon', 'molecular_carbohydrates', 'cell_guard', 'organ_leaf'],
    sections: [
      LessonSection.table(
        title: 'Two mesophyll crews',
        headers: ['Feature', 'Palisade', 'Spongy'],
        rows: [
          ['Position', 'Just under upper surface', 'Lower half of leaf'],
          ['Shape / packing', 'Tall columns, tightly packed', 'Irregular, loosely packed'],
          ['Air spaces', 'Few', 'Large and connected'],
          ['Main job', 'Capture light', 'Move CO₂ to the cells'],
          ['Chloroplasts', 'Most', 'Fewer'],
        ],
      ),
      LessonSection.table(
        title: 'Sun leaf vs shade leaf',
        headers: ['Trait', 'Sun leaf', 'Shade leaf'],
        rows: [
          ['Thickness', 'Thicker', 'Thinner'],
          ['Palisade layers', 'More (often 2–3)', 'Fewer (often 1)'],
          ['Best at', 'Using intense light', 'Squeezing out of dim light'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why columns on top?',
        question: 'Palisade cells are tall columns crammed near the top of the leaf; spongy cells are loose and airy near the bottom. Why not reverse it?',
        answer: 'Light comes from above, so the top layer should be a dense wall of chloroplasts standing edge-on to soak up as many photons as possible — columns pack the most chloroplasts into the sunlit zone. But CO₂ has to physically travel to every chloroplast, and gas moves fast through air, not through solid cell. So the bottom is built loose and gappy, connected to the stomata, so carbon dioxide can reach the whole factory. Capture light where the light is; move gas where the pores are.',
      ),
      LessonSection.thinkReveal(
        title: 'Reading a leaf\'s past',
        question: 'You slice two leaves from the same species and one is noticeably thicker. What does the thick one tell you about where it grew?',
        answer: 'It almost certainly grew in strong sun. In bright light a leaf can profitably build extra palisade layers — more stacked chloroplasts means it can turn intense light into sugar instead of wasting it. In shade that investment does not pay off, so the leaf stays thin with a single palisade layer, prioritizing catching every scarce photon over raw capacity. Leaf thickness is a physical record of the light budget the plant developed under.',
      ),
      LessonSection.fact(
        title: 'Green machines by the dozen',
        body: 'A single mesophyll cell can hold ~40–50 chloroplasts — and one square millimeter of leaf can carry on the order of half a million of them.',
      ),
    ],
  ),
  BioEntity(
    id: 'cell_xylem_vessel',
    scale: BioScale.cell,
    position: 3,
    name: 'Xylem Vessel',
    title: 'The Water Highway',
    shortDescription: 'Dead, hollow tubes reinforced with lignin that transport water and minerals from roots to leaves.',
    longDescription:
        'Xylem vessel elements only start working after they die. As they mature they lay down thick, lignin-reinforced walls, then destroy their own contents; the end walls between stacked cells dissolve, leaving continuous hollow pipes that can run from a root tip to a leaf tip. What is left is plumbing — rigid, empty, and open.\n\n'
        'Water climbs those pipes on physics alone, no metabolic energy spent. Evaporation from the leaves (transpiration) creates tension that pulls the water column upward, and because water molecules hydrogen-bond to each other (cohesion), the whole column can be dragged up without snapping. Vessel diameter is the key crop trait: wide vessels carry more water but are more prone to cavitation — air bubbles that break the column — so drought crops like wheat favor narrow, cavitation-resistant vessels while rice runs wide.',
    zoomInIds: ['organelle_cell_wall'],
    zoomOutIds: ['tissue_vascular'],
    relatedIds: ['cell_phloem_sieve_tube', 'organ_stem', 'organ_root', 'ecosystem_water_cycle'],
    sections: [
      LessonSection.table(
        title: 'Xylem vs phloem — the two pipelines',
        headers: ['Trait', 'Xylem', 'Phloem'],
        rows: [
          ['Living or dead?', 'Dead, hollow', 'Living (barely)'],
          ['Carries', 'Water + minerals', 'Sugars (sucrose)'],
          ['Direction', 'Upward only (roots → leaves)', 'Both ways (source → sink)'],
          ['Energy source', 'Physics (evaporation)', 'Active loading (ATP)'],
          ['Walls', 'Thick, lignin-reinforced', 'Sieve plates, thin walls'],
        ],
      ),
      LessonSection.table(
        title: 'The transpiration pull, link by link',
        headers: ['Step', 'What drives it'],
        rows: [
          ['Water evaporates from leaf cells', 'Transpiration through stomata'],
          ['Creates negative pressure (tension)', 'Loss at the top pulls the column'],
          ['Column holds together', 'Cohesion — water H-bonds to water'],
          ['Water climbs to the top', 'Column dragged up unbroken'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'A cell that works dead',
        question: 'Xylem vessels only function after the cell dies and empties itself out. How can a corpse be an asset rather than a failure?',
        answer: 'For a pipe, cell contents are just clutter. A living cell full of cytoplasm, organelles, and a nucleus would obstruct flow and cost energy to maintain. By killing itself, digesting its insides, and dissolving its end walls, the vessel element becomes a clean, open, rigid tube — exactly what you want for moving water fast with zero maintenance. The lignin walls it built while alive keep it from collapsing under the tension. It is less a dead cell than a self-manufactured pipe.',
      ),
      LessonSection.thinkReveal(
        title: 'The width gamble',
        question: 'Wide xylem vessels move much more water than narrow ones — so why would a drought-adapted crop deliberately keep its vessels narrow?',
        answer: 'Flow through a pipe scales steeply with radius, so a wide vessel is a firehose. But that column is under tension, and a wide column is far more likely to cavitate — one air bubble expands and snaps the water thread, killing the whole vessel. In a drought, tension runs high and cavitation is a constant threat, so a wide-vessel plant risks catastrophic failure right when it needs water most. Narrow vessels move less, but they resist embolism and keep working under stress. It is throughput versus survival.',
      ),
      LessonSection.fact(
        title: 'Uphill, with no pump',
        body: 'The tallest trees lift water more than ~100 m — over 115 m in the biggest redwoods — with no moving parts and not a single joule of metabolic energy, powered entirely by evaporation and the stickiness of water.',
      ),
    ],
  ),
  BioEntity(
    id: 'cell_phloem_sieve_tube',
    scale: BioScale.cell,
    position: 4,
    name: 'Phloem Sieve Tube',
    title: 'The Sugar Pipeline',
    shortDescription: 'Living cells connected end-to-end that transport sugars and organic compounds throughout the plant.',
    longDescription:
        'Phloem sieve tubes are the plant\'s food delivery network, carrying sucrose from sources (where sugar is made — mainly leaves) to sinks (where it is used or stored — roots, fruits, growing tips). Unlike the dead xylem, sieve tube elements are alive, but only just: they jettison their nucleus, ribosomes, and most organelles at maturity, keeping a thin rim of cytoplasm and connecting end-to-end through perforated sieve plates.\n\n'
        'Because a sieve tube can no longer run its own affairs, each one is paired with a companion cell that keeps a full set of machinery and supplies the ATP and proteins its stripped-down neighbor cannot make. Sugar is actively loaded at the source, water follows by osmosis to build pressure, and that pressure pushes the sap toward low-pressure sinks. This is also why aphids and many plant viruses target phloem — it is a pressurized stream of concentrated food.',
    zoomInIds: ['organelle_plasmodesmata'],
    zoomOutIds: ['tissue_vascular'],
    relatedIds: ['molecular_carbohydrates', 'cell_xylem_vessel', 'organ_stem', 'cell_mesophyll'],
    sections: [
      LessonSection.table(
        title: 'Source vs sink',
        headers: ['Aspect', 'Source', 'Sink'],
        rows: [
          ['What it is', 'Where sugar is made or released', 'Where sugar is used or stored'],
          ['Examples', 'Mature leaves, storage organs in spring', 'Roots, fruits, seeds, growing tips'],
          ['Sugar move', 'Loaded into phloem', 'Unloaded from phloem'],
          ['Pressure', 'High (water drawn in)', 'Low (water leaves)'],
        ],
      ),
      LessonSection.table(
        title: 'The odd couple',
        headers: ['Feature', 'Sieve tube element', 'Companion cell'],
        rows: [
          ['Nucleus?', 'No (lost at maturity)', 'Yes'],
          ['Organelles', 'Few — thin cytoplasm rim', 'Full set, dense cytoplasm'],
          ['Role', 'The pipe sap flows through', 'Metabolic life-support (ATP, proteins)'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why keep a chaperone?',
        question: 'A xylem vessel throws away everything and dies. A sieve tube also throws away its nucleus — but stays alive and keeps a companion cell attached. Why not just die too?',
        answer: 'Xylem moves water by passive physics, so an empty dead pipe is perfect. Phloem is different: sugar must be actively loaded and the flow is managed, which takes living, energy-spending machinery. But a tube full of organelles would clog the flow of thick sap. The compromise is to strip the sieve tube down to an open channel yet keep it alive, and outsource its metabolism to a fully-equipped companion cell wired right beside it. One cell is the highway; the other is the engine room that keeps it running.',
      ),
      LessonSection.thinkReveal(
        title: 'Why aphids drink sugar, not water',
        question: 'Aphids tap phloem, not xylem, and once they pierce a sieve tube the sap flows into them almost on its own. Why is phloem the easy target?',
        answer: 'Phloem sap is under positive pressure — sugar loading pulls in water and pressurizes the tube — so when an aphid\'s stylet punctures a sieve tube, the sap is actively pushed into it; the insect barely has to suck. It is also a rich sugar solution, far more nutritious than xylem. Xylem, by contrast, is water under negative tension: an insect would have to fight suction just to pull out dilute, mostly-mineral fluid. Phloem is a pressurized food line practically inviting a straw.',
      ),
      LessonSection.fact(
        title: 'Syrup on the move',
        body: 'Phloem sap can run ~15–30% dissolved sugar — as sweet as a soft drink — and streams toward sinks at roughly ~0.5–1 meter per hour.',
      ),
    ],
  ),
];
