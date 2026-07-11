import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Infinity → "Calculus I — Limits & Derivatives" module.
/// Entities carry moduleId: 'infinities_calc1'. (Authored by module agent.)
const List<BioEntity> infinityCalc1Entities = <BioEntity>[
  BioEntity(
    id: 'calc1_the_limit',
    scale: BioScale.infinities,
    position: 0,
    name: 'The Limit',
    title: 'Approaching Without Arriving',
    moduleId: 'infinities_calc1',
    shortDescription:
        'The single idea that tames infinity: where a function is heading, even when it never quite gets there.',
    longDescription:
        'A limit answers a sneaky question — not "what is the function AT this point?" but "what value is it closing in on as we creep arbitrarily near?" That gap between heading-toward and arriving-at is where all of calculus lives.\n\n'
        'We write lim(x→a) f(x) = L to mean: force x close enough to a, and f(x) is trapped as close to L as you like. The function might not even be defined at a — that is exactly the point. Limits let us reason about the infinitely small and the infinitely close without ever touching them.',
    relatedIds: ['calc1_continuity'],
    sections: [
      LessonSection.fact(
        title: 'The Hook',
        body:
            'ε–δ: for EVERY tolerance ε > 0 you demand, there exists a closeness δ > 0 that guarantees it. That challenge-and-response is the whole engine of calculus.',
      ),
      LessonSection.thinkReveal(
        title: 'The Classic Trap',
        question:
            'f(x) = (x² − 1)/(x − 1). At x = 1 the formula gives 0/0 — undefined. So what is lim(x→1) f(x)?',
        answer:
            '2. Factor the top: (x−1)(x+1)/(x−1) = x + 1 for every x ≠ 1. As x → 1, x + 1 → 2. The function has a hole at x = 1, yet the limit is a clean 2. The value AT the point never mattered.',
      ),
      LessonSection.table(
        title: 'Squeezing In From Both Sides',
        headers: ['x', 'f(x) = (x²−1)/(x−1)'],
        rows: [
          ['0.9', '1.9'],
          ['0.99', '1.99'],
          ['1.01', '2.01'],
          ['1.1', '2.1'],
        ],
      ),
      LessonSection.paragraph(
        title: 'One-Sided Warning',
        body:
            'A limit exists only if the left approach and the right approach agree. lim(x→0) 1/x fails: from the right it rockets to +∞, from the left it plunges to −∞. Different destinations, no limit. Keep that fussiness in mind — because the moment a function has NO holes and NO disagreements, it earns a name: continuous.',
      ),
    ],
  ),
  BioEntity(
    id: 'calc1_continuity',
    scale: BioScale.infinities,
    position: 1,
    name: 'Continuity',
    title: 'Drawing Without Lifting the Pencil',
    moduleId: 'infinities_calc1',
    shortDescription:
        'A function is continuous when nothing surprising happens: the limit and the value finally shake hands.',
    longDescription:
        'Intuitively, continuous means you can draw the graph without lifting your pencil — no jumps, no holes, no spikes to infinity. Formally, f is continuous at a when three things all hold and all agree: f(a) exists, lim(x→a) f(x) exists, and the two are equal.\n\n'
        'Continuity is the promise that the earlier "hole" problem is gone. It is also the ticket into two of calculus\'s most powerful guarantees — and the prerequisite for asking whether a curve has a well-behaved slope at all.',
    relatedIds: ['calc1_the_limit', 'calc1_the_derivative'],
    sections: [
      LessonSection.fact(
        title: 'The Three-Part Test',
        body:
            'Continuous at a ⇔ (1) f(a) is defined, (2) lim(x→a) f(x) exists, (3) lim(x→a) f(x) = f(a). Fail any one and the curve breaks.',
      ),
      LessonSection.table(
        title: 'The Zoo of Discontinuities',
        headers: ['Type', 'What breaks', 'Example at x = 0'],
        rows: [
          ['Removable', 'A single fixable hole', 'sin(x)/x'],
          ['Jump', 'Left ≠ right limit', 'the sign / step function'],
          ['Infinite', 'Value blows up', '1/x²'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The Intermediate Value Theorem',
        question:
            'x³ − x − 1 is continuous. At x = 1 it equals −1; at x = 2 it equals 5. Must it hit 0 somewhere between 1 and 2?',
        answer:
            'Yes. The Intermediate Value Theorem says a continuous function passing from −1 up to 5 must take every value in between, including 0. So a real root is guaranteed on (1, 2) — no formula required, just continuity.',
      ),
      LessonSection.paragraph(
        title: 'Why It Matters Next',
        body:
            'Continuity is necessary for smoothness but not sufficient — a graph can be unbroken yet have a sharp corner (like |x| at 0). To measure how a smooth curve tilts moment to moment, we need something stronger than "no gaps." We need a slope at a single point. Enter the derivative.',
      ),
    ],
  ),
  BioEntity(
    id: 'calc1_the_derivative',
    scale: BioScale.infinities,
    position: 2,
    name: 'The Derivative',
    title: 'The Slope of an Instant',
    moduleId: 'infinities_calc1',
    shortDescription:
        'The slope of a line needs two points — the derivative squeezes those two points into one and measures instantaneous change.',
    longDescription:
        'Average slope is easy: rise over run between two points, Δy/Δx. But how fast is something changing at a single instant, where there is no "run" at all? The derivative answers by taking the average slope over a shrinking interval and letting that interval collapse to zero — a limit.\n\n'
        'f′(x) = lim(h→0) [f(x + h) − f(x)] / h. Geometrically it is the slope of the tangent line; physically it is instantaneous velocity, growth rate, or marginal cost. It is the limit idea cashed out into the most useful tool in mathematics.',
    relatedIds: ['calc1_continuity', 'calc1_rules_of_differentiation'],
    sections: [
      LessonSection.fact(
        title: 'The Definition',
        body:
            'f′(x) = lim(h→0) [f(x+h) − f(x)] / h — the secant slope over a run of h, as h shrinks to nothing. That 0/0 form is defused by the limit.',
      ),
      LessonSection.thinkReveal(
        title: 'Derive One From Scratch',
        question:
            'Use the definition to find f′(x) for f(x) = x². Expand (x + h)² first.',
        answer:
            'f′(x) = 2x. [ (x+h)² − x² ] / h = (x² + 2xh + h² − x²)/h = (2xh + h²)/h = 2x + h. As h → 0, the h vanishes and 2x remains. So the slope of y = x² at x = 3 is exactly 6.',
      ),
      LessonSection.table(
        title: 'Notation, One Idea',
        headers: ['Written', 'Read as', 'Author'],
        rows: [
          ['f′(x)', 'f-prime of x', 'Lagrange'],
          ['dy/dx', 'dee-y dee-x', 'Leibniz'],
          ['ẏ', 'y-dot (time rate)', 'Newton'],
          ['Df', 'D of f', 'operator form'],
        ],
      ),
      LessonSection.paragraph(
        title: 'The Catch That Sets Up Continuity',
        body:
            'Differentiable ⇒ continuous, but never the reverse. |x| is continuous everywhere yet has NO derivative at 0 — the tangent slope would have to be both −1 and +1 at the corner. Smoothness is a strictly higher bar than unbrokenness. Computing f′ from the limit every time is exhausting, though — so next we bottle the pattern into rules.',
      ),
    ],
  ),
  BioEntity(
    id: 'calc1_rules_of_differentiation',
    scale: BioScale.infinities,
    position: 3,
    name: 'Rules of Differentiation',
    title: 'The Shortcuts That Retire the Limit',
    moduleId: 'infinities_calc1',
    shortDescription:
        'Power, product, quotient, and chain — four rules that turn the tedious limit definition into fast, mechanical algebra.',
    longDescription:
        'You could compute every derivative from lim(h→0), but nobody does. Mathematicians proved the limit once for whole families of functions and packaged the results as rules. Master four of them and you can differentiate almost anything you meet in a first course.\n\n'
        'The star is the chain rule — the one for functions nested inside functions — because the real world is layered: rates that depend on rates that depend on rates. Get these four fluent and calculus stops being scary and starts being fast.',
    relatedIds: ['calc1_the_derivative', 'calc1_related_rates'],
    sections: [
      LessonSection.fact(
        title: 'The Power Rule',
        body:
            'd/dx [xⁿ] = n·xⁿ⁻¹. Bring the exponent down front, drop it by one. d/dx[x⁵] = 5x⁴. This one alone covers most of calculus homework.',
      ),
      LessonSection.table(
        title: 'The Four Workhorses',
        headers: ['Rule', 'Formula'],
        rows: [
          ['Power', 'd/dx[xⁿ] = n·xⁿ⁻¹'],
          ['Product', '(f·g)′ = f′g + f·g′'],
          ['Quotient', '(f/g)′ = (f′g − f·g′) / g²'],
          ['Chain', 'd/dx f(g(x)) = f′(g(x))·g′(x)'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Chain Rule Under Pressure',
        question:
            'Differentiate y = (3x² + 1)⁴. Treat the inside as one lump, then multiply by the inside\'s derivative.',
        answer:
            'y′ = 4(3x² + 1)³ · 6x = 24x(3x² + 1)³. Outer power rule gives 4(inside)³; the inside 3x² + 1 differentiates to 6x; multiply them. Forgetting the ·6x is the single most common calculus mistake.',
      ),
      LessonSection.thinkReveal(
        title: 'Product vs. Quotient',
        question:
            'Which rule for y = x²·sin(x), and what is y′? (Recall d/dx[sin x] = cos x.)',
        answer:
            'Product rule: y′ = f′g + f·g′ = 2x·sin(x) + x²·cos(x). You cannot just multiply the two separate derivatives — the product rule is why 2x·cos(x) alone is wrong.',
      ),
      LessonSection.paragraph(
        title: 'Where This Unlocks',
        body:
            'The chain rule is the doorway to the next idea. When several quantities change together over time — a balloon\'s radius and its volume, a ladder\'s foot and its top — the chain rule links their rates. That family of problems has a name: related rates.',
      ),
    ],
  ),
  BioEntity(
    id: 'calc1_related_rates',
    scale: BioScale.infinities,
    position: 4,
    name: 'Related Rates',
    title: 'When Everything Moves at Once',
    moduleId: 'infinities_calc1',
    shortDescription:
        'One quantity changes and drags others with it — differentiate the relationship with respect to time to link their speeds.',
    longDescription:
        'A balloon inflates: its radius grows, so its volume grows too. The two rates are chained together by geometry. Related-rates problems hand you one rate and ask for another, using an equation that ties the quantities and the chain rule to differentiate it with respect to time.\n\n'
        'The trick is discipline: write the relationship, differentiate both sides with respect to t (every variable gets a d/dt via the chain rule), THEN substitute the numbers — not before. Substituting early freezes a variable that is supposed to be moving.',
    relatedIds: ['calc1_rules_of_differentiation', 'calc1_optimization'],
    sections: [
      LessonSection.fact(
        title: 'The Core Move',
        body:
            'Differentiate the geometry with respect to time. From V = (4/3)πr³ you get dV/dt = 4πr² · dr/dt — the two rates, chained.',
      ),
      LessonSection.table(
        title: 'The Recipe (Order Is Everything)',
        headers: ['Step', 'Do this'],
        rows: [
          ['1', 'Name variables; note which rate is given, which is wanted'],
          ['2', 'Write an equation relating the variables'],
          ['3', 'Differentiate BOTH sides with respect to t'],
          ['4', 'ONLY NOW plug in the instantaneous numbers'],
          ['5', 'Solve for the unknown rate'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The Sliding Ladder',
        question:
            'A 10 ft ladder leans on a wall. Its base slides out at 1 ft/s. When the base is 6 ft from the wall, how fast is the top sliding DOWN? (Use x² + y² = 100.)',
        answer:
            'The top drops at 0.75 ft/s. At x = 6, y = √(100 − 36) = 8. Differentiate: 2x·(dx/dt) + 2y·(dy/dt) = 0 ⇒ 6(1) + 8(dy/dt) = 0 ⇒ dy/dt = −6/8 = −0.75 ft/s. The minus sign means the top is descending.',
      ),
      LessonSection.paragraph(
        title: 'From Motion to Extremes',
        body:
            'Related rates use the derivative to describe change in motion. But the derivative also finds where change momentarily STOPS — where a rate hits zero. Those flat spots are where curves peak and bottom out, and hunting them is the art of optimization.',
      ),
    ],
  ),
  BioEntity(
    id: 'calc1_optimization',
    scale: BioScale.infinities,
    position: 5,
    name: 'Optimization',
    title: 'Finding the Best of All Worlds',
    moduleId: 'infinities_calc1',
    shortDescription:
        'Maxima and minima hide where the slope is zero — set the derivative to 0 and calculus hands you the extremes.',
    longDescription:
        'At the very top of a hill or the bottom of a valley, the tangent line is momentarily flat — the slope is zero. That single insight turns "find the biggest / cheapest / fastest" into an equation: set f′(x) = 0 and solve. The solutions are the critical points, the only candidates for a smooth extreme.\n\n'
        'To tell a peak from a valley, look at the second derivative or how the sign of f′ flips. This is calculus at its most practical — least material, maximum profit, shortest time — the machinery behind engineering and economics alike.',
    relatedIds: ['calc1_related_rates', 'calc1_lhopital'],
    sections: [
      LessonSection.fact(
        title: 'Fermat\'s Insight',
        body:
            'At a smooth maximum or minimum, f′(x) = 0. The tangent goes flat. Every candidate extreme is a critical point where the derivative vanishes.',
      ),
      LessonSection.table(
        title: 'Peak or Valley? The Second-Derivative Test',
        headers: ['At a critical point', 'f″(x) sign', 'Verdict'],
        rows: [
          ['f′ = 0', 'f″ < 0', 'concave down → maximum'],
          ['f′ = 0', 'f″ > 0', 'concave up → minimum'],
          ['f′ = 0', 'f″ = 0', 'inconclusive — inspect further'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The Fence Problem',
        question:
            'You have 100 ft of fence for a rectangular pen against a barn (only 3 sides fenced). What dimensions give the maximum area?',
        answer:
            '50 ft wide (parallel to barn) × 25 ft deep, area 1250 ft². With sides x, x, and width w: 2x + w = 100, so w = 100 − 2x. Area A = x·w = x(100 − 2x) = 100x − 2x². A′ = 100 − 4x = 0 ⇒ x = 25, w = 50. Since A″ = −4 < 0, it is a maximum.',
      ),
      LessonSection.paragraph(
        title: 'One Loose Thread',
        body:
            'The tests above assumed smooth, well-behaved limits. But some limits still land on the maddening forms 0/0 or ∞/∞ that even factoring cannot clear. For those, calculus keeps one more elegant weapon — a way to let derivatives settle a limit that refuses to resolve.',
      ),
    ],
  ),
  BioEntity(
    id: 'calc1_lhopital',
    scale: BioScale.infinities,
    position: 6,
    name: "L'Hôpital's Rule",
    title: 'When Derivatives Rescue a Limit',
    moduleId: 'infinities_calc1',
    shortDescription:
        'Stuck on 0/0 or ∞/∞? Replace top and bottom with their derivatives and try the limit again.',
    longDescription:
        'Some limits arrive as indeterminate forms — 0/0 or ∞/∞ — where the answer genuinely could be anything until you look closer. L\'Hôpital\'s Rule is the clean escape: if lim f(x)/g(x) gives such a form, then it equals lim f′(x)/g′(x), provided that second limit exists.\n\n'
        'Do NOT confuse it with the quotient rule — you differentiate the top and bottom SEPARATELY, not as a fraction. It is the perfect closing act for Calculus I: the derivative, born from limits, now circles back to conquer the limits that stumped us at the start.',
    relatedIds: ['calc1_optimization', 'calc1_the_limit'],
    sections: [
      LessonSection.fact(
        title: 'The Rule',
        body:
            'If lim f/g is 0/0 or ∞/∞, then lim f/g = lim f′/g′. Differentiate numerator and denominator separately, then retry.',
      ),
      LessonSection.table(
        title: 'The Indeterminate Forms',
        headers: ['Form', 'Direct L\'Hôpital?'],
        rows: [
          ['0 / 0', 'Yes'],
          ['∞ / ∞', 'Yes'],
          ['0 · ∞', 'Rewrite as a fraction first'],
          ['∞ − ∞', 'Combine into one fraction first'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The Limit That Started It All',
        question:
            'lim(x→0) sin(x)/x gives 0/0. Apply L\'Hôpital. (d/dx[sin x] = cos x, d/dx[x] = 1.)',
        answer:
            '1. Differentiate top and bottom: cos(x)/1. As x → 0, cos(0) = 1. So lim(x→0) sin(x)/x = 1 — the famous limit at the heart of trig calculus, settled in one line.',
      ),
      LessonSection.thinkReveal(
        title: 'Know When NOT To Use It',
        question:
            'A student applies L\'Hôpital to lim(x→0) (x + 1)/(x + 2). Why is that wrong?',
        answer:
            'Because it is NOT indeterminate — plug in x = 0 to get 1/2 directly. L\'Hôpital only applies to 0/0 or ∞/∞. Using it here (giving 1/1 = 1) produces a flat-out wrong answer. Always check the form first.',
      ),
      LessonSection.paragraph(
        title: 'Full Circle',
        body:
            'You began this module with the limit — the art of approaching without arriving. You end it wielding the derivative to bend stubborn limits to your will. The infinitesimal is no longer a mystery; it is a tool. That is Calculus I: infinity, tamed.',
      ),
    ],
  ),
];
