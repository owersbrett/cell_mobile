import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

const organSystemEntities = <BioEntity>[
  BioEntity(
    id: 'organ_system_root',
    scale: BioScale.organSystem,
    position: 0,
    name: 'Root System',
    title: 'The Underground Network',
    shortDescription: 'The integrated below-ground system of primary roots, lateral roots, and root hairs that anchors the plant, absorbs water and nutrients, and reads the soil.',
    longDescription:
        'The root system is not a bundle of separate roots — it is one integrated organ system coordinating absorption, anchorage, storage, and communication across the whole underground half of the plant. Its architecture (the spatial arrangement of roots in soil) is set by both genetics and environment: the plant steers growth toward nutrient-rich patches and away from competitors, a behavior called foraging.\n\n'
        'The root tip is the plant\'s underground sense organ. It reads gravity, moisture, nutrient gradients, and even vibration, then integrates those signals to decide where to grow next. In agriculture, root depth and density often decide whether a crop shrugs off drought or fails — which is why modern breeding now selects for the hidden half of the plant, not just the visible one.',
    zoomInIds: ['organ_root'],
    zoomOutIds: ['organism_corn', 'organism_soybean', 'organism_wheat'],
    relatedIds: ['organ_system_vascular', 'organ_system_shoot', 'ecosystem_rhizosphere'],
    sections: [
      LessonSection.fact(
        title: 'The hidden surface area',
        body: 'A single rye plant can grow ~14 billion root hairs with a combined surface area of ~600 m² — more than two tennis courts of absorbing skin, all folded into a bucket of soil.',
      ),
      LessonSection.table(
        title: 'Two ways to build a root system',
        headers: ['System', 'Structure', 'Example crops', 'What it wins at'],
        rows: [
          ['Taproot', 'One dominant vertical root + laterals', 'Carrot, soybean, alfalfa', 'Deep water, storage, anchorage'],
          ['Fibrous', 'Many similar roots near the surface', 'Corn, wheat, rice (grasses)', 'Topsoil nutrients, erosion control'],
        ],
      ),
      LessonSection.table(
        title: 'Hormones that steer growth underground',
        headers: ['Signal', 'Effect on the root'],
        rows: [
          ['Auxin', 'Drives elongation and triggers lateral-root branching'],
          ['Cytokinin', 'Generally slows root growth (favors the shoot instead)'],
          ['Abscisic acid', 'The drought alarm — closes down growth, conserves water'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The energy question',
        question: 'Roots never photosynthesize, yet a plant may spend half its total sugar budget building them. Why is that a good trade?',
        answer: 'Because absorption, not sunlight, is usually the limiting resource. Leaves are useless if the roots can\'t deliver the water and minerals photosynthesis consumes. The root system is the plant\'s supply chain — and a factory with no supply chain produces nothing, no matter how much light hits the roof.',
      ),
      LessonSection.thinkReveal(
        title: 'Drought showdown',
        question: 'A drought hits. Deep taproot vs. shallow fibrous root — which crop survives, and why isn\'t the answer always "the deep one"?',
        answer: 'It depends on where the water is. A deep taproot reaches subsoil moisture that shallow roots never touch, so it wins a long dry spell. But if the drought is broken by light, frequent showers that only wet the top few centimeters, the shallow fibrous mat drinks it first and the taproot\'s depth is wasted. "Best" root depth is a bet on the rainfall pattern.',
      ),
    ],
  ),
  BioEntity(
    id: 'organ_system_shoot',
    scale: BioScale.organSystem,
    position: 1,
    name: 'Shoot System',
    title: 'The Solar Canopy',
    shortDescription: 'The above-ground system of stems, leaves, and buds that captures light, exchanges gases, and supports the plant\'s growth and reproduction.',
    longDescription:
        'The shoot system is everything above the soil — stems, leaves, buds, and their links — working as one light-harvesting and gas-exchange machine. Leaf arrangement (phyllotaxis) follows mathematical patterns, often Fibonacci spirals, that minimize self-shading so upper leaves don\'t steal all the light from lower ones.\n\n'
        'Shoot shape is governed by apical dominance: the terminal bud chemically suppresses the buds below it. Remove the tip — by pruning, grazing, or frost — and those lateral buds wake up and the plant bushes out. Farmers exploit this constantly, from pinching tomato suckers to topping tobacco, all to sculpt the canopy for maximum productive leaf area.',
    zoomInIds: ['organ_stem', 'organ_leaf'],
    zoomOutIds: ['organism_corn', 'organism_soybean', 'organism_wheat', 'organism_tomato'],
    relatedIds: ['organ_system_root', 'organ_system_vascular', 'organ_system_reproductive'],
    sections: [
      LessonSection.fact(
        title: 'The golden angle',
        body: 'Many plants space successive leaves ~137.5° apart around the stem — the "golden angle." No two leaves ever line up, so almost none sits directly in another\'s shadow.',
      ),
      LessonSection.table(
        title: 'Farming by hijacking apical dominance',
        headers: ['Practice', 'Crop', 'What it does to the shoot'],
        rows: [
          ['Pinching suckers', 'Tomato', 'Removes side shoots so energy goes to fruit'],
          ['Topping', 'Tobacco', 'Cuts the flower tip so leaves grow larger'],
          ['Hedging / pruning', 'Fruit trees', 'Forces branching for a fuller, reachable canopy'],
          ['Coppicing', 'Willow, hazel', 'Cut to the base; many new stems resprout'],
        ],
      ),
      LessonSection.paragraph(
        title: 'A canopy is a compromise',
        body: 'The shoot solves competing engineering problems at once: maximize leaf area for photosynthesis, but minimize water lost through those same leaves; grow tall to win light, but stay light enough not to topple; be stiff enough to stand, flexible enough to bend in wind. The answer is a tuned hierarchy of stems, branches, and leaves with controlled spacing, angles, and sizes.',
      ),
      LessonSection.thinkReveal(
        title: 'Why spiral, not stack?',
        question: 'If a plant just stacked each new leaf directly above the last, that would be simpler to build. Why spiral them at an odd angle instead?',
        answer: 'Stacked leaves would shade each other completely — every leaf below the top would sit in permanent shadow. Offsetting each leaf by an irrational fraction of a turn (the golden angle) guarantees new leaves keep landing in the gaps, so light reaches deep into the canopy. Simplicity would cost the plant most of its photosynthesis.',
      ),
      LessonSection.thinkReveal(
        title: 'The pruning paradox',
        question: 'You cut the top bud off a plant and it grows bushier, not shorter. What did removing one bud actually change?',
        answer: 'You removed the plant\'s main source of auxin, the hormone the tip uses to keep lower buds dormant. With that suppression lifted, the sleeping lateral buds activate and grow, so the plant fills out sideways. You didn\'t stop growth — you released it in every direction at once.',
      ),
    ],
  ),
  BioEntity(
    id: 'organ_system_vascular',
    scale: BioScale.organSystem,
    position: 2,
    name: 'Vascular System',
    title: 'The Living Pipeline',
    shortDescription: 'The continuous network of xylem and phloem that moves water, minerals, sugars, and signaling molecules throughout the entire plant body.',
    longDescription:
        'The vascular system is the plant\'s circulation — a continuous network of xylem (water and minerals upward) and phloem (sugars from where they\'re made to where they\'re used) linking every organ from root tip to leaf edge. There is no heart: xylem is pulled upward by water evaporating from leaves (transpiration pull), while phloem is pushed by osmotic pressure differences between sugar sources and sinks.\n\n'
        'It carries far more than bulk cargo. Hormones, wound signals, and even small RNA molecules ride the vascular network, making it a plant-wide communication system as well as a plumbing one. In trees, the xylem accumulates year after year as wood, the structural record that lets a plant stand hundreds of feet tall for thousands of years.',
    zoomInIds: ['organ_stem', 'organ_root'],
    zoomOutIds: ['organism_corn', 'organism_wheat', 'organism_rice'],
    relatedIds: ['organ_system_root', 'organ_system_shoot', 'tissue_vascular'],
    sections: [
      LessonSection.fact(
        title: 'Water without a pump',
        body: 'The tallest redwoods lift water ~115 m from soil to crown with no moving parts — powered entirely by evaporation at the leaves and the cohesion of water columns holding together under tension.',
      ),
      LessonSection.table(
        title: 'Xylem vs. phloem — two pipes, opposite jobs',
        headers: ['Feature', 'Xylem', 'Phloem'],
        rows: [
          ['Cargo', 'Water + dissolved minerals', 'Sugars, hormones, signal RNA'],
          ['Direction', 'Mostly up, roots → leaves', 'Source → sink (either way)'],
          ['Driving force', 'Transpiration pull (tension)', 'Osmotic pressure gradient'],
          ['Cell state', 'Dead, hollow at maturity', 'Living cells'],
        ],
      ),
      LessonSection.paragraph(
        title: 'Wood is old plumbing',
        body: 'In woody plants, each year\'s new xylem is laid down as a ring and never removed. Only the outer rings still conduct water; the inner heartwood is retired plumbing repurposed as structure. A tree trunk is therefore a stack of former pipelines — which is exactly why counting rings counts years.',
      ),
      LessonSection.thinkReveal(
        title: 'The heartless climb',
        question: 'Animals need a muscular heart to push blood a few feet. A tree moves water 100 m straight up with no pump at all. How?',
        answer: 'Evaporation from leaf pores puts the water column under tension, and water molecules cling to each other (cohesion) and to the vessel walls (adhesion) strongly enough to be dragged up as one continuous thread. The "engine" is sunlight evaporating water at the top, not a pump at the bottom — the plant pulls its water up rather than pushing it.',
      ),
      LessonSection.thinkReveal(
        title: 'Dead pipe, living pipe',
        question: 'Xylem cells are dead at maturity, but phloem cells must stay alive. Why the opposite requirement for two pipes side by side?',
        answer: 'Xylem is a passive channel — the emptier and more hollow, the better it flows, so its cells die and dissolve their contents to leave a clean tube. Phloem must actively load sugar in at the source and unload it at the sink, pumping against gradients; that constant metabolic work needs living, energy-burning cells. Function dictates whether a cell is better off dead or alive.',
      ),
    ],
  ),
  BioEntity(
    id: 'organ_system_reproductive',
    scale: BioScale.organSystem,
    position: 3,
    name: 'Reproductive System',
    title: 'The Next Generation',
    shortDescription: 'The integrated system of flowers, fruits, and seeds that drives genetic recombination, seed development, and dispersal of the next generation.',
    longDescription:
        'The reproductive system of flowering plants ties flowers (pollination and fertilization), fruits (seed protection and dispersal), and seeds (embryo survival and germination) into one coordinated system for continuing the species. Unlike animals, plants can reproduce both sexually through seeds and asexually through runners, tubers, bulbs, or cuttings — and many crops exploit both.\n\n'
        'Timing is everything and it is tightly controlled. Leaves and shoot tips read day length (photoperiod) and cold exposure (vernalization), then send a mobile flowering signal, florigen, through the phloem to the meristems, which switch from making leaves to making flowers. In agriculture, this system is literally the harvest: grain, fruit, and even broccoli are all reproductive structures we intercept.',
    zoomInIds: ['organ_flower', 'organ_fruit', 'organ_seed'],
    zoomOutIds: ['organism_corn', 'organism_soybean', 'organism_tomato'],
    relatedIds: ['organ_system_shoot', 'organ_system_vascular', 'ecosystem_pollination'],
    sections: [
      LessonSection.fact(
        title: 'The pollinator dependency',
        body: '~75% of the world\'s leading food crop types benefit from animal pollination — meaning a huge share of the human diet rides on a reproductive system the plant can\'t complete alone.',
      ),
      LessonSection.table(
        title: 'Two reproductive strategies, one plant',
        headers: ['Mode', 'Mechanism', 'Crop examples', 'The trade-off'],
        rows: [
          ['Sexual', 'Seeds from pollen + egg', 'Corn, wheat, tomato', 'New genetic variation, but slower and uncertain'],
          ['Asexual', 'Runners, tubers, cuttings', 'Potato, strawberry, banana', 'Fast, true-to-parent clones, but no new variation'],
        ],
      ),
      LessonSection.table(
        title: 'The harvest is a reproductive organ',
        headers: ['Crop', 'What we actually eat'],
        rows: [
          ['Wheat, corn, rice', 'Seeds (the grain)'],
          ['Tomato, apple', 'Fruit — the mature ovary'],
          ['Broccoli, artichoke', 'Flower buds, harvested before they open'],
          ['Sunflower', 'Seeds packed in the flower head'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Flowering by remote control',
        question: 'The meristem that turns into a flower has no way to sense the seasons itself. So how does a plant "know" it\'s the right time to bloom?',
        answer: 'The sensing happens elsewhere: leaves measure day length and tissues track accumulated cold. When conditions are right, the leaves produce florigen, a mobile signal that travels through the phloem to the meristem and flips it from vegetative to reproductive. The decision is made in the leaves and delivered as a message — the flower just receives the order.',
      ),
      LessonSection.thinkReveal(
        title: 'The great reallocation',
        question: 'When an annual crop flips to reproduction, the whole plant seems to sacrifice itself into the seeds. Why does going reproductive so often mean dying?',
        answer: 'Setting seed is enormously expensive, so the plant strip-mines itself to pay for it — sugars, nitrogen, and minerals are pulled out of leaves and stems and poured into filling seeds. In monocarpic plants that reproduce once, this reallocation is terminal: the parent spends its entire body on the next generation, then senesces. From the gene\'s point of view, the seeds are the point; the parent is packaging.',
      ),
    ],
  ),
];
