import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Organism → "The Potato" — the POTATO-LENS module for the Organism scale.
/// The app's mascot, finally present as a whole living organism: species,
/// tuber-as-organ, life cycle, Andean origins, the blight that starved a
/// nation, and why the potato feeds the world. Six entities, positions 0..5.
const List<BioEntity> organismPotatoEntities = <BioEntity>[
  // 0 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'potato_org_species',
    scale: BioScale.organism,
    position: 0,
    name: 'Solanum tuberosum',
    title: 'The potato is a nightshade',
    moduleId: 'organism_potato',
    shortDescription:
        'The mascot has a Latin name: Solanum tuberosum — a nightshade, cousin to the tomato, eggplant, and chili pepper.',
    longDescription:
        'The potato is a single flowering plant species, Solanum tuberosum, in the family Solanaceae — the nightshades. Its relatives are a rogues\' gallery: tomato, eggplant, bell pepper, tobacco, and genuinely poisonous plants like deadly nightshade.',
    relatedIds: [
      'potato_org_tuber',
      'potato_org_andean',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'You\'ve met the potato as a lump on a plate. Meet it as an organism: a leafy, flowering herb that happens to bury its groceries underground. It shares a family with the tomato on your burger and the pepper on your pizza — and with a few plants that could kill you.',
      ),
      LessonSection.table(
        title: 'The nightshade family reunion (Solanaceae)',
        headers: ['Relative', 'Latin name', 'What we eat'],
        rows: [
          ['Potato', 'Solanum tuberosum', 'The tuber (a stem)'],
          ['Tomato', 'Solanum lycopersicum', 'The fruit'],
          ['Eggplant', 'Solanum melongena', 'The fruit'],
          ['Chili / pepper', 'Capsicum species', 'The fruit'],
          ['Deadly nightshade', 'Atropa belladonna', 'Nothing — it\'s toxic'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The green-potato warning',
        question:
            'Why should you never eat a potato that has turned green or grown long sprouts?',
        answer:
            'Because it\'s a nightshade, and the family makes toxic alkaloids to defend itself. A potato exposed to light produces solanine (a bitter, mildly poisonous alkaloid), concentrated in the green skin and the sprouting eyes. Cut those parts away, or toss the potato entirely.',
      ),
      LessonSection.fact(
        title: 'One species, many faces',
        body:
            'Every russet, Yukon Gold, fingerling, and blue potato you\'ve eaten is the same species — Solanum tuberosum. The differences are varieties within one organism, not separate species.',
      ),
    ],
  ),

  // 1 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'potato_org_tuber',
    scale: BioScale.organism,
    position: 1,
    name: 'The Tuber Is the Organism\'s Vault',
    title: 'You eat a swollen stem',
    moduleId: 'organism_potato',
    shortDescription:
        'The potato you eat is not a root — it\'s a fat underground stem the plant packs with starch to survive the winter.',
    longDescription:
        'A potato tuber is a modified stem. It grows on the tip of an underground shoot called a stolon, swelling as the plant pumps it full of starch — a buried battery of energy to survive winter and fund next spring\'s growth.\n\nThe giveaway is the "eyes." Each eye is a bud — the same kind of bud a stem grows above ground — arranged in a spiral, each ready to sprout a whole new plant. Roots don\'t have buds. Stems do.',
    relatedIds: [
      'potato_org_species',
      'potato_org_lifecycle',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'People call it a root vegetable. It isn\'t. A potato is a stem — an organ the plant evolved not to reach the sun but to hide sugar underground. It\'s a vault, and the eyes are the doors.',
      ),
      LessonSection.thinkReveal(
        title: 'Root or stem?',
        question:
            'How can you tell a potato is a stem, not a root, just by looking at it?',
        answer:
            'The eyes. Each "eye" is a bud, and buds only grow on stems — that\'s the definition of a stem. Roots absorb water and anchor the plant; they never sprout buds. Since a potato is covered in buds arranged in a spiral, it must be a stem.',
      ),
      LessonSection.table(
        title: 'Tuber vs. true root',
        headers: ['Feature', 'Potato tuber (stem)', 'A true root'],
        rows: [
          ['Has buds ("eyes")', 'Yes', 'No'],
          ['Stores starch', 'Yes — that\'s its job', 'Sometimes'],
          ['Can grow a new plant', 'Yes, from any eye', 'No'],
          ['Grows from', 'Tip of a stolon (a shoot)', 'The root system'],
        ],
      ),
      LessonSection.fact(
        title: 'A battery of starch',
        body:
            'A raw potato is roughly 80% water and about 17% starch — long chains of glucose the plant banked as energy. When you eat one, you\'re draining the plant\'s savings account.',
      ),
    ],
  ),

  // 2 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'potato_org_lifecycle',
    scale: BioScale.organism,
    position: 2,
    name: 'The Potato Life Cycle',
    title: 'From one eye, a whole plant',
    moduleId: 'organism_potato',
    shortDescription:
        'Plant a chunk of potato with one eye, and it clones itself into a whole new plant — no seed required.',
    longDescription:
        'A potato has two ways to reproduce. It can flower, get pollinated, and set true seeds (like its tomato cousin). But farmers almost never do that. Instead they plant "seed potatoes" — tubers, or pieces of tuber, each with an eye.\n\nThat eye sprouts, roots down, grows a leafy plant, flowers, and then — underground — swells a fresh crop of new tubers on its stolons. Because each new plant grows from a bud of the parent, it is a clone: genetically identical to the tuber it came from.',
    relatedIds: [
      'potato_org_tuber',
      'potato_org_blight',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Leave a forgotten potato in the cupboard too long and it starts reaching for you with pale, ghostly sprouts. That\'s not decay — that\'s the organism trying to become a whole new plant. It doesn\'t need a seed. It needs an eye and some soil.',
      ),
      LessonSection.table(
        title: 'One turn of the cycle',
        headers: ['Stage', 'What happens'],
        rows: [
          ['1. Seed potato', 'A tuber (or piece) with an eye is planted'],
          ['2. Sprout', 'The eye\'s bud grows a shoot up and roots down'],
          ['3. Plant', 'Leafy stems and foliage build energy from sunlight'],
          ['4. Flowers', 'Blooms appear; the plant can set true seeds'],
          ['5. New tubers', 'Underground stolons swell into a fresh crop'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Clones, not children',
        question:
            'If you plant a piece of a Yukon Gold, is the new plant its offspring — or something stranger?',
        answer:
            'Stranger. It\'s a clone. Because the new plant grows from a bud (an eye) of the parent tuber, not from a fertilized seed, it is genetically identical to the parent. A field of one variety is really one organism copied thousands of times.',
      ),
      LessonSection.fact(
        title: 'Why cloning matters',
        body:
            'Clonal propagation gives farmers perfectly uniform crops — but it also means an entire field shares one set of genes. Keep that in mind two entries from now, when a single mold nearly wipes a country off the map.',
      ),
    ],
  ),

  // 3 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'potato_org_andean',
    scale: BioScale.organism,
    position: 3,
    name: 'Andean Origins',
    title: 'Born high in the mountains',
    moduleId: 'organism_potato',
    shortDescription:
        'The potato was domesticated 7,000–10,000 years ago in the high Andes — and there it still grows in thousands of varieties.',
    longDescription:
        'The potato is not a European crop, despite the fries. It was first domesticated by peoples of the Andes, in the highlands around present-day Peru and Bolivia, somewhere between 7,000 and 10,000 years ago — one of humanity\'s oldest and most important domestications.\n\nSpanish ships carried it to Europe in the 1500s, and from there it spread across the world. But its homeland still holds its true diversity: the Andes grow thousands of native potato varieties in colors and shapes most of the world never sees.',
    relatedIds: [
      'potato_org_species',
      'potato_org_feeds_world',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'The potato in your kitchen is a mountaineer. Its ancestors were tamed on cold, thin-aired Andean slopes thousands of years before Rome existed. Everything the potato became to the rest of the world started there.',
      ),
      LessonSection.thinkReveal(
        title: 'A famous myth, corrected',
        question:
            'Ireland, Idaho, Belgium\'s fries — the potato feels European or American. So where is it actually from?',
        answer:
            'The high Andes of South America — around modern Peru and Bolivia. It was domesticated there 7,000–10,000 years ago and only reached Europe in the 1500s aboard Spanish ships. Every "European" potato dish descends from a South American mountain crop.',
      ),
      LessonSection.table(
        title: 'The potato\'s journey',
        headers: ['When (approx.)', 'What happened'],
        rows: [
          ['~7,000–10,000 yrs ago', 'Domesticated in the Andes (Peru / Bolivia region)'],
          ['1500s', 'Spanish ships carry it to Europe'],
          ['1600s–1700s', 'Spreads across Europe as a staple crop'],
          ['1800s onward', 'Becomes a global food, planted worldwide'],
        ],
      ),
      LessonSection.fact(
        title: 'A living seed bank',
        body:
            'The Andes still cultivate roughly 4,000 native potato varieties — a rainbow of shapes and colors. That wild diversity is a genetic reservoir the whole world\'s food supply may one day need.',
      ),
    ],
  ),

  // 4 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'potato_org_blight',
    scale: BioScale.organism,
    position: 4,
    name: 'Late Blight & the Irish Famine',
    title: 'When one clone met one mold',
    moduleId: 'organism_potato',
    shortDescription:
        'A water mold called Phytophthora infestans rotted Ireland\'s potatoes in the 1840s — and about a million people died.',
    longDescription:
        'Late blight is a disease caused by Phytophthora infestans, an oomycete — a fungus-like "water mold," not a true fungus. It turns healthy potato plants to black slime in days, and it can destroy an entire field.\n\nIn 1840s Ireland, millions of the poorest people depended almost entirely on one clonal variety, the "Lumper." When blight arrived around 1845, that genetic sameness meant the whole crop was equally defenseless. The Great Famine that followed (roughly 1845–1852) killed about a million people, and another million or more emigrated.',
    relatedIds: [
      'potato_org_lifecycle',
      'potato_org_feeds_world',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Two entries ago you learned a field of one potato variety is really one organism cloned thousands of times. Here\'s the price of that trick. When a single mold found a weakness, there was no genetic variation to stop it — and a nation starved.',
      ),
      LessonSection.thinkReveal(
        title: 'Why did ONE disease cause so much death?',
        question:
            'Blights come and go. Why did late blight specifically trigger a catastrophe on this scale?',
        answer:
            'A collision of monoculture and dependence. Ireland\'s poor relied overwhelmingly on a single clonal variety (the Lumper), so every plant was genetically identical and equally vulnerable. With no diversity to resist the mold and no other staple to fall back on, the failure was total — worsened by the social and political conditions of the time.',
      ),
      LessonSection.table(
        title: 'The Great Famine, in numbers',
        headers: ['Fact', 'Figure'],
        rows: [
          ['Cause', 'Phytophthora infestans (a water mold / oomycete)'],
          ['Years', '~1845–1852'],
          ['Deaths', '~1 million'],
          ['Emigrated', '~1–2 million'],
          ['Vulnerable variety', 'The "Lumper" — a single clone'],
        ],
      ),
      LessonSection.fact(
        title: 'Not a fungus',
        body:
            'Phytophthora infestans is an oomycete — a fungus-like organism more closely related to algae than to true fungi. Its name translates, fittingly, to "the plant destroyer."',
      ),
    ],
  ),

  // 5 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'potato_org_feeds_world',
    scale: BioScale.organism,
    position: 5,
    name: 'The Potato Feeds the World',
    title: 'A humble lump, a global staple',
    moduleId: 'organism_potato',
    shortDescription:
        'The potato is among the planet\'s biggest food crops — it produces more food per acre, faster, than almost any grain.',
    longDescription:
        'The potato is one of the world\'s largest food crops, ranking among the top staples alongside maize (corn), wheat, and rice. It earns that spot by being extraordinarily efficient: it delivers more calories and protein per acre, in less time, than the major cereal grains.\n\nIt\'s also good food. A potato is rich in vitamin C and potassium, and — eaten with the skin — a real source of fiber. Its power is simple: it grows in poor soil, in cool climates, on small plots, and it feeds a lot of people from a little land.',
    relatedIds: [
      'potato_org_andean',
      'potato_org_blight',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'The mascot of this whole app is also one of the reasons the modern world can feed itself. The potato doesn\'t look like a superfood or a global power. It just quietly grows more food, on less land, in worse conditions, than almost anything else we plant.',
      ),
      LessonSection.table(
        title: 'The world\'s staple crops',
        headers: ['Rank tier', 'Crop', 'Type'],
        rows: [
          ['Top cereals', 'Maize (corn)', 'Grain'],
          ['Top cereals', 'Wheat', 'Grain'],
          ['Top cereals', 'Rice', 'Grain'],
          ['Top non-cereal', 'Potato', 'Tuber (a stem!)'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why the potato, of all things?',
        question:
            'Grains have fed civilizations for millennia. What lets a lumpy tuber compete with wheat and rice as a global staple?',
        answer:
            'Efficiency and toughness. Per acre, the potato yields more calories and protein, faster, than the big cereal grains — and it grows in cool climates, poor soils, and small plots where grain struggles. More food, less land, harder conditions. That\'s a staple.',
      ),
      LessonSection.fact(
        title: 'Nutrition in the skin',
        body:
            'A potato eaten with its skin is a genuine source of vitamin C, potassium, and fiber. The "just empty carbs" reputation is mostly what we do to it — the frying, not the potato.',
      ),
    ],
  ),
];
