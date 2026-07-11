import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Tissue module: "Animal Tissues" — the four tissue families of animals.
/// (Authored by module agent.)
const List<BioEntity> tissueAnimalEntities = <BioEntity>[
  BioEntity(
    id: 'tissue_animal_four_types',
    scale: BioScale.tissue,
    position: 0,
    name: 'The Four Tissue Types',
    title: 'Only Four Fabrics',
    moduleId: 'tissue_animal',
    shortDescription:
        'Every animal, from a flatworm to a blue whale, is woven from just four kinds of tissue.',
    longDescription:
        'A tissue is a group of similar cells that cooperate on one job. It is the layer between a single cell and a whole organ — cells that have agreed to specialize together.\n\n'
        'The astonishing part: no matter how complex the animal, everything is built from exactly four tissue families. Epithelial covers and lines. Connective supports and connects. Muscle moves. Nervous signals. Learn these four and you can read any body plan.',
    relatedIds: [
      'tissue_animal_epithelial',
      'tissue_animal_connective',
      'tissue_animal_muscle',
      'tissue_animal_nervous',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Cut into any part of any animal and the tissue you find falls into one of four bins. Skin, gut lining, and gland — epithelial. Bone, blood, fat, tendon — connective. Anything that contracts — muscle. Anything that fires a signal — nervous. Four fabrics, endless tailoring.',
      ),
      LessonSection.thinkReveal(
        title: 'Predict it',
        question:
            'The inside of your cheek, the outer layer of your skin, and the lining of your stomach all feel very different. What single tissue family do all three belong to?',
        answer:
            'Epithelial. All three are sheets of tightly packed cells that form a covering or lining over a surface — that is the defining job of epithelial tissue, whatever it happens to be covering.',
      ),
      LessonSection.table(
        title: 'The four families at a glance',
        headers: ['Tissue', 'Core job', 'A classic example'],
        rows: [
          ['Epithelial', 'Cover, line, secrete', 'Skin surface, gut lining'],
          ['Connective', 'Support, bind, store', 'Bone, tendon, fat, blood'],
          ['Muscle', 'Contract to move', 'Biceps, heart, gut wall'],
          ['Nervous', 'Sense & signal fast', 'Brain, spinal cord, nerves'],
        ],
      ),
      LessonSection.fact(
        title: 'Four — that is all',
        body:
            'Four tissue types build the entire animal kingdom. The complexity of a body comes from how they are arranged, not from a large parts list.',
      ),
    ],
  ),
  BioEntity(
    id: 'tissue_animal_epithelial',
    scale: BioScale.tissue,
    position: 1,
    name: 'Epithelial Tissue',
    title: 'The Body\'s Wrapping',
    moduleId: 'tissue_animal',
    shortDescription:
        'Tightly packed cells forming every sheet, barrier, and gland — the frontier where inside meets outside.',
    longDescription:
        'Epithelial cells sit shoulder to shoulder with almost no space between them, glued by junctions into continuous sheets. Every free surface of the body — skin, the inside of your lungs, the lining of your blood vessels and gut — is epithelium.\n\n'
        'One side always faces open space (air, fluid, or a lumen); the other rests on a thin basement membrane. That polarity lets epithelium act as a gatekeeper: it decides what crosses. Fold a sheet inward and you get a gland, an epithelium specialized to secrete.',
    relatedIds: ['tissue_animal_four_types', 'tissue_animal_connective'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'You could not survive a minute without epithelium: it is the barrier keeping your insides in and the world out. It is also avascular — it has no blood vessels of its own — so it feeds by diffusion from the connective tissue underneath. That dependence is a theme you will meet again.',
      ),
      LessonSection.table(
        title: 'Named by shape and layering',
        headers: ['Cell shape', 'Layering', 'Where it shines'],
        rows: [
          ['Squamous (flat)', 'Simple (one layer)', 'Air sacs, capillary walls — thin for exchange'],
          ['Cuboidal', 'Simple', 'Kidney tubules, gland ducts'],
          ['Columnar (tall)', 'Simple', 'Stomach & intestine — secretion and absorption'],
          ['Squamous', 'Stratified (many layers)', 'Skin surface — protection against abrasion'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why so many layers on skin?',
        question:
            'Your outer skin is stratified (piled many cells deep), but your lung air sacs are a single flat layer. Why the opposite designs?',
        answer:
            'Function dictates form. Skin must resist abrasion, so it stacks layers as a shield and constantly sheds the worn top ones. Lung air sacs must let oxygen cross fast, so they stay a single flat (squamous) layer — the thinner the barrier, the faster diffusion.',
      ),
      LessonSection.fact(
        title: 'Glands are folded epithelium',
        body:
            'Every gland in your body — sweat, salivary, thyroid, pancreas — began as an epithelial sheet that dimpled inward and specialized to secrete.',
      ),
    ],
  ),
  BioEntity(
    id: 'tissue_animal_connective',
    scale: BioScale.tissue,
    position: 2,
    name: 'Connective Tissue',
    title: 'Cells Adrift in Matrix',
    moduleId: 'tissue_animal',
    shortDescription:
        'The biggest, most diverse family — defined not by its cells but by the matrix they float in.',
    longDescription:
        'Flip epithelium on its head and you get connective tissue. Where epithelial cells crowd together, connective cells are sparse — scattered inside a large volume of extracellular matrix they secrete around themselves. That matrix, not the cells, is the point.\n\n'
        'The matrix is protein fibers (mostly collagen, plus stretchy elastin) suspended in a ground substance that can be watery, jelly, rubbery, or rock-hard. Change the matrix and you change everything: loose packing material, tough tendon, springy cartilage, solid bone, or even liquid blood.',
    relatedIds: [
      'tissue_animal_blood_bone',
      'tissue_animal_epithelial',
      'tissue_animal_four_types',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'The secret to understanding connective tissue is one idea: the matrix defines the material. Same basic cast of cells and collagen fibers — but tune the ground substance from liquid to jelly to mineralized solid, and you go from blood to cartilage to bone. It is one family wearing many disguises.',
      ),
      LessonSection.table(
        title: 'One family, wildly different matrices',
        headers: ['Type', 'Matrix character', 'Job'],
        rows: [
          ['Loose (areolar)', 'Soft, gel-like, loose fibers', 'Packs and cushions between organs'],
          ['Adipose (fat)', 'Cells fat-stuffed, little matrix', 'Stores energy, insulates'],
          ['Dense (tendon)', 'Packed parallel collagen', 'Ties muscle to bone, resists pull'],
          ['Cartilage', 'Firm rubbery gel', 'Smooth joint surfaces, ears, nose'],
          ['Bone', 'Collagen hardened with mineral', 'Rigid frame, protection'],
          ['Blood', 'Liquid plasma', 'Transport'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'What actually makes it "connective"?',
        question:
            'Fat, tendon, and bone look nothing alike. What shared feature puts all three in the same tissue family?',
        answer:
            'Their cells are spread thinly through a large extracellular matrix they produce. The defining trait of connective tissue is that the matrix — the fibers and ground substance between cells — does the structural work, not tight cell-to-cell packing.',
      ),
      LessonSection.fact(
        title: 'Collagen: the rope of the body',
        body:
            'Collagen is the most abundant protein in your body — roughly a third of all your protein. It is the structural fiber running through nearly every connective tissue.',
      ),
    ],
  ),
  BioEntity(
    id: 'tissue_animal_blood_bone',
    scale: BioScale.tissue,
    position: 3,
    name: 'Blood & Bone',
    title: 'The Surprising Connectives',
    moduleId: 'tissue_animal',
    shortDescription:
        'Yes — flowing blood and rock-hard bone are both connective tissue. The matrix explains why.',
    longDescription:
        'This is where connective tissue trips people up. Blood is a connective tissue: red and white cells (and platelets) scattered in a liquid matrix called plasma. The "fibers" only appear on demand, when clotting proteins weave a mesh to seal a wound.\n\n'
        'Bone is connective tissue too. Its cells (osteocytes) sit in a matrix of collagen fibers hardened by calcium-phosphate mineral — collagen gives bone tension-resistance while the mineral gives it compression-resistance. Same connective blueprint, opposite extremes of the matrix: one liquid, one stone.',
    relatedIds: ['tissue_animal_connective', 'tissue_animal_four_types'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Ask most people to name a connective tissue and they will say a tendon or a ligament. Almost nobody says blood — yet blood is the textbook case. Once you accept that the matrix can be a liquid, the whole family finally makes sense.',
      ),
      LessonSection.thinkReveal(
        title: 'Liquid vs. stone',
        question:
            'Blood flows and bone is rigid — biological opposites. How can the same tissue family contain both?',
        answer:
            'Because "connective" is about cells scattered in a matrix, and the matrix can be anything. In blood the matrix is liquid plasma; in bone it is collagen mineralized with calcium phosphate. Change the matrix state and you swing from a flowing fluid to a load-bearing solid — same design principle, opposite matrix.',
      ),
      LessonSection.table(
        title: 'Blood and bone, side by side',
        headers: ['Feature', 'Blood', 'Bone'],
        rows: [
          ['Matrix', 'Liquid plasma', 'Collagen + calcium-phosphate mineral'],
          ['Main cells', 'Red & white cells, platelets', 'Osteocytes'],
          ['Fibers', 'Only when clotting (fibrin)', 'Collagen, permanent'],
          ['Core job', 'Transport O2, cells, nutrients', 'Support, protect, store calcium'],
        ],
      ),
      LessonSection.fact(
        title: 'Bone is a mineral bank',
        body:
            'About 99% of the body\'s calcium is stored in bone. When blood calcium runs low, bone is broken down to release it — the skeleton is a living reservoir, not dead scaffolding.',
      ),
    ],
  ),
  BioEntity(
    id: 'tissue_animal_muscle',
    scale: BioScale.tissue,
    position: 4,
    name: 'Muscle Tissue',
    title: 'Tissue That Pulls',
    moduleId: 'tissue_animal',
    shortDescription:
        'The only tissue that can shorten on command — and it comes in three distinct flavors.',
    longDescription:
        'Muscle is the movement tissue. Its cells are packed with overlapping protein filaments (actin and myosin) that ratchet past one another, shortening the cell — that is a contraction. Nothing else in the body can do this.\n\n'
        'There are three types. Skeletal muscle moves your bones on command. Cardiac muscle is the heart, beating on its own. Smooth muscle lines your hollow organs, squeezing without you ever noticing. They differ in control, appearance, and cell shape.',
    relatedIds: ['tissue_animal_nervous', 'tissue_animal_four_types'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Two of the three muscle types are working right now without your permission: your heart is pumping (cardiac) and your gut is pushing food along (smooth). Only skeletal muscle waits for your say-so — and "striated" (striped under the microscope) is the visible signature of the aligned filaments doing the pulling.',
      ),
      LessonSection.table(
        title: 'The three muscle types',
        headers: ['Type', 'Control', 'Striated?', 'Cell shape / nuclei', 'Where'],
        rows: [
          ['Skeletal', 'Voluntary', 'Yes', 'Long, multinucleate fibers', 'Attached to bones'],
          ['Cardiac', 'Involuntary', 'Yes', 'Branched, usually one nucleus', 'Heart only'],
          ['Smooth', 'Involuntary', 'No', 'Tapered spindle, one nucleus', 'Gut, vessels, bladder'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Spot the muscle',
        question:
            'A slide shows branched, striated cells joined end to end, each with a single nucleus, contracting rhythmically on its own. Which muscle type — and where in the body?',
        answer:
            'Cardiac muscle — found only in the heart. Branching plus striations plus a single nucleus plus self-driven rhythmic beating is the unique fingerprint of cardiac tissue. Skeletal fibers are long and multinucleate; smooth cells are spindle-shaped and non-striated.',
      ),
      LessonSection.fact(
        title: 'One heart, no rest',
        body:
            'Cardiac muscle contracts roughly 100,000 times a day, every day of your life, without ever taking a break — a feat no skeletal muscle could survive.',
      ),
    ],
  ),
  BioEntity(
    id: 'tissue_animal_nervous',
    scale: BioScale.tissue,
    position: 5,
    name: 'Nervous Tissue',
    title: 'The Wiring',
    moduleId: 'tissue_animal',
    shortDescription:
        'Neurons that fire electrical signals — plus the glia that keep them alive. Together, a tissue.',
    longDescription:
        'Nervous tissue is the body\'s fast communication network. Its star cells, neurons, carry electrical signals along long fibers and hand them off to the next cell at junctions called synapses. Brain, spinal cord, and nerves are all nervous tissue.\n\n'
        'But neurons are only half the story. The other half is neuroglia (glial cells) — support cells that outnumber neurons, insulate their fibers, feed them, and clean up around them. A neuron alone is not a tissue; neurons and glia together are.',
    relatedIds: ['tissue_animal_muscle', 'tissue_animal_four_types'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'When you touch a hot stove and yank your hand back before you even feel pain, that is nervous tissue racing electricity down a wire faster than thought. Signals can travel over 100 meters per second — chemistry pretending to be electronics.',
      ),
      LessonSection.thinkReveal(
        title: 'Is a single neuron a tissue?',
        question:
            'People call the brain "nervous tissue," but a lone neuron is just one cell. What else must be present for it to count as a tissue?',
        answer:
            'The supporting glia. A tissue is a cooperating group of cells, and nervous tissue is neurons plus neuroglia (glial cells) working together. Glia insulate axons, supply nutrients, and clear waste — without them neurons cannot function, so the tissue is the partnership, not the neuron alone.',
      ),
      LessonSection.table(
        title: 'Two cell classes, one tissue',
        headers: ['Cell class', 'Role'],
        rows: [
          ['Neuron', 'Receives, conducts, and transmits electrical signals'],
          ['Neuroglia (glia)', 'Insulate, nourish, support, and defend neurons'],
        ],
      ),
      LessonSection.fact(
        title: 'Glia outnumber neurons',
        body:
            'In the human brain, glial cells roughly equal or outnumber neurons — the "support staff" is at least as numerous as the signaling cells they serve.',
      ),
    ],
  ),
  BioEntity(
    id: 'tissue_animal_how_tissues_form',
    scale: BioScale.tissue,
    position: 6,
    name: 'How Tissues Form',
    title: 'From One Cell to Four Fabrics',
    moduleId: 'tissue_animal',
    shortDescription:
        'Every tissue traces back to a single fertilized cell, sorted into three germ layers, then specialized.',
    longDescription:
        'You began as one cell. It divided into a ball of identical stem cells — cells that can still become anything. Then, early in development, that ball folded into three sheets called germ layers: ectoderm (outer), mesoderm (middle), and endoderm (inner).\n\n'
        'From those three layers, every tissue is built through differentiation — cells switching on specific genes to commit to one job and shut the other options off. Ectoderm becomes skin and nervous tissue; mesoderm becomes muscle, bone, blood, and connective tissue; endoderm becomes the linings of the gut and lungs.',
    relatedIds: ['tissue_animal_four_types', 'tissue_animal_tissue_breaks'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'A skin cell and a heart cell carry the exact same DNA — yet they behave nothing alike. Differentiation is the answer: cells do not lose genes, they silence most of them and keep only the set their job needs. Same book, different chapters read aloud.',
      ),
      LessonSection.table(
        title: 'The three germ layers and what they make',
        headers: ['Germ layer', 'Position', 'Gives rise to'],
        rows: [
          ['Ectoderm', 'Outer', 'Skin surface, nervous tissue'],
          ['Mesoderm', 'Middle', 'Muscle, bone, blood, connective tissue'],
          ['Endoderm', 'Inner', 'Linings of gut, lungs, and glands'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Where does the brain come from?',
        question:
            'The brain and the outer skin seem worlds apart. Would you guess they share a germ-layer origin?',
        answer:
            'Yes — both come from ectoderm, the outermost germ layer. Early in development a strip of ectoderm folds inward to form the nervous system, which is why your skin and your brain are developmental siblings.',
      ),
      LessonSection.fact(
        title: 'Three layers, whole body',
        body:
            'Just three germ layers — ectoderm, mesoderm, endoderm — laid down in the first weeks of development give rise to every one of the four tissue types.',
      ),
    ],
  ),
  BioEntity(
    id: 'tissue_animal_tissue_breaks',
    scale: BioScale.tissue,
    position: 7,
    name: 'When Tissue Breaks',
    title: 'Healing, Scars & Rebellion',
    moduleId: 'tissue_animal',
    shortDescription:
        'How tissue repairs, why scars are a compromise, and what cancer is: tissue that forgot the rules.',
    longDescription:
        'Tissues are not permanent — they are constantly wearing out and rebuilding. When damage strikes, the body races to repair. Sometimes it regenerates the original tissue perfectly; often it patches the gap with dense connective tissue instead — a scar. A scar is strong but plain: it seals the hole without restoring the original function.\n\n'
        'Cancer is the darker failure. Differentiation and the "stop dividing" signals that keep a tissue orderly break down, and cells multiply without limit, ignoring their neighbors. Cancer is, at heart, a tissue-level disease: cooperation collapses and one lineage grows for itself.',
    relatedIds: ['tissue_animal_how_tissues_form', 'tissue_animal_four_types'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'A scar is the body choosing speed over perfection: seal the breach now with tough connective tissue, worry about elegance never. It is why a deep cut leaves a smooth patch with no hair or sweat glands — the original epithelium and its glands were not fully rebuilt.',
      ),
      LessonSection.thinkReveal(
        title: 'Why do wounds scar instead of vanishing?',
        question:
            'If your tissues can rebuild, why does a deep cut leave a permanent scar instead of restoring perfect skin?',
        answer:
            'Because the body prioritizes fast closure over faithful reconstruction. A deep wound is patched with dense collagen-rich connective tissue rather than fully regenerating the original layered epithelium and its glands. The scar is strong and quick, but lacks the structure — hair follicles, glands, elasticity — of the tissue it replaced.',
      ),
      LessonSection.table(
        title: 'Three fates of damaged tissue',
        headers: ['Outcome', 'What happens', 'Result'],
        rows: [
          ['Regeneration', 'Original tissue type rebuilt', 'Function restored'],
          ['Scarring (fibrosis)', 'Gap filled with connective tissue', 'Sealed, but function reduced'],
          ['Cancer', 'Growth controls fail; cells divide unchecked', 'Tissue order collapses'],
        ],
      ),
      LessonSection.fact(
        title: 'Cancer is broken cooperation',
        body:
            'A tissue works because cells obey signals to specialize and to stop dividing. Cancer is what happens when a cell line ignores both — growth without cooperation is the whole disease.',
      ),
    ],
  ),
];
