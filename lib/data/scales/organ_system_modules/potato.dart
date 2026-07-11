import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Organ System → "The Whole Potato Plant" — the POTATO-LENS module for the
/// Organ System scale. Zooms out from single organs to the plant as a set of
/// integrated organ systems working as one: root system, shoot system,
/// vascular plumbing, the source→sink sugar economy, and the tuber as the
/// plant's storage organ. Six entities, positions 0..5.
///
/// Botany law enforced throughout: leaves make sugar (source); phloem ships it
/// DOWN to the growing tubers (sink) to store as starch; xylem carries water +
/// minerals UP from the roots; the tuber is a modified STEM (stolon tip), never
/// a root.
const List<BioEntity> organSystemPotatoEntities = <BioEntity>[
  // 0 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organSystem_potato_whole_plant',
    scale: BioScale.organSystem,
    position: 0,
    name: 'The Potato Plant as a System',
    title: 'Leaves above, tubers below, all one organism',
    moduleId: 'organSystem_potato',
    shortDescription:
        'A potato plant is not a lump — it\'s a factory with a solar roof above ground and a warehouse buried below, wired together into one working machine.',
    longDescription:
        'Stand a potato plant up in your mind. Above the soil: a bushy green shoot spreading leaves to catch the sun. Below the soil: a spreading root system and, hanging off it, the tubers — the potatoes. Every part is the same organism, and none of it works alone.\n\nAn organ system is a team of organs that share one job. The potato plant runs several teams at once — roots, shoots, plumbing — and the whole plant is the product of them cooperating. Break one system and the others starve or dry out.',
    relatedIds: [
      'organSystem_potato_root_system',
      'organSystem_potato_shoot_system',
      'organSystem_potato_source_sink',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'You know the potato as dinner. Meet it as a business: the leaves are the factory floor, the roots are the supply intake, the vascular tissue is the freight network, and the tubers are the vault. Nobody eats the vault before winter — that\'s the whole point.',
      ),
      LessonSection.thinkReveal(
        title: 'Why so many systems?',
        question:
            'A single-celled alga can photosynthesize AND absorb water in the same cell. Why does a potato plant split those jobs across separate organ systems metres apart?',
        answer:
            'Because it got big. Sunlight is up in the air; water and minerals are down in the soil. You can\'t be in both places with one cell. So the plant specialised: leaves went up to catch light, roots went down to mine water, and a plumbing system grew to connect them. Bigness forces division of labour.',
      ),
      LessonSection.table(
        title: 'The plant\'s organ systems at a glance',
        headers: ['System', 'Where', 'One-line job'],
        rows: [
          ['Root system', 'Underground', 'Anchor + drink water & minerals'],
          ['Shoot system', 'Above ground', 'Catch sunlight, make sugar'],
          ['Vascular system', 'Threaded through both', 'Move water up, sugar down'],
          ['Storage (tubers)', 'Underground', 'Bank starch for next season'],
        ],
      ),
      LessonSection.fact(
        title: 'One plant, one goal',
        body:
            'Every system on the potato plant ultimately serves a single mission: pack enough starch into the tubers to launch a whole new generation next spring.',
      ),
    ],
  ),

  // 1 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organSystem_potato_root_system',
    scale: BioScale.organSystem,
    position: 1,
    name: 'The Root System',
    title: 'The anchor and the drinking straw',
    moduleId: 'organSystem_potato',
    shortDescription:
        'Fibrous roots grip the plant to the earth and pull up the water and dissolved minerals the whole plant runs on.',
    longDescription:
        'The potato\'s root system is a fine, branching, fibrous web spreading through the topsoil. It does two things at once: it holds the plant down against wind and gravity, and it acts as the plant\'s mouth, absorbing water and dissolved minerals from between the soil grains.\n\nThe real work happens at microscopic root hairs — thin extensions of surface cells that massively multiply the absorbing area. Every drop of water that will later climb to a leaf enters here first.',
    relatedIds: [
      'organSystem_potato_vascular_system',
      'organSystem_potato_whole_plant',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'The roots never see the sun and never make a scrap of food. They are pure infrastructure — anchor plus intake pipe — and if they fail, the leaves above wilt within a day. Unglamorous, and completely non-negotiable.',
      ),
      LessonSection.thinkReveal(
        title: 'The classic mix-up',
        question:
            'When you dig up potatoes, you find tubers hanging near the roots. Does that make the potato a root?',
        answer:
            'No. The tubers grow on stolons — underground stems — that branch off the base of the shoot, not off the roots. The roots are the thin, hairy, branching threads that only drink water. The tuber is a swollen STEM. They\'re neighbours underground, but completely different organs.',
      ),
      LessonSection.table(
        title: 'What the roots pull up',
        headers: ['Intake', 'Why the plant needs it'],
        rows: [
          ['Water', 'Raw material for photosynthesis; keeps cells rigid'],
          ['Nitrogen', 'Builds proteins and chlorophyll'],
          ['Phosphorus', 'Powers energy transfer (ATP); root growth'],
          ['Potassium', 'Runs the pumps; famously packed into the tuber'],
        ],
      ),
      LessonSection.fact(
        title: 'Root hairs = surface area',
        body:
            'A single healthy plant can carry billions of root hairs. Together they give the root system a soil-contact area many times larger than the whole visible plant above ground.',
      ),
    ],
  ),

  // 2 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organSystem_potato_shoot_system',
    scale: BioScale.organSystem,
    position: 2,
    name: 'The Shoot System',
    title: 'Stem, leaves, and the solar factory',
    moduleId: 'organSystem_potato',
    shortDescription:
        'The green part above ground — stem and leaves — is where sunlight becomes sugar. This is the only part of the plant that makes food.',
    longDescription:
        'The shoot system is everything above the soil: the upright stem and the leaves it holds up to the sky. The stem is scaffolding and pipework; the leaves are solar panels. Inside every leaf, chloroplasts run photosynthesis — using sunlight to weld water and carbon dioxide into sugar.\n\nThis is the plant\'s only food-producing system. The roots drink but never eat. The tubers store but never make. All the energy that ends up buried in a potato was captured, sunbeam by sunbeam, up here in the leaves.',
    relatedIds: [
      'organSystem_potato_source_sink',
      'organSystem_potato_vascular_system',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Here\'s the plot twist of the whole plant: the part you eat makes nothing, and the part you throw on the compost makes everything. The leaves are the factory. The potato is just the finished goods, shipped downstairs.',
      ),
      LessonSection.thinkReveal(
        title: 'Why hold leaves UP?',
        question:
            'The stem spends real energy growing tall and holding leaves aloft. Why not just let the leaves lie flat on the ground and save the effort?',
        answer:
            'Competition for light. Whichever plant gets its leaves highest steals the sunlight from everything shorter — and shaded leaves make almost no sugar. The stem is an investment in reaching the sun before the neighbours do. Flat leaves on crowded ground would be starved into uselessness.',
      ),
      LessonSection.table(
        title: 'Photosynthesis: the leaf\'s recipe',
        headers: ['Goes in', 'Comes out', 'Powered by'],
        rows: [
          ['Water (from roots, via xylem)', 'Sugar (glucose)', 'Sunlight'],
          ['Carbon dioxide (from air)', 'Oxygen (released)', 'Chlorophyll'],
        ],
      ),
      LessonSection.fact(
        title: 'The source of it all',
        body:
            'A leaf that is actively making more sugar than it uses is called a SOURCE. On a potato plant, the sunlit leaves are the source for the entire operation — everything downstream depends on them.',
      ),
    ],
  ),

  // 3 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organSystem_potato_vascular_system',
    scale: BioScale.organSystem,
    position: 3,
    name: 'The Vascular System',
    title: 'Xylem up, phloem down — the plant\'s plumbing',
    moduleId: 'organSystem_potato',
    shortDescription:
        'Two sets of pipes run through the whole plant: xylem hauls water UP from the roots, phloem carries sugar DOWN to the tubers.',
    longDescription:
        'A plant can\'t work as separate systems unless something connects them. That something is the vascular system — a bundle of two different pipe networks threaded from the deepest root to the topmost leaf.\n\nXylem is the up-pipe: it carries water and dissolved minerals from the roots to the leaves, pulled upward as water evaporates out of the leaves (transpiration). Phloem is the down-pipe: it carries the sugar the leaves make away to wherever it\'s needed — and on a potato plant, that mostly means DOWN to the growing tubers. Two directions, two cargos, one bundle.',
    relatedIds: [
      'organSystem_potato_source_sink',
      'organSystem_potato_root_system',
      'organSystem_potato_shoot_system',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Imagine a building with two separate stairwells: one that only goes up carrying water, one that only goes down carrying sugar. That\'s a plant. Get the directions backwards and the plant makes no sense — so nail them down now.',
      ),
      LessonSection.thinkReveal(
        title: 'What pulls water UP a tall plant with no pump?',
        question:
            'Plants have no heart. What drags a column of water all the way up from the roots to the leaves?',
        answer:
            'Transpiration. Water evaporates out of tiny leaf pores, and because water molecules cling to each other, each escaping molecule tugs the next one up behind it — dragging an unbroken thread of water up the xylem from the roots. The leaves, by drying out, pull their own drink up the straw.',
      ),
      LessonSection.table(
        title: 'The two pipes — do not mix them up',
        headers: ['Pipe', 'Direction', 'Cargo', 'Driven by'],
        rows: [
          ['Xylem', 'UP', 'Water + minerals', 'Transpiration pull'],
          ['Phloem', 'DOWN (to tubers)', 'Sugar (sap)', 'Source-to-sink pressure'],
        ],
      ),
      LessonSection.fact(
        title: 'Two-way traffic, one bundle',
        body:
            'Xylem and phloem run side by side in the same vascular bundle — water rising past sugar sinking, in opposite directions, inches apart, all day long.',
      ),
    ],
  ),

  // 4 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organSystem_potato_source_sink',
    scale: BioScale.organSystem,
    position: 4,
    name: 'Source & Sink',
    title: 'Leaves make it, tubers bank it',
    moduleId: 'organSystem_potato',
    shortDescription:
        'The idea that ties the whole plant together: leaves (the SOURCE) make sugar, phloem ships it down to the tubers (the SINK), where it\'s stored as starch.',
    longDescription:
        'This is the integrating concept — the reason all the other systems exist. A SOURCE is any part making more sugar than it needs: the sunlit leaves. A SINK is any part that consumes or stores sugar without making its own: the growing tubers, buried in the dark. Phloem carries the sugar from source to sink — and on a potato plant, that flow runs DOWN, from leaf to tuber.\n\nAt the tuber, the arriving sugar is locked away as starch — a compact, insoluble storage form. The whole plant is essentially a machine for moving carbon from sky-facing leaves into an underground bank. That downhill sugar highway is the potato.',
    relatedIds: [
      'organSystem_potato_shoot_system',
      'organSystem_potato_vascular_system',
      'organSystem_potato_tuber_storage',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'If you remember one thing from this whole module, make it this: sugar flows from where it\'s MADE to where it\'s STORED — from leaf, down the phloem, into the potato. Source up top, sink down below. That single arrow explains the entire plant.',
      ),
      LessonSection.thinkReveal(
        title: 'Which way does the sugar go?',
        question:
            'A potato plant\'s leaves are photosynthesising in full sun. Which direction does the sugar they make travel, and where does it end up?',
        answer:
            'DOWN. The leaves are the source; the tubers are the sink. Sugar loads into the phloem in the leaves and flows downward to the developing tubers, where it\'s converted to starch for storage. Sugar always moves source→sink — and here the sink is buried below the source.',
      ),
      LessonSection.table(
        title: 'Source vs. sink on a potato plant',
        headers: ['Role', 'Which part', 'What it does with sugar'],
        rows: [
          ['SOURCE', 'Sunlit leaves', 'Makes it (photosynthesis)'],
          ['Transport', 'Phloem', 'Ships it downward'],
          ['SINK', 'Growing tubers', 'Stores it as starch'],
        ],
      ),
      LessonSection.fact(
        title: 'Why farmers wait',
        body:
            'Growers often let potato foliage die back before harvest. The reason is source→sink: they\'re giving the leaves time to finish pumping every last gram of sugar down into the tubers before the source shuts off.',
      ),
    ],
  ),

  // 5 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organSystem_potato_tuber_storage',
    scale: BioScale.organSystem,
    position: 5,
    name: 'The Tuber as a Storage Organ System',
    title: 'An underground stem that banks a whole year',
    moduleId: 'organSystem_potato',
    shortDescription:
        'The potato itself: a swollen underground STEM at the tip of a stolon, packed with starch to fund next season\'s plant.',
    longDescription:
        'The tuber is where the whole source→sink story is going. It forms at the tip of a stolon — an underground stem branching from the shoot — which swells as phloem pours sugar in and the tuber converts it to starch. It is a storage organ, and structurally it is a STEM, not a root.\n\nThe proof is on its skin: the "eyes." Each eye is a bud, arranged in the same spiral as buds on a normal stem, and each can sprout a whole new plant. Roots don\'t have buds; stems do. So the potato is the plant\'s energy bank AND its next generation — a buried battery that can grow legs and start over.',
    relatedIds: [
      'organSystem_potato_source_sink',
      'organSystem_potato_whole_plant',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'The potato on your plate is a plant\'s life savings and its escape pod at the same time. Every gram of starch in it was made by leaves and shipped down for one reason: to survive the winter and relaunch in spring. You\'re eating a season\'s worth of stored sunlight.',
      ),
      LessonSection.thinkReveal(
        title: 'Stem or root? Settle it.',
        question:
            'What single feature proves a potato is a modified STEM and not a root?',
        answer:
            'The eyes. Each eye is a bud that can sprout a new shoot — and only stems carry buds arranged in a spiral like that. A root has no buds. Plant a potato and the eyes grow whole new plants, exactly as a stem\'s buds would. Case closed: it\'s a stem.',
      ),
      LessonSection.table(
        title: 'Tuber vs. root — organ identity check',
        headers: ['Feature', 'The tuber (a stem)', 'A true root'],
        rows: [
          ['Grows from', 'Tip of a stolon (a stem)', 'The root system'],
          ['Has buds ("eyes")?', 'Yes — sprouts new plants', 'No'],
          ['Main job', 'Store starch for next season', 'Anchor + absorb water'],
          ['Fed by', 'Phloem (sugar in)', 'Xylem draws water out'],
        ],
      ),
      LessonSection.fact(
        title: 'A battery that grows legs',
        body:
            'One tuber can sprout several new plants from its eyes — which is why farmers plant chunks of potato ("seed potatoes") instead of seeds. The storage organ is also the reproduction plan.',
      ),
    ],
  ),
];
