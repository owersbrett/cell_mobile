import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Universe (All) → "The Story of the Universe" module.
/// The whole 13.8-billion-year history, in seven chronological chapters.
const List<BioEntity> universeStoryEntities = <BioEntity>[
  // ── 0 · THE BIG BANG ──────────────────────────────────────────────
  BioEntity(
    id: 'universe_story_big_bang',
    scale: BioScale.universeAll,
    position: 0,
    moduleId: 'universeAll_story',
    name: 'The Big Bang',
    title: 'The Hot Dense Beginning',
    shortDescription:
        'Everything that exists was once smaller, hotter, and denser than anything you can imagine — and then space itself began to stretch.',
    longDescription:
        'About 13.8 billion years ago the entire observable universe was packed into a state so hot and dense that atoms could not form. The Big Bang was not an explosion that hurled matter outward into empty space. It was the beginning of space itself — and every point in that space started expanding away from every other point at once.\n\n'
        'This is the single most misunderstood idea in all of science. There was no bang in a room. The room was the bang.',
    relatedIds: ['universe_story_inflation'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'Point in any direction. That direction was, once, a fraction of a millimetre from you — because the whole universe was that small, and space has been growing ever since. You are not sitting still while the universe expands around you. You ARE the universe, expanding.',
      ),
      LessonSection.thinkReveal(
        title: 'Where was the center of the Big Bang?',
        question:
            'If everything exploded from a single point, we should be able to point back toward that point. So — which direction is the center?',
        answer:
            'There is no center, and no direction points to one. The Big Bang did not happen AT a place in space; it happened TO all of space, everywhere at once. Every galaxy sees every other galaxy rushing away from it, so every observer feels like the center — which means none of them is. Imagine dots on a balloon being inflated: no dot is the center of the surface, yet all dots move apart.',
      ),
      LessonSection.fact(
        title: 'The Age of Everything',
        body: '13.8 billion years — the time since the Big Bang.',
      ),
      LessonSection.table(
        title: 'Two Ways to Picture It (One Is Wrong)',
        headers: ['Idea', 'Explosion in space (WRONG)', 'Expansion of space (RIGHT)'],
        rows: [
          ['What moved', 'Matter flew out through empty space', 'Space itself stretched, carrying matter'],
          ['Center', 'Yes — the blast point', 'None — expansion happens everywhere'],
          ['Edge', 'An outer shell of debris', 'No edge; there is no "outside"'],
          ['Your role', 'A bystander watching it', 'You are inside the expansion'],
        ],
      ),
      LessonSection.fact(
        title: 'The First Second',
        body:
            'Within the first second the universe cooled from unimaginable heat and forged the protons and neutrons that make every atom in your body.',
      ),
    ],
  ),

  // ── 1 · COSMIC INFLATION ──────────────────────────────────────────
  BioEntity(
    id: 'universe_story_inflation',
    scale: BioScale.universeAll,
    position: 1,
    moduleId: 'universeAll_story',
    name: 'Cosmic Inflation',
    title: 'The Split-Second Growth Spurt',
    shortDescription:
        'In a sliver of the first second, the universe doubled in size dozens of times over — smoothing the cosmos and seeding every galaxy that would ever form.',
    longDescription:
        'A tiny fraction of a second after the Big Bang — around 10⁻³² of a second in — the universe underwent inflation: a burst of exponential expansion that ballooned a region smaller than an atom to larger than a grapefruit almost instantly.\n\n'
        'Inflation solves two deep puzzles: why the universe looks so uniform in every direction, and why space is so remarkably flat. It also stretched microscopic quantum ripples up to cosmic size — and those ripples became the scaffolding for galaxies.',
    relatedIds: ['universe_story_big_bang', 'universe_story_first_light'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'The largest structures in the universe — the great cosmic webs of galaxies — began as quantum jitters smaller than a proton. Inflation blew those jitters up to astronomical scale and froze them into the fabric of space. The map of the cosmos is a photograph of the quantum world, enlarged beyond all reason.',
      ),
      LessonSection.thinkReveal(
        title: 'Why does the whole sky have the same temperature?',
        question:
            'Opposite sides of the sky look identical in temperature, yet they are so far apart that light has never had time to travel between them. How can two places that have never "talked" agree?',
        answer:
            'Because they were once close enough to talk. Before inflation, those regions were in tiny contact and reached the same temperature. Inflation then flung them enormously far apart in an instant. Their sameness is a fossil of a moment when the whole universe was small enough to even out.',
      ),
      LessonSection.table(
        title: 'What Inflation Explains',
        headers: ['Puzzle', 'Question', 'Inflation\'s answer'],
        rows: [
          ['Horizon', 'Why is distant sky so uniform?', 'It was in contact, then stretched apart'],
          ['Flatness', 'Why is space so precisely flat?', 'Huge expansion irons out any curvature'],
          ['Structure', 'Where did galaxies\' seeds come from?', 'Quantum ripples stretched to cosmic size'],
        ],
      ),
      LessonSection.fact(
        title: 'The Timescale',
        body:
            'Inflation is thought to have ended by about 10⁻³² of a second — a hundred-billion-trillion-trillionth of a second.',
      ),
      LessonSection.fact(
        title: 'The Growth',
        body:
            'In that instant space may have expanded by a factor of 10²⁶ or more — a length shorter than an atom stretched larger than a solar system.',
      ),
    ],
  ),

  // ── 2 · THE FIRST LIGHT (CMB) ─────────────────────────────────────
  BioEntity(
    id: 'universe_story_first_light',
    scale: BioScale.universeAll,
    position: 2,
    moduleId: 'universeAll_story',
    name: 'The First Light',
    title: 'The Afterglow of Creation',
    shortDescription:
        'About 380,000 years in, the universe cooled enough for atoms to form and light to travel freely — a flash we still detect today as the Cosmic Microwave Background.',
    longDescription:
        'For its first 380,000 years the universe was an opaque fog of charged particles; light bounced endlessly and could not travel far. Then it cooled to about 3,000 K and electrons joined nuclei to make the first neutral atoms — an event called recombination. Suddenly light streamed freely across space.\n\n'
        'That ancient light is still arriving. Stretched by billions of years of expansion, it now glows faintly at just 2.7 K — the Cosmic Microwave Background, the oldest light we can ever see. Accidentally discovered by Penzias and Wilson in 1965, it is a baby picture of the cosmos.',
    relatedIds: ['universe_story_inflation', 'universe_story_dark_ages'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'Static on an old untuned TV was partly this: a whisper of the newborn universe hitting the antenna. The oldest light in existence, released before there were stars, planets, or people, is passing through your body right now.',
      ),
      LessonSection.thinkReveal(
        title: 'Why can\'t we see anything older than the CMB?',
        question:
            'Telescopes see farther and farther back in time. Why does the view hit a wall at 380,000 years — why can\'t we see the Big Bang itself?',
        answer:
            'Before recombination, the universe was an opaque plasma fog — light could not travel, so there is nothing to see. The CMB is the moment the fog cleared, the earliest instant light escaped. It is a literal wall of light, the "surface of last scattering," beyond which the universe is opaque to all telescopes.',
      ),
      LessonSection.fact(
        title: 'Recombination',
        body:
            'The universe first became transparent about 380,000 years after the Big Bang.',
      ),
      LessonSection.table(
        title: 'The Cooling of the First Light',
        headers: ['When', 'Temperature', 'What the light is'],
        rows: [
          ['At recombination', '~3,000 K', 'Visible/infrared glow, released'],
          ['Today (13.8 Gyr later)', '~2.7 K', 'Microwaves — the CMB'],
          ['Cause of the drop', 'Expansion stretched the waves', 'Redshift by ~1,100×'],
        ],
      ),
      LessonSection.fact(
        title: 'The Accidental Nobel',
        body:
            'Penzias & Wilson found the CMB in 1965 as unexplained "noise" in a radio antenna — and won the 1978 Nobel Prize for it.',
      ),
    ],
  ),

  // ── 3 · COSMIC DARK AGES & FIRST STARS ────────────────────────────
  BioEntity(
    id: 'universe_story_dark_ages',
    scale: BioScale.universeAll,
    position: 3,
    moduleId: 'universeAll_story',
    name: 'The Dark Ages & First Stars',
    title: 'Gravity Lights the Lamps',
    shortDescription:
        'After the first light faded, darkness fell for millions of years — until gravity pulled gas into the very first stars and switched the lights back on.',
    longDescription:
        'Once the CMB faded, the universe went dark. There were no stars, no galaxies — only expanding clouds of hydrogen and helium drifting through blackness. This is the Cosmic Dark Ages.\n\n'
        'But gravity was quietly at work in the ripples inflation had seeded. Denser patches pulled in more gas, collapsing over roughly 100–400 million years until the first stars ignited. These first stars were giants — massive, brilliant, and short-lived — and inside them the universe forged its first heavy elements before they exploded and scattered them across space.',
    relatedIds: ['universe_story_first_light', 'universe_story_galaxies'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'For millions of years there was not a single star anywhere in the universe — pure darkness, wall to wall. Then gravity found the faintest lumps in the fog and squeezed them, and squeezed, until the first star flared into being. Every atom heavier than helium in your bones was cooked inside a star. You are, quite literally, the ash of the first fires.',
      ),
      LessonSection.thinkReveal(
        title: 'Where did carbon, oxygen, and iron come from?',
        question:
            'The Big Bang made almost only hydrogen and helium. So where did the calcium in your teeth or the iron in your blood come from?',
        answer:
            'From stars. Stars fuse light elements into heavier ones in their cores, and when massive stars die and explode, they forge and fling out carbon, oxygen, iron, and beyond. Every heavy atom in you was manufactured inside a star that lived and died before the Sun existed. "We are made of star-stuff" is not poetry — it is nuclear physics.',
      ),
      LessonSection.fact(
        title: 'First Starlight',
        body:
            'The first stars are thought to have ignited roughly 100–400 million years after the Big Bang.',
      ),
      LessonSection.table(
        title: 'The First Stars vs. the Sun',
        headers: ['Trait', 'First stars', 'Our Sun'],
        rows: [
          ['Made from', 'Only hydrogen & helium', 'Enriched with heavy elements'],
          ['Mass', 'Often tens–hundreds × the Sun', '1 solar mass'],
          ['Lifespan', 'A few million years', '~10 billion years'],
          ['Their legacy', 'Seeded space with heavy elements', 'Warms life on Earth'],
        ],
      ),
      LessonSection.fact(
        title: 'The Job of Gravity',
        body:
            'Every star, galaxy, and planet exists because gravity amplified the faint density ripples inflation stretched across the sky.',
      ),
    ],
  ),

  // ── 4 · GALAXIES & COSMIC NOON ────────────────────────────────────
  BioEntity(
    id: 'universe_story_galaxies',
    scale: BioScale.universeAll,
    position: 4,
    moduleId: 'universeAll_story',
    name: 'Galaxies & Cosmic Noon',
    title: 'The Universe at Full Bloom',
    shortDescription:
        'Stars gathered into galaxies, galaxies merged and grew, and around 10 billion years ago the cosmos hit its peak of star formation — cosmic noon.',
    longDescription:
        'Gravity kept pulling. The first stars clustered, small galaxies collided and merged into larger ones, and grand spirals and ellipticals took shape. At the heart of most galaxies, supermassive black holes grew alongside them.\n\n'
        'Around 10 billion years ago — roughly 3–4 billion years after the Big Bang — the universe was building stars faster than ever before or since. Astronomers call this era "cosmic noon." Our own Sun and Earth would not form until much later, about 4.6 billion years ago, from the enriched debris of earlier stellar generations.',
    relatedIds: ['universe_story_dark_ages', 'universe_story_dark_energy'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'The night sky you see is a museum in its quiet years. Ten billion years ago the universe blazed — forming stars ten times faster than today, galaxies crashing and merging in a frenzy of light. We live in the calm, late afternoon of the cosmos, long after its brightest hour.',
      ),
      LessonSection.thinkReveal(
        title: 'Is the universe still building stars as fast as ever?',
        question:
            'Galaxies are full of gas and gravity never quits — so is star formation still accelerating today?',
        answer:
            'No. Star formation peaked at "cosmic noon" about 10 billion years ago and has been declining ever since. The universe has used up and spread out much of its dense, cold gas, so today it makes stars far more slowly. We are past the peak — the great bloom is behind us.',
      ),
      LessonSection.fact(
        title: 'Cosmic Noon',
        body:
            'Peak star formation occurred ~10 billion years ago, about 3–4 billion years after the Big Bang.',
      ),
      LessonSection.table(
        title: 'A Timeline of Assembly',
        headers: ['Time after Big Bang', 'Milestone'],
        rows: [
          ['~0.1–0.4 Gyr', 'First stars ignite'],
          ['~0.5–1 Gyr', 'First galaxies assemble'],
          ['~3–4 Gyr', 'Cosmic noon — peak star formation'],
          ['~9.2 Gyr', 'The Sun and Earth form (4.6 Gyr ago)'],
        ],
      ),
      LessonSection.fact(
        title: 'Our Home Galaxy',
        body:
            'The Milky Way holds an estimated 100–400 billion stars — one of perhaps 2 trillion galaxies in the observable universe.',
      ),
    ],
  ),

  // ── 5 · THE EXPANDING UNIVERSE & DARK ENERGY ──────────────────────
  BioEntity(
    id: 'universe_story_dark_energy',
    scale: BioScale.universeAll,
    position: 5,
    moduleId: 'universeAll_story',
    name: 'Expansion & Dark Energy',
    title: 'The Cosmos Hits the Gas',
    shortDescription:
        'Every galaxy is rushing away from every other — and in 1998 astronomers discovered that this expansion is not slowing down but speeding up.',
    longDescription:
        'In the 1920s Edwin Hubble found that distant galaxies are receding, and the farther they are, the faster they go: the universe is expanding. For decades everyone assumed gravity would gradually slow that expansion.\n\n'
        'Then in 1998 two teams measuring distant supernovae found the opposite — the expansion is accelerating. Some unknown energy woven into empty space is pushing the cosmos apart ever faster. We call it dark energy, and it makes up about 68% of the universe. The discovery won the 2011 Nobel Prize in Physics.',
    relatedIds: ['universe_story_galaxies', 'universe_story_observable'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'Nearly 7 out of every 10 units of "stuff" in the universe is something we cannot see, cannot touch, and barely understand — a hidden pressure in empty space, driving the cosmos apart faster and faster. The single largest ingredient of reality is a mystery with a name and almost nothing else.',
      ),
      LessonSection.thinkReveal(
        title: 'Is cosmic expansion slowing down or speeding up?',
        question:
            'Gravity pulls everything together. So surely the expansion of the universe must be gradually braking to a stop?',
        answer:
            'Astonishingly, no. In 1998, supernova surveys revealed the expansion is ACCELERATING. A repulsive dark energy is overpowering gravity on the largest scales. Left unchecked, it means distant galaxies will one day recede so fast their light can never reach us again.',
      ),
      LessonSection.fact(
        title: 'The Missing Majority',
        body: 'Dark energy makes up about 68% of the universe.',
      ),
      LessonSection.table(
        title: 'What the Universe Is Made Of',
        headers: ['Ingredient', 'Share', 'What it does'],
        rows: [
          ['Dark energy', '~68%', 'Accelerates the expansion'],
          ['Dark matter', '~27%', 'Invisible gravity that holds galaxies together'],
          ['Ordinary matter', '~5%', 'Stars, planets, gas, you'],
        ],
      ),
      LessonSection.fact(
        title: 'The 1998 Discovery',
        body:
            'Accelerating expansion was found in 1998 using distant supernovae — earning the 2011 Nobel Prize in Physics.',
      ),
    ],
  ),

  // ── 6 · THE OBSERVABLE UNIVERSE ───────────────────────────────────
  BioEntity(
    id: 'universe_story_observable',
    scale: BioScale.universeAll,
    position: 6,
    moduleId: 'universeAll_story',
    name: 'The Observable Universe',
    title: 'The Edge of What We Can See',
    shortDescription:
        'The universe is 13.8 billion years old, yet we can see objects ~46 billion light-years away — because space kept stretching while the light traveled.',
    longDescription:
        'We can only see light that has had time to reach us since the universe became transparent. That gives us a finite bubble — the observable universe — with us at its center simply because we do the observing. Every observer, everywhere, sits at the center of their own bubble.\n\n'
        'Here is the twist: although the universe is 13.8 billion years old, the observable universe is about 93 billion light-years across (about 46 billion light-years in radius). The objects that sent us their ancient light have been carried much farther away by expansion in the meantime. And beyond our horizon, the universe almost certainly continues — perhaps forever.',
    relatedIds: ['universe_story_dark_energy', 'universe_story_big_bang'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'Look up in any direction and you hit the same wall of first light, the same distance away. You appear to be at the exact center of the universe — and so does every alien on every world in every galaxy. The "observable universe" is not the whole universe. It is just the part whose light has had time to find you.',
      ),
      LessonSection.thinkReveal(
        title: 'How can we see 46 billion light-years in a 13.8-billion-year-old universe?',
        question:
            'If light travels one light-year per year, then in 13.8 billion years it can only cross 13.8 billion light-years. So how can the farthest things be 46 billion light-years away?',
        answer:
            'Because space itself expanded WHILE the light was traveling. The light set out long ago from objects that were then close by; over billions of years, expansion stretched the space in between, carrying those objects to ~46 billion light-years away today. Distance in an expanding universe is not simply speed × time — the road itself grows under the traveler\'s feet.',
      ),
      LessonSection.fact(
        title: 'The Size of the View',
        body:
            'The observable universe is about 93 billion light-years across — roughly 46 billion light-years in every direction.',
      ),
      LessonSection.table(
        title: 'Observable vs. the Whole Universe',
        headers: ['Question', 'Observable universe', 'The whole universe'],
        rows: [
          ['How big?', '~93 billion ly across', 'Unknown — possibly infinite'],
          ['Does it have an edge?', 'A horizon, not a wall', 'No known edge'],
          ['Where is the center?', 'Wherever you observe from', 'No center at all'],
          ['Can we ever see it all?', 'No — light beyond the horizon can\'t reach us', 'We only ever see our bubble'],
        ],
      ),
      LessonSection.fact(
        title: 'The Cosmic Horizon',
        body:
            'Because expansion is accelerating, some galaxies we see today will eventually vanish beyond our horizon forever — their light stretched away faster than it can reach us.',
      ),
    ],
  ),
];
