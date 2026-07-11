import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Infinity → "Linear Algebra" module.
/// Entities carry moduleId: 'infinities_linear_algebra'. (Authored by module agent.)
const List<BioEntity> infinityLinearAlgebraEntities = <BioEntity>[
  // ───────────────────────────────────────────────────────────────────────
  // 0 — Vectors & Vector Spaces
  // ───────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'linalg_vectors',
    scale: BioScale.infinities,
    position: 0,
    name: 'Vectors & Vector Spaces',
    title: 'arrows that obey rules',
    moduleId: 'infinities_linear_algebra',
    shortDescription:
        'A vector is a thing you can add to another and scale — and the arena where that always works is a vector space.',
    longDescription:
        'Forget "an arrow" for a second. A vector is any object that supports two moves: add two of them and get another one, and stretch one by a number (a scalar) and still get another one. In ℝ² that object is a pair (x, y); in ℝ³ it is a triple; the arrow picture is just how we draw it.\n\n'
        'A vector space is the whole set where those two moves never break the rules — closed under addition and scaling, with a zero vector that changes nothing. That abstract definition is the door this entire module walks through: because it says nothing about arrows, the SAME machinery will later apply to polynomials, signals, and infinite lists of numbers. Linear algebra is the study of everything that behaves like arrows.',
    relatedIds: ['linalg_span', 'linalg_infinite_dim'],
    sections: [
      LessonSection.fact(
        title: 'The whole subject in two moves',
        body:
            'ADD two vectors → get a vector.  SCALE a vector by a number → get a vector.  Everything else is consequences.',
      ),
      LessonSection.paragraph(
        title: 'A vector is coordinates in some basis',
        body:
            'Written as columns, a 2D vector is [3, 2] meaning "3 right, 2 up." Adding is component-wise: [3, 2] + [1, 4] = [4, 6]. Scaling multiplies each component: 2·[3, 2] = [6, 4]. Notice we never needed a picture — just arithmetic that stays inside the set.',
      ),
      LessonSection.table(
        title: 'The eight axioms, in plain speech',
        headers: ['Rule', 'What it demands'],
        rows: [
          ['Closed under +', 'u + v is still in the space'],
          ['Closed under scaling', 'c·v is still in the space'],
          ['Zero vector', 'a 0 that adds to nothing'],
          ['Inverses', 'every v has a −v, so v + (−v) = 0'],
          ['Commutative +', 'u + v = v + u'],
          ['Distributive', 'c·(u + v) = c·u + c·v'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Is the set of all 2D vectors with x ≥ 0 a vector space?',
        question:
            'Take only vectors pointing right or up-right (x ≥ 0). Add and scale allowed. Is it a vector space?',
        answer:
            'No. Scaling by −1 sends [3, 2] to [−3, −2], which has x < 0 and falls out of the set. It is not closed under scaling, so one axiom fails — and one failure disqualifies it. A vector space cannot have edges.',
      ),
    ],
  ),

  // ───────────────────────────────────────────────────────────────────────
  // 1 — Linear Combinations, Span & Basis
  // ───────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'linalg_span',
    scale: BioScale.infinities,
    position: 1,
    name: 'Linear Combinations, Span & Basis',
    title: 'how few arrows describe everything',
    moduleId: 'infinities_linear_algebra',
    shortDescription:
        'Scale some vectors, add them up — that is a linear combination; everything reachable is the span; the leanest reaching set is a basis.',
    longDescription:
        'Take vectors, multiply each by a scalar, and sum them: a·v₁ + b·v₂ + c·v₃. That recipe is a linear combination, and it is the only verb linear algebra allows. The set of every point you can reach this way is the SPAN of those vectors — a line, a plane, or all of space.\n\n'
        'A basis is a span-achieving set with no waste: enough vectors to reach every point, but not one vector too many (none is a combination of the others — they are "linearly independent"). The number of vectors in a basis is fixed for a given space, and that number is its dimension. In ℝ², the arrows [1, 0] and [0, 1] are the standard basis; any [x, y] is just x·[1, 0] + y·[0, 1]. Coordinates ARE the recipe.',
    relatedIds: ['linalg_vectors', 'linalg_dimension_rank'],
    sections: [
      LessonSection.fact(
        title: 'Basis = coordinates',
        body:
            'A basis turns geometry into numbers: every point becomes a unique list of "how much of each basis vector." No basis, no coordinates.',
      ),
      LessonSection.paragraph(
        title: 'Span is reachability',
        body:
            'One nonzero vector spans a line (all its scalings). Two vectors that point in different directions span a plane. But two vectors on the SAME line still span only that line — the second one is redundant. Span asks: what can we build?  Independence asks: is anyone here useless?',
      ),
      LessonSection.table(
        title: 'Span vs. dimension in ℝ³',
        headers: ['Vectors given', 'Independent?', 'Span'],
        rows: [
          ['[1,0,0]', 'yes', 'a line'],
          ['[1,0,0], [0,1,0]', 'yes', 'a plane'],
          ['[1,0,0], [2,0,0]', 'no', 'still just a line'],
          ['[1,0,0], [0,1,0], [0,0,1]', 'yes', 'all of ℝ³'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Do [1, 2] and [2, 4] form a basis for ℝ²?',
        question:
            'You are handed [1, 2] and [2, 4] and told to use them as a basis for the plane. Will they work?',
        answer:
            'No. [2, 4] = 2·[1, 2] — the second is just the first, scaled. They are linearly dependent, so they only span a single line through the origin, not the whole plane. You cannot reach [1, 0] with them. A basis for ℝ² needs two genuinely different directions.',
      ),
    ],
  ),

  // ───────────────────────────────────────────────────────────────────────
  // 2 — Matrices as Linear Transformations
  // ───────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'linalg_matrices',
    scale: BioScale.infinities,
    position: 2,
    name: 'Matrices as Linear Transformations',
    title: 'a grid that moves space',
    moduleId: 'infinities_linear_algebra',
    shortDescription:
        'A matrix is not a spreadsheet — it is a function that stretches, rotates, and shears all of space at once while keeping the grid straight.',
    longDescription:
        'The big reframe of linear algebra: a matrix is a VERB. Multiply a matrix by a vector and the vector moves. The transformation is "linear" because it keeps grid lines straight and evenly spaced, and it pins the origin in place — no curving, no bending.\n\n'
        'The trick to reading any matrix: its COLUMNS tell you where the basis vectors land. The 2×2 matrix with columns [1, 0] and [0, 1] is the identity — it moves nothing. Change the columns and you have said exactly where î (the x-arrow) and ĵ (the y-arrow) go; every other point follows because it is a linear combination of those two. To transform [x, y], you compute x·(first column) + y·(second column). That is what "matrix times vector" means.',
    relatedIds: ['linalg_span', 'linalg_matmul', 'linalg_determinant'],
    sections: [
      LessonSection.fact(
        title: 'Read the columns',
        body:
            'A matrix\'s columns are the new homes of the basis vectors î and ĵ. Know where î and ĵ go, and you know where everything goes.',
      ),
      LessonSection.paragraph(
        title: 'Matrix × vector, worked',
        body:
            'Rotate 90° counter-clockwise sends î=[1,0] → [0,1] and ĵ=[0,1] → [−1,0], so the matrix has columns [0,1] and [−1,0]:  R = [[0, −1], [1, 0]].  Apply it to [3, 2]:  first row 0·3 + (−1)·2 = −2;  second row 1·3 + 0·2 = 3.  Result [−2, 3] — exactly [3, 2] rotated a quarter turn. Check it on paper: it works.',
      ),
      LessonSection.table(
        title: 'Famous 2×2 transformations',
        headers: ['Transformation', 'Matrix (rows)', 'What it does'],
        rows: [
          ['Identity', '[1,0] / [0,1]', 'leaves space untouched'],
          ['Scale ×2', '[2,0] / [0,2]', 'doubles every length'],
          ['Rotate 90° CCW', '[0,−1] / [1,0]', 'quarter turn'],
          ['Shear (x)', '[1,1] / [0,1]', 'slants the grid sideways'],
          ['Reflect over x-axis', '[1,0] / [0,−1]', 'flips top-to-bottom'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'What does the matrix [[3, 0], [0, 3]] do to a shape?',
        question:
            'You apply the matrix with rows [3, 0] and [0, 3] to a small square. What happens to it?',
        answer:
            'It scales the square by 3 in every direction — a 1×1 square becomes 3×3. î goes to [3, 0], ĵ goes to [0, 3], so both arrows triple. Uniform scaling, no rotation or shear. (Hold that "×3 in each direction" thought — it foreshadows the determinant becoming 9.)',
      ),
    ],
  ),

  // ───────────────────────────────────────────────────────────────────────
  // 3 — Matrix Multiplication & Composition
  // ───────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'linalg_matmul',
    scale: BioScale.infinities,
    position: 3,
    name: 'Matrix Multiplication & Composition',
    title: 'doing one transformation, then another',
    moduleId: 'infinities_linear_algebra',
    shortDescription:
        'Multiplying two matrices means "apply this transformation, then that one" — composition of functions, which is exactly why the order matters.',
    longDescription:
        'Matrix multiplication looks like an arbitrary rule of rows-times-columns, but it is really function composition. If B moves space one way and A moves it another, then the single matrix A·B does B FIRST, then A — read right to left, like nested functions f(g(x)).\n\n'
        'This is why matrix multiplication is NOT commutative: rotating then shearing is a different final grid than shearing then rotating. Each entry of the product is a dot product of a row of A with a column of B. It is also why an m×n matrix times an n×p matrix works only when the inner dimensions match — the output of one transformation must be a valid input to the next.',
    relatedIds: ['linalg_matrices', 'linalg_eigenvalues'],
    sections: [
      LessonSection.fact(
        title: 'A·B means "B first, then A"',
        body:
            'Matrix products compose right-to-left, like f(g(x)). The rightmost matrix touches the vector first.',
      ),
      LessonSection.paragraph(
        title: 'The rows-times-columns rule, worked',
        body:
            'Multiply A = [[1, 2], [3, 4]] by B = [[5, 6], [7, 8]]. Each entry is (row of A) · (column of B):\n'
            'top-left  = 1·5 + 2·7 = 19;  top-right = 1·6 + 2·8 = 22;\n'
            'bot-left  = 3·5 + 4·7 = 43;  bot-right = 3·6 + 4·8 = 50.\n'
            'So A·B = [[19, 22], [43, 50]]. Verify any entry by hand — the pattern is always "walk the row across the column."',
      ),
      LessonSection.table(
        title: 'When does A·B even exist?',
        headers: ['A size', 'B size', 'Product?', 'Result size'],
        rows: [
          ['2×3', '3×2', 'yes (inner 3 = 3)', '2×2'],
          ['2×3', '2×3', 'no (inner 3 ≠ 2)', '—'],
          ['3×3', '3×1', 'yes', '3×1 (a vector)'],
          ['1×n', 'n×1', 'yes', '1×1 (a number)'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Is A·B always equal to B·A?',
        question:
            'Let A = rotate 90° and B = reflect over the x-axis. Does applying them in the opposite order give the same result?',
        answer:
            'No — order matters. Reflect-then-rotate lands a point somewhere different than rotate-then-reflect. In numbers, [[0,−1],[1,0]]·[[1,0],[0,−1]] = [[0,1],[1,0]] but the reverse product is [[0,−1],[−1,0]] — different matrices. Matrix multiplication is generally NON-commutative because composing motions in a different order is a different motion.',
      ),
    ],
  ),

  // ───────────────────────────────────────────────────────────────────────
  // 4 — The Determinant
  // ───────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'linalg_determinant',
    scale: BioScale.infinities,
    position: 4,
    name: 'The Determinant',
    title: 'how much a matrix stretches space',
    moduleId: 'infinities_linear_algebra',
    shortDescription:
        'The determinant is a single number telling you the factor by which a transformation scales area (2D) or volume (3D) — and whether it flips space inside-out.',
    longDescription:
        'Every linear transformation stretches or squishes the space it acts on. The determinant measures that scaling with ONE number: a unit square of area 1 becomes a parallelogram of area |det|. If det = 3, areas triple; if det = 0.5, they halve; if det is negative, space has been flipped over (orientation reversed).\n\n'
        'The most important value is det = 0. It means the transformation collapses space onto a line or a point — area is annihilated, information is lost, and the matrix has NO inverse (you cannot un-squish a plane back from a line). For a 2×2 matrix [[a, b], [c, d]], the determinant is ad − bc. That tiny formula decides whether a system of equations has a unique solution.',
    relatedIds: ['linalg_matrices', 'linalg_dimension_rank', 'linalg_eigenvalues'],
    sections: [
      LessonSection.fact(
        title: 'det = 0 means space collapsed',
        body:
            'A zero determinant squashes area/volume to nothing. The matrix is not invertible — the transformation cannot be undone.',
      ),
      LessonSection.paragraph(
        title: 'The 2×2 formula, worked',
        body:
            'For [[a, b], [c, d]] the determinant is ad − bc. Take [[2, 1], [1, 3]]: det = 2·3 − 1·1 = 6 − 1 = 5. So this transformation multiplies every area by 5. Take the scaling matrix [[3, 0], [0, 3]] from the earlier entry: det = 3·3 − 0·0 = 9 — a ×3 stretch in each of 2 directions gives ×9 area. Exactly what we foreshadowed.',
      ),
      LessonSection.table(
        title: 'Reading the determinant',
        headers: ['det value', 'Geometric meaning', 'Invertible?'],
        rows: [
          ['> 1', 'space expands', 'yes'],
          ['= 1', 'area preserved (e.g. rotation)', 'yes'],
          ['0 < det < 1', 'space shrinks', 'yes'],
          ['= 0', 'collapses to line/point', 'NO'],
          ['< 0', 'flips orientation + scales', 'yes'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'What is det of [[2, 4], [1, 2]], and what does it tell you?',
        question:
            'Compute the determinant of [[2, 4], [1, 2]]. What does the answer say about solving equations with this matrix?',
        answer:
            'det = 2·2 − 4·1 = 4 − 4 = 0. The transformation collapses the plane onto a line (notice row 2 is half of row 1). Because det = 0 the matrix is singular — non-invertible — so a system Ax = b either has no solution or infinitely many, never a unique one.',
      ),
    ],
  ),

  // ───────────────────────────────────────────────────────────────────────
  // 5 — Eigenvalues & Eigenvectors
  // ───────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'linalg_eigenvalues',
    scale: BioScale.infinities,
    position: 5,
    name: 'Eigenvalues & Eigenvectors',
    title: 'the directions that refuse to turn',
    moduleId: 'infinities_linear_algebra',
    shortDescription:
        'An eigenvector is a direction a matrix leaves pointing the same way — it only gets stretched, by a factor called the eigenvalue (Av = λv).',
    longDescription:
        'Most vectors get knocked off their line when a matrix transforms them — they rotate and shift. But special directions survive: the transformation only stretches or shrinks them along their own line, never turning them. Those invariant directions are EIGENVECTORS, and the stretch factor for each is its EIGENVALUE λ. The defining equation is Av = λv: "matrix times vector equals just a number times that same vector."\n\n'
        'Eigenvectors are the skeleton of a transformation — the axes it is secretly built around. They power Google\'s original PageRank (the web\'s importance ranking is an eigenvector), the principal axes in machine learning (PCA), the stable vibration modes of bridges, and the energy states of quantum systems. Find a matrix\'s eigenvectors and you understand what it fundamentally does.',
    relatedIds: ['linalg_matrices', 'linalg_determinant', 'linalg_infinite_dim'],
    sections: [
      LessonSection.fact(
        title: 'The defining equation',
        body:
            'Av = λv.  The matrix A only STRETCHES the eigenvector v by the scalar λ — it never rotates it off its own line.',
      ),
      LessonSection.paragraph(
        title: 'A worked eigenpair',
        body:
            'Let A = [[2, 1], [1, 2]] and try v = [1, 1].  A·v: top row 2·1 + 1·1 = 3;  bottom row 1·1 + 2·1 = 3;  so A·v = [3, 3] = 3·[1, 1]. That is exactly λv with λ = 3 — [1, 1] is an eigenvector, eigenvalue 3.\n'
            'Now try v = [1, −1]:  top 2·1 + 1·(−1) = 1;  bottom 1·1 + 2·(−1) = −1;  so A·v = [1, −1] = 1·[1, −1]. A second eigenvector, eigenvalue 1. Both stayed on their own line — verified by hand.',
      ),
      LessonSection.table(
        title: 'Eigenvalue λ and what the direction does',
        headers: ['λ', 'Effect on the eigenvector'],
        rows: [
          ['λ > 1', 'stretched, same direction'],
          ['λ = 1', 'unchanged (a fixed direction)'],
          ['0 < λ < 1', 'shrunk toward origin'],
          ['λ = 0', 'crushed to the origin (matrix is singular)'],
          ['λ < 0', 'flipped to point the opposite way, and scaled'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'For [[3, 0], [0, 5]], what are the eigenvectors?',
        question:
            'A diagonal matrix [[3, 0], [0, 5]] stretches x by 3 and y by 5. Which directions come out unturned, and with what eigenvalues?',
        answer:
            'The x-axis [1, 0] → [3, 0] = 3·[1, 0], eigenvalue 3. The y-axis [0, 1] → [0, 5] = 5·[0, 1], eigenvalue 5. For any diagonal matrix, the coordinate axes are the eigenvectors and the diagonal entries ARE the eigenvalues — the cleanest possible case.',
      ),
    ],
  ),

  // ───────────────────────────────────────────────────────────────────────
  // 6 — Dimension & Rank
  // ───────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'linalg_dimension_rank',
    scale: BioScale.infinities,
    position: 6,
    name: 'Dimension & Rank',
    title: 'counting the directions that survive',
    moduleId: 'infinities_linear_algebra',
    shortDescription:
        'Dimension counts the independent directions in a space; rank counts how many survive a transformation — and the gap that dies is the nullity.',
    longDescription:
        'Dimension is the number of vectors in a basis — the count of truly independent directions a space contains. A line is 1D, a plane 2D, physical space 3D. RANK carries the same counting idea into transformations: it is the dimension of a matrix\'s output (its column space) — how many independent directions actually survive the mapping.\n\n'
        'When rank is less than the number of input dimensions, the transformation squashed something flat — and det = 0 (the collapse from the determinant entry is exactly a rank drop). The Rank–Nullity Theorem balances the books: rank + nullity = number of columns. The nullity counts the directions crushed to zero. Ranking, compression, and solvability of linear systems all come down to this one integer.',
    relatedIds: ['linalg_span', 'linalg_determinant', 'linalg_infinite_dim'],
    sections: [
      LessonSection.fact(
        title: 'Rank–Nullity Theorem',
        body:
            'rank + nullity = number of input columns.  Every direction is either preserved (rank) or crushed to zero (nullity). Nothing else.',
      ),
      LessonSection.paragraph(
        title: 'Full rank vs. rank-deficient',
        body:
            'A 2×2 matrix with rank 2 keeps the plane a plane — it is invertible and det ≠ 0. Drop to rank 1 and the plane is flattened onto a line: one direction was killed (nullity 1), so rank 1 + nullity 1 = 2 columns. The matrix [[1, 2], [2, 4]] from the determinant entry has rank 1 — row 2 is a copy of row 1 scaled, so only one independent direction survives.',
      ),
      LessonSection.table(
        title: 'A 2-input transformation, by rank',
        headers: ['Rank', 'Nullity', 'Output', 'det', 'Invertible?'],
        rows: [
          ['2', '0', 'full plane', '≠ 0', 'yes'],
          ['1', '1', 'a line', '= 0', 'no'],
          ['0', '2', 'a point (origin)', '= 0', 'no'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'A 3-column matrix has rank 2. What is its nullity?',
        question:
            'A transformation takes 3D input (3 columns) and its output is a 2D plane (rank 2). How many directions were crushed to zero?',
        answer:
            'Nullity = 1. By Rank–Nullity, rank + nullity = columns, so 2 + nullity = 3, giving nullity 1. One whole line of input vectors gets mapped to the origin — squashing 3D down onto a 2D plane sacrifices exactly one dimension.',
      ),
    ],
  ),

  // ───────────────────────────────────────────────────────────────────────
  // 7 — Infinite-Dimensional Spaces (the bridge back to infinity)
  // ───────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'linalg_infinite_dim',
    scale: BioScale.infinities,
    position: 7,
    name: 'Infinite-Dimensional Spaces',
    title: 'when a function is a vector',
    moduleId: 'infinities_linear_algebra',
    shortDescription:
        'Drop the requirement that a basis be finite and vectors become functions — infinite-dimensional Hilbert spaces are where linear algebra meets ∞.',
    longDescription:
        'Everything in this module needed only two moves: add and scale. Functions can be added and scaled too — so functions are vectors. The space of all continuous functions on an interval is a vector space, but no finite basis can reach every function; you need infinitely many building blocks. This is an INFINITE-DIMENSIONAL space, and it is the bridge from linear algebra straight back to the infinity scale.\n\n'
        'A Hilbert space adds a notion of length and angle (an inner product) to an infinite-dimensional space, so ideas like "perpendicular" and "projection" survive into infinity. The Fourier series is the headline: any periodic signal is an infinite linear combination of sine and cosine "basis vectors" — an eigenvector decomposition of the derivative operator. Quantum mechanics lives here entirely: a particle\'s state is a vector in an infinite-dimensional Hilbert space, and observable quantities are its eigenvalues. Linear algebra, followed to its limit, becomes the language of the infinite.',
    relatedIds: ['linalg_vectors', 'linalg_span', 'linalg_eigenvalues'],
    sections: [
      LessonSection.fact(
        title: 'A function is a vector with ∞ coordinates',
        body:
            'Sampling a function at every point is a coordinate list of infinite length. Add and scale still work — so the whole apparatus follows into ∞ dimensions.',
      ),
      LessonSection.paragraph(
        title: 'Fourier: an infinite basis',
        body:
            'The functions 1, cos(x), sin(x), cos(2x), sin(2x), … act as an infinite basis for periodic signals. Any such signal is Σ (coefficient · basis function) — the SAME "linear combination" verb from entry 1, now with infinitely many terms. Each basis function is even an eigenvector of the derivative operator, tying entry 5 to infinity.',
      ),
      LessonSection.table(
        title: 'Finite vs. infinite-dimensional',
        headers: ['Idea', 'Finite (ℝⁿ)', 'Infinite (Hilbert space)'],
        rows: [
          ['A vector', 'list of n numbers', 'a function'],
          ['Basis size', 'n (finite)', 'infinite (e.g. Fourier)'],
          ['Inner product', 'dot product Σ xᵢyᵢ', 'integral ∫ f·g dx'],
          ['Eigen-idea', 'Av = λv', 'operator eigenfunctions'],
          ['Where it lives', 'graphics, ML', 'quantum, signals'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why can no finite basis describe every function?',
        question:
            'In ℝ³, three vectors suffice for a basis. Why can\'t some finite number of functions be a basis for all continuous functions?',
        answer:
            'Because functions have infinitely many independent "directions." Given any finite set of functions, you can always build a new function (a higher-frequency wiggle, say) that is not any linear combination of them — it lies outside their span. No finite list ever spans the whole space, so its dimension is genuinely infinite. That is exactly why this module ends here, back at ∞.',
      ),
    ],
  ),
];
