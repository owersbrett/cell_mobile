import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Infinity → "Calculus II — Integration & Series" module.
/// Entities carry moduleId: 'infinities_calc2'. (Authored by module agent.)
///
/// This is the scale where infinity sings loudest: area computed as an
/// infinite sum of slivers, functions rebuilt as infinite polynomials, and
/// tidy finite answers (like π²/6) that fall out of adding forever.
const List<BioEntity> infinityCalc2Entities = <BioEntity>[
  // 0 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'calc2_the_integral',
    scale: BioScale.infinities,
    position: 0,
    name: 'The Integral',
    title: 'Area as an infinite sum',
    moduleId: 'infinities_calc2',
    shortDescription:
        'To find the area under a curve, slice it into infinitely many rectangles and add them all up.',
    longDescription:
        'How do you measure the area under a curve when the top is not a straight line? You cheat, cleverly. Cover the region with n thin rectangles, add their areas — that is a Riemann sum — and then let the rectangles get infinitely thin. The staircase melts into the curve, and the sum converges to a single number: the integral.\n\n'
        'The symbol ∫ is a stretched-out "S" for "sum." When you write ∫ₐᵇ f(x) dx you are literally saying: add up f(x)·dx over infinitely many infinitesimal slices from a to b. Integration is the machine that turns "add up infinitely many almost-nothings" into an exact area.',
    relatedIds: ['calc2_ftc'],
    sections: [
      LessonSection.fact(
        title: 'The hook',
        body:
            'Area under a curve = the limit of a sum of infinitely many rectangles. Infinity is not a bug here — it is the whole method.',
      ),
      LessonSection.paragraph(
        title: 'The Riemann sum',
        body:
            'Split [a, b] into n pieces each of width Δx = (b − a)/n. Pick a sample height f(xᵢ) in each piece. The total rectangle area is Σ f(xᵢ)·Δx. As n → ∞, Δx → 0 and this sum → ∫ₐᵇ f(x) dx. More rectangles, thinner rectangles, better fit.',
      ),
      LessonSection.table(
        title: 'The staircase closes in (area under y = x² on [0, 1])',
        headers: ['Rectangles n', 'Riemann sum (approx)', 'Error from 1/3'],
        rows: [
          ['4', '0.219', '0.114'],
          ['10', '0.285', '0.048'],
          ['100', '0.328', '0.005'],
          ['∞', '0.333… = 1/3', '0'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Commit first',
        question:
            'The exact area under y = x² from 0 to 1 is 1/3. If you use rectangles whose height is the RIGHT edge of each slice, is your estimate too big or too small — and why?',
        answer:
            'Too big. Because x² is increasing on [0, 1], the right edge is the tallest point of each slice, so every rectangle pokes above the curve. Right-endpoint sums overestimate; left-endpoint sums underestimate. Both squeeze toward 1/3 as n → ∞.',
      ),
      LessonSection.paragraph(
        title: 'Where this goes next',
        body:
            'Adding infinitely many rectangles by hand is brutal. Next comes the theorem that makes it effortless — the one that quietly connects integration to the derivative you already know.',
      ),
    ],
  ),

  // 1 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'calc2_ftc',
    scale: BioScale.infinities,
    position: 1,
    name: 'The Fundamental Theorem of Calculus',
    title: 'The bridge between slopes and areas',
    moduleId: 'infinities_calc2',
    shortDescription:
        'Integration and differentiation are inverse operations — the single most important idea in calculus.',
    longDescription:
        'Two problems that look unrelated — finding slopes (derivatives) and finding areas (integrals) — turn out to be exact opposites of each other. That is the Fundamental Theorem of Calculus, and it is why calculus is one subject and not two.\n\n'
        'Part 1 says the area-so-far function A(x) = ∫ₐˣ f(t) dt has derivative A′(x) = f(x): differentiate an accumulated area and you recover the thing you accumulated. Part 2 turns that into a computation rule: ∫ₐᵇ f(x) dx = F(b) − F(a), where F is any antiderivative of f. You no longer sum infinitely many rectangles — you find an antiderivative and subtract two numbers.',
    relatedIds: ['calc2_the_integral', 'calc2_techniques'],
    sections: [
      LessonSection.fact(
        title: 'The landmark',
        body:
            '∫ₐᵇ f(x) dx = F(b) − F(a),  where F′ = f. The infinite sum collapses to a subtraction.',
      ),
      LessonSection.table(
        title: 'The two directions are mirror images',
        headers: ['Operation', 'What it does', 'Undoes'],
        rows: [
          ['d/dx', 'slope / instantaneous rate', 'the integral'],
          ['∫ … dx', 'accumulated area / total', 'the derivative'],
          ['FTC Part 1', 'd/dx ∫ₐˣ f = f(x)', '—'],
          ['FTC Part 2', '∫ₐᵇ f = F(b) − F(a)', '—'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Commit first',
        question:
            'We proved ∫₀¹ x² dx = 1/3 with infinitely many rectangles. Using an antiderivative of x², how fast can you get 1/3 now?',
        answer:
            'Instantly. An antiderivative of x² is F(x) = x³/3. So ∫₀¹ x² dx = F(1) − F(0) = 1³/3 − 0 = 1/3. No sum, no limit — the FTC did all the infinite work for us.',
      ),
      LessonSection.paragraph(
        title: 'Why it feels like magic',
        body:
            'The FTC says: to add up infinitely many rates of change, just ask how much the total changed from start to finish. Distance is the integral of speed; the theorem says total distance = ending odometer − starting odometer. Obvious in hindsight, revolutionary the first time.',
      ),
      LessonSection.paragraph(
        title: 'Where this goes next',
        body:
            'The FTC only helps if you can find an antiderivative. Most functions do not hand one over freely — so we need techniques to wrestle integrals into a solvable shape.',
      ),
    ],
  ),

  // 2 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'calc2_techniques',
    scale: BioScale.infinities,
    position: 2,
    name: 'Techniques of Integration',
    title: 'Substitution and integration by parts',
    moduleId: 'infinities_calc2',
    shortDescription:
        'The two workhorse tricks that turn a scary integral into one you already know how to solve.',
    longDescription:
        'Differentiation is mechanical: apply the rules and you always win. Integration is an art — there is no universal recipe, so you build a toolbox of reversals. The two most powerful tools are substitution and integration by parts, and each one is a differentiation rule run backward.\n\n'
        'Substitution reverses the chain rule: ∫ f(g(x))·g′(x) dx = ∫ f(u) du with u = g(x). Integration by parts reverses the product rule: ∫ u dv = uv − ∫ v du. The whole game is to spot which reversal a given integral is begging for.',
    relatedIds: ['calc2_ftc', 'calc2_improper'],
    sections: [
      LessonSection.fact(
        title: 'The hook',
        body:
            'Every integration trick is a derivative rule played in reverse. u-substitution = chain rule backward; by parts = product rule backward.',
      ),
      LessonSection.table(
        title: 'Pick the right tool',
        headers: ['Technique', 'Reverses', 'Use when you see…', 'Formula'],
        rows: [
          [
            'u-substitution',
            'chain rule',
            'an inner function and (a multiple of) its derivative',
            '∫ f(g(x))g′(x) dx = ∫ f(u) du'
          ],
          [
            'By parts',
            'product rule',
            'a product of two unlike things (x·eˣ, x·ln x)',
            '∫ u dv = uv − ∫ v du'
          ],
        ],
      ),
      LessonSection.paragraph(
        title: 'Worked substitution',
        body:
            'Compute ∫ 2x·cos(x²) dx. Let u = x², so du = 2x dx — and 2x dx is sitting right there. The integral becomes ∫ cos(u) du = sin(u) + C = sin(x²) + C. Check by differentiating: d/dx sin(x²) = cos(x²)·2x. It matches.',
      ),
      LessonSection.thinkReveal(
        title: 'Commit first',
        question:
            'To integrate ∫ x·eˣ dx by parts (∫ u dv = uv − ∫ v du), which factor should be u and which should be dv — and why?',
        answer:
            'Let u = x and dv = eˣ dx. Then du = dx (simpler!) and v = eˣ. So ∫ x·eˣ dx = x·eˣ − ∫ eˣ dx = x·eˣ − eˣ + C = eˣ(x − 1) + C. The trick: choose u to be the piece that gets simpler when differentiated. Here x differentiates to 1 and disappears.',
      ),
      LessonSection.paragraph(
        title: 'Where this goes next',
        body:
            'These tools handle integrals over a finite interval. But what if the region stretches to infinity? Then we push the FTC to its limit — literally.',
      ),
    ],
  ),

  // 3 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'calc2_improper',
    scale: BioScale.infinities,
    position: 3,
    name: 'Improper Integrals',
    title: 'Integrating all the way to infinity',
    moduleId: 'infinities_calc2',
    shortDescription:
        'An infinitely long region can still enclose a finite area — if the curve dies fast enough.',
    longDescription:
        'What is ∫₁^∞ f(x) dx? You cannot plug ∞ into an antiderivative, so you define it as a limit: ∫₁^∞ f(x) dx = lim(b→∞) ∫₁ᵇ f(x) dx. If that limit is a finite number, the improper integral converges; if it blows up, it diverges.\n\n'
        'The stunning part: an infinitely long region can hold a finite area. The catch is whether the curve shrinks toward zero fast enough. ∫₁^∞ 1/x² dx converges to 1, but ∫₁^∞ 1/x dx diverges to ∞ — even though 1/x also goes to zero. "Goes to zero" is not enough; it has to go to zero quickly.',
    relatedIds: ['calc2_techniques', 'calc2_series'],
    sections: [
      LessonSection.fact(
        title: 'The landmark',
        body:
            '∫₁^∞ 1/x² dx = 1.  An infinitely long sliver of area — yet its total is a clean, finite 1.',
      ),
      LessonSection.paragraph(
        title: 'How the limit works',
        body:
            'For ∫₁^∞ 1/x² dx: an antiderivative of x⁻² is −1/x. So ∫₁ᵇ 1/x² dx = [−1/x]₁ᵇ = −1/b − (−1) = 1 − 1/b. As b → ∞, 1/b → 0, so the whole thing → 1. Finite. Converges.',
      ),
      LessonSection.table(
        title: 'Same "goes to zero," opposite fate',
        headers: ['Integral', 'Antiderivative', 'Limit as b → ∞', 'Verdict'],
        rows: [
          ['∫₁^∞ 1/x² dx', '−1/x', '1 − 1/b → 1', 'converges to 1'],
          ['∫₁^∞ 1/x dx', 'ln x', 'ln b → ∞', 'diverges'],
          ['∫₁^∞ 1/x³ dx', '−1/(2x²)', '½ − 1/(2b²) → ½', 'converges to 1/2'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Commit first',
        question:
            'Both 1/x and 1/x² fall to zero as x → ∞. So why does the area under 1/x² stay finite while the area under 1/x runs off to infinity?',
        answer:
            '1/x² decays much faster. Its tail thins so quickly that the accumulated area settles down (to 1). 1/x decays too slowly — its antiderivative ln x has no ceiling, so the area keeps creeping upward forever. Convergence is a race between the tail shrinking and the interval growing, and 1/x loses that race.',
      ),
      LessonSection.paragraph(
        title: 'Where this goes next',
        body:
            'Adding up a continuous curve forever is one kind of infinite sum. Adding up discrete terms — 1 + 1/2 + 1/3 + … — is the other. Meet sequences and series.',
      ),
    ],
  ),

  // 4 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'calc2_series',
    scale: BioScale.infinities,
    position: 4,
    name: 'Infinite Sequences & Series',
    title: 'What does it mean to add forever?',
    moduleId: 'infinities_calc2',
    shortDescription:
        'A series is an infinite list of numbers added together — and sometimes the total is finite.',
    longDescription:
        'A sequence is an ordered list of numbers: a₁, a₂, a₃, … . A series is what you get when you add them: Σ aₙ = a₁ + a₂ + a₃ + … forever. The obvious worry — "adding infinitely many things must give infinity" — is simply false. Add 1/2 + 1/4 + 1/8 + … and you get exactly 1.\n\n'
        'We make sense of an infinite sum with partial sums Sₙ = a₁ + … + aₙ. If the sequence of partial sums S₁, S₂, S₃, … approaches a finite limit L, the series converges to L. If the partial sums wander off or grow without bound, it diverges. So "sum of infinitely many terms" really means "the number the running total is heading toward."',
    relatedIds: ['calc2_improper', 'calc2_convergence'],
    sections: [
      LessonSection.fact(
        title: 'The hook',
        body:
            '½ + ¼ + ⅛ + 1/16 + … = 1. You take infinitely many steps and land on an exact number.',
      ),
      LessonSection.table(
        title: 'The running total closes in on 1',
        headers: ['Terms added', 'Partial sum Sₙ', 'Gap to 1'],
        rows: [
          ['½', '0.5', '0.5'],
          ['½ + ¼', '0.75', '0.25'],
          ['+ ⅛', '0.875', '0.125'],
          ['+ 1/16', '0.9375', '0.0625'],
          ['… forever', '→ 1', '→ 0'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Commit first',
        question:
            'The harmonic series 1 + 1/2 + 1/3 + 1/4 + … has terms that shrink to zero. Does it add up to a finite number, or does it diverge to infinity?',
        answer:
            'It DIVERGES to infinity — one of the great surprises of math. Group the terms: (1/3 + 1/4) > 1/2, then (1/5 + … + 1/8) > 1/2, then the next eight terms > 1/2, and so on forever. You can keep gaining another 1/2, so the sum has no ceiling. Terms going to zero is NECESSARY for convergence but not SUFFICIENT.',
      ),
      LessonSection.paragraph(
        title: 'Where this goes next',
        body:
            'So terms→0 does not guarantee a finite sum, and staring at partial sums is slow. We need fast tests that tell us convergence-or-not without summing anything.',
      ),
    ],
  ),

  // 5 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'calc2_convergence',
    scale: BioScale.infinities,
    position: 5,
    name: 'Convergence Tests',
    title: 'Deciding if a sum is finite — without summing it',
    moduleId: 'infinities_calc2',
    shortDescription:
        'Geometric, p-series, and the ratio test — quick verdicts on whether an infinite sum settles down.',
    longDescription:
        'You rarely need the exact value of a series; you need to know whether it converges at all. Convergence tests are the diagnostic kit. The three you reach for constantly are the geometric series (a closed formula AND a verdict), the p-series (a clean threshold), and the ratio test (works when factorials or exponentials appear).\n\n'
        'Geometric: Σ arⁿ (n from 0) converges exactly to a/(1 − r) when |r| < 1, and diverges when |r| ≥ 1. p-series: Σ 1/nᵖ converges when p > 1 and diverges when p ≤ 1 (so 1/n diverges, 1/n² converges). Ratio test: compute L = lim |aₙ₊₁/aₙ|; if L < 1 it converges, if L > 1 it diverges, and if L = 1 the test is inconclusive.',
    relatedIds: ['calc2_series', 'calc2_taylor'],
    sections: [
      LessonSection.fact(
        title: 'The landmark',
        body:
            'Geometric series: Σ arⁿ = a/(1 − r) for |r| < 1. This is the ½+¼+⅛ result in one formula: a = ½, r = ½ → (½)/(1 − ½) = 1.',
      ),
      LessonSection.table(
        title: 'The three go-to tests',
        headers: ['Test', 'Series', 'Converges when', 'Diverges when'],
        rows: [
          ['Geometric', 'Σ arⁿ', '|r| < 1  → sum = a/(1 − r)', '|r| ≥ 1'],
          ['p-series', 'Σ 1/nᵖ', 'p > 1', 'p ≤ 1'],
          [
            'Ratio test',
            'general Σ aₙ',
            'L = lim|aₙ₊₁/aₙ| < 1',
            'L > 1  (L = 1: inconclusive)'
          ],
        ],
      ),
      LessonSection.paragraph(
        title: 'Ratio test in action',
        body:
            'Does Σ 1/n! converge? Take aₙ = 1/n!. Then aₙ₊₁/aₙ = n! / (n+1)! = 1/(n+1). As n → ∞ this ratio → 0 = L < 1, so the series converges (in fact it sums to e). Factorials in the denominator crush the terms fast — the ratio test loves that.',
      ),
      LessonSection.thinkReveal(
        title: 'Commit first',
        question:
            'Using the p-series rule (Σ 1/nᵖ converges iff p > 1), classify these three: Σ 1/n, Σ 1/n², and Σ 1/√n. Which converge?',
        answer:
            'Σ 1/n has p = 1 → diverges (the harmonic series). Σ 1/n² has p = 2 > 1 → converges. Σ 1/√n has p = 1/2 ≤ 1 → diverges. The p = 1 line is the exact knife-edge: anything above it converges, anything at-or-below diverges.',
      ),
      LessonSection.paragraph(
        title: 'Where this goes next',
        body:
            'Once we trust that a series converges, we can do something audacious: use an infinite series to BUILD a function — turning eˣ, sin x, and cos x into infinite polynomials.',
      ),
    ],
  ),

  // 6 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'calc2_taylor',
    scale: BioScale.infinities,
    position: 6,
    name: 'Taylor & Power Series',
    title: 'A function as an infinite polynomial',
    moduleId: 'infinities_calc2',
    shortDescription:
        'Curvy functions like eˣ and sin x can be rewritten as infinite polynomials — and it is how calculators actually compute them.',
    longDescription:
        'A power series is a polynomial with infinitely many terms: Σ cₙ xⁿ = c₀ + c₁x + c₂x² + … . The Taylor series chooses those coefficients so the polynomial matches a function\'s value and every derivative at a point: cₙ = f⁽ⁿ⁾(0)/n! (centered at 0, called a Maclaurin series). The result is astonishing — a smooth, curvy function becomes an infinite sum of simple powers.\n\n'
        'This is not a curiosity; it is how eˣ, sin x, and cos x are actually evaluated. A machine cannot "do" sine, but it can add polynomial terms. eˣ = Σ xⁿ/n! = 1 + x + x²/2! + x³/3! + … . sin x = x − x³/3! + x⁵/5! − … . cos x = 1 − x²/2! + x⁴/4! − … . Add a few terms for a rough answer, add more for a razor-sharp one.',
    relatedIds: ['calc2_convergence', 'calc2_basel'],
    sections: [
      LessonSection.fact(
        title: 'The hook',
        body:
            'eˣ = 1 + x + x²/2! + x³/3! + … . The most important function in math is just an infinite polynomial.',
      ),
      LessonSection.table(
        title: 'Three functions, rebuilt as infinite polynomials',
        headers: ['Function', 'Maclaurin series', 'Pattern'],
        rows: [
          ['eˣ', '1 + x + x²/2! + x³/3! + …', 'Σ xⁿ/n!'],
          ['sin x', 'x − x³/3! + x⁵/5! − …', 'odd powers, alternating'],
          ['cos x', '1 − x²/2! + x⁴/4! − …', 'even powers, alternating'],
          ['1/(1 − x)', '1 + x + x² + x³ + …', 'geometric, |x| < 1'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Commit first',
        question:
            'Estimate e using eˣ = 1 + x + x²/2! + x³/3! + … at x = 1 with just the first five terms. How close to the true e ≈ 2.71828 do you get?',
        answer:
            '1 + 1 + 1/2 + 1/6 + 1/24 = 1 + 1 + 0.5 + 0.1667 + 0.0417 = 2.7083. Just five terms lands within 0.01 of e ≈ 2.71828. Each extra term (÷ a bigger factorial) sharpens it further — this is exactly how your calculator does it.',
      ),
      LessonSection.paragraph(
        title: 'Where this goes next',
        body:
            'If a function can become an infinite sum, then a well-chosen infinite sum can hide a famous number inside it. The finale: add up 1/n² forever and watch π appear out of nowhere.',
      ),
    ],
  ),

  // 7 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'calc2_basel',
    scale: BioScale.infinities,
    position: 7,
    name: 'The Basel Problem',
    title: 'Where π hides inside 1/n²',
    moduleId: 'infinities_calc2',
    shortDescription:
        'Add 1 + 1/4 + 1/9 + 1/16 + … forever and you get π²/6 — a circle constant falling out of pure squares.',
    longDescription:
        'For ninety years the sharpest minds in Europe tried to find the exact value of Σ 1/n² = 1 + 1/4 + 1/9 + 1/16 + … . We already know it converges (p-series with p = 2 > 1), and it is clearly a little above 1.6 — but what number, exactly? In 1734 a 27-year-old Leonhard Euler stunned everyone: the sum is π²/6.\n\n'
        'π²/6 ≈ 1.644934. Read that again: there are no circles anywhere in 1 + 1/4 + 1/9 + … , yet π — the circle constant — comes strolling out. Euler got it by treating sin(x)/x as an infinite polynomial and comparing coefficients (a bold reuse of the power-series idea from the previous entity). This is the moment infinity stops being scary and starts being beautiful: an endless sum of humble reciprocal squares collapses to one of the most famous constants in mathematics.',
    relatedIds: ['calc2_taylor', 'calc2_convergence'],
    sections: [
      LessonSection.fact(
        title: 'The landmark',
        body:
            'Σ (n=1→∞) 1/n² = 1 + 1/4 + 1/9 + 1/16 + … = π²/6 ≈ 1.644934. (Euler, 1734.)',
      ),
      LessonSection.table(
        title: 'The partial sums crawl toward π²/6',
        headers: ['Terms', 'Partial sum', 'π²/6 ≈ 1.644934'],
        rows: [
          ['1', '1.000000', 'below'],
          ['1 + 1/4', '1.250000', 'below'],
          ['+ 1/9 + 1/16', '1.423611', 'below'],
          ['first 10 terms', '1.549768', 'closing in'],
          ['first 1000 terms', '1.643935', '≈ within 0.001'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Commit first',
        question:
            'Σ 1/n DIVERGES (harmonic) but Σ 1/n² CONVERGES to π²/6. Both are sums of reciprocals with terms shrinking to zero — what single fact draws the line between them?',
        answer:
            'The exponent p, via the p-series rule (converges iff p > 1). Σ 1/n has p = 1 (on the knife-edge → diverges); Σ 1/n² has p = 2 > 1 → converges. Squaring the denominator makes the terms shrink just fast enough to gather into a finite total — and that finite total happens to be π²/6.',
      ),
      LessonSection.paragraph(
        title: 'The takeaway',
        body:
            'This is the heart of Calculus II. Infinity is not a wall you crash into — it is a place tidy, finite, gorgeous answers come from. Area from infinite rectangles, functions from infinite polynomials, and π from an infinite sum of squares. That is the whole module in one number: π²/6.',
      ),
    ],
  ),
];
