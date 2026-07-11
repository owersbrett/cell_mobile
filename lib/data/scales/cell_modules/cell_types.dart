import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Cell module: "A Tour of Cell Types" — the astonishing variety of cells in
/// the (mostly human/animal) body. Authored by module agent.
const List<BioEntity> cellTypesEntities = <BioEntity>[
  // 0 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'celltype_red_blood_cell',
    scale: BioScale.cell,
    position: 0,
    name: 'Red Blood Cell',
    title: 'The Cell That Threw Away Its Own Nucleus',
    moduleId: 'cell_types',
    shortDescription:
        'A cell so committed to carrying oxygen it ejected its own nucleus to make room.',
    longDescription:
        'The red blood cell (erythrocyte) is the body\'s oxygen courier, and it is a strange one: a mature mammalian RBC has no nucleus and no mitochondria at all. It threw them out during development so it could pack ~270 million molecules of hemoglobin into every cell — the iron-rich protein that grabs oxygen in the lungs and releases it in your tissues.\n\nWith no nucleus it cannot repair itself or divide, so it wears out and is recycled after roughly 120 days. Its flexible biconcave-disc shape lets it fold and squeeze through capillaries narrower than the cell itself.',
    relatedIds: ['celltype_white_blood_cell', 'celltype_stem_cell'],
    sections: [
      LessonSection.fact(
        title: 'A staggering headcount',
        body:
            'There are roughly 25 trillion red blood cells in an adult body — about a quarter of all your cells — and around 5 million pack into a single microliter of blood.',
      ),
      LessonSection.thinkReveal(
        title: 'The nucleus gamble',
        question:
            'Why would a cell deliberately throw away its own nucleus — the very thing that holds its DNA?',
        answer:
            'The nucleus takes up space and the RBC needs every cubic micron for hemoglobin. Ejecting it maximizes oxygen-carrying cargo. The trade-off: with no DNA blueprint the cell can never divide or repair, so it lives only ~120 days before being recycled in the spleen and liver.',
      ),
      LessonSection.table(
        title: 'What an RBC keeps and what it ditched',
        headers: ['Component', 'Kept?', 'Why'],
        rows: [
          ['Hemoglobin', 'Kept (a LOT)', 'The whole job — binds oxygen'],
          ['Nucleus', 'Ejected', 'Frees space for hemoglobin'],
          ['Mitochondria', 'Ejected', 'Would burn the oxygen it carries'],
          ['Flexible membrane', 'Kept', 'Squeezes through tiny capillaries'],
        ],
      ),
      LessonSection.fact(
        title: 'It won\'t even burn its own fuel',
        body:
            'Because it has no mitochondria, an RBC makes energy without using oxygen (anaerobic glycolysis) — it refuses to spend the very cargo it is paid to deliver.',
      ),
    ],
  ),

  // 1 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'celltype_white_blood_cell',
    scale: BioScale.cell,
    position: 1,
    name: 'White Blood Cells',
    title: 'The Immune Fleet',
    moduleId: 'cell_types',
    shortDescription:
        'Not one cell but a whole fleet — patrollers, eaters, and snipers hunting invaders in your bloodstream.',
    longDescription:
        'White blood cells (leukocytes) are the immune system\'s standing army. Unlike red cells, they all keep their nucleus, and they come in specialized roles rather than a single design. Neutrophils are the first responders that swarm infections; macrophages are the giant "big eaters" that engulf pathogens and debris; lymphocytes (B and T cells) are the precision force that remembers past invaders and builds targeted attacks.\n\nWhite cells are far outnumbered by red cells — only a few thousand per microliter versus millions — yet they can leave the bloodstream entirely, crawling into tissues to reach an infection.',
    relatedIds: ['celltype_red_blood_cell', 'celltype_stem_cell'],
    sections: [
      LessonSection.fact(
        title: 'Outnumbered but everywhere',
        body:
            'A microliter of blood holds ~5 million red cells but only ~4,000–11,000 white cells — roughly one white cell for every 700 red cells.',
      ),
      LessonSection.table(
        title: 'The main players in the fleet',
        headers: ['Cell', 'Role', 'Move'],
        rows: [
          ['Neutrophil', 'First responder', 'Swarms and swallows bacteria fast'],
          ['Macrophage', '"Big eater"', 'Engulfs pathogens and cell debris'],
          ['Lymphocyte (B)', 'Antibody factory', 'Makes targeting antibodies'],
          ['Lymphocyte (T)', 'Sniper / commander', 'Kills infected cells, remembers'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Leaving the road',
        question:
            'Red cells stay inside blood vessels for their whole life. How does a white cell reach an infection that\'s deep inside a tissue, far from any vessel?',
        answer:
            'White cells can squeeze between the cells lining a blood vessel and crawl out into the surrounding tissue — a process called extravasation. They follow chemical "scent trails" (chemotaxis) released at the site of injury straight to the invaders.',
      ),
      LessonSection.fact(
        title: 'Memory is the point',
        body:
            'Some lymphocytes become memory cells that survive for years — the reason a vaccine or a past infection can make you immune to the same pathogen for life.',
      ),
    ],
  ),

  // 2 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'celltype_skeletal_muscle_cell',
    scale: BioScale.cell,
    position: 2,
    name: 'Skeletal Muscle Cell',
    title: 'One Cell, Many Nuclei',
    moduleId: 'cell_types',
    shortDescription:
        'A muscle "cell" that fused from hundreds of cells, so it carries hundreds of nuclei in one long fiber.',
    longDescription:
        'A skeletal muscle cell — a muscle fiber — breaks a rule you were probably taught: it has many nuclei, not one. During development, hundreds of individual cells fuse into a single long fiber (a syncytium), keeping all their nuclei so one giant cell can run its whole length. These are the fibers you consciously command to walk, lift, and type.\n\nInside, the fiber is packed with repeating protein units called sarcomeres, whose overlapping filaments slide past each other to shorten the muscle. Their orderly stripes give skeletal muscle its "striated" (striped) appearance under a microscope.',
    relatedIds: ['celltype_cardiac_muscle_cell', 'celltype_smooth_muscle_cell'],
    sections: [
      LessonSection.fact(
        title: 'A cell you can see',
        body:
            'A single skeletal muscle fiber can run the entire length of a muscle — up to tens of centimeters in a large muscle like the sartorius in your thigh.',
      ),
      LessonSection.thinkReveal(
        title: 'Breaking the one-nucleus rule',
        question:
            'You\'re usually taught "one cell, one nucleus." Why does a skeletal muscle fiber have hundreds of nuclei?',
        answer:
            'The fiber forms when many precursor cells fuse together into one giant cell, pooling their nuclei. A single nucleus couldn\'t supply enough protein-building instructions for such an enormous cell, so keeping many nuclei — each managing its own local zone — lets the whole fiber run efficiently.',
      ),
      LessonSection.table(
        title: 'Zooming into a fiber',
        headers: ['Level', 'What it is'],
        rows: [
          ['Muscle', 'Bundle of many fibers'],
          ['Fiber (the cell)', 'One multinucleate syncytium'],
          ['Myofibril', 'Thread running the fiber\'s length'],
          ['Sarcomere', 'The repeating contracting unit'],
        ],
      ),
      LessonSection.fact(
        title: 'How it shortens',
        body:
            'Contraction is the "sliding filament" trick: thin actin and thick myosin filaments ratchet past each other inside each sarcomere, so the whole fiber pulls shorter.',
      ),
    ],
  ),

  // 3 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'celltype_cardiac_muscle_cell',
    scale: BioScale.cell,
    position: 3,
    name: 'Cardiac Muscle Cell',
    title: 'The Cell That Beats On Its Own',
    moduleId: 'cell_types',
    shortDescription:
        'A muscle cell that contracts by itself, wired to its neighbors so a whole heart beats as one.',
    longDescription:
        'The cardiomyocyte is the heart\'s working cell, and it does something no skeletal fiber can: it contracts on its own, without a nerve telling it to. It is branched rather than a straight rod, and its ends lock onto neighboring cells through special junctions called intercalated discs — electrical bridges that let a beat leap cell-to-cell so the whole heart squeezes in a coordinated wave.\n\nCardiomyocytes are packed with mitochondria to power a lifetime of nonstop beating, and once you\'re grown they largely stop dividing — which is why damaged heart muscle heals so poorly after a heart attack.',
    relatedIds: [
      'celltype_skeletal_muscle_cell',
      'celltype_smooth_muscle_cell'
    ],
    sections: [
      LessonSection.fact(
        title: 'A lifetime of beats',
        body:
            'A cardiomyocyte contracts around 100,000 times a day — roughly 3 billion beats over an average lifetime, without ever taking a break.',
      ),
      LessonSection.table(
        title: 'The three muscle types side by side',
        headers: ['Type', 'Control', 'Striated?', 'Self-firing?'],
        rows: [
          ['Skeletal', 'Voluntary', 'Yes', 'No'],
          ['Cardiac', 'Involuntary', 'Yes', 'Yes'],
          ['Smooth', 'Involuntary', 'No', 'Some'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why a heart attack scars',
        question:
            'A cut in your skin heals cleanly, but heart muscle killed by a heart attack usually becomes permanent scar. Why the difference?',
        answer:
            'Mature cardiomyocytes have almost entirely lost the ability to divide, so dead heart muscle can\'t be replaced by new muscle cells. Instead, fibroblasts fill the gap with tough collagen scar tissue — which holds the wall together but can\'t contract.',
      ),
      LessonSection.fact(
        title: 'Wired together',
        body:
            'Intercalated discs contain gap junctions — tiny tunnels between cells — that let an electrical signal jump directly from one cardiomyocyte to the next, so the heart fires as a single unit.',
      ),
    ],
  ),

  // 4 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'celltype_smooth_muscle_cell',
    scale: BioScale.cell,
    position: 4,
    name: 'Smooth Muscle Cell',
    title: 'The Silent Worker',
    moduleId: 'cell_types',
    shortDescription:
        'The muscle you never think about — squeezing your gut, blood vessels, and airways all day without you noticing.',
    longDescription:
        'Smooth muscle cells run the machinery you never consciously control: they line the walls of your gut, blood vessels, bladder, and airways. Each is a single spindle-shaped cell with one nucleus, and unlike skeletal and cardiac muscle they have no striations — their contracting filaments are arranged in a crisscross mesh rather than neat stripes, so they look "smooth."\n\nThey contract slowly and can hold tension for a long time without tiring, which is exactly what you want from a blood vessel that must stay squeezed for hours, or a gut wall that pushes food along in slow waves (peristalsis).',
    relatedIds: [
      'celltype_skeletal_muscle_cell',
      'celltype_cardiac_muscle_cell'
    ],
    sections: [
      LessonSection.fact(
        title: 'Working while you sleep',
        body:
            'Smooth muscle in your intestines keeps moving food along all night — you never issue a single command, and you can\'t stop it if you tried.',
      ),
      LessonSection.thinkReveal(
        title: 'Why "smooth"?',
        question:
            'Skeletal and cardiac muscle look striped under a microscope, but smooth muscle doesn\'t. Where did the stripes go?',
        answer:
            'The stripes come from sarcomeres — highly ordered rows of actin and myosin. Smooth muscle skips the neat sarcomere arrangement; its filaments run at angles across the cell in a diffuse mesh. No repeating rows means no stripes, hence "smooth."',
      ),
      LessonSection.table(
        title: 'Where smooth muscle lives and what it does',
        headers: ['Location', 'Job'],
        rows: [
          ['Gut wall', 'Peristalsis — pushes food along'],
          ['Blood vessels', 'Adjusts vessel width, sets blood pressure'],
          ['Bladder', 'Squeezes to empty urine'],
          ['Airways', 'Widens/narrows breathing passages'],
        ],
      ),
      LessonSection.fact(
        title: 'Slow but tireless',
        body:
            'Smooth muscle contracts far more slowly than skeletal muscle but resists fatigue — it can hold a squeeze for hours using very little energy.',
      ),
    ],
  ),

  // 5 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'celltype_epithelial_cell',
    scale: BioScale.cell,
    position: 5,
    name: 'Epithelial Cell',
    title: 'The Body\'s Living Wallpaper',
    moduleId: 'cell_types',
    shortDescription:
        'Cells that pack shoulder-to-shoulder into sheets, forming every barrier between "you" and the outside world.',
    longDescription:
        'Epithelial cells are the body\'s tiling. They pack tightly together into continuous sheets that cover surfaces and line cavities — your skin\'s outer layer, the lining of your gut, lungs, and blood vessels are all epithelium. Every boundary between the inside of your body and the outside world is drawn by these cells.\n\nThey are polarized, meaning they have a distinct top (facing the outside or a cavity) and bottom (anchored to underlying tissue). Sealed to each other by tight junctions, they decide what gets through — absorbing nutrients, secreting mucus, and keeping pathogens out.',
    relatedIds: ['celltype_fibroblast'],
    sections: [
      LessonSection.fact(
        title: 'You shed a lot of these',
        body:
            'The outer epithelium of your skin renews constantly — you lose roughly 30,000–40,000 dead skin cells every minute, and much of household dust is old you.',
      ),
      LessonSection.table(
        title: 'Where barriers get built',
        headers: ['Surface', 'What the epithelium does'],
        rows: [
          ['Skin', 'Waterproof, blocks pathogens'],
          ['Gut lining', 'Absorbs nutrients from food'],
          ['Lung airways', 'Secretes mucus, sweeps out dust'],
          ['Blood vessel lining', 'Smooth, non-stick surface for blood'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Top and bottom',
        question:
            'Why does an epithelial cell need to know which end is "up"? Why be polarized?',
        answer:
            'Because it\'s a gatekeeper. A gut cell must grab nutrients from the food side (top) and pass them to the blood side (bottom) — never the reverse. Polarity lets it place different pumps and receptors on each face, so traffic only flows one way. A cell that couldn\'t tell top from bottom couldn\'t act as a barrier.',
      ),
      LessonSection.fact(
        title: 'Sealed tight',
        body:
            'Tight junctions stitch neighboring epithelial cells together so completely that fluid can\'t leak between them — forcing everything to pass through the cells, where it can be screened.',
      ),
    ],
  ),

  // 6 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'celltype_fibroblast',
    scale: BioScale.cell,
    position: 6,
    name: 'Fibroblast',
    title: 'The Collagen Factory',
    moduleId: 'cell_types',
    shortDescription:
        'The workhorse cell that spins the collagen scaffold holding your entire body together.',
    longDescription:
        'Fibroblasts are the builders of connective tissue — the scaffolding that gives your body structure. They secrete collagen, the most abundant protein in the human body, along with other fibers and the gel-like matrix that cells sit in. Without fibroblasts, your skin, tendons, and organs would have nothing to hold their shape.\n\nThey are also the first responders of repair. When you get a cut, fibroblasts migrate in, multiply, and lay down fresh collagen to knit the wound closed — the same collagen that, when overdone, becomes a scar.',
    relatedIds: ['celltype_epithelial_cell', 'celltype_cardiac_muscle_cell'],
    sections: [
      LessonSection.fact(
        title: 'The body\'s #1 protein',
        body:
            'Collagen — the fibroblast\'s main product — makes up about 30% of all the protein in your body, more than any other single protein.',
      ),
      LessonSection.thinkReveal(
        title: 'The scar-maker',
        question:
            'Fibroblasts heal your wounds — so why do they also get blamed for scars?',
        answer:
            'Healing and scarring are the same process at different intensities. Fibroblasts rush to a wound and lay down collagen to seal it. If they deposit a lot of dense, disorganized collagen, the patch is stronger and stiffer than the original tissue — that\'s a scar. Useful repair and unwanted scar are two ends of one collagen-laying job.',
      ),
      LessonSection.table(
        title: 'What fibroblasts manufacture',
        headers: ['Product', 'Purpose'],
        rows: [
          ['Collagen', 'Strong structural fibers'],
          ['Elastin', 'Stretch and recoil (skin, vessels)'],
          ['Ground substance', 'Gel matrix cells sit in'],
          ['Growth signals', 'Coordinate wound healing'],
        ],
      ),
      LessonSection.fact(
        title: 'Everywhere in between',
        body:
            'Fibroblasts fill the spaces between other tissues throughout the body — under skin, around organs, inside tendons — quietly maintaining the framework everything else is built on.',
      ),
    ],
  ),

  // 7 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'celltype_adipocyte',
    scale: BioScale.cell,
    position: 7,
    name: 'Adipocyte',
    title: 'The Body\'s Fuel Tank',
    moduleId: 'cell_types',
    shortDescription:
        'A cell that\'s almost entirely one giant droplet of fat — your body\'s dense energy storehouse.',
    longDescription:
        'The adipocyte (fat cell) is a specialist in storage. Most of its volume is a single enormous droplet of stored fat (lipid), which pushes the nucleus and the rest of the cell\'s machinery flat against the outer membrane like a thin rind around a water balloon. That droplet is concentrated energy, banked for when the body needs fuel.\n\nFat cells aren\'t just passive tanks — they also release hormones like leptin that tell your brain how much energy is stored, helping regulate hunger. Adipocytes can swell to many times their size as they fill, which is largely how body fat grows.',
    relatedIds: ['celltype_fibroblast'],
    sections: [
      LessonSection.fact(
        title: 'Energy, densely packed',
        body:
            'Fat stores about 9 calories per gram — more than double the ~4 calories per gram in carbohydrate or protein — making it the body\'s most compact way to bank energy.',
      ),
      LessonSection.thinkReveal(
        title: 'A cell shoved to the edge',
        question:
            'In most cells the nucleus sits comfortably in the middle. In a fat cell it\'s squashed flat against the outer wall. What pushed it there?',
        answer:
            'A single giant lipid droplet fills almost the entire cell, ballooning it outward and flattening everything else — nucleus, cytoplasm, organelles — into a thin rim around the edge. The cell is essentially a bag built around one big blob of stored fat.',
      ),
      LessonSection.table(
        title: 'More than a storage tank',
        headers: ['Job', 'How'],
        rows: [
          ['Energy storage', 'Holds fat as a lipid droplet'],
          ['Insulation', 'Traps body heat under the skin'],
          ['Cushioning', 'Pads organs and joints'],
          ['Hormone signaling', 'Releases leptin to report fuel levels'],
        ],
      ),
      LessonSection.fact(
        title: 'It talks to your brain',
        body:
            'Adipocytes release the hormone leptin in proportion to how much fat is stored — a signal that tells the brain whether the body\'s energy tank is full or running low.',
      ),
    ],
  ),

  // 8 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'celltype_stem_cell',
    scale: BioScale.cell,
    position: 8,
    name: 'Stem Cell',
    title: 'The Cell That Could Become Anything',
    moduleId: 'cell_types',
    shortDescription:
        'An undecided cell — it can copy itself forever, or commit to becoming almost any specialized cell in the body.',
    longDescription:
        'A stem cell is a cell that hasn\'t chosen a career. It has two rare powers: it can self-renew (divide to make more copies of itself) and it can differentiate (turn into specialized cell types). Every specialized cell in this tour — red cells, muscle, skin, fat — traces back to a stem cell that committed to a path.\n\nStem cells come in tiers of possibility. A pluripotent stem cell (like those in an early embryo) can become almost any cell type in the body. A multipotent stem cell is more limited — a blood stem cell in your bone marrow, for example, can make red cells and white cells but not neurons.',
    relatedIds: [
      'celltype_red_blood_cell',
      'celltype_white_blood_cell',
      'celltype_gamete'
    ],
    sections: [
      LessonSection.fact(
        title: 'The origin of every red cell',
        body:
            'Blood stem cells in your bone marrow churn out roughly 2–3 million new red blood cells every second to replace the ones wearing out.',
      ),
      LessonSection.table(
        title: 'How much potential? The potency ladder',
        headers: ['Type', 'Can become', 'Example'],
        rows: [
          ['Totipotent', 'Any cell + placenta', 'The fertilized egg'],
          ['Pluripotent', 'Almost any body cell', 'Early embryonic cell'],
          ['Multipotent', 'A limited family', 'Blood stem cell'],
          ['Unipotent', 'One cell type only', 'Some skin precursors'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The self-renewal trick',
        question:
            'If a stem cell keeps differentiating into specialized cells, why doesn\'t the body just run out of stem cells?',
        answer:
            'When a stem cell divides, it can split the labor: one daughter commits to becoming a specialized cell, while the other stays a stem cell (asymmetric division). This keeps the stem-cell pool topped up even as it constantly ships specialized cells out — so the well never runs dry.',
      ),
      LessonSection.fact(
        title: 'Reprogramming won a Nobel',
        body:
            'Scientists can now turn ordinary adult cells back into pluripotent stem cells (induced pluripotent stem cells) — a discovery awarded the 2012 Nobel Prize in Medicine.',
      ),
    ],
  ),

  // 9 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'celltype_gamete',
    scale: BioScale.cell,
    position: 9,
    name: 'Gamete: Egg & Sperm',
    title: 'The Biggest and the Smallest',
    moduleId: 'cell_types',
    shortDescription:
        'The two cells that make a new person — one is the largest human cell, the other among the smallest.',
    longDescription:
        'Gametes are the reproductive cells — the egg (oocyte) and the sperm — and together they showcase the most extreme size gap in the human body. The egg is the single largest human cell, about 100 micrometers across, just barely visible to the naked eye. The sperm is among the smallest, its head only a few micrometers wide, trailing a long flagellum that is the only human cell built to swim.\n\nEach carries only half a genome (23 chromosomes instead of 46), so that when they fuse at fertilization the resulting cell has a full, complete set — the first cell of a new individual.',
    relatedIds: ['celltype_stem_cell'],
    sections: [
      LessonSection.fact(
        title: 'A cell you can almost see',
        body:
            'The human egg is about 100 micrometers wide — roughly the width of a thin human hair — making it the largest cell in the body and just barely visible without a microscope.',
      ),
      LessonSection.table(
        title: 'Two cells, opposite extremes',
        headers: ['Feature', 'Egg', 'Sperm'],
        rows: [
          ['Size', '~100 µm (largest)', 'Head ~5 µm (tiny)'],
          ['Can move?', 'No', 'Yes — swims with a flagellum'],
          ['Chromosomes', '23 (half a set)', '23 (half a set)'],
          ['Supplies', 'Loaded with nutrients', 'Stripped down for speed'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why such a size gap?',
        question:
            'The egg and sperm both carry the same amount of DNA (23 chromosomes). So why is the egg thousands of times larger than the sperm?',
        answer:
            'They have opposite jobs. The sperm only has to deliver DNA and travel fast, so it strips down to a lean head plus a tail. The egg must supply everything the new embryo needs for its first days — nutrients, machinery, and cellular scaffolding — so it\'s stocked full and enormous. Same genetic payload, wildly different cargo.',
      ),
      LessonSection.fact(
        title: 'The only human cell that swims',
        body:
            'The sperm is the sole human cell with a flagellum — a whip-like tail it beats to propel itself. No other cell in the body is built to actively swim.',
      ),
    ],
  ),
];
