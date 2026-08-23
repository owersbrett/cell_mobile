/// The Ops — the antagonist crew that works the boards against the players.
///
/// Two MISCHIEF ops roam every map, doing the dirty work the cards trigger
/// (stealing purses/coins/items, swapping positions). Two BOSSES haunt specific
/// maps: the Boiling Vat (Down the Hole + Into the Void) and the Cheese Grater
/// (Into the Void + Through the Aether).
class Op {
  final String id;
  final String name;
  final String asset; // sprite in assets/characters/
  final String blurb; // what it does, in-world
  final bool isBoss;

  const Op({
    required this.id,
    required this.name,
    required this.asset,
    required this.blurb,
    this.isBoss = false,
  });
}

const Op kPeeler = Op(
  id: 'peeler',
  name: 'The Peeler',
  asset: 'assets/characters/peeler.png',
  blurb: 'Strips you down — skims coins and lifts items off anyone careless.',
);

const Op kMasher = Op(
  id: 'masher',
  name: 'The Masher',
  asset: 'assets/characters/masher.png',
  blurb: 'Mashes it all together — swaps purses, items, and whole positions.',
);

const Op kBoilingVat = Op(
  id: 'boiling_vat',
  name: 'The Boiling Vat',
  asset: 'assets/characters/boiling-vat.png',
  blurb: 'Boss of the descent — the deeper you go, the hotter the water.',
  isBoss: true,
);

const Op kCheeseGrater = Op(
  id: 'cheese_grater',
  name: 'The Cheese Grater',
  asset: 'assets/characters/cheese-grater.png',
  blurb: 'Boss of the ascent — shreds the bold a little finer each pass.',
  isBoss: true,
);

/// The mischief crew that works EVERY board (their havoc rides the cards).
const List<Op> kMischiefOps = [kPeeler, kMasher];

/// Which op is behind a given card's mischief, for narration + flavor. Steals
/// → the Peeler; swaps/scrambles → the Masher. Null = no op (cosmic/gnome/etc).
Op? opForCard(String cardId) {
  switch (cardId) {
    case 'diamond_heist': // steal diamonds from the leader
    case 'inventory_raid': // take a rival's item
    case 'aether_tax': // skim diamonds off everyone
    case 'black_hole': // strip everyone's diamonds
    case 'toll_booth': // skims your diamonds
      return kPeeler;
    case 'void_swap': // swap entire diamond stash
    case 'mirror': // set your diamonds to the leader's
    case 'tithe': // shuffle diamonds from rivals to you
    case 'even_split': // swap with the player behind
      return kMasher;
    default:
      return null;
  }
}
