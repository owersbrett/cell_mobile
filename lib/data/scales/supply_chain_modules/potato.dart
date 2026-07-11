import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Supply Chain → "A Potato's Journey" (moduleId: 'supplyChain_potato').
/// The potato-lens module: follow ONE tuber from certified seed to the fry on
/// your plate, treated as a real, multi-stage supply chain. Field-to-fork,
/// with the cold chain and food waste that ride along the whole way.
const List<BioEntity> supplyChainPotatoEntities = <BioEntity>[
  BioEntity(
    id: 'supplychain_potato_seed',
    scale: BioScale.supplyChain,
    position: 0,
    name: 'Sourcing the Seed Potato',
    title: 'The chain starts before the farm',
    moduleId: 'supplyChain_potato',
    shortDescription:
        'Every fry begins with a certified, disease-tested seed potato — a whole upstream industry most people never see.',
    longDescription:
        'A potato does not start from a packet of botanical seeds. It starts from another potato. Farmers plant "seed potatoes" — small tubers that are clones of the parent — so the crop grows true to type.\n\nBut a tuber can carry viruses and rots invisibly. So a certified-seed industry exists upstream of every farm: specialist growers raise clean stock, inspectors test it, and only disease-free lots get sold as planting seed.',
    relatedIds: ['supplychain_potato_harvest'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'You are about to trace one potato from the ground to your plate. Surprise number one: the journey begins one full step before the farm even plants anything.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'A potato grows from a seed potato, which is itself a potato. If a farmer just replanted their own crop every year, what could quietly go wrong?',
        answer:
            'Diseases accumulate. Viruses and rots pass invisibly from tuber to tuber, so yields quietly collapse over a few generations. Certified seed breaks that cycle by starting each season from tested, clean stock.',
      ),
      LessonSection.table(
        title: 'Seed potato vs. what you eat',
        headers: ['Aspect', 'Seed potato', 'Table/ware potato'],
        rows: [
          ['Purpose', 'Planted to grow a crop', 'Eaten or processed'],
          ['Grown by', 'Certified seed growers', 'Commercial farms'],
          ['Key test', 'Disease-free certification', 'Size & cosmetic grading'],
          ['Is it a seed?', 'No — a clonal tuber', 'No — a clonal tuber'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'A seed potato is a clone. The crop you harvest is genetically the same plant as the tuber you planted — no pollination required.',
      ),
    ],
  ),
  BioEntity(
    id: 'supplychain_potato_harvest',
    scale: BioScale.supplyChain,
    position: 1,
    name: 'Harvest & Grading',
    title: 'Out of the field, sorted by the numbers',
    moduleId: 'supplyChain_potato',
    shortDescription:
        'Machines lift tubers from the soil, then graders sort them by size and quality — and a large share never makes the cut.',
    longDescription:
        'At harvest, diggers lift the tubers, gently separate them from soil and stones, and move them to grading lines. There they get sorted by size, shape, and surface quality.\n\nGrading decides destiny: big, clean, uniform potatoes head to the fresh aisle or the fry line; oddly shaped or blemished ones get diverted to processing, animal feed, or waste. A large share of a field can be rejected on looks alone.',
    relatedIds: ['supplychain_potato_seed', 'supplychain_potato_storage'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'The moment a potato leaves the ground, it gets judged. Not on taste — on shape, size, and whether it is pretty enough for a shelf.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'A perfectly delicious potato is knobbly and slightly green-tinged on one side. Where is it likely to end up — and why not the grocery shelf?',
        answer:
            'Probably processing (fries/chips, where it gets cut up anyway), feed, or waste. Fresh-aisle grading rewards uniform size and clean skin, so cosmetic "defects" are rejected even when the potato is fine to eat.',
      ),
      LessonSection.table(
        title: 'Where a graded lot goes',
        headers: ['Grade', 'Typical destination'],
        rows: [
          ['Large, uniform, clean', 'Fresh retail or fry processing'],
          ['Small or off-shape', 'Processing, seed, or feed'],
          ['Blemished / greened', 'Feed or waste'],
          ['Damaged / rotten', 'Waste'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'Grading is the first big waste point in the chain — a meaningful share of a harvest can be culled for cosmetic reasons before anyone tastes it.',
      ),
    ],
  ),
  BioEntity(
    id: 'supplychain_potato_storage',
    scale: BioScale.supplyChain,
    position: 2,
    name: 'Storage & the Cold Chain',
    title: 'Months in the dark — but NOT in your fridge',
    moduleId: 'supplyChain_potato',
    shortDescription:
        'Potatoes are cured, then held for months in cool, humid, dark storage — and that is exactly why a home fridge ruins them.',
    longDescription:
        'Potatoes are harvested in a short window but eaten all year, so they are stored for months. First they are "cured" for a couple of weeks so the skin thickens and small wounds heal. Then they rest in climate-controlled stores: cool (roughly 4–10°C), high humidity, and dark to stop sprouting and greening.\n\nGo colder than that — like a home fridge — and the potato panics. "Cold-sweetening" converts starch into sugar, which browns badly and can raise acrylamide when fried. Cool, not cold, is the rule.',
    relatedIds: ['supplychain_potato_harvest', 'supplychain_potato_processing'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Your potato might sit in storage for half a year before you meet it. The people running that store are careful about one thing above all: keep it cool, but never truly cold.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Why do storage experts warn against keeping potatoes in a household fridge, even though the fridge keeps most food fresher?',
        answer:
            'Fridge temperatures trigger "cold-sweetening": the potato converts starch to sugar. Those sugars brown too fast and can raise acrylamide when the potato is fried or roasted. Potatoes want cool (~4–10°C), dark, and humid — not fridge-cold.',
      ),
      LessonSection.table(
        title: 'Storage conditions that keep a potato happy',
        headers: ['Condition', 'Target', 'Why'],
        rows: [
          ['Temperature', '~4–10°C (cool, not fridge-cold)', 'Slows sprouting; avoids cold-sweetening'],
          ['Humidity', 'High', 'Stops shriveling / water loss'],
          ['Light', 'Dark', 'Prevents greening (bitter, mildly toxic)'],
          ['Curing', '~1–2 weeks first', 'Heals skin so tubers keep longer'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'Cold-sweetening is a chemistry lesson hiding in your kitchen: too-cold storage turns starch into sugar, which is why fridge potatoes fry up dark and bitter.',
      ),
    ],
  ),
  BioEntity(
    id: 'supplychain_potato_processing',
    scale: BioScale.supplyChain,
    position: 3,
    name: 'Processing',
    title: 'Wash, cut, blanch, freeze — the fry factory',
    moduleId: 'supplyChain_potato',
    shortDescription:
        'A fry factory washes, peels, cuts, blanches, par-fries, and freezes potatoes into the shapes you recognize — at enormous scale.',
    longDescription:
        'To become a frozen fry, a potato runs a gauntlet. It is washed, peeled, and cut into strips (often with high-pressure water knives). Then blanched in hot water to set texture and color, par-fried in oil so it crisps later, cooled, and flash-frozen.\n\nThe result is a stable, uniform product built to survive shipping and finish cooking anywhere. Peels, trimmings, and starchy runoff are captured for feed, starch, or energy — so even the offcuts have a downstream life.',
    relatedIds: ['supplychain_potato_storage', 'supplychain_potato_distribution'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'The fry did not fall from a tree fry-shaped. It went through a factory line engineered so that a strip of potato can be frozen in one country and finished crisp in another.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Frozen fries are "par-fried" — fried once at the factory and then frozen raw-looking. Why fry them before you ever get them?',
        answer:
            'Par-frying pre-sets a crisp outer layer and seals the strip, so the frozen fry finishes fast and evenly when you cook it — golden outside, fluffy inside. Blanching before that sets color and texture so they do not turn gray.',
      ),
      LessonSection.table(
        title: 'The processing line, step by step',
        headers: ['Step', 'What it does'],
        rows: [
          ['Wash & peel', 'Removes soil and skin'],
          ['Cut', 'Water knives slice uniform strips'],
          ['Blanch', 'Hot water sets color & texture'],
          ['Par-fry', 'Pre-crisps and seals the strip'],
          ['Freeze', 'Flash-frozen for the cold chain'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'Almost nothing is wasted here: peels and trimmings become animal feed, starch, or biogas — the offcuts feed a second supply chain.',
      ),
    ],
  ),
  BioEntity(
    id: 'supplychain_potato_distribution',
    scale: BioScale.supplyChain,
    position: 4,
    name: 'Distribution & Retail',
    title: 'Kept frozen across the whole planet',
    moduleId: 'supplyChain_potato',
    shortDescription:
        'Frozen fries ride refrigerated trucks, ships, and warehouses worldwide — one unbroken cold chain from factory to freezer aisle.',
    longDescription:
        'A frozen fry is only as good as the coldest link that fails it. Distribution keeps the product frozen every step: refrigerated warehouses, reefer trucks, and refrigerated shipping containers move it across oceans to grocery freezers and restaurant kitchens.\n\nBreak the cold chain even briefly and the fries partly thaw, refreeze into ice crystals, and cook up soggy. That is why the "cold chain" is treated as a single continuous promise, not a series of separate cold rooms.',
    relatedIds: ['supplychain_potato_processing', 'supplychain_potato_plate'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'The fry that lands on your plate may have crossed an ocean — and it stayed below freezing the entire way. That unbroken cold is a supply-chain miracle we barely notice.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If a truck of frozen fries sits warm on a loading dock for an hour, then goes back in the freezer, why can the fries be ruined even though they are frozen again?',
        answer:
            'Partial thawing lets water inside the fry migrate; refreezing forms large ice crystals that rupture the structure. They cook up soggy and mushy. A broken cold chain cannot be "un-broken" by re-freezing.',
      ),
      LessonSection.table(
        title: 'Links in the cold chain',
        headers: ['Link', 'How it stays cold'],
        rows: [
          ['Factory store', 'Frozen warehouse'],
          ['Long haul', 'Reefer trucks & shipping containers'],
          ['Regional depot', 'Cold distribution center'],
          ['Store / restaurant', 'Freezer aisle & kitchen freezer'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'The cold chain is one promise, not many: a single warm gap anywhere between factory and freezer aisle can undo everything upstream.',
      ),
    ],
  ),
  BioEntity(
    id: 'supplychain_potato_plate',
    scale: BioScale.supplyChain,
    position: 5,
    name: 'The Fry on Your Plate',
    title: 'The last mile — and the waste along the way',
    moduleId: 'supplyChain_potato',
    shortDescription:
        'The final step is a home or restaurant kitchen — but a large share of every potato crop never reaches a plate at all.',
    longDescription:
        'The last mile is the smallest: someone drops the fries in oil or an oven and eats them. This is where months of seed selection, farming, storage, processing, and shipping finally pay off in about ten minutes of cooking.\n\nBut the plate is also where the honest tally lands. Add up cosmetic culls, storage spoilage, cold-chain losses, and plate scraps, and a large share of the potatoes grown never gets eaten by people. The journey is long, and it leaks the whole way.',
    relatedIds: ['supplychain_potato_distribution'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'You are the last stop. Everything before this — the certified seed, the grading, the six months in storage, the ocean crossing — exists so that this final ten-minute cook goes right.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Where does the biggest chunk of food waste happen along a potato\'s journey — at your plate, or somewhere upstream?',
        answer:
            'It is spread out, not just at the plate. Cosmetic culling at grading, spoilage in storage, cold-chain losses, and plate scraps all stack up — so across the whole chain, a large share of the crop never feeds a person.',
      ),
      LessonSection.table(
        title: 'Where potatoes are lost along the chain',
        headers: ['Stage', 'Loss'],
        rows: [
          ['Grading', 'Cosmetic culls (odd shape/size)'],
          ['Storage', 'Spoilage, sprouting, rot'],
          ['Cold chain', 'Broken-freezer & handling losses'],
          ['Plate', 'Uneaten scraps & leftovers'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'Field to fork is a long chain that leaks: across all stages, a large share of the potatoes grown never reaches a human mouth.',
      ),
    ],
  ),
];
