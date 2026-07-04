// ============================================================================
// CODE TRIVIA — question bank (pure data, no Flutter imports).
//
// Content contract (see GAME.md):
//   • Every question is FACTUAL and UNAMBIGUOUS — one defensibly correct
//     answer, three wrong ones. No opinion questions, no "best language".
//   • History questions only where famous and uncontested (Guido, Linus,
//     Ritchie, Stroustrup, Eich, ~1995 for JS).
//   • Backtick-delimited fragments (`fun`, `git clone`) render in a monospace
//     stack in the game (see codeTriviaSpan in code_trivia_game.dart).
//   • tier 1 = broad basics · tier 2 = working-programmer facts · tier 3 =
//     deeper cuts with CLOSER distractors (same-category near-misses), so the
//     late round is hard because the wrong answers are plausible.
// ============================================================================

/// One trivia card: a [prompt] (may contain `code` spans in backticks), the
/// [correct] answer, exactly three plausible [distractors], a one-line [why]
/// (the in-context teach shown when the player misses), and a difficulty
/// [tier] 1–3 that drives escalation over the round.
class CodeTriviaQuestion {
  final String prompt;
  final String correct;
  final List<String> distractors;
  final String why;
  final int tier;

  const CodeTriviaQuestion({
    required this.prompt,
    required this.correct,
    required this.distractors,
    required this.why,
    required this.tier,
  });
}

/// The full bank — 67 questions across 3 tiers (22 / 22 / 23).
const List<CodeTriviaQuestion> kCodeTriviaBank = [
  // ── TIER 1 · broad basics ─────────────────────────────────────────────────
  CodeTriviaQuestion(
    prompt: 'Which language declares functions with `fun`?',
    correct: 'Kotlin',
    distractors: ['Swift', 'Go', 'Rust'],
    why: 'Kotlin uses `fun`; Swift and Go use `func`, Rust uses `fn`.',
    tier: 1,
  ),
  CodeTriviaQuestion(
    prompt: 'Which language runs natively in every web browser?',
    correct: 'JavaScript',
    distractors: ['Python', 'Java', 'C++'],
    why: 'Browsers ship a JavaScript engine — other languages must compile to JS or WebAssembly.',
    tier: 1,
  ),
  CodeTriviaQuestion(
    prompt: 'What does HTML stand for?',
    correct: 'HyperText Markup Language',
    distractors: [
      'HighText Machine Language',
      'HyperTransfer Markup Language',
      'HomeTool Markup Language'
    ],
    why: 'HyperText Markup Language — the markup that structures every web page.',
    tier: 1,
  ),
  CodeTriviaQuestion(
    prompt: 'What does CSS control on a web page?',
    correct: 'How it looks — style and layout',
    distractors: [
      'Server-side logic',
      'Database queries',
      'Network requests'
    ],
    why: 'Cascading Style Sheets describe presentation: colors, fonts, spacing, layout.',
    tier: 1,
  ),
  CodeTriviaQuestion(
    prompt: 'Which HTTP verb reads data without changing anything?',
    correct: 'GET',
    distractors: ['POST', 'DELETE', 'PUT'],
    why: 'GET is the safe, read-only verb — it must not modify server state.',
    tier: 1,
  ),
  CodeTriviaQuestion(
    prompt: 'Which HTTP verb sends new data to a server?',
    correct: 'POST',
    distractors: ['GET', 'HEAD', 'OPTIONS'],
    why: 'POST submits a new resource; GET only reads.',
    tier: 1,
  ),
  CodeTriviaQuestion(
    prompt: 'What does `git clone` do?',
    correct: 'Copies a remote repository to your machine',
    distractors: [
      'Deletes a remote repository',
      'Renames the current branch',
      'Uploads your commits to the server'
    ],
    why: '`git clone` downloads a full copy of a repo, history and all.',
    tier: 1,
  ),
  CodeTriviaQuestion(
    prompt: 'What does `git commit` do?',
    correct: 'Records a snapshot of your staged changes',
    distractors: [
      'Sends your changes to the remote',
      'Discards uncommitted changes',
      'Creates a new branch'
    ],
    why: '`git commit` saves the staged changes as a snapshot in local history — pushing is separate.',
    tier: 1,
  ),
  CodeTriviaQuestion(
    prompt: 'Which of these is a version control system?',
    correct: 'Git',
    distractors: ['Docker', 'npm', 'MySQL'],
    why: 'Git tracks code history; Docker runs containers, npm installs packages, MySQL stores data.',
    tier: 1,
  ),
  CodeTriviaQuestion(
    prompt: 'A comment in Python starts with which character?',
    correct: '`#`',
    distractors: ['`//`', '`/*`', '`--`'],
    why: 'Python comments start with `#`; `//` is C-family, `--` is SQL.',
    tier: 1,
  ),
  CodeTriviaQuestion(
    prompt: 'Python source files use which extension?',
    correct: '`.py`',
    distractors: ['`.pt`', '`.pyt`', '`.pn`'],
    why: 'Python files end in `.py`.',
    tier: 1,
  ),
  CodeTriviaQuestion(
    prompt: 'The Python language is named after…',
    correct: 'Monty Python, the comedy troupe',
    distractors: [
      'The python snake',
      'A Greek myth',
      "Its creator's pet"
    ],
    why: 'Guido van Rossum named it after Monty Python — not the snake.',
    tier: 1,
  ),
  CodeTriviaQuestion(
    prompt: 'What is an IDE?',
    correct: 'An app for writing and debugging code',
    distractors: [
      'A type of database',
      'A network protocol',
      'A compiled binary format'
    ],
    why: 'Integrated Development Environment — editor, debugger and tools in one app.',
    tier: 1,
  ),
  CodeTriviaQuestion(
    prompt: 'What does API stand for?',
    correct: 'Application Programming Interface',
    distractors: [
      'Automated Program Integration',
      'Applied Protocol Index',
      'Application Process Identifier'
    ],
    why: 'An API is the interface one program exposes for others to call.',
    tier: 1,
  ),
  CodeTriviaQuestion(
    prompt: 'A boolean can hold which values?',
    correct: 'true or false',
    distractors: [
      'Any whole number',
      'Any text string',
      '0 through 9'
    ],
    why: 'A boolean is binary logic: exactly true or false.',
    tier: 1,
  ),
  CodeTriviaQuestion(
    prompt: '`console.log("hi")` prints in which language?',
    correct: 'JavaScript',
    distractors: ['Python', 'C#', 'Ruby'],
    why: '`console.log` is the JavaScript print call; Python uses `print()`.',
    tier: 1,
  ),
  CodeTriviaQuestion(
    prompt: 'Which language prints with `println!` — exclamation mark included?',
    correct: 'Rust',
    distractors: ['Java', 'Kotlin', 'C'],
    why: 'In Rust, `println!` is a macro — the `!` marks macros.',
    tier: 1,
  ),
  CodeTriviaQuestion(
    prompt: 'Which company created the Java language?',
    correct: 'Sun Microsystems',
    distractors: ['Microsoft', 'IBM', 'Apple'],
    why: 'Java came out of Sun Microsystems in 1995; Oracle acquired Sun later.',
    tier: 1,
  ),
  CodeTriviaQuestion(
    prompt: 'Which language did Microsoft build for its .NET platform?',
    correct: 'C#',
    distractors: ['Swift', 'Kotlin', 'Ruby'],
    why: 'C# is Microsoft\'s flagship .NET language.',
    tier: 1,
  ),
  CodeTriviaQuestion(
    prompt: 'In programming, what is a "bug"?',
    correct: 'A flaw that makes a program misbehave',
    distractors: [
      'A hidden bonus feature',
      'A type of computer virus',
      'A hardware fan failure'
    ],
    why: 'A bug is a defect in the code — behavior that differs from what was intended.',
    tier: 1,
  ),
  CodeTriviaQuestion(
    prompt: "Python's built-in key→value collection is called a…",
    correct: 'dict',
    distractors: ['list', 'tuple', 'set'],
    why: 'A `dict` maps keys to values; lists and tuples are ordered sequences.',
    tier: 1,
  ),
  CodeTriviaQuestion(
    prompt: 'HTML tags are wrapped in which characters?',
    correct: 'Angle brackets `<` `>`',
    distractors: [
      'Curly braces `{` `}`',
      'Square brackets `[` `]`',
      'Parentheses `(` `)`'
    ],
    why: 'HTML elements are written in angle brackets: `<p>`, `<div>`, `<a>`.',
    tier: 1,
  ),

  // ── TIER 2 · working-programmer facts ─────────────────────────────────────
  CodeTriviaQuestion(
    prompt: 'What does TypeScript add to JavaScript?',
    correct: 'Static types',
    distractors: [
      'A faster runtime',
      'Built-in databases',
      'Native mobile compilation'
    ],
    why: 'TypeScript is JavaScript plus a static type system, checked at compile time.',
    tier: 2,
  ),
  CodeTriviaQuestion(
    prompt: 'TypeScript compiles down to…',
    correct: 'Plain JavaScript',
    distractors: ['Machine code', 'Java bytecode', 'WebAssembly'],
    why: 'The TypeScript compiler strips the types and emits ordinary JavaScript.',
    tier: 2,
  ),
  CodeTriviaQuestion(
    prompt: 'What does a linter do?',
    correct: 'Flags suspicious code without running it',
    distractors: [
      'Executes your test suite',
      'Compresses code for shipping',
      'Deploys code to production'
    ],
    why: 'A linter statically analyzes source for style problems and likely bugs.',
    tier: 2,
  ),
  CodeTriviaQuestion(
    prompt: 'What does a compiler do?',
    correct: 'Translates source code before it runs',
    distractors: [
      'Runs code one line at a time',
      'Formats code to a style guide',
      'Encrypts code for security'
    ],
    why: 'A compiler translates the whole program ahead of time into a runnable form.',
    tier: 2,
  ),
  CodeTriviaQuestion(
    prompt: 'What does an interpreter do?',
    correct: 'Executes source code directly as it reads it',
    distractors: [
      'Produces a native binary first',
      'Only checks types',
      'Converts code into documentation'
    ],
    why: 'An interpreter runs the source as it goes — no separate compile-to-binary step.',
    tier: 2,
  ),
  CodeTriviaQuestion(
    prompt: 'Which of these is typically interpreted, not compiled to a native binary?',
    correct: 'Python',
    distractors: ['Go', 'Rust', 'C'],
    why: 'CPython interprets bytecode at runtime; Go, Rust and C compile ahead of time to native code.',
    tier: 2,
  ),
  CodeTriviaQuestion(
    prompt: 'Who created the Python language?',
    correct: 'Guido van Rossum',
    distractors: ['James Gosling', 'Brendan Eich', 'Dennis Ritchie'],
    why: 'Guido van Rossum released Python in 1991; Gosling made Java, Eich made JavaScript.',
    tier: 2,
  ),
  CodeTriviaQuestion(
    prompt: 'Who created Linux?',
    correct: 'Linus Torvalds',
    distractors: ['Richard Stallman', 'Steve Wozniak', 'Ken Thompson'],
    why: 'Linus Torvalds started the Linux kernel in 1991 as a student project.',
    tier: 2,
  ),
  CodeTriviaQuestion(
    prompt: 'JavaScript first appeared around which year?',
    correct: '1995',
    distractors: ['1985', '2005', '2012'],
    why: 'JavaScript shipped in Netscape Navigator in 1995.',
    tier: 2,
  ),
  CodeTriviaQuestion(
    prompt: 'Which language uses indentation — significant whitespace — for code blocks?',
    correct: 'Python',
    distractors: ['JavaScript', 'C', 'Java'],
    why: 'Python blocks are defined by indentation; the C family uses curly braces.',
    tier: 2,
  ),
  CodeTriviaQuestion(
    prompt: 'Average-case big-O of a hash-map lookup by key?',
    correct: 'O(1)',
    distractors: ['O(n)', 'O(log n)', 'O(n²)'],
    why: 'Hashing jumps straight to the bucket — constant time on average.',
    tier: 2,
  ),
  CodeTriviaQuestion(
    prompt: 'Big-O of binary search on a sorted array?',
    correct: 'O(log n)',
    distractors: ['O(1)', 'O(n)', 'O(n log n)'],
    why: 'Each step halves the search space — logarithmic time.',
    tier: 2,
  ),
  CodeTriviaQuestion(
    prompt: 'Big-O of scanning an unsorted list for one value?',
    correct: 'O(n)',
    distractors: ['O(1)', 'O(log n)', 'O(n²)'],
    why: 'Worst case you check every element once — linear time.',
    tier: 2,
  ),
  CodeTriviaQuestion(
    prompt: 'What is a regex (regular expression) used for?',
    correct: 'Matching patterns in text',
    distractors: [
      'Scheduling background jobs',
      'Encrypting passwords',
      'Managing memory'
    ],
    why: 'A regex describes a text pattern — search, validate, extract, replace.',
    tier: 2,
  ),
  CodeTriviaQuestion(
    prompt: 'What does `git branch` enable?',
    correct: 'Parallel lines of development',
    distractors: [
      'Automatic code review',
      'Permanent deletion of history',
      'Compression of the repository'
    ],
    why: 'Branches let work proceed in parallel and merge back later.',
    tier: 2,
  ),
  CodeTriviaQuestion(
    prompt: 'HTTP status `404` means…',
    correct: 'Not Found',
    distractors: ['Forbidden', 'Server Error', 'Unauthorized'],
    why: '404 Not Found; 403 Forbidden, 401 Unauthorized, 500 Server Error.',
    tier: 2,
  ),
  CodeTriviaQuestion(
    prompt: 'HTTP status `500` means…',
    correct: 'Internal server error',
    distractors: [
      'Page moved permanently',
      'Request succeeded',
      'Too many requests'
    ],
    why: '5xx codes are server-side failures; 500 is the generic one.',
    tier: 2,
  ),
  CodeTriviaQuestion(
    prompt: 'Which HTTP verb removes a resource in a REST API?',
    correct: 'DELETE',
    distractors: ['GET', 'POST', 'PATCH'],
    why: 'DELETE is the removal verb; PATCH edits, POST creates, GET reads.',
    tier: 2,
  ),
  CodeTriviaQuestion(
    prompt: 'Kotlin primarily runs on which platform?',
    correct: 'The JVM',
    distractors: [
      'The browser only',
      'Bare metal, no runtime',
      'The .NET CLR'
    ],
    why: 'Kotlin compiles to JVM bytecode — that\'s why it slots into Android/Java stacks.',
    tier: 2,
  ),
  CodeTriviaQuestion(
    prompt: 'SQL is a language for…',
    correct: 'Querying relational databases',
    distractors: [
      'Styling web pages',
      'Writing operating systems',
      'Training neural networks'
    ],
    why: 'Structured Query Language: SELECT, INSERT, UPDATE, DELETE over tables.',
    tier: 2,
  ),
  CodeTriviaQuestion(
    prompt: 'What is recursion?',
    correct: 'A function that calls itself',
    distractors: [
      'A loop that never ends',
      'Two functions sharing memory',
      'Code that runs in parallel'
    ],
    why: 'Recursion solves a problem by calling itself on a smaller piece, until a base case.',
    tier: 2,
  ),
  CodeTriviaQuestion(
    prompt: "The Go language's mascot is a…",
    correct: 'Gopher',
    distractors: ['Crab', 'Elephant', 'Penguin'],
    why: 'Go has the gopher; Rust has Ferris the crab, Linux has Tux the penguin.',
    tier: 2,
  ),

  // ── TIER 3 · deeper cuts, closer distractors ──────────────────────────────
  CodeTriviaQuestion(
    prompt: 'Who created JavaScript — famously in about 10 days?',
    correct: 'Brendan Eich',
    distractors: ['Douglas Crockford', 'James Gosling', 'Anders Hejlsberg'],
    why: 'Brendan Eich built the first JavaScript at Netscape in 1995 in roughly 10 days.',
    tier: 3,
  ),
  CodeTriviaQuestion(
    prompt: 'Who created the C language?',
    correct: 'Dennis Ritchie',
    distractors: ['Ken Thompson', 'Bjarne Stroustrup', 'Brian Kernighan'],
    why: 'Dennis Ritchie created C at Bell Labs; Thompson co-built Unix, Kernighan co-wrote the book.',
    tier: 3,
  ),
  CodeTriviaQuestion(
    prompt: 'Who created C++?',
    correct: 'Bjarne Stroustrup',
    distractors: ['Dennis Ritchie', 'Anders Hejlsberg', 'Rob Pike'],
    why: 'Stroustrup grew C++ out of "C with Classes" at Bell Labs.',
    tier: 3,
  ),
  CodeTriviaQuestion(
    prompt: 'Who wrote the first version of Git?',
    correct: 'Linus Torvalds',
    distractors: ['Junio Hamano', 'Guido van Rossum', 'Tim Berners-Lee'],
    why: 'Torvalds wrote Git in 2005 for Linux kernel development; Hamano became its maintainer.',
    tier: 3,
  ),
  CodeTriviaQuestion(
    prompt: "What does Rust's borrow checker enforce?",
    correct: 'Memory-safety rules at compile time',
    distractors: [
      'Garbage collection at runtime',
      'Consistent code formatting',
      'Network request limits'
    ],
    why: 'The borrow checker proves ownership/borrowing rules before the program ever runs — no GC needed.',
    tier: 3,
  ),
  CodeTriviaQuestion(
    prompt: 'What does a JIT compiler do?',
    correct: 'Compiles hot code while the program runs',
    distractors: [
      'Compiles everything before shipping',
      'Interprets code without compiling',
      'Only checks types at runtime'
    ],
    why: 'Just-In-Time compilation translates frequently-run code to machine code at runtime for speed.',
    tier: 3,
  ),
  CodeTriviaQuestion(
    prompt: 'Big-O of accessing an array element by index?',
    correct: 'O(1)',
    distractors: ['O(log n)', 'O(n)', 'O(n log n)'],
    why: 'Arrays are contiguous — the address is computed directly, constant time.',
    tier: 3,
  ),
  CodeTriviaQuestion(
    prompt: 'Average-case big-O of quicksort?',
    correct: 'O(n log n)',
    distractors: ['O(n)', 'O(n²)', 'O(log n)'],
    why: 'Quicksort averages O(n log n); its rare worst case is O(n²).',
    tier: 3,
  ),
  CodeTriviaQuestion(
    prompt: 'Big-O of inserting at the head of a linked list?',
    correct: 'O(1)',
    distractors: ['O(n)', 'O(log n)', 'O(n log n)'],
    why: 'Just point the new node at the old head — no shifting, constant time.',
    tier: 3,
  ),
  CodeTriviaQuestion(
    prompt: 'Which of these grows FASTEST as n grows?',
    correct: 'O(2ⁿ)',
    distractors: ['O(n²)', 'O(n log n)', 'O(n)'],
    why: 'Exponential beats every polynomial — O(2ⁿ) explodes past O(n²) quickly.',
    tier: 3,
  ),
  CodeTriviaQuestion(
    prompt: 'Which HTTP verb is idempotent by spec?',
    correct: 'PUT',
    distractors: ['POST', 'Both PUT and POST', 'Neither'],
    why: 'Repeating a PUT gives the same result; repeating a POST can create duplicates.',
    tier: 3,
  ),
  CodeTriviaQuestion(
    prompt: 'What does `git rebase` do?',
    correct: 'Replays your commits onto a new base',
    distractors: [
      'Merges two branches with a merge commit',
      'Deletes commits from the remote',
      'Reverts the last commit safely'
    ],
    why: '`git rebase` rewrites history by replaying commits on top of another branch tip.',
    tier: 3,
  ),
  CodeTriviaQuestion(
    prompt: 'A fast-forward merge in Git does what?',
    correct: 'Moves the branch pointer — no merge commit',
    distractors: [
      'Creates an empty merge commit',
      'Squashes all commits into one',
      'Rebases then force-pushes'
    ],
    why: 'When the target is directly ahead, Git just advances the pointer — no new commit needed.',
    tier: 3,
  ),
  CodeTriviaQuestion(
    prompt: 'In SOLID, the L stands for…',
    correct: 'Liskov substitution',
    distractors: [
      'Layered separation',
      'Loose coupling',
      'Lazy initialization'
    ],
    why: 'Liskov Substitution Principle: subtypes must be usable anywhere their base type is.',
    tier: 3,
  ),
  CodeTriviaQuestion(
    prompt: 'In semantic versioning, bumping `2.4.1` to `3.0.0` signals…',
    correct: 'Breaking changes',
    distractors: [
      'Only bug fixes',
      'New backwards-compatible features',
      'A documentation update'
    ],
    why: 'SemVer: MAJOR = breaking, MINOR = compatible features, PATCH = fixes.',
    tier: 3,
  ),
  CodeTriviaQuestion(
    prompt: 'What is a race condition?',
    correct: 'Behavior that depends on thread timing',
    distractors: [
      'A loop that runs too fast',
      'Two functions with the same name',
      'A benchmark between algorithms'
    ],
    why: 'When concurrent code\'s outcome depends on who runs first, the result is unpredictable.',
    tier: 3,
  ),
  CodeTriviaQuestion(
    prompt: 'Which of these languages is dynamically typed?',
    correct: 'Python',
    distractors: ['Rust', 'Go', 'Java'],
    why: 'Python checks types at runtime; Rust, Go and Java check them at compile time.',
    tier: 3,
  ),
  CodeTriviaQuestion(
    prompt: 'Go — with goroutines for concurrency — was created at…',
    correct: 'Google',
    distractors: ['Facebook', 'Microsoft', 'Mozilla'],
    why: 'Go came out of Google (Pike, Thompson, Griesemer) in 2009.',
    tier: 3,
  ),
  CodeTriviaQuestion(
    prompt: 'Which keyword declares a function in Rust?',
    correct: '`fn`',
    distractors: ['`fun`', '`func`', '`def`'],
    why: 'Rust uses `fn`; Kotlin uses `fun`, Go/Swift use `func`, Python uses `def`.',
    tier: 3,
  ),
  CodeTriviaQuestion(
    prompt: 'Swift was created by which company?',
    correct: 'Apple',
    distractors: ['Google', 'JetBrains', 'Oracle'],
    why: 'Apple unveiled Swift in 2014 as the successor to Objective-C.',
    tier: 3,
  ),
  CodeTriviaQuestion(
    prompt: 'What is WebAssembly (Wasm)?',
    correct: 'A binary format browsers run near-natively',
    distractors: [
      'A JavaScript style framework',
      'A web server written in assembly',
      'A markup language for 3D scenes'
    ],
    why: 'Wasm is a portable binary format that lets languages like Rust and C++ run fast in the browser.',
    tier: 3,
  ),
  CodeTriviaQuestion(
    prompt: 'The HTTP verb `PATCH` is for…',
    correct: 'Partially updating a resource',
    distractors: [
      'Replacing a resource entirely',
      'Creating a new resource',
      'Fetching only the headers'
    ],
    why: 'PATCH edits part of a resource; PUT replaces the whole thing, HEAD fetches headers.',
    tier: 3,
  ),
  CodeTriviaQuestion(
    prompt: 'What does `git stash` do?',
    correct: 'Shelves uncommitted changes to restore later',
    distractors: [
      'Permanently deletes local changes',
      'Uploads changes to a hidden branch',
      'Compresses the repository history'
    ],
    why: '`git stash` tucks away your work-in-progress so you can come back to it — nothing is pushed.',
    tier: 3,
  ),
];
