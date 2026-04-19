import 'package:cell_mobile/models/bio_entity.dart';

const clustersEntities = <BioEntity>[
  BioEntity(
    id: 'clusters_local_group',
    scale: BioScale.clusters,
    position: 0,
    name: 'The Local Group',
    title: 'Our Galactic Neighborhood',
    shortDescription: 'A gravitationally bound collection of 80+ galaxies spanning 10 million light-years — dominated by the Milky Way and Andromeda, destined to merge in 4.5 billion years.',
    longDescription:
        'The Local Group is a galaxy cluster containing over 80 known galaxies within a roughly 10 million light-year diameter. It is dominated by two large spiral galaxies — the Milky Way and the Andromeda Galaxy (M31), each with masses of roughly one trillion solar masses — and one medium-sized spiral, the Triangulum Galaxy (M33). The remaining members are dwarf galaxies, most of which orbit one of the two giants as satellites.\n\n'
        'The Milky Way and Andromeda are approaching each other at approximately 110 km/s, drawn together by their mutual gravitational attraction despite the expansion of the universe. In approximately 4.5 billion years, they will collide and merge over a period of about 2 billion years, forming a giant elliptical galaxy sometimes called "Milkomeda." This merger will not involve many direct stellar collisions (the space between stars is vast), but it will reshape both galaxies\' structures, trigger bursts of star formation, and eventually exhaust the combined system\'s gas supply.\n\n'
        'The Local Group is itself a component of the larger Virgo Supercluster. It sits on the outskirts of this supercluster, which contains about 100 galaxy groups and clusters. The concept of gravitational binding is crucial here: the Local Group\'s galaxies are bound to each other and will never be separated by cosmic expansion. But the Local Group as a whole is not gravitationally bound to most of the Virgo Supercluster — more distant galaxy clusters are receding from us and will eventually pass beyond our observable horizon.',
    relatedIds: ['clusters_virgo', 'clusters_gravitational_binding', 'galactic_milky_way'],
  ),
  BioEntity(
    id: 'clusters_virgo',
    scale: BioScale.clusters,
    position: 1,
    name: 'Virgo Supercluster',
    title: 'The Larger Fabric',
    shortDescription: 'A vast collection of 100+ galaxy groups and clusters spanning 110 million light-years — itself just one lobe of the even larger Laniakea Supercluster.',
    longDescription:
        'The Virgo Supercluster (also called the Local Supercluster) is a massive structure containing our Local Group and approximately 100 other galaxy groups and clusters, centered roughly on the Virgo Cluster — a dense collection of about 1,300-2,000 galaxies located 54 million light-years from Earth. The entire supercluster spans approximately 110 million light-years and contains an estimated 10^15 (one quadrillion) solar masses.\n\n'
        'In 2014, a team led by R. Brent Tully redefined our cosmic address by mapping the flow of galaxies through space. They discovered that the Virgo Supercluster is just one lobe of a much larger structure called Laniakea (Hawaiian for "immense heaven"), which spans 520 million light-years and contains approximately 100,000 galaxies. Laniakea\'s galaxies are all flowing toward a gravitational focal point called the Great Attractor, a region of space near the Norma Cluster where an enormous concentration of mass pulls everything toward it.\n\n'
        'At this scale, the universe begins to reveal its large-scale structure. Superclusters are not randomly distributed; they are arranged in filaments and sheets surrounding vast empty voids, forming a pattern sometimes called the "cosmic web." The Virgo Supercluster is connected to neighboring superclusters by filaments of galaxies and dark matter, with enormous voids — regions largely devoid of galaxies — filling the spaces between. This web-like structure is the largest pattern in the universe and reflects the distribution of matter in the very early universe.',
    relatedIds: ['clusters_local_group', 'clusters_gravitational_binding', 'cosmic_web'],
  ),
  BioEntity(
    id: 'clusters_gravitational_binding',
    scale: BioScale.clusters,
    position: 2,
    name: 'Gravitational Binding',
    title: 'The Cosmic Glue',
    shortDescription: 'Gravity is the weakest of the four fundamental forces, yet at cosmic scales it is the only one that matters — sculpting galaxies, clusters, and the large-scale structure of the universe.',
    longDescription:
        'At the subatomic scale, gravity is absurdly weak — roughly 10^36 times weaker than electromagnetism. A small magnet can lift a paperclip against the gravitational pull of the entire Earth. Yet gravity has two properties that make it dominant at cosmic scales: it is always attractive (unlike electromagnetism, which can be positive or negative and tends to cancel out), and it has infinite range (unlike the strong and weak nuclear forces, which operate only at subatomic distances).\n\n'
        'These properties mean that as you zoom out from atoms to molecules to planets to galaxies, gravity becomes increasingly important while the other forces become irrelevant. At the scale of galaxy clusters, gravity is the sole architect. It binds galaxies into groups, groups into clusters, and clusters into superclusters. It determines which structures will remain bound together forever and which will be torn apart by the expansion of space. The boundary between bound and unbound structures is the fundamental dividing line of cosmic fate.\n\n'
        'Dark matter plays a crucial role in gravitational binding. Galaxy clusters contain roughly 5 times more dark matter than visible matter, and it is the dark matter halos that provide most of the gravitational binding energy. Without dark matter, galaxy clusters would not hold together, galaxies would not have formed in their current configurations, and the large-scale structure of the universe would be dramatically different. Gravity, mediated primarily through invisible mass, is the thread that weaves the cosmic tapestry.',
    relatedIds: ['clusters_local_group', 'clusters_virgo', 'galactic_dark_matter', 'cosmic_web'],
  ),
];
