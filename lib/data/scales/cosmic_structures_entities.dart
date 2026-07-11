import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

const cosmicStructuresEntities = <BioEntity>[
  BioEntity(
    id: 'cosmic_web',
    scale: BioScale.cosmicStructures,
    position: 0,
    name: 'The Cosmic Web',
    title: 'The Universe\'s Skeleton',
    shortDescription: 'Galaxies are not scattered randomly — they trace a vast web of filaments and nodes surrounding empty voids, a structure imprinted by quantum fluctuations in the infant universe.',
    longDescription:
        'The cosmic web is the largest known structure in the universe — a network of galaxy filaments, walls, and nodes surrounding enormous empty voids, stretching across the entire observable universe. Seen all at once, the galaxies trace a pattern strikingly similar to a neural network or a slice of living tissue: dense nodes connected by thin strands, with vast empty spaces between. The resemblance is not decoration — both patterns emerge when something grows by pulling material toward its densest points.\n\n'
        'The web began as tiny quantum fluctuations in the density of matter in the early universe — ripples of roughly one part in 100,000. Over ~13.8 billion years, gravity amplified them: slightly denser regions attracted more matter and grew denser still, while underdense regions emptied out. Today, matter flows along the filaments toward the nodes like water along river channels, and computer simulations grown from those same initial ripples reproduce the observed web with remarkable fidelity.',
    relatedIds: ['cosmic_filaments', 'cosmic_voids', 'cosmic_cmb', 'clusters_virgo'],
    sections: [
      LessonSection.fact(
        title: 'The seed of everything',
        body: 'Density ripples of ~1 part in 100,000 in the infant universe grew, under gravity alone, into every galaxy, star, and planet that exists.',
      ),
      LessonSection.table(
        title: 'Anatomy of the web',
        headers: ['Component', 'What it is', 'Rough share of the universe'],
        rows: [
          ['Nodes (clusters)', 'Densest knots where filaments meet; home to giant elliptical galaxies', 'Tiny fraction of volume, largest single bound objects'],
          ['Filaments', 'Threads of dark matter, gas, and galaxies connecting the nodes', 'Most galaxies live in or near them'],
          ['Walls / sheets', 'Flattened panes of galaxies forming the faces between voids', 'Intermediate density'],
          ['Voids', 'Vast underdense bubbles being stretched empty by expansion', '~80% of the volume, ~10% of the galaxies'],
        ],
      ),
      LessonSection.table(
        title: 'How structure grew',
        headers: ['Epoch', 'When (after Big Bang)', 'What happened'],
        rows: [
          ['Inflation', 'First tiny fraction of a second', 'Quantum fluctuations stretched to cosmic size — the blueprint is drawn'],
          ['Recombination', '~380,000 years', 'The universe turns transparent; the blueprint is photographed as the CMB'],
          ['Dark ages', '~380,000 yr to ~200 million yr', 'No stars yet; dark matter quietly collapses into a skeleton of halos and threads'],
          ['First stars & galaxies', '~200-500 million yr', 'Gas falls into the dark matter scaffold and ignites'],
          ['Web maturity', 'Billions of years onward', 'Filaments feed clusters; voids expand; dark energy begins to slow the assembly'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why a web?',
        question: 'Gravity pulls equally in all directions. So why did matter organize into threads and sheets instead of collapsing into evenly spaced blobs?',
        answer: 'Because collapse is fastest along the shortest axis. A slightly overdense lump of matter is never perfectly spherical, so it collapses along one axis first — flattening into a sheet — then along a second axis, contracting into a filament, and only finally along the third, gathering into a node. Sheets, threads, and knots are the three stages of the same collapse, frozen at different points. The web is what anisotropic gravitational collapse looks like at full scale.',
      ),
      LessonSection.thinkReveal(
        title: 'The neural-network resemblance',
        question: 'Images of the cosmic web look uncannily like images of neurons in a brain. Meaningful physics, or coincidence?',
        answer: 'Mostly convergence, not kinship. Both are transport networks shaped by an optimization pressure: neurons grow connections to move signals efficiently, and matter flows along the paths of steepest gravitational descent. Networks built by flow tend to look alike — river deltas, lightning, blood vessels, and filaments share the branching logic. The physics differs completely; the geometry of "stuff flowing toward concentrations" does not. In a potato-cell universe, it is at least a satisfying rhyme.',
      ),
      LessonSection.thinkReveal(
        title: 'The web\'s future',
        question: 'Dark energy is accelerating the expansion of space. What does that do to the cosmic web over the next hundred billion years?',
        answer: 'It freezes the web and then dissolves its long-range connections. Structures already gravitationally bound — clusters and their immediate surroundings — stay bound. But the filaments between them stretch faster than matter can flow along them, so the highways snap. Each supercluster region becomes an island universe, and the web stops growing. The pattern we see today is close to the largest it will ever meaningfully be.',
      ),
      LessonSection.paragraph(
        title: 'The dark scaffold',
        body: 'The web you can photograph — galaxies and glowing gas — is the minority. Roughly five-sixths of the matter is dark matter, which collapsed first and built the gravitational scaffold; ordinary matter then rained into channels that were already carved. Simulations like Millennium and IllustrisTNG start from CMB-measured ripples, evolve dark matter forward, and recover the observed web in statistical detail — one of the strongest confirmations that the dark-matter picture is right.',
      ),
    ],
  ),
  BioEntity(
    id: 'cosmic_filaments',
    scale: BioScale.cosmicStructures,
    position: 1,
    name: 'Filaments',
    title: 'Threads of Creation',
    shortDescription: 'The longest structures in the known universe — galaxy filaments stretch for hundreds of millions of light-years, channeling matter from voids toward cluster nodes.',
    longDescription:
        'Galaxy filaments are the threads of the cosmic web, typically stretching ~150-250 million light-years in length and ~10-30 million light-years in width. They form where the walls of neighboring voids press together: matter draining out of two or more underdense regions gets funneled into the seam between them, and the seam becomes a channel. Dark matter provides the gravitational skeleton; gas and galaxies trace it.\n\n'
        'The gas inside filaments, compressed and shock-heated to ~100,000 to ~10,000,000 Kelvin, forms the warm-hot intergalactic medium (WHIM) — thin, nearly invisible, and yet believed to hold a large share of all ordinary matter in the universe. Filaments are highways: galaxies travel along them, merge along them, and are ultimately delivered by them into cluster nodes. Predicted by simulations before they were mapped, they were confirmed as surveys like SDSS charted millions of galaxy positions in three dimensions.',
    relatedIds: ['cosmic_web', 'cosmic_voids', 'clusters_virgo'],
    sections: [
      LessonSection.fact(
        title: 'The largest known structure',
        body: 'The Hercules-Corona Borealis Great Wall spans ~10 billion light-years — roughly a tenth of the observable universe in a single claimed structure.',
      ),
      LessonSection.table(
        title: 'A ladder of giant structures',
        headers: ['Structure', 'Approx. extent', 'Claim to fame'],
        rows: [
          ['Typical filament', '~150-250 million ly', 'The workhorse thread of the web'],
          ['CfA2 Great Wall', '~500-750 million ly', 'One of the first mapped giants (1989)'],
          ['Laniakea Supercluster', '~520 million ly', 'The flow basin our own galaxy belongs to'],
          ['Sloan Great Wall', '~1.4 billion ly', 'Mapped by SDSS in 2003'],
          ['South Pole Wall', '~1.4 billion ly', 'Found in 2020, partly hidden behind our own galaxy'],
          ['Hercules-Corona Borealis Great Wall', '~10 billion ly', 'So large it strains the cosmological principle'],
        ],
      ),
      LessonSection.table(
        title: 'What a filament is made of',
        headers: ['Ingredient', 'State', 'Role'],
        rows: [
          ['Dark matter', 'Cold, invisible, dominant by mass', 'The gravitational skeleton everything else follows'],
          ['WHIM gas', 'Diffuse plasma at ~10⁵-10⁷ K', 'Believed to hold roughly half of all ordinary matter'],
          ['Galaxies', 'Embedded travelers', 'Flow along the thread toward cluster nodes'],
          ['Magnetic fields', 'Extremely weak, threading the gas', 'Detected via faint radio emission between clusters'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why the seams?',
        question: 'Why do filaments form precisely where the walls of two voids meet, rather than anywhere else?',
        answer: 'Because a void is an evacuation in progress. Matter drains outward from each underdense region toward its edges. Where two voids adjoin, their outflows collide and have nowhere to go but sideways — along the seam. The seam therefore accumulates matter from both sides and becomes a channel of flow toward the nearest node. Filaments are not built where matter is; they are built where escaping matter is forced to converge.',
      ),
      LessonSection.thinkReveal(
        title: 'The missing baryons',
        question: 'For decades, astronomers could only find about half of the ordinary (baryonic) matter the Big Bang should have produced. Where was the rest hiding?',
        answer: 'In the filaments — as the WHIM. Gas at ~10⁵-10⁷ K is too hot to absorb visible light and too thin to shine brightly in X-rays, so it is nearly invisible. It took indirect probes — fast radio bursts dispersing as they crossed the gas, and stacked X-ray and Sunyaev-Zel\'dovich signals between cluster pairs — to weigh it. The census now roughly closes: the missing atoms were strung along the web the whole time.',
      ),
      LessonSection.thinkReveal(
        title: 'Too big to exist?',
        question: 'Why would a single ~10-billion-light-year structure trouble cosmologists, when the universe itself is far bigger?',
        answer: 'Because the standard model of cosmology rests on the cosmological principle: at large enough scales, the universe should be homogeneous — statistically the same everywhere. Structures are expected to top out around ~1-2 billion light-years. Something ~10 billion light-years across, if it is truly one connected structure and not a chance alignment of gamma-ray bursts (which is still debated), would mean "large enough" scales are larger than the theory comfortably allows. It is either a statistical fluke or a genuine crack worth watching.',
      ),
      LessonSection.paragraph(
        title: 'Galaxies remember their highway',
        body: 'Filaments leave fingerprints on their travelers. Galaxy spins show measurable alignment with the filament they inhabit — lighter galaxies tend to spin along the thread, heavier ones (built by mergers along it) tend to spin across it. A galaxy\'s environment on the web is one of the strongest predictors of its fate: filament galaxies are pre-processed — their gas gets stripped and their star formation throttled — before they ever fall into a cluster.',
      ),
    ],
  ),
  BioEntity(
    id: 'cosmic_voids',
    scale: BioScale.cosmicStructures,
    position: 2,
    name: 'Cosmic Voids',
    title: 'The Great Emptinesses',
    shortDescription: 'Vast regions of space containing almost nothing — some voids span hundreds of millions of light-years, making them the largest individual features of the universe by volume.',
    longDescription:
        'Cosmic voids are the dominant feature of the universe by volume: they fill roughly 80% of the observable universe yet hold only about 10% of its galaxies. They are not truly empty — a sparse population of galaxies, gas, and dark matter remains, typically at ~10-20% of average cosmic density, along with faint filamentary substructure like the last strands of a web being pulled apart.\n\n'
        'Voids are the complement of filaments: as gravity drained matter from underdense regions into denser ones, the underdense regions expanded and emptied. Dark energy accelerates the process, making voids grow faster than they would in a matter-only universe — which turns these emptinesses into sensitive probes of the physics driving cosmic expansion. The nothing between somethings, once again, carries profound meaning.',
    relatedIds: ['cosmic_web', 'cosmic_filaments', 'cosmic_cmb', 'nothing_void'],
    sections: [
      LessonSection.fact(
        title: 'The universe is mostly gap',
        body: 'Voids occupy ~80% of the volume of the observable universe but contain only ~10% of its galaxies.',
      ),
      LessonSection.table(
        title: 'Notable voids',
        headers: ['Void', 'Approx. diameter', 'Why it matters'],
        rows: [
          ['Local Void', '~150-250 million ly', 'Right next door — it borders our own galactic neighborhood'],
          ['Boötes Void', '~330 million ly', 'The famous "Great Nothing"; only ~60 galaxies found where thousands were expected'],
          ['Giant Void (in Canes Venatici)', '~1-1.3 billion ly', 'One of the largest confirmed underdensities'],
          ['KBC Void ("Local Hole")', '~2 billion ly', 'We may sit inside it — a possible player in the Hubble tension'],
        ],
      ),
      LessonSection.table(
        title: 'Void galaxies vs. cluster galaxies',
        headers: ['Property', 'In voids', 'In clusters'],
        rows: [
          ['Typical size', 'Small', 'Includes the largest giants'],
          ['Color', 'Bluer (young stars)', 'Redder (old stars)'],
          ['Star formation', 'Active, ongoing', 'Largely quenched'],
          ['Merger history', 'Quiet, few interactions', 'Violent, merger-built'],
          ['Gas supply', 'Retained', 'Stripped by the hot cluster medium'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Studying nothing to measure everything',
        question: 'If voids are nearly empty, why are they among the best tools cosmologists have for probing dark energy?',
        answer: 'Because emptiness is clean. Inside clusters, gravity is a mess of nonlinear collapse, gas physics, and feedback. Inside voids, matter is sparse and the dynamics stay simple — expansion nearly wins outright. That makes void sizes, shapes, and growth rates directly sensitive to the tug-of-war between gravity and dark energy, with little astrophysical noise on top. If dark energy pushed even slightly differently, void statistics would shift measurably. The gaps are the least contaminated experiment the universe offers.',
      ),
      LessonSection.thinkReveal(
        title: 'Living in a hole',
        question: 'Suppose we really do live inside the ~2-billion-light-year KBC underdensity. Which famous cosmological measurement could that quietly distort, and how?',
        answer: 'The local measurement of the Hubble constant. Matter surrounding an underdense region pulls its contents outward, so galaxies near us would recede a bit faster than the true cosmic average — inflating locally measured expansion. That is one proposed contributor to the Hubble tension: nearby measurements give a higher rate than the value inferred from the CMB. Most analyses find the void too shallow to explain the whole gap, but it is a reminder that a "constant" measured from inside a hole may not be the universe\'s constant.',
      ),
      LessonSection.thinkReveal(
        title: 'The healthiest neighborhoods',
        question: 'Void galaxies are bluer and forming stars faster than cluster galaxies. Isolation usually sounds like starvation — so why does emptiness keep galaxies young?',
        answer: 'Because in the crowd, galaxies get robbed. Cluster galaxies have their cold gas — the fuel for new stars — stripped away by the hot intracluster medium and torn loose in close encounters and mergers. A void galaxy suffers almost none of that: it keeps its gas reservoir, feeds steadily from its surroundings, and burns slow and blue for billions of years. Solitude, at cosmic scale, is protection.',
      ),
      LessonSection.paragraph(
        title: 'The ghost web inside',
        body: 'Deep surveys show voids are not featureless. Faint threads of dwarf galaxies and tenuous gas cross their interiors — a diluted miniature of the cosmic web, the remnant of structure that never finished draining away. As dark energy stretches the voids, these ghost filaments thin further; voids merge with neighboring voids, their shared walls dissolving. On the longest timescales, void growth is the universe\'s dominant activity.',
      ),
    ],
  ),
  BioEntity(
    id: 'cosmic_cmb',
    scale: BioScale.cosmicStructures,
    position: 3,
    name: 'Cosmic Microwave Background',
    title: 'The First Light',
    shortDescription: 'The oldest light in the universe — emitted ~380,000 years after the Big Bang, now stretched to microwave wavelengths, carrying a snapshot of the infant cosmos.',
    longDescription:
        'The cosmic microwave background (CMB) fills the entire sky. It was released ~380,000 years after the Big Bang, at the moment called recombination, when the universe cooled enough (~3,000 Kelvin) for protons and electrons to bind into neutral hydrogen. Before that, the universe was an opaque glowing plasma — photons could not travel far without scattering off free electrons. The instant atoms formed, the fog lifted, and that first free light has been traveling ever since.\n\n'
        'Cosmic expansion has stretched those photons by a factor of ~1,100, from the orange glow of a cooling ember to microwaves at 2.725 Kelvin today. The CMB is astonishingly uniform — the same temperature in every direction to about one part in 100,000 — and it is precisely those tiny variations, first seen by COBE in 1992 and mapped in exquisite detail by WMAP and Planck, that are the seeds of every structure that followed. It is, quite literally, the baby photo of reality.',
    relatedIds: ['cosmic_web', 'cosmic_voids', 'universe_observable', 'universe_age'],
    sections: [
      LessonSection.fact(
        title: '2.725 Kelvin',
        body: 'The entire sky glows at 2.725 K — light from ~380,000 years after the Big Bang, stretched ~1,100-fold by 13.8 billion years of cosmic expansion.',
      ),
      LessonSection.table(
        title: 'What the baby photo tells us',
        headers: ['Question', 'CMB answer', 'How it is read'],
        rows: [
          ['Age of the universe', '~13.8 billion years', 'Fit of the full fluctuation pattern to cosmological models'],
          ['Composition', '~5% ordinary matter, ~27% dark matter, ~68% dark energy', 'Relative heights of the acoustic peaks'],
          ['Geometry of space', 'Flat (to within measurement error)', 'Angular size of the strongest ripples'],
          ['Expansion rate', '~67-68 km/s per megaparsec (Planck)', 'Model fit — famously in tension with local measurements'],
          ['Seeds of structure', 'Ripples of ~1 part in 100,000', 'Direct temperature mapping across the sky'],
        ],
      ),
      LessonSection.table(
        title: 'From prediction to precision',
        headers: ['Year', 'Milestone', 'Who'],
        rows: [
          ['1948', 'Relic radiation from a hot Big Bang predicted (~5 K estimated)', 'Alpher & Herman'],
          ['1965', 'Accidental detection as stubborn antenna noise; Nobel Prize follows', 'Penzias & Wilson'],
          ['1992', 'First map of the tiny temperature ripples', 'COBE satellite'],
          ['2003', 'Ripples mapped precisely; universe\'s age and mix pinned down', 'WMAP satellite'],
          ['2013', 'Definitive map — the current gold standard', 'Planck satellite'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The wall of fog',
        question: 'Why exactly could light not travel freely before 380,000 years — and why did neutral atoms suddenly change that?',
        answer: 'Free electrons are superb photon scatterers: in the early plasma, a photon could only fly a short distance before ricocheting off one, so the universe was opaque like the inside of a star or a thick fog. When cooling let electrons bind to protons, the free electrons vanished into neutral hydrogen — which barely interacts with the CMB\'s photon wavelengths. Scattering essentially stopped everywhere at nearly the same time, and the universe went transparent in one cosmic moment. The CMB is the light released by that last scattering, which is why its origin is called the "surface of last scattering."',
      ),
      LessonSection.thinkReveal(
        title: 'Where did the Big Bang happen?',
        question: 'The CMB arrives from every direction equally. So where, in the sky, did the Big Bang actually take place?',
        answer: 'Everywhere — including exactly where you are sitting. The Big Bang was not an explosion at a point in space; it was the expansion of space itself, happening at every location at once. The CMB photons reaching us today simply come from the shell of plasma that sat ~13.8 billion light-years of travel time away in every direction. An observer in a distant galaxy sees their own CMB sphere, centered on them. There is no center to point at, because every point was the center.',
      ),
      LessonSection.thinkReveal(
        title: 'Too smooth to be true',
        question: 'The CMB temperature matches to 1 part in 100,000 between patches of sky that — under ordinary expansion — could never have exchanged light or heat. Why is that uniformity a problem, and what is the leading fix?',
        answer: 'Things equalize temperature by contact. Opposite sides of the CMB sky are so far apart that, tracing standard expansion backward, no signal could ever have connected them — yet they agree perfectly. This is the horizon problem. The leading fix is inflation: in the first sliver of a second, a tiny, already-uniform patch was stretched enormously, so the entire observable universe descends from one region that had equalized before the stretch. Bonus: inflation also stretches quantum jitters to cosmic size, providing exactly the 1-in-100,000 seeds the CMB shows.',
      ),
      LessonSection.paragraph(
        title: 'The static on channel nothing',
        body: 'On an old analog television tuned between channels, a small fraction of the dancing static — often quoted at around ~1% — was the CMB itself, picked up by the antenna along with terrestrial noise. Humanity spent decades watching the afterglow of the Big Bang without knowing it. Penzias and Wilson found it only because they refused to ignore a persistent hiss in their horn antenna — even after evicting the pigeons roosting in it.',
      ),
      LessonSection.paragraph(
        title: 'The edge of seeing',
        body: 'The CMB defines the boundary of the observable universe: no light older than it can ever reach us, because earlier light was trapped in the plasma fog. To look past it, astronomy would need messengers that ignore electrons — primordial neutrinos or gravitational waves from the first instant. Both backgrounds are predicted to exist; neither has been directly mapped. The baby photo is, for now, the first page of the album.',
      ),
    ],
  ),
];
