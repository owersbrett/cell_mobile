import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Atoms → "Atoms of a Potato": the potato-lens module for the Atoms scale.
/// Teach atomic and elemental science THROUGH the tuber — what a potato is
/// actually made of, atom by atom. Six entities; every entity carries a HOOK
/// plus think-reveal, table, and fact sections.
const List<BioEntity> atomsPotatoEntities = [
  // ─────────────────────────────────────────────────────────────────────
  // (0) The Elemental Recipe
  // ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'potato_atoms_recipe',
    scale: BioScale.atoms,
    position: 0,
    name: 'The Elemental Recipe',
    title: 'A potato, broken down to its atoms',
    moduleId: 'atoms_potato',
    shortDescription:
        'Peel a potato all the way down to the atoms and you find it is mostly '
        'water and starch — which means mostly oxygen, hydrogen, and carbon.',
    longDescription:
        'A raw potato is about 79% water and 17% carbohydrate (nearly all of '
        'that starch), with roughly 2% protein and just 0.1% fat. Strip away '
        'the words "water" and "starch" and what is left is a bag of atoms — '
        'and only a handful of elements do almost all the work.\n\n'
        'By mass, oxygen wins: it is heavy (16 g/mol) and it is packed into '
        'every H₂O and every ring of starch. But by sheer atom COUNT, hydrogen '
        'runs away with it — tiny, everywhere, two per water molecule and '
        'strung all over the starch. Same potato, two different champions, '
        'depending on whether you weigh the atoms or just count heads.',
    relatedIds: [
      'potato_atoms_potassium',
      'potato_atoms_chnops',
      'potato_atoms_carbon',
      'element_c',
    ],
    sections: [
      LessonSection.fact(
        title: 'HOOK',
        body:
            'About 4 out of every 5 grams of a raw potato is plain water. The '
            '"solid" tuber is a soggy scaffold of starch holding an ocean.',
      ),
      LessonSection.table(
        title: 'A raw potato by mass',
        headers: ['Component', 'Share (by mass)', 'Main elements'],
        rows: [
          ['Water (H₂O)', '~79%', 'O, H'],
          ['Carbohydrate (mostly starch)', '~17%', 'C, H, O'],
          ['Protein', '~2%', 'C, H, O, N, S'],
          ['Minerals (ash: K, P, Mg…)', '~1%', 'K, P, Mg, others'],
          ['Fat', '~0.1%', 'C, H, O'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Weigh it or count it?',
        question:
            'Which single element makes up the LARGEST number of atoms in a '
            'potato — and which makes up the largest MASS?',
        answer:
            'Hydrogen wins by atom count (it is in every water molecule twice '
            'and all through the starch), but oxygen wins by mass — each oxygen '
            'atom weighs 16× a hydrogen atom, so the heavy O in water and '
            'starch tips the scale.',
      ),
      LessonSection.paragraph(
        title: 'Why so few elements?',
        body:
            'Life is built from a short list. Water plus carbohydrate is just '
            'O, H, and C rearranged — three elements accounting for the vast '
            'bulk of the tuber. Everything else (the potassium, the nitrogen, '
            'the trace metals) is the seasoning, not the dish.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────
  // (1) Potassium — the Potato's Signature
  // ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'potato_atoms_potassium',
    scale: BioScale.atoms,
    position: 1,
    name: 'Potassium — the Signature',
    title: 'Element 19, and why the potato is famous',
    moduleId: 'atoms_potato',
    shortDescription:
        'Potassium (K) is the atom the potato is famous for — and one rare '
        'isotope of it makes every potato faintly, harmlessly radioactive.',
    longDescription:
        'A 100 g raw potato carries roughly 420 mg of potassium — one of the '
        'reasons potatoes get name-checked as a dietary potassium source '
        '(often ranked ahead of a banana gram-for-gram). Potassium is element '
        '19, symbol K (from the Latin "kalium"), and your nerves and muscles '
        'run on the potassium-vs-sodium gradient across every cell membrane.\n\n'
        'Here is the fun part: about 0.012% of all potassium atoms are '
        'potassium-40 (⁴⁰K), a naturally radioactive isotope. Because a potato '
        'is full of potassium, it is also — very, very slightly — radioactive. '
        'You are too. So is the banana. It is a real effect and a completely '
        'harmless one.',
    relatedIds: [
      'potato_atoms_recipe',
      'potato_atoms_trace_metals',
      'element_k',
    ],
    sections: [
      LessonSection.fact(
        title: 'HOOK',
        body:
            'Your potato is radioactive. Not "danger" radioactive — ⁴⁰K '
            'radioactive, the same trace glow every living thing carries.',
      ),
      LessonSection.table(
        title: 'Potassium, at a glance',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol / number', 'K / 19'],
          ['In 100 g raw potato', '≈ 420 mg'],
          ['Radioactive isotope', '⁴⁰K (~0.012% of all K atoms)'],
          ['Body job', 'nerve signals, muscle, fluid balance'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why does a potato tick on a Geiger counter?',
        question:
            'A potato has no uranium, no plutonium — nothing exotic. So where '
            'does its faint radioactivity come from?',
        answer:
            'From its own potassium. A tiny fraction (~0.012%) of natural '
            'potassium is the unstable isotope ⁴⁰K, which decays and emits '
            'radiation. Pack a food full of potassium and you pack it full of '
            'a little ⁴⁰K too — harmless, but real.',
      ),
      LessonSection.paragraph(
        title: 'The "K" mystery',
        body:
            'Why is potassium abbreviated K and not P? Because P was already '
            'taken by phosphorus. K comes from "kalium," the Latinized name '
            'rooted in "alkali." The potato\'s signature element hides behind a '
            'letter that is not even in its English name.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────
  // (2) CHNOPS in a Tuber
  // ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'potato_atoms_chnops',
    scale: BioScale.atoms,
    position: 2,
    name: 'CHNOPS in a Tuber',
    title: 'The six elements of life, located inside a potato',
    moduleId: 'atoms_potato',
    shortDescription:
        'Nearly all of any living thing is six elements — C, H, N, O, P, S — '
        'and you can point to exactly where each one lives in a potato.',
    longDescription:
        'Biologists have a mnemonic: CHNOPS — carbon, hydrogen, nitrogen, '
        'oxygen, phosphorus, sulfur. These six elements make up roughly 97–98% '
        'of the mass of a typical organism. A potato is no exception, and the '
        'nice thing is that each element has an address inside the tuber.\n\n'
        'Carbon and hydrogen frame the starch; oxygen fills the water and the '
        'starch rings; nitrogen sits in the proteins and the DNA; phosphorus '
        'holds the DNA backbone together and rides in ATP; sulfur ties protein '
        'chains into their working shapes. Six elements, one potato, every '
        'atom accounted for.',
    relatedIds: [
      'potato_atoms_recipe',
      'potato_atoms_nitrogen',
      'element_c',
      'element_n',
    ],
    sections: [
      LessonSection.fact(
        title: 'HOOK',
        body:
            'Six elements build almost everything alive. Slice a potato and '
            'you can put your finger on where each one is hiding.',
      ),
      LessonSection.table(
        title: 'CHNOPS, addressed inside a potato',
        headers: ['Element', 'Symbol', 'Where it lives in the tuber'],
        rows: [
          ['Carbon', 'C', 'the skeleton of starch, sugars, protein'],
          ['Hydrogen', 'H', 'water and every organic molecule'],
          ['Nitrogen', 'N', 'proteins, enzymes, DNA bases, solanine'],
          ['Oxygen', 'O', 'water and the rings of starch'],
          ['Phosphorus', 'P', 'the DNA backbone and ATP'],
          ['Sulfur', 'S', 'protein cross-links (cysteine, methionine)'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'What do CHNOPS add up to?',
        question:
            'Roughly what fraction of a living potato\'s mass is just these '
            'six elements combined?',
        answer:
            'About 97–98%. CHNOPS covers nearly the entire tuber; potassium, '
            'the trace metals, and everything else share the last 2–3%.',
      ),
      LessonSection.paragraph(
        title: 'The odd ones out',
        body:
            'Notice what is NOT in CHNOPS: potassium, iron, magnesium, all the '
            'metals. They are essential — you would die without them — yet by '
            'mass they are a rounding error. Being vital and being abundant '
            'are two completely different things.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────
  // (3) Nitrogen & Solanine
  // ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'potato_atoms_nitrogen',
    scale: BioScale.atoms,
    position: 3,
    name: 'Nitrogen & Solanine',
    title: 'The single N atom behind the green-potato toxin',
    moduleId: 'atoms_potato',
    shortDescription:
        'The bitter toxin in a green potato is solanine — and everything '
        'dangerous about it hangs on the nitrogen atom in the middle.',
    longDescription:
        'When a potato is exposed to light it turns green (chlorophyll) and '
        'builds up a glycoalkaloid called solanine, formula C₄₅H₇₃NO₁₅. Look '
        'at that formula: 45 carbons, 73 hydrogens, 15 oxygens — and exactly '
        'ONE nitrogen. That lone N is what makes it an alkaloid, and alkaloids '
        'are the plant kingdom\'s pharmacy: caffeine, nicotine, morphine, and '
        'solanine all share nitrogen-bearing rings.\n\n'
        'Nitrogen is a joiner. Its atoms slot into ring structures and carry a '
        'lone pair of electrons, which is exactly what lets solanine interfere '
        'with your nerve enzymes. The green tint is a warning flag; the '
        'bitterness is the alkaloid; and the whole story pivots on one '
        'nitrogen atom.',
    relatedIds: [
      'potato_atoms_chnops',
      'potato_atoms_recipe',
      'element_n',
    ],
    sections: [
      LessonSection.fact(
        title: 'HOOK',
        body:
            'Solanine is C₄₅H₇₃NO₁₅ — 134 atoms, and just ONE of them is '
            'nitrogen. Remove that single N and it is no longer an alkaloid at '
            'all.',
      ),
      LessonSection.table(
        title: 'Nitrogen the alkaloid-maker',
        headers: ['Alkaloid', 'Found in', 'Nitrogen\'s role'],
        rows: [
          ['Solanine', 'green potatoes', 'ring N → nerve-enzyme toxin'],
          ['Caffeine', 'coffee, tea', 'N in the purine ring'],
          ['Nicotine', 'tobacco (a nightshade!)', 'N in a pyridine ring'],
          ['Morphine', 'poppies', 'N gives it its punch'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why does a green potato taste bitter?',
        question:
            'Green skin is just chlorophyll, which is harmless. So why is a '
            'green potato a bad idea to eat?',
        answer:
            'Green is a signal, not the poison. The same light that makes '
            'chlorophyll also drives the potato to build solanine — a bitter, '
            'nitrogen-bearing glycoalkaloid that irritates the gut and nerves. '
            'The green tells you the solanine is likely there.',
      ),
      LessonSection.paragraph(
        title: 'Nitrogen the connector',
        body:
            'Nitrogen has three bonds to give plus a lone pair of electrons, '
            'which makes it a natural hinge in rings and chains. That same '
            'chemistry builds the amino groups in every protein and the bases '
            'in every strand of the potato\'s DNA — the useful side of the '
            'element that also builds the toxin.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────
  // (4) The Trace Metals
  // ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'potato_atoms_trace_metals',
    scale: BioScale.atoms,
    position: 4,
    name: 'The Trace Metals',
    title: 'Iron, magnesium, zinc & friends — a few atoms that matter',
    moduleId: 'atoms_potato',
    shortDescription:
        'A pinch of metal atoms — iron, magnesium, zinc, manganese, copper, '
        'calcium — hides in every potato, and your enzymes cannot work without '
        'them.',
    longDescription:
        'Beyond the potassium headline, a potato carries a quiet cast of metal '
        'atoms in milligram amounts. They are called trace elements because '
        'the quantities are tiny — but "tiny" is not "unimportant." Most of '
        'them are cofactors: metal atoms that sit at the heart of an enzyme '
        'and do the actual chemistry the protein cannot do alone.\n\n'
        'Iron carries oxygen and shuttles electrons; magnesium anchors ATP '
        'and hundreds of enzymes; zinc holds proteins in shape and drives '
        'others; manganese and copper run redox reactions; calcium signals and '
        'builds structure. Six metals, a few milligrams each, and without them '
        'the whole biochemical machine seizes.',
    relatedIds: [
      'potato_atoms_potassium',
      'potato_atoms_recipe',
    ],
    sections: [
      LessonSection.fact(
        title: 'HOOK',
        body:
            'The metals in a potato weigh almost nothing — yet remove the '
            'magnesium and every ATP reaction in the tuber stalls.',
      ),
      LessonSection.table(
        title: 'Trace metals in a potato and what they do',
        headers: ['Metal', 'Symbol', 'What it does'],
        rows: [
          ['Iron', 'Fe', 'oxygen transport, electron shuttling'],
          ['Magnesium', 'Mg', 'anchors ATP; cofactor for 100s of enzymes'],
          ['Zinc', 'Zn', 'holds proteins in shape; enzyme catalysis'],
          ['Manganese', 'Mn', 'antioxidant + metabolic enzymes'],
          ['Copper', 'Cu', 'redox reactions, electron transfer'],
          ['Calcium', 'Ca', 'cell signaling and structure'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'How can a few milligrams matter so much?',
        question:
            'If a potato only holds a handful of milligrams of iron or zinc, '
            'why call these elements essential?',
        answer:
            'Because they work as CATALYSTS, not building blocks. A single '
            'metal atom parked in an enzyme\'s active site can process '
            'thousands of reactions and keep going. You need bulk carbon by '
            'the gram, but a catalyst you need only in a trace — and losing it '
            'shuts a whole pathway down.',
      ),
      LessonSection.paragraph(
        title: 'Cofactors, not filler',
        body:
            'Proteins are made of CHNOPS, but a lot of them are useless until '
            'a metal atom clicks into place. That metal is the cofactor — the '
            'bit that actually grabs, bends, or oxidizes the target. The potato '
            'stocks these atoms the way a kitchen stocks a few precious spices: '
            'small jars, enormous impact.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────
  // (5) Carbon In, Carbon Out
  // ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'potato_atoms_carbon',
    scale: BioScale.atoms,
    position: 5,
    name: 'Carbon In, Carbon Out',
    title: 'The potato is captured air',
    moduleId: 'atoms_potato',
    shortDescription:
        'Almost every carbon atom in a potato was floating in the sky as CO₂ '
        'before a leaf pulled it down and stacked it into starch.',
    longDescription:
        'Here is the trick that never stops being astonishing: a potato does '
        'not build itself out of the soil. Its dry mass is mostly carbon, and '
        'that carbon comes from the AIR. Photosynthesis in the leaves grabs '
        'carbon dioxide (CO₂) and, powered by sunlight, welds those carbon '
        'atoms into sugar, which the plant ships down and stockpiles as starch '
        'in the tuber.\n\n'
        'So a potato is, quite literally, solidified atmosphere plus water. '
        'The soil hands over water and a sprinkle of minerals; the air hands '
        'over the carbon skeleton. Eat the potato and you release that carbon '
        'again — back to CO₂ — completing a loop that ran from sky to tuber to '
        'you.',
    relatedIds: [
      'potato_atoms_recipe',
      'potato_atoms_chnops',
      'element_c',
    ],
    sections: [
      LessonSection.fact(
        title: 'HOOK',
        body:
            'The carbon in your fries used to be in the sky. Photosynthesis '
            'pulled it out of thin air, one CO₂ molecule at a time.',
      ),
      LessonSection.table(
        title: 'The carbon round-trip',
        headers: ['Step', 'Where the carbon is', 'What happens'],
        rows: [
          ['1. In the air', 'CO₂ gas', 'carbon floats as carbon dioxide'],
          ['2. Photosynthesis', 'sugar in the leaf', 'sunlight welds CO₂ into sugar'],
          ['3. Storage', 'starch in the tuber', 'sugar chained up as starch'],
          ['4. You eat it', 'your cells', 'starch broken back to sugar'],
          ['5. You exhale', 'CO₂ gas again', 'carbon returns to the air'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Where does the potato\'s bulk actually come from?',
        question:
            'A potato grows heavy underground. Common sense says the mass came '
            'up from the dirt — but is that right?',
        answer:
            'No. The soil mostly supplies water and a trace of minerals. The '
            'carbon skeleton — the actual dry substance of the tuber — is '
            'built from CO₂ pulled out of the AIR by the leaves. A potato is '
            'far more sky than soil.',
      ),
      LessonSection.paragraph(
        title: 'A potato is a carbon battery',
        body:
            'Starch is just carbon-hydrogen-oxygen locked into long chains — '
            'energy the plant banked from sunlight. When you digest it, you '
            'unbank exactly that energy and let the carbon atoms drift back up '
            'as CO₂. The atoms are borrowed, never spent; the potato just held '
            'them still for a season.',
      ),
    ],
  ),
];
