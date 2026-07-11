import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Particles module: "Forces & Composite Particles". Eight entities covering
/// the four fundamental forces and the composite particles they build.
/// (Authored by module agent — physics-verified.)
const List<BioEntity> particlesForcesEntities = <BioEntity>[
  // 0 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'particles_four_forces',
    scale: BioScale.particles,
    position: 0,
    name: 'The Four Fundamental Forces',
    title: 'The rulebook of reality',
    moduleId: 'particles_forces',
    shortDescription:
        'Every push, pull, glow, and decay in the universe reduces to just four forces.',
    longDescription:
        'Gravity, electromagnetism, and the strong and weak nuclear forces are the '
        'complete list of ways things influence each other. Everything else — friction, '
        'chemistry, tension, magnetism — is one of these four wearing a costume.\n\n'
        'Their strengths span an almost unbelievable range. Set the strong force to 1, '
        'and electromagnetism is about 1/137, the weak force near a millionth, and '
        'gravity a staggering ~10⁻³⁹. Range matters too: the two nuclear forces reach '
        'no farther than an atomic nucleus, while gravity and electromagnetism stretch '
        'across the cosmos.',
    relatedIds: ['particle_gluon', 'particle_w_boson'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'Four forces. That is it. The tension in a rope, a lightning bolt, the '
            'shine of a star, and a falling apple are all just these four — no fifth '
            'force has ever been confirmed. Learn these four and you have the entire '
            'instruction manual for how anything touches anything else.',
      ),
      LessonSection.table(
        title: 'The four, ranked',
        headers: ['Force', 'Relative strength', 'Range', 'Carrier'],
        rows: [
          ['Strong', '1', '~10⁻¹⁵ m (nucleus)', 'Gluon'],
          ['Electromagnetic', '~1/137', 'Infinite', 'Photon'],
          ['Weak', '~10⁻⁶', '~10⁻¹⁸ m', 'W & Z bosons'],
          ['Gravity', '~10⁻³⁹', 'Infinite', 'Graviton (hypothetical)'],
        ],
      ),
      LessonSection.fact(
        title: 'A gap you can barely write',
        body:
            'Gravity is about 10³⁸ times weaker than the strong force — a 1 followed '
            'by 38 zeros. Yet gravity, not the strong force, sculpts galaxies.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If gravity is the weakest force by far, why does it dominate at the '
            'scale of planets and galaxies?',
        answer:
            'Because gravity only adds up — it has no negative charge to cancel it. '
            'Electromagnetism is far stronger but positive and negative charges '
            'neutralize, so large objects are nearly neutral. The nuclear forces have '
            'no reach beyond a nucleus. Only gravity accumulates across every atom of '
            'a star, so at cosmic scales the weakling wins.',
      ),
    ],
  ),

  // 1 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'particles_strong_force',
    scale: BioScale.particles,
    position: 1,
    name: 'The Strong Force',
    title: 'The glue that never lets go',
    moduleId: 'particles_forces',
    shortDescription:
        'The strongest force in nature — and the reason you can never hold a single quark.',
    longDescription:
        'The strong force binds quarks together inside protons and neutrons. It is '
        'carried by gluons and acts on a property called color charge (red, green, '
        'blue — nothing to do with actual color). Only "colorless" combinations are '
        'allowed to exist freely, which is why quarks always travel in tight bundles.\n\n'
        'It behaves backwards from every force you know: pull two quarks apart and the '
        'attraction grows stronger, like a stretched rubber band. Let them sit close '
        'and they roam almost freely (asymptotic freedom). A leftover, "residual" '
        'strong force leaks out of protons and neutrons to bind them into nuclei.',
    relatedIds: ['particle_gluon', 'particle_up_quark'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'Why can you never catch a lone quark in a jar? Because the strong force '
            'gets STRONGER the farther you pull. Yank hard enough and the stored '
            'energy simply snaps into brand-new quarks — you end up with more '
            'particles, never a single naked one. Nature refuses to be un-glued.',
      ),
      LessonSection.table(
        title: 'Strong force, at a glance',
        headers: ['Property', 'Value'],
        rows: [
          ['Carrier', 'Gluon (massless, 8 types)'],
          ['Acts on', 'Color charge'],
          ['Relative strength', '1 (the benchmark)'],
          ['Range', '~10⁻¹⁵ m — a nucleus wide'],
          ['Signature trait', 'Confinement + asymptotic freedom'],
        ],
      ),
      LessonSection.fact(
        title: 'Confinement',
        body:
            'No isolated quark or gluon has ever been observed. They are permanently '
            'confined inside colorless composite particles called hadrons.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'The residual strong force holds a nucleus together against the '
            'electromagnetic repulsion of its protons. What historically was said to '
            'carry this leftover force between protons and neutrons?',
        answer:
            'Pions (π mesons). Before gluons were understood, the nuclear binding '
            'between nucleons was modeled as an exchange of pions — quark-antiquark '
            'pairs. It is a "residual" strong force: the gluon interaction leaking '
            'out of one colorless nucleon to tug on its neighbor.',
      ),
    ],
  ),

  // 2 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'particles_weak_force',
    scale: BioScale.particles,
    position: 2,
    name: 'The Weak Force',
    title: 'The shapeshifter',
    moduleId: 'particles_forces',
    shortDescription:
        'The only force that can change one kind of quark into another — and it lights the Sun.',
    longDescription:
        'The weak force is the sole force able to change a particle\'s "flavor" — '
        'turning, say, a down quark into an up quark. That single trick powers '
        'radioactive beta decay and the first step of the fusion that fuels every star.\n\n'
        'It is carried by the W and Z bosons, which are enormous as particles go '
        '(about 80–91 GeV — roughly 90 times a proton\'s mass). A force carrier that '
        'heavy can only reach an incredibly short distance, which is exactly why the '
        'weak force is both weak and extremely short-ranged.',
    relatedIds: ['particle_w_boson', 'particle_up_quark'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'The other forces push and pull. The weak force TRANSFORMS. It is the '
            'only way one type of quark becomes another — the reason a neutron can '
            'flip into a proton, the reason the Sun can start fusing at all. Without '
            'the weak force, stars could not shine.',
      ),
      LessonSection.table(
        title: 'Weak force, at a glance',
        headers: ['Property', 'Value'],
        rows: [
          ['Carriers', 'W⁺, W⁻, Z⁰ bosons'],
          ['Carrier mass', '~80 GeV (W), ~91 GeV (Z)'],
          ['Relative strength', '~10⁻⁶'],
          ['Range', '~10⁻¹⁸ m (very short)'],
          ['Unique power', 'Changes quark & lepton flavor'],
        ],
      ),
      LessonSection.fact(
        title: 'Beta decay',
        body:
            'In β⁻ decay, a down quark becomes an up quark, emitting a W⁻ boson that '
            'instantly becomes an electron and an antineutrino. That is a neutron '
            'turning into a proton.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Why is the weak force both "weak" and short-ranged, when the strong '
            'force is strong yet also short-ranged?',
        answer:
            'Because its carriers, the W and Z bosons, are extremely massive. A heavy '
            'force carrier is "expensive" to create and can only exist fleetingly, so '
            'it travels a minuscule distance before vanishing — that limits both the '
            'range and the probability of the interaction, making the force feeble. '
            'The strong force is short-ranged for a different reason: confinement.',
      ),
    ],
  ),

  // 3 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'particles_electromagnetism',
    scale: BioScale.particles,
    position: 3,
    name: 'Electromagnetism',
    title: 'The force you live inside',
    moduleId: 'particles_forces',
    shortDescription:
        'The force of light, chemistry, and every solid surface you have ever touched.',
    longDescription:
        'Electromagnetism binds electrons to nuclei, holds atoms into molecules, and '
        'therefore runs all of chemistry, biology, and everyday material strength. Its '
        'carrier is the photon — the particle of light itself — which is massless, so '
        'the force reaches across infinite distance.\n\n'
        'Like charges repel and opposites attract, so matter tends to neutralize into '
        'balance. That is why a force ~10³⁶ times stronger than gravity does not tear '
        'the world apart: at large scales, positive and negative cancel almost perfectly.',
    relatedIds: ['particle_photon', 'particle_up_quark'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'When your hand rests on a table, no atoms actually touch — you are feeling '
            'electromagnetism, electron clouds refusing to overlap. Every color you '
            'see, every chemical reaction in your body, every spark: all one force, '
            'carried by light.',
      ),
      LessonSection.table(
        title: 'Electromagnetism, at a glance',
        headers: ['Property', 'Value'],
        rows: [
          ['Carrier', 'Photon (massless)'],
          ['Acts on', 'Electric charge'],
          ['Relative strength', '~1/137'],
          ['Range', 'Infinite'],
          ['Governs', 'Chemistry, light, magnetism'],
        ],
      ),
      LessonSection.fact(
        title: 'The fine-structure constant',
        body:
            'The strength of electromagnetism is set by α ≈ 1/137 — one of the most '
            'mysterious pure numbers in physics.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Electromagnetism is enormously stronger than gravity, yet we feel '
            'gravity constantly and electromagnetism only in sparks and magnets. Why?',
        answer:
            'Because electric charge comes in two signs that cancel. Bulk matter is '
            'nearly neutral, so its electromagnetic pull on you is almost zero. '
            'Gravity has only one sign and never cancels, so even the weak per-atom '
            'gravity of the whole Earth adds up to something you feel every second.',
      ),
    ],
  ),

  // 4 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'particles_gravity',
    scale: BioScale.particles,
    position: 4,
    name: 'Gravity',
    title: 'The weak force that runs the universe',
    moduleId: 'particles_forces',
    shortDescription:
        'By far the feeblest force — yet it shapes planets, stars, and galaxies.',
    longDescription:
        'Gravity is roughly 10⁻³⁹ as strong as the strong force, so weak that between '
        'two protons it is negligible next to their electric repulsion. But gravity '
        'only ever attracts, has infinite range, and never cancels — so across an '
        'entire star or galaxy it wins by sheer accumulation.\n\n'
        'It is also the odd one out. The other three forces are unified in the Standard '
        'Model as quantum fields with known carriers; gravity is described by Einstein\'s '
        'general relativity as curved spacetime. A quantum theory of gravity (and its '
        'hypothetical carrier, the graviton) remains unfinished physics.',
    relatedIds: ['particle_graviton'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'The weakest force in existence — a fridge magnet beats the entire Earth\'s '
            'gravity to lift a paperclip — is the one that assembles galaxies and lights '
            'the stars. How does the loser of every arm-wrestle end up running the cosmos?',
      ),
      LessonSection.table(
        title: 'Gravity, at a glance',
        headers: ['Property', 'Value'],
        rows: [
          ['Carrier', 'Graviton (hypothetical, unconfirmed)'],
          ['Acts on', 'Mass / energy'],
          ['Relative strength', '~10⁻³⁹'],
          ['Range', 'Infinite'],
          ['Status', 'Not yet unified with the other three'],
        ],
      ),
      LessonSection.fact(
        title: 'The odd one out',
        body:
            'Three forces fit the Standard Model as quantum fields. Gravity is still '
            'described by general relativity as curved spacetime — the two frameworks '
            'have never been fully reconciled.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If gravity is ~10³⁹ times weaker than the strong force, why is it the '
            'force that determines the fate of the whole universe?',
        answer:
            'Range and sign. The strong and weak forces die out beyond a nucleus. '
            'Electromagnetism reaches far but cancels because charge comes in ±. '
            'Gravity alone is long-range AND always attractive, so every scrap of '
            'mass in a galaxy pulls together with no cancellation — the tiny force '
            'summed over 10⁶⁸ atoms becomes irresistible.',
      ),
    ],
  ),

  // 5 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'particles_proton',
    scale: BioScale.particles,
    position: 5,
    name: 'The Proton',
    title: 'The rock of the atom',
    moduleId: 'particles_forces',
    shortDescription:
        'Three quarks (uud), a positive charge, and a mass that is mostly pure energy.',
    longDescription:
        'A proton is a bundle of two up quarks and one down quark (uud), giving it a '
        'charge of +1. It sits at the heart of every atomic nucleus, and its count '
        'defines which element you have. It appears to be perfectly stable — no proton '
        'decay has ever been observed, with a lifetime bound beyond 10³⁴ years.\n\n'
        'The astonishing part is its mass: about 938.3 MeV. The three quarks together '
        'weigh only around 1% of that. The other ~99% is the energy of the roaring '
        'gluon field and quark motion binding them — E = mc² made solid. You are, '
        'quite literally, mostly bound energy.',
    relatedIds: ['particle_up_quark', 'particle_gluon'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'Weigh a proton, then weigh its three quarks. They come up ~99% short. So '
            'where does a proton\'s mass actually come from? Not the matter inside it — '
            'from the frenzied energy of the strong force gluing it together. Most of '
            'YOUR mass is binding energy, not "stuff."',
      ),
      LessonSection.table(
        title: 'Proton, at a glance',
        headers: ['Property', 'Value'],
        rows: [
          ['Quark content', 'up + up + down (uud)'],
          ['Charge', '+1'],
          ['Mass', '~938.3 MeV/c²'],
          ['Stability', 'Stable (no decay observed)'],
          ['Bound by', 'Strong force (gluons)'],
        ],
      ),
      LessonSection.fact(
        title: 'Mass from energy',
        body:
            'The up and down quarks supply only ~1% of a proton\'s mass. The remaining '
            '~99% is gluon-field and kinetic energy — mass conjured from E = mc².',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'A proton is +1 and a neutron is 0, yet they have almost the same mass. '
            'How can adding electric charge barely change the mass?',
        answer:
            'Because quark rest mass and charge contribute almost nothing to the total. '
            'The proton (uud) and neutron (udd) differ by swapping one up quark for a '
            'down quark — a tiny mass shift. Nearly all the mass in both is the same '
            'strong-force binding energy, so the two land within ~0.1% of each other.',
      ),
    ],
  ),

  // 6 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'particles_neutron',
    scale: BioScale.particles,
    position: 6,
    name: 'The Neutron',
    title: 'The unstable twin',
    moduleId: 'particles_forces',
    shortDescription:
        'Neutral, slightly heavier than a proton — and doomed the moment it leaves the nucleus.',
    longDescription:
        'A neutron is two down quarks and one up quark (udd), summing to zero charge. '
        'It weighs about 939.6 MeV, just a hair more than a proton. Inside a stable '
        'nucleus it can live forever, held in place by the residual strong force.\n\n'
        'Set one free, though, and it is living on borrowed time. A lone neutron decays '
        'by the weak force in about 15 minutes on average (a mean lifetime near 880 '
        'seconds), turning into a proton, an electron, and an antineutrino — the '
        'textbook example of β⁻ decay.',
    relatedIds: ['particle_w_boson', 'particle_up_quark'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'Locked in a nucleus, a neutron can last billions of years. Kick it out '
            'on its own and it survives about 15 minutes before the weak force flips '
            'it into a proton. The same particle: immortal in company, doomed alone.',
      ),
      LessonSection.table(
        title: 'Neutron, at a glance',
        headers: ['Property', 'Value'],
        rows: [
          ['Quark content', 'up + down + down (udd)'],
          ['Charge', '0'],
          ['Mass', '~939.6 MeV/c²'],
          ['Free lifetime', '~880 s mean (~15 min)'],
          ['Decay', 'β⁻ → proton + electron + antineutrino'],
        ],
      ),
      LessonSection.fact(
        title: 'Barely heavier',
        body:
            'A neutron outweighs a proton by only about 1.3 MeV (~0.14%). That tiny '
            'surplus is exactly what makes free-neutron decay energetically possible.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Why can a neutron live essentially forever inside a nucleus but only ~15 '
            'minutes when free?',
        answer:
            'Because decay must be energetically favorable. A free neutron is heavier '
            'than its decay products, so it can decay. Inside a stable nucleus, the '
            'would-be product proton has no available lower-energy slot — turning the '
            'neutron into a proton would raise the nucleus\'s total energy, so the '
            'decay is forbidden and the neutron persists.',
      ),
    ],
  ),

  // 7 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'particles_mesons_hadrons',
    scale: BioScale.particles,
    position: 7,
    name: 'Mesons & Hadrons',
    title: 'The particle zoo',
    moduleId: 'particles_forces',
    shortDescription:
        'Any particle built from quarks is a hadron — and the strong force lets it build hundreds.',
    longDescription:
        'A hadron is any composite particle held together by the strong force. There '
        'are two classic families: baryons (three quarks, like the proton and neutron) '
        'and mesons (a quark paired with an antiquark, like the pion). Together they '
        'form the sprawling "particle zoo" discovered through the mid-20th century.\n\n'
        'Mesons are fleeting — a charged pion lives about 26 nanoseconds — but they '
        'matter enormously: exchanged pions were the original model for the residual '
        'strong force that binds protons and neutrons into nuclei. The zoo\'s wild '
        'variety is exactly what led physicists to the underlying quark model.',
    relatedIds: ['particle_up_quark', 'particle_gluon'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'For a while, new particles poured out of accelerators faster than anyone '
            'could name them — a chaotic "zoo." The order hiding underneath was quarks: '
            'every last one of those hadrons is just quarks bundled by the strong force. '
            'The zoo was really an alphabet.',
      ),
      LessonSection.table(
        title: 'The hadron families',
        headers: ['Family', 'Quark content', 'Examples'],
        rows: [
          ['Baryon', 'Three quarks (qqq)', 'Proton (uud), Neutron (udd)'],
          ['Meson', 'Quark + antiquark (qq̄)', 'Pion (π), Kaon (K)'],
          ['(Not a hadron)', 'No quarks', 'Electron, photon, neutrino'],
        ],
      ),
      LessonSection.fact(
        title: 'Fleeting glue',
        body:
            'A charged pion lives only ~26 nanoseconds, yet exchanged pions were the '
            'first successful model of the force binding whole atomic nuclei together.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'A proton and a pion are both hadrons made of quarks. What is the key '
            'structural difference between them?',
        answer:
            'Number and type of quarks. A proton is a baryon: three quarks (uud). A '
            'pion is a meson: one quark plus one antiquark. Baryons are matter-heavy '
            'and can be stable (the proton); mesons pair matter with antimatter and are '
            'short-lived, since the quark and antiquark can annihilate.',
      ),
    ],
  ),
];
