import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Cell module: "The Life of a Cell" — the universal processes every cell runs.
/// (Authored by module agent.)
const List<BioEntity> cellLifeEntities = <BioEntity>[
  // 0 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'celllife_membrane',
    scale: BioScale.cell,
    position: 0,
    name: 'The Cell Membrane',
    title: 'the living skin',
    moduleId: 'cell_life',
    shortDescription:
        'A two-molecule-thick oily film decides what gets into the cell — and what stays out.',
    longDescription:
        'Every cell is wrapped in a phospholipid bilayer: two sheets of fat molecules with '
        'water-loving (hydrophilic) heads facing outward toward the watery world, and water-fearing '
        '(hydrophobic) tails tucked inward, away from water. That simple geometry builds a barrier '
        'oil can\'t cross and water can\'t flood.\n\n'
        'But it isn\'t a rigid wall. In the "fluid mosaic" model the membrane is a living sea: '
        'phospholipids drift sideways while proteins, cholesterol, and sugar tags float in it like '
        'boats. The proteins are the gates and sensors — the membrane is selective, not sealed.',
    relatedIds: ['celllife_transport', 'celllife_signaling'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Drop a bit of oil in water and it beads up — oil and water refuse to mix. The cell '
            'weaponizes that refusal. By pointing all the oily tails inward, the membrane becomes a '
            'barrier that a watery world simply cannot dissolve. Your life runs on a stubborn drop of oil.',
      ),
      LessonSection.table(
        title: 'Anatomy of the bilayer',
        headers: ['Part', 'Loves / fears water', 'Where it points'],
        rows: [
          ['Phosphate head', 'Hydrophilic (loves water)', 'Outward — faces the watery inside & outside'],
          ['Fatty-acid tails', 'Hydrophobic (fears water)', 'Inward — buried in the middle'],
          ['Cholesterol', 'Wedges between tails', 'Keeps the sheet fluid but not floppy'],
          ['Membrane proteins', 'Float in the sheet', 'Gates, pumps, and receptors'],
        ],
      ),
      LessonSection.fact(
        title: 'How thin?',
        body: 'The bilayer is roughly 5 nanometers thick — about 10,000 times thinner than a sheet of paper.',
      ),
      LessonSection.thinkReveal(
        title: 'Why two layers, not one?',
        question:
            'The membrane separates water inside the cell from water outside. Why does it take TWO '
            'layers of phospholipid facing tail-to-tail?',
        answer:
            'Because there is water on BOTH sides. Each layer turns its hydrophilic heads toward its '
            'own water and hides its hydrophobic tails in the middle. One layer would leave tails exposed '
            'to water on one face — unstable. Tail-to-tail, the oily cores meet and the whole thing is happy.',
      ),
    ],
  ),

  // 1 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'celllife_transport',
    scale: BioScale.cell,
    position: 1,
    name: 'Membrane Transport',
    title: 'the cell\'s customs office',
    moduleId: 'cell_life',
    shortDescription:
        'Why does a slice of potato go limp in salt water? The membrane is deciding what crosses.',
    longDescription:
        'The membrane is selective, so the cell needs ways to move things across it. Some cost no '
        'energy: diffusion (particles drift from crowded to sparse) and osmosis (water crossing a '
        'semipermeable membrane from high water potential to low). Some cost ATP: active transport '
        'pushes molecules "uphill," against their gradient.\n\n'
        'The star active pump is the Na⁺/K⁺ pump, which shoves 3 sodium ions out and 2 potassium ions '
        'in per ATP spent — building the electrical charge nerves and muscles fire on. For cargo too big '
        'for any gate, the membrane wraps a bubble around it: endocytosis (in) and exocytosis (out).',
    relatedIds: ['celllife_membrane', 'celllife_respiration'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Salt a slice of raw potato and it turns floppy within minutes. The salty water outside has '
            'LESS free water than the potato\'s insides, so water rushes OUT of the cells by osmosis to '
            'balance it. The cells deflate — and the potato wilts. No salt actually entered; only water left.',
      ),
      LessonSection.table(
        title: 'Four ways across the membrane',
        headers: ['Process', 'What moves', 'Direction', 'Needs ATP?'],
        rows: [
          ['Diffusion', 'Small molecules (O₂, CO₂)', 'High → low concentration', 'No'],
          ['Osmosis', 'Water', 'High → low water potential', 'No'],
          ['Active transport', 'Ions, nutrients', 'Low → high (uphill)', 'Yes'],
          ['Endo / exocytosis', 'Big cargo in bubbles', 'In / out via vesicles', 'Yes'],
        ],
      ),
      LessonSection.fact(
        title: 'The pump\'s tally',
        body: 'The Na⁺/K⁺ pump moves 3 Na⁺ out and 2 K⁺ in for every 1 ATP — and can run ~30% of a resting cell\'s energy budget.',
      ),
      LessonSection.thinkReveal(
        title: 'Passive vs. active',
        question:
            'Diffusion and osmosis are free, but active transport burns ATP. Why would a cell ever pay '
            'energy to move something it could let drift for free?',
        answer:
            'Because drifting only ever goes downhill — toward balance. To CONCENTRATE something (pile K⁺ '
            'inside, dump Na⁺ outside) the cell must push against the gradient, and pushing uphill always '
            'costs energy. That stored imbalance is a battery the cell later spends on nerve signals and nutrient uptake.',
      ),
    ],
  ),

  // 2 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'celllife_cell_cycle',
    scale: BioScale.cell,
    position: 2,
    name: 'The Cell Cycle',
    title: 'the life clock of a cell',
    moduleId: 'cell_life',
    shortDescription:
        'Before a cell can split in two, it grows, copies its DNA, and double-checks its work at three gates.',
    longDescription:
        'A dividing cell doesn\'t just snap in half. It runs a scheduled cycle: G1 (grow, make proteins), '
        'S (synthesis — copy ALL the DNA), G2 (grow more, prep for division), then M (mitosis — the actual '
        'split). G1, S, and G2 together are called interphase, the long "living and copying" stretch.\n\n'
        'Between phases sit checkpoints — molecular inspectors that ask "is the cell big enough? is the DNA '
        'copied correctly? is it damaged?" A failed checkpoint halts the cycle so errors don\'t get copied '
        'into daughter cells. When checkpoints break, unchecked division is what we call cancer.',
    relatedIds: ['celllife_mitosis', 'celllife_apoptosis'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Copy-paste a document with a typo and now you have two typos. A cell about to divide faces the '
            'same danger with 3 billion DNA letters. So before it splits, it copies everything ONCE and then '
            'stops at inspection gates to catch mistakes — because a mistake here gets inherited forever.',
      ),
      LessonSection.table(
        title: 'The phases in order',
        headers: ['Phase', 'What happens', 'Part of'],
        rows: [
          ['G1', 'Cell grows, builds proteins & organelles', 'Interphase'],
          ['S', 'DNA is synthesized (copied) — chromosomes doubled', 'Interphase'],
          ['G2', 'More growth, final checks, spindle prep', 'Interphase'],
          ['M', 'Mitosis + cytokinesis — the cell divides', 'Mitotic phase'],
        ],
      ),
      LessonSection.fact(
        title: 'When is the DNA copied?',
        body: 'DNA is duplicated exactly ONCE per cycle — during S phase. Never twice, never zero times.',
      ),
      LessonSection.thinkReveal(
        title: 'Why checkpoints?',
        question:
            'Checkpoints slow the cycle down. Wouldn\'t a cell divide faster — and win — if it skipped them?',
        answer:
            'Faster, yes. Safer, no. A checkpoint verifies the DNA is fully and correctly copied before the '
            'cell commits to splitting. Skip it, and damaged or half-copied DNA passes to both daughters. '
            'Cells that skip checkpoints DO divide faster and out-compete their neighbors — that is exactly '
            'what a tumor is.',
      ),
    ],
  ),

  // 3 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'celllife_mitosis',
    scale: BioScale.cell,
    position: 3,
    name: 'Mitosis',
    title: 'one cell becomes two twins',
    moduleId: 'cell_life',
    shortDescription:
        'How does one cell become two exact copies? It lines its chromosomes up and splits them down the middle.',
    longDescription:
        'Mitosis is the division that makes two genetically identical daughter cells — the engine of '
        'growth and healing. Its job is faithful copying: each daughter must get one complete set of '
        'chromosomes, no more, no less. It runs in four choreographed stages: prophase, metaphase, '
        'anaphase, telophase.\n\n'
        'Chromosomes condense (prophase), line up single-file across the cell\'s middle (metaphase), get '
        'pulled to opposite poles by spindle fibers (anaphase), then re-form into two nuclei (telophase). '
        'The cytoplasm pinches apart (cytokinesis) and — one cell in, two identical diploid cells out.',
    relatedIds: ['celllife_cell_cycle', 'celllife_meiosis'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Cut yourself and within days the wound closes with new skin that is genetically identical to '
            'the skin around it. That is mitosis: the body\'s copy machine, printing exact duplicates so you '
            'grow, heal, and replace worn-out cells with more of the same you.',
      ),
      LessonSection.table(
        title: 'The four phases (PMAT)',
        headers: ['Phase', 'What you\'d see', 'Key event'],
        rows: [
          ['Prophase', 'Chromosomes condense, become visible', 'Nuclear envelope breaks down, spindle forms'],
          ['Metaphase', 'Chromosomes line up single-file at the center', 'Alignment on the metaphase plate'],
          ['Anaphase', 'Sister chromatids pulled apart', 'Each pole gets one full copy'],
          ['Telophase', 'Two new nuclei form', 'Chromosomes de-condense; cytokinesis follows'],
        ],
      ),
      LessonSection.fact(
        title: 'The result',
        body: '1 parent cell → 2 daughter cells, each DIPLOID and genetically IDENTICAL to the parent.',
      ),
      LessonSection.thinkReveal(
        title: 'Why line up in the middle?',
        question:
            'In metaphase every chromosome parks single-file across the cell\'s equator before anything is '
            'pulled apart. Why the fuss over alignment?',
        answer:
            'So each pole gets exactly one copy of every chromosome. Lining up single-file lets spindle '
            'fibers grab each duplicated chromosome from both sides and pull the two identical halves to '
            'opposite ends. Skip the alignment and a daughter could end up with two of one chromosome and '
            'none of another — a fatal miscount.',
      ),
    ],
  ),

  // 4 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'celllife_meiosis',
    scale: BioScale.cell,
    position: 4,
    name: 'Meiosis',
    title: 'the shuffle that makes you unique',
    moduleId: 'cell_life',
    shortDescription:
        'Sperm and eggs carry HALF a genome — and no two are ever the same. Meiosis is how.',
    longDescription:
        'Meiosis makes gametes (sperm and eggs) and it must do two special things mitosis never does: '
        'HALVE the chromosome count, and SHUFFLE the genes. One round of DNA copying is followed by TWO '
        'divisions (meiosis I and II), so a single diploid cell yields four haploid cells — each with half '
        'the chromosomes, ready to combine with a partner\'s half at fertilization.\n\n'
        'The magic is genetic variety. During meiosis I, matching chromosomes pair up and swap segments '
        '("crossing over"), and the pairs sort into daughters at random ("independent assortment"). The '
        'result: four gametes that are genetically DIFFERENT from each other and from the parent.',
    relatedIds: ['celllife_mitosis', 'celllife_cell_cycle'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Siblings share the same two parents, yet no two (identical twins aside) are alike. Why? Because '
            'every sperm and every egg is a freshly shuffled deck. Meiosis mixes each parent\'s genes into a '
            'unique hand before fertilization deals it — you are a one-time-only combination.',
      ),
      LessonSection.table(
        title: 'Mitosis vs. meiosis',
        headers: ['Feature', 'Mitosis', 'Meiosis'],
        rows: [
          ['Divisions', 'One', 'Two (I and II)'],
          ['DNA copied', 'Once', 'Once (before division I)'],
          ['Daughter cells', '2', '4'],
          ['Chromosome count', 'Diploid (same as parent)', 'Haploid (half)'],
          ['Genetically', 'Identical to parent', 'Varied — crossing over + assortment'],
        ],
      ),
      LessonSection.fact(
        title: 'The math',
        body: '1 diploid cell → 4 haploid gametes, each with HALF the chromosomes and a unique gene mix.',
      ),
      LessonSection.thinkReveal(
        title: 'Why must gametes be halved?',
        question:
            'A body cell is diploid. If sperm and egg were ALSO diploid, what would go wrong at fertilization?',
        answer:
            'The count would double every generation — child with 92 chromosomes, grandchild with 184, and '
            'so on into chaos. By halving to haploid, each gamete carries just one set; sperm-half plus '
            'egg-half restores the correct diploid number in the child. Halving keeps the species\' chromosome '
            'count stable across generations.',
      ),
    ],
  ),

  // 5 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'celllife_signaling',
    scale: BioScale.cell,
    position: 5,
    name: 'Cell Signaling',
    title: 'how cells talk to each other',
    moduleId: 'cell_life',
    shortDescription:
        'Cells can\'t speak, so how does one tell another to grow, move, or die? Chemical messages and matching locks.',
    longDescription:
        'No cell lives alone. To coordinate a body, cells send chemical messages — ligands (hormones, '
        'neurotransmitters, growth factors) — that travel and bind to receptors, proteins shaped to catch '
        'exactly one message like a key fits one lock. Binding flips the receptor on.\n\n'
        'A switched-on receptor triggers a signal cascade inside the cell: one activated protein activates '
        'the next, and the next, amplifying a tiny outside signal into a big inside response — turning on '
        'genes, releasing energy, or telling the cell to divide. It\'s a relay race that turns a whisper at '
        'the door into a shout in the nucleus.',
    relatedIds: ['celllife_membrane', 'celllife_apoptosis'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Get startled and your heart pounds within a second — long before you consciously think about '
            'it. A single squirt of adrenaline found the matching receptors on your heart cells and set off '
            'a cascade. You didn\'t decide; a chemical message did, and millions of cells obeyed at once.',
      ),
      LessonSection.table(
        title: 'The parts of a signal',
        headers: ['Part', 'Role', 'Analogy'],
        rows: [
          ['Ligand', 'The message molecule (hormone, etc.)', 'The key'],
          ['Receptor', 'Protein that catches one ligand', 'The lock'],
          ['Cascade', 'Chain of proteins passing the signal', 'The relay race'],
          ['Response', 'Gene turns on, cell acts', 'The finish line'],
        ],
      ),
      LessonSection.fact(
        title: 'Amplification',
        body: 'A single ligand can, through a cascade, activate thousands of downstream molecules — a whisper becomes a roar.',
      ),
      LessonSection.thinkReveal(
        title: 'Why lock-and-key?',
        question:
            'Blood carries hundreds of different hormones at once. How does adrenaline reach heart cells '
            'without accidentally triggering everything else?',
        answer:
            'Because only cells with the MATCHING receptor can "hear" a given ligand. Adrenaline drifts past '
            'a cell with no matching lock and does nothing. Specificity comes from shape: one ligand fits one '
            'receptor, so a single message can be broadcast everywhere yet acted on only where it belongs.',
      ),
    ],
  ),

  // 6 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'celllife_apoptosis',
    scale: BioScale.cell,
    position: 6,
    name: 'Apoptosis',
    title: 'the clean self-destruct',
    moduleId: 'cell_life',
    shortDescription:
        'Why would your body deliberately kill its own healthy-looking cells? Because sometimes a cell must go.',
    longDescription:
        'Apoptosis is programmed cell death — a cell dismantling itself on purpose, tidily and on command. '
        'Unlike a messy accidental death (necrosis) that spills contents and inflames the area, apoptosis '
        'is orderly: the cell shrinks, chops its DNA, and packages itself into neat bubbles that neighbors '
        'quietly eat. No mess, no alarm.\n\n'
        'It\'s essential, not tragic. It sculpts fingers from webbed hands in the embryo, deletes cells '
        'with dangerously damaged DNA before they turn cancerous, and removes cells the body no longer '
        'needs. A cell that REFUSES to die when told to is a step toward a tumor — death is part of health.',
    relatedIds: ['celllife_cell_cycle', 'celllife_signaling'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'You were born with fingers, but as an embryo your hands were webbed paddles. What carved the '
            'gaps? Your body deliberately killed the cells between the fingers — apoptosis. Sometimes '
            'creating a shape means choosing exactly which cells must die.',
      ),
      LessonSection.table(
        title: 'Apoptosis vs. necrosis',
        headers: ['Feature', 'Apoptosis (programmed)', 'Necrosis (accidental)'],
        rows: [
          ['Trigger', 'Internal signal, on command', 'Injury, toxin, lack of oxygen'],
          ['Cell contents', 'Neatly packaged in vesicles', 'Spilled into surroundings'],
          ['Inflammation', 'None — quiet cleanup', 'Yes — swelling and alarm'],
          ['Purpose', 'Sculpting, safety, renewal', 'Uncontrolled damage'],
        ],
      ),
      LessonSection.fact(
        title: 'The daily toll',
        body: 'A healthy adult body clears tens of billions of cells by apoptosis every single day — and barely notices.',
      ),
      LessonSection.thinkReveal(
        title: 'Why kill a healthy cell?',
        question:
            'A cell with badly damaged DNA might still look and function fine. Why does the body order it '
            'to self-destruct instead of leaving it alone?',
        answer:
            'Because damaged DNA is a ticking bomb. If that cell divides, it copies the damage into every '
            'descendant — and unchecked, damaged cells that keep dividing become cancer. Apoptosis is the '
            'body\'s fail-safe: better to sacrifice one suspect cell now than risk a tumor later.',
      ),
    ],
  ),

  // 7 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'celllife_respiration',
    scale: BioScale.cell,
    position: 7,
    name: 'Cellular Respiration & ATP',
    title: 'burning food for battery power',
    moduleId: 'cell_life',
    shortDescription:
        'Every move you make is paid for in ATP — the cell\'s cash. It\'s minted by burning glucose with oxygen.',
    longDescription:
        'Cells can\'t spend glucose directly; they convert it into ATP, the universal energy currency every '
        'process pays with. Cellular respiration does the conversion in three stages: glycolysis (glucose '
        'split in the cytoplasm), the Krebs cycle, and oxidative phosphorylation (both in the mitochondria, '
        'the "powerhouse of the cell"). Oxygen is the final electron acceptor that makes the big payoff possible.\n\n'
        'The honest yield is about 30–32 ATP per glucose molecule — not the old textbook "38," which ignored '
        'the energy cost of shuttling molecules into the mitochondria. Most of that ATP is made in the last '
        'stage, oxidative phosphorylation, where the electron transport chain does the heavy minting.',
    relatedIds: ['celllife_transport', 'celllife_membrane'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'A potato is packed with starch — chains of glucose. Eat it and your mitochondria "burn" that '
            'glucose with the oxygen you breathe, capturing the energy as ATP. The chemistry is the same slow, '
            'controlled fire as a campfire; your cells just harvest the heat as usable currency instead of flame.',
      ),
      LessonSection.table(
        title: 'The three stages',
        headers: ['Stage', 'Where', 'Needs O₂?', 'ATP contribution'],
        rows: [
          ['Glycolysis', 'Cytoplasm', 'No', 'Small (net 2 ATP)'],
          ['Krebs cycle', 'Mitochondrial matrix', 'Yes (indirectly)', 'Small (2 ATP) + electron carriers'],
          ['Oxidative phosphorylation', 'Inner mitochondrial membrane', 'Yes — O₂ is final acceptor', 'The bulk of the ATP'],
        ],
      ),
      LessonSection.fact(
        title: 'The real yield',
        body: 'About 30–32 ATP per glucose — NOT 38. The older figure ignored the cost of importing molecules into the mitochondria.',
      ),
      LessonSection.thinkReveal(
        title: 'Why is oxygen the deal-breaker?',
        question:
            'Stop breathing and cells fail within minutes. Glycolysis doesn\'t even need oxygen — so why is '
            'oxygen so utterly non-negotiable?',
        answer:
            'Oxygen is the FINAL electron acceptor at the end of the electron transport chain, where most ATP '
            'is minted. No oxygen means the chain backs up, the big oxidative-phosphorylation payoff stops, and '
            'the cell is left with only glycolysis\'s tiny 2 ATP. That trickle can\'t power a living cell for long.',
      ),
    ],
  ),
];
