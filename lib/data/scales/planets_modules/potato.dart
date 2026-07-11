import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Planets module: "Potato-Shaped Worlds" — the POTATO-LENS module.
/// Real astronomy: small moons and asteroids are literally potato-shaped
/// because they lack the gravity to pull themselves round. The crown-jewel
/// on-brand module for a potato game about actual potato-shaped worlds.
const List<BioEntity> planetsPotatoEntities = <BioEntity>[
  BioEntity(
    id: 'planet_potato_why_round',
    scale: BioScale.planets,
    position: 0,
    name: 'Why Worlds Are Round',
    title: 'Gravity vs. the stubbornness of rock',
    moduleId: 'planets_potato',
    shortDescription:
        'Planets are round for one reason: they got big enough that their own gravity crushed every mountain flat.',
    longDescription:
        'Roundness is not decoration — it is a truce. Every world is a fight between gravity, which pulls every bit of matter toward the center, and the strength of the rock or ice it is made of, which resists being squeezed. Below a certain size, the rock wins and the body keeps whatever lumpy shape it was born with. Above it, gravity wins and pulls the whole thing into a sphere.\n\nWhen gravity has flattened a world into a sphere, scientists say it has reached hydrostatic equilibrium — the point where no mountain can stand any taller and no valley can sink any deeper. A big planet is round because it is, quite literally, too heavy to be a potato.',
    relatedIds: ['planet_potato_radius'],
    sections: [
      LessonSection.fact(
        title: 'The one-line law',
        body:
            'Round = gravity beat the rock. Lumpy = the rock beat gravity. Every world in the sky is on one side of that fight.',
      ),
      LessonSection.thinkReveal(
        title: 'The pull that never rests',
        question:
            'Earth\'s tallest mountain, Everest, is about 8.8 km high. Why can\'t a mountain on Earth just keep growing to 100 km?',
        answer:
            'Because rock is not infinitely strong. Pile enough of it up and the weight at the base exceeds what stone can bear — it slumps and flows. Gravity sets a ceiling on how tall anything can stand. On a big world that ceiling is low, so the surface stays close to a smooth sphere. That same ceiling is why worlds round out at all.',
      ),
      LessonSection.table(
        title: 'The two forces in the truce',
        headers: ['Force', 'What it wants', 'Wins when the body is...'],
        rows: [
          ['Self-gravity', 'Pull everything into a sphere', 'Large / massive'],
          ['Material strength', 'Keep the lumpy birth shape', 'Small / light'],
          ['The winner\'s name', 'A balanced, round world', 'In "hydrostatic equilibrium"'],
        ],
      ),
      LessonSection.paragraph(
        title: 'A truce you can see',
        body:
            'Look at any full-Moon photo and any asteroid flyby side by side. The Moon is a smooth disc; the asteroid is a battered lump. You are looking at the same law with two different answers — and the answer is set almost entirely by size.',
      ),
    ],
  ),
  BioEntity(
    id: 'planet_potato_radius',
    scale: BioScale.planets,
    position: 1,
    name: 'The Potato Radius',
    title: 'The size where lumps become spheres',
    moduleId: 'planets_potato',
    shortDescription:
        'There is a real threshold — nicknamed the "potato radius" — below which a world is doomed to stay a potato.',
    longDescription:
        'Somewhere around a couple hundred kilometers in radius, worlds cross a line. Below it, they are too small for gravity to overwhelm their own strength, so they keep an irregular, lumpy, unmistakably potato-like shape. Above it, gravity takes over and rounds them out. Astronomers genuinely call this the potato radius — it is not a joke term, it is in the literature.\n\nThe exact line depends on what the body is made of. Rock is strong, so rocky bodies need to be bigger — roughly 300 km or more across — before they go round. Ice is weaker and flows more easily, so icy bodies can round out at smaller sizes. Below the line, you get a belt full of potatoes.',
    relatedIds: [
      'planet_potato_why_round',
      'planet_potato_phobos_deimos',
      'planet_potato_asteroids',
    ],
    sections: [
      LessonSection.fact(
        title: 'Yes, that is the real name',
        body:
            'The "potato radius" is a genuine scientific term for the size threshold above which a body\'s gravity forces it into a round shape. The most on-brand number in astronomy.',
      ),
      LessonSection.table(
        title: 'Where the line falls',
        headers: ['Material', 'Roughly rounds out above', 'Why'],
        rows: [
          ['Rock', '~600 km diameter (~300 km radius)', 'Rock is strong; resists gravity longer'],
          ['Ice', '~400 km diameter', 'Ice is weaker and flows, so it caves in sooner'],
          ['Below the line', 'Any size', 'Stays irregular — a potato'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Icy vs. rocky',
        question:
            'Two moons are the same size — one is rock, one is ice. Which is more likely to be round?',
        answer:
            'The icy one. Ice is mechanically weaker than rock and deforms more easily, so gravity can pull an icy body into a sphere at a smaller size. That is why some small icy moons look round while similar-sized rocky asteroids stay lumpy. Composition, not just size, sets exactly where the potato radius falls.',
      ),
      LessonSection.paragraph(
        title: 'The cutoff, in one thought',
        body:
            'Think of the potato radius as a bouncer at the door of "planet-shaped." Bring enough mass and the right (soft) material, and you\'re waved through into sphere-hood. Show up small and made of stubborn rock, and you stay a potato — forever.',
      ),
    ],
  ),
  BioEntity(
    id: 'planet_potato_phobos_deimos',
    scale: BioScale.planets,
    position: 2,
    name: 'Phobos & Deimos',
    title: 'Mars\'s two tiny potato moons',
    moduleId: 'planets_potato',
    shortDescription:
        'Mars has two moons and both are potatoes — tiny, lumpy, and far too small ever to go round.',
    longDescription:
        'Mars\'s moons Phobos and Deimos are the poster children for potato worlds. Phobos is only about 22 km across and Deimos about 12 km — thousands of times too small to reach the potato radius, so both are permanently irregular, cratered lumps. They look far more like captured asteroids than like our smooth, round Moon.\n\nPhobos is doomed in a slow, spectacular way: it orbits so close to Mars that tidal forces are dragging it inward. In tens of millions of years it will either be torn apart into a ring or crash into the planet — a potato on borrowed time.',
    relatedIds: ['planet_potato_radius', 'planet_potato_asteroids'],
    sections: [
      LessonSection.fact(
        title: 'Small enough to walk off',
        body:
            'Phobos is ~22 km wide; Deimos ~12 km. Their gravity is so feeble a person could not walk normally — a hard jump could nearly reach escape velocity.',
      ),
      LessonSection.table(
        title: 'Mars\'s two spuds',
        headers: ['Moon', 'Diameter', 'Shape', 'Fate'],
        rows: [
          ['Phobos', '~22 km', 'Grooved, cratered potato', 'Spiraling in — will break up or crash'],
          ['Deimos', '~12 km', 'Smaller, smoother potato', 'Slowly drifting away'],
          ['Earth\'s Moon', '~3,474 km', 'Round sphere', 'Stable — well above the potato radius'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Where did they come from?',
        question:
            'Phobos and Deimos look like asteroids, not like Mars. What is the leading idea for their origin?',
        answer:
            'Many scientists think they are captured asteroids — small bodies from the nearby asteroid belt that wandered too close and got snagged by Mars\'s gravity. Their dark, primitive composition and irregular shapes fit asteroids well. (A competing idea is that a giant impact on Mars flung out debris that clumped into them.) Either way, they were never big enough to become round.',
      ),
      LessonSection.paragraph(
        title: 'Named for dread and terror',
        body:
            'Phobos means "fear" and Deimos means "panic" — the sons of the war god Ares (Mars) in Greek myth. Two little potatoes escorting the red planet, named for the feelings war brings.',
      ),
    ],
  ),
  BioEntity(
    id: 'planet_potato_lumpy_moons',
    scale: BioScale.planets,
    position: 3,
    name: 'Hyperion, Amalthea & the Lumpy Moons',
    title: 'The outer planets\' irregular little moons',
    moduleId: 'planets_potato',
    shortDescription:
        'Saturn and Jupiter keep whole collections of small, irregular moons — sponges, reddish lumps, and battered potatoes.',
    longDescription:
        'The giant planets are ringed by dozens of small moons, and the little ones are almost all potatoes. Saturn\'s Hyperion is one of the strangest: an eerily sponge-like body, riddled with deep craters, so lightly packed and irregular that it tumbles chaotically as it orbits — you could never predict which face it will show. Jupiter\'s Amalthea is a reddish, elongated moon about 250 km long, one of the reddest objects in the solar system, and clearly not round.\n\nThese moons stayed lumpy for the same reason as everything else in this module: they never grew big enough to cross the potato radius. Only the giant moons — Titan, Ganymede, the round ones — made it over the line.',
    relatedIds: ['planet_potato_radius', 'planet_potato_asteroids'],
    sections: [
      LessonSection.fact(
        title: 'A moon that tumbles',
        body:
            'Hyperion rotates chaotically — its spin is genuinely unpredictable, one of the few large bodies in the solar system that never settles into a steady rotation.',
      ),
      LessonSection.table(
        title: 'A gallery of lumps',
        headers: ['Moon', 'Planet', 'Claim to fame'],
        rows: [
          ['Hyperion', 'Saturn', 'Sponge-like, deeply cratered, chaotic tumble'],
          ['Amalthea', 'Jupiter', 'Reddish, ~250 km long, irregular'],
          ['Phoebe', 'Saturn', 'Dark captured potato on a backward orbit'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why does Hyperion look like a sponge?',
        question:
            'Hyperion is covered in deep, sharp-edged craters that don\'t look like normal impact craters. What makes it so porous?',
        answer:
            'Hyperion is thought to have very low density — it may be nearly half empty space, a loosely-bound rubble pile of ice. When something hits a body that porous, it punches straight in and compresses material rather than blasting out a wide crater, leaving deep, steep-walled pits. Low gravity means the debris that IS thrown out mostly escapes instead of raining back down. The result is that unmistakable sponge look.',
      ),
      LessonSection.paragraph(
        title: 'Captured vs. born there',
        body:
            'Many irregular outer moons — like Saturn\'s dark Phoebe — orbit backward or steeply tilted, a tell-tale sign they are captured potatoes: passing asteroids or comets snagged by a giant planet\'s gravity, never part of the tidy disc the round moons formed in.',
      ),
    ],
  ),
  BioEntity(
    id: 'planet_potato_asteroids',
    scale: BioScale.planets,
    position: 4,
    name: 'Asteroids — a Belt of Potatoes',
    title: 'Vesta, Eros, Itokawa & Bennu',
    moduleId: 'planets_potato',
    shortDescription:
        'The asteroid belt is a warehouse of potatoes — and we\'ve flown spacecraft right up to several of them.',
    longDescription:
        'Between Mars and Jupiter drifts a belt of rocky leftovers from the solar system\'s birth. Almost all of them are potatoes, because almost all of them are far below the potato radius. The clearest exception is Vesta — at about 525 km across it is big enough that gravity nearly rounded it out, though a colossal impact at its south pole left it dented rather than perfectly spherical.\n\nWe have visited the little ones up close. Eros is an elongated, lumpy world NASA\'s NEAR spacecraft actually landed on. Japan\'s Hayabusa mission touched down on Itokawa, a rubble-pile potato, and brought grains home. And OSIRIS-REx grabbed a sample from Bennu, a spinning-top rubble pile — loose gravel held together by the faintest gravity.',
    relatedIds: [
      'planet_potato_radius',
      'planet_potato_comets',
      'planet_potato_phobos_deimos',
    ],
    sections: [
      LessonSection.fact(
        title: 'We\'ve touched the potatoes',
        body:
            'NEAR landed on Eros. Hayabusa sampled Itokawa. OSIRIS-REx grabbed a piece of Bennu. Real spacecraft, real potato-shaped worlds, real dirt brought home.',
      ),
      LessonSection.table(
        title: 'Four asteroids we\'ve met',
        headers: ['Asteroid', 'Size', 'Shape', 'Mission'],
        rows: [
          ['Vesta', '~525 km', 'Nearly round (dented at the pole)', 'Dawn'],
          ['Eros', '~34 km long', 'Elongated potato', 'NEAR Shoemaker (landed)'],
          ['Itokawa', '~0.5 km', 'Two-lobed rubble pile', 'Hayabusa (sampled)'],
          ['Bennu', '~0.5 km', 'Spinning-top rubble pile', 'OSIRIS-REx (sampled)'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'What is a "rubble pile"?',
        question:
            'Bennu and Itokawa aren\'t solid rock — they\'re called rubble piles. What does that mean, and how does it stay together?',
        answer:
            'A rubble pile is not one solid boulder but a loose heap of gravel, rocks, and dust — pieces of a bigger asteroid that shattered and then gently re-gathered. There is empty space throughout, so they\'re surprisingly low-density. What holds them together is almost nothing: their own faint gravity plus tiny cohesive forces between grains. Poke one hard enough and it would scatter — which is exactly why OSIRIS-REx sank into Bennu\'s surface like a ball pit when it grabbed its sample.',
      ),
      LessonSection.paragraph(
        title: 'Why Vesta is the odd one out',
        body:
            'Vesta sits right at the edge of the potato radius. It is big enough that gravity mostly won — it is roughly round — but not so big that a giant impact couldn\'t leave a huge scar and a bulge. It is the belt\'s "almost-planet," caught mid-transformation from potato to sphere.',
      ),
    ],
  ),
  BioEntity(
    id: 'planet_potato_comets',
    scale: BioScale.planets,
    position: 5,
    name: 'Comets & Rubble Piles',
    title: '67P, the rubber-duck potato of ice',
    moduleId: 'planets_potato',
    shortDescription:
        'Comets are potatoes made of ice and dust — and one of them looks exactly like a rubber duck.',
    longDescription:
        'Comets are the frozen leftovers of the outer solar system: loose mixtures of ice, dust, and rock, far too small to be anything but irregular. The most famous is Comet 67P/Churyumov-Gerasimenko, which the European Rosetta mission orbited and landed on in 2014. It turned out to be shaped like a rubber duck — two lobes joined by a narrow neck, a bilobed potato of ice.\n\nThat duck shape is a clue to its history: 67P is very likely two objects that formed separately and then drifted together in a gentle, low-speed merger, sticking rather than smashing. Like the asteroid rubble piles, it is loosely bound — porous, fragile, and held together by almost nothing.',
    relatedIds: ['planet_potato_asteroids', 'planet_potato_radius'],
    sections: [
      LessonSection.fact(
        title: 'We landed on a rubber duck',
        body:
            'In 2014 Rosetta\'s Philae probe touched down on Comet 67P — the first-ever landing on a comet — a bilobed, duck-shaped potato of ice about 4 km across.',
      ),
      LessonSection.table(
        title: 'Ice potato vs. rock potato',
        headers: ['Trait', 'Comet (67P)', 'Asteroid (Bennu)'],
        rows: [
          ['Made of', 'Ice, dust, frozen gases', 'Rock and gravel'],
          ['Home region', 'Cold outer solar system', 'Warmer asteroid belt / near-Earth'],
          ['Grows a tail?', 'Yes — ice vaporizes near the Sun', 'No — nothing to boil off'],
          ['Structure', 'Loose, porous, bilobed', 'Loose rubble pile'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why the rubber-duck shape?',
        question:
            'What is the best explanation for why 67P has two lobes joined by a thin neck instead of being one smooth blob?',
        answer:
            'It is most likely a "contact binary" — two separate comets that formed nearby, drifted together, and merged in an extremely gentle, low-speed collision. Instead of shattering, they stuck and stayed, keeping both lobes and the narrow neck where they joined. Its gravity is far too weak to pull that dumbbell into a ball, so the duck shape is frozen in place — a potato that started as two potatoes.',
      ),
      LessonSection.paragraph(
        title: 'The whole module in one body',
        body:
            'A comet ties the story together: too small to be round, loosely bound like the rubble-pile asteroids, irregular like the tiny moons, and a living demonstration that below the potato radius, the universe simply builds lumps. From Phobos to 67P, the sky is full of potatoes — and now you know exactly why.',
      ),
    ],
  ),
];
