import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Organ-system module: "The Human Organ Systems".
///
/// The organ-system scale otherwise holds the PLANT systems; this module adds
/// the human/animal side. Ten entities: the ten major systems plus a closing
/// integration lesson on homeostasis. Every entity carries a HOOK plus at least
/// one table, one landmark fact, and one think-then-reveal — the module is a
/// teaching tool, not a reference dump.
const List<BioEntity> organSystemHumanEntities = <BioEntity>[
  // ────────────────────────────────────────────────────────────── 0 ──
  BioEntity(
    id: 'organSystem_human_cardiovascular',
    scale: BioScale.organSystem,
    position: 0,
    name: 'The Cardiovascular System',
    title: 'The Tireless Pump',
    moduleId: 'organSystem_human',
    shortDescription:
        'A fist-sized muscle that never rests, pushing your entire blood supply on a full-body loop about once a minute.',
    longDescription:
        'The heart, blood, and blood vessels form a closed delivery network. The heart pumps, the arteries carry blood away under pressure, capillaries trade oxygen and nutrients with your cells, and veins bring blood back.\n\nStretched end to end, an adult\'s blood vessels would run roughly 100,000 km — more than twice around the Earth. Every cell you own lives within a few cell-widths of a capillary.',
    relatedIds: [
      'organSystem_human_respiratory',
      'organSystem_human_urinary',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Make a fist. That is roughly the size of your heart. Now consider that this fist-sized muscle squeezes about once every second, every second, for your entire life — no weekends, no vacation, no rest longer than the fraction of a second between beats.',
      ),
      LessonSection.fact(
        title: 'Beats per day',
        body:
            'Your heart beats roughly 100,000 times a day — about 35 million times a year, and well over 2.5 billion times across a lifetime.',
      ),
      LessonSection.thinkReveal(
        title: 'The full lap',
        question:
            'You have about 5 litres of blood. Roughly how long does it take a single drop to travel from your heart, out to your body, and all the way back?',
        answer:
            'About 60 seconds. At rest the heart pumps your whole blood volume — around 5 litres — every minute, so a red blood cell completes the full circuit in roughly one minute. Under hard exercise that can drop to about 20 seconds.',
      ),
      LessonSection.table(
        title: 'The four vessels of the loop',
        headers: ['Vessel', 'Direction', 'Job'],
        rows: [
          ['Arteries', 'Away from heart', 'Carry blood under high pressure'],
          ['Capillaries', 'The exchange', 'Trade O₂, CO₂, nutrients with cells'],
          ['Veins', 'Back to heart', 'Return blood, aided by one-way valves'],
          ['Heart', 'The pump', 'Two pumps in one: lungs loop + body loop'],
        ],
      ),
      LessonSection.fact(
        title: 'The double loop',
        body:
            'The heart is really two pumps side by side: the right side sends blood to the lungs for oxygen, the left side sends that oxygen-rich blood to the whole body.',
      ),
    ],
  ),

  // ────────────────────────────────────────────────────────────── 1 ──
  BioEntity(
    id: 'organSystem_human_respiratory',
    scale: BioScale.organSystem,
    position: 1,
    name: 'The Respiratory System',
    title: 'The Gas Exchange',
    moduleId: 'organSystem_human',
    shortDescription:
        'Two lungs unfold into a surface the size of a tennis court to trade oxygen in and carbon dioxide out, breath after breath.',
    longDescription:
        'Air travels down the trachea, branches through the bronchi into ever-smaller tubes, and ends in tiny air sacs called alveoli. There, a single cell-thin wall separates air from blood, and gases diffuse across it.\n\nOxygen crosses into the blood; carbon dioxide — the waste of every cell burning fuel — crosses out and is breathed away. It is a partnership: the respiratory system loads the cargo the cardiovascular system delivers.',
    relatedIds: [
      'organSystem_human_cardiovascular',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'You take about 20,000 breaths a day without deciding to. Each one refreshes the air inside microscopic sacs that, unfolded, would carpet a shocking amount of space.',
      ),
      LessonSection.thinkReveal(
        title: 'Unfolding the lungs',
        question:
            'The lungs pack their surface into millions of tiny sacs. If you flattened that surface out, roughly how big would it be?',
        answer:
            'Around 70 square metres — roughly the size of one side of a tennis court. That vast, crumpled surface is why gas exchange is so fast: your ~300–500 million alveoli give oxygen an enormous doorway into the blood.',
      ),
      LessonSection.fact(
        title: 'The number of sacs',
        body:
            'Each lung holds roughly 300–500 million alveoli — the microscopic air sacs where oxygen enters the blood. Their walls are about one cell thick.',
      ),
      LessonSection.table(
        title: 'The road the air takes',
        headers: ['Stop', 'What it is', 'What happens'],
        rows: [
          ['Trachea', 'The windpipe', 'Main airway from throat'],
          ['Bronchi', 'Two branches', 'One tube into each lung'],
          ['Bronchioles', 'Tiny branches', 'Split thousands of times'],
          ['Alveoli', 'Air sacs', 'Oxygen in, carbon dioxide out'],
        ],
      ),
      LessonSection.fact(
        title: 'You exhale what plants breathe in',
        body:
            'The carbon dioxide you breathe out is the same gas plants pull in for photosynthesis — the respiratory system is one half of a planet-wide gas trade.',
      ),
    ],
  ),

  // ────────────────────────────────────────────────────────────── 2 ──
  BioEntity(
    id: 'organSystem_human_digestive',
    scale: BioScale.organSystem,
    position: 2,
    name: 'The Digestive System',
    title: 'The Disassembly Line',
    moduleId: 'organSystem_human',
    shortDescription:
        'A nine-metre tube that takes food apart molecule by molecule so your cells can rebuild you from the pieces.',
    longDescription:
        'Food enters your mouth as something recognisable and leaves the far end as waste. In between, a continuous tube — mouth, oesophagus, stomach, small intestine, large intestine — breaks it down mechanically and chemically until nutrients are small enough to cross into the blood.\n\nMost of the actual extraction happens in the small intestine, whose inner surface is folded and fuzzed with tiny projections to soak up as much as possible.',
    relatedIds: [
      'organSystem_human_cardiovascular',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'You never actually eat a sandwich. You eat molecules — and your digestive system\'s whole job is to smash that sandwich down into pieces small enough to smuggle into your bloodstream, one nutrient at a time.',
      ),
      LessonSection.thinkReveal(
        title: 'How long is the tube?',
        question:
            'The small intestine is coiled up to fit in your belly. If you uncoiled just the small intestine, roughly how long would it be?',
        answer:
            'About 6–7 metres — longer than most rooms are wide. The whole digestive tract, mouth to end, runs around 9 metres. It fits because it is folded and packed tightly inside you.',
      ),
      LessonSection.fact(
        title: 'A hidden surface',
        body:
            'The small intestine\'s lining is carpeted with millions of finger-like villi, giving it an absorbing surface of roughly 30 square metres — the size of a small studio apartment.',
      ),
      LessonSection.table(
        title: 'Stations along the line',
        headers: ['Organ', 'Main action'],
        rows: [
          ['Mouth', 'Chewing + saliva start breaking down starch'],
          ['Stomach', 'Acid + churning turn food to a paste'],
          ['Small intestine', 'Enzymes finish digestion; nutrients absorbed'],
          ['Large intestine', 'Water reclaimed; waste compacted'],
        ],
      ),
      LessonSection.fact(
        title: 'Acid strong enough to worry about',
        body:
            'Stomach acid is about as strong as battery acid (pH ~1.5–2). A thick mucus layer, replaced constantly, is all that stops your stomach from digesting itself.',
      ),
    ],
  ),

  // ────────────────────────────────────────────────────────────── 3 ──
  BioEntity(
    id: 'organSystem_human_nervous',
    scale: BioScale.organSystem,
    position: 3,
    name: 'The Nervous System',
    title: 'The Living Wiring',
    moduleId: 'organSystem_human',
    shortDescription:
        'Billions of cells firing electrical signals let you think, feel, and move — the fastest messaging network your body owns.',
    longDescription:
        'The brain and spinal cord form the central command; nerves branch out to every corner of the body. Signals travel as electrical pulses down neurons and leap between them at junctions called synapses using chemical messengers.\n\nThis is the body\'s high-speed line. Where hormones take seconds to minutes, nerve signals are near-instant — the difference between a slow broadcast and a phone call.',
    relatedIds: [
      'organSystem_human_endocrine',
      'organSystem_human_muscular',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Reading this sentence, feeling the device in your hand, deciding whether you agree — all of it is electricity crackling through a mesh of cells more numerous than the stars you can see with the naked eye.',
      ),
      LessonSection.fact(
        title: 'How many neurons?',
        body:
            'The human brain holds roughly 86 billion neurons, each wired to thousands of others — an estimated 100+ trillion connections.',
      ),
      LessonSection.thinkReveal(
        title: 'How fast is a nerve signal?',
        question:
            'When you touch something hot, the "pull away!" message races up your arm. Roughly how fast can a nerve signal travel?',
        answer:
            'Up to about 120 metres per second — around 400 km/h on the fastest, insulated nerves. That is why a reflex feels instant: the signal can reach your spinal cord and fire back before your brain has even registered the pain.',
      ),
      LessonSection.table(
        title: 'Two divisions',
        headers: ['Division', 'Parts', 'Role'],
        rows: [
          ['Central (CNS)', 'Brain + spinal cord', 'Processing + decisions'],
          ['Peripheral (PNS)', 'All other nerves', 'Wiring to body + senses'],
        ],
      ),
      LessonSection.fact(
        title: 'The reflex shortcut',
        body:
            'Some reactions never reach the brain: a reflex arc loops through the spinal cord alone, so your hand leaves a hot stove before you consciously feel it.',
      ),
    ],
  ),

  // ────────────────────────────────────────────────────────────── 4 ──
  BioEntity(
    id: 'organSystem_human_endocrine',
    scale: BioScale.organSystem,
    position: 4,
    name: 'The Endocrine System',
    title: 'The Chemical Mail',
    moduleId: 'organSystem_human',
    shortDescription:
        'Glands drip hormones into the blood — slow chemical messages that quietly govern growth, mood, energy, and sleep.',
    longDescription:
        'Where the nervous system is a wired phone call, the endocrine system is the postal service. Glands release hormones — chemical messengers — into the bloodstream, which carries them everywhere. Only cells with the matching receptor "read the letter" and respond.\n\nHormones are slow but powerful: they set puberty in motion, keep your blood sugar in range, ready you for a fight-or-flight moment, and tell you when to sleep.',
    relatedIds: [
      'organSystem_human_nervous',
      'organSystem_human_integration',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'A single drop of a hormone, invisible in your blood, can flip your whole body from calm to fight-or-flight in seconds — pupils widening, heart pounding, sugar flooding your muscles — all from one chemical whispered by a gland the size of a walnut.',
      ),
      LessonSection.thinkReveal(
        title: 'Nerves vs. hormones',
        question:
            'Both the nervous and endocrine systems send messages. If nerves are so much faster, why keep a slow hormone system at all?',
        answer:
            'Because hormones are broadcast and long-lasting. A nerve signal hits one target and fades in milliseconds; a hormone floods the whole body and can act for minutes, hours, or years — perfect for slow, body-wide jobs like growth, puberty, and daily rhythms.',
      ),
      LessonSection.table(
        title: 'A few key glands',
        headers: ['Gland', 'Hormone', 'Controls'],
        rows: [
          ['Pancreas', 'Insulin', 'Blood sugar'],
          ['Adrenal', 'Adrenaline', 'Fight-or-flight response'],
          ['Thyroid', 'Thyroxine', 'Metabolic speed'],
          ['Pituitary', 'Many', 'The "master gland" — directs others'],
        ],
      ),
      LessonSection.fact(
        title: 'Vanishingly small doses',
        body:
            'Hormones work at astonishingly tiny concentrations — often billionths of a gram per litre of blood — yet they steer entire body-wide changes.',
      ),
      LessonSection.fact(
        title: 'The master gland',
        body:
            'The pea-sized pituitary at the base of the brain is called the master gland because its hormones tell other glands when to release theirs.',
      ),
    ],
  ),

  // ────────────────────────────────────────────────────────────── 5 ──
  BioEntity(
    id: 'organSystem_human_skeletal',
    scale: BioScale.organSystem,
    position: 5,
    name: 'The Skeletal System',
    title: 'The Living Scaffold',
    moduleId: 'organSystem_human',
    shortDescription:
        '206 bones frame and protect you — and, deep inside, factories in the marrow churn out billions of blood cells a day.',
    longDescription:
        'Bones give your body shape, let muscles pull against a rigid frame, and armour your softest organs — the skull for the brain, the ribcage for heart and lungs. Bone is not dead scaffolding: it is living tissue, constantly rebuilt, and a mineral bank storing calcium.\n\nHidden inside many bones is red marrow, a factory producing red and white blood cells and platelets. The skeleton literally makes the blood the cardiovascular system pumps.',
    relatedIds: [
      'organSystem_human_muscular',
      'organSystem_human_cardiovascular',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'You picture a skeleton as something dry and dead in a museum. But your bones are alive, richly supplied with blood, and — surprise — one of the busiest factories in your body hides inside them.',
      ),
      LessonSection.thinkReveal(
        title: 'A changing count',
        question:
            'A baby is born with about 300 bones. An adult has 206. Where did nearly 100 bones go?',
        answer:
            'They fused. Many bones start as separate pieces and grow together as you mature — the skull plates knit shut, and bones like those in the spine and pelvis fuse into single units. Nothing is lost; the count drops as pieces merge.',
      ),
      LessonSection.fact(
        title: 'A blood factory inside you',
        body:
            'Red bone marrow produces roughly 2 million red blood cells every second — hundreds of billions a day — plus white cells and platelets.',
      ),
      LessonSection.table(
        title: 'What the skeleton does',
        headers: ['Function', 'Example'],
        rows: [
          ['Support', 'Holds the body upright'],
          ['Protection', 'Skull guards brain; ribs guard heart + lungs'],
          ['Movement', 'Anchors muscles that pull on it'],
          ['Blood production', 'Marrow makes blood cells'],
          ['Mineral store', 'Banks calcium and phosphorus'],
        ],
      ),
      LessonSection.fact(
        title: 'Stronger than it looks',
        body:
            'Gram for gram, healthy bone is remarkably strong — its blend of flexible collagen and hard mineral lets it bear heavy loads without shattering.',
      ),
    ],
  ),

  // ────────────────────────────────────────────────────────────── 6 ──
  BioEntity(
    id: 'organSystem_human_muscular',
    scale: BioScale.organSystem,
    position: 6,
    name: 'The Muscular System',
    title: 'The Engine of Motion',
    moduleId: 'organSystem_human',
    shortDescription:
        'Over 600 muscles pull you through the world — but the tireless one you never think about is the heart itself.',
    longDescription:
        'Muscles do only one thing: they contract, they pull. They never push. That is why they work in pairs — one muscle bends a joint, its partner straightens it. Anchored to bone, they turn chemical energy into movement, posture, and heat.\n\nAt the organ-system scale, three muscle types share the body, each specialised for a different job — the ones you command, the ones that run without you, and the one that beats.',
    relatedIds: [
      'organSystem_human_skeletal',
      'organSystem_human_nervous',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'You think of muscles as biceps and abs — the ones you can flex. But most of your muscle work happens with zero conscious effort: your gut squeezes, your arteries tighten, and one muscle has been beating since before you were born.',
      ),
      LessonSection.table(
        title: 'Three kinds of muscle',
        headers: ['Type', 'Where', 'Control'],
        rows: [
          ['Skeletal', 'Attached to bones', 'Voluntary (you decide)'],
          ['Smooth', 'Gut, blood vessels', 'Involuntary (automatic)'],
          ['Cardiac', 'The heart only', 'Involuntary, never tires'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The push problem',
        question:
            'Muscles can only pull, never push. So how does your arm both bend AND straighten?',
        answer:
            'With opposing pairs. Your biceps pulls the forearm up to bend the elbow; to straighten it, the biceps relaxes and the triceps on the other side pulls it back down. Every joint you can move has muscles working against each other like this.',
      ),
      LessonSection.fact(
        title: 'The heart is a muscle',
        body:
            'Cardiac muscle is found nowhere else in the body. Unlike your biceps, it never fatigues — it contracts about 100,000 times a day for your entire life without a break.',
      ),
      LessonSection.fact(
        title: 'Muscles make heat',
        body:
            'Muscle contraction is inefficient, and the "wasted" energy comes out as heat — which is exactly why you shiver: rapid tiny contractions to warm you up.',
      ),
    ],
  ),

  // ────────────────────────────────────────────────────────────── 7 ──
  BioEntity(
    id: 'organSystem_human_immune',
    scale: BioScale.organSystem,
    position: 7,
    name: 'The Immune / Lymphatic System',
    title: 'The Standing Army',
    moduleId: 'organSystem_human',
    shortDescription:
        'A roaming army of white cells and a second circulatory network that hunts invaders and drains the body\'s excess fluid.',
    longDescription:
        'The immune system is your defence force: white blood cells patrol the body, recognise invaders like bacteria and viruses, and destroy them — while remembering the ones they\'ve beaten so the next attack is faster.\n\nRunning alongside it is the lymphatic system, a network of vessels and nodes that drains excess fluid from tissues, filters it through node checkpoints packed with immune cells, and returns it to the blood.',
    relatedIds: [
      'organSystem_human_cardiovascular',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Right now, without any effort from you, an army of cells is patrolling your body, checking IDs, and quietly killing thousands of bacteria and virus-infected cells — and it remembers every enemy it has ever fought.',
      ),
      LessonSection.thinkReveal(
        title: 'Why a vaccine works',
        question:
            'A vaccine shows your body a harmless piece of a germ. Why does that make you immune before you ever meet the real one?',
        answer:
            'Because the immune system remembers. After an exposure, "memory cells" stay on file for years. Meet the same germ again and the response is so fast you may never feel sick. A vaccine is a safe rehearsal that installs that memory without the illness.',
      ),
      LessonSection.table(
        title: 'Two teams of defence',
        headers: ['Line', 'How it works', 'Speed'],
        rows: [
          ['Innate', 'Attacks anything foreign', 'Instant, general'],
          ['Adaptive', 'Learns + targets a specific germ', 'Slower, precise'],
          ['Memory', 'Remembers past invaders', 'Instant on re-attack'],
        ],
      ),
      LessonSection.fact(
        title: 'The lymph network',
        body:
            'The lymphatic system has hundreds of lymph nodes — the "swollen glands" you feel when sick are nodes crowded with immune cells fighting an infection.',
      ),
      LessonSection.fact(
        title: 'Fluid that would drown you',
        body:
            'Tissues constantly leak fluid; the lymphatic system drains roughly 3 litres of it back into the blood each day. Without that drainage, you would swell up.',
      ),
    ],
  ),

  // ────────────────────────────────────────────────────────────── 8 ──
  BioEntity(
    id: 'organSystem_human_urinary',
    scale: BioScale.organSystem,
    position: 8,
    name: 'The Urinary System',
    title: 'The Blood Filter',
    moduleId: 'organSystem_human',
    shortDescription:
        'Two kidneys filter your entire blood supply dozens of times a day, saving almost everything and discarding the waste.',
    longDescription:
        'The kidneys are the body\'s water-treatment plant. They filter waste, excess salt, and water out of the blood, tune the balance of minerals, and help hold blood pressure and pH steady. The waste becomes urine, which drains through the ureters to the bladder.\n\nThe astonishing part is the reabsorption: the kidneys filter far more than they discard, clawing back almost everything valuable and keeping only the true waste.',
    relatedIds: [
      'organSystem_human_cardiovascular',
      'organSystem_human_integration',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Your kidneys are strict editors. Every day they draft a river of fluid pulled from your blood — and then delete more than 99% of it, keeping only the tiny fraction that is actually waste.',
      ),
      LessonSection.thinkReveal(
        title: 'The 180-litre puzzle',
        question:
            'Your kidneys filter about 180 litres of fluid from your blood every day — but you only pee out roughly 1.5–2 litres. Where do the other ~178 litres go?',
        answer:
            'Straight back into your blood. The kidneys deliberately over-filter, then reabsorb about 99% of the water, sugar, and useful salts. This "filter everything, reclaim almost everything" design lets them precisely fine-tune what stays and what goes.',
      ),
      LessonSection.fact(
        title: '99% reclaimed',
        body:
            'Of the ~180 litres filtered daily, the kidneys reabsorb roughly 99%, leaving only about 1–2 litres as urine.',
      ),
      LessonSection.table(
        title: 'The plumbing',
        headers: ['Organ', 'Job'],
        rows: [
          ['Kidneys', 'Filter blood; make urine'],
          ['Ureters', 'Carry urine to bladder'],
          ['Bladder', 'Stores urine'],
          ['Urethra', 'Drains urine out of the body'],
        ],
      ),
      LessonSection.fact(
        title: 'More than a filter',
        body:
            'Kidneys also balance salts, steady blood pressure, keep blood pH in range, and release a hormone that tells marrow to make more red blood cells.',
      ),
    ],
  ),

  // ────────────────────────────────────────────────────────────── 9 ──
  BioEntity(
    id: 'organSystem_human_integration',
    scale: BioScale.organSystem,
    position: 9,
    name: 'How the Systems Work Together',
    title: 'No System Alone',
    moduleId: 'organSystem_human',
    shortDescription:
        'No organ system survives on its own — together they hold your inner world steady, a balancing act called homeostasis.',
    longDescription:
        'There are eleven human organ systems in total — the ten majors in this module plus the integumentary system (skin) and the reproductive system. But listing them misses the point: they are not eleven separate machines. They are one machine.\n\nTheir shared mission is homeostasis: keeping your internal conditions — temperature, blood sugar, water, pH, oxygen — steady no matter what the outside world does. Every system is constantly correcting the others.',
    relatedIds: [
      'organSystem_human_cardiovascular',
      'organSystem_human_nervous',
      'organSystem_human_endocrine',
      'organSystem_human_urinary',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Sprint up a flight of stairs. Your heart races, your lungs heave, you sweat, your muscles burn, and within minutes everything settles back to normal. That recovery is not one system — it is nearly all of them, silently coordinating to pull you back to balance.',
      ),
      LessonSection.thinkReveal(
        title: 'Trace one action',
        question:
            'You go for a run. Name as many systems as you can that had to cooperate for that single act.',
        answer:
            'Nervous (commands the muscles), muscular (moves you), skeletal (the frame + fresh blood cells), cardiovascular (delivers oxygen), respiratory (loads that oxygen), endocrine (adrenaline for energy), urinary (balances water + salts lost in sweat), integumentary (skin sweats to cool you). One run — the whole body.',
      ),
      LessonSection.table(
        title: 'The full roster: 11 systems',
        headers: ['System', 'One-line job'],
        rows: [
          ['Cardiovascular', 'Transport — the delivery loop'],
          ['Respiratory', 'Gas exchange — O₂ in, CO₂ out'],
          ['Digestive', 'Extract nutrients from food'],
          ['Nervous', 'Fast control + sensing'],
          ['Endocrine', 'Slow chemical control'],
          ['Skeletal', 'Frame + blood factory'],
          ['Muscular', 'Movement + heat'],
          ['Immune / Lymphatic', 'Defence + fluid drainage'],
          ['Urinary', 'Filter blood, balance fluids'],
          ['Integumentary', 'Skin — barrier + temperature'],
          ['Reproductive', 'Making the next generation'],
        ],
      ),
      LessonSection.fact(
        title: 'The one word that ties it together',
        body:
            'Homeostasis — the maintenance of a steady internal state. It is the shared purpose behind every organ system, and the reason none of them can work alone.',
      ),
      LessonSection.fact(
        title: 'Balance, not stillness',
        body:
            'Homeostasis is not "no change" — it is constant correction. Your body temperature, blood sugar, and pH drift every second and are pulled back, thousands of times a day.',
      ),
    ],
  ),
];
