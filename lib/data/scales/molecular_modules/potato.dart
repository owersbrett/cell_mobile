import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Molecular → "Molecules of a Potato" — the potato-lens module for the
/// Molecular scale. The actual molecules inside a spud and the chemistry that
/// happens when you cook one. (Authored by module agent.)
const List<BioEntity> molecularPotatoEntities = <BioEntity>[
  // 0 ── Starch: Amylose & Amylopectin ────────────────────────────────────
  BioEntity(
    id: 'molecular_potato_starch',
    scale: BioScale.molecular,
    position: 0,
    moduleId: 'molecular_potato',
    name: 'Starch',
    title: 'Amylose & Amylopectin — the Spud\'s Main Molecule',
    shortDescription:
        'A potato is roughly 17% starch by mass — thousands of glucose sugars '
        'strung into two very different chains that give you both mash and gel.',
    longDescription:
        'Starch is how a plant banks energy: glucose molecules linked into long '
        'polymers. Potato starch is a blend of two of them. Amylose is a long, '
        'mostly linear chain of α-1,4-linked glucose that coils into a helix. '
        'Amylopectin is the same α-1,4 backbone but heavily branched with '
        'α-1,6 links, making a huge bushy tree. The typical ratio is about '
        '20% amylose to 80% amylopectin.\n\n'
        'Cook a potato in water and those tight starch granules swell, burst, '
        'and spill their chains out — that\'s gelatinisation. The amylose '
        'leaking out is what thickens a sauce and lets a cooled potato set into '
        'a sliceable, salad-ready gel.',
    relatedIds: ['molecular_potato_maillard', 'molecular_potato_browning'],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'Cut a potato open and you are basically looking at a warehouse of '
            'sugar — just locked up so tightly it tastes like nothing. Cooking '
            'is how you break into the vault.',
      ),
      LessonSection.thinkReveal(
        title: 'One backbone, two shapes',
        question:
            'Amylose and amylopectin are both chains of the same glucose sugar '
            'with the same α-1,4 links. So what actually makes them behave so '
            'differently in the pot?',
        answer:
            'The branching. Amylose is nearly straight and coils into a tidy '
            'helix, so it packs and gels. Amylopectin adds α-1,6 branch points '
            'roughly every 20–25 glucose units, exploding into a bushy tree '
            'that swells and softens instead. Same building block, opposite '
            'texture.',
      ),
      LessonSection.table(
        title: 'The two starch chains',
        headers: ['Property', 'Amylose', 'Amylopectin'],
        rows: [
          ['Share of potato starch', '~20%', '~80%'],
          ['Bonds', 'α-1,4 (linear)', 'α-1,4 + α-1,6 (branched)'],
          ['Shape', 'Long coiled helix', 'Large branched tree'],
          ['In the kitchen', 'Thickens & gels', 'Swells & softens'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'A raw potato is about 17% starch by mass — the single biggest '
            'molecule in the whole tuber.',
      ),
    ],
  ),

  // 1 ── Solanine: the Potato's Toxin ─────────────────────────────────────
  BioEntity(
    id: 'molecular_potato_solanine',
    scale: BioScale.molecular,
    position: 1,
    moduleId: 'molecular_potato',
    name: 'Solanine',
    title: 'The Potato\'s Built-In Toxin — C₄₅H₇₃NO₁₅',
    shortDescription:
        'The bitter glycoalkaloid a potato brews to defend itself — harmless in '
        'trace amounts, genuinely toxic when green skin and sprouts run wild.',
    longDescription:
        'Potatoes are nightshades, and like their relatives they make chemical '
        'defences. Solanine is a steroidal glycoalkaloid — a steroid-shaped '
        'core with sugars hung off it — formula C₄₅H₇₃NO₁₅. It tastes bitter, '
        'deters insects and grazers, and in large enough doses is toxic to '
        'humans too, disrupting nerve signalling and irritating the gut.\n\n'
        'The catch: it concentrates exactly where you can see the warning. '
        'Green patches (from light exposure), sprouting eyes, and the skin '
        'carry the most. Peeling green areas, cutting out sprouts, and storing '
        'spuds cool and dark keeps levels low. When in doubt, bitterness is the '
        'tell — trust it.',
    relatedIds: ['molecular_potato_vitc_k'],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'That greenish potato at the back of the drawer isn\'t just old — '
            'it\'s armed. Green means the tuber has been making a defence '
            'chemical, and your tongue can taste the warning before your gut '
            'ever files a complaint.',
      ),
      LessonSection.thinkReveal(
        title: 'Green skin: the real signal',
        question:
            'A potato turns green in the light. Is the green pigment itself the '
            'thing that can make you sick?',
        answer:
            'No — the green is chlorophyll, which is harmless. But the same '
            'light exposure that greens the skin also drives up solanine, the '
            'actual glycoalkaloid toxin. The green is a bystander flag; solanine '
            'is what you\'re really cutting away.',
      ),
      LessonSection.table(
        title: 'Where the solanine hides',
        headers: ['Part of the potato', 'Solanine level'],
        rows: [
          ['Sprouts & eyes', 'Highest'],
          ['Green skin', 'High'],
          ['Peel / just under skin', 'Moderate'],
          ['Inner flesh (white)', 'Low'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'Solanine is a steroidal glycoalkaloid, C₄₅H₇₃NO₁₅ — and unlike '
            'starch, boiling barely touches it. Cut it out; don\'t cook it out.',
      ),
    ],
  ),

  // 2 ── Vitamin C & Potassium ────────────────────────────────────────────
  BioEntity(
    id: 'molecular_potato_vitc_k',
    scale: BioScale.molecular,
    position: 2,
    moduleId: 'molecular_potato',
    name: 'Vitamin C & Potassium',
    title: 'Ascorbic Acid + K⁺ — Why the Humble Spud Is Good For You',
    shortDescription:
        'A potato is quietly nutritious: real vitamin C to keep your collagen '
        'together and more potassium than a banana to keep your nerves firing.',
    longDescription:
        'Past all that starch, a potato carries two standout nutrients. Vitamin '
        'C (ascorbic acid, C₆H₈O₆) is a water-soluble antioxidant your body '
        'needs to build collagen — the scaffolding of skin, gums, and blood '
        'vessels. Potassium arrives as the K⁺ ion, an electrolyte that helps '
        'run nerve impulses, muscle contractions, and blood pressure.\n\n'
        'Both are fragile in their own way. Vitamin C is heat-sensitive and '
        'water-soluble, so hard-boiling in lots of water leaches it away. K⁺ '
        'also dissolves into cooking water. Bake or steam with the skin on and '
        'you keep far more of both.',
    relatedIds: ['molecular_potato_solanine', 'molecular_potato_browning'],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'Sailors once carried potatoes to fend off scurvy — the same '
            'disease that rots gums when vitamin C runs out. The "boring" spud '
            'was quietly keeping crews alive.',
      ),
      LessonSection.thinkReveal(
        title: 'Boil vs. bake',
        question:
            'You boil one potato in a big pot of water and bake another in its '
            'skin. Which keeps more of its vitamin C and potassium, and why?',
        answer:
            'The baked one. Both vitamin C (water-soluble and heat-sensitive) '
            'and potassium (a water-soluble ion) leach out into boiling water '
            'and get poured down the drain. Baking or steaming with the skin on '
            'keeps them trapped in the flesh.',
      ),
      LessonSection.table(
        title: 'Two nutrients, two jobs',
        headers: ['Nutrient', 'Chemical form', 'What it does'],
        rows: [
          ['Vitamin C', 'Ascorbic acid, C₆H₈O₆', 'Antioxidant; builds collagen'],
          ['Potassium', 'K⁺ ion', 'Nerve & muscle signalling; blood pressure'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'A medium baked potato with the skin carries more potassium than a '
            'banana — one of the richest everyday sources of K⁺ on your plate.',
      ),
    ],
  ),

  // 3 ── Enzymatic Browning ───────────────────────────────────────────────
  BioEntity(
    id: 'molecular_potato_browning',
    scale: BioScale.molecular,
    position: 3,
    moduleId: 'molecular_potato',
    name: 'Enzymatic Browning',
    title: 'Why a Cut Potato Goes Grey-Brown in Minutes',
    shortDescription:
        'Slice a raw potato, walk away, come back to a dull brown surface — '
        'that\'s an enzyme, oxygen, and a race you can win with cold water.',
    longDescription:
        'Cutting a potato ruptures its cells and lets an enzyme called '
        'polyphenol oxidase (PPO) meet two things it was kept apart from: the '
        'potato\'s own phenolic compounds and oxygen from the air. PPO oxidises '
        'those phenols into quinones, which then link up into brown-black '
        'pigments called melanins. No heat required — it happens at room '
        'temperature in minutes.\n\n'
        'Because it needs the enzyme AND oxygen, you can stop it three ways: '
        'drop the slices in cold water to shut out air, add acid (lemon juice, '
        'vinegar) to slow the enzyme, or blanch briefly in hot water to '
        'denature PPO entirely. This is raw-only chemistry — and it is not the '
        'same reaction as the golden browning you cook for.',
    relatedIds: ['molecular_potato_maillard', 'molecular_potato_starch'],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'A cut potato browning on the board isn\'t rotting — it\'s bruising. '
            'You broke the cells open, and an enzyme that was minding its own '
            'business just met the air.',
      ),
      LessonSection.thinkReveal(
        title: 'Three ways to stop it',
        question:
            'Chefs drop peeled potatoes into a bowl of cold water. Others use a '
            'squeeze of lemon, or a quick dunk in boiling water. All three stop '
            'browning — but by attacking different parts of the reaction. How?',
        answer:
            'Cold water shuts out the oxygen the reaction needs. Acid (lemon, '
            'vinegar) lowers the pH so the PPO enzyme works far more slowly. A '
            'hot blanch denatures PPO outright — kill the enzyme and the '
            'reaction can\'t happen at all. Remove oxygen, slow the enzyme, or '
            'destroy the enzyme: pick your lever.',
      ),
      LessonSection.table(
        title: 'Enzymatic browning: the ingredients',
        headers: ['Piece', 'Role'],
        rows: [
          ['Polyphenol oxidase (PPO)', 'The enzyme that starts it'],
          ['Phenolic compounds', 'The raw material it oxidises'],
          ['Oxygen (air)', 'Required reactant'],
          ['Melanins', 'The brown pigment produced'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'This is a cold, enzyme-driven reaction — no heat, no flavour gain. '
            'It is completely different from the tasty browning you get in a '
            'hot pan.',
      ),
    ],
  ),

  // 4 ── The Maillard Reaction ────────────────────────────────────────────
  BioEntity(
    id: 'molecular_potato_maillard',
    scale: BioScale.molecular,
    position: 4,
    moduleId: 'molecular_potato',
    name: 'The Maillard Reaction',
    title: 'Why Roasted & Fried Potatoes Go Golden and Delicious',
    shortDescription:
        'The golden crust on a roast potato is hundreds of new flavour '
        'molecules — sugars and amino acids reacting under real heat.',
    longDescription:
        'The Maillard reaction is where a fried or roasted potato gets its '
        'colour AND its flavour. When reducing sugars meet amino acids (the '
        'building blocks of protein) at high heat — roughly 140–165°C — they '
        'react and cascade into hundreds of new aromatic compounds: nutty, '
        'toasty, savoury. It\'s named for the chemist Louis-Camille Maillard, '
        'who described it in 1912.\n\n'
        'Crucially, this is NOT caramelisation. Caramelisation is sugar alone '
        'breaking down under heat; Maillard needs amino acids in the mix. It '
        'also needs a dry, hot surface — which is why a wet, steaming potato '
        'stays pale and a well-dried, oil-slicked one goes gloriously crisp and '
        'brown.',
    relatedIds: ['molecular_potato_acrylamide', 'molecular_potato_starch'],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'The difference between a sad pale boiled potato and a golden roast '
            'one isn\'t just temperature — it\'s an entire chemical reaction '
            'you can only unlock when the surface goes dry and hot.',
      ),
      LessonSection.thinkReveal(
        title: 'Maillard vs. caramelisation',
        question:
            'Both make food brown and delicious under heat. So what is the one '
            'ingredient the Maillard reaction needs that plain caramelisation '
            'does not?',
        answer:
            'Amino acids. Caramelisation is sugar breaking down all by itself. '
            'The Maillard reaction pairs reducing sugars WITH amino acids, and '
            'that partnership is what produces the deep savoury-nutty flavours — '
            'not just sweetness. Same golden colour, different chemistry.',
      ),
      LessonSection.table(
        title: 'Reading the browning',
        headers: ['Feature', 'Maillard reaction', 'Enzymatic browning'],
        rows: [
          ['Needs heat?', 'Yes (~140–165°C)', 'No — room temperature'],
          ['Reactants', 'Sugars + amino acids', 'Phenols + oxygen (via PPO)'],
          ['Result', 'Flavour + golden crust', 'Dull grey-brown, no flavour'],
          ['When', 'Frying / roasting', 'Raw cut surface in air'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'The Maillard reaction really gets going around 140–165°C — well '
            'above boiling. A potato sitting in water tops out at 100°C, which '
            'is exactly why boiled potatoes never brown.',
      ),
    ],
  ),

  // 5 ── Acrylamide: the Fry Trade-off ────────────────────────────────────
  BioEntity(
    id: 'molecular_potato_acrylamide',
    scale: BioScale.molecular,
    position: 5,
    moduleId: 'molecular_potato',
    name: 'Acrylamide',
    title: 'The Fry Trade-off — When Golden Goes Too Far',
    shortDescription:
        'The same high-heat browning that makes fries taste incredible can, '
        'pushed too hot and too dark, form a compound worth being honest about.',
    longDescription:
        'Acrylamide (C₃H₅NO) is the honest footnote to the Maillard reaction. '
        'When the amino acid asparagine — which potatoes have plenty of — reacts '
        'with reducing sugars at high heat, above about 120°C, some of it '
        'converts to acrylamide. The darker and hotter the fry, the more forms. '
        'It\'s classed as a probable human carcinogen, so it\'s a genuine '
        'reason not to burn your chips.\n\n'
        'The fix isn\'t to stop cooking — it\'s to stop overcooking. "Go for '
        'gold, not brown": fry to a light golden colour, not deep mahogany. '
        'Soaking cut potatoes in water first rinses out some of the sugars that '
        'feed the reaction, and storing spuds in the pantry rather than the '
        'fridge keeps their sugar levels down.',
    relatedIds: ['molecular_potato_maillard'],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'Every gorgeous fry is a trade-off. The chemistry that browns it is '
            'the same chemistry that, taken too far, leaves something behind you '
            'don\'t want a lot of. The skill is knowing when to stop.',
      ),
      LessonSection.thinkReveal(
        title: 'Why the fridge is a trap',
        question:
            'Storing potatoes in the fridge to keep them fresh actually makes '
            'them form MORE acrylamide when fried. Why would cold storage make '
            'it worse?',
        answer:
            'Cold triggers "cold sweetening" — the potato converts some starch '
            'into reducing sugars. Those extra sugars are exactly the fuel the '
            'acrylamide reaction needs. More sugar at the surface plus high heat '
            'means more acrylamide. Keep potatoes in a cool, dark pantry '
            'instead — not the fridge.',
      ),
      LessonSection.table(
        title: 'The recipe for (too much) acrylamide',
        headers: ['Factor', 'Effect on acrylamide'],
        rows: [
          ['Asparagine (in the potato)', 'Key amino-acid precursor'],
          ['Reducing sugars', 'React with asparagine'],
          ['Temperature > 120°C', 'Drives the reaction'],
          ['Darker / longer cook', 'More acrylamide forms'],
          ['Soak & "go for gold"', 'Cuts it down'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'Acrylamide (C₃H₅NO) forms above ~120°C from asparagine + sugars, '
            'and is classed as a probable human carcinogen. The rule of thumb: '
            'fry to golden, never to brown.',
      ),
    ],
  ),
];
