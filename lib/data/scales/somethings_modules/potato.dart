import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Somethings → "A Potato Is Something" — the POTATO-LENS on existence and
/// information. Six entities that use the humblest spud to teach what it means
/// for a thing to *be*: existence, information, identity, the genome as stored
/// bits, emergence, and the whole nothing→infinity ladder seen through one
/// potato. Rigor under the whimsy.
const List<BioEntity> somethingsPotatoEntities = <BioEntity>[
  BioEntity(
    id: 'somethings_potato_humblest_something',
    scale: BioScale.somethings,
    position: 0,
    name: 'The Humblest Something',
    title: 'A potato is the plainest proof that *anything* exists',
    moduleId: 'somethings_potato',
    shortDescription:
        'Point at a potato. There it is. Congratulations — you have just witnessed the entire miracle of "something rather than nothing."',
    longDescription:
        'A "something" is the smallest possible claim the universe can make: not "what" or "why," just *is*. A potato makes that claim about as loudly and as modestly as anything can. Lumpy, brown, no opinions — and yet undeniably, stubbornly present.\n\n'
        'Start here because a potato hides nothing. It does not argue, glow, or explain itself. It just occupies space and refuses to be nothing. Everything else in this app — atoms, cells, galaxies, infinities — is a fancier version of that single trick.',
    relatedIds: [
      'somethings_potato_bits',
      'somethings_potato_ladder',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'The deepest question in philosophy is "why is there something rather than nothing?" We will not answer it. We will do something better: hold up a potato as Exhibit A that the "something" side won.',
      ),
      LessonSection.thinkReveal(
        title: 'What is the *least* a thing must do to count as "something"?',
        question:
            'A rock, a photon, a thought, a potato — what do they minimally share that makes each of them a "something"?',
        answer:
            'They each occupy a distinguishable state of reality — there is a fact of the matter about them being *here* and *not-nothing*. "Something" is the bare existence claim, before you ask what kind of thing it is. A potato clears that bar with room to spare.',
      ),
      LessonSection.table(
        title: 'Nothing vs. something, refereed by a potato',
        headers: ['Property', 'Nothing', 'A potato'],
        rows: [
          ['Occupies space', 'No', 'Yes (~150 g of it)'],
          ['Has a state to describe', 'No', 'Yes — shape, mass, temperature'],
          ['Can be pointed at', 'No', 'Emphatically yes'],
          ['Refuses to be nothing', 'N/A', 'Its entire career'],
        ],
      ),
      LessonSection.fact(
        title: 'The whole point',
        body:
            'Existence is not rare or exotic. It is the single most common thing there is — and a potato is its most honest ambassador.',
      ),
    ],
  ),
  BioEntity(
    id: 'somethings_potato_bits',
    scale: BioScale.somethings,
    position: 1,
    name: 'A Potato in Bits',
    title: 'How much *information* is one potato?',
    moduleId: 'somethings_potato',
    shortDescription:
        'To fully describe a potato you need information — and the answer ranges from "a napkin sketch" to "more data than exists on Earth," depending on how honest you want to be.',
    longDescription:
        'A bit is the smallest possible unit of information: one yes/no distinction, one fork in the road. Everything describable — a shape, a genome, a temperature — can be written down as some number of bits.\n\n'
        'Describing a potato "well enough" is cheap. Describing it *completely* — every atom, every jiggle — is astronomically expensive. Same potato, wildly different bit-counts. The gap between them is one of the most important ideas in physics and computing.',
    relatedIds: [
      'somethings_potato_genome',
      'somethings_potato_humblest_something',
    ],
    sections: [
      LessonSection.fact(
        title: 'A bit, defined',
        body:
            'One bit = one binary distinction. Yes or no. On or off. This-side or that-side. Every description ever written is ultimately a pile of these.',
      ),
      LessonSection.thinkReveal(
        title: 'How many bits to describe a potato?',
        question:
            'Is it kilobytes (a sketch), megabytes (its genome), or something far larger?',
        answer:
            'All of the above — it depends on the level of description. A rough 3D shape: a few kilobytes. Its full DNA recipe: on the order of ~200 MB (next lesson). Its *complete physical microstate* — the position and motion of every one of its ~10^25 atoms — would take vastly more information than could ever be stored. One potato, three answers separated by many orders of magnitude.',
      ),
      LessonSection.table(
        title: 'One potato at four resolutions',
        headers: ['Description', 'Roughly how much', 'What it captures'],
        rows: [
          ['"A potato"', '~1 byte (a label)', 'Category only'],
          ['3D shape mesh', 'kilobytes', 'Silhouette + lumps'],
          ['Full genome (DNA)', '~200 MB (order-of-magnitude)', 'Its build recipe'],
          ['Every atom & motion', 'astronomically huge', 'The true microstate'],
        ],
      ),
      LessonSection.paragraph(
        title: 'Why the gap matters',
        body:
            'Compression is exactly this: throwing away bits you do not need. "Potato" is the ultimate compression of a potato — one word standing in for 10^25 atoms — and it works because you already know what the missing bits roughly are.',
      ),
    ],
  ),
  BioEntity(
    id: 'somethings_potato_identity',
    scale: BioScale.somethings,
    position: 2,
    name: 'What Makes It a Potato and Not a Rock?',
    title: 'Identity lives in the arrangement, not the atoms',
    moduleId: 'somethings_potato',
    shortDescription:
        'A potato and a rock can be built from many of the same elements. What makes one a potato is not *what* it is made of — it is how it is put together.',
    longDescription:
        'Carbon, oxygen, hydrogen, potassium, phosphorus — a potato and a lump of the right rock can share a surprising amount of raw ingredient list. Grind the potato to a paste and the "potato-ness" is gone, even though every atom remains. Nothing was removed. The *arrangement* was.\n\n'
        'Identity is information: it is the specific, improbable ordering of parts, not the parts themselves. A thing is defined by its distinctions — the pattern that makes it this and not that.',
    relatedIds: [
      'somethings_potato_genome',
      'somethings_potato_order',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Here is a genuinely spooky fact: you could, in principle, disassemble a potato into atoms and reassemble the same atoms into a rock-like lump. Same stuff. No longer a potato. So where did the potato *go*?',
      ),
      LessonSection.thinkReveal(
        title: 'If not the atoms, what is the potato?',
        question:
            'Two objects can share elements. What is the actual difference between a potato and a rock?',
        answer:
            'The arrangement — the pattern, the organization, the information encoded in how the atoms are structured into cells, starch grains, and living tissue. Identity is a property of the *ordering*, not the ingredients. Scramble the order and you keep every atom but lose the thing.',
      ),
      LessonSection.table(
        title: 'Potato vs. rock — where they actually differ',
        headers: ['Feature', 'Potato', 'Rock'],
        rows: [
          ['Shares common elements', 'Yes (C, O, H, K, P…)', 'Yes (some overlap)'],
          ['Organized into cells', 'Yes', 'No'],
          ['Carries a build recipe (DNA)', 'Yes', 'No'],
          ['Can grow / self-replicate', 'Yes', 'No'],
          ['Identity source', 'Arrangement', 'Arrangement'],
        ],
      ),
      LessonSection.fact(
        title: 'The one-liner',
        body:
            'A thing is not its atoms. A thing is the *pattern* its atoms are holding. Information, not matter, is where identity lives.',
      ),
    ],
  ),
  BioEntity(
    id: 'somethings_potato_genome',
    scale: BioScale.somethings,
    position: 3,
    name: "The Potato's Genome as Information",
    title: 'DNA is a book that says "make a potato"',
    moduleId: 'somethings_potato',
    shortDescription:
        'The potato genome is roughly 840 million DNA letters — a stored recipe, written in a four-symbol alphabet, that literally spells out how to build a spud.',
    longDescription:
        'DNA is real, physical information storage. Each base pair is one of four possibilities (A, T, G, C), which is exactly 2 bits of information. The potato genome (*Solanum tuberosum*, sequenced in 2011) is about 844 million base pairs — call it ~840 Mbp.\n\n'
        'Multiply it out: ~840 million base pairs × 2 bits ≈ 1.7 billion bits ≈ ~200 MB of raw recipe. That is the entire written instruction set for building, running, and reproducing a potato — smaller than many phone apps.',
    relatedIds: [
      'somethings_potato_bits',
      'somethings_potato_order',
    ],
    sections: [
      LessonSection.fact(
        title: 'Landmark number',
        body:
            'The potato genome is ~840 million base pairs (~844 Mbp, published 2011). At 2 bits per base pair, that is ~200 MB of raw information — the whole recipe for a potato.',
      ),
      LessonSection.thinkReveal(
        title: 'Why exactly 2 bits per base pair?',
        question:
            'DNA has a 4-letter alphabet: A, T, G, C. How many bits does one letter carry?',
        answer:
            '2 bits. Two yes/no questions pin down one of four options: "Is it A or T (vs. G or C)?" then "Which of that pair?" Four possibilities = 2 bits, always. So DNA is nature\'s 2-bit-per-symbol storage format.',
      ),
      LessonSection.table(
        title: 'From letters to a recipe',
        headers: ['Quantity', 'Value', 'Meaning'],
        rows: [
          ['Alphabet size', '4 (A, T, G, C)', 'Bases'],
          ['Bits per base pair', '2', 'log₂(4)'],
          ['Genome length', '~840 Mbp', '~844 million base pairs'],
          ['Raw information', '~200 MB', 'Order-of-magnitude'],
          ['What it encodes', 'A whole potato', 'Build + run + reproduce'],
        ],
      ),
      LessonSection.paragraph(
        title: 'A humbling comparison',
        body:
            'The complete design for a living, self-replicating, sunlight-storing organism fits in less space than a short video. Biology is astonishingly information-efficient — and the potato is a fine, modest example of it.',
      ),
    ],
  ),
  BioEntity(
    id: 'somethings_potato_order',
    scale: BioScale.somethings,
    position: 4,
    name: 'Order From Simplicity',
    title: 'A few rules of growth, one complicated tuber',
    moduleId: 'somethings_potato',
    shortDescription:
        'Nobody hand-carves a potato. It builds itself from a handful of local rules repeated by every cell — this is emergence, potato-style.',
    longDescription:
        'The genome does not contain a blueprint of the finished potato any more than a chess rulebook contains a finished game. It contains *rules*: when to divide, when to store starch, which way is up. Each cell follows simple local instructions, and complex global form falls out — no architect required.\n\n'
        'This is emergence: complicated, organized structure arising from simple rules applied over and over. The same principle builds snowflakes, ant colonies, brains, and — humbly — the lump in your pantry.',
    relatedIds: [
      'somethings_potato_genome',
      'somethings_potato_ladder',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'The recipe is ~200 MB. A finished potato has ~10^25 atoms in a very particular arrangement. The recipe is billions of times smaller than the thing it makes. So most of the potato is not stored anywhere — it is *computed*, live, by growth.',
      ),
      LessonSection.thinkReveal(
        title: 'How does a tiny recipe build a huge complicated object?',
        question:
            'The genome is far too small to list every atom. So how does it produce the whole tuber?',
        answer:
            'By encoding rules, not results. Each cell runs the same simple local instructions — divide here, store starch there, follow this chemical gradient — and repeats them millions of times. Complex global order emerges from simple rules iterated. The potato is grown, not drawn.',
      ),
      LessonSection.table(
        title: 'Emergence: simple rules, complex outcome',
        headers: ['Simple rule (local)', 'Emergent result (global)'],
        rows: [
          ['Cells divide when fed', 'Bulk of the tuber'],
          ['Store starch below ground', 'The edible, energy-rich lump'],
          ['Follow gravity & light cues', 'Roots down, sprouts up'],
          ['Copy the genome each division', 'Every cell carries the recipe'],
        ],
      ),
      LessonSection.fact(
        title: 'The big idea',
        body:
            'Complexity is not always designed in — often it is *grown* out, one simple rule at a time. That is emergence, and it is how nature cheats the information budget.',
      ),
    ],
  ),
  BioEntity(
    id: 'somethings_potato_ladder',
    scale: BioScale.somethings,
    position: 5,
    name: 'One Potato, the Whole Ladder',
    title: 'A single "something" that reaches from nothing to infinity',
    moduleId: 'somethings_potato',
    shortDescription:
        'This whole app is a ladder from nothing to infinity — and every rung is already inside one potato, if you know where to look.',
    longDescription:
        'Zoom into a potato and you fall down the ladder: cells, molecules, atoms, particles — and eventually the nothings underneath. Zoom out and you climb it: a farm, a supply chain, a planet, a galaxy, the cosmos, the infinities beyond. The potato is not the start or the end. It is the doorway that connects both directions.\n\n'
        'That is the app\'s spine, held in a spud: existence is a single continuous ladder, and any honest "something" — even the humblest — is standing on every rung of it at once.',
    relatedIds: [
      'somethings_potato_humblest_something',
      'somethings_potato_order',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The closing hook',
        body:
            'We began with the plainest possible thing that exists. We end by noticing it was never plain at all — a potato quietly contains the entire journey, nothing on one end and infinity on the other.',
      ),
      LessonSection.thinkReveal(
        title: 'Where does the potato sit on the ladder?',
        question:
            'Nothings below, infinities above — which rung is the potato?',
        answer:
            'Every rung, at once. Zoom in and it becomes cells → molecules → atoms → particles → nothings. Zoom out and it becomes farm → planet → galaxy → cosmos → infinities. The potato is not a single rung — it is the doorway that proves the ladder is one continuous thing.',
      ),
      LessonSection.table(
        title: 'The ladder, read through one potato',
        headers: ['Direction', 'You reach…', 'Ends at'],
        rows: [
          ['Zoom in', 'cells → molecules → atoms → particles', 'nothings'],
          ['Right here', 'one potato', 'a "something"'],
          ['Zoom out', 'farm → planet → galaxy → cosmos', 'infinities'],
        ],
      ),
      LessonSection.fact(
        title: 'The spine in a spud',
        body:
            'From nothing to infinity is one unbroken ladder — and a single humble potato is standing on all of it. That is the whole app, in one "something."',
      ),
    ],
  ),
];
