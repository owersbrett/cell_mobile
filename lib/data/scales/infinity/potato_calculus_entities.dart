import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Infinity → "Infinity in a Potato" module (the potato lens on calculus).
/// Entities carry moduleId: 'infinities_potato'. (Authored by module agent.)
///
/// The whole point: teach calculus THROUGH the potato. Six real ideas —
/// integration, related rates, optimization, surface-of-revolution, limits,
/// and infinite series — each made concrete on a single humble tuber.
const List<BioEntity> infinityPotatoEntities = <BioEntity>[
  // ─────────────────────────────────────────────────────────────────────────
  // 0. Volume of a Potato — integration by slices / solids of revolution
  // ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'potato_calc_volume',
    scale: BioScale.infinities,
    position: 0,
    name: 'Volume of a Potato',
    title: 'How much potato is in the potato?',
    moduleId: 'infinities_potato',
    shortDescription:
        'A potato has no formula — so we slice it into pennies and add the slices up. That is integration.',
    longDescription:
        'A sphere has a volume formula. A cube has one. A potato has nothing — it is a bumpy blob no equation ever describes. So how do you find its volume? You cheat the honest way: cut it into very thin slices, treat each slice as a flat disc, add up the discs. Make the slices thinner and thinner and the answer stops wobbling. That limit — the sum of infinitely many infinitely thin slices — is the integral ∫A(x)dx.\n\nIf a slice at position x has cross-sectional area A(x) and thickness dx, its volume is A(x)·dx. The whole potato is the sum of all of them from one end to the other: V = ∫A(x)dx. If the potato is roughly a solid of revolution (spin a profile curve f(x) around its long axis), each slice is a disc of radius f(x), so A(x) = π[f(x)]² and V = ∫π[f(x)]²dx.',
    relatedIds: ['potato_calc_growth', 'potato_calc_peel'],
    sections: [
      LessonSection.fact(
        title: 'The one idea',
        body:
            'Volume = ∫A(x)dx — add up infinitely many pancake-thin slices. No potato is too lumpy for this.',
      ),
      LessonSection.paragraph(
        title: 'Spin a potato out of a curve',
        body:
            'Model a small potato as the curve f(x) = √(9 − x²) spun around the x-axis from x = −3 to x = 3 (a 3 cm-radius ball, close enough to a round russet). Each slice is a disc of radius f(x), area π[f(x)]² = π(9 − x²). Integrate: V = ∫₋₃³ π(9 − x²)dx = π[9x − x³/3] from −3 to 3 = π[(27 − 9) − (−27 + 9)] = 36π ≈ 113 cm³. At ~1 g/cm³ that is a 113 g potato — a real small one.',
      ),
      LessonSection.table(
        title: 'Thinner slices → truer answer',
        headers: ['Slices', 'Slice thickness', 'Estimated volume', 'Error'],
        rows: [
          ['2', '3.0 cm', '~85 cm³', 'huge'],
          ['6', '1.0 cm', '~108 cm³', 'closer'],
          ['60', '0.1 cm', '~112.9 cm³', 'tiny'],
          ['∞ (the integral)', '0', '36π ≈ 113.10 cm³', 'exact'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Commit first',
        question:
            'You double the potato\'s radius (r: 3 cm → 6 cm) but keep the same shape. Does the volume double? Guess before you peek.',
        answer:
            'No — it grows by 2³ = 8×. Volume scales with the cube of length, so 36π → 288π ≈ 905 cm³. A potato twice as wide is EIGHT potatoes. This cubic scaling is why a slightly bigger seed potato yields a monster.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 1. A Growing Tuber — related rates
  // ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'potato_calc_growth',
    scale: BioScale.infinities,
    position: 1,
    name: 'A Growing Tuber',
    title: 'When one thing swells, everything swells with it',
    moduleId: 'infinities_potato',
    shortDescription:
        'The potato widens a hair a day. How fast is it packing on grams? Related rates links dr/dt to dV/dt.',
    longDescription:
        'Now the potato is alive underground, drinking, and swelling. You can measure how fast its radius grows — say a tenth of a centimetre a day. What you actually care about is how fast its VOLUME grows, because volume is (roughly) mass, and mass is dinner. Related rates is the calculus of "when one quantity changes, how fast does a connected quantity change?"\n\nStart from the volume law V = 4/3πr³. Differentiate both sides with respect to time t. The chain rule spits out dV/dt = 4πr²·dr/dt. Notice 4πr² is exactly the surface area of the potato — so the growth of volume equals the skin area times how fast the skin pushes outward. The bigger the potato already is, the more grams a single day of the same radial growth adds.',
    relatedIds: ['potato_calc_volume', 'potato_calc_surface'],
    sections: [
      LessonSection.fact(
        title: 'The master link',
        body:
            'dV/dt = 4πr²·dr/dt. (Surface area) × (how fast the skin moves out) = grams per day.',
      ),
      LessonSection.paragraph(
        title: 'Worked day in the dirt',
        body:
            'A tuber is r = 3 cm and swelling at dr/dt = 0.1 cm/day. Then dV/dt = 4π(3)²(0.1) = 4π·9·0.1 = 3.6π ≈ 11.3 cm³/day — about 11 grams a day. Two weeks of that is ~158 g added: the potato roughly doubles. Same 0.1 cm/day on a bigger r = 5 cm potato gives 4π(25)(0.1) = 10π ≈ 31.4 g/day — nearly triple the daily gain, from the identical radial speed.',
      ),
      LessonSection.table(
        title: 'Same dr/dt, very different dV/dt',
        headers: ['Radius r', 'dr/dt', 'Surface area 4πr²', 'dV/dt'],
        rows: [
          ['2 cm', '0.1 cm/day', '≈ 50.3 cm²', '≈ 5.0 g/day'],
          ['3 cm', '0.1 cm/day', '≈ 113 cm²', '≈ 11.3 g/day'],
          ['5 cm', '0.1 cm/day', '≈ 314 cm²', '≈ 31.4 g/day'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Commit first',
        question:
            'You want the potato to gain a steady 11.3 g every day. As it gets bigger, must you keep dr/dt at 0.1 cm/day — or can the skin slow down?',
        answer:
            'The skin can slow down. dV/dt = 4πr²·dr/dt, so to hold dV/dt fixed while r grows you need dr/dt to SHRINK like 1/r². A big potato barely has to widen to still be piling on the same grams — its huge surface does the work.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 2. The Perfect Fry Cut — optimization
  // ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'potato_calc_fry',
    scale: BioScale.infinities,
    position: 2,
    name: 'The Perfect Fry Cut',
    title: 'Calculus decides how crispy your fry is',
    moduleId: 'infinities_potato',
    shortDescription:
        'Thin fries = crispy but oily; fat fries = fluffy but soggy. The best cut is a calculus optimum.',
    longDescription:
        'Cut a potato into fries and you have made a decision with a right answer. A fry crisps at its surface and stays fluffy in its core; it also drinks oil through its surface. So surface-to-volume ratio is destiny: thin fries are all surface (max crunch, max oil), fat wedges are all core (fluffy, greaseless, but barely crisp). Optimization is the calculus of finding the single best value — you write the thing you care about as a function, then set its derivative to zero.\n\nTake a square-cross-section fry of side s and fixed length L = 8 cm. Its volume is V = s²L and its "crisping surface" (the four long sides) is A = 4sL. The oil uptake per gram of potato tracks A/V = 4sL / (s²L) = 4/s. That function only ever decreases as s grows — no interior maximum — which itself is the lesson: to cut oiliness you must cut thickness only so far before the fry stops being crispy at all. Real fry optimization instead FIXES a target (a set surface-to-volume ratio, e.g. 4/s = a chosen value) and solves for s.',
    relatedIds: ['potato_calc_surface', 'potato_calc_volume'],
    sections: [
      LessonSection.fact(
        title: 'The crispy law',
        body:
            'Crispiness AND oiliness both ride on surface-to-volume A/V. For a square fry of side s: A/V = 4/s. Thinner = crispier = oilier.',
      ),
      LessonSection.paragraph(
        title: 'The honest optimization: a box of fries',
        body:
            'Suppose you must fry a fixed 120 g potato and you want the LEAST oil for a required crunch. You have a real max/min problem when a constraint fights the objective. Classic version: from a fixed potato mass, maximize total crisp surface across N identical fries. Cutting into more, thinner fries always raises surface — but each halving of thickness doubles oil per gram (A/V = 4/s doubles when s halves). The optimum is where added crunch stops being worth the added grease: set d(net-tastiness)/ds = 0. That derivative-equals-zero is the whole move.',
      ),
      LessonSection.table(
        title: 'Fry side s vs. what you get (L = 8 cm)',
        headers: ['Side s', 'Volume s²L', 'Surface 4sL', 'A/V = 4/s', 'Verdict'],
        rows: [
          ['0.5 cm', '2.0 cm³', '16 cm²', '8.0 /cm', 'shoestring: crisp, oily'],
          ['1.0 cm', '8.0 cm³', '32 cm²', '4.0 /cm', 'classic fry'],
          ['2.0 cm', '32 cm³', '64 cm²', '2.0 /cm', 'steak fry: fluffy, dry'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Commit first',
        question:
            'To minimize OIL alone (ignore crunch) for a fixed potato mass, do you want few fat fries or many thin ones?',
        answer:
            'Few fat fries. Oil rides on surface, and A/V = 4/s falls as s grows — the fattest cut (a single baked potato, s huge) has the least surface per gram and drinks almost no oil. That is literally why a baked potato is the low-oil option: minimum surface-to-volume.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Surface Area & the Skin — surface of revolution
  // ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'potato_calc_surface',
    scale: BioScale.infinities,
    position: 3,
    name: 'Surface Area & the Skin',
    title: 'The skin is an integral wrapped around dinner',
    moduleId: 'infinities_potato',
    shortDescription:
        'The peel is a surface-of-revolution integral — and its ratio to the flesh decides how a potato cooks.',
    longDescription:
        'The skin is not a formula either — it is a wrinkled sheet stretched over a lumpy solid. To find its area you spin the profile curve f(x) around the axis and sum up thin ribbons. Each ribbon is a slanted band of circumference 2πf(x) and slant width √(1 + [f′(x)]²)dx (slanted, because the surface tilts as it goes). The surface-of-revolution integral adds them all: S = ∫2πf(x)√(1 + [f′(x)]²)dx.\n\nWhy care? Because cooking happens at the skin. Heat, browning, and moisture loss all scale with surface area, while the fluffy payoff scales with volume. Skin-to-flesh ratio (S/V) is the cooking dial: a small new potato is nearly all skin and cooks fast and crusty; a giant baker is nearly all flesh and needs an hour to reach its middle. Same physics as the fry — surface cooks, volume waits.',
    relatedIds: ['potato_calc_fry', 'potato_calc_growth'],
    sections: [
      LessonSection.fact(
        title: 'The skin integral',
        body:
            'S = ∫2πf(x)√(1 + [f′(x)]²)dx — spin the profile, sum the slanted ribbons. That is the whole peel.',
      ),
      LessonSection.paragraph(
        title: 'A round potato, checked against the known answer',
        body:
            'For our f(x) = √(9 − x²) ball, the surface-of-revolution integral must give the sphere\'s 4πr². Here f′(x) = −x/√(9 − x²), and 1 + [f′(x)]² = 9/(9 − x²), so the integrand 2πf(x)√(that) = 2π√(9 − x²)·3/√(9 − x²) = 6π — a constant. Then S = ∫₋₃³ 6π dx = 6π·6 = 36π ≈ 113 cm². And 4πr² = 4π·9 = 36π. ✓ The lumpy machine reproduces the textbook sphere.',
      ),
      LessonSection.table(
        title: 'Skin-to-flesh ratio S/V sets the cook (spheres)',
        headers: ['Potato', 'Radius', 'Surface 4πr²', 'Volume 4/3πr³', 'S/V'],
        rows: [
          ['New potato', '2 cm', '≈ 50 cm²', '≈ 34 cm³', '1.5 /cm'],
          ['Medium', '3 cm', '≈ 113 cm²', '≈ 113 cm³', '1.0 /cm'],
          ['Big baker', '5 cm', '≈ 314 cm²', '≈ 524 cm³', '0.6 /cm'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Commit first',
        question:
            'Two potatoes have the same mass, but one is a smooth ball and one is knobbly with deep eyes. Which has more skin — and cooks crustier?',
        answer:
            'The knobbly one. The √(1 + [f′(x)]²) factor blows up wherever the surface is steep, so every bump and eye adds ribbon area. Same volume, more surface, more browning — the wrinkly potato is the crispier bake. A perfect sphere is the LEAST-skin shape for a given volume.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Peeling to the Limit — limits / infinitesimals
  // ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'potato_calc_peel',
    scale: BioScale.infinities,
    position: 4,
    name: 'Peeling to the Limit',
    title: 'How thin can the peel get before it is nothing?',
    moduleId: 'infinities_potato',
    shortDescription:
        'Peel thinner, thinner, thinner. In the limit the peel is a surface with zero thickness — the idea of dx.',
    longDescription:
        'Take the thinnest peel you can — a millimetre, then a hair, then thinner. Each peel is a real slab of potato with a real volume: (surface area) × (thickness). As the thickness shrinks toward zero, the peel\'s volume shrinks toward zero too — yet its area does not vanish. Push it all the way: an infinitely thin peel has zero volume but a perfectly real surface. That impossible-sounding object is exactly what dx means in every integral you have met so far.\n\nThis is the Riemann-sum picture from the inside. Slicing the potato (entity 1) and peeling the potato are the same act at right angles: both approximate a smooth whole by a stack of thin pieces, then take the limit as the pieces go infinitely thin. The limit is not "the peel eventually becomes nothing" — it is "the SUM of infinitely many infinitely thin peels reconstructs the whole potato exactly." Infinity and zero shake hands, and calculus is the handshake.',
    relatedIds: ['potato_calc_volume', 'potato_calc_infinity'],
    sections: [
      LessonSection.fact(
        title: 'The infinitesimal',
        body:
            'One peel\'s volume = area × thickness. Let thickness → 0: volume → 0, area survives. That survivor is dx.',
      ),
      LessonSection.paragraph(
        title: 'Onion-skin the whole potato',
        body:
            'Peel a 113 cm³ / 36π sphere in concentric shells instead of end-slices. A shell at radius r with thickness Δr has volume ≈ (surface)×(thickness) = 4πr²·Δr. Sum every shell from r = 0 out to r = 3 and, as Δr → 0, the sum becomes ∫₀³ 4πr² dr = 4π[r³/3]₀³ = 4π·9 = 36π ≈ 113 cm³ — the whole potato, rebuilt from infinitely many infinitely thin peels. Notice the shell area 4πr² is the very dV/dt term from "A Growing Tuber": growing outward and peeling inward are the same integral run in reverse.',
      ),
      LessonSection.table(
        title: 'Peel thickness → 0',
        headers: ['Peel thickness', 'One peel\'s volume (at r = 3)', 'Peels to cover the potato'],
        rows: [
          ['1 mm', '≈ 11.3 cm³', 'a few dozen'],
          ['0.1 mm', '≈ 1.13 cm³', 'hundreds'],
          ['0.001 mm', '≈ 0.0113 cm³', 'tens of thousands'],
          ['→ 0 (dr)', '→ 0', '→ ∞ (the integral)'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Commit first',
        question:
            'If each peel has zero volume in the limit, and you have infinitely many of them, how can they add up to a real 113 cm³ instead of 0 or ∞?',
        answer:
            'Because 0 × ∞ is not automatically anything — it depends on HOW fast each goes. Peel volume → 0 like Δr, and the count → ∞ like 1/Δr; their product stays finite. That controlled 0 × ∞ balance is the definite integral. Calculus is precisely the machine that makes "infinitely many infinitely small things" add to a definite number.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // 5. How Many Potatoes Feed Infinity? — infinite series / convergence
  // ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'potato_calc_infinity',
    scale: BioScale.infinities,
    position: 5,
    name: 'How Many Potatoes Feed Infinity?',
    title: 'A harvest of endless potatoes that still fits in a sack',
    moduleId: 'infinities_potato',
    shortDescription:
        'Add infinitely many potatoes and sometimes you get a finite pile — that is convergence.',
    longDescription:
        'End of the module, end of the season: the harvest. Suppose each day\'s crop is exactly half the day before — 1 sack, then 1/2, then 1/4, then 1/8, forever. You are adding infinitely many nonzero harvests. Common sense screams the total must be infinite. It is not: 1 + 1/2 + 1/4 + 1/8 + ⋯ = 2. Two sacks, ever, no matter how many days pass. That is a convergent geometric series, and it is the strangest true thing in this whole potato.\n\nA geometric series Σarⁿ = a + ar + ar² + ⋯ converges to a/(1 − r) whenever |r| < 1, and diverges to infinity otherwise. Our harvest has a = 1, r = 1/2, so the total is 1/(1 − 1/2) = 2. Change the rule so each day\'s crop shrinks only like 1, 1/2, 1/3, 1/4, ⋯ (the harmonic series) and the total blows up to infinity even though each harvest gets tiny. Whether infinity fills a sack or overflows the barn comes down to how fast the potatoes shrink.',
    relatedIds: ['potato_calc_peel', 'potato_calc_volume'],
    sections: [
      LessonSection.fact(
        title: 'The landmark sum',
        body:
            '1 + 1/2 + 1/4 + 1/8 + ⋯ = 2. Infinitely many sacks of potatoes, total = exactly two sacks.',
      ),
      LessonSection.paragraph(
        title: 'The geometric harvest, in general',
        body:
            'If every harvest is the fraction r of the last one, the lifetime total is Σₙ₌₀^∞ arⁿ = a/(1 − r), valid only when |r| < 1. Halving crop (r = 1/2, a = 1): total 1/(1 − 1/2) = 2. Tripling crop (r = 3): |r| > 1, the sum diverges — the barn overflows. The knife-edge is r = 1: crop never shrinks, the pile grows without bound. Convergence is a race between "how many terms" (→ ∞) and "how small each term" (→ 0), and the shrink has to win decisively.',
      ),
      LessonSection.table(
        title: 'Does the endless harvest fit in a sack?',
        headers: ['Daily rule', 'The series', 'Verdict', 'Total'],
        rows: [
          ['Half of yesterday', '1 + ½ + ¼ + ⅛ + ⋯', 'converges', '2'],
          ['One-tenth of yesterday', '1 + 0.1 + 0.01 + ⋯', 'converges', '1.111… = 10/9'],
          ['Harmonic (1, ½, ⅓, ¼, …)', '1 + ½ + ⅓ + ¼ + ⋯', 'DIVERGES', '∞'],
          ['Double every day', '1 + 2 + 4 + 8 + ⋯', 'diverges', '∞'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Commit first',
        question:
            'Harvest shrinks fast: 1, ½, ⅓, ¼, … each day. Every term is tiny and heading to zero. Does the total harvest stay finite?',
        answer:
            'No — it diverges to ∞. The harmonic series is the famous trap: terms shrink, but not FAST enough. Group them (½), (⅓+¼ > ½), (⅕+⋯+⅛ > ½)… you can always scrape together another ½, forever. Terms going to zero is necessary but NOT sufficient for convergence — the whole punchline of infinite series, taught by a potato.',
      ),
    ],
  ),
];
