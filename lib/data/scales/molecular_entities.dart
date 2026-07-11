import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

const molecularEntities = <BioEntity>[
  BioEntity(
    id: 'molecular_water',
    scale: BioScale.molecular,
    position: 0,
    name: 'Water',
    title: 'The Universal Solvent',
    shortDescription: 'H₂O — two hydrogens bonded to one oxygen at 104.5°, creating the polar molecule that makes all life possible.',
    longDescription:
        'Water is the most extraordinary molecule in biology. Its bent shape — two hydrogen atoms bonded to one oxygen at a 104.5° angle — creates a polar molecule with a slightly negative oxygen end and slightly positive hydrogen ends. This polarity is everything. It lets water molecules form hydrogen bonds with each other and with other polar molecules, giving water its remarkable properties.\n\n'
        'Because it is polar, water dissolves more substances than any other liquid: ions, sugars, amino acids, and gases all go into solution. That makes it the medium in which all biochemistry occurs. The cytoplasm is mostly water, blood is mostly water, the vacuole is filled with water. Life is, fundamentally, chemistry happening in water — and in agriculture, water availability is the single most limiting factor for crop production worldwide.',
    zoomOutIds: ['organelle_central_vacuole', 'organelle_cytoplasm'],
    relatedIds: ['molecular_carbohydrates', 'cell_guard', 'cell_xylem_vessel', 'ecosystem_water_cycle'],
    sections: [
      LessonSection.table(
        title: 'Water\'s strange properties',
        headers: ['Property', 'Value', 'Why it matters'],
        rows: [
          ['Bond angle', '104.5°', 'Bends the molecule into a polar dipole'],
          ['Boiling point', '100 °C', 'Absurdly high for its size — hydrogen bonds hold it together'],
          ['Specific heat', '~4.18 J/g·°C', 'Resists temperature swings; buffers cells and climate'],
          ['Ice vs. liquid', 'Ice ~9% less dense', 'Solid floats on its own liquid — almost unique'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The floating solid',
        question: 'Nearly every solid sinks in its own liquid. Why does ice float?',
        answer:
            'Hydrogen bonds lock water molecules into an open hexagonal lattice with more empty space than liquid water, so ice is ~9% less dense and rides on top. Consequence: lakes freeze top-down, and the ice sheet insulates the living water below instead of the whole pond freezing solid.',
      ),
      LessonSection.thinkReveal(
        title: 'The 200-litre "waste"',
        question: 'A corn plant transpires ~200 L of water in a season and keeps almost none of it. Why spend so much?',
        answer:
            'Transpiration is the toll for open stomata. To let CO₂ in for photosynthesis, water inevitably escapes the same pores. That loss is not wasted: the evaporative pull drags water and dissolved minerals up from the roots and cools the leaf. It is the unavoidable cost of doing carbon business.',
      ),
      LessonSection.fact(
        title: 'Thirsty crop',
        body: 'A single corn plant transpires roughly 200 litres of water over one growing season.',
      ),
    ],
  ),
  BioEntity(
    id: 'molecular_nucleic_acids',
    scale: BioScale.molecular,
    position: 1,
    name: 'Nucleic Acids',
    title: 'The Information Carriers',
    shortDescription: 'DNA and RNA — long polymers of nucleotides that store, transmit, and execute the genetic instructions for all living organisms.',
    longDescription:
        'Nucleic acids are the information molecules of life. DNA stores the complete genetic blueprint in its double helix — two antiparallel strands held together by hydrogen bonds between complementary bases: adenine with thymine, guanine with cytosine. RNA is the working copy — single-stranded, versatile, and essential for translating genetic instructions into proteins.\n\n'
        'Each nucleotide is three parts: a five-carbon sugar (deoxyribose in DNA, ribose in RNA), a phosphate group, and a nitrogenous base. The sugar-phosphate backbone provides structure while the sequence of bases carries the information. That sequence — the genetic code, read three bases at a time — specifies the amino acid sequence of every protein the organism can make. In agriculture, this molecule is the foundation of marker-assisted selection, genetic engineering, and CRISPR editing.',
    zoomOutIds: ['organelle_dna', 'organelle_rna', 'organelle_nucleotide'],
    relatedIds: ['molecular_proteins', 'molecular_atp', 'organelle_ribosomes'],
    sections: [
      LessonSection.table(
        title: 'DNA vs. RNA',
        headers: ['Feature', 'DNA', 'RNA'],
        rows: [
          ['Sugar', 'Deoxyribose', 'Ribose'],
          ['Strands', 'Double helix', 'Usually single'],
          ['Bases', 'A · T · G · C', 'A · U · G · C'],
          ['Role', 'Archive / master copy', 'Working copy / messenger'],
          ['Stability', 'High (built to last)', 'Low (made and destroyed fast)'],
        ],
      ),
      LessonSection.table(
        title: 'Base pairing',
        headers: ['Base', 'Pairs with', 'Hydrogen bonds'],
        rows: [
          ['Adenine (A)', 'Thymine (T) — Uracil (U) in RNA', '2'],
          ['Guanine (G)', 'Cytosine (C)', '3'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The stronger stitch',
        question: 'G–C pairs use three hydrogen bonds, A–T only two. Which DNA region is harder to pull apart — and how do heat-loving microbes exploit that?',
        answer:
            'GC-rich stretches take more energy to separate, so they "melt" at higher temperature. Thermophiles living in hot springs tend toward GC-rich genomes precisely to keep their DNA zipped together in the heat.',
      ),
      LessonSection.thinkReveal(
        title: 'Archive vs. worker',
        question: 'Why keep the master copy as double-stranded DNA but do the daily work with single-stranded RNA?',
        answer:
            'Two complementary strands give a built-in backup: if one is damaged, the other is the repair template. That redundancy makes DNA a stable archive. RNA is deliberately disposable and single-stranded so it can fold into working shapes and be produced or shredded on demand. Separating the archive from the worker protects the information.',
      ),
      LessonSection.fact(
        title: 'The triplet code',
        body: 'Three bases (a codon) specify one amino acid — a 4-letter alphabet read in triplets makes 64 codons for ~20 amino acids.',
      ),
    ],
  ),
  BioEntity(
    id: 'molecular_proteins',
    scale: BioScale.molecular,
    position: 2,
    name: 'Proteins',
    title: 'The Molecular Machines',
    shortDescription: 'Chains of amino acids folded into precise 3D shapes that perform nearly every function in a living cell — enzymes, transporters, structural supports, and signals.',
    longDescription:
        'Proteins are the workhorses of biology. Made from chains of 20 different amino acids linked by peptide bonds, each protein folds into a unique three-dimensional shape determined by its sequence. That shape IS the function: an enzyme\'s active site fits its substrate like a lock and key, a channel\'s pore is exactly sized for its ion, a structural fibre has exactly the right tensile strength.\n\n'
        'Proteins do almost everything a cell needs. Enzymes catalyze reactions (RuBisCO fixes carbon), transporters move molecules across membranes (aquaporins shuttle water), structural proteins build scaffolding (tubulin forms microtubules), signalling proteins carry messages, and defensive proteins fight pathogens. In agriculture, protein content is a key measure of nutritional value — from wheat gluten to soybeans at ~40% protein by weight.',
    zoomOutIds: ['organelle_ribosomes', 'organelle_rough_er'],
    relatedIds: ['molecular_nucleic_acids', 'molecular_carbon'],
    sections: [
      LessonSection.table(
        title: 'Four levels of protein structure',
        headers: ['Level', 'What it is', 'Held together by'],
        rows: [
          ['Primary', 'The amino acid sequence', 'Peptide bonds'],
          ['Secondary', 'Local helices and sheets', 'Hydrogen bonds'],
          ['Tertiary', 'The full 3D fold', 'Side-chain interactions, disulfide bridges'],
          ['Quaternary', 'Several folded chains joined', 'Same forces, between subunits'],
        ],
      ),
      LessonSection.table(
        title: 'One molecule, many jobs',
        headers: ['Type', 'Example', 'Function'],
        rows: [
          ['Enzyme', 'RuBisCO', 'Fixes CO₂ in photosynthesis'],
          ['Transport', 'Aquaporin', 'Moves water across membranes'],
          ['Structural', 'Tubulin', 'Builds microtubules'],
          ['Signalling', 'Phytochrome', 'Senses light for the plant'],
          ['Defense', 'Defensins', 'Attack pathogens'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'One swap, whole machine broken',
        question: 'A single amino acid change out of hundreds can destroy a protein. Why does one letter matter so much?',
        answer:
            'The sequence dictates the fold, and the fold is the function. One wrong side chain can misfold the entire shape or distort the active-site geometry — the lock no longer accepts its key. Sickle-cell anemia is exactly this: a single amino acid swap in hemoglobin.',
      ),
      LessonSection.thinkReveal(
        title: 'Reused, not consumed',
        question: 'Enzymes accelerate reactions millions of times over yet are not used up. How?',
        answer:
            'An enzyme is a catalyst: it lowers the activation energy by holding the reactants in the perfect orientation and straining the bonds about to break, then releases the products unchanged and grabs the next pair. It shapes the reaction without being part of the product.',
      ),
      LessonSection.fact(
        title: '20 letters, every machine',
        body: 'Just 20 amino acids, chained in any order, build every protein in every organism on Earth.',
      ),
    ],
  ),
  BioEntity(
    id: 'molecular_lipids',
    scale: BioScale.molecular,
    position: 3,
    name: 'Lipids',
    title: 'The Barrier Builders',
    shortDescription: 'Fats, oils, waxes, and phospholipids — hydrophobic molecules that form membranes, store energy, and waterproof surfaces.',
    longDescription:
        'Lipids are a diverse group of hydrophobic (water-fearing) molecules united by their insolubility in water. The most important are phospholipids, which form the bilayer membranes enclosing every cell and organelle. Each phospholipid has a hydrophilic head (attracted to water) and two hydrophobic fatty-acid tails (repelled by it). In water they spontaneously arrange into bilayers — the fundamental architecture of all biological membranes.\n\n'
        'Beyond membranes, lipids store concentrated energy (twice as much per gram as carbohydrate), waterproof surfaces (cutin and suberin coat leaves and roots), carry signals (jasmonic acid, brassinosteroids), and act as pigments (carotenoids). In agriculture they are economically crucial: oilseed crops such as soybean, canola, palm, and sunflower are grown primarily for their lipids, and the waxy cuticle is a frontline defense against water loss and pathogens.',
    zoomOutIds: ['organelle_smooth_er', 'organelle_plasma_membrane'],
    relatedIds: ['molecular_water', 'molecular_carbon', 'molecular_carbohydrates'],
    sections: [
      LessonSection.table(
        title: 'Energy density of the three fuels',
        headers: ['Molecule', 'Energy per gram', 'Typical role'],
        rows: [
          ['Fat / oil', '~9 kcal/g', 'Concentrated long-term storage'],
          ['Carbohydrate', '~4 kcal/g', 'Quick, accessible fuel'],
          ['Protein', '~4 kcal/g', 'Last-resort fuel; mainly machinery'],
        ],
      ),
      LessonSection.table(
        title: 'The lipid family',
        headers: ['Type', 'Example', 'Job'],
        rows: [
          ['Phospholipid', 'Membrane lipid', 'Forms the bilayer of every membrane'],
          ['Wax', 'Cutin', 'Waterproofs leaf and fruit surfaces'],
          ['Storage fat', 'Triglyceride', 'Dense energy reserve'],
          ['Pigment', 'Carotenoid', 'Photoprotection; colour of carrots/tomatoes'],
          ['Hormone', 'Brassinosteroid', 'Signalling molecule'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'A wall that builds itself',
        question: 'Phospholipids form a sealed bilayer in water with zero energy input. What drives it?',
        answer:
            'The hydrophobic tails cannot tolerate water, so they tuck inward while the water-loving heads face out — a bilayer is simply the lowest-energy arrangement. The ordering of surrounding water (the "hydrophobic effect") powers the assembly. No pump required; the membrane self-heals for the same reason.',
      ),
      LessonSection.thinkReveal(
        title: 'Why seeds pack oil, not starch',
        question: 'Starch is cheaper to synthesize, yet many seeds store their reserves as oil. Why pay the extra cost?',
        answer:
            'Fat holds ~2× the energy per gram, so an oily seed carries far more fuel per unit weight — lighter for wind or animal dispersal and a denser reserve to launch the seedling before it can photosynthesize. Energy density beats production cost.',
      ),
      LessonSection.fact(
        title: 'Twice the punch',
        body: 'Fats store ~9 kcal per gram — more than double the ~4 kcal/g of carbohydrates.',
      ),
    ],
  ),
  BioEntity(
    id: 'molecular_carbohydrates',
    scale: BioScale.molecular,
    position: 4,
    name: 'Carbohydrates',
    title: 'The Energy & Structure Dual',
    shortDescription: 'Sugars, starches, and cellulose — carbon-hydrogen-oxygen molecules that fuel cellular processes and build structural walls.',
    longDescription:
        'Carbohydrates are molecules of carbon, hydrogen, and oxygen — typically in a 1:2:1 ratio, giving the general formula (CH₂O)n. They range from simple sugars (monosaccharides like glucose and fructose) to complex polymers (polysaccharides like starch, cellulose, and chitin). This single class serves two radically different purposes: energy and structure.\n\n'
        'As fuel, glucose is the universal energy molecule, broken down to make ATP; starch and glycogen store it; sucrose transports it through the phloem. As structure, cellulose — the same glucose in a different bond geometry — forms the rigid walls of plants and is the most abundant organic molecule on Earth. In agriculture, carbohydrates ARE the harvest: grain is starch, sugarcane is sucrose, cotton is cellulose.',
    zoomOutIds: ['organelle_chloroplast', 'organelle_mitochondria', 'organelle_cell_wall'],
    relatedIds: ['molecular_water', 'molecular_atp', 'molecular_carbon'],
    sections: [
      LessonSection.table(
        title: 'The carbohydrate ladder',
        headers: ['Class', 'Example', 'Structure'],
        rows: [
          ['Monosaccharide', 'Glucose', 'Single sugar ring'],
          ['Disaccharide', 'Sucrose', 'Glucose + fructose'],
          ['Polysaccharide', 'Starch / cellulose', 'Long glucose polymer'],
        ],
      ),
      LessonSection.table(
        title: 'Same monomer, opposite jobs',
        headers: ['Molecule', 'Glucose bond', 'Role'],
        rows: [
          ['Starch', 'alpha-1,4', 'Energy storage (plants)'],
          ['Glycogen', 'alpha-1,4 + branches', 'Energy storage (animals)'],
          ['Cellulose', 'beta-1,4', 'Structural cell wall'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Digestible vs. not',
        question: 'Starch and cellulose are both pure glucose chains. Why can you digest starch but not cellulose?',
        answer:
            'It comes down to bond geometry. Starch links glucose with alpha-1,4 bonds our amylase can cut. Cellulose uses beta-1,4 bonds, which flip every second glucose 180°, producing a straight, rigid, tightly hydrogen-bonded fibre our enzymes cannot touch. Same brick, opposite mortar.',
      ),
      LessonSection.thinkReveal(
        title: 'Why "choose" the indigestible form?',
        question: 'Cellulose is the most abundant organic molecule on Earth. Why did plants build their walls from the version almost nothing can eat?',
        answer:
            'Precisely because it is tough and inert. The beta bonds create straight chains that hydrogen-bond into strong crystalline fibres — an excellent building material exactly because so few organisms can break it down. Durability is the point, not a flaw.',
      ),
      LessonSection.fact(
        title: 'Earth\'s most abundant molecule',
        body: 'Cellulose is the single most abundant organic molecule on the planet.',
      ),
    ],
  ),
  BioEntity(
    id: 'molecular_atp',
    scale: BioScale.molecular,
    position: 5,
    name: 'ATP',
    title: 'The Energy Currency',
    shortDescription: 'Adenosine triphosphate — a nucleotide carrying three phosphate groups whose bonds release energy to power virtually every cellular process.',
    longDescription:
        'Adenosine triphosphate (ATP) is the universal energy currency of all living cells: an adenine base, a ribose sugar, and three phosphate groups in a chain. The energy sits in the bonds between those phosphates. When the terminal phosphate is cleaved by water, ATP becomes ADP and releases energy that drives everything from muscle contraction to DNA replication to ion transport.\n\n'
        'ATP is made two main ways. In photosynthesis, the light reactions in chloroplast thylakoids capture sunlight to make it (photophosphorylation); in respiration, mitochondria oxidize glucose through glycolysis, the citric acid cycle, and the electron transport chain (oxidative phosphorylation), yielding roughly 30-38 ATP per glucose. The cell does not stockpile it — ATP is made and spent continuously, turning over its entire pool every minute or two.',
    zoomOutIds: ['organelle_mitochondria', 'organelle_chloroplast'],
    relatedIds: ['molecular_carbohydrates', 'molecular_proteins', 'molecular_water'],
    sections: [
      LessonSection.table(
        title: 'ATP yield from one glucose',
        headers: ['Pathway', 'Location', '~ATP'],
        rows: [
          ['Glycolysis', 'Cytoplasm', '~2'],
          ['Citric acid cycle', 'Mitochondrial matrix', '~2'],
          ['Electron transport chain', 'Inner mitochondrial membrane', '~26-34'],
          ['Total', 'Complete oxidation', '~30-38'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The battery, not the tank',
        question: 'The body makes and burns roughly its own weight in ATP daily, yet holds only ~250 g at any instant. How?',
        answer:
            'ATP is not stored, it is recharged. Each molecule cycles ADP → ATP → ADP thousands of times a day — spend the phosphate, then re-attach it with energy from food. It is a rechargeable battery on a fast loop, not a fuel tank you fill once.',
      ),
      LessonSection.thinkReveal(
        title: 'Why a middleman?',
        question: 'Why bother with ATP instead of burning glucose directly to power each task?',
        answer:
            'Oxidizing glucose releases one big, awkward burst of energy. ATP repackages it into small, uniform, spendable coins any process can use. A common currency means one food source can pay for thousands of unrelated reactions without each needing its own custom fuel.',
      ),
      LessonSection.fact(
        title: 'Fast turnover',
        body: 'A typical cell recycles its entire ATP pool roughly every 1-2 minutes.',
      ),
    ],
  ),
  BioEntity(
    id: 'molecular_air',
    scale: BioScale.molecular,
    position: 6,
    name: 'Air Content',
    title: 'The Atmospheric Exchange',
    shortDescription: 'N₂ (78%), O₂ (21%), CO₂ (0.04%) — the gases plants breathe in and out, driving both photosynthesis and respiration.',
    longDescription:
        'The atmosphere is a gas mixture plants are in constant conversation with. Nitrogen (N₂) is 78% — abundant but largely inaccessible, because the triple bond between its two atoms is extremely strong and only nitrogen-fixing bacteria can break it. Oxygen (O₂) at 21% is both a product of photosynthesis and a requirement for respiration. Carbon dioxide (CO₂) at just ~0.04% (~420 ppm) is the carbon source for all photosynthesis.\n\n'
        'The exchange happens through stomata: when they open, CO₂ diffuses in while O₂ and water vapour diffuse out. This is the fundamental transaction of plant life — carbon in, oxygen out by day. In agriculture, atmospheric CO₂ has climbed from ~280 ppm pre-industrial to over 420 ppm today; the "CO₂ fertilization effect" boosts photosynthesis, but the gains are offset by the warming, drought, and extreme weather that accompany the rise.',
    zoomOutIds: ['cell_guard'],
    relatedIds: ['molecular_water', 'molecular_carbon', 'molecular_carbohydrates', 'ecosystem_nitrogen_cycle'],
    sections: [
      LessonSection.table(
        title: 'What air is made of',
        headers: ['Gas', 'Share', 'Role for plants'],
        rows: [
          ['Nitrogen (N₂)', '~78%', 'Nitrogen source — but only via fixation'],
          ['Oxygen (O₂)', '~21%', 'Respiration; product of photosynthesis'],
          ['Argon (Ar)', '~0.93%', 'Inert bystander'],
          ['Carbon dioxide (CO₂)', '~0.04% (~420 ppm)', 'The carbon source for all life'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Starving in a sea of nitrogen',
        question: 'Nitrogen is 78% of the air, yet it is often the #1 limiting nutrient for crops. How can a plant starve surrounded by it?',
        answer:
            'N₂\'s triple bond is one of the strongest in chemistry, and plants cannot break it. Only nitrogen-fixing bacteria (or the industrial Haber-Bosch process) can crack it into usable ammonia. Abundance you cannot reach is not the same as availability — which is exactly why fertilizer exists.',
      ),
      LessonSection.thinkReveal(
        title: 'More CO₂, better farms?',
        question: 'CO₂ is only ~0.04% of air, and raising it boosts photosynthesis. So why is rising CO₂ not an unqualified win for agriculture?',
        answer:
            'The fertilization gain is offset by the heat, drought, and extreme weather that come with rising CO₂, and the extra carbon can dilute the protein and mineral content of grain. The photosynthesis boost is real but comes bundled with costs that often erase it.',
      ),
      LessonSection.fact(
        title: 'Every carbon atom passed through here',
        body: 'Every carbon atom in every organism entered biology through CO₂ fixation — from a gas that is only ~0.04% of the air.',
      ),
    ],
  ),
  BioEntity(
    id: 'molecular_carbon',
    scale: BioScale.molecular,
    position: 7,
    name: 'Carbon',
    title: 'The Backbone of Life',
    shortDescription: 'Element 6 — four bonding electrons allow carbon to form the complex chains, rings, and branches that scaffold every biological molecule.',
    longDescription:
        'Carbon is the element that makes life possible. With four valence electrons it can form four stable covalent bonds — with other carbons and with hydrogen, oxygen, nitrogen, sulfur, and phosphorus. This tetravalence lets carbon build an almost infinite variety of architectures: straight chains, branches, rings, double and triple bonds. No other element comes close to this structural versatility.\n\n'
        'Every major class of biomolecule is built on a carbon skeleton — carbohydrates, lipids, proteins, nucleic acids, ATP. Strip away the carbon and there is no biology, just water and salts. The carbon cycle threads every scale in this app: atmospheric CO₂ is fixed by RuBisCO into glucose, transported through phloem, built into every organ, then returned to soil and air by decomposers. Agriculture is, in essence, human management of that cycle.',
    relatedIds: ['molecular_carbohydrates', 'molecular_proteins', 'molecular_lipids', 'molecular_nucleic_acids', 'molecular_air', 'ecosystem_nitrogen_cycle'],
    sections: [
      LessonSection.table(
        title: 'Bonding capacity across elements',
        headers: ['Element', 'Valence electrons', 'Stable bonds'],
        rows: [
          ['Hydrogen', '1', '1'],
          ['Oxygen', '6', '2'],
          ['Nitrogen', '5', '3'],
          ['Carbon', '4', '4'],
        ],
      ),
      LessonSection.table(
        title: 'Carbon in every biomolecule',
        headers: ['Molecule class', 'Carbon\'s role'],
        rows: [
          ['Carbohydrate', 'C-H-O rings and chains'],
          ['Lipid', 'Long C-H hydrocarbon chains'],
          ['Protein', 'C backbone plus side groups'],
          ['Nucleic acid', 'C-sugar backbone carrying bases'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why not silicon?',
        question: 'Silicon sits directly below carbon and also forms four bonds. Why is life carbon-based, not silicon-based?',
        answer:
            'Carbon bonds strongly to itself and readily forms double and triple bonds, and its oxide CO₂ is a mobile gas that cycles freely. Silicon\'s bonds are weaker and unstable in water, and its oxide SiO₂ is solid rock — locked up, not recyclable. Carbon wins on both versatility and the ability to keep circulating.',
      ),
      LessonSection.thinkReveal(
        title: 'Infinite architectures',
        question: 'Why can carbon build an "almost infinite variety" of molecules when other elements cannot?',
        answer:
            'Four equal bonds let carbon link into chains, branches, and rings of any length, with single, double, or triple bonds anywhere along them. That combinatorial freedom — tetravalence plus stable self-bonding — produces an explosion of stable scaffolds no two- or three-bond element can match.',
      ),
      LessonSection.fact(
        title: 'Four bonds, all of biology',
        body: 'Carbon\'s four valence electrons let one atom form four stable covalent bonds — the root of every biomolecule.',
      ),
    ],
  ),
  BioEntity(
    id: 'molecular_amylose',
    scale: BioScale.molecular,
    position: 8,
    name: 'Starch (Amylose)',
    title: 'The Linear Chain',
    shortDescription: 'Long unbranched chains of glucose that pack tightly in potato starch granules — responsible for the firm, waxy texture of cooked potatoes.',
    longDescription:
        'Amylose is a linear polysaccharide of glucose units joined by alpha-1,4 glycosidic bonds. Unlike its branched counterpart amylopectin, it forms long, unbranched helical chains of several hundred to several thousand glucose residues. These helices pack tightly through hydrogen bonding into semi-crystalline regions of the starch granule — which makes amylose less soluble, more resistant to digestion, and more prone to retrogradation (recrystallization) than amylopectin.\n\n'
        'The amylose-to-amylopectin ratio decides potato texture. High-amylose potatoes (like russets, ~25-30% amylose) cook dry, fluffy, and mealy because the chains separate and each absorbs water. Low-amylose (waxy) potatoes hold together into a firm, creamy texture ideal for salads and roasting. This genetically-set ratio is a major breeding target, and amylose retrogradation on cooling is why cold potato salad has a lower glycemic index than hot mash.',
    zoomOutIds: ['organelle_amyloplast', 'organelle_central_vacuole'],
    relatedIds: ['molecular_amylopectin', 'molecular_carbohydrates', 'molecular_carbon', 'molecular_water'],
    sections: [
      LessonSection.table(
        title: 'Amylose vs. amylopectin',
        headers: ['Feature', 'Amylose', 'Amylopectin'],
        rows: [
          ['Shape', 'Linear helix', 'Heavily branched'],
          ['Bonds', 'alpha-1,4', 'alpha-1,4 + alpha-1,6 branches'],
          ['Share of potato starch', '~20-30%', '~70-80%'],
          ['Solubility', 'Low', 'Higher'],
          ['Texture effect', 'Dry, fluffy, mealy', 'Creamy, viscous'],
        ],
      ),
      LessonSection.table(
        title: 'Potato texture by amylose content',
        headers: ['Type', 'Amylose', 'Cooked texture', 'Best for'],
        rows: [
          ['Russet (mealy)', 'High (~25-30%)', 'Dry, fluffy', 'Baking, fries, mash'],
          ['Waxy', 'Low', 'Firm, creamy', 'Salads, roasting, boiling'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Cold potato, lower spike',
        question: 'Why does chilled potato salad have a lower glycemic index than hot mashed potato of the very same variety?',
        answer:
            'On cooling, amylose retrogrades — the chains recrystallize into resistant starch that digestive enzymes can\'t fully break down, so less glucose hits the blood and it feeds gut bacteria as prebiotic fibre. Reheating partly reverses the effect, which is why leftover-then-warmed potato lands in between.',
      ),
      LessonSection.thinkReveal(
        title: 'Fluffy vs. firm',
        question: 'High-amylose potatoes cook up dry and fluffy while waxy ones stay firm. What at the molecular level makes the difference?',
        answer:
            'Long linear amylose chains separate on cooking and each grabs its own water, so the cells fall apart into loose, fluffy grains. Low-amylose (branch-dominated) tissue keeps its cells stuck together and moist, giving the firm, creamy waxy texture.',
      ),
      LessonSection.fact(
        title: 'A very long thread',
        body: 'A single amylose chain runs from several hundred to several thousand glucose units long.',
      ),
    ],
  ),
  BioEntity(
    id: 'molecular_amylopectin',
    scale: BioScale.molecular,
    position: 9,
    name: 'Starch (Amylopectin)',
    title: 'The Branched Matrix',
    shortDescription: 'Highly branched glucose polymer that forms the bulk of potato starch — its structure determines how starch granules swell and gelatinize during cooking.',
    longDescription:
        'Amylopectin is the dominant component of most starches, typically ~70-80% of potato starch by weight. It is a massively branched glucose polymer: an alpha-1,4 backbone with branch points every ~20-25 units connected by alpha-1,6 bonds. A single molecule can hold over a million glucose residues, making it one of the largest molecules in nature. Its branching organizes into alternating crystalline and amorphous layers, visible under polarized light as the characteristic "Maltese cross."\n\n'
        'Gelatinization — the irreversible swelling and disruption of granules in hot water — is governed largely by amylopectin. Potato starch gelatinizes at a relatively low ~58-65 °C because its granules are unusually large (up to ~100 µm) and carry phosphate groups that weaken the crystalline packing. This is what happens when you boil a potato: granules absorb water, swell, and burst into a viscous paste. Those same properties — high viscosity, clear paste, neutral flavour — make potato starch a prized food thickener.',
    zoomOutIds: ['organelle_amyloplast', 'organelle_central_vacuole'],
    relatedIds: ['molecular_amylose', 'molecular_carbohydrates', 'molecular_carbon', 'molecular_water'],
    sections: [
      LessonSection.table(
        title: 'Inside an amylopectin molecule',
        headers: ['Property', 'Value'],
        rows: [
          ['Backbone bond', 'alpha-1,4'],
          ['Branch bond', 'alpha-1,6, every ~20-25 units'],
          ['Molecule size', '>1 million glucose residues'],
          ['Potato granule size', 'up to ~100 µm'],
        ],
      ),
      LessonSection.table(
        title: 'Gelatinization temperature by source',
        headers: ['Starch source', '~Gelatinization temp', 'Note'],
        rows: [
          ['Potato', '~58-65 °C', 'Large granules + phosphate lower it'],
          ['Wheat', '~58-64 °C', 'Smaller granules'],
          ['Maize (corn)', '~62-72 °C', 'Higher, opaque gel'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why potato cooks softer, sooner',
        question: 'Potato starch gelatinizes at a lower temperature than corn or wheat starch. What two features of potato amylopectin explain it?',
        answer:
            'First, potato amylopectin carries phosphate groups that repel each other and weaken the crystalline packing. Second, potato granules are unusually large. Together they let water penetrate and swell the granule at a lower temperature than the tightly packed cereal starches.',
      ),
      LessonSection.thinkReveal(
        title: 'Chef\'s choice',
        question: 'Why do cooks reach for potato starch over cornstarch when they want a clear, glossy sauce?',
        answer:
            'Potato starch\'s large, phosphate-bearing granules give high viscosity, a transparent paste, and a neutral flavour, whereas cereal starches gel cloudy and can taste starchy. For a shiny, clear glaze or gravy, potato starch simply thickens cleaner.',
      ),
      LessonSection.fact(
        title: 'A molecular giant',
        body: 'A single amylopectin molecule can contain over 1 million glucose residues — among the largest molecules in nature.',
      ),
    ],
  ),
  BioEntity(
    id: 'molecular_solanine',
    scale: BioScale.molecular,
    position: 10,
    name: 'Solanine',
    title: 'The Chemical Defender',
    shortDescription: 'A toxic glycoalkaloid produced in green or damaged potato tissue — the plant\'s defense against herbivores that humans must manage carefully.',
    longDescription:
        'Solanine and chaconine are the two principal glycoalkaloids in potatoes, together ~95% of total glycoalkaloid content. Both are steroidal glycoalkaloids — a cholesterol-like steroid backbone with sugar chains attached — produced throughout the plant, highest in flowers, sprouts, and green skin. Their job is defense: they are toxic to insects, fungi, and herbivores, disrupting cell membranes and inhibiting acetylcholinesterase, an enzyme essential for nerve function. This is the potato\'s chemical warfare system, honed over millions of years in the Andes.\n\n'
        'The green-equals-toxic association is often misread. Light triggers two independent processes at once — chlorophyll production (green, harmless) and glycoalkaloid synthesis (invisible, toxic). The green is a warning flag, not the poison itself. Safe limits are set at ~200 mg/kg fresh weight; most cultivated varieties sit well under that (~20-100 mg/kg). Damage, sprouting, and warm or lit storage all raise glycoalkaloid levels, which is why breeders select against them and every new variety is safety-tested.',
    zoomOutIds: ['organelle_central_vacuole', 'organelle_plasma_membrane'],
    relatedIds: ['molecular_vitamin_c', 'molecular_proteins', 'molecular_carbohydrates', 'cell_parenchyma'],
    sections: [
      LessonSection.table(
        title: 'Where glycoalkaloids concentrate',
        headers: ['Part of plant', 'Relative glycoalkaloid level'],
        rows: [
          ['Sprouts and eyes', 'Highest'],
          ['Flowers', 'Very high'],
          ['Green skin / surface', 'Elevated'],
          ['Flesh (tuber interior)', 'Low'],
          ['Whole tuber (typical)', '~20-100 mg/kg'],
          ['Regulatory safe limit', '~200 mg/kg fresh weight'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Is green really the danger?',
        question: 'Chlorophyll — the green pigment — is harmless. So why are cooks told to avoid green potatoes?',
        answer:
            'Light triggers two separate reactions at once: harmless chlorophyll (the visible green) and toxic glycoalkaloids (invisible). The green does not poison you, but it is a reliable signal that the invisible toxin has probably risen alongside it. It is a warning label, not the toxin itself — so peel deep or discard.',
      ),
      LessonSection.thinkReveal(
        title: 'Why the Andes freeze-dried tubers',
        question: 'Ancient Andean farmers turned wild potatoes into chuño by repeated freeze-drying. What molecular problem was that solving?',
        answer:
            'Wild tubers carried dangerously high glycoalkaloid loads. Cycles of freezing, thawing, and treading/leaching pulled the water-associated toxins out and dropped them to edible levels — detoxifying otherwise poisonous tubers and, as a bonus, making a storable food that lasts for years.',
      ),
      LessonSection.fact(
        title: 'The safety line',
        body: 'The safe limit for glycoalkaloids in commercial potatoes is ~200 mg/kg fresh weight; most varieties sit well under it at ~20-100 mg/kg.',
      ),
    ],
  ),
  BioEntity(
    id: 'molecular_vitamin_c',
    scale: BioScale.molecular,
    position: 11,
    name: 'Vitamin C',
    title: 'The Antioxidant Shield',
    shortDescription: 'Ascorbic acid — a vital antioxidant that potatoes provide in significant quantities, making them historically important in preventing scurvy.',
    longDescription:
        'Ascorbic acid (vitamin C) is a small, water-soluble organic acid and one of the most important antioxidants in plant and animal biology. Plants synthesize it from glucose and accumulate it in nearly all tissues. A medium potato (~150 g) holds ~30-45 mg — roughly 45% of an adult\'s daily requirement. Citrus gets the fame, but potatoes have mattered more historically simply because people ate them in far larger, more regular quantities.\n\n'
        'That nutritional role was decisive: before potatoes spread through Europe, scurvy was endemic among the poor in winter. A reliable, storable, year-round source of vitamin C helped drive the 18th-19th century population boom. Content varies with variety, growing conditions, and handling — potatoes lose 30-50% of their vitamin C over months of storage, and boiling leaches it into the cooking water while baking, steaming, and microwaving preserve much more.',
    zoomOutIds: ['organelle_cytoplasm', 'organelle_central_vacuole'],
    relatedIds: ['molecular_solanine', 'molecular_water', 'molecular_carbohydrates', 'molecular_proteins'],
    sections: [
      LessonSection.table(
        title: 'Vitamin C: content and losses',
        headers: ['Situation', 'Vitamin C effect'],
        rows: [
          ['Medium potato (~150 g), fresh', '~30-45 mg (~45% of adult daily need)'],
          ['After months of storage', 'Loses ~30-50%'],
          ['Boiled', 'Leaches into the water — large loss'],
          ['Baked / steamed / microwaved', 'Much better retention'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The unglamorous scurvy-fighter',
        question: 'Citrus is famous for vitamin C, yet potatoes prevented far more scurvy in old Europe. How can the "weaker" source matter more?',
        answer:
            'Total intake = concentration × how much you eat × how reliably. Potatoes were a storable, year-round staple eaten in large daily portions, so their cumulative vitamin C dwarfed occasional, seasonal citrus — especially through the winter months when scurvy struck hardest.',
      ),
      LessonSection.thinkReveal(
        title: 'Why the cooking water robs you',
        question: 'Boiling potatoes can strip much of their vitamin C while baking loses far less. Why does the water matter so much?',
        answer:
            'Vitamin C is water-soluble, so in a boiling pot it dissolves out of the tissue and into the water you pour down the drain. Dry-heat methods keep it locked in the food. (Heat degrades some of it too, but the leaching is the bigger thief — which is why saving the cooking water recovers a lot of it.)',
      ),
      LessonSection.fact(
        title: 'Nearly half your day\'s worth',
        body: 'A medium potato (~150 g) delivers ~30-45 mg of vitamin C — roughly 45% of an adult\'s daily requirement.',
      ),
    ],
  ),
];
