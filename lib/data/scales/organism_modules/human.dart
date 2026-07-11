import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Organism module — "The Human": Homo sapiens as a whole organism.
/// Eight entities, awe-plus-humility: we are one organism among millions,
/// the only one that names the others.
const List<BioEntity> organismHumanEntities = <BioEntity>[
  // 0 ─────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'human_sapiens',
    scale: BioScale.organism,
    position: 0,
    moduleId: 'organism_human',
    name: 'Homo sapiens',
    title: 'The ape that named itself',
    shortDescription:
        'You are a Great Ape — the only species that ever paused to write down what it is.',
    longDescription:
        'Homo sapiens ("wise human") is a single species of Great Ape, sitting in the family Hominidae alongside chimpanzees, bonobos, gorillas, and orangutans. We are not descended from modern apes; we and they share ancient common ancestors, and our lineage split from that of chimpanzees roughly 6–7 million years ago.\n\n'
        'Every living human belongs to this one species — one branch, no subspecies that survived. The awe and the humility arrive together: we are extraordinary, and we are ordinary animals, twigs on the same tree of life as the potato, the paramecium, and the whale.',
    relatedIds: ['human_unique', 'human_nature'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Carl Linnaeus, who invented the system that names every species, had to name his own. He landed on Homo sapiens — and then, unlike every other entry, wrote no physical description. Beside our species he simply wrote "nosce te ipsum": know thyself. We are the animal that has to look inward to be classified.',
      ),
      LessonSection.table(
        title: 'Our address in the tree of life',
        headers: ['Rank', 'Name', 'Also contains'],
        rows: [
          ['Kingdom', 'Animalia', 'Every animal, from sponges to whales'],
          ['Phylum', 'Chordata', 'Everything with a backbone'],
          ['Class', 'Mammalia', 'Fur, milk, warm blood'],
          ['Order', 'Primates', 'Lemurs, monkeys, apes'],
          ['Family', 'Hominidae', 'Great Apes — chimps, gorillas, orangutans'],
          ['Genus', 'Homo', 'Us + extinct human relatives'],
          ['Species', 'Homo sapiens', 'Every living person'],
        ],
      ),
      LessonSection.fact(
        title: 'Kinship, measured',
        body:
            'We share about 98.8% of our DNA with chimpanzees — our closest living relatives on Earth.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If a chimp and a human share 98.8% of their DNA, what could that remaining ~1.2% possibly account for?',
        answer:
            'A staggering amount. That ~1.2% difference — plus differences in how genes switch on and off — reshapes brain wiring, hand dexterity, the vocal tract, and lifespan. Small percentages of a 3.2-billion-letter genome are still tens of millions of differences. Similarity and difference are both real.',
      ),
    ],
  ),

  // 1 ─────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'human_organ_systems',
    scale: BioScale.organism,
    position: 1,
    moduleId: 'organism_human',
    name: "The Body's Organ Systems",
    title: 'Eleven teams, one body',
    shortDescription:
        'Your body runs on 11 organ systems that never stop cooperating — most of it without your permission.',
    longDescription:
        'A whole human is not a bag of parts; it is 11 organ systems working in concert. Each is a set of organs that shares a job — moving blood, digesting food, sensing the world — and none of them can survive alone. Your heart is useless without lungs to oxygenate the blood it pumps; your muscles are dead weight without nerves to fire them.\n\n'
        'The systems overlap and hand off constantly. Right now, without a single conscious thought from you, all 11 are coordinating to keep one organism — you — alive.',
    relatedIds: ['human_brain', 'human_microbiome'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Take a breath. In that one second, your respiratory system pulled in air, your cardiovascular system moved oxygen to every cell, your nervous system timed the whole thing, and your muscular system did the pulling — four systems for a single breath, and you noticed none of it.',
      ),
      LessonSection.table(
        title: 'The 11 systems',
        headers: ['System', 'Core job', 'Star organs'],
        rows: [
          ['Integumentary', 'Barrier + temperature', 'Skin, hair, nails'],
          ['Skeletal', 'Structure + blood cell factory', 'Bones, joints'],
          ['Muscular', 'Movement + heat', 'Skeletal & smooth muscle'],
          ['Nervous', 'Sense + control + think', 'Brain, spinal cord, nerves'],
          ['Endocrine', 'Chemical messaging (hormones)', 'Glands: thyroid, pancreas'],
          ['Cardiovascular', 'Transport blood', 'Heart, blood vessels'],
          ['Lymphatic / Immune', 'Drain fluid + defend', 'Lymph nodes, spleen'],
          ['Respiratory', 'Gas exchange', 'Lungs, airways'],
          ['Digestive', 'Break down + absorb food', 'Stomach, intestines, liver'],
          ['Urinary', 'Filter blood + balance water', 'Kidneys, bladder'],
          ['Reproductive', 'Make the next generation', 'Gonads'],
        ],
      ),
      LessonSection.fact(
        title: 'Built from tiny units',
        body:
            'All 11 systems are assembled from roughly 37 trillion human cells — every one carrying a copy of the same genome.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Which single organ system is doing double duty as both a barrier AND your largest sense organ?',
        answer:
            'The integumentary system — your skin. It walls the outside world out, regulates your temperature, and is packed with receptors for touch, pressure, pain, and heat. As the body\'s largest organ, it is defense and sensation at once.',
      ),
    ],
  ),

  // 2 ─────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'human_genome',
    scale: BioScale.organism,
    position: 2,
    moduleId: 'organism_human',
    name: 'The Human Genome',
    title: 'Your whole recipe, in four letters',
    shortDescription:
        'The complete instructions for a human fit in an alphabet of just four letters, 3.2 billion long.',
    longDescription:
        'The human genome is the full set of DNA instructions for building and running a person. It is written in only four chemical letters — A, T, C, G — arranged in a sequence about 3.2 billion base pairs long, packaged into 23 pairs of chromosomes inside almost every cell.\n\n'
        'Surprisingly, only about 20,000 of those stretches are protein-coding genes — a number close to a roundworm\'s. Most of the genome is regulatory switches, timing signals, and stretches whose roles we are still decoding. Complexity comes not just from how many genes you have, but from how they are controlled.',
    relatedIds: ['human_sapiens', 'human_life_cycle'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'When the Human Genome Project finished, one number shocked biologists: only ~20,000 genes. People had guessed 100,000 — surely a human needs more instructions than a worm? The lesson was humbling: you are not defined by how many genes you have, but by how cleverly they are switched on and off.',
      ),
      LessonSection.table(
        title: 'The genome by the numbers',
        headers: ['Feature', 'Value'],
        rows: [
          ['Alphabet', '4 letters (A, T, C, G)'],
          ['Base pairs', '~3.2 billion'],
          ['Protein-coding genes', '~20,000'],
          ['Chromosome pairs', '23 (46 total)'],
          ['Copies per cell', '2 (one from each parent)'],
          ['DNA shared with any other human', '~99.9%'],
        ],
      ),
      LessonSection.fact(
        title: 'A staggering length',
        body:
            'Uncoiled, the DNA in a single cell stretches about 2 meters. Across all ~37 trillion cells, that is enough to reach the Sun and back many times over.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Every cell in your body holds the same 3.2-billion-letter genome. So why is a brain cell nothing like a skin cell?',
        answer:
            'Because different cells read different pages. The genome is the whole cookbook; each cell type follows only certain recipes — switching some genes on, silencing others. A neuron and a skin cell are the same book read two different ways. That control is called gene expression.',
      ),
    ],
  ),

  // 3 ─────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'human_microbiome',
    scale: BioScale.organism,
    position: 3,
    moduleId: 'organism_human',
    name: 'The Human Microbiome',
    title: 'You are a walking ecosystem',
    shortDescription:
        'For roughly every human cell in your body, there is a microbial one — you are never truly alone.',
    longDescription:
        'The human microbiome is the vast community of bacteria, archaea, fungi, and viruses living on and inside you — concentrated in your gut, but blanketing your skin, mouth, and airways too. Current estimates put microbial cells at roughly a 1:1 ratio with your own — about the same number as your ~37 trillion human cells (the old "10-to-1" claim is outdated).\n\n'
        'These microbes are not just passengers. They help digest food, synthesize vitamins, train your immune system, and crowd out invaders. A human is less a single organism than a negotiated truce between one animal and trillions of tiny partners.',
    relatedIds: ['human_organ_systems', 'human_nature'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'For years textbooks said microbes outnumber your cells 10 to 1 — meaning you were "only 10% human." A 2016 recount corrected it: the ratio is closer to 1 to 1. You are roughly half you and half everyone else, and that is strange enough.',
      ),
      LessonSection.table(
        title: 'Where they live, what they do',
        headers: ['Region', 'Who lives there', 'What they do for you'],
        rows: [
          ['Gut', 'Trillions of bacteria', 'Digest fiber, make vitamins K & B'],
          ['Skin', 'Bacteria & fungi', 'Block pathogens, tune immunity'],
          ['Mouth', 'Hundreds of species', 'First line of defense, break down food'],
          ['Airways', 'Sparse communities', 'Help regulate lung immune response'],
        ],
      ),
      LessonSection.fact(
        title: 'The ratio, corrected',
        body:
            'Microbial cells ≈ human cells — roughly 1:1, not 10:1. You are an ecosystem carrying an ecosystem.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If half your cells aren\'t "you," where exactly does an organism end?',
        answer:
            'Biology no longer draws a clean line. The gut microbes that make your vitamins and calm your immune system are as essential to your survival as your own liver. Many scientists now describe a human as a "holobiont" — a host plus its microbes, functioning as one living system.',
      ),
    ],
  ),

  // 4 ─────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'human_brain',
    scale: BioScale.organism,
    position: 4,
    moduleId: 'organism_human',
    name: 'The Human Brain',
    title: 'The organ that names organs',
    shortDescription:
        'Roughly 86 billion neurons, three pounds of tissue — the only object in the universe trying to understand itself.',
    longDescription:
        'The human brain contains about 86 billion neurons, each wiring up to thousands of others across trillions of connections called synapses. It weighs only about 1.4 kilograms (three pounds) yet burns roughly 20% of your body\'s energy at rest — the most expensive organ you own, per gram.\n\n'
        'It runs your body without asking, stores a lifetime of memory, and — uniquely — turns its attention back on itself. Every word in this lesson, including the word "brain," was minted by one.',
    relatedIds: ['human_organ_systems', 'human_unique'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Here is the strangest fact in all of biology: the object reading this sentence is the same kind of object that wrote it. The brain is the only known structure in the universe complex enough to build a model of itself — and curious enough to try.',
      ),
      LessonSection.table(
        title: 'The brain in numbers',
        headers: ['Feature', 'Value'],
        rows: [
          ['Neurons', '~86 billion'],
          ['Synaptic connections', 'Trillions'],
          ['Mass', '~1.4 kg (about 3 lbs)'],
          ['Share of body energy used', '~20%'],
          ['Share of body weight', '~2%'],
        ],
      ),
      LessonSection.fact(
        title: 'The energy hog',
        body:
            'The brain is ~2% of your body weight but consumes ~20% of your energy — ten times its fair share.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'A supercomputer needs a power plant. Your brain does the same kind of work on about 20 watts — less than a dim light bulb. How?',
        answer:
            'Through extreme efficiency and parallelism. Instead of a few fast processors, the brain uses billions of slow, low-power neurons all working at once, reusing patterns and only firing when needed. Evolution optimized for survival on scarce calories, not for raw speed — an efficiency human-built computers still can\'t match.',
      ),
    ],
  ),

  // 5 ─────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'human_life_cycle',
    scale: BioScale.organism,
    position: 5,
    moduleId: 'organism_human',
    name: 'A Human Life Cycle',
    title: 'From one cell to trillions and back',
    shortDescription:
        'You began as a single cell smaller than a grain of sand — and every stage after was that cell keeping its promise.',
    longDescription:
        'Every human life starts as a zygote: one fertilized cell holding the complete genome. That cell divides, and divides again, following its genetic instructions to build an embryo, a fetus, and eventually a body of ~37 trillion cells — all descended from that first one.\n\n'
        'From birth through childhood, puberty, and adulthood, the body grows, matures, and can reproduce. Later, aging sets in as cells accumulate damage and repair slows. It is a single continuous unfolding of one genome, from a dot to a person to an elder.',
    relatedIds: ['human_genome', 'human_organ_systems'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'The most complex object you will ever meet — a whole human being, with 86 billion neurons and a lifetime of memory — was, not long ago, one single cell. Every stage of your life is that cell, and its descendants, following instructions.',
      ),
      LessonSection.table(
        title: 'Stages of a life',
        headers: ['Stage', 'What happens'],
        rows: [
          ['Zygote', 'One fertilized cell — the full genome, ready to begin'],
          ['Embryo', 'Rapid division; the body plan is laid down'],
          ['Fetus', 'Organs form and mature before birth'],
          ['Infancy & childhood', 'Explosive growth of body and brain'],
          ['Puberty', 'Body matures; reproduction becomes possible'],
          ['Adulthood', 'Full size, peak function, next generation possible'],
          ['Aging', 'Cell damage accumulates; repair slows'],
        ],
      ),
      LessonSection.fact(
        title: 'From one to trillions',
        body:
            'A single starting cell becomes an estimated ~37 trillion cells — a growth of over a trillion-fold, all from one set of instructions.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If one zygote becomes trillions of cells with the same DNA, how does the body know to build a hand here and an eye there?',
        answer:
            'Through signals and timing. As cells divide, chemical gradients and neighbor signals tell each one where it is and what to become — a process called differentiation. Position plus timing switches different genes on, so identical DNA sculpts a hand in one place and an eye in another. Geography, not genetics, decides the part.',
      ),
    ],
  ),

  // 6 ─────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'human_unique',
    scale: BioScale.organism,
    position: 6,
    moduleId: 'organism_human',
    name: 'What Makes Humans Unique',
    title: 'Language, culture, and the shared mind',
    shortDescription:
        'No single trait makes us human — it\'s that ideas outlive the people who have them.',
    longDescription:
        'Plenty of animals use tools, and some communicate richly. What sets humans apart is the combination and scale: open-ended language that can express any idea, cumulative culture that passes knowledge across generations, and cooperation among strangers on a massive scale.\n\n'
        'A chimp is born knowing roughly what a chimp a thousand years ago knew. A human inherits ten thousand years of accumulated discovery — fire, writing, mathematics, medicine — because our ideas don\'t die with us. That "ratchet" of shared knowledge is the human superpower.',
    relatedIds: ['human_brain', 'human_sapiens'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'You did not invent counting, writing, or the wheel — yet you use all three. That is the human trick: no one starts from scratch. Every generation stands on the accumulated knowledge of every one before it, a ladder no other animal has ever built.',
      ),
      LessonSection.table(
        title: 'Human traits, in context',
        headers: ['Trait', 'Other animals?', 'The human difference'],
        rows: [
          ['Tool use', 'Yes (crows, chimps)', 'Tools that make other tools'],
          ['Communication', 'Yes (many species)', 'Open-ended, recursive language'],
          ['Cooperation', 'Yes (ants, wolves)', 'With strangers, at planetary scale'],
          ['Culture', 'Some (whale song)', 'Cumulative — it ratchets upward'],
        ],
      ),
      LessonSection.fact(
        title: 'The ratchet',
        body:
            'Cumulative culture means knowledge builds on knowledge instead of restarting — the reason we went from stone tools to spacecraft in a few thousand years.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'A lone human dropped in a forest is weaker than a chimp. So why did humans, not chimps, reach the Moon?',
        answer:
            'Because humans win as a networked group, not as individuals. Language lets us pool knowledge across millions of minds and thousands of years; cooperation lets strangers build together. No single person could design a rocket — but a culture that accumulates and shares ideas can. Our strength was never the body. It was the shared mind.',
      ),
    ],
  ),

  // 7 ─────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'human_nature',
    scale: BioScale.organism,
    position: 7,
    moduleId: 'organism_human',
    name: 'Humans as Part of Nature',
    title: 'One organism among millions',
    shortDescription:
        'The same chemistry that runs a potato runs you — we are not above the tree of life, we are on it.',
    longDescription:
        'For all our uniqueness, humans are animals, built from the same cells, the same DNA alphabet, and the same molecular machinery as every other living thing. We breathe oxygen made by plants and algae, we depend on ecosystems for food and clean water, and we share ancestors with every organism on Earth.\n\n'
        'The human body is a bridge across every scale in this app: atoms assemble into molecules, molecules into cells, cells into organs, organs into you — and you into ecosystems, food webs, and the biosphere. To understand a human is to understand our connection to all of it, not our exemption from it.',
    relatedIds: ['human_sapiens', 'human_microbiome'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'The oxygen in your last breath was exhaled by a plant. The carbon in your cells was once in the air, in a leaf, in your dinner. You are not separate from nature dropping in to visit — you are nature, temporarily arranged into a person.',
      ),
      LessonSection.table(
        title: 'What we share with all life',
        headers: ['Shared feature', 'Also true of…'],
        rows: [
          ['Built from cells', 'Every living thing on Earth'],
          ['DNA in the same 4 letters', 'Bacteria, plants, fungi, animals'],
          ['Uses ATP for energy', 'Potatoes, paramecia, whales'],
          ['A common ancestor', 'All life, ~3.5+ billion years back'],
          ['Depends on ecosystems', 'Every organism, no exceptions'],
        ],
      ),
      LessonSection.fact(
        title: 'The humbling truth',
        body:
            'You share a common ancestor with the potato, the mushroom, and the housefly. Different branches — one tree.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'This app spans 22 scales, from nothings to infinities. Where does the human belong — and where does the human reach?',
        answer:
            'A human sits at the organism scale — but reaches every scale. Built from atoms and molecules and cells (the scales below), we live inside ecosystems, food webs, and a biosphere (the scales above), and our minds probe planets, galaxies, and infinities. The human is a single organism woven into the entire chain of being. That is the awe, and the humility, together.',
      ),
    ],
  ),
];
