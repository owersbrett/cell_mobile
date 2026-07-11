import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Atoms → "The Periodic Table" module — the superheavy synthetic elements,
/// Z = 104 → 118. Every one of these is human-made, forged by slamming lighter
/// nuclei together in an accelerator; most have only ever existed as a handful
/// of atoms that survived for milliseconds or less. Properties here are
/// overwhelmingly predicted, never measured — the honesty of "predicted" and
/// "unknown" is part of the lesson.
const List<BioEntity> periodicElements104to118 = [
  // ── 104 ──────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_rf',
    scale: BioScale.atoms,
    position: 103,
    name: 'Rutherfordium',
    title: 'First past the actinides',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The first transactinide — the element that opened the superheavy frontier, named for Ernest Rutherford.',
    longDescription:
        'Rutherfordium is the first element beyond the actinide series and the first of the transactinides. It is made atom-by-atom by fusing lighter nuclei, and every isotope is radioactive with short half-lives. Named after Ernest Rutherford, the father of nuclear physics. Its chemistry is expected to resemble hafnium, but only a few atoms at a time have ever been studied.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Rf'],
          ['Atomic number', '104'],
          ['Group', '4'],
          ['Period', '7'],
          ['Category', 'transition metal (predicted)'],
          ['State at 25°C (predicted)', 'solid'],
          ['Standout fact', 'First transactinide element'],
        ],
      ),
      LessonSection.fact(
        title: 'Made, never mined',
        body:
            'Rutherfordium does not occur in nature. Every atom that has ever existed was synthesized in a lab by fusing nuclei together.',
      ),
      LessonSection.fact(
        title: 'Named for a giant',
        body:
            'It honors Ernest Rutherford, who first split the atom and mapped the nucleus.',
      ),
    ],
  ),

  // ── 105 ──────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_db',
    scale: BioScale.atoms,
    position: 104,
    name: 'Dubnium',
    title: 'Prize of a naming war',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A superheavy metal whose name settled a decades-long Cold War dispute over who discovered it.',
    longDescription:
        'Dubnium sits below tantalum in group 5 and is expected to behave chemically like it. Only fleeting atoms have ever been made. Its name comes from Dubna, Russia, home of the Joint Institute for Nuclear Research — a resolution to the "Transfermium Wars," the bitter rivalry between Soviet and American labs over who discovered and named elements 104 through 106.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Db'],
          ['Atomic number', '105'],
          ['Group', '5'],
          ['Period', '7'],
          ['Category', 'transition metal (predicted)'],
          ['State at 25°C (predicted)', 'solid'],
          ['Standout fact', 'Named for Dubna, Russia'],
        ],
      ),
      LessonSection.fact(
        title: 'The Transfermium Wars',
        body:
            'Soviet and American labs fought for decades over credit for elements 104–106. IUPAC brokered the peace; Dubnium honors the Russian town of Dubna.',
      ),
    ],
    relatedIds: ['element_rf', 'element_sg'],
  ),

  // ── 106 ──────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_sg',
    scale: BioScale.atoms,
    position: 105,
    name: 'Seaborgium',
    title: 'Named for a living scientist',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The first element named after a person who was still alive to see it — Glenn Seaborg.',
    longDescription:
        'Seaborgium falls below tungsten in group 6. It is intensely radioactive and exists only as a few atoms at a time. It broke precedent as the first element named for a living person: Glenn T. Seaborg, who co-discovered plutonium and nine other elements and reshaped the periodic table by placing the actinides in their own row.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Sg'],
          ['Atomic number', '106'],
          ['Group', '6'],
          ['Period', '7'],
          ['Category', 'transition metal (predicted)'],
          ['State at 25°C (predicted)', 'solid'],
          ['Standout fact', 'First element named for a living person'],
        ],
      ),
      LessonSection.fact(
        title: 'Named while he lived',
        body:
            'Glenn Seaborg was alive when element 106 took his name in 1997 — a first for the periodic table, and controversial at the time.',
      ),
    ],
    relatedIds: ['element_db'],
  ),

  // ── 107 ──────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_bh',
    scale: BioScale.atoms,
    position: 106,
    name: 'Bohrium',
    title: 'Heavy echo of the quantum atom',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A group-7 superheavy element named for Niels Bohr, architect of the quantum model of the atom.',
    longDescription:
        'Bohrium sits below rhenium in group 7 and is predicted to share its chemistry. First made in 1981 at Darmstadt, Germany, only a handful of atoms have ever been synthesized. It honors Niels Bohr, whose model of the atom explained how electrons occupy quantized energy levels.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Bh'],
          ['Atomic number', '107'],
          ['Group', '7'],
          ['Period', '7'],
          ['Category', 'transition metal (predicted)'],
          ['State at 25°C (predicted)', 'solid'],
          ['Standout fact', 'Named for Niels Bohr'],
        ],
      ),
      LessonSection.fact(
        title: 'Chemistry, confirmed in atoms',
        body:
            'Even from a few atoms, chemists showed bohrium forms a volatile oxychloride much like rhenium — evidence its group-7 placement holds.',
      ),
    ],
  ),

  // ── 108 ──────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_hs',
    scale: BioScale.atoms,
    position: 107,
    name: 'Hassium',
    title: 'A whiff of osmium chemistry',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'One of the few superheavies whose chemistry has actually been probed — it behaves like osmium below it.',
    longDescription:
        'Hassium, group 8, is named after the German state of Hesse (Latin Hassia), home of the GSI lab in Darmstadt where it was discovered in 1984. Despite existing only fleetingly, chemists managed to form hassium tetroxide and show it behaves like its lighter cousin osmium — a rare experimental confirmation of a superheavy element’s expected chemistry.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Hs'],
          ['Atomic number', '108'],
          ['Group', '8'],
          ['Period', '7'],
          ['Category', 'transition metal (predicted)'],
          ['State at 25°C (predicted)', 'solid'],
          ['Standout fact', 'Chemistry measured — behaves like osmium'],
        ],
      ),
      LessonSection.fact(
        title: 'Real chemistry from real atoms',
        body:
            'Scientists coaxed hassium into forming a tetroxide (HsO₄) and confirmed it mirrors osmium — an experimental win at the edge of the table.',
      ),
    ],
  ),

  // ── 109 ──────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_mt',
    scale: BioScale.atoms,
    position: 108,
    name: 'Meitnerium',
    title: 'Justice for Lise Meitner',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Named for Lise Meitner, who explained nuclear fission but was passed over for the Nobel Prize.',
    longDescription:
        'Meitnerium, group 9, was first synthesized in 1982 at Darmstadt. Its chemistry has never been studied — only a tiny number of short-lived atoms have been made. It honors Lise Meitner, who co-discovered and named nuclear fission; her collaborator Otto Hahn won the Nobel Prize while she was overlooked, making her element a form of scientific redress.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Mt'],
          ['Atomic number', '109'],
          ['Group', '9'],
          ['Period', '7'],
          ['Category', 'transition metal (predicted)'],
          ['State at 25°C (predicted)', 'solid'],
          ['Standout fact', 'Named for Lise Meitner'],
        ],
      ),
      LessonSection.fact(
        title: 'The overlooked physicist',
        body:
            'Lise Meitner explained nuclear fission but was left off the Nobel Prize. Element 109 carries her name — one of the few named for a woman.',
      ),
    ],
  ),

  // ── 110 ──────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_ds',
    scale: BioScale.atoms,
    position: 109,
    name: 'Darmstadtium',
    title: 'A city etched in the table',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Named for the German city of Darmstadt, where a run of superheavy elements was forged.',
    longDescription:
        'Darmstadtium, group 10, was first made in 1994 at the GSI facility in Darmstadt, Germany — the same lab that discovered elements 107 through 112. It is expected to resemble platinum but has no measured chemistry, existing only as a few short-lived atoms.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Ds'],
          ['Atomic number', '110'],
          ['Group', '10'],
          ['Period', '7'],
          ['Category', 'transition metal (predicted)'],
          ['State at 25°C (predicted)', 'solid'],
          ['Standout fact', 'Named for Darmstadt, Germany'],
        ],
      ),
      LessonSection.fact(
        title: 'A prolific lab',
        body:
            'The GSI lab in Darmstadt discovered six elements (107–112). Element 110 is named for its home city.',
      ),
    ],
  ),

  // ── 111 ──────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_rg',
    scale: BioScale.atoms,
    position: 110,
    name: 'Roentgenium',
    title: 'The X-ray element',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A superheavy metal below gold, named for Wilhelm Röntgen, who discovered X-rays.',
    longDescription:
        'Roentgenium, group 11, was first synthesized in 1994 at Darmstadt. It sits below gold and silver and is predicted to be a metal, though its chemistry is unmeasured and only a few atoms have ever existed. It honors Wilhelm Conrad Röntgen, discoverer of X-rays and the first Nobel laureate in Physics.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Rg'],
          ['Atomic number', '111'],
          ['Group', '11'],
          ['Period', '7'],
          ['Category', 'transition metal (predicted)'],
          ['State at 25°C (predicted)', 'solid'],
          ['Standout fact', 'Named for X-ray discoverer Röntgen'],
        ],
      ),
      LessonSection.fact(
        title: 'Below gold',
        body:
            'Roentgenium sits directly under gold in group 11 — but unlike gold, no one will ever hold a coin of it.',
      ),
    ],
  ),

  // ── 112 ──────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_cn',
    scale: BioScale.atoms,
    position: 111,
    name: 'Copernicium',
    title: 'A metal that may act like a gas',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Named for Copernicus; predicted to be so affected by relativity it might behave like a volatile, mercury-like liquid or gas.',
    longDescription:
        'Copernicium, group 12, sits below mercury. Relativistic effects on its electrons are so strong that it is predicted to be extremely volatile — possibly a gas at room temperature, breaking the trend of its group. First made in 1996 at Darmstadt, it honors Nicolaus Copernicus, who placed the Sun, not the Earth, at the center.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Cn'],
          ['Atomic number', '112'],
          ['Group', '12'],
          ['Period', '7'],
          ['Category', 'transition metal (predicted)'],
          ['State at 25°C (predicted)', 'liquid or gas (predicted)'],
          ['Standout fact', 'Relativity may make it act like a noble gas'],
        ],
      ),
      LessonSection.fact(
        title: 'When relativity reshapes an element',
        body:
            'Copernicium’s electrons move so fast that Einstein’s relativity distorts them, possibly making a group-12 metal behave like a volatile gas.',
      ),
    ],
  ),

  // ── 113 ──────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_nh',
    scale: BioScale.atoms,
    position: 112,
    name: 'Nihonium',
    title: 'Japan’s element',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'The first element discovered in Asia — "Nihon" means Japan, where RIKEN made it.',
    longDescription:
        'Nihonium, group 13, is the first element discovered by an Asian team: RIKEN in Japan, confirmed after painstaking single-atom experiments. Its name comes from "Nihon," one of the Japanese words for Japan. It is a predicted post-transition metal with no measured chemistry.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Nh'],
          ['Atomic number', '113'],
          ['Group', '13'],
          ['Period', '7'],
          ['Category', 'post-transition metal (predicted)'],
          ['State at 25°C (predicted)', 'solid (predicted)'],
          ['Standout fact', 'First element discovered in Asia'],
        ],
      ),
      LessonSection.fact(
        title: 'A national first',
        body:
            'RIKEN’s team saw only three atoms of nihonium across years of experiments before the discovery was accepted — Asia’s first named element.',
      ),
    ],
  ),

  // ── 114 ──────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_fl',
    scale: BioScale.atoms,
    position: 113,
    name: 'Flerovium',
    title: 'Doorstep of the stable island',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Sits near the predicted "island of stability" — some isotopes cling to life for whole seconds.',
    longDescription:
        'Flerovium, group 14, sits below lead and near the theorized "island of stability," a region where certain superheavy nuclei are predicted to last much longer than their neighbors. Some flerovium isotopes survive for seconds — an eternity in this realm. It is named for the Flerov Laboratory of Nuclear Reactions and its founder Georgy Flyorov.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Fl'],
          ['Atomic number', '114'],
          ['Group', '14'],
          ['Period', '7'],
          ['Category', 'post-transition metal (predicted)'],
          ['State at 25°C (predicted)', 'unknown (possibly gas)'],
          ['Standout fact', 'Near the "island of stability"'],
        ],
      ),
      LessonSection.fact(
        title: 'Seconds, not milliseconds',
        body:
            'Most superheavies vanish in fractions of a second. Some flerovium isotopes last several seconds — a hint that the island of stability is near.',
      ),
    ],
    relatedIds: ['element_og'],
  ),

  // ── 115 ──────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_mc',
    scale: BioScale.atoms,
    position: 114,
    name: 'Moscovium',
    title: 'The Moscow region’s element',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A fleeting group-15 element named for the Moscow region, home of the Dubna lab.',
    longDescription:
        'Moscovium, group 15, sits below bismuth and was first synthesized in 2003 at Dubna in a Russian–American collaboration. It exists only as a few atoms lasting fractions of a second. Its name honors the Moscow Oblast, the region surrounding the Joint Institute for Nuclear Research.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Mc'],
          ['Atomic number', '115'],
          ['Group', '15'],
          ['Period', '7'],
          ['Category', 'post-transition metal (predicted)'],
          ['State at 25°C (predicted)', 'solid (predicted)'],
          ['Standout fact', 'Named for the Moscow region'],
        ],
      ),
      LessonSection.fact(
        title: 'A collaboration, not a rivalry',
        body:
            'Unlike the Cold War naming wars, moscovium came from a joint Russian–American effort at Dubna and Livermore.',
      ),
    ],
  ),

  // ── 116 ──────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_lv',
    scale: BioScale.atoms,
    position: 115,
    name: 'Livermorium',
    title: 'A partner lab immortalized',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'A group-16 superheavy named for Lawrence Livermore National Laboratory, longtime partner to Dubna.',
    longDescription:
        'Livermorium, group 16, sits below polonium and was discovered in 2000 in the Dubna–Livermore collaboration. Only a handful of short-lived atoms have been made, and its chemistry is unknown. It is named for the Lawrence Livermore National Laboratory in California.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Lv'],
          ['Atomic number', '116'],
          ['Group', '16'],
          ['Period', '7'],
          ['Category', 'post-transition metal (predicted)'],
          ['State at 25°C (predicted)', 'solid (predicted)'],
          ['Standout fact', 'Named for Lawrence Livermore Lab'],
        ],
      ),
      LessonSection.fact(
        title: 'A lab on the table',
        body:
            'Livermorium honors the American lab whose collaboration with Dubna produced several of the heaviest elements known.',
      ),
    ],
  ),

  // ── 117 ──────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_ts',
    scale: BioScale.atoms,
    position: 116,
    name: 'Tennessine',
    title: 'The second-heaviest, a made halogen',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Sits in the halogen column but almost certainly won’t act like one — named for Tennessee.',
    longDescription:
        'Tennessine, group 17, is the second-heaviest element known. Though it sits under the halogens, relativistic effects mean it is unlikely to behave like a typical halogen at all. Its synthesis in 2010 required a rare berkelium target made at Oak Ridge in Tennessee, which the name honors — one of the few elements named for a US state.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Ts'],
          ['Atomic number', '117'],
          ['Group', '17'],
          ['Period', '7'],
          ['Category', 'metalloid / unknown (predicted)'],
          ['State at 25°C (predicted)', 'solid (predicted)'],
          ['Standout fact', 'A "halogen" that likely won’t act like one'],
        ],
      ),
      LessonSection.fact(
        title: 'Made from a rarer element',
        body:
            'Tennessine required a target of berkelium — itself synthetic and scarce — grown at Oak Ridge before the atoms could even be attempted.',
      ),
    ],
    relatedIds: ['element_og'],
  ),

  // ── 118 — MARQUEE ─────────────────────────────────────────────────────────
  BioEntity(
    id: 'element_og',
    scale: BioScale.atoms,
    position: 117,
    name: 'Oganesson',
    title: 'The heaviest element there is',
    moduleId: 'atoms_periodic_table',
    shortDescription:
        'Element 118 — the heaviest known element, sitting under the noble gases but predicted to be a reactive solid, not an inert gas.',
    longDescription:
        'Oganesson closes period 7 as the heaviest element ever made — only a few atoms have ever existed, each lasting under a millisecond. It sits below the noble gases, yet theory predicts it is not inert or gaseous at all: relativistic effects may make it a reactive solid. It is the only element named after a person still living at the time of naming — Yuri Oganessian, the physicist who pioneered superheavy-element synthesis.',
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Symbol', 'Og'],
          ['Atomic number', '118'],
          ['Group', '18'],
          ['Period', '7'],
          ['Category', 'unknown (predicted reactive solid)'],
          ['State at 25°C (predicted)', 'solid (predicted)'],
          ['Standout fact', 'The heaviest element known'],
        ],
      ),
      LessonSection.fact(
        title: 'The only living namesake',
        body:
            'Yuri Oganessian was alive when element 118 took his name in 2016 — one of only two people so honored, and the only one who led the field itself.',
      ),
      LessonSection.thinkReveal(
        title: 'The island of stability',
        question:
            'Superheavy atoms usually vanish in less than a second. Why do scientists keep hunting for even heavier ones?',
        answer:
            'Because of the predicted "island of stability" — a region where special combinations of protons and neutrons ("magic numbers") could make certain superheavy nuclei survive for minutes, days, or longer instead of milliseconds. Oganesson and its neighbors are the doorstep; the goal is to reach that island and finally study a superheavy element long enough to hold it still.',
      ),
    ],
    relatedIds: ['element_fl', 'element_ts'],
  ),
];
