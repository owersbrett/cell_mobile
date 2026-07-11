import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Farm System → "Growing Potatoes" — the POTATO-LENS module.
/// How the mascot is actually grown, start to finish: cut seed potatoes,
/// mound the soil, fend off blight, feed and water, then lift and cure.
/// Six entities, one honest potato-farming season.
const List<BioEntity> farmPotatoEntities = <BioEntity>[
  BioEntity(
    id: 'farm_potato_planting_seed_potatoes',
    scale: BioScale.farmSystem,
    position: 0,
    name: 'Planting Seed Potatoes',
    title: 'You plant a potato to grow a potato',
    moduleId: 'farmSystem_potato',
    shortDescription:
        'A potato crop starts with other potatoes — cut chunks with eyes, buried in rows. It is cloning, not seeding.',
    longDescription:
        'Farmers plant "seed potatoes": whole small tubers or cut pieces, each one carrying at least one eye (a dormant bud). Drop them in trenches, cover them, and every eye sprouts into a plant that is a genetic copy of its parent. That is clonal propagation — no pollination, no surprises.\n\nThe true botanical seeds inside a potato berry exist, but farmers ignore them for crops: seedlings are unpredictable and slow. When you want a whole field of the same reliable potato, you plant potatoes.',
    relatedIds: ['farm_potato_hilling', 'farm_potato_farm_year'],
    sections: [
      LessonSection.fact(
        title: 'The eye is the engine',
        body:
            'Every "eye" on a potato is a dormant bud. Cut a seed potato so each chunk keeps at least one eye — that eye is what sprouts into a plant.',
      ),
      LessonSection.thinkReveal(
        title: 'Same or different?',
        question:
            'If a farmer plants pieces cut from one prize potato across a whole field, how genetically similar is the resulting crop?',
        answer:
            'Essentially identical — they are clones. Every plant is a copy of that one parent tuber. Great for consistency, but it also means one perfectly matched disease can rip through the entire field.',
      ),
      LessonSection.table(
        title: 'Seed potato vs. botanical seed',
        headers: ['', 'Seed potato (tuber piece)', 'True botanical seed'],
        rows: [
          ['What it is', 'A cut chunk with an eye', 'A tiny seed from a berry'],
          ['Offspring', 'Clone of the parent', 'Genetic lottery'],
          ['Farm use', 'The standard — reliable', 'Rare — mostly breeders'],
          ['Speed to crop', 'Fast, vigorous', 'Slow, weak seedlings'],
        ],
      ),
      LessonSection.paragraph(
        title: 'Why rows',
        body:
            'Seed pieces go in evenly spaced trenches so machines can plant, hill, spray, and later lift them without trampling the crop. The ridge you plant into becomes the ridge you mound higher later.',
      ),
    ],
  ),
  BioEntity(
    id: 'farm_potato_hilling',
    scale: BioScale.farmSystem,
    position: 1,
    name: 'Hilling / Earthing Up',
    title: 'Bury the babies before the sun does',
    moduleId: 'farmSystem_potato',
    shortDescription:
        'Farmers keep mounding soil over the plants — partly for support, but mostly to keep tubers in the dark and out of trouble.',
    longDescription:
        'As potato plants grow, farmers "hill" them: dragging soil up around the stems into tall ridges. It braces the plant, gives the underground tubers room to swell, and smothers early weeds.\n\nThe load-bearing reason, though, is light. A tuber that pokes into sunlight turns green — that green is chlorophyll, and it rides along with solanine, a bitter, mildly toxic compound. Hilling keeps developing tubers buried in the dark so they stay pale, safe, and sellable.',
    relatedIds: ['farm_potato_planting_seed_potatoes', 'farm_potato_harvest'],
    sections: [
      LessonSection.fact(
        title: 'Green = do not eat',
        body:
            'Green skin means light exposure — chlorophyll plus rising solanine, a natural toxin. Hilling exists largely to prevent this.',
      ),
      LessonSection.thinkReveal(
        title: 'Why keep piling on dirt?',
        question:
            'The plant is doing fine — so why do farmers keep mounding more soil over it as the season goes on?',
        answer:
            'Because tubers grow just under the surface and creep upward. Without fresh soil over them, they hit sunlight and turn green and toxic. Hilling keeps them buried in the dark (and also braces the plant and buries weeds).',
      ),
      LessonSection.table(
        title: 'What one mound of soil buys you',
        headers: ['Benefit', 'What it does'],
        rows: [
          ['No green tubers', 'Blocks light → no chlorophyll, no solanine'],
          ['Support', 'Holds tall, top-heavy vines upright'],
          ['Room to grow', 'Loose soil lets tubers swell freely'],
          ['Weed control', 'Buries young weeds between the rows'],
        ],
      ),
      LessonSection.paragraph(
        title: 'The shape of a potato field',
        body:
            'Those neat parallel ridges you see are hills — each one a covered nursery of tubers, re-mounded a few times over the season as the plants stretch.',
      ),
    ],
  ),
  BioEntity(
    id: 'farm_potato_blight_pest_defense',
    scale: BioScale.farmSystem,
    position: 2,
    name: 'Blight & Pest Defense',
    title: 'The famine pathogen still wants your field',
    moduleId: 'farmSystem_potato',
    shortDescription:
        'Late blight is the #1 threat — the same pathogen behind the Irish Famine — and the Colorado potato beetle is the classic bug that shrugs off sprays.',
    longDescription:
        'Late blight (Phytophthora infestans) is the historic king of potato diseases. In cool, wet weather it can rot leaves and tubers in days, and it is the pathogen that triggered the Irish Potato Famine. Farmers fight it with resistant varieties, protective fungicide sprays, and constant scouting to catch outbreaks early.\n\nOn the insect side, the Colorado potato beetle is the poster child. It is infamous for evolving resistance to insecticide after insecticide, which pushed farmers toward Integrated Pest Management (IPM): rotate crops, rotate chemistries, watch closely, and spray only when it truly pays.',
    relatedIds: ['farm_potato_water_nutrients', 'farm_potato_farm_year'],
    sections: [
      LessonSection.fact(
        title: 'It caused a famine',
        body:
            'Late blight (Phytophthora infestans) is the pathogen behind the 1840s Irish Potato Famine. It is still potato disease #1 today.',
      ),
      LessonSection.thinkReveal(
        title: 'Why not just spray harder?',
        question:
            'The Colorado potato beetle keeps coming back — why not just hit it with more of the same insecticide?',
        answer:
            'Because the beetle is famous for evolving resistance — it burns through insecticides fast. Spraying the same chemistry harder just breeds survivors. The answer is IPM: rotate crops and chemistries, scout, and spray only when it counts.',
      ),
      LessonSection.table(
        title: 'Two enemies, two playbooks',
        headers: ['Threat', 'Type', 'How farmers fight it'],
        rows: [
          [
            'Late blight',
            'Fungus-like disease',
            'Resistant varieties, fungicides, scouting'
          ],
          [
            'Colorado potato beetle',
            'Insect pest',
            'IPM: rotation, rotate chemistries, scout'
          ],
        ],
      ),
      LessonSection.paragraph(
        title: 'Scouting is the real weapon',
        body:
            'The cheapest defense is a farmer walking the rows. Catch the first blighted leaf or beetle cluster early and you act small; miss it and cool, wet weather turns a spot into a lost field.',
      ),
    ],
  ),
  BioEntity(
    id: 'farm_potato_water_nutrients',
    scale: BioScale.farmSystem,
    position: 3,
    name: 'Water & Nutrients',
    title: 'Thirsty, hungry, and picky about it',
    moduleId: 'farmSystem_potato',
    shortDescription:
        'Potatoes want steady water and a real meal — and it is the *steadiness* of the water that decides whether tubers come out smooth or deformed.',
    longDescription:
        'Potatoes are shallow-rooted and thirsty. They need consistent moisture, especially once tubers start bulking. The trap is inconsistency: let the soil swing dry, then wet, then dry, and the tubers respond with defects — knobs, cracks, and hollow centers. Even watering beats heavy-then-thirsty watering.\n\nThey are heavy feeders too, leaning on the big three: nitrogen (N) for leafy growth, phosphorus (P) for roots and early establishment, and potassium (K) — which potatoes crave in large amounts for tuber quality. Farmers match the feeding to the growth stage rather than dumping it all up front.',
    relatedIds: ['farm_potato_blight_pest_defense', 'farm_potato_harvest'],
    sections: [
      LessonSection.fact(
        title: 'The K in N-P-K is the big one here',
        body:
            'Potatoes are notably hungry for potassium (K) — it drives tuber size and quality — on top of their nitrogen and phosphorus needs.',
      ),
      LessonSection.thinkReveal(
        title: 'What makes a knobby potato?',
        question:
            'A field got plenty of total water over the season but still produced cracked, knobby tubers. What likely went wrong?',
        answer:
            'The water was inconsistent. Drought followed by a soaking makes tubers stop, then surge — and that stop-start growth shows up as knobs, growth cracks, and hollow hearts. Steady moisture matters more than total moisture.',
      ),
      LessonSection.table(
        title: 'The big three nutrients',
        headers: ['Nutrient', 'Symbol', 'Mostly powers'],
        rows: [
          ['Nitrogen', 'N', 'Leafy vine growth'],
          ['Phosphorus', 'P', 'Roots + early establishment'],
          ['Potassium', 'K', 'Tuber size and quality (a big need)'],
        ],
      ),
      LessonSection.paragraph(
        title: 'Timing over volume',
        body:
            'Good potato farmers feed and water to the calendar of the plant — light early, heavier as tubers bulk — instead of one big dose. Consistency is the whole game.',
      ),
    ],
  ),
  BioEntity(
    id: 'farm_potato_harvest',
    scale: BioScale.farmSystem,
    position: 4,
    name: 'Harvest & Curing',
    title: 'Kill the vines, lift the crop, toughen the skin',
    moduleId: 'farmSystem_potato',
    shortDescription:
        'Harvest is a three-step ritual: kill the tops, lift the tubers, then *cure* them so their skins toughen before storage.',
    longDescription:
        'Before lifting, farmers kill or desiccate the vines — mowing or spraying the tops down a couple weeks before harvest. That stops growth, sets the skin, and makes machine harvesting clean. Then diggers lift the tubers out of the ridges.',
    relatedIds: ['farm_potato_hilling', 'farm_potato_water_nutrients'],
    sections: [
      LessonSection.fact(
        title: 'Curing = about 1–2 weeks',
        body:
            'Fresh-dug potatoes are cured for roughly a week or two in warm, humid air. This heals nicks and toughens the skin so they survive months of storage.',
      ),
      LessonSection.thinkReveal(
        title: 'Why kill a healthy plant on purpose?',
        question:
            'The vines are still green and alive — why would a farmer mow or spray them down before digging?',
        answer:
            'Killing the tops stops the tubers from growing, "sets" and toughens their skins, and clears the field so machines can lift cleanly. A set skin is one that will not scuff off in storage.',
      ),
      LessonSection.table(
        title: 'The harvest sequence',
        headers: ['Step', 'Action', 'Why'],
        rows: [
          ['1', 'Kill / desiccate vines', 'Stop growth, set the skin'],
          ['2', 'Lift the tubers', 'Diggers pull them from the ridges'],
          ['3', 'Cure ~1–2 weeks', 'Warm + humid heals and toughens skin'],
          ['4', 'Cold storage', 'Cool, dark, long-term holding'],
        ],
      ),
      LessonSection.paragraph(
        title: 'Cure first, chill later',
        body:
            'Skip curing and you store potatoes with soft, wounded skins that rot and shrivel. A potato that survives until spring earned it in that first humid week after digging.',
      ),
    ],
  ),
  BioEntity(
    id: 'farm_potato_farm_year',
    scale: BioScale.farmSystem,
    position: 5,
    name: "The Potato Farm's Year",
    title: 'From cut seed in spring to bins in winter',
    moduleId: 'farmSystem_potato',
    shortDescription:
        'Every step you just learned lands on a calendar: plant, hill, defend, feed, kill the vines, lift, cure, store.',
    longDescription:
        'A potato season is one long, orderly arc. Spring: cut seed potatoes into rows. Early summer: hill the plants, feed and water them steadily while scouting for blight and beetles. Late summer: the tubers bulk up under the ridges.\n\nEnd of season: kill the vines, lift the crop, cure the skins, and move everything into cool, dark storage — where good potatoes can hold for months. Then, next spring, some of those very tubers become the seed potatoes that start the whole loop again.',
    relatedIds: [
      'farm_potato_planting_seed_potatoes',
      'farm_potato_harvest',
    ],
    sections: [
      LessonSection.fact(
        title: 'The loop closes on itself',
        body:
            'Stored tubers become next spring\'s seed potatoes — the crop plants the next crop. The potato year is a circle.',
      ),
      LessonSection.thinkReveal(
        title: 'What ties the whole year together?',
        question:
            'Planting, hilling, spraying, feeding, killing vines, curing, storing — what single crop connects the end of one season to the start of the next?',
        answer:
            'The potatoes themselves. Some of the tubers you store over winter are held back as seed potatoes and cut up to plant in spring — the harvest becomes the seed, and the cycle never really ends.',
      ),
      LessonSection.table(
        title: 'The season, field to storage',
        headers: ['When', 'On the farm'],
        rows: [
          ['Spring', 'Cut & plant seed potatoes in rows'],
          ['Early summer', 'Hill up; feed, water, scout for pests'],
          ['Mid summer', 'Keep hilling; defend against blight & beetles'],
          ['Late summer', 'Tubers bulk under the ridges'],
          ['Harvest', 'Kill vines, lift, cure the skins'],
          ['Winter', 'Cool, dark storage — and next year\'s seed'],
        ],
      ),
      LessonSection.paragraph(
        title: 'One mascot, one calendar',
        body:
            'This is how the potato actually gets grown: not one clever trick but a year of steady, unglamorous decisions — each one you met earlier in this module, in the order the field demands them.',
      ),
    ],
  ),
];
