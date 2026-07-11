import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

const tissueEntities = <BioEntity>[
  BioEntity(
    id: 'tissue_vascular',
    scale: BioScale.tissue,
    position: 0,
    name: 'Vascular Tissue',
    title: 'The Transport Network',
    shortDescription: 'The interconnected system of xylem and phloem that moves water, minerals, and sugars throughout the plant.',
    longDescription:
        'Vascular tissue is the plant\'s circulatory system — a continuous network of specialized cells reaching from root tips to leaf margins. It splits into two plumbing systems: xylem carries water and dissolved minerals upward from the roots, and phloem distributes sugars made in photosynthetic tissues to wherever the plant is growing or storing.\n\n'
        'The evolution of vascular tissue was one of the great turning points in plant history: it let plants stiffen, grow tall, and colonize dry land. In stems the tissue runs in bundles whose arrangement separates the two great flowering-plant lineages, and its health decides how well water and nutrients reach developing fruit — which is why xylem-clogging wilt diseases are so deadly.',
    zoomInIds: ['cell_xylem_vessel', 'cell_phloem_sieve_tube'],
    zoomOutIds: ['organ_stem', 'organ_root', 'organ_leaf'],
    relatedIds: ['tissue_ground', 'tissue_dermal', 'organ_stem'],
    sections: [
      LessonSection.table(
        title: 'Two pipelines, opposite jobs',
        headers: ['', 'Xylem', 'Phloem'],
        rows: [
          ['Carries', 'Water + minerals', 'Sugars + organics'],
          ['Direction', 'Mostly upward', 'Source to sink (either way)'],
          ['Cells at maturity', 'Dead, hollow', 'Living (no nucleus)'],
          ['Driven by', 'Transpiration pull', 'Active pressure-flow'],
        ],
      ),
      LessonSection.table(
        title: 'Stem layout: dicot vs monocot',
        headers: ['Trait', 'Dicot', 'Monocot'],
        rows: [
          ['Bundle pattern', 'Ring', 'Scattered'],
          ['Vascular cambium', 'Present', 'Absent'],
          ['Makes wood', 'Yes', 'No'],
          ['Examples', 'Tomato, soybean', 'Corn, wheat, rice'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The wilt paradox',
        question:
            'A fungus like Fusarium clogs only the xylem, never the phloem. Why does the whole plant wilt and die anyway?',
        answer:
            'Xylem is the only water pipeline the plant has. Block it and the leaves keep transpiring but get no replacement water, so they lose turgor and collapse. The plant effectively dies of thirst even though its sugar-carrying phloem is completely intact — cutting the water line starves everything above the blockage.',
      ),
      LessonSection.thinkReveal(
        title: 'Why one dies and one must live',
        question:
            'Xylem does its job dead and hollow; phloem has to stay alive. Why the opposite requirement?',
        answer:
            'Xylem is passive plumbing — water is pulled through it by evaporation at the leaves, so empty dead tubes with no cytoplasm in the way move water fastest. Phloem instead pushes sugars using active, energy-hungry pressure-flow, so its sieve tubes must stay alive, leaning on neighboring companion cells for the metabolism they gave up.',
      ),
      LessonSection.fact(
        title: 'Pumpless climb',
        body:
            'Water can rise more than ~100 m up the xylem of the tallest trees — with no pump at all, driven purely by evaporation from the leaves.',
      ),
    ],
  ),
  BioEntity(
    id: 'tissue_dermal',
    scale: BioScale.tissue,
    position: 1,
    name: 'Dermal Tissue',
    title: 'The Outer Shield',
    shortDescription: 'The protective outer layer of the plant that controls water loss, gas exchange, and defense against pathogens.',
    longDescription:
        'Dermal tissue is the plant\'s outer covering — the epidermis of leaves, stems, and roots, and the periderm (bark) of woody plants. At its simplest the epidermis is a single layer of cells sealed by a waxy cuticle that blocks water loss, but that thin skin hides a surprising diversity of specialized cells.\n\n'
        'Guard cells, trichomes, root hairs, and cork cells each turn the covering into an active organ — regulating gas exchange, fending off herbivores, drinking in water, and armoring old wood. Its exact properties, from cuticle thickness to trichome density, translate directly into how well a crop tolerates drought and resists pests.',
    zoomInIds: ['cell_guard', 'cell_root_hair'],
    zoomOutIds: ['organ_leaf', 'organ_stem', 'organ_root'],
    relatedIds: ['tissue_vascular', 'tissue_ground'],
    sections: [
      LessonSection.table(
        title: 'Specialists in the skin',
        headers: ['Cell / structure', 'Job'],
        rows: [
          ['Guard cells', 'Open and close stomata for gas exchange'],
          ['Trichomes (hairs)', 'Deter herbivores, cut water loss'],
          ['Root hairs', 'Extend the absorptive surface of roots'],
          ['Cork (periderm)', 'Waterproof, dead armor on woody stems'],
        ],
      ),
      LessonSection.table(
        title: 'Dermal trait to crop payoff',
        headers: ['Feature', 'Crop effect'],
        rows: [
          ['Thick cuticle', 'Drought tolerance'],
          ['Dense sticky trichomes', 'Insect resistance'],
          ['Waxy bloom', 'Protected fruit (grapes, blueberries)'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The sealed leaf that still breathes',
        question:
            'The cuticle blocks water from escaping the leaf. So how does the leaf still take in the CO2 it needs for photosynthesis?',
        answer:
            'Through stomata — adjustable pores flanked by guard cells that punch through the otherwise sealed epidermis. This forces a constant trade-off: open the stomata to admit CO2 and the plant loses water; close them to conserve water and photosynthesis stalls. Guard cells manage that dilemma minute by minute.',
      ),
      LessonSection.thinkReveal(
        title: 'Armor made of corpses',
        question:
            'Cork cells are dead at maturity, yet they are the plant\'s best defense. How can dead cells protect anything?',
        answer:
            'Their protection is structural, not active. As cork cells die they leave behind walls soaked in suberin, a waxy waterproof polymer. Stacked in dense layers, these dead husks form a barrier against water loss, pathogens, and physical damage — armor does not need to be alive to work.',
      ),
      LessonSection.fact(
        title: 'One cell thick',
        body:
            'The epidermis is often just a single cell thick — one layer of cells standing between the plant\'s entire interior and the outside world.',
      ),
    ],
  ),
  BioEntity(
    id: 'tissue_ground',
    scale: BioScale.tissue,
    position: 2,
    name: 'Ground Tissue',
    title: 'The Versatile Matrix',
    shortDescription: 'The bulk tissue that fills the space between dermal and vascular tissues, performing photosynthesis, storage, and support.',
    longDescription:
        'Ground tissue is everything that isn\'t dermal or vascular — the bulk of the plant body. It is built from three cell types: parenchyma (thin-walled and living), collenchyma (unevenly thickened for flexible support), and sclerenchyma (thick, lignified, and usually dead at maturity).\n\n'
        'Parenchyma is the versatile workhorse: it runs photosynthesis in leaves, stockpiles starch in roots and tubers, and swells with water and sugar in fruit. Much of what we actually harvest — potato flesh, apple pulp, cotton fiber — is simply ground tissue, so how these cells develop and fill sits at the center of crop quality and yield.',
    zoomInIds: ['cell_mesophyll'],
    zoomOutIds: ['organ_leaf', 'organ_stem', 'organ_root'],
    relatedIds: ['tissue_vascular', 'tissue_dermal', 'tissue_meristematic'],
    sections: [
      LessonSection.table(
        title: 'The three ground-tissue cells',
        headers: ['Cell type', 'Wall', 'Alive?', 'Job'],
        rows: [
          ['Parenchyma', 'Thin', 'Yes', 'Photosynthesis, storage'],
          ['Collenchyma', 'Unevenly thick', 'Yes', 'Flexible support'],
          ['Sclerenchyma', 'Thick, lignified', 'No', 'Rigid support'],
        ],
      ),
      LessonSection.table(
        title: 'What we eat is ground tissue',
        headers: ['Crop / product', 'Tissue'],
        rows: [
          ['Potato flesh', 'Storage parenchyma'],
          ['Apple, tomato flesh', 'Fleshy parenchyma'],
          ['Celery strings', 'Collenchyma'],
          ['Pear grit, nut shell', 'Sclerenchyma'],
          ['Cotton, hemp fiber', 'Sclerenchyma fibers'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Strength through dying',
        question:
            'Sclerenchyma gives the strongest support of the three cell types, yet it is dead. Why is dying part of its job?',
        answer:
            'Its strength comes from thick walls hardened with lignin. Once those walls are fully built, the living cytoplasm inside would only get in the way, so the cell dissolves it and dies, leaving a hollow rigid box. Wood, nut shells, and plant fibers are all these dead reinforced husks — support engineered to outlast the cell that made it.',
      ),
      LessonSection.thinkReveal(
        title: 'The potato that becomes a plant',
        question:
            'Cut a potato, keep a piece with an eye, plant it, and a whole new plant grows. Which property of ground tissue makes that possible?',
        answer:
            'Parenchyma cells stay alive and keep a full nucleus, so unlike specialized dead cells they can de-differentiate — revert to a dividing, meristem-like state. That is what lets them heal wounds and regrow entire plants, and it is exactly why seed potatoes, cuttings, and grafts work at all.',
      ),
      LessonSection.fact(
        title: 'Mostly one humble cell',
        body:
            'Most of the mass of a potato, an apple, or a tomato is a single unglamorous cell type: parenchyma.',
      ),
    ],
  ),
  BioEntity(
    id: 'tissue_meristematic',
    scale: BioScale.tissue,
    position: 3,
    name: 'Meristematic Tissue',
    title: 'The Growth Engine',
    shortDescription: 'Perpetually dividing stem cells at growth points that generate all other tissues throughout the plant\'s life.',
    longDescription:
        'Meristematic tissue is the source of all plant growth — populations of undifferentiated, endlessly dividing cells that manufacture every specialized tissue in the plant. Unlike animals, which mostly stop growing at maturity, plants keep growing from their meristems for as long as they live.\n\n'
        'Different meristems do different jobs: apical meristems at root and shoot tips drive elongation, lateral meristems widen woody plants, and intercalary meristems at the base of grass leaves let cereals and lawns regrow after cutting. Understanding them underpins pruning, grazing recovery, and the tissue culture that produces virus-free seed potatoes and identical rootstocks.',
    zoomOutIds: ['organ_root', 'organ_stem'],
    relatedIds: ['tissue_ground', 'tissue_vascular', 'tissue_dermal'],
    sections: [
      LessonSection.table(
        title: 'Types of meristem',
        headers: ['Meristem', 'Location', 'Growth it drives'],
        rows: [
          ['Apical', 'Root & shoot tips', 'Primary (longer, taller)'],
          ['Lateral (cambium)', 'Cylinders in stem/root', 'Secondary (wider, wood)'],
          ['Intercalary', 'Base of grass leaves', 'Regrowth after grazing'],
        ],
      ),
      LessonSection.table(
        title: 'Meristems at work on the farm',
        headers: ['Practice', 'Meristem principle'],
        rows: [
          ['Pruning fruit trees', 'Break apical dominance for more branches'],
          ['Mowing / grazing', 'Intercalary regrowth survives cutting'],
          ['Tissue culture', 'Meristem cells regrow whole plants'],
          ['Virus-free seed potato', 'Clean meristem tip is cultured out'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why the lawn wins',
        question:
            'Mow a lawn and the grass grows back; snip a tomato plant\'s tip and that shoot stops growing taller. Why the difference?',
        answer:
            'Grasses keep their growth zone (the intercalary meristem) at the base of the leaf, below the mower blade, so cutting the top removes only mature tissue and the plant regrows from underneath. A dicot\'s growth zone is the apical meristem at the very tip — cut that off and you have removed the growth engine itself.',
      ),
      LessonSection.thinkReveal(
        title: 'Growth without end',
        question:
            'Animals reach an adult size and stop; a redwood keeps getting bigger for a thousand years. What lets plants grow indefinitely?',
        answer:
            'Plants hold permanent reserves of undifferentiated dividing cells — meristems — at their tips and in their cambium, so there is always a fresh supply of cells to add. Most animals commit nearly all their cells to specialized roles and retire their stem cells to repair duty, which caps growth at maturity.',
      ),
      LessonSection.fact(
        title: 'The engine that outlives the planter',
        body:
            'A single apical meristem can keep dividing for centuries — the growth engine behind trees that outlive the humans who planted them.',
      ),
    ],
  ),
];
