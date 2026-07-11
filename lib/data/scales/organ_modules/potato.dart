import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Organ module: "The Potato's Organs" — the POTATO-LENS on the organ scale.
/// The organs of the potato PLANT and how they cooperate to build the tuber.
/// (Authored by module agent.)
const List<BioEntity> organPotatoEntities = <BioEntity>[
  // 0 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organ_potato_tuber',
    scale: BioScale.organ,
    position: 0,
    name: 'The Tuber',
    title: 'A Storage Organ (the star of the show)',
    moduleId: 'organ_potato',
    shortDescription:
        'The potato itself is not a root — it is a swollen underground STEM, an organ built for one job: hoarding starch.',
    longDescription:
        "Meet me, the tuber — the part of the plant you actually eat. I am a storage organ: a chunk of stem that grew fat with starch to bankroll next spring's growth. The plant packs sugar into me all summer so a new potato empire can rise when the days warm again.\n\n"
        "The classic mistake is calling me a root. I am not. My eyes are buds, my \"skin\" is stem skin, and inside I have the plumbing of a stem — dead giveaways that I am a modified underground stem, not a root at all.",
    relatedIds: ['organ_potato_stolon', 'organ_potato_roots', 'organ_potato_eyes'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            "You have eaten thousands of me. But you have been eating a STEM this whole time — a stem that decided napping underground and getting rich on starch beat standing up in the sun.",
      ),
      LessonSection.thinkReveal(
        title: 'Root or stem?',
        question:
            "A potato grows underground, so surely it is a root — right? What single feature proves it is actually a stem?",
        answer:
            "The EYES. Each eye is an axillary bud sitting at a node, and only stems produce buds at nodes. True roots never form buds like that. Add in the internal stem plumbing (vascular ring, pith) and the verdict is unanimous: the tuber is a modified STEM, not a root.",
      ),
      LessonSection.table(
        title: 'Tuber vs. a true root — spot the difference',
        headers: ['Feature', 'Tuber (me, a stem)', 'A true root'],
        rows: [
          ['Buds / eyes', 'Yes — buds at nodes', 'None'],
          ['Nodes & internodes', 'Present (compressed)', 'Absent'],
          ['Grows sprouts', 'Yes, from every eye', 'No'],
          ['Main job', 'Store starch', 'Absorb water & minerals'],
        ],
      ),
      LessonSection.fact(
        title: 'Starch bank',
        body:
            "A tuber is roughly 80% water and up to ~18% starch by fresh weight — a dense underground battery pre-loaded for next season's launch.",
      ),
    ],
  ),

  // 1 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organ_potato_stolon',
    scale: BioScale.organ,
    position: 1,
    name: 'The Stolon',
    title: 'The runner whose tip becomes a potato',
    moduleId: 'organ_potato',
    shortDescription:
        'A stolon is a horizontal underground stem — a runner — and when its tip swells, a brand-new tuber is born.',
    longDescription:
        "I am the stolon: a slender stem the plant sends creeping sideways through the dark soil. I am not a root either — I am stem tissue on an adventure, scouting for a good spot to build a tuber.\n\n"
        "When I decide the moment is right, my TIP stops growing outward and starts fattening. That swelling tip is where a potato comes from. The tuber and I are the same tissue type; I am simply the stem before it got rich.",
    relatedIds: ['organ_potato_tuber', 'organ_potato_leaves'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            "Every potato has a birthplace, and it is not a seed and not a root — it is my tip. I am the runner; the potato is what happens when I stop running and start storing.",
      ),
      LessonSection.thinkReveal(
        title: 'Where does the tuber form?',
        question:
            "A stolon runs sideways underground. Which part of it becomes the potato — the middle, the base, or the tip?",
        answer:
            "The TIP. The stolon tip stops elongating and begins radial swelling as starch floods in — a process called tuberization. The rest of me stays thin; only the tip becomes the tuber.",
      ),
      LessonSection.table(
        title: 'Stolon vs. the tuber it makes',
        headers: ['Trait', 'Stolon (runner)', 'Tuber (swollen tip)'],
        rows: [
          ['Shape', 'Thin & horizontal', 'Fat & rounded'],
          ['Job', 'Explore, position', 'Store starch'],
          ['Tissue type', 'Stem', 'Stem (same!)'],
          ['Triggered by', 'Growth signals', 'Short days + cool nights'],
        ],
      ),
      LessonSection.fact(
        title: 'Same stem, two jobs',
        body:
            "Stolon and tuber are the same organ system caught at two moments — a runner, then a runner that got rich. Proof the tuber was never a root.",
      ),
    ],
  ),

  // 2 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organ_potato_roots',
    scale: BioScale.organ,
    position: 2,
    name: 'The Roots',
    title: 'The real roots (and no, the potato is not one)',
    moduleId: 'organ_potato',
    shortDescription:
        'The potato plant grows a fibrous root system to drink water and minerals — completely separate from the tuber.',
    longDescription:
        "I am the roots — the true ones. While the tuber hogs the spotlight, I do the unglamorous work: a fibrous web of fine roots pulling water and dissolved minerals out of the soil to keep the whole plant alive.\n\n"
        "I want to clear up the family gossip: the tuber is NOT me. It is a stem. I absorb; the tuber stores. We are different organs doing different jobs, and confusing us is the most common potato mix-up there is.",
    relatedIds: ['organ_potato_tuber', 'organ_potato_stolon'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            "Here is the potato plant's dirty secret: it has real roots, and they are not the part you eat. I am the actual root system — thin, fibrous, thirsty, and permanently upstaged by a swollen stem.",
      ),
      LessonSection.thinkReveal(
        title: 'Two things underground',
        question:
            "Both the roots and the tuber live in the dark soil. So why do we call one a root organ and the other a stem organ?",
        answer:
            "Job and anatomy. Roots ABSORB water and minerals and never form buds. The tuber STORES starch and is covered in buds (eyes). Same neighborhood, totally different organs — absorption vs. storage, root vs. stem.",
      ),
      LessonSection.table(
        title: 'Roots vs. tuber — two underground organs',
        headers: ['Feature', 'Roots (me)', 'Tuber'],
        rows: [
          ['Organ type', 'Root', 'Stem'],
          ['Main job', 'Absorb water & minerals', 'Store starch'],
          ['Has buds/eyes?', 'No', 'Yes'],
          ['Grows a new plant?', 'No', 'Yes (from eyes)'],
        ],
      ),
      LessonSection.fact(
        title: 'Fibrous, not fat',
        body:
            "The potato plant is a FIBROUS-rooted species — many thin roots, no single fat taproot. The fat underground part is the tuber, and it is a stem.",
      ),
    ],
  ),

  // 3 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organ_potato_leaves',
    scale: BioScale.organ,
    position: 3,
    name: 'The Leaves',
    title: 'The solar panels that fill the tuber',
    moduleId: 'organ_potato',
    shortDescription:
        'Green leaves run photosynthesis, and the sugar they make is shipped straight down to load the tuber with starch.',
    longDescription:
        "I am the leaves — the plant's solar array. Up in the sun I catch light and turn air (CO2) and water into sugar. Every gram of starch in a potato started as sugar I made on a bright afternoon.\n\n"
        "But I do not keep the sugar. I load it into the phloem — the plant's sugar highway — and ship it DOWN to the tuber. Biologists call me the \"source\" and the tuber the \"sink\": I make it, the tuber banks it.",
    relatedIds: ['organ_potato_tuber', 'organ_potato_stolon'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            "The potato you roast was built out of sunlight. I am the leaf that caught that sunlight, and I spent all summer shipping sugar downstairs so the tuber could get fat.",
      ),
      LessonSection.thinkReveal(
        title: 'Source and sink',
        question:
            "The tuber is full of starch, but the tuber underground never sees the sun. So where did all its energy come from?",
        answer:
            "From ME, the leaves. Photosynthesis in the leaves (the SOURCE) makes sugar, which travels through the phloem down to the tuber (the SINK), where it is converted to starch and stored. Leaf → phloem → tuber. That is source-to-sink flow.",
      ),
      LessonSection.table(
        title: 'Source vs. sink',
        headers: ['Role', 'Organ', 'What it does'],
        rows: [
          ['Source', 'Leaves', 'Make sugar by photosynthesis'],
          ['Transport', 'Phloem', 'Carry sugar downward'],
          ['Sink', 'Tuber', 'Store sugar as starch'],
        ],
      ),
      LessonSection.fact(
        title: 'The green rule',
        body:
            "Leaves must stay green and sunlit — but a TUBER turning green is a warning: light exposure makes it produce toxic solanine. Green leaf good, green potato bad.",
      ),
    ],
  ),

  // 4 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organ_potato_flower_berry',
    scale: BioScale.organ,
    position: 4,
    name: 'The Flower & Berry',
    title: 'The potato\'s true fruit (small, green, toxic)',
    moduleId: 'organ_potato',
    shortDescription:
        'Potato plants flower and can set little green berries — the true fruit, holding real seeds, and quite toxic to eat.',
    longDescription:
        "I am the flower and the berry — the part almost nobody notices. The potato plant blooms with small star-shaped flowers, and when pollinated, some flowers ripen into little green BERRIES packed with true seeds.\n\n"
        "This is the twist: the berry is the potato's real fruit, not the tuber. But do not snack on me — like the plant's leaves and stems, my berries carry toxic solanine. I make seeds; the tuber makes clones.",
    relatedIds: ['organ_potato_tuber', 'organ_potato_eyes'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            "Surprise: the potato has a real fruit, and you have probably never seen it. It is a little green berry hanging above the soil — the botanical fruit the tuber is so often mistaken for.",
      ),
      LessonSection.thinkReveal(
        title: 'What is the real fruit?',
        question:
            "People call the tuber the potato's \"fruit.\" Botanically that is wrong. So what IS the true fruit of the potato plant?",
        answer:
            "The BERRY. A true fruit develops from a flower and contains seeds — and the potato's small green berry does exactly that. The tuber is a storage stem with no seeds. So the berry is the fruit; the tuber is not.",
      ),
      LessonSection.table(
        title: 'Berry vs. tuber — fruit vs. storage',
        headers: ['Feature', 'Berry (true fruit)', 'Tuber'],
        rows: [
          ['Comes from', 'A flower', 'A stolon tip'],
          ['Contains', 'True seeds', 'Stored starch'],
          ['Above/below ground', 'Above', 'Below'],
          ['Safe to eat?', 'No — toxic solanine', 'Yes (when not green)'],
        ],
      ),
      LessonSection.fact(
        title: 'Two ways to make more potatoes',
        body:
            "Berries give SEEDS (genetic variety, used by breeders). Tubers give CLONES (from eyes). Farmers plant clones; breeders sow seeds.",
      ),
    ],
  ),

  // 5 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organ_potato_eyes',
    scale: BioScale.organ,
    position: 5,
    name: 'The Eyes',
    title: 'Buds that clone a whole new plant',
    moduleId: 'organ_potato',
    shortDescription:
        'Each "eye" on a potato is a bud sitting at a node — and every one can sprout into an entire new plant.',
    longDescription:
        "I am the eyes — those little dimples on the potato's skin. Each of us is an axillary bud sitting at a node on the tuber's surface, exactly where buds sit on any stem. (This, remember, is the proof the tuber is a stem.)\n\n"
        "Give me warmth, moisture, and a little time and I sprout: a shoot heads up, roots head down, and a whole new potato plant grows — a genetic clone of the parent. Chop a potato into eye-bearing chunks and you can plant every piece.",
    relatedIds: ['organ_potato_tuber', 'organ_potato_stolon'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            "Those \"eyes\" are not decoration and they are not watching you — each one is a sleeping bud ready to grow an entire new plant. One potato is a whole orchard waiting for a reason to wake up.",
      ),
      LessonSection.thinkReveal(
        title: 'Why eyes settle the argument',
        question:
            "How do the eyes, all by themselves, prove once and for all that a potato is a stem and not a root?",
        answer:
            "Because eyes are axillary BUDS, and buds form only at nodes on STEMS. Roots cannot make buds at nodes like this. So a surface covered in eyes is a surface covered in stem-nodes — the tuber is a stem, case closed.",
      ),
      LessonSection.table(
        title: 'From eye to new plant',
        headers: ['Step', 'What the eye does'],
        rows: [
          ['1. Dormant', 'Sits as a bud at a node'],
          ['2. Sprout', 'Warmth wakes it; a shoot pushes out'],
          ['3. Grow', 'Shoot goes up, roots go down'],
          ['4. Clone', 'A full new plant — genetically identical'],
        ],
      ),
      LessonSection.fact(
        title: 'Seed potatoes',
        body:
            "Farmers plant \"seed potatoes\" — tuber chunks each carrying at least one eye. It is cloning, not seeding: every plant in the field is a copy of its parent.",
      ),
    ],
  ),
];
