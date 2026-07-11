import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Galactic module: "How We Know" — the modern astronomer's toolkit.
/// The detective methods behind every galactic fact: light across the
/// spectrum, spectroscopy, redshift, the distance ladder, gravitational
/// lensing, JWST, and multi-messenger astronomy.
const List<BioEntity> galacticHowEntities = <BioEntity>[
  // 0 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'galactic_how_spectrum',
    scale: BioScale.galactic,
    position: 0,
    moduleId: 'galactic_how',
    name: 'Telescopes Across the Spectrum',
    title: 'Seeing the Invisible Light',
    shortDescription:
        'Visible light is a sliver — the universe broadcasts on channels our eyes can\'t tune to, and each one shows a different sky.',
    longDescription:
        'Everything you\'ve ever seen with your eyes arrives as visible light: a narrow band of the electromagnetic spectrum. But the cosmos also glows in radio, microwave, infrared, ultraviolet, X-ray, and gamma rays. Each wavelength is a different messenger of a different physics.\n\nCold gas hums in radio and microwave. Dust and newborn stars smoulder in infrared. Million-degree gas around black holes screams in X-rays. To see the whole galaxy, an astronomer needs eyes for every channel — and each telescope is built for one.',
    relatedIds: ['galactic_how_spectroscopy', 'galactic_how_jwst'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Point an optical telescope at the center of the Milky Way and you see almost nothing — a wall of dust. Point an infrared telescope at the same spot and the galactic core blazes into view. Same sky, different eyes. The lesson of modern astronomy: what you can\'t see depends entirely on which light you\'re looking for.',
      ),
      LessonSection.table(
        title: 'The electromagnetic toolkit',
        headers: ['Band', 'Wavelength (short→long)', 'What it reveals'],
        rows: [
          ['Gamma ray', 'shortest, < 0.01 nm', 'Explosions, black-hole jets, the most violent events'],
          ['X-ray', '0.01–10 nm', 'Million-degree gas, accretion disks, hot cluster gas'],
          ['Ultraviolet', '10–400 nm', 'Hot young massive stars, active galaxy cores'],
          ['Visible', '400–700 nm', 'Sun-like stars — what our eyes evolved to see'],
          ['Infrared', '700 nm – 1 mm', 'Dust, cool stars, distant redshifted galaxies'],
          ['Microwave', '1 mm – 30 cm', 'The cosmic microwave background — the afterglow of the Big Bang'],
          ['Radio', 'longest, > 30 cm', 'Cold hydrogen gas, pulsars, galactic magnetic fields'],
        ],
      ),
      LessonSection.fact(
        title: 'The visible sliver',
        body:
            'Visible light spans roughly 400–700 nm. The full electromagnetic spectrum spans from picometers to kilometers — visible light is less than a trillionth of it. We were nearly blind until we built instruments to see the rest.',
      ),
      LessonSection.fact(
        title: 'Why space telescopes exist',
        body:
            'Earth\'s atmosphere blocks most X-rays, gamma rays, and much infrared. To observe those bands, the telescope has to go above the air — which is why X-ray (Chandra) and infrared (JWST) observatories orbit in space.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'The center of our own galaxy is hidden behind thick dust lanes in visible light. Which band of telescope would you build to look straight through the dust and see the stars behind it — and why?',
        answer:
            'Infrared (and radio). Longer wavelengths pass through dust that scatters and absorbs short visible light. Infrared light slips between the dust grains largely unblocked, so infrared telescopes reveal the crowded galactic core — including the stars orbiting the central supermassive black hole — that visible light can never show.',
      ),
    ],
  ),

  // 1 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'galactic_how_spectroscopy',
    scale: BioScale.galactic,
    position: 1,
    moduleId: 'galactic_how',
    name: 'Spectroscopy',
    title: 'Reading a Star\'s Barcode',
    shortDescription:
        'Split a star\'s light into a rainbow and dark lines appear — a chemical fingerprint of what the star is made of, from light-years away.',
    longDescription:
        'When you pass starlight through a prism, it fans out into a spectrum — and that spectrum is crossed by dark absorption lines. Each element (hydrogen, helium, iron, calcium) absorbs light at a precise, unique set of wavelengths. The pattern of lines is a barcode that names the elements in the star, without ever leaving Earth.',
    relatedIds: ['galactic_how_spectrum', 'galactic_how_redshift'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'In 1868 astronomers found a set of spectral lines in the Sun that matched no element known on Earth. They named the mystery element after the Greek word for the Sun — helios. Helium was discovered in a star before it was ever found on our planet. Spectroscopy let us do chemistry across a hundred million kilometers of empty space.',
      ),
      LessonSection.fact(
        title: 'Every element has a signature',
        body:
            'Hydrogen absorbs strongly at 656.3 nm (the famous red H-alpha line). No other element does exactly that. Read the lines, name the elements — spectroscopy is how we know stars are mostly hydrogen and helium.',
      ),
      LessonSection.table(
        title: 'Two kinds of spectra',
        headers: ['Type', 'How it forms', 'What it tells you'],
        rows: [
          ['Absorption', 'Cool gas in front of a hot source removes specific colors', 'Composition of a star\'s outer layers'],
          ['Emission', 'Hot thin gas glows at its own specific colors', 'Composition + physics of nebulae and galaxy gas'],
          ['Doppler shift', 'Lines slide toward red (away) or blue (toward)', 'Motion — how fast the object approaches or recedes'],
        ],
      ),
      LessonSection.fact(
        title: 'Not just chemistry — motion, too',
        body:
            'If the whole barcode is shifted toward the red end, the object is moving away; toward blue, it\'s approaching. The size of the shift gives the speed. Spectroscopy measures both what things are made of AND how they move.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'You take a spectrum of a distant galaxy and see hydrogen\'s absorption lines — but every line sits at a longer (redder) wavelength than in a lab on Earth. The line pattern is intact, just slid over. What two things does that single observation tell you?',
        answer:
            'First, composition: the intact pattern proves the galaxy contains hydrogen — the same physics everywhere. Second, motion: because the whole pattern shifted toward red without distorting, the galaxy is moving away from us (a Doppler/cosmological redshift). The amount of shift measures how fast. One spectrum delivers both the ingredients and the velocity.',
      ),
    ],
  ),

  // 2 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'galactic_how_redshift',
    scale: BioScale.galactic,
    position: 2,
    moduleId: 'galactic_how',
    name: 'Redshift & Hubble\'s Law',
    title: 'The Universe Is Expanding',
    shortDescription:
        'Nearly every galaxy\'s light is shifted red — and the farther away it is, the faster it flees. That single pattern proved the universe is growing.',
    longDescription:
        'A galaxy moving away stretches its light toward longer, redder wavelengths — a redshift, labeled z. In 1929 Edwin Hubble plotted galaxy distances against their redshift velocities and found a straight line: the farther a galaxy, the faster it recedes.\n\nThat relationship is Hubble\'s Law, v = H₀ × d. It doesn\'t mean we\'re at the center of an explosion — it means space itself is expanding, carrying every galaxy away from every other, like raisins in rising dough.',
    relatedIds: ['galactic_how_spectroscopy', 'galactic_how_ladder'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Imagine baking raisin bread. As the dough rises, every raisin drifts away from every other raisin — and the ones farthest apart separate fastest. No raisin is the center; the whole loaf is expanding. Hubble discovered we live inside that loaf. The galaxies aren\'t flying through space — space between them is stretching.',
      ),
      LessonSection.fact(
        title: 'Hubble\'s Law',
        body:
            'v = H₀ × d. A galaxy\'s recession speed (v) equals the Hubble constant (H₀) times its distance (d). H₀ is about 70 kilometers per second per megaparsec — so a galaxy 10 Mpc away recedes at roughly 700 km/s.',
      ),
      LessonSection.table(
        title: 'How the shift works',
        headers: ['Observation', 'Meaning'],
        rows: [
          ['Lines shifted to red (z > 0)', 'Object receding — nearly all galaxies do this'],
          ['Lines shifted to blue (z < 0)', 'Object approaching (e.g. Andromeda, our neighbor)'],
          ['Bigger redshift z', 'Faster recession → greater distance'],
          ['z = Δλ / λ', 'Fractional stretch of the wavelength'],
        ],
      ),
      LessonSection.fact(
        title: 'The year it changed everything',
        body:
            'Edwin Hubble published the distance–velocity relation in 1929, building on Henrietta Leavitt\'s and Vesto Slipher\'s measurements. Before that, many thought the universe was static and eternal. After it, the universe had a history — and a beginning.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Almost every galaxy shows a redshift — it\'s moving away from us. Does that mean the Milky Way is at the special center of the universe, with everything fleeing from us?',
        answer:
            'No. In an expanding space, an observer in ANY galaxy sees every other galaxy receding, with the most distant fleeing fastest — exactly what we see. There\'s no center. The raisin-bread picture makes this concrete: every raisin sees all the others moving away. Universal redshift is evidence of expanding space, not of our privileged position.',
      ),
    ],
  ),

  // 3 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'galactic_how_ladder',
    scale: BioScale.galactic,
    position: 3,
    moduleId: 'galactic_how',
    name: 'The Cosmic Distance Ladder',
    title: 'Measuring the Unreachable',
    shortDescription:
        'You can\'t hold a ruler to a galaxy. Instead astronomers stack methods — each calibrating the next — to measure distances across billions of light-years.',
    longDescription:
        'No single tool reaches from your backyard to the edge of the observable universe. So astronomers build a ladder: each rung measures a range of distances and calibrates the rung above it. Trigonometric parallax handles nearby stars. Cepheid variable stars carry us across galaxies. Type Ia supernovae reach the deepest cosmos.\n\nKick out a lower rung and every distance above it wobbles — which is why calibrating the ladder is one of the most important, and contested, jobs in astronomy.',
    relatedIds: ['galactic_how_redshift', 'galactic_how_lensing'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Hold up a finger and wink each eye in turn — your finger jumps against the background. That jump is parallax, and it\'s literally the first rung of the ladder that measures the universe. From a wink to a supernova, every cosmic distance rests on that simple geometry, extended step by careful step.',
      ),
      LessonSection.table(
        title: 'The three great rungs',
        headers: ['Rung', 'Method', 'Reach'],
        rows: [
          ['1. Parallax', 'Star shifts against background as Earth orbits — pure geometry', 'Nearby stars (thousands of light-years)'],
          ['2. Cepheid variables', 'Pulsation period reveals true brightness (Leavitt\'s law)', 'Nearby galaxies (tens of millions of ly)'],
          ['3. Type Ia supernovae', 'Explode at a known standard brightness — "standard candles"', 'Distant galaxies (billions of ly)'],
        ],
      ),
      LessonSection.fact(
        title: 'Leavitt\'s law — the key that unlocked the galaxies',
        body:
            'In 1912 Henrietta Leavitt found that a Cepheid star\'s pulsation period predicts its true luminosity. Measure the period, know the real brightness, compare to how bright it looks — and you get the distance. This period-luminosity relation turned Cepheids into cosmic mile-markers.',
      ),
      LessonSection.fact(
        title: 'Standard candles',
        body:
            'A Type Ia supernova always detonates at nearly the same peak brightness — a white dwarf hitting a critical mass. Because you know the true brightness, its apparent faintness tells you the distance. They\'re bright enough to see across billions of light-years.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'A "standard candle" is an object whose true brightness you already know. How does knowing an object\'s real brightness let you measure how far away it is — using nothing but how bright it looks in your telescope?',
        answer:
            'Brightness falls off with the square of distance (the inverse-square law): move twice as far, it looks four times fainter. If you know the true (intrinsic) brightness and measure the apparent brightness, the ratio tells you exactly how much the light has dimmed — and therefore how far it traveled. A Cepheid\'s period or a Type Ia\'s fixed peak gives you that true brightness for free.',
      ),
    ],
  ),

  // 4 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'galactic_how_lensing',
    scale: BioScale.galactic,
    position: 4,
    moduleId: 'galactic_how',
    name: 'Gravitational Lensing',
    title: 'Gravity as a Telescope',
    shortDescription:
        'Massive galaxies bend the light passing them — smearing background objects into arcs and rings, and magnifying the faintest, most distant galaxies for free.',
    longDescription:
        'Einstein\'s general relativity says mass curves spacetime, and light follows that curve. When a massive galaxy or cluster sits between us and a distant object, its gravity bends the passing light — like a giant, lumpy lens in the sky.\n\nThe result: background galaxies stretched into luminous arcs, split into multiple images, or wrapped into a perfect "Einstein ring." And crucially, the lens magnifies — letting us see galaxies far too faint and distant to observe any other way. Nature lends us a telescope built of gravity.',
    relatedIds: ['galactic_how_ladder', 'galactic_how_jwst'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'In 1919, during a total solar eclipse, astronomers watched the stars just beside the Sun appear to shift out of position. The Sun\'s gravity had bent their starlight — exactly as Einstein\'s new theory predicted, and exactly as Newton\'s could not. It made Einstein world-famous overnight, and it handed astronomers a tool: gravity is a lens.',
      ),
      LessonSection.fact(
        title: 'Light follows curved spacetime',
        body:
            'General relativity (Einstein, 1915) says mass warps spacetime and light travels along the curve. A massive foreground galaxy therefore deflects the light of anything behind it — bending, magnifying, and sometimes multiplying its image.',
      ),
      LessonSection.table(
        title: 'What a gravitational lens produces',
        headers: ['Effect', 'What you see', 'Why it matters'],
        rows: [
          ['Einstein ring', 'Background galaxy smeared into a full circle', 'Perfect alignment; measures the lens\'s mass'],
          ['Arcs & multiple images', 'Same galaxy appears 2–4 times, stretched', 'Maps invisible dark matter in the lens'],
          ['Magnification', 'Faint distant galaxy brightened many-fold', 'Lets us see the earliest, faintest galaxies'],
        ],
      ),
      LessonSection.fact(
        title: 'A dark-matter detector',
        body:
            'The amount of bending depends on ALL the mass, including invisible dark matter. So the shape of the arcs lets astronomers weigh — and map — the dark matter in galaxy clusters, even though it emits no light at all.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'A galaxy cluster bends and magnifies the light of galaxies far behind it. How can astronomers use this "gravitational lens" to observe galaxies that are otherwise too faint for even the biggest telescopes to detect?',
        answer:
            'The cluster\'s gravity acts as a natural magnifying lens, focusing and amplifying the background galaxy\'s light — often brightening it by factors of ten or more. That free boost pushes faint, extremely distant galaxies over a telescope\'s detection threshold. JWST routinely aims at massive clusters precisely to use them as lenses, catching some of the earliest galaxies in the universe that would otherwise be invisible.',
      ),
    ],
  ),

  // 5 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'galactic_how_jwst',
    scale: BioScale.galactic,
    position: 5,
    moduleId: 'galactic_how',
    name: 'The James Webb Space Telescope',
    title: 'A Time Machine Tuned to Infrared',
    shortDescription:
        'JWST sees in infrared — the exact band that the universe\'s first galaxies are redshifted into — letting it look back to the cosmic dawn.',
    longDescription:
        'Launched December 25, 2021, the James Webb Space Telescope is the most powerful observatory ever flown. Its 6.5-meter gold-coated mirror gathers infrared light, and its sunshield keeps it cold enough to see faint heat from the edge of time.\n\nWhy infrared? The light of the very first galaxies left them as visible and ultraviolet — but after 13 billion years of cosmic expansion, that light has been stretched (redshifted) all the way into the infrared. To see the first galaxies, you need infrared eyes. JWST was built to be exactly that.',
    relatedIds: ['galactic_how_spectrum', 'galactic_how_redshift', 'galactic_how_lensing'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Light takes time to travel, so every telescope is a time machine — the farther you look, the older the light. JWST looks so far that it catches light which left its galaxies more than 13 billion years ago, when the universe was a few hundred million years old. It doesn\'t photograph the early universe; it photographs the light that\'s still arriving from it.',
      ),
      LessonSection.fact(
        title: 'The launch',
        body:
            'JWST launched on December 25, 2021, on an Ariane 5 rocket. It operates about 1.5 million km from Earth at the L2 Lagrange point — far from Earth\'s heat — with a mirror 6.5 meters across, far larger than Hubble\'s 2.4 m.',
      ),
      LessonSection.table(
        title: 'Why infrared reaches the first galaxies',
        headers: ['Step', 'What happens'],
        rows: [
          ['1. Emission', 'The first galaxies shine in visible & ultraviolet light'],
          ['2. Expansion', 'Over 13+ billion years, space stretches that light'],
          ['3. Redshift', 'The stretched light lands in the infrared band'],
          ['4. JWST', 'An infrared telescope is the only tool that can catch it'],
        ],
      ),
      LessonSection.fact(
        title: 'Cold on purpose',
        body:
            'To detect faint infrared (heat) from the early universe, the telescope itself must be freezing — otherwise its own warmth drowns the signal. JWST\'s tennis-court-sized sunshield keeps its instruments near −235 °C (about 40 K).',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'The first galaxies emitted mostly visible and ultraviolet light. Yet JWST — designed to find them — is an infrared telescope, not an ultraviolet one. Why build it to see the "wrong" color?',
        answer:
            'Because the universe changed the color for us. Over 13+ billion years of cosmic expansion, that original visible/UV light was stretched (redshifted) by huge factors, sliding all the way into the infrared by the time it reaches us. So the first galaxies now appear as infrared sources. An infrared telescope is exactly the right tool — the "wrong" color is the correct one after cosmological redshift.',
      ),
    ],
  ),

  // 6 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'galactic_how_multimessenger',
    scale: BioScale.galactic,
    position: 6,
    moduleId: 'galactic_how',
    name: 'Multi-Messenger Astronomy',
    title: 'Listening to the Cosmos Beyond Light',
    shortDescription:
        'For all of history we only had light. Now we also feel spacetime ripple and catch ghostly particles — new senses for the same universe.',
    longDescription:
        'Until 2015, every discovery in astronomy came from light — some band of the electromagnetic spectrum. Multi-messenger astronomy adds entirely new channels: gravitational waves (ripples in spacetime from colliding black holes and neutron stars) and neutrinos (near-massless particles that stream out of stellar cores and explosions).\n\nEach messenger carries information light can\'t. Combine them — see a neutron-star collision in gravitational waves AND in light AND in neutrinos — and you learn things no single messenger could ever tell you alone.',
    relatedIds: ['galactic_how_spectrum', 'galactic_how_lensing'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'On September 14, 2015, two detectors in the United States twitched by less than a thousandth the width of a proton. That tiny shiver was a gravitational wave — spacetime itself rippling from two black holes that had collided 1.3 billion years ago. For the first time, we didn\'t see the universe. We felt it.',
      ),
      LessonSection.fact(
        title: 'The first detection',
        body:
            'LIGO recorded the first gravitational wave on September 14, 2015, from two merging black holes about 1.3 billion light-years away. Einstein predicted such waves in 1916; it took a century to build instruments sensitive enough to catch one.',
      ),
      LessonSection.table(
        title: 'The three messengers',
        headers: ['Messenger', 'What it is', 'What it reveals'],
        rows: [
          ['Light (photons)', 'Electromagnetic waves', 'Composition, temperature, motion — the classic toolkit'],
          ['Gravitational waves', 'Ripples in spacetime itself', 'Merging black holes & neutron stars — invisible to light'],
          ['Neutrinos', 'Near-massless ghost particles', 'The inside of stars, cores of supernovae, violent explosions'],
        ],
      ),
      LessonSection.fact(
        title: 'The night it all came together',
        body:
            'In August 2017, a neutron-star collision (GW170817) was caught in gravitational waves AND then seen by dozens of telescopes across the light spectrum. This first multi-messenger event confirmed that such mergers forge heavy elements like gold and platinum.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Neutrinos barely interact with anything — trillions pass harmlessly through your body every second. That makes them fiendishly hard to detect. So why are astronomers so eager to catch these "ghost particles" from a distant supernova?',
        answer:
            'That same ghostliness is the point. Light from a supernova\'s core has to fight its way out through the star\'s outer layers, so it\'s delayed and distorted. Neutrinos, interacting with almost nothing, stream straight out from the collapsing core untouched — a direct, unfiltered report from the exact place the explosion begins. They carry information light simply cannot bring us. That\'s the power of a new messenger: it sees what light is blind to.',
      ),
    ],
  ),
];
