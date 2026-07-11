import 'package:cell_mobile/blocs/cell/cell_states.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

const organelleEntities = <BioEntity>[
  // Existing 18 organelles mapped from the original data
  BioEntity(
    id: 'organelle_nucleolus',
    scale: BioScale.organelle,
    position: 0,
    name: 'Nucleolus',
    title: 'The Creator',
    imagePath: 'assets/images/nucleolus.png',
    shortDescription: 'A dense region inside the nucleus where ribosomes — the cell\'s protein-building machines — are assembled.',
    longDescription:
        'The nucleolus is not membrane-bound; it is a dense knot of DNA, RNA, and protein that condenses around the genes for ribosomal RNA. Its one job is to transcribe those genes, process the rRNA, and pre-assemble the two ribosomal subunits before shipping them out through the nuclear pores.\n\n'
        'It sits deep inside the nuclear envelope, in the innermost region of the cell. When a cell is growing fast and needs many proteins, its nucleolus swells; a quiet cell has a small one. It is a factory whose size reports the workload.',
    organelleEnum: Organelle.nucleolus,
    zoomInIds: ['molecular_proteins'],
    zoomOutIds: ['cell_mesophyll', 'cell_guard'],
    relatedIds: ['organelle_ribosomes'],
    sections: [
      LessonSection.table(
        title: 'The ribosome assembly line',
        headers: ['Stage', 'Where', 'What happens'],
        rows: [
          ['Transcription', 'Nucleolus', 'rRNA genes copied into long rRNA'],
          ['Processing', 'Nucleolus', 'rRNA cut, folded, chemically tagged'],
          ['Subunit assembly', 'Nucleolus', 'rRNA + proteins form 40S and 60S parts'],
          ['Export', 'Nuclear pores', 'Subunits leave separately to the cytoplasm'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why build here?',
        question: 'The ribosomes do their work out in the cytoplasm. Why assemble them inside the nucleus instead?',
        answer: 'Because the parts are made here. Ribosomal RNA is transcribed directly from DNA, which stays locked in the nucleus. Building the subunits next to their rRNA source avoids dragging fragile, half-finished machines across the nuclear membrane. The subunits are only snapped together into a working ribosome after export — a safety catch that stops the cell from accidentally translating RNA before it is ready.',
      ),
      LessonSection.thinkReveal(
        title: 'What breaks if it stops?',
        question: 'A toxin shuts the nucleolus down. What is the first thing the cell can no longer do?',
        answer: 'Make new ribosomes — and therefore, soon, new proteins. Existing ribosomes keep working for a while, but they wear out and are not replaced. Protein production stalls, growth halts, and the cell cannot repair or divide. Because so much depends on it, nucleolar stress is one of the cell\'s main alarm signals for calling a halt to the cell cycle.',
      ),
      LessonSection.fact(
        title: 'Factory throughput',
        body: 'A rapidly growing human cell can assemble on the order of ~7,500 ribosomes every minute in its nucleolus.',
      ),
    ],
  ),
  BioEntity(
    id: 'organelle_nucleotide',
    scale: BioScale.organelle,
    position: 1,
    name: 'Nucleotides',
    title: 'The Building Blocks',
    imagePath: 'assets/images/nucleotide.png',
    shortDescription: 'The three-part units that link into chains to form DNA and RNA — and, on their own, carry energy.',
    longDescription:
        'A nucleotide has three parts: a nitrogenous base, a phosphate group, and a five-carbon sugar. String them together and you get a nucleic acid; the sugar of one links to the phosphate of the next, forming the backbone, while the bases hang off to the side and carry the information.\n\n'
        'Their job is bigger than storage. The same molecular family also runs the cell\'s energy economy (ATP is a nucleotide) and drives enzyme activity. The five bases are adenine, guanine, cytosine, thymine, and uracil.',
    organelleEnum: Organelle.nucleotide,
    zoomInIds: ['molecular_proteins'],
    relatedIds: ['organelle_dna', 'organelle_rna'],
    sections: [
      LessonSection.table(
        title: 'The five bases',
        headers: ['Base', 'Family', 'In DNA?', 'In RNA?', 'Pairs with'],
        rows: [
          ['Adenine (A)', 'Purine', 'Yes', 'Yes', 'T (DNA) / U (RNA)'],
          ['Guanine (G)', 'Purine', 'Yes', 'Yes', 'Cytosine'],
          ['Cytosine (C)', 'Pyrimidine', 'Yes', 'Yes', 'Guanine'],
          ['Thymine (T)', 'Pyrimidine', 'Yes', 'No', 'Adenine'],
          ['Uracil (U)', 'Pyrimidine', 'No', 'Yes', 'Adenine'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why three parts?',
        question: 'A nucleotide could have been simpler. Why does it need a base, a sugar, AND a phosphate?',
        answer: 'Each part has a job. The sugar and phosphate alternate to build a strong, uniform backbone that any base can hang off — so the sequence can vary freely without weakening the chain. The base is the actual letter of information. The phosphate is also chemically loaded; when several phosphates chain up (as in ATP) they store energy. Separating structure, information, and energy into three modules is what lets one molecule family do all three jobs.',
      ),
      LessonSection.thinkReveal(
        title: 'A revealing coincidence',
        question: 'Adenine turns up in DNA, in RNA, and in ATP. What does one base doing three jobs suggest?',
        answer: 'That the information molecules and the energy molecules share a common ancestry. In the leading origin-of-life story, RNA came first and did everything — carrying information and running chemistry — so its building blocks got recruited into energy carriers too. ATP is essentially a nucleotide the cell never stopped using as currency. The overlap is a fossil of that shared beginning.',
      ),
      LessonSection.fact(
        title: 'One alphabet, all life',
        body: 'Just 4 DNA bases, arranged in different orders, encode every organism that has ever lived on Earth.',
      ),
    ],
  ),
  BioEntity(
    id: 'organelle_rna',
    scale: BioScale.organelle,
    position: 2,
    name: 'RNA',
    title: 'The Messenger',
    imagePath: 'assets/images/rna.png',
    shortDescription: 'A single-stranded nucleic acid that carries DNA\'s instructions out to the ribosome and helps build proteins.',
    longDescription:
        'RNA — ribonucleic acid — is the cell\'s working copy of its instructions. DNA stays safe in the nucleus; RNA is the disposable messenger and toolset that carries orders out to where proteins are made. It is single-stranded, which lets it fold into shapes and act, not just store.\n\n'
        'There are many kinds, but three dominate: messenger RNA (mRNA) carries the gene\'s recipe, transfer RNA (tRNA) ferries amino acids, and ribosomal RNA (rRNA) forms the core of the ribosome itself.',
    organelleEnum: Organelle.rna,
    relatedIds: ['organelle_nucleotide', 'organelle_dna', 'organelle_ribosomes'],
    sections: [
      LessonSection.table(
        title: 'The three main RNAs',
        headers: ['Type', 'Nickname', 'Job'],
        rows: [
          ['mRNA', 'Messenger', 'Carries a gene\'s code from DNA to the ribosome'],
          ['tRNA', 'Transfer', 'Brings the matching amino acid for each code word'],
          ['rRNA', 'Ribosomal', 'Builds the ribosome and catalyzes bonding'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why single-stranded?',
        question: 'DNA is a stable double helix. Why is RNA left single-stranded and short-lived?',
        answer: 'Because RNA is a messenger, not an archive. Being single-stranded lets it fold into complex 3D shapes — so a tRNA can grip an amino acid, and rRNA can act like an enzyme. It is also meant to be temporary: the cell makes an mRNA, uses it a few times, and destroys it. That disposability is a feature — it lets the cell change which proteins it makes minute to minute, instead of being stuck with permanent copies.',
      ),
      LessonSection.thinkReveal(
        title: 'Which came first?',
        question: 'DNA stores information and proteins do chemistry. So why do many scientists think RNA came before both?',
        answer: 'Because RNA can do BOTH jobs. It can store a sequence like DNA and fold up to catalyze reactions like a protein — rRNA proving it by forming the ribosome\'s catalytic heart. A single molecule that both remembers and acts could bootstrap life on its own, whereas DNA and proteins each need the other. That is the "RNA world" hypothesis: RNA first, with DNA and proteins as later, more specialized upgrades.',
      ),
      LessonSection.fact(
        title: 'The ribosome is an RNA machine',
        body: 'The chemical bond that links amino acids into protein is forged by rRNA — not by any protein. Life\'s core reaction is run by RNA.',
      ),
    ],
  ),
  BioEntity(
    id: 'organelle_base_pairs',
    scale: BioScale.organelle,
    position: 3,
    name: 'Base Pairs',
    title: 'The Complementary Building Blocks',
    imagePath: 'assets/images/base-pairs.png',
    shortDescription: 'The A–T and G–C pairings whose hydrogen bonds zip the two strands of DNA into a double helix.',
    longDescription:
        'A base pair is a rung of the DNA ladder: adenine always bonds with thymine, and guanine always with cytosine. These pairings are held by hydrogen bonds — weak individually, but by the millions they hold the whole double helix together.\n\n'
        'The pairing is "complementary," which is the whole trick of heredity: if you know one strand, you know the other. When the cell needs to read or copy DNA, the pairs unzip, the information is decoded, and they zip back up.',
    organelleEnum: Organelle.base_pairs,
    relatedIds: ['organelle_dna', 'organelle_nucleotide'],
    sections: [
      LessonSection.table(
        title: 'The two legal pairs',
        headers: ['Pair', 'Hydrogen bonds', 'Relative strength'],
        rows: [
          ['A – T', '2', 'Weaker, unzips more easily'],
          ['G – C', '3', 'Stronger, needs more heat to separate'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why only these two?',
        question: 'Why can\'t adenine just pair with guanine, or cytosine with thymine?',
        answer: 'Geometry and bonding. A purine (A or G, the big bases) must pair with a pyrimidine (T or C, the small ones) so every rung is the same width — mixing two big or two small bases would kink or snap the ladder. Within that rule, only A–T and G–C line their hydrogen-bond donors and acceptors up correctly. The other combinations physically can\'t make stable bonds. The pairing is dictated by shape and chemistry, not choice.',
      ),
      LessonSection.thinkReveal(
        title: 'Which DNA is tougher?',
        question: 'Two stretches of DNA: one is rich in G–C pairs, the other in A–T. Which needs a higher temperature to melt apart, and why?',
        answer: 'The G–C-rich stretch. Each G–C pair has three hydrogen bonds versus two for A–T, so G–C DNA holds together more tightly. This is why organisms living in hot springs tend to have G–C-heavy genomes, and why the "melting temperature" of a DNA sample is a direct readout of its G–C content. Same four letters, but the ratio tunes the physical toughness of the molecule.',
      ),
      LessonSection.fact(
        title: 'The scale of the ladder',
        body: 'A single human cell holds ~3 billion base pairs of DNA — enough rungs that, uncoiled, the ladder would stretch ~2 meters.',
      ),
    ],
  ),
  BioEntity(
    id: 'organelle_dna',
    scale: BioScale.organelle,
    position: 4,
    name: 'DNA',
    title: 'Genetic Database',
    imagePath: 'assets/images/dna.png',
    shortDescription: 'The double-stranded archive that stores every instruction a cell needs, and can copy itself to pass them on.',
    longDescription:
        'DNA is the cell\'s database of life. Its defining trick is self-instruction: it holds the recipe for copying itself, so information passes to the next generation. Copying is not perfect — mutations creep in — and some of those changes show up in how an organism looks and behaves.\n\n'
        'Store up enough change across a population and you eventually get speciation. All of it is written in the same four-letter code, telling each cell what to make and how to make it.',
    organelleEnum: Organelle.dna,
    zoomInIds: ['molecular_proteins'],
    relatedIds: ['organelle_nucleotide', 'organelle_rna', 'organelle_base_pairs'],
    sections: [
      LessonSection.table(
        title: 'DNA vs RNA at a glance',
        headers: ['Property', 'DNA', 'RNA'],
        rows: [
          ['Strands', 'Double', 'Single'],
          ['Sugar', 'Deoxyribose', 'Ribose'],
          ['Bases', 'A, T, G, C', 'A, U, G, C'],
          ['Role', 'Long-term storage', 'Working copy / tool'],
          ['Stability', 'Very stable', 'Short-lived'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why keep two copies?',
        question: 'DNA carries the same information on both strands. Isn\'t that wasteful? What is the second strand actually for?',
        answer: 'It is a built-in backup and a repair template. Because the strands are complementary, if one is damaged the cell can rebuild the missing letters from its partner — the correct sequence is never truly lost as long as one side survives. The doubled strand is also what makes copying possible: unzip it, and each half is a ready-made mold for a new partner. The "redundancy" is the mechanism of both repair and inheritance.',
      ),
      LessonSection.thinkReveal(
        title: 'Is a mutation a bug?',
        question: 'Copy errors sound like a flaw. Would perfectly error-free DNA copying be better?',
        answer: 'No — it would be a dead end. Mutations are the raw material of evolution. Without them, a population could never vary, adapt, or improve; a changing environment would eventually kill a species that could not change with it. The cell walks a tightrope: it proofreads copying obsessively (to avoid disease), but not perfectly (to preserve variation). A little error is the price of a future.',
      ),
      LessonSection.fact(
        title: 'Two meters, folded small',
        body: 'The DNA in one human cell is ~2 meters long, yet packs into a nucleus only ~6 micrometers wide — a ~300,000-fold compaction.',
      ),
    ],
  ),
  BioEntity(
    id: 'organelle_nucleoplasm',
    scale: BioScale.organelle,
    position: 5,
    name: 'Nucleoplasm',
    title: 'The Inner Sanctum',
    imagePath: 'assets/images/nucleoplasm.png',
    shortDescription: 'The gel-like fluid inside the nucleus that suspends the chromosomes and the nucleolus.',
    longDescription:
        'The nucleoplasm is the fluid-filled interior of the nucleus — the medium in which the chromosomes float and the nucleolus is suspended. It fills the space between the nuclear envelope and the nucleolus, and it is where DNA is copied and read.\n\n'
        'Think of it as the cytoplasm\'s counterpart, but for the nucleus: a crowded, protein-rich solution that keeps the machinery of the genome bathed in the enzymes and building blocks it needs.',
    organelleEnum: Organelle.nucleoplasm,
    relatedIds: ['organelle_nuclear_membrane', 'organelle_nucleolus'],
    sections: [
      LessonSection.table(
        title: 'Two fluids, two compartments',
        headers: ['Feature', 'Nucleoplasm', 'Cytoplasm'],
        rows: [
          ['Location', 'Inside the nucleus', 'Outside the nucleus'],
          ['Holds', 'Chromosomes, nucleolus', 'Organelles, ribosomes'],
          ['Main work', 'DNA copying and transcription', 'Protein synthesis, metabolism'],
          ['Separated by', 'Nuclear envelope', 'Plasma membrane'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why a separate room?',
        question: 'Bacteria let their DNA float free in the cytoplasm. Why do our cells go to the trouble of walling the genome off in its own fluid?',
        answer: 'To separate reading the gene from using it. Keeping DNA in the nucleoplasm means transcription (making RNA) happens in one room and translation (making protein) happens in another. That gap gives the cell a chance to edit and quality-check the RNA before it is ever used, and it keeps the delicate genome away from the rough-and-tumble of metabolism. This separation is a defining feature that splits eukaryotes from bacteria.',
      ),
      LessonSection.thinkReveal(
        title: 'Fluid, but not just water',
        question: 'If the nucleoplasm were pure water, why would the genome grind to a halt?',
        answer: 'Because copying and reading DNA are chemistry, and chemistry needs reagents. The nucleoplasm is packed with enzymes, free nucleotides, ions, and regulatory proteins — the toolkit and raw materials for replication and transcription. Pure water would suspend the chromosomes but supply nothing to act on them. The medium is as important as the message it surrounds.',
      ),
      LessonSection.fact(
        title: 'A crowded pool',
        body: 'Cellular fluids like the nucleoplasm can be up to ~30% protein by weight — closer to a thick gel than to water.',
      ),
    ],
  ),
  BioEntity(
    id: 'organelle_nuclear_membrane',
    scale: BioScale.organelle,
    position: 6,
    name: 'Nuclear Membrane',
    title: 'The Inner Walls',
    imagePath: 'assets/images/nuclear-membrane.png',
    shortDescription: 'A double lipid bilayer, pierced by pores, that separates the nucleus from the rest of the cell.',
    longDescription:
        'The nuclear membrane (or nuclear envelope) is a double lipid bilayer wrapping the nucleus. In biology, "nuclear" means the innermost region, and a "membrane" is a barrier that separates compartments — so this is the wall between the nucleoplasm and the cytoplasm.\n\n'
        'It is not a sealed wall. Nuclear pores stud the envelope, forming guarded passageways that let specific cargo — nucleic acids out, proteins in — cross while keeping everything else where it belongs.',
    organelleEnum: Organelle.nuclear_membrane,
    zoomInIds: ['molecular_lipids'],
    relatedIds: ['organelle_nucleoplasm', 'organelle_plasma_membrane'],
    sections: [
      LessonSection.table(
        title: 'Traffic through the pores',
        headers: ['Cargo', 'Direction', 'Why'],
        rows: [
          ['mRNA', 'Out to cytoplasm', 'To be translated by ribosomes'],
          ['Ribosomal subunits', 'Out to cytoplasm', 'Assembled in the nucleolus'],
          ['Proteins / enzymes', 'In to nucleus', 'To copy and read the DNA'],
          ['Nucleotides', 'In to nucleus', 'Raw material for DNA and RNA'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why double?',
        question: 'The plasma membrane is a single bilayer. Why is the nuclear envelope built from two?',
        answer: 'The two bilayers give the nucleus extra structural integrity and a distinct in-between space, and the outer one is continuous with the endoplasmic reticulum — so the nuclear envelope is physically part of the cell\'s membrane network, not an island. That continuity lets the cell rebuild the envelope from the ER after every cell division, when it briefly dissolves and reforms.',
      ),
      LessonSection.thinkReveal(
        title: 'Why not a solid wall?',
        question: 'If the point is to protect the DNA, why doesn\'t the nucleus just seal itself completely shut?',
        answer: 'Because a sealed vault is useless — the genome has to be read to matter. Proteins made in the cytoplasm must get in to copy and regulate the DNA, and the RNA messages must get out to be translated. The pores are the compromise: guarded checkpoints that allow controlled, selective traffic while still blocking random molecules. Protection without communication would kill the cell as surely as no protection at all.',
      ),
      LessonSection.fact(
        title: 'Thousands of gates',
        body: 'A single mammalian nucleus is pierced by ~2,000–4,000 nuclear pore complexes, each a machine of ~30 different proteins.',
      ),
    ],
  ),
  BioEntity(
    id: 'organelle_smooth_er',
    scale: BioScale.organelle,
    position: 7,
    name: 'Smooth E.R.',
    title: 'The Tubular Factory',
    imagePath: 'assets/images/smooth-endoplasmic-reticulum.png',
    shortDescription: 'A ribosome-free network of tubes that makes lipids and hormones and detoxifies the cell.',
    longDescription:
        'The smooth endoplasmic reticulum is a network of membrane tubes that makes lipids and hormones. Its surface is bare — no ribosomes — which is exactly what distinguishes it from the rough ER and gives it its name.\n\n'
        'Because it is not busy building proteins, the smooth ER specializes in fat-based chemistry: synthesizing membrane lipids and steroids, storing calcium, and breaking down toxins.',
    organelleEnum: Organelle.smooth_endoplasmic_reticulum,
    zoomInIds: ['molecular_lipids'],
    relatedIds: ['organelle_rough_er', 'organelle_golgi_apparatus'],
    sections: [
      LessonSection.table(
        title: 'Smooth vs rough ER',
        headers: ['Feature', 'Smooth ER', 'Rough ER'],
        rows: [
          ['Ribosomes', 'None', 'Studded on surface'],
          ['Main product', 'Lipids, hormones', 'Proteins'],
          ['Shape', 'Tubular network', 'Flattened sacs'],
          ['Extra jobs', 'Detox, Ca²⁺ storage', 'Protein folding, quality control'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why no ribosomes?',
        question: 'The rough ER is covered in ribosomes and the smooth ER has none. Why would a factory choose to have zero of the cell\'s main machines?',
        answer: 'Because it isn\'t making proteins — it\'s making fats. Ribosomes are only for assembling proteins, so a lipid-and-hormone factory has no use for them. Their absence is not a lack; it is a specialization. It also physically changes the shape: without bulky ribosomes the membrane curls into slender tubes rather than flat sheets, giving lots of surface area for its fat-based chemistry.',
      ),
      LessonSection.thinkReveal(
        title: 'Why liver cells are full of it',
        question: 'Liver cells have unusually abundant smooth ER. What does that tell you about what the smooth ER does?',
        answer: 'That it detoxifies. The liver is the body\'s main filter for drugs, alcohol, and metabolic poisons, and the smooth ER carries the enzymes that chemically neutralize them. When you take a drug regularly, liver cells grow MORE smooth ER to keep up — which is part of why tolerance builds. The organelle\'s abundance tracks the toxic load the cell has to handle.',
      ),
      LessonSection.fact(
        title: 'A calcium reservoir',
        body: 'In muscle cells, a specialized smooth ER stores calcium and releases it to trigger every single contraction — including the ones you make lifting a potato.',
      ),
    ],
  ),
  BioEntity(
    id: 'organelle_ribosomes',
    scale: BioScale.organelle,
    position: 8,
    name: 'Ribosomes',
    title: 'The Machine Elves',
    imagePath: 'assets/images/ribosomes.png',
    shortDescription: 'Two-part molecular machines that read mRNA and stitch amino acids into proteins.',
    longDescription:
        'Ribosomes are the cell\'s protein factories: they read the code in messenger RNA and forge peptide bonds to link amino acids into a growing protein chain. Some drift free in the cytoplasm; others dock on the rough ER. Their parts are born in the nucleolus and shipped out to work.\n\n'
        'They are ephemeral little workers — assembling on an mRNA, running its length, then releasing and moving on. Small, countless, and relentless, they are where the genome\'s instructions finally become physical.',
    organelleEnum: Organelle.ribosomes,
    zoomInIds: ['molecular_proteins'],
    relatedIds: ['organelle_rna', 'organelle_rough_er', 'organelle_nucleolus'],
    sections: [
      LessonSection.table(
        title: 'Two subunits, one machine',
        headers: ['Subunit', 'Role'],
        rows: [
          ['Small (40S)', 'Grips the mRNA and reads it three letters at a time'],
          ['Large (60S)', 'Holds the amino acids and forges the peptide bonds'],
          ['Joined (80S)', 'The working ribosome — only assembles once on an mRNA'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why come apart?',
        question: 'A ribosome splits back into two subunits when it finishes a protein. Why not stay assembled and ready?',
        answer: 'Splitting apart is the reset. Keeping the subunits separate when idle stops the ribosome from grabbing and translating an mRNA at the wrong moment — assembly only completes at a proper start signal on a real message. It is a safety interlock: the machine is only "on" when correctly loaded, so the cell never wastes energy or makes garbage proteins from random RNA.',
      ),
      LessonSection.thinkReveal(
        title: 'Free vs bound ribosomes',
        question: 'Some ribosomes float free in the cytoplasm; others stick to the rough ER. What decides which protein gets made where?',
        answer: 'The protein\'s destination, revealed by its first few amino acids. If the emerging chain starts with a "signal sequence" — an address tag for secretion or the membrane — the ribosome gets towed to the rough ER to feed the protein inside for shipping. If there is no tag, the ribosome stays free and the protein is made for use within the cytoplasm. Same machine; the cargo\'s zip code sets its workbench.',
      ),
      LessonSection.fact(
        title: 'Blistering assembly speed',
        body: 'A bacterial ribosome adds ~20 amino acids per second; human ribosomes run slower, but a cell may hold millions of them working at once.',
      ),
    ],
  ),
  BioEntity(
    id: 'organelle_rough_er',
    scale: BioScale.organelle,
    position: 9,
    name: 'Rough E.R.',
    title: 'The Studded Factory',
    imagePath: 'assets/images/rough-endoplasmic-reticulum.png',
    shortDescription: 'A ribosome-studded membrane network that synthesizes, folds, and quality-checks proteins.',
    longDescription:
        'The rough endoplasmic reticulum is a stack of flattened membrane sacs studded with ribosomes — which is where the "rough" comes from. Those ribosomes feed newly made proteins directly into the ER interior, where the proteins fold, get chemically decorated, and are checked for defects.\n\n'
        'It is a factory with a built-in quality-control department: proteins that fold correctly are packaged and shipped toward the Golgi; misfolds are flagged and destroyed before they can cause harm.',
    organelleEnum: Organelle.rough_endoplasmic_reticulum,
    zoomInIds: ['molecular_proteins'],
    relatedIds: ['organelle_ribosomes', 'organelle_smooth_er', 'organelle_golgi_apparatus'],
    sections: [
      LessonSection.table(
        title: 'The rough ER pipeline',
        headers: ['Step', 'What happens'],
        rows: [
          ['Synthesis', 'Docked ribosomes thread new protein into the ER'],
          ['Folding', 'Chaperone proteins help it fold to its correct shape'],
          ['Tagging', 'Sugar groups are added (glycosylation)'],
          ['Check', 'Misfolded proteins are caught and sent for destruction'],
          ['Ship', 'Good proteins bud off in vesicles toward the Golgi'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why "how convenient"?',
        question: 'The rough ER makes proteins, and it\'s covered in ribosomes — which also make proteins. Is that redundant, or clever?',
        answer: 'Clever. The ribosomes do the actual assembling; the ER provides the enclosed, controlled space where the fresh protein can be folded, tagged, and inspected without interference. Docking the ribosome onto the ER means the protein is threaded straight into that processing chamber as it is built — no risky transport step. It is an assembly line where the machine is bolted directly onto the finishing room.',
      ),
      LessonSection.thinkReveal(
        title: 'What if the check fails?',
        question: 'A cell is churning out so many proteins that misfolds pile up faster than the rough ER can clear them. What happens?',
        answer: 'The ER raises an alarm called the "unfolded protein response." It slows new protein production, makes more folding helpers, and ramps up disposal to catch up. If the backlog still can\'t be cleared, the same signal orders the cell to self-destruct rather than flood the body with defective proteins. Chronic versions of this jam are implicated in diabetes and neurodegenerative disease — quality control that fails loudly, exactly as it should.',
      ),
      LessonSection.fact(
        title: 'Secretion powerhouses',
        body: 'Cells built for export — like antibody-making plasma cells — can devote a huge share of their interior to rough ER, cranking out thousands of protein molecules per second.',
      ),
    ],
  ),
  BioEntity(
    id: 'organelle_golgi_apparatus',
    scale: BioScale.organelle,
    position: 10,
    name: 'Golgi Apparatus',
    title: 'The Packaging Plant',
    imagePath: 'assets/images/golgi-apparatus.png',
    shortDescription: 'A stack of membrane sacs that modifies, sorts, and packages proteins and lipids for shipping.',
    longDescription:
        'The Golgi apparatus is the cell\'s shipping-and-finishing department. It receives proteins and lipids from the ER, chemically modifies them — trimming and adding sugar tags — and then sorts and packages them into vesicles addressed to their destinations, including export from the cell.\n\n'
        'It is directional, like an assembly line: cargo enters at one face (cis), moves through the stack being edited, and leaves polished and labeled at the other (trans).',
    organelleEnum: Organelle.golgi_apparatus,
    relatedIds: ['organelle_rough_er', 'organelle_smooth_er'],
    sections: [
      LessonSection.table(
        title: 'A directional assembly line',
        headers: ['Face', 'Position', 'Role'],
        rows: [
          ['Cis face', 'Facing the ER', 'Receiving dock — takes in vesicles from the ER'],
          ['Medial', 'Middle stack', 'Sequential chemical modification'],
          ['Trans face', 'Facing the membrane', 'Shipping dock — sorts and sends vesicles out'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why edit at all?',
        question: 'The ER already made the protein. Why does it need a second stop at the Golgi to be modified again?',
        answer: 'Because the final chemical tags — precise sugar chains, sorting labels, cleavage into active form — are added in a strict order that requires the Golgi\'s specialized, compartment-by-compartment enzymes. The ER makes a rough draft; the Golgi does the finishing edits and, crucially, attaches the "address labels" that tell each vesicle where in (or out of) the cell to go. Without it, proteins would be made but never correctly finished or delivered.',
      ),
      LessonSection.thinkReveal(
        title: 'Why is it stacked?',
        question: 'The Golgi is a stack of separate sacs rather than one big bag. Why does that architecture matter?',
        answer: 'Because processing is sequential. Each sac holds a different set of enzymes, so cargo is modified in stages as it passes from one to the next — like moving down stations on a factory line. If it were one mixed bag, all the enzymes would act at once and in no order, scrambling the careful step-by-step edits. The separation into stacked compartments IS how the Golgi enforces the correct sequence.',
      ),
      LessonSection.fact(
        title: 'Named for its finder',
        body: 'The Golgi is one of the few organelles named after a person — Camillo Golgi, who spotted it in 1898 with a silver stain and won a Nobel Prize.',
      ),
    ],
  ),
  BioEntity(
    id: 'organelle_microtubules',
    scale: BioScale.organelle,
    position: 11,
    name: 'Microtubules',
    title: 'The Scaffold',
    imagePath: 'assets/images/microtubules.png',
    shortDescription: 'Hollow tubes of tubulin protein that form the cell\'s skeleton and its internal transport rails.',
    longDescription:
        'Microtubules are hollow rods built from the protein tubulin. A polymer is a chain of repeated subunits, and here the subunit is tubulin — thousands of them stack into a stiff tube. Together with microfilaments and intermediate filaments, they make up the cytoskeleton.\n\n'
        'They do more than hold shape. Microtubules are the rails along which motor proteins haul cargo across the cell, and they build the spindle that separates chromosomes during division. Structure and highway in one.',
    organelleEnum: Organelle.microtubules,
    relatedIds: ['organelle_centrioles', 'organelle_cytoplasm'],
    sections: [
      LessonSection.table(
        title: 'The three cytoskeleton fibers',
        headers: ['Fiber', 'Built from', 'Diameter', 'Main job'],
        rows: [
          ['Microtubules', 'Tubulin', '~25 nm', 'Shape, transport rails, spindle'],
          ['Microfilaments', 'Actin', '~7 nm', 'Movement, cell shape changes'],
          ['Intermediate filaments', 'Various proteins', '~10 nm', 'Tensile strength, anchoring'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why hollow?',
        question: 'A solid rod uses less material. Why is a microtubule built as a hollow tube instead?',
        answer: 'Because a hollow tube is far stiffer per gram than a solid rod of the same weight — the same reason bones and bamboo are hollow. Cells need rigidity without dead weight or wasted protein, and a tube resists bending in every direction. It is a structural-engineering solution the cell arrived at long before human bridge-builders did.',
      ),
      LessonSection.thinkReveal(
        title: 'Rails and roads',
        question: 'A nerve cell in your leg is a meter long, but proteins are made near the nucleus at the top. How does cargo reach the far end?',
        answer: 'It rides microtubules. Motor proteins grab vesicles and "walk" them along microtubule tracks like trains on rails, carrying cargo from the cell body all the way to the tip. Diffusion alone would take years over that distance; directed transport does it in days. The cytoskeleton isn\'t just scaffolding — it\'s the highway network, and microtubules are the long-haul routes.',
      ),
      LessonSection.fact(
        title: 'Built to be torn down',
        body: 'Microtubules constantly grow and collapse in minutes — "dynamic instability" — so the cell can rebuild its entire scaffold on demand, which is exactly how it re-tools for division.',
      ),
    ],
  ),
  BioEntity(
    id: 'organelle_centrioles',
    scale: BioScale.organelle,
    position: 12,
    name: 'Centrioles',
    title: 'The Great Divider',
    imagePath: 'assets/images/centrioles.png',
    shortDescription: 'Cylindrical microtubule structures that organize the spindle and help direct cell division.',
    longDescription:
        'Centrioles are cylinders built from microtubules, usually sitting in a pair near the nucleus. Their headline role is cell division: they help organize the spindle apparatus — the array of fibers that pulls duplicated chromosomes into the two new cells.\n\n'
        'They also help template cilia and asters. Interestingly, most flowering plant cells build their spindles without centrioles at all, a reminder that the cell\'s goals are conserved even when its tools differ.',
    organelleEnum: Organelle.centrioles,
    relatedIds: ['organelle_microtubules', 'organelle_dna'],
    sections: [
      LessonSection.table(
        title: 'What centrioles help build',
        headers: ['Structure', 'Role in the cell'],
        rows: [
          ['Spindle', 'Fibers that pull chromosomes apart in division'],
          ['Asters', 'Star-shaped arrays that position the spindle'],
          ['Cilia / flagella', 'Hair-like structures for movement or sensing'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why near the nucleus?',
        question: 'Centrioles cluster right beside the nucleus. Why is that the strategic spot for the "great divider"?',
        answer: 'Because the nucleus holds the chromosomes that have to be split. When division begins, the centrioles move to opposite ends of the cell and string the spindle fibers between them, latching onto the chromosomes in the middle. Starting from beside the genome means the spindle is already anchored to the very cargo it must separate. Location is logistics: you set up the machinery next to what it has to move.',
      ),
      LessonSection.thinkReveal(
        title: 'The plant exception',
        question: 'Most flowering-plant cells have no centrioles at all — yet they still divide perfectly. What does that prove about the centriole?',
        answer: 'That the centriole is one tool for the job, not the job itself. The essential task is organizing a spindle to sort chromosomes; plants accomplish it with other microtubule-organizing regions and no centrioles. Evolution cares about the outcome — clean chromosome separation — and different lineages found different hardware to get there. It is a lesson in separating a function from any one mechanism, exactly the rules-over-implementation idea.',
      ),
      LessonSection.fact(
        title: 'A ninefold symmetry',
        body: 'Each centriole is built from nine triplets of microtubules arranged in a ring — a strikingly precise 9-fold pattern conserved across most of eukaryotic life.',
      ),
    ],
  ),
  BioEntity(
    id: 'organelle_mitochondria',
    scale: BioScale.organelle,
    position: 13,
    name: 'Mitochondria',
    title: 'The Powerhouse',
    imagePath: 'assets/images/mitochondria.png',
    shortDescription: 'The organelle that burns fuel with oxygen to charge ATP — the cell\'s energy currency.',
    longDescription:
        'Mitochondria are the powerhouse of the cell: they take chemical fuel and, using oxygen, store its energy as ATP (adenosine triphosphate). When a cell spends energy, ATP loses a phosphate to become ADP — the split releases energy for reactions, then the mitochondrion recharges it back to ATP. It is a rechargeable battery run millions of times a second.\n\n'
        'Mitochondria are strange in owning their own DNA, a clue that they were once free-living bacteria engulfed by an ancestral cell — the endosymbiotic theory.',
    organelleEnum: Organelle.mitochondrion,
    zoomInIds: ['molecular_atp', 'molecular_carbohydrates'],
    zoomOutIds: ['cell_mesophyll', 'cell_root_hair', 'cell_guard'],
    relatedIds: ['molecular_atp', 'molecular_carbohydrates', 'organelle_chloroplast'],
    sections: [
      LessonSection.table(
        title: 'The ATP ⇄ ADP battery',
        headers: ['State', 'Phosphates', 'Meaning'],
        rows: [
          ['ATP', '3', 'Charged — ready to release energy'],
          ['ADP', '2', 'Spent — one phosphate broken off, energy released'],
          ['Recharge', 'ADP → ATP', 'Mitochondrion re-adds the phosphate using fuel + O₂'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why its own DNA?',
        question: 'Every other organelle relies on the nucleus for instructions. Why does the mitochondrion carry its own separate DNA?',
        answer: 'Because it used to be an independent organism. The best explanation is endosymbiosis: an ancestral cell swallowed a free-living bacterium that could burn oxygen, and instead of digesting it, kept it as a live-in power plant. Over eons most of its genes migrated to the nucleus, but a small core stayed behind. That leftover DNA is a genetic fossil of a merger that made complex life possible.',
      ),
      LessonSection.thinkReveal(
        title: 'Chloroplast\'s mirror',
        question: 'A chloroplast makes sugar and releases oxygen; a mitochondrion consumes sugar and oxygen. How do these two organelles relate?',
        answer: 'They run the same reaction in opposite directions. Chloroplasts use light to build sugar from CO₂ and water, releasing O₂. Mitochondria break sugar back down with O₂, releasing CO₂ and water — and capturing the energy as ATP. Together they form a loop: the chloroplast stores sunlight in sugar, the mitochondrion spends it. In a plant cell, both live side by side, and the whole biosphere runs on that cycle.',
      ),
      LessonSection.fact(
        title: 'Your body-weight in ATP daily',
        body: 'You only hold ~50 grams of ATP at once, but recycle it so fast that you cycle through roughly your entire body weight in ATP every day.',
      ),
    ],
  ),
  BioEntity(
    id: 'organelle_vacuoles',
    scale: BioScale.organelle,
    position: 14,
    name: 'Vacuoles',
    title: 'The Storage Units',
    imagePath: 'assets/images/vacuoles.png',
    shortDescription: 'Membrane-bound sacs that store water, nutrients, and waste and help manage cellular cleanup.',
    longDescription:
        'Vacuoles are membrane-enclosed sacs used for storage and waste management. They hold water, nutrients, ions, and waste products, keeping them safely partitioned from the rest of the cell so metabolism runs cleanly.\n\n'
        'In animal cells they tend to be small and numerous; in plant cells one giant central vacuole often dominates. The membrane around each is what lets the cell control what goes in and what comes out.',
    organelleEnum: Organelle.vacuoles,
    relatedIds: ['organelle_central_vacuole', 'organelle_cytoplasm'],
    sections: [
      LessonSection.table(
        title: 'What a vacuole holds',
        headers: ['Contents', 'Purpose'],
        rows: [
          ['Water', 'Volume, pressure, dilution'],
          ['Nutrients / ions', 'Reserves for later use'],
          ['Waste', 'Isolated until disposed'],
          ['Pigments / defenses (plants)', 'Color and protection'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why wrap waste in a membrane?',
        question: 'Why does the cell bother enclosing its garbage in a membrane instead of just letting it float in the cytoplasm?',
        answer: 'Because unwrapped waste is dangerous. Many byproducts are reactive, acidic, or toxic — left loose, they would corrode enzymes and disrupt reactions everywhere. The vacuole membrane quarantines them, letting the cell store or process waste on its own terms. It is the same logic as a sealed trash bin versus scattering rubbish across the floor: containment is what keeps the workspace usable.',
      ),
      LessonSection.thinkReveal(
        title: 'Plant vs animal vacuoles',
        question: 'Animal cells have many small vacuoles; a plant cell usually has one huge central one. What does that difference reveal about their lives?',
        answer: 'Their pressure strategies differ. Plant cells have rigid walls and use a single big vacuole to inflate against that wall, holding the plant upright — pressure is a structural tool. Animal cells have no wall and must avoid bursting, so they keep vacuoles small and flexible for targeted storage and transport. The size of the vacuole is a fingerprint of whether the cell relies on internal water pressure to keep its shape.',
      ),
      LessonSection.fact(
        title: 'A shape-shifting sac',
        body: 'Some single-celled organisms use a "contractile vacuole" that swells with excess water and squeezes it out — a built-in bilge pump firing every few seconds.',
      ),
    ],
  ),
  BioEntity(
    id: 'organelle_peroxisomes',
    scale: BioScale.organelle,
    position: 15,
    name: 'Peroxisomes',
    title: 'The Oxidative Metabolite',
    imagePath: 'assets/images/peroxisomes.png',
    shortDescription: 'Small organelles that break down fats and neutralize toxic free radicals and hydrogen peroxide.',
    longDescription:
        'Peroxisomes detoxify the cell and metabolize lipids. Their signature task is neutralizing free radicals — reactive molecules missing an electron, which "steal" electrons from other molecules and damage the cell in the process.\n\n'
        'They break fatty acids down and handle hydrogen peroxide, a toxic byproduct, converting it to harmless water. Small but vital, they are the cell\'s chemical hazard team.',
    organelleEnum: Organelle.peroxisome,
    relatedIds: ['organelle_smooth_er'],
    sections: [
      LessonSection.table(
        title: 'Peroxisome duties',
        headers: ['Task', 'Why it matters'],
        rows: [
          ['Break down fatty acids', 'Frees energy and building blocks'],
          ['Neutralize free radicals', 'Prevents electron-stealing damage'],
          ['Convert H₂O₂ → water', 'Destroys a toxic byproduct'],
          ['Detoxify (e.g. alcohol)', 'Protects the cell from poisons'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why are free radicals dangerous?',
        question: 'A free radical is just a molecule missing one electron. Why is that tiny shortage so destructive?',
        answer: 'Because it starts a chain reaction. A radical grabs an electron from a neighboring molecule to complete itself — but that leaves the neighbor short one electron, so now IT is a radical, and it robs the next molecule. One radical can trigger a cascade that damages membranes, proteins, and DNA down the line. Peroxisomes halt the cascade by supplying electrons safely, breaking the chain before it spreads.',
      ),
      LessonSection.thinkReveal(
        title: 'Making poison to fight poison',
        question: 'Peroxisomes generate hydrogen peroxide — which is itself toxic — as part of their work. Why produce a poison on purpose?',
        answer: 'Because it is a controlled weapon. Peroxisomes use hydrogen peroxide to oxidize and break down other harmful substances, then immediately destroy the leftover peroxide with the enzyme catalase, splitting it into water and oxygen. The danger is real but boxed in: the reactive chemistry happens inside the sealed organelle and is quenched before it escapes. It is the cell handling a hazardous reagent safely inside a fume hood.',
      ),
      LessonSection.fact(
        title: 'One of the fastest enzymes known',
        body: 'Catalase, packed inside peroxisomes, can break down millions of hydrogen peroxide molecules per second — among the highest turnover rates of any enzyme.',
      ),
    ],
  ),
  BioEntity(
    id: 'organelle_cytoplasm',
    scale: BioScale.organelle,
    position: 16,
    name: 'Cytoplasm',
    title: 'The Gelatinous Body',
    imagePath: 'assets/images/cytoplasm.png',
    shortDescription: 'The gel-like fluid that fills the cell, holds the organelles in place, and hosts countless reactions.',
    longDescription:
        'Cytoplasm fills and shapes the cell, giving every other organelle a stable, supportive medium to work in and holding them all in position — without it, they would deflate and collapse inward. It is also where a huge share of the cell\'s chemistry happens.\n\n'
        'The portion of cytoplasm with no organelles floating in it — the pure fluid — is called the cytosol. Together they form the crowded, active body of the cell.',
    organelleEnum: Organelle.cytoplasm,
    relatedIds: ['organelle_microtubules', 'organelle_plasma_membrane'],
    sections: [
      LessonSection.table(
        title: 'Cytoplasm vs cytosol',
        headers: ['Term', 'What it includes'],
        rows: [
          ['Cytoplasm', 'Everything inside the membrane except the nucleus — fluid + organelles'],
          ['Cytosol', 'Just the fluid, with no organelles suspended in it'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why does it hold shape?',
        question: 'Cytoplasm is described as gel-like, not watery. Why would a thin, water-like fill be worse for the cell?',
        answer: 'Because organelles need to stay put. A gel-like consistency suspends and cushions the organelles at their working positions, resists collapse, and slows things from crashing together randomly. Pure water would let everything settle, clump, or drift out of place, and the cell would lose its internal organization. The slight thickness is what turns a bag of parts into an ordered workspace.',
      ),
      LessonSection.thinkReveal(
        title: 'A crowded, working fluid',
        question: 'Is the cytoplasm just packing material, or is it doing chemistry itself?',
        answer: 'It is doing chemistry. Many core metabolic reactions — including the first stage of breaking down sugar, glycolysis — happen right in the cytosol, not inside any organelle. It is jammed with enzymes, nutrients, and ions, making it a reaction medium as much as a support. Calling it "just filler" undersells it; the fluid between the organelles is one of the busiest chemical arenas in the cell.',
      ),
      LessonSection.fact(
        title: 'Molecular gridlock',
        body: 'The cytoplasm is so crowded with molecules that proteins can bump into ~100,000 neighbors per second — a traffic jam that actually speeds many reactions up.',
      ),
    ],
  ),
  BioEntity(
    id: 'organelle_plasma_membrane',
    scale: BioScale.organelle,
    position: 17,
    name: 'Plasma Membrane',
    title: 'The Skin',
    imagePath: 'assets/images/plasma-membrane.png',
    shortDescription: 'The lipid bilayer that wraps the cell, separating inside from outside and controlling all traffic across.',
    longDescription:
        'The plasma membrane — the cell membrane — is a lipid bilayer that separates the cell from the outside world. Its fatty double layer is naturally waterproof, so most molecules cannot cross unaided.\n\n'
        'Studded through it are proteins that act as gates, pumps, and sensors, allowing safe and selective transport in and out. This "selective permeability" is what lets the cell keep its interior different from its surroundings.',
    organelleEnum: Organelle.cell_membrane,
    zoomInIds: ['molecular_lipids'],
    relatedIds: ['organelle_cell_wall', 'organelle_cytoplasm'],
    sections: [
      LessonSection.table(
        title: 'Crossing the membrane',
        headers: ['Mode', 'Needs energy?', 'Example'],
        rows: [
          ['Simple diffusion', 'No', 'O₂ and CO₂ slip straight through'],
          ['Facilitated diffusion', 'No', 'Glucose rides a carrier protein'],
          ['Active transport', 'Yes (ATP)', 'Pumps push ions against the gradient'],
          ['Bulk transport', 'Yes', 'Vesicles engulf or expel large cargo'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why a fatty double layer?',
        question: 'The membrane is built from two layers of lipid with their oily tails facing inward. Why that specific arrangement?',
        answer: 'Because the cell lives in water, and lipids have a split personality: a water-loving head and a water-fearing tail. In water, they self-assemble so the tails hide inside, shielded, and the heads face the watery inside and outside. That sandwich creates an oily core that water and most dissolved molecules can\'t cross — an automatic, self-healing barrier. The cell didn\'t have to engineer the wall; the chemistry of oil and water builds it spontaneously.',
      ),
      LessonSection.thinkReveal(
        title: 'Why "selective"?',
        question: 'A barrier that blocks everything would keep the cell perfectly safe. Why does the membrane let some things through instead?',
        answer: 'Because a cell that can\'t take in food or expel waste is a dead cell. The membrane\'s value is in being selective, not sealed: its embedded proteins choose exactly which molecules cross, and in which direction. That control is what lets the cell keep its inside chemically different from the outside — high in some ions, low in others — which is the basis of nerve signals, nutrient uptake, and life itself. Selectivity, not isolation, is the point.',
      ),
      LessonSection.fact(
        title: 'Thinner than you can imagine',
        body: 'The plasma membrane is only ~5 nanometers thick — you\'d stack ~10,000 of them to equal the width of a single sheet of paper.',
      ),
    ],
  ),
  // 4 new plant-specific organelles
  BioEntity(
    id: 'organelle_chloroplast',
    scale: BioScale.organelle,
    position: 18,
    name: 'Chloroplast',
    title: 'The Solar Panel',
    shortDescription: 'The plant organelle that captures sunlight and turns it, water, and CO₂ into sugar and oxygen.',
    longDescription:
        'Chloroplasts make plant life — and by extension nearly all life on Earth — possible. Inside their double membrane sit stacks of disc-like thylakoids (a stack is a granum), where the light-dependent reactions run: chlorophyll absorbs sunlight, uses it to split water, and generates ATP, NADPH, and the oxygen you breathe.\n\n'
        'That energy then drives the Calvin cycle in the surrounding fluid (the stroma), where CO₂ is fixed into glucose. Like mitochondria, chloroplasts carry their own DNA — evidence they were once free-living photosynthetic bacteria taken in by an ancestral cell.',
    zoomInIds: ['molecular_carbon', 'molecular_atp', 'molecular_carbohydrates'],
    zoomOutIds: ['cell_mesophyll'],
    relatedIds: ['molecular_carbon', 'molecular_carbohydrates', 'organelle_mitochondria', 'cell_mesophyll', 'organ_leaf'],
    sections: [
      LessonSection.table(
        title: 'The two halves of photosynthesis',
        headers: ['Stage', 'Where', 'Input', 'Output'],
        rows: [
          ['Light reactions', 'Thylakoids (grana)', 'Sunlight, water', 'ATP, NADPH, O₂'],
          ['Calvin cycle', 'Stroma', 'CO₂, ATP, NADPH', 'Glucose'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Where does the sugar come from?',
        question: 'A plant builds itself out of solid matter — wood, leaves, potatoes. Where does most of that mass actually come from?',
        answer: 'Out of thin air. The carbon in a plant\'s body is pulled from carbon dioxide gas in the atmosphere and fixed into sugar by the chloroplast, using energy from sunlight. Water contributes, but the bulk of the dry mass is captured CO₂ — not soil. A tree, or a potato, is in a very real sense built from air and light. The chloroplast is the machine that performs that near-magical conversion.',
      ),
      LessonSection.thinkReveal(
        title: 'Two organelles, one bargain',
        question: 'Chloroplasts and mitochondria both carry their own DNA. What shared history does that hint at, and why does it matter?',
        answer: 'Both descend from once-free-living bacteria that were engulfed and kept — chloroplasts from photosynthetic bacteria, mitochondria from oxygen-burning ones. This endosymbiosis is one of the deepest events in life\'s history: it gave cells both a way to capture sunlight and a way to burn its products, powering the leap to complex life. The leftover DNA in each is the receipt for that ancient merger.',
      ),
      LessonSection.fact(
        title: 'The engine of the food chain',
        body: 'Photosynthesis in chloroplasts and algae fixes ~100+ billion tonnes of carbon into sugar every year — the base of nearly every food chain on Earth.',
      ),
      LessonSection.paragraph(
        title: 'Why farmers care',
        body: 'Chloroplast efficiency sets a ceiling on crop yield. Researchers are engineering photosynthesis to work faster or waste less energy, with early results suggesting yield gains of ~20–40% — a direct lever on how much food a field can produce.',
      ),
    ],
  ),
  BioEntity(
    id: 'organelle_cell_wall',
    scale: BioScale.organelle,
    position: 19,
    name: 'Cell Wall',
    title: 'The Rigid Armor',
    shortDescription: 'A tough cellulose layer outside the plasma membrane that gives plant cells shape and strength.',
    longDescription:
        'The cell wall is a defining feature of plant cells — a rigid outer layer that provides shape, support, and protection. It is built mainly of cellulose, long chains of glucose woven into strong microfibrils, plus hemicellulose, pectin, and sometimes lignin.\n\n'
        'A flexible primary wall is laid down as the cell grows; afterward, many cells add a thicker, rigid secondary wall inside it. Heavily lignified secondary walls in xylem become wood — the structural backbone of stems and trees.',
    zoomInIds: ['molecular_carbohydrates'],
    zoomOutIds: ['cell_xylem_vessel'],
    relatedIds: ['organelle_plasma_membrane', 'molecular_carbohydrates', 'cell_xylem_vessel'],
    sections: [
      LessonSection.table(
        title: 'Primary vs secondary wall',
        headers: ['Feature', 'Primary wall', 'Secondary wall'],
        rows: [
          ['Laid down', 'During cell growth', 'After growth stops'],
          ['Flexibility', 'Flexible, extensible', 'Thick and rigid'],
          ['Key material', 'Cellulose, pectin', 'Cellulose + lignin'],
          ['Example', 'Young growing cells', 'Wood (xylem vessels)'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Wall vs membrane',
        question: 'Plant cells already have a plasma membrane. Why add a rigid wall on top of it — isn\'t one barrier enough?',
        answer: 'They do different jobs. The membrane is selective and controls what enters and leaves, but it is soft and can\'t resist pressure. The wall is structural: it withstands the outward push of the water-filled vacuole so the cell can pressurize without bursting — which is how non-woody plants stand upright. Membrane = gatekeeper, wall = armor and skeleton. A plant needs both because it has no bones and can\'t run from harm.',
      ),
      LessonSection.thinkReveal(
        title: 'Why timber is a locked treasure',
        question: 'Cellulose is just chains of glucose — pure sugar energy. So why can\'t most animals eat wood?',
        answer: 'Because the glucose is bonded in a way animal enzymes can\'t cut. Cellulose links glucose with beta bonds that our digestive enzymes don\'t recognize, so the energy is locked away as fiber. Cows and termites only manage it by hosting microbes that carry the special enzyme. This same tough bond is why the biofuel industry works so hard to break cellulose down into fermentable sugar — the energy is right there, behind a chemical lock.',
      ),
      LessonSection.fact(
        title: 'Earth\'s most abundant biomolecule',
        body: 'Cellulose is the most common organic polymer on the planet, with an estimated ~100+ billion tonnes made by plants each year.',
      ),
    ],
  ),
  BioEntity(
    id: 'organelle_central_vacuole',
    scale: BioScale.organelle,
    position: 20,
    name: 'Central Vacuole',
    title: 'The Pressure Regulator',
    shortDescription: 'A huge water-filled sac that pressurizes the plant cell, keeping tissues firm, and stores nutrients.',
    longDescription:
        'The central vacuole is one of the largest features of a mature plant cell, often filling 80–90% of its volume. Bounded by a membrane called the tonoplast, it holds cell sap — water, ions, sugars, amino acids, pigments, and defensive compounds. Fundamentally, it is a pressure vessel.\n\n'
        'By pulling in water through osmosis, it generates turgor pressure that pushes the membrane against the cell wall, keeping soft plant tissues firm and upright. When a plant wilts, that pressure has dropped. It also stores nutrients and pigments and recycles worn-out cell parts.',
    zoomOutIds: ['cell_guard'],
    relatedIds: ['organelle_vacuoles', 'cell_guard', 'organ_leaf'],
    sections: [
      LessonSection.table(
        title: 'Jobs of the central vacuole',
        headers: ['Job', 'How / why'],
        rows: [
          ['Turgor pressure', 'Osmosis pulls water in, pushing on the wall'],
          ['Storage', 'Holds sugars, ions, amino acids'],
          ['Color', 'Stores pigments like anthocyanins'],
          ['Defense', 'Keeps bitter or toxic deterrent compounds'],
          ['Recycling', 'Breaks down and reclaims old organelles'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why does lettuce wilt?',
        question: 'A crisp leaf goes limp when it dries out. In terms of the central vacuole, what actually changed?',
        answer: 'It lost water, and with it, turgor pressure. A firm plant cell is one whose central vacuole is full and pressing outward against the cell wall — that internal pressure is what makes leaves and stems rigid, since plants have no skeleton. When water is lost faster than it\'s replaced, the vacuoles shrink, the pressure drops, and the whole tissue sags. Watering a wilted plant re-inflates every vacuole and it stiffens back up.',
      ),
      LessonSection.thinkReveal(
        title: 'Why so huge?',
        question: 'The central vacuole can fill 80–90% of a plant cell. Why would a cell hand over almost all its room to one water sac?',
        answer: 'Because it is a cheap way to get big and strong. Filling most of the cell with water lets the plant grow large and hold its shape without building expensive protein or extra cytoplasm — water is free and plentiful. It also pushes the cytoplasm and chloroplasts into a thin outer layer, right against the light and the wall where they work best. A giant vacuole is the plant\'s low-cost solution to size and structure.',
      ),
      LessonSection.fact(
        title: 'The pressure of a tire',
        body: 'Turgor pressure inside a plant cell can reach several atmospheres — comparable to or higher than the air pressure in a car tire.',
      ),
    ],
  ),
  BioEntity(
    id: 'organelle_plasmodesmata',
    scale: BioScale.organelle,
    position: 21,
    name: 'Plasmodesmata',
    title: 'The Cellular Bridges',
    shortDescription: 'Tiny channels through plant cell walls that directly connect neighboring cells into one network.',
    longDescription:
        'Plasmodesmata are tiny channels (~40–50 nanometers wide) that pass through the walls of adjacent plant cells, creating direct cytoplasm-to-cytoplasm connections. Through them, water, ions, small molecules, and even some proteins and RNA move cell to cell without crossing any membrane. This interconnected web of shared cytoplasm is called the symplast.\n\n'
        'Each channel is lined by plasma membrane and threaded by a fine tube of ER called the desmotubule; molecules travel through the space around it. Plants widen or pinch these channels to control the flow — opening them in development, closing them under attack.',
    zoomOutIds: ['cell_mesophyll', 'cell_phloem_sieve_tube'],
    relatedIds: ['organelle_cell_wall', 'organelle_plasma_membrane', 'tissue_vascular'],
    sections: [
      LessonSection.table(
        title: 'Anatomy of a bridge',
        headers: ['Part', 'What it is'],
        rows: [
          ['Channel', 'A pore piercing the shared cell wall'],
          ['Membrane lining', 'Plasma membrane, continuous between cells'],
          ['Desmotubule', 'A thin tube of ER running through the middle'],
          ['Cytoplasmic sleeve', 'The gap around the desmotubule — the actual path'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why plants need bridges',
        question: 'Animal cells signal each other with hormones through the bloodstream. Why do walled plant cells need physical channels instead?',
        answer: 'Because the cell wall is in the way. Every plant cell is boxed in rigid cellulose, which blocks the easy membrane-to-membrane contact animal cells use. Plasmodesmata punch through that wall to give neighbors a direct cytoplasmic hotline — sharing nutrients and signals without shipping everything the long way around through the wall. The wall that gives plants their strength also isolates their cells; plasmodesmata are the workaround that reconnects them.',
      ),
      LessonSection.thinkReveal(
        title: 'A door a virus can use',
        question: 'Plasmodesmata are great for cooperation — but why are they also a security risk during infection?',
        answer: 'Because a channel built to pass molecules between cells is exactly what a virus needs to spread. Some plant viruses make "movement proteins" that pry plasmodesmata open wider and slip their genetic material through to the next cell — hijacking the plant\'s own communication grid. This is why the plant can actively pinch these channels shut when it senses attack, sealing off infected cells. The same bridge is both the nervous system and the vulnerability.',
      ),
      LessonSection.fact(
        title: 'One giant connected body',
        body: 'Through plasmodesmata, most of the living cells in a plant share a continuous cytoplasm — the symplast — effectively wiring the whole organism into one network.',
      ),
    ],
  ),
];
