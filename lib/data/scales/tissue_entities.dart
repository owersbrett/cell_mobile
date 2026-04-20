import 'package:cell_mobile/models/bio_entity.dart';

const tissueEntities = <BioEntity>[
  BioEntity(
    id: 'tissue_vascular',
    scale: BioScale.tissue,
    position: 0,
    name: 'Vascular Tissue',
    title: 'The Transport Network',
    shortDescription: 'The interconnected system of xylem and phloem that moves water, minerals, and sugars throughout the plant.',
    longDescription:
        'Vascular tissue is the plant\'s circulatory system — a continuous network of specialized cells that extends from root tips to leaf margins, connecting every part of the plant. It comprises two main tissue types: xylem (which carries water and dissolved minerals upward from the roots) and phloem (which distributes sugars and other organic compounds from photosynthetic tissues to the rest of the plant).\n\n'
        'In stems, vascular tissue is arranged in bundles. In dicots like tomatoes and soybeans, these bundles form a ring, with the vascular cambium (a meristematic tissue) between the xylem and phloem, allowing the stem to grow wider over time. In monocots like corn, wheat, and rice, the bundles are scattered throughout the stem, and there is no vascular cambium — which is why monocots don\'t produce wood.\n\n'
        'The evolution of vascular tissue was one of the most important innovations in plant history, allowing plants to grow tall and colonize dry land. In agriculture, vascular health determines how effectively nutrients and water reach developing fruits and seeds. Vascular wilt diseases (caused by fungi like Fusarium and Verticillium) are devastating because they block the xylem, cutting off water supply to the upper plant.',
    zoomInIds: ['cell_xylem_vessel', 'cell_phloem_sieve_tube'],
    zoomOutIds: ['organ_stem', 'organ_root', 'organ_leaf'],
    relatedIds: ['tissue_ground', 'tissue_dermal', 'organ_stem'],
  ),
  BioEntity(
    id: 'tissue_dermal',
    scale: BioScale.tissue,
    position: 1,
    name: 'Dermal Tissue',
    title: 'The Outer Shield',
    shortDescription: 'The protective outer layer of the plant that controls water loss, gas exchange, and defense against pathogens.',
    longDescription:
        'Dermal tissue forms the outer covering of every plant organ — the epidermis of leaves, stems, and roots, and the periderm (bark) of woody plants. In its simplest form, the epidermis is a single layer of cells coated with a waxy cuticle that prevents water loss. But this simple-sounding tissue contains a remarkable diversity of specialized cells.\n\n'
        'Guard cells and their stomata control gas exchange. Trichomes (leaf hairs) deter herbivores, reduce water loss, and in some species secrete aromatic oils or sticky substances. Root hairs extend the absorptive surface of roots. In older woody plants, the epidermis is replaced by periderm — layers of cork cells (dead at maturity) that protect the plant from desiccation, mechanical damage, and pathogens.\n\n'
        'In agriculture, dermal tissue properties directly influence crop performance. Cuticle thickness affects drought tolerance. Trichome density influences insect resistance — some tomato varieties have been bred with dense, sticky trichomes that trap small insect pests. The waxy bloom on grapes and blueberries is a cuticle modification that protects the fruit. Understanding dermal tissue helps breeders develop crops that are naturally more resistant to environmental stress.',
    zoomInIds: ['cell_guard', 'cell_root_hair'],
    zoomOutIds: ['organ_leaf', 'organ_stem', 'organ_root'],
    relatedIds: ['tissue_vascular', 'tissue_ground'],
  ),
  BioEntity(
    id: 'tissue_ground',
    scale: BioScale.tissue,
    position: 2,
    name: 'Ground Tissue',
    title: 'The Versatile Matrix',
    shortDescription: 'The bulk tissue that fills the space between dermal and vascular tissues, performing photosynthesis, storage, and support.',
    longDescription:
        'Ground tissue makes up the majority of a plant\'s body — everything that isn\'t dermal or vascular tissue. It comprises three cell types: parenchyma (the most common, with thin walls and living cytoplasm), collenchyma (with unevenly thickened walls for flexible support), and sclerenchyma (with thick, lignified walls for rigid support — usually dead at maturity).\n\n'
        'Parenchyma cells are the Swiss army knife of the plant kingdom. In leaves, they form the mesophyll where photosynthesis occurs. In stems and roots, they store starch and other reserves. In fruits, they fill with water and sugars to create the fleshy tissue we eat. They can even de-differentiate and become meristematic again, enabling wound healing and vegetative propagation. Collenchyma provides the flexible support found in celery stalks and leaf petioles. Sclerenchyma forms the hard shells of nuts, the gritty texture in pears, and the fibers in jute and hemp.\n\n'
        'In agriculture, ground tissue is often what we\'re actually harvesting. The starchy parenchyma of potatoes, the fleshy parenchyma of apples and tomatoes, the fiber sclerenchyma of cotton — these are all ground tissue. Understanding how these cells develop, fill with storage products, and respond to environmental conditions is central to improving crop quality and yield.',
    zoomInIds: ['cell_mesophyll'],
    zoomOutIds: ['organ_leaf', 'organ_stem', 'organ_root'],
    relatedIds: ['tissue_vascular', 'tissue_dermal', 'tissue_meristematic'],
  ),
  BioEntity(
    id: 'tissue_meristematic',
    scale: BioScale.tissue,
    position: 3,
    name: 'Meristematic Tissue',
    title: 'The Growth Engine',
    shortDescription: 'Perpetually dividing stem cells at growth points that generate all other tissues throughout the plant\'s life.',
    longDescription:
        'Meristematic tissue is the source of all plant growth — populations of undifferentiated, actively dividing cells that produce all the specialized tissues of the plant body. Unlike animals, which largely stop growing after reaching maturity, plants grow continuously from meristems throughout their lives. This is why a tree can keep getting taller and wider for centuries.\n\n'
        'There are several types of meristems. Apical meristems at the tips of roots and shoots drive primary growth (elongation). Lateral meristems (vascular cambium and cork cambium) drive secondary growth (widening) in woody plants. Intercalary meristems at the bases of grass leaves and stems allow grasses to regrow after being grazed or mowed — the biological basis of lawn mowing and livestock grazing.\n\n'
        'In agriculture, understanding meristems is critical for crop management. Pruning fruit trees manipulates apical dominance to promote lateral branching and fruit production. The fact that grasses grow from intercalary meristems (at the base, not the tip) is why cereals like wheat and rice can recover from grazing or hail damage that would kill dicot crops. Tissue culture and clonal propagation — techniques essential for producing virus-free seed potatoes and identical fruit tree rootstocks — rely on the ability of meristematic cells to regenerate entire plants.',
    zoomOutIds: ['organ_root', 'organ_stem'],
    relatedIds: ['tissue_ground', 'tissue_vascular', 'tissue_dermal'],
  ),
];
