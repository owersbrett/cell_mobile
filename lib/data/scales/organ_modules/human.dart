import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Organ module: "The Human Organs" — eight individual organs treated as
/// structures (distinct from the organ-SYSTEMS scale). Authored by module agent.
const List<BioEntity> organHumanEntities = <BioEntity>[
  // 0 ─────────────────────────────────────────────────────────── THE HEART
  BioEntity(
    id: 'organ_human_heart',
    scale: BioScale.organ,
    position: 0,
    name: 'The Heart',
    title: 'The Tireless Pump',
    moduleId: 'organ_human',
    shortDescription:
        'A fist-sized muscle that beats about 100,000 times a day without ever taking a break.',
    longDescription:
        'The heart is a four-chambered pump made almost entirely of a special muscle — cardiac muscle — that '
        'never fatigues. Two atria on top receive blood, two ventricles below launch it back out: the right side '
        'to the lungs, the left side to the rest of the body.\n\n'
        'It weighs only about 300 grams, yet over an average lifetime it beats more than 2.5 billion times and '
        'moves enough blood to fill a supertanker. One-way valves snap shut between the beats — that "lub-dub" you '
        'hear is the sound of those valves closing.',
    relatedIds: ['organ_human_lungs'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Attribute', 'Value'],
        rows: [
          ['System', 'Cardiovascular (circulatory)'],
          ['Size/weight', '~300 g, roughly the size of a clenched fist'],
          ['Key job', 'Pump blood — oxygen out, waste back — to every cell'],
          ['Standout fact', '~100,000 beats a day; ~2.5 billion in a lifetime'],
        ],
      ),
      LessonSection.fact(
        title: 'Four chambers, two loops',
        body:
            'Right side → lungs (pick up oxygen). Left side → body (deliver it). '
            'The left ventricle wall is the thickest muscle in the heart because it pushes blood the farthest.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'The heart pumps blood to the whole body — so how does the heart muscle itself get its oxygen?',
        answer:
            'Not from the blood passing through its chambers. Its own dedicated coronary arteries wrap around the '
            'outside and feed the muscle directly. When one clogs, that patch of muscle starves — that is a heart attack.',
      ),
    ],
  ),

  // 1 ─────────────────────────────────────────────────────────── THE BRAIN
  BioEntity(
    id: 'organ_human_brain',
    scale: BioScale.organ,
    position: 1,
    name: 'The Brain',
    title: 'Three Pounds of Universe',
    moduleId: 'organ_human',
    shortDescription:
        'Around 86 billion neurons wired into the most complex object known to exist.',
    longDescription:
        'The brain is a roughly 1.4-kilogram organ of soft, folded tissue that runs everything you are — thought, '
        'memory, movement, emotion, breathing. Its wrinkled outer layer, the cortex, folds so that a huge sheet of '
        'neurons can pack into a small skull.\n\n'
        'It holds about 86 billion neurons, each connecting to thousands of others across trillions of synapses. '
        'Though it makes up only about 2% of your body weight, it burns roughly 20% of your resting energy — the '
        'single most power-hungry organ you own.',
    relatedIds: ['organ_human_eye'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Attribute', 'Value'],
        rows: [
          ['System', 'Central nervous system'],
          ['Size/weight', '~1.4 kg (~2% of body weight)'],
          ['Key job', 'Process signals; run thought, movement, and life-support'],
          ['Standout fact', '~86 billion neurons; ~20% of resting energy use'],
        ],
      ),
      LessonSection.fact(
        title: 'The energy hog',
        body:
            'Two percent of your mass, twenty percent of your fuel. The brain never stops drawing power — '
            'even in deep sleep it stays hungry.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'The brain has no pain receptors of its own. So why do headaches hurt?',
        answer:
            'The pain comes from tissues around the brain — blood vessels, muscles, and the membranes covering it — '
            'not the brain matter itself. Surgeons can operate on an awake patient\'s brain without them feeling the cuts.',
      ),
      LessonSection.paragraph(
        title: 'Why the folds?',
        body:
            'Those deep wrinkles (gyri and sulci) let a cortex the size of a large dinner napkin fold down to fit '
            'inside the skull. More folding means more surface area — and more neurons doing work.',
      ),
    ],
  ),

  // 2 ─────────────────────────────────────────────────────────── THE LUNGS
  BioEntity(
    id: 'organ_human_lungs',
    scale: BioScale.organ,
    position: 2,
    name: 'The Lungs',
    title: 'A Forest of Air Sacs',
    moduleId: 'organ_human',
    shortDescription:
        'Hundreds of millions of tiny air sacs unfold to a gas-exchange surface the size of a tennis court.',
    longDescription:
        'The lungs are a pair of spongy organs that trade gases with the blood: oxygen in, carbon dioxide out. Air '
        'travels down branching airways that end in clusters of microscopic sacs called alveoli, each wrapped in '
        'the thinnest possible mesh of blood vessels.\n\n'
        'There are roughly 300–500 million alveoli in the lungs. Unfolded and laid flat, their combined surface '
        'would cover around 70 square metres — about half a singles tennis court — all packed inside your chest.',
    relatedIds: ['organ_human_heart'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Attribute', 'Value'],
        rows: [
          ['System', 'Respiratory'],
          ['Size/weight', 'Paired; light and spongy, filled with air'],
          ['Key job', 'Exchange oxygen for carbon dioxide with the blood'],
          ['Standout fact', '~300–500 million alveoli; ~70 m² of surface'],
        ],
      ),
      LessonSection.fact(
        title: 'Tennis-court lungs',
        body:
            'All those tiny alveoli, unfolded, would blanket roughly 70 square metres — a gas-exchange surface '
            'the size of half a tennis court, crammed into your rib cage.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Why do the lungs need hundreds of millions of tiny sacs instead of two big balloons?',
        answer:
            'Surface area. Gas exchange only happens across the sac walls, so more, smaller sacs mean vastly more '
            'wall to breathe through. Two big balloons would have a fraction of the surface and couldn\'t supply the body.',
      ),
    ],
  ),

  // 3 ─────────────────────────────────────────────────────────── THE LIVER
  BioEntity(
    id: 'organ_human_liver',
    scale: BioScale.organ,
    position: 3,
    name: 'The Liver',
    title: 'The Body\'s Chemical Plant',
    moduleId: 'organ_human',
    shortDescription:
        'The metabolic hub that runs some 500 different jobs — and the only organ that can regrow a lost lobe.',
    longDescription:
        'The liver is the body\'s largest internal organ and its master chemist. Blood from the gut passes through '
        'it first, so the liver gets to inspect, process, and detoxify almost everything you absorb. It builds '
        'proteins, stores energy as glycogen, makes bile for digesting fats, and breaks down drugs and toxins.\n\n'
        'It performs on the order of 500 distinct functions — no other organ comes close. And it holds a unique '
        'superpower: the liver can regenerate. Remove up to two-thirds of it and the remaining tissue can grow '
        'the lost lobe back.',
    relatedIds: ['organ_human_stomach'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Attribute', 'Value'],
        rows: [
          ['System', 'Digestive / metabolic'],
          ['Size/weight', '~1.5 kg — the largest internal organ'],
          ['Key job', 'Detoxify, build proteins, store energy, make bile'],
          ['Standout fact', '~500 functions; the only organ that regrows a lobe'],
        ],
      ),
      LessonSection.fact(
        title: 'The regenerator',
        body:
            'Cut away up to two-thirds of the liver and it can grow back. It is the only human organ with this '
            'power — which is what makes living-donor liver transplants possible.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Why does blood from your intestines flow through the liver BEFORE reaching the rest of your body?',
        answer:
            'So the liver can screen it first. Everything you absorb — nutrients, drugs, toxins — arrives at the '
            'liver via the portal vein for processing and detox before it circulates. It is a checkpoint, not a bypass.',
      ),
    ],
  ),

  // 4 ────────────────────────────────────────────────────────── THE KIDNEYS
  BioEntity(
    id: 'organ_human_kidneys',
    scale: BioScale.organ,
    position: 4,
    name: 'The Kidneys',
    title: 'The Blood Filters',
    moduleId: 'organ_human',
    shortDescription:
        'Two bean-shaped filters that clean about 180 litres of fluid a day and reclaim 99% of it.',
    longDescription:
        'The kidneys are a pair of fist-sized, bean-shaped organs that filter the blood, balance the body\'s water '
        'and salts, and send the waste out as urine. Each holds around a million microscopic filtering units called '
        'nephrons.\n\n'
        'Together they filter roughly 180 litres of fluid every day — far more than your total blood volume, '
        'because the same blood cycles through again and again. Almost all of that fluid is precious, so the '
        'kidneys reabsorb about 99% of it, leaving only a couple of litres to leave as urine.',
    relatedIds: ['organ_human_liver'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Attribute', 'Value'],
        rows: [
          ['System', 'Urinary (renal)'],
          ['Size/weight', 'Paired; each about the size of a fist'],
          ['Key job', 'Filter blood, balance water/salts, excrete waste'],
          ['Standout fact', '~180 L filtered/day, ~99% reabsorbed'],
        ],
      ),
      LessonSection.fact(
        title: '180 litres, 99% returned',
        body:
            'The kidneys filter about 180 litres of fluid daily, then reabsorb roughly 99% of it. Only ~1–2 litres '
            'actually leaves as urine — the rest is reclaimed.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Your body only holds about 5 litres of blood. So how can the kidneys filter 180 litres a day?',
        answer:
            'Because the same blood passes through them over and over. That 5 litres cycles through the kidneys '
            'dozens of times daily, so the total filtered volume stacks up to roughly 180 litres.',
      ),
    ],
  ),

  // 5 ────────────────────────────────────────────────────────── THE STOMACH
  BioEntity(
    id: 'organ_human_stomach',
    scale: BioScale.organ,
    position: 5,
    name: 'The Stomach',
    title: 'The Acid Cauldron',
    moduleId: 'organ_human',
    shortDescription:
        'A muscular bag that churns food in acid strong enough to dissolve metal — without dissolving itself.',
    longDescription:
        'The stomach is a stretchy, muscular sac that receives swallowed food, mixes it, and begins breaking down '
        'proteins. Its lining pumps out hydrochloric acid, driving the interior to a fierce pH of about 1.5–3.5 — '
        'acidic enough to kill most swallowed microbes and unravel proteins.\n\n'
        'To keep from digesting itself, the stomach coats its own wall in a thick layer of mucus and constantly '
        'rebuilds its lining. Meanwhile its muscular walls churn everything into a soupy paste called chyme before '
        'passing it on to the intestines.',
    relatedIds: ['organ_human_liver'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Attribute', 'Value'],
        rows: [
          ['System', 'Digestive'],
          ['Size/weight', 'Stretchy; holds ~1 litre, expands to several'],
          ['Key job', 'Store, churn, and acid-digest food into chyme'],
          ['Standout fact', 'Interior pH ~1.5–3.5 (hydrochloric acid)'],
        ],
      ),
      LessonSection.fact(
        title: 'pH ~1.5–3.5',
        body:
            'Stomach acid is hydrochloric acid strong enough to dissolve metal. It sterilises most of what you '
            'swallow and starts tearing proteins apart.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If stomach acid is strong enough to dissolve metal, why doesn\'t it digest the stomach itself?',
        answer:
            'A thick coat of mucus lines the wall and neutralises acid at the surface, and the stomach continuously '
            'replaces its lining cells — the whole surface is renewed every few days. When that defence fails, you get an ulcer.',
      ),
    ],
  ),

  // 6 ──────────────────────────────────────────────────────────── THE SKIN
  BioEntity(
    id: 'organ_human_skin',
    scale: BioScale.organ,
    position: 6,
    name: 'The Skin',
    title: 'The Largest Organ',
    moduleId: 'organ_human',
    shortDescription:
        'Your biggest organ — a self-repairing barrier of about 1.5–2 square metres wrapping the entire body.',
    longDescription:
        'The skin is the largest organ in the body: a living sheet of roughly 1.5–2 square metres that seals you '
        'off from the outside world. It blocks pathogens, holds water in, senses touch and temperature, and makes '
        'vitamin D in sunlight. It can account for around 15% of your total body weight.\n\n'
        'It works in layers — a tough outer epidermis that constantly sheds and rebuilds, and a deeper dermis '
        'packed with blood vessels, nerves, sweat glands, and hair roots. Much of household dust is, in fact, '
        'dead skin your body has shed.',
    relatedIds: [],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Attribute', 'Value'],
        rows: [
          ['System', 'Integumentary'],
          ['Size/weight', '~1.5–2 m²; up to ~15% of body weight'],
          ['Key job', 'Barrier, sensation, temperature control, vitamin D'],
          ['Standout fact', 'The single largest organ in the body'],
        ],
      ),
      LessonSection.fact(
        title: 'Biggest of all',
        body:
            'Spread flat, adult skin covers about 1.5–2 square metres and can make up roughly 15% of body weight — '
            'making it, by area and mass, the largest organ you have.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Skin is constantly shedding dead cells. So why doesn\'t your body simply wear thin over time?',
        answer:
            'Because the epidermis makes new cells from below just as fast as it sheds them from above. Fresh cells '
            'are born at the base, push upward, flatten, die, and flake off — the barrier fully renews about every month.',
      ),
      LessonSection.paragraph(
        title: 'More than a wrapper',
        body:
            'Skin does not just hold you in. Its dermis is dense with sensors that report touch, pressure, pain, '
            'and heat, and its sweat glands and blood vessels are your main thermostat — flushing to shed heat, '
            'clamping down to keep it.',
      ),
    ],
  ),

  // 7 ───────────────────────────────────────────────────────────── THE EYE
  BioEntity(
    id: 'organ_human_eye',
    scale: BioScale.organ,
    position: 7,
    name: 'The Eye',
    title: 'The Living Camera',
    moduleId: 'organ_human',
    shortDescription:
        'A biological camera with about 120 million rods and 6 million cones — that projects the world upside-down.',
    longDescription:
        'The eye is a fluid-filled sphere that turns light into vision. The cornea and lens focus incoming light '
        'onto the retina at the back, a screen of light-sensitive cells that fire signals down the optic nerve to '
        'the brain.\n\n'
        'The retina carries roughly 120 million rod cells (dim-light and motion, in shades of grey) and about '
        '6 million cone cells (fine detail and colour, in bright light). Because the lens bends light as it '
        'passes through, the image landing on the retina is actually upside-down — your brain flips it right-side up.',
    relatedIds: ['organ_human_brain'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Attribute', 'Value'],
        rows: [
          ['System', 'Sensory / nervous (vision)'],
          ['Size/weight', 'Paired; each about 2.5 cm across'],
          ['Key job', 'Focus light and convert it into nerve signals'],
          ['Standout fact', '~120 million rods + ~6 million cones per retina'],
        ],
      ),
      LessonSection.fact(
        title: 'Rods and cones',
        body:
            'About 120 million rods handle dim light and motion in greyscale; about 6 million cones deliver sharp '
            'detail and colour in bright light. That split is why colours fade at night.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'The image focused onto the back of your eye is upside-down. So why do you see the world right-side up?',
        answer:
            'The lens flips the image as light passes through, so it lands inverted on the retina. Your brain has '
            'learned to reinterpret that signal and turns it back upright — vision is as much brain as eye.',
      ),
    ],
  ),
];
