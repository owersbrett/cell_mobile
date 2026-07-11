import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Solar-system module entities — "The Sun & the Potato" (the POTATO-LENS
/// module): our star as the ultimate power source for every potato.
const List<BioEntity> solarPotatoEntities = <BioEntity>[
  // 0 ── The Sun as a Fusion Furnace ─────────────────────────────────────────
  BioEntity(
    id: 'solarSystems_potato_fusion_furnace',
    scale: BioScale.solarSystems,
    position: 0,
    name: 'The Sun as a Fusion Furnace',
    title: 'Where every potato\'s energy is born',
    moduleId: 'solarSystems_potato',
    shortDescription:
        'Every calorie in every french fry began as hydrogen being crushed into helium at the center of the Sun.',
    longDescription:
        'The Sun is a ball of plasma so heavy that its own gravity squeezes its core to about 15 million degrees Celsius. At that pressure, hydrogen nuclei slam together and fuse into helium — the proton-proton chain — and a sliver of their mass vanishes, reappearing as raw energy via E=mc².\n\n'
        'It is not a gentle process. The Sun fuses roughly 600 million tonnes of hydrogen every second and, in doing so, converts about 4 million tonnes of matter directly into sunlight per second. A rounding error of that firehose, eight minutes later, becomes a leaf, a tuber, a potato.',
    relatedIds: ['solarSystems_potato_sunlight_starch', 'solarSystems_potato_suns_future'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'You cannot grow a potato without a nuclear reactor. You just happen to keep yours 150 million km away, which is generally considered good practice.',
      ),
      LessonSection.thinkReveal(
        title: 'The mass that goes missing',
        question:
            'The Sun turns ~4 million tonnes of its own mass into energy every second. Won\'t it run out embarrassingly soon?',
        answer:
            'No. The Sun weighs about 2×10^27 tonnes. Losing 4 million tonnes a second sounds catastrophic, but that\'s roughly one Earth-mass every ~70 million years — a trickle against a reservoir it\'s been burning for 4.6 billion years and will keep burning for ~5 billion more. Big furnace, small tab.',
      ),
      LessonSection.table(
        title: 'The core, by the numbers',
        headers: ['Quantity', 'Value'],
        rows: [
          ['Core temperature', '~15 million °C'],
          ['Fusion reaction', 'Proton-proton chain (H → He)'],
          ['Hydrogen fused per second', '~600 million tonnes'],
          ['Mass → energy per second', '~4 million tonnes'],
          ['The equation', 'E = mc²'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'The Sun radiates ~4×10^26 watts. One second of it could power a potato harvest for longer than there have been potatoes.',
      ),
    ],
  ),

  // 1 ── The Habitable Zone ───────────────────────────────────────────────────
  BioEntity(
    id: 'solarSystems_potato_habitable_zone',
    scale: BioScale.solarSystems,
    position: 1,
    name: 'The Habitable Zone',
    title: 'The Goldilocks band where crops are possible',
    moduleId: 'solarSystems_potato',
    shortDescription:
        'There is a ring around the Sun where water stays liquid — and Earth, luckily for the potato, sits right inside it.',
    longDescription:
        'The habitable (or "Goldilocks") zone is the orbital band around a star where a planet\'s surface can hold liquid water: not so close it boils off, not so far it freezes solid. Water is the negotiable ingredient of life as we know it — and of any field you\'d ever plant.\n\n'
        'Earth orbits comfortably inside the Sun\'s zone. Venus, just inward, cooked its oceans away; Mars, just outward, froze. A potato is mostly water held in a starchy sack. It could only ever have evolved on a world where water knew how to stay a liquid.',
    relatedIds: ['solarSystems_potato_growing_season', 'solarSystems_potato_solar_field'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Goldilocks tasted three bowls of porridge. The Sun has three famous planets: too hot (Venus), too cold (Mars), and just right (Earth). Only one of them grows potatoes.',
      ),
      LessonSection.thinkReveal(
        title: 'Why liquid water and not, say, warmth?',
        question:
            'A planet could be plenty warm and still be a dead rock. What specifically does the Goldilocks zone protect?',
        answer:
            'Liquid water — a solvent stable across a temperature range where complex chemistry (and photosynthesis) can happen. Too close, and heat boils water to vapor that escapes to space; too far, and it locks up as ice that can\'t move nutrients through a plant. The zone is defined by water\'s liquid state, not by temperature alone.',
      ),
      LessonSection.table(
        title: 'Three neighbors, one lucky field',
        headers: ['World', 'Position vs. zone', 'Water fate'],
        rows: [
          ['Venus', 'Inner edge / too hot', 'Boiled away — runaway greenhouse'],
          ['Earth', 'Inside the zone', 'Liquid — oceans, rain, potatoes'],
          ['Mars', 'Outer edge / too cold', 'Frozen — ice caps, no crops'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'Earth sits about 150 million km (1 astronomical unit) from the Sun — dead center of the only real estate a tuber could grow on.',
      ),
    ],
  ),

  // 2 ── Sunlight to Starch ───────────────────────────────────────────────────
  BioEntity(
    id: 'solarSystems_potato_sunlight_starch',
    scale: BioScale.solarSystems,
    position: 2,
    name: 'Sunlight to Starch',
    title: 'The 8-minute trip that ends inside a potato',
    moduleId: 'solarSystems_potato',
    shortDescription:
        'A photon\'s last 8 minutes are the easy part — its first 10,000 years, clawing out of the Sun, are the epic.',
    longDescription:
        'A photon born in the Sun\'s core does not fly straight out. It bounces off dense plasma over and over, taking somewhere between ~10,000 and ~100,000 years just to escape to the surface. Then it crosses the vacuum to Earth in about 8 minutes 20 seconds — the fast, boring final lap.\n\n'
        'It lands on a potato leaf, where chlorophyll catches it and photosynthesis stitches CO₂ and water into glucose. The plant strings glucose into starch and buries it underground in a swollen stem: the potato. The tuber is, quite literally, sunlight in storage.',
    relatedIds: ['solarSystems_potato_fusion_furnace', 'solarSystems_potato_solar_field'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'When you eat a potato, you are eating light — light that spent longer escaping the Sun than humans have had agriculture.',
      ),
      LessonSection.thinkReveal(
        title: 'The 8-minute myth',
        question:
            'People say "sunlight is 8 minutes old." True — but what part of the photon\'s life does that number quietly ignore?',
        answer:
            'The 8 min 20 s is only the Sun-to-Earth vacuum sprint. Before that, the photon\'s energy random-walked out of the dense core for ~10,000 to ~100,000 years. So the light warming your potato is 8 minutes old on the outside and tens of millennia old on the inside.',
      ),
      LessonSection.table(
        title: 'A photon\'s itinerary',
        headers: ['Leg of the journey', 'How long'],
        rows: [
          ['Core → surface (bouncing through plasma)', '~10,000-100,000 years'],
          ['Sun → Earth (empty space)', '~8 min 20 s'],
          ['Leaf → glucose (photosynthesis)', 'A fraction of a second'],
          ['Glucose → buried starch (the potato)', 'A growing season'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'A potato is stored sunlight. The chemical energy in your fries is a photon that left the Sun\'s surface 8 minutes and 20 seconds before it hit a leaf.',
      ),
    ],
  ),

  // 3 ── The Growing Season ───────────────────────────────────────────────────
  BioEntity(
    id: 'solarSystems_potato_growing_season',
    scale: BioScale.solarSystems,
    position: 3,
    name: 'The Growing Season',
    title: 'Why potatoes have a schedule',
    moduleId: 'solarSystems_potato',
    shortDescription:
        'Seasons don\'t come from Earth moving closer to the Sun — they come from a 23.5° tilt, and that tilt is the potato\'s calendar.',
    longDescription:
        'Earth\'s axis is tipped about 23.5° from vertical. As the planet orbits, that tilt points each hemisphere toward or away from the Sun, changing how directly sunlight strikes the ground and how long the day lasts. That — not distance — is what makes summer summer.\n\n'
        'A tilted hemisphere in summer gets steeper, longer sunlight: more energy per square meter, more photosynthesis, more starch. Potatoes are planted after the last frost and lifted before the ground freezes. The tilt writes the planting calendar; the farmer just reads it.',
    relatedIds: ['solarSystems_potato_habitable_zone', 'solarSystems_potato_solar_field'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Ask most people why it\'s hot in summer and they\'ll say "Earth\'s closer to the Sun." They\'re wrong — and the potato field knows it.',
      ),
      LessonSection.thinkReveal(
        title: 'The distance trap',
        question:
            'Earth is actually closest to the Sun in early January. So why is the Northern Hemisphere buried in snow then?',
        answer:
            'Because seasons come from axial TILT, not distance. In January the Northern Hemisphere leans away from the Sun, so light hits at a shallow angle and days are short — cold, despite Earth being at its closest. Meanwhile the Southern Hemisphere, tilted toward the Sun, is enjoying summer. Same distance, opposite seasons. Distance is nearly irrelevant.',
      ),
      LessonSection.table(
        title: 'Tilt writes the calendar',
        headers: ['Season', 'Hemisphere & Sun', 'What the potato gets'],
        rows: [
          ['Spring', 'Tilting toward Sun', 'Frost lifts — planting time'],
          ['Summer', 'Tilted toward Sun', 'Long, steep light — bulking up'],
          ['Autumn', 'Tilting away', 'Vines die back — harvest'],
          ['Winter', 'Tilted away', 'Ground freezes — no growth'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'Earth\'s axial tilt: ~23.5°. Change that one angle and you rewrite every farmer\'s planting calendar on the planet.',
      ),
    ],
  ),

  // 4 ── Solar Energy on a Field ──────────────────────────────────────────────
  BioEntity(
    id: 'solarSystems_potato_solar_field',
    scale: BioScale.solarSystems,
    position: 4,
    name: 'Solar Energy on a Field',
    title: 'How much sunlight a potato actually keeps',
    moduleId: 'solarSystems_potato',
    shortDescription:
        'A field is drenched in about a kilowatt of sunlight per square meter — and the potato plant banks barely 1-2% of it.',
    longDescription:
        'On a clear day, roughly 1,000 watts of sunlight fall on every square meter of ground. That is an enormous, free, unrelenting delivery of energy across an entire farm. And yet plants are famously stingy with it.\n\n'
        'Photosynthesis is only about 1-2% efficient at turning that sunlight into new biomass. The rest is reflected, misses the useful wavelengths, or is lost as heat. The potato isn\'t lazy — it\'s a chemistry factory running on a razor-thin conversion rate, which is exactly why fields have to be so big.',
    relatedIds: ['solarSystems_potato_sunlight_starch', 'solarSystems_potato_growing_season'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'The Sun hands a potato field a fortune in energy every afternoon. The plants pocket about 1-2% of it and let the rest blow away. That\'s not a bug — it\'s biology.',
      ),
      LessonSection.thinkReveal(
        title: 'Where does the other 98% go?',
        question:
            'If ~1,000 W/m² lands on the field and photosynthesis grabs only 1-2%, where does the overwhelming majority of that sunlight actually end up?',
        answer:
            'Most of it never becomes food. A big share is the wrong wavelength for chlorophyll (which mainly uses red and blue light), some is reflected straight back off leaves and soil, and much is re-radiated as waste heat. Only a sliver drives the chemistry that builds glucose. The plant is a low-yield converter of a very generous supply.',
      ),
      LessonSection.table(
        title: 'The energy budget of a sunny field',
        headers: ['Item', 'Value'],
        rows: [
          ['Sunlight at the surface (clear day)', '~1,000 W per m²'],
          ['Photosynthetic efficiency (to biomass)', '~1-2%'],
          ['Chlorophyll\'s favorite light', 'Red & blue wavelengths'],
          ['Where the rest goes', 'Reflected, wrong wavelength, or heat'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            '~1 kilowatt of sunlight per square meter, banked at ~1-2%. To feed a village, you don\'t need a better potato — you need a bigger field.',
      ),
    ],
  ),

  // 5 ── The Sun's Future ─────────────────────────────────────────────────────
  BioEntity(
    id: 'solarSystems_potato_suns_future',
    scale: BioScale.solarSystems,
    position: 5,
    name: 'The Sun\'s Future',
    title: 'The ultimate deadline for potatoes',
    moduleId: 'solarSystems_potato',
    shortDescription:
        'The Sun is a middle-aged star with a hard stop: in about 5 billion years it swells into a red giant, and the potato\'s lease runs out.',
    longDescription:
        'The Sun is roughly 4.6 billion years old — about halfway through its stable "main sequence" life, calmly fusing hydrogen. This is the good era, the potato-growing era, and it lasts another ~5 billion years.\n\n'
        'Then the core runs low on hydrogen, the Sun bloats into a red giant, brightens, and swallows the inner Solar System. Long before it engulfs Earth, rising heat will boil off the oceans and end the growing of anything. The Sun that started every potato will, eventually, be the thing that stops them.',
    relatedIds: ['solarSystems_potato_fusion_furnace', 'solarSystems_potato_habitable_zone'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Every potato has a best-by date. So does the field. So does the Sun — it\'s just written in billions of years instead of days.',
      ),
      LessonSection.thinkReveal(
        title: 'Is the Sun getting old?',
        question:
            'The Sun is ~4.6 billion years old. Should potatoes be worried about it dying anytime soon?',
        answer:
            'Not on any human timescale. The Sun is only about halfway through its main-sequence life — it has ~5 billion years of steady hydrogen fusion left. It will end not by burning out quietly but by swelling into a red giant, growing bright enough to boil Earth\'s oceans long before it physically reaches us. That\'s the real deadline, and it\'s billions of years off.',
      ),
      LessonSection.table(
        title: 'The Sun\'s life story',
        headers: ['Stage', 'When', 'What it means for potatoes'],
        rows: [
          ['Birth', '~4.6 billion years ago', 'The furnace ignites'],
          ['Main sequence (now)', 'Halfway through', 'Stable light — golden age of crops'],
          ['Hydrogen runs low', 'In ~5 billion years', 'The core stalls'],
          ['Red giant', 'After that', 'Oceans boil — the field is gone'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            '~5 billion years: the Sun\'s remaining main-sequence life. That\'s the ultimate deadline for every potato that will ever grow.',
      ),
    ],
  ),
];
