import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Infinity → "Calculus III — Multivariable" module.
/// Entities carry moduleId: 'infinities_calc3'. (Authored by module agent.)
const List<BioEntity> infinityCalc3Entities = <BioEntity>[
  // ── 0 ──────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'calc3_functions_several_variables',
    scale: BioScale.infinities,
    position: 0,
    name: 'Functions of Several Variables',
    title: 'When the input grows a second axis',
    moduleId: 'infinities_calc3',
    shortDescription:
        'A function z = f(x, y) stops being a curve and becomes a landscape — a surface floating over the xy-plane.',
    longDescription:
        'In Calculus I a function ate one number and spat out one number: y = f(x), a curve you could trace with a pencil. Multivariable calculus hands the function a second input. Now f(x, y) takes a POINT in a plane and returns a height. Sweep over every point and the outputs stitch together into a surface — a rolling terrain suspended above the floor.\n\n'
        'This one move — a second input axis — is the whole reason Calc III exists. Temperature over a map, pressure across a wing, altitude over a valley: all are functions of two variables. Add a third input and f(x, y, z) becomes a density or a temperature filling a solid region of space. The pictures get richer, but the questions stay the same: how steep, how much, which way?',
    relatedIds: ['calc3_partial_derivatives', 'calc3_multiple_integrals'],
    sections: [
      LessonSection.fact(
        title: 'The core upgrade',
        body: 'One input → a CURVE.  Two inputs → a SURFACE.  Three inputs → a FIELD filling space.',
      ),
      LessonSection.paragraph(
        title: 'Reading a surface with level curves',
        body:
            'You already read surfaces every day: a topographic map. Slice the surface z = f(x, y) at a fixed height (say z = 100 m) and project that slice down onto the plane — you get a level curve, a contour. Closely spaced contours mean a steep climb; widely spaced contours mean gentle ground. The whole family of contours is a flat portrait of a 3D shape.',
      ),
      LessonSection.table(
        title: 'From one dimension up to three',
        headers: ['Function', 'Input', 'Output', 'Graph lives in'],
        rows: [
          ['y = f(x)', '1 number', '1 number', '2D (a curve)'],
          ['z = f(x, y)', 'a point (x, y)', 'a height', '3D (a surface)'],
          ['w = f(x, y, z)', 'a point in space', 'a value', '4D (drawn as a colored field)'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Picture the paraboloid',
        question:
            'Take f(x, y) = x² + y². What does its surface look like, and what shape are its level curves?',
        answer:
            'The surface is a bowl (a paraboloid) with its low point at the origin — every step away from the center raises the height. Setting x² + y² = c gives circles of radius √c, so the level curves are concentric circles that crowd together as you go outward (the bowl gets steeper). At (1, 2) the height is 1² + 2² = 5.',
      ),
    ],
  ),

  // ── 1 ──────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'calc3_partial_derivatives',
    scale: BioScale.infinities,
    position: 1,
    name: 'Partial Derivatives',
    title: 'Slope along one axis at a time',
    moduleId: 'infinities_calc3',
    shortDescription:
        'A partial derivative asks: if I nudge ONLY x and freeze y, how fast does the height change? It is single-variable calculus in blinders.',
    longDescription:
        'On a surface there is no single "slope" — it depends which way you walk. The partial derivative tames this by walking along the coordinate axes. To compute ∂f/∂x, you treat y as a frozen constant and differentiate as if x were the only variable. Geometrically you slice the surface with a plane parallel to the x-axis and measure the slope of the resulting curve.\n\n'
        'That is the entire trick: a hard multivariable problem collapses into the Calc I you already know, because every other variable is held still. The symbol changes from d to ∂ (the "curly d") to announce "there are other variables I am deliberately ignoring right now."',
    relatedIds: ['calc3_functions_several_variables', 'calc3_gradient'],
    sections: [
      LessonSection.fact(
        title: 'The mantra',
        body: '∂f/∂x  =  "differentiate with respect to x, holding every other variable CONSTANT."',
      ),
      LessonSection.thinkReveal(
        title: 'Do one by hand',
        question:
            'For f(x, y) = x²y + 3y², find ∂f/∂x and ∂f/∂y. Commit to both before revealing.',
        answer:
            '∂f/∂x: hold y constant. The term x²y differentiates to 2xy; the term 3y² is a constant in x, so it vanishes. ∂f/∂x = 2xy.\n\n'
            '∂f/∂y: hold x constant. The term x²y differentiates to x²; the term 3y² differentiates to 6y. ∂f/∂y = x² + 6y.',
      ),
      LessonSection.table(
        title: 'One derivative → several partials',
        headers: ['f(x, y)', '∂f/∂x', '∂f/∂y'],
        rows: [
          ['x²y + 3y²', '2xy', 'x² + 6y'],
          ['sin(xy)', 'y·cos(xy)', 'x·cos(xy)'],
          ['x/y', '1/y', '−x/y²'],
          ['e^(x²+y)', '2x·e^(x²+y)', 'e^(x²+y)'],
        ],
      ),
      LessonSection.paragraph(
        title: 'Second partials and the mixed-derivative surprise',
        body:
            'You can differentiate again. ∂²f/∂x² measures the curvature along x. The mixed partial ∂²f/∂x∂y differentiates first by y, then by x. Clairaut\'s theorem says that for well-behaved functions the order does not matter: ∂²f/∂x∂y = ∂²f/∂y∂x. Check it on our example: ∂/∂y of (2xy) = 2x, and ∂/∂x of (x² + 6y) = 2x. They agree.',
      ),
    ],
  ),

  // ── 2 ──────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'calc3_gradient',
    scale: BioScale.infinities,
    position: 2,
    name: 'The Gradient & Directional Derivatives',
    title: 'The arrow that points straight uphill',
    moduleId: 'infinities_calc3',
    shortDescription:
        'Bundle the partial derivatives into a vector ∇f and you get an arrow, at every point, aiming in the direction of steepest ascent.',
    longDescription:
        'Partial derivatives only tell you the slope along x and along y. But a hiker can walk in ANY direction. The directional derivative measures the slope along an arbitrary unit vector u, and the elegant result is that you compute it with a single dot product: D_u f = ∇f · u.\n\n'
        'The star of the show is the gradient ∇f = (∂f/∂x, ∂f/∂y). This vector packs both facts a hiker wants: its DIRECTION points straight uphill (steepest ascent), and its LENGTH is exactly how steep that steepest climb is. As a bonus, ∇f is always perpendicular to the level curves — which is why the fastest way up a hill is to cut straight across the contour lines, never along them.',
    relatedIds: ['calc3_partial_derivatives', 'calc3_vector_fields'],
    sections: [
      LessonSection.fact(
        title: 'The gradient, two dimensions',
        body: '∇f = (∂f/∂x, ∂f/∂y).  It points toward steepest ASCENT, and |∇f| is that maximum slope.',
      ),
      LessonSection.thinkReveal(
        title: 'Steepest way up the bowl',
        question:
            'For f(x, y) = x² + y², what is ∇f at the point (3, 4)? Which way is steepest, and how steep is it?',
        answer:
            '∇f = (2x, 2y), so at (3, 4) it is (6, 8). Steepest ascent points along (6, 8) — directly away from the origin. Its steepness is the length |∇f| = √(6² + 8²) = √(36 + 64) = √100 = 10.',
      ),
      LessonSection.paragraph(
        title: 'The directional derivative by dot product',
        body:
            'To find the slope in a chosen direction, first make the direction a UNIT vector u (length 1). Then D_u f = ∇f · u. Because a dot product is largest when the two vectors are parallel, the slope is maximized when you walk along ∇f itself — confirming the gradient is the steepest direction. Walk perpendicular to ∇f and the dot product is zero: you are moving along a level curve, gaining no height.',
      ),
      LessonSection.table(
        title: 'Walk which way, get which slope',
        headers: ['Direction relative to ∇f', 'Dot product ∇f · u', 'What happens'],
        rows: [
          ['Same direction (uphill)', '+|∇f| (max)', 'Steepest climb'],
          ['Opposite (downhill)', '−|∇f| (min)', 'Steepest descent'],
          ['Perpendicular', '0', 'Along a contour, no height change'],
        ],
      ),
    ],
  ),

  // ── 3 ──────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'calc3_multiple_integrals',
    scale: BioScale.infinities,
    position: 3,
    name: 'Multiple Integrals',
    title: 'Adding up volume, one slab at a time',
    moduleId: 'infinities_calc3',
    shortDescription:
        'A double integral ∫∫ sums the volume under a surface; a triple integral ∫∫∫ sums mass or charge throughout a solid.',
    longDescription:
        'A single integral found the AREA under a curve. Raise the dimension: a double integral ∫∫ f(x, y) dA finds the VOLUME trapped between the surface z = f(x, y) and the floor beneath a region. You chop the base region into tiny tiles of area dA, multiply each tile by the height of the surface above it, and add up an infinity of these matchbox columns.\n\n'
        'The practical secret is that you evaluate it as an iterated integral — integrate with respect to x first (holding y fixed, the reverse of a partial derivative), then integrate the result over y. A triple integral ∫∫∫ f dV goes one dimension further: it sweeps through a solid region, and with f as a density it totals the mass, or the charge, or the heat contained inside.',
    relatedIds: ['calc3_functions_several_variables', 'calc3_divergence_theorem'],
    sections: [
      LessonSection.fact(
        title: 'The dimension ladder',
        body: '∫ f dx → area under a curve.   ∫∫ f dA → volume under a surface.   ∫∫∫ f dV → total stuff inside a solid.',
      ),
      LessonSection.paragraph(
        title: 'Iterated: integrate one variable, then the next',
        body:
            'A double integral is done from the inside out. To evaluate ∫∫ f dA over a rectangle, first integrate over x while treating y as a constant — this is antidifferentiation in blinders, the mirror image of the partial derivative. That produces a function of y alone. Then integrate THAT over y. Two ordinary integrals, stacked.',
      ),
      LessonSection.thinkReveal(
        title: 'Compute a real volume',
        question:
            'Evaluate ∫∫ (over 0 ≤ x ≤ 2, 0 ≤ y ≤ 3) of the constant f = 4. Then check it with plain geometry.',
        answer:
            'Inner integral over x: ∫₀² 4 dx = 4x evaluated 0→2 = 8. Now integrate over y: ∫₀³ 8 dy = 8y evaluated 0→3 = 24.\n\n'
            'Geometry check: this is a box of height 4 over a 2×3 base, so volume = 4 × 2 × 3 = 24. ✓ The integral machinery agrees with the box formula.',
      ),
      LessonSection.table(
        title: 'What the integral totals depends on f',
        headers: ['Integral', 'If f is…', 'You get'],
        rows: [
          ['∫∫ f dA', 'height', 'volume under the surface'],
          ['∫∫ 1 dA', 'just 1', 'area of the region'],
          ['∫∫∫ ρ dV', 'density', 'total mass of the solid'],
          ['∫∫∫ 1 dV', 'just 1', 'volume of the solid'],
        ],
      ),
    ],
  ),

  // ── 4 ──────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'calc3_vector_fields',
    scale: BioScale.infinities,
    position: 4,
    name: 'Vector Fields',
    title: 'An arrow at every point in space',
    moduleId: 'infinities_calc3',
    shortDescription:
        'A vector field F(x, y) attaches an arrow to every point — the language of wind, water currents, gravity, and electromagnetism.',
    longDescription:
        'Until now a function returned a number (a height). A vector field returns a whole ARROW at each point: F(x, y) = (P(x, y), Q(x, y)). Stand anywhere in the plane and the field tells you a direction and a magnitude. This is exactly how physics draws the invisible: the wind on a weather map, the current in a river, the pull of gravity around a planet, the electric field around a charge.\n\n'
        'Notice the gradient from earlier was secretly a vector field — ∇f assigns the steepest-uphill arrow to every point. Fields that arise this way, as the gradient of some scalar function, are called conservative, and they are special: the work to move through them depends only on start and end points, never the path. Water flowing downhill under gravity is the everyday example.',
    relatedIds: ['calc3_gradient', 'calc3_divergence_curl'],
    sections: [
      LessonSection.fact(
        title: 'What a field returns',
        body: 'A scalar field returns a NUMBER at each point. A vector field returns an ARROW: F = (P, Q).',
      ),
      LessonSection.table(
        title: 'Fields you already know from physics',
        headers: ['Vector field', 'The arrow means', 'Where you meet it'],
        rows: [
          ['Velocity field', 'fluid speed + direction', 'Wind maps, river currents'],
          ['Gravitational field', 'pull on a mass', 'Orbits, tides'],
          ['Electric field', 'force on a + charge', 'Electromagnetism'],
          ['Gradient ∇f', 'steepest ascent', 'Heat flow, optimization'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Sketch the swirl',
        question:
            'Consider F(x, y) = (−y, x). At the point (1, 0) which way does the arrow point? What overall pattern does the field make?',
        answer:
            'At (1, 0): F = (−0, 1) = (0, 1), an arrow pointing straight up. At (0, 1): F = (−1, 0), pointing left. Everywhere the arrow is perpendicular to the position vector, so the whole field ROTATES counterclockwise around the origin — a pure whirlpool. (Hold this example; the next entity measures exactly how much it swirls.)',
      ),
      LessonSection.paragraph(
        title: 'Conservative fields: the path does not matter',
        body:
            'If a field is the gradient of some scalar f (F = ∇f), it is conservative. Moving a particle through it, the total work equals f(end) − f(start) — the messy path in between cancels out completely. Gravity is conservative: climbing a hill by a switchback or straight up costs the same potential energy. This is the multivariable echo of the Fundamental Theorem of Calculus.',
      ),
    ],
  ),

  // ── 5 ──────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'calc3_divergence_curl',
    scale: BioScale.infinities,
    position: 5,
    name: 'Divergence & Curl',
    title: 'How much a field spreads, and how much it spins',
    moduleId: 'infinities_calc3',
    shortDescription:
        'Divergence (∇·F) measures outflow — sources and sinks. Curl (∇×F) measures rotation — the tendency to spin a paddlewheel.',
    longDescription:
        'A vector field has two fundamental local behaviors, and the ∇ operator extracts both. DIVERGENCE, written ∇·F, is a dot product that yields a number: it measures how much the field spreads out of a point. Positive divergence is a SOURCE (a faucet, water gushing out); negative divergence is a SINK (a drain, water rushing in); zero divergence means whatever flows in also flows out.\n\n'
        'CURL, written ∇×F, is a cross product that yields a vector: it measures how much the field ROTATES around a point — drop a tiny paddlewheel in the flow and the curl tells you how fast it spins and about which axis. These two ideas underpin all of fluid dynamics and Maxwell\'s equations for electromagnetism: divergence links fields to charge, curl links changing fields to each other.',
    relatedIds: ['calc3_vector_fields', 'calc3_divergence_theorem'],
    sections: [
      LessonSection.fact(
        title: 'Two operators, two meanings',
        body: 'Divergence ∇·F = ∂P/∂x + ∂Q/∂y  (a number: spreading).   Curl (2D, scalar) = ∂Q/∂x − ∂P/∂y  (spinning).',
      ),
      LessonSection.table(
        title: 'Divergence vs. curl at a glance',
        headers: ['Quantity', 'Operator', 'Result', 'Physical picture'],
        rows: [
          ['Divergence', '∇·F (dot)', 'a number', 'Source (+), sink (−), spreading'],
          ['Curl', '∇×F (cross)', 'a vector', 'Rotation, paddlewheel spin'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Measure the whirlpool',
        question:
            'For the swirl F = (−y, x) from before — here P = −y and Q = x — compute its divergence and its (2D scalar) curl. What do the numbers say?',
        answer:
            'Divergence = ∂P/∂x + ∂Q/∂y = ∂(−y)/∂x + ∂(x)/∂y = 0 + 0 = 0. Nothing is created or destroyed — no source, no sink.\n\n'
            'Curl = ∂Q/∂x − ∂P/∂y = ∂(x)/∂x − ∂(−y)/∂y = 1 − (−1) = 2. A positive curl of 2 everywhere confirms a uniform counterclockwise spin — exactly the whirlpool we sketched.',
      ),
      LessonSection.paragraph(
        title: 'Why physicists live and breathe these',
        body:
            'Maxwell\'s equations are written almost entirely in divergence and curl: ∇·E relates the electric field\'s spreading to charge (Gauss\'s law), and ∇×E, ∇×B tie changing electric and magnetic fields together (Faraday and Ampère). In fluids, zero divergence means incompressible flow; nonzero curl means turbulence and eddies. Two derivatives of a vector field, and you have described most of classical physics.',
      ),
    ],
  ),

  // ── 6 ──────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'calc3_divergence_theorem',
    scale: BioScale.infinities,
    position: 6,
    name: 'The Divergence Theorem',
    title: 'What happens inside equals what crosses the boundary',
    moduleId: 'infinities_calc3',
    shortDescription:
        'The capstone: the total divergence summed throughout a solid equals the net flow through its surface. Interior and boundary, forever linked.',
    longDescription:
        'The great theorems of Calc III — Green\'s, Stokes\', and the Divergence Theorem — all say the same profound thing: an integral over a REGION equals an integral over its BOUNDARY. They are the multivariable descendants of the Fundamental Theorem of Calculus, where ∫ f\'(x) dx over [a, b] equaled f(b) − f(a), the function evaluated at the two boundary points.\n\n'
        'The Divergence Theorem is the most tangible. It says: add up all the divergence (all the tiny sources and sinks) throughout a solid, and the total must equal the net amount of the field flowing OUT through the solid\'s skin. In symbols, ∫∫∫ (∇·F) dV = ∫∫ F·n dS. If more is being created inside than destroyed, exactly that surplus must be escaping through the surface — flow is conserved. It is the mathematics of "what goes in must come out."',
    relatedIds: ['calc3_divergence_curl', 'calc3_multiple_integrals'],
    sections: [
      LessonSection.fact(
        title: 'The Divergence Theorem',
        body: '∫∫∫ (∇·F) dV  =  ∫∫ F·n dS.   Total divergence inside a solid = net flux out through its surface.',
      ),
      LessonSection.paragraph(
        title: 'The one idea behind all the big theorems',
        body:
            'Every capstone theorem trades a hard interior integral for an easier boundary integral (or vice versa). The Fundamental Theorem does it in 1D. Green\'s Theorem ties a double integral over a flat region to a line integral around its curved edge. Stokes\' Theorem lifts that to curved surfaces and their bounding loops. The Divergence Theorem does it for solids and their enclosing skins. Same melody, rising through the dimensions.',
      ),
      LessonSection.thinkReveal(
        title: 'Why it must be true, intuitively',
        question:
            'Imagine a solid packed with tiny cubes, each with some outflow. When you add up every cube\'s flux, why does everything except the outer surface cancel?',
        answer:
            'Where two interior cubes touch, the flow LEAVING one across the shared face is exactly the flow ENTERING its neighbor — same amount, opposite sign, so they cancel. Only faces on the OUTER skin have no neighbor to cancel against. Summing all the interior divergence therefore collapses to just the flux through the outer surface. That cancellation IS the theorem.',
      ),
      LessonSection.table(
        title: 'The family of boundary theorems',
        headers: ['Theorem', 'Interior integral over…', 'Equals boundary integral over…'],
        rows: [
          ['Fundamental Thm (Calc I)', 'an interval [a, b]', 'its two endpoints'],
          ['Green\'s Theorem', 'a flat 2D region', 'the closed curve around it'],
          ['Stokes\' Theorem', 'a curved surface', 'the loop bounding it'],
          ['Divergence Theorem', 'a 3D solid', 'the surface enclosing it'],
        ],
      ),
      LessonSection.fact(
        title: 'The whole module in one breath',
        body: 'Surface → slope one axis (partials) → steepest arrow (gradient) → sum it up (integrals) → arrows everywhere (fields) → spread & spin (div, curl) → inside equals boundary (the theorem).',
      ),
    ],
  ),
];
