// Organism facts — the "fact bombardment" bank for the Harvest game (Organism scale).
//
// On each harvest, fact cards spawn, float upward, and wiggle off on their own (they do NOT need to
// be tapped). Tapping one closes it AND pays out coins — the incentive to swat them. Deliberately
// pushy: a clear directive to clear them so you can get back to harvesting. A coin power-up can
// auto-close them. All Canvas/widget-rendered — no assets.

const List<String> kOrganismFacts = [
  // The headliner — the potato's double identity.
  'A potato is an ORGAN of the plant — but plant one with an eye and it becomes a whole new ORGANISM.',
  'The potato plant and the potato tuber are both organisms — one attached, one able to go solo.',
  'Every "eye" on a potato is a bud that can grow into a complete new plant.',
  'A potato grown from a tuber is a clone — genetically identical to its parent.',
  'A single potato plant can grow dozens of tubers underground.',

  // What an organism is.
  'An organism is any single living thing that carries out all life processes on its own.',
  'Some organisms are a single cell; others, like a blue whale, are trillions of cells.',
  'An organism that makes its own food, like a plant, is called an autotroph.',
  'Yeast — the stuff in bread and beer — is a living, single-celled organism.',

  // The crops on this scale.
  'Corn was domesticated about 9,000 years ago in Mexico from a wild grass called teosinte.',
  'Soybeans team up with soil bacteria to pull nitrogen straight out of the air.',
  'Wheat feeds more people than any other crop on Earth.',
  'Rice feeds about half the world\'s population.',
  'A tomato is botanically a fruit — but a vegetable by kitchen rules.',
  'Legumes like beans and peas leave the soil richer than they found it.',
  'Domestication turned a small, bitter wild potato into a staple that feeds billions.',

  // Wild organism facts (tap-bait).
  'The largest organism on Earth is a honey fungus in Oregon, spanning nearly 10 square kilometers.',
  'Pando, a colony of aspen trees in Utah, is one organism — and thousands of years old.',
  'Tardigrades can survive being frozen, boiled, dried out, and even the vacuum of space.',
  'Bananas are grown almost entirely from clones — which is why one disease could wipe them out.',
];
