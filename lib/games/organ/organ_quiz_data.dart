// Organ Quiz — fact bank for the reworked Organ-scale game.
//
// Rapid-fire multiple choice: a "The part that ..." prompt + 4 options. The game
// alternates between [OrganRealm.human] and [OrganRealm.plant] (mostly potato).
// `fact` is shown as a post-answer flare (same signature mechanic as the other
// scales). All Canvas-rendered — no assets. Content authored to be accurate and
// kid-friendly; distractors are plausible same-realm organs.

enum OrganRealm { human, plant }

class OrganQuestion {
  final OrganRealm realm;
  final String prompt; // "The part that ..."
  final String answer; // correct organ
  final List<String> wrong; // exactly 3 distractors (same realm)
  final String fact; // one-line fun fact for the answer flare
  const OrganQuestion({
    required this.realm,
    required this.prompt,
    required this.answer,
    required this.wrong,
    required this.fact,
  });

  /// All four options unshuffled (answer first). The game should shuffle.
  List<String> get options => [answer, ...wrong];
}

const List<OrganQuestion> kOrganQuiz = [
  // ---- HUMAN ORGANS ----
  OrganQuestion(
    realm: OrganRealm.human,
    prompt: 'The part that pumps blood through your body',
    answer: 'Heart',
    wrong: ['Lungs', 'Liver', 'Kidneys'],
    fact: 'Your heart beats about 100,000 times every day.',
  ),
  OrganQuestion(
    realm: OrganRealm.human,
    prompt: 'The part that takes in oxygen and releases carbon dioxide',
    answer: 'Lungs',
    wrong: ['Heart', 'Stomach', 'Liver'],
    fact: 'Spread flat, your lungs would cover about half a tennis court.',
  ),
  OrganQuestion(
    realm: OrganRealm.human,
    prompt: 'The part that filters waste out of your blood',
    answer: 'Kidneys',
    wrong: ['Liver', 'Spleen', 'Bladder'],
    fact: 'Your kidneys filter all of your blood about 30 times a day.',
  ),
  OrganQuestion(
    realm: OrganRealm.human,
    prompt: 'The part that makes bile and cleans toxins from your blood',
    answer: 'Liver',
    wrong: ['Kidneys', 'Pancreas', 'Stomach'],
    fact: 'The liver is the only organ that can fully regrow itself.',
  ),
  OrganQuestion(
    realm: OrganRealm.human,
    prompt: 'The part that breaks down food with strong acid',
    answer: 'Stomach',
    wrong: ['Liver', 'Pancreas', 'Heart'],
    fact: 'Stomach acid is strong enough to dissolve some metals.',
  ),
  OrganQuestion(
    realm: OrganRealm.human,
    prompt: 'The part that absorbs most of the nutrients from food',
    answer: 'Small intestine',
    wrong: ['Stomach', 'Large intestine', 'Liver'],
    fact: 'Unraveled, the small intestine is about 6 meters long.',
  ),
  OrganQuestion(
    realm: OrganRealm.human,
    prompt: 'The part that reabsorbs water from leftover food',
    answer: 'Large intestine',
    wrong: ['Small intestine', 'Stomach', 'Kidneys'],
    fact: 'The large intestine hosts trillions of helpful bacteria.',
  ),
  OrganQuestion(
    realm: OrganRealm.human,
    prompt: 'The part that thinks, remembers, and controls your body',
    answer: 'Brain',
    wrong: ['Heart', 'Spinal cord', 'Nerves'],
    fact: 'Your brain uses about 20% of your body\'s energy.',
  ),
  OrganQuestion(
    realm: OrganRealm.human,
    prompt: 'The part that makes insulin to control blood sugar',
    answer: 'Pancreas',
    wrong: ['Liver', 'Stomach', 'Gallbladder'],
    fact: 'The pancreas makes both hormones and digestive juices.',
  ),
  OrganQuestion(
    realm: OrganRealm.human,
    prompt: 'The largest organ, which protects everything inside you',
    answer: 'Skin',
    wrong: ['Liver', 'Lungs', 'Heart'],
    fact: 'Your skin completely replaces itself about every month.',
  ),
  OrganQuestion(
    realm: OrganRealm.human,
    prompt: 'The part that stores bile until you eat',
    answer: 'Gallbladder',
    wrong: ['Liver', 'Bladder', 'Pancreas'],
    fact: 'The gallbladder squeezes out bile when you eat fatty food.',
  ),
  OrganQuestion(
    realm: OrganRealm.human,
    prompt: 'The part that filters blood and recycles old red blood cells',
    answer: 'Spleen',
    wrong: ['Liver', 'Kidneys', 'Heart'],
    fact: 'You can live without a spleen — other organs take over its job.',
  ),
  OrganQuestion(
    realm: OrganRealm.human,
    prompt: 'The muscle that pulls down so you can breathe in',
    answer: 'Diaphragm',
    wrong: ['Heart', 'Lungs', 'Ribs'],
    fact: 'A hiccup is a sudden spasm of the diaphragm.',
  ),
  OrganQuestion(
    realm: OrganRealm.human,
    prompt: 'The part that holds urine until you are ready to go',
    answer: 'Bladder',
    wrong: ['Kidneys', 'Gallbladder', 'Stomach'],
    fact: 'A full adult bladder holds about two cups of liquid.',
  ),
  OrganQuestion(
    realm: OrganRealm.human,
    prompt: 'The part that contains your vocal cords for speaking',
    answer: 'Voice box (larynx)',
    wrong: ['Windpipe', 'Tongue', 'Lungs'],
    fact: 'The voice box grows during puberty, which deepens the voice.',
  ),
  OrganQuestion(
    realm: OrganRealm.human,
    prompt: 'The tube that carries air down toward your lungs',
    answer: 'Windpipe (trachea)',
    wrong: ['Esophagus', 'Larynx', 'Aorta'],
    fact: 'Rings of cartilage keep the windpipe from collapsing shut.',
  ),

  // ---- PLANT / POTATO ORGANS ----
  OrganQuestion(
    realm: OrganRealm.plant,
    prompt: 'The part that soaks up water and minerals from the soil',
    answer: 'Roots',
    wrong: ['Leaves', 'Stem', 'Flower'],
    fact: 'A single rye plant can grow over 600 km of roots in a season.',
  ),
  OrganQuestion(
    realm: OrganRealm.plant,
    prompt: 'The part that captures sunlight to make food',
    answer: 'Leaves',
    wrong: ['Roots', 'Stem', 'Tuber'],
    fact: 'Leaves turn sunlight, water, and air into sugar — photosynthesis.',
  ),
  OrganQuestion(
    realm: OrganRealm.plant,
    prompt: 'The part that carries water and sugar between roots and leaves',
    answer: 'Stem',
    wrong: ['Root', 'Leaf', 'Flower'],
    fact: 'Surprise: a potato is a swollen underground stem, not a root.',
  ),
  OrganQuestion(
    realm: OrganRealm.plant,
    prompt: 'The underground part that stores starch — the potato itself',
    answer: 'Tuber',
    wrong: ['Root', 'Seed', 'Fruit'],
    fact: 'A tuber is a thickened stem tip packed with starch.',
  ),
  OrganQuestion(
    realm: OrganRealm.plant,
    prompt: 'The part that attracts pollinators and makes seeds',
    answer: 'Flower',
    wrong: ['Leaf', 'Root', 'Tuber'],
    fact: 'Potato flowers are usually white, pink, or purple.',
  ),
  OrganQuestion(
    realm: OrganRealm.plant,
    prompt: 'The part that protects seeds and helps spread them',
    answer: 'Fruit',
    wrong: ['Flower', 'Leaf', 'Stem'],
    fact: 'A potato plant\'s fruit looks like a tiny green tomato — and is toxic.',
  ),
  OrganQuestion(
    realm: OrganRealm.plant,
    prompt: 'The dormant baby plant waiting inside a protective coat',
    answer: 'Seed',
    wrong: ['Tuber', 'Fruit', 'Root'],
    fact: 'Some seeds can stay alive and dormant for hundreds of years.',
  ),
  OrganQuestion(
    realm: OrganRealm.plant,
    prompt: 'The tissue that carries water UP from the roots',
    answer: 'Xylem',
    wrong: ['Phloem', 'Cortex', 'Epidermis'],
    fact: 'Xylem pipes are made of dead, hollow cells stacked end to end.',
  ),
  OrganQuestion(
    realm: OrganRealm.plant,
    prompt: 'The tissue that carries sugar DOWN from the leaves',
    answer: 'Phloem',
    wrong: ['Xylem', 'Root hairs', 'Stomata'],
    fact: 'Phloem delivers sugar to wherever it is needed — like a growing tuber.',
  ),
  OrganQuestion(
    realm: OrganRealm.plant,
    prompt: 'The tiny pores on leaves that open and close to breathe',
    answer: 'Stomata',
    wrong: ['Roots', 'Xylem', 'Petals'],
    fact: 'A single leaf can have thousands of stomata per square millimeter.',
  ),
  OrganQuestion(
    realm: OrganRealm.plant,
    prompt: 'The "eyes" of a potato, which sprout into new plants',
    answer: 'Buds (eyes)',
    wrong: ['Roots', 'Seeds', 'Flowers'],
    fact: 'Each eye on a potato is a bud that can grow a whole new plant.',
  ),
  OrganQuestion(
    realm: OrganRealm.plant,
    prompt: 'The part of a potato that turns green and toxic in sunlight',
    answer: 'Skin (periderm)',
    wrong: ['Pith', 'Xylem', 'Root'],
    fact: 'Green skin means solanine, a natural toxin — store potatoes in the dark.',
  ),
  OrganQuestion(
    realm: OrganRealm.plant,
    prompt: 'The tiny hairs that increase a root\'s surface for drinking water',
    answer: 'Root hairs',
    wrong: ['Stomata', 'Petals', 'Xylem'],
    fact: 'Root hairs hugely increase the surface area for absorbing water.',
  ),
  OrganQuestion(
    realm: OrganRealm.plant,
    prompt: 'The waxy outer coat of a leaf that prevents water loss',
    answer: 'Cuticle',
    wrong: ['Xylem', 'Pith', 'Root hairs'],
    fact: 'The cuticle is a waxy layer that keeps leaves from drying out.',
  ),
  OrganQuestion(
    realm: OrganRealm.plant,
    prompt: 'The central storage tissue filling the inside of a potato',
    answer: 'Pith',
    wrong: ['Periderm', 'Xylem', 'Stomata'],
    fact: 'The pith of a potato is packed with starch-storing cells.',
  ),
  OrganQuestion(
    realm: OrganRealm.plant,
    prompt: 'The part of a flower that swells into a fruit after pollination',
    answer: 'Ovary',
    wrong: ['Petal', 'Leaf', 'Root'],
    fact: 'After pollination, a flower\'s ovary grows into the fruit.',
  ),
];
